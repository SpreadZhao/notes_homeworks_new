---
title: 4.2 启动和终止线程
chapter: "4"
order: "2"
---

## 4.2 启动和终止线程

### 4.2.1 构造线程

从Thread的构造方法入手。这里就不往上贴了，只是简单说点。在构造一个Thread的时候，会有这些比较重要的事情：

* 设置线程的名称；
* 设置新线程的父线程为当前线程。比如从main线程new出一个Thread，那么这个Thread的parent就是main线程；
* 从父亲线程继承内容：
	* 是否是守护线程；
	* 线程优先级；
	* ContextClassLoader；
	* ThreadLocal

### 4.2.2 启动线程

调用start()方法启动线程。它的含义是：当前线程（即 parent 线程）同步告知 Java 虚拟机，只要线程规划器空闲，应立即启动调用 start()方法的线程。

### 4.2.3 中断线程

其它线程可以调用`a.interrupt()`来中断a线程。但是中断并不意味着终止，中断可以理解为当前线程给a线程打了个招呼，或者拍了拍它。具体有啥用？~~我也不知道~~。

- [/] #TODO 到底有啥用？我记得写过一个输出日志的那个线程。可以拿出来看看。 🔼 🛫 2024-02-21 ^219d41

> [!todo] 到底有啥用？我记得写过一个输出日志的那个线程。可以拿出来看看。
> * #date 2024-02-21 不能光拿那个输出日志就完了。什么AQS啥的里面很多都和这个有关系。本节中其实就已经给出了interrupt的一些作用了。

线程是否被中断有一个标志位`interrupted`。一个线程在刚启动的时候这个标志位是false。而如果被中断了，这个标志位就会变成true。所以下面的代码：

```kotlin
val th = Thread(...)
th.start()
println("before: ${th.isInterrupted}")
th.interrupt()
println("after: ${th.isInterrupted}")
```

会分别输出false和true。

但是，如果在调用`th.interrupt()`的时候，th处于休眠状态，那么th就会抛出InterruptedException异常。所以我们可以通过catch这个异常来处理被打断之后的操作。

> [!quote] 休眠状态？
> 具体的状态参考注释：
> 
> If this thread is blocked in an invocation of the wait(), wait(long), or wait(long, int) methods of the Object class, or of the join(), join(long), join(long, int), sleep(long), or sleep(long, int) methods of this class, then its interrupt status will be cleared and it will receive an InterruptedException.

> [!note]
> 如果这段看不懂，可以看看后面我的看法。

那么，我既然都抛出异常了，就证明我这个线程已经对中断做出了响应。<u>所以，我是不是可以重置一下状态了？</u>因此，在抛出InterruptedException之前，该线程的interrupted标志位会被清除，也就是置回false。

我们通过一个例子来证明这件事。有两个线程。一个一直在睡大觉；一个一直在空转：

```kotlin
val sleepThread = Thread(ThreadInterrupt.SleepRunner(), "SleepThread")  
val busyThread = Thread(ThreadInterrupt.BusyRunner(), "BusyThread")
```

其中睡大觉的线程会不停睡眠10s种，并catch被中断的InterruptedException：

```kotlin
class SleepRunner : Runnable {  
    override fun run() {  
        while (true) {  
            try {  
                TimeUnit.SECONDS.sleep(10)  
            } catch (e: InterruptedException) {  
                e.printStackTrace()  
            }  
        }  
    }  
}
```

而一直忙的线程就是在空转：

```kotlin
class BusyRunner : Runnable {  
    override fun run() {  
        while (true) {}  
    }  
}
```

如果我们打断了这两个线程：

```kotlin
sleepThread.interrupt()  
busyThread.interrupt()
```

那么标志位会分别是什么呢？

```kotlin
println("SleepThread interrupted is ${sleepThread.isInterrupted}")  
println("BusyThread interrupted is ${busyThread.isInterrupted}")
```

整个测试程序如下：

```kotlin
class ThreadInterrupt {  
    class SleepRunner : Runnable {  
        override fun run() {  
            while (true) {  
                try {  
                    TimeUnit.SECONDS.sleep(10)  
                } catch (e: InterruptedException) {  
                    e.printStackTrace()  
                }  
            }  
        }  
    }  
  
    class BusyRunner : Runnable {  
        override fun run() {  
            while (true) {}  
        }  
    }  
}  
  
fun main() {  
    val sleepThread = Thread(ThreadInterrupt.SleepRunner(), "SleepThread")  
    val busyThread = Thread(ThreadInterrupt.BusyRunner(), "BusyThread")  
    sleepThread.start()  
    busyThread.start()  

	// 让两个线程充分运行
    TimeUnit.SECONDS.sleep(5)  
    sleepThread.interrupt()  
    busyThread.interrupt()  
    println("SleepThread interrupted is ${sleepThread.isInterrupted}")  
    println("BusyThread interrupted is ${busyThread.isInterrupted}")  

	// 防止两个线程立刻退出
    TimeUnit.SECONDS.sleep(2)  
}  
```

> 书中这俩线程都设置为Daemon，所以有最后的sleep。不过我不知道为啥这么干。

我们来分析一下。这个一直在睡大觉的线程，因为在interrupt的时候大概率是在sleep，所以一旦被中断，首先当然是把标志位置为true，然后就会抛出InterruptedException，并在这之前将标志位再置回false；而一直在忙的线程，如果被interrupt了，那么只会将标志位置为true，其它什么也不管，还是忙着自己空转。所以，最后的输出应该是：

```shell
SleepThread interrupted is false
BusyThread interrupted is true
java.lang.InterruptedException: sleep interrupted
	at java.base/java.lang.Thread.sleep(Native Method)
	at java.base/java.lang.Thread.sleep(Thread.java:346)
	at java.base/java.util.concurrent.TimeUnit.sleep(TimeUnit.java:446)
	at concurrency.thread.ThreadInterrupt$SleepRunner.run(ThreadInterrupt.kt:11)
	at java.base/java.lang.Thread.run(Thread.java:842)
```

最后。我想谈一谈自己的看法，为什么要这么设计。如果一个线程当前正在忙着自己的事情，那么如果被别人打扰，应该去做别人的事情吗？我觉得应该把响应权利交给目标线程自己。因为如果去做别人的事情，效率有可能会因为线程切换任务而降低。所以，<u>如果一个繁忙的线程接收到了interrupt，最正确的做法就是仅仅记住我曾经被interrupt了</u>。这也是interrupted为true的原因；而如果是一个空闲的线程接收到了interrupt，那么是不是你该干点儿活儿了？不然要你干嘛？你出生之后就在这儿躺着啥也不干？所以，之所以抛出异常，就是希望<u>这个闲下来的线程正确对待这次interrupt，找点事情干</u>。而正因为这个线程找到了干的事情，也就意味着发出这个interrupt的一方的请求被【满足】了。从而这个interrupted标志位可以复位，以便接受新的interrupt请求。

> [!warning]
> 但是，在我的测试中，有很小的概率两个值都为true。也就是被睡眠的线程被interrupt之后，标志位并没有置回false。但是却也抛出了InterruptedException。

- [ ] #TODO 这个东西很奇怪。 🔼

### 4.2.4 Deprecated suspend(), resume() and stop()

这三个方法在Java17里已经是属于调用就报错了：

```java
@Deprecated(since="1.2", forRemoval=true)  
public final void suspend() {  
    checkAccess();  
    suspend0();  
}
```

官方的删除公告，以及该如何替代它们：[Java Thread Primitive Deprecation (oracle.com)](https://docs.oracle.com/javase/8/docs/technotes/guides/concurrency/threadPrimitiveDeprecation.html)

### 4.2.5 安全地终止线程

这个比较重要。如何优雅地结束一个线程？答案是要么通过interrupt，要么自己写一个标记位：

```kotlin
class Runner : Runnable {  
  
    private var i = 0L  
  
    @Volatile  
    private var on = true  
  
    override fun run() {  
        while (on && !Thread.currentThread().isInterrupted) {  
            i++  
        }  
        println("i = $i")  
    }  
  
    fun cancel() {  
        on = false  
    }  
}
```

这样，当这个线程跑起来之后，我们调用`interrupt()`之后，isInterrupted就是true。这样while循环就会中止；或者，我们可以调用`cancel()`，这样on就变成了false，while循环也会终止。

这两种方法都可以终止线程的运行，并可以自主选择在线程结束之后做一些收尾工作。优雅。下面是测试程序：

```kotlin
fun main() {  
    val one = ElegantlyKillThread.Runner()  
    var countThread = Thread(one, "CountThread")  
    countThread.start()  
    TimeUnit.SECONDS.sleep(1)  
    countThread.interrupt()  
    val two = ElegantlyKillThread.Runner()  
    countThread = Thread(two, "CountThread")  
    countThread.start()  
    TimeUnit.SECONDS.sleep(1)  
    two.cancel()  
}
```







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