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

---

看看Android官方是怎么实现的。位于文件`frameworks/base/tests/JankBench/app/src/main/java/com/android/benchmark/results/UiBenchmarkResult.java`。这是一个官方提供的工具，用来存放和分析UI方面的性能指标。

这个类去统计掉帧的方式和FrameMatrics的注释中写的是一样的：

```java
/**  
* Metric identifier for the total duration that was available to the app to produce a frame.  
* <p>  
* Represents the total time in nanoseconds the system allocated for the app to produce its  
* frame. If FrameMetrics.TOTAL_DURATION < FrameMetrics.DEADLINE, the app hit its intended  
* deadline and there was no jank visible to the user.  
* </p>  
**/  
public static final int DEADLINE = 13;
```

其实就是看TOTAL_DURATION和DEADLINE哪个更大。并不像matrix中那样还要加加减减去算一个新的值。具体的逻辑如下：

```java
public int[] getSortedJankFrameIndices() {
	ArrayList<Integer> jankFrameIndices = new ArrayList<>();
	boolean tripleBuffered = false;
	int totalFrameCount = getTotalFrameCount();
	int totalDurationPos = getMetricPosition(FrameMetrics.TOTAL_DURATION);

	for (int i = 0; i < totalFrameCount; i++) {
		double thisDuration = mStoredStatistics[totalDurationPos].getElement(i);
		if (!tripleBuffered) {
			if (thisDuration > FRAME_PERIOD_MS) {
				tripleBuffered = true;
				jankFrameIndices.add(i);
			}
		} else {
			if (thisDuration > 2 * FRAME_PERIOD_MS) {
				tripleBuffered = false;
				jankFrameIndices.add(i);
			}
		}
	}

	int[] res = new int[jankFrameIndices.size()];
	int i = 0;
	for (Integer index : jankFrameIndices) {
		res[i++] = index;
	}
	return res;
}
```

这里唯一的一个for循环是在遍历一个FrameMetrices的list，每一次遍历是一个frame中的信息。可以看到，它只取出来了TOTAL_DURATION这个属性，并且和FRAME_PERIOID_MS作比较。其中FRAME_PERIOD_MS就是60hz的屏幕刷新率的间隔，也就是16。

但是，在这个基础上还增加了三缓存的判断：

* 如果没有采用三缓存机制，丢帧了之后**下次**就采用三缓存；
* 如果已经采用了三缓存，丢帧之后就**下次**就不用三缓存。

借用这个思想，我们写出一个自己版本的FpsListener：

```kotlin
private class OnFpsListener(private val activity: Activity) : OnFrameMetricsAvailableListener {

	private var tripleBuffered = false
	private var totalFrameCount = 0L
	private var droppedFrameCount = 0L
	private var frameLostRate = 0.0

	override fun onFrameMetricsAvailable(
		window: Window?,
		frameMetrics: FrameMetrics?,
		dropCountSinceLastInvocation: Int
	) {
		val fm = FrameMetrics(frameMetrics)
		if (fm.isFirstFrame) {
			Log.i(TAG, "First frame which we won't care for now.")
			return
		}
		totalFrameCount++
		val duration = fm.totalDuration.ms
		val interval = fm.deadline.ms
		if (!tripleBuffered) {
			if (duration > interval) {
				tripleBuffered = true
				droppedFrameCount++
			}
		} else {
			if (duration > 2 * interval) {
				tripleBuffered = false
				droppedFrameCount++
			}
		}
		val newFrameLostRate = droppedFrameCount.toDouble() / totalFrameCount
		if (frameLostRate != newFrameLostRate) {
			Log.d(TAG, "frameLostRate: ${newFrameLostRate * 100}%, dropped: $droppedFrameCount, total: $totalFrameCount")
			frameLostRate = newFrameLostRate
		}
	}
}
```