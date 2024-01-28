---
title: Backing Field in Kotlin
date: 2024-01-28
tags:
  - "#language/coding/kotlin"
mtrace:
  - 2024-01-28
---

# Backing Field in Kotlin

#date 2024-01-28

* [Properties | Kotlin Documentation (kotlinlang.org)](https://kotlinlang.org/docs/properties.html#backing-properties)
* [[Kotlin]深入理解backing field_kotlin backing filed-CSDN博客](https://blog.csdn.net/apple337008/article/details/79275426)

如果是在传统java中，有一个成员，你只想外部能get，但是不能外部set，只能在内部set。那么通常是这么写的：

```kotlin
class BackingField {  
    private var age: Int = 0  
  
    fun getAge(): Int {  
        return age  
    }  
}
```

但是kotlin中有更优雅的写法：

```kotlin
class BackingField {  
    var age: Int = 0  
        private set  
}
```

在外部尝试设置age的值的话就会报错：

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/Pasted image 20240128185926.png]]

那么，对于某些属性。比如RecyclerView有个setAdapter()方法，我们先来看看它的实现：

```java
public void setAdapter(@Nullable Adapter adapter) {
	// bail out if layout is frozen
	setLayoutFrozen(false);
	setAdapterInternal(adapter, false, true);
	processDataSetCompletelyChanged(false);
	requestLayout();
}
```

也就是说，**除了设置自己的mAdapter之外，还有一些其他的操作**。这种setter可以抽象为：

```kotlin
class BackingField {  
    private var age: Int = 0  
    fun setAge(age: Int) {  
        this.age = age      // 设置自己的成员  
        doOthers()          // 做一些其他的事情  
    }  
      
    private fun doOthers() {  
        // something  
    }  
}
```

那么对于这种，kotlin应该怎么写呢？这个时候就用到setter的定制了：

```kotlin
class BackingField {  
    var age: Int = 0  
        set(value) {  
            field = value       // 设置自己的成员  
            doOthers()          // 做一些其它的事情  
        }  
  
    private fun doOthers() {  
        // something  
    }  
}
```

这里终于到了本文的重点：这个`field`是什么？为什么用field而不是age？

我们稍微思考一下，显然，field表示的就是这个age。那么为什么要写`field = value`而不是`age = value`呢？要回答这个问题，我们先想一想如果我们想要在外部设置这个age，是咋写的：

```kotlin
fun main() {
	val bf = BackingField()
	bf.age = 10
}
```

这么写，很简单对吧！现在你瞅一瞅，如果我们在setter里写`age = value`的话，和这里写的`bf.age = 10`有啥区别？**没区别**！因此，Kotlin在遇到`xxx.age = 10`的时候，就会调用自己的setter来赋值。那么，如果你在setter里面调用了setter，那就直接递归导致StackOverFlow了：

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/Pasted image 20240128190823.png]]

最后，getter和setter的访问限制一定要等于属性本身的限制，或者比属性本身的限制更严格。比如这样就会报错：

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/Pasted image 20240128191141.png]]

道理也很简单，**getter和setter被认为是属性的一部分**。那么如果属性本身都不让外部访问，那凭什么让setter能被外部访问呢？

# Backing Properties

额外多说一句。这个也很常见。比如LiveData里就有可变的和不变的，我们get的时候最好get不变的那个。这种在Kotlin里都是定义两个属性：

```kotlin
private var _table: Map<String, Int>? = null
public val table: Map<String, Int>
	get() {
		if (_table == null) {
			_table = HashMap()
		}
		return _table ?: throw AssertionError("Set to null by another thread")
	}
```