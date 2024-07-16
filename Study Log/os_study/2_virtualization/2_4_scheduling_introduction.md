## 2.4 Scheduling: Introduction

回头看2.1中介绍的那张图：

![[Study Log/os_study/2_virtualization/resources/Drawing 2024-06-24 22.43.56.excalidraw.svg]]

2.3中我们就已经把low-level mechanisms介绍清楚了。下面我们来介绍high-level policies，也就是调度策略（scheduling policies）

### 2.4.1 Workload Assumptions

要想设计调度策略，首先要进行评估。评估啥？当然你调度啥就评估啥。我们调度的是OS中的**进程**，所以自然就要评估进程。

OS中运行的所有进程，我们统称为workload。接下来我们要对workload进行评估，首先用一种最简单的方式，然后逐渐让他变复杂。假设：

> [!attention]
> 我们称进程的一部分（就是一坨代码），CPU在这个时间段内要执行的这部分，为“任务”。

1. 每一个任务运行时长都一样；
2. 所有任务同时到达；
3. 一旦启动，每个任务就要运行完才行；
4. 所有任务只用CPU（比如IO就不用）；
5. 每一个任务的运行时长已知。

### 2.4.2 Scheduling Metrics

有了假设，接下来还要知道怎么比较调度策略，哪个更好。这里就要设置一些指标了。先说一个最简单的：Turnaround time。就是从这个任务到达，直到这个任务完成用了多长时间：

$$
T_{turnaround} = T_{completion} - T_{arrival}
$$

因为前面假设所有的任务同时到达，所以其实就可以认为$T_{arrival} = 0$，因此$T_{turnaround} = T_{completion}$。Turnaround time是一个**性能**指标，这东西越短代表性能越好。**除了性能，指标关注的还有公平**。但是我们之后会发现（[[Study Log/java_kotlin_study/concurrency_art/5_3_reentrant_lock#^e43b0b|其实我早就发现了]]），性能和公平这俩东西本身就是不可兼得的。

### 2.4.3 First In, First Out (FIFO)

FIFO又可以叫做先来先服务（FCFS）。

没啥好说的。比如A B C，履行上面的假设。当然，同时到达是不现实的，就是A比B先来一丢丢，B比C先来一丢丢，可以忽略不计的那种。每个任务运行10s，从0s开始。应该是这样的：

![[Study Log/os_study/2_virtualization/resources/Pasted image 20240710004236.png]]

我们在乎的指标是**平均周转时长**：

$$
\overline{T_{turnaround}} = \dfrac{10 + 20 + 30}{3} = 20
$$

为啥是平均呢？我们这么想：你A B C都是OS的进程中要执行的代码，肯定**都**是越早完成越好。因此平均值最能反应情况。这么看来，FIFO还算是可以的。但是实际情况和我们的假设差距很大。我们现在放宽假设1：*如果任务执行的时间不是一样的，会怎么样*？我们可以想一想，能不能给出一种情况，让这个结果很差：

![[Study Log/os_study/2_virtualization/resources/Pasted image 20240710004655.png]]

这就和你去买菜一样：你就买个萝卜就结账了，但是你前面那人拿了好几筐，虽然你只需要几秒钟，但是那个人会很大程度地拖累你。回到例子中，就是后面的进程会感觉很“饿”，利用平均周转时长这个指标就能体现出来。

### 2.4.4 Shortest Job First (SJF)

非常好理解，上面那个例子里，用SJF就是这样的：

![[Study Log/os_study/2_virtualization/resources/Pasted image 20240716234622.png]]

ABC同时到达，但是我们运行最短的，也就是B和C。最后才运行A。这样平均周转时长就从110变成了50。

但是，这东西真就一定更好吗？我们来放宽假设2：*如果任务不是同时到达的，会怎样*？比如，任务A在0时刻到，B和C在10时刻到。显然，这样就不行了。因为A到的时候OS只能运行A，没其它的可以运行。所以：

![[Study Log/os_study/2_virtualization/resources/Pasted image 20240716235203.png]]

==虽然现在没有考试了==，但是我还是希望你算准这里的平均周转时长：

$$
T_{turnaround} = \dfrac{100 + (110 - 10) + (120 - 10)}{3} \approx 103.33
$$

> [!note]
> 这里B和C因为是10时刻到的，所以要减掉。

显然，这样也不行了。还得换。

### 2.4.5 Shortest Time-to-Completion First (STCF)

现在要放宽假设3：*如果任务可以不运行完，会怎样*？我们之前聊过timer interrupts和context switching：[[Study Log/os_study/2_virtualization/2_3_limited_directed_execution#2.3.3 Problem 2 Switching Between Processes|2_3_limited_directed_execution]]。因此我们完全可以在B和C到来的时候停止运行A然后运行它们。

这样的调度策略就叫做Shortest Time-to-Completion First。或者叫Preemptive Shortest Job First (PSJF)。注意，是当有新任务来的时候，我们才判断现在的任务里谁是最短的（**还剩下的任务**），然后运行它。

刚才的例子用STCF就是这样：

![[Study Log/os_study/2_virtualization/resources/Pasted image 20240717000446.png]]

### 2.4.6 A New Metric: Response Time

现在感觉STCF够好了吧。继续想：任务到达，代表OS就应该**尽快**运行它了。比如我在终端里，输入一个命令，然后回车，那肯定是我希望OS尽快运行这段命令。但是，这个过程总要有个时间，因为这个时候CPU可能还在运行其它的。所以，另一个指标诞生了：响应时间。

$$
T_{response} = T_{firstrun} - T_{arrival}
$$

如果按照上面STCF的例子去看，ABC的响应时间就是0，0，10。

其实这么看，前面所有的调度策略的响应时间都很烂。你因为晚到、时间长等原因，都会被排到其它任务后面。所以，还得换。

### 2.4.7 Round Robin

RR又叫做time-slicing。其实就是一个任务运行一段时间。假设一个任务运行一个时间，ABC同时到达，都运行5的话，SJF和RR的结果如下：

![[Study Log/os_study/2_virtualization/resources/Pasted image 20240717002603.png]]

我们发现，RR的响应时间很快，只有1（SJF是5）；但是平均周转时长很差，足足有14（SJF是7.5）。这就是之前说的性能和公平的问题。RR非常公平，因为它让每个任务运行的时间都一样。但是这样就不能让一些任务很快完成，体现出来也就是性能差。

### 2.4.8 Incorporating I/O

现在放宽假设4：*如果进程会做IO，会怎样*？当然几乎所有的程序都得做IO。

- 当程序发出IO请求时，OS就不会再管它了：因为它不再使用CPU，进入**阻塞**状态等待IO完成。这时OS就可以调度其它的任务了；
- 当IO完成时，会发出一个中断，这个时候OS会把进程置回ready状态，然后OS就又可以考虑调度它了。

> [!note]
> 回想讲进程的时候的那张状态图：[[Study Log/os_study/2_virtualization/2_1_process#2.1.4 Process States|2_1_process]]。

有IO的时候怎么办呢？看下图这个例子：

![[Study Log/os_study/2_virtualization/resources/Pasted image 20240717004331.png]]

现在如果先运行A再运行B，那显然很浪费。但是如果你用STCF的话，结果好像也是一样的。因为A只用50（CPU时间）。因此当A运行了10之后，B来了。这个时候A剩40，B剩50，那运行的还是A。所以结果还是和上图一样。

那怎么办？常见的策略是：**将这个一小段看成一个独立的任务**。再详细点儿说，就是一段独立的，使用CPU的任务，即使是A的一部分，也看成独立的。这样就是A1 A2 A3 A4 A5 B这6个任务的事情了。这个时候如果我们再用STCF，结果就是这样的：

![[Study Log/os_study/2_virtualization/resources/Pasted image 20240717004727.png]]

这种技术叫**overlap**，等IO的时候还可以干别的。这样CPU就利用的很好了。

还有最后一个假设我们没放宽，这也是最难的一个。因为时长不知道的情况下，我们发现以上所有的策略都没法安排了，因为之前的策略之所以好，就是因为我们知道每个任务的时长，然后排方块排出来的。因此，这个最难的我们留到下一节再说。

- SJF/SCTF：性能好，但是不公平。所以平均周转时长好，但是响应时间差；
- RR：性能查，但是公平。所以平均周转时长差，但是响应时间好。