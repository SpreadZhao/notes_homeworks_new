#language/coding/java #language/coding/kotlin #question/coding/practice 

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

![[Study Log/java_study/resources/Pasted image 20230723224323.png]]

好像差距有点大呀！我们想一想现在的运行模式：四个线程同时启动，并且都在拼命地向控制台中打印自己的字母。而我们要的输出是这样的：

![[Study Log/java_study/resources/Pasted image 20230723224447.png]]

其实也就是，**这些线程执行的顺序需要是固定且有序的**。我们目前的代码，就是让这些线程七手八脚在运行，完全将控制权交给了CPU。

## Busy Waiting

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

## Start Using Lock

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

![[Study Log/java_study/resources/Pasted image 20230723235006.png]]

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

![[Study Log/java_study/resources/Pasted image 20230724000647.png]]
```

但是，这样的作法其实和之前的Busy Waiting没啥区别。因为无法获得锁的线程依然是在不停进行while循环来尝试获得锁。所以，**我们需要让无法获得锁的线程休息一下**。

## Sleep & Wakeup

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

注意改动。首先，我们将锁从this换成了变量lock。它是一个Object变量，所以可以调用它的wait()和notifyAll()来操控当前线程；在获得了锁之后，它会检查是否轮到自己输出了。在第一次，只有th1能进行下面的代码，其它的线程都会调用lock的wait()方法。而这个方法会立刻**释放当前持有的锁**，也就是lock变量。直到其它线程调用了notify()方法时，它会继续尝试获得这个锁。如果获得了，会从**wait()方法之后的地方开始执行**。