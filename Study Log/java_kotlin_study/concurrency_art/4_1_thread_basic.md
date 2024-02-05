---
title: 4.1 线程基础
chapter: "4"
order: "1"
---

## 4.1 线程基础

我们先从一个main线程入手。看看Java/Kotlin的main方法，也就是main线程启动时，都有哪些线程信息：

```kotlin
fun main(args: Array<String>) {  
	// 获取 Java 线程管理 MXBean
    val threadMXBean = ManagementFactory.getThreadMXBean() 
    // 不需要获取同步的 monitor 和 synchronizer 信息，仅获取线程和线程堆栈信息 
    val threadInfos = threadMXBean.dumpAllThreads(false, false)  
    // 遍历线程信息，仅打印线程 ID 和线程名称信息
    for (info in threadInfos) {  
        println("[${info.threadId}]${info.threadName}")  
    }  
}
```

输出如下：

```shell
[1]main                     # main线程，用户程序入口
[2]Reference Handler        # 清楚Reference的线程
[3]Finalizer                # 调用对象finalize方法的线程
[4]Signal Dispatcher        # 分发处理发送给JVM信号的线程
[5]Attach Listener
[21]Common-Cleaner
[22]Monitor Ctrl-Break
[23]Notification Thread
```

### 4.1.1 线程优先级

接下来，我们看看线程优先级这个东西。在Java中有个接口可以给当前线程设置一个优先级：

```java
thread.setPriority(priority);
```

优先级为一个`[1, 10]`之间的整数。10表示优先级最高。而优先级越高的线程，就越容易被CPU选中去执行。或者说，**被分配到更多的时间片**。具体的调度策略还是要看CPU自己，可以参考我的OS笔记：[[Lecture Notes/Operating System/os#4. Scheduling|os#4. Scheduling]]。

我们大概写一个例子去看看这个事情。自己定义一个Runnable，这个Runnable里存着执行它线程的优先级：

```java
static class Job implements Runnable {  
  
    private int priority;  
    private long jobCount;  
  
    public Job(int priority) {  
        this.priority = priority;  
    }  
  
    @Override  
    public void run() {  
        while (notStart) {  
            Thread.yield();  
        }  
        while (notEnd) {  
            Thread.yield();  
            jobCount++;  
        }  
    }  
}
```

这里面jobCount没什么实际的意义，就是看一看这个while循环执行了多少次。为了更好地实现不同优先级的线程相互抢占，我们用notStart作为卡口。只有所有线程都创建完并且start，才将notStart置为false。这样所有的线程都是同时去运行下一个while循环并增加自己的jobCount。这样我们通过观察最后每个线程的jobCount值就能判断出线程被调度的频率。

两个volatile开关：

```java
private static volatile boolean notStart = true;  
private static volatile boolean notEnd = true;
```

main方法：

```java
public static void main(String[] args) throws Exception {  
    List<Job> jobs = new ArrayList<>();  
    for (int i = 0; i < 10; i++) {  
        int priority = i < 5 ? Thread.MIN_PRIORITY : Thread.MAX_PRIORITY;  
        Job job = new Job(priority);  
        jobs.add(job);  
        Thread thread = new Thread(job, "Thread" + i);  
        thread.setPriority(priority);  
        thread.start();  
    }  
    notStart = false;  
    TimeUnit.SECONDS.sleep(10);   
    notEnd = false;  
    for (Job job : jobs) {  
        System.out.println("Job Priority: " + job.priority + " Count: " + job.jobCount);  
    }  
}
```

我们让5个线程的优先级是1；另外5个线程的优先级是10。看看是不是优先级低的线程，它的jobCount就比优先级高的要少。结果如下：

```shell
Job Priority: 1 Count: 98718318
Job Priority: 1 Count: 98085067
Job Priority: 1 Count: 98041745
Job Priority: 1 Count: 95770658
Job Priority: 1 Count: 96616949
Job Priority: 10 Count: 95960804
Job Priority: 10 Count: 94849455
Job Priority: 10 Count: 96144513
Job Priority: 10 Count: 94685635
Job Priority: 10 Count: 100392407
```

emm，感觉没差多少？其实还真是。不过，并不是所有的CPU和所有的操作系统都这样，这玩意儿比较玄学。所以，像书上说的，**不能依赖Java线程优先级去写代码**。不过，和书上不同的是，书上说它的例子中线程的优先级没有设置成功，但是我的确成功了，但结果还是跟没设一样。

咋看设置成功与否？还是用一开始就介绍过的jstack命令。不过这一次，我们不能像死锁那样在其它地方做了，因为我们这个程序只有10s多的运行时间，来不及。

所以，我们直接将逻辑写到程序里。

还记得jstack咋用吗？

```shell
jstack [pid]
```

所以，第一步就是得到当前进程的pid：

```java
String pid = ManagementFactory.getRuntimeMXBean().getName().split("@")[0];
```

然后使用Process来运行它：

```java
// 别落了jstack后面的空格！
Process process = Runtime.getRuntime().exec("jstack " + pid);
```

之后，我们就能拿到这个结果的InputStream，那就想怎么读就怎么读了：

```java
is = process.getInputStream();  
reader = new BufferedReader(new InputStreamReader(is));  
String line = reader.readLine();  
while (line != null) {  
    System.out.println(line);  
    line = reader.readLine();  
}
```

完整的程序如下：

```java
private static void threadDump() {  
    InputStream is = null;  
    BufferedReader reader = null;  
    try {  
        String pid = ManagementFactory.getRuntimeMXBean().getName().split("@")[0];  
        System.out.println("pid: " + pid);  
        Process process = Runtime.getRuntime().exec("jstack " + pid);  
        is = process.getInputStream();  
        reader = new BufferedReader(new InputStreamReader(is));  
        String line = reader.readLine();  
        while (line != null) {  
            System.out.println(line);  
            line = reader.readLine();  
        }  
    } catch (IOException e) {  
        throw new RuntimeException(e);  
    }  
}
```

最后，我们将它放到哪里？肯定是**我们创建的那些线程创建出来之后，结束之前**。所以，我选择放到了notEnd为false的前面：

```java
for (int i = 0; i < 10; i++) {  
    ... ...
}  
notStart = false;  
TimeUnit.SECONDS.sleep(10);  
threadDump();  
notEnd = false;
```

最后的结果我就不写在这儿了，不过确实是5个优先级为1；5个优先级为10。不像书上说的那样还都是5。但是不排除是有这样的操作的，也就是**操作系统忽略了我们对线程优先级的设置**，我行我素。

- [ ] #TODO 用Linux试试改天。

### 4.1.2 线程的状态

- [ ] #TODO 这部分**一定一定**要和pthread做一做对比。

接下来我们通过一个例子来看看线程都有哪些状态。其实我们猜一猜，无非就是刚创建好，运行起来，阻塞住，被取消，终止之类的状态。我们来看看详细的状态：

| 状态名称 | 说明 |
| :--: | ---- |
| `NEW` | 初始状态，线程被构建，但是还没有调用start()方法 |
| `RUNNABLE` | 运行状态，Java线程将操作系统中的**就绪**和**运行**两种状态笼统地称作“运行中” |
| `BLOCKED` | 阻塞状态，表示线程阻塞于**锁** |
| `WAITING` | 等待状态，进入该状态表示当前线程需要等待其它线程做出一些特定动作（通知或者中断） |
| `TIMED_WAITING` | 超时等待状态，该状态不同于WAITING，它是可以在指定的时间自行返回的 |
| `TERMINATED` | 终止状态，表示当前线程已经执行完毕 |
这些状态都挺好理解。下面我们来写一个例子。这个例子里展示了三种状态的线程：

```kotlin
fun main() {  
    Thread(ThreadState.TimeWaiting(), "TimeWaitingThread").start()  
    Thread(ThreadState.Waiting(), "WaitingThread").start()  
    Thread(ThreadState.Blocked(), "BlockedThread-1").start()  
    Thread(ThreadState.Blocked(), "BlockedThread-2").start()  
}
```

我们一个一个来说。首先，我们需要定义好一个休眠的工具方法，让当前线程休眠若干秒：

```kotlin
class SleepUtils {  
    companion object {  
        @JvmStatic  
        fun second(seconds: Long) {  
            try {  
                TimeUnit.SECONDS.sleep(seconds)  
            } catch (e: InterruptedException) {  
                e.printStackTrace()  
            }  
        }  
    }  
}
```

> 调用`SleepUtils.second(100)`来休眠100秒。

下面，介绍第一个线程：TimeWaitingThread。这个线程的运行就是单纯的**不停**休眠100秒：

```kotlin
class TimeWaiting : Runnable {  
    override fun run() {  
        while (true) {  
            SleepUtils.second(100)  
        }  
    }  
}
```

猜一猜它运行的时候是什么状态？显然是`TIMED_WAITING`。在休眠的过程中，只需要等到休眠结束，就会**自动返回**，即使接下来等待他的还是另一轮休眠。

然后是第二个线程：WaitingThread。当然我们需要让他处于等待中断中，也就是只有别人让他继续才能继续。这里使用的就是Object中的wait()方法：

```kotlin
class Waiting : Runnable {  
  
    override fun run() {  
        while (true) {  
            synchronized(Waiting::class.java) {  
                try {  
                    // https://kotlinlang.org/docs/java-interop.html#object-methods  
                    (Waiting::class.java as java.lang.Object).wait()  
                } catch (e: InterruptedException) {  
                    e.printStackTrace()  
                }  
            }  
        }  
    }  
}
```

注意，这里因为Kotlin只有Any，所以调用Object的方法比较费劲儿：[Calling Java from Kotlin | Kotlin Documentation](https://kotlinlang.org/docs/java-interop.html#object-methods)

显然，该线程在运行起来之后应该处于`WAITING`状态。

最后两个线程是用来复现`BLOCKED`状态的。两个线程都是一样的，而第一个线程启动后会抢一把锁，之后在锁里面睡着；之后第二个线程启动的时候就会被阻塞了：

```kotlin
class Blocked : Runnable {  
    override fun run() {  
        synchronized(Blocked::class.java) {  
            while (true) {  
                SleepUtils.second(100)  
            }  
        }  
    }  
}
```

好了，现在启动这个程序。启动之后如何查看状态呢？使用`jps`命令：

```shell
PS C:\Users\SpreadZhao> jps
16928 Jps
17716 ThreadStateKt
```

> 注意，有可能你的jps什么也输出不出来。这有可能是因为没有权限：[debugging - jps returns no output even when java processes are running - Stack Overflow](https://stackoverflow.com/questions/3805376/jps-returns-no-output-even-when-java-processes-are-running)根据这篇文章，可以以管理员启动Power Shell即可；或者在Linux中使用sudo。

现在看到了我们的程序pid为17716。因此输入`jstack 17716`，就能看到我们程序中的线程信息了。这里排除掉其它线程，只看我们创建的这些，和我之前的描述都是一样的：

```shell
"TimeWaitingThread" #24 prio=5 os_prio=0 cpu=0.00ms elapsed=13.86s tid=0x000001ceef2fb7d0 nid=0x7288 waiting on condition  [0x000000c0172ff000]
   java.lang.Thread.State: TIMED_WAITING (sleeping)
        at java.lang.Thread.sleep(java.base@17.0.10/Native Method)
        at java.lang.Thread.sleep(java.base@17.0.10/Thread.java:346)
        at java.util.concurrent.TimeUnit.sleep(java.base@17.0.10/TimeUnit.java:446)
        at concurrency.thread.ThreadState$SleepUtils$Companion.second(ThreadState.kt:46)
        at concurrency.thread.ThreadState$TimeWaiting.run(ThreadState.kt:10)
        at java.lang.Thread.run(java.base@17.0.10/Thread.java:842)

"WaitingThread" #25 prio=5 os_prio=0 cpu=0.00ms elapsed=13.86s tid=0x000001ceef2fc950 nid=0x33b4 in Object.wait()  [0x000000c0173ff000]
   java.lang.Thread.State: WAITING (on object monitor)
        at java.lang.Object.wait(java.base@17.0.10/Native Method)
        - waiting on <0x00000005ac38ecf8> (a java.lang.Class for concurrency.thread.ThreadState$Waiting)
        at java.lang.Object.wait(java.base@17.0.10/Object.java:338)
        at concurrency.thread.ThreadState$Waiting.run(ThreadState.kt:22)
        - locked <0x00000005ac38ecf8> (a java.lang.Class for concurrency.thread.ThreadState$Waiting)
        at java.lang.Thread.run(java.base@17.0.10/Thread.java:842)

"BlockedThread-1" #26 prio=5 os_prio=0 cpu=0.00ms elapsed=13.86s tid=0x000001ceef3016d0 nid=0x3704 waiting on condition  [0x000000c0174fe000]
   java.lang.Thread.State: TIMED_WAITING (sleeping)
        at java.lang.Thread.sleep(java.base@17.0.10/Native Method)
        at java.lang.Thread.sleep(java.base@17.0.10/Thread.java:346)
        at java.util.concurrent.TimeUnit.sleep(java.base@17.0.10/TimeUnit.java:446)
        at concurrency.thread.ThreadState$SleepUtils$Companion.second(ThreadState.kt:46)
        at concurrency.thread.ThreadState$Blocked.run(ThreadState.kt:35)
        - locked <0x00000005ac390bf8> (a java.lang.Class for concurrency.thread.ThreadState$Blocked)
        at java.lang.Thread.run(java.base@17.0.10/Thread.java:842)

"BlockedThread-2" #27 prio=5 os_prio=0 cpu=0.00ms elapsed=13.86s tid=0x000001ceef301bb0 nid=0x4e78 waiting for monitor entry  [0x000000c0175ff000]
   java.lang.Thread.State: BLOCKED (on object monitor)
        at concurrency.thread.ThreadState$Blocked.run(ThreadState.kt:33)
        - waiting to lock <0x00000005ac390bf8> (a java.lang.Class for concurrency.thread.ThreadState$Blocked)
        at java.lang.Thread.run(java.base@17.0.10/Thread.java:842)
```

下图是Java线程状态转换图：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-02-06 00.11.15.excalidraw.png]]

当线程的Runnable的run()执行完成之后，线程也就终止了。

```ad-caution
title: 注意图中的syncronized

看，是等待进入syncronized方法或者块的时候，才是处于`BLOCKED`状态。这是啥意思？其它的锁不行吗？在java.util.concurrent包中有个Lock接口，它也能实现类似syncronized的并发模式。但是，获取这个Lock锁却并不会进入`BLOCKED`状态。那么是啥呢？答案是`WAITING`。因为Lock接口的实现利用了LockSupport中的方法。这里面并没有syncronized。
```

