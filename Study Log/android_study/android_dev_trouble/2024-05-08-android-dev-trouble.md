---
title: A Gesture-Recognize View
date: 2024-05-08
tags:
  - "#question/coding/practice/custom-view"
mtrace:
  - 2024-05-08
---

# A Gesture-Recognize View

写一个可以双指缩放和移动的Layout。思路就是让这个layout接收触摸事件，然后识别出这些事件是缩放、平移还是旋转，然后让它的子View做相应的动作。

在每一帧，对收到的事件进行解析，依次进行缩放、平移和旋转的识别。其中前两个已经有了现成的组件，也就是GestureDetector；但是旋转的识别需要自己写一个新的。

可以通过对MotionEvent进行简单解析得到手指根数的信息：

```kotlin
val action = event.actionMasked
val count = event.pointerCount
```

我们只希望在两根手指的时候做，所以这样：

```kotlin
if (count == 2) {
	// Detector detect
}
```

接下来是GestureDetector的使用。方法如下：

```kotlin
// 内置的Detector
private val mScaleGestureDetector = ScaleGestureDetector(context, mScaleListener)
private val mTransferGestureDetector = GestureDetector(context, mTransferListener)
private val mNormalGestureDetector = GestureDetector(context, mSimpleGestureListener)
// 自定义的Detector
private val mRotateGestureDetector = RotateGestureDetector(mRotateListener)

// 进行识别，通常在自己的onTouchEvent里调用
mScaleGestureDetector.onTouchEvent(event)
mTransferGestureDetector.onTouchEvent(event)
mRotateGestureDetector.onTouchEvent(event)
```

自带的都需要传入一个Context，当然最重要的是后面的Listener。Detector顾名思义，只负责detect。你传入一个事件，它帮你检测这个事件是点击、平移、双击、长按还是缩放等等。因此我们需要在Listener的回调里做真正的动作。拿缩放举例子：

```kotlin
private val mScaleListener = object : ScaleGestureDetector.OnScaleGestureListener {
	override fun onScale(detector: ScaleGestureDetector): Boolean {
		val factor = detector.scaleFactor
		mChild?.apply {
			scaleX *= factor
			scaleY *= factor
		}
		return true
	}

	override fun onScaleBegin(detector: ScaleGestureDetector): Boolean {
		mTouchHandled = true
		return true
	}

	override fun onScaleEnd(detector: ScaleGestureDetector) {
	}
}
```

在我们调用了`mScaleGestureDetector.onTouchEvent(event)`之后，就会开始对这个事件的识别。<u>如果发现这是个缩放事件</u>，那么就会依次回调上面的三个方法。我们就可以在这里做真正的缩放。

> [!comment] 如果发现这是个缩放事件
> 当然，不可能是一个event就变成缩放了。它会根据多个事件去判断（我猜是两个。因为我自己写的旋转的Detector用了前后两个事件就能判断出来是旋转动作），主要是通过事件之间的滑动距离的区别等等。

其他的同理，就不多说了。现在说说旋转怎么做。知道了思路就很容易了，不过还是得算一段时间（或者GPT）。另外需要说一点，如果你两根手指头一起点，那一个MotionEvent里其实是包含你两根手指头的动作的。所以我们可以拆出来每根手指头的移动行为。旋转的判断核心就在这里：

```kotlin
val prevX0 = prev.getX(rotateIndex0)
val prevY0 = prev.getY(rotateIndex0)
val prevX1 = prev.getX(rotateIndex1)
val prevY1 = prev.getY(rotateIndex1)
val prevXDistance = prevX1 - prevX0
val prevYDistance = prevY1 - prevY0
mPrevFingerDiffX = prevXDistance
mPrevFingerDiffY = prevYDistance

val currX0 = curr.getX(rotateIndex0)
val currY0 = curr.getY(rotateIndex0)
val currX1 = curr.getX(rotateIndex1)
val currY1 = curr.getY(rotateIndex1)
val currXDistance = currX1 - currX0
val currYDistance = currY1 - currY0
mCurrFingerDiffX = currXDistance
mCurrFingerDiffY = currYDistance
```

这里`prev`和`curr`是两个MotionEvent。而`rotateIndex0`和`rotateIndex1`就是两根手指头，其实就是0和1，用这个下标去查那根手指头的移动距离。这样一算就能得到，在一次滑动之后，两根手指头分别在x方向和y方向移动了多少。

最后一步就是算角度。从距离算出移动的角度需要数学推到，反正答案就是$arctan$的差值：

```kotlin
var a1 = atan2(mCurrFingerDiffY, mCurrFingerDiffX)
val a2 = atan2(mPrevFingerDiffY, mPrevFingerDiffX)
return ((a1 - a2) * 100 / PI).toFloat()
```

不过，这段代码有bug。通过打印日志排查出来是当两根手指头恰好在水平方向的左侧和右侧时，这个a1和a2会突然异号。后果就是算出来的角度会突然超过$180\degree$，导致转着转着突然反向。所以这里如果发现异号，修复一下：

```kotlin
val degree: Float
	get() {
		var a1 = atan2(mCurrFingerDiffY, mCurrFingerDiffX)
		val a2 = atan2(mPrevFingerDiffY, mPrevFingerDiffX)
		if ((a1 < 0 && a2 > 0) || (a1 > 0 && a2 < 0)) {
			// fix: sudden reverse when two fingers at:  -> O <-
			a1 = -a1
		}
		return ((a1 - a2) * 100 / PI).toFloat()
	}
```