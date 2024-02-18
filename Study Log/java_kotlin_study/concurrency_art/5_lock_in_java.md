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