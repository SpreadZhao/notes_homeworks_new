---
title: Java中的锁
date: 2024-01-28
tags:
  - language/coding/java
  - language/coding/kotlin
  - question/coding/practice
  - question/interview
mtrace:
  - 2024-01-28
---
#language/coding/java #language/coding/kotlin #question/coding/practice  #question/interview 

# Syncronized

[Java并发常见面试题总结（中） | JavaGuide(Java面试 + 学习指南)](https://javaguide.cn/java/concurrent/java-concurrent-questions-02.html#synchronized-%E6%98%AF%E4%BB%80%E4%B9%88-%E6%9C%89%E4%BB%80%E4%B9%88%E7%94%A8)

我们从一道非常**常见且基础**的面试题开始（我自己就被考了三次，但一次也没完全写对）：*四个线程交替输出abcd，或者是三个线程交替输出1到100*。我们先从前者开始说起。

先简单想一想：如果想要四个线程这样输出的话，**不可能只工作一次**。从一个线程自己的视角来看，它的工作就是输出a到d中的一个字母。因此它的工作一定是**拼命地**进行输出这个字母：

```kotlin
class LockTest2 {  
	private val th1 = Thread {  
		// print a  
	}  
	private val th2 = Thread {  
		// print b  
	}  
	private val th3 = Thread {  
		// print c  
	}  
	private val th4 = Thread {  
		// print d  
	}  
	fun start() {  
		th1.start()  
		th2.start()  
		th3.start()  
		th4.start()  
		Thread.sleep(3000)  
	}  
}
```

那么我们可以很轻松地想到：4个`while(true）`不就好了嘛！

```kotlin
fun main() {  
	LockTest2().start()  
}  
class LockTest2 {  
	private var isRunning = true  
	private val th1 = Thread {  
		// print a  
		while (isRunning) {  
			print("a")  
		}  
	}  
	private val th2 = Thread {  
		// print b  
		while (isRunning) {  
			print("b")  
		}  
	}  
	private val th3 = Thread {  
		// print c  
		while (isRunning) {  
			print("c")  
		}  
	}  
	private val th4 = Thread {  
		// print d  
		while (isRunning) {  
			print("d")  
		}  
	}  
	fun start() {  
		th1.start()  
		th2.start()  
		th3.start()  
		th4.start()  
		Thread.sleep(3000)  
		isRunning = false  
	}  
}
```

这里为了方便观察，我设置了3秒后结束程序。现在看一看输出的结果：

![[Study Log/java_kotlin_study/resources/Pasted image 20230723224323.png]]

好像差距有点大呀！我们想一想现在的运行模式：四个线程同时启动，并且都在拼命地向控制台中打印自己的字母。而我们要的输出是这样的：

![[Study Log/java_kotlin_study/resources/Pasted image 20230723224447.png]]

其实也就是，**这些线程执行的顺序需要是固定且有序的**。我们目前的代码，就是让这些线程七手八脚在运行，完全将控制权交给了CPU。

## abcd

### Busy Waiting

我们可以按照[[Lecture Notes/Operating System/os#3.3 How to avoid race conditions?|操作系统]]讲的顺序来。首先是Busy Waiting，其实就是**我如果不想让这个线程进入，那就让它在原地空转**：

```kotlin
fun main() {  
	LockTest2().start()  
}  
class LockTest2 {  
	private var isRunning = true  
	private var curr = 1  
	private val th1 = Thread {  
		// print a  
		while (isRunning) {  
			while (curr != 1) {}  
			print("a")  
			curr = 2  
		}  
	}  
	private val th2 = Thread {  
		// print b  
		while (isRunning) {  
			while (curr != 2) {}  
			print("b")  
			curr = 3  
		}  
	}  
	private val th3 = Thread {  
		// print c  
		while (isRunning) {  
			while (curr != 3) {}  
			print("c")  
			curr = 4  
		}  
	}  
	private val th4 = Thread {  
		// print d  
		while (isRunning) {  
			while (curr != 4) {}  
			print("d")  
			curr = 1  
		}  
	}  
	fun start() {  
		th1.start()  
		th2.start()  
		th3.start()  
		th4.start()  
		Thread.sleep(3000)  
		isRunning = false  
	}  
}
```

非常简单！现在四个线程依然七手八脚地进入。但是除了th1，其它的线程都被前面的while循环给卡住了。当th1将curr改成了2之后，除了th2以外的其他线程也都陷入了while循环。如此往复下去，就能够按顺序进行输出了。

显然，这种忙等待的方式及其不优雅，并且很低效。因此我们才引入了锁来实现，也就是syncronized。

### Start Using Lock

首先来介绍一下Kotlin中的syncronized。一般用法是这样的：

```kotlin
syncronized(lock) {
	// do something
}
syncronized(lock) {
	// do otherthing
}
```

上面这两个syncronized块要的锁是同一个，意味着这两者只有其中之一会运行里面的代码。当一个线程执行到syncronized时，它会试图获取我们声明的锁。一旦获得了这个锁，就会进入代码块执行，并且拒绝任何其他试图获得锁的代码。直到执行完毕之后，才会释放这个锁，其它的代码段就可以获取了。

至于上面的锁lock，其实是什么都可以。只要是一样的对象，那么它们就存在竞争关系，也就达到了我们的目的。

下面我给出用syncronized实现的第一个版本，它是**错误**的：

```kotlin
fun main() {  
	LockTest2().start()  
}  
class LockTest2 {  
	private var isRunning = true   
	private val th1 = Thread {  
		// print a  
		synchronized(this) {  
			while (isRunning) {  
				print("a")  
			}  
		}  
	}  
	private val th2 = Thread {  
		// print b  
		synchronized(this) {  
			while (isRunning) {  
				print("b")  
			}  
		}  
	}  
	private val th3 = Thread {  
		// print c  
		synchronized(this) {  
			while (isRunning) {  
				print("c")  
			}  
		}  
	}  
	private val th4 = Thread {  
		// print d  
		synchronized(this) {  
			while (isRunning) {  
				print("d")  
			}  
		}  
	}  
	fun start() {  
		th1.start()  
		th2.start()  
		th3.start()  
		th4.start()  
		Thread.sleep(3000)  
		isRunning = false  
	}  
}
```

> 这种写法curr就没有作用了，因此删掉。

错在哪儿了呢？其实不需要深究，想一想：这样写，四个线程都**只会获取一次锁**。而在我们的要求中，锁应该是在四个线程中不停交换的。所以肯定是有问题的。那么下一个问题，*你能猜出来这段代码的执行结果吗*？其实也很简单。任意一个线程拿到了锁之后，都会陷入里面的while循环。因此最终的输出一定是a到d中的其中一个，且只有这个字符。而由于th1是最先开始的，所以最后的结果最有可能是满屏的a：

![[Study Log/java_kotlin_study/resources/Pasted image 20230723235006.png]]

那么，如果仅仅是把syncronized和while交换位置，可不可以呢？

```kotlin
fun main() {  
	LockTest2().start()  
}  
class LockTest2 {  
	private var isRunning = true  
		private val th1 = Thread {  
		// print a  
		while (isRunning) {  
			synchronized(this) {  
				print("a")  
			}  
		}  
	}  
	private val th2 = Thread {  
		// print b  
		while (isRunning) {  
			synchronized(this) {  
				print("b")  
			}  
		}  
	}  
	... ...
	fun start() {  
		th1.start()  
		th2.start()  
		th3.start()  
		th4.start()  
		Thread.sleep(3000)  
		isRunning = false  
	}  
}
```

显然，也是错误的。任意一个线程在任意时刻都有可能获得这个锁。因此也无法确定他们执行的顺序。其实，还是和之前的curr配合使用即可：

```kotlin
fun main() {  
	val stime = System.currentTimeMillis()  
	LockTest().start()  
	val etime = System.currentTimeMillis()  
	println()  
	println("time: ${(etime - stime) / 1000.0}")  
}  
class LockTest {  
	private var isRunning = true  
	private var curr = 1  
	private val th1 = Thread {  
		while (isRunning) {  
			synchronized(this) {  
				if (curr == 1) {  
					print("a")  
					curr = 2  
				}  
			}  
		}  
	}  
	private val th2 = Thread {  
		while (isRunning) {  
			synchronized(this) {  
				if (curr == 2) {  
					print("b")  
					curr = 3  
				}  
			}  
		}  
	}  
	private val th3 = Thread {  
		while (isRunning) {  
			synchronized(this) {  
				if (curr == 3) {  
					print("c")  
					curr = 4  
				}  
			}  
		}  
	}  
	private val th4 = Thread {  
		while (isRunning) {  
			synchronized(this) {  
				if (curr == 4) {  
					print("d")  
					curr = 1  
				}  
			}  
		}  
	}  
	fun start() {  
		th1.start()  
		th2.start()  
		th3.start()  
		th4.start()  
		Thread.sleep(5000)  
		isRunning = false  
	}  
}
```

这样的话，第一次获得锁的顺序还是不一定的。然而，除了th1以外，其它任何一个线程即使获得了锁，**也什么都不会做**。直到th1获得了锁之后，才会输出a，并将权力交给th2。

```ad-warning
千万不要把curr的赋值语句移到外面！

![[Study Log/java_study/resources/Pasted image 20230724000647.png|500]]
```

但是，这样的作法其实和之前的Busy Waiting没啥区别。因为无法获得锁的线程依然是在不停进行while循环来尝试获得锁。所以，**我们需要让无法获得锁的线程休息一下**。

### Sleep & Wakeup

这里使用的方法是`wait()`和`notifyAll()`。需要注意，**它们都是定义在Object**类中的。而Kotlin中的class并没有继承自Object，所以我们需要将锁换一下：

```kotlin
fun main() {  
	val stime = System.currentTimeMillis()  
	LockTest().start()  
	val etime = System.currentTimeMillis()  
	println()  
	println("time: ${(etime - stime) / 1000.0}")  
}  
class LockTest {  
	private var isRunning = true  
	private var curr = 1  
	private val lock = Object()  
	private val th1 = Thread {  
		while (isRunning) {  
			synchronized(lock) {  
				while (curr != 1) lock.wait()  
				print("a")  
				curr = 2  
				lock.notifyAll()  
			}  
		}  
	}  
	... ...
	fun start() {  
		th1.start()  
		th2.start()  
		th3.start()  
		th4.start()  
		Thread.sleep(5000)  
		isRunning = false  
	}  
}
```

注意改动。首先，我们将锁从this换成了变量lock。它是一个Object变量，所以可以调用它的wait()和notifyAll()来操控当前线程；在获得了锁之后，它会检查是否轮到自己输出了。在第一次，只有th1能进行下面的代码，其它的线程都会调用lock的wait()方法。而这个方法会立刻**释放当前持有的锁**，也就是lock变量。直到其它线程调用了notify()方法时，它会继续尝试获得这个锁。如果获得了，会从~~**wait()方法之后的地方开始执行**~~[^1]。

## 1-100

然后是这个比较难一点的。难在哪儿呢？就难在控制。在之前打印ABCD的时候，我们并没有强调什么时候才要结束。而如果明确强调要打印1-100时，就必须打印100之后立刻停止程序。所以，当某一个线程输出了100时，其它的程序就要立刻停止工作了。

这个需求的Busy Waiting版本是比较难实现的。如果按照之前的思想，代码就是这样的：

```kotlin
fun main() {  
	LockTest3().start()  
}  
class LockTest3 {  
	private var currNum = 1  
	private var curr = 1  
	private val th1 = Thread {  
		while (currNum <= 100) {  
			while (curr != 1) {}  
			println("[1]$currNum")  
			currNum++  
			curr = 2  
		}  
	}  
	private val th2 = Thread {  
		while (currNum <= 100) {  
			while (curr != 2) {}  
			println("[2]$currNum")  
			currNum++  
			curr = 3  
		}  
	}  
	private val th3 = Thread {  
		while (currNum <= 100) {  
			while (curr != 3) {}  
			println("[3]$currNum")  
			currNum++  
			curr = 1  
		}  
	}  
	fun start() {  
		th1.start()  
		th2.start()  
		th3.start()  
	}  
}
```

但是运行一下你就会发现，程序卡死了。因为这里产生了死锁，导致无法继续进行。另外，上一个abcd的程序，其实也有这样的情况！只是当时运气比较好，没有出现问题。解决方法就是，在会被修改的变量上面加上@Volatile，也就是currNum和curr。然而，加上之后虽然能按顺序输出，但是：

![[Study Log/java_kotlin_study/resources/Pasted image 20230724192915.png]]

这也是为什么我说这道题的结束控制是一个难点。如果不引入锁的话，是很难用纯粹的逻辑来决定程序何时应该结束的。

我们现在写一个带锁的版本。有了之前abcd的铺垫，这里的代码是很好懂的：

```kotlin
fun main() {  
	LockTest3().start()  
}  
class LockTest3 {  
	private var currNum = 1  
	private var curr = 1  
	private val lock = Object()  
	private val limit = 100  
	private val th1 = Thread {  
		while (currNum <= limit) {  
			synchronized(lock) {  
				while (curr != 1) lock.wait()  
				println("[1]$currNum")  
				currNum++  
				curr = 2  
				lock.notifyAll()  
			}  
		}  
	}  
	... ...
	fun start() {  
		th1.start()  
		th2.start()  
		th3.start()  
	}  
}
```

对于每一个线程，当没有轮到自己执行时，就锁住。每当一个线程执行完，就通知所有的线程来抢锁。这样就好了，现在运行一下代码：

![[Study Log/java_kotlin_study/resources/Pasted image 20230725153030.png]]

What？为啥还是102？这个问题的原因我想了非常久，最终终于明白了：

任意一个线程，如果卡死了，就是在wait()那里。而输出到最后一个数字limit时，其它的两个线程也都必定会卡在那里。然而，如果这个时候我们还通知它们来抢锁的话，它们一旦抢到了锁，**还是会从wait()处执行啊**[^1]！所以之后它们就会打印出那两个不应该打出来的数字。知道了问题所在，解决就很简单了：在notifyAll()之前加上currNum的判定就好：

```kotlin
fun main() {  
	LockTest3().start()  
}  
class LockTest3 {  
	private var currNum = 1  
	private var curr = 1  
	private val lock = Object()  
	private val limit = 100  
	private val th1 = Thread {  
		while (currNum <= limit) {  
			synchronized(lock) {  
				while (curr != 1) lock.wait()  
				println("[1]$currNum")  
				currNum++  
				curr = 2  
				if(currNum <= limit) lock.notifyAll()  
			}  
		}  
	}  
	... ...
	fun start() {  
		th1.start()  
		th2.start()  
		th3.start()  
	}  
}
```

这下输出终于是正常了！但是还有一点：*程序为啥没结束呢*？原因也很简单：由于你放弃了notifyAll，**那些被卡住的线程就永远卡住了**！在这之后，我有尝试了N多种可能，最后给出了一个完美实现的版本：

```kotlin
fun main() {  
	LockTest3().start()  
}  
  
class LockTest3 {  
	private var currNum = 1  
	private var curr = 1  
	private val lock = Object()  
	private val limit = 1000  
	@Volatile  
	private var shouldTerminate = false // 添加一个标志表示线程是否应该终止  
	private val th1 = Thread {  
		while (currNum <= limit && !shouldTerminate) { // 添加检查标志是否终止的条件  
			synchronized(lock) {  
				while (currNum <= limit && curr != 1 && !shouldTerminate) lock.wait()  
				if (currNum < limit) {  
					println("[1]$currNum")  
					currNum++  
					curr = 2  
				} else if (currNum == limit) {  
					if (currNum % 3 == 1) println("[1]$currNum")  
					terminate()  
				}  
				lock.notifyAll()  
			}  
		}  
	}  
	... ...
	fun start() {  
		th1.start()  
		th2.start()  
		th3.start()  
	}  
	  
	fun terminate() {  
		shouldTerminate = true // 设置终止标志  
	}  
}
```

首先，我们需要给一个让线程终止的条件，所以定义了shouldTerminate变量。当任意一个线程输出了最后一个数字时，都要调用terminate()方法终结所有线程的运行。并且，**当一个线程被notifyAll()唤醒时，会立刻重新走一遍这个while循环，看到shouldTerminate为true，就会跳出这个循环，然后什么也不会执行，最后跳出外层的while循环，结束自己**。

太复杂了！！！难道不是吗？我们可以观察一下，这些逻辑其实都是可以抽离出来的。所以我们可以定义一个Runnable来实现这个功能。另外，我们可以再继续优化一下，让它支持使用自定义个线程打印1到任意数字。这里给出最终的代码：

```kotlin
fun main() {  
	LockTest4(1000, 5).start()  
}  
class LockTest4(  
	limit: Int,  
	threadCount: Int  
) {  
	  
	private val threadList = ArrayList<Thread>()  
	  
	companion object {  
	  
		private val lock = Object()  
		  
		@Volatile  
		private var currNum = 1  
		  
		@Volatile  
		private var currThread = 1  
		  
		private var isRunning = true  
	  
	}  
	  
	init {  
		for (i in 1 .. threadCount) {  
			threadList.add(  
				Thread(PrintTask(i, limit, threadCount))  
			)  
		}  
	}  
	  
	fun start() {  
		for (thread in threadList) {  
			thread.start()  
		}  
	}  
	  
	class PrintTask(  
		private val threadNumber: Int,  
		private val limit: Int,  
		private val threadCount: Int  
	) : Runnable {  
		override fun run() {  
			while (isRunning && currNum <= limit) {  
				synchronized(lock) {  
					while (isRunning && currThread != threadNumber) {  
						lock.wait()  
					}  
					if (currNum < limit) {  
						println("[$threadNumber]$currNum")  
						currNum++  
						currThread = getNext(threadNumber)  
					} else if (currNum == limit) {  
						// 最后一次输出是不可控的，不信你就去掉if试试  
						// 这里currNum和limit相等，用谁都一样。但按理来说应该是前者。  
						if (match(threadNumber)) {  
							println("[$threadNumber]$currNum")  
						}  
						isRunning = false  
					}  
					lock.notifyAll()  
				}  
			}  
		}  
		  
		private fun getNext(num: Int) = if (num < threadCount) {  
			num + 1  
		} else {  
			1  
		}  
		  
		private fun match(num: Int) = if (num < threadCount) {  
			currNum % threadCount == threadNumber  
		} else {  
			currNum % threadCount == 0  
		}  
	  
	}  
}
```

为什么会有match()方法？如果去掉会怎么样？你可以试试，使用5个线程打印1到1000。如果去掉了match方法，会变成什么样子。

#TODO 

- [ ] 继续写Java的锁！

[volatile和synchronized到底啥区别？多图文讲解告诉你 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/111229417)

[^1]: ~~这个说法有错误，被唤醒的线程会重新试图获得syncronized中的锁，如果获得了，会重新执行syncronized代码块里面的代码~~。前面的说法还是有错误。确实是从wait()处执行。只不过需要获得锁，获得了锁之后从wait()处执行。又由于**我们是在while循环中**，所以之后还会判断curr的条件。