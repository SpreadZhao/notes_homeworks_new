---
mtrace:
  - 2023-08-29
  - 2023-09-04
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
table[index] = Entry(k, v, table[index])  
_size++  
return null
```

下面是图解。首先是链表中存在key的情况：

![[Study Log/java_kotlin_study/resources/Drawing 2023-08-30 10.12.49.excalidraw.png]]

然后是链表中不存在key的情况：

![[Study Log/java_kotlin_study/resources/Drawing 2023-08-30 10.17.34.excalidraw.png]]

```ad-warning
千万要注意！这里put中的key不是我真正传入的参数，而是**经过哈希函数运算**后的结果！这样写是为了好说明插入的过程。
```

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

```ad-question
不知道你会不会有这样的问题：*我的头节点的key是4，数组的下标是3，那我remove的是2，为啥还能找到头节点呢*？还记不记得我之前说的哈希碰撞，之所以这些结点在一个链表里，就是因为它们经过哈希函数计算之后，**结果全部都是3**！所以它们全部都在下标为3的这个链表里。
```

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