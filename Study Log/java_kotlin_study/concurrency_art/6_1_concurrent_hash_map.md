---
title: 6.1 ConcurrentHashMap的原理与使用
chapter: "6"
order: "1"
---

## 6.1 ConcurrentHashMap的原理与使用

在并发编程中使用 HashMap 可能导致程序死循环。而使用线程安全的 HashTable 效率又非常低下，基于以上两个原因，便有了 ConcurrentHashMap 的登场机会。

在多线程环境下，使用 HashMap 进行 put 操作会引起死循环，导致 CPU 利用率接近100%，所以在并发情况下不能使用 HashMap。例如，执行以下代码会引起死循环：

```java
public static void main(String[] args) throws InterruptedException {
	final HashMap<String, String> map = new HashMap<>(2);
	Thread t = new Thread(new Runnable() {
		@Override
		public void run() {
			for (int i = 0; i < 10000; i++) {
				new Thread(new Runnable() {
					@Override
					public void run() {
						map.put(UUID.randomUUID().toString(), "");
					}
				}, "ftf" + i).start();
			}
		}
	}, "ftf");
	t.start();
	t.join();
}
```

> [!attention]
> 以上代码只有在jdk1.7以前才会出问题：[java - 11张图让你彻底明白jdk1.7 hashmap的死循环是如何产生的 - 个人文章 - SegmentFault 思否](https://segmentfault.com/a/1190000024510131)。这里我特地自己搞了一下。确实使用java8以及以后的版本，就不会有死循环的问题了。
> 
> 这里给出编译和执行的过程：
> 
> ```shell
> # 编译
> /usr/lib/jvm/java-7-j9/bin/javac UnsafehashMap.java
> # 执行
> /usr/lib/jvm/java-7-j9/bin/java UnsafehashMap
> ```
> 
> 注意包名不能写，不然搞的很麻烦。所以这个类就不参与主工程了。




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