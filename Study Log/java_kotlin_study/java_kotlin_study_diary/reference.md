---
mtrace:
  - 2023-08-31
  - 2024-06-12
tags:
  - language/coding/java
  - question/interview
  - rating/high
title: Java的引用类型
date: 2023-08-31
---
# Java的引用类型

**1．强引用（StrongReference）**

以前我们使用的大部分引用实际上都是强引用，这是使用最普遍的引用。如果一个对象具有强引用，那就类似于**必不可少的生活用品**，垃圾回收器绝不会回收它。当内存空间不足，Java 虚拟机宁愿抛出 OutOfMemoryError 错误，使程序异常终止，也不会靠随意回收具有强引用的对象来解决内存不足问题。

**2．软引用（SoftReference）**

如果一个对象只具有软引用，那就类似于**可有可无的生活用品**。如果内存空间足够，垃圾回收器就不会回收它，如果内存空间不足了，就会回收这些对象的内存。只要垃圾回收器没有回收它，该对象就可以被程序使用。软引用可用来实现内存敏感的高速缓存。

软引用可以和一个引用队列（ReferenceQueue）联合使用，如果软引用所引用的对象被垃圾回收，JAVA 虚拟机就会把这个软引用加入到与之关联的引用队列中。

**3．弱引用（WeakReference）**

如果一个对象只具有弱引用，那就类似于**可有可无的生活用品**。弱引用与软引用的区别在于：只具有弱引用的对象拥有更短暂的生命周期。在垃圾回收器线程扫描它所管辖的内存区域的过程中，一旦发现了只具有弱引用的对象，不管当前内存空间足够与否，都会回收它的内存。不过，由于垃圾回收器是一个优先级很低的线程， 因此不一定会很快发现那些只具有弱引用的对象。

弱引用可以和一个引用队列（ReferenceQueue）联合使用，如果弱引用所引用的对象被垃圾回收，Java 虚拟机就会把这个弱引用加入到与之关联的引用队列中。

> [[Study Log/android_study/handler_looper#^b9e691|Handler引起内存泄漏的解决方法]]

**4．虚引用（PhantomReference）**

"虚引用"顾名思义，就是形同虚设，与其他几种引用都不同，虚引用并不会决定对象的生命周期。如果一个对象仅持有虚引用，那么它就和没有任何引用一样，在任何时候都可能被垃圾回收。

**虚引用主要用来跟踪对象被垃圾回收的活动**。

**虚引用与软引用和弱引用的一个区别在于：** 虚引用必须和引用队列（ReferenceQueue）联合使用。当垃圾回收器准备回收一个对象时，如果发现它还有虚引用，就会在回收对象的内存之前，把这个虚引用加入到与之关联的引用队列中。程序可以通过判断引用队列中是否已经加入了虚引用，来了解被引用的对象是否将要被垃圾回收。程序如果发现某个虚引用已经被加入到引用队列，那么就可以在所引用的对象的内存被回收之前采取必要的行动。

特别注意，在程序设计中一般很少使用弱引用与虚引用，使用软引用的情况较多，这是因为**软引用可以加速 JVM 对垃圾内存的回收速度，可以维护系统的运行安全，防止内存溢出（OutOfMemory）等问题的产生**。

# 一个关于引用的迷惑性问题

#date 2024-06-12

今天又发现了一个关于引用的问题：如果我有一个数组，然后用一个引用承接数组中的一个元素，然后把数组中的这个元素置空，那么那个承接的引用是空吗？

在解答这个问题之前，我们先看一个比较简单的问题： ^6027fb

```kotlin
class RefCopy {
    class People(val name: String)
}

var p1 = RefCopy.People("Spread")
val p2 = p1
p1 = RefCopy.People("Zhao")
println("p1: ${p1.name}")
println("p2: ${p2.name}")
```

这段代码的输出是什么？我们先画一个图表示一下：

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/Drawing 2024-06-12 15.30.55.excalidraw.svg]]

所以答案也很简单：

```shell
p1: Zhao
p2: Spread
```

p2和p1虽然指向同一个对象，但是我们改变了p1之后，p2的指向并没有发生变化。因为`p1 = XXX`只是修改了p1的指向而已。这个道理换成Int类型也是一样的：

```kotlin
var p3 = 5  
val p4 = p3  
p3 = 6  
println("p3: $p3")  
println("p4: $p4")
```

```shell
p3: 6
p4: 5
```

那现在的问题是：换成数组之后，答案还是一样的吗？

```kotlin
val arr = intArrayOf(0, 1, 2, 3)
val b = arr[2]
arr[2] = 100
println("arr: ${arr.contentToString()}")
println("b: $b")
```

上面代码中，b的最终值是多少？是100还是2？根据我们之前的结论，答案应该是2。而事实证明，答案也确实是2：

```shell
arr: [0, 1, 100, 3]
b: 2
```

因为都是数字，赋值是直接赋值的。当b被赋值成2之后，就和`arr[2]`没有关系了（从b是val也能看出这一点）。

那么问题就是，如果arr是个对象数组的话，结果会怎么样？

```kotlin
class People(val age: Int)

val arr2 = arrayOf<People?>(
	People(0),
	People(1),
	People(2),
	People(3)
)
val b2 = arr2[2]
arr2[2] = null
print("arr2: [")
arr2.forEach {
	print("${it?.age}, ")
}
println("]")
println("b2: ${b2?.age}")
```

这里我们让b2和`arr2[2]`指向同一个对象，然后让`arr2[2]`为空，那么b2也会跟着变化吗？答案是不会，因为这个情况其实和我们[[#^6027fb|最一开始说的情况]]是一样的：

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/Drawing 2024-06-12 15.39.18.excalidraw.svg]]

这里`arr2[2]`和b2其实就是最一开始的p1和p2。唯一的区别就是变成了数组，更加有迷惑性了。