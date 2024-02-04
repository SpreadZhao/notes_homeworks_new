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

