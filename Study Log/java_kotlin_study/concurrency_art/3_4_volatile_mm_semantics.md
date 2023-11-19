---
title: 3.4 volatile内存语义
chapter: "3"
order: "7"
---

## 3.4 volatile的内存语义

### 3.4.1 volatile特性

接下来我写一个代码。这个代码在之前也写过类似的：[[Study Log/java_kotlin_study/concurrency_art/2_concurrency_internal#2.3.2 Java如何实现原子操作（CAS）|2_concurrency_internal]]。其实就是多个线程去增加一个数字的操作：

```kotlin
package concurrency

import kotlin.concurrent.thread

class VolatileExample {

  private var _integer = 0

  val integer: Int
    get() = _integer

  fun increment() {
    _integer++
  }

  companion object {
    fun test() {
      val volatileExample = VolatileExample()
      // 所有的线程
      val threads = arrayListOf<Thread>()
      // 创建100个线程，每个线程累加100次integer
      repeat(100) {
        val t = Thread {
          repeat(100) { volatileExample.increment() }
          println("thread${it} result: ${volatileExample.integer}")
        }
        threads.add(t)
      }
      // 开始所有线程
      threads.forEach { it.start() }
      // 等待所有线程结束
      threads.forEach {
        try {
          it.join()
        } catch (e: InterruptedException) {
          e.printStackTrace()
        }
      }
      // 输出最终的结果
      println("final result: ${volatileExample.integer}")
    }
  }

}
```

这里我一开始使用的是两个线程来模拟。但是发现，两个线程并不会暴露出这个问题。因为CPU实在是太快了。所以我搞了100个线程，每个线程都累加100次integer。理想的情况下，最终的答案应该是10000，但显然不会是的：

```
thread0 result: 100
thread5 result: 300
thread3 result: 400
thread8 result: 500
thread1 result: 200
thread9 result: 600
thread11 result: 700
thread12 result: 800
thread4 result: 900
thread2 result: 1000
thread6 result: 1100
thread7 result: 1200
thread13 result: 1300
thread14 result: 1400
thread10 result: 1500
thread15 result: 1600
thread20 result: 1700
thread21 result: 1800
thread22 result: 1900
thread19 result: 2000
thread16 result: 2100
thread17 result: 2200
thread28 result: 2300
thread23 result: 2400
thread24 result: 2500
thread25 result: 2600
thread27 result: 2800
thread26 result: 2800
thread18 result: 2900
thread29 result: 3000
thread30 result: 3100
thread35 result: 3200
thread32 result: 3300
thread38 result: 3400
thread34 result: 3500
thread31 result: 3600
thread36 result: 3700
thread37 result: 3800
thread39 result: 3900
thread33 result: 4000
thread40 result: 4100
thread41 result: 4200
thread42 result: 4300
thread44 result: 4400
thread43 result: 4500
thread77 result: 7000
thread71 result: 7100
thread67 result: 7675
thread76 result: 7914
thread58 result: 7975
thread63 result: 7975
thread66 result: 7975
thread49 result: 7000
thread48 result: 7000
thread81 result: 8175
thread47 result: 7000
thread46 result: 7000
thread45 result: 7000
thread83 result: 8375
thread82 result: 8275
thread84 result: 8475
thread80 result: 8175
thread68 result: 7975
thread69 result: 7975
thread85 result: 8575
thread86 result: 8675
thread65 result: 7975
thread64 result: 7975
thread88 result: 8875
thread60 result: 7975
thread75 result: 7975
thread91 result: 9075
thread59 result: 7975
thread61 result: 7975
thread94 result: 9275
thread79 result: 7975
thread62 result: 7699
thread92 result: 9475
thread95 result: 9575
thread57 result: 7675
thread56 result: 7675
thread97 result: 9775
thread72 result: 7675
thread51 result: 7675
thread78 result: 7591
thread73 result: 7200
thread52 result: 7496
thread70 result: 7509
thread50 result: 7000
thread53 result: 7200
thread74 result: 7300
thread55 result: 7400
thread54 result: 7200
thread99 result: 9975
thread98 result: 9875
thread96 result: 9675
thread93 result: 9375
thread90 result: 9175
thread89 result: 8975
thread87 result: 8775
final result: 9975
```

这是我随便执行一次的结果。显然每次执行的结果也都是不一样的。那么，如何让执行结果就是10000呢？之前我们是怎么做的？CAS！但是现在，我们用volatile来试一试：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231119150520.png|300]]

仅仅是在integer上面加一个volatile，我们再试一试。emm，结果是，有的时候是10000，有的时候又不是。那么这就意味着，volatile起作用了，但没有完全起作用。那么，到底是什么问题呢？

另外，我们把这个volatile去掉，然后在increment()方法上加上syncronized：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231119151046.png|300]]

这下不管你怎么执行，最后的结果都是10000了。这个操作其实好理解：因为100个线程在执行这个方法的时候，都要获得锁，而竞争的锁是同一把，也就是对象volatileExample。自然就不会出现那样的问题。

但是为什么volatile没有完全解决这个问题呢？在第二章中（[[Study Log/java_kotlin_study/concurrency_art/2_concurrency_internal|2_concurrency_internal]]），我们已经介绍过volatile的一些特性。比如它是怎么增加那个lock指令的，那个指令又有什么用；在第三章中（[[Study Log/java_kotlin_study/concurrency_art/3_1_JMM_basic#3.1.3 happens-before|3.1.3 happens-before]]），我们又介绍了一些happens-before规则，其中就提到了volatile的这个规则：

```note-imp
对一个volatile的写，happens-before任意之后对它的读。
```

一定要注意，这里说的仅仅是“写”和“读”！！！而你想一想，`integer++`这样的指令，真的仅仅是写和读吗？

我们将这个指令翻译出来，大概是这样的：

```kotlin
var temp = get()
temp += 1
set(temp)
```

对吧！其实`integer++`这样的指令，是拿到原始的值，然后在上面加上1，然后再写回到原来的变量里。那么，这里真的只是写和读吗？一眼就看出来了吧！

```kotlin
var temp = get() // 读
temp += 1 // What's this???
set(temp) // 写
```

我们可以再进一步猜测一下，为什么volatile能保证那个happens-before规则。既然读和写可以满足这种规则，是不是就是说，**它给这两个操作做了同步的呀**！！！

换句话来说，**就是上面的get()方法和set()方法，其实是syncronized修饰的**！按照这个猜测，如果我们有一个volatile的变量：

```kotlin
class VolatileExample {
	@Volatile
	private var integer
}
```

**给这个变量加上volatile，其实就等价于：**

> [!stickies]
> 
> <bold>这是我们这一章最重要的东西！！！</bold>

```kotlin
class VolatileExample {
	private var integer

	@Syncronized
	fun get() = integer

	@Syncronized
	fun set(i: Int) {
		integer = i
	}
}
```

因为太重要了，这里我再给出书上的Java版本：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231119163747.png]]

我们刚刚写的那个increment()方法，如果加了volatile，就会被翻译成上图的getAndIncrement()方法。volatile因为只对读写做了同步，因此，这种++的操作并不会进行同步。所以下面三个操作就会被多个线程来乱序执行：

```kotlin
var temp = get()
temp += 1
set(temp)
```

```ad-hint
这也是为什么CAS能做到这一点的原因。因为CAS自带的incrementAndGet()方法本身就是**对这三步操作整体的同步**。
```

也正是因为volatile对读写做了同步，我们才说volatile具有以下特性：

* **可见性**：对一个volatile变量的读，总是能看到（任意线程）对这个volatile变量最后的写入；
* **原子性**：对任意单个volatile变量的**读/写**具有原子性，但类似于volatile++这种复合操作不具有原子性。

### 3.4.2 volatile的内存语义

现在我们来说之前的另一个例子：[[Study Log/java_kotlin_study/concurrency_art/3_3_sequential_consistency#3.3.3 同步程序的顺序一致性效果|3.3.3 同步程序的顺序一致性效果]]

这个例子可以用volatile来解决吗？

```kotlin
class VolatileExample2 {
  var a = 1

  @Volatile
  var flag = false

  fun writer() {
    a = 3
    Thread.sleep(3000)
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
      val example = VolatileExample2()
      thread { example.writer() }
      thread { example.reader() }
    }
  }
}
```

我们仅仅给flag变量加上volatile就能成功吗？根据我们之前的推论，答案显然是不可以。因为volatile只能保证读和写flag变量是同步的，并不能保证writer()先于reader()执行。

- [?] 那么，volatile在这个地方到底起了什么作用？回答这个问题之前，我们首先回答一个问题：*之前那个两个syncronized的版本，真的就能保证一定正确吗*？

- [I] **以下的介绍统统说的是两个syncronized版本，而volatile的版本会在之后介绍。**

按照调用顺序来讲，确实几乎可以保证writer()方法在reader()方法之前执行。但是，我们需要看看这个syncronized的边界：

在writer()方法中，边界是`flag = true`这句话。意思就是将这个变量改为true，并写回到内存中。根据之前我们讲过的内存模型（[[Study Log/java_kotlin_study/concurrency_art/3_1_JMM_basic#3.1.1 JMM|3.1.1 JMM]]），我们能知道，这句话实际上包含了两步操作：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2023-11-19 17.07.15.excalidraw.png]]

而根据之前所说（[[Study Log/java_kotlin_study/concurrency_art/3_3_sequential_consistency#^0578f5|3_3_sequential_consistency]]），这两步操作是**无法逃逸到syncronized外面**的。所以，在线程B执行reader()之前，内存的模型**一定**是下面的情况：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2023-11-19 17.12.19.excalidraw.png]]

那么接下来线程B执行的时候，就不会有任何问题了：**它一定会读到flag为true，从而成功获取到新的a的值**。所以，上面的答案实际上是：正确的。

---

现在把目光转回到volatile的版本上，会有什么问题呢？volatile虽然没能保证这个执行顺序一样，但是又保证了什么呢？现在回想一下之前我们对于volatile本质的介绍：[[Study Log/java_kotlin_study/concurrency_art/2_concurrency_internal#^35e1b7|2_concurrency_internal]] 和 [[Study Log/java_kotlin_study/concurrency_art/2_concurrency_internal#^ce42bc|2_concurrency_internal]]

也就是说，这个值在**写**的时候，会将所有缓存都更新，将本线程的本地内存也更新，并最终将这个更新也同步到主内存中。

那么，读的时候呢？如果试图读一个volatile变量，又会做出什么判断呢？继续回想之前所说：[[Study Log/java_kotlin_study/concurrency_art/2_concurrency_internal#^a73a5c|2_concurrency_internal]] 和 [[Study Log/java_kotlin_study/concurrency_art/2_concurrency_internal#^cd709e|2_concurrency_internal]]

之前所埋下的伏笔，终于在此揭开。当线程试图**读**一个volatile变量时，所作的第一件事，就是让自己本地内存中的那个变量无效：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2023-11-19 17.34.18.excalidraw.png]]

所以，volatile真正保证的事情其实是：**你至少得让我读到一个之前线程更新过的新值吧**！

虽然之前可能没有线程更新过，虽然我读到的依旧可能是错误的值。但是我却是在主存中去读的，而这就代表着，我读到过的，至少也不是我本地内存中的值，而是一个可能被其它线程写入过的值，**因为volatile的写最终就是会到主存里去呀**！

实际上，这个flag的例子举得并不是很恰当，它没法很直观地体现出volatile的作用。但是我也尽量解释到完美了。

- [ ] #TODO #urgency/high 如果之后有一个完美的volatile的使用例子，我会贴在这里。

```ad-summary
title: 做一个总结

首先，是volatile到底能做到什么事情：

1. 写的时候，一股脑儿从Cache到本地内存到主存一条龙刷新，并且这个过程是原子的（也就是对单个变量**写操作的原子性**）；
2. 读的时候，让本地内存直接无效，就是要从主存中去读（也就是**读的原子性plus版**）。

然后，就是volatile的内存语义的总结：

* 线程 A 写一个 volatile 变量，实质上是线程 A 向接下来将要读这个 volatile 变量的某个线程发出了（其对共享变量所做修改的）消息。
* 线程 B 读一个 volatile 变量，实质上是线程 B 接收了之前某个线程发出的（在写这个 volatile 变量之前对共享变量所做修改的）消息。
* 线程 A 写一个 volatile 变量，随后线程 B 读这个 volatile 变量，这个过程实质上是线程 A 通过主内存向线程 B 发送消息。
```

另外，我遗漏了一个非常重要的点，这里补上。回到之前那张图，完整的图： ^61ac91

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2023-11-19 17.48.21.excalidraw.png]]

> [!stickies]
> 我的猜测：volatile的使用，是否建立在代码的执行顺序是100%确定的前提下？又或者是我不关心代码执行顺序的前提下？因为只有这个情况下，单独使用volatile才能发挥出它对变量的可见性控制。

虽然我们的volatile例子并不能保证这个图中描述的，但是姑且先当它能吧。毕竟书上也是假设writer()先于reader()执行。

我们一直看flag去了，这个a = 3还没看呢！它并不是volatile变量，但是依然随着我们的操作给刷新了上去。这意味着什么呢？

之前我们也说了，在写volatile变量的时候，本地内存**所有**的改变都会一股脑儿flush到主存中去。这意味着，**A线程在写这个volatile之前对==所有共享变量==的改变，也是能传递到B线程那里去的**。 ^a3a78e


这个过程，也像是发送了一个消息一样：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2023-11-19 17.54.13.excalidraw.png]]

### 3.4.3 volatile内存语义的实现

下面来说一说，volatile到底是怎么实现的。想当然，这里一定会有对于重排序的限制。下面就来说一说，JMM对**编译器**指定的volatile重排序规则（并不是对CPU制定的，貌似也制定不了）。

假设有两个操作

```
ins1
ins2
```

其实就是两行比较简单的代码。那么这两个操作如果是不同的指令，能否重排序也有着不一样的要求：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231119180949.png]]

比如，当第一个操作是普通读/写的时候，如果第二个操作是对volatile的写，那么就不允许重排序。比如：

```kotlin
class Test {
	@Volatile
	var i = 0

	var a = 1

	companion object {
		fun test() {
			a = 2 // 普通写
			i = 2 // volatile写
		}
	}
}
```

上面的代码中，test()里面的代码就不允许重排序了。

我们来观察一下这个表格，得出一些结论。首先是最后一列：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231119181250.png]]

这一列意味着，如果第二个指令为对volatile的写，那么不管第一个指令是什么都不允许重排序。本质是什么？本质就是，**你不能把对volatile的写指令往前挪**！

为啥这么要求？就是为了实现我们刚才的结论啊：[[#^a3a78e]]。这样做，就能让volatile写指令之前的任何指令都不会因为重排序而逃逸到volatile写指令的后面去。因为这里对重排序的单位要求是每两个指令。意味着你做不了这样的操作：

```
normalRead1--------
normalRead2       |
volatileWrite3    |
           <______⌟
```

也就是不能隔着一个指令把倒数第二条插到后面去。因为是每两个指令。你**最多**只能决定normalRead1和normalRead2的重排序。

接下来，是这个表格的第二行：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231119182058.png]]

> [!stickies]
> 其实这一行和那一列，就是为了保证那个volatile的happens-before原则。

这一行代表着，如果第一个操作是volatile的读，那么不管第二个操作是什么，都不能重排序。这个也很好理解，和之前是相对应的，volatile读之后的操作也不能逃逸到volatile读的前面。

这么看完，就剩最后一个了。也就是第一个是volatile写，第二个是volatile读的时候，也不能重排序。这个其实还是一样的道理。前面都是“**写和读中间夹心的情况**”，而如果没夹心，也就是它俩挨着的情况也是不能落下的。

既然是这些情况不允许重排序，下面就该实现了！怎么实现呢？建议回头看一看[[Study Log/java_kotlin_study/concurrency_art/3_1_JMM_basic#3.1.2 重排序简介|3.1.2 重排序简介]]，也就是那些内存屏障。

对于volatile写的修改如下：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231119184242.png]]

在它前面插入了一个StoreStore屏障。这保证了必须前面的普通写已经刷新到内存之后，volatile写才能执行。这也就禁止了重排序。

- [?] #question/coding/theory *这里为什么插入的是StoreStore而不是StoreLoad？前面如果是普通读的话，不就又可以重排序了吗？但实际上我不想让它重排序呀？StoreLoad有其它三个屏障的所有功能，为什么不插入这个？再或者，你像下面volatile读那样，在StoreStore后面跟上一个LoadStore也行呀？你为啥不跟呢？*

在后面插入了一个StoreLoad屏障。这保证了**万一**后面紧跟着一个volatile读（此线程的或者是其它线程的），依然不要去重排序。那么这里引出了一个问题：*为啥是在volatile写的后面插，而不是在volatile读的前面插*？答案是，**写操作的数量通常要远小于读操作的数量**。因此写操作插会让代码更加精简，同时屏障的个数也会变少，执行效率更高（是真的细，真的牛逼）。

---

对于volatile读的改动如下：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231119184940.png]]

这里的LoadLoad屏障是为了防止下面的普通读逃逸上去；LoadStore是为了下面的普通写逃逸上去。

- [?] #question/coding/theory *还是那个问题，你这里咋就两个屏障都有，上面volatile写的就没有俩？*

上面这种插屏障的方式，其实是**非常保守**的，也就是最坏情况。通常情况下，在执行的时候编译器会根据具体情况省略掉一些屏障。

这里就照搬书上的图吧。感兴趣可以看看，就是通过分析，看哪些屏障是可以干掉的：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231119185739.png]]

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231119185745.png]]

然后是x86平台的单独优化，很好理解，也直接搬上来了：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231119185941.png]]

### 3.4.4 以前的volatile

这部分对应着我之前介绍的那个补充的一点：[[#^61ac91]]。在旧的JMM模型中，那个表格其实和[[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231119180949.png|现在的]]不一样。在以前，普通变量的读写其实是可以和volatile的读写进行排序的。不变的只是volatile变量之间不能重排序。因此，之前那个writer() reader()的例子，有可能被重排序成这样：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20231119193116.png]]

> 1. a = 3
> 2. flag = true
> 3. if (flag)
> 4. i = a \* a

也就是说，在旧的模型下，会出现这种情况：**线程B读flag发现是true，但是a居然没变成新的值3，还是老的值1**。

所以，volatile最终能保证什么？只能保证对于这个volatile变量的读/写操作是原子的，你再加上任何其它的东西，都可能失效了。

最后，给出一个使用volatile的正确姿势：[Java 理论与实践: 正确使用 Volatile 变量-腾讯云开发者社区-腾讯云 (tencent.com)](https://cloud.tencent.com/developer/article/1340711)