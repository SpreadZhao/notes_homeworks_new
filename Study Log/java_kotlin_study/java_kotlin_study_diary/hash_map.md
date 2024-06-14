---
mtrace:
  - 2023-08-29
  - 2023-09-04
  - 2024-06-06
title: 手动实现HashMap
date: 2023-08-29
tags:
  - "#question/interview"
  - "#language/coding/kotlin"
  - "#rating/high"
---

# 手动实现HashMap

#question/interview #language/coding/kotlin #rating/high 

## 1 基本原理

HashMap的本质功能就是一个数组，没有任何其它的东西。只不过，它访问下标的方式比较奇怪。

传统访问下标的方式，就是从0开始，一直到size-1。也就是说，**我们直接访问的就是下标**。而在HashMap中，我们访问的并不是下标，而是key，而如果key相同的话，访问的就是同一个元素。

![[Study Log/java_kotlin_study/resources/Drawing 2023-08-29 17.12.41.excalidraw.png]]

比如，我想访问这个数组的四号，调用`map.get(4)`就可以了。但是，你有没有想过，*我们在放入值，也就是执行put操作时，并不是按着顺序来的*？也就是说，我想让第10000号是字符串haha，只需要执行`put(10000, "haha")`就可以了。但是，这个HashMap（**或者说数组**）的初始容量可能是10000以上吗？如果是的话，那我如果只往这个map里放一个值，那岂不是非常浪费空间？所以，我们用脚趾头想都能知道，这种直接用数组的方法必定是不可能的。

HashMap采用的策略，就在它的名字里：哈希。既然我们无法给出一个无限大的数组，那么就给一个有限大，尽可能满足要求的数组，然后，**不管你要访问的key是什么，最后都要让它命中这个数组的某个元素，也就是不能越界**。最简单的方法，我们能想到：

```kotlin
val index = key % array.size
```

![[Study Log/java_kotlin_study/resources/Drawing 2023-08-29 17.21.16.excalidraw.png]]

让key模上数组的长度就好了嘛！这样，不管你key是多少，最后一定会落在这个数组中，也就不会超过限制了。那么紧接着问题就又来了：*key如果不是数字咋办*？

这个问题就是使用哈希的原因了：**任何一个Object都有哈希码**。无论是java中Object的hashCode()方法，还是kotlin中Any的hashCode()方法，都能确定一个key的唯一性。所以，我们将代码改成这样就好了：

```kotlin
val index = key.hashCode() % array.size
```

这样，我执行`get(10000)`两次，那么这两个Int类型计算的哈希是相同的，模上数组的长度之后也是相同的。所以我们两次取到的就是这个数组的同一个位置了。

大体上解决了我们之前的问题，*但是还有另一种新的问题，并且更严重*。从这个数组也能看出来，它的长度是16。也就是说，**即使我们的运气非常好，执行了17次put操作以后，也必定至少会有一个格子里有两个元素**。而这个过程就叫做**哈希碰撞**。所谓的哈希碰撞，就是指两个**不同的**key在通过哈希函数计算后，得到的结果是一样的。而在上面的例子中，哈希函数是什么呢？其实可以抽象成下面的函数：

```kotlin
fun calHash(key: Int): Int {
	return key % array.size
}
val index = calHash(key.hashCode())
```

而实参就是`key.hashCode()`。而如何解决这个问题呢？显然，我们要让一个格子里能存多个元素。而HashMap采用的策略就是：**拉链**。

既然要拉链，就意味着，数组的每一个元素不再是Value对应的类型，**而是一个链表的头节点**。下面就不卖关子了，这个结点其实就是HashMap.Entry：

```kotlin
class Entry<K, V>(  
    var k: K? = null,  
    var v: V? = null,  
    var next: Entry<K, V>? = null  
)
```

> [!question]- 为什么HashMap的Entry还要存key？
> 
> 之前，我们在用数组实现的时候，并没有存key，是因为它的下标就是key。但是，采用了哈希函数，并且还拉链了，如果我们要找的元素在链表的后面咋办？那自然只能顺着这个链表去找，通过key来判断是不是我们要的结点；另一个原因是，我们有时候可能也会有通过value反着找key的需求。

> [!question]- 这里的key是调用HashMap.put()方法中传入的key吗？
> 不是！这个key是经过hash运算之后的。在之前的例子中，也就是经过`key % array.size`运算之后的值。正如前面提到的，HashMap并不关心使用者传入的key究竟是什么，它只想通过这个key找到一个坑把东西塞进去。所以『经过运算之后的』『唯一确定坑位的』这个key才是HashMap关心的。
> 
> 再说个问题，上面一段中的“坑位”指的是什么？答案是一个链表。一个数组项对应的链表。

这里用kt写了一个比较简易的版本。其实和任意一个链表一样，它的每一项都是一个Entry，里面保存着它下一个Entry的引用。而上面的那个数组，每一个元素的类型就也都要是Entry类型的了。至此，我们可以写出我们MyHashMap的雏形：

```kotlin
class MyHashMap<K, V> {  
    class Entry<K, V>(  
        var k: K? = null,  
        var v: V? = null,  
        var next: Entry<K, V>? = null  
    )
    private var table: Array<Entry<K, V>?>
}
```

## 2 开始构建

就是这样！下面，我们来开始从0构造一个HashMap。其实，就是创建一个数组嘛！但是，这个数组的大小需要给安排好，我在这里就沿用上面的例子，让它是16（**注意，这里的16并不是HashMap实际元素的个数，只是格子的个数，里面不一定是装满的**）。

然后，就是HashMap实际的长度了，也就是size。这个很简单，一开始是0，每put一个元素再增加就好了。

有了这些基本元素，现在开始构建：

```kotlin
class MyHashMap<K, V> {  
    class Entry<K, V>(  
        var k: K? = null,  
        var v: V? = null,  
        var next: Entry<K, V>? = null  
    )
    
    companion object {  
	    const val DEFAULT_CAPACITY = 16 
	    
	    const val DEFAULT_LOAD_FACTOR = 0.75f
	    
	    private fun upperMinPowerOf2(n: Int): Int {  
		    var power = 1  
		    while (power <= n) {  
		        power *= 2  
		    }  
		    return power  
		}
    }

	private var capacity = 0  
	private var loadFactor = 0f  
	private var _size = 0  
    private var table: Array<Entry<K, V>?>
    
    val size: Int get() = _size
    
    constructor() : this(DEFAULT_CAPACITY, DEFAULT_LOAD_FACTOR)  
    
	constructor(capacity: Int, loadFactor: Float) {  
	    this.capacity = upperMinPowerOf2(capacity)  
	    this.loadFactor = loadFactor  
	    this.table = Array(capacity) { null }  
	}
}
```

> 这里的loadFactor并没有用上，以后有机会再说。

这里唯一没有介绍过的，就是这个upperMinPowerOf2函数。它的作用是找到和capacity相等或者比它小的，最大的2的幂。这个是为了后续更好地进行扩容，我们直接写`this.capacity = capacity`也是一样的效果。

~~现在，我们就有了一个长度为16的数组，每一个元素都是一个Entry。它的key是null，value也是null，next还是null。~~

现在，我们就有了一个长度为16的数组，每一个元素的类型都一个Entry，只不过目前都是null。

## 3 实现put，get，remove操作

下面，就是实现put操作了。具体的思路之前也介绍过了，首先通过哈希函数算出要存放的index：

```kotlin
fun put(k: K, v: V): V? {  
    val index = k.hashCode() % table.size
    ...
}
```

然后，我们要看：**当前格子里是否已经有元素了**？

```kotlin
fun put(k: K, v: V): V? {  
    val index = k.hashCode() % table.size  
    var current = table[index]  
    if (current != null) {  
        // 如果存在，那么需要看链表里是否有这个值，通过key来看。如果有，替换；如果没有，插入链表
    } else {
		// 如果不存在，那么直接放进去就行了
    }
}
```

首先先写简单的情况。如果current是null的话，直接把这个Entry放在里面就好了：

```kotlin
table[index] = Entry(k, v, null)  
_size++  
return null
```

而如果此处已经有了一个Entry，就要在链表中一个个比较了。

* 如果链表中存在这个key，那么实际上是个更新操作；
* 如果不存在，那么就是插入操作。这里我们选择头插。

```kotlin
while (current != null) {  
    if (current.k == k) {  
        val oldValue = current.v  
        current.v = v  
        return oldValue  
    }  
    current = current.next  
}  
// current is null
table[index] = Entry(k, v, table[index])  
_size++  
return null
```

下面是图解。首先是链表中存在key的情况：

> 你可能会觉得这张图哪里有问题。如果是这样的话，先看下面的注意：[[#^404661]]

![[Study Log/java_kotlin_study/resources/Drawing 2023-08-30 10.12.49.excalidraw.png]]

然后是链表中不存在key的情况：

![[Study Log/java_kotlin_study/resources/Drawing 2023-08-30 10.17.34.excalidraw.png]]

> [!attention]
> ~~千万要注意！这里put中的key不是我真正传入的参数，而是**经过哈希函数运算**后的结果！这样写是为了好说明插入的过程。~~
> 
> 好吧，首先可以确定，上面删掉的这句话是错的。图中`<_, _>`里面的数字不是**经过哈希运算之后的结果**。因为如果是的话，上面所有的数字都应该是3，只有运算完之后是3才能放到这个格子里。看后面我的描述：[[#^ecaa12]]，这里==说的==也是同样的==道理==。所以如果硬要解释，就是**上面的这两张图中，1 2 3 4 经过某个哈希函数计算之后，结果都是3**。这样才能让它们在同一个链表里出现。因此这个哈希函数也不可能是模运算。那至于这个函数到底应该是什么，其实不重要。

^404661

有了put操作之后，get操作就很简单了：还是找到index，然后在这个链表里搜，看能不能搜到就好了：

```kotlin
fun get(k: K): V? {  
    val index = k.hashCode() % table.size  
    var current = table[index]  
    while (current != null) {  
        if (current.k == k) return current.v  
        current = current.next  
    }  
    return null  
}
```

接下来，就是remove操作。这个操作也可以举一反三：找到链表，在链表里删除结点。

```kotlin
fun remove(k: K): V? {  
    val index = k.hashCode() % table.size  
    val result: V?  
    var current = table[index]  
    var pre: Entry<K, V>? = null  
    while (current != null) {  
        if (current.k == k) {  
            result = current.v  
            _size--  
            if (pre != null) {  
                pre.next = current.next  
            } else {  
                table[index] = current.next  
            }  
            return result  
        }  
        pre = current  
        current = current.next  
    }  
    return null  
}
```

这和删除链表的结点几乎没啥区别，唯一不同的就是要通过哈希函数来找到这个链表的头节点。下面画个图吧：

![[Study Log/java_kotlin_study/resources/Drawing 2023-08-30 10.29.49.excalidraw.png]]

> [!question]
> 不知道你会不会有这样的问题：*我的头节点的key是4，数组的下标是3，那我remove的是2，为啥还能找到头节点呢*？还记不记得我之前说的哈希碰撞，之所以这些结点在一个链表里，就是因为它们经过哈希函数计算之后，**结果全部都是3**！所以它们全部都在下标为3的这个链表里。

^ecaa12

好了，这就是最基础的功能了。下面，给出全部的代码：

```kotlin
class MyHashMap<K, V> {  
    class Entry<K, V>(  
        var k: K? = null,  
        var v: V? = null,  
        var next: Entry<K, V>? = null  
    )  
    companion object {  
        const val DEFAULT_CAPACITY = 16  
        const val DEFAULT_LOAD_FACTOR = 0.75f  
        private fun upperMinPowerOf2(n: Int): Int {  
            var power = 1  
            while (power <= n) {  
                power *= 2  
            }  
            return power  
        }  
        fun test() {  
            val myMap = MyHashMap<Int, String>()  
            for (i in 1..10) {  
                myMap.put(i, "key$i")  
            }  
            println("My map size: ${myMap.size}")  
            for (i in 1..10) {  
                println("key: $i, value: ${myMap.get(i)}")  
            }  
            myMap.remove(7)  
            println("After remove:")  
            for (i in 1..10) {  
                println("key: $i, value: ${myMap.get(i)}")  
            }  
        }  
    }  
    private var capacity = 0  
    private var loadFactor = 0f  
    private var _size = 0  
    private var table: Array<Entry<K, V>?>  
    val size: Int get() = _size  
  
    constructor() : this(DEFAULT_CAPACITY, DEFAULT_LOAD_FACTOR)  
  
    constructor(capacity: Int, loadFactor: Float) {  
        this.capacity = upperMinPowerOf2(capacity)  
        this.loadFactor = loadFactor  
        this.table = Array(capacity) { null }  
    }  
  
    fun put(k: K, v: V): V? {  
        val index = k.hashCode() % table.size  
        var current = table[index]  
        if (current != null) {  
            while (current != null) {  
                if (current.k == k) {  
                    val oldValue = current.v  
                    current.v = v  
                    return oldValue  
                }  
                current = current.next  
            }  
            table[index] = Entry(k, v, table[index])  
            _size++  
            return null  
        }  
        table[index] = Entry(k, v, null)  
        _size++  
        return null  
    }  
  
    fun get(k: K): V? {  
        val index = k.hashCode() % table.size  
        var current = table[index]  
        while (current != null) {  
            if (current.k == k) return current.v  
            current = current.next  
        }  
        return null  
    }  
  
    fun remove(k: K): V? {  
        val index = k.hashCode() % table.size  
        val result: V?  
        var current = table[index]  
        var pre: Entry<K, V>? = null  
        while (current != null) {  
            if (current.k == k) {  
                result = current.v  
                _size--  
                if (pre != null) {  
                    pre.next = current.next  
                } else {  
                    table[index] = current.next  
                }  
                return result  
            }  
            pre = current  
            current = current.next  
        }  
        return null  
    }  
  
    fun isEmpty() = size == 0  
}
```

#date 2024-06-06

# JDK 1.7 中的 HashMap

> [!attention]
> 本文章使用的jdk版本：[openjdk/jdk at jdk7-b147](https://github.com/openjdk/jdk/tree/jdk7-b147)

- [java - 11张图让你彻底明白jdk1.7 hashmap的死循环是如何产生的 - 个人文章 - SegmentFault 思否](https://segmentfault.com/a/1190000024510131)
- [【透彻】java关于HashMap多线程扩容导致死循环（JDK1.7）的详细过程_jdk1.7hashmap扩容死循环-CSDN博客](https://blog.csdn.net/HD243608836/article/details/126630059)

jdk1.7以前的HashMap的实现方式和我们上面的代码基本上是差不多的，也是使用的头插法。我们首先回顾一下我们刚刚自己写的put方法：

```kotlin
fun put(k: K, v: V): V? {
	val index = k.hashCode() % table.size
	var current = table[index]
	if (current != null) {
		// 有Hash碰撞
		while (current != null) {
			if (current.k == k) {
				// 存在key
				val oldValue = current.v
				current.v = v
				return oldValue
			}
			current = current.next
		}
		// 不存在key
		table[index] = Entry(k, v, table[index])
		_size++
		return null
	}
	// 没有Hash碰撞
	table[index] = Entry(k, v, null)
	_size++
	return null
}
```

可以看到，如果发生了Hash碰撞，但是链表中并不存在想要的key的话，会执行这句代码：

```kotlin
table[index] = Entry(k, v, table[index])
```

这句代码就是头插法的体现。将现在的`table[index]`作为新Entry的next，然后让新的Entry作为新的`table[index]`。这样新加入的entry就是新的链表头了。现在我们来看看jdk1.7中的put方法：

```java
/**
 * Associates the specified value with the specified key in this map.
 * If the map previously contained a mapping for the key, the old
 * value is replaced.
 *
 * @param key key with which the specified value is to be associated
 * @param value value to be associated with the specified key
 * @return the previous value associated with <tt>key</tt>, or
 *         <tt>null</tt> if there was no mapping for <tt>key</tt>.
 *         (A <tt>null</tt> return can also indicate that the map
 *         previously associated <tt>null</tt> with <tt>key</tt>.)
 */
public V put(K key, V value) {
	if (key == null)
		return putForNullKey(value);
	int hash = hash(key.hashCode());
	int i = indexFor(hash, table.length);
	for (Entry<K,V> e = table[i]; e != null; e = e.next) {
		Object k;
		if (e.hash == hash && ((k = e.key) == key || key.equals(k))) {
			V oldValue = e.value;
			e.value = value;
			e.recordAccess(this);
			return oldValue;
		}
	}

	modCount++;
	addEntry(hash, key, value, i);
	return null;
}
```

先看其中的for循环：

```java
for (Entry<K,V> e = table[i]; e != null; e = e.next) {
	Object k;
	if (e.hash == hash && ((k = e.key) == key || key.equals(k))) {
		V oldValue = e.value;
		e.value = value;
		e.recordAccess(this);
		return oldValue;
	}
}
```

可以发现，这和我们自己写的while循环是几乎一致的。都描述的是在Hash碰撞，且链表中存在key的情况。在这种情况下我们会去修改链表中相应元素，并返回老的元素。它唯一比我们多出来的就是`recordAccess()`操作，不过这个方法看名字就是类似于记录的功能，所以并不重要。

当退出for循环时，代表链表中并不存在key对应的entry。或者这个链表本身就是空的（即没有Hash碰撞）。在我们的例子中，这两种情况是分开处理的，为了更好地解释HashMap的原理：

```kotlin
// 不存在key
table[index] = Entry(k, v, table[index])
_size++
return null

// 没有Hash碰撞
table[index] = Entry(k, v, null)
_size++
return null
```

我们发现，这两种策略的操作几乎都是一样的。所以在jdk1.7中，他们被统一处理。方法就是addEntry：

```java
/**
 * Adds a new entry with the specified key, value and hash code to
 * the specified bucket.  It is the responsibility of this
 * method to resize the table if appropriate.
 *
 * Subclass overrides this to alter the behavior of put method.
 */
void addEntry(int hash, K key, V value, int bucketIndex) {
	Entry<K,V> e = table[bucketIndex];
	table[bucketIndex] = new Entry<>(hash, key, value, e);
	if (size++ >= threshold)
		resize(2 * table.length);
}
```

这里面的这句：

```java
table[bucketIndex] = new Entry<>(hash, key, value, e);
```

和我们自己写的是一模一样的，就是头插法的实现。而接下来的操作是我们没有的，就是将数组给扩容。随着不断插入元素，数组肯定会越来越满。这样的后果就是Hash碰撞的概率也会增加。为了减少我们操作链表的次数以提升性能，最简单直观的方式就是给数组扩容。可以看到，这里扩容的条件是，如果增加元素之后的size超过了阈值threshold，就会调用resize方法进行扩容。方法传入的参数是我们希望的新的容量。这里传入的是原来数组大小的2倍。

扩容的逻辑，也就是resize方法的实现，看起来很简单：

```java
/**
 * Rehashes the contents of this map into a new array with a
 * larger capacity.  This method is called automatically when the
 * number of keys in this map reaches its threshold.
 *
 * If current capacity is MAXIMUM_CAPACITY, this method does not
 * resize the map, but sets threshold to Integer.MAX_VALUE.
 * This has the effect of preventing future calls.
 *
 * @param newCapacity the new capacity, MUST be a power of two;
 *        must be greater than current capacity unless current
 *        capacity is MAXIMUM_CAPACITY (in which case value
 *        is irrelevant).
 */
void resize(int newCapacity) {
	Entry[] oldTable = table;
	int oldCapacity = oldTable.length;
	if (oldCapacity == MAXIMUM_CAPACITY) {
		threshold = Integer.MAX_VALUE;
		return;
	}

	Entry[] newTable = new Entry[newCapacity];
	transfer(newTable);
	table = newTable;
	threshold = (int)(newCapacity * loadFactor);
}
```

就是构造一个新的数组，然后调用transfer方法将数据移动到新的数组上。然而，transfer方法的实现想要弄明白还是需要一些基本功的。

我希望你先看完[[Study Log/java_kotlin_study/java_kotlin_study_diary/reference#一个关于引用的迷惑性问题|一个关于引用的迷惑性问题]]，然后再继续进行下去。这个对我们阅读transfer方法的代码非常有帮助。

transfer的代码如下：

```java
/**
 * Transfers all entries from current table to newTable.
 */
void transfer(Entry[] newTable) {
	Entry[] src = table;
	int newCapacity = newTable.length;
	for (int j = 0; j < src.length; j++) {
		Entry<K,V> e = src[j];
		if (e != null) {
			src[j] = null;
			do {
				Entry<K,V> next = e.next;
				int i = indexFor(e.hash, newCapacity);
				e.next = newTable[i];
				newTable[i] = e;
				e = next;
			} while (e != null);
		}
	}
}
```

src是原来的数组，而newTable是新数组，**里面目前还全都是null**。transfer的核心是遍历整个src数组，将里面的东西移动到新的数组中。如果你仔细看了之前关于引用的问题，你就会知道，这两句代码：

```java
Entry<K,V> e = src[j];
src[j] = null;
```

并不会改变e的值，只是`src[j]`的指向从原来的链表头节点变成了null。在for循环的第一轮执行到了`src[j] = null;`的时候，应该是下图的情况：

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/Drawing 2024-06-12 14.55.26.excalidraw.svg]]

我们发现，当do-while循环执行之前，我们就已经**将链表从原来的数组中抽离出来**，由临时引用e来接管了。

> [!note]
> 这里我们假设原来的数组大小是4，所以调用resize扩容时的新容量就是8；同时每个entry的key是一个数字，value是一个string。

接下来我们开始走第一遍do-while循环。这里为了看的更清晰，调整一下图：

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/Drawing 2024-06-13 01.09.23.excalidraw.svg]]

假设这个链表在新的数组中的index是1，那么以e（`<121, a>`）开头的所有元素都应该被放到新的数组的1号标中。跟着这个走，我们看它到底是怎么放的。其实，这里我能想到的最简单的办法，让新的数组的1号指向e指向的东西不就行了？之所以没这么做，主要的原因是我们要给原来链表中的每一个节点都判断。虽然它们在老链表中的hash结果都是0，但是不代表新的结果都是1。这里都是1只是我的假设。所以真实情况要具体看。

对于链表中的每个节点，都需要做下面的步骤：

```java
// 暂存当前节点的下一个节点，仅用作最后的移动。
Entry<K,V> next = e.next;
// 找到要存放的数组。在本例中i永远是1。
int i = indexFor(e.hash, newCapacity);
// 下两行为头插法的核心步骤。
e.next = newTable[i];
newTable[i] = e;
// 移动节点到下一个。
e = next;
```

这里最需要关注的就是，如果新数组还没有被放入过元素，那么它其实就是null。根据这个描述，我们画出第一次结束之后的样子：

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/Drawing 2024-06-13 01.27.09.excalidraw.svg]]

这就是头插法：新来的元素永远插在第一个的前一个。我们自己想：如果现在已经有来一个链表，头节点是head。如果我希望头插一个元素，应该怎么做？答案其实很容易想到：**让新节点的下一个是head，然后再让head是新节点**。而这里的操作完全就是这样的。唯一多出来的一点是：我们的新节点不是凭空构造出来的，而是原来存在于一个链表中的。也就是说，**我们在把链表的每一个节点都使用头插法插入到一个（或多个，但不是本例）新链表中**。

那这里的问题也很容易发现：经过这样的操作，新的链表就变成原来的倒序了。

这样的头插实现也是jdk1.7中容易出现死循环的原因。当有多个线程访问HashMap的时候，就很可能会出现这种情况。接下来我们以两个线程来模拟一下这个情况。

在模拟之前，需要说明几个问题：

1. 链表从原来的数组移动到新数组的时候，会发生反转，因为头插法；
2. 两个线程执行的过程中，<fieldset class="inline"><legend class="small">💬</legend>可能</fieldset>会读到同一个老的链表，而新的链表完全是两个线程私有的（具体过程看下图）；
3. 当执行完resize中的`table = newTable`之后，才真正把自己的修改写入公共变量。

> [!comment] 可能
> 之所以是可能，主要是因为两个线程执行的顺序不可控。比如第一个线程都把整个addEntry执行完了，第二个线程才开始执行transfer。这个时候第二个线程读到的就是第一个线程完全修改过后的结果。这种情况就不会出现问题。而我们讨论的出现问题的情况是**两个线程同时执行transfer，读到了同一个老链表**的情况。当执行完transfer之后，返回到resize中，紧接着下一句话就是`table = newTable`。这句话就是将自己修改过后的新链表赋值给公共的变量table。这才代表真正把修改写入。

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/Pasted image 20240613133227.png]]

现在假设两个线程同时执行到transfer方法。然后线程1第一次执行**完**transfer的`Entry<K,V> next = e.next`时被挂起，然后线程2将整个resize都执行完了。此时线程2已经将修改写入了公共变量table。这样的话，线程1的src指向的也是table，所以这个时候src中的变量已经发生了变化：
 
![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/Drawing 2024-06-13 14.06.13.excalidraw.svg]]

- [ ] #TODO tasktodo1718262686036 上面这张图，table应该放在哪里？是两个线程都有，还是在主线程的栈中？换句话说，如果两个线程访问同一个公共变量，那么它们访问的这个引用到底是怎么存的？ ➕ 2024-06-13 ⏫ 

当线程2执行完全部代码时，情况如下：

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/Drawing 2024-06-13 13.54.47.excalidraw.svg]]

这和我们之前的内容是一样的。然而，当线程1恢复之后，情况就大不相同了：

1. 因为线程2已经将修改结果写入，所以线程1的src已经指向一个修改好的数组；
2. 此时线程1要修改的链表已经是被添加成功，并且是反转的。

此时最好的策略其实是让线程1停止执行。但是实际上并没有这么做，可能有其他的问题吧。后果就是线程1会继续运行下去，再进行一次修改。线程1和线程2现在的情况是这样的：

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/Drawing 2024-06-13 15.27.43.excalidraw.svg]]

线程1的src已经指向了线程2修改之后的结果，所以大小也翻倍了；另外线程1因为执行完了`Entry<K,V> next = e.next`，导致线程1的e和next还是指向的修改之前的entry。

我们把线程1的情况画一个漂亮一点的图：

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/1.drawio.svg]]

接下来，我们按照这段代码一行行执行。看最终的结果是如何。我已经将这个过程做成了一个动图：

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/hashmap-loop-error.gif]]

> [!attention]
> - 为了让图更加清晰直观，我把e和next放到了左边，但是它们都是线程1栈空间的变量。
> - 图中蓝色的线代表链表的下一个，也就是`e.next`。
> - 图中红色的代码表示**这行已经执行完毕了**。

我们发现，线程1执行完毕后，最终的情况是这样的：

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/16.drawio.svg]]

- 链表中出现了环；
- 链表的头本来应该是`<786, jdf>`，现在却变成了`<121, a>`。**这正好是环的出发点**。

产生这个现象的主要原因就是，一开始线程1执行完了`Entry<K,V> next = e.next`，而那个时候链表还是正向的；之后线程2操作完之后，链表倒过来了。这就导致**线程1之前记住的e和next之间的关系已经是错的了**。所以在之后移动链表的过程中，**e的指向出现了先往下走再往上走的现象**（我十分建议你回头再看一眼动图，盯着e的指向即可）。

而这样的后果，导致链表中间出现了一个环。所以，如果之后再有人访问这个链表（无论是调用get读取数据，还是调用put存放数据），恰好这个要被读的key或者要存的key的hash结果正好也是这个格子的话，由于现在就处在链表的环的开头，那么之后就很有可能一直环下去了。