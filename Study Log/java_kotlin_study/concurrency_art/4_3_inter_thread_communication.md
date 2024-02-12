---
title: 4.3 线程间通信
order: "3"
chapter: "4"
---

## 4.3 线程间通信

很多方式都可以实现线程之间通信。比如在之前我们介绍过的volatile还有synchronized关键字。这些都能保证我做过的一些修改是对其它线程立即可见的。除了这些，其它的机制比如wait/notify机制还有管道等等也都可以。

### 4.3.1 volatile & synchronized

上一节，我们介绍的那个中止线程的例子：[[Study Log/java_kotlin_study/concurrency_art/4_2_thread_life#4.2.5 安全地终止线程|4_2_thread_life]]。里面的变量`on`就是volatile的变量。它能够保证，我写入的这个值能够立刻被其他线程看到。还有[[Study Log/java_kotlin_study/concurrency_art/3_4_volatile_mm_semantics#^d00fb6|3_4_volatile_mm_semantics]]里面我们补充的例子，也都是这样的道理。

然后是synchronized。之前我们已经介绍过了。这里给一个例子：

```java
public class SynchronizedExample2 {
    public static void main(String[] args) {
        synchronized (SynchronizedExample2.class) {

        }
        m();
    }

    public static synchronized void m() {

    }
}
```

编译完成后，执行

```shell
javap -v SynchronizedExample2.class
```

会得到如下输出：

```shell
  #16 = Utf8               SourceFile
  #17 = Utf8               SynchronizedExample2.java
  #18 = NameAndType        #5:#6          // "<init>":()V
  #19 = Utf8               concurrency/itc/SynchronizedExample2
  #20 = NameAndType        #15:#6         // m:()V
  #21 = Utf8               java/lang/Object
  #22 = Utf8               [Ljava/lang/String;
  #23 = Utf8               java/lang/Throwable
{
  public concurrency.itc.SynchronizedExample2();
    descriptor: ()V
    flags: ACC_PUBLIC
    Code:
      stack=1, locals=1, args_size=1
         0: aload_0
         1: invokespecial #1                  // Method java/lang/Object."<init>":()V
         4: return
      LineNumberTable:
        line 3: 0

  public static void main(java.lang.String[]);
    descriptor: ([Ljava/lang/String;)V
    flags: ACC_PUBLIC, ACC_STATIC
    Code:
      stack=2, locals=3, args_size=1
         0: ldc           #2                  // class concurrency/itc/SynchronizedExample2
         2: dup
         3: astore_1
         4: monitorenter                      # synchronized的入口位置
         5: aload_1
         6: monitorexit
         7: goto          15
        10: astore_2
        11: aload_1
        12: monitorexit
        13: aload_2
        14: athrow
        15: invokestatic  #3                  // Method m:()V
        18: return
      Exception table:
         from    to  target type
             5     7    10   any
            10    13    10   any
      LineNumberTable:
        line 5: 0
        line 7: 5
        line 8: 15
        line 9: 18
      StackMapTable: number_of_entries = 2
        frame_type = 255 /* full_frame */
          offset_delta = 10
          locals = [ class "[Ljava/lang/String;", class java/lang/Object ]
          stack = [ class java/lang/Throwable ]
        frame_type = 250 /* chop */
          offset_delta = 4

  public static synchronized void m();
    descriptor: ()V
    flags: ACC_PUBLIC, ACC_STATIC, ACC_SYNCHRONIZED    # ACC_SYNCHRONIZED代表synchronized方法
    Code:
      stack=0, locals=0, args_size=0
         0: return
      LineNumberTable:
        line 13: 0
}
SourceFile: "SynchronizedExample2.java"
```

可以看到，synchronized块是用`monitorenter`和`monitorexit`来表示的；而synchronized方法是用`ACC_SYNCHRONIZED`表示的。当然，这两种方式的最终结果也都是`monitorenter`和`monitorexit`。

> 任意一个对象都拥有自己的监视器，当这个对象由同步块或者这个对象的同步方法调用时，执行方法的线程必须先获取到该对象的监视器才能进入同步块或者同步方法，而没有获取到监视器（执行该方法）的线程将会被阻塞在同步块和同步方法的入口处，进入 BLOCKED 状态

monitor的等待同步机制如下图：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-02-12 21.07.53.excalidraw.png]]

一个线程在试图获取Monitor锁的时候，『可能』会经历如下过程：

1. 进入synchronized块，调用`monitorenter`，尝试获取Monitor锁；
2. 因为其它线程已经获得了Monitor锁，所以获取失败了。此时进入<mark class="square-solid-yellow">同步队列</mark>（Synchronized Queue），状态变为**BLOCKED**；
3. 当访问Object的前驱（获得了锁的线程）释放了锁，这个**BLOCKED**的线程被唤醒，并重新尝试获取锁进入；
4. 成功获得了Monitor锁，执行同步代码；
5. 执行完毕，释放了锁，并通知<mark class="square-solid-yellow">同步队列</mark>中剩下的人。

### 4.3.2 Wait & Notify

之前我写过一个例子：[[Study Log/java_kotlin_study/java_kotlin_study_diary/lock_in_java|lock_in_java]]。学习完本节之后，可以再回顾一下。

书上给了一个轮询去查询的例子。然后说这种轮询的方式属于忙等待，浪费效率，从而引出Wait \& Notify机制。其实，这种情况我在介绍操作系统的时候就已经说过了：[[Lecture Notes/Operating System/os#3.3 How to avoid race conditions?|os]]。只不过当时说的是进程之间的。

> 书上给的，轮询的具体的缺点如下：
> 
> 1. 难以确保及时性。在睡眠时，基本不消耗处理器资源，但是如果睡得过久，就不能及时发现条件已经变化，也就是及时性难以保证。
> 2. 难以降低开销。如果降低睡眠的时间，比如休眠 1 毫秒，这样消费者能更加迅速地发现条件变化，但是却可能消耗更多的处理器资源，造成了无端的浪费。

与wait \& notify有关的方法定义在Object中，所有Java对象都具备：

|     方法名称      | 描述                                                                                                                         |
|:-----------------:| ---------------------------------------------------------------------------------------------------------------------------- |
|    `notify()`     | 通知一个在对象上等待的线程，使其从`wait()`方法**返回**，而返回的前提是**该线程获取到了对象的锁**。                           |
|   `notifyAll()`   | 通知所有等待在该对象上的线程。                                                                                               |
|     `wait()`      | 调用该方法的线程进入**WAITING**状态，只有等待另外线程的通知或被中断才会返回。需要注意， 调用`wait()`方法后，会释放对象的锁。 |
|   `wait(long)`    | 超时等待一段时间。这里的参数时间是毫秒，也就是等待长达n毫秒，如果没有通知就超时返回。                                        |
| `wait(long, int)` | 对于超时时间更细粒度的控制，可以达到纳秒。                                                                                   |

```ad-note
title: PS

线程的状态：[[Study Log/java_kotlin_study/concurrency_art/4_1_thread_basic#4.1.2 线程的状态|4_1_thread_basic]]
```

我们将演示下面的例子，来说明这些方法的功能： ^f936d3

1. 线程waitThread获取了锁lock，并在获取锁之后**不断**执行wait。这会导致waitThread进入WATIING状态并**释放lock**；
2. 随后线程notifyThead也获取了lock，并获取成功。因为waitThread由于wait已经释放了lock。之后，它会通知waitThread可以获取lock，同时**不需要再不断**执行wait了；
3. 但是由于此时notifyThread还霸占着lock，所以waitThread并不会从wait返回；
4. 之后，notifyThread会短暂释放lock并快速再次获取lock。在短暂释放之后，waitThread就有机会去抢lock了。但是，由于notifyThread又会快速重新获取lock，所以此时存在竞争：
	1. 如果notifyThread重新获取又成功了，那么此时waitThread还是无法返回。只有等notifyThread再次释放lock之后才能获取；
	2. 如果waitThread抢到了lock，那么由于2中notifyThread通知我不要再不断执行wait了，我将会不再等待，继续进行下去；
5. 根据4.1和4.2，也会有两种结局： 
	1. 如果4.1发生了，那么notifyThread再次释放lock之后，waitThread才能重新抢到lock，执行4.2中的内容；
	2. 如果4.2发生了，那么notifyThread会等到waitThread释放锁之后执行4.1中再次获得lock的行为。

首先，是一些标志位和工具方法：

```kotlin
companion object {
	@JvmField
	var needWait = true

	@JvmField
	var lock = Object()

	@JvmStatic
	fun getDate(): String {
		return SimpleDateFormat("HH:mm:ss").format(Date())
	}

	@JvmStatic
	fun log(msg: String) {
		println("${Thread.currentThread()} $msg ${getDate()}")
	}
}
```

然后是等待线程waitThread。内容如下：

1. 获取lock；
2. 只要needWait，就不停走循环。每次循环进行一次wait；
3. 循环退出之后，继续执行剩下的工作。

```kotlin
class Wait : Runnable {  
    override fun run() {  
        synchronized(lock) {                                // 1
            while (needWait) {                             // 2
                try {  
                    log("need wait. wa @")  
                    lock.wait()  
                } catch (_: InterruptedException) {  
  
                }  
            }  
            log("running @")                                // 3
        }  
    }  
}
```

通知线程notifyThread的内容如下：

1. 获取lock；
2. 在lock中，通知waitThread，并needWait置为false；
3. 在释放锁之前先睡5s。这是为了展示，notifyThread不释放锁，waitThread就无法从wait返回；
4. 释放锁之后，再次尝试获取lock。

```kotlin
class Notify : Runnable {
	override fun run() {
		synchronized(lock) {                          // 1
			log("hold lock. notify @")
			lock.notifyAll()
			needWait = false                         // 2
			SleepUtils.second(5)                     // 3
		}
		synchronized(lock) {                          // 4
			log("hold lock again. sleep @")
			SleepUtils.second(5)
		}
	}
}
```

测试程序如下：

```kotlin
fun main() {
    val waitThread = Thread(WaitNotify.Wait(), "WaitThread")
    waitThread.start()
    TimeUnit.SECONDS.sleep(1)
    val notifyThread = Thread(WaitNotify.Notify(), "NotifyThread")
    notifyThread.start()
}
```

样例输出：

```shell
Thread[WaitThread,5,main] need wait. wa @ 22:32:20
Thread[NotifyThread,5,main] hold lock. notify @ 22:32:21
Thread[NotifyThread,5,main] hold lock again. sleep @ 22:32:26
Thread[WaitThread,5,main] running @ 22:32:31
```

下面对这个结果中的问题作出解答。

- [?] *为什么前两行之间差了一秒钟？*
- [>] 我们在测试程序中间sleep了一秒钟。这也就导致了waitThread在wait之后释放了lock，又过了1s之后notifyThread才启动并获取lock。
- [?] *为什么2和3之间差了5秒钟？*
- [>] 因为notifyThread在第一次获取lock之后睡眠了5s。它没释放，waitThread和notifyThread都是没法继续下去的。
- [?] *最后两行输出可能交换吗？*
- [>] 可能。就是取决于[[#^f936d3|之前]]的4.1和4.2哪个先执行。

[[#^f936d3|之前]]的例子，图示如下：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-02-12 23.18.16.excalidraw.png]]

这里面标了数字的地方都是和前面对应的。唯一需要解释的就是**红色的两个4**。这里在描述的是waitThread在同步队列中和notifyThread抢锁的情况。如果同步队列中的waitThread抢到了，那么notifyThread要走Enter failure，也要进入到同步队列中；如果notifyThread抢到了，那么waitThread会走Enter failure。

```ad-summary
title: 最后，书上的总结。重要的点如下：

1. `wait()` `notify()` `notifyAll()`的使用必须要先synchronized；
2. 调用 `wait()`方法后，线程状态由 **RUNNING** 变为 **WAITING**，并将当前线程放置到对象的等待队列；
3. `notify()`或 `notifyAll()`方法调用后，等待线程依旧不会从`wait()`返回，需要调用`notify()`或`notifAll()`的线程**释放锁之后**，等待线程才有机会从 wait()返回；
4. `notify()`方法将等待队列中的一个等待线程从等待队列中移到同步队列中，而`notifyAll()`方法则是将等待队列中所有的线程全部移到同步队列，被移动的线程状态由 **WAITING** 变为 **BLOCKED**；
5. 从`wait()`方法返回的前提是获得了调用对象的锁。
```

```ad-note
我们可以发现，synchronized和wait \& notify的结合度是非常紧密的。实际上，它们俩在JVM中的实现本身也是在同一个类中去管理的。

见`jdk/src/hotspot/share/runtime/objectMonitor.hpp`。类的开头也有一堆注释说明这套机制的作用。讲解：[synchronized底层实现monitor详解 - 朱子威 - 博客园](https://www.cnblogs.com/minikobe/p/12123065.html)

里面的`_WaitSet`就是我们上面说的Wait Queue；`_EntryList`就是Synchronized Queue。
```

---

对于之前那个交替打印的例子：[[Study Log/java_kotlin_study/java_kotlin_study_diary/lock_in_java#1-100|lock_in_java]]，我写了一个更简单的版本：

```kotlin
class OneToHundred {

    companion object {
        private val lock = Object()
        private var currThread = 1
        private var currNum = 1
        private val Int.next: Int
            get() = if (this == 3) 1 else this + 1
        private var isRunning = true
    }

    private val th1 = Thread(PrintRunnable(1))
    private val th2 = Thread(PrintRunnable(2))
    private val th3 = Thread(PrintRunnable(3))

    fun start() {
        th1.start()
        th2.start()
        th3.start()
    }

    class PrintRunnable(private val thNum: Int) : Runnable {
        override fun run() {
            while (currNum <= 100) {
                synchronized(lock) {
                    while (currThread != thNum && isRunning) {
                        try {
                            lock.wait()
                        } catch (_: InterruptedException) {}
                    }
                    if (currNum == 100) {
                        isRunning = false
                    } else if (currNum > 100) {
                        return
                    }
                    println("th${thNum}: ${currNum++}")
                    lock.notifyAll()
                    currThread = currThread.next
                }
            }
        }
    }
}
```

这个例子中的任何一个地方去掉，都无法正常输出1-100或者无法正常结束。

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