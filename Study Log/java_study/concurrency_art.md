---
tags:
  - language/coding/java
  - language/coding/kotlin
---
# Java并发编程的艺术

## 1 并发编程的挑战

### 1.1 上下文切换

- [?] 多线程一定快吗?

答案是否定的。主要的原因就是**上下文切换也会带来开销**。当我们频繁去切换线程做事情，如果做的事情本身的规模就很小，小到比切换线程的代价还小，那就有点舍本逐末了。

我们可以这么想：如果我想切换线程，那么CPU就需要**记住目前都执行到了哪里**，然后再切换到新的线程中去做事情。等做完了之后切回来的时候，也要从大脑中搜索之前记住的现场。而这部分需要的消耗就是**线程上下文切换**的代价。

我们用一个例子来说明这点，定义两个函数：

* `concurrency()`：使用两个线程并发执行。一个线程负责将a累加若干次，另一个线程负责将b累减若干次；
* `serial()`：使用一个线程来串行执行a的累加和b的累减操作。也就是先加a，再减b。

现在来写吧：

```kotlin
class ConcurrencyVSSerial {  
    companion object {  
        // 循环的次数  
        private const val count = 10000L
        
        private fun concurrency() {  
            val start = System.currentTimeMillis()  
            // a+和b-的操作由两个线程并发  
            val th = thread {  
                var a = 0  
                for (i in 0 until count) {  
                    a += 5  
                }  
            }  
            var b = 0  
            for (i in 0 until count) {  
                b--  
            }  
            val time = System.currentTimeMillis() - start  
            th.join()  
            println("concurrency: $time ms, b = $b")  
        }  
  
        private fun serial() {  
            val start = System.currentTimeMillis()  
            // a+和b-的操作在一个线程中串行  
            var a = 0  
            for (i in 0 until count) {  
                a += 5  
            }  
            var b = 0  
            for (i in 0 until count) {  
                b--  
            }  
            val time = System.currentTimeMillis() - start  
            println("serial: $time ms, b = $b, a = $a")  
        }  
  
        fun startVS() {  
            concurrency()  
            serial()  
        }  
    }  
}
```

我们通过count来控制累加和累减执行的次数，并分别统计了并发和串行的耗时。下面给出结论。如果并发的次数是10000次的话，结果是：

```
concurrency: 3 ms, b = -10000
serial: 0 ms, b = -10000, a = 50000
```

哦？**串行居然比并发还快**？虽然只快了3毫秒。接下来，我们不断增加count，给一个表格：

| count      | concurrency | serial |
| ---------- |:-----------:|:------:|
| 10000      |     3ms     |  0ms   |
| 100000     |     4ms     |  2ms   |
| 1000000    |     5ms     |  4ms   |
| 10000000   |     9ms     |  9ms   |
| 100000000  |    61ms     |  81ms  |
| 1000000000 |    527ms    | 650ms  |

在我们的例子中，当执行次数超过$10^7$次时，并发的执行才会体现出优势。因此，**多线程并不一定更快**。

- [?] 如何减少上下文的切换？

* **无锁并发编程**。多线程竞争锁时，会引起上下文切换，所以多线程处理数据时，可以用一些办法来避免使用锁，如将数据的 ID 按照 Hash 算法取模分段，不同的线程处理不同段的数据。
* **CAS 算法**。Java 的 Atomic 包使用 CAS 算法来更新数据，而不需要加锁。
* **使用最少线程**。避免创建不需要的线程，比如任务很少，但是创建了很多线程来处理，这样会造成大量线程都处于等待状态。
* **协程**：在单线程里实现多任务的调度，并在单线程里维持多个任务间的切换。

### 1.2 死锁

在[[Lecture Notes/Operating System/os#9. Deadlock|操作系统笔记]]中，我们就介绍过死锁，以及他的必要条件。但是当时我一直没有理解这些条件中的最后一条：

* Circular wait condition
	* Must be a circular chain of 2 or more processes
	* Each is waiting for resource held by next member of the chain 

如果一个线程（或者进程，下同）在访问临界区时出现了崩溃，导致它无法释放之前的资源。那么当其它线程想要使用这个资源时，就会被卡住。这也就导致了死锁。我们可以用一个例子来演示一下。

下面是两个线程t1和t2。由于我们首先调用的是`t1.start()`，所以大概率t1会先获得A这个锁。接下来，我们让t1在锁里面睡上10秒钟，来模拟“死在临界区”的情况。这样，当t2试图去获得这个锁时，就无法获得了。而过了10秒之后，t1才会释放这个A，然后输出1，并且t2此时也能获得A，输出2。

```kotlin
class Deadlock {  
    companion object {  
        // const means static  
        private const val A = "A"  
    }  
    fun dummyDeadlock() {  
        val t1 = Thread {  
            synchronized(A) {  
                Thread.sleep(1000 * 10)  
            }  
            println("1")  
        }  
        val t2 = Thread {  
            synchronized(A) {  
                println("2")  
            }  
        }        
        t1.start()  
        t2.start()  
    }
}
```

然而，我们要注意。这里其实是一个假的死锁。而真正的死锁还是要满足上面**环路等待**的情况。也就是说，在这个环中，至少有两个线程，并且每个线程都在等着下一个线程的资源。所以，现在我们来写一个真正的死锁：

![[Study Log/java_study/resources/Drawing 2023-09-19 11.40.49.excalidraw.png]]

在这个例子中，t1持有锁A，t2持有锁B。然而此时t1想要t2的B，同时t2又想要t1的A。这种才是一个环路等待的过程。下面我们来大致写一下代码：

```kotlin
class Deadlock {  
    companion object {  
        // const means static  
        private const val A = "A"  
        private const val B = "B"  
    }  
    fun deadlock() {  
        val t1 = Thread {  
            synchronized(A) {  
                synchronized(B) {  
                    println("1")  
                }  
            }        
		}        
		val t2 = Thread {  
			synchronized(B) {  
				synchronized(A) {  
					println("2")  
				}  
			}        
		}        
		t1.start()  
        t2.start()  
    }  
}
```

理想情况下，t1和t2同时执行，那么t1就会获得A，t2就会获得B。此时如果继续走下去的话，那么t1就会向t2要B，t2也会向t1要A。这样，就导致了死锁。

然而，由于现实是我们先调用了`t1.start()`，所以还没等t2开始执行，t1就已经把1输出了出来，并释放了B这个锁。因此，我们要将这个错误给放大。如何放大呢？只需要在t1获得锁A之后休眠一会就好了：

```kotlin
fun deadlock() {  
    val t1 = Thread {  
        synchronized(A) {  
            Thread.sleep(1000)  // 休眠一会儿
            synchronized(B) {  
                println("1")  
            }  
        }    
	}    
	val t2 = Thread {  
        synchronized(B) {  
            synchronized(A) {  
                println("2")  
            }  
        }    
	}    
	t1.start()  
    t2.start()  
}
```

这下当t1获得了A之后，没有立马获取B锁，导致t2得以执行并获得B，然后才能成功将死锁问题给暴露出来。下面，我们通过生成dump日志来看一看这个问题所在。

在windows中，`tasklist`命令可以输出正在运行的进程。

![[Study Log/java_study/resources/Pasted image 20230919120848.png]]

下面这个pid为18532的就是我们刚刚产生死锁的进程：

![[Study Log/java_study/resources/Pasted image 20230919120928.png]]

下面，通过这个命令来输出dump日志（参考文章：[【Java基础】- JVM之Dump文件详解-阿里云开发者社区 (aliyun.com)](https://developer.aliyun.com/article/1301868)）。`jstack`也是jdk提供的工具。

```shell
jstack 18532 > thread.txt
```

然后日志就会默认输出到用户的目录中了：

![[Study Log/java_study/resources/Pasted image 20230919121051.png]]

在里面，我们也可以成功看到这两个线程的信息：

![[Study Log/java_study/resources/Pasted image 20230919121141.png]]

在日志的最后，dump也给出了死锁的详情：

![[Study Log/java_study/resources/Pasted image 20230919121247.png]]

我们在os笔记中也说过，想要避免死锁，最有效的办法就是破坏那四个必要条件中的一个或多个。而这种策略可以总结成下面的几种方法：

* 避免一个线程同时获取多个锁。
* 避免一个线程在锁内同时占用多个资源，尽量保证每个锁只占用一个资源。
* 尝试使用定时锁，使用 lock.tryLock（timeout）来替代使用内部锁机制。
* 对于数据库锁，加锁和解锁必须在一个数据库连接里，否则会出现解锁失败的情况。

### 1.3 资源限制

说人话，还是在解释为什么并发有时候不会更快。如果你下载资源的速度是1mb/s，那么理论上你用了16线程去下载，应该能达到16mb/s。但是由于你家宽带的限制，撑死也就能到4mb/s的速度。所以，一些固有的资源本身也会成为并发效率的瓶颈。这些瓶颈主要有：

* 从硬件上来看：
	* 带宽的上传/下载速度
	* 硬盘读写速度
	* CPU处理速度（频率，核心数等等）
* 从软件上来看：
	* 数据库的连接数
	* socket连接数

有了这种限制，你的并发操作很有可能反而会降低执行速度。就是因为上下文切换和资源调度的时间。那么，如何在这种限制下更好地提高效率呢？非常简单，两个方向：

1. 突破限制（增加资源）；
2. 合理利用限制（别搞什么并发了，老老实实串行不香吗）。

## 2 Java并发机制的底层实现原理

在写Java单例模式时，有一种非常经典的写法，叫做[Double Check](https://www.cnblogs.com/leozmm/p/java_singleton_double_check.html)：

```java
class Singleton {
    private static volatile Singleton INSTANCE = null;  // <-- 禁止指令重排序
    private Singleton() {}

    public static getInstance() {
        if (null == INSTANCE) {                  // <-- 第1次，一般性检查，但是有并发隐患：可能有多执行流同时进入改处
            synchronized(Singleton.class) {
                if (null == INSTANCE) {          // <-- 此处第2次检查，为了防止后续多执行流并发时，后续获取同步锁的执行流，不会再次初始化Singleton对象
                    INSTANCE = new Singleton();
                }
            }
        }
        return INSTANCE;
    }
}
```

这里面的INSTANCE实例就是volatile的。那么它是什么意思呢？为什么Double Check要这么写呢？在本书中我们对这个问题来一个终极版的讲解。同时，这篇文章：[volatile和synchronized到底啥区别？多图文讲解告诉你 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/111229417)中的内存模型，也在本章中有很大的作用。

#TODO 

- [ ] 别忘了Double Check

[单例设计模式-Double Check - 阿叮339 - 博客园 (cnblogs.com)](https://www.cnblogs.com/DFX339/p/12531008.html#:~:text=%E5%8D%95%E4%BE%8B%E8%AE%BE%E8%AE%A1%E6%A8%A1%E5%BC%8F-Double%20Check,%E5%8D%95%E4%BE%8B%E8%AE%BE%E8%AE%A1%E6%A8%A1%E5%BC%8F%E4%B8%BB%E8%A6%81%E6%98%AF%E4%B8%BA%E4%BA%86%E4%BF%9D%E8%AF%81%E5%8F%AA%E5%88%9B%E5%BB%BA%E4%B8%80%E4%B8%AA%E5%AF%B9%E8%B1%A1%EF%BC%8C%E5%85%B6%E4%BD%99%E6%97%B6%E5%80%99%E9%9C%80%E8%A6%81%E5%A4%8D%E7%94%A8%E7%9A%84%E8%AF%9D%E5%B0%B1%E7%9B%B4%E6%8E%A5%E5%BC%95%E7%94%A8%E9%82%A3%E4%B8%AA%E5%AF%B9%E8%B1%A1%E5%8D%B3%E5%8F%AF%E3%80%82%20%E7%AE%80%E5%8D%95%E6%9D%A5%E8%AF%B4%EF%BC%8C%E5%B0%B1%E6%98%AF%E5%9C%A8%E6%95%B4%E4%B8%AA%E5%BA%94%E7%94%A8%E4%B8%AD%E4%BF%9D%E8%AF%81%E5%8F%AA%E6%9C%89%E4%B8%80%E4%B8%AA%E7%B1%BB%E7%9A%84%E5%AE%9E%E4%BE%8B%E5%AD%98%E5%9C%A8%E3%80%82)

### 2.1 volatile

首先，要回想起之前讲过的CPU三级缓存。因为内存实在是太慢了，所以在CPU上挂了三个相比于内存要快得多的缓存：L1、L2和L3。当我们要从内存中读数据时，会依次经过这些缓存，并留在里面。如果下次又要读的时候，会优先从这些缓存中去拿数据，比从内存中拿要快得多。

然而，一旦CPU变成了多线程，会怎样？有可能一个线程修改了这个值，但是这个值**还没来得及修改到其它线程对接的缓存中**。这样一来，如果其它线程又要读这个值，岂不是读到的就变成了旧的值了？因此，为了解决这个问题，我们需要一种手段，**来通知其它线程“对于这个值的修改操作已经发生”**。

而volatile的本质，我们可以通过转换成汇编来看。一个加了volatile的指令，在赋值的时候是这样的。如果下面的INSTANCE是一个volatile的变量：

```java
INSTANCE = new Singleton();
```

那么将他转换成汇编之后就是这样的：

```asm
0x01a3de1d: movb $0x0,0x1104800(%esi);
0x01a3de24: lock addl $0x0,(%esp);
```

对有volatile的变量进行**写操作**时，就会多出第二行代码。而这个lock指令根据IA-32的指令手册，有这样的两个功能：

* 将当前处理器`缓存行`的数据写回到系统内存；
* 这个写回内存的操作会使其它CPU里缓存了该内存的地址的数据无效。

```ad-note
这里要介绍一下“缓存行”这个概念。CPU是有Cache的，而Cache中肯定也不能全是一个字节一个字节的小地址排起来，也要分块的。而缓存行就是这个块的最小单位。它和内存的一个Page类似。
```

***注意，我们下面讨论的都是“写操作”，而不是“读操作”捏***。

想想我们要做什么：对于这段内存，我有一个新的值要写进去。然而在这之前，很有可能它已经被读取过若干次了，这就导致它的缓存可哪儿都是，内存中、CPU的各个级别的Cache中都有它的身影。那么我们想往这个内存中写入一个新值，应该如何保证**一致性**呢？

这就是lock指令的本质了：锁！锁啥？以前的处理器中，锁的是`总线`；而最近的处理器中，锁的只是缓存，也就是Cache。**如果一些Cache中存入了这些volatile的变量，那么就有可能被多个核或者线程去同时访问。因此锁的就是这些会被同时访问的Cache们**。另外，锁总线的开销比较大，这部分我们在后面的章节中会介绍。lock指令的第一个功能，就是把新值放到缓存里，并锁定这些会被同时访问的缓存**以及内存区域**，并将这个新值==在所有缓存中更新==，最终写回到内存里。 ^ce42bc

#TODO 

- [ ] ↑介绍了吗？

```ad-note
锁住了总线，其它CPU（核或线程）不能访问总线，不能访问也就意味着不能访问内存。
```

另一个功能，就是让其它的核或者线程认为这个内存地址是“无效的”。其它的线程其实都是可以去嗅探总线上的数据变化的，当有人想要写volatile的变量时，其它人就会嗅探到这一操作，并认为自己对接的这部分CPU Cache是无效的，这样也就不会出现**读到旧值**的情况了。

```ad-warning
title: 注意

注意前面说的“在所有缓存中更新”。这意味着什么呢？从网上找的资料中有写，`volatile`有这样的语义：

*保证了不同线程对这个变量进行操作时的可见性，即一个线程修改了某个变量的值，这新值对其他线程来说是**立即可见**的。*

这个立即可见，不就是这个意思吗\~
```

### 2.2 syncronized

syncronized一共有三种使用方法：

```java
public class Syncronized {  
    private final static Object lock = new Object();  

	// 方法1：锁普通方法
    public synchronized void function1() {  
  
    }  
    // 方法2：锁静态方法
    public static synchronized void function2() {  
  
    }  
    // 方法3：锁代码块
    public void function3() {  
        synchronized (lock) {  
  
        }  
    }  
}
```

1. 普通的方法用syncronized修饰，锁是当前**实例对象**。
2. 静态方法使用syncronized修饰，锁是当前**类的Class对象**。
3. 在同步块代码中，锁是**括号里写的对象**。

那么，*凭什么对象可以作为锁呢*？*当一个对象作为锁存在时，它又是怎么工作的呢*？想要了解这个问题，首先要了解java对象的结构。

#### 2.2.1 Java对象头

[涨姿势啦！Java程序员装X必备词汇之Mark Word！ - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/399423994)

Java对象的实例可以分为下面三个部分：

* 对象头
* 实例数据
* padding

padding很好理解，就是将实例的大小补齐成字节的整数倍，也就是8bit的整数倍；而实例数据就是对象内部的一些内容；最后就是这个对象头了。它和什么ipv4的请求头，文件的metadata一样，都是用来存储对象的基本信息的。而锁的信息也存储在对象头中。

而对象头又可以分为两个或三个部分：

* Mark Word
* Class Metadata Address
* Array length（如果是数组）

这三个东西每个都占了一个Word（字）。而一个字的大小取决于是32位还是64位的系统。在32位的系统中，它们占的空间都是32bit，也就是4个字节；而在64位系统中，它们所占的空间分别是64bit 64bit 32bit。

|   长度   |          内容          |             说明             |
|:--------:|:----------------------:|:----------------------------:|
| 32/64bit |       Mark Word        | 存储对象的hashCode或锁信息等 |
| 32/64bit | Class Metadata Address |   存储到对象类型数据的指针   |
| 32/32bit |      Array length      |          数组的长度          |

我们之前也听过什么“偏向锁”，“轻量级锁”这些概念。而这些信息就存储在Mark Word里。我们可以稍微浏览一下Mark Word的大致结构，这里就只看64位系统的了：

![[Study Log/java_study/resources/Pasted image 20230921154823.png]]

下面我们先介绍一下锁的其它概念，再回头来看这个表格，就清晰多了。

#### 2.2.2 锁的升级与对比

Java的对象在锁的方面，一共有四种状态：

1. 无锁状态；
2. **偏向锁**状态；
3. **轻量级锁**状态；
4. **重量级锁**状态

它们的级别从低到高，**代表着线程的竞争的激烈程度也越来越高**。***锁只能升级，不能降级***。

```ad-hint
title: 注意

这里的四种状态，指的是<u>一个对象作为锁时的不同状态</u>。比如，一把锁一开始只是一个对象，并没有被放在syncronized中，那么此时它就处于无锁状态；而随着竞争越来越激烈，这个对象的锁状态也会不断**升级**。
```

##### 偏向锁

`偏向锁`是Java中最轻量的锁。是在Java SE 1.6中，为了**减少获得锁和释放锁的性能消耗**而引入的。

当一个线程初次获得偏向锁时，会在**锁对象**的对象头中记录自己这个线程的ID。之后再获取的时候，就不用进行`CAS`来加锁和解锁了，只需要看看锁的对象头的Mark Word中的这个偏向锁的线程ID是否是自己。

```ad-note
CAS(Compare And Swap)操作：[【Java并发】面试官问我CAS、乐观锁、悲观锁，我反手就是骑脸输出_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1ff4y1q7we/?spm_id_from=333.788&vd_source=64798edb37a6df5a2f8713039c334afb)
```

然后是一个问题：为什么会叫做“偏向”锁？从名字上听，就是在说，**只要我获得了这个锁，那么这把锁就是==偏向==我的，之后它不会再去偏向别人**。

那么这样看来，这把锁的设计是比较特殊的。也就是说，**一旦一个线程获得了这把锁，之后也最有可能一直是它在获得这把锁**。为什么要这么设计？HotSpot的作者经过研究发现，**大多数情况下，锁==不仅不存在多线程竞争，而且总是由同一线程多次获得==**。

懂了吧\~\~，其实就是因为有这样的现象，才有了这样的设计。如果每次都是同一个线程在获得这把锁，那*为什么还要每次都麻烦人家去加锁解锁呢*？因此，偏向锁的根本目的是，**让线程（大多数情况下，是同一个线程）获得锁的代价更低**。

为啥要有偏向锁？如果我这把锁只能给一个线程，那为啥还要加锁？还记得锁的升级过程吗？**偏向锁的存在，是为了在并发过程一开始的时候，让一个线程访问的情况的性能更好**。一旦有第二个线程试图去竞争这把锁，那么就不再是偏向锁了。

更直白一点说，下面的方法：

```java
public static syncronized void method() {
	doSomething();
}
```

是一个加了锁的方法，很多线程都会同时调用它。那么，在程序刚运行起来的时候，如果只有一个线程会调用这个方法，那为啥还要加锁呢？但是，在之后的过程中，可能还会有其他的线程会调用这个方法。因此，偏向锁就是为这段**只有一个线程访问**的空档期而生的。

[（二）偏向锁详解_匿名偏向锁-CSDN博客](https://blog.csdn.net/qq_28773223/article/details/109706667#:~:text=%E5%81%8F%E5%90%91%E9%94%81%EF%BC%88%E4%B8%8D%E5%A4%AA%E9%9C%80%E8%A6%81%E7%AB%9E%E4%BA%89%E7%9A%84%EF%BC%8C%E4%B8%80%E8%88%AC%E4%B8%80%E4%B8%AA%E7%BA%BF%E7%A8%8B%EF%BC%89%20%E6%9C%AA%E5%BF%85%E4%BC%9A%E6%8F%90%E9%AB%98%EF%BC%8C%E5%B0%A4%E5%85%B6%E6%98%AF%E5%BD%93%E4%BD%A0%E7%9F%A5%E9%81%93%E4%B8%80%E5%AE%9A%E4%BC%9A%E6%9C%89%E5%A4%A7%E9%87%8F%E7%BA%BF%E7%A8%8B%E5%8E%BB%E7%AB%9E%E4%BA%89%E7%9A%84%E6%97%B6%E5%80%99%E3%80%82%20%E6%89%93%E5%BC%80%E5%81%8F%E5%90%91%E9%94%81%E5%81%8F%E5%90%91%E9%94%81%E8%BF%98%E6%9C%89%E4%B8%80%E4%B8%AA%E9%94%81%E6%92%A4%E9%94%80%E7%9A%84%E8%BF%87%E7%A8%8B%EF%BC%88%E6%8A%8AID%E6%92%95%E4%B8%8B%E6%9D%A5%EF%BC%89%EF%BC%8C,2.%E4%B8%BA%E4%BB%80%E4%B9%88%E8%A6%81%E5%BB%B6%E8%BF%9F4s%20%E5%9B%A0%E4%B8%BAJVM%E8%99%9A%E6%8B%9F%E6%9C%BA%E8%87%AA%E5%B7%B1%E6%9C%89%E4%B8%80%E4%BA%9B%E9%BB%98%E8%AE%A4%E7%9A%84%E5%90%AF%E5%8A%A8%E7%BA%BF%E7%A8%8B%EF%BC%8C%E9%87%8C%E9%9D%A2%E6%9C%89%E5%A5%BD%E5%A4%9Async%E4%BB%A3%E7%A0%81%EF%BC%8C%E8%BF%99%E4%BA%9B%E4%BB%A3%E7%A0%81%E5%90%AF%E5%8A%A8%E6%97%B6%E5%B0%B1%E8%82%AF%E5%AE%9A%E4%BC%9A%E6%9C%89%E7%AB%9E%E4%BA%89%EF%BC%8C%E5%A6%82%E6%9E%9C%E7%9B%B4%E6%8E%A5%E4%BD%BF%E7%94%A8%E5%81%8F%E5%90%91%E9%94%81%EF%BC%8C%E5%B0%B1%E4%BC%9A%E9%80%A0%E6%88%90%E5%81%8F%E5%90%91%E9%94%81%E4%B8%8D%E6%96%AD%E7%9A%84%E8%BF%9B%E8%A1%8C%E9%94%81%E6%92%A4%E9%94%80%E5%92%8C%E9%94%81%E5%8D%87%E7%BA%A7%E7%9A%84%E6%93%8D%E4%BD%9C%EF%BC%8C%E6%95%88%E7%8E%87%E8%BE%83%E4%BD%8E%203.%E6%80%8E%E6%A0%B7%E8%AE%BE%E7%BD%AE%E5%81%8F%E5%90%91%E9%94%81%E5%BB%B6%E8%BF%9F%E6%97%B6%E9%97%B4)

[Java的Synchronized锁-偏向锁 - 掘金 (juejin.cn)](https://juejin.cn/post/6994404508344270878)

接下来，我们来看一个例子，来说明上面的结论。定义一个偏向锁的模型：

```kotlin
class BiasLock {  
    var i = 0  
    @Synchronized  
    fun incr() {  
        i++  
        System.out.println(Thread.currentThread().name + " - " + ClassLayout.parseInstance(this).toPrintable())  
    }  
}
```

当有线程调用这个`incr()`方法时，就会进入同步代码块的区域。下面，我们在主线程中调用一下试试：

```kotlin
class LockTest() {  
    companion object {  
        fun test() {  
            val lock = BiasLock()  
            System.err.println(ClassLayout.parseInstance(lock).toPrintable())  
            lock.incr()  
            System.err.println(ClassLayout.parseInstance(lock).toPrintable())  
        }  
    }  
}
```

执行`LockTest.test()`就可以了。然而，如果你使用的是jdk15+的版本，应该不会看到有关偏向锁的信息。因为在这之后偏向锁已经被默认移除了：[java偏向锁默认开启还是关闭,JDK15 默认关闭偏向锁优化原因-CSDN博客](https://blog.csdn.net/weixin_39764379/article/details/116055860)

为了重新开启偏向锁，我们需要配置虚拟机参数：

![[Study Log/java_study/resources/Pasted image 20231003164409.png]]

```
-XX:+UseBiasedLocking -XX:BiasedLockingStartupDelay=0
```

此时的输出是这样的：

```shell
Java HotSpot(TM) 64-Bit Server VM warning: Option UseBiasedLocking was deprecated in version 15.0 and will likely be removed in a future release.
Java HotSpot(TM) 64-Bit Server VM warning: Option BiasedLockingStartupDelay was deprecated in version 15.0 and will likely be removed in a future release.
# WARNING: Unable to get Instrumentation. Dynamic Attach failed. You may add this JAR as -javaagent manually, or supply -Djdk.attach.allowAttachSelf
concurrency.lock.BiasLock object internals:
OFF  SZ   TYPE DESCRIPTION               VALUE
  0   8        (object header: mark)     0x0000000000000005 (biasable; age: 0)
  8   4        (object header: class)    0x00c02420
 12   4    int BiasLock.i                0
Instance size: 16 bytes
Space losses: 0 bytes internal + 0 bytes external = 0 bytes total

concurrency.lock.BiasLock object internals:
OFF  SZ   TYPE DESCRIPTION               VALUE
  0   8        (object header: mark)     0x000002aec274c805 (biased: 0x00000000abb09d32; epoch: 0; age: 0)
  8   4        (object header: class)    0x00c02420
 12   4    int BiasLock.i                1
Instance size: 16 bytes
Space losses: 0 bytes internal + 0 bytes external = 0 bytes total

main - concurrency.lock.BiasLock object internals:
OFF  SZ   TYPE DESCRIPTION               VALUE
  0   8        (object header: mark)     0x000002aec274c805 (biased: 0x00000000abb09d32; epoch: 0; age: 0)
  8   4        (object header: class)    0x00c02420
 12   4    int BiasLock.i                1
Instance size: 16 bytes
Space losses: 0 bytes internal + 0 bytes external = 0 bytes total
```

有两个问题需要说明一下：

1. 一开始的警告就是在说，偏向锁已经被移除了，最好不要用，会有性能损失；
2. 第三段，也就是main开头的那个，是我在`incr()`方法里面写的。如果单步调试走的话，这段应该在中间，也就是第二段输出。我也不知道为什么它会出现在第三段。

从输出信息，我们能看出，偏向锁已经启动。并且，当`incr()`方法执行结束之后，偏向锁中保存的线程ID依然是`0x00000000abb09d32`。也就是说，**偏向锁是不会解锁的，它只会属于一个线程**。

```ad-note
下图中，线程1执行偏向锁的获得过程；线程2执行偏向锁的撤销过程。
```

![[Study Log/java_study/resources/Pasted image 20231002215029.png]]

其他资料：[难搞的偏向锁终于被 Java 移除了 - 掘金 (juejin.cn)](https://juejin.cn/post/7046921350065160206#heading-2)这篇资料介绍了为什么偏向锁被废弃，为什么偏向锁启用需要延迟4秒左右。以及还没有提到的epoch等等内容。

#TODO 

- [ ] 偏向锁的这部分内容，之后有时间的话最好补充上去。

##### 轻量级锁

一旦有两个或以上线程去竞争一把锁时，偏向锁就会升级成为`轻量级锁`。这里主要采用的手段是CAS操作。

在之前的例子中，我们只需要修改一下LockTest：

```kotlin
class LockTest(private val lock: BiasLock) : Runnable {  
    override fun run() {  
        this.lock.incr()  
    }  
    companion object {  
        fun test() {  
            val lock = BiasLock()  
            System.err.println(ClassLayout.parseInstance(lock).toPrintable())  
            lock.incr()  
            System.err.println(ClassLayout.parseInstance(lock).toPrintable())  
            Thread(LockTest(lock)).start()  
        }
    }  
}
```

这样就有两个线程在竞争lock这把锁，当第二次执行到`incr()`方法时，我们就能看到，锁已经升级成了thin-lock。

[Java锁之偏向级锁、轻量级锁、重量级锁_偏向锁是什么?轻量级锁是什么?_Colourful．的博客-CSDN博客](https://blog.csdn.net/Colorful_X/article/details/117110786)

[轻量级锁加解锁过程详解 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/141554048)

---

在介绍轻量级锁的加锁和解锁过程之前，我们需要先了解一下**栈帧**这个概念。这个概念在我正式学习之前也有所了解和认知，但总是感觉如梦似幻，下面就来正式介绍一下。

[图解栈帧，别再死记硬背_Java_李子捌_InfoQ写作社区](https://xie.infoq.cn/article/6b7026f6d930eca0efa021371)

程序运行都有个栈空间，这是我们知道的。但是，这个栈空间内部是什么样的呢？我们猜都能猜出来：**就是栈帧组成的呗**！

![[Study Log/java_study/resources/Pasted image 20231003191740.png]]

程序在运行的时候，会**进行若干次的函数调用，甚至递归调用**。每调用一个函数，我们就需要在**这次函数执行的周期内**，在栈空间中分配一段空间，用来存这个函数独有的变量。

```java
public static void method() {
	int a;
}
```

上面代码中的变量a就是这个方法独享的，也自然只存在于为这个函数分配的**栈帧**中。

---

ok，现在可以介绍轻量级锁的加锁过程了。其实非常简单：

***1. 将锁的对象头中的Mark Word复制到线程自己的栈帧中***。

线程的栈帧的这部分空间叫做**Lock Record**，复制过来的Mark Word叫做**Displaced Mark Word**。直译过来，就是“被移走的Mark Word”。非常简单易懂是不是🙂。

***2. 线程尝试将锁的对象头的Mark Word替换为自己这个Displaced Mark Word的指针***。

这一步稍微有点绕，我们画个图解释一下。首先，线程自己的栈帧里存的是Displaced Mark Word，也就是从锁里面复制过来的：

![[Study Log/java_study/resources/Drawing 2023-10-03 22.23.04.excalidraw.png]]

然后，**这个Displaced Mark Word肯定会有个地址呀**！我们假设它是`0x1234abcd`。那么接下来，这个地址就会被替换到锁的Mark Word中：

![[Study Log/java_study/resources/Drawing 2023-10-03 22.26.30.excalidraw.png]]

现在回头看一下之前介绍Mark Word内部结构时的图片：

![[Study Log/java_study/resources/Pasted image 20230921154823.png]]

当锁为轻量级锁时，Mark Word的结构就是一个指针加上标识位00。这和我刚刚画的图是一样的。

但是要注意，只是在尝试。这就代表不一定能成功。由于**这步替换操作使用的是CAS**，那么就意味着会有其它线程也要进行替换。而如果某个线程比我抢先一步进行了替换，那么我如果立刻进行替换的话，就产生了竞争。那么我此时的替换就会失败。

失败了之后呢？我当前这个线程会使用~~自旋~~来不断重新尝试获取锁。而如果总是获得不了，达到一定次数之后，就会升级成重量级锁。

```ad-note
真的会自旋吗？看看这篇文章：[别再和面试官说Synchronized轻量级锁自旋了，错了！_牛客网 (nowcoder.com)](https://www.nowcoder.com/discuss/353157586415460352)
```

---

然后，是轻量级锁解锁的过程。其实很简单，我们刚刚不是复制了个Displaced Mark Word出来吗？**它其实就相当于一个备份**。在备份之后，我们将原来锁中的Mark Word的前边都替换成了我们这个DMW的指针。那既然要解锁，把备份还原回去就行了呗：

***使用CAS操作将Displaced Mark Word替换回到锁的对象头中***。

```ad-attention
title: 注意

加锁时的替换指针的操作，和解锁时还原备份的操作，都是CAS。
```

如果还原成功，那么就没有发生竞争，成功解锁；如果失败，那么就代表此时依然还存在锁的竞争。那么此时锁就会变成重量级的锁。

![[Study Log/java_study/resources/Pasted image 20231003224859.png]]

其它资料：[死磕Synchronized底层实现--概论 · Issue #12 · farmerjohngit/myblog (github.com)](https://github.com/farmerjohngit/myblog/issues/12)

- [>] 锁的优缺点对比

| 锁       | 优点                                                               | 缺点                                           | 适用场景                           |
| -------- | ------------------------------------------------------------------ | ---------------------------------------------- | ---------------------------------- |
| 偏向锁   | 加锁和解锁不需要额外的消耗，和执行非同步方法相比仅存在纳秒级的差距 | 如果线程间存在锁竞争，会带来额外的锁撤销的消耗 | 适用于只有一个线程访问同步块的场景 |
| 轻量级锁 | 竞争的线程**不会阻塞**，提高了程序的响应速度                           | 如果始终得不到锁竞争的线程，~~使用自旋会消耗CPU~~  | 追求响应时间，同步块执行速度非常快 |
| 重量级锁 | 线程竞争不使用自旋，不会消耗CPU                                    | 线程**阻塞**，响应时间慢                           | 追求吞吐量，同步块执行速度较慢                                   |

```ad-note
注意之前对于自旋的解释。
```

### 2.3 原子操作

#### 2.3.1 处理器如何实现原子操作

> <small>32 位 IA-32 处理器使用基于对缓存加锁或总线加锁的方式来实现多处理器之间的原子操作。首先处理器会自动保证基本的内存操作的原子性。处理器保证从系统内存中读取或者写入一个字节是原子的，意思是当一个处理器读取一个字节时，其他处理器不能访问这个字节的内存地址。Pentium 6 和最新的处理器能自动保证单处理器对同一个缓存行里进行 16/32/64 位的操作是原子的，但是复杂的内存操作处理器是不能自动保证其原子性的，比如跨总线宽度、跨多个缓存行和跨页表的访问。但是，处理器提供<font color="yellow">总线锁定</font>和<font color="yellow">缓存锁定</font>两个机制来保证复杂内存操作的原子性。</small>

##### 总线锁

现在假设，我们要执行两次`i++`操作。如果i的初值是1，那么结果应该是3。但是如果这两次i++操作是由两个线程去完成的，那可能会有这样的情况：

![[Study Log/java_study/resources/Pasted image 20231005134008.png]]

两个CPU同时读到了i的初值都是1，然后分别把它们加成了2，然后写回到内存中。这样的结果就是错误的。

错误的根本原因在于，**当一个CPU对变量进行修改时，另一个变量也试图读取==并修改==这个变量，且成功读取**。所以我们要做的就是，让他失败。

总线锁就是处理器提供的一个`LOCK#`信号，当一个处理器在总线上输出这个信号的时候，**其它处理器的请求就会阻塞**。之前介绍volatile的时候我们也提到过：[[#^ce42bc]]

##### 缓存锁

也是之前的介绍中，比总线锁更聪明的是缓存锁。既然你不让多个CPU同时读到i，那你只把i的那段内存锁住不就好了嘛，还干嘛锁整个总线呢？**在同一时刻，我们只需要保证对某个内存地址的操作是原子性的即可**。

还记得之前说过的L1 L2 L3缓存吗？如果是频繁使用的内存，那么它们就更有可能出现在这些缓存中。所以，对于会被并发操作（多人运动）的内存，我们只需要在它对应的缓存中进行原子操作就可以了。

在上面的例子中，如果CPU1在修改i的时候使用了`缓存锁定`，那么CPU2就不能同时缓存i的缓存行。

**但是，有一些例外情况，我们不能使用缓存锁，只能使用总线锁**：

* 当操作的数据根本就不能缓存时；
* 数据跨多个缓存行（cache line）时；
* 处理器本身就不支持缓存锁时。

> <small>针对以上两个机制，我们通过 Intel 处理器提供了很多 Lock 前缀的指令来实现。例如，位测试和修改指令：BTS、BTR、BTC；交换指令 XADD、CMPXCHG，以及其他一些操作数和逻辑指令（如 ADD、OR）等，被这些指令操作的内存区域就会加锁，导致其他处理器不能同时访问它。</small>

#### 2.3.2 Java如何实现原子操作

其实就是AtomicXXX。我们写一个计数器来比较一下线程安全和非线程安全的区别。

首先，需要两个变量。一个是线程安全的整数，一个是非线程安全的整数：

```kotlin
class AtomCounter {  
    // Thread safe counter  
    private val atomicInteger = AtomicInteger(0)  
    // Thread unsafe counter  
    private var i = 0
}
```

然后，定义两个方法。一个对线程安全的整数累加，另一个对非线程安全的整数累加：

```kotlin
class AtomCounter {  
    // Thread safe counter  
    private val atomicInteger = AtomicInteger(0)  
    // Thread unsafe counter  
    private var i = 0  
  
    private fun safeCount() {  
        while (true) {  
            var i = atomicInteger.get()  
            val success = atomicInteger.compareAndSet(i, ++i)  
            if (success) break  
        }  
    }  
  
    private fun unsafeCount() {  
        i++  
    } 
}
```

这里要注意线程安全的累加过程。由于多线程并发过程中，很有可能在进行累加的时候会出现竞争，所以不能只累加，还要先比较一下，当累加成功之后才退出，否则**使用循环**不断尝试累加。这样才能保证**任意线程的任意一个累加任务都能执行成功**。

最后测试一下。我们使用100个线程并发执行，也就是在一个List里面塞100个线程。每个线程的任务都是：

* 循环累加`atomicInteger`10000次；
* 循环累加`i`10000次。

```kotlin
companion object {  
    fun test() {  
        val cas = AtomCounter()  
        val threads = ArrayList<Thread>(600)  // 600这个数字不重要
        val start = System.currentTimeMillis()  
        repeat(100) { // thread count  
            val t = Thread {  
                for (i in 0 until 10000) {  
                    cas.safeCount()  
                    cas.unsafeCount()  
                }  
            }  
            threads.add(t)  
        }  
        for (t in threads) {  
            t.start()  
        }  
        // Wait all threads to finish.  
        for (t in threads) {  
            try {  
                t.join()  
            } catch (e: InterruptedException) {  
                e.printStackTrace()  
            }  
        }  
        println("unsafe res: ${cas.i}")  
        println("safe res: ${cas.atomicInteger}")  
        println("time: ${System.currentTimeMillis() - start} ms")  
    }  
}
```

我们多执行几次，看看结果：

```
unsafe res: 996511
safe res: 1000000
time: 131 ms

unsafe res: 995692
safe res: 1000000
time: 134 ms

unsafe res: 992205
safe res: 1000000
time: 127 ms
```

可以看到，三次执行结果中，非线程安全的版本每次的结果都不一样，可见它并没有很好地控制多线程并发的情况；而使用了AtomicInteger之后，无论怎么执行，都是100个线程每个累加了10000次，最后的结果一直都是1000000。

---

接下来，讲讲为什么要用循环。我们如果把线程安全的版本这么写：

```kotlin
private fun safeCount2() {  
    atomicInteger.set(atomicInteger.get() + 1)  
}
```

那么执行几次你就会看到，和非线程安全的版本没有什么不同。如果改成下面的样子，就是仅仅把while循环去掉，也是不行的：

```kotlin
private fun safeCount2() {  
    val i = atomicInteger.get()  
    atomicInteger.compareAndSet(i, i + 1)
}
```

如果想不用循环这么麻烦，其实Atomic包里有个原子自增的方法：

```kotlin
private fun safeCount2() {  
    atomicInteger.incrementAndGet()  
}
```

这样就只需要一句话就能控制并发了。但是要记住，这里的`incrementAndGet()`方法**本质上还是使用循环CAS的方式去实现的**。

#TODO 

- [ ] 这里的过程，以及CAS内部的原理，之后要研究一下。

---

CAS这好那好，也总会出现问题。有三个非常经典的问题：

1. ABA问题
2. 循环时间长，开销大
3. 只能保证一个共享变量的原子操作

- [>] ABA问题

从上面的例子，我们不难猜出`compareAndSet()`这个方法内部大致的执行步骤。假设i的值原来是2，我们想要把他变成3的话：

> 1. 看看现在的值是几；
> 2. 如果是2的话，就认为它没发生变化，把它变成3，返回true；
> 3. 如果不是2的话，就认为它发生了变化，返回false表示操作失败。

这个步骤看起来没问题，但是我们想想这样的一个情况。一个线程瞅了一眼这个i，发现它是2。此时它理所当然地认为，i没有发生过变化。但是还有一种可能，就是在它“瞅这一眼”之前，其它的线程**先把这个i从2改成了100，又把它从100改回了2**。这样虽然结果上来说没有发生变化，但是事实是**i已经确确实实被其它的变量修改过了**。

虽然看起来这样的问题不会带来什么严重的后果，但事实并不是这样。如果在我“瞅这一眼”之前，其它线程进行了修改，修改回来的操作，**但是这个操作本身就是一个非法的操作**，这就意味着即使最后结果是好的，但是已经产生了一次非法的行为（跟我去自首🕶）。

解决这个问题的办法也很简单，就是加上版本号就好了。每次修改这个值的时候，都顺带着更新一下附带的版本号，然后每次比较的时候不但要比较值是否相同，还要比较版本号是否相同。

比如在上面的例子中，i的变化是这样的：

$$
2 \rightarrow 100 \rightarrow 2
$$

带上版本号之后，就是这样的：

$$
2(1) \rightarrow 100(2) \rightarrow 2(3)
$$

如果一开始我拿到的版本号是1，然后经过其它线程的偷鸡操作之后再一看，虽然值一样都是2，*但版本号咋变成3了*？**肯定是有人趁我不注意给改了**。所以我直接报告失败就行了，等下一次循环的时候我拿到的就是新的2(3)了。

- [>] 循环时间长开销大

其实从上面的例子叕能看出来，自旋的CAS就烂在自旋。每次失败之后还要while循环跑回去重新试一遍，这就很像busy waiting的思想了。然后是书上的一些废话，看他的意思，好像JVM还不支持pause指令，只是幻想时间而已。

> <small><font color="yellow">如果（这个如果就很灵性）</font> JVM 能支持处理器提供的 pause 指令，那么效率会有一定的提升。pause 指令有两个作用：第一，它可以延迟流水线执行指令（de-pipeline），使 CPU 不会消耗过多的执行资源，延迟的时间取决于具体实现的版本，在一些处理器上延迟时间是零；第二，它可以避免在退出循环的时候因内存顺序冲突（Memory Order Violation）而引起 CPU 流水线被清空（CPU Pipeline Flush），从而提高 CPU 的执行效率。</small>

- [>] 只能保证一个共享变量的原子操作

还是上面的`atomicInteger`，它只是一个整数对吧，我们不能在一次CAS操作中操作多个共享变量。因此，如果想操作多个变量，要么使用锁，要么将多个变量合并。比如AtomicReference就可以将多个变量塞到一个对象里操作。

```ad-note
title: 使用锁机制实现原子操作

锁机制保证了只有获得锁的线程才能够操作锁定的内存区域。JVM 内部实现了很多种锁机制，有偏向锁、轻量级锁和互斥锁。有意思的是除了偏向锁，JVM 实现锁的方式都用了循环 CAS，即当一个线程想进入同步块的时候使用循环 CAS 的方式来获取锁，当它退出同步块的时候使用循环 CAS 释放锁。
```

## 3 Java内存模型

### 3.1 Java内存模型的基础

