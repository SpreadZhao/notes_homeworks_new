---
title: 5 Java中的锁
order: "5"
chapter_root: true
chapter: "5"
---

## 5.1 Lock接口

Lock和synchronized在使用层面上，最大的区别就是：

* synchronized锁的获取和释放是隐式的（大括号）；
* lock的获取和释放是手动的。

因此，我们想象一下这样的情况：

```kotlin
synchronized(A) {
	synchronized(B) {
		// 释放A?
	}
}
```

假设当获取到了B锁之后，我认为A锁已经不需要获取了。那么这个时候咋释放A锁？因为大括号在那儿，所以我们很难实现。但是**如果锁的释放和获取都是手动的**，这个过程就要简单很多。又或者书上的一个例子：

> <small>例如，针对一个场景，手把手进行锁获取和释放，先获得锁 A，然后再 获取锁 B，当锁 B 获得后，释放锁 A 同时获取锁 C，当锁 C 获得后，再释放 B 同时获取 锁 D，以此类推。这种场景下， synchronized 关键字就不那么容易实现了，而使用 Lock 却容易许多。</small>

Lock的使用方式如下：

```kotlin
val lock = ReentrantLock()
lock.lock()    // 在try外部释放锁
try {
	/* 临界区 */
} finally {
	lock.unlock()
}
```

> [!warning]
> 不要将锁的获取写在try里面。如果获取时发生了异常，锁会被无故释放。

- [ ] #TODO 举个例子？ ⏫ ➕ 2024-02-18

Lock提供了synchronized不具备的特性。在注释中有所描述：

> Lock implementations provide additional functionality over the use of synchronized methods and statements by providing a **non-blocking** attempt to acquire a lock (tryLock()), an attempt to acquire the lock that **can be interrupted** (lockInterruptibly, and an attempt to acquire the lock that can **timeout** (tryLock(long, TimeUnit)).

总结起来三点：

* 非阻塞获取：获取失败的话，不会阻塞当前线程；
* 中断获取：获取失败的话，当前线程会休眠，直到锁被当前线程获取成功或者其它线程中断了当前线程；另外，如果获取到锁的线程被中断，那么会抛出InterruptedException，并释放锁；
* 超时获取：如果规定时间没获取到，就返回。

Lock接口中的方法就先不介绍了（其实上面就已经说了一些了），我们之后再细说。这里先回顾一下之前的concurrent包结构：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240203160837.png]]

> 首次提到：[[Study Log/java_kotlin_study/concurrency_art/3_5_lock_mm_semantics|3_5_lock_mm_semantics]]

## 5.2 AbstractQueuedSynchronizer

继续之前，建议重看一遍[[Study Log/java_kotlin_study/concurrency_art/3_5_lock_mm_semantics|3_5_lock_mm_semantics]]。这个类叫做『队列同步器』，目的就是“**让锁的实现更简单和规范**”。

这个类提供了三个`protected`且`final`的方法来修改同步器的同步状态：

* getState()
* setState()
* compareAndSetState()

> [!note]
> 这里要@一下之前说过的一段话：[[Study Log/java_kotlin_study/concurrency_art/3_5_lock_mm_semantics#^b71a4e|3_5_lock_mm_semantics]]。如果你继承了AQS，那么子类就必须定义一些protected的方法来改变这个state。这句话可能会引起一些歧义。上面的这三个方法其实就是protected的，它们也是用来修改同步状态（也就是那个volatile的int）的。那么，为啥注释里会这么说呢？
> 
> 根据我的猜测，比如你在AQS的子类里想要定义一个方法，将这个同步状态改变：
> 
> ~~~kotlin
> fun setSomeState(factor1: Int, factor2: Int) {
> 	this.setState(factor1 shl 2 + factor1 / factor2)
> }
> ~~~
> 
> 这里我写的比较复杂。就是说，如果你这个状态是通过某些复杂的因素算出来的一个值。那么这个方法也是和那三个一样是要修改状态的。因此，AQS建议这些方法也定义成protected：
> 
> ~~~kotlin
> protected fun setSomeState(factor1: Int, factor2: Int) {
> 	this.setState(factor1 shl 2 + factor1 / factor2)
> }
> ~~~

^c383c9

AQS也建议，AQS的子类应该被定义为同步组建的静态内部类（Helper Class）。

理解锁、AQS的关系：

* 锁面向的是使用者，使用者使用锁提供的接口可以进行多线程的并发控制；
* AQS面向的是锁的实现者，使用AQS的规范可以更规范、更安全地实现锁的同步机制。**AQS内部屏蔽了同步状态管理、线程排队、等待唤醒等底层操作**。

### 5.2.1 AQS接口与示例

我们自己来实现一个同步组建。就写个Mutex（互斥锁）吧！

自己写一个类Mutex，继承自Lock。发现有这些方法需要实现：

```kotlin
override fun lock()

override fun tryLock(): Boolean

override fun unlock()

override fun tryLock(time: Long, unit: TimeUnit): Boolean {
	return sync.tryAcquireNanos(1, unit.toNanos(time))
}

override fun unlock() {
	sync.release(1)
}

override fun newCondition(): Condition {
	return sync.newCondition()
}
```

其中和本次无关的方法我们已经给出了简单的默认实现。重点关注lock, trylock, unlock这三个方法。

我们需要明确的第一件事情是，有try和没有try的有什么区别。我们已经总结过，锁的获取有三种方式：

* 非阻塞
* 中断
* 超时

然而，这三种只是synchronized不具备的方式。还有一种和synchronized一样的方式，也就是阻塞获取。即如果获取不到，当前线程就会停留在队列里，直到获取成功。我们看看Lock接口中lock()方法的注释，发现它就是说的这种方式：

```java
/**
 * Acquires the lock.
 *
 * If the lock is not available then the current thread becomes
 * disabled for thread scheduling purposes and lies dormant until the
 * lock has been acquired.
 */
void lock();
```

通过描述，我们来看看，lock应该咋实现？

* 如果获取成功，那么啥事没有，直接进入就行了；
* 如果获取失败，需要进入到队列中。

如果没有AQS的话，我们可能想象的是，获取的时候设置个啥状态啊，然后获取失败了，需要自己维护一个队列啊，这个队列里面有好多个线程在排队啊，每次轮到一个线程都要尝试再获取啊，获取失败的线程需要<label class="ob-comment" title="wait" style=""> wait <input type="checkbox"> <span style=""> 实际上AQS的实现用的是park </span></label>啊，谁获取成功了或者谁释放锁了需要notify啊。。。

然而，AQS帮我们做的事情就是这些。所以这些我们统统不用去想。AQS暴露出的这个接口我们可以直接调用，来实现阻塞的获取锁：

```java
/**
 * Acquires in exclusive mode, ignoring interrupts.  Implemented
 * by invoking at least once {@link #tryAcquire},
 * returning on success.  Otherwise the thread is queued, possibly
 * repeatedly blocking and unblocking, invoking {@link
 * #tryAcquire} until success.  This method can be used
 * to implement method {@link Lock#lock}.
 *
 * @param arg the acquire argument.  This value is conveyed to
 *        {@link #tryAcquire} but is otherwise uninterpreted and
 *        can represent anything you like.
 */
public final void acquire(int arg) {
	if (!tryAcquire(arg))
		acquire(null, arg, false, false, false, 0L);
}
```

我们暂时先不管它内部到底做了什么，后面都会提到。只需要看注释的第一段最后：This method can be used to implement method `Lock#lock()`。所以，我们lock的实现如下：

```kotlin
override fun lock() {  
    sync.acquire(1)  // 其中sync就是继承自AQS的内部类。目前不需要实现AQS的什么方法
}
```

然后，就是实现tryLock()，也是最重要的。我们思考一下，和lock唯一的区别就是，如果获取失败了，直接返回就好了。但是，AQS给我们提供的acquire()在获取失败后会直接阻塞，并不是我们想要的。

那么，我们首先考虑到的就是自己实现。还记得之前说的那三个protected吗？现在到了用它们的时候了：

```kotlin
override fun tryLock(): Boolean {
	if (compareAndSetState(0, 1)) {
		exclusiveOwnerThread = Thread.currentThread()
		return true
	}
	return false
}
```

如果获取成功了，那么就成功了！如果失败了，返回false来让获取锁的线程知道，好进行其它操作。

现在成功了吗？看起来我们已经实现的差不多了。但是，如果你真的认为成功了，那就说明我写的代码你根本没自己copy或者自己写一份验证一下。因为，我写的这个tryLock根本就是报错的！

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240219164436.png]]

为啥？还用问吗？你自己定义的Mutex里哪里来的这些方法？这些方法是定义在AQS中的！因此，我们需要开始定制自己的sync了。从之前lock()的实现就能看出来，我把sync当成了内部类，就像推荐的那样：

```kotlin
class Mutex : Lock {

    private val sync = Sync()

    private class Sync : AbstractQueuedSynchronizer()

	... ...
}
```

既然AQS里才有这些接口，那么我们就在里面封装一下：

```kotlin
private class Sync : AbstractQueuedSynchronizer() {
	fun tryLock(): Boolean {
		if (compareAndSetState(0, 1)) {
			exclusiveOwnerThread = Thread.currentThread()
			return true
		}
		return false
	}
}
```

然后在外面实现tryLock：

```kotlin
override fun tryLock(): Boolean {
	return sync.tryLock()
}
```

好了。我们现在来验证一下，我们实现的lock是否正常工作。首先从tryLock开始。

```kotlin
fun test() {
    val mutex = Mutex()
    thread {
        if (!mutex.tryLock()) println("th1 try lock failed!") else println("th1 try lock success")
        println("th1 exit")
    }
    SleepUtils.second(1)
    thread {
        if (!mutex.tryLock()) println("th2 try lock failed!") else println("th2 try lock success")
        println("th2 exit")
    }
}
```

第一个线程获取了锁之后，输出成功。之后直接退出并没有释放锁。所以即使th1已经结束，th2在获取锁的时候也会失败。因此输出：

```shell
th1 try lock success
th1 exit
th2 try lock failed!
th2 exit
```

但是，如果我们在th1终结前调用`mutex.unlock()`，就能让th2成功。

> [!tip]
> 这里忘了，我们好像还没给unlock()的实现。这个不那么重要，随便实现一下就可以了：
> 
> ~~~kotlin
> override fun unlock() {
> 	sync.release(1)
> }
> ~~~
> 

- [x] #TODO 这里录个音解释一下吧。文字修改太多了，主要把tryRelease补上。 🔺 ➕ 2024-02-19 ✅ 2024-02-21

> [!todo] 这里录个音解释一下吧。文字修改太多了，主要把tryRelease补上。
> * #date 2024-02-21 ![[Study Log/java_kotlin_study/concurrency_art/resources/Recording 20240221233231.webm|Recording 20240221233231]]
> 

下面，我们来看看默认的lock是否正常工作。这里我们用做过的[[Study Log/java_kotlin_study/java_kotlin_study_diary/lock_in_java|交替打印]]的例子来做：多个线程交替输出1-100。

```kotlin
class LockTest {

    companion object {
        var i = 1
        var currThNum = 1
        val mutex = Mutex()
    }

    class MutexPrintThread(private val thNum: Int, private val otherNum: Int) : Thread("mutex-thread-$thNum") {
        override fun run() {
            while (i < 100) {
                mutex.lock()
                if (currThNum != thNum && mutex.isLocked) {
                    mutex.unlock()
                    continue
                }
                println("thread $thNum print $i")
                currThNum = otherNum
                i++
                mutex.unlock()
            }
        }
    }
}
```

这里主要关心while循环中的实现。如果一个线程获得了锁，之后发现当前输出的线程不是自己并且<label class="ob-comment" title="已经被锁住" style=""> 已经被锁住 <input type="checkbox"> <span style=""> isLocked的实现就是我们设置的那个state是不是1。 </span></label>了，那么要立刻释放这个锁以便让其它线程获取。同时重新获取这个锁。等获取了锁之后，打印并增加数字，同时指定下一个应该打印数字的线程。

这个实现我们可以发现，只要我们的线程形成了一个环，那么多少个线程交替都是能做到的：

```kotlin
fun testPrint() {
    val pt1 = LockTest.MutexPrintThread(1, 2)
    val pt2 = LockTest.MutexPrintThread(2, 3)
    val pt3 = LockTest.MutexPrintThread(3, 1)
    pt1.start()
    pt2.start()
    pt3.start()
}
```

启动！果然，失败了：

```shell
Exception in thread "mutex-thread-1" Exception in thread "mutex-thread-3" Exception in thread "mutex-thread-2" java.lang.UnsupportedOperationException
	at java.base/java.util.concurrent.locks.AbstractQueuedSynchronizer.tryAcquire(AbstractQueuedSynchronizer.java:816)
	at java.base/java.util.concurrent.locks.AbstractQueuedSynchronizer.acquire(AbstractQueuedSynchronizer.java:937)
	at concurrency.lock.Mutex.lock(Mutex.kt:45)
	at concurrency.lock.LockTest$MutexPrintThread.run(LockTest.kt:14)
java.lang.UnsupportedOperationException
	at java.base/java.util.concurrent.locks.AbstractQueuedSynchronizer.tryAcquire(AbstractQueuedSynchronizer.java:816)
	at java.base/java.util.concurrent.locks.AbstractQueuedSynchronizer.acquire(AbstractQueuedSynchronizer.java:937)
	at concurrency.lock.Mutex.lock(Mutex.kt:45)
	at concurrency.lock.LockTest$MutexPrintThread.run(LockTest.kt:14)
java.lang.UnsupportedOperationException
	at java.base/java.util.concurrent.locks.AbstractQueuedSynchronizer.tryAcquire(AbstractQueuedSynchronizer.java:816)
	at java.base/java.util.concurrent.locks.AbstractQueuedSynchronizer.acquire(AbstractQueuedSynchronizer.java:937)
	at concurrency.lock.Mutex.lock(Mutex.kt:45)
	at concurrency.lock.LockTest$MutexPrintThread.run(LockTest.kt:14)
```

看到，三个线程都抛出了UnsupportedOperationException异常。而AQS的tryAcquire的默认实现就抛出了这个异常：

```java
/**
 * Attempts to acquire in exclusive mode. This method should query
 * if the state of the object permits it to be acquired in the
 * exclusive mode, and if so to acquire it.
 *
 * <p>This method is always invoked by the thread performing
 * acquire.  If this method reports failure, the acquire method
 * may queue the thread, if it is not already queued, until it is
 * signalled by a release from some other thread. This can be used
 * to implement method {@link Lock#tryLock()}.
 *
 * <p>The default
 * implementation throws {@link UnsupportedOperationException}.
 *
 * @param arg the acquire argument. This value is always the one
 *        passed to an acquire method, or is the value saved on entry
 *        to a condition wait.  The value is otherwise uninterpreted
 *        and can represent anything you like.
 * @return {@code true} if successful. Upon success, this object has
 *         been acquired.
 * @throws IllegalMonitorStateException if acquiring would place this
 *         synchronizer in an illegal state. This exception must be
 *         thrown in a consistent fashion for synchronization to work
 *         correctly.
 * @throws UnsupportedOperationException if exclusive mode is not supported
 */
protected boolean tryAcquire(int arg) {
	throw new UnsupportedOperationException();
}
```

为什么会这样？我们调用的明明是lock()，里面的实现调用的是acquire()，为啥最后还是会try？其实，无论从报错的调用栈，还是你直接去看AQS里面的代码，都能看到，==所有关于锁的获取，如果获取成功，那么一定是从`tryAcquire()`这个方法成功的==。也就是说，如果一个AQS的非抽象子类最终都没有实现`tryAcquire()`方法的话，那么它永远不可能实现阻塞的获取锁。

之所以之前tryLock()是工作的，是因为它根本没涉及到AQS内部的接口调用，只是设置了一下状态而已。

在我们的例子中，Mutex无论是tryLock还是lock，其实最终获取锁的动作没有区别。所以我们可以将这两个合到一起去：

```kotlin
private class Sync : AbstractQueuedSynchronizer() {

	fun tryLock(): Boolean {
		return tryAcquire(1)
	}

	override fun tryAcquire(arg: Int): Boolean {
		if (compareAndSetState(0, 1)) {
			exclusiveOwnerThread = Thread.currentThread()
			return true
		}
		return false
	}
}
```

现在，这个例子已经可以工作了。这个例子涉及的东西比较多，后续关于这个Mutex相关的内容我会更新到日记中：[[Study Log/java_kotlin_study/java_kotlin_study_diary/2024-02-19-java-kotlin-study|2024-02-19-java-kotlin-study]]

回答一下这个过程中可能会遇到的问题：

- [?] *为什么你知道在获取锁的时候要用`compareAndSetState()`？*
- [>] 这是AQS的规定。可以看看`tryAcquire()`的注释，开头就说了这个方法应该查询当前状态是否能够获取。而查询状态的方法，或者说和状态有关的方法只有那三个protected。
- [?] *为什么最后成功只能在`tryAcquire()`中成功？*
- [>] 也是tryAcquire()的注释有提到。只要线程要获取锁，就是调用这个方法。其实也很好理解，即使我获取失败就休眠，那我总得先试试才行。
- [?] *为什么`tryAcquire()`是protected的？*
- [>] 我们发现tryAcquire()是protected的，代表在sync之外是不让使用的。所以，如果我们自己在我们的Mutex里调用`sync.tryAcquire()`是获取不到的。我们的做法是封装了一层`sync.tryLock()`，<label class="ob-comment" title="然后让`tryLock()`去调用最终的tryAcquire()" style=""> 然后让`tryLock()`去调用最终的tryAcquire() <input type="checkbox"> <span style=""> 注意，这也是建立在tryLock()的行为恰好和tryAcquire()一致的条件下的。比如ReentrantLock的tryLock()和tryAcquire()就有一些区别，所以不能直接调用 </span></label>；而书上的做法是在自己重写Sync的时候直接将tryAcquire()改成public的。这种做法我本人不太赞成。 ^817568
- [?] *<font color="red">为什么要有lockXXX和XXXAcquire两套接口？</font>*
- [>] 这是最重要的一个问题。明明我们实现了Lock接口，依赖了AQS中的能力，<label class="ob-comment" title="那么我直接在Lock里面去调用AQS的接口不好吗" style=""> 那么我直接在Lock里面去调用AQS的接口不好吗 <input type="checkbox"> <span style=""> 比如就是上个问题，我直接调用那个protected的tryAcquire()不香吗？ </span></label>？为啥还要再封装一层？这就谈到了AQS的设计模式了。我们接下来就要讨论这个问题。

到这里，我们来看看Lock和AQS是怎么合作，并由锁的使用者使用的：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-02-19 21.00.37.excalidraw.png]]

图中的箭头表示调用。可以发现，在我们实现的Mutex中，所有Lock的接口都没有调用我们重写的AQS的方法（比如tryAcquire()），而是调用了AQS内置的一些『模板方法』。而之所以你会问出刚刚最后的那个问题，就是因为AQS中并没有为tryLock()专门提供一个这样的模板方法。不提供的原因也很好理解，因为tryLock()并不需要获取失败之后的一系列操作，失败了就失败了。所以这个简单的逻辑就移交给开发者自己了。分析ReentrantLock源码也能发现，它的tryLock()的实现也完全是自己搞定的。

这也是我不赞成书上将Mutex中的AQS的tryAcquire()改成public的原因。因为这个方法本身就不应该暴露给Lock，Lock能调用的只应该是那些模板方法。

最后，总结一下这个Mutex。最重要的加锁逻辑就是tryAcquire()中的这一句：

```kotlin
if (compareAndSetState(0, 1)) {
	......
}
```

其实就是CAS操作。我们调用了AQS的那三个protected且final中的一个，来更改内置的state，将0改成了1。如果成功了，那就表示锁被【当前线程】获取到了。因此，在if里面才会将exclusiveOwnerThread改为当前的Thread。

通过这点，我们也能猜出来：咋知道当前Mutex是否被某个线程获取了？**state是1就得了**！

```kotlin
val heldExclusively: Boolean
	get() = state == 1
```

### 5.2.2 AQS实现分析

- [/] #TODO 看jdk8的AQS源码。jdk17改了太多。以后有时间再分析。 🔼 ➕ 2024-02-23 🛫 2024-02-23
- [ ] #TODO 这部分因为jdk17的源码改动太大了，所以我先从8开始。后面有机会把jdk17的解析补上。➕ 2024-02-23 🔽 
- [ ] #TODO 这一节中说的锁是指state，也就是书中的同步状态，并不是外面那个lock。这点容易混淆，修改一下。➕ 2024-02-23 🔺 

AQS的同步队列的实现，是一个由线程组成的双向链表。链表中的每一个元素都代表着一个想要**获得锁**的线程。而在jdk8中，锁有两种：

* exclusive: 互斥锁，只有一个线程能获得。
* shared: 共享锁，不只有一个线程能获得。

- [ ] #TODO 共享锁，不只有一个线程能获得。真的吗？➕ 2024-02-23 🔺 

我们现在只介绍互斥锁。之前的`acquire()`方法就是互斥锁获得的实现。下图是AQS中双向链表的结构：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-02-23 14.45.38.excalidraw.png]]

非常好理解，一个head一个tail。那么现在如果我们想要新入队一个节点，应该怎么做？稍微思考一下，大致为以下几步：

1. 构造新的节点`node`；
2. `node`的前驱节点为现在的`tail`；
3. 现在的`tail`的后继节点为`node`；
4. 将`tail`指向`node`；
5. 返回`node`，也就是新的`tail`。

非常简单，就是在一个双向链表中插入尾节点的逻辑。我们试着将它写成代码：

```java
private Node addWaiter(Node mode) {
	// 使用当前线程构造新的节点
	Node node = new Node(Thread.currentThread(), mode);
	// 当前的尾节点
	Node pred = tail;
	if (pred != null) {
		// 设置新的尾节点
		this.tail = node;
		// 建立连接
		node.prev = pred;
		pred.next = node;
	}
	// 返回新的尾节点
	return node;
}
```

看起来很nice对吧！但是，别忘了这是AQS，一个用于多线程的场景。假设有10个线程同时调用`acquire()`，那么只有1个线程能获得锁，其它9个线程都要变成node进入这个队列。因此，addWaiter()方法会被多个线程同时调用。

问题就出在这里。如果这段逻辑没有任何并发控制的话，后果不堪设想。整个链表的结构会在高并发场景下瞬间乱七八糟。因此，我们需要引入并发控制。

第一个问题就是，谁在并发场景下会混乱？显而易见，就是`tail`。因为每个线程的`node`都是自己，不存在共享一说，但是每个线程读到的当前AQS的`tail`却是同一个。

知道了这点，我们怎么入手？加锁？可以，但是性能就太差了。jdk8中选择的是CAS：

```java
private Node addWaiter(Node mode) {
	Node node = new Node(Thread.currentThread(), mode);
	// Try the fast path of enq; backup to full enq on failure
	Node pred = tail;
	if (pred != null) {
		node.prev = pred;
		if (compareAndSetTail(pred, node)) {
			pred.next = node;
			return node;
		}
	}
	/* 获取失败了 */
}
```

会引起混乱的代码乍一看主要是这两句：

```java
node.prev = pred;
pred.next = node;
```

但是我们再乍一下就能发现，只有第二句是会导致并发异常的。为啥？**因为只有第二句涉及了对`tail`的写操作**。第一句中只是设置了一下新的node的前驱节点，这并不会让其它线程之后读到错误的结果，即使`node.prev`被设置之后出现了错误。

因此，jdk的做法是仅将第二句用设置尾节点的CAS包裹起来：

```java
if (compareAndSetTail(pred, node)) {
	pred.next = node;
	return node;
}
```

`compareAndSetTail()`是包装的方法，作用是以CAS的方式进行设置。

* 第一个参数是我希望`AQS.tail`现在指向的是谁。pred是我刚刚读出来的尾节点。如果之后发现不是，那么就是有人在这个过程中将`AQS.tail`换成了其它node；
* 第二个参数是如果是**我希望**的话，要将`AQS.tail`换成什么。我要换成的就是新的尾节点node。

因此，以上操作就是在`this.tail = node;`的基础上增加了CAS，保证并发场景下的一致性。总体流程如下图：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-02-23 14.50.19.excalidraw.png]]

还是刚刚10个线程的例子。显然那9个线程都无法通过这个操作将自己入队。但是我既然已经要去获得锁了，也失败了，就不能不入队。因此，后续的操作一定是一个『死循环』，直到入队成功为止。

这部分的逻辑位于`enq()`方法。代码如下：

```kotlin
private Node enq(final Node node) {
	for (;;) {
		Node t = tail;
		if (t == null) { // Must initialize
			if (compareAndSetHead(new Node()))
				tail = head;
		} else {
			node.prev = t;
			if (compareAndSetTail(t, node)) {
				t.next = node;
				return t;
			}
		}
	}
}
```

我们先不看if分支，只看else。else分支里做的事情和我们刚刚说的一模一样：

* 设置新节点node的前驱为现在的尾节点；
* 使用CAS去尝试将新的tail指向自己；
	* 如果成功了，那么让原来的尾节点的`next`指向自己并返回自己作为新的尾节点；
	* 如果失败了，那就是有人改了tail。重新尝试。

我们看到，这段操作被放到了一个无限循环中。也就是说，『不入队，不罢休』。

> [!question]- 为什么这段逻辑会放到无限循环中，而不是使用sleep \& wakeup的模式？
> 我的考量有两点：
> 
> 1. 因为链表的入队操作是一个非常快的过程；同时，即使并发量很高，因为获取**同一个锁**而入队并且掐架起来的概率比较低；
> 2. 如果当前线程有其它重要工作要执行（比如Android UI线程），那么sleep的后果非常严重。

- [ ] #TODO 为什么这段逻辑会放到无限循环中，而不是使用sleep & wakeup的模式？这个问题有必要补充一下？ ➕ 2024-02-23 ⏬ 

最后，if里面的那个逻辑是什么？回到我们刚刚addWaiter()的逻辑：

```java
if (pred != null) {
	... ...
}
```

只有当前尾节点不为空的时候才去试。那如果一开始这个链表就是空的呢？显然jdk也将这个逻辑放到了`enq()`中。其实`enq()`的注释就有提到：

```java
/**
 * Inserts node into queue, initializing if necessary. See picture above.
 * @param node the node to insert
 * @return node's predecessor
 */
private Node enq(final Node node)
```

初始化的逻辑如下：

```java
if (compareAndSetHead(new Node()))
	tail = head;
```

可以看到，头节点~~永远~~在初始化的时候是一个假的空Node，而我们主要关注的是tail。

下一个问题。线程节点入队了之后干嘛？既然我们是因为没获得成功锁而入队的。那么入队之后肯定要<label class="ob-comment" title="不断" style=""> 不断 <input type="checkbox"> <span style=""> 真的是“不断”吗？接着往下看。 </span></label>尝试在队列中获取锁，获得了锁之后要出队。

但是有一个问题，一个很关键的问题：如果**任何**一个线程进了队列之后都不断获取锁，谁获取了谁出队列，那么我要队列干嘛？AQS之所以要这么个队列，是为了维护『公平』。具体的思路如下：

1. 每一个获取锁失败的线程都必须进入队列的尾部；
2. “在运行过程中”，队列头部的线程是持有锁的线程；
3. 当**队头**线程释放了锁之后，会通知队列的老二去抢锁；
4. 队列的老二获得锁之后，才会变为队列的头节点；
5. <font color="red">只有队列的老二能被队头节点唤醒去抢锁。其它的节点只要发现自己不是老二，就会park；</font>
6. 队列遵循FIFO原则，即“只有队头元素能出队（释放锁），获取失败的锁都进入队尾”。

- [ ] #TODO Wait vs Park 🔺 ➕ 2024-02-23

通过以上的原则，这个双向链表才起到了它的作用：**只让老二抢锁**。那问题来了：只有老二抢锁，和谁抢？答案显而易见：和还没入队的线程抢。谁失败了谁去队尾。

> [!question]
> 说到这里，你可能发现了一个问题。反正我是发现了。之前在[[Study Log/java_kotlin_study/concurrency_art/3_5_lock_mm_semantics#3.5.2 锁内存语义的实现|3_5_lock_mm_semantics]]中我们就介绍过ReentrantLock中的公平锁和非公平锁。那你AQS既然维护的是『公平』，那么ReentrantLock中的公平和非公平又是啥？既然ReentrantLock依赖的AQS本身就是公平的FIFO队列，那么ReentrantLock的非公平从何而来？
> 
> 这个问题可以看一看这篇文章：[AQS的非公平锁与同步队列的FIFO冲突吗？_如果是非公平锁,是否还维持fifo队列-CSDN博客](https://blog.csdn.net/Mutou_ren/article/details/103883011)
> 
> 文章的主要内容是这样的。ReentrantLock的公平和非公平，与AQS所维护的『公平』是两个截然不同的概念：
> 
> * ReentrantLock中的公平指的是，所有还没入队的线程<u>只要发现有线程在FIFO队列中等待（老二及以后）</u>，就要乖乖去排队；而非公平指的是所有还没入队的线程要<u>和FIFO队列的老二去竞争锁</u>，谁失败了谁去排队，谁成功了谁是队头。因此我们可以发现，这里的公平指的是==时间顺序==，已经在FIFO队列中的线程肯定到达的时间比新来的线程要早，所以为了公平，新来的线程没有资格和老一辈儿竞争，**遵守了时间顺序**；而非公平锁就**打破了这个时间顺序**。
> * 而FIFO队列所维护的『公平』是，所有已经在队列中的线程，必须按照时间顺序排好队，只有老二能去尝试获得锁。既然是尝试，那也会有失败的风险。但是**时间顺序不能被AQS自己打破**，只能被『锁的实现方』打破（比如ReentrantLock的非公平锁）。
> 

- [ ] #TODO 在ReentrantLock的非公平锁中，如果一个新来的线程和老二抢锁，新的线程抢到了，会发生什么？原来的老二怎么办？ ➕ 2024-02-23 ⏫ 



---



```dataviewjs
const pages = dv.pages('"Study Log/java_kotlin_study/concurrency_art"')
let nextChapterHead = undefined
let res = undefined
const current = dv.current()
for (let page of pages) {
	if (page.chapter_root == true && page.order == Number(current.chapter) + 1) {
		console.log("found next head: " + page.name)
		nextChapterHead = page
		continue
	}
	if (page.chapter == undefined || page.chapter != current.chapter) {
		console.log("not current chapter: " + page.file.name)
		continue
	}
	if (page.order == Number(current.order) + 1) {
		res = page
	}
}
console.log("res: " + res)
console.log("next: " + nextChapterHead)
if (res == undefined) {
	res = nextChapterHead
}
let text = ""
if (res != undefined) {
	const path = res.file.path
	const title = res.title
	const decoLink = "[[" + path + "|" + title + "]]"
	text = "Next Article: " + decoLink
} else {
	text = "旅途的终点！"
}
dv.el("p", text, { attr: { align: "right" } })
```