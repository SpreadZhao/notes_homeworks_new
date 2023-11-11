---
title: Delegation Usage
description: 委托的原理与应用
tags:
  - language/coding/kotlin
  - language/coding/java
  - question/coding/practice
  - rating/high
mtrace:
  - 2023-11-11
links:
  - https://www.bilibili.com/video/BV1tM411D7Sz/
---
# DELEGATION

## INTRODUCTION

为什么要用委托这个东西？我在学安卓的时候，就遇到过这个东西。当时是通过懒加载技术，也就是by lazy，可以让这个变量在用到的时候才初始化。那么，为什么偏偏需要by这个关键字呢？

另一个时刻，就是学到Compose的时候，在Composable函数中声明和UI相关的数据变量时，也要用by remember。这个又是什么意思呢？今天就来说说这个by到底是个什么东西。

## CLASS DELEGATION

我在西瓜视频的横屏作者详情页中，终于找到了能够使用它的机会。我来简单描述一下这块的逻辑。

先看看作者详情页，就是横批状态下点击作者头像弹出来的：

![[Study Log/java_kotlin_study/resources/Pasted image 20231111111019.png]]

这里面的数据在初始化的时候就会请求，然后每个视频都是一个Tab。

在这里，有个Provider的概念，它是网络和UI的中间层。我们可以理解为MVVM架构中的仓库层，但又不太一样。当网络请求的数据回来之后，存在Provider中，当UI层要获取数据时，从Provider里拿。所以，不像仓库层，这个Provider实际上还起着缓存的作用。

我们现在来模拟着写出一个这样的架构吧。首先是接口，这样的一个功能都会有什么接口呢？

```kotlin
interface IPLDataProvider<T> {
  fun queryData()
  fun getList(): List<T>
}
```

非常简单，一个查询数据的方法，一个从UI层拿请求结果的方法。这就意味着，我们在这个接口的实现类中，需要给出这样的一个list的具体实现。

下面来简单实现一个，得到播放列表的Provider：

```kotlin
class PlayListDataProvider : IPLDataProvider<Video> {

  private val _mData = ArrayList<Video>()

  override fun queryData() {
    _mData.addAll(fakeQueryFromNet())
  }

  override fun getList() = _mData

  private fun fakeQueryFromNet(): List<Video> {
    return listOf(
      Video(name = "因为一个bug，程序员在出租屋内结束自己的生命", duration = 1093, authorId = 123235235),
      Video(name = "Java第一次作业", duration = 125315, authorId = 3485927523875),
      Video(name = "你们使用的手机终端有哪些？", duration = 235235, authorId = 235235236236)
    )
  }
}
```

> 注意一下，这里使用了泛型，代表我们请求回来的不一定是Video，啥都行。

非常简单对吧！仅仅是拿到数据之后，塞到自己的list中而已。那么，除此之外呢？除了这个当前播放列表的实现，还有可能有的是相关视频。它们用的不同的接口，请求回来的数据也不一样。但是逻辑都是类似的，所以我们再实现一个：

```kotlin
class RelativeListDataProvider : IPLDataProvider<Video> {

  private val _mData = ArrayList<Video>()

  override fun queryData() {
    _mData.addAll(fakeQueryFromNet())
  }

  override fun getList() = _mData

  private fun fakeQueryFromNet(): List<Video> {
    return listOf(
      Video(name = "相关视频1", duration = 1093, authorId = 123235235),
      Video(name = "相关视频2", duration = 125315, authorId = 3485927523875),
      Video(name = "相关视频3", duration = 235235, authorId = 235235236236)
    )
  }

}
```

一模一样的实现。现在好了，我们已经有了两个IPLDataProvider的具体实现了。下一步，如果我想用，该咋办？最直接的做法，就是直接在ViewModel层或者UI层直接创建一个PlayListDataProvider或者RelativeListDataProvider，然后调用它们的queryData()方法。这个很容易想到。但是，*如果我有一些顾虑呢*？比如，==**我想在这中间再添加一些功能，比如我想给查询回来的数据排个序，比如我想根据某些条件过滤掉一些视频**==。。。这些功能又应该怎么实现呢？

```ad-hint
title: **委托就是这么来的！**

我想让我这个类的一部分功能完全沿用已经有的类。比如，我这个类是个List，那我就要实现List的接口对吧！但是，我说：“你这也太TM麻烦了！*我只是想在ArrayList的基础上稍微扩展一点功能，为啥又要我全部重写一遍*？”因此，Kotlin增加了一种简洁的方式，让我们能够很快做到这一点。
```


下面，来看看Kotlin是怎么做的：

```kotlin
class ProviderWrapper<T>(realProvider: IPLDataProvider<T>)
  : IPLDataProvider<T> by realProvider
```

一句话，搞定了！甚至我们还没写具体类的实现！如果我们换成Java的版本，应该是这样的：

```java
public class ProviderWrapperJava<T> implements IPLDataProvider<T> {
  
  private final IPLDataProvider<T> realProvider;
  
  ProviderWrapperJava(IPLDataProvider<T> realProvider) {
    this.realProvider = realProvider;
  }

  @Override
  public void queryData() {
    realProvider.queryData();
  }

  @NotNull
  @Override
  public List<T> getList() {
    return realProvider.getList();
  }
}

```

你看，ProviderWrapperJava实现了IPLDataProvider接口，就得实现里面的所有（两个）方法。然而，我不想实现呀！我只想在已经有的实现（PlayListDataProvider和RelativeListDataProvider）的基础上扩充一些功能。那么我又没有别的办法，只能保住一个真正的provider，然后重写方法的时候，按部就班地调用原来的实现。

**确实，这些都是废话**。因此，Kotlin帮我们省去了。

最后的测试方法，我们用起来就很舒服了：

```kotlin
class DelegationTest {
  companion object {
    fun test() {
      val playListProvider = ProviderWrapper(PlayListDataProvider())
      playListProvider.queryData()
      println(playListProvider.getList())

      val relativeListDataProvider = ProviderWrapper<Video>(RelativeListDataProvider())
      relativeListDataProvider.queryData()
      println(relativeListDataProvider.getList())
    }
  }
}
```

传一个真正的provider进去，这个wrapper就有它全部的功能了。虽然我们还没进行扩展，但是我已经能想到一万个能加的功能了。比如，排个序呀，过个滤呀。。。因为这都是List，我们只需要按照通用的格式去操作就可以了。

另外注意一点，这里我们用了泛型。意味着我们不止可以传Video，还可以传任何东西。比如User，String等等。。。而最后这个Wrapper中使用的泛型更是画龙点睛之笔。我们在具体实现的时候已经指定了泛型（在本例中是Video），所以测试的时候完全不用显式声明出来：

```kotlin
// 不用指出是Video，PlayListDataProvider已经指定了
val playListProvider = ProviderWrapper(PlayListDataProvider())
// 这里的Video完全没必要
val relativeListDataProvider = ProviderWrapper<Video>(RelativeListDataProvider())
```

还有一点，Java那个Wrapper的版本也是能使用的。但是，你要把它放在Java包里：

![[Study Log/java_kotlin_study/resources/Pasted image 20231111130719.png|300]]

不然，会报异常找不到类。因为kotlin目录下是不会搜索.java的文件的。[Java + Kotlin 混合编程，构建后找不到class文件_kotlin-classes\release文件夹不存在-CSDN博客](https://blog.csdn.net/tuilp1a/article/details/99691247)

## PROPERTY DELEGATION

by的用法到这里就为止了？没有。即使我们已经了解了上述过程，依然不知道lazy这玩意儿是怎么工作的！实际上，它用的是另一种委托：委托属性。和类的委托不一样，属性的委托更多是为了自定义它的get和set过程。比如懒加载，我们就让get的过程延迟到它第一次被访问的时候。那么如何写一个呢？来！

首先，我们要知道委托属性的写法：

```kotlin
val p by Delegation()
```

左边都很容易理解，那这个by到底起了什么作用呢？推导一下：我们必须要对p初始化对吧！Kotlin也不允许变量只声明但没有初始值。因此，**这个by一定起到一个初始化的作用**。那么下一个问题，咋初始化的？猜测，肯定是和右边的这个Delegation类有关，即**Delegation类中必定有这个p初始化的实现逻辑**。

有了这些猜想，再介绍起来才更清晰：实际上，by的作用就是调用Delegation里的getValue()方法，而这个方法的返回值的类型就是p的类型。

我们来实现一个自己的Delegation，MyLazy：

```kotlin
class MyLazy {
  operator fun getValue(myClass: Any?, prop: KProperty<*>): Int {
    return 123
  }
}
```

**没错！只要你的类中有一个getValue方法，就能用by了！**

那么，我们在使用的过程中，就可以这么写：

```kotlin
class MyLazyTest {
  private val lazyInteger by MyLazy()
}
```

非常好理解对吧！也就是说，这个lazyInteger就是123了。然而我们要注意，当你new出来一个MyLazyTest的时候，lazyInteger是123吗？**不是**！注意为什么叫做属性委托。Kotlin里，我们是可以将属性当作方法来用的，最常见的情况就是：

```kotlin
class MyViewModel() {
	private val _realLiveData = MutableLiveData<Int>()
	val liveData: LiveData<Int>
		get() = _realLiveData
}
```

这里的liveData变量是成员吗？是，**但是Kotlin的语法糖使得我们在用这个变量的时候，自动调用它的get()方法**，所以这个成员你已经不能把它当变量来用了，**它就是一个长得像变量的方法**！只是语法糖让它看起来像变量而已。

为什么说这些？你回头看这个lazyInteger，是不是很像啊！当我们用它的时候，自动会调用它委托的类的getValue()方法，这种写法难道不就是：

```kotlin
private val lazyInteger
  get() = 123
```

说实话，一模一样！但是但是但是！有个问题呀！这个自带的get()也太不灵活了！就比如我想要延迟初始化，它咋做到？做不到！因为你只是个get()方法，你存不了缓存，用不了骚操作，当其它人用你的时候，就是执行一下你这个get()方法，**我发挥的空间太小了**！

怎么办？你tm是不是也想到上面我们说的委托了？功能受限，我想要在此基础上扩展一下，但是又不想实现原来的那套逻辑？就是了！这两种方法最大的区别就是，==get()只是个写死的方法，我们没法往里加什么东西；而MyLazy是个实打实的类，我们可以通过非常灵活的手段用各种骚操作往里面塞东西，实现我们想要的功能==。

那么，lazy往里塞了什么东西呢？你猜也能才出来，肯定**至少塞了一个高阶函数进去呀**！也就是在lazy的大括号里写的那一坨逻辑。

现在看看，这个MyLazy到底该怎么实现：

```kotlin
class MyLazy<T>(val block: () -> T) {

  var value: T? = null

  operator fun getValue(myClass: Any?, prop: KProperty<*>): T {
    if (value == null) value = block()
    return value!!
  }
}
```

就是传入了一个高阶函数，然后在getValue里返回这个函数的返回值。而如果已经不是null了，那就返回这个缓存value。没什么好神秘的。

这玩意儿怎么用呢？很简单！

```kotlin
class MyLazyTest {
  private val lazyInteger by MyLazy {
    println("lazy start!")
    456
  }
}
```

这里我们要讲解一下类型推导的过程，也就是上面的泛型T究竟是怎么识别成Int的。起点其实是我们的代码段。我们传入了一个lambda表达式，而最后一行返回值，就是Int，这个信息被携带到了MyLazy的构造方法中：

![[Study Log/java_kotlin_study/resources/Pasted image 20231111135845.png]]

然后经过一次自动推导，这个MyLazy里面的T就全部替换成Int了。然后，当有人要使用这个lazyInteger的时候，就会调用**被委托对象**MyLazy的getValue()方法，==其实就是相当于原来的get()，一个更加灵活和强大的get()==。在这里面，我们判断这个缓存是否是null，如果是就代表没初始化过，而初始化的逻辑就是block，所以接上就行了；如果否那就直接返回缓存。

基本上结束了！最后还有一点，lazy是一个函数，而我们的MyLazy是一个方法。所以我们还可以再包装一层，加一个顶层方法：

```kotlin
fun <T> myLazy(block: () -> T) = MyLazy(block)
```

这下使用就真没啥差别了！

```kotlin
class MyLazyTest {
  private val lazyInteger by myLazy {
    println("lazy start!")
    456
  }

  fun useLazy() {
    val i = lazyInteger
    println("i = $i")
  }

  companion object {
    fun test() {
      val testLazyClass = MyLazyTest()
      Thread.sleep(3000)
      testLazyClass.useLazy()
    }
  }
}
```

这里我设置了初始化testLazyClass休息了三秒钟。而你在三秒钟之后，才会看到"lazy start!"这句话，这证明了确实是用到的时候才会调用getValue()方法的。

## SUMMARY

```ad-summary
最后做个总结。其实你可以看到，无论是类委托还是属性委托，出发点都是一样的：我想要一个更强大的，但是又不想实现一堆逻辑的类。而by其实也只是个语法糖，帮我们屏蔽了一些逻辑；而lazy方法只是属性委托的其中一个应用而已，它的使用只要涉及到了get()和set()，我们都是可以按照自己的需求进行更加强大的扩展的。

- [ ] #TODO 这里有时间看一下by remember的逻辑，应该就是我说的更加强大的扩展。
```