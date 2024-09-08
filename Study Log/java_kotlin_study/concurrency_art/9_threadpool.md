---
title: 9 Java 中的线程池
chapter: "9"
order: "9"
chapter_root: true
---
****
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
> 你可能会感觉这种情况不会发生，毕竟刚刚我们还判断了核心线程数。想象这样的情况：核心线程是4个，我提交了4个任务，此时都在执行。当我提交第五个任务时，判断核心线程肯定是false。那接下来我要尝试入队了是把。但是，如果这个时候我还没入队呢，前面那四个线程正好把任务都做完了。<u>接下来他们一看队列里没任务了，就都做收尾工作然后退出了（这里确实是会退出的。可以看keepAliveTime这个参数，如果一直没等到队列里有新任务，就退出了。而大部分线程池的这个值都是0，意味着没任务不等，直接线程终结了。这个和我们自己实现的一直等的线程池很不一样。可以搜一搜为啥它不这么做）</u>。
> 
> 4个线程都退出了，那等任务入队了，查一下线程池状态，还是运行中，因为我没调shutdown，虽然已经没线程了，但是池子还是待命状态。那我如果不检查还有没有线程的话，那就真没人干活儿了。所以，这里要检查一下是否真的没有能干活儿的线程了。[[#^512df9|如果真没有了，那我总得加一个吧]]！
> 
> 注意一下上面划线的句子。接着看下去你会发现，核心线程要是想在没有任务的时候结束自己，需要一定的条件。这个条件我们之后会说明。
> 
> - [ ] #TODO tasktodo1725772639884 说明了吗？ ➕ 2024-09-08 ⏫ 🆔 qunse9 

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
	- [ ] [[#^283ad8|代码在哪里？]] ^8bbd3d
	- [ ] 为什么会失败？ ^0e1eb2
	- [ ] [[#^ffb99a|代码在哪里]]？ ^28fb49
	- [ ] 什么时候会结束？ ^c6627b
	- [ ] 真的吗？代码证明？ ^e8989f
	- [ ] 为啥一开始不检查？ ^52b263
	- [ ] 写个demo验证一下？感觉这个挺难触发的；另外收尾的线程到底是不是算在workerCount里？这个东西要确定一下，不然这句话本身就有问题。 ^f70a15
	- [ ] 这里为啥核心线程是false？我猜测的是反正已经没线程了，所以这里不用关心是不是核心线程。毕竟不管你是不是核心线程，待遇都是一样的。只是增加的UPPER BOUND不一样。所以这里不管是true都是false都能添加成功 ^7272d6
	- [ ] 这里有个问题，如果创建线程，workerCount增加，但是创建失败，还没来得及把数字设置回来。这个时候如果进行execute判断，并且正好也遇到了上面所说的case，那这个时候workerCount不是0，就不会增加worker。但是事实情况是worker最后会创建失败。那这个时候不是又没有线程能干活儿了吗？ ^512df9

[Deepak Vadgama blog – Java ThreadPoolExecutor internals](https://deepakvadgama.com/blog/java-executor-internals/#using-ctl-lock)

[JAVA-ThreadPoolExecutor why we need to judge the worker count in the execute function during the recheck procedure? - Stack Overflow](https://stackoverflow.com/questions/46901095/java-threadpoolexecutor-why-we-need-to-judge-the-worker-count-in-the-execute-fun)

接下来，介绍worker是如何工作的。它会不断从队列中取出任务执行。

> [!Attention] With Code!
> 读接下来的内容的时候，一定对着源码读。不然你很可能不知道我在说什么。

- ~~线程池的几个状态，RUNNING, SHUTDOWN... 是怎么转换的，还有runStateAtLeast的意思；~~
- getTask里是如何处理，worker在长时间获取不到任务，也就是idle的时候会干嘛。分为非核心线程和核心线程。这里分allowCoreThreadTimeOut去说；
- 核心线程在获取不到任务时，会空转还是park？

介绍一下**线程池的**几个状态：

- `RUNNING`：允许接收新任务，并且会处理在队列中的任务；
- `SHUTDOWN`：不接受新的任务，但是也会处理队列中的任务；
- `STOP`：不接受新任务，也不处理队列中的任务，并且对于正在执行的任务，也会尝试中断它们；
- `TIDYING`：所有任务都已经停止了，并且此时`workerCountOf(c)`应该是0。如果线程池正在转移到`TIDYING`状态，会执行一些hook方法；
- `TERMINATED`：`terminated()`方法已经完成后的状态。

看一下这几个状态的表示：

```java
private static final int COUNT_BITS = Integer.SIZE - 3;
// runState is stored in the high-order bits
private static final int RUNNING    = -1 << COUNT_BITS;
private static final int SHUTDOWN   =  0 << COUNT_BITS;
private static final int STOP       =  1 << COUNT_BITS;
private static final int TIDYING    =  2 << COUNT_BITS;
private static final int TERMINATED =  3 << COUNT_BITS;
```

其中，`COUNT_BITS`是int类型大小-3，也就是32-3=29。注意，**计算机实际上是用补码存的数字**，所以这几个状态的实际值是这样的：

| 状态           | 十进制        |                                 二进制 |
| ------------ | ---------- | ----------------------------------: |
| -            | -1         | `111,11111111111111111111111111111` |
| -            | 2147483647 | `011,11111111111111111111111111111` |
| `RUNNING`    | -536870912 | `111,00000000000000000000000000000` |
| `SHUTDOWN`   | 0          |                                 `0` |
| `STOP`       | 536870912  | `001,00000000000000000000000000000` |
| `TIDYING`    | 1073741824 | `010,00000000000000000000000000000` |
| `TERMINATED` | 1610612736 | `011,00000000000000000000000000000` |

我们能发现，随着数字不断变大，状态也逐渐向着关闭流转。这里用的是int的最高的3bit表示这些状态。而剩下的29bit就用来表示工作线程的数量了。就像注释里说的：

> In order to pack them **into one int**, we limit workerCount to  `(2^29)-1` (about 500 million) threads rather than `(2^31)-1` (2 billion) otherwise representable. If this is ever an issue in the future, the variable can be changed to be an AtomicLong, and the shift/mask constants below adjusted. But until the need arises, this code is a bit faster and simpler using an int.

而这个int就是该线程池的核心状态控制：

```java
// 初始状态，state == RUNNING, workerCount == 0
private final AtomicInteger ctl = new AtomicInteger(ctlOf(RUNNING, 0));
```

再次比较一下这几个状态的值，我们能发现，不管后面29bit是多少，对于整个ctl来说，只要前三位是一定的，那么大小关系就是确定的。这就像，100多万一定比200多万要小，不管后面的零头是多少。因此，如果要判断当前处于什么状态，其实不需要单独把ctl的最高3bit取出来，直接整个比就行了。这也就是这些方法产生的原因：

```java
/*
 * Bit field accessors that don't require unpacking ctl.
 * These depend on the bit layout and on workerCount being never negative.
 */

private static boolean runStateLessThan(int c, int s) {
	return c < s;
}

private static boolean runStateAtLeast(int c, int s) {
	return c >= s;
}

private static boolean isRunning(int c) {
	return c < SHUTDOWN;
}
```

以`runStateAtLeast()`为例，在增加线程的方法`addWorker()`的时候就会调用到这里。现在就是简单看一看： ^29b849

```java
// Check if queue empty only if necessary.
if (runStateAtLeast(c, SHUTDOWN)
	&& (runStateAtLeast(c, STOP)
		|| firstTask != null
		|| workQueue.isEmpty()))
	return false;
```

这是其中一个小部分，表示如果满足这些情况，我拒绝创建新的线程。判断的逻辑如下：

- 线程池必须至少是`SHUTDOWN`状态；
- 以下三个条件之一成立：
	- 至少是`STOP`状态；
	- 要让新创建的线程立即执行的任务不为空；
	- 队列中没有任务。

我们来解释一下为什么是这样。首先，如果是`RUNNING`状态，那肯定没问题可以创建。但是如果是`SHUTDOWN`状态，表示当前**不接受新的任务，但是也会处理队列中的任务**。所以，对于后面的两个条件，`firstTask != null`表示有新的任务，我不接受它；`workQueue.isEmpty()`表示队列中没有任务，所以不用处理。这样自然就需要拒绝创建新线程。至于`STOP`状态，在这个状态下，连队列里的任务都要全部中断，所以不管你要干嘛，这个时候绝对不允许创建新线程了。

- [ ] #TODO tasktodo1724255272132 在shutdown之后，如果我悄悄把所有worker都干掉，但是任务队列里还有任务。这个时候我addWorker的时候要是每一个都带着firstTask，那是不是线程池就永远关不掉了？？ ➕ 2024-08-21 🔽 🆔 6n5jlv

然后给一下线程池状态之间的流转。当然，只能单向流转。

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-08-21 23.57.38.excalidraw.svg]]

接下来，介绍工作线程，也就是worker的添加。唯一添加worker的方法是调用`addWorker()`，而这个方法绝大多数情况是调用`execute()`提交任务的时候会进行。剩下的情况都是一些边界情况，比如修改核心线程数量等。我们很少会调整核心线程数，嗯。

是否可以增加一个worker，主要取决于：

1. 当前线程池的状态。这个我们刚刚讲过；
2. 已存在的线程数量，这个与线程是否是核心线程有关。

刚刚添加worker时，就会进行我们介绍过的判断：

```java
// Check if queue empty only if necessary.
if (runStateAtLeast(c, SHUTDOWN)
	&& (runStateAtLeast(c, STOP)
		|| firstTask != null
		|| workQueue.isEmpty()))
	return false;
```

这个条件如果通过，那么就要开始创建。当然，创建的时候，需要进行存在线程数的判断：

```java
if (workerCountOf(c) >= ((core ? corePoolSize : maximumPoolSize) & COUNT_MASK))
	return false;
```

反正要么是核心线程数，要么是最大线程数。就取决于当前线程是不是核心线程。从这里我们能看到，一个线程是不是核心线程，其实不是由Worker来记忆的。**线程池对待核心线程，和对待非核心线程的行为是完全一致的**。之所以有核心和非核心一说，就是我们会用这个upper bound去控制数量。而在后面我们也能看到，之所以核心线程不会退出，也是因为线程在取任务的时候，如果没取到，还会判断一下当前存活的线程数量与核心线程数。换句话说，**我们不关心“哪几个”线程是核心线程，我们只关心需要“有几个”线程是核心线程**。而“有几个”，用核心线程数这个upper bound去判断足矣。

接下来，会尝试增加worker的数量。还记得这个东西在哪儿存的吗？就是workerCount，那显然是在`ctl`里存的。所以我们要单独设置这个AtomicInteger，那显然就是会用CAS去设置。如果设置成功了，那当然继续就行了；如果失败了，就要重试。 ^283ad8

到了这里，其实还有一种情况没有覆盖到。就是如果你的CAS一直失败，会一直重试。但是如果不断重试的过程中，外面把线程池给关了。这个时候要走一开始判断SHUTDOWN, STOP的逻辑。TPE的实现思路如下。我们重试CAS的过程，被包在一个无限的for循环里：

```java
for (;;) {
	/* 不断尝试CAS，如果成功了就要跳出循环 */
}
```

然后一开始状态的判断，是在这个for循环的上面做的：

```java
// Check if queue empty only if necessary.
if (runStateAtLeast(c, SHUTDOWN) ...
for (;;) {
	/* 不断尝试CAS，如果成功了就要跳出循环 */
}
```

那现在的问题是，在for循环里面需要判断TPE的状态，然后还需要重新走一遍外面的逻辑。这里的做法就是，再用一层for循环包起来，并加上标签。这样我们continue的时候就可以continue到外层的循环了：

```java
retry:
for (int c = ctl.get();;) {
	// Check if queue empty only if necessary.
	if (runStateAtLeast(c, SHUTDOWN) ...
	for (;;) {
		/* 不断尝试CAS，如果成功了就要跳出循环 */
		c = ctl.get();  // Re-read ctl
		if (runStateAtLeast(c, SHUTDOWN))
			continue retry;  // 这里跳到了retry，也就是外层循环
	}
}

```

并且注意，外层循环的那个条件里，后面两个语句都是空的，也就意味着外层循环也只会拿一次`ctl`。所以这里我们才会在内层循环帮它拿一次`ctl`，这样到了外层循环重试，就会用我们刚刚在内层循环拿到的新的`ctl`去做状态判断，从而正确返回false。

这部分完整的代码：

```java
private boolean addWorker(Runnable firstTask, boolean core) {
	retry:
	for (int c = ctl.get();;) {
		// Check if queue empty only if necessary.
		if (runStateAtLeast(c, SHUTDOWN)
			&& (runStateAtLeast(c, STOP)
				|| firstTask != null
				|| workQueue.isEmpty()))
			return false;

		for (;;) {
			if (workerCountOf(c) >= ((core ? corePoolSize : maximumPoolSize) & COUNT_MASK))
				return false;
			if (compareAndIncrementWorkerCount(c))
				break retry;
			c = ctl.get();  // Re-read ctl
			if (runStateAtLeast(c, SHUTDOWN))
				continue retry;
			// else CAS failed due to workerCount change; retry inner loop
		}
	}
	
	/* 成功设置CAS,开始添加worker */
}
```

注意，这里我们并没有真正创建Worker实例，更没有创建新的线程。但是我们却设置了`ctl`，把workerCount给+1了。所以后面如果worker没有真正被创建出来（因为各种异常），还需要进行状态回滚。

创建Worker的过程就先不说了，在创建之后，需要添加。添加之前，最重要的一件事就是获取这个全局锁：

```java
final ReentrantLock mainLock = this.mainLock;
mainLock.lock();
```

在`addWorker()`中，获取这个锁的主要目的是避免多个线程同时调用这个方法，同时操作`workers`这个结构，它是很脆弱的：

```java
/**
 * Set containing all worker threads in pool. Accessed only when
 * holding mainLock.
 */
private final HashSet<Worker> workers = new HashSet<>();
```

> [!question]-
> 这个时候你可能就会问了：*我用一些并发的集合，比如CopyOnWriteArrayList之类的，不是就能避免使用锁了吗*？确实。但是这里选择用锁的原因，也写在mainLock的注释里了。最主要的原因就是**避免"interrupt storm"**。在TPE里有个方法叫`interruptIdleWorkers()`，功能是中断正在等着任务的线程。大概看一眼实现就能明白，这里面做的其实就是尽可能，把`workers`里所有的线程都给中断。线程是否在执行任务是通过`w.tryLock()`的返回值决定的。这个我们后面会说。显然，如果有多个线程并发地调用这个方法，那还真就是一个"interrupt storm"。因为相当于同时有多个线程对`workers`进行遍历，并且对其中的worker进行中断（正在退出的线程并发地中断那些还没被中断的线程）。为了避免这种情况，我们只能将`interruptIdleWorkers()`的执行给原子化，也就是注释中说的"serializes"（序列化，就是指把多个`interruptIdleWorkers()`的调用排成一排，这样每一个调用就会被认为是原子的）。而如果不这么做的话，可以看看`processWorkerExit()`方法。它是worker执行结束的时候调用的。这里面最终就会调用到`interruptIdleWorkers()`。意味着，这些将要结束的线程，如果同时结束，很有可能会并发地调用到`interruptIdleWorkers()`，导致之前所说的"interrupt storm"。而**如果我们调用了`shutdown()`，这种情况会更加严重**。因为每个结束的线程都会来一遍这样的操作。
> 
> 除了给workers加锁，mainLock还有一个更重要的作用，就是**让[[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-08-21 23.57.38.excalidraw.svg|线程池状态的转移]]也要原子化**。一旦获取了mainLock，我能保证之后获取的线程池状态，**在锁的作用域内一定是正确的**，绝对不会被别人改变。这个功能马上就会体现。

- [ ] #TODO tasktodo1724436111909 结合妥善终结线程的方法，来说明TPE的shutdown是怎么实现的。 ➕ 2024-08-24 🔺 🆔 oqel59 

获取了锁之后，真正要添加worker，还需要满足几个条件：

- 线程池状态满足条件；
- 线程正常启动。

我们先看第一个。这里显然无非还是要查一下ctl，但是这里的代码依然很晦涩：

```java
// Recheck while holding lock.  
// Back out on ThreadFactory failure or if  
// shut down before lock acquired.  
int c = ctl.get();  
  
if (isRunning(c) || (runStateLessThan(c, STOP) && firstTask == null)) {
	... ...
}
```

从注释的提示可以看出，如果在mainLock的获取之前，更准确来说，在上面那两个for循环跳出来之后，和mainLock获取之前，如果有人关掉了线程池，那么在这里会进行最后一次捕捉。捕捉的代码就是if里面的条件。

`isRunning(c)`这个很好懂，就不说了，但是后面又是啥意思。`isRunning`表示当前是RUNNING状态，如果不满足，并且后面这个条件也满足了，less than STOP，那么当前的状态肯定是SHUTDOWN，因为我们已经获取mainLock了。此时，如果firstTask还是空的话，代表没有新任务提交，所以我们还可以让这个新的worker去处理队列中的任务。所以这里允许添加；而如果firstTask不是空，代表这个worker要处理新任务。但是SHUTDOWN状态不允许处理新任务，所以这里不让添加。

> [!summary]
> 总结一下上面“允许添加worker”的情况。就是两种：
> 
> - RUNNING状态；
> - SHUTDOWN状态，并且这个添加的worker是要去处理队列中的任务的，而不是firstTask。
> 
> 如果你是STOP及以上的状态，啥线程也不让你加了，这里就直接不会执行。

好了，看第二个，线程是否正常启动。这个判断就很简单了：

```java
if (t.getState() != Thread.State.NEW)
	throw new IllegalThreadStateException();
```

也没什么好说的。

如果条件都满足，就可以添加worker了：

```java
workers.add(w);  
workerAdded = true;  
int s = workers.size();  
if (s > largestPoolSize)  
    largestPoolSize = s;
```

这里的`largestPoolSize`没有它用，是纯粹提供给业务方的。用来标识这个线程池里**曾经出现过的**最多的线程数。

最后，无非两种结果，添加成功或者失败：

- 成功，启动worker的线程；
- 失败，回滚状态，也就是`addWorkerFailed()`方法。

> [!note]
> 在走成功或者失败的逻辑之前，会先释放一下mainLock。

先看成功，直接放代码，不用说：

```java
if (workerAdded) {
	t.start();
	workerStarted = true;
}
```

然后是失败。这里需要进行回滚。回滚的操作当然是从workers里移除添加的worker，然后把workerCount设置回来。因为也要操作workers，所以也要获取mainLock。 ^ffb99a

我当时看到这段代码，最奇怪的就是，为什么会去remove。我们看看失败的出发点：

```java
if (!workerStarted)  
    addWorkerFailed(w);
```

只有workerStarted是false才会触发。但是如果remove的时候worker真的在workers里面，证明刚才的`workers.add(w)`是成功的，则证明`workerAdded`一定是true，则证明`t.start(); workerStarted = true;`一定会被执行。那这种情况下，如果还存在，唯一的解释就是，`t.start()`抛出了异常。而这个异常会再用一个try catch捕获，导致在`addWorkerFailed`的时候，发现workers里居然还有我刚刚添加的worker。

> [!attention]
> 上面这段对着代码理解。

到这里，我就可以把整个addWorker方法贴出来了，每一句代码是干什么的，都应该很清楚了：

```java
private boolean addWorker(Runnable firstTask, boolean core) {
	retry:
	for (int c = ctl.get();;) {
		// Check if queue empty only if necessary.
		if (runStateAtLeast(c, SHUTDOWN)
			&& (runStateAtLeast(c, STOP)
				|| firstTask != null
				|| workQueue.isEmpty()))
			return false;

		for (;;) {
			if (workerCountOf(c) >= ((core ? corePoolSize : maximumPoolSize) & COUNT_MASK))
				return false;
			if (compareAndIncrementWorkerCount(c))
				break retry;
			c = ctl.get();  // Re-read ctl
			if (runStateAtLeast(c, SHUTDOWN))
				continue retry;
			// else CAS failed due to workerCount change; retry inner loop
		}
	}

	/* CAS成功，开始添加worker */

	boolean workerStarted = false;
	boolean workerAdded = false;
	Worker w = null;
	try {  // 外层的try catch主要用于捕获t.start()的异常
		w = new Worker(firstTask);
		final Thread t = w.thread;
		if (t != null) {
			final ReentrantLock mainLock = this.mainLock;
			mainLock.lock();
			try {  // 内层的try catch主要用于捕获IllegalThreadStateException
				// Recheck while holding lock.
				// Back out on ThreadFactory failure or if
				// shut down before lock acquired.
				int c = ctl.get();

				if (isRunning(c) ||
					(runStateLessThan(c, STOP) && firstTask == null)) {
					if (t.getState() != Thread.State.NEW)
						throw new IllegalThreadStateException();
					workers.add(w);
					workerAdded = true;
					int s = workers.size();
					if (s > largestPoolSize)
						largestPoolSize = s;
				}
			} finally {
				mainLock.unlock();
			}
			if (workerAdded) {
				t.start();
				workerStarted = true;
			}
		}
	} finally {
		if (! workerStarted)
			addWorkerFailed(w);
	}
	return workerStarted;
}
```

接下来我们从每一个worker的生命周期出发，来看线程是怎么接收任务，处理任务，最后又是怎么结束自己的。

Worker这个类是继承自AQS。那自然它其实也是一个锁。这个锁和mainLock有啥区别呢？mainLock的功能我们也提到过了：

1. 避免有多个工作线程同时结束，并发地调用interruptIdleWorkers()，导致线程疯狂（并发地）被interrupt，引发interrupt storm；
2. 保证状态的改变是原子的。这样只要我获取了mainLock，在我释放它之前，线程池的状态就一定会保持不变。因为任何人想要改变线程池的状态都要先获取mainLock。

可以看到，mainLock的限制都是加在整个线程池上的，更准确的来说，是**workers set**。就像注释里说的那样；而每一个worker如果也是个锁的话，自然就是为了给没一个worker执行任务的时候加上一点限制。从注释里也能看到，这个实现是opportunistically，投机取巧地。所以其实可以用其它的实现，比如给每一个worker单独安排一个锁之类的。而这里因为需要的并发控制比较简单，所以没有像mainLock一样用ReentrantLock，而是自己实现了一个**简单的不可重入的互斥锁**。至于更具体的原因，我们接下来进行探究。

明确一点，Worker这个锁有两个状态：

```java
// The value 0 represents the unlocked state.  
// The value 1 represents the locked state.
```

worker里除了AQS相关的实现，就是一个run方法。当然也就是执行任务的方法。接下俩我们就来看看运行的时候发生了什么。这个run方法将任务运行委托给了线程池：

```java
/** Delegates main run loop to outer runWorker. */
public void run() {
	runWorker(this);
}
```

所以实际还是要看runWorker的实现。

既然要运行任务。首先最重要的目的就是要知道任务是啥。任务主要来源于两方面：

1. worker创建时分配的firstTask；
2. worker主动获取的task，通过getTask()方法。

> [!note] getTask()
> `getTask()`方法返回值有两种。要么是一个任务，代表成功获取到了任务；要么是null，代表没获取到，意味着获取这个任务的线程要退出了。

第一个就不多说了，我们主要看第二个。当线程执行完一个任务后，紧接着就是要继续获取任务来执行，自然也只能通过任务队列。我们在分析execute的时候也说过，任务队列就是这个workQueue。只有execute这一个方法里会将任务入队；同样也只有getTask这一个方法会将任务出队。

获取任务，当然也要是合适的时机才行。如果我们把线程池关了，那么再获取任务执行也没意义了。所以我们也能在getTask里看到和addWorker中[[#^29b849|类似]]的场景：

```java
// Check if queue empty only if necessary.
if (runStateAtLeast(c, SHUTDOWN)
	&& (runStateAtLeast(c, STOP) || workQueue.isEmpty())) {
	decrementWorkerCount();
	return null;
}
```

同样是：

1. 线程池已经处于STOP状态；
2. 线程池处于SHUTDOWN状态，并且队列是空的。

这两种情况下，我们会直接返回null，因为已经不需要再获取任务了。但是在返回任务之前，需要减少一下线程数。但是我们需要注意一下，这里的减少线程数不是用CAS，是直接减少。毕竟是关闭线程池，所以直接减少也没啥。这里我们需要补充一点，虽然是直接减少，但是由于是AtomicInteger，所以还是具有原子性的：

```java
/**
 * Decrements the workerCount field of ctl. This is called only on
 * abrupt termination of a thread (see processWorkerExit). Other
 * decrements are performed within getTask.
 */
private void decrementWorkerCount() {
	ctl.addAndGet(-1);
}
```

这里的“直接减少”强调的其实是：**我们不关心减去当前线程之后，还剩下多少个线程**。马上我们就会看到，我们有时候也关心减掉之后到底还剩几个线程。而如何实现“关心”呢？当然就是CAS啦。

还有一个时刻，线程不会继续取任务，会退出。那就是要看看线程池中当前线程池的个数，是否已经过了。

我们之前提到过，添加worker时，这个worker是核心还是非核心，其实就是设置一个upper bound。如果是核心线程，那么upper bound就是corePoolSize；如果是非核心线程，那就是maximumPoolSize。

而在getTask()中也有类似的情况。当一个线程因为长时间获取不到任务（这个之后会讲），从而超时，这个线程就应该结束了。那么当前线程是否要结束，有如下判断：

- 看线程池的配置中，是否允许核心线程超时（allowCoreThreadTimeOut）；
- 看当前的线程数是否已经超过了核心线程数。

这两个情况中任意一个满足，当前线程就会退出。你可能感觉比较绕，我来解释一下。之前我们说过，我们不关心哪几个线程是核心线程，只关心有几个线程是核心线程。线程池对待任意一个线程，都是一视同仁。所以，对于执行到这里的线程，它是否应该退出，不是看它是不是核心线程（当然也看不到，根本没这标记位），而是看当前线程池的线程个数是否超过了核心线程。如果已经超过了，那毫无疑问我就应该退出了；而如果没超过，那就代表**当前线程池里还剩下的线程其实都是核心线程**。这个时候我应该退出吗？那当然就是看线程池的配置里是不是允许核心线程超时了。

> [!note]- 核心线程是否允许超时
> 存储在标记位`allowCoreThreadTimeOut`中：
> 
> 
> ~~~java
> /**
>  * If false (default), core threads stay alive even when idle.
>  * If true, core threads use keepAliveTime to time out waiting
>  * for work.
>  */
> private volatile boolean allowCoreThreadTimeOut;
> ~~~
> 
> 这个标记位通过allowCoreThreadTimeout()方法设置。如果设置为了true，那么就会立刻调用interruptIdleWorkers()，来中断所有已经休眠的线程。因为如果这些休眠的是核心线程，那你们也该死啦。

以上逻辑的代码：

```java
int wc = workerCountOf(c);
// Are workers subject to culling?
boolean timed = allowCoreThreadTimeOut || wc > corePoolSize;
```

如果timed为true就表示：当前线程执行getTask()时，执行到这里，通过看核心线程超时的配置，和当前线程的数量之后，评估出了一个结论：我该死啦！

当然，这两种情况，只是当前线程认为它该死了。其实还有一种情况我们没有考虑到，就是当前线程的个数已经超过了最大线程数。那这个就不是你自己的问题了，是线程池都出了问题。所以自然要算在里面。

那么，为什么在代码里，没有将`wc > maximumPoolSize`这种情况并入到`timed`里面呢？答案是因为，即使`timed == true`，这个线程也不是完全需要退出，而`wc > maximunPoolSize`的情况下，当前线程必须要退出，因为这已经属于错误了。

那么，`timed == true`的情况下，还需要满足什么条件才能退出呢？看代码就知道了，就是`timedOut`变量。这个变量我们还没接触到，不过可以先说一下，它代表着**当前线程曾经试图从workQueue中取任务，一直没取到，然后就在那儿等，等超时了都**。因此，如果是正常的在线程池中“生活工作”的一个线程，它结束自己的前提条件要是“没活儿干”。后面的条件才是是否核心线程。

满足以上的所有条件，线程就能退出了吗？好像不是。因为我们只讨论了线程本身，还没有讨论任务。只有能让线程池在移除当前线程后还能合理地完成任务，才会允许当前线程退出。

首先，就是线程池的个数大于1。如果不满足的话，其实只有这一种情况：线程池内，就只剩我这一个活着的线程了。那1-0=0，没了我，线程池就空了。那这活儿谁干？所以，允许当前线程退出的，和任务相关的条件是：

要么线程个数大于1（还有人能干活儿），要么任务队列已经空了（真没活儿干了）。

最后总结一下总体的条件：

1. 线程认为自己应该退出了，或者线程池发现线程数量出现了错误，超过了最大限制；
2. 保证线程退出后，线程池还能正常工作。

两个条件要都满足，才能最终让这个线程退出：

```java
if (
	(wc > maximumPoolSize || (timed && timedOut)) 
	&& (wc > 1 || workQueue.isEmpty())
) {
	if (compareAndDecrementWorkerCount(c))
		return null;
	continue;
}
```

看到这里，我倒吸了一口冷气：为啥是CAS？难道还有猫腻？好在刚刚我们已经打过预防针了。这里用CAS的根本原因就是，我们关心移除当前线程之后的结果。

我们从业务方的视角思考：在我没设置allowCoreThreadTimeout的情况下，我认为线程池中的核心线程应该是永远不会退出的。换句话说，如果核心线程数是4，只要我添加了超过4个线程，之后线程数就永远也不会小于4了。

我把这部分代码贴出来，模拟一下一个例子：

```java
int wc = workerCountOf(c);                                     // 1

// Are workers subject to culling?
boolean timed = allowCoreThreadTimeOut || wc > corePoolSize;   // 2

if ((wc > maximumPoolSize || (timed && timedOut))              // 3
	&& (wc > 1 || workQueue.isEmpty())) {
	if (compareAndDecrementWorkerCount(c))                     // 4
		return null;                                           // 5
	continue;                                                  // 6
}
```

还是核心线程数是4。假设现在实际上有5个线程，然后有两个线程并发地执行到了getTask()，然后都没取到任务超时了（timedOut为true），然后又同时执行到了1。

那么两个线程得到的`wc`就都是5。

假设allowCoreThreadTimeout是false，那么两个线程都会判断`wc > corePoolsize`是true（5 > 4）。所以两个线程都认为自己是那个多余的线程，应该退出了。

然后，两个线程在3的判断中，`timed && timedOut`的结果都是true，并且此时的`wc > 1`是恒成立的。

然后两个线程就会并发地执行到4。而如果4这个位置不是CAS，而是普通的AtomicInteger的减少，结果是什么？那当然就是线程数会从5变成3。然后两个线程就都成功退出了。

但是，我们之前那么费劲巴拉到底是为啥？那个allowCoreThreadTimeout，还比什么核心线程数为了啥？不就是为了：保住核心线程，不要让他退出吗？

所以，这里的一个并发的小bug，就会导致两个线程同时认为自己是该死的那个，我死了，剩下的就都是核心线程了。然而殊不知，你俩要真都死了，核心线程反而少了一个。

这就是用CAS的原因：我关心当前线程退出后，还剩下多少个线程。还记得我们之前提到过的CAS的特点吗？[[Study Log/java_kotlin_study/concurrency_art/5_4_read_write_lock#^fba60d|有人失败，就一定有人成功]]。因此，这里用了单独的一次CAS，保证的是：有多个线程并发地想要退出时，保证有且只有一个线程最终能够成功退出。因为退出之后修改了线程数，其他想要退出的线程的CAS就会失败，失败之后就要用新的状态重新来一遍。

好了，终于开始取任务了！workQueue是一个BlockingQueue，我们取任务主要用的是两种方法：

```java
E poll(long timeout, TimeUnit unit) // 如果超时了，就会返回
E take()                            // 不取到，我就一直等
```

什么时候用一直等的方法？显然，必须要是核心线程，并且allowCoreThreadTimeout要是false。其它的时候都用超时的这种。那么怎么区分两种情况呢？好像`timed`变量就是呀！如果`timed == false`，那么allowCoreThreadTimeout要是false，同时`wc <= corePoolSize`，也就是当前线程是核心线程。一切都是那么巧合。。。

```java
Runnable r = timed ?
		workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) :
		workQueue.take();
```

如果这个线程还能往下走，只有两种情况：

1. 成功取出了一个任务；
2. 超时了。

所以，剩下的就好说了。我就直接贴全部的代码了。现在getTask()的每一行代码你都应该知道是怎么回事了（除了最后异常的处理）：

```java
private Runnable getTask() {
	boolean timedOut = false; // Did the last poll() time out?

	for (;;) {
		int c = ctl.get();

		// Check if queue empty only if necessary.
		if (runStateAtLeast(c, SHUTDOWN)
			&& (runStateAtLeast(c, STOP) || workQueue.isEmpty())) {
			decrementWorkerCount();
			return null;
		}

		int wc = workerCountOf(c);

		// Are workers subject to culling?
		boolean timed = allowCoreThreadTimeOut || wc > corePoolSize;

		if ((wc > maximumPoolSize || (timed && timedOut))
			&& (wc > 1 || workQueue.isEmpty())) {
			if (compareAndDecrementWorkerCount(c))
				return null;
			continue;
		}

		try {
			Runnable r = timed ?
				workQueue.poll(keepAliveTime, TimeUnit.NANOSECONDS) :
				workQueue.take();
			if (r != null)
				return r;
			timedOut = true;
		} catch (InterruptedException retry) {
			timedOut = false;
		}
	}
}
```

- [ ] #TODO tasktodo1725805658470 最后的异常处理是为了应对线程在等待任务的时候被中断。可以看到getTask()的调用者——runWorker()方法在一开始就执行了w.unlock()，旁边一句注释allow interrupts。那么这里为啥要允许别人中断它呢？ ➕ 2024-09-08 ⏫ 🆔 lbku3q 
- [ ] #TODO tasktodo1725805757050 这里只有for循环一开始进行了线程池状判断。那如果刚检查完状态，甚至是已经获取到了任务的时候，有人把线程池关了，会发生什么？ ➕ 2024-09-08 ⏫ 🆔 7lpbsb 






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