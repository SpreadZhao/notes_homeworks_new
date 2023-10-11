# 1 Client - AMS - Server是如何通信的

这里的Client和Server可以是Activity也可以是Service。我们来看一看这个流程，从Activity的startActivity入手，会一步步走到Instrumentation的execStartActivity：

```kotlin
 @UnsupportedAppUsage  
public ActivityResult execStartActivity(  
        Context who, IBinder contextThread, IBinder token, Activity target,  
        Intent intent, int requestCode, Bundle options) {  
    ... ...
    try {  
        int result = ActivityTaskManager.getService().startActivity(whoThread,  
                who.getOpPackageName(), who.getAttributionTag(), intent,  
                intent.resolveTypeIfNeeded(who.getContentResolver()), token,  
                target != null ? target.mEmbeddedID : null, requestCode, 0, null, options);  
        checkStartActivityResult(result, intent);  
    } catch (RemoteException e) {  
        throw new RuntimeException("Failure from system", e);  
    }  
    return null;  
}
```

最主要的就是这个getService()。它获得的其实就是ATMS，，**的代理**，然后调用它的startActivity方法。~~获取的流程可以看这篇文章~~： ^4946f2

[Android11（API30）中Activity的启动流程—从startActivity到onCreate_android11+activity启动流程_coder_ywb的博客-CSDN博客](https://blog.csdn.net/yu749942362/article/details/107978083)

好吧，我还是得说，这个挺重要。其实就是下面的代码： ^4b84eb

```java
/** @hide */
public static IActivityTaskManager getService() {
	return IActivityTaskManagerSingleton.get();
}

@UnsupportedAppUsage(trackingBug = 129726065)
private static final Singleton<IActivityTaskManager> IActivityTaskManagerSingleton =
		new Singleton<IActivityTaskManager>() {
			@Override
			protected IActivityTaskManager create() {
				final IBinder b = ServiceManager.getService(Context.ACTIVITY_TASK_SERVICE);
				return IActivityTaskManager.Stub.asInterface(b);
			}
		};
```

注意，得到的是一个从Binder解析出来的接口，并且调用的是ServiceManager的代码。而这也正是这张图的流程：

![[Study Log/android_study/resources/Pasted image 20230817131711.png|300]]

那么接下来，走到的就是ATMS的startActivity方法：

```java
private int startActivityAsUser(IApplicationThread caller, String callingPackage,
		@Nullable String callingFeatureId, Intent intent, String resolvedType,
		IBinder resultTo, String resultWho, int requestCode, int startFlags,
		ProfilerInfo profilerInfo, Bundle bOptions, int userId, boolean validateIncomingUser) {
	... ...
	return getActivityStartController().obtainStarter(intent, "startActivityAsUser")
			... ...
			.execute();

}
```

这里最重要的，就是执行这个starter的execute方法。而在这个execute方法中，又执行了executeRequest方法，这里面又调用了startActivityUnchecked方法。这里，就是根据[[Study Log/android_study/activity#3 启动模式介绍|启动模式]]来以不同的方式启动这个Activity的地方。之后，又调用了startActivityInner方法：

```java
/**
 * Start an activity and determine if the activity should be adding to the top of an existing
 * task or delivered new intent to an existing activity. Also manipulating the activity task
 * onto requested or valid root-task/display.
 *
 * Note: This method should only be called from {@link #startActivityUnchecked}.
 */
// TODO(b/152429287): Make it easier to exercise code paths through startActivityInner
@VisibleForTesting
int startActivityInner(final ActivityRecord r, ActivityRecord sourceRecord,
		IVoiceInteractionSession voiceSession, IVoiceInteractor voiceInteractor,
		int startFlags, boolean doResume, ActivityOptions options, Task inTask,
		TaskFragment inTaskFragment, @BalCode int balCode,
		NeededUriGrants intentGrants) {
}
```

这坨代码很关键。~~从网上的各种资料都在说，是在判断进程是否已经启动。但是我觉得都没说到点子上~~。就像我在启动模式里说的一样，这不就是在根据taskAffinity来判断新的Activity应该放在哪个Task上嘛？[[Study Log/android_study/activity#3.4 Task Affinity|activity]]

在这里面，执行了RootWindowContainer的resumeFocusedTasksTopActivities方法，在这里面又又执行了targetRootTask这个成员(类型为Task)的resumeTopActivityUncheckedLocked方法。这一点在安卓10的源码中是没有的，在安卓13中我才看到：

```java
// frameworks\base\services\core\java\com\android\server\wm
@GuardedBy("mService")
private boolean resumeTopActivityInnerLocked(ActivityRecord prev, ActivityOptions options,
		boolean deferPause) {

	... ...
	resumed[0] = topFragment.resumeTopActivity(prev, options, deferPause);
	... ...
	return resumed[0];
}
```

这里是在调用TaskFragement的resumeTopActivity。而在这个方法中，终于调用了**最重要的mTaskSupervisor.startSpecificActivity**：

```java
void startSpecificActivity(ActivityRecord r, boolean andResume, boolean checkConfig) {
	// 如果进程存在，realStart
	if (wpc != null && wpc.hasThread()) {
		try {
			realStartActivityLocked(r, wpc, andResume, checkConfig);
			return;
		} catch xxx
	}

	// 进程不存在，fork进程
	mService.startProcessAsync(r, knownToBeDead, isTop,
			isTop ? HostingRecord.HOSTING_TYPE_TOP_ACTIVITY
					: HostingRecord.HOSTING_TYPE_ACTIVITY);
}
```

这个fork进程是谁来做的呢？答案是ATMS！跟着代码一步步走下去，最后会看到用**Socket**通知Zygote去孵化进程。

```ad-question
为什么不用Binder? [[Article/interview/interview_questions#^36a413|interview_questions]]
```

fork出来之后的操作呢？就会走到ActivityThread的main方法了。这里可以看：[[Study Log/android_study/app_boot_process#2 流程分析|app_boot_process]]

全流程图：

![[Study Log/android_study/resources/Drawing 2023-08-17 13.28.16.excalidraw.png]]