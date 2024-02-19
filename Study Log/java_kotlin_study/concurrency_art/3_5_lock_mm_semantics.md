---
title: 3.5 锁的内存语义
chapter: "3"
order: "8"
---

## 3.5 锁的内存语义

### 3.5.1 锁的释放和锁的获取

锁这块，其实不用多说。从语义上讲，**他和volatile是一模一样的**！这可能会让你感到惊讶：明明锁能做到volatile做不到的事情，它俩的内存语义还一样？然而，事实就是如此。

```java
class MonitorExample {
	int a = 0;
	
	public synchronized void writer() {  // 1
		a++;                             // 2
	}                                    // 3
	
	public synchronized void reader() {  // 4
		int i = a;                       // 5
		……
	}                                    // 6
}
```

还是假设先执行writer，然后再执行reader。这样我们就能保证2 happens-before 5。这个很好理解。但是，书上用了非常多的篇幅来推导出这个过程。为啥呢？主要的点就在于，从这干干巴巴的代码里，**我们看不出来锁的获取和锁的释放**的过程。

在上面的代码中，操作1和操作4就是锁的获取；而操作3和操作6就是锁的释放。而锁能保证，对于一个锁的释放，这里面所作的所有修改都会对下一个线程可见。而这里的方式和volatile是一模一样的：**刷新到主存中，下一个线程让本地内存无效，从主存中读**。

> 这里还是认为，writer先于reader执行。

现在，如果A释放了锁，那么过程就是这样的：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231130000607.png]]

这和[[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2023-11-19 17.12.19.excalidraw.png|volatile的那个图]]一模一样不是吗？那么我们需要思考一下：凭啥他能一样？之前我们说，这个图实际上是两个syncronized的版本，但是在假设writer()先于reader()执行时，这个图对于volatile也是对的。

> [!stickies] 
> 这里好好想想，“大大滴写”指得到底是什么？

volatile只是对读和写进行了原子操作。而这里我们虽然用了锁，但锁里的代码**从外部看**，也只是读和写。对于writer()方法，我们不关心它的实现，只知道它写了a，但是因为用锁修饰了，所以是一个**大大滴写**。而volatile只能原子化普通的写，不能原子化这个**大大滴写**。所以，**当volatile只操作一个变量的读写时，锁只操作一个变量的读写时，它们的效果是等价的，否则，锁>volatile**。比如在本例中，`a++`属于大大滴写，因为涉及临时变量，所以锁能做到，而volatile做不到，但是在volatile也能做到的情况下，它们俩是等价的。

现在可以直接总结锁的内存语义了，其实和volatile一模一样。当锁释放的时候，代表这个线程说：“==我搞定了！共享变量你们用吧！==”这就像在对volatile写的时候，写完了，也可以告诉其它线程“==我写完了，你们读吧==！”一样。所以：

```ad-def
title: 锁的内存语义

* 线程 A 释放一个锁，实质上是线程 A 向接下来将要获取这个锁的某个线程发出了（线程 A 对共享变量所做修改的）消息。
* 线程 B 获取一个锁，实质上是线程 B 接收了之前某个线程发出的（在释放这个锁之前对共享变量所做修改的）消息。
* 线程 A 释放锁，随后线程 B 获取这个锁，这个过程实质上是线程 A 通过主内存向线程 B 发送消息。
```

### 3.5.2 锁内存语义的实现

好吧，我觉得有必要先明确一个事情，就是：*我们现在说的锁，是不是syncronized*？

答案是，syncronized确实<label class="ob-comment" title="和锁有关系" style=""> 和锁有关系 <input type="checkbox"> <span style=""> 为什么要说和锁有关系？因为syncronized本身不是锁，而是syncronized在使用锁。在2.2我们介绍过，syncronized使用的真正的锁其实就是Object，或者说是存在Object对象头里面的东西。 </span></label>，但是我们这里所说的锁，并不局限于syncronized。在3.5.1中我们通过锁的释放和获取的过程推出来了锁的内存语义。syncronized是可以实现这样的语义的。然而，syncronized实现的方式是通过monitor，也就是监视器锁（管程），通过加monitorenter和monitorexit指令来实现这样的语义；而我们现在所说的锁，比如ReentrantLock，是在**纯**Java层面的锁，而不是在字节码层面的锁。它没有手段去在字节码中增加什么东西来实现并发控制。所以，我们现在考虑的是==怎么用java提供给我们的手段去实现锁的内存语义==，从而让我们写的玩意儿能被称为一个锁。

我们借助ReentrantLock（可重入锁）来看一看锁内存语义有哪些实现方式。

```kotlin
class ReentrantLockExample {  
    var a = 0  
    val lock = ReentrantLock(true)  
  
    fun writer() {  
        lock.lock()  
        try {  
            a++  
        } finally {  
            lock.unlock()  
        }  
    }  
  
    fun reader() {  
        lock.lock()  
        try {  
            val i = a  
        } finally {  
            lock.unlock()  
        }  
    }  
}
```

这里面ReentrantLock的构造传入true表示这是一个公平的锁。什么是公平，什么是非公平呢？简单来讲。如果三个线程同时去抢一把锁。只有一个人能抢到对吧。假设它是A，那么：

* 公平锁就是剩下的两个线程以及后来的线程在A释放锁后只能**按照抢锁的顺序**排好队，一个个去获得锁；
* 非公平锁就是剩下的两个线程以及后来的线程在A释放锁后还是有可能去**再抢一次**，谁牛逼谁来。

因此，非公平锁最大的一个特点就是，任何线程都可能『插队』。这样就导致某些线程可能因为运气不好被饿死。<u>但是这样可以提高吞吐率</u>。 

- [?] #TODO why 提高吞吐率?

那ReentrantLock是咋实现锁的呢？我们稍微看看ReentrantLock的加锁和解锁过程。

首先是公平锁。看看加锁：

```java
final boolean initialTryLock() {  
    Thread current = Thread.currentThread();  
    int c = getState();  
    ... ...
}
```

下面的不用看了，我们后面会详细说。我们现在不是为了学习ReentrantLock的实现，而是看它怎么实现锁的内存语义的。可以看到，它先读了一个state。而这个state，就是一个**volatile**变量。

再看看解锁：

```java
protected final boolean tryRelease(int releases) {  
	... ... 
    setState(c);  
    return free;  
}
```

它在最后也写了这个**volatile**变量。根据我[[Study Log/java_kotlin_study/concurrency_art/3_4_volatile_mm_semantics#^d00fb6|3_4_volatile_mm_semantics]]补充的例子可以知道，在一个方法的最后对volatile写，然后在另一个方法的开头对这个volatile读，代表啥？不就是可见吗！也就是，在释放锁的时候，会咔咔一通修改那些公共变量，像队列啊，线程的状态啊等等。然后最后给你来个volatile写。这就意味着，**之后**这个线程读到的，一定是**之前**的这个线程写过的结果。

你可能会问了：欸？我这不是锁吗？你volatile只能保证写后读的正确，那这个写之前，和这个读之后的同步你又怎么保证？你volatile写之前的指令确实不能逃逸到volatile后面，但是其它的代码完全可以插到这个volatile写之前啊！那不会对这个造成影响吗？

我只能说，别急。现在我们只是看到了ReentrantLock的一小小部分，使用了volatile的内存语义。这个问题ReentrantLock，还有concurrent包里的各种Lock肯定都是能解决的。当然不可能只是一个volatile这么简单。不然还要你concurrent包干鸡毛？直接用volatile不就行了！

- [ ] #TODO 这里我说的，之后要证明一下是正确的。

---

然后是非公平锁的实现。释放锁是完全一样的，我们只看获取锁：

```java
final boolean initialTryLock() {  
    Thread current = Thread.currentThread();  
    if (compareAndSetState(0, 1)) { // first attempt is unguarded  
    ... ...
}
```

好么，CAS。也就是说，CAS会看看当前的state是不是0，如果是的话，就更新成1。其实，这个CAS操作就是非公平锁能够【插队】的关键。

那么，为啥可以用CAS呢？因为<u>CAS同时具有volatile的读内存语义和写内存语义</u>。因此，它也可以放在方法的开头，和释放锁的那一段呼应。

- [ ] #TODO 这里加上hotspot源码。

[[Study Log/java_kotlin_study/concurrency_art/resources/why_cas_has_volatile_semantics|why_cas_has_volatile_semantics]]

```ad-summary
title: 总结-公平锁和非公平锁

* 公平锁和非公平锁释放时，最后都要写一个 volatile 变量 state。
* 公平锁获取时，首先会去读 volatile 变量。
* 非公平锁获取时，首先会用 CAS 更新 volatile 变量，这个操作同时具有 volatile 读 和 volatile 写的内存语义。
```

通过这个分析，我们能猜出来，要想实现锁的内存语义，在纯Java层面有这么两种方式：

* 利用volatile的写后读的内存语义；
* 利用CAS附带的volatile的读写内存语义。

最后再说一句。现在我们只是最基础最基础的，没有大刀阔斧地去讲锁的什么什么东西，<u>也没提这个锁咋实现的公平和非公平</u>。现在提到的只是实现一个锁会用到的很基础的东西。比如volatile。理论上，我们可以用很多个volatile还有CAS的拼接来弄出一个真正能用的锁。而这个就是concurrent包在做的事情。

分析一下concurrent包，我们就能看到一个非常通用的实现并发控制的模式：

1. 首先，声明共享变量为volatile；
2. 然后，使用CAS的原子条件更新来实现线程间的同步；
3. 同时配合volatile以及CAS具有的读写内存语义来实现线程间的通信。

而基于volatile + CAS的组合，concurrent包又定义了一些比较基础的模型：

* **AQS**：AbstractQueuedSynchronizer。我们简单翻译一下这个类的第一段注释：这玩意儿提供了一个框架，用这个框架我们能实现一些**阻塞的锁**以及一些“同步器”，比如semaphore，events等等。这些同步器都依赖于一个FIFO（first-in-first-out）的<label class="ob-comment" title="等待队列" style=""> 等待队列 <input type="checkbox"> <span style=""> ReentrantLock不就是这样的吗？！ </span></label>。然后，这个同步器有啥特点呢？就是如果你这个同步器依赖于一个**int值**来表示<label class="ob-comment" title="当前同步的状态" style=""> 当前同步的状态 <input type="checkbox"> <span style=""> 这不就是ReentrantLock里的那个getState和setState吗？！ </span></label>，那么就很适合了。所以，如果你继承了AQS，==那么子类就必须定义一些protected的方法来改变这个state==。光改变还不算完，<u>你还得定义获取锁或者释放锁的时候，这个状态是啥意思</u>。 ^b71a4e
* **非阻塞数据结构**
* **原子变量类**：也就是java.util.concurrent.atomic包中的类。也就是之前说CAS的时候用到的。

- [ ] #TODO “你还得定义获取锁或者释放锁的时候，这个状态是啥意思”这句话tm是啥意思？结合后面对源码的分析解释一下。
- [ ] #TODO 非阻塞数据结构到底是啥？这里要明确一下。
- [x] #TODO “子类定义protected方法来改变state”的具体操作： [[Study Log/java_kotlin_study/concurrency_art/5_lock_in_java#^c383c9|5_lock_in_java]]

而在这三个东西的基础上，我们才实现了更加精细化的并发控制的工具。比如ReentrantLock就是基于AQS而产生的锁，它里面的FairSync和NonfairSync就是基于AQS产生的同步器。

因此，concurrent包的大体结构如下：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240203160837.png]]

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