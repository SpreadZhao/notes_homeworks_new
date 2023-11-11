---
mtrace:
  - 2023-07-27
tags:
  - language/coding/kotlin
  - language/coding/java
  - question/coding/theory
---
# Unit, Nothing and Any

#date 2023-07-27

## Unit

在介绍Unit之前，我们先来看这样一个问题，这也是[[Study Log/java_kotlin_study/generics/generics_intro#变形|协变和逆变]]中涉及到的：

```java
class Fruit {}  
class Apple extends Fruit {}  
  
class Maker {  
	public Apple make() {  
		return new Apple();  
	}  
}  
  
class AppleMaker extends Maker {  
	@Override  
	public Fruit make() {  
		return new Fruit();  
	}  
}
```

这段代码违反了里氏替换原则：子类重写的方法的返回值应该比父类的更具体。所以，AppleMaker的make方法的返回值至少也要和父亲一样是Apple。而正常的逻辑其实应该是这样的：

```java
class Maker {  
	public Fruit make() {  
		return new Fruit();  
	}  
}  
  
class AppleMaker extends Maker {  
	@Override  
	public Apple make() {  
		return new Apple();  
	}  
}
```

那现在问题来了：*void又算是个什么*？首先考虑一下合不合理：子类可以返回void，也就是什么都不返回吗？很合理啊！因为我什么都不返回其实并不会破坏里氏替换原则，也并不会造成什么错误，我的需求就在这儿。但是，当我们试图实现的时候：

```java
class NothingMaker extends Maker {  
	@Override  
	public void make() {  
		return;  
	}  
}
```

![[Article/story/resources/Pasted image 20230727101828.png]]

显然，编译器拒绝我们这么做，我们只能返回Fruit的子类。那怎么办？在java中，我们有这两种解决方法：

1. 返回null

```java
class NothingMaker extends Maker {  
	@Override  
	public Fruit make() {  
		return null;  
	}  
}
```

2. 定义一个假类型

```java
class NothingMaker extends Maker {  
	@Override  
	public NoFruit make() {  
		return new NoFruit();  
	}  
}
```

> 当然，NoFruit的实现是用单例还是其他的无所谓。重点是**它必须也继承Fruit才可以**。

现在，我们来看看Kotlin到底有没有这样的问题。首先是违反里氏替换原则：

![[Article/story/resources/Pasted image 20230727102626.png]]

可见，kotlin也是不允许违反的。我们现在把代码改正，然后测试是否可以什么都不返回：

![[Article/story/resources/Pasted image 20230727103011.png]]

依然不可以！不过别着急，我们现在把两种语言的Maker类中的返回值都换一下：java的换成Object，kotlin的换成对应的Any看看。你应该已经预料到结果了：Kotlin更胜一筹。这是为什么呢？Unit明明是等价于void的，为什么这里Kotlin的版本就可以编译通过呢？我来画一张图：

![[Article/story/resources/Drawing 2023-07-27 10.34.07.excalidraw.png]]

**Unit是一个实实在在的类型，是Any的子类，而void本身就不是一个类型**！所以，并不是Kotlin违反了里氏替换原则，而是Kotlin让“什么也部返回”变成了一个“会返回东西”的形式。只不过返回的这个Unit我们不是很在意罢了。我们可以看看Unit的实现：

```kotlin
public object Unit {  
	override fun toString() = "kotlin.Unit"  
}
```

它其实就是一个单例类，没有什么特殊的。

![[Article/story/resources/Pasted image 20230727103849.png|500]]

而这也是之前为什么我能在LaunchedEffect()函数中传递Unit，在Kotlin Flow中发送Unit的原因了：

[[Article/story/2023-07-16#^94d033|2023-07-16]]

#TODO 

- [ ] Nothing, Any