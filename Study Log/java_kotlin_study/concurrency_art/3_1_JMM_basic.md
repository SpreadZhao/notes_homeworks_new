---
title: 3.1 Java内存模型的基础
chapter: "3"
order: "4"
---
### 3.1 Java内存模型的基础

并发编程有两个关键问题：

* 线程的**通信**；
* 线程的**同步**。

Java中，通信使用的方式就是共享内存。既然提到共享内存，那么就要看看Java是如何管理内存的。也就是JMM（**Java** Memory Model）。

首先，我们明确一些东西：

```ad-info
**线程之间共享的**：

**堆内存**里存的东西。都有啥呢？有实例域，静态域，数组元素。

---

**线程之间不共享的**：

局部变量、方法定义参数和异常处理器参数。
```

- [ ] #TODO 这些玩意儿都是什么东西？查一查。就共享和不共享那些。

#### 3.1.1 JMM

那么如何实现呢？看看JMM模型具体是什么：

![[Study Log/java_kotlin_study/resources/Pasted image 20231031231058.png]]

**每个线程都有个本地的内存，这里面存着主内存里共享变量的副本**。这个本地内存就是之前那篇文章：[为什么volatile能保证可见性？volitile为什么只能保证可见性-CSDN博客](https://blog.csdn.net/m0_37892106/article/details/97050278)里说的工作内存，大概是。

```ad-warning
注意，本地内存实际上不存在，只是一个抽象概念。它涵盖了缓存、写缓冲区、寄存器以及其他的硬件和编译器优化。
```

那么这样子，看看一个线程是怎么通知另一个线程的：

![[Study Log/java_kotlin_study/resources/Pasted image 20231031233508.png]]

这里，先假设三个内存中的x都是0。现在，A线程更新了，把x变成了1，那么之后，如果A要通知B“我的x已经更新啦！”就要这样做：

1. A线程把x的新值1写到主内存中；
2. B线程从主内存中读到新值1，并写到自己的本地内存中。

```ad-note
title: Summary

所以，我们可以总结，在这种模型下，两个线程通信的方式：

- 线程 A 把本地内存 A 中更新过的共享变量刷新到主内存中去。
- 线程 B 到主内存中去读取线程 A 之前已更新过的共享变量。
```

Java帮我们封装了这个内部的实现，所以在我们看来就是上面虚线箭头中的内容。而实际上在通信的内部已经进行了这种对内存的读写过程。这个通信必须经过主内存，**JMM通过控制==主内存==与每个线程的==本地内存==之间的交互，来为Java程序员提供==内存可见性==保证**。

#### 3.1.2 重排序简介

接下来，看看指令重排序的问题。这里只是稍微提一下，后面会详细介绍。重排序主要分成3种：

1. **编译器优化**重排序：编译的时候，在**不改变单线程程序语义**的前提下，重新安排代码的执行顺序；
2. **指令级并行**的重排序：指令级并行我感觉就是CPU的那个流水线技术，可以让多条指令交错执行，就是取指译码执行写回那种，让多个人一块干：[[Lecture Notes/Computer Structure/cs2#1. Pipe Line|cs2]]；
3. **内存系统**重排序：主要是对IO操作的优化。你想想，CPU有Cache，然后做IO操作的时候还有buffer这样的概念，那么有了这些东西，处理某些指令的时候就可以乱序执行了。因为有缓存兜着，没必要时时刻刻为了保持顺序而放弃性能。

从Java源代码到最终执行，重排序大概的顺序是这样的：

![[Study Log/java_kotlin_study/resources/Pasted image 20231104002137.png]]

这些重排序会产生什么问题呢？我们来举个例子。现在有两个线程A和B，分别执行这样的代码：

| 线程 |        A        |        B        |
| ---- |:---------------:|:---------------:|
| 代码 | `a = 1; x = b;` | `b = 2; y = a;` |

```ad-info
假设a, b的初值为0。
```

用我们以往的方式思考，假设A先执行，B后执行。那么x先变成b，也就是0，然后y变成a，也就是1，所以最后的结果是`x = 0, y = 1`；

假设B先执行，A后执行，同理，最后`x = 2, y = 0`。

然而，以上的这些结果都是建立在顺序执行的条件下的，如果考虑**指令重排序**的话，会有非常出乎意料的结果，比如，**x和y最后都是0**？？？

我们先来理一理这两个线程做的事情。A线程和B线程首先试图对自己的变量a和b赋值，然后由分别试图获取对方的变量：A想要B的b，而B想要A的a。要到了之后，再分别赋值给自己的x和y。

那么，考虑到之前的JMM模型，我们能想到，a和b其实是分别保存在自己的本地内存中。而我们刚刚也提到过，在做IO操作的时候，会用到Cache之类的，也就是写缓冲区。所以实际上a和b是分别保存在这两个线程的写缓冲区里的：

![[Study Log/java_kotlin_study/resources/Drawing 2023-11-04 17.46.54.excalidraw.png]]

那么这样你其实也能看出来，当A线程和B线程要更改a和b的值的时候，就涉及到很多小的步骤。拿A线程来举例子：

1. A线程在BufferA中把a的值**更新**；
2. 将BufferA的新的a值**同步**到主存中；

这样的话，A线程如果想读取b的值，就只能从主存中读。我们将这些操作标个号：

![[Study Log/java_kotlin_study/resources/Drawing 2023-11-04 17.53.32.excalidraw.png]]

如果这些任务实际执行的顺序是：

$$
1 \rightarrow 3 \rightarrow 4 \rightarrow 6 \rightarrow 2 \rightarrow 5
$$

那么最终x和y就都是0了。

```ad-question
你可能会问，为啥可以是3 2，不严格按照2 3来。这就是重排序的原理所在啊！你想想，对于一个线程来说，我其实并不关心其它线程对数据的操作是怎样的。因此，我这个a可以更新也可以不更新，因为**反正我之后要读取的是b而不是a，所以2和3哪个先执行对于我这个线程是不要紧的**。
```

像我们上面的操作，先存一个值（a和b），再读取一个值的操作，叫做**Store-Load**操作。而对于大多数处理器，Store-Load操作都是允许重排序的：

![[Study Log/java_kotlin_study/resources/Pasted image 20231104180430.png]]

那么按着上面的例子，对于A线程或者B线程来说，它做的操作就是：

```
Store1
Load2
```

上面的表格中展示出来的指令，都是有可见性的问题的。为了解决，Java编译器在生成指令序列的时候，就会在中间插入一个内存屏障。比如Store-Load指令的内存屏障就叫做StoreLoad。那么这个时候编译出来的指令序列就变成了这样：

```
Store1
StoreLoad
Load2
```

这样，StoreLoad就会保证，在Store1执行完成之前，**所有的Store指令和Load指令都不能执行**。也就不会出现之前说的那种都为0的问题了。

这样的指令，一共有4种：

![[Study Log/java_kotlin_study/resources/Pasted image 20231104183013.png]]

> <small>StoreLoad Barriers 是一个“全能型”的屏障，<mark style="background-color:orange"><font color="black">它同时具有其他 3 个屏障的效果</font></mark>。现代的多处理器大多支持该屏障（其他类型的屏障不一定被所有处理器支持）。执行该屏障开销会很昂贵，因为当前处理器通常要把写缓冲区中的数据全部刷新到内存中（BufferFully Flush）。</smalll>

#### 3.1.3 happens-before

这个东西来源于JDK1.5开始使用的新内存模型JSR-133。其实很好理解，==A happens-before B==就是必须A先发生完，B才能发生。

有了这个概念，我们来说几个比较重要的happens-before规则：

* **顺序执行的程序**：一个线程中的每个操作==happens-before==该线程中任意后续操作；
* **Monitor锁规则**：对于一个锁的解锁，==happens-before==对它的加锁；
* **volatile**：对一个volatile的写，==happens-before==任意之后对它的读；
* **传递性**：如果A happens-before B，B happens-before C，那么A happens-before C。

```ad-cor
你可能会问，为什么要不说人话。比如volatile，我直接“先写后读”就行了呗！实际上，**还真不一定是先写后读**！

两个操作之间具有 happens-before 关系，***==并不意味着前一个操作必须要在后一个操作之前执行==***！happens-before 仅仅要求前一个操作（执行的结果）对后一个操作可见，且前一个操作按顺序排在第二个操作之前（the first is visible to and ordered before thesecond）。happens-before 的定义很微妙，后文会具体说明 happens-before 为什么要这么定义。

为什么呢？看这里：[[Study Log/java_kotlin_study/concurrency_art/3_2_reorder#3.2.3 程序顺序规则|3_2_reorder]]
```

happens-before是直接提供给程序员看的，也就是说，程序员用的就是happens-before规则，而这个规则具体的实现就来自JMM，也包括上面说的什么StoreLoad这种屏障指令（大概包括）。

![[Study Log/java_kotlin_study/resources/Pasted image 20231104185527.png|550]]

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