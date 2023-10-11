---
mtrace:
  - 2023-07-15
tags:
  - language/coding/kotlin
  - question/coding/practice
  - question/interview
  - rating/basic
---
# Kotlin的SAM

我们从View的onClickListener说起。在Kotlin中，我们可以直接这么写：

```kotlin
button.setOnClickListener {
	// 点击按钮后的逻辑
}
```

那么为什么能这么写呢？我们看一看逻辑。setOnClickListener中只有一个参数，这个参数的类型是OnClickListener。而它是一个接口，里面只有一个onClick方法。所以，我们在Lambda表达式中写的逻辑就是在重写这个唯一的onClick方法。

既然如此，我们在Kotlin里也这样写不也行？所以我想当然地，进行了这样的操作：

```kotlin
interface OnChangeListener {
	fun onChange()
}

fun setOnChangeListener(listener: OnChangeListener) {
	listener.onChange()
}

xxx.setOnChangeListener {
	// 试图重写onChange方法
}
```

**报错了**！为什么？而如果我向Java一样，将这个逻辑改成匿名类的写法，就没问题了：

```kotlin
xxx.setOnChangeListener(object : OnChangeListener {
	override fun onChange() {
		// 重写onChange方法
	}
})
```

凭啥？我的实现逻辑明明是和Java一样的，为啥你不让我用这种写法呢？我的疑问，直到看到了SAM究竟是什么才打消。

实际上，SAM可以理解为一种，**能将Lambda表达式转化成一个实现了一个单方法接口的匿名类的一种底层实现**。这句话听起来有点拗口，所以我还是详细说明一下：

我们在调用button的setOnClickListener中时，是这样写的：

```kotlin
button.setOnClickListener {
	// 点击按钮后的逻辑
}
```

而我们都知道，这实际上运用了Kotlin的一些Lambda表达式的机制，也叫[[Article/story/2023-05-04#4.2 Functional API|函数式API]]。看了这个之后，你就会知道，上面的写法实际上是将一个Lambda表达式作为**实参**传递进去了。

然而，如果没有SAM机制的话，这样做是错误的！因为，我要的参数是一个OnClickListener，而你却给我传了一个Lambda表达式进来，这怎么能行呢？然而，如果有了SAM机制，情况就不一样了。SAM一瞅：欸？你传进来的是一坨逻辑（也就是Lambda），而我需要的是一个接口，然而巧的是，**我的这个接口里只有一个要实现的方法**。那么我给你在底层实现一个匿名类然后实现这个接口，**把你传进来的lambda来填到那个接口的唯一方法里面去**，不就大功告成了吗？！

这就是SAM机制产生的原因，而这样我们就可以快速地实现一个单方法的接口的匿名类，而不用我们自己写逻辑了。**注意，这是给Java独享的**，Kotlin是没有这样的机制的。

嗯？你可能又要问了，凭啥给别的语言这样好的机制，我们自己没有呢？傻孩子，怎么可能没有，不但有，我们还更高级。之所以Kotlin中没有这样的机制，是因为Kotlin里有[[Article/story/2023-05-05#6. Higher-Order Functions|高阶函数]]这个东西。你想想：*Java要想让一坨逻辑作为参数，唯一的办法就是手动实现一个单方法的接口*。而Kotlin里本身就带这玩意儿，那凭啥还要走那弯弯绕呢？！

于是，我们将上面错误的实例改成下面的实现方式，就大功告成了：

```kotlin
// typealias要写在类的外面
typealias OnChangeListener = () -> Unit

fun setOnChangeListener(listener: OnChangeListener) {
	listener.onChange()
}

xxx.setOnChangeListener {
	// 直接传Lambda，重写个屁！
}
```

在上面的写法中，我们直接将这个逻辑作为了参数，也就根本不需要手动重写什么接口了。而这点就是Kotlin比Java要更高级的原因之一。

另外补充一点，Kotlin里的单方法接口，也是可以转换成Lambda表达式的。只不过不是在传参的时候，而是在赋值的时候。可以看下面的文章：

[函数式接口（SAM 接口） - Kotlin 语言中文站 (kotlincn.net)](https://www.kotlincn.net/docs/reference/fun-interfaces.html)

文章中介绍的，也是系统底层为我们屏蔽了匿名类实现的逻辑，从而直接将一个匿名类赋值给我们的变量，而不需要我们自己去实现这个匿名类的逻辑。
