---
title:
  - ConcurrentModificationException on SubList of ArrayList
  - Fail-fast And Fail-safe Iterators
date: 2024-05-05
tags:
  - language/coding/java
  - language/coding/kotlin
mtrace:
  - 2024-05-05
---

# ConcurrentModificationException on SubList of ArrayList

工作的时候遇到的。页面是一个 RecyclerView，里面的 Adapter 是用的 ArrayList 保存的数据。之后换数据的时候，阴差阳错进行了类似下面的操作：

```kotlin
val list = arrayListOf(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)  
val sublist = list.subList(0, 3)  
list.clear()        // ok if no this  
list.addAll(sublist)  
println("list: $list")
```

我们希望把这个 list 提取出一部分，经过若干操作（上面的代码省略了，就是对 sublist 加加减减的操作）再设置回原来的list。

最重要的就是 clear() 方法和 addAll() 方法。报了这个异常：

```shell
Exception in thread "main" java.util.ConcurrentModificationException
	at java.base/java.util.ArrayList$SubList.checkForComodification(ArrayList.java:1415)
	at java.base/java.util.ArrayList$SubList.toArray(ArrayList.java:1227)
	at java.base/java.util.ArrayList.addAll(ArrayList.java:670)
	at basic.ConcurrentModificationExceptionExample.test(ConcurrentModificationExceptionExample.kt:8)
	at basic.ConcurrentModificationExceptionExampleKt.main(ConcurrentModificationExceptionExample.kt:14)
	at basic.ConcurrentModificationExceptionExampleKt.main(ConcurrentModificationExceptionExample.kt)
```

如果没有 clear()，那么是可以正常运行的，并且运行结果也是符合预期的。但是加上了clear反而报了这个错误。主要的原因可以看clear()的源码：

```java
/**
 * Removes all of the elements from this list.  The list will
 * be empty after this call returns.
 */
public void clear() {
	modCount++;
	final Object[] es = elementData;
	for (int to = size, i = size = 0; i < to; i++)
		es[i] = null;
}
```

在后面的addAll()方法中，首先会将传入的参数，也就是sublist转成array。而sublist是list.sublist，这个是ArrayList的一个内部类。它的toArray()实现如下：

```java
public Object[] toArray() {
	checkForComodification();
	return Arrays.copyOfRange(root.elementData, offset, offset + size);
}
```

而checkForComodification中看的就是这个modCount。

```java
private void checkForComodification() {
	if (root.modCount != modCount)
		throw new ConcurrentModificationException();
}
```

这也证明了一点，sublist和原来的list是有联系的。后面可以看看为什么需要这个联系，以及如何断开这个联系，还有类似的操作应该怎么做。

- [ConcurrentModificationException of ArrayList’s SubList | by Ashok Chaudhari | Medium](https://mr-ashok.medium.com/concurrentmodificationexception-of-arraylists-sublist-47fe47c3ffd3)
- [java - ArrayList.addAll() ConcurrentModificationException - Stack Overflow](https://stackoverflow.com/questions/28088085/arraylist-addall-concurrentmodificationexception)

# Fail-fast And Fail-safe Iterators

[Fail-fast and Fail-safe iterations in Java | by Sarangan Janakan | Medium](https://saranganjana.medium.com/fail-fast-and-fail-safe-iterations-in-java-6d532b5b5b11)

java的集合是有迭代器的，总的就是java.util.Iterator接口。而这些迭代器分成两种，线程安全的和线程不安全的。显然，线程不安全的性能更高，但是不适用于多线程。

ArrayList返回的迭代器就是这一种。下面的代码：

```kotlin
val list = ArrayList<String>()
list.add("item1")
list.add("item2")
val iterator = list.iterator()
list.add("item3")
while (iterator.hasNext()) {
	val item = iterator.next()
	println(item)
}
println("$list")
```

在第一次执行到`val item = iterator.next()`的时候就会抛出ConcurrentModificationException异常。因为我们在创建出iterator之后，又加了一个item3。而在ArrayList的add中，就修改了modCount：

```java
/**
 * Appends the specified element to the end of this list.
 *
 * @param e element to be appended to this list
 * @return {@code true} (as specified by {@link Collection#add})
 */
public boolean add(E e) {
	modCount++;
	add(e, elementData, size);
	return true;
}
```

综上所述，我们不希望迭代器工作的时候，对集合本身进行修改（会让modCount改变的操作）。实际上，正式为了这个，我们才搞出来的modCount。从[[Study Log/java_kotlin_study/concurrency_art/6_1_concurrent_hash_map#6.1.4.3 size|6_1_concurrent_hash_map]]中我们也能看出，modCount的作用就是记录之前修改的次数，来判断我当前这次是否要继续修改。对于ArrayList的迭代器（内部类）来说，它会在乎这个，所以它fail-fast了：

```java
public E next() {
	checkForComodification();    // fail-fast if modified
	int i = cursor;
	if (i >= size)
		throw new NoSuchElementException();
	Object[] elementData = ArrayList.this.elementData;
	if (i >= elementData.length)
		throw new ConcurrentModificationException();
	cursor = i + 1;
	return (E) elementData[lastRet = i];
}
```

fail-fast的意思就是，我只要发现有人修改了，那我立马赶紧报错，别继续了。因为你硬着头皮去搞对你肯定是没好处的。在fail之后，就会抛出ConcurrentModificationException来标识这个问题。

> [!note]
> 这里说一下我对CME中Concurrent的理解。第一次看到这个名字，我以为是多线程导致的。比如[[#ConcurrentModificationException on SubList of ArrayList|开始遇到的那个问题]]。但是结果表明单线程也可以引发这个问题。那是不是意味着，这个异常叫Concurrent不太合适呢？我的看法是，这是一个原则性的问题。拿迭代器举例子，我创建了迭代器，那我就是想遍历这个集合，这个时候你就别该它，谁都别改。对于我自己线程来说，自己这个线程（迭代器遍历的线程）**有义务**不对集合进行修改，所以，设计者就是表明对自己这个线程表示相信，不觉得它会修改，要修改也是别人修改的。所以叫Concurrent就很合理了。
> 
> 再回到开始的问题，本质上出问题的是`list.clear()`和`sublist.toArray()`这两个方法。从这里我们也大致能推测出来，sublist创建出来了，那我也不希望你修改原来的list。因此，这里我们调用了`list.clear()`修改了list，之后再要操作就出问题了😿。
> 
> ~~猜想：这两个问题的共同点都是**内部类**。迭代器和子列表都是内部类。是不是意味着，一个类的内部类（非静态）在修改的时候都会出这样的问题？~~

相对的，fail-safe的意思就是没问题，我不在乎这个。比如ConcurrentHashMap，它是一个不会抛出CME的类。