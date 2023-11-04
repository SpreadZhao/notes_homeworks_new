---
title: 3.2 重排序
chapter: "3"
order: "5"
---

### 3.2 重排序

现在终于开始讲重排序了！之前在祭祖的笔记里，其实就稍微提到过：[[Lecture Notes/Computer Structure/cs2#1.3 Pipeline Hazard|cs2]]。流水线需要冒险，而多线程并发同意也有，重排序就是冒险的一个大头。

#### 3.2.1 数据依赖

其实就是祭祖笔记里提到的Data Harzard。当数据之间存在依赖关系的时候，就不是那么好挪指令了：

![[Study Log/java_study/resources/Pasted image 20231104190014.png]]

按照之前所说的那种缓存模型，只要稍微调一下这种指令的执行顺序，那么结果就不一样了（在多线程中）。所以，像这种指令，你干脆就别排了。

#### 3.2.2 as-if-serial

这个东西的意思直接翻译过来就是：**就好像串行一样**。即使编译器和处理器对指令进行了重排序，你的<u>执行结果也不能改变</u>。

> - [i] *这里的结果指的是在单线程中结果不能改变，毕竟我们靠重排序也控制不了多线程。*

为了遵守这个语义，对于有数据依赖的操作，就不会重排序。但是如果不存在，那么就不好意思啦：

```java
double pi = 3.14;  // A
double r = 1.0;  // B
double area = pi * r * r; // C
```

C操作对A和B都有依赖，但是AB之间却没有。所以只要保证C是最后一个执行的就可以了。（卧槽？这个不是祭祖笔记里也说过吗：[[Lecture Notes/Computer Structure/cs2#^f151cf|cs2]]）

```ad-cor
现在回头看一看AB线程的那个例子：

| 线程 |        A        |        B        |
| ---- |:---------------:|:---------------:|
| 代码 | `a = 1; x = b;` | `b = 2; y = a;` |

这里A或者B的这两条也不存在数据依赖呀？只是两个线程之间存在而已。那么这个时候JMM也傻了，当成可以重排序的那种了。所以，我们要**手动让这个地方不能重排序**。
```

#### 3.2.3 程序顺序规则

上面那个算⚪面积的代码是单线程对吧！那么根据happens-before原则，每一句代码都比它后一句代码先发生，也就是：

* A happens-before B
* B happens-before C
* <mark style="border-style: dotted; background-color: transparent">A happens-before C</mark>

这里第三句是由前两句推导出来的。那么，既然A happens-before B，为什么AB又可以调换顺序呢？其实，JMM只需要：

```note-yellow
前一个操作执行的结果对后一个操作可见。
```

也就是说，无论是A happens-before B还是B happens-before A，结果都是一样的，那么JMM认为这种重排序并不是非法的，所以可以。

#### 3.2.4 重排序对多线程的影响

这部分在AB线程那个地方就已经开始涉及了，现在再来举一个例子：

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

一开始，如果一个线程执行reader方法，那么它是读不了的。只有在writer写过之后它才能读。那么，我让A线程先执行writer，B线程后执行reader，就成了吗？答案显然是否。

就和之前那个

| 线程 |        A        |        B        |
| ---- |:---------------:|:---------------:|
| 代码 | `a = 1; x = b;` | `b = 2; y = a;` |

一样，如果一重排序就完了。那么凭啥它会给你重排序呢？因为**没数据依赖**呀！在这个例子中，操作1和操作2不存在数据依赖；操作3和操作4也不存在。所以它可能给你排成这个样子：

![[Study Log/java_study/concurrency_art/resources/Pasted image 20231104214245.png|400]]

JMM认为：诶呀，你这个线程A里面的代码，两句之间没啥关系，给你重排吧！诶呀，你这个线程B里面两句代码也没啥关系，也给你重排吧！这么一搞，就炸了。这里A重排了，但是B没有，导致B读到的a是还没写入的a。

> 上图中的虚线表示错误/不存在的读操作，后面都是同理的。

而如果B重排了呢？在现实中是确实有这样的例子的，这里我们祭祖笔记还是讲过：[[Lecture Notes/Computer Structure/cs2#^5c1c35|cs2]]。在执行if之前，我们其实就可以提前去里面取值了。所以，可能会重排成这样子：

![[Study Log/java_study/concurrency_art/resources/Pasted image 20231104222240.png|500]]

> <small>在程序中，操作 3 和操作 4 存在控制依赖关系。当代码中存在控制依赖性时，会影响指令序列执行的并行度。为此，编译器和处理器会采用猜测（Speculation）执行来克服控制相关性对并行度的影响。以处理器的猜测执行为例，执行线程 B 的处理器可以提前读取并计算 a\*a，然后把计算结果临时保存到一个名为重排序缓冲（Reorder Buffer，ROB）的硬件缓存中。当操作 3 的条件判断为真时，就把该计算结果写入变量 i 中。</small>