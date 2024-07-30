---
description: 你见过这种错误吗？
title: 不能在构造方法里调用非final的方法！
mtrace:
  - 2023-11-29
date: 2023-11-29
tags:
  - language/coding/java
  - constructor
---

# Calling Non-final Function in Constructor

不知道你有没有这种需求：**父类里有个属性需要初始化，但是初始化的逻辑是交给子类的**。在我那个需求中，之所以要这样做，是因为这个父类和子类在不同的仓库里，实际上是多仓开发。父类在子仓中，子类在主仓中。而我需要的那个配置属性也在子仓里，但是配置要写入的地方在父类，子仓。所以这就导致，如果我直接在父类里初始化这个配置的话，是报错的，因为根本拿不到在主仓中的那个引用。

所以我选择了这种方式。代码就类似下面的：

```kotlin
abstract class Config {
  private val realConfig = getConfig()
  abstract fun getConfig(): Int
}
```

这是父类的代码，这个realConfig就是我要赋值的东西，但是等号右边的逻辑在另一个仓库里，所以只能交给他的子类来做了。

而子类的实现其实也很简单：

```kotlin
class TimeConfig : Config() {
  override fun getConfig(): Int {
    return 1
  }
}

class PeopleConfig : Config() {
  override fun getConfig(): Int {
    return 2
  }
}
```

就大概是这样的，两个类分别给出自己的配置就好了，这样这个realConfig就能在不同的实现中走到各自的子类里去了。思路是没问题的，但是报错了：

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/Pasted image 20231128234931.png]]

意思就是说，你要是在构造方法里调用一个不是final（能被重写）的方法，那么就会有这样的错误。我改一下，放到init代码块里，还是一样的错误：

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/Pasted image 20231128235119.png]]

这个解决方法其实简单：**不在构造方法里调它就完了呗**！所以，改成这样：

```kotlin
abstract class Config {
  private var realConfig = 1
  fun initConfig() {
    realConfig = getConfig()
  }
  abstract fun getConfig(): Int
}
```

这样就不报错了，但是要注意得手动调一下initConfig()方法。

问题解决了！但是，*为啥会这样*？说严重点，甚至会产生空指针异常！所以，这个问题是一定要避免的。首先，看一下之前我写的文章：[[Study Log/java_kotlin_study/java_kotlin_study_diary/constructors_and_static_classes|constructors_and_static_classes]]，主要看父类和子类的构造方法调用的顺序。

然后，看一下这篇解释：[java - Kotlin calling non final function in constructor works - Stack Overflow](https://stackoverflow.com/questions/50222139/kotlin-calling-non-final-function-in-constructor-works)

你应该明白了！不明白我再说一遍：

```kotlin
open class Base {
    open val size: Int = 0
    init { println("size = $size") }
}

class Derived : Base() {
    val items = mutableListOf(1, 2, 3)
    override val size: Int get() = items.size
}
```

在上面的代码里，当你new出来一个Derived的时候，必定会报空指针！为啥？当你在执行Derived的构造方法时，**Base的构造方法会最先执行**。那这个时候就会走到Base的init块里。这个时候，就要读size，那一看size是open，那就自然会往子类走，然后走到子类的items.size。问题来了：*这个时候items存在吗*？**不存在呀**！连Base都没初始化完呢，咋可能走到Derived里？所以，这时items就是null，然后你调用null.size，一个NullPointerException就糊你脸上了。