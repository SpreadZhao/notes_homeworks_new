---
title: ConcurrentModificationException on SubList of ArrayList
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