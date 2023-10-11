拥有rating标签的是重要的面试问题。

#TODO 单例模式的风险，各种设计模式的风险

# View

> [!question]- View的绘制流程？

> [!question]- onMeasure方法一般执行几次，什么情况下会执行多次
> 
> #rating/medium 
> 
> onMeasure: [[Study Log/android_study/view_create_flow#3.2 Measure|view_create_flow]]
> 
> [Android中View的绘制过程 onMeasure方法简述 附有自定义View例子 - 圣骑士wind - 博客园 (cnblogs.com)](https://www.cnblogs.com/mengdd/p/3332882.html)
> 
> ![[Article/interview/resources/Pasted image 20230713103325.png]]
> 
> [(45条消息) View的三次measure,两次layout和一次draw_程序员历小冰的博客-CSDN博客](https://blog.csdn.net/u012422440/article/details/52972825)
> 
> #question/coding/practice Activity创建过程，onMeasure会执行几次？
> 
> [(45条消息) 进入Activity时，为何页面布局内View#onMeasure会被调用两次？_android onmeasure调用两次_tinyvampirepudge的博客-CSDN博客](https://blog.csdn.net/qq_26287435/article/details/123274342)
> 
> 这两次，第一次是measureHierarchy触发的，第二次是performMeasure触发的：
> 
> ![[Article/interview/resources/Pasted image 20230714151942.png]] ![[Article/interview/resources/Pasted image 20230714152029.png]]
> 
> 经过我自己的探索，又发现了一个会重新执行onMeasure的时机。看看下面的例子：
> 
> ![[Article/interview/resources/Pasted image 20230714140843.png]]
> 
> 上面是一个输入框和按钮，下面是我自定义的跑马灯：
> 
> [[Article/interview/resources/marquee|marquee]]
> 
> 我们输入一个可以让跑马灯跑起来的字符串：
> 
> ![[Article/interview/resources/Pasted image 20230714141052.png]]
> 
> 可以看到，跑马灯成功地跑了起来。但是，如果我们在EditText里插入一个换行符，也就是让这个空间的大小发生改变，此时如果我们在MarqueeText的onMeasure方法中打了断点，就能发现，居然真的执行到了这里。
> 
> **然而，如果我们将这两个控件调换一下位置**：
> 
> ![[Article/interview/resources/Pasted image 20230714141545.png]]
> 
> 这时，如果我们插入一个换行符，就不会执行到onMeasure方法了。
> 
> ![[Article/interview/resources/Pasted image 20230714141711.png]]
> 
> 因此，我们可以得到一个结论：如果布局的改变会影响当前布局的形态，位置的话，也是会重新执行onMeasure方法的。

> [!question]- 点击icon到展示第一帧页面经过了哪些流程，尤其是AndroidManagerService起了什么作用
> 
> #rating/high 
> 
> 应用启动流程：[[Study Log/android_study/app_boot_process|app_boot_process]]
> 
> [Android启动过程分析(图+文)-腾讯云开发者社区-腾讯云 (tencent.com)](https://cloud.tencent.com/developer/article/1356506)

> [!question]- View的绘制流程分为几步，从哪儿开始？哪个过程结束之后能够看到View？
> 
> 重点就是这张图：[[Study Log/android_study/resources/Pasted image 20230710142551.png]]
> 
> 从ViewRoot的performTraversals开始，经过measure，layout,draw 三个流程。draw流程结束以后就可以在屏幕上看到view了。

> [!question]- View的测量宽高和实际宽高有区别吗？
> 
> 基本上百分之99的情况下都是可以认为没有区别的。有两种情况，有区别。第一种 就是有的时候会因为某些原因 view会[[#onMeasure方法一般执行几次，什么情况下会执行多次|测量多次]]，那第一次测量的宽高 肯定和最后实际的宽高 是不一定相等的，但是在这种情况下最后一次测量的宽高和实际宽高是一致的。此外，实际宽高是在layout流程里确定的，我们可以在layout流程里将实际宽高写死 写成硬编码，这样测量的宽高和实际宽高就肯定不一样了，虽然这么做没有意义 而且也不好。
> 

> [!question]- View的measureSpec由谁决定？顶级View呢？
> 
> 我们在构造View的时候，知道要传入一个LayoutParams参数。而这个参数实际上就是在XML中声明View的时候写的那些属性。这些属性在入之后，在onMeasure阶段时，就会起到约束的作用。还记得我们重写onMeasure的逻辑吗？在[[Study Log/android_study/custom_view|自定义View]]的文章中：
> 
> ```java
> int widthSize = MeasureSpec.getSize(widthMeasureSpec); 
> int heightSize = MeasureSpec.getSize(heightMeasureSpec);
> ```
> 
> 这里实际上就是从LayoutParams里得到的结果，要么是match_parent，要么是确切的大小数值。而这也是为什么我们要单独处理wrap_content的原因了。
> 
> 另外，我们也不能毫无限制地传入LayoutParams，因为父容器一定是有一个限制的。因此，父容器的大小也是决定Spec的一个因素， #question/coding/practice  而这也是可能需要多次测量的原因。
> 
> #question/coding/practice 看这张图：
> 
> ![[Article/interview/resources/Pasted image 20230714104239.png]]
> 
> 这里说这两个Spec是父View施加上去的。然而经过实践可知，如果我们给这个View传入一个wrap_content属性，这里得到的值就会是AT_MOST。那为啥还是父亲施加上去的，难道不是我们自己传入的requirement吗？
> 
> 对于顶级的View，则稍微特殊一点。代码在ViewRootImpl中：
> 
> [[Article/interview/resources/get_root_measure_spec|get_root_measure_spec]]

> [!question]- 普通View的measure过程和它的父View有关吗？如果有关，这个父View扮演了什么角色？
> 
> 父View会是一个ViewGroup，因为只有ViewGroup才配拥有子节点。测量ViewGroup的过程参考[[Study Log/android_study/view_create_flow#3.2.4 ViewGroup的测量|这里]]。下面是其中WithMargins的源码：
> 
> ```java
> /**
>  * Ask one of the children of this view to measure itself, taking into
>  * account both the MeasureSpec requirements for this view and its padding
>  * and margins. The child must have MarginLayoutParams The heavy lifting is
>  * done in getChildMeasureSpec.
>  *
>  * @param child The child to measure
>  * @param parentWidthMeasureSpec The width requirements for this view
>  * @param widthUsed Extra space that has been used up by the parent
>  *        horizontally (possibly by other children of the parent)
>  * @param parentHeightMeasureSpec The height requirements for this view
>  * @param heightUsed Extra space that has been used up by the parent
>  *        vertically (possibly by other children of the parent)
>  */
> protected void measureChildWithMargins(View child,
> 		int parentWidthMeasureSpec, int widthUsed,
> 		int parentHeightMeasureSpec, int heightUsed) {
> 	// 第一步 先取得子view的 layoutParams 参数值
> 	final MarginLayoutParams lp = (MarginLayoutParams) child.getLayoutParams();
> 
> 	// 然后开始计算子view的spec的值，注意这里看到 
> 	// 计算的时候除了要用子view的 layoutparams参数以外
> 	// 还用到了父view 也就是viewgroup自己的spec的值
> 	final int childWidthMeasureSpec = getChildMeasureSpec(parentWidthMeasureSpec,
> 			mPaddingLeft + mPaddingRight + lp.leftMargin + lp.rightMargin
> 					+ widthUsed, lp.width);
> 	final int childHeightMeasureSpec = getChildMeasureSpec(parentHeightMeasureSpec,
> 			mPaddingTop + mPaddingBottom + lp.topMargin + lp.bottomMargin
> 					+ heightUsed, lp.height);
> 
> 	child.measure(childWidthMeasureSpec, childHeightMeasureSpec);
> }
> 
> 
> /**
>  * Does the hard part of measureChildren: figuring out the MeasureSpec to
>  * pass to a particular child. This method figures out the right MeasureSpec
>  * for one dimension (height or width) of one child view.
>  *
>  * The goal is to combine information from our MeasureSpec with the
>  * LayoutParams of the child to get the best possible results. For example,
>  * if the this view knows its size (because its MeasureSpec has a mode of
>  * EXACTLY), and the child has indicated in its LayoutParams that it wants
>  * to be the same size as the parent, the parent should ask the child to
>  * layout given an exact size.
>  *
>  * @param spec The requirements for this view
>  * @param padding The padding of this view for the current dimension and
>  *        margins, if applicable
>  * @param childDimension How big the child wants to be in the current
>  *        dimension
>  * @return a MeasureSpec integer for the child
>  */
> public static int getChildMeasureSpec(int spec, int padding, int childDimension) {
> 	int specMode = MeasureSpec.getMode(spec);
> 	int specSize = MeasureSpec.getSize(spec);
> 
> 	int size = Math.max(0, specSize - padding);
> 
> 	int resultSize = 0;
> 	int resultMode = 0;
> 
> 	switch (specMode) {
> 		// Parent has imposed an exact size on us
> 		case MeasureSpec.EXACTLY:
> 			if (childDimension >= 0) {
> 				resultSize = childDimension;
> 				resultMode = MeasureSpec.EXACTLY;
> 			} else if (childDimension == LayoutParams.MATCH_PARENT) {
> 				// Child wants to be our size. So be it.
> 				resultSize = size;
> 				resultMode = MeasureSpec.EXACTLY;
> 			} else if (childDimension == LayoutParams.WRAP_CONTENT) {
> 				// Child wants to determine its own size. It can't be
> 				// bigger than us.
> 				resultSize = size;
> 				resultMode = MeasureSpec.AT_MOST;
> 			}
> 			break;
> 	
> 		// Parent has imposed a maximum size on us
> 		case MeasureSpec.AT_MOST:
> 			if (childDimension >= 0) {
> 				// Child wants a specific size... so be it
> 				resultSize = childDimension;
> 				resultMode = MeasureSpec.EXACTLY;
> 			} else if (childDimension == LayoutParams.MATCH_PARENT) {
> 				// Child wants to be our size, but our size is not fixed.
> 				// Constrain child to not be bigger than us.
> 				resultSize = size;
> 				resultMode = MeasureSpec.AT_MOST;
> 			} else if (childDimension == LayoutParams.WRAP_CONTENT) {
> 				// Child wants to determine its own size. It can't be
> 				// bigger than us.
> 				resultSize = size;
> 				resultMode = MeasureSpec.AT_MOST;
> 			}
> 			break;
> 	
> 		// Parent asked to see how big we want to be
> 		case MeasureSpec.UNSPECIFIED:
> 			if (childDimension >= 0) {
> 				// Child wants a specific size... let them have it
> 				resultSize = childDimension;
> 				resultMode = MeasureSpec.EXACTLY;
> 			} else if (childDimension == LayoutParams.MATCH_PARENT) {
> 				// Child wants to be our size... find out how big it should
> 				// be
> 				resultSize = View.sUseZeroUnspecifiedMeasureSpec ? 0 : size;
> 				resultMode = MeasureSpec.UNSPECIFIED;
> 			} else if (childDimension == LayoutParams.WRAP_CONTENT) {
> 				// Child wants to determine its own size.... find out how
> 				// big it should be
> 				resultSize = View.sUseZeroUnspecifiedMeasureSpec ? 0 : size;
> 				resultMode = MeasureSpec.UNSPECIFIED;
> 			}
> 			break;
> 	}
> 	//noinspection ResourceType
> 	return MeasureSpec.makeMeasureSpec(resultSize, resultMode);
> }
> ```

> [!question]- View的measure和onMeasure有什么关系
> 
> [[Study Log/android_study/view_create_flow#^8894fd|view_create_flow]]

> [!question]- View的Measure流程
> 
> [[Study Log/android_study/view_create_flow#3.2 Measure|view_create_flow]]
> 
> ![[Study Log/android_study/resources/Pasted image 20230710145603.png]]

> [!question]- 自定义View中如果onMeasure方法没有对wrap_content做处理，会发生什么？怎么解决？
> 
> 见[[#View的measureSpec由谁决定？顶级View呢？]]，所以实际上是和match_parent效果相同。所以，我们需要给一个默认的宽或者高。而这个值是多少？其实我们是可以动态测量出来的。[[Study Log/android_study/custom_view#4.4 Example|这就是一个例子]]。

> [!question]- ViewGroup有onMeasure方法吗，为什么？
> 
> 首先，没有搜索到，所以一定没有。另外，[[Study Log/android_study/view_create_flow#3.2.4 ViewGroup的测量|ViewGroup的测量流程]]中，也只是调用了子View的测量方法，所以这个方法是交给子类自己实现的。不同的viewgroup子类布局都不一样，那onMeasure索性就全部交给他们自己实现好了。

> [!question]- 为什么在Activity的生命周期里无法获得测量宽高？有什么方法可以解决这个问题吗？
> 
> [Activity中获取某个View宽高信息的四种方法 - 掘金 (juejin.cn)](https://juejin.cn/post/7056659774028382245)
> 
> 因为measure的过程和activity的生命周期  没有任何关系。你无法确定在哪个生命周期执行完毕以后 view的measure过程一定走完。可以尝试如下几种方法 获取view的测量宽高。
> 
> - [*] onWindowFocusChanged
> 
> 该方法的含义是：View已经初始化完毕了，宽/高已经准备好了，所以此时去获取宽/高是没有问题的。
> 
> 注意：onWindowFocusChanged会被调用多次，当activity的窗口得到焦点和失去焦点时均会被调用一次，具体来说，当activity继续执行（onResume）和暂停执行（onPause）时，onWindowFocusChanged均会被调用。
> 
> ```kotlin
> // testView可以是Activity的成员
> override fun onWindowFocusChanged(hasFocus: Boolean) {  
>     super.onWindowFocusChanged(hasFocus)  
>     if (hasFocus) {  
>         val width = testView.measuredWidth  
>         val height = testView.measuredHeight  
>         Log.v("MainActivity", "width: $width")  
>         Log.v("MainActivity", "height: $height")  
>     }  
> }
> ```
> 
> - [*] view.post
> 
> 通过post可以将一个runnable投递到消息队列的尾部，然后等待Looper调用此runnable时，View也已经初始化好了。
> 
> ```kotlin
> override fun onStart() {  
>     super.onStart()  
>     testView.post {   
> 		val width = testView.measuredWidth  
>         val height = testView.measuredHeight  
>     }  
> }
> ```
> 
> - [*] ViewTreeObserver
> 
> 使用ViewTreeObserver的众多回调也可以完成这个功能，比如使用OnGlobalLayoutListener这个接口。当View树的状态发生改变或者View树内部的View的可见性发生改变时，onGlobalLayout方法将被调用。
> 
> 注意：伴随着View树的状态改变等，onGlobalLayout会被调用多次。因此需要在适当时机将监听回调移除。
> 
> ```kotlin
> override fun onStart() {  
> 	super.onStart()  
> 	val observer = testView.viewTreeObserver  
> 	observer.addOnGlobalLayoutListener(object : OnGlobalLayoutListener {  
> 		override fun onGlobalLayout() {  
> 			observer.removeOnGlobalLayoutListener(this)  
> 			val width = testView.measuredWidth  
> 			val height = testView.measuredHeight  
> 		}  
> 	})  
> }
> ```
> 
> ```ad-error
> title: 警告
> 
> 这种方式会导致程序崩溃，目前在调查原因。
> ```

> [!question]- layout和onLayout方法有什么区别
> 
> [[Study Log/android_study/view_create_flow#3.3 Layout|view_create_flow#layout]]
> 
> layout是确定本身view的位置而onLayout是确定所有子元素的位置。layout里面就是通过 [[Study Log/android_study/view_create_flow#^42577a|setFrame]]方法设设定本身view的四个顶点的位置。这4个位置以确定 自己view的位置就固定了。
> 
> 然后就调用onLayout来确定子元素的位置。view和viewgroup的onlayout方法都没有写。都留给我们自己给子元素布局。 

> [!question]- draw方法有几个步骤
> 
> 比较重要的步骤有4个：[[Study Log/android_study/view_create_flow#^2bf32e|view_create_flow]]。然而，其中的第二步和第五步通常情况下是可以跳过的。为什么跳过可以看看源码。
> 
> #TODO 分析跳过的源码

> [!question]- setWillNotDraw方法有什么用
> 
> 这是View的方法：
> 
> ```java
> /**
>  * If this view doesn't do any drawing on its own, set this flag to
>  * allow further optimizations. By default, this flag is not set on
>  * View, but could be set on some View subclasses such as ViewGroup.
>  *
>  * Typically, if you override {@link #onDraw(android.graphics.Canvas)}
>  * you should clear this flag.
>  *
>  * @param willNotDraw whether or not this View draw on its own
>  */
> public void setWillNotDraw(boolean willNotDraw) {
> 	setFlags(willNotDraw ? WILL_NOT_DRAW : 0, DRAW_MASK);
> }
> ```
> 
> 用于设置标志位的 也就是说 如果你的自定义view不需要draw的话，就可以设置这个方法为true。这样系统知道你这个view 不需要draw 可以**优化执行速度**。viewgroup一般都默认设置这个为true，因为viewgroup多数都是只负责布局。
> 
> 不负责draw的。而view 这个标志位 默认一般都是关闭的。

> [!question]- 自定义View有什么需要注意的？
> 
> 1. wrap_content
> 2. padding
> 
> 下面是一个自定义的圆形：
> 
> ```kotlin
> class CircleView : View {  
>     private val mColor = Color.RED  
>     private val mPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = mColor }  
>   
>     constructor(context: Context) : super(context)  
>     constructor(context: Context, attrs: AttributeSet) : super(context, attrs)  
>     constructor(context: Context?, attrs: AttributeSet?, defStyleAttr: Int) : super(  
>         context,  
>         attrs,  
>         defStyleAttr  
>     )  
>   
>     override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {  
>         super.onMeasure(widthMeasureSpec, heightMeasureSpec)  
>   
>         val widthMode = MeasureSpec.getMode(widthMeasureSpec)  
>         val heightMode = MeasureSpec.getMode(heightMeasureSpec)  
>   
>         val widthSize = MeasureSpec.getSize(widthMeasureSpec)  
>         val heightSize = MeasureSpec.getSize(heightMeasureSpec)  
>   
>         if (widthMode == MeasureSpec.AT_MOST && heightMode == MeasureSpec.AT_MOST) {  
>             setMeasuredDimension(200, 200);  
>         } else if (widthMode == MeasureSpec.AT_MOST) {  
>             setMeasuredDimension(200, heightSize)  
>         } else if (heightMode == MeasureSpec.AT_MOST) {  
>             setMeasuredDimension(widthSize, 200)  
>         }  
>     }  
>   
>     override fun onDraw(canvas: Canvas?) {  
>         super.onDraw(canvas)  
> 
> 		// padding在xml中设置后，就会成为getPaddingXXX的返回值
>         val w = width - paddingLeft - paddingRight  
>         val h = height - paddingTop - paddingBottom  
>         val r = min(w, h) / 2  
>         canvas?.drawCircle(  
>             (paddingLeft + w / 2).toFloat(),  
>             (paddingTop + h / 2).toFloat(),  
>             r.toFloat(),  
>             mPaint  
>         )  
>     }  
> }
> ```

# Touch Event

> [!question]- 触摸事件传递的流程都有哪些可能？
> 
> 首先，触摸事件是一个**一次性**的东西，也就是在传递的过程中，如果被某个View给拦截并消费了，就会终止。而这个消费的过程就写在onTouchEvent()中，所以这整个过程看起来就像一条L型的链子：
> 
> ![[Article/interview/resources/Pasted image 20230725094136.png|500]]
> 
> 而如果任何一个View都没有消费这个事件，那么这个事件就会最终重新回到Activity，变成一个U型的链：
> 
> ![[Article/interview/resources/Pasted image 20230725094305.png|500]]

> [!question]- 这些MotionEvent在触摸的时候都可能会触发多少次？
> 
> 我们可以在dispatchEvent和onTouchEvent上都打上日志来看一看：
> 
> ```
> dispatch, ev: MotionEvent { action=ACTION_DOWN, ...
> onTouch, ev: MotionEvent { action=ACTION_DOWN, ...
> dispatch, ev: MotionEvent { action=ACTION_MOVE, ...
> onTouch, ev: MotionEvent { action=ACTION_MOVE, ...
> dispatch, ev: MotionEvent { action=ACTION_MOVE, ...
> onTouch, ev: MotionEvent { action=ACTION_MOVE, ...
> ... ...
> dispatch, ev: MotionEvent { action=ACTION_UP, ...
> onTouch, ev: MotionEvent { action=ACTION_UP, ...
> ```
> 
> 可以看到，DOWN只有一次，而中间可能会经过若干次MOVE，最后来一个UP。这也是非常符合我们的常识的。
> 
> ![[Article/interview/resources/Pasted image 20230725100859.png|500]]

> [!question]- 如果要实现拖拽，需要如何重写方法？
> 
> 最简单地，只需要重写onTouchEvent()方法就可以了。当按下时，记住点击的位置，然后MOVE时，不断算出新的位置并更新：
> 
> ```kotlin
> override fun onTouchEvent(event: MotionEvent): Boolean {  
> 	when (event.action) {  
> 		MotionEvent.ACTION_MOVE -> {  
> 			val x = event.rawX.toInt()  
> 			val y = event.rawY.toInt()  
> 			val destX = x - mLastFocusX  
> 			val destY = y - mLastFocusY  
> 			windowParams.x += destX  
> 			windowParams.y += destY  
> 			windowManager.updateViewLayout(this, windowParams)  
> 			mLastFocusX = x  
> 			mLastFocusY = y  
> 		}  
> 		MotionEvent.ACTION_DOWN -> {  
> 			mLastFocusX = event.rawX.toInt()  
> 			mLastFocusY = event.rawY.toInt()  
> 			performClick()  
> 		}  
> 	}  
> 	return true  
> }
> ```
> 
> 上面的例子是一个可以拖拽的悬浮窗。当move时，首先算出新的位置保存到windowParams中，然后用它来更新悬浮窗。而如果我们想要设计一个可以全局拖拽的普通View的话，可以使用layout()方法：
> 
> ```kotlin
> override fun onTouchEvent(event: MotionEvent): Boolean {  
>     when (event.action) {  
>         MotionEvent.ACTION_MOVE -> {  
>             val x = event.rawX.toInt()  
>             val y = event.rawY.toInt()  
>             val destX = x - mLastFocusX  
>             val destY = y - mLastFocusY  
>             val left = left + destX  
>             val top = top + destY  
>             val right = right + destY  
>             val bottom = bottom + destY  
>             layout(left, top, right, bottom)  
>             mLastFocusX = x  
>             mLastFocusY = y  
>         }  
>         MotionEvent.ACTION_DOWN -> {  
>             mLastFocusX = event.rawX.toInt()  
>             mLastFocusY = event.rawY.toInt()  
>             performClick()  
>         }  
>     }  
>     return true  
> }
> ```
> 
> 另外，我们还可以在onDraw()方法里去处理，并在更新完之后调用invalidate()来触发绘画。可以参考自定义气泡的例子：[[Article/story/2023-07-25#自定义QQ气泡View|2023-07-25]]。
> 
> ```ad-caution
> 我们要注意一下getX()和getRawX()的区别。前者获取的是相对于**屏幕**左上角的横坐标，而后者是相对于收到这个事件的**View**左上角的横坐标。
> ```

> [!question]- 什么时候才需要重写dispatchTouchEvent()方法？
> 
> `dispatchTouchEvent`是一个用于分发触摸事件的方法，它负责将触摸事件传递给目标View和ViewGroup的方法。大部分情况下，你不需要重写`dispatchTouchEvent`方法，因为它在`View`和`ViewGroup`类中已经有了默认的实现，会自动处理触摸事件的分发。
> 
> 但有时候，你可能需要重写`dispatchTouchEvent`方法来实现一些特定的触摸事件分发逻辑。以下是一些需要重写`dispatchTouchEvent`方法的情况：
> 
> 1.  事件拦截：如果你希望在触摸事件到达目标View之前拦截并处理触摸事件，可以重写`dispatchTouchEvent`方法，然后在适当的时候返回`true`来拦截事件，或者返回`false`将事件传递给目标View。
> 2.  自定义事件分发逻辑：在某些特殊情况下，你可能希望根据自己的业务需求定制触摸事件的分发逻辑。例如，你可能需要根据一些条件来决定是否将触摸事件传递给子View，或者在某些情况下将触摸事件传递给父View。
> 3.  事件日志记录：有时候你可能需要在应用程序中记录触摸事件的信息，以便进行调试或分析。通过重写`dispatchTouchEvent`方法，你可以在事件分发过程中添加日志记录。
> 
> 值得注意的是，如果你决定重写`dispatchTouchEvent`方法，通常你需要在方法中实现一些复杂的逻辑来正确地处理触摸事件的分发。因此，在没有特定需求的情况下，最好不要随意重写`dispatchTouchEvent`方法，以免引入不必要的复杂性和潜在的错误。大多数情况下，可以通过在`onTouchEvent`方法中处理触摸事件来满足常规需求。

> [!question]- 什么时候才需要重写onInterceptTouchEvent()方法？
> 
> `onInterceptTouchEvent`方法用于拦截子View的触摸事件，它是在`ViewGroup`类中定义的。当一个`ViewGroup`包含多个子View时，如果你希望在某些特定情况下拦截子View的触摸事件，并阻止其传递给子View的`onTouchEvent`方法，就可以重写`onInterceptTouchEvent`方法。
> 
> 一般情况下，你不需要经常重写`onInterceptTouchEvent`方法，因为它的默认实现已经满足大多数情况。但以下情况可能需要重写该方法：
> 
> 1.  滑动冲突解决：当`ViewGroup`中包含多个可滑动的子View（例如`ScrollView`、`RecyclerView`等）时，可能会出现滑动冲突。如果你希望在某些情况下阻止子View的滑动事件，就可以在`onInterceptTouchEvent`方法中实现相关逻辑来解决滑动冲突。
> 2.  手势处理：在某些场景下，你可能需要在`ViewGroup`中检测特定的手势，例如双击、长按等，来触发一些自定义操作。在这种情况下，你可以重写`onInterceptTouchEvent`方法来实现手势的拦截和处理。
> 3.  自定义触摸事件分发逻辑：如果你的`ViewGroup`需要定制触摸事件的分发逻辑，例如根据某些条件来决定是否拦截触摸事件，就可以在`onInterceptTouchEvent`方法中实现相应的逻辑。
> 
> 需要注意的是，当你重写`onInterceptTouchEvent`方法时，需要谨慎处理触摸事件的拦截逻辑，以免引入不必要的滑动冲突或触摸事件的混乱。正确处理触摸事件的拦截逻辑能够提供更好的用户体验，并确保各个子View能够正确响应用户的触摸操作。
> 
> 最后，与`dispatchTouchEvent`方法一样，在没有特定需求的情况下，最好不要随意重写`onInterceptTouchEvent`方法，以免引入复杂性和潜在的错误。在大多数情况下，通过在`onTouchEvent`方法中处理触摸事件已经能够满足常规需求。

# Handler

> [!question]- 一个线程有几个Looper？

> [!question]- 你对Handler的了解？

> [!question]- 如何保障一个线程最多只有一个Looper？



# AMS

> [!question]- 一个Activity启动另一个Activity，通过什么启动的？
>
> 你可能会说Intent，但我要底层。答案是通过AMS。在AMS中有一个列表叫processList的成员。这个成员的类型是ProcessList，而在ProcessList类里面有个成员是一个ProcessRecord的列表：[[Study Log/android_study/resources/process_record|process_record]]。从注释看就能看出它是正在运行的进程的标识。所以，在AMS里面是维持着一张所有进程的表。我这个Activity启动其它Activity，本质上是**我这个进程想启动其它Activity**。所以必须向AMS去查询这个表才能得到目标进程的信息，或者说间接通过AMS去启动其它Activity。~~最后，和SystemServer一样，也是通过[[Study Log/android_study/system_server#^e0a7ae|zygoteInit]]那个方法启动，通过反射找到ActivityThread的main函数启动的。~~ActivityThread是在底层启动的，和SystemServer的位置不一样：[ActivityThread分析—ActivityThread的main方法是如何被调用的_Red_Dragon_的博客-CSDN博客](https://blog.csdn.net/user11223344abc/article/details/81013641)

> [!question]- 一个新的进程被启动，AMS是如何管理的？
> 
> 首先，我们要清楚，一个Application启动代表着ActivityThread的main函数启动。它里面有着ApplicationThread的**内部类**：`final ApplicationThread mAppThread = new ApplicationThread();`在ActivityThread的main函数中，有一个attach方法，在attach内部会把这个mAppThread给attach上去。这样AMS就能够拿到这个进程的句柄，从而管理这个进程了。

> [!question]- AMS属于SystemServer还是ServiceManager？
> 
> 这个问题非常刁钻。如果说AMS的实例运行在哪里，那答案是SystemServer进程；而如果说是AMS的服务主要都放在哪里，那还是ServiceManager里。看这里：[[Study Log/android_study/ams#^4b84eb|ams]]，应用想要拿binder，就得通过ServiceManager拿，然后解析成ATMS的接口就能用了。

# SystemServer

> [!question]- 为什么有的服务里有LifeCycle内部类，有的服务没有？
> 
> 有LifeCycle的服务的你看看是什么就知道了，它们是AMS和ATMS。这些东西干什么的？管理四大组件的，那四大组件有没有生命周期？有！所以你知道为啥了吧。其实，最主要的原因是这样写，**通过内部类的方式来把被管理对象给抠出去。也就是你只能管理我的内部类，但你不能管理我。所以这样的灵活性会大大增加**。

# Binder

安卓11以前，是直接用linux的接口来控制binder，到了安卓12，变成了libbinder库和AIDL：

[Android 12 系统源码分析 | Native Binder 代码变迁 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/454886399)

> [!question]- 你了解Binder吗？是什么机制？

# Zygote

> [!question]- 为什么Zygote通信使用Socket而不使用Binder？
> 
> 最大的原因，是Linux不推荐fork一个多线程的进程。如果采用了Binder机制的话，看[[Study Log/android_study/binder#1 Binder的创建|binder的创建流程]]就知道，你都用线程池了，还不是多线程？而如果fork了一个多线程，那对于锁的控制是非常麻烦的。所以为了避开这个，只能采用单线程的方法，而最终选用了Socket。

^36a413

# Java

> [!question]- 类加载的双亲委派？

> [!question]- Java的引用类型？

> [!question]- Cache的缓存应该是软引用还是弱引用？

# Kotlin

> [!question]- 为什么要学Kotlin？

> [!question]- Kotlin如何比较两个对象相等？

> [!question]- Data Class默认支持哪些函数（比如copy）？

> [!question]- Kotlin是编译还是解释？

# 架构

> [!question]- 你对MVVM有什么理解？

> [!question]- 安卓整体的架构你看过吗？

> [!question]- MVC MVP MVVM？

# Activity

> [!question]- Activity的生命周期都有哪些？

> [!question]- Activity的启动模式，它们的差异？

# 数据结构

> [!question]- HashMap的了解？

# 性能优化

> [!question]- 你遇到过卡顿吗？怎么解决的？

# Git

> [!question]- 项目不存在，从远端拉取项目怎么办？

> [!question]- 开发分支同步主分支一般怎么办？

> [!question]- rebase出现冲突怎么解决？

# 网络

> [!question]- TCP三次握手的流程？可以两次握手吗？

# 项目

> [!question]- 自己写的项目和企业里的项目区别是什么？

# 进程

> [!question]- 进程有哪几种状态？

> [!question]- 一个进程启动时，操作系统都做了哪些工作？

> [!question]- 虚拟地址空间可以分为哪些部分？

> [!question]- 在Linux中malloc分配的内存是虚拟地址还是物理地址？是在栈上还是堆上？

> [!question]- 内核是怎么管理虚拟地址空间的？

# 开放问题

> [!question]- 每输入一个字符就展示新的匹配，该怎么设计和优化？

# 其它

> [!question]- 编译和解释的区别？

> [!question]- 你的技术爱好兴趣有哪些？

# 按公司分类

## 快手

### 客户端平台组

#### 一面

> [!question]- Kotlin比Java好在哪儿？有什么优点？

> [!question]- Kotlin比较对象相等用什么方法？

> [!question]- Kotlin data class如果不写其它方法还有什么方法？

> [!question]- MVVM

> [!question]- Activity生命周期

> [!question]- Activity启动模式

> [!question]- Android整体的架构了解吗？

> [!question]- NDK开发有接触过吗？

> [!question]- 卡顿优化做过吗？

> [!question]- 进程的状态有哪些？

> [!question]- 你对Binder的了解？

> [!question]- Git从远端拉取项目用什么？

> [!question]- Git开发分支如何同步主分支代码？

> [!question]- Rebase如何解决冲突？

> [!question]- TCP的三次握手？两次握手可以吗？

> [!question]- 你的两个项目给你最大收获的是哪个？有什么收获？

> [!question]- 你个人感觉实习的项目和自己做的项目最大区别是什么？

> [!question]- 算法：二叉树的锯齿形层序遍历

#### 二面

> [!question]- 你的技术爱好兴趣有哪些？比如安卓，Framework，Linux内核？

> [!question]- 为什么你要学习QEMU？

> [!question]- 在Linux中，一个进程启动，操作系统都做了哪些事情？

> [!question]- 进程的虚拟地址空间可以分为哪些部分？

> [!question]- 在Linux中，malloc分配的内存是虚拟地址还是物理地址？是在栈空间还是堆空间？

> [!question]- 内核是如何管理虚拟地址空间的？

> [!question]- 你觉得对于一个新手来说，如何学习一门开发语言？

> [!question]- 算法：删除链表倒数第N个结点

#### 三面

> [!question]- 寻车的APP是主动寻车还是被动寻车？是车辆主动发消息吗？

> [!question]- 寻车进程是如何实现保活的？

> [!question]- Binder是同步通信还是异步通信？

> [!question]- MMKV耗时低的原因是什么？它有什么缺点？

> [!question]- 为什么寻车项目要重构？你在里面的角色是怎样的？

> [!question]- Android Framework里的状态机在哪里使用的？具体讲讲原理？

> [!question]- Mock工具为什么选择一秒发一个消息？

> [!question]- 处理ANR的问题是怎么处理的？

> [!question]- ANR的原理，是怎么触发的？

> [!question]- 有了解过Logcat的原理吗？为什么它能把日志输出出来？

> [!question]- Kotlin的协程是怎么实现的？

> [!question]- 不用线程池（线程池是一种偷懒行为），还有没有其它实现协程的方法？

> [!question]- 为什么在安卓12之后，binder的操作从内核态迁移到了用户态？

> [!question]- Handler有哪些组件？基本原理？

> [!question]- [[Article/interview/resources/handler|这段]]代码的执行顺序是怎样的？

> [!question]- Handler为什么会导致内存泄露？怎么解决？

> [!question]- 算法：找到数组中第K大（手撕大顶堆）

## 字节

### 飞书中台

#### 一面

> [!question]- 遇到ANR问题该怎么解决？

> [!question]- 为什么会发生ANR？ANR都有哪些类型？

> [!question]- View绘制的流程

> [!question]- 跑马灯，如果锁屏或者应用切到了后台会有什么问题？

> [!question]- 讲讲MVVM是什么东西？

> [!question]- ViewModel和View之间是怎么关联起来的？

> [!question]- 从当前Activity进入到下一个Activity再回来。这个过程中ViewModel的实例会变吗？横竖屏切换的时候呢？

> [!question]- 现在就一个Activity，一个ViewModel，Activity被销毁了后又重建了，为什么这个Activity拿到的ViewModel还是之前的那个而不是创建一个新的？或者说为什么ViewModel的生命周期比Activity长？

> [!question]- 进程和线程的区别是什么？

> [!question]- Handler

> [!question]- Java里锁的概念？

> [!question]- syncronized和volatile的区别是什么？

> [!question]- 知道类锁和对象锁的概念吗？

> [!question]- Kotlin扩展函数的原理？

> [!question]- kt flow和rxjava有什么区别？

> [!question]- kt flow里面如何切换线程？原理是什么？

> [!question]- Java反射的原理？

> [!question]- TCP为什么有半关闭的过程？

> [!question]- 代码：三个线程交替打印1-100

### 国际化

#### 一面

> [!question]- 开放性问题：搜索优化

> [!question]- 每次变更都要直接写到数据库里吗？

> [!question]- Kotlin是解释型的还是编译型的？

> [!question]- 编译和解释的区别？

> [!question]- 你对HashMap了解多少？

> [!question]- HashMap是线程安全的吗？

> [!question]- 类加载的双亲委派机制？

> [!question]- Java的引用类型？

> [!question]- 在搜索优化的例子中，搜索结果的缓存应该是什么引用？

> [!question]- 什么场景下会用到弱引用？

> [!question]- MVP MVVM MVC

> [!question]- 你对Handler Looper的了解？为什么能保证一个线程只有最多一个Looper？

> [!question]- View的绘制流程

> [!question]- 算法：大整数相加

#### 二面

> [!question]- 项目

> [!question]- 广播都有哪几类？怎么使用？

> [!question]- Service分为哪几种？怎么使用？

> [!question]- 对Binder的了解？

> [!question]- Binder是怎么让两个进程能互相找到对方的？

> [!question]- 常用的布局，Layout的了解？有什么性能问题？ConstraintLayout要注意什么？

> [!question]- 给了你界面设计，你设计布局的偏好是怎样的？

> [!question]- 动画有哪几种？你对动画的了解？

> [!question]- 自定义View的常见流程

> [!question]- 算法：二叉树最近公共祖先

### 西瓜视频

#### 一面

> [!question]- 实习的时候遇到的技术上的难点？怎么解决的？

> [!question]- Mock工具的两个版本，是如何分类的？

> [!question]- ANR分类，原理

> [!question]- 线程和进程

> [!question]- 如何声明一个进程？

> [!question]- 怎样安全停止掉一个线程？你知道interrupt吗？

> [!question]- 为什么会发生死锁？死锁必要条件？

> [!question]- JVM做过什么锁优化？

> [!question]- 知道CAS吗？它有一些什么问题？

> [!question]- volatile的作用？

> [!question]- Kotlin对比Java的优缺点？

> [!question]- apply和let的区别？

> [!question]- 对协程的了解？

> [!question]- Android都有哪些持久化的方式？

> [!question]- SharedPreferences和SQLite的选择？

> [!question]- 悬浮窗是怎么实现的？Activity是如何和Service通信的？

> [!question]- 算法：两个栈实现队列的push, pop, peek

## 美团

### 优选

#### 一面

> [!question]- 深拷贝和浅拷贝的区别

> [!question]- JVM中堆和栈的区别

> [!question]- Java里一个静态方法调用一个非静态成员，可以吗？

> [!question]- OSI七层模型

> [!question]- HTTP默认端口？HTTPS默认端口？

> [!question]- 你对DNS的理解？

> [!question]- RESTful API的风格？

> [!question]- 你还知道其它的API设计风格吗？

> [!question]- 你知道微服务架构吗？

> [!question]- 进程和线程的区别？

> [!question]- 内存分页的机制？为什么要内存分页？

> [!question]- 在企业实习的时候会遇到平时没做过的东西。遇到这种情况时你的思路是什么？

> [!question]- 一个新框架，新语言，你是怎么学习的？

> [!question]- 如果是你完全没接触过的新东西，你学习的方法和途径都有哪些？

> [!question]- 如何尽量保证自己从0到1的项目的扩展性？

> [!question]- 如果是业务开发的话，对业务方法进行多次迭代，会有很大改动，如何避免这种事情？

> [!question]- 算法：合并两个有序链表

> [!question]- 算法：青蛙跳

> [!question]- 算法：最长回文字串

#### 二面

> [!question]- 最近关注哪些技术方向或者技术热点？

> [!question]- 平时有哪些学习渠道？

> [!question]- 笔记仓库是从什么时候开始的？

> [!question]- 学习过程中遇到过哪些难点？
> 

> [!question]- 从什么时候开始接触安卓的？

> [!question]- Framework主要看了哪些部分？

> [!question]- 看过Zygote吗？

> [!question]- Zygote用Socket通信，是怎么了解到的？

> [!question]- 安卓的虚拟机大概是什么架构？

> [!question]- 在实习的时候有对项目提过改进的建议吗？

> [!question]- 我提的建议有没有遇到意见冲突的时候？怎么解决的？

> [!question]- 算法：求相交的两个链表的交点

> [!question]- 算法：给定一个整形数组，构建出[[Article/interview/resources/Pasted image 20230907143107.png|最大根的二叉树]]（分治）。

> [!question]- 你今后的发展方向？有什么规划？

## 淘天

### 1688

#### 一面

> [!question]- Kotlin协程的原理？

> [!question]- 了解过其它语言的协程吗？

> [!question]- Kotlin协程的优缺点？

> [!question]- 点击APP图标到启动的流程

> [!question]- 从通知栏进入应用和点击APP图标有什么区别？

> [!question]- 线程和进程的区别

> [!question]- LiveData的好处

> [!question]- RxJava用过吗？

> [!question]- 为什么要用Compose？

> [!question]- 用过Compose跨平台吗？

> [!question]- 做过Compose性能和传统View性能的对比吗？

> [!question]- 内存测试有做过吗？

> [!question]- 贪心算法的原理

> [!question]- 对AI大模型是否感兴趣？或者其它的一些技术？

> [!question]- 了解车机系统吗？

> [!question]- 

# 流程图

- [*] Activity启动全流程

![[Study Log/android_study/resources/Drawing 2023-08-17 13.28.16.excalidraw.png]]

- [*] SystemServer工作流程

![[Study Log/android_study/resources/Drawing 2023-08-15 15.34.25.excalidraw.png]]

- [*] SystemServer启动流程

![[Study Log/android_study/resources/Drawing 2023-08-15 18.33.52.excalidraw.png|700]]

# 其它位置

```dataviewjs
let data = [];
for (let page of dv.pages("#question/interview")) {
	let fileStr = await dv.io.load(page.file.path);
	let lines = fileStr.split('\n');
	let headers = "";
	for (let line of lines) {
		let hashCount = 0;
		if (line.match(/^#+\s/)) {
			hashCount += (line.match(/#/g) || []).length;
			headers += generateNestedList(hashCount, line.replace(/^#+\s/, ""));
		}
	}
	let fileLink = "[[" + page.file.path + "]]";
	headers = "<div style=\"border: 2px solid #D58E06; padding: 10px;\">" + headers + "</div>";
	data.push({fileLink, headers})
}
function generateNestedList(level, content) {
	if (level === 0) { 
		return content; 
	} 
	const nestedListContent = generateNestedList(level - 1, content); 
	return `<ul><li>${nestedListContent}</li></ul>`; 
}
dv.table(
	["File Name", "Headers"],
	data.map(d => [d.fileLink, d.headers])
);
```