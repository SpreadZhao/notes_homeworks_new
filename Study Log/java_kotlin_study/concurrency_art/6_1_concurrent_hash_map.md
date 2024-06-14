---
title: 6.1 ConcurrentHashMap的原理与使用
chapter: "6"
order: "1"
---

## 6.1 ConcurrentHashMap的原理与使用

> [!attention]
> 本节使用jdk1.7版本。后续要更新接下来的jdk对于ConcurrentHashMap的升级。
> 
> - [ ] #TODO tasktodo1718346387211 升级ConcurrentHashMap。 ➕ 2024-06-14 🔼 

### 6.1.1 为什么用ConcurrentHashMap

#### 6.1.1.1 HashMap在多线程的缺陷

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
> 以上代码只有在jdk1.7以前才会出问题：[[Study Log/java_kotlin_study/java_kotlin_study_diary/hash_map#JDK 1.7 中的 HashMap|hash_map]]。这里我特地自己搞了一下。确实使用java8以及以后的版本，就不会有死循环的问题了。
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

#### 6.1.1.2 HashTable的低效

另外还有HashTable。它可以处理多线程访问的情况，但是效率太低了。我们来看看HashTable的注释是怎么说的：

> Unlike the new collection implementations, `Hashtable` is synchronized.  If a thread-safe implementation is not needed, it is recommended to use `HashMap` in place of `Hashtable`.  If a thread-safe highly-concurrent implementation is desired, then it is recommended to use `ConcurrentHashMap` in place of `Hashtable`.

这段注释强调了2点：

- 如果你根本用不到并发场景，那用HashMap，别用HashTable；
- 如果你需要**高**并发场景，那用ConcurrentHashMap，也别用HashTable。

主要的原因注释里也说了，因为它是synchronized。HashTable的get和set方法都是用synchronized修饰的，这意味着两个线程无论是读还是写，都会竞争同一把锁。甚至两个线程不能同时读，这就有点不太行了。

另外，据我观察，jdk1.7的HashTable和jdk17的HashTable的代码几乎就没啥区别，所以我们也能猜测出来官方本身就已经属于是半放弃这个类了。

#### 6.1.1.3 ConcurrentHashMap的优势

CHM高效就在它的数据不是一把锁干死的，是分段的。CHM里面的数据被分成若干段，每一段用一个锁给锁起来。这样多个线程大概率会访问到不同的段，也就能很大程度上提高并发效率。

### 6.1.2 ConcurrentHashMap的结构

简单的结构如下：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-06-14 13.58.48.excalidraw.svg]]

主要的数据都存在segments里。里面的每个元素是一个Segment，也就是我们提到过的一段。而这一段我们可以看成一个小小的HashMap（实际上是HashTable），因为这一段里面依然有一个完整的链表数组。数组的每一个entry是一个HashEntry。

CHM构造的时候，无论你怎么调用，最后都会走到统一的构造方法。如果你有一些参数没传，那么就会用默认的。下面是这些参数的说明：

- `initialCapacity`：初始容量，这个参数用来创建segments数组中的第一个Segment，也就是和`segment[0]`内部的链表数组的大小有关；
- `loadFactor`：这个东西HashMap和HashTable都有，是用来控制扩容的。参考[[Study Log/java_kotlin_study/java_kotlin_study_diary/hash_map|hash_map]]，如果数组大到一定程度，hash碰撞的概率就会增加。所以需要进行扩容，才能进一步减少hash碰撞的概率；
- `concurrencyLevel`：这个东西主要是为了应付并发。它有多大主要看会修改CHM的线程有多少个，也就是并发量。并发量越高，那么这个level也就越大。

下面我们来介绍CHM初始化的时候会初始化的其他东西。

#### 6.1.2.1 segments数组

显然，这里面的segments就是最重要的数据+锁，所以它也是初始化的核心。所以我们来看看它是怎么构造出来的。主要就和刚刚的`concurrencyLevel`参数有关，因为之所以segments是个数组，就是为了多线程访问不同的Segment。而并发量越大，那么segments肯定就要越长，才能容纳这么多线程去访问。

下面是经过精简的，CHM的构造方法的最深层版本：

```java
public ConcurrentHashMap(int initialCapacity, float loadFactor, int concurrencyLevel) {
	... ...
	if (concurrencyLevel > MAX_SEGMENTS)
		concurrencyLevel = MAX_SEGMENTS;
	// Find power-of-two sizes best matching arguments
	int sshift = 0;
	int ssize = 1;
	while (ssize < concurrencyLevel) {
		++sshift;
		ssize <<= 1;
	}
	this.segmentShift = 32 - sshift;
	this.segmentMask = ssize - 1;
	... ...
	Segment<K,V>[] ss = (Segment<K,V>[])new Segment[ssize];
	... ...
	this.segments = ss;
}
```

可以看到，最终的segments的大小是ssize，而这个变量的计算就是依赖于concurrencyLevel。但是我们需要注意的是，ssize并不是每次+1的，而是`<<= 1`。所以，实际上相当于`ssize *= 2`。

我们假设concurrencyLevel是15。那么while循环会走4次，退出循环后ssize为16，正好是**大于等于concurrencyLevel的2的整数次方**。这也就是注释中说的`power-of-two sizes best matching arguments`。如果有15个线程需要访问这个HashMap，那么segments的长度就应该是16。这样既能有足够大的并发量，同时由于正好是2的整数次方，所以也能满足按位与的hash散列算法来定位对应的Segment（关于这个算法，我们之后会详细介绍）。



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