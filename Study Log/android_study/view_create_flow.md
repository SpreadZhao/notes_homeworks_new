# 3 View绘制流程

View绘制的三大流程：Measure -> Layout -> Draw。下面是准备工作：

![[Study Log/android_study/resources/Pasted image 20230710140529.png]]

图中是每一个Activity中和View绘制有关的组件。我们可以看到，**每一个Activity**都对应着一个PhoneWindow，这个对象负责管理和显示所有的窗口。PhoneWindow是Window的一个实现类。

[Activity 与 Window、PhoneWindow、DecorView 之间的关系简述 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/26834562#:~:text=%E6%AF%8F%E4%B8%80%E4%B8%AA%20Activity%20%E9%83%BD%E6%8C%81%E6%9C%89%E4%B8%80%E4%B8%AA%20Window%20%E5%AF%B9%E8%B1%A1%EF%BC%8C%20public%20class%20Activity,PhoneWindow%20%E5%AF%B9%E8%B1%A1%E3%80%82%20%E4%BD%86%E6%98%AF%20PhoneWindow%20%E7%BB%88%E7%A9%B6%E6%98%AF%20Window%EF%BC%8C%E5%AE%83%E5%B9%B6%E4%B8%8D%E5%85%B7%E5%A4%87%E5%A4%9A%E5%B0%91%20View%20%E7%9B%B8%E5%85%B3%E7%9A%84%E8%83%BD%E5%8A%9B%E3%80%82)

## 3.1 Prepare

在准备阶段，会执行以下的逻辑，简要概括即可：

1. 初始化PhoneWindow和WindowManager。
2. 创建DecorView，负责装饰元素（如标题栏、导航栏）的显示。
3. 创建ViewRootImpl，负责管理DecorView，是WindowManager和DecorView的连接器。
4. 连接PhoneWindow和WindowManagerService。这个Service负责窗口的添加删除等管理操作，是系统级的服务。PhoneWindow想要操作其中的窗口，靠的也是WMS。因此通过这个连接，才真正将DecorView加载到了PhoneWindow中。
5. 申请Surface。其实Canvas绘制的真正对象就是Surface。

之后，才是按照开头提到的三步走来绘制View：

![[Study Log/android_study/resources/Pasted image 20230710142551.png]]

**Measure和Layout的流程**：

![[Study Log/android_study/resources/Pasted image 20230716223747.png]]

![[Study Log/android_study/resources/Pasted image 20230716223856.png]]

可以看到，就是一个递归调用的过程，而View就是这棵递归树的根节点。

## 3.2 Measure

Measure翻译过来即是“测量”的意思，在此测量的是每个控件的宽和高。在代码层面，则是给每个View的mMeasuredWidth和mMeasuredHeight变量进行赋值。在测量时遵循：

-   如果是ViewGroup，则遍历测量子View的宽高，再根据子View宽高算出自身的宽高；
-   如果是子View，则直接测量出自身宽高；

现在从performMeasure()方法开始：

```java
//frameworks/base/core/java/android/view/ViewRootImpl.java
private void performMeasure(int childWidthMeasureSpec, int childHeightMeasureSpec) {
	if (mView == null) {
		return;
	}
	Trace.traceBegin(Trace.TRACE_TAG_VIEW, "measure");
	try {
		mView.measure(childWidthMeasureSpec, childHeightMeasureSpec);
	} finally {
		Trace.traceEnd(Trace.TRACE_TAG_VIEW);
	}
	mMeasuredWidth = mView.getMeasuredWidth();
	mMeasuredHeight = mView.getMeasuredHeight();
	mViewMeasureDeferred = false;
}
```

逻辑很清晰，可发现实际起作用的是mView.measure()方法，

```java
//frameworks/base/core/java/android/view/View.java
public final void measure(int widthMeasureSpec, int heightMeasureSpec) {
	if (cacheIndex < 0 || sIgnoreMeasureCache) {
		if (isTraversalTracingEnabled()) {
			Trace.beginSection(mTracingStrings.onMeasure);
		}
		// measure ourselves, this should set the measured dimension flag back
		onMeasure(widthMeasureSpec, heightMeasureSpec);
		if (isTraversalTracingEnabled()) {
			Trace.endSection();
		}
		mPrivateFlags3 &= ~PFLAG3_MEASURE_NEEDED_BEFORE_LAYOUT;
	} else {
		long value = mMeasureCache.valueAt(cacheIndex);
		// Casting a long to int drops the high 32 bits, no mask needed
		setMeasuredDimensionRaw((int) (value >> 32), (int) value);
		mPrivateFlags3 |= PFLAG3_MEASURE_NEEDED_BEFORE_LAYOUT;
	}
}
```

measure()方法使用final修饰，代表不可重写。在measure()方法中会进行一系列逻辑处理后，调用onMeasure()方法，真正的测量都在onMeasure()方法中实现。 ^8894fd

```java
//frameworks/base/core/java/android/view/View.java
protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
	setMeasuredDimension(
		getDefaultSize(
			getSuggestedMinimumWidth(), widthMeasureSpec
		),
		getDefaultSize(
			getSuggestedMinimumHeight(), heightMeasureSpec
		)
	);
}
```

可以看到onMeasure()方法使用protected修饰，代表我们可以重写该方法。因此如果需要实现自己的测量逻辑，只能通过子View重写onMeasure()方法，而不能重写measure()方法。onMeasure()最后调用setMeasuredDimension()设置View的宽高信息，完成View的测量操作。

以下是官方给出的`onMeasure()`方法的解释：

![[Study Log/android_study/resources/Pasted image 20230710144933.png]]

![[Study Log/android_study/resources/Pasted image 20230710144949.png]]

![[Study Log/android_study/resources/Pasted image 20230710145002.png]]

![[Study Log/android_study/resources/Pasted image 20230710145013.png]]

看看getDefaultSize()的源码：

```java
/**
 * Utility to return a default size. Uses the supplied size if the
 * MeasureSpec imposed no constraints. Will get larger if allowed
 * by the MeasureSpec.
 *
 * @param size Default size for this view
 * @param measureSpec Constraints imposed by the parent
 * @return The size this view should be.
 */
public static int getDefaultSize(int size, int measureSpec) {
    int result = size;
    //通过MeasureSpec解析获取mode与size
    int specMode = MeasureSpec.getMode(measureSpec);
    int specSize = MeasureSpec.getSize(measureSpec);

    switch (specMode) {
    case MeasureSpec.UNSPECIFIED:
        result = size;
        break;
    case MeasureSpec.AT_MOST: //8
    case MeasureSpec.EXACTLY: //8
        result = specSize;
        break;
    }
    return result;
}
```

这是系统设置默认的尺寸，在`//8`可以看到如果specMode是AT_MOST或者EXACTLY，则返回的就是specSize。至于 UNSPECIFIED 的情况，则会返回一个建议的最小值，这个值和子元素设置的最小值它的背景大小有关。

从一开始执行的performMeasure()到最后设置宽高的setMeasuredDimension()方法，流程都比较清晰。并且可以发现有两个贯穿整个流程的变量，widthMeasureSpec和heightMeasureSpec，理解这两个变量才是关键。

### 3.2.1 什么是MeasureSpec

MeasureSpec是一个32位的int型数据，由两部分组成，SpecMode（测量模式，高2位） + SpecSize（测量尺寸，低30位）。将这两者打包为一个int数据可以起到节省内存的作用。有打包当然也有解包的方法：

```java
//获取测量模式
public static int getMode(int measureSpec) {
    return (measureSpec & MODE_MASK);
}
//获取测量尺寸
public static int getSize(int measureSpec) {
    return (measureSpec & ~MODE_MASK);
}
```

> 名词解析：控件的`布局参数LayoutParams`是指控件设定为match_parent或者wrap_content或具体数值之中的一种。

### 3.2.2 测量模式

-   EXACTLY：确定大小，~~父View~~希望子View的大小是确定的。对应LayoutParams中的match_parent和具体数值这两种模式。检测到View所需要的精确大小，这时候View的最终大小就是SpecSize所指定的值；
-   AT_MOST ：最大大小，~~父View~~希望子View的大小最多是specSize指定的值。对应LayoutParams中的wrap_content。View的大小不能大于父容器的大小。
-   UNSPECIFIED ：不确定大小，~~父View~~完全依据子View的设计值来决定。系统不对View进行任何限制，要多大给多大，一般用于系统内部。

具体详见2.2.2小节的图。

```ad-warning
这里“父View”的说法是非常容易产生歧义的，见[[Article/story/2023-07-16#View测量布局流程的再感悟|我之后的感悟]]。
```

### 3.2.3 MeasureSpec如何确定

-   DecorView：通过屏幕大小和自身布局参数LayoutParams，只要将自身大小和屏幕大小相比，设置一个不超过屏幕大小的宽高和对应测量模式即可；
-   ViewGroup和View：需要通过父布局的MeasureSpec和自身的布局参数LayoutParams确定，具体如下：

![[Study Log/android_study/resources/Pasted image 20230710145318.png]]

### 3.2.4 ViewGroup的测量

如果是ViewGroup，那么会以树的形式从父节点向下遍历。上面说过ViewGroup需要测量其包含的子View的宽高后，根据子View宽高算出自身的宽高。所以在ViewGroup中定义了measureChildren(), measureChild(), measureChildWithMargins()方法来对子视图进行测量，measureChildren（）内部实质只是循环调用measureChild()。**调用的方式是递归的，所以叶子结点的View是最先被测量的**。

### 3.2.5 总结

-   measure过程主要就是从顶层父View向子View递归调用view.measure方法进行测量（measure()中又回调onMeasure()方法）的过程;
-   如果是ViewGroup则需执行要measure()并重写onMeasure()方法，在该方法中定义自己的测量方式，接着调用maesureChildren()方法遍历测量子View的宽高，最终根据子View宽高确定自己的宽高；
-   ViewGroup类提供了measureChild()，measureChildren()和measureChildWithMargins()方法，简化了父子View的尺寸计算；
-   如果是子View则调用measure() -> onMeasure()方法完成自身的测量即可；
-   View的measure()方法是final修饰的，不能重写，只能重写onMeasure()方法完成自己的测量，且重写时不建议把宽高设置为死值；
-   使用View的getMeasuredWidth()和getMeasuredHeight()方法来获取View测量的宽高，必须保证这两个方法在onMeasure流程之后被调用才能返回有效值。

![[Study Log/android_study/resources/Pasted image 20230710145603.png]]

> 一篇写的很好的文章：[一文理解 onMeasure -- 从 MeasureSpec 说起 - 掘金 (juejin.cn)](https://juejin.cn/post/6962438735426224136#comment)

面试问题：

* [[Article/interview/interview_questions#onMeasure方法一般执行几次，什么情况下会执行多次]]

## 3.3 Layout

刚才Measure的流程是performMeasure -> measure -> onMeasure。而Layout的流程是一模一样的，就像[[Study Log/android_study/resources/Pasted image 20230710142551.png|刚才图里]]画的那样。

```java
private void performLayout(WindowManager.LayoutParams lp, int desiredWindowWidth, int desiredWindowHeight) {
	mScrollMayChange = true;
	mInLayout = true;
	final View host = mView;
	if (host == null) {
		return;
	}
	if (DEBUG_ORIENTATION || DEBUG_LAYOUT) {
		Log.v(mTag, "Laying out " + host + " to (" +
				host.getMeasuredWidth() + ", " + host.getMeasuredHeight() + ")");
	}
	Trace.traceBegin(Trace.TRACE_TAG_VIEW, "layout");
	try {
		host.layout(0, 0, host.getMeasuredWidth(), host.getMeasuredHeight());
		mInLayout = false;
		int numViewsRequestingLayout = mLayoutRequesters.size();
		if (numViewsRequestingLayout > 0) {
			// requestLayout() was called during layout.
			// If no layout-request flags are set on the requesting views, there is no problem.
			// If some requests are still pending, then we need to clear those flags and do
			// a full request/measure/layout pass to handle this situation.
			ArrayList<View> validLayoutRequesters = getValidLayoutRequesters(mLayoutRequesters,
					false);
			if (validLayoutRequesters != null) {
				// Set this flag to indicate that any further requests are happening during
				// the second pass, which may result in posting those requests to the next
				// frame instead
				mHandlingLayoutInLayoutRequest = true;
				// Process fresh layout requests, then measure and layout
				int numValidRequests = validLayoutRequesters.size();
				for (int i = 0; i < numValidRequests; ++i) {
					final View view = validLayoutRequesters.get(i);
					Log.w("View", "requestLayout() improperly called by " + view +
							" during layout: running second layout pass");
					view.requestLayout();
				}
				measureHierarchy(host, lp, mView.getContext().getResources(),
						desiredWindowWidth, desiredWindowHeight, false /* forRootSizeOnly */);
				mInLayout = true;
				host.layout(0, 0, host.getMeasuredWidth(), host.getMeasuredHeight());
				mHandlingLayoutInLayoutRequest = false;
				// Check the valid requests again, this time without checking/clearing the
				// layout flags, since requests happening during the second pass get noop'd
				validLayoutRequesters = getValidLayoutRequesters(mLayoutRequesters, true);
				if (validLayoutRequesters != null) {
					final ArrayList<View> finalRequesters = validLayoutRequesters;
					// Post second-pass requests to the next frame
					getRunQueue().post(new Runnable() {
						@Override
						public void run() {
							int numValidRequests = finalRequesters.size();
							for (int i = 0; i < numValidRequests; ++i) {
								final View view = finalRequesters.get(i);
								Log.w("View", "requestLayout() improperly called by " + view +
										" during second layout pass: posting in next frame");
								view.requestLayout();
							}
						}
					});
				}
			}
		}
	} finally {
		Trace.traceEnd(Trace.TRACE_TAG_VIEW);
	}
	mInLayout = false;
}
```

里面核心的逻辑就是调用了host的layout方法，而host同样也是一个View。**View的布局主要是通过确定上下左右四个关键点来确定其位置**。值得一说的是，[[Article/story/2023-07-16#View测量布局流程的再感悟|测量时，先测量子View的宽高，再测量父View的宽高。但是在布局时顺序则相反，是父View先确定自身的布局，再确认子View的布局]]。 ^107fa1

```java
/**
 * Assign a size and position to a view and all of its
 * descendants
 *
 * <p>This is the second phase of the layout mechanism.
 * (The first is measuring). In this phase, each parent calls
 * layout on all of its children to position them.
 * This is typically done using the child measurements
 * that were stored in the measure pass().</p>
 *
 * <p>Derived classes should not override this method.
 * Derived classes with children should override
 * onLayout. In that method, they should
 * call layout on each of their children.</p>
 *
 * @param l Left position, relative to parent
 * @param t Top position, relative to parent
 * @param r Right position, relative to parent
 * @param b Bottom position, relative to parent
 */
public void layout(int l, int t, int r, int b) {  
    // 当前视图的四个顶点
    int oldL = mLeft;  
    int oldT = mTop;  
    int oldB = mBottom;  
    int oldR = mRight;  

    // setFrame（） / setOpticalFrame（）：确定View自身的位置
    // 即初始化四个顶点的值，然后判断当前View大小和位置是否发生了变化并返回  
 boolean changed = isLayoutModeOptical(mParent) ?
            setOpticalFrame(l, t, r, b) : setFrame(l, t, r, b); //10

    //如果视图的大小和位置发生变化，会调用onLayout（）
    if (changed || (mPrivateFlags & PFLAG_LAYOUT_REQUIRED) == PFLAG_LAYOUT_REQUIRED) {  
        // onLayout（）：确定该View所有的子View在父容器的位置     
        onLayout(changed, l, t, r, b);      //11
        ...
    }
    ...
}
```

-   setFrame()：确定View自身位置； ^42577a
-   setOpticalFrame()：也是确定View自身位置，其内部也是通过调用setFrame()来实现；
-   onLayout()：确认该View里面的子View在父容器的位置，用protected修饰，在View.java文件里的onLayout()只是个空函数，需要子类进行重写。

因此，我们可以通过安卓内置的一些View重写的onLayout()来了解这个过程。比如LinearLayout：

```java
@Override
protected void onLayout(boolean changed, int l, int t, int r, int b) {
	if (mOrientation == VERTICAL) {
		layoutVertical(l, t, r, b);
	} else {
		layoutHorizontal(l, t, r, b);
	}
}
```

在这里面，最重要的就是layoutVertical和layoutHorizontal中会不断去确定子布局的位置。也就是**先确定父布局，再确定子布局**。这与Measure的递归过程是相反的。

![[Study Log/android_study/resources/Pasted image 20230710151346.png]]

## 3.4 Draw

显然，要从performDraw()开始了：

```java
private boolean performDraw() {
	try {
		boolean canUseAsync = draw(fullRedrawNeeded, usingAsyncReport && mSyncBuffer);
		if (usingAsyncReport && !canUseAsync) {
			mAttachInfo.mThreadedRenderer.setFrameCallback(null);
			usingAsyncReport = false;
		}
	} finally {
		mIsDrawing = false;
		Trace.traceEnd(Trace.TRACE_TAG_VIEW);
	}
}
```

这里的draw()方法还是定义在ViewRootImpl中的。如果追到最深层，那么还是View中的draw方法：

```java
/**
 * Manually render this view (and all of its children) to the given Canvas.
 * The view must have already done a full layout before this function is
 * called.  When implementing a view, implement
 * {@link #onDraw(android.graphics.Canvas)} instead of overriding this method.
 * If you do need to override this method, call the superclass version.
 *
 * @param canvas The Canvas to which the View is rendered.
 */
@CallSuper
public void draw(Canvas canvas) {
	/*
	 * Draw traversal performs several drawing steps which must be executed
	 * in the appropriate order:
	 *
	 *      1. Draw the background
	 *      2. If necessary, save the canvas' layers to prepare for fading
	 *      3. Draw view's content
	 *      4. Draw children
	 *      5. If necessary, draw the fading edges and restore layers
	 *      6. Draw decorations (scrollbars for instance)
	 *      7. If necessary, draw the default focus highlight
	 */

	// Step 1, draw the background, if needed
	int saveCount;
	drawBackground(canvas);
	// skip step 2 & 5 if possible (common case)
	final int viewFlags = mViewFlags;
	boolean horizontalEdges = (viewFlags & FADING_EDGE_HORIZONTAL) != 0;
	boolean verticalEdges = (viewFlags & FADING_EDGE_VERTICAL) != 0;
	if (!verticalEdges && !horizontalEdges) {
		// Step 3, draw the content
		onDraw(canvas);
		// Step 4, draw the children
		dispatchDraw(canvas);
		drawAutofilledHighlight(canvas);
		// Overlay is part of the content and draws beneath Foreground
		if (mOverlay != null && !mOverlay.isEmpty()) {
			mOverlay.getOverlayView().dispatchDraw(canvas);
		}
		// Step 6, draw decorations (foreground, scrollbars)
		onDrawForeground(canvas);
		// Step 7, draw the default focus highlight
		drawDefaultFocusHighlight(canvas);
		if (isShowingLayoutBounds()) {
			debugDrawFocus(canvas);
		}
		// we're done...
		return;
	}
	/*
	 * Here we do the full fledged routine...
	 * (this is an uncommon case where speed matters less,
	 * this is why we repeat some of the tests that have been
	 * done above)
	 */
	boolean drawTop = false;
	boolean drawBottom = false;
	boolean drawLeft = false;
	boolean drawRight = false;
	float topFadeStrength = 0.0f;
	float bottomFadeStrength = 0.0f;
	float leftFadeStrength = 0.0f;
	float rightFadeStrength = 0.0f;
	// Step 2, save the canvas' layers
	int paddingLeft = mPaddingLeft;
	final boolean offsetRequired = isPaddingOffsetRequired();
	if (offsetRequired) {
		paddingLeft += getLeftPaddingOffset();
	}
	int left = mScrollX + paddingLeft;
	int right = left + mRight - mLeft - mPaddingRight - paddingLeft;
	int top = mScrollY + getFadeTop(offsetRequired);
	int bottom = top + getFadeHeight(offsetRequired);
	if (offsetRequired) {
		right += getRightPaddingOffset();
		bottom += getBottomPaddingOffset();
	}
	final ScrollabilityCache scrollabilityCache = mScrollCache;
	final float fadeHeight = scrollabilityCache.fadingEdgeLength;
	int length = (int) fadeHeight;
	// clip the fade length if top and bottom fades overlap
	// overlapping fades produce odd-looking artifacts
	if (verticalEdges && (top + length > bottom - length)) {
		length = (bottom - top) / 2;
	}
	// also clip horizontal fades if necessary
	if (horizontalEdges && (left + length > right - length)) {
		length = (right - left) / 2;
	}
	if (verticalEdges) {
		topFadeStrength = Math.max(0.0f, Math.min(1.0f, getTopFadingEdgeStrength()));
		drawTop = topFadeStrength * fadeHeight > 1.0f;
		bottomFadeStrength = Math.max(0.0f, Math.min(1.0f, getBottomFadingEdgeStrength()));
		drawBottom = bottomFadeStrength * fadeHeight > 1.0f;
	}
	if (horizontalEdges) {
		leftFadeStrength = Math.max(0.0f, Math.min(1.0f, getLeftFadingEdgeStrength()));
		drawLeft = leftFadeStrength * fadeHeight > 1.0f;
		rightFadeStrength = Math.max(0.0f, Math.min(1.0f, getRightFadingEdgeStrength()));
		drawRight = rightFadeStrength * fadeHeight > 1.0f;
	}
	saveCount = canvas.getSaveCount();
	int topSaveCount = -1;
	int bottomSaveCount = -1;
	int leftSaveCount = -1;
	int rightSaveCount = -1;
	int solidColor = getSolidColor();
	if (solidColor == 0) {
		if (drawTop) {
			topSaveCount = canvas.saveUnclippedLayer(left, top, right, top + length);
		}
		if (drawBottom) {
			bottomSaveCount = canvas.saveUnclippedLayer(left, bottom - length, right, bottom);
		}
		if (drawLeft) {
			leftSaveCount = canvas.saveUnclippedLayer(left, top, left + length, bottom);
		}
		if (drawRight) {
			rightSaveCount = canvas.saveUnclippedLayer(right - length, top, right, bottom);
		}
	} else {
		scrollabilityCache.setFadeColor(solidColor);
	}
	// Step 3, draw the content
	onDraw(canvas);
	// Step 4, draw the children
	dispatchDraw(canvas);
	// Step 5, draw the fade effect and restore layers
	final Paint p = scrollabilityCache.paint;
	final Matrix matrix = scrollabilityCache.matrix;
	final Shader fade = scrollabilityCache.shader;
	// must be restored in the reverse order that they were saved
	if (drawRight) {
		matrix.setScale(1, fadeHeight * rightFadeStrength);
		matrix.postRotate(90);
		matrix.postTranslate(right, top);
		fade.setLocalMatrix(matrix);
		p.setShader(fade);
		if (solidColor == 0) {
			canvas.restoreUnclippedLayer(rightSaveCount, p);
		} else {
			canvas.drawRect(right - length, top, right, bottom, p);
		}
	}
	if (drawLeft) {
		matrix.setScale(1, fadeHeight * leftFadeStrength);
		matrix.postRotate(-90);
		matrix.postTranslate(left, top);
		fade.setLocalMatrix(matrix);
		p.setShader(fade);
		if (solidColor == 0) {
			canvas.restoreUnclippedLayer(leftSaveCount, p);
		} else {
			canvas.drawRect(left, top, left + length, bottom, p);
		}
	}
	if (drawBottom) {
		matrix.setScale(1, fadeHeight * bottomFadeStrength);
		matrix.postRotate(180);
		matrix.postTranslate(left, bottom);
		fade.setLocalMatrix(matrix);
		p.setShader(fade);
		if (solidColor == 0) {
			canvas.restoreUnclippedLayer(bottomSaveCount, p);
		} else {
			canvas.drawRect(left, bottom - length, right, bottom, p);
		}
	}
	if (drawTop) {
		matrix.setScale(1, fadeHeight * topFadeStrength);
		matrix.postTranslate(left, top);
		fade.setLocalMatrix(matrix);
		p.setShader(fade);
		if (solidColor == 0) {
			canvas.restoreUnclippedLayer(topSaveCount, p);
		} else {
			canvas.drawRect(left, top, right, top + length, p);
		}
	}
	canvas.restoreToCount(saveCount);
	drawAutofilledHighlight(canvas);
	// Overlay is part of the content and draws beneath Foreground
	if (mOverlay != null && !mOverlay.isEmpty()) {
		mOverlay.getOverlayView().dispatchDraw(canvas);
	}
	// Step 6, draw decorations (foreground, scrollbars)
	onDrawForeground(canvas);
	// Step 7, draw the default focus highlight
	drawDefaultFocusHighlight(canvas);
	if (isShowingLayoutBounds()) {
		debugDrawFocus(canvas);
	}
}
```

以上的源码里的官方注释，draw()方法有以下步骤：

1.  **绘制View的背景**； ^2bf32e
2.  如果有必要的话，保存画布的图层以准备fading；
3.  **绘制View的内容，即执行关键函数`onDraw()`**。这是一个空方法;
4.  **绘制子View**；
5.  如果有必要的话，绘制View的fading边缘并恢复图层；
6.  **绘制View的装饰（比如滚动条等等）**；
7.  绘制默认焦点高亮

无论是View还是ViewGroup，绘制的流程都是如此，还有两点需要了解：

-   在ViewGroup中，实现了dispatchDraw()方法，而子View是不需要实现该方法的；
-   自定义View时，一般需要重写onDraw()方法，以绘制自己想要的样式。

![[Study Log/android_study/resources/Pasted image 20230710152918.png]]

# 4 Questions

> [!question]- invalidate会触发其它View的重绘吗？
> 
> 会，View的绘制是沿着ViewTree来一层一层分发的，这和事件分发机制是同一个思路。而invalidate的流程，就是把这个分发的流程反着来，从根节点开始，将要重绘的区域传递给父亲结点，父亲会算出**自己和子节点的交集区域dirty**，并继续向上传递。传递到根节点ViewRootImpl时，会触发它的画儿子方法，又把绘制事件一层层传下来。因此，在这条路径上的View，都会进行重绘。重绘的区域就是和根节点的交集。

