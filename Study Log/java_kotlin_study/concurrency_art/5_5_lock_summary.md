---
title: 5.5 锁的总结 & LockSupport
chapter: "5"
order: "5"
---

## 5.5 锁的总结

本来书上讲的是LockSupport，而且篇幅很短。我的想法是在这里做一个和锁有关的总结。但是在这之前还是把这一部分给补上。

LockSupport提供了另一种阻塞线程+唤醒线程的能力：park和unpark。

在此之前，我们首先来看原始的Object的wait & notify方法。我们知道，在Java的早期版本，没有concurrent包，更没有LockSupport。所有的并发都依赖于synchronized，也就是OS中讲过的『管程』，英文叫monitor，在本书中也翻译成监视器锁。

然后，我们可以去看一下Object里wait和notify的注释。我大概贴一下：

> [!info]- wait
> Causes the current thread to wait until it is awakened, typically by being *notified* or *interrupted*, or until a certain amount of real time has elapsed.
> 
> The current thread <u>must own this object's monitor lock</u>. See the `notify` method for a description of the ways in which a thread can become the owner of a monitor lock.

> [!info]- notify
> Wakes up a single thread that is <u>waiting on this object's monitor</u>. If any threads are waiting on this object, one of them is chosen to be awakened. The choice is arbitrary and occurs at the discretion of the implementation. A thread waits on an object's monitor by calling one of the `wait` methods.
> 
> This method should only be called by a thread that is the <u>owner of this object's monitor</u>. A thread becomes the owner of the object's monitor in one of three ways:
> 
> * By executing a **synchronized** instance method of that object.
> * By executing the body of a **synchronized** statement that synchronizes on the object.
> * For objects of type Class, by executing a **synchronized** static method of that class.

看，所有的一切都和synchronized有关。wait和notify都需要monitor的持有者调用，也就是我们经常写的synchronized代码段中。那么，这种结构其实会有这样的问题：比如一个线程因为不合时宜，需要等待一下才能继续执行代码（通常就是临界区中的代码）。但是，按照wait和notify的思路，代码写出来肯定是这样的：

```java
synchronized(lock) {
	while (/* I can't go any further!!! */) {
		lock.wait();
	}
	// do Critical Region things.
}
```

也就是说，当需要判断我应不应该wait的时候，**已经进入synchronized了**。但是当发现我需要wait的时候，又立刻会释放这个锁。等到被notify之后，又要尝试重新获取这个锁。等获得了之后，才会从wait()方法返回并继续。在上面的例子中，返回之后又会判断我是否需要wait，如果失败了还是会继续wait。。。

不难看出，好像里面有些操作是比较低效的。其中大头就是synchronized的底层，monitor本身。而Java后续推出的一系列并发策略都是基于volatile和CAS的。这些操作的底层实现交由Unsafe来管理，而将这些能力封装起来，就能形成一些很轻量的锁。其中最典型的就是我们本章讨论的AQS。

而如果不使用synchronized，那显然也不能使用wait \& notify了。那么，我们使用什么呢？emm，应该是，concurrent包的发明者应该使用什么呢？答案就是LockSupport。LockSupport中的等待和唤醒机制也是交给Unsafe来管理，不对上层暴露。而其中的park和unpark就是最核心的功能。这里我也简单贴几个：

> [!info]- LockSupport类
> This class associates, with each thread that uses it, a **permit** (in the sense of the `Semaphore` class). A call to park will return immediately if the permit is available, consuming it in the process; otherwise it may block. A call to unpark makes the permit available, if it was not already available. (Unlike with Semaphores though, <u>permits do not accumulate. There is at most one</u>.) ==Reliable usage requires the use of volatile (or atomic) variables to control when to park or unpark==. Orderings of calls to these methods are maintained with respect to volatile variable accesses, but not necessarily non-volatile variable accesses.

> [!info]- park
> This method does **not** report which of these caused the method to return. <u>Callers should re-check the conditions which caused the thread to park in the first place</u>. Callers may also determine, for example, the interrupt status of the thread upon return.

> [!info]- unpark
> Makes available the permit for the given thread, if it was not already available. If the thread was blocked on park then it will unblock. <u>Otherwise, its next call to park is guaranteed not to block</u>. This operation is not guaranteed to have any effect at all if the given thread has not been started.

首先，LockSupport内部使用了一个permit来进行多线程访问限制。permit类似信号量，但是是一个资源数量最多就是1的信号量。

~~所有的parkXXX方法，都必须传入一个blocker，这个就类似于synchronized里传入的那个锁的对象。每个线程在park的时候，都要指定是依赖哪个blocker。换句话说，**这个线程在park之后会立刻返回还是休眠，取决于这个blocker此时的permit数量**。~~ ^74ac31

当park之后，调用者需要自己检查一下是什么原因导致了park返回。比如在[[Study Log/java_kotlin_study/concurrency_art/5_2_aqs#5.2.2.1.3 入队成功之后 - 尝试获得锁 - accquireQueued()|5_2_aqs]]中我们就讨论过，AQS的队列中，只要不是老二，或者老二抢锁失败，都会park。这里具体的策略在方法在parkAndCheckInterrupt()中：

```java
/**
 * Convenience method to park and then check if interrupted
 *
 * @return {@code true} if interrupted
 */
private final boolean parkAndCheckInterrupt() {
	LockSupport.park(this);
	return Thread.interrupted();
}
```

看，通常情况下，那些应该park的线程就会在`LockSupport.park(this)`这句阻塞住。当不知道因为什么原因返回时，调用者需要手动检查。这里AQS关心的是在这个过程中是否被中断，所以返回了`Thread.interrupted()`。

调用了unpark，会让传入的线程解除休眠，也就是让permit资源增加。不过最多也就是1而已。如果这个线程本身就没因为park而阻塞，那么你给它调用了unpark，下次它在park的时候就会立刻返回（注释里是这么说的，但是真实情况不是应该取决于permit的数量吗？比如[这个问题](https://stackoverflow.com/questions/72636299/when-locksupport-unpark-occur-before-locksupport-park-it-would-block-in-th) 。所以还是要分析一下代码才清楚）。

最后，我想说的最关键的高亮部分：**对于LockSupport最合理的使用，就是用volatile或者atomic变量（本质是CAS操作）来确定什么时候park，什么时候unpark**。这两个正是我刚才说的，Java的并发新引入的volatile和CAS。

还是用上面AQS队列的park的例子。那个parkAndCheckInterrupt()方法调用的位置是这样的：

```java
/* 上面是非老二 || 老二抢锁失败的判断，acquireQueued()方法 */
if (shouldParkAfterFailedAcquire(p, node) &&
                    parkAndCheckInterrupt())
                    interrupted = true;
```

它是先执行shouldParkAfterFailedAcquire()，然后才执行parkAndCheckInterrupt()。意思就是说，只有前面这个方法返回true，才会去park。那么，你猜猜这里面是啥？没错！就是上面高亮中的建议：用volaitle和CAS操作控制。

方法内部就不具体展开了，但是我们能看到，里面的Node的waitStatus就是volatile的，最后也用了CAS去执行了一些操作。

- [ ] #TODO 分析一下hotspot源码，看看permit在Unsafe里是怎么管理的。另外，我上面的分析也都是猜的，不一定都对。我现在感觉，应该是个初始值为0的信号量。线程park之后变为负数，所以休眠；如果为0的时候就unpark，那么就需要park两次才休眠。这和上面的描述正好吻合。 ➕ 2024-03-13 🔼 
- [ ] #TODO 上面waitStatus的这部分逻辑，有时间分析一下。➕ 2024-03-14 🔼 
- [ ] #TODO blocker不是[[#^74ac31|这个]]作用，到底是什么？➕ 2024-03-14 ⏫ 

总结一下，其实Java的并发就是分成两个派系：synchronized和concurrent包。前者就和Object里那几个方法相关，后者就是依赖于volatile和CAS操作。而LockSupport也是作为concurrent包里的一个基础组件，为AQS和Lock接口等上层组件服务。这些组件不断堆积，最终变成调用者可以安全使用的锁。

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