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

```ad-warning
不要将锁的获取写在try里面。如果获取时发生了异常，锁会被无故释放。
```

- [ ] #TODO 举个例子？

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

```ad-note
这里要@一下之前说过的一段话：[[Study Log/java_kotlin_study/concurrency_art/3_5_lock_mm_semantics#^b71a4e|3_5_lock_mm_semantics]]。如果你继承了AQS，那么子类就必须定义一些protected的方法来改变这个state。这句话可能会引起一些歧义。上面的这三个方法其实就是protected的，它们也是用来修改同步状态（也就是那个volatile的int）的。那么，为啥注释里会这么说呢？

根据我的猜测，比如你在AQS的子类里想要定义一个方法，将这个同步状态改变：

~~~kotlin
fun setSomeState(factor1: Int, factor2: Int) {
	this.setState(factor1 shl 2 + factor1 / factor2)
}
~~~

这里我写的比较复杂。就是说，如果你这个状态是通过某些复杂的因素算出来的一个值。那么这个方法也是和那三个一样是要修改状态的。因此，AQS建议这些方法也定义成protected：

~~~kotlin
protected fun setSomeState(factor1: Int, factor2: Int) {
	this.setState(factor1 shl 2 + factor1 / factor2)
}
~~~
```

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

override fun lockInterruptibly() {
	sync.acquireInterruptibly(1)
}

override fun tryLock(time: Long, unit: TimeUnit): Boolean {
	return sync.tryAcquireNanos(1, unit.toNanos(time))
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

```ad-info
这里忘了，我们好像还没给unlock()的实现。这个不那么重要，随便实现一下就可以了：

~~~kotlin
override fun unlock() {
	sync.release(1)
}
~~~
```

- [ ] #TODO 这里录个音解释一下吧。文字修改太多了，主要把tryRelease补上。

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
- [>] 我们发现tryAcquire()是protected的，代表在sync之外是不让使用的。所以，如果我们自己在我们的Mutex里调用`sync.tryAcquire()`是获取不到的。我们的做法是封装了一层`sync.tryLock()`，<label class="ob-comment" title="然后让`tryLock()`去调用最终的tryAcquire()" style=""> 然后让`tryLock()`去调用最终的tryAcquire() <input type="checkbox"> <span style=""> 注意，这也是建立在tryLock()的行为恰好和tryAcquire()一致的条件下的。比如ReentrantLock的tryLock()和tryAcquire()就有一些区别，所以不能直接调用 </span></label>；而书上的做法是在自己重写Sync的时候直接将tryAcquire()改成public的。这种做法我本人不太赞成。
- [?] *<font color="red">为什么要有lockXXX和XXXAcquire两套接口？</font>*
- [>] 这是最重要的一个问题。明明我们实现了Lock接口，依赖了AQS中的能力，<label class="ob-comment" title="那么我直接在Lock里面去调用AQS的接口不好吗" style=""> 那么我直接在Lock里面去调用AQS的接口不好吗 <input type="checkbox"> <span style=""> 比如就是上个问题，我直接调用那个protected的tryAcquire()不香吗？ </span></label>？为啥还要再封装一层？这就谈到了AQS的设计模式了。我们接下来就要讨论这个问题。

到这里，我们来看看Lock和AQS是怎么合作，并由锁的使用者使用的：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-02-19 21.00.37.excalidraw.png]]

图中的箭头表示调用。可以发现，在我们实现的Mutex中，所有Lock的接口都没有调用我们重写的AQS的方法（比如tryAcquire()），而是调用了AQS内置的一些『模板方法』。而之所以你会问出刚刚最后的那个问题，就是因为AQS中并没有为tryLock()专门提供一个这样的模板方法。不提供的原因也很好理解，因为tryLock()并不需要获取失败之后的一系列操作，失败了就失败了。所以这个简单的逻辑就移交给开发者自己了。分析ReentrantLock源码也能发现，它的tryLock()的实现也完全是自己搞定的。

这也是我不赞成书上将Mutex中的AQS的tryAcquire()改成public的原因。因为这个方法本身就不应该暴露给Lock，Lock能调用的只应该是那些模板方法。



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