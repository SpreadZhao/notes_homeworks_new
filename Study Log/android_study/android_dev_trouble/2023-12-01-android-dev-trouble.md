---
title: by lazy的使用时机
date: 2023-12-01
---

# by lazy的使用时机

#date 2023-12-01

今天Review的时候，mt跟我说了一个问题。一个Settings，下发的是整个app生命周期内唯一的配置。代码如下：

```kotlin
enum class UIorPURE {
	UI, PURE
}

val uiAndPureConfig: Map<UIorPURE, Boolean>
	get() = when (uiAndPureSettings) {
		1 -> mapOf(UIorPURE.UI to true, UIorPURE.PURE to false)
		2 -> mapOf(UIorPURE.UI to false, UIorPURE.PURE to true)
		3 -> mapOf(UIorPURE.UI to true, UIorPURE.PURE to true)
		else -> mapOf(UIorPURE.UI to false, UIorPURE.PURE to false)
	}
```

其中uiAndPureSettings是一个Int，就不重要了。mt说这样做会有个问题。因为uiAndPureSettings是几，在程序启动时就已经确定了。这样的话，你多次get，其实拿到的是同一个map。不过，由于我这样写，每次拿到的map其实都不是同一个，但内容一样的map。所以这样会比较费性能和内存。

比较好的方式就是用lazy，当已经确定了是哪个map，就一直用这个就行。其实，lazy在使用的时候还有个模式，描述是否线程安全。我们这个例子里不需要，所以最终改成这样子：

```kotlin
val uiAndPureConfig: Map<UIorPURE, Boolean> by lazy(LazyThreadSafetyMode.NONE) {
	when (uiAndPureSettings) {
		1 -> mapOf(UIorPURE.UI to true, UIorPURE.PURE to false)
		2 -> mapOf(UIorPURE.UI to false, UIorPURE.PURE to true)
		3 -> mapOf(UIorPURE.UI to true, UIorPURE.PURE to true)
		else -> mapOf(UIorPURE.UI to false, UIorPURE.PURE to false)
	}
}
```