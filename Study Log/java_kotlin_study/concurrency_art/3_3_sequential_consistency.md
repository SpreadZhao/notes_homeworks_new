---
title: 3.3 顺序一致性
chapter: "3"
order: "6"
---
## 3.3 顺序一致性

现在假设，有个变量x，初始值为0。然后有100个线程，每个线程所做的事情就是将这个变量+1。看起来很简单，但是每个线程需要做的事情却不少：

* 读出原来的x值；
* 在此基础上+1；
* 把新值写回去。

显然，如果七手八脚地进行读取，最后的结果肯定是很艹蛋的。就拿两个线程举例子，它俩同时读了x，发现都是0，所以这俩线程都把x更新成了1，最后还是1。但是按照我们的期望，它应该变成2才对。

### 3.3.1 数据竞争与顺序一致性

如果，刚才那个例子，多少个线程操作之后，x就增加多少，就意味着**即使是多线程并发的执行状态下，和顺序执行的结果也一样**。这样的性质就叫做**顺序一致性**。

实际上，顺序一致性的起源是**顺序一致性内存模型**。太高深，先不鸟它。

然后，你作为一个多线程并发的模型，所有线程都等着抢数据，又怎么可能平白无故就能具有顺序一致性呢？因此，在这个过程中，线程之间必然发生**数据竞争**。Java内存模型规范对数据竞争的定义如下：

* 在一个线程中写一个变量；
* 在另一个线程中读这个变量；
* 而且写和读没有通过同步操作来排序。

所以，我们想消除数据竞争，就要同步。而**同步的过程，就是对syncronized, volatile, final的正确使用**。

### 3.3.2 顺序一致性内存模型

好吧，还是得提。**实际上JMM不是这样的内存模型**。假设有两个线程A和B，它们的操作分别是：

- [F] A线程：

```java
a++ // A1
b++ // A2
c++ // A3
```

---

- [F] B线程：

```java
a-- // B1
b-- // B2
c-- // B3
```

那么我们现在让这两个线程跑起来，不做任何限制，那么显然，啥都有可能。甚至，因为对于单个线程来说，这些语句之间也不存在数据依赖，所以可以想怎么重排序就怎么重排序。

因此，最后的执行顺序可能是

$$
A_2 \rightarrow B_1 \rightarrow A_3 \rightarrow B_3 \rightarrow A_1 \rightarrow B_2
$$

看起来乱七八糟对吧。乱就对了！这就是不加约束的后果。谁知道CPU为了提高性能会给我们的代码搞成什么样子呢。。。

另一个情况是，假设我们的B2操作会用到A1操作的结果，也就是B2操作必须在A1之后才能执行。但是，在这种并发状态下，好像根本不行呀！你都重排序了，而且，**B2也没有任何手段能够知道A1操作结束了**。因为现在还没有搭建通信的媒介，A1结束之后也没发什么广播之类的通知给大家。

因此，顺序一致性内存模型诞生了！它就是为了解决这些问题的内存模型。在这个模型下，并发的执行是有限制的：

1. 一个线程中的所有操作必须按照**程序的顺序**来执行。
2. （不管程序是否同步）所有线程都只能看到一个单一的操作执行顺序。在顺序一致性内存模型中，**每个操作都必须原子执行且立刻==对所有线程可见==**。

第一点就是说，你**单线程里就别重排序啦**；第二点在说，任何线程的任何操作执行完之后，都必须让所有线程可见。举个例子：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231109232551.png]]

这是**我们采用了同步之后**的结果，让A线程所有操作都执行完才让B开始。这个执行顺序，AB线程都是能看到的。

另外，在顺序一致性内存中，我们也可以不同步，虽然不同步，但是也要符合上面的两点要求。比如：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231109232729.png]]

看到没，单独拆出来，A1就是在A2前面，A2就是在A3前面。B也是同理。也就是不允许你给单线程里重排序；同时，即使这个顺序看起来比较乱，**但也是有序的，且AB线程都能看到**。

以上说的这些，Java统统没有。。。为啥没有还要说呢？这其实算是一个标准。如果我们自己写的并发控制能达到顺序一致性内存的水平，那么就代表这个并发写的是OK的。

### 3.3.3 同步程序的顺序一致性效果

改造一下之前那个读和写的代码：

```java
class ReorderExample {
	int a = 0;
	boolean flag = false;

	public void writer() {
		a = 1;  // 1
		flag = true;  // 2
	}

	public void reader() {
		if (flag) {  // 3
			int i = a * a;  // 4
			... ...
		}
	}
}
```

怎么改，能合理？首先，这玩意儿还没跑起来呢，我先写个能跑的。。。

```kotlin
class ReorderExample {
  var a = 1
  var flag = false
  fun writer() {
    a = 3
    Thread.sleep(1) // 稍加干扰，就读不了了。
    flag = true
  }
  fun reader() {
    if (flag) {
      val i = a * a
      println("i: $i")
    } else {
      println("I can't read it!")
    }
  }
  companion object {
    fun test() {
      val example = ReorderExample()
      thread { example.writer() }
      thread { example.reader() }
    }
  }
}
```

如果你真写上去，还真能读到值。但是这是因为writer()执行得太快了。只要你稍微加个休息的操作，就读不到了。那么，如何修改呢？很简单！加两个syncronized就成了！

```kotlin
class ReorderExample {
  var a = 1
  var flag = false
  @Synchronized
  fun writer() {
    a = 3
    Thread.sleep(10000)
    flag = true
  }
  @Synchronized
  fun reader() {
    if (flag) {
      val i = a * a
      println("i: $i")
    } else {
      println("I can't read it!")
    }
  }
  companion object {
    fun test() {
      val example = ReorderExample()
      thread { example.writer() } // Thread A
      thread { example.reader() } // Thread B
    }
  }
}
```

这样，你想怎么休息就怎么休息。只要A线程先获得锁，你B就得在那儿等着。还记得之前说的吗：[[Study Log/java_kotlin_study/concurrency_art/2_concurrency_internal#2.2 syncronized|2_concurrency_internal]]？syncronized修饰方法的时候，锁是当前实例的。也就是说，在上面的例子中，锁就是`example`这个实例。

下面，有一个问题：

- [?] *你加了这两个syncronized之后，真的就和内存一致性模型一样了吗？*

答案是否定的。syncronized只是一把锁，它没办法控制指令真正的执行顺序。所以，能重排序的地方。它还是会重排序的。毕竟为了性能嘛！但是，我们要好好想一想：*它在哪里重排序的呢*？

答案也很简单：只要不是被syncronized限制的地方，都会重排序：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231119140506.png]]

上图是我们的Java/Kotlin并发程序的运行过程与真正的顺序一致性模型中执行的情况的对比。可以发现，在syncronized代码块里面的语句其实是可以重排序的，但是它**不允许临界区内的代码逃逸到syncronized的外面**。虽然A线程做了重排序，但是B也无法观察到A的重排序，因为syncronized本身就是互斥的。所以，这种方法既提高了执行效率，又没有改变程序的执行结果。 ^0578f5

### 3.3.4 JMM vs 内存一致性模型

| 内存一致性模型                       | JMM                              |
| ------------------------------------ | -------------------------------- |
| 单线程内顺序执行                     | 不保证单线程内顺序执行（重排序） |
| 所有线程看到的执行顺序一致           | 不保证所有线程看到的执行顺序一致 |
| 保证对所有内存的读写操作都具有原子性 | 不保证对64位的long和double的写操作具有原子性                                 |

> 这里的第三条可以参考原文

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