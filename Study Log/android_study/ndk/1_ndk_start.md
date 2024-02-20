---
title: 初次NDK
---

# 初次NDK

首先，建议看一下jni的入门：[[Study Log/java_kotlin_study/jni_start|jni_start]]。本次初见和这个jni的初见其实难度是差不多的。

用AndroidStudio新建一个Native的工程。会看到自动给我们生成了cpp的目录：

![[Study Log/android_study/ndk/resources/Pasted image 20240121171217.png]]

然后，我们在MainActivity里也能看到之前加载native动态链接库的影子：

```kotlin
companion object {
	// Used to load the 'nativestudy' library on application startup.
	init {
		System.loadLibrary("nativestudy")
	}
}
```

然后，在旁边我们就能看到这个默认给我们生成的HelloWorld的native方法：

```kotlin
/**
 * A native method that is implemented by the 'nativestudy' native library,
 * which is packaged with this application.
 */
external fun stringFromJNI(): String
```

> 关于`external`的作用：[Keywords and operators | Kotlin Documentation (kotlinlang.org)](https://kotlinlang.org/docs/keyword-reference.html#modifier-keywords)

显然，这个方法的实现就在cpp中。还记得对应的cpp的函数名是啥吗？

```
Java_包名_类名_方法名
```

所以，对应到我们这里，就应该是：

```cpp
Java_com_spread_nativestudy_MainActivity_stringFromJNI
```

来验证一下吧：

```cpp
JNICALL
Java_com_spread_nativestudy_MainActivity_stringFromJNI(
        JNIEnv *env,
        jobject thiz) {
    std::string hello = "Hello from C++";
    return env->NewStringUTF(hello.c_str());
}
```

之后我们观察一下，可以发现在cpp文件中，并没有include对应的.h文件，也就是我们之前用`javac -h`生成的那个。这是为什么呢？

- [ ] #TODO 我猜，是因为它把需要的include都放在这个cpp里面了。比如`extern "C"`。🔽 

另外，方法开头也没有了之前的`JNIEXPORT jstring`，也是放在了开头。

其它的其实就没什么了。下面，我们来稍微进阶一下，学一学怎么使用这里的这个`jobject`。在AndroidStudio中可以看到，这个`jobject`实际上就是MainActivity：

![[Study Log/android_study/ndk/resources/Pasted image 20240121174313.png]]

## 打印类名

所以，这个thiz对象我们应该怎么使用呢？在Java/Kotlin中，我们想要打印一个MainActivity的实例的类名，只需要这样：

```kotlin
// java
this.getClass().getName();
// kotlin
this.javaClass.name
```

比如在我们的例子中，它就应该输出：

```
com.spread.nativestudy.MainActivity
```

但是要注意，此时的这个thiz对象，是在c++中。因此我们不能用java的方式去调用它的方法。那么怎么办呢？显然，JNI给我提供了这样的接口，可以让我们在c++中去调用Java的方法。

```cpp
jclass jclass_mainActivity = env->GetObjectClass(thiz);
```

传入这个MainActivity的实例，我们通过JNIEnv的接口就可以拿到这个Java类在c++中对应的类——jclass。但是，这**并不等于**我们执行了`this.getClass()`。或者说，`GetObjectClass()`和`getClass()`本身没有任何关系！！！

这个问题困扰了我好久，最终我才想明白。要了解这个JNI执行的机制，我们要先看看Java的东西。

在Java中，所有的对象都是Object。而在Object中，就有`getClass()`这个方法：

```java
public final Class<?> getClass() {
  return shadow$_klass_;
}
```

要注意，这是一个Object的实例具有的方法。所以我们才可以在Java中在一个实例后面直接`.getClass()`。

但是问题是，*c++中能操作Java的实例吗*？显然是不能的。所以，~~<label class="ob-comment" title="JNIEnv中也根本没有`CallObjectMethod()`这样的接口" style=""> JNIEnv中也根本没有`CallObjectMethod()`这样的接口 <input type="checkbox"> <span style=""> 其实是有的。但是参数需要方法的id。这个id我们只能通过这个实例的jclass获取。 </span></label>~~。但是，如果我们想调用这个实例的方法，该怎么办呢？JNIEnv虽然不能直接调用Object实例的方法，**~~<label class="ob-comment" title="但是却可以做类似反射的操作" style=""> 但是却可以做类似反射的操作 <input type="checkbox"> <span style=""> 这个操作也不是反射。通过Object的Class获取的只是Class的方法。这里这么说只是因为我们要打印类名而已。JNI真正做的是通过这个object的jclass获取这个方法的id，然后通过这个id在这个object上调用这个方法。 </span></label>~~**：得到这个Object的Class，然后通过这个Class去寻找这个方法。

~~而`env->GetObjectClass(thiz)`返回的就是这样的东西。也就是这个MainActivity的类本身。而MainActivity是一个Object，自然里面会有`getClass()`方法。~~

#question `env->GetObjectClass(thiz)`相当于Java中的什么？我目前的感觉是，什么也不相当。网上说的相当于`getClass()`我觉得是**完全错误**的。jobject和jclass的关系本身就对应着Java中的Object和Class。而Object里面确实包含着Class，但是jobject里面却不包含jclass。所以这个`env->GetObjectClass`也不应该是将Object里的Class给返回。

这里还是画一个图会清晰些：

![[Study Log/android_study/ndk/resources/Drawing 2024-01-21 18.42.48.excalidraw.png]]

这才是`env->GetObjectClass`真正做的事情：仅仅是得到MainActivity这个Object的类信息（<label class="ob-comment" title=" 其实都不应该叫做Class，只是jclass" style=""> 其实都不应该叫做Class，只是jclass <input type="checkbox"> <span style=""> 或者我这么说吧。实际上这里面的每一个方框才是唯一对应着jclass的。像Object有一个jclass，MainActivity有一个jclass，Class也有一个jclass。但是只有Class这个jclass里面才有getName()这个方法。 </span></label>）。

最关键的一个问题：*我们得到的这个jclass，是Class吗*？**不是**！它是Object！这才是JNI的互操作中最容易被混淆的一个概念。也就是一些傻逼认为，jclass就是Class。

现在，让我们总结一下之前说过的一些东西：

* 之前我们说，`GetObjectClass()`和`getClass()`本身没有任何关系。这是因为，前者返回的是jclass，它仅仅代表Java中一个类的信息。可以是People, Activity, Object等等，也可以是Class。<label class="ob-comment" title="只有是Class的时候，才能根据这个Class去找里面的Field，方法等" style=""> 只有是Class的时候，才能根据这个Class去找里面的Field，方法等 <input type="checkbox"> <span style=""> 为啥？我之前都说过了。没有`CallObjectMethod()` </span></label>；而后者直接是在Java中返回这个Object内部的Class的实例。
* 之前我们说，~~可以做反射的操作~~：得到这个Object的Class，然后通过这个Class去寻找这个方法。那么问你，*`GetObjectClass()`是得到这个jobject的Class吗*？傻逼当然不是啦！只是得到这个jobject的jclass而已。如果你这个jobject本身（在Java中）还是一个Object，那么你得到的jclass也是一个Object，而不是Class。当然，在我们这个例子中，`GetObjectClass`返回的jclass对应的应该是MainActivity。

回过头来。既然它返回的是jclass而不是Class，那我咋拿到Class？别急。虽然Object不是Class，但Object里有Class。而Object这个jclass里面是能拿到`getClass()`这个方法的。所以：

```cpp
jclass jclass_mainActivity = env->GetObjectClass(thiz);
jmethodID method_getClass = env->GetMethodID(jclass_mainActivity, "getClass", "()Ljava/lang/Class;");
```

现在，我们相当于是拿到了一个指向MainActivity类中的`getClass()`方法的一个指针。所以下一步就是在thiz这个实例上调用这个方法：

```cpp
jclass jclass_mainActivity = env->GetObjectClass(thiz);
jmethodID method_getClass = env->GetMethodID(jclass_mainActivity, "getClass", "()Ljava/lang/Class;");
jobject classOf_MainActivity = env->CallObjectMethod(thiz, method_getClass);
```

这三步合起来，才相当于我们在Java中或者在Kotlin中调用：

```java
// java
this.getClass()
// kotlin
this.javaClass
```

对应到刚才那张图：

![[Study Log/android_study/ndk/resources/Drawing 2024-01-21 19.29.03.excalidraw.png]]

有了Class的实例，下一步是调用这个实例的getName()方法来获取类名。显然，这里我们是Class的实例，在c++里也是操作不了的。所以还是如法炮制。这里我就直接都给出来了：

```cpp
jclass jclass_mainActivityClass = env->GetObjectClass(classOf_MainActivity);
jmethodID method_getName = env->GetMethodID(jclass_mainActivityClass, "getName", "()Ljava/lang/String;");
jstring className = static_cast<jstring>(env->CallObjectMethod(classOf_MainActivity, method_getName));
```

对应到图上：

![[Study Log/android_study/ndk/resources/Drawing 2024-01-21 19.40.20.excalidraw.png]]

所以，其实我们能看到。如果我们只是想调用一个类里的一个方法。比如MainActivity里的某些方法，是不用这么费劲的。只需要三步。但是类名这个东西它就存在Object里的Class里。所以我们只能来上两遍。

最后，这个函数的全过程：

```cpp
JNICALL
Java_com_spread_nativestudy_MainActivity_stringFromJNI(
        JNIEnv *env,
        jobject thiz) {
    jclass jclass_mainActivity = env->GetObjectClass(thiz);
    jmethodID method_getClass = env->GetMethodID(jclass_mainActivity, "getClass", "()Ljava/lang/Class;");
    jobject classOf_MainActivity = env->CallObjectMethod(thiz, method_getClass);

    jclass jclass_mainActivityClass = env->GetObjectClass(classOf_MainActivity);
    jmethodID method_getName = env->GetMethodID(jclass_mainActivityClass, "getName",
                                                "()Ljava/lang/String;");
    jstring className = static_cast<jstring>(env->CallObjectMethod(classOf_MainActivity,
                                                                   method_getName));
    return className;
}
```

通常，在cpp中调用一个java对象的方法，就三步：

* 找到这个实例的jclass：GetObjectClass；
* 通过它的jclass找到目标方法的id：GetMethodId；
* 在实例上调用这个方法：CallObjectMethod。

当然，这里面你可能看到了一些`()Ljava/lang/Class;`这样的奇怪符号。这些先不管，之后会介绍。