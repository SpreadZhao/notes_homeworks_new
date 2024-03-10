---
title: 5.1 Lock接口
chapter: "5"
order: "1"
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