---
title: 简单计时器
---
[Java Native Interface Specification: 5 - The Invocation API](https://docs.oracle.com/en/java/javase/17/docs/specs/jni/invocation.html)

# 1 改造

## 1.1 Fragment

简单做一个计时器。但是在这之前先改造一下主页，变成Fragment的形式。

```xml
<androidx.drawerlayout.widget.DrawerLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:id="@+id/drawer_main"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    tools:context=".MainActivity">

	<!-- 这是自己加的Toolbar。 -->
    <FrameLayout
        android:layout_width="match_parent"
        android:layout_height="match_parent">

        <com.google.android.material.appbar.MaterialToolbar
            android:layout_width="match_parent"
            android:layout_height="?attr/actionBarSize" />
    </FrameLayout>

	<!-- 用来装所有的Fragment -->
    <FrameLayout
        android:id="@+id/fragment_container"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        />

	<!-- DrawerLayout左侧的NavigationView -->
    <com.google.android.material.navigation.NavigationView
        android:id="@+id/main_nav"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_gravity="start"
        app:menu="@menu/nav_menu" />

</androidx.drawerlayout.widget.DrawerLayout>
```

这里面有几点需要注意。首先是这个NavigationView的menu，在`res/menu`目录下创建：

![[Study Log/android_study/ndk/resources/Pasted image 20240210223248.png]]

然后最重要的是这个NavigationView的位置：[NavigationView导航视图与DrawerLayout绘制布局_navigationview getmenu-CSDN博客](https://blog.csdn.net/m0_57150356/article/details/134332218)。DrawerLayout也是按照Z轴摆放子View的。所以如果NavigationView不是最后一个子View，那么就不会响应触摸事件。

切换Fragment的核心逻辑：

```kotlin
private fun switchToFragment(fg: Fragment) {
	val fm = supportFragmentManager
	fm.beginTransaction()
			.replace(R.id.fragment_container, fg)
			.commit()
}
```

给它一个Fragment就能切换。所以，我们每次选中一个item，就创建一个对应的Fragment就可以了：

```kotlin
private val navListener = OnNavigationItemSelectedListener { item ->
	drawer.closeDrawers()
	val newFragment = when (item.itemId) {
		R.id.menu_item_simple_class_name -> SimpleClassNameFragment()
		R.id.menu_item_simple_timer -> SimpleTimerFragment()
		else -> null
	}
	newFragment?.let { switchToFragment(it) }
	true
}
```

接下来，我们去关心每个Fragment中的逻辑就可以了。

## 1.2 Multiple Native Libs

怎么拆分成多个`.cpp`文件？做一个通用的.h：

![[Study Log/android_study/ndk/resources/Pasted image 20240210224114.png]]

然后，每个.cpp都依赖这个.h就好了。但是，在CMakeLists.txt里面需要配置上对应的.cpp文件：

```cmake
add_library(${CMAKE_PROJECT_NAME} SHARED
        # List C/C++ source files with relative paths to this CMakeLists.txt.
        simple_class_name.cpp
        simple_timer.cpp
        )
```

[java - C++ std::string to jstring with a fixed length - Stack Overflow](https://stackoverflow.com/questions/27303316/c-stdstring-to-jstring-with-a-fixed-length)

# 2 Simple Things

首先，是两个比较简单的功能：

* 得到当前CPU的架构；
* 得到当前的系统时间。

通过两个external函数：

```kotlin
private external fun getDescription(): String  
private external fun requestForCurrTime()
```

但是我们通过观察可以看到，这两个函数的工作方式是不同的。前者是将一个字符串返回，后者是一个reqeust。其实，后者相当于向c++层发送一个请求，之后C++层会调用我们的回调：

```kotlin
/**
 * 由C++回调，设置当前时间。
 */
@Keep
private fun setCurrTime(time: String) {
	timeView.text = time
}
```

## 2.1 Architecture

首先从简单的开始。这个函数的实现和[[Study Log/android_study/ndk/1_ndk_start|1_ndk_start]]中的几乎一样：

```cpp
extern "C"
JNIEXPORT jstring
JNICALL
Java_com_spread_nativestudy_fragments_SimpleTimerFragment_getDescription(JNIEnv *env,
                                                                         jobject thiz) {
#if defined(__arm__)
#if defined(__ARM_ARCH_7A__)
#if defined(__ARM_NEON__)
#if defined(__ARM_PCS_VFP)
#define ABI "armeabi-v7a/NEON (hard-float)"
#else
#define ABI "armeabi-v7a/NEON"
#endif
#else
#if defined(__ARM_PCS_VFP)
#define ABI "armeabi-v7a (hard-float)"
#else
#define ABI "armeabi-v7a"
#endif
#endif
#else
#define ABI "armeabi"
#endif
#elif defined(__i386__)
#define ABI "x86"
#elif defined(__x86_64__)
#define ABI "x86_64"
#elif defined(__mips64) /* mips64el-* toolchain defines __mips__ too */
#define ABI "mips64"
#elif defined(__mips__)
#define ABI "mips"
#elif defined(__aarch64__)
#define ABI "arm64-v8a"
#else
#define ABI "unknown"
#endif
    return env->NewStringUTF("Hello from JNI !  Compiled with ABI " ABI ".");
}
```

这里的一堆if的宏就是在判断架构。这种代码我们在浏览器内核，os内核之类的项目中经常都会看见。最后，在我们的手机上，这个函数返回的ABI就是`arm64-v8a`。

## 2.2 Get Curr Time

现在，我们来一个新操作，也就是获取当前的时间。并且，我们要通过回调的方式在Java层将获取到的字符串设置到TextView上。

首先，获取当前时间的一种C++的方式：

```cpp
std::string getCurrTimeStr() {
    auto now = std::chrono::system_clock::now();
    auto now_c = std::chrono::system_clock::to_time_t(now);
    std::tm *local_now = std::localtime(&now_c);
    std::stringstream ss;
    ss << "curr time: " << std::put_time(local_now, "%Y-%m-%d %H:%M:%S");
    return ss.str();
}
```

这里面需要的额外的库：

```cpp
#include <chrono>  
#include <ctime>  
#include <sstream>  
#include <iomanip>
```

最后，`ss.str()`就是c++中的string类型的时间，而`ss.str().c_str()`得到的就是c中的`char *`类型的时间字符串。

现在，我们来看看怎么做回调。

1. 得到当前的时间字符串；
2. 将当前的字符串转换成jstring类型。这样才能传到java方法中；
3. 找到java中的这个方法，并调用它，传入时间jstring。

第一步：

```cpp
const std::string curr_time = getCurrTimeStr();  
LOGI("%s", curr_time.c_str());
```

第二步：

```cpp
jstring stdStringToJString2(JNIEnv *env, const std::string &str) {
    return env->NewStringUTF(str.c_str());
}

jstring curr_time_j = stdStringToJString2(env, curr_time);
```

第三步：

这两步都很简单。下面我们来着重说一说怎么得到回调方法。其实和[[Study Log/android_study/ndk/1_ndk_start|1_ndk_start]]中的方法一模一样，都是：

1. 通过jobject得到里面的jclass；
2. 在jclass里找到这个方法的id；
3. 通过CallMethodId在jobject上调用这个方法。

第一步：

```cpp
jclass clz = env->GetObjectClass(thiz);
```

第二步：

```cpp
jmethodID setCurrTime = env->GetMethodID(clz, 
									 "setCurrTime", 
									 "(Ljava/lang/String;)V");
```

这里就需要好好说说之前我们没提的Java方法的Signature了：[Java Native Interface Specification: 3 - JNI Types and Data Structures](https://docs.oracle.com/en/java/javase/17/docs/specs/jni/types.html#type-signatures)

通过官方的文档，我在这里总结一下，如何写出一个方法的签名：

1. 一个方法的关键点包括方法名，参数类型，返回值类型；
2. 方法名在GetMethodId的第二个参数中；
3. 我们只需要确定返回值类型和参数类型，就能唯一定位一个方法；
4. 总体的结构是：`(参数类型)返回值类型`。

比如有下面的java方法：

```java
long f(int n, String s, int[] arr);
```

所以括号里的就应该是：`int`，`String`和`int[]`，最后括号外面是`long`。

查阅表格，我们看一看具体怎么写。

* `int`的签名是`I`；
* `String`因为不是基本类型，所以需要写全类名。类名的写法是`L类名;`，所以`String`最后的签名是`Ljava/lang/String;`；
* 最后`int[]`的签名是`[I`。

所以，括号里的就应该是拼起来： `(ILjava/lang/String;[I)`。再加上最后的返回值`long`的签名是`J`，最后的答案是：

```
(ILjava/lang/String;[I)J
```

现在回头看我们`setCurrTime`方法，就很简单了吧！

最后，在jobject上调用这个方法：

```cpp
env->CallVoidMethod(thiz, setCurrTime, curr_time_j);
```

结束！这样我们就能在手机上看到最后的结果了：

![[Study Log/android_study/ndk/resources/Pasted image 20240211144914.png|300]]

> 那两个按钮不要管，我们之后再说。

# 3 Timer

## 3.1 Before Timer

在开始写计时器之前，我们需要明确一些事情：

1. 计时器由子线程进行计时；
2. 子线程的计时逻辑是什么；
3. 子线程去计时会不会产生什么问题；
4. 如何将数据传递给子线程。

### 3.1.1 AttachCurrentThread

首先，用子线程计时的操作如下：

```cpp
// 创建线程标识符
pthread_t th;
// 创建并启动线程，参数按需传入。StartTimer是计时器的工作函数
pthread_create(&th, nullptr, StartTimer, &context);  
// main线程等待th结束
pthread_join(th, nullptr);
```

那么，这个过程中会出现什么问题呢？要回答这个问题，我们要先看看这个线程的需求是什么。

th的工作，其实就是每一秒钟进行一次更新时间的操作。既然如此，那么这个线程一定是需要获取到Java中的某些方法或者变量的。那么，这个新创建出来的线程具有这样的能力吗？答案是否定的：[Java Native Interface Specification: 5 - The Invocation API](https://docs.oracle.com/en/java/javase/17/docs/specs/jni/invocation.html#attaching-to-the-vm)
根据官网的介绍我们知道，一个线程想要访问Java虚拟机中的内容，一定要调用`AttachCurrentThread()`这个函数。我们来看看这个函数是什么样子的：[Java Native Interface Specification: 5 - The Invocation API](https://docs.oracle.com/en/java/javase/17/docs/specs/jni/invocation.html#attachcurrentthread)

当获取成功之后，我们就能获取到Java侧的JNIEnv。它是通过放到传入的参数里实现的，所以我们要给它一个空间去存放：

```cpp
JNIEnv *env;  
// 这里的jvm是什么？我们之后会介绍。
res = jvm->AttachCurrentThread(&env, nullptr);
```

如果返回值是`JNI_OK`的话，就代表attach成功了。这样，之后我们在使用`env->xxx`的时候才是正确的。而如果没有这个attach操作，程序会收到signal 11错误：

```verilog
Fatal signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 0x0 in tid 19033 (ead.nativestudy), pid 18991 (ead.nativestudy)
```

### 3.1.2 Global Reference

另一个问题，是关于jclass和jobject的。由于在StartTimer内部我们需要回调Fragment中的方法，因此我们需要将native方法中引入的jobject暴露给这个线程。

不管用什么方式都可以。这里我首先采用全局变量的方式：

```cpp
typedef struct tick_context {
	... ...
    jclass simpleTimerClz;
    jobject simpleTimerObj;
} TickContext;

TickContext context;
```

在native接口方法中对这些成员赋值，之后在线程中就能访问到了：

```cpp
extern "C"
JNIEXPORT void JNICALL
Java_com_spread_nativestudy_fragments_SimpleTimerFragment_startTimer(JNIEnv *env, jobject thiz) {
	... ...
	// 往全局变量里写
    context.simpleTimerClz = env->GetObjectClass(thiz);
    context.simpleTimerObj = thiz;
    pthread_t th;
    // 之后StartTimer中会对context进行访问
    pthread_create(&th, nullptr, StartTimer, nullptr);
    pthread_join(th, nullptr);
}
```

这样看起来没啥问题对吧！我们不用给th传参数，在StartTimer里面也能访问到全局的context里面的内容：

```cpp
void *StartTimer(void * p) {
	// 获取Java中SimpleTimerFragment#updateTime方法
	jmethodID updateTime = env->GetMethodID(context->simpleTimerClz, "updateTime", "()V");
	everySecond { // 伪代码，每一秒钟触发
		// updateTime() every second!!!
		env->CallVoidMethod(context->simpleTimerObj, updateTime);
	}
}
```

这样挺好，对吧！但是，这样做其实是会报错的：

```verilog
JNI DETECTED ERROR IN APPLICATION: JNI ERROR (app bug): jclass is an invalid local reference: 0x7a400f7029 (reference outside the table: 0x7a400f7029)
... ...
Fatal signal 6 (SIGABRT), code -1 (SI_QUEUE) in tid 18877 (Thread-2), pid 18824 (ead.nativestudy)
... ...
```

* [Android Developers Blog: JNI Local Reference Changes in ICS](https://android-developers.googleblog.com/2011/11/jni-local-reference-changes-in-ics.html)
* [Local and Global References](https://www.cis.upenn.edu/~bcpierce/courses/629/papers/Java-tutorial/native1.1/implementing/refs.html)
* [Java Native Interface Specification: 2 - Design Overview](https://docs.oracle.com/en/java/javase/17/docs/specs/jni/design.html#global-and-local-references)

通过这些文章，我们能发现，我们默认创建的jclass和jobject（其实jclass就是jobject的『子类』）都是**local reference**。因为如果不这样管理，native的内存就全乱套了。而local reference的有效周期：

1. 当前线程有效；
2. 在调用`DeleteLocalRef()`之前有效；
3. 更常见的情况，在你当前native函数返回之前有效。

因此，在`Java_com_spread_nativestudy_fragments_SimpleTimerFragment_startTimer`方法中，这个函数返回之后，`simpleTimerClz`和`simpleTimerObj`就都失效了。

解决方法也很简单：变成**global reference**就好咯！之后我们在其它的时机手动释放就可以了。修改之后的`Java_com_spread_nativestudy_fragments_SimpleTimerFragment_startTimer`方法如下：

```cpp
extern "C"
JNIEXPORT void JNICALL
Java_com_spread_nativestudy_fragments_SimpleTimerFragment_startTimer(JNIEnv *env, jobject thiz) {
    jclass clz = env->GetObjectClass(thiz);
    context.simpleTimerClz = static_cast<jclass>(env->NewGlobalRef(clz));
    context.simpleTimerObj = env->NewGlobalRef(thiz);
    pthread_t th;
    pthread_create(&th, nullptr, StartTimer, &context);
    pthread_join(th, nullptr);
}
```

## 3.2 Let's Timer !

现在到了正式写程序的时候了。首先，简单看一下界面：

![[Study Log/android_study/ndk/resources/Pasted image 20240211193748.png]]

在onResume的时候，将Timer清零，然后请求一下当前的时间。这里调用的就是第一个native方法：

```kotlin
private external fun requestForCurrTime()
```

下面是native函数的实现，之前都介绍过了：

```cpp
extern "C"
JNIEXPORT void JNICALL
Java_com_spread_nativestudy_fragments_SimpleTimerFragment_requestForCurrTime(JNIEnv *env, jobject thiz) {
    const std::string curr_time = getCurrTimeStr();
    LOGI("%s", curr_time.c_str());
    jstring curr_time_j = stdStringToJString2(env, curr_time);
    jclass clz = env->GetObjectClass(thiz);
    jmethodID setCurrTime = env->GetMethodID(clz, "setCurrTime", "(Ljava/lang/String;)V");
    env->CallVoidMethod(thiz, setCurrTime, curr_time_j);
}
```

然后，就是最主要的开线程去启动Timer的逻辑。这里面我们首先需要结合之前的一个问题来说。之前，我在说AttachCurrentThread的时候，有这句代码：

```cpp
res = jvm->AttachCurrentThread(&env, nullptr);
```

这里的jvm是什么？AttachCurrentThread的功能就是将当前线程依附到应用的JavaVM上。在Android中，每一个进程只能有一个JavaVM：

[JNI tips | Android NDK | Android Developers](https://developer.android.com/training/articles/perf-jni#javavm-and-jnienv)

```ad-note
上面的文章也告诉我们，不能在线程之间共享JNIEnv。就和之前的jclass和jobject一样，是Local的。如果我们想在线程之间共享JNIEnv，那么就要先共享JavaVM，然后通过它去获得JNIEnv。
```

这里的jvm就是我们在全局变量中加入的：

```cpp
typedef struct tick_context {
    JavaVM *javaVm;             // 线程间共享的JavaVM
    jclass jniHelperClz;
    jobject jniHelperObj;
    jclass simpleTimerClz;
    jobject simpleTimerObj;
    pthread_mutex_t mutex;
    bool interrupted;
} TickContext;
```

那么，这个JavaVM如何获得呢？答案是在`JNI_OnLoad`中：[Java Native Interface Specification: 5 - The Invocation API](https://docs.oracle.com/en/java/javase/17/docs/specs/jni/invocation.html#jni_onload)

这个函数的定义是可选的。我们在内部能够得到当前程序的JavaVM，并通过`GetEnv()`来获得此时的JNIEnv来进行其它操作：

```kotlin
JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    JNIEnv *env;
    memset(&context, 0, sizeof(context));
    context.javaVm = vm;
    if (vm->GetEnv((void **)&env, JNI_VERSION_1_6) != JNI_OK) {
        return JNI_ERR;
    }
    context.interrupted = false;
    context.simpleTimerObj = nullptr;
    return JNI_VERSION_1_6;
}
```

有了JavaVM，之后就可以在线程中去通过它获取JNIEnv了。

这里给出官方案例中获取JNIEnv的步骤：

```c
TickContext *pctx = (TickContext *)context;
JavaVM *javaVM = pctx->javaVM;
JNIEnv *env;
// 先尝试GetEnv
jint res = (*javaVM)->GetEnv(javaVM, (void **)&env, JNI_VERSION_1_6);
if (res != JNI_OK) {  // 如果没获取到，那就是还没ATTACH
	res = (*javaVM)->AttachCurrentThread(javaVM, &env, NULL);
	if (JNI_OK != res) {
		LOGE("Failed to AttachCurrentThread, ErrorCode = %d", res);
		return NULL;
	}
}
```

```ad-note
在`JNI_OnLoad()`中`GetEnv()`能成功，是因为当前线程是main线程，已经是attach VM的状态了；而在`StartTimer()`中`GetEnv()`失败，是因为当前处于子线程。
```

好了。现在我们已经可以给出完整的StartTimer的逻辑了！

```cpp
void *StartTimer(void *ctx) {
    LOGI("timer thread id: %d", pthread_gettid_np(pthread_self()));
    TickContext *pctx = (TickContext *)ctx;
    JavaVM *jvm = pctx->javaVm;
    JNIEnv *env;
    jint res = 0;
    jvm->GetEnv((void **)&env, JNI_VERSION_1_6);
    res = jvm->AttachCurrentThread(&env, nullptr);
    LOGI("Attach return: %d", res);
    // 获得Java层的updateTime回调
    jmethodID updateTime = env->GetMethodID(pctx->simpleTimerClz, "updateTime", "()V");
    struct timespec sleepTime;
    sleepTime.tv_sec = 1;
    sleepTime.tv_nsec = 0;
    pctx->interrupted = false;
    while (true) {
        if (pctx->interrupted) {
            LOGI("Timer interrupted");
            break;
        }
        // 每秒种调用一次回调
        env->CallVoidMethod(pctx->simpleTimerObj, updateTime);
        nanosleep(&sleepTime, nullptr);
    }
    jvm->DetachCurrentThread();
    pthread_exit(nullptr);
}
```

这里的`pctx`既可以是参数`ctx`，也可以是全局变量取地址`&context`。得到Java层的`updateTime()`回调，每一秒钟调用一次。然后也是用全局变量里的`interrupted`来退出线程。

最后，就是停止的逻辑。也非常简单：

1. 删除Global References；
2. interrupt th。

```cpp
extern "C"
JNIEXPORT void JNICALL
Java_com_spread_nativestudy_fragments_SimpleTimerFragment_stopTimer(JNIEnv *env, jobject thiz) {
    env->DeleteGlobalRef(context.simpleTimerClz);
    env->DeleteGlobalRef(context.simpleTimerObj);
    context.interrupted = true;
}
```

# 4 Additional

是不是觉得在c++里写一长串函数名来表示java中的函数很麻烦？还有别的方式！而且更好！

[JNI tips | Android NDK | Android Developers](https://developer.android.com/training/articles/perf-jni#native-libraries)

在Java层创建一个测试的native方法：

```kotlin
private external fun testRegister()
```

现在，在c++层也创建一个函数。名字其实叫什么都可以：

```cpp
void testRegister() {
    LOGI("Hello World!");
}
```

最后，在`JNI_OnLoad()`中写入如下逻辑：

```cpp
jclass clz = env->FindClass("com/spread/nativestudy/fragments/SimpleTimerFragment");
if (clz == nullptr) return JNI_ERR;
static const JNINativeMethod methods[] = {
		{"testRegister", "()V", reinterpret_cast<void *>(testRegister)}
};
int rc = env->RegisterNatives(clz, methods, sizeof(methods) / sizeof(JNINativeMethod));
if (rc != JNI_OK) return rc;
```

这一切都非常好理解。现在，即使不用那一长串逻辑，也可以通过编译了！