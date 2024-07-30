---
mtrace:
  - 2023-07-02
  - 2023-11-22
tags:
  - question/coding/practice
  - language/coding/kotlin
  - constructor
title: Kotlin构造函数中加val/var和不加有什么区别
date: 2023-07-02
---
# Kotlin构造函数中加val/var和不加有什么区别

[Kotlin中构造方法的参数var val 和 什么都没有的区别 - GLORY-HOPE - 博客园 (cnblogs.com)](https://www.cnblogs.com/gloryhope/p/10485515.html#:~:text=Kotlin%E4%B8%AD%E6%9E%84%E9%80%A0%E6%96%B9%E6%B3%95%E7%9A%84%E5%8F%82%E6%95%B0var%20val%20%E5%92%8C%20%E4%BB%80%E4%B9%88%E9%83%BD%E6%B2%A1%E6%9C%89%E7%9A%84%E5%8C%BA%E5%88%AB%201.%E4%BB%80%E4%B9%88%E9%83%BD%E6%B2%A1%E6%9C%89%2C%E5%9C%A8%E8%AF%A5%E7%B1%BB%E4%B8%AD%E4%BD%BF%E4%B8%8D%E8%83%BD%E4%BD%BF%E7%94%A8%E7%9A%84%2C%20%E8%BF%99%E4%B8%AA%E5%8F%82%E6%95%B0%E7%9A%84%E4%BD%9C%E7%94%A8%E5%B0%B1%E6%98%AF%2C%E4%BC%A0%E9%80%92%E7%BB%99%E7%88%B6%E7%B1%BB%E7%9A%84%E6%9E%84%E9%80%A0%E6%96%B9%E6%B3%95,2.%E4%BD%BF%E7%94%A8var%20%E5%8F%AF%E4%BB%A5%E5%9C%A8%E7%B1%BB%E4%B8%AD%E4%BD%BF%E7%94%A8%2C%E7%9B%B8%E5%BD%93%E4%BA%8E%20%E6%88%91%E4%BB%AC%E5%A3%B0%E6%98%8E%E4%BA%86%E4%B8%80%E4%B8%AA%E8%AF%A5%E7%B1%BB%E4%B8%AD%E5%AE%9A%E4%B9%89%E4%BA%86%E4%B8%80%E4%B8%AAprivate%20%E7%9A%84%E6%88%90%E5%91%98%E5%8F%98%E9%87%8F%203.val%E8%A1%A8%E7%A4%BA%E4%B8%8D%E8%AE%A9%E4%BF%AE%E6%94%B9%E8%AF%A5%E5%8F%82%E6%95%B0%20%E5%8A%A0%E4%B8%8A%E4%BA%86final%20%E4%BF%AE%E9%A5%B0%E7%AC%A6)

加了val或者var，就表示这个参数可以在函数中使用。而如果不加那么就只能作为传递给父类用于构造，而不能在这个类的内部使用：

![[Article/story/resources/Pasted image 20230702225926.png]]

如上图中的`context`成员就不能在类的内部使用。

#date 2023-11-23

遇到了一个例子。下面是一个抽象类：

```kotlin
abstract class XDPartnerResponse<DATA>(
  val code: Int,
  val data: DATA,
  val msg: String
)
```

这个类其实是data class。但是我有个需求，因为我所有的response都是这个格式的，所以字段是复用的。只不过是这个data的类型不一样。所以这里我选择用泛型来配置。然后子类就是data class，继承它这一招从这里学的：[Kotlin data class 遇到的坑及解决方案 - 简书 (jianshu.com)](https://www.jianshu.com/p/a98156d08337)

比如其中一个子类：

```kotlin
data class ThreadsResponse(
  @SerializedName("code") val code: Int,
  @SerializedName("data") val data: List<ThreadMeta>,
  @SerializedName("msg") val msg: String
) : XDPartnerResponse<List<ThreadMeta>>(code, data, msg)
```

**但是这样写是报错的**！错误如下：

![[Study Log/java_kotlin_study/resources/Pasted image 20231122235929.png]]

就是因为父类里面加了val，导致这三个字段变成了成员，不是仅仅用于构造的字段。所以要把抽象父类里的val去掉：

```kotlin
abstract class XDPartnerResponse<DATA>(
  code: Int,
  data: DATA,
  msg: String
)
```

但是有个问题，就是如果不加val就用不了，那我要这个属性有何用？

这个其实不适合在这个例子里说。因为data class比较特殊，它构造方法里所有的变量必须都加上val，也就是说，**所有构造data class的字段都必须是成员**。而普通的类没有这个要求，所以普通的类在继承时，val的添加会更加灵活。