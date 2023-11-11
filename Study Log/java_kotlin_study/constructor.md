---
mtrace:
  - 2023-07-02
tags:
  - question/coding/practice
  - language/coding/kotlin
---
# Kotlin构造函数中加val/var和不加有什么区别

[Kotlin中构造方法的参数var val 和 什么都没有的区别 - GLORY-HOPE - 博客园 (cnblogs.com)](https://www.cnblogs.com/gloryhope/p/10485515.html#:~:text=Kotlin%E4%B8%AD%E6%9E%84%E9%80%A0%E6%96%B9%E6%B3%95%E7%9A%84%E5%8F%82%E6%95%B0var%20val%20%E5%92%8C%20%E4%BB%80%E4%B9%88%E9%83%BD%E6%B2%A1%E6%9C%89%E7%9A%84%E5%8C%BA%E5%88%AB%201.%E4%BB%80%E4%B9%88%E9%83%BD%E6%B2%A1%E6%9C%89%2C%E5%9C%A8%E8%AF%A5%E7%B1%BB%E4%B8%AD%E4%BD%BF%E4%B8%8D%E8%83%BD%E4%BD%BF%E7%94%A8%E7%9A%84%2C%20%E8%BF%99%E4%B8%AA%E5%8F%82%E6%95%B0%E7%9A%84%E4%BD%9C%E7%94%A8%E5%B0%B1%E6%98%AF%2C%E4%BC%A0%E9%80%92%E7%BB%99%E7%88%B6%E7%B1%BB%E7%9A%84%E6%9E%84%E9%80%A0%E6%96%B9%E6%B3%95,2.%E4%BD%BF%E7%94%A8var%20%E5%8F%AF%E4%BB%A5%E5%9C%A8%E7%B1%BB%E4%B8%AD%E4%BD%BF%E7%94%A8%2C%E7%9B%B8%E5%BD%93%E4%BA%8E%20%E6%88%91%E4%BB%AC%E5%A3%B0%E6%98%8E%E4%BA%86%E4%B8%80%E4%B8%AA%E8%AF%A5%E7%B1%BB%E4%B8%AD%E5%AE%9A%E4%B9%89%E4%BA%86%E4%B8%80%E4%B8%AAprivate%20%E7%9A%84%E6%88%90%E5%91%98%E5%8F%98%E9%87%8F%203.val%E8%A1%A8%E7%A4%BA%E4%B8%8D%E8%AE%A9%E4%BF%AE%E6%94%B9%E8%AF%A5%E5%8F%82%E6%95%B0%20%E5%8A%A0%E4%B8%8A%E4%BA%86final%20%E4%BF%AE%E9%A5%B0%E7%AC%A6)

加了val或者var，就表示这个参数可以在函数中使用。而如果不加那么就只能作为传递给父类用于构造，而不能在这个类的内部使用：

![[Article/story/resources/Pasted image 20230702225926.png]]

如上图中的`context`成员就不能在类的内部使用。