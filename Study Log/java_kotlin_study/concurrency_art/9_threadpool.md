---
title: 9 Java 中的线程池
chapter: "9"
order: "9"
chapter_root: true
---

# 9 Java 中的线程池

## 9.1 以前线程池的总结

我们之前就写过一个线程池：[[Study Log/java_kotlin_study/concurrency_art/4_4_thread_example#4.4 线程池初见|4_4_thread_example]]。但是当时实现的非常简单。~~简单~~总结一下：

1. 由于取任务，加任务的时候可能会发生竞争，所以这里任务需要锁起来，我们用的是[Synchronized List](https://medium.com/@the_infinity/javas-synchronized-collections-07712ae3b2cb);
2. 在添加任务，执行任务的时候，需要对jobs加锁。用的是低效的synchronized；
3. 在添加worker，==移除worker的时候，使用的依然是synchronized==，即使在workers已经是Synchronized List的情况下。

> [!comment] 移除worker的时候，使用的依然是synchronized
> 而且，这里用的锁依然是jobs。这里我一直不知道到底是为什么，问了gpt也在说车轱辘话：[DefaultThreadPool Implementation Explained](https://chatgpt.com/share/8049f345-aad2-4f8a-8386-f16ed12161c2) and [[Study Log/java_kotlin_study/concurrency_art/resources/gpt_threadpool_sb.pdf|gpt_threadpool_sb]]。
> 
> 目前我的推测是，从本质上看，就是为了让worker在+-的时候，不能有线程在取队列中的任务。设想：如果removeWorker我们不加jobs锁的话，如果一个线程调用了removeWorker，就直接把这个worker给干掉了。如果这个时候这个worker刚刚执行jobs.removeFirst()，那就意味着这个任务还没执行呢worker就没了。因此，这里要让**移除worker的线程和被移除的worker进行竞争，竞争jobs**。
> 
> 在源代码中，worker取出了任务之后调用jobs.run()。此时如果才进行removeWorker的话，先remove再shutdown。这样当worker执行完job之后，再次判断isRunning就是false了。然而，我依然不知道为什么addWorkers里面也要加上jobs的锁。你说和removeWorker竞争吧，但是这个竞争也不涉及任务的执行，并且workers已经是Synchronized List了，更没有必要再套一层；你说和execute竞争吧，他俩也完全没有能竞争的地方啊。。你说和worker竞争吧，你要加worker，和已经存在的worker有啥关系？所以我不知道为啥这里有个`synchronized(jobs)`。

- [ ] #TODO tasktodo1723305102984 一个功能完整，设计合理的线程池到底是什么样子？这里没探究出来的问题到底是为什么？ ➕ 2024-08-10 ⏫ 🆔 881cuz

## 9.2 线程池实现原理

> [!attention]
> 估计这是整本书最复杂的部分了。甚至比[[Study Log/java_kotlin_study/concurrency_art/5_2_aqs|5_2_aqs]]还要复杂。

[Java并发常见面试题总结（下） | JavaGuide](https://javaguide.cn/java/concurrent/java-concurrent-questions-03.html#%E7%BA%BF%E7%A8%8B%E6%B1%A0)

现在看看java线程池的工作原理。java线程池为了能节省线程资源，通常会有一些配置：

- 核心线程池数。这个是线程池刚被创建，任务还不多的时候，可以同时运行的最大线程数。比如如果是4，我提交了一个任务，1个线程运行来执行（**需要获取全局锁**）；然后我又提交了一个，这个时候会再创建一个线程运行（**需要获取全局锁**）；当4个线程都在执行任务时，我如果再提交，那么就不会再创建新的线程了。
- 任务队列：就是存放任务的队列。还是刚刚4个核心线程的例子。[[#^d09730|如果第五个任务被提交，此时不会再创建新的线程，会将任务入队]]。
- 最大线程数：如果上面的队列也满了（这个有点难，比如默认任务队列的size是Integer.MAX），还有新任务提交的话，就会再次创建线程执行（**需要获取全局锁**）。此时的线程就不是核心线程了。
- 拒绝策略：如果最大线程数也达到了，就直接拒绝任务执行。抛出一个异常。

通过上面的解释，我们可以看出来，比较影响性能的就是这两个创建线程的过程，这个过程[[#^ca5c6d|需要获取全局锁]]。因此，如果没有核心线程数只有最大线程数的话，全局锁获取就会很频繁。比如一个脑瘫写的代码，直接创建了100个线程的线程池，但是他提交的任务就星崩几个，而每次提交，调用execute，里面的addWorker方法（增加线程的方法）都要获取一次全局锁。这样就太浪费了。所以，这里将两个数字拆开，把任务队列放到中间作为缓冲，这样绝大多数情况都会走入队的操作，这样就不用获取全局锁了。

看看execute的实现（ThreadPoolExecutor）：

```java
/**
 * Executes the given task sometime in the future.  The task
 * may execute in a new thread or in an existing pooled thread.
 *
 * If the task cannot be submitted for execution, either because this
 * executor has been shutdown or because its capacity has been reached,
 * the task is handled by the current {@link RejectedExecutionHandler}.
 *
 * @param command the task to execute
 * @throws RejectedExecutionException at discretion of
 *         {@code RejectedExecutionHandler}, if the task
 *         cannot be accepted for execution
 * @throws NullPointerException if {@code command} is null
 */
public void execute(Runnable command) {
	if (command == null)
		throw new NullPointerException();
	/*
	 * Proceed in 3 steps:
	 *
	 * 1. If fewer than corePoolSize threads are running, try to
	 * start a new thread with the given command as its first
	 * task.  The call to addWorker atomically checks runState and
	 * workerCount, and so prevents false alarms that would add
	 * threads when it shouldn't, by returning false.
	 *
	 * 2. If a task can be successfully queued, then we still need
	 * to double-check whether we should have added a thread
	 * (because existing ones died since last checking) or that
	 * the pool shut down since entry into this method. So we
	 * recheck state and if necessary roll back the enqueuing if
	 * stopped, or start a new thread if there are none.
	 *
	 * 3. If we cannot queue task, then we try to add a new
	 * thread.  If it fails, we know we are shut down or saturated
	 * and so reject the task.
	 */
	int c = ctl.get();
	if (workerCountOf(c) < corePoolSize) {
		if (addWorker(command, true))
			return;
		c = ctl.get();
	}
	if (isRunning(c) && workQueue.offer(command)) {
		int recheck = ctl.get();
		if (!isRunning(recheck) && remove(command))
			reject(command);
		else if (workerCountOf(recheck) == 0)
			addWorker(null, false);
	}
	else if (!addWorker(command, false))
		reject(command);
}
```

好好解释一下这段代码。首先是`workerCountOf(c)`的作用，它返回的是当前[[#^15fc63|被允许启动，但不允许停止]]的线程的数量。举个例子： ^ecd2ad

- 🤨 我要创建一个线程，那么这个线程就是允许启动的。[[#^8bbd3d|workerCount就会增加]]。但是这时候如果因为ThreadFactory创建线程[[#^0e1eb2|失败]]了，实际上workerCount不应该增加。[[#^28fb49|所以到时候还会设置回去]]。因此这个值暂时会和真实情况不一样；
- 🤨 [[#^c6627b|一个线程要结束了]]，最后会做一些收尾工作了。此时线程[[#^e8989f|不会再运行新任务]]，但是因为它没有真正停止，所以此时workerCount其实还是把它给算上了的。

因此，这里第一步的逻辑就是，看当前正在工作线程的数量，看是不是小于核心线程数。如果小于，就会添加一个worker。这里调用的addWorker的第二个参数就是是否核心：

```java
if (workerCountOf(c) < corePoolSize) {
	if (addWorker(command, true))
		return;
	c = ctl.get();
}
```

如果这里不行，那就是超过了核心线程数，应该把任务入队了。所以这里[[#^52b263|检查一下线程池是否任然在运行]]，如果在运行就会尝试把任务入队。入队成功了，就完了吗？没有。在入队成功之后，可能会发生下面的情况：

- 线程池在这个时候被关了（`!isRunning(recheck)`）：那这个时候就不能执行这个任务了，需要拒绝；
- ==此时没有线程还能运行了==（`workerCountOf(recheck) == 0`）：这个时候我们要再添加一个线程。因为此时要么池子已经空了，要么 🤨  [[#^f70a15|剩下的线程都在做收尾工作，马上都要死了]]。[[#^7272d6|所以得加一个线程来工作]]。

所以逻辑如下：

```java
if (isRunning(c) && workQueue.offer(command)) {    // 检查一下线程池是否仍在运行，如果在就入队任务
	int recheck = ctl.get();                       // 重新获取当前状态
	if (!isRunning(recheck) && remove(command))    // 用当前状态再次检查是否在运行
		reject(command);
	else if (workerCountOf(recheck) == 0)
		addWorker(null, false);
}
```

> [!comment] 此时没有线程还能运行了
> 你可能会感觉这种情况不会发生，毕竟刚刚我们还判断了核心线程数。想象这样的情况：核心线程是4个，我提交了4个任务，此时都在执行。当我提交第五个任务时，判断核心线程肯定是false。那接下来我要尝试入队了是把。但是，如果这个时候我还没入队呢，前面那四个线程正好把任务都做完了。接下来他们一看队列里没任务了，就都做收尾工作然后退出了（这里确实是会退出的。可以看keepAliveTime这个参数，如果一直没等到队列里有新任务，就退出了。而大部分线程池的这个值都是0，意味着没任务不等，直接线程终结了。这个和我们自己实现的一直等的线程池很不一样。可以搜一搜为啥它不这么做）。
> 
> 4个线程都退出了，那等任务入队了，查一下线程池状态，还是运行中，因为我没调shutdown，虽然已经没线程了，但是池子还是待命状态。那我如果不检查还有没有线程的话，那就真没人干活儿了。所以，这里要检查一下是否真的没有能干活儿的线程了。[[#^512df9|如果真没有了，那我总得加一个吧]]！

从worker自己生命周期，整个线程池生命周期的角度分别看线程池。

最后，如果还是没走，那就是队列也满了。这个时候就要扩展新线程了。如果还不行，就拒绝吧：

```java
else if (!addWorker(command, false))
	reject(command);
```

- [ ] #TODO tasktodo1723314678194 汇总线程池实现的一些问题。这些对阅读代码非常重要！！！ ➕ 2024-08-11 🔺 🆔 efw1c7
	- [ ] 如果第五个任务来的时候，有空闲的核心线程。此时任务会入队还是直接被其中一个线程执行？ ^d09730
	- [ ] 为什么需要获取全局锁？ ^ca5c6d
	- [ ] 这里的条件要从代码上给出准确的时机，因为后面很多代码的解释要参考这里 ^15fc63
	- [ ] 代码在哪里？ ^8bbd3d
	- [ ] 为什么会失败？ ^0e1eb2
	- [ ] 代码在哪里？ ^28fb49
	- [ ] 什么时候会结束？ ^c6627b
	- [ ] 真的吗？代码证明？ ^e8989f
	- [ ] 为啥一开始不检查？ ^52b263
	- [ ] 写个demo验证一下？感觉这个挺难触发的；另外收尾的线程到底是不是算在workerCount里？这个东西要确定一下，不然这句话本身就有问题。 ^f70a15
	- [ ] 这里为啥核心线程是false？我猜测的是反正已经没线程了，所以这里不用关心是不是核心线程。毕竟不管你是不是核心线程，待遇都是一样的。只是增加的UPPER BOUND不一样。所以这里不管是true都是false都能添加成功 ^7272d6
	- [ ] 这里有个问题，如果创建线程，workerCount增加，但是创建失败，还没来得及把数字设置回来。这个时候如果进行execute判断，并且正好也遇到了上面所说的case，那这个时候workerCount不是0，就不会增加worker。但是事实情况是worker最后会创建失败。那这个时候不是又没有线程能干活儿了吗？ ^512df9

[Deepak Vadgama blog – Java ThreadPoolExecutor internals](https://deepakvadgama.com/blog/java-executor-internals/#using-ctl-lock)

[JAVA-ThreadPoolExecutor why we need to judge the worker count in the execute function during the recheck procedure? - Stack Overflow](https://stackoverflow.com/questions/46901095/java-threadpoolexecutor-why-we-need-to-judge-the-worker-count-in-the-execute-fun)

接下来，介绍worker是如何工作的。它会不断从队列中取出任务执行。

- 线程池的几个状态，RUNNING, SHUTDOWN... 是怎么转换的，还有runStateAtLeast的意思；
- getTask里是如何处理，worker在长时间获取不到任务，也就是idle的时候会干嘛。分为非核心线程和核心线程。这里分allowCoreThreadTimeOut去说；
- 核心线程在获取不到任务时，会空转还是park？

---

```dataviewjs
const pages = dv.pages('"Study Log/java_kotlin_study/concurrency_art"')
let nextChapterHead = undefined
let res = undefined
const current = dv.current()
for (let page of pages) {
	if (page.chapter_root == true && page.order == Number(current.chapter) + 1) {
		console.log("found next head: " + page.name)
		nextChapterHead = page
		continue
	}
	if (page.chapter == undefined || page.chapter != current.chapter) {
		console.log("not current chapter: " + page.file.name)
		continue
	}
	if (page.order == Number(current.order) + 1) {
		res = page
	}
}
console.log("res: " + res)
console.log("next: " + nextChapterHead)
if (res == undefined) {
	res = nextChapterHead
}
let text = ""
if (res != undefined) {
	const path = res.file.path
	const title = res.title
	const decoLink = "[[" + path + "|" + title + "]]"
	text = "Next Article: " + decoLink
} else {
	text = "旅途的终点！"
}
dv.el("p", text, { attr: { align: "right" } })
```