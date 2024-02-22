---
mtrace:
  - 2023-07-25
  - 2024-02-17
tags:
  - question/coding/android
  - language/coding/kotlin
  - question/coding/practice
  - block_and_conquer
---
# 自定义QQ气泡View

#date 2023-07-25 #question/coding/android #language/coding/kotlin #question/coding/practice #block_and_conquer 

参考文章：[(47条消息) 自定义View完结篇--从实现QQ消息气泡去理解自定义View_Pingred_hjh的博客-CSDN博客](https://blog.csdn.net/qq_39867049/article/details/131539825?spm=1001.2014.3001.5501)

#TODO 

- [x] 自定义气泡View，以及如何把他塞到Compose里的

## 准备工作

首先，要确定这个Bubble都包含哪些View：

![[Article/story/resources/Pasted image 20230806123449.png]]

然后，确定一下这些View的属性：

* 中心的小圆
	* 半径：`mBubbleStillRadius`
	* 中心点：`mBubbleStillCenter`
* 移动的大圆
	* 半径：`mBubbleMoveRadius`
	* 中心点：`mBubbleMoveCenter`
* 气泡上的文字
	* 字符串：`mTextStr`
	* 字体大小：`mTextSize`
	* 颜色：`mTextColor`
	* 画字体的范围：`mTextRect`
* 相连时的路径
	* 贝塞尔曲线：`mBeiPath`

然后，这个气泡应该有几种状态：

```kotlin
companion object {  
    // 气泡的四种状态  
    private const val BUBBLE_DEFAULT = 0  
    private const val BUBBLE_CONNECT = 1  
    private const val BUBBLE_APART = 2  
    private const val BUBBLE_DISMISS = 3  
}
```

## 移动的大圆

然后，是确定这些View的位置，也就是给这些属性赋值。首先，我们只管这个移动的大圆。在默认模式下，它就应该显示在最初始的位置，然后在上面画上一个文字。所以，我们需要重写onDraw方法：

```kotlin
if (mBubbleState != BUBBLE_DISMISS) {  
    mBubbleMoveCenter.let {  
        canvas.drawCircle(it.x, it.y, mBubbleMoveRadius, mBubblePaint)  
        mTextPaint.getTextBounds(mTextStr, 0, mTextStr.length, mTextRect)  
        canvas.drawText(  
            mTextStr,  
            it.x - mTextRect.width() / 2,  
            it.y + mTextRect.height() / 2,  
            mTextPaint  
        )  
    }  
}
```

```ad-info
这里的条件为什么是`mBubbleState != BUBBLE_DISMISS`而不是`mBubbleState == BUBBLE_DEFAULT`呢？之后会说明为什么。
```

^d4a62e

那么，现在的问题就是：`mBubbleMoveCenter`是从哪儿来的？所以，我们需要在这之前就算出这个圆的初始位置。我们自然而然，就能想到重写onMeasure方法来确定。然而，我们有一个更好的方法，就是重写onSizeChanged方法。该方法是能在父容器的尺寸发生变化时触发的，也就是当我们的气泡所在的父容器即使发生了尺寸变化，它也会随着父容器变化而去测量自己的宽高，因为这样会比用onMearsure方法更好。并且，这个方法的参数本身就可以得到新的宽高和老的宽高：

```java
/**  
 * This is called during layout when the size of this view has changed. If * you were just added to the view hierarchy, you're called with the old * values of 0. * * @param w Current width of this view.  
 * @param h Current height of this view.  
 * @param oldw Old width of this view.  
 * @param oldh Old height of this view.  
 */
protected void onSizeChanged(int w, int h, int oldw, int oldh) {  
}
```

现在，就来重写吧！非常简单，只是给`mBubbleMoveCenter`设置下而已：

```kotlin
override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {  
    super.onSizeChanged(w, h, oldw, oldh)  
    if (!::mBubbleMoveCenter.isInitialized) {  
        mBubbleMoveCenter = PointF(w / 2F, h / 2F)  
    } else {  
        mBubbleMoveCenter.set(w / 2F, h / 2F)  
    }  
    if (!::mBubbleStillCenter.isInitialized) {  
	    mBubbleStillCenter = PointF(w / 2F, h / 2F)  
	} else {  
	    mBubbleStillCenter.set(w / 2F, h / 2F)  
	}
}
```

> 在中间的那个小圆的坐标我们也要确定下来哟。

这样，我们已经可以显示出这个气泡了。接下来，就是让它支持拖拽，也非常简单，就是修改`mBubbleMoveCenter`的横纵坐标：

```kotlin
override fun onTouchEvent(event: MotionEvent): Boolean {  
	when (event.action) {  
		ACTION_MOVE ->  {  
			mBubbleMoveCenter.x = event.x  
			mBubbleMoveCenter.y = event.y  
			invalidate()  
		}  
	}  
	return true  
}
```

最后调用invalidate()来触发onDraw方法。这样，就支持拖拽了：

![[Article/story/resources/scrcpy_HxNhQFFmRq.gif]]

## 中心的小圆

然后，就是那个在原地的小圆。要注意一下，这个小圆会响应的事件：

* 只有连接状态（`BUBBLE_CONNECT`）才会有这个圆；
* 随着移动的大圆和这个圆的距离**增加**，这个圆的半径会**变小**（但是不会变成负数）。

所以，首先要补充onDraw在`BUBBLE_CONNECT`状态下的情况：

```kotlin
if (mBubbleState == BUBBLE_CONNECT) {  
	canvas.drawCircle(  
		mBubbleStillCenter.x,  
		mBubbleStillCenter.y,  
		mBubbleStillRadius,  
		mBubblePaint  
	)  
}
```

```ad-warning
注意！这个条件和`mBubbleState != BUBBLE_DISMISS`是并列的！这样才能保留住我们之前拖拽的逻辑！
```

然后，我们也要给一个条件，能够让Bubble的状态从默认变为CONNECT。在哪里呢？当然是`ACTION_DOWN`的时候最合适了：

```kotlin
override fun onTouchEvent(event: MotionEvent): Boolean {  
	when (event.action) {  
		ACTION_DOWN -> {  
		    if (mDistance < mMaxDistance) {  
		        mBubbleState = BUBBLE_CONNECT  
		    }  
		    performClick()  
		}
		ACTION_MOVE ->  {  
			mBubbleMoveCenter.x = event.x  
			mBubbleMoveCenter.y = event.y  
			invalidate()  
		}  
	}  
	return true  
}
```

> mDistance是实际的距离，初始化时为0，之后会更改；mMaxDistance是我们希望分开时的距离，这个可以按需自定义。<u>为了测试需要，一开始我设置的非常大</u>。

![[Article/story/resources/scrcpy_aVzmBgCZ4k.gif]]

这里也要注意一下，onDraw中的两个if条件的位置关系。如果是这样：

```kotlin
override fun onDraw(canvas: Canvas) {  
	super.onDraw(canvas)  
	if (mBubbleState != BUBBLE_DISMISS) {  
		... ...
	}  
	if (mBubbleState == BUBBLE_CONNECT) {  
		... ...
	}  
}
```

我们来看一看效果：

![[Article/story/resources/scrcpy_RG5Vh88iQ5.gif]]

可以看到，那个中心的小圆把文字给遮住了。这就是因为在Canvas中，**先画的在下面，后画的在上面**。所以，我们要把这两个if调换一下，保证**移动的大圆和里面的文字是在最后画出来的**。因为这个圆才是用户希望看到的东西，其它的都只是装饰而已。

![[Article/story/resources/Pasted image 20230725134443.png]]

### 修改小圆的半径

接下来，就是修改这个圆的半径了。在哪里修改呢？当然是`ACTION_MOVE`啊！

```kotlin
override fun onTouchEvent(event: MotionEvent): Boolean {  
	when (event.action) {  
		ACTION_DOWN -> {  
			if (mDistance < mMaxDistance) {  
				mBubbleState = BUBBLE_CONNECT  
			}  
			performClick()  
		}  
		ACTION_MOVE ->  {  
			mBubbleMoveCenter.x = event.x  
			mBubbleMoveCenter.y = event.y  
			mDistance = hypot(  
				x = event.x - mBubbleStillCenter.x,  
				y = event.y - mBubbleStillCenter.y  
			)  
			if (mBubbleState == BUBBLE_CONNECT) {  
				if (mBubbleStillRadius > 0){  
					mBubbleStillRadius = mBubbleMoveRadius - mDistance / 6  
					if (mBubbleStillRadius < 0){  
						mBubbleStillRadius = 0F  
					}  
				}  
			}  
			invalidate()  
		}  
	}  
	return true  
}
```

当检测到手指移动时，就用勾股定理计算出距离。然后，就是通过这个距离来得到新的固定小圆的半径。这个半径是一个和距离成正比的函数关系：

```kotlin
mBubbleStillRadius = mBubbleMoveRadius - mDistance / 6  
```

这样才能看到线性缩小的动画。当某一次MOVE事件，使得这个半径由正数变成了负数，那么就把这个值置成0。并且，在之后的MOVE事件中，由于只有大于0才会进入，所以一旦变为0了，这个小圆就无法再在屏幕上看到了。

![[Article/story/resources/scrcpy_lui2KMM5OM.gif]]

## 中间的路径

接下來，就是画中间了路径了，一个贝塞尔曲线。这里的数学计算就不讲了，直接上结论。我们定义一个drawPath方法，把画路线的逻辑封装在这里。这样只需要调用一下，就能画出来了。同时需要注意，这个路径也是只有在CONNECT状态下才会画的：

```kotlin
override fun onDraw(canvas: Canvas) {  
	super.onDraw(canvas)  
	if (mBubbleState == BUBBLE_CONNECT) {  
		... ...
		drawPath(canvas)
	}  
	if (mBubbleState != BUBBLE_DISMISS) {  
		... ...
	}  
}

private fun drawPath(canvas: Canvas) {  
    val cosTana = (mBubbleMoveCenter.x - mBubbleStillCenter.x) / mDistance  
    val sinTana = (mBubbleMoveCenter.y - mBubbleStillCenter.y) / mDistance  
    val mAStartX = mBubbleStillCenter.x - mBubbleStillRadius * sinTana  
    val mAStartY = mBubbleStillCenter.y + mBubbleStillRadius * cosTana  
    val mBEndX = mBubbleMoveCenter.x - mBubbleMoveRadius * sinTana  
    val mBEndY = mBubbleMoveCenter.y + mBubbleMoveRadius * cosTana  
    val mCStartX = mBubbleMoveCenter.x + mBubbleMoveRadius * sinTana  
    val mCStartY = mBubbleMoveCenter.y - mBubbleMoveRadius * cosTana  
    val mDEndX = mBubbleStillCenter.x + mBubbleStillRadius * sinTana  
    val mDEndY = mBubbleStillCenter.y - mBubbleStillRadius * cosTana  
    val mGCenterX = (mBubbleStillCenter.x + mBubbleMoveCenter.x) / 2  
    val mGCenterY = (mBubbleStillCenter.y + mBubbleMoveCenter.y) / 2  
    mBeiPath.reset()  
    mBeiPath.moveTo(mAStartX, mAStartY)  
    mBeiPath.quadTo(mGCenterX, mGCenterY, mBEndX, mBEndY)  
    mBeiPath.lineTo(mCStartX, mCStartY)  
    mBeiPath.quadTo(mGCenterX, mGCenterY, mDEndX, mDEndY)  
    mBeiPath.close()  
    canvas.drawPath(mBeiPath, mBubblePaint)  
}
```

![[Article/story/resources/scrcpy_78R9MgukBP.gif]]

## 回弹动画

接下来，就是松手后的回弹动画了。如果依然处于CONNECT状态，需要播放回弹动画。这里定义一个回弹的startBubbleReset方法：

```kotlin
private fun startBubbleReset() {  
    ValueAnimator.ofObject(  
        PointFEvaluator(),  
        PointF(mBubbleMoveCenter.x, mBubbleMoveCenter.y),  
        PointF(mBubbleStillCenter.x, mBubbleStillCenter.y)  
    ).apply {  
        duration = 500  
        // 回弹效果  
        interpolator = OvershootInterpolator(5F)  
        addUpdateListener {  
            mBubbleMoveCenter = animatedValue as PointF  
            invalidate()  
        }  
        addListener(object : AnimatorListener {  
            override fun onAnimationStart(animation: Animator) {  
                mBubbleStillRadius = 0F  
                invalidate()  
            }  
  
            override fun onAnimationEnd(animation: Animator) {  
                mBubbleStillRadius = mBubbleMoveRadius  
                invalidate()  
            }  
  
            override fun onAnimationCancel(animation: Animator) {  
  
            }  
  
            override fun onAnimationRepeat(animation: Animator) {  
  
            }  
        })  
    }.start()  
}
```

定义好起点（移动大圆的位置）和终点（中心小圆的位置），然后这个动画就能帮我们规划好所有的属性。在过程中，每一次都会算出一个新的位置，也就是animatedValue。我们在Listener中就能获取到这个值，然后用这个坐标触发一次onDraw，就可以了。最后，是一些细节。在动画开始的时候，把中心圆的半径设置为0，在动画结束的时候，把它的半径置回最一开始的半径。**这样我们在下一次拖拽的时候，才能再次看到缩小的中心圆**。

最后，在ACTION_UP里调用一下这个方法就好了：

```kotlin
override fun onTouchEvent(event: MotionEvent): Boolean {  
    when (event.action) {  
        ACTION_DOWN -> {  
			...
        }  
        ACTION_MOVE ->  {  
			...
        }  
        ACTION_UP -> {  
            if (mBubbleState == BUBBLE_CONNECT) {  
                startBubbleReset()  
            }
        }  
    }  
    return true  
}
```

![[Article/story/resources/scrcpy_MKMGXSyq2w.gif]]

## 分离，消失

最后，就是它分开的过程了。非常简单，在MOVE的过程中，如果超过了最大距离，就变成APART，这个逻辑之前已经顺手加上去了。只是，需要把最大的值改一下。我设置的是`6 * mBubbleMoveRadius`：

![[Article/story/resources/scrcpy_VwXO4g3Mbp.gif]]

```ad-warning
这就是为什么[[#^d4a62e|之前]]那个if条件里要写不等于的原因！即使处于APART状态，移动的圆也是要画的！
```

然后，是松手时的逻辑。在ACTION_UP的时候，如果状态是APART，就要爆炸了。

```kotlin
ACTION_UP -> {  
    if (mBubbleState == BUBBLE_CONNECT) {  
        startBubbleReset()  
    } else if (mBubbleState == BUBBLE_APART) {  
        if (mDistance <= mMaxDistance) {  
            mBubbleState = BUBBLE_CONNECT  
            startBubbleReset()  
        } else {  
            mBubbleMoveRadius = 0F  
            mBubbleStillRadius = 0F  
            mBubbleState = BUBBLE_DISMISS  
            invalidate()  
        }  
    }  
}
```

将状态换成DISMISS，也就是消散状态。这样在触发onDraw的时候，所有的元素就都被清空了。

![[Article/story/resources/scrcpy_NcYx5fL2t9.gif]]

当然，这个程序到现在还是有很多小bug的。但是基本的雏形已经搭好，接下来的优化就水到渠成了。下面贴出来全部的代码（**顺便，这里也有从xml中获取属性的方法，在res/values/attrs.xml中定义**）：

```kotlin
class BubbleView(context: Context, attrs: AttributeSet) : View(context, attrs) {  
  
    private val TAG = "BubbleView"  
  
    // 抗锯齿画笔  
    private val mBubblePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {  
        color = Color.RED  
    }  
  
    private val mTextPaint = Paint(Paint.ANTI_ALIAS_FLAG)  
  
//    private lateinit var mContext: Context  
//    private lateinit var mAttrs: AttributeSet  
    private var mBubbleMoveRadius = 0F  
    private var mBubbleStillRadius = 0F  
    private var mBubbleColor = Color.RED  
    private var mTextStr = ""  
    private var mTextSize = 10F.sp  
    private var mTextColor = Color.WHITE  
    private var mBubbleState = BUBBLE_DEFAULT  
    private lateinit var mBubbleMoveCenter: PointF  
    private lateinit var mBubbleStillCenter: PointF  
    private val mTextRect = Rect()  
    private val mBeiPath = Path()  
    private var mDistance = 0F  
    private var mMaxDistance = 0F  
  
  
    companion object {  
        // 气泡的四种状态  
        private const val BUBBLE_DEFAULT = 0  
        private const val BUBBLE_CONNECT = 1  
        private const val BUBBLE_APART = 2  
        private const val BUBBLE_DISMISS = 3  
    }  
  
//    constructor(context: Context) : super(context) {  
//        mContext = context  
//    }  
//    constructor(context: Context, attrs: AttributeSet) : super(context, attrs) {  
//        mContext = context  
//        mAttrs = attrs  
//    }  
//    constructor(context: Context, attrs: AttributeSet, defStyle: Int) : super(context, attrs, defStyle) {  
//        mContext = context  
//        mAttrs = attrs  
//    }  
  
    init {  
        val array = context.obtainStyledAttributes(attrs, R.styleable.BubbleView)  
        mBubbleMoveRadius = array.getDimension(R.styleable.BubbleView_bubble_radius, mBubbleMoveRadius)  
        mBubbleStillRadius = array.getDimension(R.styleable.BubbleView_bubble_still_radius, mBubbleMoveRadius)  
        mBubbleColor = array.getColor(R.styleable.BubbleView_bubble_color, mBubbleColor)  
        mTextStr = array.getString(R.styleable.BubbleView_bubble_text) ?: mTextStr  
        mTextSize = array.getDimension(R.styleable.BubbleView_bubble_textSize, mTextSize)  
        mTextColor = array.getColor(R.styleable.BubbleView_bubble_textColor, mTextColor)  
        mTextPaint.apply {  
            color = mTextColor  
            textSize = mTextSize  
        }  
        mMaxDistance = 6 * mBubbleMoveRadius  
        array.recycle()  
  
    }  
  
    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {  
        super.onSizeChanged(w, h, oldw, oldh)  
        if (!::mBubbleMoveCenter.isInitialized) {  
            mBubbleMoveCenter = PointF(w / 2F, h / 2F)  
        } else {  
            mBubbleMoveCenter.set(w / 2F, h / 2F)  
        }  
        if (!::mBubbleStillCenter.isInitialized) {  
            mBubbleStillCenter = PointF(w / 2F, h / 2F)  
        } else {  
            mBubbleStillCenter.set(w / 2F, h / 2F)  
        }  
    }  
  
    override fun onDraw(canvas: Canvas) {  
        super.onDraw(canvas)  
        if (mBubbleState == BUBBLE_CONNECT) {  
            canvas.drawCircle(  
                mBubbleStillCenter.x,  
                mBubbleStillCenter.y,  
                mBubbleStillRadius,  
                mBubblePaint  
            )  
            drawPath(canvas)  
        }  
        // 这一段一定要放在后面！保证最后画移动的大圆和文字。这样文字才能显示在上面  
        if (mBubbleState != BUBBLE_DISMISS) {  
            mBubbleMoveCenter.let {  
                canvas.drawCircle(it.x, it.y, mBubbleMoveRadius, mBubblePaint)  
                mTextPaint.getTextBounds(mTextStr, 0, mTextStr.length, mTextRect)  
                canvas.drawText(  
                    mTextStr,  
                    it.x - mTextRect.width() / 2,  
                    it.y + mTextRect.height() / 2,  
                    mTextPaint  
                )  
            }  
        }  
    }  
  
    override fun onTouchEvent(event: MotionEvent): Boolean {  
        when (event.action) {  
            ACTION_DOWN -> {  
                if (mDistance < mMaxDistance) {  
                    mBubbleState = BUBBLE_CONNECT  
                }  
                performClick()  
            }  
            ACTION_MOVE ->  {  
                mBubbleMoveCenter.x = event.x  
                mBubbleMoveCenter.y = event.y  
                mDistance = hypot(  
                    x = event.x - mBubbleStillCenter.x,  
                    y = event.y - mBubbleStillCenter.y  
                )  
                if (mBubbleState == BUBBLE_CONNECT) {  
                    if (mDistance > mMaxDistance) {  
                        mBubbleState = BUBBLE_APART  
                    } else {  
                        if (mBubbleStillRadius > 0){  
                            mBubbleStillRadius = mBubbleMoveRadius - mDistance / 6  
                            if (mBubbleStillRadius < 0){  
                                mBubbleStillRadius = 0F  
                                Log.d(TAG, "BubbleStillRadius: $mBubbleStillRadius")  
                            }  
                        }  
                    }  
                }  
                invalidate()  
            }  
            ACTION_UP -> {  
                if (mBubbleState == BUBBLE_CONNECT) {  
                    startBubbleReset()  
                } else if (mBubbleState == BUBBLE_APART) {  
                    if (mDistance <= mMaxDistance) {  
                        mBubbleState = BUBBLE_CONNECT  
                        startBubbleReset()  
                    } else {  
                        mBubbleMoveRadius = 0F  
                        mBubbleStillRadius = 0F  
                        mBubbleState = BUBBLE_DISMISS  
                        invalidate()  
                    }  
                }  
            }  
        }  
        return true  
    }  
  
    override fun performClick(): Boolean {  
        return super.performClick()  
    }  
  
    private fun startBubbleReset() {  
        ValueAnimator.ofObject(  
            PointFEvaluator(),  
            PointF(mBubbleMoveCenter.x, mBubbleMoveCenter.y),  
            PointF(mBubbleStillCenter.x, mBubbleStillCenter.y)  
        ).apply {  
            duration = 500  
            // 回弹效果  
            interpolator = OvershootInterpolator(5F)  
            addUpdateListener {  
                mBubbleMoveCenter = animatedValue as PointF  
                invalidate()  
            }  
            addListener(object : AnimatorListener {  
                override fun onAnimationStart(animation: Animator) {  
                    mBubbleStillRadius = 0F  
                    invalidate()  
                }  
  
                override fun onAnimationEnd(animation: Animator) {  
                    mBubbleStillRadius = mBubbleMoveRadius  
                    invalidate()  
                }  
  
                override fun onAnimationCancel(animation: Animator) {  
  
                }  
  
                override fun onAnimationRepeat(animation: Animator) {  
  
                }  
            })  
        }.start()  
    }  
  
    private fun drawPath(canvas: Canvas) {  
        val cosTana = (mBubbleMoveCenter.x - mBubbleStillCenter.x) / mDistance  
        val sinTana = (mBubbleMoveCenter.y - mBubbleStillCenter.y) / mDistance  
        val mAStartX = mBubbleStillCenter.x - mBubbleStillRadius * sinTana  
        val mAStartY = mBubbleStillCenter.y + mBubbleStillRadius * cosTana  
        val mBEndX = mBubbleMoveCenter.x - mBubbleMoveRadius * sinTana  
        val mBEndY = mBubbleMoveCenter.y + mBubbleMoveRadius * cosTana  
        val mCStartX = mBubbleMoveCenter.x + mBubbleMoveRadius * sinTana  
        val mCStartY = mBubbleMoveCenter.y - mBubbleMoveRadius * cosTana  
        val mDEndX = mBubbleStillCenter.x + mBubbleStillRadius * sinTana  
        val mDEndY = mBubbleStillCenter.y - mBubbleStillRadius * cosTana  
        val mGCenterX = (mBubbleStillCenter.x + mBubbleMoveCenter.x) / 2  
        val mGCenterY = (mBubbleStillCenter.y + mBubbleMoveCenter.y) / 2  
        mBeiPath.reset()  
        mBeiPath.moveTo(mAStartX, mAStartY)  
        mBeiPath.quadTo(mGCenterX, mGCenterY, mBEndX, mBEndY)  
        mBeiPath.lineTo(mCStartX, mCStartY)  
        mBeiPath.quadTo(mGCenterX, mGCenterY, mDEndX, mDEndY)  
        mBeiPath.close()  
        canvas.drawPath(mBeiPath, mBubblePaint)  
    }  
  
    private val Float.sp: Float  
        get() = TypedValue.applyDimension(
			        TypedValue.COMPLEX_UNIT_SP, this, 
			        context.resources.displayMetrics
				)  
}
```

## 加入到Compose中

[在 Compose 中使用 View  |  Jetpack Compose  |  Android Developers](https://developer.android.com/jetpack/compose/migrate/interoperability-apis/views-in-compose?hl=zh-cn#:~:text=%E6%82%A8%E5%8F%AF%E4%BB%A5%E5%9C%A8%20Compose%20%E7%95%8C%E9%9D%A2%E4%B8%AD%E6%B7%BB%E5%8A%A0%20Android%20View%20%E5%B1%82%E6%AC%A1%E7%BB%93%E6%9E%84%E3%80%82%20%E5%A6%82%E6%9E%9C%E6%82%A8%E8%A6%81%E4%BD%BF%E7%94%A8%20Compose,%E5%8F%AF%E7%BB%84%E5%90%88%E9%A1%B9%20%E3%80%82%20%E7%B3%BB%E7%BB%9F%E4%BC%9A%E5%90%91%20AndroidView%20%E4%BC%A0%E9%80%92%E4%B8%80%E4%B8%AA%E8%BF%94%E5%9B%9E%20View%20%E7%9A%84%20lambda%E3%80%82)

```kotlin
@Composable  
fun CustomView() {  
    AndroidView(  
        modifier = Modifier.size(25.dp), // Occupy the max size in the Compose UI tree  
        factory = { context ->  
            // Creates view  
            BubbleView(context)  
        },  
        update = { view ->  
            /*  
                比如我在View里面自定义了一些属性，当view更新的时候，这些属性会变化。View自己是知道的，  
                但是如何返回给外面的Compose组件呢？在这里就可以做到了。  
             */        
		}  
    )  
}
```

用起来非常简单。这样`CustomView()`就变成了一个可组合项了。在任何位置都可以调用：

```kotlin
@Composable  
fun ContentExample() {  
    Column(  
        Modifier.fillMaxSize(),  
        horizontalAlignment = Alignment.CenterHorizontally,  
        verticalArrangement = Arrangement.SpaceEvenly  
    ) {  
        Text("Look at this CustomView!")  
        CustomView()  
        Text(text = "Look at me!")  
    }  
}
```

![[Article/story/resources/scrcpy_dAM56I0Gll.gif|300]]

你可能注意到，使用了这种方法，我也可以很轻松在Compose中设置控件的大小：

```kotlin
modifier = Modifier.size(25.dp)
```

这样，其它的位置就点不了了。

# MVC MVVM MVP

#question/coding/practice #language/coding/kotlin #question/coding/android #question/interview #rating/high 

- [ ] #TODO 三种架构模式 🔽

[一文读懂MVC、MVP和MVVM架构 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/616953800)

[MVC、MVP、MVVM的区别？前端面试标准答案！ - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/483586580)