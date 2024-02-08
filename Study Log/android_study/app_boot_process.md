这篇文章写的很好：[# Android12 应用启动流程分析](https://evilpan.com/2021/12/05/apk-startup/)

# 1 应用启动流程

[Android启动过程分析(图+文)-腾讯云开发者社区-腾讯云 (tencent.com)](https://cloud.tencent.com/developer/article/1356506)

从点击桌面的APP图标，到APP主页显示出来，大致会经过以下流程：

1.  点击桌面App图标，Launcher进程采用Binder跨进程机制向system_server进程发起startActivity请求；
2.  system_server进程接收到请求后，向Zygote进程发送创建进程的请求，Zygote进程fork出新的子进程，即新启动的App进程；
3.  App进程，通过Binder机制向sytem_server进程发起attachApplication请求（绑定Application）；
4.  system_server进程在收到请求后，进行一系列准备工作后，再通过binder机制向App进程发送scheduleLaunchActivity请求；
5.  App进程的binder线程（ApplicationThread）在收到请求后，通过handler向主线程发送LAUNCH_ACTIVITY消息。主线程在收到Message后，通过发射机制创建目标Activity，并回调Activity.onCreate()/onStart()/onResume()等方法，经过UI渲染结束后便可以看到App的主界面。

![[Study Log/android_study/resources/Pasted image 20230714144749.png]]

一些基础知识：

-   冷启动：当启动应用时，后台没有该应用的进程，这时系统会重新创建一个新的进程分配给该应用，这个启动方式就是冷启动，下文讲述的APP启动流程属于冷启动；
-   热启动：当启动应用时，后台已有该应用的进程（例：按back键、home键，应用虽然会退出，但是该应用的进程是依然会保留在后台，可进入任务列表查看），所以在已有进程的情况下，这种启动会从已有的进程中来启动应用，这个方式叫热启动；
-   一个APP就是一个单独的进程，对应一个单独的Dalvik虚拟机；[Android Runtime (ART) 和 Dalvik  |  Android 开源项目  |  Android Open Source Project](https://source.android.com/docs/core/runtime?hl=zh-cn)
-   Launcher：我们打开手机桌面，手机桌面其实就是一个系统应用程序，这个应用程序就叫做“Launcher”。同样的，下拉菜单其实也是一个应用程序，叫做“SystemUI”；
-   Binder：跨进程通讯的一种方式。
-   Zygote：Android系统基于Linux内核，当Linux内核加载后会启动一个叫“init”的进程，并fork出“Zygote”进程。Zygote意为“受精卵”，无论是系统服务进程，如ActivityManagerService、PackageManagerService、WindowManagerService等等，还是用户启动的APP进程，都是由Zygote进程fork出来的；
-   system_server：系统服务进程，也是Zygote进程fork出来的。该进程和Zygote进程是Android系统中最重要的两个进程，系统服务ActivityManagerService、PackageManagerService、WindowManagerService等等都是在system_server中启动的；
-   ActivityManagerService：活动管理服务，简称AMS，负责系统中所有的Activity的管理；
-   App与AMS通过Binder进行跨进程通信，AMS与Zygote通过Socket进行跨进程通信；
-   Instrumentation：主要用来监控应用程序和系统的交互，是完成对Application和Activity初始化和生命周期的工具类。每个Activity都持有Instrumentation对象的一个引用，但是整个进程只会存在一个Instrumentation对象；
-   ActivityThread：依赖于UI线程，ActivityThread不是指一个线程，而是运行在主线程的一个对象。App和AMS是通过Binder传递信息的，那么ActivityThread就是专门与AMS的外交工作的。ActivityThread是APP的真正入口，APP启动后从ActivityThread的main()函数开始运行；
-   ActivityStack：Activity在AMS的栈管理，用来记录经启动的Activity的先后关系，状态信息等。通过ActivtyStack决定是否需要启动新的进程；
-   ApplicationThread：是ActivityThread的内部类，是ActivityThread和ActivityManagerServie交互的中间桥梁。在ActivityManagerSevice需要管理相关Application中的Activity的生命周期时，通过ApplicationThread的代理对象与ActivityThread通信；

## 1.1 startActivity请求

系统启动过程中，会启动PMS服务，该服务会扫描解析系统中所有APP的AndroidManifest文件，在Launcher应用启动后，会将每个APP的图标和相关启动信息封装在一起。回想平时应用开发中，启动一个新的Activity是通过startAcitvity()方法。因此在桌面点击应用图标，也是在Luancher这个应用程序里面根据当前点击的APP的启动信息，执行startAcitvity()方法，通过Binder通信，最后调用ActivityManagerService的startActivity()方法。流程图如下：

![[Study Log/resources/Pasted image 20230704161238.png]]

## 1.2 Zygote fork新进程

![[Study Log/resources/Pasted image 20230704164058.png]]

当执行到startSpecificActivityLocked()方法时，会进行一次判断：

* 如果当前的程序已经有正在运行的Application，那么直接执行startActivity()即可；
* 如果并没有关联的进程，那么需要通过socket通道传递给Zygote进程，让它fork初一个新的进程来绑定这个Activity。

## 1.3 绑定Application

ActivityThread的main函数主要执行两件事情：

-   依次调用Looper.prepareLoop()和Looper.loop()来开启消息循环；
-   调用attach()方法，将给该新建的APP进程和指定的Application绑定起来；

## 1.4 启动Activity

经过1.2\~1.3后，系统就有了当前新APP的进程了，接下里的调用顺序就相当于从一个已经存在的进程中启动一个新的Actvity。因此回到1.2，如果当前Activity所在的Application有运行的话，就会执行realStartActivityLocked()方法，并调用scheduleLaunchActivity();

scheduleLaunchActivity()发送一个LAUNCH_ACTIVITY消息到消息队列中, 通过 handleLaunchActivity()来处理该消息。在 handleLaunchActivity()通过performLaunchActiivty()方法回调Activity的onCreate()方法和onStart()方法，然后通过handleResumeActivity()方法，回调Activity的onResume()方法，最终显示Activity界面。

![[Study Log/resources/Pasted image 20230704164706.png]]

# 2 流程分析

我们从最后面的Activity开始说起。它的入口是ActivityThread，这是什么呢？还记不记得，如果我们要让一个Activity在应用启动的时候就打开，那么应该配置AndroidMenifest：

```xml
<intent-filter>  
    <action android:name="android.intent.action.MAIN" />  
    <category android:name="android.intent.category.LAUNCHER" />  
</intent-filter>
```

上面这个main就表示，**这个Activity所在的线程是应用的主线程**。而ActivityThread就是这个主线程的管理者：

```java
/**
 * This manages the execution of the main thread in an
 * application process, scheduling and executing activities,
 * broadcasts, and other operations on it as the activity
 * manager requests.
 *
 * {@hide}
 */
public final class ActivityThread extends ClientTransactionHandler implements ActivityThreadInternal
```

它也是有main函数的，这个main函数也是通过反射启动的。具体的功能在app启动流程时已经说过了：[[Study Log/android_study/app_boot_process#1.3 绑定Application|app_boot_process]]

```java
// Code in main()
ActivityThread thread = new ActivityThread();
thread.attach(false, startSeq);
```

这里的attach是什么呢？就是一个APP进程刚刚启动后最重要的事：**让AMS能管理自己**。

```java
// code in attach()
final IActivityManager mgr = ActivityManager.getService();
mgr.attachApplication(mAppThread, startSeq);
```

这个getService熟不熟悉？又看到了我们的[[Study Log/android_study/ams#^4946f2|老朋友]]。来对比一下它们获取的方式，真的太像了！

![[Study Log/android_study/resources/Pasted image 20230817140639.png]]

获取到的是谁？AMS！！**的代理**！！接下来，我们就可以调用AMS中的方法了。这回调用的是attachApplication，传的是什么？答案是：**ApplicationThread**。ApplicationThread其实是ActivityThread的一个内部类，一个**Binder Stub**：

```java
final ApplicationThread mAppThread = new ApplicationThread();
// Binder stub
private class ApplicationThread extends IApplicationThread.Stub
```

```ad-note
Stub是在RPC中常见的模式：[[Lecture Notes/Middleware/mid#^b14646|mid]]，在本例中，APP把自己的ApplicationThread传给了AMS，对于AMS来说，它就会把这个ApplicationThread当成ActivityThread提供的服务，从而调用里面的方法。
```

这一套流程，实际上就是，**我APP通过你AMS的Binder里的服务，把我的Binder再传给你**。这样，AMS和APP双方就都知道彼此的存在，也可以调用彼此的方法了。而这回ActivityThread调用的就是AMS的attachApplication方法。在这里面，会执行一个bindApplication方法：

```java
// code in attachApplicationLocked()
thread.bindApplication(processName, appInfo,
                        app.sdkSandboxClientAppVolumeUuid, app.sdkSandboxClientAppPackage,
                        providerList, null, profilerInfo, null, null, null, testMode,
                        mBinderTransactionTrackingEnabled, enableTrackAllocation,
                        isRestrictedBackupMode || !normalMode, app.isPersistent(),
                        new Configuration(app.getWindowProcessController().getConfiguration()),
                        app.getCompat(), getCommonServicesLocked(app.isolated),
                        mCoreSettingsObserver.getCoreSettingsLocked(),
                        buildSerial, autofillOptions, contentCaptureOptions,
                        app.getDisabledCompatChanges(), serializedSystemFontMap,
                        app.getStartElapsedTime(), app.getStartUptime());
```

这个thread是谁呢？**就是刚刚ActivityThread传过来的AplicationThread的Binder**！所以，我们又跑回去看。这里的操作其实就是**通知自己**绑定ActivityThread自己和ApplicationThread，当然是用Handler通知，初始化消息完毕后发送一个消息，而这个消息也就是Main Looper管理的，**H**处理的：

```java
@Override
public final void bindApplication(参数太多了，不写了) {
	... ...
	sendMessage(H.BIND_APPLICATION, data);
}
```

> [!question]- 为什么ActivityThread绑定ApplicationThread这么大费周章，还要通过AMS来？为什么不直接调用绑定的逻辑？
> 
> 我的猜测是，AMS需要知道是哪个进程绑定了这个ApplicationThread。

#TODO 

- [ ] 绑定Application之后，创建Application，Activity的逻辑。

接下来，就按照上面的逻辑，会走到ActivityThread的handleLaunchActivity方法：

```java
/**
 * Extended implementation of activity launch. Used when server requests a launch or relaunch.
 */
@Override
public Activity handleLaunchActivity(ActivityClientRecord r, PendingTransactionActions pendingActions, Intent customIntent) {
	...
	final Activity a = performLaunchActivity(r, customIntent);
	...
	return a;
}
```

最主要的事情，就是调用performLaunchActivity创建出这个Activity并返回。

```java
/**  Core implementation of activity launch. */
private Activity performLaunchActivity(ActivityClientRecord r, Intent customIntent) {
	Activity activity = null;
	try {
		java.lang.ClassLoader cl = appContext.getClassLoader();
		activity = mInstrumentation.newActivity(
				cl, component.getClassName(), r.intent);
	} catch ...
	
	...
	
	activity.attach(appContext, this, getInstrumentation(), r.token,
			r.ident, app, r.intent, r.activityInfo, title, r.parent,
			r.embeddedID, r.lastNonConfigurationInstances, config,
			r.referrer, r.voiceInteractor, window, r.activityConfigCallback,
			r.assistToken, r.shareableActivityToken);

	return activity;
}
```

这里面，首先通过反射创建了一个Activity，并执行attach函数进行依附。依附的是谁呢？当然就是PhoneWindow啦！但是这里要注意，依附并不是值Activity是包含在PhoneWindow里的，正相反，是Activity包含了Window。实际上，**只有Window才是能添加View的**。

attach方法中，主要做了这几件事：

* 创建一个PhoneWindow
* 设置这个window的Manager，也就是WMS

之后，就该调用Activity的onCreate了。只不过，真正的调用是在Instrumentation中执行的。其中就有Activity的onCreate的执行。而Activity的setContentView就是去xml中把View树给解析出来，然后添加到之前的window中。