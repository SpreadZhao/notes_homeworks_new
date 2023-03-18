---
author: "Spread Zhao"
title: os
category: inter_class
description: 操作系统课堂笔记，李航老师
---

# 操作系统笔记

## 1. Process

### 1.1 Definition

​	An abstraction of a running program

### 1.2 Internal Structure

* Code Segment(Read-Only)

* Stack Segment

* Data Segment

* Address Space

* PCB

  > 分区：方便安全

### 1.3 Address Space: 进程之间互不相干

* Kernel Space：系统内核
* User Space：应用程序
* Kernel Mode = Kernel Space + Kernel Privilege
* User Mode = User Space + User Privilege
* Kernel Mode和User Mode区别：<u>Kernel下代码可访问硬件</u>

### 1.4 PCB - Process Control Block

* 开2个记事本，咋知道关的是哪一个 -> 通过PCB中的PID

### 1.5 Program和Process区别

* Program 有 Code Segment, Data Segment, Address Space, **没有 PCB, Stack Segment**

### 1.6 Stack Segment

​		比如 a() 调用 b() 再调用 c(), c() 里有变量t1, t2, t3, b() 里有y1, y2, y3, 则**c() 最后执行，最先执行完毕，t1, t2, t3 最先被分配，最先被释放，正好使用stack管理。**下面是一个例子：

 ```c
 #include <stdio.h>
 #include <string.h>
 int f(char* p){
     long low;	//long在c中是8byte
     long str;
     long top;
     
     low = 1;
     top = 3;
     strncpy((char*)(&str), p, 16);	//现在拷贝16byte
     return 1;
 }
 
 //main会覆盖top还是low呢？
 int main(){
     char mstr[16];
     printf("size of long %ld\n", sizeof(long));
     strncpy(mstr, "12345678abcdefgh", 16);
     f(mstr);
 }
 ```

​		在上面的例子中，我们首先需要了解英特尔的CPU架构：

![[Operating System/img/intelcpu.png|300]]

由于是从低地址拷贝到高地址，因此拷贝的16byte会将low覆盖。**同时我们也能看出，Stack Segment存放的是局部变量和函数的返回地址**

### 1.7 Process Model

​		一会儿切一个Process在CPU的一个核上

![[Operating System/img/processmodel.png]]

### 1.8 Process State

![[Operating System/img/processstate.png]]

#### 1.8.1 Process Creation

> **`pstree`命令，可以看到, 由 systemd(1号)生成其他进程**

##### 1.8.1.1 Four time for creation

* System Initialization

  > 通过1号Process生成其他Process参与初始化界面等

* Execution of a process creation system call by a running process

  > 用系统调用通过一个运行的Process生成另一个Process, **fork()**

* A user request to create a new process

  > 比如./haha

* Initiation of a batch job (批处理任务)

  > 比如bash

##### 1.8.1.2 Implementation-Creation: fork, exec

* Fork

  > Code
  >
  > ```c
  > #include <unistd.h>
  > #include <stdio.h>
  > int main(){
  >    pid_t pid;
  >    /* 子进程拿到的pid是0 */
  >    pid = fork();
  >    /* 父进程拿到的pid是子进程的，>0 */
  > 
  >    //子进程会走这里
  >    if(pid == 0){
  >        while(1){
  >            sleep(1);
  >            printf("Kylin\n");
  >        }
  >    }
  >    //父进程会走这里
  >    if(pid > 0){
  >        while(1){
  >            sleep(1);
  >            printf("My Favorite\n");
  >        }
  >    }
  > }
  > ```
  >
  > Result
  
![[Operating System/img/myfvkylin.png|100]]

  >
  > **注意：子进程从fork返回处开始执行**
  >
  > #question 子进程的PID是0是不是因为从返回处开始执行，导致没有初始化呢？（普通中断/缺页中断）
  >
  > Another example 
  >
  > ```c
  > #include <unistd.h>
  > #include <stdio.h>
  > int main(){
  > 	pid_t pid;
  > 	pid = fork();
  > 
  >     if(pid == 0){
  >         sleep(1);
  >         printf("Kylin\n");
  >     }
  > 
  >     sleep(1);
  >     printf("My Favorite\n");
  > }
  > ```
  >
  > * Question: 该程序会打印几次Kylin，几次My Favorite？
  > * Ans: 1, 2(父进程不会走\==0，只会打My Favorite，子进程即打Kylin，也打My Favorite)
  >
  > Another Question
  >
  > 对于下面的程序，程序执行完成后，会产生几个进程？
  >
  > ```c
  > int main(){
  >     pid_t pid;
  >     int i;
  >     for(i = 0; i < 2; i++){
  >         pid = fork();
  >     }
  > }
  > ```
  >
  > 首先看父进程。假设它是1号，从0开始，到2，会执行两次`fork`，产生两个子进程2号和3号；2号是在`i = 0`的时候创建的，那么2号会**从`fork`的返回处开始执行**，也就是一上来就执行`i++`，i变成1，那么2号就只会执行一次`fork`，产生一个4号；对于3号，它是在1号的`i = 1`的时候开始创建的，并且也是从返回处开始执行，那么3号先`i++`变成2，发现不满足条件，则3号一次`fork`也不会执行；4号进程的i和3号一样是1，那么人生经历和3号一样也不会执行`fork`。那么1, 2, 3, 4一共4个进程会被产生

* Execl

  > **不会生成Process，在子进程中使用，用于替换代码，用新的，和父进程不一样的**
  >
  > Code
  >
  > ```c
  > #include <unistd.h>
  > #include <stdio.h>
  > int main(){
  >      pid_t pid;
  >      pid = fork();
  > 
  >      if(pid == 0){
  >          /*
  >            子进程会执行"ls -l"命令，不会打
  >            haha，因为execl就是子进程的尽头
  >          */
  >          execl("/bin/ls", "-l", 0);
  >          printf("haha\n");
  >      }
  > 
  >      /* 父进程pid > 0，不断打出hehe */
  >      while(1){
  >          sleep(1);
  >          printf("hehe\n");
  >      }
  > }
  > ```
  >
  > 问题：
  >
  > Result
  >
  > ![[Operating System/img/execl.png]]

#### 1.8.2 Process Termination

时机

* Normal exit (voluntary) **老死**

* Error exit (voluntary) **病死， 打开程序发现打不开，有个返回码**

* Fatal error (involuntary) **事故死， 非法访问，被OS干掉**

* Killed by another process (involuntary) **谋杀**

  >Fatal Error
  >
  >```c
  >#include <unistd.h>
  >#include <stdio.h>
  >int main(){
  >        char* p;
  >        p = 0x0;
  >        *p = 'a';
  >        while(1){
  >            sleep(1);
  >            printf("haha\n");
  >        }
  >}
  >```
  >
  >Result
  >
  >![[Operating System/img/fatalerror.png]]
  >
  >Reason
  >
  >* OS强制退出，因为访问了不让访问的0x0

  >Kill Process
  >
  >`kill -9 <pid> //-9表示杀掉，kill只是发指令`
  >
  >现在有一个进程是3539号
  >
  >* 当`kill -9 3539`后的状态
  >
  >  ![[Operating System/img/kill3539.png]]
  >
  >* 与此同时，看到3539变为僵尸态
  >
  >  ![[Operating System/img/3539zb.png]]
  >
  >现在有俩进程，3700的父进程是3699
  >
  >* 若`kill -9 3699`(也就是把孩子他爸干掉)会
  >
  >  ![[Operating System/img/kill3699.png]]
  >
  >* 与此同时，发现这个孩子被1号进程接管
  >
  >  ![[Operating System/img/adopted.png]] ^467bf0

##### 1.8.2.1 Process Termination Implementation

* 尸检时

  > 释放Code Segment, Data Segment, Stack Segment

* 尸检完

  > 释放PCB(**Z+这种状态就在PCB里**)

* Address Space

  > 会释放Page Table

* PCB里的内容

  ![[Operating System/img/pcbcontent.png]]

### 1.9 Process Model Implementation

#### 1.9.1 Process Switching

![[Operating System/img/psswitch.png]]

## 2. Thread

### 2.1 An example

```c
#include <stdio.h>
#include <pthread.h>

int a;

void* th(void* p){
    int i = 0;
    while(1){
        a = 1; i++;
        sleep(1);
        if(i <= 5){
            printf("haha\n");
        }
    }
}

int main(){
    int i = 0;
    a = 0;
    pthread_t myth;
    pthread_create(&myth, NULL, th, NULL);
    while(1){
        i++; sleep(1);
        if(i <= 5) printf("a = %d, hehe\n", a);
    }
}
```

Result

![[Operating System/img/threadhaha.png]]

### 2.2 Definition

>进程中正在执行的代码片段，其可以与其他片段并发执行
>
>**<u>一个Process的不同Thread不共享Stack</u>**

### 2.3 Thread Model

![[Operating System/img/threadmodel.png]]

### 2.4 Why Thread?

1. 在一个application里有多个活动，其中一些会block，这时把app分成几个能并行的顺序线程，模型会更简单
2. Thread比Process更容易创建/消除
3. ![[Operating System/img/whythread3.png]]
4. Finally, threads are useful on systems with multiple CPUs, where real parallelism is possible.

### 2.5 Implementation of  thread model

* TCB(Thread Control Block)

![[Operating System/img/tcb.png]]

* Three Implementation Way

  1. In User Space

![[Operating System/img/tinus.png]]

**优点**

* 可在不支持Thread的OS上实现
* 线程切换快，不用陷入内核

#question 线程切换不需要靠系统调用来实现吗？如果要靠系统调用的话，不是还需要陷入到内核空间中吗？

* 允许每个Thread有自己的Scheduling Algorithm
* 有较好的可扩展性

问题：如何实现阻塞系统调用

![[Operating System/img/howsyscall.png]]
  
  2. In Kernel Space
  
![[Operating System/img/tinks.png]]
  
* 创建Thread要用系统调用，进入Kernel Space
* Process Table保存每个Process的状态等

![[Operating System/img/tinkspb.png]]
  
  3. Hybrid
  
![[Operating System/img/thybrid.png]]
  
![[Operating System/img/thbdpb.png]]

### 2.6 POSIX Thread-学会！

* IEEE定义的线程包：pthread

![[Operating System/img/tphread.png]]

* Why POSIX?

  > 可移植，通用

### 2.7 Pop-Up Thread

* Definition, Advantage

![[Operating System/img/pptd.png]]

![[Operating System/img/pptd2.png]]

* Why Pop-Up Thread?

  >One reason: remove block
  >
  >传统：将Process或Thread阻塞在一个receive系统调用上，等待message，而Pop-Up Thread在message来时才创建，remove了block

## 3. IPC(Inter Process Communication)

### 3.1 Race Conditions

![[Operating System/img/rccd.png]]

### 3.2 Critical Region

>**The part of the program where the shared memory is accessed is called the critical region**

### 3.3 How to avoid race conditions?

* Mutual Exclusion(十字路口)

  >Avoid two processes access critical region at the same time

* **Implementation**

  * **需要满足以下几个时机**

    1. No two processes may be simutaneously inside their critical regions

       >**不同时在critical region**

    2. No assumptions may be made about speeds of the number of CPUs

       >**要是假设了，移植性不好。因为CPU很快，在快的机子上好使，在慢的上就不行**
       >
       >*一个十字路口，一辆车超快，一辆车超慢，那快的wu一下就过去了，根本不会有race condition，但是对于慢的机子，这俩车有多快就不一定了*

    3. No process running outside its critical region may block other processes

       >**不能在critical region里sleep(占着茅坑不拉屎)**

    4. No process should have to wait forever to enter its critical region

       >**不能饿死**

  * Proposals for achieving mutual exclusion

    * Disabling interrupts

      >**关掉中断，CPU不处理中断处理，不执行Scheduling，其他Process都别想运行**
      >
      >*<u>不好，对CPU数量假设了，若有多个CPU，关了中断也没用，其它CPU上的Process还会运行</u>*

    * Lock variables

      1. Strict Alternation

![[Operating System/img/strictat.png]]

         >**缺点：2个Process/Thread的顺序是固定的，TURN有个初值，则一定是某一个人先来**

      2. Peterson's solution

![[Operating System/img/ptsolu.png]]

![[Operating System/img/tsl.png]]

      4. Another TSL - XCHG(Intel)

![[Operating System/img/xchg.png]]

         >**Exercise：gcc用C语言嵌入汇编语言**

    * TSL Busy Waiting缺点

      * 反复查锁，浪费CPU时间
      * Cause Priority inversion problem

  * 改进：发现别人上锁了，歇一会 -> **Sleep and Wakeup**

    * Implementation - with Producer Consumer

      ```c
      #define N 100	/*number of slots in the buffer*/
      int count = 0;	/*number of items in the buffer*/
      
      void producer(void){
          int item;
          while (TRUE) { 	/*repeat forever*/
              item = produce item(); 			/*generate next item*/
              if (count == N) sleep(); 			/*if buffer is full, go to sleep*/
              inser t item(item); 				/*put item in buffer*/
              count = count + 1; 					/*increment count of items in buffer*/
              if (count == 1) wakeup(consumer); 	/*was buffer empty?*/
      	}
      }
      
      void consumer(void)
      {
          int item;
          while (TRUE) { 							/*repeat forever*/
              if (count == 0) sleep(); 			/*if buffer is empty, got to sleep*/
              item = remove item(); 				/*take item out of buffer*/
              count = count − 1; 					/*decrement count of items in buffer*/
              if (count == N − 1) wakeup(producer); /*was buffer full?*/
              consume item(item); 				/*pr int item*/
          }
      }
      ```

      >  **问题：若comsumer先来，count == 0，<u>正要sleep但还没sleep的时候</u>，Process切换到producer，最后wakeup，但这时consumer还没睡呢，导致<u>信号丢失</u>。之后，consumer睡了，producer把仓库填满后也睡了，永远睡下去**

    * 改进 - Semaphore

      ```c
      #define N 100							/*number of slots in the buffer*/
      typedef int semaphore; 					/*semaphores are a special kind of int*/
      semaphore mutex = 1;					 /*controls access to critical region*/
      semaphore empty = N; 					/*counts empty buffer slots*/
      semaphore full = 0; 					/*counts full buffer slots*/
      
      void producer(void){
          int item;
          while (TRUE) { 						/*TRUE is the constant 1*/
              item = produce item(); 		/*generate something to put in buffer*/
              down(&empty); 					/*decrement empty count*/
              down(&mutex); 					/*enter critical region*/
              insert item(item); 			/*put new item in buffer*/
              up(&mutex); 					/*leave critical region*/
              up(&full); 						/*increment count of full slots*/
          }
      }
      
      void consumer(void)
      {
          int item;
          while (TRUE) { /*infinite loop*/
              down(&full); 					/*decrement full count*/
              down(&mutex); 					/*enter critical region*/
              item = remove item( ); 			/*take item from buffer*/
              up(&mutex); 					/*leave critical region*/
              up(&empty); 					/*increment count of empty slots*/
              consume item(item); 			/*do something with the item*/
          }
      }
      ```

      >**down：-1，若减完>0,继续；=0，继续，但不能再down了;<0，把自己放进睡眠队列**

      **Semaphore - System Call**

      >Code

![[Operating System/img/semacode.png]]
      >
      >Result
      >
![[Operating System/img/semares.png]]

  2个Process和Semaphore
  
![[Operating System/img/twosem.png]]
  
  使用GDB调试
  
![[Operating System/img/semgdb.png]]

    * Semaphore Disadvantage
    
      >**实现在Kernel Space**，生成和消除代价高
    
  * Mutex: Simplified Semaphore

    >**实现在User Space**

    Pthread Calls

    | Thread call           | Description                 |
    | --------------------- | --------------------------- |
    | Pthread_mutex_init    | Create a mutex              |
    | Pthread_mutex_destroy | Destroy an existion mutex   |
    | Pthread_mutex_lock    | Acquire a lock or **block** |
    | Pthread_mutex_trylock | Acquire a lock or **fail**  |
    | Pthread_mutex_unlock  | Release a lock              |

    #question linuxStudy/mutex.c为什么两个in？

    Example

    ![[Operating System/img/mutexex.png]]

  * Mutex, Semaphore区别
  
  * 量级
  
* **Mutex进程完了就没了，除非塞到Share Memory**
  
  * Mutex Implementation in ASM
  
    ```assembly
    mutex lock:
        TSL REGISTER,MUTEX 				 ; copy mutex to register and set mutex to 1
        CMP REGISTER,#0 				 ; was mutex zero?
        JZE ok 							; if it was zero, mutex was unlocked, so return
        CALL thread yield 				 ; mutex is busy; schedule another thread
        JMP mutex lock 					 ; try again
    ok: RET 							; return to caller; critical region entered
    mutex unlock:
        MOVE MUTEX,#0 					 ; store a 0 in mutex
      RET 							; return to caller
    ```
  ```
  
  ```
  
* Mutex Other: Conditional Variables
  
  ![[Operating System/img/cdvb.png]]
  
  ![[Operating System/img/cdvb2.png]]
  
  * Monitor
  
    >**Semaphore problem: easy to <u>deadlock</u>**
    >
    >What is Dead lock?
    >
    >![[Operating System/img/ddlk.png]]
    >
    >结论：
  >
  >​	**使用Semaphore要小心**
  
  Solution: High level abstraction
  
  >A monitor is **a collection of procedures, variables, and data structures** that are all **grouped together** in a special kind of module or package. Processes may call the procedures in a monitor whenever they want to, but they **can't directly access the monitor's internal data structures** from procedures declared outside the monitor.
  
  **Monitor Important Feature**
  
  > Only one process can be active *in a monitor* at any instant.
  
    Example - Pascal语言
  
    ```pascal
    monitor example
    	integer i;
    	condition c;
    	
    	procedure producer();
    	.
    	.
    	.
    	end;
    	
    	procedure consumer();
    	.
    	end;
  end monitor;
    ```
  
    Monitor - Pseudo Pascal
  
    ```pascal
    monitor ProducerConsumer
        condition full, empty;
        integer count;
        
        procedure insert(item: integer);
        begin
            if count = N then wait(full);
            insert item(item);
            count := count + 1;
            if count = 1 then signal(empty)
        end;
        
        function remove: integer;
        begin
            if count = 0 then wait(empty);
            remove = remove item;
            count := count − 1;
            if count = N − 1 then signal(full)
        end;
        
        count := 0;
    end monitor;
    
    procedure producer;
    begin
        while true do
        begin
            item = produce item;
            ProducerConsumer.insert(item)
        end
    end;
    
    procedure consumer;
    begin
        while true do
        begin
            item = ProducerConsumer.remove;
            consume item(item)
    	end
  end;
    ```
  
    Monitor - Java(synchronized)
  
    ```java
    public class ProducerConsumer {
        static final int N = 100; 						// constant giving the buffer size
        static producer p = new producer(); 			 // instantiate a new producer thread
        static consumer c = new consumer();			 // instantiate a new consumer thread
        static our monitor mon = new our monitor();	  // instantiate a new monitor
        
        public static void main(String args[]) {
            p.start(); 									// start the producer thread
            c.start(); 									// start the consumer thread
        }
        
        static class producer extends Thread {
            public void run() {						// run method contains the thread code
                int item;
                while (true) { 						// producer loop
                    item = produce_item();
                    mon.insert(item);
                }
            }
            private int produce_item() { ... } 		// actually produce
        }
        
        static class consumer extends Thread {
            public void run() {					//run method contains the thread code
                int item;
                while (true) { 							// consumer loop
                    item = mon.remove();
                    consume_item (item);
                }
            }
            private void consume_item(int item) { ... }	// actually consume
        }
        
        static class our monitor { 						// this is a monitor
            private int buffer[] = new int[N];
            private int count = 0, lo = 0, hi = 0; 		 // counters and indices
            public synchronized void insert(int val) {
                if (count == N) go to sleep(); 	 // if the buffer is full, go to sleep
                buffer [hi] = val; 					// inser t an item into the buffer
                hi = (hi + 1) % N; 					// slot to place next item in
                count = count + 1; 					// one more item in the buffer now
                if (count == 1) notify();			 // if consumer was sleeping, wake it up
        	}
            
            public synchronized int remove() {
                int val;
                if (count == 0) go to sleep(); 		// if the buffer is empty, go to sleep
                val = buffer [lo]; 					// fetch an item from the buffer
                lo = (lo + 1) % N; 					// slot to fetch next item from
                count = count − 1;					 // one few items in the buffer
                if (count == N − 1) notify(); 		// if producer was sleeping, wake it up
                return val;
            }
            private void go_to_sleep() { 
                try{wait();} catch(InterruptedException exc) {};}
            }
  }
    ```
  
* Message Passing
  
    Monitor Disadvantage
  
    >Monitor之间也需要互斥，因为管程也是一个编程语言概念，**编译器必须要识别管程并用某种方式对其互斥进行安排**。但实际中，**如何让编译器知道哪些过程属于管程，哪些不属于？**
    >
    >如果一个分布式系统具有多个CPU，并且每个CPU拥有自己的私有内存，他们通过一个局域网相连，那么，这些原语将失效。这里的结论是：Semaphore太低级了，而管程在少数几种编程语言之外又无法使用，并且，这些原语均未提供机器间的信息交换方法，所以还需要其他的方法——Message Passing
  >
  >即，Monitor，Semaphore, Mutex解决的也都是一台电脑内部的Process, Thread互斥，没解决多台电脑合作时的互斥
  
  Message Passing System Call
  
    * 像Semaphore而不像Monitor，是系统调用而不是语言成分
  
      > Message Passing使用两条原语来实现**进程**间通信
      >
      > ```c
      > send(destination, &message);
      <<<<<<< HEAD
      > ```
    > receive(source, &message);
    >
    > ```
    > 
    > ```
  =======
  
  
  
    > ```
    > receive(source, &message);
    > ```
>>>>>>> fedd9a90e1940e19af66713c598e24ed60a3434c

    * Example
      
      ```c
      #define N 100							/*number of slots in the buffer*/
      void producer(void)
      {
          int item;
          message m; 							/*message buffer*/
          while (TRUE) {
              item = produce item();			 /*generate something to put in buffer*/
              receive(consumer, &m); 			 /*wait for an empty to arrive*/
              build_message(&m, item); 		 /*construct a message to send*/
              send(consumer, &m);				 /*send item to consumer*/
          }
      }
      void consumer(void)
      {
          int item, i;
          message m;
          for (i = 0; i < N; i++) send(producer, &m); 	  /*send N empties*/
          while (TRUE) {
              receive(producer, &m); 						/*get message containing item*/
              item = extract_item(&m); 					/*extract item from message*/
              send(producer, &m); 						/*send back empty reply*/
              consume_item(item); 						/*do something with the item*/
          }
      }
      ```

  * Barriers
  
    用于一组Process同步
  
![[Operating System/img/barrier.png]]

## 4. Scheduling

* 用于所有Process之间(之前的IPC是两个或几个Process之间)

### 4.1 Problem

* **一些Process已经就绪，哪个该放到CPU上跑呢？**
* **调度为何不是时时刻刻发生，而是有间隔的发生？**

### 4.2 When to Schedule?

* Process creation
* Process exit
* Process blocks on I/O
* I/O interrupt (**比如网络包到了，会发一个中断，运行接包的Process**)

### 4.3 Scheduling Algorithm

>Category
>
>1. Preemptive vs Non-Preemptive
>
>2. Batch
>
>>批处理任务执行的好，就是
>>
>>* Throughput(吞吐量) -> Max
>>* Turnaround time -> Min
>>* CPU utilization(利用率) -> Max
>
>3. Interactive
>
>4. Real time
>
>Ps
>
>* Throughput - the number of processes that complete their execution per time unit
>* Turnaround time - the interval from submission to completion
>* Waiting time - amount of time a process has been waiting in the ready queue
>* Response time - amount of time it takes from when a request was submitted unitl the first response is produced, not output (for time-sharing environment)

#### 4.3.1 FCFS Example

| Process | Burst Time |
| ------- | ---------- |
| P1      | 24         |
| P2      | 3          |
| P3      | 3          |

Arrive order: P1, P2, P3

解决思路：画Gannt Chart

![[Operating System/img/fcfsgc.png]]

Turnaround time for

> P1 = 24; P2 = 27; P3 = 30

Average turnaround time

> (24 + 27 + 30) / 3 = 27

#### 4.3.2 SJF Example(Non Preemptive)

| Process | Arrival Time | Burst Time |
| ------- | ------------ | ---------- |
| P1      | 0.0          | 7          |
| P2      | 2.0          | 4          |
| P3      | 4.0          | 1          |
| P4      | 5.0          | 4          |

* 因为P1先到，到的时候P2, P3, P4还没来，所以先P1
* P1完事，此时，P2, P3, P4都来了，选最短的P3先来

Gannt Chart

![[Operating System/img/sjfnpgc.png]]

Average turnaround time

>[(7 - 0) + (8 - 4) + (12 - 2) + (16 - 5)] / 4 = 8

#### 4.3.3 SJF Example(Preemptive)

| Process | Arrival Time | Burst Time |
| ------- | ------------ | ---------- |
| P1      | 0.0          | 7          |
| P2      | 2.0          | 4          |
| P3      | 4.0          | 1          |
| P4      | 5.0          | 4          |

* P1先来，2s后，P2来了，P1还剩5s，但是P2只用4s，所以先P2
* P2运行2s后，P3又来了，此时P1->5s, P2->2s, P3->1s, 所以P3
* 1s后，P3完事，P4来，此时P2->2s, P1->5s, P4->4s，所以先P2, 后P4，最后P1

Gannt Chart

![[Operating System/img/sjfpgc.png]]

Average turnaround time

>[(16 - 0) + (7 - 2) + (5 - 4) + (11 - 5) / 4]  = 7

### 4.4 Interactive System Scheduling

#### 4.4.1 Round Robin

![[Operating System/img/rr.png]]

#### 4.4.2 Priority Scheduling

![[Operating System/img/prioritysc.png]]

#### 4.4.3 Multiple Queue

![[Operating System/img/mqueue.png]]

#### 4.4.4 Guaranteed Scheduling

若Process已经Ready，保证10s内能运行1s

> He gives you a "promise" and make sure he will keep it.
>
> * Example
>   * Promise: n processes in system, each will get 1/n CPU time
>   * Resource Reservation Scheduling Algorithms

**应用：花多少米，得多少时间**

#### 4.4.5 Lottery Scheduling

* Give processes lottery tickets for various system resources, such as CPU time
* Whenever a scheduling decision has to be made, a lottery ticket is chosen at random, and **the process holding that ticket gets the resource**

#### 4.4.6 Fair-Share Scheduling(FSS)

* 可以看做Guaranteed Scheduling的特例
* A和B交一样钱，但是A有10000000个Process，B就1个，则CPU全被A给抢了，那么就要保证A和B不管有几个Process，CPU时间都要平分

#### 4.4.7 Real-Time Scheduling

* Hard Real-Time：必须在时限前搞定(**飞机计算，否则飞机炸**)
* Soft Real-Time：可以通融(**网络视频，卡了还行**)

### 4.5 Schedulable

>可调度序列
>
>There's existed one scheduling sequence that make **every process** meet their deadline

### 4.6 Policy Versus Mechanism

Separate the scheduling mechanism from the scheduling policy

* Key Idea: User can decide which scheduling algorithm is to use

* Scheduling algorithm is parameterized in some way, but the parameters can be filled in by user processes

  > **Exercise: 把Thread绑到CPU的一个核上(Linux)**

### 4.7 Thread Scheduling

| Implementation in: | Kernel Space | User Space                      |
| ------------------ | ------------ | ------------------------------- |
| Cost               | Big          | Small                           |
| Other              | /            | 可实现应用特定Scheduler，效果好 |

#question 为啥实现在Kernel Space进行线程调度的开销大呢？不是应该取决于我这个线程放在用户空间还是内核空间吗？如果线程本来就是放在内核空间的，那么在内核空间调度内核空间的线程花费应该是更少的吧

## 5. Classical IPC Problems

### 5.1 Dining Philosophers Problem

* 哲学家：吃/思考
* 吃需要2个fork
* 一次拿一个fork
* 解决问题，还要防止deadlock

A wrong solution - may cause deadlock

```c
#define N 5 								/*number of philosophers*/
void philosopher(int i) 					 /*i: philosopher number, from 0 to 4*/
{
    while (TRUE) {
        think(); 							/*philosopher is thinking*/
        take fork(i); 						/*take left for k*/
        take fork((i+1) % N); 				 /*take right for k; % is modulo operator*/
        eat(); 								/*yum-yum, spaghetti*/
        put fork(i); 						/*put left for k back on the table*/
        put fork((i+1) % N); 				 /*put right for k back on the table*/
    }
}
```

**如果5个人都拿左边的fork，全部sleep -> deadlock**

解决：引入中控

![[Operating System/img/eatf.png]]

> IPC Design
>
> * Prevent deadlock
> * 尽量多并发

### 5.2 Readers and writers Problem

![[Operating System/img/raw.png]]

**如果有读者，那么读者随便进，写者不能进，因为后来的读者，rc != 1，不会走down(&db)这句话**

### 5.3 Sleeping Barber

* 理发店里有一位理发师、一把理发椅和n把供等候理发的顾客坐的椅子
* 如果没有顾客，理发师便在理发椅上睡觉
* 一个顾客到来时，它必须叫醒理发师
* 如果理发师正在理发时又有顾客来到，则如果有空椅子可坐，就坐下来等待，否则就离开

```c
#define CHAIRS 5               /* # chairs for waiting customers */
typedef int semaphore;         /* use your imagination */
semaphore customers = 0;       /* # of customers waiting for service */
semaphore barbers = 0;         /* # of barbers waiting for customers */
semaphore mutex = 1;           /* for mutual exclusion */

//critical region
int waiting = 0;               /* customers are waiting (not being cut) */
 
void barber(void){
    white (TRUE) {
        /**
        * 没有顾客，睡觉；
        * 有顾客，down完还要接着剪
        */
        down(&customers);      /* go to sleep if # of customers is 0 */
        
        /* 若能执行到这儿，waiting肯定被加了 */
        down(&mutex);          /* acquire access to 'waiting' */
        waiting = waiting − 1; /* decrement count of waiting customers */
        up(&barbers);          /* one barber is now ready to cut hair */
        up(&mutex);            /* release 'waiting' */
        
        cut_hair();            /* cut hair (outside critical region) */
    }
}
 
void customer(void){
    down(&mutex);              /* enter critical region */
    if (waiting < CHAIRS) {    /* if there are no free chairs, leave */
        
        //抢椅子
        waiting = waiting + 1; /* increment count of waiting customers */
        
        up(&customers);        /* wake up barber if necessary */
        up(&mutex);            /* release access to 'waiting' */
        down(&barbers);        /* go to sleep if # of free barbers is 0 */
        get_haircut();         /* be seated and be serviced */
    } else {
        //椅子满，走人
        up(&mutex);            /* shop is full; do not wait */
    }
}
```

### 5.4 Driver and  Seller

原则

* IPC -> 同步，互斥，同步互斥
* 同步：semaphore初值为0，需要等别人的进程要p操作，被别人等的进程要v操作
* 互斥：semaphore初值为进程数量

```c
//司机和售票员问题
Semaphore driver = 0, door = 0;

/*
 司机的活动：启动车辆，正常行车，到站停车
 售票员的活动：关车门，售票，开车门
 	注意：当发车时间到，售票员关门后司机才能开车，售票员开始售票；
 	到站时，司机停车后，售票员才能打开车门
*/
Driver(){
    /* 要等售票员关门后才能开车，等别人 */
    P(drive);
    
    Drive();
    CarMove();
    Stop();
    
    /* 停车后允许售票员开门 */
    V(door);
}

Ticket_Seller(){
    DoorClose();
    
    /* 关门后允许司机开车 */
    V(drive);
    SellTicket();
    
    /* 要等司机停车后才能开门，等别人 */
    P(door);
    DoorOpen();
}
```

## 6. Memory Management

### 6.1 MM Overview

#### 6.1.1 **What will happen if no Memory Abstraction?**

![[Operating System/img/noma.png]]

#### **6.1.2 How to solve?**

Propose an Abstract Concept - **Address Space**

> **Each process have its own space, whose address starts at  0**

Implementation: Use **Static relocation(静态重定位)**

> 若一个Process装在16384号上，则该程序的每一个程序地址加上16384，则1号就是16385
>
> **Static relocation Problem**
>
> ![[Operating System/img/sr.png]]

#### 6.1.3 **Memory Abstraction**

Solution of Static relocation Problem -> **Dynamic**

How to implement address space?

> **Base register + Limit register**

**Base and Limit Registers**

![[Operating System/img/dyrc.png]]

Proplems all solved?

* No!!!
  * <u>What to do if we **have not enough memory when running multiple programs?**</u>

Use Swap

> Swap
>
> *Bringing in each process in its entirety, running it for a while, then putting it back on the disk*

![[Operating System/img/swap.png]]

Swap Problem<a name = "downward" ></a>

产生空洞(hole, Fragment, 即上图中的阴影)，消掉要把所有Process向下移动(downward)，称为Memory Compaction(内存紧缩)，但是这样做会**浪费CPU时间**

Another Problem

* Dynamic relocation Problem

![[Operating System/img/drp.png]]

#### 6.1.4 Free Space Management(**Dynamic**)

* bit map & list

![[Operating System/img/bl.png]]

* 对于list的升级：List Management

  当X结束时，更改List

![[Operating System/img/gglist.png]]

* Four methods to insert A new Process

  1. First Fit: 找第一个合适的洞
  2. Next Fit: **slightly worse than First Fit**
  3. Best Fit: **比First Fit慢，比First Fit和Next Fit浪费内存，产生大量小空闲区**
  4. Worst Fit: 选最大的洞

  >As an example of first fit and best fit, consider example forward again. If a block of size 2 is needed, first fit will allocate the hole at 5, but best fit will allocate the hole at 18

### 6.2 Virtual Memory

Problem

* If program is too large, bigger than main memory, what will happen?
* Swap --- Address in program may need modification when swapping

How to solve this Problem?

* **Virtual Memory?**

  > * Each program has **its own address space**, which is broken up into chunks called pages.
  > * Pages can be swapped out

MMU

![[Operating System/img/mmu.png]]

An Example

> 2个Process，都定义变量a，一个a是1，一个a是2，打印a的地址，发现地址相同，但是值明明不同
>
> -> **Virtual Address**

Why introduce Virtual Address?

1. 把进程地址空间分离，防止程序之间地址被共用或恶意攻击
2. 内存效率原来很低，会大量swap，现在swap就少了
3. 原来swap回来的Process的地址总是变

#### 6.2.1 **Paging**

![[Operating System/img/paging.png]]

#### **6.2.2 Virtual Address Translation**

![[Operating System/img/vat.png]]

假设虚拟地址64KB，物理地址32KB，4KB一个Page，则虚拟16Page，物理8Page

* 要翻译：0010 0000 0000 0100 (16bit)

  1. 除以4KB -> 2^12B并向下取整：

     > **也就是去掉末尾12位，只留前4位**
     >
     > 0010 -> VPage号，也就是2号VPage
     >
     > 其中的PPage：110 -> 6号

  2. 算虚拟地址的位置与虚拟页面(起始位置)的偏移量：

![[Operating System/img/vat2.png]]
     >
     > 则最终物理地址：<u>110</u> <u>0000 0000 0100</u>
     >
     > ​							   ^              ^
     >
     > ​						  PPage6    偏移量

**Page Table Entry**

![[Operating System/img/pta.png]]

加速分页

* TLB：转换检测缓冲区(Translation Lookaside Buffer)

  > 计算机的一个小型硬件设备，**将虚拟地址直接映射到物理地址，<u>而不必再访问页表</u>**，这种设备成为转换检测缓冲区(Translation Lookaside Buffer, TLB)，又称相联存储器(associate memory)，或快表，**通常在MMU中**，包含少量的表项
  >
![[Operating System/img/tlb.png]]

Multilevel Page Tables

![[Operating System/img/mpt.png]]

Inverted Table

![[Operating System/img/ip.png]]

> 区别
>
> * 普通Page Table每一个Process一张
> * Inverted Table全局就一张

#### 6.2.3 Page Replacement Algorithms

Page Fault: 缺页中断(**Abscent位**)

* Optimal Page Replacement

  > 替换最久才会用到的Page，则Page Fault最少，抖动最小

  Ex: 内存访问序列：0 1 3 2 2 5 3 4 2 1，3个物理Page，计算Page Fault数

![[Operating System/img/opr.png]]

  PS：**这里的页面号都是虚拟的！！！**

  缺点：不可实现

* Least Recently Used(LRU)

  Ex: 内存访问序列：0 1 3 2 2 5 3 4 2 1，3个物理Page，计算Page Fault数

![[Operating System/img/lru.png]]

  LRU另一种图解

![[Operating System/img/lruan.png]]

  使用硬件模拟LRU

![[Operating System/img/lruhd.png]]

  硬件模拟缺点：管理成本巨大，Matrix太大

  近似LRU: NFU(Not Frequently Used)

  > 要个计数器，每个时钟中断，扫描所有Page，查每一个Page的R位，把R位值(0或1)加到计数器上，每次替换计数最少的

  NFU缺点

  * 在2个时钟中断之间，某个Page可能已经被访问多次
  * **It never forgets anything**

  NFU改进：Let it forget!

![[Operating System/img/lif.png]]

* NRU(Not Recently Used)

  * 使用R位和M位

  * 定期清零R位：最近没被访问过

  * M位不清零：假设1个Page要被换出去，**M位是0，表示<u>从磁盘加载进来后再也没改动过</u>，因此只需要释放掉再加新的；若是1，<u>则应先刷到磁盘上保存修改</u>**，然后才能换新的Page，这时候M位才能清零

  * 经过以上操作，所有Page被分为4类

    1. R = 0, M = 0 -> Not refferenced, not modified

    2. R = 0, M = 1 -> Not refferenced, modified

    3. R = 1, M = 0 -> Refferenced, not modified

    4. R = 1, M = 1 -> Refferenced, modified

       **从上到下，<u>被替换</u>优先级降低**

* Clock Page Replacement

![[Operating System/img/cpr.png]]

  > 为什么R位要Clear?
  >
  > 如果不Clear，那早晚所有的Page都会满

* Working Set Page Replacement

  Working Set：干什么事，访问的Page基本是固定的

  思想：替换那些**不是我干这件事儿时**访问的Page

  但是，OS不知道你经常访问哪些Page

  推测

![[Operating System/img/wspr.png]]

* WSClock = Clock + Working Set

![[Operating System/img/wscpr.png]]

* FIFO(First in First out)

  想象一个Stack，栈**底**的是最早访问的，替换它

  Disadvantage：随着内存增加，Page Fault数不降反生(**命中率低**)

* 改进FIFO: Second Chance

![[Operating System/img/sc.png]]

  > 栈底的元素的R位如果是
  >
  > * 0：拍死，换出去
  > * 1：再给次机会，放到栈顶

### 6.3 Design Issues

#### 6.3.1 Local & Global

![[Operating System/img/lg.png]]

> **Age: 上次访问的时刻，越小表示越久没用了**

#### 6.3.2 Page Fault Frequency(PFF)

![[Operating System/img/pff.png]]

> Page Fault越多，Page分配越多
>
> **前提(Precondition)：当前Process的Working Set不超过Memory Size，不然也没法儿多分Page，对吧！**
>
> 多分的Page肯定不是自己的，所以PFF建立在Global Replacement上

#### 6.3.3 Thrashing

一个Page刚被换出去，又要被访问，就又被换回来，然后又出去又回来……

Solution：加内存！

但是，要是没米捏？

* Reduce number of processes competing for memory

  > **原来5个Process同时，现在3个……**

* Swap one or more to disk, divide up pages they held

* Clean Policy：加速，降Page Fault

  > Page Fault数是命中率的指标 —— Spread Zhao

  不要等内存脏页满了才将脏页刷到磁盘上

  > **比如，保证任何时可都有10%free pages**

* **Page Size**

  当Page Size大了，Page Table就小，更好管理，但太大，一个Page Table浪费得多了

  为进程分配最优Page Size

  * s: 进程平均大小
  * p: 一个Page大小
  * 则s/p：一个Process要几个Page
  * **e：一个Page Table Entry大小**
  * 则se/p：一个Process**在内存中实现的大小**
  * p/2：在最后一个Page通常占不满

  则Overhead(开销) = se/p + p/2

  > **比如s = 10KB，一个Page4KB，e为4B，那么se/p + p/2 = 8B + 2KB，有必要？**
  >
  > 上面的疑惑，主要是因为s并不是10KB，是经过好多测量得出来的
  >
  > **se/p近似为Page Table大小**，p/2这个开销虽然是在Virtual Address Space中的浪费，但是**每个虚拟地址还是映射一个实际的物理地址啊**！比如s还是10KB，但Page若分成1个GB，那仅用1个Page Table Entry(4B)就能表示这10KB的程序，但是，**那些剩下的Page Table中的地方，还映射着物理地址，并且永远也不会被用到**
  >
  > 因此，Overhead可以写成
  >
  > Overhead = Page Table大小 + 浪费的虚拟地址的个数
  >
  > ​				 = Page Table大小 + 浪费的**物理**地址的个数
  >
  > ​				 =          se/p           +			   p/2
  >
  > p/2的计算：
  >
  > 一个Page有P个地址，从全空到全满，有P+1种情况，则等概率分布，期望
  >
  > E = \[1 / (p + 1)\] * (0 + 1 + ... + p) = p/2
  >
  > #question 为什么se/p不判一下s/p的余数是否为0

  之后，将Overhead两边对p求导，求出p(optimise) = 根号下2se

  **当s = 1MB，e = 8B时，算出p = 4KB**

#### 6.3.4 Increase Address Space

如果内存足够大，Single address Space就够了

![[Operating System/img/sas.png]]

但是不够咋办？

比如16位机子上，分成了Ispace，Dspace

![[Operating System/img/isds.png]]

这样，一个Process有2个Page Table，分别在要翻译的时候对应自己的，这样变向扩大了内存(**运用Dynamic relocation**)

#### 6.3.5 Shared Memory

* Create: shmget

![[Operating System/img/shmget.png]]

  > 查看：**ipcs**

* Write: shmat(Shared Memory Attach)

![[Operating System/img/shmat.png]]

* Read

![[Operating System/img/shmrd.png]]

#### 6.3.6 Shared Library

* Shared Memory -> Data Share
* Shared Library -> Code Share

![[Operating System/img/sl.png]]

**注：编译时，库里的应是<u>相对地址</u>**

![[Operating System/img/sl2.png]]

> **Exercise: c + gcc -> Shared Library**

#### 6.3.7 Mapped Files

> Mapped files provide an alternative model for I/O. Instead of doing reads and writes, the file can be accessed as a big character array in memory. In some situations, programmers find this model more convenient.

Advantage

* 不用调函数，指针更灵活
* 不用为每个Process创建Buffer

普通访问File

![[Operating System/img/fwfile.png]]

> 不能像指针一样在File中来回跳

使用Mapped File

```c
#include "stdio.h"
#include "unistd.h"
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <string.h>

int main()
{
	int fd;
	void *p;
	fd=open("haha",O_CREAT|O_RDWR,0666);
    /**
    * NULL：一段连续地址空间
    * 5：文件大小5B
    * MAP_SHARED：可共享
    */
	p=mmap(NULL,5,PROT_WRITE|PROT_READ,MAP_SHARED,fd,0);
    /* 指针访问 */
	strncpy((char*)p,"hehe\n",5);
	munmap(p,5);
	close(fd);
}

```

补充：open函数

![[Operating System/img/open.png]]

运行mmap

> 运行之前，首先创建一个haha文件，并使用命令：
> 	truncate -s 5 haha
> 将其长度改为5，否则会出错，错误名busy bus。

#### 6.3.8 Virtual Memory Interface

**Linux: /proc**，看Memory Manage info

proc特点：不留在磁盘上，动态生成

### 6.4 Implementation Issues

#### 6.4.1 Time for paging

1. Process Creation

   > * **Determine Program Size**
   >
   > * **Create Page Table**
   >
   > * 怎么知道程序的大小？
   >
   >   元信息，编译器通过编译后含在程序里(elf)

2. Process execution

   > * **MMU reset for new process**
   > * **TLB flushed**

3. Page Fault

   > * **Determine virtual address causing fault**
   > * **Swap target page out, needed page in**

4. Terminate

   > * **Release Page Table, Pages**

#### 6.4.2 RISC and CISC

* RISC: Reduced Instruction Set Computers，每条Ins等长
* CISC: Complex Instruction Set Computers，每条Ins不等长

复杂指令集计算机(CISC)

长期来，计算机性能的提高往往是通过增加硬件的复杂性来获得．随着集成电路技术．特别是VLSI（超大规模集成电路）技术的迅速发展，为了软件编程方便和提高程序的运行速度，硬件工程师采用的办法是不断增加可实现复杂功能的指令和多种灵活的编址方式．甚至某些指令可支持高级语言语句归类后的复杂操作．至使硬件越来越复杂，造价也相应提高．为实现复杂操作，微处理器除向程序员提供类似各种寄存器和机器指令功能外．还通过存于只读存贮器(ROM)中的微程序来实现其极强的功能 ，傲处理在分析每一条指令之后执行一系列初级指令运算来完成所需的功能，这种设计的型式被称为复杂指令集计算机(Complex
Instruction Set Computer-CISC)结构．一般CISC计算机所含的指令数目至少300条以上，有的甚至超过500条．

精简指令集计算机(RISC)

采用复杂指令系统的计算机有着较强的处理高级语言的能力．这对提高计算机的性能是有益的．当计算机的设计沿着这条道路发展时．有些人没有随波逐流．他们回过头去看一看过去走过的道路，开始怀疑这种传统的做法：IBM公司没在纽约Yorktown的JhomasI.Wason研究中心于1975年组织力量研究指令系统的合理性问题．因为当时已感到，日趋庞杂的指令系统不但不易实现．而且还可能降低系统性能．1979年以帕特逊教授为首的一批科学家也开始在美国加册大学伯克莱分校开展这一研究．结果表明，CISC存在许多缺点．**首先．在这种计算机中．各种指令的使用率相差悬殊：一个典型程序的运算过程所使用的80％指令．只占一个处理器指令系统的20％．**事实上最频繁使用的指令是取、存和加这些最简单的指令．这样-来，长期致力于复杂指令系统的设计，实际上是在设计一种难得在实践中用得上的指令系统的处理器．同时．复杂的指令系统必然带来结构的复杂性．这不但增加了设计的时间与成本还容易造成设计失误．此外．尽管VLSI技术现在已达到很高的水平，但也很难把CISC的全部硬件做在一个芯片上，这也妨碍单片计算机的发展．在CISC中，许多复杂指令需要极复杂的操作，这类指令多数是某种高级语言的直接翻版，因而通用性差．由于采用二级的微码执行方式，它也降低那些被频繁调用的简单指令系统的运行速度．因而．针对CISC的这些弊病．帕特逊等人提出了精简指令的设想即指令系统应当只包含那些使用频率很高的少量指令．并提供一些必要的指令以支持操作系统和高级语言．按照这个原则发展而成的计算机被称为精简指令集计算机(Reduced Instruction Set Computer-RISC)结构．简称RISC．

CISC与RISC的区别

我们经常谈论有关"PC"与"Macintosh"的话题，但是又有多少人知道以Intel公司X86为核心的PC系列正是基于CISC体系结构，而 Apple公司的Macintosh则是基于RISC体系结构，CISC与RISC到底有何区别？-

- **从硬件角度来看CISC处理的是不等长指令集，它必须对不等长指令进行分割，因此在执行单一指令的时候需要进行较多的处理工作。而RISC执行的是等长精简指令集，CPU在执行指令的时候速度较快且性能稳定。因此在并行处理方面RISC明显优于CISC，RISC可同时执行多条指令，它可将一条指令分割成若干个进程或线程，交由多个处理器同时执行。由于RISC执行的是精简指令集，所以它的制造工艺简单且成本低廉。**
- 从软件角度来看，CISC运行的则是我们所熟识的DOS、Windows操作系统。而且它拥有大量的应用程序。因为全世界有65%以上的软件厂商都理为基于CISC体系结构的PC及其兼容机服务的，象赫赫有名的Microsoft就是其中的一家。而RISC在此方面却显得有些势单力薄。虽然在RISC上也可运行DOS、Windows，但是需要一个翻译过程，所以运行速度要慢许多。
- 目前CISC与RISC正在逐步走向融合，Pentium Pro、Nx586、K5就是一个最明显的例子，它们的内核都是基于RISC体系结构的。他们接受CISC指令后将其分解分类成RISC指令以便在遇一时间内能够执行多条指令。由此可见，下一代的CPU将融合CISC与RISC两种技术，从软件与硬件方面看二者会取长补短。
- 复杂指令集CPU内部为将较复杂的指令译码，也就是指令较长，分成几个微指令去执行，正是如此开发程序比较容易（指令多的缘故），但是由于指令复杂，执行工作效率较差，处理数据速度较慢，PC 中 Pentium的结构都为CISC CPU。
- RISC是精简指令集CPU，指令位数较短，内部还有快速处理指令的电路，使得指令的译码与数据的处理较快，所以执行效率比CISC高，不过，必须经过编译程序的处理，才能发挥它的效率，我所知道的IBM的 Power PC为RISC CPU的结构，CISCO 的CPU也是RISC的结构。
- 咱们经常见到的PC中的CPU，Pentium-Pro（P6）、Pentium-II,Cyrix的M1、M2、AMD的K5、K6实际上是改进了的CISC，也可以说是结合了CISC和RISC的部分优点。
- RISC与CISC的主要特征对比
  比较内容 CISC RISC
  指令系统 复杂，庞大 简单，精简
  指令数目 一般大于200 一般小于100
  指令格式 一般大于4 一般小于4
  寻址方式 一般大于4 一般小于4
  指令字长 不固定 等长
  可访存指令 不加限制 只有LOAD/STORE指令
  各种指令使用频率 相差很大 相差不大
  各种指令执行时间 相差很大 绝大多数在一个周期内完成
  优化编译实现 很难 较容易
  程序源代码长度 较短 较长
  控制器实现方式 绝大多数为微程序控制 绝大多数为硬布线控制
  软件系统开发时间 较短 较长

#### 6.4.3 Instruction Backup

![[Operating System/img/ib.png]]

**前面说的CISC会有以下问题：**

![[Operating System/img/ciscpb.png]]

假设MOVE和6在一个Page，2在下一个Page。当发现2是Abscent，就会产生一个**Page Fault**，**返回地址是2的地址（产生缺页中断处）。**这样就会先把MOV 6存在CPU的某个位置，等2进来后再拼一起，放到Instruction流水线上执行

**但是普通中断不这样**

比如在TSL处产生了一个普通中断，要等TSL完成后，普通中断程序运行，**其返回值是TSL的下一条**，也就是说，**普通中断不管TSL成功与否**

#### 6.4.4 Paging With I/O

* Locking Pages in Memory

  如果一个Page中的程序在等I/O传来数据(比如buf[]在等数)，但Data还没来，程序被交换了，变成了别人的形状，这时候就要产生Page Fault把原来的程序写回来，很耗时。同时Data也肯恩被后来者覆盖，因此需要Lock一下Page，不让换出去

  > #question Lock之后会有啥问题？
  >
  > 恶意Lock，把所有的Virtual Page都锁上，即它映射的所有Page Frame都锁上了，别人的地方就小了

* Backing Store

  Page被换出去，存在磁盘的哪儿？ -> Disk中的swap area

![[Operating System/img/bs.png]]

  > Windows: C:\pagefile.sys, swapfile.sys就是
  >
  > **Exercise：Linux生成交换文件**

#### 6.4.5 Separation of Policy and Mechanism

![[Operating System/img/sopam.png]]

#### 6.4.6 Segmentation

> *什么是段？*
>
> **一个区域，里面的地址是连续的**

Why Segmentation?

让程序和数据有分离独立的空间，利于共享和保护

Segentation已弃用 -> 改用Page

为什么CS，DS还在？向前兼容

**那么，Segmentation，Page共存咋办？**

MULTICS：多级翻译

![[Operating System/img/multics.png]]

* 一个Virtual Address还是表示成：SG + offset

* VA -> IA --Page Table--> PA

* IA咋实现？

  以前，CS，DS存的都是基地址，现在不存了，改存一个编号：Selector, Descriptor

  还有一张Segment Table

![[Operating System/img/st.png]]

  > 注意：得到的IA也是虚地址

**RISC-V和ARM的区别**
	ARM 架构和 RISC-V 架构都源自 1980 年代的精简指令计算机 RISC。两者最大的不同就在于其推崇的大道至简的技术风格和彻底开放的模式。
	ARM 是一种封闭的指令集架构，众多只用 ARM 架构的厂商，只能根据自身需求，调整产品频率和功耗，不得改变原有设计，经过几十年的发展演变，CPU 架构变得极为复杂和冗繁，ARM 架构文档长达数千页，指令数目复杂，版本众多，彼此之间既不兼容，也不支持模块化，并且存在着高昂的专利和架构授权问题。
	反观 RISC-V，在设计之初，就定位为是一种完全开源的架构，规避了计算机体系几十年发展的弯路，架构文档只有二百多页，基本指令数目仅 40 多条，同时一套指令集支持所有架构，模块化使得用户可根据需求自由定制，配置不同的指令子集。

## 7. File System

### 7.1 File System Overview

File System = File + **File Management**

Why File System?

* How do you find information?

* How do you keep one user from reading another user's data?(安全)

* How do you know which blocks are free?

* Others?

  容灾性(xp非法关机)，文件缓存(提高文件命中率，访问速度)，实时性

### 7.2 Files

#### 7.2.1 File Naming

Why file naming

* Help you identify the information you need, i.e, help you speedup searching process

![[Operating System/img/fnex.png]]

Example: regedit on Windows

> 注册表是windows操作系统中的一个核心数据库，其中存放着各种参数，直接控制着windows的启动、硬件驱动程序的装载以及一些windows应用程序的运行，从而在整个系统中起着核心作用。这些作用包括了软、硬件的相关配置和状态信息，比如注册表中保存有应用程序和资源管理器外壳的初始条件、首选项和卸载数据等，联网计算机的整个系统的设置和各种许可，**文件扩展名与应用程序的关联**，硬件部件的描述、状态和属性，性能记录和其他底层的系统状态信息，以及其他数据等。
>
> 具体来说，在启动Windows时，Registry会对照已有硬件配置数据，检测新的硬件信息；系统内核从Registry中选取信息，包括要装入什么设备驱动程序，以及依什么次序装入，内核传送回它自身的信息，例如版权号等；同时设备驱动程序也向Registry传送数据，并从Registry接收装入和配置参数，一个好的设备驱动程序会告诉Registry它在使用什么系统资源，例如硬件中断或DMA通道等，另外，设备驱动程序还要报告所发现的配置数据；为应用程序或硬件的运行提供增加新的配置数据的服务。配合ini文件兼容16位Windows应用程序，当安装—个基于Windows 3.x的应用程序时，应用程序的安装程序Setup像在windows中—样创建它自己的INI文件或在win.ini和system.ini文件中创建入口；同时windows还提供了大量其他接口，允许用户修改系统配置数据，例如控制面板、设置程序等。
>
> 如果注册表受到了破坏，轻则使windows的启动过程出现异常，重则可能会导致整个windows系统的完全瘫痪。因此正确地认识、使用，特别是及时备份以及有问题恢复注册表对windows用户来说就显得非常重要。

#### 7.2.2 File Types

* Regular file
* Device file
  * block device file
  * character device file
* Directory file
* Linux Examples

Most important: exe and archive

![[Operating System/img/exeac.png]]

> **Magic number: 标识符，表示程序是可执行的**
>
> archive: 库，档案
>
> #question 为什么有的程序就几行，却把整个库都链上了？

展示：普通文件和目录文件

在linux下执行`ll`命令

![[Operating System/img/ll.png]]

> 第一列
>
> * 'd' 代表目录文件
> * '-' 代表普通文件
>
> #question 这里显示的目录文件为啥是文件夹？

Device file下的block device file和character device file

进入`/dev`目录，使用`ll`命令

![[Operating System/img/devll.png]]

> 第一列中c代表character device file
>
> 那么block呢？

使用`ll loop1`命令：

![[Operating System/img/loop1.png]]

> 这个b就是block device file

#### 7.2.3 File Access

* Sequential access -> 只能顺序访问

  管道文件，设备文件

* Random access -> 能顺序，也能随机

  很常见，比如用c随便开一个文件，可以用fseek调转，随便跳

#### 7.2.4 File Attributes

文件的属性和文件本身不会存在一起，分开存

想要修改文件的属性，只能通过操作系统提供的接口

![[Operating System/img/fa.png]]

#### 7.2.5 File Operations

Manipulate(操作) files in program: Using system call

```c
/*File copy program. Error checking and reporting is minimal.*/

#include <sys/types.h> 						/*include necessary header files*/
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char*argv[]); 			 /*ANSI prototype*/
#define BUF SIZE 4096 						/*use a buffer size of 4096 bytes*/
#define OUTPUT MODE 0700 					/*protection bits for output file*/


int main(int argc, char*argv[])
{
    int in_fd, out_fd, rd_count, wt_count;
    char buffer[BUF SIZE];
    /**
    * argc包括：文件名，要copy的文件，copy的目标文件，一共3个
    * 所以要看看argc到底是不是3
    */
    if (argc != 3) exit(1); /*syntax error if argc is not 3*/
    
    /*Open the input file and create the output file*/
    in_fd = open(argv[1], O_RDONLY);						 /*open the source file*/
    if (in_fd < 0) exit(2); 								/*if it cannot be opened, exit*/
    
    out_fd = creat(argv[2], OUTPUT_MODE); 					 /*create the destination file*/
    if (out_fd < 0) exit(3); 								/*if it cannot be created, exit*/
    /*Copy loop*/
    
    while (TRUE) {
        /* 使用read和write系统调用来读写文件实现copy */
        rd_count = read(in_fd, buffer, BUF_SIZE); 			/*read a block of data*/
        /**
        * 如果read到文件末尾继续read，rd_count为0
        * 如果read过程中出错，read_count < 0
        */
        if (rd_count <= 0) break; 					   	/*if end of file or error, exit loop*/
        wt_count = write(out_fd, buffer, rd_count); 	    /*wr ite data*/
        if (wt_count <= 0) exit(4);						 /*wt count <= 0 is an error*/
    }
    
    /*Close the files*/
    close(in_fd);
    close(out_fd);
    if (rd_count == 0)										 /*no error on last read*/
    exit(0);
    else
    exit(5); 												/*error on last read*/
}
```

> **Exercise: 把这个代码在自己的机子上转一下**

#### 7.2.6 File Structure

Three kinds of file's logical structure(**这是每一个文件内部的结构，不是文件和文件之间的关系结构!**)

<a name = "byteseq"></a>

* byte sequence

  > 顺序的字节集合
  >
  > *怎么观测到文件是一个顺序结构，有什么例子？*
  >
  > * Mapped File，指针映射的一个文件是连续的
  > * c语言，每调用一次fread都会把指针往后移一下，或者fseek可以跳转便宜量，肯定是顺序的字节结构才能这样偏转

* record sequence

  > 早期的一些文件系统，拆成一块一块，每一块都是等长的

* Tree(withh key field: First letter)

  > *有什么例子？*
  >
  > * 在程序里写一个树的数据结构
  > * html文件就是一个树形结构的文件

* **后两种都是在第一种的基础上搭建的！**

![[Operating System/img/tkfs.png]]

> **这三种是逻辑结构，不是在磁盘上存的物理结构**

### 7.3 Directory

上面看到了那么多文件，文件属性，那么怎么组织他们？

* Ostrich Policy: Let it be chaos, I don't care!

  > 鸵鸟方式：乱着来
  >
  > 在某些系统就几个文件，弄那么复杂的目录没有必要，所以鸵鸟在这时候还挺有用

* Classify

#### 7.3.1 Single-Level Directory

![[Operating System/img/sld.png]]

* Contains 4 files
* Owned by 4 different people: A, B, C and D

![[Operating System/img/sld2.png]]

* Conatins 4 files
* Owned by 3 different people: A, B, and C

Problems of Single-Level Directory

* **都放一个目录里，不同的用户可能会起一样的名字**

#### 7.3.2 Double-Level Directory

![[Operating System/img/dld.png]]

* 每个用户一个文件夹

#### 7.3.3 Hierarchical Directory

![[Operating System/img/hd.png]]

> *Is it perfect?*
>
> * Search Speed: 需要一层一层进，慢
>
> * 目录代表分类，那分完之后，这个东西就定了，后面如果要采用不同的分类，或者两种分类共存 ，不好办
>
>   > 比如文件按C, Java, Python分，之后又想按数据库，面向对象，操作系统分
>
> * MVC: Model, View, Control

#### 7.3.4 Path Names

* Absolute path name: start from '/'
* Relative path name: start from '.' or '..'

> *思考：在某一目录下，执行程序的前面必须要加上一个`./`*，这是为什么？
>
> 提示：环境变量$PATH
>
> `echo $PATH`

Path Name Work

![[Operating System/img/dtree.png]]

> 如果要想快点查找：使用索引
>
> `locate <filename>`
>
> 如果没建索引，那只能慢慢找
>
> `find <filename>`

Directory operating interface

| Create   | Readdir |
| -------- | ------- |
| Delete   | Rename  |
| Opendir  | Link    |
| Closedir | Unlink  |

#question 

* 为啥读一个文件还要open一下，直接read不行吗？

  > `open`就是`malloc`；`close`就是`free`
  >
  > 获得的文件句柄指针所指向的区域是放在堆区的，因为放在栈区`open`结束后就会被销毁；放在静态区多次`open`打开的是同一个文件，而放在堆区在创建的时候就要用`malloc`，正好和`close`中的`free`；配套

* 为啥要有一个Rename，对文件进行修改本身就是要进行写操作，那用Write不就行了吗？

  > 目录文件在操作系统存储的时候是有特定结构的，不能随便改的，这个改的规则不能暴露给用户，因此才封装在Rename中，不能像Write一样随便把指针随便跳
  >
  > **Exercise: 用Opendir和Readdir把目录项列出来然后打印出来**

* 内核函数和系统调用的区别

  > * 系统调用是由内核函数实现的，进入kernel后，不同的系统调用会找到各自对应的内核函数，这些内核函数被叫做系统调用的"服务例程"
  >
  > * 库函数也就是我们通常所说的应用编程接口API，它其实就是一个函数定义，比如常见read()、write()等函数说明了如何获得一个给定的服务，但是系统调用是通过软中断向内核发出一个明确的请求，再者**系统调用是在内核完成的，而用户态的函数是在函数库完成的**。
  > * 系统调用发生在内核空间，因此如果在用户空间的一般应用程序中使用系统调用来进行文件操作，会有用户空间到内核空间切换的开销。事实上，即使在用户空间使用库函数来对文件进行操作，因为文件总是存在于存储介质上，因此不管是读写操作，都是对硬件（存储器）的操作，都必然会引起系统调用。也就是说，库函数对文件的操作实际上是通过系统调用来实现的。例如C库函数fwrite()就是通过write()系统调用来实现的。
  > * 这样的话，使用库函数也有系统调用的开销，为什么不直接使用系统调用呢？这是因为，**读写文件通常是大量的数据（这种大量是相对于底层驱动的系统调用所实现的数据操作单位而言），这时，使用库函数就可以大大减少系统调用的次数。这一结果又缘于缓冲区技术。在用户空间和内核空间，对文件操作都使用了缓冲区，例如用fwrite写文件，都是先将内容写到用户空间缓冲区，当用户空间缓冲区满或者写操作结束时，才将用户缓冲区的内容写到内核缓冲区，同样的道理，当内核缓冲区满或写结束时才将内核缓冲区内容写到文件对应的硬件媒介**。
  >   系统调用与系统命令：系统命令相对API更高一层，每个系统命令都是一个可执行程序，比如常用的系统命令ls、hostname等，比如strace ls就会发现他们调用了诸如open(),brk(),fstat(),ioctl()等系统调用。

**An Link Example**

<a name = "linkex"></a>

现在有一个s.c文件，给它建一个link，使用如下代码

```c
ln -s s.c sln.c
```

这样就建好了一个类似快捷方式的东西，sln.c就是s.c的快捷方式

输入`ll s.c sln.c`可以看到他们的关系

![[Operating System/img/sln.png]]

### 7.4 File System Implementation

#### 7.4.1 Files Implementation

How do we implement file?

* 在存储文件的时候
  * 磁盘空间怎么分配？ - Physical Block Allocation
  * 把文件存在磁盘上的时候，通常是分散在各个角落，那么这一个文件的顺序应该怎么存？哪一个是开头？- Block Tracking

**Physical Block**

> 地址是连续的，存在一块的一个区域叫做一个<u>Physical Block</u>
>
> *对文件进行访问的时候，都是按照Block为单位进行的，并不是按照字节来的，为什么？*
>
> * ~~可能是上面提到的系统调用，按照块来可以少进行用户态和内核态的切换？~~

##### 7.4.1.1 Physical Block Allocation

* Raw version: Continuous Allocation

![[Operating System/img/ca.png]]

  > * 在特定情况下(类似机械硬盘)，读写效率比较高，机械臂来回动的时候，由于是连续的，移动少，**不用来回寻道**
  > * 不停生成删除文件，会形成大大小小的空洞，要消除空洞，就要把文件往前移一移(参考<a href = "#downward">downward</a>操作)

##### 7.4.1.2 Block Tracking

按照上面那种方式存完了，只是表面上感觉着是顺序存的，**实际上还是分散在磁盘中，只不过是用了某种方式让用户从表面上看起来是顺序存的**。用什么方式呢？Maybe Link list

![[Operating System/img/llcun.png]]

> * 这么存，随机访问很慢，每次都要从表头一个一个搜索，改进 -> FAT

##### 7.4.1.3 FAT(File Allocation Table)

![[Operating System/img/fat.png]]

> * 要访问的时候，**整张表全部加载到内存里**，这样访问某一个Block，查表(看下面英文)就行了
> * 当磁盘超大的时候，FAT表太大了，太占空间，FAT表里存的是**所有文件**的Block占用情况
> * (考点)**FAT除了Tracking，还有别的功能：那些空的位置，代表没人用的Block，所以也记录了当前磁盘上的空闲块**
> * Using the table of Fig. 4-12, we can **start with block 4 and follow the chain all the way to the end**. The same can be done starting with block 6. Both chains are terminated with a special marker (e.g.,−1) that is not a valid block number. 

##### 7.4.1.4 Inode

> Inodes contain the following information:
>
> - **File type** - file, folder, executable program etc.
> - **File size**
> - **Time stamp** - creation, access, modification times
> - **File permissions** - read, write, execute
> - **[Access control list](https://techterms.com/definition/acl)** - permissions for special users/groups
> - **File protection flags**
> - **File location** - directory path where the file is stored
> - **Link count** - number of hardlinks to the inode
> - **Additional file [metadata](https://techterms.com/definition/metadata)**
> - **File pointers** - addresses of the storage blocks that store the file contents
>
> Notably, an inode does not contain the [filename](https://techterms.com/definition/filename) or the actual [data](https://techterms.com/definition/data). When a file is created in the Linux file system, it is assigned an inode number and a filename. This linked pair allows the filename to be changed without affecting the file ID in the system. The same holds true when renaming directories, which are treated as files in Linux.
>
> File data is stored across one or more blocks on the storage device. An inode includes a pointer to this data but does not contain the actual data. Therefore, all inodes are relatively small, regardless of the size of the files they identify.

* **一个文件对应一个Inode**，对比前面的FAT，要访问那个文件，加载哪个文件的Inode即可，不向上面那样导入整张表
* 一个文件坏了，不会影响到其他文件，可靠性提高

![[Operating System/img/inode.png]]

* 前半部分存File Attributes
* 逻辑块0对应的物理块
* 逻辑块1对应的物理块
* ...
* Inode大小是固定的，万一槽位用完了咋办？-> 最后一个是个间接块，存可能溢出的文件的逻辑块，同理，还有间接间接块...

> * *Inode也是在磁盘上存的，那Inode的空间是谁给分配的？*

#### 7.4.2 Directory Implementation

* **目录文件，不是文件夹！**

  文件控制块的有序集合构成文件目录，每个目录项即是一个文件控制块。

  为了实现文件目录的管理，通常将文件目录以文件的形式保存在外存空间，这个文件就被称为目录文件。目录文件是长度固定的记录式文件。

  系统为用户提供一个目前正在使用的工作目录，称为当前目录。

  从操作系统的观点，**文件夹也是一种文件，只不过是可以包含其他文件的文件**。<u>你可以把文件目录当成一张表，每个表项就是FCB（文件控制块），每个表项标识着某个文件的存在信息。</u>
  <u>但是这个表也得以文件的形式存储在磁盘上，我们称这个文件为目录文件，用来跟普通文件区别</u>。

在已有的<a href = "#byteseq">顺序集合</a>的基础上，怎么实现目录文件？

##### 7.4 2.1 Fixed size

![[Operating System/img/fxsize.png]]

> * 一个Directory Entry(目录项)的大小是固定的
> * 比如前面一半存名字，后面一半可能存属性
> * 文件名对应的文件在磁盘上存的位置，如果是用Inode存的，就存Inode的地址；如果是连续存的，就存那一块的首地址
> * attributes的位置不一定，Inode中不是也有文件属性吗，所以不一定存在哪儿，可能在目录项，也可能在Inode
> * 问题：文件名很长咋办？比如电脑上会有这种`~.`开头的文件，那个就有可能是名字太长了，按照一种规则给截短了

##### 7.4.2.2 Improved

![[Operating System/img/ipr.png]]

> * 以一个叉号表示文件名的结束
> * 阴影表示**字节对齐**
> * a有个问题，删掉一个目录项会有空洞，采用b，**把固定长度的东西放在前面**，移动的空间会少一些，不用移attributes之类的

#### 7.4.3 Linked File Implementation

在上面的<a href = "#linkex">An Link Example</a>中，s.c和sln.c是一个文件吗？

> **是两个文件！**怎么证明？
>
> 一个文件对应一个Inode，每一个Inode在系统中有唯一编号
>
> 使用`ls -i sln.c`看到sln.c对应Inode的编号
>
> ![[Operating System/img/lsisln.png]]
>
> 再看一下s.c的编号
>
> ![[Operating System/img/lsis.png]]
>
> * **这个就是软连接-soft**

**创建硬链接**

对s.c创建硬链接，使用`ln s.c hln.c`，再看一下他的信息和Inode编号

![[Operating System/img/hl.png]]

和s.c一样，所以硬链接创建的是同一个文件

![[Operating System/img/hli.png]]

> 问题：


![[Operating System/img/link.png]]

>
> **可不可以这么想：软连接的话，如果改了源文件的名字，软连接就会失效。那是不是意味着，软连接其实就是一个新文件，在里面通过源文件的名字来打开这个文件，如果打开失败，返回的错误码和`open`系统调用返回的错误码是一样的。**

*一个实验：如果把s.c删掉，sln.c会进入悬空状态；如果把s.c删掉，hln.c的文件内容还在，这是为什么？*

> * 硬链接是通过目录指向同一个Inode实现的，把一个目录删掉，另一个还在。那什么时候Inode被释放呢？那个Count看见了吗，当Count变成0的时候就释放了
> * Count在哪儿看？输入`ll hln.c`的时候，那一排rwx之后有个2，那个就是Count

*为啥要用软连接？*

> 比如链接一个库会用`-lpthread`，`-lstdc`之类的，那么这些库由于标准的改变，修改bug，要扩充，加载一个超集等等原因，会有更新，而在执行的时候，会有makefile来处理依赖关系，那比如我`-lpthread_v1`，之后更新了，又变成`-lpthread_v2`很麻烦，所以直接去掉版本号，**然后这个`-lpthread`是链了一个软连接，让它指向真正的库文件**

*既然软连接这么好使，还要硬链接干嘛？*

> 上面都说了，软连接是俩不同的文件，**创建软连接是要消耗Inode的！**Inode的个数在一些系统上是有限的，所以软连接过多，有时候磁盘空间够，但是文件创建不出来了

**Quote on Stack Overflow**

> **Directory Implementation**
>
> The internal structure of directories is dependent on the filesystem in use. If you want to know precisely what happens, have a look at filesystem implementations.
>
> Basically, in most filesystems, a directory is an [associative array](http://en.wikipedia.org/wiki/Associative_array) between filenames (keys) and inodes numbers (values). Something like this¹:
>
> ```
> 1167010 .
> 1158721 ..
> 1167626 subdir
> 132651 barfile
> 132650 bazfile
> ```
>
> This list is coded in some – more or less – efficient way inside a chain of (usually) 4KB blocks. Notice that the content of regular files is stored similarly. In the case of directories, there is no point in knowing which size is actually used inside these blocks. That's why the sizes of directories reported by `du` are multiples of 4KB.
>
> Inodes are there to tie blocks together, forming a single entity, namely a 'file' in the general sense. They are identified by a number which is some kind of address and each one is usually stored as a single, special block.
>
> Management of all this happens in kernel mode. Software just asks for the creation of a directory with a function named `int mkdir(const char *pathname, mode_t mode);` leading to a system call, and all the rest is performed behind the scenes.
>
> **About links structure:**
>
> A hard link is not a file, it's just a new directory entry (i.e. a *name – inode number* association) referring to a preexisting inode entity². This means that the same inode can be accessed from different pathnames. In particular, since metadatas (permissions, ownership, timestamps…) are stored within the inode, these are unique and independent of the pathname chosen to access the file.
>
> A symbolic link *is* a file and it's distinct from its target. This means that it has its own inode. It used to be handled just like a regular file: the target path was stored in a data block. But now, for efficiency reasons in recent *ext* filesystems, paths shorter than 60 bytes long are stored within the inode itself (using the fields which would normally be used to store the pointers to data blocks).

#### 7.4.4 File System Layout

![[Operating System/img/fsl.png]]

把整个磁盘看成一个大文件，一个顺序字节集合，磁盘可以被分成很多个区(Disk Partion)，每一个分区中又有Boot block, Super block, Free space mgmt ... 通常一个分区认为可以装一个操作系统

* MBR(Master Boot Record)用于启动电脑，MBR的末尾包括了Partion table，标记了每个分区的启示和末尾的地址，只有一个，对于多个操作系统，MBR可以指出要启动的是哪一个系统
* Boot Block里边放一些能把操作系统加载到内存里的东西
* Super Block里放一些文件系统的关键参数，比如前面说的Physical Block，那一个块有多大呢？Inode的区域(就是后面那块)的起始地址在哪？或者这是啥文件系统呢？是ext3，ext4，还是ntfs之类的？在我的[[5. ext_fs#5. EXT文件系统结构|数据管理技术课程调研报告]]中有补充。
* Free space management，MM里讲过 ，是bitmap或者是link list

#### 7.4.5 Log-Structed File System

把文件系统当做一个日志文件，只往里追加着写

*为啥会有这个思想？*

> 内存，CPU都越来越快，越来越便宜，因此后序的趋势一定是I/O决定了性能，而主要取决于写操作的速度，**因为内存大了，CPU的cache也大了，读的话很大概率都是从缓冲区和内存里读，很少概率会从磁盘读，但是写操作一定会往磁盘上写**。而写的时间主要取决于机械臂的移动。那追加着写，就能减少机械臂的移动！

*但是一直这样的话，如果写到磁盘的末尾，会发生肾么？*

* If there’s no free disk space, an error will be occurred.
* A cleaner Process, continuously scans from the start of log. If segment contains no data，then marks segment free for next log write，If contains inode and data block still inuse，Then these inode and data block will be read out. Then mark this segment free. The new data read out will be use as a new logsegment appended to the end。

*Log和非Log在出错之后，恢复有什么差别？*

> **日志出错后，定位速度快，因为当前位置就是出错位置！**

虽然现在文件系统不用Log了，但是这个思想还在用

> SSD的NAND芯片，在写入时一定要先擦除操作，而且对于同一个单元，频繁擦除，寿命不长，所以采用Log方式追加着写，**能做到写均衡**

#### 7.4.6 Journaling File System

* Log啥都记日志，Journaling仅记录**关键数据更改的日志**，比如Inode

#### 7.4.7 Virtual File System

![[Operating System/img/pavs.png]]

![[Operating System/img/vfa.png]]

比如你电脑是NTFS的，为啥还能识别FAT32硬盘呢？就是因为虚拟文件系统，将各个不同的文件系统统一抽象成一个接口，变成类似c++的虚函数，java的抽象类中不加final的函数，这样不管啥系统，都调用这个父类的函数，就直接向下转型为自己的函数执行了，也就是多态，实现了多种文件系统的共存，移植方便

### 7.5 File System Management & Optimization

#### 7.5.1 Disk Space Management

一个磁盘块(disk block)多大合适？

* Too big: waste disk space
* Too small: multiple seeks and rotational delays

**Keeping Track of Free Blocks**

![[Operating System/img/ktfb.png]]

![[Operating System/img/kt2.png]]

有些用户会恶意写垃圾数据，因此需要做一些限制：Quota table(配额表)

![[Operating System/img/qtt.png]]

* Soft: 过了会警告

* Hard: 直接不让在创了

* Block limit: 一个文件占用的块数的限制

* File limit

  > Block limit不是一个块大小的限制！之前Super block那里，就已经把块的大小存在里面了，改不了的！
  >
  > > 打开文件的个数有限制吗(当时上课的时候说的)？
  > >
  > > * 打开文件进行的操作：加载Inode，记录文件的状态(初始地址等)，这些是占内存的，所以打开文件是有上限的
  >
  > File limit是拥有的文件的上限：Inode是有上限的，如果一个用户不断创建小文件，拥有超级多，那就把Inode消耗光了
  >
  > #question 那个表里是Open file table里的QuotaPointer，那么是每一个用户对应一张Quota table，还是每一个文件都有一张Quota table呢？我感觉是每个用户一张，然后不同的Open file table中正在打开的文件，每个里面的Quota pointer，只要User是那个User，那pointer指向的就是同一张Quota table

#### 7.5.2 File System Reliability

增量式备份(incremental dump)：当修改文件时，不拷贝整个文件系统，只拷贝修改过的文件

![[Operating System/img/dump.png]]

* 应用：虚拟机镜像，拍照做，快速拍只拍改变的部分

* 问题：

  * Compress or not?

  * How to perform a backup on an active file system?

    > 比如电信局要备份通话记录，那有人正在打电话的时候咋备份？正在修改文件系统，那怎么备份？

  * Nontecnical: like security?

**Logical dump or Physical Dump?**

* Physical dump: 从0开始，全部按顺序输出到磁带上

* Logical dump: 从特定的目录(1 or more)开始，递归备份修改的文件(如果第一次备份，那就全拷)

  > 整盘备份，并且是第一次，Logical比Physical要慢，因为Logical基于API，需要打开文件，对每个文件要建立Inode，更耗时，Physical最多给硬盘整个建立一个Inode，也不用遍历树型目录

#### 7.5.3 File System Consistency

要写一个文件，建立Inode，但数据还没写，断电了；或者分配block的时候，正要改链表，断电了，咋办？

* UNIX: fsck
* Windows scandisk(非法关机)

![[Operating System/img/sd.png]]

两张表，一张记当前block在bitmap/list中使用的出现次数；一张记空闲次数。那么只能是0 1或者1 0，其他情况都是有问题

快速扫描(上面是全盘扫描)

> * Checker通过扫描目录文件中目录项指向文件的指针，建立一张表，该表的每一项表示每个文件的引用数
> * Inode节点本身也含有本文件的引用数，据此也可以建立一张表
> * 上述两张表进行比对

#### 7.5.4 File System Performance

**Cache**

![[Operating System/img/cache.png]]

> 使用**LRU**，Hash算法
>
> * 检査全部的读请求,査看在高速缓存中是否有所需要的块。如果存在,可执行读操作而无须访问磁盘。如果该块不在高速缓存中,首先要把它读到高速缓存,再复制到所需地方。之后,对同一个块的请求都通过高速缓存完成
> * 当要读一个新块时，替换现有的cache，那根据LRU，替换栈底的

*如果要写，写到Cache上，还没从Cache往磁盘上传的时候，断电了，咋整？*

* Write-through Cache: 要做就做完，就算只差一点，也算没做

**Block Read Ahead**

> When the file system is asked to produce block k in a file, it does that, but when it is finished, it makes a sneaky check in the cache to see if block k + 1 is already there. If it is not, it schedules a read for block k + 1 in the hope that when it is needed, it will have already arrived in the cache.At the very least, it will be on the way

**Reducing Disk-Arm Motion**

> * Log File Structure
>
> * 每次分配新块，分到上一个块的旁边


![[Operating System/img/cid.png]]

>
>   把Inode分散，这样加载Inode的时候，不用移到外围，再移回来
>
> * 把启动文件放在SSD上，把文件放在机械盘上



#### 7.5.5 Defragmenting

> * 在初始安装操作系统后,从磁盘的开始位置,ー个接ー个地连续安装了程序与文件。所有的空闲磁盘空间放在ー个单独的、与被安装的文件邻近的单元里。但随着时间的流逝,文件被不断地创建与删除,于是磁盘会产生很多碎片,文件与空穴到处都是。结果是,当创建一个新文件时,它使用的块会散布在
>   整个磁盘上,造成性能的降低。
> * 磁盘性能可以通过如下方式恢复:移动文件使它们相邻,并把所有的（至少是大部分的）空闲空间放在一个或多个大的连续的区域内。Windows有一个程序defrag就是从事这个工作的。Windows的用户应该定期使用它,当然,SSD盘除外。
> * 磁盘碎片整理程序会在ー个在分区末端的连续区域内有大量空闲空间的文件系统上很好地运行。这段空间会允许磁盘碎片整理程序选择在分区开始端的碎片文件,并复制它们所有的块放到空闲空间内。这个动作在磁盘开始处释放出ー个连续的块空间,这样原始或其他的文件可以在其中相邻地存放。这个过程可以在下一大块的磁盘空间上重复,并继续下去。
> * 有些文件不能被移动,包括页文件、休眠文件以及日志,因为移动这些文件所需的管理成本要大于移动它们所获得的收益。在ー些系统中,这些文件是固定大小的连续的区域,因此它们不需要进行碎片整理。这类文件缺乏灵活性会造成一些问题,ー种情况是,它们恰好在分区的末端附近并且用户想减小分区的大小。解决这种问题的唯一的方法是把它们ー起删除,改变分区的大小,然后再重新建立它们。
> * Linux文件系统（特别是ext2和6xt3） 由于其选择磁盘块的方式,在磁盘碎片整理上一般不会遭受像Windows那样的困难,因此很少需要手动的磁盘碎片整理。而且,固态硬盘并不受磁盘碎片的影响。事实上,在固态硬盘上做磁盘碎片整理反倒是多此ー举,不仅没有提髙性能,反而磨损了固态硬盘。所以碎片整理只会缩短固态硬盘的寿命。

### 7.6 Example File Systems

#### 7.6.1 ISO 9660

![[Operating System/img/iso.png]]

> * the first field is a byte telling how long the entry is directory entries have variable lengths
> * second byte tells how long the extended attributes are Directory entries may optionally have an extended attributes
> * Flags field contains a few miscellaneous bits, including one to hide the entryin listings (a feature copied from MS-DOS), one to distinguish an entry that is afile from an entry that is a directory, one to enable the use of the extended attributes, and one to mark the last entry in a directory.
> * L: gives the size of the file name in bytes
> * After entry, it comes the starting block of the file itself. Files are stored as contiguous runs of blocks, so a file’s location is completely specified by the starting block and the size, which is contained in the next field.
> * 问题：文件名15个byte，太长了要用别的格式

#### 7.6.2 MS-DOS

![[Operating System/img/msdos.png]]

> * 文件名11个byte，左对齐，右补空格
> * **Attributes描述一个文件是否是Read-Only, Archived, Hidden, System file**，不能写只读文件,这样避免了文件意外受损。存档位没有对应的操作系统的功能（即MS-DOS不检査和设置它）。存档位主要的用途是使用户级别的存档程序在存档ー个文件后清理这一位,其他程序在修改了这个文件之后设置这一位。以这种方式,ー个备份程序可以检査毎个文件的这一位来确定是否需要备份该文件。设置隐藏位能够使一个文件在目录列表中不出现,其作用是避免初级用户被ー些不熟悉的文件搞糊涂了。最后,系统位也隐藏文件。另外,系统文件不可以用del命令刪除,在MS-DOS的主要组成部分中，系统位都被设置
> * Time2个字节16bit，一共2^16 = 65536个状态，但一天是86400秒，因此可能会有2s左右误差
> * First block number: 和FAT搭配，从第一块开始遍历FAT

#### 7.6.3 UNIX V7

![[Operating System/img/unixv7.png]]

> *给了这个目录项，问你：UNIX V7能容纳的文件个数是多少？*
>
> * Inode number是2个byte，16个bit，所以有2^16种状态，即这2byte最多表示这么多个不同的Inode，而且一个Inode对应一个文件，所以文件的个数就是2^16
>
> *还是这个，问你：UNIX V7能容纳的文件名的个数是多少？*
>
> * 不是2^(14*8) = 2^112，因为这是：如果这些目录项都存在在同一个文件夹(一个表示为文件夹的目录项)下的时候，这些目录项(并不是所有目录项)的文件名肯定不同，这个数表示的是这个文件夹下的文件最多能有多少个不同的名字。
> * 实际有多少，大于2^16就行了，因为软连接对应Inode，硬链接不对应Inode，所以(文件+软+硬)一定是大于(文件+软)=2^16

![[Operating System/img/uxi.png]]

> 最后三个槽位都是扩展槽位

![[Operating System/img/usc.png]]

## 8. I/O

### 8.1 Principles of I/O Hardware

对于操作系统开发者，关心硬件要关心到什么程度？-> API

![[Operating System/img/std.png]]

可以看到，假设两个键盘厂商生产两个键盘，接口都不一样，操作系统为了适配这两种键盘，就要设计两套接口，太麻烦也太浪费。解决办法，就是**将这些设备分类，为每一类设备提供一套接口**

**Device Classification**

* Block Device -> 硬盘等可以随机读取
* Character Device -> 键盘等只能顺序读取

This is not very good : Clock device should belong to ?

* 分类太笼统

Where do we get the specification of Device Interface?

* hand book

**Device Controller**

> ~~I/O units often consist of a mechanical component and an electronic compo-nent. It is possible to separate the two portions to provide a more modular andgeneral design. The electronic component is called the device controller or adapter.~~ 
>
> 这种定义的问题：有一些设备比如SSD，全是电子部分，没有机械部分，那就分不出来那一部分是Device Controller
>
> * 设备通常分为控制部分和被控制部分，那控制部分就叫做设备控制器
>
> 设备控制器的作用
>
> * 设备寄存器上每一位代表一个作用，合起来表示一个功能，用来控制设备

**I/O Address Access** ^530c0b

I/O设备和它们提供的API也是有地址的，那怎么知道我访问的地址存的不是程序或者数据，而是一个I/O设备呢？

* Separate I/O and memory space

![[Operating System/img/smi.png]]

  > 需要用特殊指令加上地址，表示访问的是IO space

* Memory-Mapped I/O

![[Operating System/img/mmi.png]]

  > 不管在内存还是IO，用一种指令就行，比如MOVE

* Hybrid

![[Operating System/img/hy.png]]

> 当今的CPU，采用的一般是Hybrid结构，早期的外设很慢，和CPU啥的是挂在不同的Address Bus上，所以用两种不同的指令访问不同的地址空间，也就是Separate类型，这样会比较快。后来外设(比如显存)越来越快，甚至和MM不相上下，所以和MM一块编址更加方便。而为了向前兼容，使用Hybrid

#question 那这个图里的IO空间的地址是实地址还是虚地址？如果是虚地址，那比如我写一个程序要控制IO，那在这个程序的进程执行的时候，要创建一个虚地址空间，如果采用的是统一编址，那是不是会有某种特定的算法来讲这个内存的虚地址和IO的虚地址区分开呢？

**Bus connection**

总线的链接有两种方式

* CPU，IO，MM用一根总线

![[Operating System/img/algo.png]]

* 在上面的基础上，CPU和MM之间搭了一根高速总线

![[Operating System/img/gs.png]]

**DMA(Direct Memory Access)**

* DMA负责把外设里东西读到内存里

> 如果没有DMA，CPU想要读硬盘里的东西，要等很长时间，这个时间里CPU本来可以干其他的事。因此把这个工作交给DMA。**当CPU要读IO时，分配给DMA任务，DMA来控制读IO，当把内容读到MM后，通知一下CPU说我干完了就行**

![[Operating System/img/dma.png]]

* Address，Count，Control都是CPU给DMA发的，告诉它应该从哪儿读，读多少，是读还是写
* **DMA在控制IO和MM进行读取的时候，完全不需要CPU干预，只是在读完的时候产生中断通知CPU我干完活了**

**DMA Working Mode**

* Fly-by

  MM和IO之间直接传数据

* Cached

  先把MM或者IO里的数据放到DMA中，DMA再把数据放到IO或者MM中，类似中转站

*Does DMA really improve  the access speed?*

> No. 一般情况下，内存在同一时刻只允许别人对它的一个地址进行访问(除非是多端口内存)，这样在IO和MM进行数据传输的时候，CPU无法访问MM，**不能做到拷数据的时候同时CPU处理数据**；另外，MM和IO设备之间的传输是要靠总线的，而总线一般只允许一个地址和一个数据在跑，这样**DMA在用总线的时候CPU就不能用**，也会产生冲突

**Interrupt**

![[Operating System/img/it.png]]

* **和使用DMA的区别**：需要CPU亲自来把IO的东西塞到内存里。比如一个IO设备每次只能发一个字节，而CPU要读取1000个字节。那么如果使用DMA，只会在最后一次读完之后给CPU发送一个中断；而Interrupt方式每准备好一个字节都会给CPU发一个中断

> CPU上有一个引脚，接的就是这个Interrupt Controller，当Disk发生一个中断，IC就会将这个中断传导给CPU，CPU就会放下当前手里的活去干Disk的事。而要干的这个事叫做中断处理程序。当有很多个设备同时给IC发中断时，IC就体现出了裁决的作用，判断哪个中断的优先级更高，先干重要的事儿。
>
> ~~那CPU是咋知道这个中断是谁发出的呢？通过中断向量。中断向量就是一个数，由IC给它们编号，CPU通过这个数就能判断是谁发的中断。那咋判断呢？内存里有一个叫中断向量表的东西，其实就是个数组，下标就是中断向量，里面存的内容就是每一个中断处理程序的起始地址(函数指针)。~~
> 
> 上面的表述有错误。中断向量号才是`int 21`这种指令中的21。而中断向量才是中断处理程序的起始地址。更改如下：
> 
> 那CPU是咋知道这个中断是谁发出的呢？通过中断向量**号**。中断向量**号**就是一个数，由IC给它们编号，CPU通过这个数就能判断是谁发的中断。那咋判断呢？内存里有一个叫中断向量表的东西，其实就是个数组，下标就是中断向量**号**，里面存的内容就是每一个中断处理程序的起始地址(函数指针 or **中断向量**)。

^8004e9

*OS启动的时候，要初始化IC的什么？*

* 不同设备的id -> Plug Play
* 中断向量表
* **中断的优先级**

一般硬件设备在刚开始就初始化好了，不再进行调整

**Precise/Imprecise Interrupt**

> CPU执行指令通常要取地址，解码，执行，写回，这样如果能并行的话，可以让第一条指令在执行的时候，第二条指令在解码，第三条指令刚取完地址，这样可以提高吞吐量。那么，如果一个中断处理程序这时候要被执行，那这三条指令怎么办？如果把没有正在执行的指令立即清空(**不能清空正在执行的指令，否则会有严重后果**)并加载中断程序，就叫做Precise Interrupt。好处是响应时间短，坏处是那些本来要执行的指令被浪费了；如果只是关上大门，等门里的指令都执行完，CPU闲下来之后再加载中断程序，这就叫做Imprecese Interrupt。好处是指令没有被浪费，坏处是中断响应时间长

### 8.2 Principles of I/O Software Layers

I/O软件设计采用分层架构

![[Operating System/img/layer.png]]

*为什么采用分层？*

* 封装I/O硬件的实现细节
* 方便定制，在改动代码时可以尽可能地复用之前的部分(比如内存分配函数)

**Device driver**

比如显卡驱动，鼠标驱动，键盘驱动啥的，**而一般来讲一个Device driver就会包括一个Interrupt handler**

**Interrupt handler**

大体过程上面说过了，这里说一些要执行的操作

1. Save regs not already saved by interrupt hardware(保存现场)
2. Set up context for interrupt service procedure(TLB, Page Table...)
3. Set up stack for interrupt service procedure
4. Ack interrupt controller, reenable interrupts
5. Copy registers from where saved to the process table
6. Run service procedure
7. Set up MMU context for process to run next
8. Load new process' registers
9. Start running the new process

重要：中断向量号，保存现场，创建Context(函数堆栈等)

**Device Driver**

写一个驱动程序的时候，不仅要关心操作系统的接口，还要关心硬件的接口，就像之前说的，一个SSD和U盘，都可以用read函数来读，那肯定是利用多态来定位到ssd_read或者flash_read。

![[Operating System/img/jk.png]]

**Device-Independent I/O Software**

![[Operating System/img/fi.png]]

> 虚拟文件系统就是一种Device-Independent Software
>
> The basic function of the device-independent software is to perform the I/O functions that are **common to all devices** and to provide a uniform interface to the user-level software. 

提供统一接口的好处

![[Operating System/img/hc.png]]

> TCP-IP网卡，不管是啥牌子的网卡，都可以用Socket做

关于其中的Buffering

![[Operating System/img/bf.png]]

* 不用buffer，有可能会丢数据
* 把buffer放在User space，如果那个page被swap out了咋办？
* 把buffer放在kernel space，要拷贝的话有开销，而且通常一个buffer不够用，要开两个，在正在copy的时候，有新的数据来了咋办？
* Double buffer, after the first buffer fills up, but before it has been emptied, the second one is used. When the second buffer fills up, it is available to be copied to the user (assuming the user has asked for it). **While the second buffer is being copied to user space, the first one can be used fornew characters.** In this way, the two buffers take turns: while one is being copied to user space, the other is accumulating new input. 

如果把buffer放在内核态，会有copy问题

![[Operating System/img/cppb.png]]

> 拷一个buffer要这么多次copy，那像百度网盘(网络其实也可以看做像硬盘、键盘这样的IO设备)那种在线看视频的话，会非常慢，因此这种会有特定优化，将buffer直接放在User space，并且操作的进程要进行保护，普通用户根本没有权限访问

**I/O Software**

*I/O处理函数位于Kernel Space，那么用户怎样才能调用I/O处理函数？*

* System Call*
* 前面说过系统调用和内核函数的区别，是通过**软中断**从User Space切换到Kernel Space

系统调用实现的具体过程

> Intel的CPU有一个INT指令，就是一个软中断程序，这个指令有一个编号，就是0x80(中断向量)。但是，对于同一个IO设备，可能会有多个中断处理程序，而且，一个CPU的中断向量表的大小通常是255个，不够大，还有各种外设，硬盘键盘等都会有很多中断处理程序，那这个中断向量表就很有可能不够用了，那咋办？解决方法是复用某些中断向量号。**其中，只要接收到0x80，系统就会认为这个<u>中断处理程序是系统调用</u>**，那问题又来了，只知道是系统调用，还不知道是read，write还是啥捏？还有一个系统调用号，还有一个系统调用表，下标就是系统调用号，内容是系统调用函数的指针

整个调用的流程

![[Operating System/img/zlc.png]]

> 比如printf函数就是一个User process，调用屏幕的驱动，系统调用write

**Programmed I/O**

比如要打印一个字符串，在CPU发送打印一个字符的指令之后，执行打印的过程是很慢的，CPU不能紧接着又发一个打印指令，因此在发送之前要检查打印机的状态。这样的话打印机就会有两个Reg，一个用来接收打印字符，一个用来表明自己的状态是Ready还是Busy

![[Operating System/img/pt.png]]

这样CPU的程序就是这样的

```c
copy_from_user(buffer, p, count);		    /* p is the kernel buffer */
for(i = 0; i < count; ++i){				   /* loop on every character */
    while(*printer_stats_reg != READY);		/* loop until ready */
    *printer_data_reg = p[i];
}
return_to_user();
```

* 浪费CPU时间用来检查状态

**Interrupt-Driven I/O**

* 让CPU在I/O时能干别的事，等I/O完事了给CPU发个中断就行，就像前面说的

```c
//当系统调用时
copy_from_user(buffer, p, count);
enable_interrupts();
while(*printer_status_reg != READY);
*printer_data_reg = p[0];
scheduler();

//打印机中断程序
if(count == 0){						/* 没有字符要打了 */
    unblock_user();					/* 解除用户进程阻塞 */
}else{
    *printer_data_reg = p[i];
    count--;
    i++;
}
acknowledge_interrupt();
return_from_interrupt();
```

**Using DMA**

前面都说的差不多了，主要就是DMA和Interrupt的区别

```c
copy_from_user(buffer, p, count);
set_up_DMA_controller();
scheduler();

acknowledge_interrupt();
unblock_user();
return_from_interrupt();
```

> Programmed I/O虽然速度慢，但现在还在用。有的I/O设备速度非常快，那么CPU如果用中断的话，刚准备去干别的事，中断马上来了，这时候CPU就要立刻放下刚要干的别的事，保存好现场，要执行好多微指令，然后去发下一个I/O任务，这样就本末倒置了，所以在快的I/O设备上Programmed还是适用的(比如千兆的网卡)

**Key Issues**

* Device independence: programs can access any I/O device without specifying device in advance

  比如read一个设备，就用read，不read_xxx

* Uniform naming

  统一命名，比如访问键盘用dev_keyboard，访问硬盘用一个地址，那就不统一。便于移植

* Error handling

  出错时，尽可能处理靠硬件的方面(那个分层，往下)，因为很多硬件都是有自动纠错功能的。出错先问问自己！然后再问别人

* Synchronous or asynchronous

  是等着IO写完再干活还是一边IO一边干

* Buffering

  命中率，一致性

* Sharable or dedicated devices

  硬盘能共享，磁带不能，很专一

### 8.3 Hardwares

**Disks**

两种硬盘的参数

![[Operating System/img/td.png]]

* Server disk and PC disk: Server的更贵，存储密度低，通常一个文件分散在多个硬盘上，可以多个硬盘一块儿读，效率高

新老硬盘对比

![[Operating System/img/no.png]]

* 左新右旧
* 新硬盘每道的扇区数不一样，存储密度高，能做到更大容量
* 老式硬盘结构简单，只需要恒定转速即可

RAID(Redundant Array of Inexpensive / Independent Disks)

![[Operating System/img/raid.png]]

* RAID0: 不保存数据，没有备份
* RAID1: 保存一份(后面的阴影)
* RAID2: 按位存，但是硬盘都是按块存的，咋整？把文件块拆开，**一个块里存这些字节的第一bit**，下一块存这些字节的第二bit……
* RAID3: 比2多一个校验位
* RAID4: 比0多一个校验位
* RAID5: 4有个问题，每访问一块都要访问最后的校验位，所以把校验位分散在磁盘中

**Disk Formatting**

![[Operating System/img/ds.png]]

* Preamble: 标志一个扇区的开始，ECC校验位 ^c31505
* 低级格式化：格式化出扇区，高级格式化：格式化出一些管理数据(bitmap, superblock...)，**存放在Data里面**。所以尽量做高级格式化，做低级格式化要把所有扇区重新建一遍，对硬盘损伤很大

![[Operating System/img/df.png]]

* 第一圈的0和第二圈的0没对齐：为了优化

**Disk Arm Scheduling Algorithms**

3 factors

* Seek time(Major)
* Rotational delay
* Actual data transfer time

Shorted Seek First(SSF)

![[Operating System/img/ssf.png]]

> 假设现在在11，然后读11的时候，来了一堆请求 ，要读12,9,16,1,34，那就看这几个里谁离11最近读谁，那就是12，然后再看剩下的谁离12最近，9，所以读9……然后算seek motion就是看11读12挪了1,12读9挪了3

Elevator

![[Operating System/img/ele.png]]

> 就和坐电梯一样，只能往一个方向走，只有目的地都在另一边时才转向

**Error handling**

![[Operating System/img/eh.png]]

> 有保留扇区，如果第七块坏了，就把保留扇区替换那块坏的，号还是7

**CD-ROM**

![[Operating System/img/cdr.png]]

* 比如有坑是0，凸起是1，那就能存数据了

**Stable Storage**

![[Operating System/img/ss.png]]

> 两块盘
>
> * a：在写1之前出错，没啥事，重启就行了
> * b：在写1时出错，根据transaction原理，要恢复到没写时的状态，所以2号上的备份恢复到1号上就行
> * c，d：写2之前和写2时错误，那把1号上的复制到2号上就行了
> * e：写完2出错，那随便出

**Clock**

![[Operating System/img/cl.png]]

> Crystal oscillator：发射方波，发一个Counter减一下，减到0后就发一个中断

**Soft Timer**

![[Operating System/img/scl.png]]

> 用一个时钟通过软件来模拟多个时钟

**Terminal**

比如用户想要访问远方的一个主机，那就用一套硬件练到远方的主机上，这套硬件就叫做一个终端

![[Operating System/img/ter.png]]

> 比如登陆网站访问网页，那当前的电脑就可以叫终端，只不过这个终端是智能终端，早期的终端没有CPU啥的东西，只有键盘鼠标显示器，所以通过一个接口RS-232

*多个用户访问一个服务器，怎么确保服务端发回给用户的信息是对应的？*

Section management

![[Operating System/img/sm.png]]

**GUI Software**

![[Operating System/img/gui.png]]

```c
#include <windows.h>
int WINAPI WinMain(HINSTANCE h, HINSTANCE, hprev, char*szCmd, int iCmdShow){
    WNDCLASS wndclass; 			/*class object for this window*/
    MSG msg; 					/*incoming messages are stored here*/
    HWND hwnd; 					/*handle (pointer) to the window object*/
    /*Initialize wndclass*/
    wndclass.lpfnWndProc = WndProc; 			/*tells which procedure to call*/
    wndclass.lpszClassName = "Program name"; 		/*text for title bar*/
    wndclass.hIcon = LoadIcon(NULL, IDI APPLICATION); 	/*load program icon*/
    wndclass.hCursor = LoadCursor(NULL, IDC ARROW); 	/*load mouse cursor*/
    RegisterClass(&wndclass); 				/*tell Windows about wndclass*/
    hwnd = CreateWindow ( ... ) 			/*allocate storage for the window*/
    ShowWindow(hwnd, iCmdShow); 			/*display the window on the screen*/
    UpdateWindow(hwnd);				 /*tell the window to paint itself*/
    while (GetMessage(&msg, NULL, 0, 0)) { 			/*get message from queue*/
    Tr anslateMessage(&msg); 			/*translate the message*/
    DispatchMessage(&msg); 				/*send msg to the appropriate procedure*/
}
	return(msg.wParam);
}


long CALLBACK WndProc(HWND hwnd, UINT message, UINT wParam, long lParam){
    /*Declarations go here.*/
    switch (message) {
        case WM CREATE: ... ; retur n ... ; /*create window*/
        case WM PAINT: ... ; retur n ... ; /*repaint contents of window*/
        case WM DESTROY : ... ; retur n ... ; /*destroy window*/
	}
    return(DefWindowProc(hwnd, message, wParam, lParam)); /*default*/
}
```



> Call Back Function: 回调函数
>
> 回调函数不是由用户来调用，是由操作系统调用

**Font**

存字体，用矢量图存，存特定的点以及点和点之间的关系，每放大一下，就算一下

**X Window**

可以在网络上进行图像的处理

![[Operating System/img/xw.png]]

> **Exercise: **虚拟机Linux，然后Windows上下X Window程序，然后"远程"连接虚拟机

**Power Management**

![[Operating System/img/pm.png]]

> 显示器省电，window1要显示要点亮9块，那把它移到左上角，就只点亮4块了

![[Operating System/img/pmc.png]]

> CPU省电

*其他省电方式*

## 9. Deadlock

**Definition**

> A set of processes is deadlocked if each process in the set is waiting for an event that only another process **in the set** can cause

**Key factor**

* Race for Resource

> 因为对资源的竞争才会产生死锁

### 9.1 Four Conditions

Deadlock的4个必要条件(如果出现了Deadlock的话，那么)

* Mutual exclusion condition

  > Each resource is either currently assigned to exactly one process or is available.
  >
  > #question 这句话是不是说了和没说一样，改成：有人正在访问关键区是不是更好呢？

* Hold and wait condition

  > Process holding resources can request additional
  >
  > 某人不仅占着地方，还要别人的东西

* No preemption condition

  > Previously granted resources cannot forcibly taken away
  >
  > 占地方还要东西的人，还挺有礼貌，不抢

* Circular wait condition

  > * Must be a circular chain of 2 or more processes
  > * Each is waiting for resource held by next member of the chain

![[Operating System/img/cir.png]]

解释一下必要条件：有Deadlock，一定同时有这4个；但是有这4个里的某些，不一定是Deadlock

* 有互斥访问，但我也可以乖乖访问呀
* 我虽然占着资源还要别人的资源，不过我要的那个别人可能不要
* 连打劫的想法还没产生，对面直接交钱，不多bb
* **拿上面那张图说明，c占着u，想要t；d占着t，想要u，照理来说，c和d都不允许对方先拿自己的东西，所以会产生死锁，但是有可能，t和u是个数组，而c只占有u的前几个，而d要访问u的后几个，这样就不会产生死锁了。也就是，如果每个资源是有多个的时候，就不一定**

### 9.2 Deadlock Handling

#### 9.2.1 Ostrich Algorithm

不管，爱咋咋地。但是也有合理性，当今的UNIX和Windows就是这样，不管上层应用是否会产生死锁。因为管理成本太高太高了

#### 9.2.2 Detect and Recover

**每种资源有一个**

![[Operating System/img/dd.png]]

> 使用离散数学中的环，如果有环，那这个程序就有可能会产生Deadlock

**每种资源有多个**

![[Operating System/img/dd2.png]]

> 用个矩阵来检测
>
> * Em表示第m种资源有Em个
> * Am表示程序运行了一段时间之后，第m种资源可用的还有Am个
> * 左边那个c的矩阵的每一行是一个Process，Cnm表示第n个进程运行一段时间后占有的第m中资源有Cnm个
> * Rnm表示第n个进程运行一段时间后还想要的第m种资源有Rnm个

咋整捏？看个栗子就懂了

![[Operating System/img/lz.png]]

> 现在有3个进程，有四种资源，一共分别有4, 2, 3, 1个；在当前状态下，还能用的有2, 1, 0, 0个
>
> * 首先看需求，我还能用的能满足那些进程呢？
>
>   很显然，2100只能满足R的第三行2100，前两行因为有个1
>
>   所以第三行先运行，**运行完后就似了，要把财产交出来！**
>
> * 财产在哪儿？在C里！也就是第三行0120，那给它的2100再加上0120，就是第三行运行完似了后的可用向量：2220
>
> * 然后，2220能满足剩下的谁？第二行，所以让他来，第二行似了后，交出财产，可用向量变成4221
>
> * 然后4221能满足第一行，也能运行
>
> * 最后都能运行，没死锁！

**Recover**

出现Deadlock了，咋恢复呢？

* Preemption

  让对面还活着，但是把它的东西抢过来

* Rollback

  定期做快照，出死锁能回滚

* Killing process

  弄死，资源自然释放

#### 9.2.3 Avoidance

**Resource trajectories**

![[Operating System/img/dilei.png]]

> 用的比较少，看有没有地雷，有就绕着走

**Safe and Unsafe States**

* Safe State: 有至少一种资源分配路径能使得这些程序不会产生死锁

* Unsafe State: 不管我咋分配路径，都会产生死锁

  > * Safe State不代表不产生死锁，只是有那么一丝希望
  > * Unsafe State也不一定正处于死锁，只是有可能离死锁已经不远了；Safe也不一定正处于死锁，只是以后有可能遇到死锁，也有可能遇不到

![[Operating System/img/su.png]]

> 有五种状态，判断是Safe还是Unsafe。Free表示**ABC都想要**的，而且空闲的资源
>
> * a：我先分配给b，能执行完，b似了释放俩，现在有5个了；然后再分配给c，c正好执行完，之后释放2个，一共7个；然后分配给a，3 + 7 = 10 > 9，所以能执行完，Safe。也就是说，**存在一个资源分配方式：b, c, a使得不产生死锁，所以是Safe**
> * b：很显然是Unsafe，因为咋分配都执行不完。**但是b当前的状态不是死锁状态，因为B还能向下挪一挪**

**The Banker's Algorithm**

> What the algo-rithm does is check to see if <u>granting the request leads to an unsafe state</u>. If so, the request is denied. If granting the request leads to a safe state, it is carried out.

![[Operating System/img/bks.png]]

* a：随便走都能分完，一次分一个就行，safe
* b：先给c，然后给b或者d，然后……也是safe
* c：不管咋给都不行，unsafe

![[Operating System/img/bks2.png]]

* 现在有5个进程，4种资源，A表示还能用的资源，E表示总共有多少资源，P表示已经分配了多少资源
* 左边矩阵是每个进程已经有了多少资源；右边是每个进程还要多少才完事儿
* 那就看A(1020)能满足右边的谁，很显然只有D，那就先给他，让他完事儿释放资源，之后A变成了2121
* 然后2121能满足A，也能满足E，但是看到E占有的资源很少，先不给他，给A(其实给E也行，不过做题只需要试出一个Safe就成功，所以先A)
* 给A后，A变成了5132，然后再B，C，E。。。发现是Safe

#### 9.2.4 Prevention

* Attacking the **Mutual Exclusion** Condition

  > Key Idea: 不许竞争
  >
  > * Some devices (such as printer) can be spooled
  >   * only the printer daemon uses printer resource
  >   * thus deadlock for printer eliminated
  >
  > * Not all devices can be spooled
  > * Principle:
  >   * avoid assigning resource when not absolutely necessary
  >   * as few processes as possible actually claim the resource

* Attacking the **Hold and Wait** Condition

  > Require processes to request resources before starting
  >
  > * a process never has to wait for what it needs
  >
  > Problems
  >
  > * may not know required resources at start of run
  > * also ties up resources other processes could be using
  >
  > Variation:
  >
  > * process must give up all resources
  > * then request all immediately needed

  一次把所有资源拿到手，就不会Wait；一个资源也没有，就不会Hold

* Attacking the **No Preemption Condition**

  > This solution sometimes is not feasible.
  >
  > * Consider a process given the printer, but now it need a plotter that has already been given to others
  >   * halfway through its job
  >   * now forcibly take away printer
  >   * !!??
  >
  > 打印机打到一半被抢了，那到底打谁的？可能会造成系统不一致

* Attacking the Circular Wait Condition

  > 最推荐的方式
  >
  > 假设有两个进程，一个进程做`p(1); p(2);`，另一个进程做`p(2); p(1);`那么如果第一个进程在`p(1)`的时候没问题，然后进到`p(2)`的时候把自己阻塞了，就代表"我已经占用了资源1，但我还等着你把资源2给我"；同理，另一个进程就是"我已经占用了资源2，但我还等着你把资源1给我"。这样就会导致Deadlock。如果让两个进程都是`p(1); p(2)`，那么就不会产生Deadlock，原因就是破坏了环路等待
  

![[Operating System/img/cw.png]]

  > provide a global numbering of all the resources, processes can request resources whenever they want to, but all requests must be made **in numerical order**.
  >
  > * Normally ordered resources
  > * A resource graph

#### 9.2.5 Summary

**要考的：**

* 四个必要条件，概念填空

* 解释为啥是必要条件

* 给你一张表格：

  | Condition        | Approach                              |
  | ---------------- | ------------------------------------- |
  | Mutual exclusion | Spool everything                      |
  | Hold and wait    | Request all resources initially(最初) |
  | No preemption    | Take resources away                   |
  | Circular wait    | Order resources numerically           |

  只给你右边，让你填左边

多处理器用busywaiting 特别设计

## 10. Multiprocessor

![[Operating System/img/mp.png]]

> * a: shared memory motiprocessor
>
>   大家访问同一块内存
>
> * b: message-passing multicomputer
>
>   每个CPU有自己的内存，通过一个交叉网络传递信息
>
> * c: wide area distributed system
>
>   利用广域网实现

经常考：给你图，问是哪个架构

**UMA**(Uniform Memory Access): 访问内存的速度一样(**a**)

**NUMA**: 不一样(b, c)

## 11. Security

| Goal                         | Threat                    |
| ---------------------------- | ------------------------- |
| Data confidentiality(机密性) | Exposure of data          |
| Data integrity(完整性)       | Tampering(篡改) with data |
| System availability(可用性)  | Denial(拒绝) of service   |

**Covert Channel**(隐蔽信道)

**Symmetric key(对称秘钥)**: 加密和解密的秘钥是一样的

**Public key(公钥)**：加密和解密秘钥不一样

**Protection Domain**: 哪些进程能对哪些文件访问的表，一个进程的势力范围

**Access Control List(ACL)**：Protection Domain的一列是一个ACL，也就是一个文件对应一个ACL

**Discretionary access control(DAC)**: 自主访问控制，用户可以自己决定谁能访问

**Mandatory access control(MAC)**: 强制访问控制，系统生成的命令
