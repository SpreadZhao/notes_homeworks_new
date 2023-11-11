---
title: 1 并发编程的挑战
order: "1"
---
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

![[Study Log/java_kotlin_study/resources/Drawing 2023-09-19 11.40.49.excalidraw.png]]

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

![[Study Log/java_kotlin_study/resources/Pasted image 20230919120848.png]]

下面这个pid为18532的就是我们刚刚产生死锁的进程：

![[Study Log/java_kotlin_study/resources/Pasted image 20230919120928.png]]

下面，通过这个命令来输出dump日志（参考文章：[【Java基础】- JVM之Dump文件详解-阿里云开发者社区 (aliyun.com)](https://developer.aliyun.com/article/1301868)）。`jstack`也是jdk提供的工具。

```shell
jstack 18532 > thread.txt
```

然后日志就会默认输出到用户的目录中了：

![[Study Log/java_kotlin_study/resources/Pasted image 20230919121051.png]]

在里面，我们也可以成功看到这两个线程的信息：

![[Study Log/java_kotlin_study/resources/Pasted image 20230919121141.png]]

在日志的最后，dump也给出了死锁的详情：

![[Study Log/java_kotlin_study/resources/Pasted image 20230919121247.png]]

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