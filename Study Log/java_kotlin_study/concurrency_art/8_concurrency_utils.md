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

这里的parser可以是解析任何东西，反正有若干个。我们要等所有线程都结束之后再继续程序。最号想到的就是用join去等待所有的线程结束。我们可以看看join的实现：

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

