---
title: 5.6 Condition接口
chapter: "5"
order: "6"
---

## 5.6 Condition接口

在一开始，我们实现Mutex的时候，就稍微写过这个东西：[[Study Log/java_kotlin_study/concurrency_art/5_2_aqs#5.2.1 AQS接口与示例|5_2_aqs]]。但是，我们并没有细说。现在开始详细说一下。

### 5.6.1 Condition的使用

#### 5.6.1.1 Mutex改造

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

这就好像：一个房间里只能呆一个指定的人。现在屋子外面有3个人。那么这三个人只能有一个人进入房间，其它两人发现那个人进去之后就不能再动了。进入房间的人还要判断这个时候房间里允许呆的人是不是自己。如果不是，那么他还要从房间里出来，然后这三个人再抢一次。

看起来可以实现，也不错。但是从中我们能发现一些问题。在synchronized版本的实现中，当一个线程进入synchronized块中时，如果发现轮不到自己打印，就需要进行wait()；当一个线程输出完，并修改了下一个人是谁之后，在释放锁之前就会通知一下所有人，也就是notifyAll()。

我们需要注意的是，拿监视器锁和concurrent包做对比，那么Lock接口中的unlock()对应的是什么？**答案应该是synchronized闭包的结束**，而不是wait()方法。这个问题其实很好理解，如果你还记得当时我们介绍wait和notify的时候说的：[[Study Log/java_kotlin_study/concurrency_art/4_3_inter_thread_communication_1#4.3.2 Wait & Notify|4.3.2 Wait & Notify]]。**wait其实就是将线程移入一个等待队列，而synchronized结束直接就和这个Object没关系了**。所以他俩肯定是不一样的，并且unlock()明显和后者的语义一致。

既然如此，问题来了：*wait()在concurrent包中对应的是啥*？这东西还是很有必要的：操作系统中本身就有Conditional Variables这种东西，**让线程根据不同的情况等待在不同的队列中，虽然竞争的还是同一把锁**。而看名字也知道，本节的主角Condition就是这个东西。并且，它的使用语义和wait() \& notify()也是一致的。

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

当执行await()的时候，当前线程必须已经持有Lock。之后会释放掉这个Lock()同时等待。当其它线程调用signal() / signalAll()的时候会被唤醒，从await()返回。**在从await()返回之前也能确保再次获得了Lock**。

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

这样就完成了！和synchronized版本一致的Lock版本。这就是Condition的作用。能让**Lock的持有者**拥有和**监视器锁的持有者**类似的行为。同时，由于一个Lock可以有多个Condition，所以也可以<u>让不同的线程由于不同的原因等待在不同的队列上</u>。

我们对比一下之前那张图：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-02-12 23.18.16.excalidraw.png]]

可以看到，一个Object对应一个同步队列（Synchronized Queue）和一个等待队列（Wait Queue）。然而到了Condition这边，就是一个同步队列和多个等待队列了：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240321183108.png]]

#### 5.6.1.2 有界队列

这玩意儿是书上的，但是实际上就是Condition源码中的注释里的例子。我们来好好说说。这玩意儿的优点就是：**空的时候会等，满的时候也会等**。回想之前的那个线程池：[[Study Log/java_kotlin_study/concurrency_art/4_4_thread_example|4_4_thread_example]]。在里面的实现中，只有队列是空的时候，那些抢活儿干的线程会等待。用的是synchronized + wait。

那么这样其实是不完美的：因为如果我们不停往里面加任务，加的速度超过了干活儿线程消费的速度。此时你再往里加任务，其实效率反而会降低。因为你加任务那个线程（通常是主线程）完全可以用这个时间干点儿别的事情。

这就是我们“满的时候也会等”的原因。那么问题来了：空的时候等，和满的时候等，他俩等的锁是啥？**其实都是这个队列**。因为你加任务的时候别人不能拿，你拿任务的时候别人也不能加。而我要等，还要分为两种不同的情况去等。这就是Condition起作用的时候了。




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