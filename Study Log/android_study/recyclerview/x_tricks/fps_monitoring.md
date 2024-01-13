#TODO

- [ ] 找到jitter逻辑中，一帧超过一个vsync interval之后，第二个vsync信号来的时候，发现第一帧的handler还在干活儿，延时发送第二帧的msg的逻辑在哪里。

首先，是FPS监控目前最新的方式。这也是[腾讯matrix](https://github.com/Tencent/matrix)现在在使用的方法。

Window类中在API24之后加入了一个新的接口：

![[Study Log/android_study/recyclerview/x_tricks/resources/Pasted image 20240113112921.png]]

传入两个参数。一个是我们用来接收信息的回调；另一个就是调用这个回调的Handler。没错，发送回调的Handler是我们自己传入的。主要原因就是，绘制UI的线程在大型项目中往往不止一个。它们都有自己的Looper，所以这里将**发送给谁**交由我们自己去选择。

比如自带的HandlerThread。这种线程有自己的Looper，自然能够处理这个回调。而如果传入的handler为空的话，是会抛异常的。所以，一般情况下传入的都是绑定主线程的Handler：

```kotlin
mWindow.addOnFrameMetricsAvailableListener({ window, frameMetrics, dropCountSinceLastInvocation ->
	val copy = FrameMetrics(frameMetrics)
	val duration = copy.getMetric(FrameMetrics.TOTAL_DURATION)
	val frameIntervalNanos = 1000000000 / (mDisplay?.refreshRate ?: 60F)
	val calDroppedFrames = (duration / frameIntervalNanos).toInt()
	val instantFps = 1000000000 / duration
	val fps = if (instantFps < 60) {
		lostFrames++
		instantFps
	} else {
		60
	}
	totalFrames++
	val thread = if (Looper.myLooper() == Looper.getMainLooper()) {
		"Main Thread"
	} else {
		"Test Thread"
	}
	Log.d("SpreadAPM", "Official: $dropCountSinceLastInvocation, my: $calDroppedFrames, fps: $fps, lost: ${lostFrames.toDouble() * 100 / totalFrames}%, thread: $thread")
}, Handler(Looper.getMainLooper())) // 绑定主线程的Handler
```

上面的代码中演示了一个简单的使用案例。在合适的实际获得Activity的Window，然后在上面添加Listener，最后传入了一个绑定主线程的Handler，表示这个回调是运行在主线程中的。

当然，这种统计工作怎么能交给主线程去做呢！无疑是性能浪费。我们看看matrix是怎么做的：

```kotlin
activity.getWindow().addOnFrameMetricsAvailableListener(onFrameMetricsAvailableListener, MatrixHandlerThread.getDefaultHandler());
```

Matrix自己实现了一个HandlerThread，将这些统计工作交给它来处理。所以，我们可以自己new一个线程出来，然后准备好自己的looper。这样就能够将这个任务运行在我们的线程里了。代码就不放了，太简单。