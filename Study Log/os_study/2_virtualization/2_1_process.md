## 2.1 The Abstraction: The Process

进程定义：一个正在运行的程序。

OS是怎么共享CPU的？最基础的手段叫**时间共享**（time-sharing）。显然，潜在的消耗就是时间消耗。因为如果你要共享CPU的时间，那么每个程序运行的速度就会变慢。

> <small><b>Time sharing</b> is a basic technique used by an OS to share a resource. By allowing the resource to be used for a little while by one entity, and then a little while by another, and so forth, the resource in question (e.g., the CPU, or a network link) can be shared by many. The counterpart of time sharing is <b>space sharing</b>, where a resource is divided (in space) among those who wish to use it. For example, disk space is naturally a space shared resource; once a block is assigned to a file, it is normally not assigned to another file until the user deletes the original file.</small>

为了实现CPU的虚拟化，需要低层和高层两方面的内容：

![[Study Log/os_study/2_virtualization/resources/Drawing 2024-06-24 22.43.56.excalidraw.svg]]

底层的叫机制（mechanism），上层的叫策略（policy）。比如我们在[[Study Log/java_kotlin_study/concurrency_art/1_concurrency_challange|1_concurrency_challange]] 的开头就提到的上下文切换（context-switch）就是一种底层机制；而之前学OS的时候也提到过一些调度策略。

### 2.1.1 The Abstraction: A Process

OS提供的一个运行程序的抽象就是一个**进程**（process）。一个进程都由什么组成？我们要了解一下它的**机械状态**（machine state）。也就是说，一个程序在运行的时候，它都能读或者写什么？

- Memory：内存当然是一部分。指令就在里面，数据也在里面。当前程序能访问的内存也被成为它的**地址空间**（address space）；
- Registers：寄存器，不用多说。但是要注意有很多特殊的寄存器。比如PC指针指向下一条指令，Stack Pointer负责指向栈空间的起始位置，然后[Frame Pointer](https://stackoverflow.com/questions/68023230/whats-the-difference-between-stack-pointer-and-frame-pointer-in-assembly-arm)可以配合Stack Pointer来管理函数参数、本地变量和返回地址；
- I/O Information：程序运行当然要访问IO设备。

### 2.1.2 Process API

首先要给出一些OS必备的和进程相关的接口：

- 创建；
- 销毁；
- 等待：比如join；
- 各种控制：比如挂起和恢复；
- 状态：获取进程的各种状态信息。

### 2.1.3 Process Creation: A Little More Detail

进程启动的图如下：

![[Study Log/os_study/2_virtualization/resources/Pasted image 20240625000338.png]]

从图中看到，程序的启动就是那一坨东西从硬盘里跑到内存里。程序一开始是在磁盘里的，以一种**可执行的格式**存在。

在老的OS里，加载程序之前所有的东西都一股脑儿加载完；但是新的OS也用上了懒加载，就是需要什么就加载什么。如果想深入了解懒加载，需要先了解分页（paging）和交换（swapping）机制。这些我们稍后会讨论。

当代码和数据加载到内存之后，还有一些其他的事情要做才能启动进程。比如你要给程序分配运行时的栈空间，当然是在内存中分配。然后还会在栈空间里初始化一些参数。对于`main()`函数，还会特殊对待，填入它的参数，也就是`argc`和`argv`。

当然也会分配堆空间。有一些数据结构比如链表，哈希表，树等，这些都是需要存到堆里的。

还会做一些和IO相关的初始化。比如每个程序默认都会打开三个文件描述符（file descriptor）：标准输入，标准输出和标准错误。这些会在讨论持久化的时候说。

最后，总算是都初始化完了，还剩一件事：跳到`main()`函数，运行。这之后OS就会把CPU的控制权从自己手里转交给新产生的这个进程了，从而执行里面的代码。

> [!note]
> 怎么跳到main里面的？也是通过一种mechanism。这个我们下一章会介绍。

### 2.1.4 Process States

如图：

![[Study Log/os_study/2_virtualization/resources/Pasted image 20240625011307.png]]

- Running：没什么好说的，进程运行在处理器上，也就是正在执行指令；
- Ready：已经可以运行了，但是由于某些原因，OS并没有选择它运行；
- Blocked：比如你写硬盘，因为硬盘特别慢，所以你要阻塞一会儿，这个时候CPU交给其他人用。

下面是一个两个进程之间争抢CPU的例子：

![[Study Log/os_study/2_virtualization/resources/Pasted image 20240625011958.png]]

图很好看懂，但是有一些关键点要注意：

1. 因为p0要处理IO，所以它Blocked了，p1开始运行；
2. **当p0的IO完事儿之后，并没有从p1切换回p0。所以p0变成了Ready**；
3. 等p1结束之后，p0才夺回CPU使用权，变成Running。

从这里，就能看出OS的重要作用：调度。p0遇到了IO，所以调度p1运行；而第二条是一个值得商榷的行为。因为从p1切换回p0与否涉及到很多问题，所以并没有标准答案。

### 2.1.5 Data Structures

下面是教材中[xv6](https://pdos.csail.mit.edu/6.828/2012/xv6.html)内核给的和进程相关的数据结构：

```c
// the registers xv6 will save and restore
// to stop and subsequently restart a process
struct context {
	int eip;
	int esp;
	int ebx;
	int ecx;
	int edx;
	int esi;
	int edi;
	int ebp;
};
// the different states a process can be in
enum proc_state { UNUSED, EMBRYO, SLEEPING,
                  RUNNABLE, RUNNING, ZOMBIE };
// the information xv6 tracks about each process
// including its register context and state
struct proc {
	char *mem; // Start of process memory
	uint sz; // Size of process memory
	char *kstack; // Bottom of kernel stack
	// for this process
	enum proc_state state; // Process state
	int pid; // Process ID
	struct proc *parent; // Parent process
	void *chan; // If !zero, sleeping on chan
	int killed; // If !zero, has been killed
	struct file *ofile[NOFILE]; // Open files
	struct inode *cwd; // Current directory
	struct context context; // Switch here to run process
	struct trapframe *tf; // Trap frame for the
						  // current interrupt
};
```

和我自己找到的不太一样：[xv6-public/proc.h at master · mit-pdos/xv6-public](https://github.com/mit-pdos/xv6-public/blob/master/proc.h)。

不过不管是哪个，都是OS中必不可少的结构，OS需要这些信息来维护进程，来进行一些任务。比如调度，当一个进程执行完毕了，要切到其它进程，我首先想到的就应该是找**哪些进程是Ready状态**的，这样才能切换到对的进程上。

很多个这样的结构串一串，就变成了**进程列表**（process list）。

> [!note]
> 存储一个进程相关信息的数据结构叫做Process Control Block，多个PCB就组成了Process List。

- [ ] #TODO tasktodo1719252003499 验证一下，Linux内核里的`task_struct`是不是也是这个东西。 ➕ 2024-06-25 🔽 🆔 lnwsl1

> [!todo] `task_struct`
> [task_struct结构解析：了解进程管理的内幕](https://mp.weixin.qq.com/s/3JRQuCmLcsqOtlllke_v-Q)

回到代码中，一开始的这个context，看注释：the registers xv6 will save and restore to stop and subsequently restart a process. 意思就是说，是为了恢复进程的。比如一个进程停止了，这些寄存器里的东西就会被保存到内存中。等要继续的时候，就再从内存里放回寄存器。这个东西其实就是之后要讨论的上下文切换。

除此之外，还可以看到进程的状态也不止提到的那三个。

- initial：正在创建的进程有的状态。比如上面的`EMBRYO`（胚胎）；
- final：进程已经结束了，但是还没被清理。比如上面的`ZOMBIE`。

对于zombie，需要特别强调。首先是这里的清理，不是代表这个进程的内存。它已经不占内存了，因为都已经结束了。它占的是进程列表中的一项；其次是什么时候才是僵尸态。比如线程，主线程调用join来等待它派生出来的线程结束。进程也是一样的，父进程会调用waitXXX来等待子进程结束。而如果父进程忘了调用wait，子进程就会一直保持僵尸状态。

### 2.1.6 Homework

[ostep-homework/cpu-intro at master · remzi-arpacidusseau/ostep-homework](https://github.com/remzi-arpacidusseau/ostep-homework/tree/master/cpu-intro)

这里解析一下这个作业程序。其实代码没必要看，主要看它设计的思路。

用法如下：

```shell
❯ ./process-run.py -l 5:100
Produce a trace of what would happen when you run these processes:
Process 0
  cpu
  cpu
  cpu
  cpu
  cpu

Important behaviors:
  System will switch when the current process is FINISHED or ISSUES AN IO
  After IOs, the process issuing the IO will run LATER (when it is its turn)
```

这里`5:100`的意思是，这个进程包含5个指令，完全都是CPU的指令。因此输出了5个cpu就结束了。最后要注意它给的提示：

- 当前进程是FINISHED或者处理IO的时候，才会切换进程； ^c8c0b1
- 在IO之后，处理IO的进程会稍后运行。 ^392518

第二条不太好懂，我们先接着往后看，毕竟这里还没涉及到IO。我们把例子变复杂一点：

```shell
❯ ./process-run.py -l 5:100,5:100
Produce a trace of what would happen when you run these processes:
Process 0
  cpu
  cpu
  cpu
  cpu
  cpu

Process 1
  cpu
  cpu
  cpu
  cpu
  cpu

Important behaviors:
  System will switch when the current process is FINISHED or ISSUES AN IO
  After IOs, the process issuing the IO will run LATER (when it is its turn)
```

这里是两个进程，所以按照规则，就是两个进程先后运行，不存在中间切换。我们可以用`-c`验证：

```shell
❯ ./process-run.py -l 5:100,5:100 -c
Time        PID: 0        PID: 1           CPU           IOs
  1        RUN:cpu         READY             1          
  2        RUN:cpu         READY             1          
  3        RUN:cpu         READY             1          
  4        RUN:cpu         READY             1          
  5        RUN:cpu         READY             1          
  6           DONE       RUN:cpu             1          
  7           DONE       RUN:cpu             1          
  8           DONE       RUN:cpu             1          
  9           DONE       RUN:cpu             1          
 10           DONE       RUN:cpu             1
```

> [!attention]
> 这里不存在调度，所以0先运行完全是巧合。另外，这里假设的是每个指令的耗时都是一样的，都是一个CPU时间单位。

在之后的例子中，我们要尽可能不加`-c`命令，然后猜出来`-c`的这个结果。

然后该看看IO了。因为IO比较长，所以不一定只占一个时间。使用`-L <IO Length>`来设置IO的长度。**默认值是5**，例子如下：

```shell
❯ ./process-run.py -l 3:0 -L 5
Produce a trace of what would happen when you run these processes:
Process 0
  io
  io_done
  io
  io_done
  io
  io_done

Important behaviors:
  System will switch when the current process is FINISHED or ISSUES AN IO
  After IOs, the process issuing the IO will run LATER (when it is its turn)
```

`3:0`表示这个进程有3个指令，全都是IO指令。每个指令长5个时间单位。因此最后结果应该是到15。然而，我们需要注意的是，运行IO和IO结束本身也是需要时间的。因此这部分消耗的还是CPU时间（因为发起IO肯定也是个CPU要执行的指令）。最后的结果应该是$15 + 3 \times 2 = 21$：

```shell
❯ ./process-run.py -l 3:0 -L 5 -c
Time        PID: 0           CPU           IOs
  1         RUN:io             1          
  2        BLOCKED                           1
  3        BLOCKED                           1
  4        BLOCKED                           1
  5        BLOCKED                           1
  6        BLOCKED                           1
  7*   RUN:io_done             1          
  8         RUN:io             1          
  9        BLOCKED                           1
 10        BLOCKED                           1
 11        BLOCKED                           1
 12        BLOCKED                           1
 13        BLOCKED                           1
 14*   RUN:io_done             1          
 15         RUN:io             1          
 16        BLOCKED                           1
 17        BLOCKED                           1
 18        BLOCKED                           1
 19        BLOCKED                           1
 20        BLOCKED                           1
 21*   RUN:io_done             1     
```

现在我们可以加上`-p`来查看CPU和IO的繁忙程度：

```shell
❯ ./process-run.py -l 3:0 -L 5 -cp
Time        PID: 0           CPU           IOs
  1         RUN:io             1          
  2        BLOCKED                           1
  3        BLOCKED                           1
  4        BLOCKED                           1
  5        BLOCKED                           1
  6        BLOCKED                           1
  7*   RUN:io_done             1          
  8         RUN:io             1          
  9        BLOCKED                           1
 10        BLOCKED                           1
 11        BLOCKED                           1
 12        BLOCKED                           1
 13        BLOCKED                           1
 14*   RUN:io_done             1          
 15         RUN:io             1          
 16        BLOCKED                           1
 17        BLOCKED                           1
 18        BLOCKED                           1
 19        BLOCKED                           1
 20        BLOCKED                           1
 21*   RUN:io_done             1          

Stats: Total Time 21
Stats: CPU Busy 6 (28.57%)
Stats: IO Busy  15 (71.43%)
```

算这个很简单。接下来就是作业中的题了。

> [!question]- 1\. Run `process-run.py` with the following flags: `-l 5:100,5:100`. What should the CPU utilization be (e.g., the percent of time the CPU is in use?) Why do you know this? Use the -c and -p flags to see if you were right.
> 这个我们已经给过答案了，就不多说了，应该是100%。

> [!question]- 2\. Now run with these flags: `./process-run.py -l 4:100,1:0`. These flags specify one process with 4 instructions (all to use the CPU), and one that simply issues an I/O and waits for it to be done. How long does it take to complete both processes? Use -c and -p to find out if you were right.
> 概括来说，就是4个CPU和1个IO。如果是进程0先运行的话，那么4个CPU运行完之前进程1是不能动的。因此只能顺序执行，也就是4个CPU加上1个IO（5个时间）和这个IO的启动和结束，总共是11个时间单位，CPU利用率为$\dfrac{6}{11}$，IO利用率为$\dfrac{5}{11}$：
> 
> ~~~shell
> ❯ ./process-run.py -l 4:100,1:0 -cp
> Time        PID: 0        PID: 1           CPU           IOs
>   1        RUN:cpu         READY             1          
>   2        RUN:cpu         READY             1          
>   3        RUN:cpu         READY             1          
>   4        RUN:cpu         READY             1          
>   5           DONE        RUN:io             1          
>   6           DONE       BLOCKED                           1
>   7           DONE       BLOCKED                           1
>   8           DONE       BLOCKED                           1
>   9           DONE       BLOCKED                           1
>  10           DONE       BLOCKED                           1
>  11*          DONE   RUN:io_done             1          
> 
> Stats: Total Time 11
> Stats: CPU Busy 6 (54.55%)
> Stats: IO Busy  5 (45.45%)
> ~~~

> [!question]- 3\. Switch the order of the processes: `-l 1:0,4:100`. What happens now? Does switching the order matter? Why? (As always, use -c and -p to see if you were right)
> 你看，这里因为没有调度策略，就是默认列表前面的先运行。换了顺序之后，进程0变成IO的了。因此它要做的是花1个时间发起IO，用5个时间处理IO。但是看之前的提示：[[#^c8c0b1]]，等第二个时间，因为它在处理IO，所以就切到进程1了。所以2 3 4 5时间就是进程1的时间。而进程0处理IO的时间是2 3 4 5 6，所以等到7时间才会继续运行。但是因为进程0只有一个IO，所以时间7就全都结束了。这里算利用率的时候要注意，因为有的时候CPU和IO是同时在工作的。所以它们两个加起来会超过100\%。CPU利用率是$\dfrac{6}{7}$，IO利用率是$\dfrac{5}{7}$：
> 
> ~~~shell
> ❯ ./process-run.py -l 1:0,4:100 -cp
> Time        PID: 0        PID: 1           CPU           IOs
>   1         RUN:io         READY             1          
>   2        BLOCKED       RUN:cpu             1             1
>   3        BLOCKED       RUN:cpu             1             1
>   4        BLOCKED       RUN:cpu             1             1
>   5        BLOCKED       RUN:cpu             1             1
>   6        BLOCKED          DONE                           1
>   7*   RUN:io_done          DONE             1          
> 
> Stats: Total Time 7
> Stats: CPU Busy 6 (85.71%)
> Stats: IO Busy  5 (71.43%)
> ~~~

> [!question]- 4\. We’ll now explore some of the other flags. One important flag is -S, which determines how the system reacts when a process issues an I/O. With the flag set to `SWITCH_ON_END`, the system will NOT switch to another process while one is doing I/O, instead waiting until the process is completely finished. What happens when you run the following two processes (`-l 1:0,4:100 -c -S SWITCH_ON_END`), one doing I/O and the other doing CPU work?
> 和上一个的区别就是时间2。在上一道题里，因为进程0做IO了，所以切到了进程1。但是你设置了这个flag，就不会切换了。因此直到时间8的时候，进程1才能运行。进程1运行的时候应该是8 9 10 11，所以总时间为11。CPU利用率是$\dfrac{6}{11}$，IO利用率是$\dfrac{5}{11}$：
> 
> ~~~shell
> ❯ ./process-run.py -l 1:0,4:100 -cp -S SWITCH_ON_END
> Time        PID: 0        PID: 1           CPU           IOs
>   1         RUN:io         READY             1          
>   2        BLOCKED         READY                           1
>   3        BLOCKED         READY                           1
>   4        BLOCKED         READY                           1
>   5        BLOCKED         READY                           1
>   6        BLOCKED         READY                           1
>   7*   RUN:io_done         READY             1          
>   8           DONE       RUN:cpu             1          
>   9           DONE       RUN:cpu             1          
>  10           DONE       RUN:cpu             1          
>  11           DONE       RUN:cpu             1          
> 
> Stats: Total Time 11
> Stats: CPU Busy 6 (54.55%)
> Stats: IO Busy  5 (45.45%)
> ~~~

> [!question]- 5\. Now, run the same processes, but with the switching behavior set to switch to another process whenever one is WAITING for I/O (`-l 1:0,4:100 -c -S SWITCH_ON_IO`). What happens now? Use -c and -p to confirm that you are right.
> 这个一看就是和第三题的结果一样。这个flag不加默认应该就是这个。

> [!question]- 6\. One other important behavior is what to do when an I/O completes. With `-I IO_RUN_LATER`, when an I/O completes, the process that issued it is not necessarily run right away; rather, whatever was running at the time keeps running. What happens when you run this combination of processes? (Run `./process-run.py -l 3:0,5:100,5:100,5:100 -S SWITCH_ON_IO -I IO_RUN_LATER -c -p`) Are system resources being effectively utilized?
> 
> 这回终于可以说刚才第二个提示了：[[#^392518]]。这个例子我们详细说一说，一共有4个进程。进程0会先发起一个IO，所以我们起码能写出第一行：
> 
> | Time | PID: 0                          | PID: 1 | PID: 2 | PID: 3 | CPU | IOs |
> | ---- | ------------------------------- | ------ | ------ | ------ | --- | --- |
> | 1    | <font color="red">RUN:io</font> | READY  | READY  | READY  | 1   |     |
> 
> 接下来0要做5个IO了，所以2 3 4 5 6时间内0都是IO。而此时由于是`SWITCH_ON_IO`，所以要切换，那自然就切换到第二个进程1号：
> 
> | Time | PID: 0                           | PID: 1                           | PID: 2 | PID: 3 | CPU | IOs |
> | ---- | -------------------------------- | -------------------------------- | ------ | ------ | --- | --- |
> | 1    | RUN:io                           | READY                            | READY  | READY  | 1   |     |
> | 2    | <font color="red">BLOCKED</font> | <font color="red">RUN:cpu</font> | READY  | READY  | 1   | 1   |
> | 3    | <font color="red">BLOCKED</font> | <font color="red">RUN:cpu</font> | READY  | READY  | 1   | 1   |
> | 4    | <font color="red">BLOCKED</font> | <font color="red">RUN:cpu</font> | READY  | READY  | 1   | 1   |
> | 5    | <font color="red">BLOCKED</font> | <font color="red">RUN:cpu</font> | READY  | READY  | 1   | 1   |
> | 6    | <font color="red">BLOCKED</font> | <font color="red">RUN:cpu</font> | READY  | READY  | 1   | 1   |
> 
> 等到第7个时间就出问题了：进程1是已经结束了没他事儿了。但是进程0的IO做完了。此时0需要一个CPU时间来让IO结束，而2和3也都需要运行。
> 
> 另一个要注意的一点是，进程0不止有一个IO，它有3个。所以进程0之后还要做事情的。
> 
> 这个时候，就体现出`IO_RUN_LATER`的作用了：IO稍后运行。也就是等CPU空闲之后再继续。所以它这个时候会等下去，**等2和3都运行完了，它才会继续**。所以接下来的10行就是2和3在运行。
> 
> 还有一点，就是这10行里0的状态：它已经做完IO了，**渴求的是CPU运行指令，结束IO的指令**。所以应该是READY状态：
> 
> | Time | PID: 0                         | PID: 1  | PID: 2                           | PID: 3                           | CPU | IOs |
> | ---- | ------------------------------ | ------- | -------------------------------- | -------------------------------- | --- | --- |
> | 1    | RUN:io                         | READY   | READY                            | READY                            | 1   |     |
> | 2    | BLOCKED                        | RUN:cpu | READY                            | READY                            | 1   | 1   |
> | 3    | BLOCKED                        | RUN:cpu | READY                            | READY                            | 1   | 1   |
> | 4    | BLOCKED                        | RUN:cpu | READY                            | READY                            | 1   | 1   |
> | 5    | BLOCKED                        | RUN:cpu | READY                            | READY                            | 1   | 1   |
> | 6    | BLOCKED                        | RUN:cpu | READY                            | READY                            | 1   | 1   |
> | 7    | <font color="red">READY</font> | DONE    | <font color="red">RUN:cpu</font> | READY                            | 1   |     |
> | 8    | <font color="red">READY</font> | DONE    | <font color="red">RUN:cpu</font> | READY                            | 1   |     |
> | 9    | <font color="red">READY</font> | DONE    | <font color="red">RUN:cpu</font> | READY                            | 1   |     |
> | 10   | <font color="red">READY</font> | DONE    | <font color="red">RUN:cpu</font> | READY                            | 1   |     |
> | 11   | <font color="red">READY</font> | DONE    | <font color="red">RUN:cpu</font> | READY                            | 1   |     |
> | 12   | <font color="red">READY</font> | DONE    | DONE                             | <font color="red">RUN:cpu</font> | 1   |     |
> | 13   | <font color="red">READY</font> | DONE    | DONE                             | <font color="red">RUN:cpu</font> | 1   |     |
> | 14   | <font color="red">READY</font> | DONE    | DONE                             | <font color="red">RUN:cpu</font> | 1   |     |
> | 15   | <font color="red">READY</font> | DONE    | DONE                             | <font color="red">RUN:cpu</font> | 1   |     |
> | 16   | <font color="red">READY</font> | DONE    | DONE                             | <font color="red">RUN:cpu</font> | 1   |     |
> 
> 这之后，0终于可以继续运行了！但是它只剩下第一个IO的结束和剩下两个IO了。所以只有它孤零零地完成。结果直接给出了：
> 
> | Time | PID: 0                               | PID: 1  | PID: 2  | PID: 3  | CPU | IOs |
> | ---- | ------------------------------------ | ------- | ------- | ------- | --- | --- |
> | 1    | RUN:io                               | READY   | READY   | READY   | 1   |     |
> | 2    | BLOCKED                              | RUN:cpu | READY   | READY   | 1   | 1   |
> | 3    | BLOCKED                              | RUN:cpu | READY   | READY   | 1   | 1   |
> | 4    | BLOCKED                              | RUN:cpu | READY   | READY   | 1   | 1   |
> | 5    | BLOCKED                              | RUN:cpu | READY   | READY   | 1   | 1   |
> | 6    | BLOCKED                              | RUN:cpu | READY   | READY   | 1   | 1   |
> | 7    | READY                                | DONE    | RUN:cpu | READY   | 1   |     |
> | 8    | READY                                | DONE    | RUN:cpu | READY   | 1   |     |
> | 9    | READY                                | DONE    | RUN:cpu | READY   | 1   |     |
> | 10   | READY                                | DONE    | RUN:cpu | READY   | 1   |     |
> | 11   | READY                                | DONE    | RUN:cpu | READY   | 1   |     |
> | 12   | READY                                | DONE    | DONE    | RUN:cpu | 1   |     |
> | 13   | READY                                | DONE    | DONE    | RUN:cpu | 1   |     |
> | 14   | READY                                | DONE    | DONE    | RUN:cpu | 1   |     |
> | 15   | READY                                | DONE    | DONE    | RUN:cpu | 1   |     |
> | 16   | READY                                | DONE    | DONE    | RUN:cpu | 1   |     |
> | 17   | <font color="red">RUN:io_done</font> | DONE    | DONE    | DONE    | 1   |     |
> | 18   | <font color="red">RUN:io</font>      | DONE    | DONE    | DONE    | 1   |     |
> | 19   | <font color="red">BLOCKED</font>     | DONE    | DONE    | DONE    |     | 1   |
> | 20   | <font color="red">BLOCKED</font>     | DONE    | DONE    | DONE    |     | 1   |
> | 21   | <font color="red">BLOCKED</font>     | DONE    | DONE    | DONE    |     | 1   |
> | 22   | <font color="red">BLOCKED</font>     | DONE    | DONE    | DONE    |     | 1   |
> | 23   | <font color="red">BLOCKED</font>     | DONE    | DONE    | DONE    |     | 1   |
> | 24   | <font color="red">RUN:io_done</font> | DONE    | DONE    | DONE    | 1   |     |
> | 25   | <font color="red">RUN:io</font>      | DONE    | DONE    | DONE    | 1   |     |
> | 26   | <font color="red">BLOCKED</font>     | DONE    | DONE    | DONE    |     | 1   |
> | 27   | <font color="red">BLOCKED</font>     | DONE    | DONE    | DONE    |     | 1   |
> | 28   | <font color="red">BLOCKED</font>     | DONE    | DONE    | DONE    |     | 1   |
> | 29   | <font color="red">BLOCKED</font>     | DONE    | DONE    | DONE    |     | 1   |
> | 30   | <font color="red">BLOCKED</font>     | DONE    | DONE    | DONE    |     | 1   |
> | 31   | <font color="red">RUN:io_done</font> | DONE    | DONE    | DONE    | 1   |     |
> 
> 最后的CPU利用率$\dfrac{21}{31}$，IO利用率$\dfrac{15}{31}$。然后说这个效率高不高？肯定不高！这三个IO只利用了一个。完全可以用剩下的两个IO去运行其它的进程。

> [!question]- 7\. Now run the same processes, but with `-I IO_RUN_IMMEDIATE` set, which immediately runs the process that issued the I/O. How does this behavior differ? Why might running 『a process that just completed an I/O』 again be a good idea?
> 相对的，在第7个时间，运行的是进程0。这样能够在下一个IO的时候运行其它进程。这里直接给结果了：
> 
> ~~~shell
> ❯ ./process-run.py -l 3:0,5:100,5:100,5:100 -S SWITCH_ON_IO -I IO_RUN_IMMEDIATE -c -p
> Time        PID: 0        PID: 1        PID: 2        PID: 3           CPU           IOs
>   1         RUN:io         READY         READY         READY             1          
>   2        BLOCKED       RUN:cpu         READY         READY             1             1
>   3        BLOCKED       RUN:cpu         READY         READY             1             1
>   4        BLOCKED       RUN:cpu         READY         READY             1             1
>   5        BLOCKED       RUN:cpu         READY         READY             1             1
>   6        BLOCKED       RUN:cpu         READY         READY             1             1
>   7*   RUN:io_done          DONE         READY         READY             1          
>   8         RUN:io          DONE         READY         READY             1          
>   9        BLOCKED          DONE       RUN:cpu         READY             1             1
>  10        BLOCKED          DONE       RUN:cpu         READY             1             1
>  11        BLOCKED          DONE       RUN:cpu         READY             1             1
>  12        BLOCKED          DONE       RUN:cpu         READY             1             1
>  13        BLOCKED          DONE       RUN:cpu         READY             1             1
>  14*   RUN:io_done          DONE          DONE         READY             1          
>  15         RUN:io          DONE          DONE         READY             1          
>  16        BLOCKED          DONE          DONE       RUN:cpu             1             1
>  17        BLOCKED          DONE          DONE       RUN:cpu             1             1
>  18        BLOCKED          DONE          DONE       RUN:cpu             1             1
>  19        BLOCKED          DONE          DONE       RUN:cpu             1             1
>  20        BLOCKED          DONE          DONE       RUN:cpu             1             1
>  21*   RUN:io_done          DONE          DONE          DONE             1          
> 
> Stats: Total Time 21
> Stats: CPU Busy 21 (100.00%)
> Stats: IO Busy  15 (71.43%)
> ~~~
> 
> 为什么运行完成IO的进程是好主意？当然是因为这样能够让利用率更高，它之后还会运行IO，所以可以把CPU交给其他人用。

> [!question]- 8\. Now run with some randomly generated processes: `-s 1 -l 3:50,3:50` or `-s 2 -l 3:50,3:50` or `-s 3 -l 3:50,3:50`. See if you can predict how the trace will turn out. What happens when you use the flag `-I IO_RUN_IMMEDIATE` vs. `-I IO_RUN_LATER`? What happens when you use `-S SWITCH_ON_IO` vs. `-S SWITCH_ON_END`?
> 最后这题没什么新东西。就是之前所有的综合情况。这里直接给结果了：
> 
> ~~~shell
> ❯ ./process-run.py -s 1 -l 3:50,3:50 -cp
> Time        PID: 0        PID: 1           CPU           IOs
>   1        RUN:cpu         READY             1          
>   2         RUN:io         READY             1          
>   3        BLOCKED       RUN:cpu             1             1
>   4        BLOCKED       RUN:cpu             1             1
>   5        BLOCKED       RUN:cpu             1             1
>   6        BLOCKED          DONE                           1
>   7        BLOCKED          DONE                           1
>   8*   RUN:io_done          DONE             1          
>   9         RUN:io          DONE             1          
>  10        BLOCKED          DONE                           1
>  11        BLOCKED          DONE                           1
>  12        BLOCKED          DONE                           1
>  13        BLOCKED          DONE                           1
>  14        BLOCKED          DONE                           1
>  15*   RUN:io_done          DONE             1          
> 
> Stats: Total Time 15
> Stats: CPU Busy 8 (53.33%)
> Stats: IO Busy  10 (66.67%)
> ~~~
> 
> ~~~shell
> ❯ ./process-run.py -s 2 -l 3:50,3:50 -cp
> Time        PID: 0        PID: 1           CPU           IOs
>   1         RUN:io         READY             1          
>   2        BLOCKED       RUN:cpu             1             1
>   3        BLOCKED        RUN:io             1             1
>   4        BLOCKED       BLOCKED                           2
>   5        BLOCKED       BLOCKED                           2
>   6        BLOCKED       BLOCKED                           2
>   7*   RUN:io_done       BLOCKED             1             1
>   8         RUN:io       BLOCKED             1             1
>   9*       BLOCKED   RUN:io_done             1             1
>  10        BLOCKED        RUN:io             1             1
>  11        BLOCKED       BLOCKED                           2
>  12        BLOCKED       BLOCKED                           2
>  13        BLOCKED       BLOCKED                           2
>  14*   RUN:io_done       BLOCKED             1             1
>  15        RUN:cpu       BLOCKED             1             1
>  16*          DONE   RUN:io_done             1          
> 
> Stats: Total Time 16
> Stats: CPU Busy 10 (62.50%)
> Stats: IO Busy  14 (87.50%)
> ~~~
> 
> ~~~shell
> ❯ ./process-run.py -s 3 -l 3:50,3:50 -cp
> Time        PID: 0        PID: 1           CPU           IOs
>   1        RUN:cpu         READY             1          
>   2         RUN:io         READY             1          
>   3        BLOCKED        RUN:io             1             1
>   4        BLOCKED       BLOCKED                           2
>   5        BLOCKED       BLOCKED                           2
>   6        BLOCKED       BLOCKED                           2
>   7        BLOCKED       BLOCKED                           2
>   8*   RUN:io_done       BLOCKED             1             1
>   9*       RUN:cpu         READY             1          
>  10           DONE   RUN:io_done             1          
>  11           DONE        RUN:io             1          
>  12           DONE       BLOCKED                           1
>  13           DONE       BLOCKED                           1
>  14           DONE       BLOCKED                           1
>  15           DONE       BLOCKED                           1
>  16           DONE       BLOCKED                           1
>  17*          DONE   RUN:io_done             1          
>  18           DONE       RUN:cpu             1          
> 
> Stats: Total Time 18
> Stats: CPU Busy 9 (50.00%)
> Stats: IO Busy  11 (61.11%)
> ~~~

