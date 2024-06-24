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

- [ ] #TODO tasktodo1719252003499 验证一下，Linux内核里的`task_struct`是不是也是这个东西。 ➕ 2024-06-25 🔽 🆔 lnwsl1

回到代码中，一开始的这个context，看注释：the registers xv6 will save and restore to stop and subsequently restart a process. 意思就是说，是为了恢复进程的。比如一个进程停止了，这些寄存器里的东西就会被保存到内存中。等要继续的时候，就再从内存里放回寄存器。这个东西其实就是之后要讨论的上下文切换。

除此之外，还可以看到进程的状态也不止提到的那三个。

- initial：正在创建的进程有的状态。比如上面的`EMBRYO`（胚胎）；
- final：进程已经结束了，但是还没被清理。比如上面的`ZOMBIE`。

对于zombie，需要特别强调。首先是这里的清理，不是代表这个进程的内存。它已经不占内存了，因为都已经结束了。它占的是进程列表中的一项；其次是什么时候才是僵尸态。比如线程，主线程调用join来等待它派生出来的线程结束。进程也是一样的，父进程会调用waitXXX来等待子进程结束。而如果父进程忘了调用wait，子进程就会一直保持僵尸状态。

