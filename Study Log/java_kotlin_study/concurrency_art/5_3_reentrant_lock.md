---
title: 5.3 可重入锁
chapter: "5"
order: "3"
---

## 5.3 重入锁

在[[Study Log/java_kotlin_study/concurrency_art/5_2_aqs#5.2.2.1.3 入队成功之后 - 尝试获得锁 - accquireQueued()|5_2_aqs]]中我们正式介绍了什么情况锁才是公平的。简单来说：

<font color="red">在绝对时间上，先对锁进行获取的请求一定先被满足，这就是公平；只要不满足，就是不公平。</font>

ReentrantLock自己本身就在『可重入』的基础上又支持公平锁和非公平锁。

### 5.3.1 可重入

我们首先来研究可重入。字面意思，就是如果这个锁已经被自己获得了，还能再被自己获得（有啥用？）。我们之前实现的Mutex是可重入的吗？试一试，下面的代码：

```kotlin
val mutex = Mutex()
mutex.lock()
mutex.lock()
```

执行完之后，卡住了。我们用jstack看一下就发现，它确实在『重入』的时候阻塞住了：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240226204822.png]]

也就是说，目前这个Mutex是不支持重入的。原因也很简单，我们回顾一下lock()：

1. 调用的就是默认的acquire()方法；
2. acquire()首先会调用tryAcquire()。在我们这个例子中肯定会成功，所以直接返回；
3. 之后又调用了acquire() -> tryAcquire()。由于已经被获得了，所以tryAcquire()返回false，导致主线程被送进队列。

不难发现，问题出在tryAcquire()上。我们应该在这里面加入『自己和获得锁线程的比较』。如果发现获得锁的线程就是自己，那么应该返回true。

但是还有一个问题：如果线程连续两次获取同一个锁，那算一次还是两次呢？我们认为，一个线程不可能平白无故地获取两遍一样的锁，那就肯定是有它的理由。所以，如果一个线程获取了两次锁，就得解锁两次之后其它线程才能获取（前提是互斥锁）。

> [!summary] 重入的实现需要注意两个问题：
> * **线程再次获取锁**：锁需要去识别获取锁的线程是否为当前占据锁的线程，如果是，则再次成功获取。
> * **锁的最终释放**：线程重复 n 次获取了锁，随后在第 n 次释放该锁后，其他线程能够获取到该锁。锁的最终释放要求锁对于获取进行计数自增，计数表示当前锁被重复获取的次数，而锁被释放时，计数自减，当计数等于 0 时表示锁已经成功释放。

下面，我们来分析一下代码来看看可重入是怎么实现的。

- [ ] #TODO 这里也是jdk8，之后升级一下。➕ 2024-02-27 🔽 

首先，我们从tryLock()入手。毕竟无论是公平还是非公平，最终都是要调用这个方法才**可能**获得锁：

```kotlin
public boolean tryLock() {
	return sync.nonfairTryAcquire(1);
}
```

我们发现，是nonfair的。为啥公平的锁在尝试获得的时候也会调用nonFair的呢？我们看看注释：

> Even when this lock has been set to use a fair ordering policy, a call to `tryLock()` *will* immediately acquire the lock if it is available, whether or not other threads are currently waiting for the lock. This barging behavior can be useful in certain circumstances, <u>even though it breaks fairness</u>. If you want to honor the fairness setting for this lock, then use `tryLock(0, TimeUnit.SECONDS)` which is almost equivalent (it also detects interruption).

^996bb3

也就是说，公平锁在尝试获得锁的时候也是不公平的。如果真想公平，那就用两个参数的版本。

- [/] #TODO 为啥允许公平锁打破公平？ ⏫ ➕ 2024-02-27 🛫 2024-02-29 ^4b9f26

> [!todo] 为啥允许公平锁打破公平
> * #date 2024-02-29 [[#^7e0552]]

现在看看nonfairTryAcquire()的实现：

```java
final boolean nonfairTryAcquire(int acquires) {
	final Thread current = Thread.currentThread();
	int c = getState();
	if (c == 0) {
		if (compareAndSetState(0, acquires)) {
			setExclusiveOwnerThread(current);
			return true;
		}
	}
	else if (current == getExclusiveOwnerThread()) {
		int nextc = c + acquires;
		if (nextc < 0) // overflow
			throw new Error("Maximum lock count exceeded");
		setState(nextc);
		return true;
	}
	return false;
}
```

可以发现，就是在原来[[Study Log/java_kotlin_study/concurrency_art/5_2_aqs#^mutextryacquire|Mutex版本]]的基础上增加了当前线程的判断（else分支）。这样当一个线程重复获得同一个锁的时候，就会走到这里，并增加锁的计数（用state表示）。另一点是，由于走到else分支的时候，其它的线程不可能获得锁，所以这里使用的是`setState()`而不是`compareAndSetState()`。

既然如此，当释放锁的时候肯定也不是简单的赋值，而是做减法： ^reentrantrelease

```java
protected final boolean tryRelease(int releases) {
	int c = getState() - releases;
	if (Thread.currentThread() != getExclusiveOwnerThread())
		throw new IllegalMonitorStateException();
	boolean free = false;
	if (c == 0) {
		free = true;
		setExclusiveOwnerThread(null);
	}
	setState(c);
	return free;
}
```

首先，这个方法定义在FairSync和NonfairSync的公共父类Sync中，并且是final。代表公平锁和非公平锁的释放操作都 走的是这里。

剩下的，就是将当前的state减去传进来的参数releases。最后的结果如果是0，那么就释放成功了。如果不是，那么就还是我的锁。这里因为不可能有其它线程来抢，所以也不需要CAS。

### 5.3.2 公平 & 非公平

在继续之前，我觉得有必要对ReentrantLock()的结构来一张图。不然绕起来非常乱：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-02-27 14.44.54.excalidraw.svg]]

通过这张图我们发现，就像我们之前说的那样，tryLock()只会走非公平的实现nonfairTryAcquire()。**想要调用到公平锁的tryAcquire()**，只能用lock()。而[[Study Log/java_kotlin_study/concurrency_art/5_2_aqs#^fb346a|5_2_aqs]]我们说过，公平锁在发现没有竞争的时候要进去排队。但是，公平锁的tryLock()调用的居然是非公平的实现。理论上，如果是公平锁的tryLock()，应该是只要发现有人在排队，或者CAS失败就返回false。但是不知道为什么jdk8没提供这样的实现，而是打破了这个规则，转而让用另一个版本的tryLock()来做这件事。

- [/] #TODO 看看jdk17有没有修改这段逻辑，并且说明为啥不像我说的这样做。 ⏫ ➕ 2024-02-27 🛫 2024-02-28

> [!todo] 看看jdk17有没有修改这段逻辑，并且说明为啥不像我说的这样做。
> * #date 2024-02-28 目前看jdk17的源码注释是没变的，还是[[#^996bb3|原来]]的。

现在来看看具体是咋实现的，很简单：

```java
protected final boolean tryAcquire(int acquires) {
	final Thread current = Thread.currentThread();
	int c = getState();
	if (c == 0) {
		if (!hasQueuedPredecessors() &&
			compareAndSetState(0, acquires)) {
			setExclusiveOwnerThread(current);
			return true;
		}
	}
	else if (current == getExclusiveOwnerThread()) {
		int nextc = c + acquires;
		if (nextc < 0)
			throw new Error("Maximum lock count exceeded");
		setState(nextc);
		return true;
	}
	return false;
}
```

我们发现，这里的else分支和非公平是一样的。原因是无论是公平还是非公平，在一个线程已经获得了锁的状态下，其它线程都是没资格抢的，也就不存在公平非公平的问题了。

而在if分支中，如果这个锁还没被任何一个线程获得，那么就是在非公平的判断条件基础上再加了一个`!hasQueuedPredecessors()`。也就是说，如果我前面还有人排着，那我也不能排队，返回false。 ^d7044c

由于只有lock()会调用到这里，返回false的结果就是我要去FIFO队列中排着。

我们来写一个例子来验证一下。让一个线程先获取锁，然后打印一下自己，也就是获取锁的线程；然后再看看当前队列里有谁在排着：

```kotlin
private fun lockAndLook() {
	lock.lock()
	try {
		println("locked by: ${currentThread().name}, wait queue: ${lock.queuedThreads.map { it.name }}")
	} finally {
		lock.unlock()
	}
}
```

然而，getQueuedThreads()在ReentrantLock中是protected，所以我们要自己重写一个，把它public出来：

```kotlin
class ReentrantLock2(fair: Boolean) : ReentrantLock(fair) {
	public override fun getQueuedThreads(): MutableCollection<Thread> {
		return super.getQueuedThreads().reversed().toMutableList()
	}
}
```

> 这里反转了一下，反转之后队列的第一个元素就是最早进入的元素，也就是FIFO队头。

将lockAndLook()包装到一个线程中，然后启动5个线程：

```kotlin
private fun testLock(lock: ReentrantLock2) {
	repeat(5) {
		val job = Job(lock, it)
		job.start()
	}
}
```

这里每个线程start之后重复获得三次锁：

```kotlin
override fun run() {
	repeat(3) {
		lockAndLook()
	}
}
```

这样我们就可以观察在FIFO队列不断有人进进出出的时候，会发生什么。结果如下：

```shell
locked by: 0, wait queue: []
locked by: 1, wait queue: [2, 4, 3, 0]
locked by: 2, wait queue: [4, 3, 0, 1]
locked by: 4, wait queue: [3, 0, 1, 2]
locked by: 3, wait queue: [0, 1, 2, 4]
locked by: 0, wait queue: [1, 2, 4, 3]
locked by: 1, wait queue: [2, 4, 3, 0]
locked by: 2, wait queue: [4, 3, 0, 1]
locked by: 4, wait queue: [3, 0, 1, 2]
locked by: 3, wait queue: [0, 1, 2, 4]
locked by: 0, wait queue: [1, 2, 4, 3]
locked by: 1, wait queue: [2, 4, 3]
locked by: 2, wait queue: [4, 3]
locked by: 4, wait queue: [3]
locked by: 3, wait queue: []
```

可以发现，**每次抢到锁的线程都是队列里的第一个线程**。这也就证明了这个锁的公平性。我们用同样的方式测试一下非公平锁：

```shell
locked by: 0, wait queue: []
locked by: 0, wait queue: [1, 2, 3, 4]
locked by: 0, wait queue: [1, 2, 3, 4]
locked by: 1, wait queue: [2, 3, 4]
locked by: 1, wait queue: [2, 3, 4]
locked by: 1, wait queue: [2, 3, 4]
locked by: 2, wait queue: [3, 4]
locked by: 2, wait queue: [3, 4]
locked by: 2, wait queue: [3, 4]
locked by: 3, wait queue: [4]
locked by: 3, wait queue: [4]
locked by: 3, wait queue: [4]
locked by: 4, wait queue: []
locked by: 4, wait queue: []
locked by: 4, wait queue: []
```

可以发现，同一个线程很有可能会多次获得锁。当一个线程不再获取（已经获取了3次）之后FIFO队头的线程才进行获取。这样的原因很大程度上是因为，如果线程获取次数没满三次，那么它刚刚释放了锁之后就可以立刻继续和FIFO的老二去抢。<u>老二的反应会慢一些</u>，所以大多数情况下都是原来的老大再次获得锁，新老大还是它。这样的设计会出现一些问题，比如如果一个线程长时间排在最后面总也抢不到（那个占有锁的线程一直反复获取），就会被饿死。

- [ ] #TODO 为什么老二慢一些？ ➕ 2024-02-29 🔺 

既然如此，为什么ReentrantLock的默认实现是非公平的？主要还是为了性能考虑。我们观察两种锁的输出结果，发现非公平锁在这个过程中一共切换了14次线程，而公平锁只切换了4次。也就是说，非公平锁切换线程的次数少，所以系统的资源调度就更少，执行速度会更快。当然总耗时也会更短。公平锁由于每个排队的线程都**可能**不一样，所以会涉及到频繁的上下文切换。 ^e43b0b

- [ ] #TODO FIFO队列里排队的不同节点，有可能是同一个线程吗？➕ 2024-02-29 🔼 

> [!note]
> 我感觉，上面说的也是[[#^4b9f26]]的一部分原因，性能。

^7e0552

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