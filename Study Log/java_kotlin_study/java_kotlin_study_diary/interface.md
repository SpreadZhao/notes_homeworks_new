---
mtrace:
  - 2023-07-15
tags:
  - language/coding/java
  - language/coding/kotlin
  - question/coding/practice
title: 接口能实例化吗
date: 2023-07-15
---
# 接口能实例化吗

我们经常能见到这样的代码：

```java
Test test = new Test() {  
	@Override  
	public void test1() {  
	  
	}  
}
```

我们将这段代码编译成字节码时，实际上是这样的：

```java
Test test = new Main$1(this);
```

其中的`Main$1`表示这是一个存在于类Main中的匿名内部类。所以，实际上是Java帮助我们隐藏了这样实现，而不是接口本身就能实例化。而Kotlin在这方面是完全一样的。

#TODO 

- [ ] 日记里遇到的问题要补齐