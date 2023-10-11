```ad-info
用`/* */`注释的代码，是屏蔽掉的源码逻辑，它不是主要流程。
```

# 1 SystemServer的工作原理

## 1.1 创建管理者-SystemServiceManager

SystemServer是安卓系统启动的最后一个流程，也是一个非常底层的进程。我们在多处地方见到过它：

* [[Study Log/android_study/sys_boot_process#1.6 System Servers|sys_boot_process]]
* [[Study Log/android_study/resources/Pasted image 20230714144749.png]]

我们来看一看它以及安卓的这些系统服务究竟都是怎么启动的。在SystemServer类中，有一个main函数。而这个main函数是Zygote进程通过反射启动的： ^0e9b76

```java
public static void main(String[] args) {
	new SystemServer().run();
}
```

在main函数中，就是创建了一个SystemServer的实例，并调用了一下它的run方法。在run方法的中间，有这样一段逻辑：

```java
// Create the system service manager.
mSystemServiceManager = new SystemServiceManager(mSystemContext);
mSystemServiceManager.setStartInfo(mRuntimeRestart,mRuntimeStartElapsedTime, mRuntimeStartUptime);
mDumper.addDumpable(mSystemServiceManager);
```

也就是说，SystemServiceManager是一个SystemServer的内部成员，来对系统里面的这些服务进行一个统一的管理：

![[Study Log/android_study/resources/Drawing 2023-08-14 18.20.15.excalidraw.png]]

```java
/**
 * Manages creating, starting, and other lifecycle events of
 * {@link com.android.server.SystemService system services}.
 *
 * {@hide}
 */
public final class SystemServiceManager implements Dumpable
```

> 注释里面提到的这个SystemService，我们之后会提到。

## 1.2 创建被管理者-SystemService

现在回到SystemServer的run方法。**既然已经有了管理服务的对象了，那么接下来就是启动那些被管理的对象——服务了**。

```java
// Start services.
try {
	t.traceBegin("StartServices");
	startBootstrapServices(t);
	startCoreServices(t);
	startOtherServices(t);
	startApexServices(t);
} catch (Throwable ex) {
	Slog.e("System", "******************************************");
	Slog.e("System", "************ Failure starting system services", ex);
	throw ex;
} finally {
	t.traceEnd(); // StartServices
}
```

这四句startXXXServices一共包括了90+个服务。而SystemServiceManager的工作就是对它们进行统一管理。

我们从startBootstrapServices入手。这里面就包括了启动AMS的过程。然而，在这之前，其实还有一个ATMS：

```java
// 启动ATMS
ActivityTaskManagerService atm = mSystemServiceManager.startService(
	ActivityTaskManagerService.Lifecycle.class
).getService();

// 启动AMS
mActivityManagerService = ActivityManagerService.Lifecycle.startService(
	mSystemServiceManager, atm
);
```

> ATMS和AMS都是什么？我们先不谈，现在只把它们当成两个系统服务就好了。

ATMS是定义出的一个临时变量；而AMS是在成员内部的一个变量。先暂且不管它们都是什么，我们来看一看启动了这些服务之后都做了什么：

```java
mActivityManagerService.setSystemServiceManager(mSystemServiceManager);
```

这句话是在说，设置AMS的管理者为SystemServiceManager。而我们注意到，ATMS那里是SystemServiceManager[[Study Log/android_study/resources/Pasted image 20230815145939.png|主动去启动]]了ATMS这个类。所以其实启动一个Service也有多种方式。实际上，绝大多数的服务，都是用ATMS那种方式去启动的。也就是SystemServiceManager中的startService方法。这个方法有很多种重载，我们来看看一个最终入口的版本：

```java
/**
 * Creates and starts a system service. The class must be a subclass of
 * {@link com.android.server.SystemService}.
 *
 * @param serviceClass A Java class that implements the SystemService interface.
 * @return The service instance, never null.
 * @throws RuntimeException if the service fails to start.
 */
public <T extends SystemService> T startService(Class<T> serviceClass) {
	try {
		final String name = serviceClass.getName();
		/* 记日志 */
		final T service;
		/* 一坨tyr-catch */
		startService(service);
		return service;
	} finally {
		Trace.traceEnd(Trace.TRACE_TAG_SYSTEM_SERVER);
	}
}
```

传入的是一个类，所以再看看我们之前传入的参数：

```java
ActivityTaskManagerService.Lifecycle.class
```

走到的正是这里。在方法中，我们构造了一个类型为T的引用，**之后在try catch中构造了实例**。这个实例其实就是T类型的，在我们的例子中，就是`ActivityTaskManagerService.Lifecycle`类型的。这个类型是一个服务，你可能会好奇为什么LifeCycle是服务，我们来接着看下去。之后，又调用了一个startService来启动这个服务。这回是直接把这个类的实例给传进去了：

```java
public void startService(@NonNull final SystemService service)
```

只看方法头就够了，参数是SystemService类型。这是什么？我们传的不是LifeCycle吗？我们找找LifeCycle是怎么定义出来的：

```java
public static final class Lifecycle extends SystemService
```

Oops！还真的是，LifeCycle就是一个继承了SystemService**抽象类**的内部类。其实，很多服务内部都有这个LifeCycle，而它们通过继承了SystemService抽象类，从而能被统一管理。现在，我们来补充一下之前的图吧：

![[Study Log/android_study/resources/Drawing 2023-08-15 14.50.39.excalidraw.png|center|600]]

> 这里第三步add to是startService的内部逻辑。

这就是安卓服务启动的本质了。最后别忘了，之前在启动ATMS的时候，最后还有个getService()，而执行它的就是startService的返回值，在之前的代码中看了，也是T，那就是LifeCycle。果然，我们在其中找到了这个方法：

```java
public ActivityTaskManagerService getService() {
	return mService;
}
```

## 1.3 服务的发布

最后，补充一点**贯穿安卓系统设计的流程**，也就是启动服务真正的位置。我们现在只知道调用了startService可以启动这个服务，那真正启动的位置在哪里呢？答案就在那个以Service实例为参数的方法中，现在放出来代码吧，之前我们只看了方法头：

```java
public void startService(@NonNull final SystemService service) {
	/* Check if already started */

	// Register it.
	mServices.add(service);

	// Start it.
	try {
		service.onStart();
	} catch (RuntimeException ex) {
		...
	}
}
```

调用了onStart！这和什么Activity的onStart，View的onDraw不是非常像吗？！所以，它们的设计模式都是很相似的。这个onStart毫无疑问也定义在了LifeCycle中：

```java
@Override
public void onStart() {
	publishBinderService(Context.ACTIVITY_TASK_SERVICE, mService);
	mService.start();
}
```

其中，最重要的是这句publish方法，有了它，其它的App才能使用这个服务。还记得LifyCycle继承的谁吗？SystemService，也就是一个服务。这是一个抽象类，publishBinderService也是其中的方法：

```java
/**
 * Publish the service so it is accessible to other services and apps.
 *
 * @param name the name of the new service
 * @param service the service object
 * @param allowIsolated set to true to allow isolated sandboxed processes
 * to access this service
 * @param dumpPriority supported dump priority levels as a bitmask
 *
 * @hide
 */
protected final void publishBinderService(String name, IBinder service, boolean allowIsolated, int dumpPriority) {
	ServiceManager.addService(name, service, allowIsolated, dumpPriority);
}
```

无论是几个参数，最终都会调用这个版本。实际上就是把当前服务（**主要是Binder**）添加到一个叫`ServiceManager`的对象中。这又是个新角色了，它才是真正和应用程序进行交互的角色，所有的服务在启动之后，都会把自己publish到这里，以供APP使用；**而SystemServer在启动了这些服务之后，就不会再干预它们了**。最终，SystemServer会永远loop下去：

```java
// SystemServer.java
private void run() {
	... ...
	
	// Loop forever.
	Looper.loop();
	throw new RuntimeException("Main thread loop unexpectedly exited");
}
```

现在回到那个突然蹦出来的ServiceManager。既然它和用户APP打交道，那它是怎么诞生的？它是一个守护进程，而守护进程的启动，显然就在init.rc中：[[Study Log/android_study/sys_boot_process#1.4 Init|sys_boot_process]]

```rc
# Start essential services.
    start servicemanager
    start hwservicemanager
    start vndservicemanager
```

好了，现在我们来总结一下目前梳理出的流程吧：

![[Study Log/android_study/resources/Drawing 2023-08-15 15.34.25.excalidraw.png]]

# 2 SystemServer的启动流程

不过最后，我们还差一个小问题：SystemServer又是从哪儿来的？我们在文章的一开始说，是通过Zygote的反射勾出来的，那么在哪里呢？现在就来看看吧！之所以把他放到最后，是因为它对于我们理解SystemServer的内部流程并没有太大帮助。

## 2.1 fork出SystemServer进程

这部分的逻辑要从[[Study Log/android_study/sys_boot_process#1.5 Zygote and Dalvik VM|ZygoteInit]]说起，它也是安卓启动流程的第一句java代码：

```kotlin
/**
 * This is the entry point for a Zygote process.  It creates the Zygote server, loads resources,
 * and handles other tasks related to preparing the process for forking into applications.
 *
 * This process is started with a nice value of -20 (highest priority).  All paths that flow
 * into new processes are required to either set the priority to the default value or terminate
 * before executing any non-system code.  The native side of this occurs in SpecializeCommon,
 * while the Java Language priority is changed in ZygoteInit.handleSystemServerProcess,
 * ZygoteConnection.handleChildProc, and Zygote.childMain.
 *
 * @param argv  Command line arguments used to specify the Zygote's configuration.
 */
@UnsupportedAppUsage
public static void main(String[] argv) {
	... ...
	if (startSystemServer) {
		Runnable r = forkSystemServer(abiList, zygoteSocketName, zygoteServer);
	}
}
```

Zygote启动的入口就是这个main函数。由于它是static，所以**所有这里调用的函数也都得是static才行，这其中也包括了SystemServer创建的逻辑**。而它就是上面展示的这句forkSystemServer：

```java
/**
 * Prepare the arguments and forks for the system server process.
 *
 * @return A {@code Runnable} that provides an entrypoint into system_server code in the child
 * process; {@code null} in the parent.
 */
private static Runnable forkSystemServer(String abiList, String socketName, ZygoteServer zygoteServer) {
	/* 让Zygotefork出SystemServer进程，并传入参数，返回值是进程号，赋值给pid */	

	/* For child process */
	if (pid == 0) {
		if (hasSecondZygote(abiList)) {
			waitForSecondaryZygote(socketName);
		}

		zygoteServer.closeServerSocket();
		return handleSystemServerProcess(parsedArgs);
	}
	return null;
}
```

这里面调了很多native层的c++代码，不用关心。重点就是fork出SystemServer进程后，它是子进程（pid为0），那么就会调用handleSystemServerProcess方法。这个方法就是真正**完成**启动SystemServer的地方：

```java
/**
 * Finish remaining work for the newly forked system server process.
 * 这里的参数就是之前fork的时候赋值的
 */
private static Runnable handleSystemServerProcess(ZygoteArguments parsedArgs) {
	/*
	 * Pass the remaining arguments to SystemServer.
	 */
	return ZygoteInit.zygoteInit(parsedArgs.mTargetSdkVersion,
			parsedArgs.mDisabledCompatChanges,
			parsedArgs.mRemainingArgs, cl);
}
```

## 2.2 Binder的创建

最后的这个zygoteInit方法我们虽然没怎么见过，但是它确是最重要的一个方法：**任何APP启动的时候，都会由Zygote fork出一个进程。而这个过程中，必定会走到zygoteInit方法**。

```java
/**
 * The main function called when started through the zygote process. This could be unified with
 * main(), if the native code in nativeFinishInit() were rationalized with Zygote startup.<p>
 *
 * Current recognized args:
 * <ul>
 * <li> <code> [--] &lt;start class name&gt;  &lt;args&gt;
 * </ul>
 *
 * @param targetSdkVersion target SDK version
 * @param disabledCompatChanges set of disabled compat changes for the process (all others
 *                              are enabled)
 * @param argv             arg strings
 */
public static Runnable zygoteInit(int targetSdkVersion, long[] disabledCompatChanges, String[] argv, ClassLoader classLoader) {
	if (RuntimeInit.DEBUG) {
		Slog.d(RuntimeInit.TAG, "RuntimeInit: Starting application from zygote");
	}

	Trace.traceBegin(Trace.TRACE_TAG_ACTIVITY_MANAGER, "ZygoteInit");
	RuntimeInit.redirectLogStreams();

	RuntimeInit.commonInit();
	ZygoteInit.nativeZygoteInit();
	return RuntimeInit.applicationInit(targetSdkVersion, disabledCompatChanges, argv,
			classLoader);
}
```

注意咯，这个方法的参数就是当前进程携带的一些信息，还是我们之前fork的时候赋值进去的（pid那里）。这里面最重要的是nativeZygoteInit()方法。这是一个c++方法，会调用native层的[[Study Log/android_study/resources/onzygoteinit|onZygoteInit()]]回调，而在那里面，**就是真正binder初始化的地方**。其实，Binder就是linux的一个驱动设备，在`/dev/binder`。 ^e0a7ae

## 2.3 Server，启动！

创建完binder之后，就是最后的applicationInit方法了。这个方法也很重要，它的作用就是**找到一个进程的main函数，并通过反射启动它**。我们的SystemServer是这样，我们的所有用户APP也都是这样。

```java
protected static Runnable applicationInit(int targetSdkVersion, long[] disabledCompatChanges, String[] argv, ClassLoader classLoader) {
	... ...

	// Remaining arguments are passed to the start class's static main
	return findStaticMain(args.startClass, args.startArgs, classLoader);
}
```

```java
/**
 * Invokes a static "main(argv[]) method on class "className".
 * Converts various failing exceptions into RuntimeExceptions, with
 * the assumption that they will then cause the VM instance to exit.
 *
 * @param className Fully-qualified class name
 * @param argv Argument vector for main()
 * @param classLoader the classLoader to load {@className} with
 */
protected static Runnable findStaticMain(String className, String[] argv, ClassLoader classLoader) {
	... ...
	
	try {
		// 得到main函数
		m = cl.getMethod("main", new Class[] { String[].class });
	} catch ...

	/*
	 * This throw gets caught in ZygoteInit.main(), which responds
	 * by invoking the exception's run() method. This arrangement
	 * clears up all the stack frames that were required in setting
	 * up the process.
	 */
	return new MethodAndArgsCaller(m, argv);
}
```

简单来说，反射勾出来，然后一调用完了。显然，MethodAndArgsCaller中就应该有m.invoke()这样的逻辑（就不展示了）。但是注意了！**名字是大写的，为什么？另外，为什么我们要返回Runnable**？这显然说明，这里并不是调用的位置，而是只是**将这个main函数的调用封装成一个Runnable，并把调用的权力给交出去**。而看到了MethodAndArgsCallers的内部，也就证实了我们的猜想：

```java
/**
 * Helper class which holds a method and arguments and can call them. This is used as part of
 * a trampoline to get rid of the initial process setup stack frames.
 */
static class MethodAndArgsCaller implements Runnable {
	/** method to call */
	private final Method mMethod;

	/** argument array */
	private final String[] mArgs;

	public MethodAndArgsCaller(Method method, String[] args) {
		mMethod = method;
		mArgs = args;
	}

	public void run() {
		try {
			mMethod.invoke(null, new Object[] { mArgs });
		} catch (IllegalAccessException ex) {
			throw new RuntimeException(ex);
		} catch (InvocationTargetException ex) {
			Throwable cause = ex.getCause();
			if (cause instanceof RuntimeException) {
				throw (RuntimeException) cause;
			} else if (cause instanceof Error) {
				throw (Error) cause;
			}
			throw new RuntimeException(ex);
		}
	}
}
```

注意，这不是个方法，是个类！它重写了Runnable接口，将main函数执行的逻辑封装成了一个Runnable，这样外部调用它的run方法，也就等于调用了这个main方法。那么它究竟是在哪里调用的呢？明白了这一点，我们其实只要回头去看我们的调用链，这个Runnable返回到哪里去就知道了。好家伙，这一回头就回到头了，还是ZygoteInit的main方法：

```java
/**
 * This is the entry point for a Zygote process.  It creates the Zygote server, loads resources,
 * and handles other tasks related to preparing the process for forking into applications.
 *
 * This process is started with a nice value of -20 (highest priority).  All paths that flow
 * into new processes are required to either set the priority to the default value or terminate
 * before executing any non-system code.  The native side of this occurs in SpecializeCommon,
 * while the Java Language priority is changed in ZygoteInit.handleSystemServerProcess,
 * ZygoteConnection.handleChildProc, and Zygote.childMain.
 *
 * @param argv  Command line arguments used to specify the Zygote's configuration.
 */
@UnsupportedAppUsage
public static void main(String[] argv) {
	... ...
	if (startSystemServer) {
		Runnable r = forkSystemServer(abiList, zygoteSocketName, zygoteServer);
		// {@code r == null} in the parent (zygote) process, and {@code r != null} in the
		// child (system_server) process.
		if (r != null) {
			r.run();
			return;
		}
	}
}
```

来吧，总的流程图来了：

![[Study Log/android_study/resources/Drawing 2023-08-15 18.33.52.excalidraw.png]]

最后一个问题，那个在ZygoteInit的main中运行的main，又或者说通过反射勾出来的那个main，在我们的例子中，是什么？就在文章的[[#^0e9b76|开头]]呀！

# 3 Questions

## 3.1 ATMS vs AMS

为什么要有ATMS呢？我们来看看源码的注释：

```java
/**
 * System service for managing activities and their containers (task, displays,... ).
 *
 * {@hide}
 */
public class ActivityTaskManagerService extends IActivityTaskManager.Stub
```

显然，它是用来管理Activity和它们存放的位置，也就是Task的。实际上，在安卓10以前，还没有ATMS这个东西，之前所有四大组件的管理都是由AMS来控制。然而作为通信最频繁的Activity，这方面的管理任务也越来越繁重。最终在安卓10的时候将所有Activity的管理逻辑给拆了出去，成为了ATMS。