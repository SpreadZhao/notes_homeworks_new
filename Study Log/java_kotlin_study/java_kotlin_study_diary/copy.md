---
mtrace:
  - 2023-07-24
tags:
  - "#language/coding/kotlin"
  - "#language/coding/java"
  - "#question/coding/practice"
  - "#question/interview"
title: 浅拷贝和深拷贝
date: 2023-07-24
---

# 浅拷贝和深拷贝

#date 2023-07-24

[深拷贝和浅拷贝区别了解吗？什么是引用拷贝？](https://javaguide.cn/java/basis/java-basic-questions-02.html#%E6%B7%B1%E6%8B%B7%E8%B4%9D%E5%92%8C%E6%B5%85%E6%8B%B7%E8%B4%9D%E5%8C%BA%E5%88%AB%E4%BA%86%E8%A7%A3%E5%90%97-%E4%BB%80%E4%B9%88%E6%98%AF%E5%BC%95%E7%94%A8%E6%8B%B7%E8%B4%9D)

如果这样的代码：

```kotlin
val a = User()
val b = a
```

这种就是最常见的引用拷贝，a和b是两个引用，它们指向的对象都是一样的：

```kotlin
fun main(args: Array<String>) {  
	val user1 = User("Spread", 12)  
	val user2 = user1  
	println(user1 === user2)  
}
```

```ad-note
在kotlin中，`===`运算符相当于java中的`==`。
```

这段代码的输出是true，表示他们指向的对象就是一样的。那现在问题来了：我不想让他们的对象是一样的，怎么办？你可能会说：再构造一个就完了唄！这样确实可以，但是问题是，如果属性非常多的话，那构造方法写起来可太费劲了。因此，Java的Object类中就内置了clone()方法来实现这个功能。

```kotlin
class User(  
	var name: String,  
	val age: Int  
) : Cloneable {  
	public override fun clone(): User {  
		return super.clone() as User  
	}
}
```

^221e24

这里我们让User类实现了Cloneable接口，并重写了clone()方法。但是要注意，因为clone方法在Object类中是protected的：

```java
@IntrinsicCandidate  
protected native Object clone() throws CloneNotSupportedException;
```

所以我们需要在自类中将属性改成public才可以在外部调用。现在，我们将代码换一下再执行：

#TODO 

- [ ] 为什么可以改成public？

```kotlin
fun main(args: Array<String>) {  
	val user1 = User("Spread", 12)  
	val user2 = user1.clone()  
	println(user1 === user2)  
}
```

这下结果已经变成false了。此时他们就是两个不同的对象了。到了这里，其实还没完，我们再比较一下它们内部的成员：

```kotlin
fun main(args: Array<String>) {  
	val user1 = User("Spread", 12)  
	val user2 = user1.clone()  
	println(user1 === user2)  
	println(user1.name === user2.name)
}
```

它们的name成员居然是true！也就是说，其实实际的结构是这样的：

![[Article/story/resources/Drawing 2023-07-24 10.58.10.excalidraw.png|center]]

虽然两个引用指向了不同的实例，但是这两个不同的实例持有的成员却是一样的。因此我如果做下面的操作：

```kotlin
fun main(args: Array<String>) {  
	val user1 = User("Spread", 12)  
	val user2 = user1.clone()  
	println(user1 === user2)  
	println(user1.name === user2.name)  
	user1.name = "Zhao"  
	println(user2.name)  
	println(user1.name === user2.name)  
}
```

将user1的name改变之后，user2的name会是Spread呢还是Zhao呢？你可能会说是Zhao，因为它们毕竟指向的是同一个name嘛，所以user1的改了，user2的也会跟着变。但实际上，最后的输出却是这样的：

```kotlin
false
true // 改之前
Spread
false // 改之后
```

为什么？你可能犯了和我一样的错误。如果我把刚才那张图再展开一下，可能你就明白了：

![[Article/story/resources/Drawing 2023-07-24 11.06.40.excalidraw.png]]

**name本身也是个引用啊**！所以我们刚才的操作，实际上是：

![[Article/story/resources/Drawing 2023-07-24 11.10.01.excalidraw.png]]

看到了这些，再回头看那些输出，就会明白是怎么回事了。而这，就是java和kotlin中的浅拷贝。下面择出参考网站给的定义：

> - **浅拷贝**：浅拷贝会在堆上创建一个新的对象（区别于引用拷贝的一点），不过，如果原对象内部的属性是引用类型的话，浅拷贝会直接复制内部对象的引用地址，也就是说拷贝对象和原对象共用同一个内部对象（**成员的引用相同**）。
> - **深拷贝**：深拷贝会完全复制整个对象，包括这个对象所包含的内部对象。

最后，再来说一下kotlin的copy()函数。这个函数属于data class独有，实现的也是浅拷贝。在[[Article/story/2023-07-16#使用Compose实现一个单选框|2023-07-16]]那次可是帮了我的大忙。

```kotlin
fun main(args: Array<String>) {  
	val data = UserData("spread")  
	val data2 = data.copy()  
	println(data == data2)  
	println(data === data2)  
	println(data.name === data2.name)  
	val data3 = UserData("zhao")  
	val data4 = data3.copy(name = "chuan")  
	println(data3 == data4)  
	println(data3 === data4)  
	println(data3.name === data4.name)  
}
```

这六条语句的执行结果，在我的讲解下，相信你也一定可以写出来了：

```kotlin
true  // 同一个对象不同的引用，但对象是一个
false // 对象引用不同
true  // 成员的引用是相同的

// 更改过成员的浅拷贝，就什么都不一样了
false
false
false
```