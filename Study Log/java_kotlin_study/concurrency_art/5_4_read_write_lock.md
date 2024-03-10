---
title: 5.4 读写锁
chapter: "5"
order: "4"
---

## 5.4 读写锁

其实我们已经介绍过读写锁了，在本章的[[Study Log/java_kotlin_study/concurrency_art/5_2_aqs#5.2.2.4 共享式获取|5_2_aqs]]。读写锁就是用读的方式和写的方式去访问同一把锁，来解决『读写者问题』：

* 如果有读者，那么只有读者能访问，其它写者不能访问；
* 如果有写者，那么其它读者和写者都不能访问。

我们也说过，读写锁其实是一把锁，但是读写的访问方式不一样而已。其中读者是共享式访问，写者是独占式访问。

但是，如果我们稍微看一下concurrent包的读写锁实现ReentrantReadWriteLock，会发现并不是这样：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240304232804.png]]

我们发现，读写锁里面有两个Lock？为啥是这样？其实，如果我们稍微细看一点，就能发现，实际上还是同一把锁：

```java
// 读锁的构造
protected ReadLock(ReentrantReadWriteLock lock) {
	sync = lock.sync;
}

// 写锁的构造
protected WriteLock(ReentrantReadWriteLock lock) {
	sync = lock.sync;
}

// 读写锁的构造
public ReentrantReadWriteLock(boolean fair) {
	sync = fair ? new FairSync() : new NonfairSync();
	readerLock = new ReadLock(this);
	writerLock = new WriteLock(this);
}
```

我们发现，最终使用的Sync其实都是同一个，也就是说，**读写锁依赖于同一个AQS维护的状态**。那不管你Lock怎么分，最后管理的都是同一个状态。

### 5.4.1 使用例子

稍微看一看使用，非常简单：

```java
object TestReadWriteLock {

    private val map = HashMap<String, Any>()
    private val rwl = ReentrantReadWriteLock()
    private val rl = rwl.readLock()
    private val wl = rwl.writeLock()

    operator fun get(key: String): Any? {
        rl.lock()
        try {
            println("read locked by ${Thread.currentThread().name}")
            return map[key]
        } finally {
            rl.unlock()
        }
    }

    operator fun set(key: String, value: Any): Any? {
        wl.lock()
        try {
            println("write locked by ${Thread.currentThread().name}")
            return map.put(key, value)
        } finally {
            wl.unlock()
        }
    }

    fun clear() {
        wl.lock()
        try {
            map.clear()
        } finally {
            wl.unlock()
        }
    }
}
```

我们让HashMap的访问加上读写锁，这样就能够实现ConcurrentHashMap的功能了。

- [ ] #TODO ConcurrentHashMap内部是用synchronized保证并发安全的。那么用读写锁的方式和ConcurrentHashMap哪种更好？➕ 2024-03-04 ⏫ 

### 5.4.2 读写锁实现分析

从名字也可以看出来，ReentrantReadWriteLock既支持读写锁，也支持可重入（甚至支持公平 & 非公平）。那这里就出现了一个问题：既然可重入，那我就要知道一个线程重复获得了多少次这个锁。但是，锁只有一把，但是获取的方式有读和写两种。**那么我就要能表示两种状态分别被获取了多少次**，即使这两种状态是不会同时出现的。

而我们知道，AQS内部就是用一个volatile的int来维护这把锁的全部状态的。那么，咋用一个int来表示两种状态下的情况？答案是，**把int给拆开**：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240309225759.png]]

一个int是4个byte，32个bit。所以拆成高16位和低16位。高的表示读状态，低的表示写状态。所以，之后对于这把读写锁的操作就是这样的：

* 获取写锁：将这个值+1；
* 获取读锁：将这个值+(1<<16)；
* 查看读锁的获取状态：将这个值和0xFFFF0000按位与（取高16位）；
* 查看写锁的获取状态：将这个值和0x0000FFFF按位与（取低16位）。

天才！一个int不够用，就拆成两个半个int！

基于这个思想，我们再来看读写锁的内部实现，就会比较简单了。

> [!attention] 牢记
> * 读锁利用的是AQS的共享获取能力；
> * 写锁利用的是AQS的独占获取能力。

下面，和重入锁一样，我们也来给读写锁画一个图。但是要注意，读写锁同时支持：

* 可重入；
* 公平 & 非公平；
* 读 & 写。

所以，这个图会比较复杂：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-03-10 13.58.31.excalidraw.svg]]

这幅图比[[Study Log/java_kotlin_study/concurrency_art/5_3_reentrant_lock#5.3.2 公平 & 非公平|之前的那张]]改进了一些，更好看懂。我们发现，无论锁本身多么复杂，这套模板方法的规则是不变的：**Lock的实现类需要在实现的接口中（比如`lock()`，`unlock()`等）调用AQS提供的模板方法（比如`acquire()`, `acquireShared()`），然后这些模板方法会自动走到我们的AQS实现类中（比如`tryAcquire()`, `tryAcquireShared()`）**。

> [!attention]
> 这里依然要注意我们强调过的点：AQS并没有给`tryLock()`提供一个能调用的模板方法，因为尝试获得锁只会去尝试一次，不需要依赖AQS内部的等待队列。只不过，在一般情况下，AQS内部的`tryAcquire()`刚好可以用来实现`tryLock()`方法。不过稍后我们会看到ReentrantReadWriteLock没有采用这种策略（其实从ReentrantLock开始就已经不是这种策略了）。

^7c2914

#### 5.4.2.1 写锁的获取

我们首先从独占式的写锁开始分析。我们可以大致猜测一下写获取锁的策略：

1. 如果没有任何人获取任何锁，直接跳到4，如果有人获取锁，走2和3；
2. 如果正在有人获取读锁，那么我不能去获得；
3. 如果没人获取读锁，那就是有人在获取写锁。所以只有当前获取写锁的人就是我自己的时候，才能继续获得锁，否则我也不能获得；
4. 尝试<u>使用CAS</u>获取锁，如果获取成功了，就成功，否则还是失败。

> [!comment] 使用CAS
> 这里有一个非常重要的细节问题需要搞清楚：**使用CAS，而不是循环CAS**。在[[Study Log/java_kotlin_study/concurrency_art/5_2_aqs#5.2.3 实战 - TwinsLock|#5.2.3 实战 - TwinsLock]]的时候，我们尝试写了一个共享式的，能被两个线程同时获取的不可重入的锁。我十分建议你重新读一下那一节，搞清楚那个时候我们遇到的问题。简单来说，就是『在资源数>1的共享式锁中，CAS失败，并不等于获取锁失败』。因为当时我们的state是为0，1，2的时候成立，所以我们必须先看看CAS结束后的新值是什么，才能判断锁是否成功获取。但是到了这个独占式的锁，为什么又可以使用CAS而不是循环CAS了呢？我们可以回头看一下之前我[[Study Log/java_kotlin_study/concurrency_art/5_2_aqs#^4dc7b7|举的例子]]。在资源数为2的共享式锁中，如果是初始状态，三个线程同时去抢锁，那么结果一定是两个线程获得，一个线程没获得。因此仅仅是CAS失败不足以证明我真的没获得，只是有人在跟我抢，如果我重新尝试，没准就能获得了。但是回头来看独占式的锁，如果也是三个线程同时去抢，结果是什么？**一定是一个线程获得了，两个线程没获得**。那么根据CAS的特点我们能知道，有人失败，就一定有人成功。因为之所以我失败，就是因为跟我争抢去修改值的某一个人最终成功将state给更新了。所以，在独占式的情况下，**CAS失败就代表获取锁失败**，因为即使我再怎么尝试，也绝无可能获得，因为它已经被其它某个人给独占了。在[[#5.4.2.2 读锁的获取|后面]]我们也能看到，ReentrantReadWriteLock的读锁在尝试获取的时候采用的也是循环CAS，和我们自己实现的TwinsLock是一致的。

除了上面的这几条，我们还需要注意一些事情。在之前介绍ReentrantLock的时候，我们分析过这样的事情：即使是公平锁，在tryLock()的时候也是用的非公平实现。到了读写锁中，也是一样的套路，那段注释依然也在这里出现了。所以，回头看一下之前说过的：[[#^7c2914]]，刚才说的『稍后』就是现在！

> 其实不把tryAcquire()直接搬到tryLock()中主要的原因，就是因为设计者希望尝试获取锁能够让公平锁也能打破公平。

写锁的最终获取，通过一开始的图就知道，最终会调用到Sync中的tryAcquire()方法；而尝试获取锁，就会走另一套实现。但是，二者的代码几乎是一样的，唯一的区别就是那个打破公平的规则。

我们先看一下写锁tryLock()最终的实现tryWriteLock()：

```java
/**
 * Performs tryLock for write, enabling barging in both modes.
 * This is identical in effect to tryAcquire except for lack
 * of calls to writerShouldBlock.
 */
@ReservedStackAccess
final boolean tryWriteLock() {
	Thread current = Thread.currentThread();
	int c = getState();
	if (c != 0) {
		int w = exclusiveCount(c);
		if (w == 0 || current != getExclusiveOwnerThread())
			return false;
		if (w == MAX_COUNT)
			throw new Error("Maximum lock count exceeded");
	}
	if (!compareAndSetState(c, c + 1))
		return false;
	setExclusiveOwnerThread(current);
	return true;
}
```

> [!comment]
> 上面的注释和我刚才说的一样，和tryAcquire()唯一的区别就是公平的打破，也就是上面的方法没有调用writerShouldBlock()。

和那四步走是一样的逻辑，就不多说了。然后看看tryAcquire()的逻辑：

```java
protected final boolean tryAcquire(int acquires) {
	/*
	 * Walkthrough:
	 * 1. If read count nonzero or write count nonzero
	 *    and owner is a different thread, fail.
	 * 2. If count would saturate, fail. (This can only
	 *    happen if count is already nonzero.)
	 * 3. Otherwise, this thread is eligible for lock if
	 *    it is either a reentrant acquire or
	 *    queue policy allows it. If so, update state
	 *    and set owner.
	 */
	Thread current = Thread.currentThread();
	int c = getState();
	int w = exclusiveCount(c);
	if (c != 0) {
		// (Note: if c != 0 and w == 0 then shared count != 0)
		if (w == 0 || current != getExclusiveOwnerThread())
			return false;
		if (w + exclusiveCount(acquires) > MAX_COUNT)
			throw new Error("Maximum lock count exceeded");
		// Reentrant acquire
		setState(c + acquires);
		return true;
	}
	if (writerShouldBlock() ||
		!compareAndSetState(c, c + acquires))
		return false;
	setExclusiveOwnerThread(current);
	return true;
}
```

对比一下可以发现，其它的逻辑几乎都是一致的，无非多了一些边界的判断（比如`exclusiveCount(acquires)`）。唯一不同的就是最后如果`writerShouldBlock()`返回true，那么我也不能获得锁。而这里面就是公平性的判断。在之前tryLock()中没有调用它，就相当于这里永远返回false，也就是不参与条件判断了。

那么这里面的逻辑是什么呢？其实非常简单，我们都能猜出来。首先，如果是非公平的锁，这个方法肯定直接返回false，因为不需要公平性判断；而如果是公平锁，还记得之前说ReentrantLock的时候公平是怎么来的吗？[[Study Log/java_kotlin_study/concurrency_art/5_3_reentrant_lock#^d7044c|5_3_reentrant_lock]] 也就是说，如果前面有人排着，那么我就认为获取锁已经失败了。因此：

```java
// FairSync对于writerShouldBlock()的实现
final boolean writerShouldBlock() {
	return hasQueuedPredecessors();
}

// NonfairSync对于writerShouldBlock()的实现
final boolean writerShouldBlock() {
	return false; // writers can always barge
}
```

写锁的释放与[[Study Log/java_kotlin_study/concurrency_art/5_3_reentrant_lock#^reentrantrelease|ReentrantLock的释放]]过程几乎一致：

> <small>写锁的释放与 ReentrantLock 的释放过程基本类似，每次释放均减少写状态，当写状态为 0 时表示写锁已被释放，从而等待的读写线程能够继续访问读写锁，同时前次写线程的修改对后续读写线程可见。</small>

- [ ] #TODO [[Study Log/java_kotlin_study/concurrency_art/5_2_aqs#^7548dc|5_2_aqs]] 其中一个原因。释放锁的时候不需要CAS，那么就要保证我释放后的结果对其它线程可见。➕ 2024-03-10 ⏫ 

#### 5.4.2.2 读锁的获取

关于读锁，它的实现看起来非常复杂。这是因为由于读锁是共享式的，所以如果想要获取到每个线程关于读锁的信息，就比较困难。

比如，现在的state就是一个int，那么这里的高16位肯定记录的就是所有线程加起来，一共获取了多少次读锁。但是，如果我想知道每个线程获取读锁的次数呢？这用简单对int的操作就办不到了。jdk采用的做法是，使用ThreadLocal保存每个线程对于读锁的获取信息。加上了这些操作，就使得读锁的获取流程看起来超级复杂。

> [!comment]
> 由于写锁是独占式的，所以没有什么每个线程获取了多少次这种信息，只能被一个线程获取，那还ThreadLocal干鸡毛。

还有一点，和我们实现的TwinsLock不同，TwinsLock的总资源数是2，所以好的策略是获取锁的时候，从2往下减；但是读锁不一样，没有资源限制，只要没人写，那谁都能读。所以这里的策略是读状态从0往上加。不过，如果超过了16bit的最大限制，肯定还是会报错的。

既然如此，获取锁成功的条件是啥？如果不考虑溢出的话，只要循环CAS成功了，就是获取锁成功了。所以，通过代码我们也能看到，无论是tryReadLock()还是tryAcquireShared()，只要CAS成功了，只有返回~~true~~成功的可能。

这里就只分析一下tryLock()那一侧的实现吧，这里清晰一些。

首先，得到当前的状态：

```java
int c = getState();
```

如果有**别**人获得了**写**锁，那么我不能获得读锁：

```java
if (exclusiveCount(c) != 0 &&
	getExclusiveOwnerThread() != current)
	return false;
```

如果当前读锁的状态已经爆了（超过16bit），那么直接抛出错误：

```java
int r = sharedCount(c);
if (r == MAX_COUNT)
	throw new Error("Maximum lock count exceeded");
```

最后，如果CAS成功，那么返回true，否则从头开始：

```java
if (compareAndSetState(c, c + SHARED_UNIT)) {
	... ... // 和ThreadLocal有关的操作，按下不表
	return true;
}
```

以上几步被包裹在一个无限循环中，正应了之前分析的循环CAS。

#### 5.4.2.3 读写锁的降级

读写锁是支持降级的：写锁 -> 读锁。但是不支持升级。这里的支持和不支持指的是从实现的角度，它并没有提供一个降级或者升级的接口。所以，降级操作得我们自己来完成。

需要注意的是，如果一个线程先获得写锁，然后释放它，再获得读锁，这个不叫降级。降级必须是一个线程在已经获取了写锁的情况下，不释放，再获取读锁。支持这个地方的分析，我们可以从[[#5.4.2.2 读锁的获取]]中分析出来，就是这句代码：

```java
if (exclusiveCount(c) != 0 &&
	getExclusiveOwnerThread() != current)
	return false;
```

如果我在获取读锁的时候，发现有人获取写锁，但是这人居然是我自己，那么我也能成功获得读锁。

说实话，这个特性其实和直接获取写锁没啥区别，因为即使锁刚刚降级，但是由于我还没释放写锁，所以其它线程也还是会被阻塞住，只有我一个人能读。这么做的意义我觉得是警示锁的使用者，让他降级了之后虽然有写锁的权力，但是你最好还是只干读锁能做的事情。

因此，不支持锁升级的原因也显而易见：你读锁的权利本身就比写锁小，那么你如果持有了读锁，获取写锁的时候，和其它啥锁也没获取的线程应该是公平竞争的，所以也就不存在升级这一说。

> 书上说什么保持可见性，这东西感觉没说到本质。

锁降级的一般过程：

```java
public void processData() {
	readLock.lock();
	if (!update) {
		// 必须先释放读锁
		readLock.unlock();
		// 锁降级从写锁获取到开始
		writeLock.lock();
		try {
			if (!update) {
				// 准备数据的流程（略）
				update = true;
			}
			readLock.lock();
		} finally {
			writeLock.unlock();
		}
		// 锁降级完成，写锁降级为读锁
	}
	try { // 使用数据的流程（略）
	} finally {
	readLock.unlock();
	}
}
```

这段代码不仅仅描述了锁降级，而是一个比较具体的场景：

1. 首先，我只是想读这个东西，所以获取了读锁。之后，我突然有想写点东西了，所以我必须先释放读锁，然后再获取写锁。因为不支持锁的升级；
2. 然后，在写的过程中，如果我写完了，之后我还是要读了，但是，我不希望在我之后读的时候（上面第一个finally块之前的读，而不是第二个finally）被其它线程写入，所以我依然保持着写锁不释放，继续获取读锁，也就是锁降级。只不过，我们也分析过，这里的降级就是闹着玩儿，只是提示一下开发者你现在最好只给我读，别写而已；
3. 最后，我依然想读，但是我已经不在乎别人是否写入了，所以我释放了写锁，最后想怎么读怎么读吧；
4. 至于最后一个finally块里的unlock()，是为了应对update一开始就为true的情况。

> [!attention]
> 上面的`update`需要是volatile的，需要对其它线程可见。

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