---
mtrace:
  - 2023-10-26
tags:
  - question/coding/android
  - language/coding/kotlin
  - language/coding/java
  - question/coding
description: 安卓开发遇到的问题，bug，编译错误之类的。
---
# 安卓开发遇到的问题

## 2023-10-26

#date 2023-10-26

今天在编译项目的时候，报了个错，说androidx.activity:activity:1.8.0依赖于api34，我现在是api33。但是，我并没有直接依赖，并且我也不想把api升级。直到我找到了这篇文章：

[java - Dependency 'androidx.activity:activity:1.8.0' requires libraries or apps that depend on it to compile against version 34 or later of the Android APIs - Stack Overflow](https://stackoverflow.com/questions/77271961/dependency-androidx-activityactivity1-8-0-requires-libraries-or-apps-that-de)

看起来是因为这个库：

![[Study Log/android_study/resources/Pasted image 20231026200902.png]]

只能在api34才能用。所以要么降级它，要么升级api。我还是选择升级api了。

---

#TODO 

- [x] 这个感觉像是kotlin的bug？

看下面的代码：

![[Study Log/android_study/resources/Pasted image 20231026211955.png]]

其中这几个button的声明：

![[Study Log/android_study/resources/Pasted image 20231026212014.png]]

这里明明已经标了类型了。下面我删掉其中一个apply：

![[Study Log/android_study/resources/Pasted image 20231026212104.png]]

为什么呢？为什么删掉之后泛型里就不用加了呢？

好吧，我知道了，我是个傻逼。在等号右侧先操作完，才会把结果返回到左边。而只有返回到左边之后，类型推导才能工作。而执行到apply的时候，还在等号右边，还没到左边呢。。。。。