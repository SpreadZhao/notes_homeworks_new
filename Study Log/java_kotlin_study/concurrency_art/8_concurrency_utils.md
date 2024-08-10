---
title: 8 Java 中的并发工具类
chapter: "8"
order: "8"
chapter_root: true
---

# 8 Java 中的并发工具类

## 8.1 CountDownLatch

看代码：

```kotlin
fun main() {
    val parser1 = Thread {  }
    val parser2 = Thread { println("parser2 finish") }
    /* ... */
    parser1.start()
    parser2.start()
    parser1.join()
    parser2.join()
    println("all parsers finished")
}
```

这里的parser可以是解析任何东西，反正有若干个。我们要等所有线程都结束之后再继续程序。最好想到的就是用join去等待所有的线程结束。我们可以看看join的实现：

```java
while (isAlive()) {
	wait(0);
}
```

> [!attention]
> jdk17就是这样。看join那个带参数的实现。

在join的注释里（带参数版本）也能看到，当线程结束的时候，notifyAll会被调用，所以这里的wait就会退出，然后调用join的线程就能继续了。

CountDownLatch也可以实现join的功能，而且更强大。

Latch是闩的意思，也就是能卡住，不让你进门。卡住的是谁？可以是一个线程，也可以是很多。CountDownLatch的功能非常强大，不过我们先用一个最简单的例子说明：

```kotlin
val c = CountDownLatch(2)
fun main() {
    thread {
        println(1)
        c.countDown()
        println(2)
        c.countDown()
    }
    c.await()
    println(3)
}
```

这段代码的输出永远是

```
1
2
3
```

我们看到主线程调用了await，所以会被卡住，3输出不了。那么什么时候3可以输出呢？也就是这个闩什么时候才解开呢？答案就是c什么时候变成0。一开始的初始值是2，所以调用了两次countDown之后，主线程才从await处返回。从这个例子我们能看到，CountDownLatch在join的基础上加了很多灵活的东西，它可以等待不同线程完成任务，也可以等待**一个线程完成几段任务**。

接下来看一个更复杂的例子：

```
do something before start workers
do my own things, I don't care whether workers finished or not!
worker 3 do work!
worker 5 do work!
worker 2 do work!
worker 1 do work!
worker 4 do work!
all workers finished!
```

我们想实现上面的效果。也就是：

- 有一个分发任务的，和若干个干活儿的；
- 分发任务的线程在干活儿的开始干活儿之前，要做一些准备工作；
- 当干活儿的开始干活儿之后，分发的那位可以做一些其它的事情；
- 所有干活儿的任务都做完之后，分发的线程做收尾工作；
- 我们不关心干活儿的线程执行任务的顺序。

显然，这里有两个卡点：

1. 所有干活儿的线程需要等分发者准备完；
2. 分发者需要等所有干活儿的线程干完活儿。

因此这里有两个CountDownLatch。那么各是多少呢？第一个场景，所有人都等一个人准备完，因此应该是1，等准备完之后变成0就好了；第二个场景，一个人要等所有人都干完。所以应该是干活儿的线程的个数n：

```kotlin
val startSignal = CountDownLatch(1)  // 等着开始
val doneSignal = CountDownLatch(n)   // 等着结束
```

如何实现第一个场景？显然，干活儿的线程在开始干活儿之后，不能直接干活儿，要**先等**。那显然就是要调用`startSignal.await()`：

```kotlin
override fun run() {
	try {
		startSignal.await()  // 先等分发者准备
		/* 开始工作 */
	} catch (_: InterruptedException) {}
}
```

这样，分发者的逻辑就好办了。先启动所有线程，这样它们就都会等自己准备。之后执行准备的逻辑，然后再down一下就ok了：

```kotlin
fun driver(n: Int) {
    val startSignal = CountDownLatch(1)
    val doneSignal = CountDownLatch(n)
    /* 启动所有worker */
    ... ...
    println("do something before start workers")
    Thread.sleep(1000)  // 我甚至可以皮一下，等个1s，反正worker启动不了。
    startSignal.countDown()
}
```

然后就是第二个场景了。这里显然就是分发者要等。那么在这后面调用await就行了：

```kotlin
fun driver(n: Int) {
    val startSignal = CountDownLatch(1)
    val doneSignal = CountDownLatch(n)
    /* 启动所有worker */
    ... ...
    println("do something before start workers")
    Thread.sleep(1000)  // 我甚至可以皮一下，等个1s，反正worker启动不了。
    startSignal.countDown()
    doneSignal.await()  // 等所有worker结束
    println("all workers finished!")  // 结束之后的收尾
}
```

await会阻塞主线程，等待worker结束。因为初值是n，所以要等n个worker都down一下才行。那worker啥时候down呢？当然是退出的时候down啦：

```kotlin
override fun run() {
	try {
		startSignal.await()
		doWork()
		doneSignal.countDown()
	} catch (_: InterruptedException) {}
}
```

这样基本上就写完了。但是还差最后一个小问题，上面的第三点：**当干活儿的开始干活儿之后，分发的那位可以做一些其它的事情**。这里的其它事情，其实是不关心worker是否都结束的。所以理论上加在哪儿都行。但是为了效率着想，如果这个事情不是很耗时，可以放在doneSignal的await前面（[[#^2c25c8|其实，即使很耗时也应该放在前面]]）：

```kotlin
fun driver(n: Int) {
    val startSignal = CountDownLatch(1)
    val doneSignal = CountDownLatch(n)
    /* 启动所有worker */
    ... ...
    println("do something before start workers")
    Thread.sleep(1000)  // 我甚至可以皮一下，等个1s，反正worker启动不了。
    startSignal.countDown() // 开始worker
    // 无关的事情
    println("do my own things, I don't care whether workers finished or not!")
    doneSignal.await()  // 等所有worker结束
    println("all workers finished!")  // 结束之后的收尾
}
```

那么这里有个问题，如果这个无关的事情很耗时，会怎样？如果这个东西耗时到等它结束的时候，worker早都已经结束了。那么这个时候再执行`doneSignal.await()`就会立刻返回，因为此时已经是0了。

这就是我们所说的无关。为了看到差别，我们可以把sleep放到start的down和这个无关事情的中间，比如：

```kotlin
fun driver(n: Int) {
    val startSignal = CountDownLatch(1)
    val doneSignal = CountDownLatch(n)
    /* 启动所有worker */
    ... ...
    println("do something before start workers")
    startSignal.countDown() // 开始worker
    // 耗时1s多的无关的事情
    Thread.sleep(1000)
    println("do my own things, I don't care whether workers finished or not!")
    doneSignal.await()  // 等所有worker结束
    println("all workers finished!")  // 结束之后的收尾
}
```

这样，等我再去等的时候，其实就不用等了。这样的效率就会高一些。 ^2c25c8

---

再看一个例子。有时候，我们等的可能不是明确的多个线程，而是某些任务的片段。我只希望等这些片段都结束。至于这些片段是谁做的，我不关心，也有可能是N个线程，或者也有可能是1个线程，甚至是一个线程池。

这种情况其实和上一个例子差不多，唯一的区别就是down不一定是由谁做的了。只写在Runnable里。这种情况我就直接上代码了：

```kotlin
class WorkerRunnable(
    private val num: Int,
    private val doneSignal: CountDownLatch
) : Runnable {
    override fun run() {
        try {
            doWork()
            doneSignal.countDown()
        } catch (_: InterruptedException) {}
    }

    private fun doWork() {
        println("work $num is being done!")
    }
}

fun driver2(n: Int) {
    val doneSignal = CountDownLatch(n)
    val executor = Executors.newSingleThreadExecutor()
    for (i in 0 until n) {
        executor.execute(WorkerRunnable(i + 1, doneSignal))
    }
    doneSignal.await()
    println("all works are done")
    executor.shutdown()
}
```

这个例子其实很恰当。因为`executor.shutdown`就是应该在所有任务都完成之后再调用，从而关闭线程池，让程序正常退出。

如果我们要用join写这个例子，好像还真没法写。因为线程池里的线程是我们要手动关闭的，因此在这之前它根本不会notify，那join也就没作用了。

- [ ] #TODO tasktodo1722007420163 看看西瓜是怎么用CountDownLatch的。 ➕ 2024-07-26 🔺 🆔 uam4hu

## 8.2 CyclicBarrier

CountDownLatch是一个闩，我们前面已经描述地很形象了。那么这个Barrier是什么？在OS中我们学到过，[[Lecture Notes/Operating System/os#^e7f345|Barrier]]是为了让多个人到达同一种状态的。而CyclicBarrier的目的也是这样：多个线程会互相等，直到它们都到达了同一种状态。

其实CountDownLatch也可以做到这样的效果，比如刚才我们就让一个分发任务的线程等所有干活儿线程都结束之后，进行一些收尾工作。而CyclicBarrier对比Latch的优势是，它是Cyclic的，也就是可以重复利用。

> [!note] CountDownLatch和CyclicBarrier
> 这里补充一下我自己认为的他俩的使用区别。当然不保证准确。CountDownLatch是“一等多”的关系，由一个线程调用await去等待多个任务，或者多个线程去调用countDown直到到0；而CyclicBarrier是“多等多”的关系。更多的是一种互相等，这个团体中的每一个人在到达barrier之后都会等，等所有人都到达这个barrier之后再进行。

CyclibBarrier的构造可以传两个参数：

```java
/**
 * Creates a new {@code CyclicBarrier} that will trip when the
 * given number of parties (threads) are waiting upon it, and which
 * will execute the given barrier action when the barrier is tripped,
 * performed by the last thread entering the barrier.
 *
 * @param parties the number of threads that must invoke {@link #await}
 *        before the barrier is tripped
 * @param barrierAction the command to execute when the barrier is
 *        tripped, or {@code null} if there is no action
 * @throws IllegalArgumentException if {@code parties} is less than 1
 */
public CyclicBarrier(int parties, Runnable barrierAction) {
	if (parties <= 0) throw new IllegalArgumentException();
	this.parties = parties;
	this.count = parties;
	this.barrierCommand = barrierAction;
}
```

第一个是个int，也就是：有多少线程都到达barrier时，才能继续进行；第二个参数是一个trigger。也就是等这些线程都到达barrier时，会由最后一个到达barrier的线程去完成这个barrierAction。显然，这个action是用来收集一些其它线程工作信息的。

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-08-04 21.02.02.excalidraw.svg]]

在上图的情况下，4号就会执行这个action。

下面我们用一个例子来说明这个过程：4个线程，每个线程的工作是产生一个随机数。但是我要在4个线程都结束之后，由其中一个线程去算一下这4个随机数之和。

这个其实用CountDownLatch也能完成，并且也很合理。只不过通常是一个主线程和四个干活儿的线程。不过我现在的需求是：**主线程很忙的**，还要做其它的事情，所以**求和这种事情就还是让那4个线程做吧**！毕竟这本身就是你们的任务！

那么现在思考一下。首先是为啥要使用barrier：因为4个线程去生产随机数，生产完之后都要等待。只有都生产完了我才能去求和。所以，我们要让四个线程在生产完之后都用一个barrier给拦住。等4个线程都到达barrier之后，才能去执行求和的任务。所以：

```kotlin
// 这里的this先不用关心，之后会说明
private val c = CyclicBarrier(4, this)
private val executor = Executors.newFixedThreadPool(4)
```

然后就是生产的逻辑了。很简单，生产一个数字，然后等就行了。这里我们用ConcurrentHashMap来存这个数字：

```kotlin
fun produce() {
	repeat(4) {
		executor.execute {
			numbers[Thread.currentThread().name] = Random.nextInt(100)
			println("${Thread.currentThread().name}: ${numbers[Thread.currentThread().name]}")
			try {
				c.await()
			} catch (e: InterruptedException) {
				e.printStackTrace()
			}
			println("${Thread.currentThread().name} after barrier")
		}
	}
}
```

这样，如果我们只执行这个方法，4个线程在生产完数字之后都会await。当最后一个线程执行await时，由于等待线程已经是4个了，所以它们都会从await返回，继续执行下面的内容。结果如下：

```
pool-1-thread-3: 50
pool-1-thread-4: 99
pool-1-thread-1: 91
pool-1-thread-2: 14
pool-1-thread-3 after barrier
pool-1-thread-2 after barrier
pool-1-thread-1 after barrier
pool-1-thread-4 after barrier
```

当然，执行顺序也会不一样。另外这里程序其实是没中止的。因为我们并没有给线程池调用shutdown。那么现在还差什么？差求和。这里我们让最后一个线程进行求和工作，一个Runnable：

```kotlin
override fun run() {
	var result = 0
	for ((_, value) in numbers) {
		result += value
	}
	println("${Thread.currentThread().name}: final result: $result")
	executor.shutdown()
}
```

求和之后，顺手再把线程池给关掉。这样程序就完美中止了。当然，妥善的做法不应该在这里shutdown，而是在主线程中（线程池之外的线程）等待任务真正全部执行完再关闭。

执行结果如下：

```
pool-1-thread-1: 85
pool-1-thread-2: 75
pool-1-thread-3: 87
pool-1-thread-4: 52
pool-1-thread-2: final result: 299
pool-1-thread-2 after barrier
pool-1-thread-1 after barrier
pool-1-thread-4 after barrier
pool-1-thread-3 after barrier
```

现在你可能会产生一个问题：这个action不是最后一个到达barrier的线程做的吗？为什么从输出里看，4是最后一个到达的，但是这个action是2完成的？

没错，我也有这个疑问。但是我当时怀疑，是程序的输出欺骗了我们。因为从输出这个随机数，到在`await()`方法中真正因为barrier而等待，中间还有一些指令。我们不能保证OS在这个过程中不进行什么调度。所以**虽然4是最后一个输出随机数的，但不代表4是最后一个到达barrier的**。

为了弄清楚这个问题，我们其实只需要在action里面执行一下jstack就好了。经过验证，除了线程2是RUNNABLE状态，其它线程都是WAITING(parking)状态。

这里回忆一下之前我们说过的线程状态图：[[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-02-06 00.11.15.excalidraw.png]]。这样看来，这个Barrier其实底层还是LockSupport（为什么这么说？因为parking）。其实看看代码就能发现，其实里面用的还是ReentrantLock。

- [ ] #TODO tasktodo1722779013787 CountDownLatch, CyclicBarrier的内部实现要补上。 ➕ 2024-08-04 🔼 🆔 xfsp7l

## 8.3 Semaphore

老熟人了。比如初始值是10，那么就允许10个线程并发。每个线程在获取信号量之后会down一下，down了10次之后，就变成了0，此时就不能再有线程去down了。

还记得我们之前实现过的那个[[Study Log/java_kotlin_study/concurrency_art/5_2_aqs#5.2.3 实战 - TwinsLock|TwinsLock]]吗？其实这个就是一个初始值为2的信号量。它最多允许两个线程进行并发。

为了验证，我们直接上代码对比。下面是我们自己写的TwinsLock的核心内容：

```kotlin
override fun tryAcquireShared(acquired: Int): Int {
	while (true) {
		val curr = state
		val after = curr - acquired
		if (after < 0 || compareAndSetState(curr, after)) {
			return after
		}
	}
}
```

还记得吗？因为可以多个线程一起来，所以是shared类型。然后因为after是不可能小于0的，所以这里`after < 0`必须放在前面。最后是一个CAS，如果CAS不成功那还得再来一遍。这样退出循环的时候，要么CAS成功了，要么因为after已经是负数，表示坑位已经满了。

下面是Semaphore源码中的tryAcquireShared。不能说一摸一样，只能说没啥区别：

```java
final int nonfairTryAcquireShared(int acquires) {
	for (;;) {
		int available = getState();
		int remaining = available - acquires;
		if (remaining < 0 ||
			compareAndSetState(available, remaining))
			return remaining;
	}
}
```

所以Semaphore的东西就不多说了。

## 8.4 Exchanger

最后是Exchanger。看名字也知道是用来交换东西的。两个线程都到达一个交换点之后，可以互相传送数据。这个东西就不多说了。看看代码吧。

- [ ] #TODO tasktodo1722781482971 这一章里的东西之后都补上实现。 ➕ 2024-08-04 🔼 🆔 0y8h2f