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

^mutextryacquire

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

- [x] #TODO 共享锁，不只有一个线程能获得。真的吗？==真的==。 🔺 ➕ 2024-02-23 ✅ 2024-02-26

#### 5.2.2.1 锁的获取 - acquire()

##### 5.2.2.1.1 获取失败后 - 添加新节点 - addWaiter()

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

##### 5.2.2.1.2 新节点入队失败后 - “不入队，不罢休” - enq()

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

> [!note]
> 大多数情况，`enq()`就是由`addWaiter()`调用的。

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

##### 5.2.2.1.3 入队成功之后 - 尝试获得锁 - accquireQueued()

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

^fb346a

- [ ] #TODO 在ReentrantLock的非公平锁中，如果一个新来的线程和老二抢锁，新的线程抢到了，会发生什么？原来的老二怎么办？ ➕ 2024-02-23 ⏫ 

#### 5.2.2.2 锁的释放 - release()

接下来介绍FIFO队列的老大释放锁的过程。在简单的例子中，应该从锁（Lock接口）的使用者调用unlock()开始。在我们刚刚实现的Mutex中，是这样的：

```kotlin
override fun unlock() {
	sync.release(1)
}
```

显然，从我们之前给出的[[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-02-19 21.00.37.excalidraw.png|AQS设计模式图]]就能看出，这个方法是模板方法，它最终会调用到AQS中，在本例中就是Mutex中的Sync里面实现的tryRelease()方法：

```kotlin
override fun tryRelease(release: Int): Boolean {
	if (state == 0) {
		throw IllegalMonitorStateException()
	}
	exclusiveOwnerThread = null
	state = 0
	return true
}
```

> [!attention]
> 需要注意的一点是，这里的`state = 0`是:dev_kotlin_original:中的语法糖。实际上调用的就是AQS那三个protected中的一个：`setState()`。

由于释放锁没人会和他抢（互斥锁只有一个线程能持有），所以释放的过程并不需要加锁。正因为state是volatile的，所以所有线程只有在state设置为0之后才能读到这个新的值。

仿照acquire()，我们来猜猜release()会做什么：

1. 调用tryRelease()来释放锁；
2. 如果释放成功，那么通知队列的老二去抢锁。

好像就没了！释放就是这么简单！

#### 5.2.2.3 总结

现在，我们来总结一下AQS在获得锁和释放锁的逻辑（仅exclusive）：

1. 锁的获取 - acquire()
	1. 尝试获取锁 - tryAcquire()
	2. 如果失败，将当前线程创建出新的节点并尝试入队 - addWaiter()
	3. 如果尝试入队失败，不断循环，直到成功为止 - enq()
	4. 每个入队成功的节点都遵循之前提到的『公平』原则 - acquireQueued()
2. 锁的释放 - release()
	1. 尝试释放锁 - tryRelease()
	2. 如果释放成功，通知队列老二抢锁 - unparkSuccessor()

> [!note]
> 这里的unparkSuccessor()内部的实现用到了我们[[Study Log/java_kotlin_study/concurrency_art/4_1_thread_basic#^6e38f5|提过一嘴]]的LockSupport，后面会介绍。

- [ ] #TODO :obs_up_arrow_with_tail:介绍了吗？➕ 2024-02-25 ⏫ 

在这个过程中，1.4里的『公平』原则内部包含了你可能听说的AQS的“自旋”流程。这个过程在代码中主要是acquireQueued()中的实现。主要的逻辑如下：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240225021140.png]]

只有前驱节点是头节点，并且尝试获取锁成功之后，才会变成新的队头；否则就会进入等待状态，等待被中断或者队头释放了锁。

#### 5.2.2.4 共享式获取

我记得os的时候介绍过一个读写者问题：[[Lecture Notes/Operating System/os#5.2 Readers and writers Problem|os]]。当一个文件被一个线程读的时候，其实其它线程是可以读的，但是不能写；但是如果文件被一个线程写的时候，那么其它线程啥都不能干。

- [ ] #TODO 试着实现[[#5.2.2.4 共享式获取]]里面说的文件锁。➕ 2024-02-26 ⏫ 

通过这个我们可以发现，一个文件的访问权限其实分成两种：

* 读权限
* 写权限

~~这就是两把锁~~。而一个线程持有读权限~~锁~~和写权限~~锁~~时，权力是不一样的。写权限就是我们之前说的exclusive模式，即只能有一个人持有；而读权限这种也允许其它人获取锁的方式就是**Shared**的。

> [!error] Deprecated
> 这里读权限和写权限并不是两把锁，是同一把。只是获取这把锁的方式不同。我们可以这么理解，当一个线程想要获得锁时，就等于向被锁住的东西发送了一个请求：
> 
> * Exclusive模式就等于在说：兄弟，这把锁我要了，你一旦给我了，那其它人可就都别想要了:angry:！
> * Shared模式就等于在说：兄弟，这把锁我想要，但是别人如果想要的话，我们俩都能进来:smiley:。

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240225022314.png]]

共享式获取也遵循AQS那一套模板设计，加到之前那张图里就是这样：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-02-25 02.33.03.excalidraw.png]]

需要注意，Lock接口并没有提供专门针对shared模式的方法，所以我们自己随便加上一个就可以。主要的逻辑是AQS里面这个模板设计。

- [ ] #TODO 这样的模板设计有什么好处？➕ 2024-02-25 🔼 

当一个线程请求共享式地访问锁的时候，会经历下面的流程（acquireShared()的实现）：

1. 调用tryAcquireShared()来尝试获取锁；
2. 如果获取成功，那么没啥好说；
3. 如果获取失败，和acquire()一样，<label class="ob-comment" title="要进入队列中并不断尝试获取" style=""> 要进入队列中并不断尝试获取 <input type="checkbox"> <span style=""> 这部分的实现在doAcquireShared()中。 </span></label>；
4. 进入队列的方式也是添加节点，入队，在队列里不断尝试获取锁。也会经历“自旋”的过程；
5. 自旋的时候，先看前驱节点是不是头，如果是的话才尝试获取。成功之后我（老二）变新头，如果失败，那就park，直到被中断或者其它人释放了锁。

显然，共享式的锁也需要释放。和独占式最主要的区别就是，由于共享式的锁可以被多个线程同时获取，所以释放的时候会出现竞争问题，不能被两个线程同时释放。所以，这里面通常加入了CAS操作。

- [ ] #TODO 这么看来，共享式锁不只有队头才能获取。AQS是怎么把这两个模式给融合起来的呢？➕ 2024-02-25 🔼 

#### 5.2.2.5 中断式获取

中断式的特点就是，如果在获取锁失败后阻塞的时候（在FIFO队列里面）被中断了，那么就会直接返回不获取了，而不是继续在那儿排着。

实现方式也是通过抛出InterruptedException。

在独占式和共享式的基础上都有：

* 独占式：acquireInterruptibly()
* 共享式：acquireSharedInterruptibly()

具体到代码上，非中断式的获取在被中断的时候只会<u>记录一下我被中断了</u>；而中断式获取在检查到被中断的时候会抛出InterruptedException。

> [!note]- 记录一下我被中断了
> 这可不是置中断位！看acquireQueued()的实现，里面只是一个临时变量interrupted，并不是线程的interrupted标志位。这个临时变量用作返回值，来告诉调用方：当前线程在等待的时候被中断了吗？

#### 5.2.2.6 超时获取

字面意思，也是获取。也在独占式和共享式上都有。如果过了规定的时间还没获得锁，那么直接返回：

* 独占式：tryAcquireNanos()
* 共享式：tryAcquireSharedNanos()

> [!note] 
> 可以发现，这两个是try，也就是那个AQS的模板设计结构图的右半边。AQS没专门给这种方式提供模板方法。所以你可以直接用它来实现Lock接口。比如上面这两个任意一个方法都能用来实现Lock接口的tryLock()方法。

超时获取是**建立在中断式获取**上的。也就是说，只要是超时获取，被中断的时候都会直接返回。

- [ ] #TODO 为什么超时一定是中断的？为啥这样设计？➕ 2024-02-25 🔼 

### 5.2.3 实战 - TwinsLock

我们来写一个自己的Lock回顾一下本章的内容。一个TwinsLock，同时允许两个线程获得。调用lock()获取锁，调用unlock()释放锁。

分析一下。既然允许两个线程同时获得，那么一定是共享式。所以，我们需要实现：

* tryAcquireShared()
* tryReleaseShared()

那么我们稍微回顾一下之前的模板设计，就知道我们应该在lock()里调用对应的acquireShared()，在unlock()里调用对应的releaseShared()。AQS会自动帮我们去实现内部的尝试、等待、中断等逻辑。

```kotlin
override fun lock() {
	sync.acquireShared(1)
}

override fun unlock() {
	sync.releaseShared(1)
}
```

需要注意的点是这里传入的1。通常，一个线程获得一把锁，相当于把资源数-1。而对于独占式的锁，通常资源只有1个。

而我们是TwinsLock，所以资源数应该是2。因此，我们可以做如下定义：AQS里面那个state表示资源数量。资源数量的合法值为2, 1, 0。当：

* `state == 2`：表示目前没有线程可以获得锁；
* `state == 1`：表示目前有一个线程获得了锁；
* `state == 0`：表示两个线程获得了锁，无法再被获取。

那么，我们联系一下之前实现Mutex中的AQS的tryAcquire()时的情况：tryAcquire()返回的是一个布尔。为true就是获取成功，false就是获取失败。但是现在的情况是虽然获取的结果还是只有成功和失败。

这个时候，你可能会萌生和我一样的想法：*<label class="ob-comment" title="用tryAcquire()难道不也能实现共享式访问吗" style=""> 用tryAcquire()难道不也能实现共享式访问吗 <input type="checkbox"> <span style=""> 然后lock()里面就不调acquireShared()了，直接调acquire()。 </span></label>*？比如我们可以这样实现：

```kotlin
override fun tryAcquire(acquired: Int): Boolean {
	val curr = state    // getState()
	val after = curr - acquired
	if (after >= 0 && compareAndSetState(curr, after)) {
		return true
	} else {
		return false
	}
}
```

传入的acquired是需要的资源数量，在我们这个例子中永远是1，即每一个线程一次获取只获取一个资源。state的初始值是2，当小于0的时候，不允许其它的线程再获取了。

上面的实现看起来既简单又正确。首先，得到当前的资源状态，然后将资源减去。如果结果还是>=0，就表示『我理论上是能获取成功的』，因此，只要CAS成功，我就可以返回true了；而如果这两者的任意一个不成立，那么都是尝试获取失败，应该去排队。

然而，上面的做法是**完全错误**的！并且，错的不是一点半点。下面我们来逐个问题去分析。

首先，我们要知道为什么AQS要设计成模板的模式，并且严格区分开了acquire()和acquireShared()这两个方法。用:chicken::chicken:想都知道，这两个模式的内部实现肯定是不同的。无论是处理中断的时候，还是队列中的老大释放锁之后的通知行为，这两种模式的节点的处理方式肯定是不一样的。而在模板的设计模式中，**acquire()永远只会调用tryAcquire()；acquireShared()永远只会调用tryAcquireShared()**。因此，如果我们用tryAcquire()实现共享式的访问，那么就违背了AQS的根本意愿，并且我们这个线程在**获取失败之后会被AQS按照独占式的节点去对待**，后面的行为就全乱了。因此，我们就是要实现tryAcquireShared()，并且在lock()中调用acquireShared()。

第二点，我们哪怕实现的就是tryAcquireShared()，这里面的实现就是对的吗？我试了试下面的版本：

```kotlin
override fun tryAcquireShared(acquired: Int): Int {
	val curr = state
	val after = curr - acquired
	if (!compareAndSetState(curr, after)) {
		return -1   // 如果失败了，直接返回-1表示获取锁失败
	}
	return after
}
```

> [!attention]
> tryAcquireShared()的返回值是int，>=0表示成功，<0表示是失败。如果是>=0的话，这个返回值还表示获取之后剩余的资源数量。

这个版本是会产生死锁的！为啥？其实，在之前的笔记中，我也有提到过，但是我当时说的也有不严谨的地方，就是：『CAS』和『循环CAS』。

显然，单次CAS是会失败的。就像加锁的代码一样，直到我获得了锁才能继续下去。那么，我们是否问过这样的问题：*CAS等于锁吗*？

**答案当然是否定的**！我们就拿synchronized来举例子。如果进入synchronized时失败了，会一直阻塞到能进去为止；但是CAS只要失败了就返回了！所以，真正的情况应该是，如果我们想要实现类似锁的功能，应该用的是**循环CAS**。也就是一次CAS失败了，我还不能不管了，要一直尝试下去，直到CAS成功执行为止。可以看看这篇文章，虽然我感觉没啥水平：[【锁思想】自旋 or CAS 它俩真的一样吗？一文搞懂 - 掘金 (juejin.cn)](https://juejin.cn/post/7252889628376842297)

有了这个概念，我们再回头看这个问题。我注释里说的那句话对吗？*如果CAS失败，难道真的表示【共享式的锁】的【尝试获取】失败了吗*？

我们再来回顾一下共享式的锁什么时候获取失败：。。。好吧，其实谈不上回顾，因为我之前好像没提过。其实，这个锁的获取成功还是失败，是由开发者自己定义的。比如我们的TwinsLock，获取失败的条件应该是：

<font color="red">当一个线程修改完状态之后，发现状态不是0, 1, 2中的一个时，表示当前线程获取锁失败。</font>

这段话很好理解，就是我们一开始的分析。那么，问题就在于此：**必须要修改完状态**。那么CAS失败等价于修改完状态且发现它不是0 1 2吗？显然不是。这是两个截然不同的概念，==CAS失败，仅仅代表有人在跟我抢这个状态的修改，而不是我修改完之后状态就不是0 1 2了==。

下面我们举一个例子。假设<u>有且只有</u>ABC三个线程几乎同时去修改这个值。那么如果我们的TwinsLock正确工作的话，肯定是他们仨中的两个能获取成功，另一个失败。

> [!hint]- 有且只有
> 不是因为这个情况特殊，只是因为三个线程足以复现问题。

但是，在我们当前的设计下，是啥样的？假设A先成功用CAS修改了值，B和C紧接着同时也去做CAS。那么这个时候B和C都会发现state已经变化，然后，，，就都失败了？！？！

对吧！现在这个结果，和我们理论上的结果是不一样的。这就完美地证明了：**CAS失败并不代表获取TwinsLock失败**。

既然CAS失败不代表，那啥代表呢？聪明的你应该猜到了：为啥我之前介绍循环CAS和CAS的区别？我们给CAS加上一个循环，不就是了！但是，在继续写之前，我们需要明确一个问题：*这个循环应该加在哪儿*？

我们可以用goto来模拟一下：

```kotlin
override fun tryAcquireShared(acquired: Int): Int {
	val curr = state
	val after = curr - acquired
	val success = compareAndSetState(curr, after)
	if (success) {
		return after
	} else {
		goto ???
	}
}
```

~~正确的实现就应该是这样的~~：**只有CAS成功了**，新的值after才能表示是否成功获得TwinsLock。而如果失败了，就应该从前面的某个时刻重试。那么，从哪里？我们想想：既然CAS失败了，就代表**肯定有其它人在这个空挡修改了state**。那么我下次如果还用原来的state的话，那就没有时效性了。

因此，正确的做法就是从整个方法的开头重来，重新读一遍新的state，重新减去，重新CAS。所以，简化成这样：

```kotlin
override fun tryAcquireShared(acquired: Int): Int {
	while (true) {
		val curr = state
		val after = curr - acquired
		val success = compareAndSetState(curr, after)
		if (success) {
			return after
		}
	}
}
```

看起来总算正确了吧！只有CAS成功了，我们返回的after才代表着最后获取成功与否；否则就要不断尝试，直到CAS成功为止。

我也是这么想的。但是，又死锁了。。。这个问题困扰了我好久。后来我才发现，我是真的蠢。之前在os里面讲信号量的时候，就提到过这里：[[Lecture Notes/Operating System/os#3.3 How to avoid race conditions?|os]]。当时我们讲的是信号量Sempahore的例子。如果信号量已经<0，那么我们就不能再继续减下去了。因为从-1开始（包括-1），后面的值都已经是非法的了。由于在释放锁的时候，操作就是将state+1，所以如果你有一堆线程疯狂地去down这个state，并且还只有两个最终获得锁，那么这两个线程即使释放了锁，加的state也不够恢复成正数。结果就是所有的线程都休眠了。

所以，正确的方法应该是：

```kotlin
val curr = state
val after = curr - acquired
```

在这一步之后，after表示的是『理论上我获得了锁之后的state状态』。如果这个值已经<0了，那我**连CAS操作都不能做**！因为只要做了CAS就修改了state，就已经违反了这个TwinsLock的意愿了。

所以，下面的实现：

```kotlin
override fun tryAcquireShared(acquired: Int): Int {  
    while (true) {  
        val curr = state  
        val after = curr - acquired  
        val success = compareAndSetState(curr, after)  
        if (after < 0 || success) {  
            return after  
        }  
    }  
}
```

**是错误的**。因为`after < 0`的比较在CAS之后，所以你虽然“意识”到这个CAS不该做，但是你已经做了。正确的做法是在CAS之前就判断after：

```kotlin
override fun tryAcquireShared(acquired: Int): Int {
	while (true) {
		val curr = state
		val after = curr - acquired
		if (after < 0) {
			return after
		}
		val success = compareAndSetState(curr, after)
		if (success) {
			return after
		}
	}
}
```

或者像书上一样简化：

```kotlin
override fun tryAcquireShared(acquired: Int): Int {
	while (true) {
		val curr = state
		val after = curr - acquired
		if (after < 0 || compareAndSetState(curr, after)) {
			return after
		}
	}
}
```

> [!note]- 小问题
> > [!error] Deprecated
> > ~~这里我突然发现，和[[Study Log/java_kotlin_study/java_kotlin_study_diary/2024-02-19-java-kotlin-study#^b08f74|互斥锁的获取过程]]正好是反的。在互斥锁的获取的时候，通常都是先只管抢锁，抢到了发现不该抢我再退出来；而操作Semaphore这种类似的结构的时候，就要先试探，只要我发现我不该抢，就完全不能做操作。我目前怀疑这就是『互斥』和『共享』的一个很大的区别：xxxx~~
> >
> >~~操操操，我上面感觉也像在放屁。我们就对比一下那篇日记里的tryLock()版本和上面的tryAcquireShared()。日记里的那个是先tryLock()，如果失败直接重来，如果成功进入临界区；而上面的共享获取，**整个方法都是临界区**。因为第一句`curr = state`其实已经是在读共享变量state了。所以，在我们判断`after < 0`的时候，就已经要退出临界区重来了。~~
> >
> >~~那这样你可能又会问，日记里不是说，==我在临界区里面判断我是不是该进临界区==这样的做法是错误的吗？其实这句话说的不准确，应该是：**如果我在临界区里发现我不应该进入临界区，那么在这个时间点上到进入临界区，下到立刻，都不能有**。日记里面那个错误版本的实现是，当`got == false`的时候，~~
> 
> 行吧，这里重新和Mutex的问题对比。看的是这一段：[[Study Log/java_kotlin_study/java_kotlin_study_diary/2024-02-19-java-kotlin-study#^39f670|2024-02-19-java-kotlin-study]]
> 
> 这个TwinsLock相信看到这里也能看出来了，就是一个资源为2的信号量。信号量和锁在概念上就是不同的，信号量的操作是down和up，而互斥锁只有被获得和没被获得两种状态。所以，compareAndSetState这个方法虽然也是类似于获取锁的状态，但是我们不能用对待锁的方式去对待它。
> 
> 另外，我感觉，资源数为1的共享就是互斥。

^5a197f

- [ ] #TODO 难道互斥不等于资源数为1的共享吗？同时我对上面的Note正确与否表示怀疑。➕ 2024-02-26 🔺 

这个时候你可能也会问这样的问题：*为什么实现Mutex的时候tryAcquire()的CAS就没用循环包起来，而tryAcquireShared()就需要*？我们可以看看jdk的源码，发现Semaphore这样的同步组件，在实现tryAcquireShared()的时候也是用一个无限循环包起来。其实，包不包起来，或者任何其它的行为，都是为了“锁的成功获取”服务的。我们这里包起来只是为了，当真正将这个值减掉之后，它的结果对我们判断锁状态才有意义。如果是其它锁的话，也可以不包。

最后是释放锁。也很简单，就是+1。但是，这个时候会有其它的线程和它抢着，无论是想-1还是+1都会影响到。所以这里的CAS也会失败，所以也需要套上循环；另外，这里就不存在类似那个<0的判断了。因为==获得了锁的线程个数==是确定的，这就导致我们不管怎么加这个state，都不可能让它超过2。

```kotlin
// 持有锁的线程是不可能释放失败的。所以最终只有返回true
override fun tryReleaseShared(released: Int): Boolean {
	while (true) {
		val curr = state
		val after = curr + released
		if (compareAndSetState(curr, after)) {
			return true
		}
	}
}
```

这样就结束了。我们写个例子来验证一下。

```kotlin
class Worker(val lock: TwinsLock) : Thread() {
	override fun run() {
		while (true) {
			lock.lock()
			try {
				println(currentThread().name)
				SleepUtils.second(1)
			} finally {
				lock.unlock()
			}
		}
	}
}
```

一个线程，抢到锁之后休眠一秒钟之后输出自己名字。这样的情况下，如果10个线程同时启动，那么首先只有2个线程能抢到并输出。这俩线程释放锁之后又会重新来抢。所以，结果应该是每1秒输出两个线程：

```kotlin
val lock = TwinsLock()
repeat(10) {
	val w = Worker(lock)
	w.isDaemon = true
	w.start()
}
SleepUtils.second(100)
```

![[Study Log/java_kotlin_study/concurrency_art/resources/Peek 2024-02-26 20-43.gif|300]]

## 5.3 重入锁

在[[#5.2.2.1.3 入队成功之后 - 尝试获得锁 - accquireQueued()]]中我们正式介绍了什么情况锁才是公平的。简单来说：

<font color="red">在绝对时间上，先对锁进行获取的请求一定先被满足，这就是公平；只要不满足，就是不公平。</font>

ReentrantLock自己本身就在『可重入』的基础上又支持公平锁和非公平锁。

### 5.3.1 可重入

我们首先来研究可重入。字面意思，就是如果这个锁已经被自己获得了，还能再被自己获得（有啥用？）。我们之前实现的Mutex是可重入的吗？试一试，下面的代码：

```kotlin
val mutex = Mutex()
mutex.lock()
mutex.lock()
```

执行完之后，卡住了。我们用jstack看一下就发现，它确实在『重入』的时候阻塞住了：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240226204822.png]]

也就是说，目前这个Mutex是不支持重入的。原因也很简单，我们回顾一下lock()：

1. 调用的就是默认的acquire()方法；
2. acquire()首先会调用tryAcquire()。在我们这个例子中肯定会成功，所以直接返回；
3. 之后又调用了acquire() -> tryAcquire()。由于已经被获得了，所以tryAcquire()返回false，导致主线程被送进队列。

不难发现，问题出在tryAcquire()上。我们应该在这里面加入『自己和获得锁线程的比较』。如果发现获得锁的线程就是自己，那么应该返回true。

但是还有一个问题：如果线程连续两次获取同一个锁，那算一次还是两次呢？我们认为，一个线程不可能平白无故地获取两遍一样的锁，那就肯定是有它的理由。所以，如果一个线程获取了两次锁，就得解锁两次之后其它线程才能获取（前提是互斥锁）。

> [!summary] 重入的实现需要注意两个问题：
> * **线程再次获取锁**：锁需要去识别获取锁的线程是否为当前占据锁的线程，如果是，则再次成功获取。
> * **锁的最终释放**：线程重复 n 次获取了锁，随后在第 n 次释放该锁后，其他线程能够获取到该锁。锁的最终释放要求锁对于获取进行计数自增，计数表示当前锁被重复获取的次数，而锁被释放时，计数自减，当计数等于 0 时表示锁已经成功释放。

下面，我们来分析一下代码来看看可重入是怎么实现的。

- [ ] #TODO 这里也是jdk8，之后升级一下。➕ 2024-02-27 🔽 

首先，我们从tryLock()入手。毕竟无论是公平还是非公平，都是**可能**要调用这个方法才能获得锁：

```kotlin
public boolean tryLock() {
	return sync.nonfairTryAcquire(1);
}
```

我们发现，是nonfair的。为啥公平的锁在尝试获得的时候也会调用nonFair的呢？我们看看注释：

> Even when this lock has been set to use a fair ordering policy, a call to `tryLock()` *will* immediately acquire the lock if it is available, whether or not other threads are currently waiting for the lock. This barging behavior can be useful in certain circumstances, <u>even though it breaks fairness</u>. If you want to honor the fairness setting for this lock, then use `tryLock(0, TimeUnit.SECONDS)` which is almost equivalent (it also detects interruption).

也就是说，公平锁在尝试获得锁的时候也是不公平的。如果真想公平，那就用两个参数的版本。

- [ ] #TODO 为啥允许公平锁打破公平？➕ 2024-02-27 ⏫ 

现在看看nonfairTryAcquire()的实现：

```java
final boolean nonfairTryAcquire(int acquires) {
	final Thread current = Thread.currentThread();
	int c = getState();
	if (c == 0) {
		if (compareAndSetState(0, acquires)) {
			setExclusiveOwnerThread(current);
			return true;
		}
	}
	else if (current == getExclusiveOwnerThread()) {
		int nextc = c + acquires;
		if (nextc < 0) // overflow
			throw new Error("Maximum lock count exceeded");
		setState(nextc);
		return true;
	}
	return false;
}
```

可以发现，就是在原来[[#^mutextryacquire|Mutex版本]]的基础上增加了当前线程的判断（else分支）。这样当一个线程重复获得同一个锁的时候，就会走到这里，并增加锁的计数（用state表示）。另一点是，由于走到else分支的时候，其它的线程不可能获得锁，所以这里使用的是`setState()`而不是`compareAndSetState()`。

既然如此，当释放锁的时候肯定也不是简单的赋值，而是做减法：

```java
protected final boolean tryRelease(int releases) {
	int c = getState() - releases;
	if (Thread.currentThread() != getExclusiveOwnerThread())
		throw new IllegalMonitorStateException();
	boolean free = false;
	if (c == 0) {
		free = true;
		setExclusiveOwnerThread(null);
	}
	setState(c);
	return free;
}
```

首先，这个方法定义在FairSync和NonfairSync的公共父类Sync中，并且是final。代表公平锁和非公平锁的释放操作都 走的是这里。

剩下的，就是将当前的state减去传进来的参数releases。最后的结果如果是0，那么就释放成功了。如果不是，那么就还是我的锁。这里因为不可能有其它线程来抢，所以也不需要CAS。

### 5.3.2 公平 & 非公平

在继续之前，我觉得有必要对ReentrantLock()的结构来一张图。不然绕起来非常乱：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-02-27 14.44.54.excalidraw.svg]]

通过这张图我们发现，就像我们之前说的那样，tryLock()只会走非公平的实现nonfairTryAcquire()。**想要调用到公平锁的tryAcquire()**，只能用lock()。而[[#^fb346a|之前]]我们说过，公平锁在发现没有竞争的时候要进去排队。所以tryLock()调用的就是非公平的实现了。理论上，如果是公平锁的tryLock()，应该是只要发现有人在排队，或者CAS失败就返回false。但是不知道为什么jdk8没提供这样的实现，而是打破了这个规则，转而让用另一个版本的tryLock()来做这件事。

- [ ] #TODO 看看jdk17又没有修改这段逻辑 ➕ 2024-02-27 ⏫ 

现在来看看具体是咋实现的，很简单：

```java
protected final boolean tryAcquire(int acquires) {
	final Thread current = Thread.currentThread();
	int c = getState();
	if (c == 0) {
		if (!hasQueuedPredecessors() &&
			compareAndSetState(0, acquires)) {
			setExclusiveOwnerThread(current);
			return true;
		}
	}
	else if (current == getExclusiveOwnerThread()) {
		int nextc = c + acquires;
		if (nextc < 0)
			throw new Error("Maximum lock count exceeded");
		setState(nextc);
		return true;
	}
	return false;
}
```

我们发现，这里的else分支和非公平是一样的。原因是无论是公平还是非公平，在一个线程已经获得了锁的状态下，其它线程都是没资格抢的，也就不存在公平非公平的问题了。

而在if分支中，如果这个锁还没被任何一个线程获得，那么就是在非公平的判断条件基础上再加了一个`!hasQueuedPredecessors()`。也就是说，如果我前面还有人排着，那我也不能排队，返回false。

由于只有lock()会调用到这里，返回false的结果就是我要去FIFO队列中排着。

我们来写一个例子来验证一下。让一个线程先获取锁，然后打印一下自己，也就是获取锁的线程；然后再看看当前队列里有谁在排着：

```kotlin
private fun lockAndLook() {
	lock.lock()
	try {
		println("locked by: ${currentThread().name}, wait queue: ${lock.queuedThreads.map { it.name }}")
	} finally {
		lock.unlock()
	}
}
```

然而，getQueuedThreads()在ReentrantLock中是protected，所以我们要自己重写一个，把它public出来：

```kotlin
class ReentrantLock2(fair: Boolean) : ReentrantLock(fair) {
	public override fun getQueuedThreads(): MutableCollection<Thread> {
		return super.getQueuedThreads().reversed().toMutableList()
	}
}
```



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