---
title:
  - "2.6 Scheduling: Proportional Share"
order: "7"
---
[[Study Log/os_study/0_ostep_index|Return to Index]]

## 2.6 Scheduling: Proportional Share

和上一节一样，我们也要讨论一种调度策略。但是和MLFQ的出发点是不一样的。之前我们讨论过两个指标：Turnaround Time和Response Time，分别为了衡量被服务的充分程度和响应的速度。但是本节讨论的调度策略，目的不太一样。和它的名字一样，Proportional Share，有时候也叫Fair Share。目的是为了**让每个任务尽量都能分到固定比例的CPU资源**。比如我这个任务，就固定是占用5%的CPU，不会有很大的偏差。

这种维度的调度策略，已经有比较好的实现了。那就是——Lottery Scheduling。虽然已经比较老了，但是它的思想也不是那么简单。下面就来看一看。

### 2.6.1 Basic Concept: Tickets Represent Your Share

简单举个例子，什么是彩票。假设两个进程A和B。一共有100个tiket。让A有75个，B有25个。每次（每个time slice）CPU都会选出一个中奖的tiket。谁持有它，谁就会运行。

实现起来也很简单。一个随机数，从0-99。如果结果是0-74，那么A就运行。如果是75-99，那么就是B运行。

下面是一个例子。如果CPU生成的数字，和对应的谁会执行：

```
63 85 70 39 76 17 29 41 36 39 10 99 68 83 63 62 43 0 49 12
A     A  A     A  A  A  A  A  A     A     A  A  A  A A  A
   B        B                    B     B
```

显然，这个概率是不准的。理论值B可以有25%，但是实际上只有20%。不过随着time slice越来越多，这个概率就会越来越准。

### 2.6.2 Ticket Mechanisms

[[Study Log/os_study/0_ostep_index|Return to Index]]