---
title: 5.6 Condition接口
chapter: "5"
order: "6"
---

## 5.6 Condition接口

在一开始，我们实现Mutex的时候，就稍微写过这个东西：[[Study Log/java_kotlin_study/concurrency_art/5_2_aqs#5.2.1 AQS接口与示例|5_2_aqs]]。但是，我们并没有细说。现在开始详细说一下。

### 5.6.1 Condition的使用

#### 5.6.1.1 交替打印

在使用Mutex的时候，我们又进行了1-100的交替打印，最后实现的源码是这样的：

```kotlin
class MutexPrintThread(private val thNum: Int, private val otherNum: Int) : Thread("mutex-thread-$thNum") {
	override fun run() {
		while (i < 100) {
			mutex.lock()
			if (currThNum != thNum) {
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
```

一个线程先尝试获得锁。获得了之后只要发现轮不到我打印，那么就立刻要释放锁并出来。

这就好像：一个房间里只能呆一个**指定**的人。现在屋子外面有3个人。那么这三个人只能有一个人进入房间，其它两人发现那个人进去之后就不能再动了。进入房间的人还要判断这个时候房间里允许呆的人是不是自己。如果不是，那么他还要从房间里出来，然后这三个人再抢一次。

看起来可以实现，也不错。但是从中我们能发现一些问题。在synchronized版本的实现中，当一个线程进入synchronized块中时，如果发现轮不到自己打印，就需要进行wait()；当一个线程输出完，并修改了下一个人是谁之后，在释放锁之前就会通知一下所有人，也就是notifyAll()。

我们需要注意的是，拿监视器锁和concurrent包做对比，那么Lock接口中的unlock()对应的是什么？**答案应该是synchronized闭包的结束**，而不是wait()方法。这个问题其实很好理解，如果你还记得当时我们介绍wait和notify的时候说的：[[Study Log/java_kotlin_study/concurrency_art/4_3_inter_thread_communication_1#4.3.2 Wait & Notify|4.3.2 Wait & Notify]]。**wait其实就是将线程移入一个等待队列，而synchronized结束直接就和这个Object没关系了**。所以他俩肯定是不一样的，并且unlock()明显和后者的语义一致。

既然如此，问题来了：*wait()在concurrent包中对应的是啥*？这东西还是很有必要的：操作系统中本身就有Conditional Variables这种东西，**让线程根据不同的情况等待在不同的队列中，虽然竞争的还是同一把锁**。而看名字也知道，本节的主角Condition就是这个东西。并且，它的使用语义和wait() \& notify()也是一致的。

> [!note]-
> 你可能会想起上一节我们提到的东西：[[Study Log/java_kotlin_study/concurrency_art/5_5_lock_summary#^7a8a69|5_5_lock_summary]]。我们说过concurrent包中，使用LockSupport提供的park()和unpark()来实现一个**更轻量的wait() \& notify()**操作。所以你会觉得synchronized中使用wait()相当于Concurernt包中的park()。但是，为啥这里又说是Condition呢？其实很容易想到，park()和unpark()是非常不安全的操作，非常底层。所以想要像使用wait和notify那样使用它们，必须好好封装一下。我们可以看看Condition中接口的实现，其实底层也都是park()和unpark()。比如下面的await() \& signal()就是这样。

下面我们来改造一下上面交替打印的例子，使用Condition来实现。首先，Condition的创建必须使用Lock接口的newCondition()方法：

```kotlin
val mutex = Mutex()
val condition = mutex.newCondition()

// Mutex
override fun newCondition(): Condition {
	return sync.newCondition()
}

// AQS
fun newCondition() = ConditionObject()
```

可以看到，归根结底也就是创建了一个ConditionObject。一个Condition对应了一个Lock，属于多对一的关系。所以一把锁可以有多个条件，每个条件下面都可以等待着不同的队列。

Condition最主要的两个方法就是await()和signalAll()。它们的语义和wait \& notifyAll()很像。所以使用的思路也很像。

当执行await()的时候，当前线程必须已经持有Lock。之后会释放掉这个Lock同时等待。当其它线程调用signal() / signalAll()的时候会被唤醒，从await()返回。**在从await()返回之前也能确保再次获得了Lock**。

因此，通常情况下使用await \& signal的范式如下：

```java
// await使用
lock.lock();
try {
	condition.await();
} finally {
	lock.unlock();
}

// signal使用
lock.lock();
try {
	condition.signal();
} finally {
	lock.unlock();
}
```

^89ef65

现在看看我们的交替打印怎么改。其实很简单，原来是发现不是自己打印就释放锁并重来，那么现在就是发现不是自己打印就要await：

```kotlin
while (i < 100) {
	mutex.lock()
	if (currThNum != thNum) {
		condition.await()
	}
	... ...
}
```

当从await返回时，就代表再一次获得了锁。但是别忘了，虽然我们又获得了锁，轮不轮得到我们打印呢？所以，上面的实现是错误的，正确的做法是if换成while：

```kotlin
while (i < 100) {
	mutex.lock()
	while (currThNum != thNum) {
		condition.await()
	}
	... ...
}
```

后面就是正常的逻辑了，最后在释放锁之前记得signal一下：

```kotlin
class MutexPrintThread2(private val thNum: Int, private val otherNum: Int) : Thread("mutex-thread-$thNum") {
	override fun run() {
		while (i < 100) {
			mutex.lock()
			while (currThNum != thNum) {
				condition.await()
			}
			println("thread $thNum print $i")
			currThNum = otherNum
			i++
			condition.signalAll()
			mutex.unlock()
		}
	}
}
```

这样就写完了。不过你如果少了一个地方，是跑不起来的。必须重写AQS中的isHeldExclusively()方法：

```kotlin
override fun isHeldExclusively(): Boolean {
	return state == 1    // getState()
}
```

这样就完成了！<fieldset class="inline"><legend class="small">💬</legend>和synchronized版本一致的Lock版本</fieldset>。这就是Condition的作用。能让**Lock的持有者**拥有和**监视器锁的持有者**类似的行为。同时，由于一个Lock可以有多个Condition，所以也可以<u>让不同的线程由于不同的原因等待在不同的队列上</u>。

> [!comment] 和synchronized版本一致的Lock版本
> 我们在上一节介绍LockSupport的时候说过，park和unpark比wait和notify要轻量。当时我们还举了那个例子：[[Study Log/java_kotlin_study/concurrency_art/5_5_lock_summary#^8eeacb|5_5_lock_summary]]。我们使用Lock接口时的这些操作（比如Condition）和synchronized是一致的，但是由于concurrent包中的操作基于volatile和CAS操作，相对于管程更加轻量，所以一致的行为效率会更高一些。

- [ ] #TODO 有没有什么情况，Lock接口的效率反而不如synchronized？ ➕ 2024-03-23 🔽 

我们对比一下之前那张图：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-02-12 23.18.16.excalidraw.png]]

可以看到，一个Object对应一个同步队列（Synchronized Queue）和一个等待队列（Wait Queue）。然而到了Condition这边，就是一个同步队列和多个等待队列了：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240321183108.png]]

#### 5.6.1.2 有界队列

这玩意儿是书上的，但是实际上就是Condition源码中的注释里的例子。我们来好好说说。这玩意儿的优点就是：**空的时候会等，满的时候也会等**。回想之前的那个线程池：[[Study Log/java_kotlin_study/concurrency_art/4_4_thread_example|4_4_thread_example]]。在里面的实现中，只有队列是空的时候，那些抢活儿干的线程会等待。用的是synchronized + wait。

那么这样其实是不完美的：因为如果我们不停往里面加任务，加的速度超过了干活儿线程消费的速度。此时你再往里加任务，其实效率反而会降低。因为你加任务那个线程（通常是主线程）完全可以用这个时间干点儿别的事情。

这就是我们“满的时候也会等”的原因。那么问题来了：空的时候等，和满的时候等，他俩等的锁是啥？**其实都是这个队列**。因为你加任务的时候别人不能拿，你拿任务的时候别人也不能加。而我要等，还要分为两种不同的情况去等。这就是Condition起作用的时候了。

现在来看看代码。我们用一个100个元素的数组表示队列，但是做的更加巧妙。我们来看看图示：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-03-31 00.36.57.excalidraw.svg]]

`put_ptr`表示队尾，也就是入队的位置；而`take_ptr`就是出队的位置，自然就是队头。那么：

* 每当入队时，`put_ptr++`。如果走到了头，就回到头；
* 每当出队时，`take_ptr++`。如果走到了头，就回到头。

看起来很不合理，但实际上合理得很。在某个时刻，这个队列可能是这样的：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-03-31 00.42.05.excalidraw.svg]]

此时。队尾走过了一圈又绕了回来。这样很好地利用了这个数组。此时，如果按编号从队头数到队尾，就应该是：50, 51, 52, ..., 98, 99, 0, 1。

显然，队列里最多只能有100个元素。那么，如果我一直往里加任务，没人去消费的话，等到加满了，就不会再加了。这也是之前我们没实现的逻辑；另外，和之前一样，如果一个线程发现队列里没东西了，那也会等，不再去取了。

结合之前的Condition，我们来统计一下这个案例需要的东西：

* 一个队列，就是个数组，100个元素；
* 两个指针，分别指向队头（要拿走的元素位置）和队尾（要放入元素的**空格**）；
* 一把锁，锁的就是队列。因为无论是加还是拿，都是不能有其它人干预的；
- [*] 两个Condition，一个是队列中空的时候等它有东西；一个是队列满的时候等它被消费。这两个Condition都是和队列挂钩的，所以对应的都是同一把锁。

现在来准备一下吧：

```kotlin
private val lock: Lock = ReentrantLock()
// 两个Condition，对应同一把锁
private val notFull: Condition = lock.newCondition()
private val notEmpty: Condition = lock.newCondition()

val items: Array<Any> = Array(100) {}

// put item pointer, take item pointer, actual item count
private var putptr = 0
private var takeptr = 0
private var count = 0
```

相信通过解释，我不需要说明代码的意义了，除了那两个Condition的名字和作用。接下来就是代码细节了。首先，我们需要弄懂，*这两个Condition到底能实现什么*？现在，假设干活儿的线程有2个，那么情况应该是这样的：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-03-31 01.16.08.excalidraw.svg]]

上面图的编号看一下，0号线程是提交任务的线程，通常是主线程。而1号和2号就是线程池里干活儿的线程。中间的队列就是我们实现的这个有界队列。那么：

* 当1和2从队列中取任务时，发现没任务了，需要等；
* 当0往队列里放任务时，发现任务满了，需要等。

这两种等的情况一样吗？不一样。一个是空了一个是满了。那么，如果我没有Condition的话，如果我等了，那么**谁**该用**什么**唤醒我？我们发现，『谁』和『什么』这两个东西我们都需要确定。

比如还是之前的synchronized版本，当0发现满了，就等了。那么如果0刚刚休息，队列里的任务立马就被干活儿的线程给清空了（可能比较卷，就像我现在这段文字是凌晨1:23写的），这个时候1又要取任务，那么发现已经没了，所以也等了。这个时候，如果任意一个线程（可能是线程池里的线程，也可能是另一个新的提交任务的0.5号线程，whoever）调用了notifyAll()或者notify()，那唤醒的是谁？

我们发现，**好像都（可能）被唤醒了**！如果是notify()，那么就可能唤醒了0号或者1号或者2号（取决于之前0和1，2谁在队列的前面）；如果是notifyAll()，那么就把所有线程都给唤醒了。这显然不是我们希望的。如果调用notify()的是一个新的提交任务的线程，那么我希望唤醒的是干活儿的线程；如果调用notify()的是一个干活儿的线程，那么就应该是**现在队列还不是满的**，我希望有人再提交一点儿。

上面的问题总结起来就是：<u>我没有一个手段能准确地通知到我想通知的线程</u>。显然，Condition就是这个手段。每个线程由于某个原因，在等待着某个Condition。在本例中：

* 提交任务的线程，在队列**满了**（原因）之后，等待着队列**不满**（notFull, Conditioin）；
* 干活儿的线程，在队列**空了**（原因）之后，等待着队列**不空**（notEmpty, Condition）。

所以，我们直接用Condition的通知能力，就能**精准定位**到我想通知的线程，唤醒他们。

首先是提交任务的方法：

```kotlin
@Throws(InterruptedException::class)
fun put(x: E) {
	lock.lock()
	try {
		while (count == items.size) {
			notFull.await()
		}
		items[putptr] = x
		if (++putptr == items.size) {
			putptr = 0
		}
		++count
		notEmpty.signal()
	} finally {
		lock.unlock()
	}
}
```

首先锁住队列，当发现队列已经满了，那么我等着它什么时候不满。**如果被唤醒了，那么就是真不满了**。所以我现在可以放入一个元素，然后将指针挪到下一位。同时，因为我已经放入了一个元素，所以现在是不空的，所以我通知一下**等着不空**的那些线程。

举一反三，干活儿的方法也很简单：

```kotlin
@Suppress("UNCHECKED_CAST")
@Throws(InterruptedException::class)
fun take(): E {
	lock.lock()
	try {
		while (count == 0) {
			notEmpty.await()
		}
		val item = items[takeptr] as E
		if (++takeptr == items.size) {
			takeptr = 0
		}
		--count
		notFull.signal()
		return item
	} finally {
		lock.unlock()
	}
}
```

- [ ] #TODO 补一个这玩意儿使用的例子 ➕ 2024-03-31 🔽 

#### 5.6.1.3 再次交替打印

- [ ] #TODO 梳理一下交替打印到底有多少方式？根据语言，实现方式区分。 ➕ 2024-04-02 ⏫ 

通过有界队列，我们发现，利用好这个等待队列，可以实现非常高效的程序。就比如再升级一下交替打印。我自己以前实现的所有版本的交替打印，都有这么一个问题：**当被唤醒的时候，可能还是没轮到我，所以又进行等待/解锁**。这就导致了，以前的版本在里面都有一个『while + 等待』的逻辑，无论是使用synchronized还是Lock，还是一个单独的Condition（[[#5.6.1.1 交替打印]]）。

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240402234739.png|400]] ![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240402234800.png|400]]

写法是其次，问题是这样做确实会让一些线程做无用功。那么，有没有一种可能，**我唤醒的线程就是下一个要打印的线程呢**？

[8.线程-互斥量_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV18p4y167Md?p=209&vd_source=64798edb37a6df5a2f8713039c334afb) 这个视频里介绍了C语言中实现的一种思路，用的是4个Mutex。显然，我们也可以使用4个Mutex（或者ReentrantLock）来实现，不过这里介绍的是4个Condition。

4个Condition其实更合理。Condition的意思是“我要等待一个『我可以做』的时机”，因此『轮到我打印』就是一个很好的时机。

给每个线程指定一个Condition，没轮到自己就等待，自己打印完之后通知下一个线程继续：

```kotlin
while (i < 100) {
	mutex.lock()
	try {
		if (thNum != currThNum) {
			// 自己等待
			conditions[thNum - 1].await()
		}
		if (i <= 100) {
			println("${name}: $i")
		}
		i++
		currThNum = otherNum
		// 唤醒下一个
		conditions[otherNum - 1].signal()
	} finally {
		mutex.unlock()
	}
}
```

注意，我们不需要while了，直接用if就行。因为**只要我们被唤醒了，那么现在一定是轮到我打印了**。

> [!note]
> 这里再次强调一下Condition和Lock之间的关系：Condition是和Lock打配合的组件，并且只能由Lock进行创建。在Lock接口中有个newCondition()方法，这个方法就是用来创建Condition的。而Lock的实现方（比如ReentrantLock）需要实现这个方法。这个方法的实现基本上就是靠AQS的默认实现。而这个默认实现实际上就是创建一个ConditionObject。

### 5.6.2 Condition 的实现分析

首先，来对比一下Condition和Synchronized的区别：

| 对比项                            | Object Monitor Methods  | Condition                                              |
| ------------------------------ | ----------------------- | ------------------------------------------------------ |
| 前置条件                           | 获取对象的锁                  | 调用Lock.lock()获取锁<br>调用Lock.newCondition()获取Condition对象 |
| 调用方式                           | 直接调用<br>如：object.wait() | 直接调用<br>如：condition.wait()                             |
| 等待队列个数                         | 一个                      | 多个                                                     |
| 当前线程释放锁并进入等待状态                 | 支持                      | 支持                                                     |
| 当前线程释放锁并进入等待状态，在等待状态中**不**响应中断 | 不支持                     | 支持                                                     |
| 当前线程释放锁并进入超时等待状态               | 支持                      | 支持                                                     |
| 当前线程释放锁并进入等待状态到将来的某个时间         | 不支持                     | 支持                                                     |
| 唤醒等待队列中的一个线程                   | 支持                      | 支持                                                     |
| 唤醒等待队列中的全部线程                   | 支持                      | 支持                                                     |

然后看一眼Condition的这张图：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240321183108.png]]

~~说实话，我对上面这张图从Condition指向同步器的箭头的正确性存疑。因为我翻遍了代码，也没看到Condition和AQS是用什么方式绑定起来的。诚然，ConditionObject确实是AQS的内部类，但是~~

> [!note]
> 草，刚写一半，就知道了。这个箭头确实是对的，因为ConditionObject是内部类，而不是静态内部类。他俩的区别见[[Study Log/java_kotlin_study/constructor/constructors_and_static_classes#静态内部类|constructors_and_static_classes]]。所以，必须构造出一个AQS的实例，才能继续构造ConditionObject。因此，他俩确实是一对多的关系。

接下来我们介绍的Condition的功能都是默认是ConditionObject的。

从之前的图就能看出来。结构如下：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240529202953.png]]

ConditionObject有两个最重要的成员：firstWaiter和lastWaiter。其实就是链表的头指针和尾指针。而每一个结点都有指向下一个结点的指针。你可以看[[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240321183108.png|上面Condition的图]]，或者[[Study Log/java_kotlin_study/concurrency_art/5_2_aqs#5.2.2.1.1 获取失败后 - 添加新节点 - addWaiter()|之前我们对AQS同步队列的描述]]，来对比一下两者（Lock的同步队列和Condition的等待队列）之间的区别。

- [ ] #TODO tasktodo1716987186900 下面的部分也是jdk8的，之后看看jdk17是什么样子的。

#### 5.6.2.1 await()的实现

我们可以猜一下，一个线程什么时候才会进入这个队列：当然是调用await()方法！所以，我们需要从await()调用的地方谈起。什么时候才会调用await()方法？我们说过：[[#^89ef65]]。必须是在已经获得了锁的情况下，才能调用await()。这个和进入了synchronized闭包之后，再调用Object.wait()的效果是一样的，都是要**释放已经获得的锁**，并且等待其它人唤醒它，等再次获得了锁之后才会从这里继续。因此，

默认情况下，ConditionObject的await()是可以处理中断的。具体的流程如下：

1. 如果当前线程已经被中断了（通过标记位判断），抛出InterruptedException；
2. 保存当前AQS的状态（因为当前线程就是已经获得了锁的线程，所以理应记录状态。通过getState()方法。）；
3. 调用[[Study Log/java_kotlin_study/concurrency_art/5_2_aqs#5.2.2.2 锁的释放 - release()|release()]]来释放锁，如果失败了会抛出IllegalMonitorStateException异常。这个异常就是那种你要释放锁，但是却连锁都没获得的情况；
4. 接下来一直在队列里等，直到被**通知**或者被**中断**（中断了会抛出InterruptedException）；
5. 重新尝试获得锁，需要改的状态就是之前存的状态，也就是要恢复到之前的状态。另外获得锁的方式取决于这个本来是啥锁，是互斥，重入，读写等；

- [ ] #TODO tasktodo1717400910299 以上的流程来自jdk8的ConditionObject的await()方法的注释。之后看看jdk17+的版本的注释还一不一样。如果还是一样的话，那感觉没啥细看的必要。也可以搜搜jdk在迭代的过程中有关AQS的变化。 ➕ 2024-06-03 🔼 

以上过程如下图。就是从同步队列的牢大（获得了锁的线程）变成了调用await()的ConditionObject的队列的一个小小节点。

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240603155150.png]]

> [!attention]
> 这里需要注意，是用当前线程构造一个新节点，不是原封不动加进去。加的实现看addConditionWaiter()方法。不过，同步队列中的节点和等待队列中的节点都是Node，至少jdk8是这样的。

最后看一眼代码：

```java
/**
 * Implements interruptible condition wait.
 * <ol>
 * <li> If current thread is interrupted, throw InterruptedException.
 * <li> Save lock state returned by {@link #getState}.
 * <li> Invoke {@link #release} with saved state as argument,
 *      throwing IllegalMonitorStateException if it fails.
 * <li> Block until signalled or interrupted.
 * <li> Reacquire by invoking specialized version of
 *      {@link #acquire} with saved state as argument.
 * <li> If interrupted while blocked in step 4, throw InterruptedException.
 * </ol>
 */
public final void await() throws InterruptedException {
	if (Thread.interrupted())
		throw new InterruptedException();
	Node node = addConditionWaiter();
	int savedState = fullyRelease(node);
	int interruptMode = 0;
	while (!isOnSyncQueue(node)) {
		LockSupport.park(this);
		if ((interruptMode = checkInterruptWhileWaiting(node)) != 0)
			break;
	}
	if (acquireQueued(node, savedState) && interruptMode != THROW_IE)
		interruptMode = REINTERRUPT;
	if (node.nextWaiter != null) // clean up if cancelled
		unlinkCancelledWaiters();
	if (interruptMode != 0)
		reportInterruptAfterWait(interruptMode);
}
```

#### 5.6.2.2 signal()的实现

下一步，这些节点怎么粗去？当然是调用signal()啦！还是之前使用Condition的范式：[[#^89ef65]]。调用signal()的线程也需要是获得了Lock的线程，<fieldset class="inline"><legend class="small">💬</legend>因为只有这些线程才知道这个锁马上就要被释放了</fieldset>。调用了signal()，会通知等待队列中的**老大**，也就是**等待了最久的线程**。通知它尝试获取锁。

> [!comment] 因为只有这些线程才知道这个锁马上就要被释放了
> 避免看不懂，这里就是因为，通常是先调用signal()，然后立马释放lock。所以才说这些线程知道什么时候锁释放，因为只有占有，才知道什么时候会主动失去。

```java
/**
 * Moves the longest-waiting thread, if one exists, from the
 * wait queue for this condition to the wait queue for the
 * owning lock.
 *
 * @throws IllegalMonitorStateException if {@link #isHeldExclusively}
 *         returns {@code false}
 */
public final void signal() {
	if (!isHeldExclusively())
		throw new IllegalMonitorStateException();
	Node first = firstWaiter;
	if (first != null)
		doSignal(first);
}
```

- [ ] #TODO tasktodo1717402132180 具体的实现在doSignal()方法里，后面有时间补上。

> 通过调用同步器的 enq(Node node)方法，等待队列中的头节点线程安全地移动到同步队列。当节点移动到同步队列后，当前线程再使用 LockSupport 唤醒该节点的线程。
> 
> 被唤醒后的线程，将从 await()方法中的 while 循环中退出（isOnSyncQueue(Node node)方法返回 true，节点已经在同步队列中），进而调用同步器的 acquireQueued()方法加入到获取同步状态的竞争中。
> 
> 成功获取同步状态（或者说锁）之后，被唤醒的线程将从先前调用的 await()方法返回，此时该线程已经成功地获取了锁。

signalAll()没啥好说的，就是给队列里的每个线程执行一遍signal()。

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