## 2.4 Scheduling: Introduction

回头看2.1中介绍的那张图：

![[Study Log/os_study/2_virtualization/resources/Drawing 2024-06-24 22.43.56.excalidraw.svg]]

2.3中我们就已经把low-level mechanisms介绍清楚了。下面我们来介绍high-level policies，也就是调度策略（scheduling policies）

### 2.4.1 Workload Assumptions

要想设计调度策略，首先要进行评估。评估啥？当然你调度啥就评估啥。我们调度的是OS中的**进程**，所以自然就要评估进程。

OS中运行的所有进程，我们统称为workload。接下来我们要对workload进行评估，首先用一种最简单的方式，然后逐渐让他变复杂。假设：

> [!attention]
> 我们称进程的一部分，或者是CPU要执行的这部分，为“任务”。

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

为啥是平均呢？我们这么想：你A B C都是OS的进程，肯定**都**是越早完成越好。因此平均值最能反应情况。这么看来，FIFO还算是可以的。但是实际情况和我们的假设差距很大。我们现在放宽假设1：如果任务执行的时间不是一样的，会怎么样？我们可以想一想，能不能给出一种情况，让这个结果很差：

![[Study Log/os_study/2_virtualization/resources/Pasted image 20240710004655.png]]

这就和你去买菜一样：你就买个萝卜就结账了，但是你前面那人拿了好几筐，虽然你只需要几秒钟，但是那个人会很大程度地拖累你。回到例子中，就是后面的进程会感觉很“饿”，利用平均周转时长这个指标就能体现出来。