<h1>安卓面经</h1>

# 1. Activity

## 1.1 Back Stack

[Tasks and the back stack  |  Android Developers](https://developer.android.com/guide/components/activities/tasks-and-back-stack)

启动Activity，将它加入返回栈，此时它处于栈顶。如果按下返回键或者调用`finish()`放法销毁它，它就从返回栈里弹出。

![[Article/resources/Pasted image 20230323215937.png]]

## 1.2 Life Cycle

[The activity lifecycle  |  Android Developers](https://developer.android.com/guide/components/activities/activity-lifecycle)

![[Article/resources/Pasted image 20230323220228.png|400]]

* onResume状态的Activity处于返回栈的栈顶，因为它**正在运行**；
* 当其他Activity占据了返回栈的栈顶，而原来的Activity仍然可见时，被占用的Activity处于onPause状态(对话Activity占据时，下面的Acitivity仍然可见)。此时我们可以释放一些浪费CPU的资源；
* 当Activity完全不可见时，处于onStop状态(和onPause的区别就是如果是对话Activity抢占，被抢占的Activity只执行onPause，不执行onStop)；
* 当Activity完全被干掉时，处于onDestroy状态。
* 当Activity从返回栈的内部被移回到栈顶时(通常是按返回键)，调用onRestart方法。

```kotlin
// 启动Activity A
A.onCreate() -> A.onStart() -> A.onResume()

// 在A上打开B
A.onPause() -> A.onStop()

// 回到A
A.onRestart() -> A.onStart() -> A.onResume()

// 在A上按返回键
A.onPause() -> A.onStop() -> A.onDestroy()

// 在A上不按返回键，按Home键后又回来
A.onPause() -> A.onStop() -> A.onRestart() -> A.onStart() -> A.onResume()

// 调用finish()方法
A.onDestroy()

// 在A上旋转屏幕时
A.onPause() -> A.onSaveInstanceState() -> A.onStop() -> A.onDestroy() -> A.onCreate() -> A.onStart() -> A.onRestoreInstanceState() -> A.onResume()
```

可以看到，Activity发生旋转时，会经历重建的过程。因此我们需要将数据在`onSaveInstanceState()`方法中以bundle(键值对)的形式保存起来。**该方法只要Acitivity被回收，就会被调用**。因此即使不是旋转屏幕，在后台的Activity被系统回收时，也要考虑用此方法保存数据。另外，我们可以通过配置AndroidManifest的方式来避免走完生命周期：

![[Article/resources/Pasted image 20230323223145.png]]

> 在MVVM架构中，旋转屏幕最好用带构造参数的ViewModel来解决。

## 1.3 Launch Mode

通过AndroidManifest中的`android:launchMode`属性配置，或者在Intent中配置。

1. standard：默认，同一个Activity可以被创建多次副本。
2. singleTop：当Activity处于栈顶，只允许创建一次(栈内)。
3. singleTask：任何Activity都只能被创建一次(栈内)。
4. singleInstance：特立独行，只要Activity被设为这种模式，创建的时候使用专享返回栈。一般用于和其他程序共享Activity。

# 2. Service

[Services overview  |  Android Developers (google.cn)](https://developer.android.google.cn/guide/components/services)

> A Service is an [application component](https://developer.android.google.cn/guide/components/fundamentals#Components) that can perform long-running operations in the background. It does not provide a user interface. Once started, a service might continue running for some time, even after the user switches to another application. Additionally, a component can bind to a service to interact with it and even perform interprocess communication (IPC). For example, a service can handle network transactions, play music, perform file I/O, or interact with a content provider, all from the background.

## 2.1 Start of Service

![[Article/resources/Pasted image 20230328205312.png|400]]

### 2.1.1 startService()

其它组件可以调用`startService()`函数来启动service，同时可以传递Intent作为参数，来向Service提供一些信息。比如，在后台下载服务时，可以将下载地址的Url传递进去。从Service来看，它回在`onStartCommand()`函数调用时接收到这个intent。

```kotlin
override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {        
	// The service is starting, due to a call to startService()        
	return startMode  
}
```

使用这种方式，即使Service所关联的Activity挂掉了，它还是会继续运行。直到Service调用`stopSelf()`或者其它组件调用`stopService()`时才会停止。

### 2.1.2 bindService()

