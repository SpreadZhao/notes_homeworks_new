---
title: 6.3 Java中的阻塞队列
chapter: "6"
order: "3"
---

## 6.3 Java中的阻塞队列

> [!attention]
> 本文章jdk版本：[openjdk/jdk at jdk8-b120](https://github.com/openjdk/jdk/tree/jdk8-b120)

之前写过一个阻塞队列：[[Study Log/java_kotlin_study/concurrency_art/5_6_condition#5.6.1.2 有界队列|5_6_condition#5.6.1.2 有界队列]]。而jdk里本身就提供了这种数据结构。显然，人家提供的功能更多。我们现在来分析一下。

| 方法\\处理方式 |    抛出异常     |   返回特殊值    |   一直阻塞   |          超时退出          |
| :------: | :---------: | :--------: | :------: | :--------------------: |
|    插入    |  `add(e)`   | `offer(e)` | `put(e)` | `offer(e, time, unit)` |
|    移除    | `remove()`  |  `poll()`  | `take()` |   `poll(time, unit)`   |
|    检查    | `element()` |  `peek()`  |    无     |           无            |

拿插入来举例子。你第一次看到有add，又有offer，还有put。这么多方法都可以插入，显然它们是有区别的。

其它的其实就和我们自己写的核心思想是一样的了，比如ArrayBlockingQueue使用的就是Condition，它的put代码如下(java8)：

```java
/**
 * Inserts the specified element at the tail of this queue, waiting
 * for space to become available if the queue is full.
 *
 * @throws InterruptedException {@inheritDoc}
 * @throws NullPointerException {@inheritDoc}
 */
public void put(E e) throws InterruptedException {
	checkNotNull(e);
	final ReentrantLock lock = this.lock;
	lock.lockInterruptibly();
	try {
		while (count == items.length)
			notFull.await();
		enqueue(e);
	} finally {
		lock.unlock();
	}
}
```

对比一下我们自己写的：

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

ABQ的put里面这个enqueue方法，就和我们自己写的后面半部分几乎是一样的。所以这里我们主要分析一下之前没说过的内容：park的内部实现。

我们在之前的一些内容中介绍过park： ^9c1599

- [[Study Log/java_kotlin_study/concurrency_art/5_5_lock_support#^7a8a69|5_5_lock_support]]
- [[Study Log/java_kotlin_study/concurrency_art/5_6_condition#^0b45b9|5_6_condition]]
- [[Study Log/java_kotlin_study/concurrency_art/5_6_condition#^d28715|5_6_condition]]

park是一个更轻量的wait，也是阻塞线程。那么我们看看park的源代码：

```java
/**
 * Disables the current thread for thread scheduling purposes unless the
 * permit is available.
 *
 * <p>If the permit is available then it is consumed and the call returns
 * immediately; otherwise
 * the current thread becomes disabled for thread scheduling
 * purposes and lies dormant until one of three things happens:
 *
 * <ul>
 * <li>Some other thread invokes {@link #unpark unpark} with the
 * current thread as the target; or
 *
 * <li>Some other thread {@linkplain Thread#interrupt interrupts}
 * the current thread; or
 *
 * <li>The call spuriously (that is, for no reason) returns.
 * </ul>
 *
 * <p>This method does <em>not</em> report which of these caused the
 * method to return. Callers should re-check the conditions which caused
 * the thread to park in the first place. Callers may also determine,
 * for example, the interrupt status of the thread upon return.
 *
 * @param blocker the synchronization object responsible for this
 *        thread parking
 * @since 1.6
 */
public static void park(Object blocker) {
	Thread t = Thread.currentThread();
	setBlocker(t, blocker);
	UNSAFE.park(false, 0L);
	setBlocker(t, null);
}
```

根据注释，park在把线程停止之后，有三种恢复的方式：

1. 其他线程对该线程调用了unpark。这里注意需要**成对**调用；
2. 其他线程中断了该线程；
3. 异常现象发生时，这个异常现象没有任何原因。

除了这个版本的park，还有两个带时间参数的版本：

```java
public static void parkNanos(Object blocker, long nanos)
public static void parkUntil(Object blocker, long deadline)
```

parkNanos可以设置一个超时时间，而parkUntil设置的是ddl。比如可以是`System.currentTimeMillis() + 10`。

接下来看HotSpot的实现。在[unsafe.cpp的1613行](https://github.com/openjdk/jdk/blob/9a9add8825a040565051a09010b29b099c2e7d49/hotspot/src/share/vm/prims/unsafe.cpp#L1613)可以找到jdk1.8注册的位置。然后就是定位了：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240623005531.png]]

贴出来：

```cpp
void os::PlatformEvent::park() {       // AKA "down()"
  // Invariant: Only the thread associated with the Event/PlatformEvent
  // may call park().
  // TODO: assert that _Assoc != NULL or _Assoc == Self
  int v ;
  for (;;) {
      v = _Event ;
      if (Atomic::cmpxchg (v-1, &_Event, v) == v) break ;
  }
  guarantee (v >= 0, "invariant") ;
  if (v == 0) {
     // Do this the hard way by blocking ...
     int status = pthread_mutex_lock(_mutex);
     assert_status(status == 0, status, "mutex_lock");
     guarantee (_nParked == 0, "invariant") ;
     ++ _nParked ;
     while (_Event < 0) {
        status = pthread_cond_wait(_cond, _mutex);
        // for some reason, under 2.7 lwp_cond_wait() may return ETIME ...
        // Treat this the same as if the wait was interrupted
        if (status == ETIME) { status = EINTR; }
        assert_status(status == 0 || status == EINTR, status, "cond_wait");
     }
     -- _nParked ;

    _Event = 0 ;
     status = pthread_mutex_unlock(_mutex);
     assert_status(status == 0, status, "mutex_unlock");
    // Paranoia to ensure our locked and lock-free paths interact
    // correctly with each other.
    OrderAccess::fence();
  }
  guarantee (_Event >= 0, "invariant") ;
}
```

可以看到，使用的也是`pthread_cond_wait`条件变量。

- [ ] #TODO tasktodo1719075504506 等后面把OS重新搞一遍之后，贴上Condition Variable的链接。 ➕ 2024-06-23 🔽 🆔 n4sihv



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