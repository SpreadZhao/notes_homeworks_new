# 4 自定义View流程

## 4.1 onMeasure

在onMeasure阶段，需要给出View的精确的大小测量结果。并且**必须调用setMeasuredDimension**来设置View的宽高信息。下面是一个重写onMeasure的例子：

```java
protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) { //1
    super.onMeasure(widthMeasureSpec, heightMeasureSpec);
    int defaultValue = 700;
    
    int widthSpecMode = MeasureSpec.getMode(widthMeasureSpec);
    int heightSpecMode = MeasureSpec.getMode(heightMeasureSpec);
    
    int widthSpecSize = MeasureSpec.getSize(widthMeasureSpec);
    int heightSpecSize = MeasureSpec.getSize(heightMeasureSpec);
   
   //AT_MOST对应的是wrap_content的宽高
    if (widthSpecMode == MeasureSpec.AT_MOST && heightSpecMode == MeasureSpec.AT_MOST) {
        setMeasuredDimension(defaultValue,defaultValue);
	} else if (widthSpecMode == MeasureSpec.AT_MOST) {
        setMeasuredDimension(defaultValue,heightSpecSize);
    } else if (heightSpecMode == MeasureSpec.AT_MOST) {
        setMeasuredDimension(widthSpecSize,defaultValue);
    }
}
```

其中，SpecMode（由MeasureSpec.getMode()方法得到）的值见[[Study Log/android_study/view_create_flow#3.2.2 测量模式|自定义View的3.2.2]]。现在假设，如果widthSpecMode经过解包，得到的是AT_MOST，那么意味着父布局希望当前布局的宽度是wrap_content（**在xml中声明这个布局时，宽度写成wrap_content**），也就是需要有一个最大值。而这个最大值的大小就是MeasureSpec.getSize(widthMeasureSpec)返回的结果。然而，我们不能将这个值直接设置给它的宽度。这是因为，**这个值实际上是它父布局的宽和高**。至于为什么是这样，之后会用例子来说明。

总之，对于当前这个自定义View，它的宽和高任意一个如果是wrap_content，那么其实际大小将会是默认值700。

![[Study Log/android_study/resources/Pasted image 20230711144327.png|200]] ![[Study Log/android_study/resources/Pasted image 20230711144336.png|200]]

> 左图：默认值为700；右图：默认值为300

## 4.2 onLayout

确定布局可以用onLayout()方法，在自定义View中，一般不需要重写该方法。但在自定义ViewGroup中可能需要重写，一般做法是**循环取出子View，并计算每个子View位置等坐标值，然后使用child.layout()方法设置子View的位置**，如下所示：

```kotlin
override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {  
    val childCount: Int = getChildCount()  
    var left = 0  
    var child: View  
    //循环遍历各个子View  
    for (i in 0 until childCount) {  
        child = getChildAt(i)  
        if (child.visibility != GONE) {  
            val width = child.measuredWidth  
            childWidth = width  
            //设置子View位置  
            child.layout(left, 0, left + width, child.measuredHeight)  
            left += width  
        }  
    }  
}
```

## 4.3 onDraw

这就是自定义View的核心函数了。我们在这里使用Canvas画出我们需要的形状。

![[Study Log/android_study/resources/Pasted image 20230711114236.png]]

> 其中的drawPath是一个比较重要的方法。而它画出的Path可以参考如下：[Path - Android中文版 - API参考文档 (apiref.com)](https://www.apiref.com/android-zh/android/graphics/Path.html)

而Canvas画图，需要一个很重要的工具，也就是Paint。而Paint常见的API如下：

```java
void reset();
void set(Paint src);
void setCompatibilityScaling( float factor);
void setBidiFlags( int flags);
void setFlags( int flags);
void setHinting( int mode);
//是否抗锯齿
void setAntiAlias( boolean aa);
//设定是否使用图像抖动处理，会使绘制出来的图片颜色更加平滑和饱满，图像更加清晰  
void setDither( boolean dither);
//设置线性文本
void setLinearText( boolean linearText);
//设置该项为true，将有助于文本在LCD屏幕上的显示效果  
void setSubpixelText( boolean subpixelText);
//设置下划线
void setUnderlineText( boolean underlineText);
//设置带有删除线的效果 
void setStrikeThruText( boolean strikeThruText);
//设置伪粗体文本，设置在小字体上效果会非常差  
void setFakeBoldText( boolean fakeBoldText);
//如果该项设置为true，则图像在动画进行中会滤掉对Bitmap图像的优化操作
//加快显示速度，本设置项依赖于dither和xfermode的设置  
void setFilterBitmap( boolean filter);
//设置画笔风格，空心或者实心 FILL，FILL_OR_STROKE，或STROKE
//Paint.Style.STROKE 表示当前只绘制图形的轮廓，而Paint.Style.FILL表示填充图形。  
void setStyle(Style style);
  //设置颜色值
void setColor( int color);
//设置透明图0~255，要在setColor后面设置才生效
void setAlpha( int a);   
//设置RGB及透明度
void setARGB( int a,  int r,  int g,  int b);  
//当画笔样式为STROKE或FILL_OR_STROKE时，设置笔刷的粗细度  
void setStrokeWidth( float width);
void setStrokeMiter( float miter);
//当画笔样式为STROKE或FILL_OR_STROKE时，设置笔刷末端的图形样式
//如圆形样式Cap.ROUND,或方形样式Cap.SQUARE  
void setStrokeCap(Cap cap);
//设置绘制时各图形的结合方式，如平滑效果等  
void setStrokeJoin(Join join);
//设置图像效果，使用Shader可以绘制出各种渐变效果  
Shader setShader(Shader shader);
//设置颜色过滤器，可以在绘制颜色时实现不用颜色的变换效果 
ColorFilter setColorFilter(ColorFilter filter);
//设置图形重叠时的处理方式，如合并，取交集或并集，经常用来制作橡皮的擦除效果 
Xfermode setXfermode(Xfermode xfermode);
//设置绘制路径的效果，如点画线等 
PathEffect setPathEffect(PathEffect effect);
//设置MaskFilter，可以用不同的MaskFilter实现滤镜的效果，如滤化，立体等  
MaskFilter setMaskFilter(MaskFilter maskfilter);
//设置Typeface对象，即字体风格，包括粗体，斜体以及衬线体，非衬线体等  
Typeface setTypeface(Typeface typeface);
//设置光栅化
Rasterizer setRasterizer(Rasterizer rasterizer);
//在图形下面设置阴影层，产生阴影效果，radius为阴影的角度，dx和dy为阴影在x轴和y轴上的距离，color为阴影的颜色
//注意：在Android4.0以上默认开启硬件加速，有些图形的阴影无法显示。关闭View的硬件加速 view.setLayerType(View.LAYER_TYPE_SOFTWARE, null);
void setShadowLayer( float radius,  float dx,  float dy,  int color);
//设置文本对齐
void setTextAlign(Align align);
//设置字体大小
void setTextSize( float textSize);
//设置文本缩放倍数，1.0f为原始
void setTextScaleX( float scaleX);
//设置斜体文字，skewX为倾斜弧度  
void setTextSkewX( float skewX);
```

> 更多参考：[Paint - Android中文版 - API参考文档 (apiref.com)](https://www.apiref.com/android-zh/android/graphics/Paint.html)，[(45条消息) Android Paint API总结和使用方法_BigBee3.的博客-CSDN博客](https://blog.csdn.net/shell812/article/details/49781397?ref=myread)

## 4.4 Example

下面通过一些例子来熟悉以下以上的流程。首先，是一个跑马灯文字。我们先来展示一下它的onDraw方法：

```kotlin
override fun onDraw(canvas: Canvas) {  
    val textWidth = mPaint.measureText(realText)  
    if (measuredWidth < textWidth) {  // 宽度不够，展示跑马灯
        canvas.drawText(realText, x.toFloat(), 50f, mPaint)  
        x -= 2  
        if (x < -textWidth) {  
            x = measuredWidth  
        }  
        postInvalidateDelayed(10)  
    } else {  // 宽度够，直接展示
        canvas.drawText(realText, measuredWidth - textWidth, 50f, mPaint)  
    }  
}
```

这里首先有一个判断，也就是**当前布局的宽度是否能够支持我不展示跑马灯**？这里的布局宽度，其实就是在xml中定义的，又或者是在构造方法中通过LayoutParam参数传入进来的。realText变量是我要显示的实际的文字。而在构造方法中，它被赋值为None，经过测量得到的值是115。因此，如果布局的大小不足115，就会以跑马灯的形式展示。

而这个measuredWidth，其实就是getMeasuredWidth()方法。在onMeasure中测量得到的结果。

下一个问题就是，canvas画图的坐标。注意直接展示的逻辑：

```kotlin
canvas.drawText(realText, measuredWidth - textWidth, 50f, mPaint)
```

再对比以下默认情况的位置：

![[Study Log/android_study/resources/Pasted image 20230711123126.png]]

可以看到，canvas画图的原点也是从**左上角**开始的。因此，如果以跑马灯展示的话，当所有的文字都扫过屏幕时，最后一个字符就在屏幕的边缘，那么第一个字符自然也就在屏幕的`-textWidth`位置，而此时的画笔正好就在第一个字符的位置。因此，我们重新将画笔挪到屏幕的最右侧，也就是`measuredWidth`位置继续作画就好了：

```kotlin
if (x < -textWidth) {  
	x = measuredWidth  
} 
```

然而，我们目前发现了一个比较严重的问题，那就是，**这个布局的高为啥那么高**？很显然，这是由于我们没有实现onMeasure导致的。因此，我们需要在onMeasure中获取当前文字的高度并设置进去。这样我们才能够适应xml中的wrap_content：

```kotlin
override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {  

	val widthMode = MeasureSpec.getMode(widthMeasureSpec)  
	val heightMode = MeasureSpec.getMode(heightMeasureSpec)  
	
	val widthSize = MeasureSpec.getSize(widthMeasureSpec)  
	val heightSize = MeasureSpec.getSize(heightMeasureSpec)  

	if (heightMode == MeasureSpec.AT_MOST) {  
		// 实现wrap_content  
		setMeasuredDimension(
			widthSize, 
			(paddingTop + currTextHeight + paddingBottom).toInt()
		)  
	} else {  
		super.onMeasure(widthMeasureSpec, heightMeasureSpec)  
	}  
}
```

当高度为AT_MOST，也就是wrap_content的时候，我们需要重新考虑设置高度。然而，如果给一个类似50这样的默认值，**是非常不妥当的行为**。因此，我们需要在这里手动获取当前文字的高度。来看currTextHeight的实现：

```kotlin
private val currTextHeight: Float  
    get() {  
        val metrics = mPaint.fontMetrics  
        return abs(metrics.ascent - metrics.descent)  
    }
```

这里就涉及到fontMetrics这个东西了。具体的解释可以参考下面的文章：

> [(45条消息) 中文字体的FontMetrics解析_话与山鬼听的博客-CSDN博客](https://blog.csdn.net/loveyou388i/article/details/115934795)

而ascent - descent就能得到当前文字所占据的最大的高度（当然是文字只有一行的情况下）。而除此之外，还需要再加上和父布局之间留下的padding才能得到比较适合的高度。

显然，如果这里的逻辑变了，那么画图的逻辑也跟着要变：

```kotlin
override fun onDraw(canvas: Canvas) {  
    val textWidth = mPaint.measureText(realText)  
    if (measuredWidth < textWidth) {  
        canvas.drawText(realText, x.toFloat(), paddingTop + baselineOffset, mPaint)  
        x -= 2  
        if (x < -textWidth) {  
            x = measuredWidth  
        }  
        postInvalidateDelayed(10)  
    } else {  
        canvas.drawText(
	        realText, 
	        measuredWidth - textWidth,
	        paddingTop + baselineOffset, 
	        mPaint
	    )  
    }  
}
```

这里需要重点强调的是baselineOffset这个东西：

```kotlin
// 基线位置的偏移量，用来计算Canvas画图时的纵坐标  
private val baselineOffset: Float  
    get() {  
        val metrics = mPaint.fontMetrics  
        return (currTextHeight - metrics.bottom + metrics.top) / 2 - metrics.top  
    }
```

Canvas在绘制文字时，纵坐标是从baseline开始的，而不是文字的顶部。因此如果想让它从文字顶部开始绘画，需要一些额外的计算。如果在上面的onDraw中，我们直接把currTextHeight填入纵坐标，结果是这样的：

![[Study Log/android_study/resources/Pasted image 20230711143954.png]]

可以看到最下面有一小块超出了布局范围。因此才需要这个额外的计算：

![[Study Log/android_study/resources/Pasted image 20230711144033.png]]

## 4.5 Summary & Extension

[java - When is View.onMeasure() called? - Stack Overflow](https://stackoverflow.com/questions/6631105/when-is-view-onmeasure-called)

[View  |  Android Developers](https://developer.android.com/reference/android/view/View.html)

![[Study Log/android_study/resources/Pasted image 20230711144603.png]]

![[Study Log/android_study/resources/Pasted image 20230711144648.png]]

![[Study Log/android_study/resources/Pasted image 20230711144701.png]]