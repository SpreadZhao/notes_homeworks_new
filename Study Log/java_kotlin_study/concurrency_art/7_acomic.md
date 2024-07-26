---
title: 7 Java 中的13个原子操作类
chapter: "7"
order: "7"
chapter_root: true
---

# 7 Java中的13个原子操作类

回想我们之前提到的不安全的问题：[[Study Log/java_kotlin_study/concurrency_art/2_concurrency_internal#2.3.2 Java如何实现原子操作（CAS）|2_concurrency_internal]]。里面提到了CAS。CAS就是Java实现原子操作的方法。而主要的内容都在这个[[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240721163642.png|java.util.concurrent.atomic]]包里。现在我们就来讨论一下它。**Atomic包里的类基本都是使用 Unsafe 实现的包装类**。

根据数据类型的不同，分为：

- 基本类型；
- 数组；
- 引用；
- 字段。

基本类型提供了三个类：

- AcomicBoolean：更新布尔类型；
- AtomicInteger：更新整型；
- AtomicLong：更新长整型。

你会问为啥没有float，double，char之类的。这个我们稍后会说。

我们以AtomicInteger为例进行讲解。

- `int addAndGet(int delta)`：相加并返回；
- `boolean compareAndSet(int expect, int update)`：如果现在这个数字的值就是expect，那么把它更新成update；
- `int getAndIncrement()`：原子+1，返回**自增前**的值。和它相对的方法我们也用过：[[Study Log/java_kotlin_study/concurrency_art/2_concurrency_internal#^eec176|2_concurrency_internal]]；
- `void lazySet(int newValue)`：最终会设置成 newValue，使用 lazySet 设置值后，可能导致其他线程在之后的一小段时间内还是可以读到旧的值。[How does AtomicLong.lazySet work? - Quora](https://www.quora.com/Java-programming-language/How-does-AtomicLong-lazySet-work)
- `int getAndSet(int newValue)`：设置成新值，返回旧值。

我们介绍最常用的`getAndIncrement()`方法的实现。一个具体的使用例子：

```kotlin
private val ai = AtomicInteger(1)

fun main() {
    println(ai.getAndIncrement())
    println(ai.get())
}
```

输出应该是：

```
1
2
```

下面分析一下实现。

> [!attention]
> 以下jdk版本：[openjdk/jdk at jdk7-b147](https://github.com/openjdk/jdk/tree/jdk7-b147)

- [ ] #TODO tasktodo1721551908986 之后 补上jdk8及以后做了什么改动。 ➕ 2024-07-21 🔽 

```java
/**
 * Atomically increments by one the current value.
 *
 * @return the previous value
 */
public final int getAndIncrement() {
	for (;;) {
		int current = get();
		int next = current + 1;
		if (compareAndSet(current, next))
			return current;
	}
}
```

还记得我们之前说过的那句话吗：[[Study Log/java_kotlin_study/concurrency_art/2_concurrency_internal#^3b7d16|2_concurrency_internal]]。对比一下我们之前自己的实现：

```kotlin
private fun safeCount() {  
	while (true) {  
		var i = atomicInteger.get()  
		val success = atomicInteger.compareAndSet(i, ++i)  
		if (success) break  
	}  
}
```

可以发现基本上就是一样的。所以这里的本质上其实还是循环CAS。我们在很多地方都提到过循环CAS。

- [ ] #TODO tasktodo1721552351449 贴链接，循环CAS。 ➕ 2024-07-21 ⏫ 🆔 hdcwzi

继续去深究Unsafe的实现。我们能发现底层只提供了三个方法：

```java
public final boolean compareAndSwapObject(Object o, long offset,
										  Object expected,
										  Object x)

public final boolean compareAndSwapInt(Object o, long offset,
									   int expected,
									   int x)

public final boolean compareAndSwapLong(Object o, long offset,
										long expected,
										long x)
```

对于其它的类型，比如Boolean，通过AtomicBoolean里的实现看，其实就是先转换成integer，然后走里面整型的这一套；而对于浮点类型，可以看这个提问：[concurrency - Java: is there no AtomicFloat or AtomicDouble? - Stack Overflow](https://stackoverflow.com/questions/5505460/java-is-there-no-atomicfloat-or-atomicdouble)。其实就是将float或者double按找bit转成integer，用一样的操作。

- [ ] #TODO tasktodo1721552892050 可以继续跟踪native的实现。 ➕ 2024-07-21 🔽 🆔 ikuzbv

对于其它的类型，书上有。其实都没啥，接口都差不多。所以这里自己多用一用就明白了，不讲了。

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