为了更好地说明滑动时RecyclerView发生的变化，我对itemView做出了一些修改：

```kotlin
override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): MyViewHolder {  
  val view = LayoutInflater.from(parent.context).inflate(R.layout.big_text, parent, false).apply {  
    layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, QUARTER_SCREEN_HEIGHT + 10)  
  }  
  return MyViewHolder(view)  
}
```

将View的高度修改为四分之一屏幕高度+10。屏幕原本的高度是2892，四分之一就是723。原本情况下，屏幕正好能容纳四个item，只要一滑动，第五个item就会走创建的逻辑。然而，为了更好地演示在滑动，创建，bind过程中穿插的计算流程，将高度多加上10，这样每个item的高度变为733，四个View的总高度变为2932，比原本的屏幕高出了40：

![[Study Log/android_study/recyclerview/2_scroll/resources/Drawing 2023-12-22 16.02.58.excalidraw.png]]

然后，将Adapter中的数据变成5个。这样，当首次加载的时候，只会布局4个Item。接下来我们来看一看第五个布局是如何加载的。显然，RecyclerView需要重写onTouchEvent()来处理滑动事件，毕竟大家族里只有它是View的子类：

```java
case MotionEvent.ACTION_MOVE: {  

    if (mScrollState != SCROLL_STATE_DRAGGING) {  
        boolean startScroll = false;  
        if (canScrollHorizontally) {  
            if (dx > 0) {  
                dx = Math.max(0, dx - mTouchSlop);  
            } else {  
                dx = Math.min(0, dx + mTouchSlop);  
            }  
            if (dx != 0) {  
                startScroll = true;  
            }  
        }  
        if (canScrollVertically) {  
            if (dy > 0) {  
                dy = Math.max(0, dy - mTouchSlop);  
            } else {  
                dy = Math.min(0, dy + mTouchSlop);  
            }  
            if (dy != 0) {  
                startScroll = true;  
            }  
        }  
        if (startScroll) {  
            setScrollState(SCROLL_STATE_DRAGGING);   // 关键点1
        }  
    }  
  
    if (mScrollState == SCROLL_STATE_DRAGGING) {  
        mReusableIntPair[0] = 0;  
        mReusableIntPair[1] = 0;  
        if (dispatchNestedPreScroll(  
                canScrollHorizontally ? dx : 0,  
                canScrollVertically ? dy : 0,  
                mReusableIntPair, mScrollOffset, TYPE_TOUCH  
        )) {  
            dx -= mReusableIntPair[0];  
            dy -= mReusableIntPair[1];  
            // Updated the nested offsets  
            mNestedOffsets[0] += mScrollOffset[0];  
            mNestedOffsets[1] += mScrollOffset[1];  
            // Scroll has initiated, prevent parents from intercepting  
            getParent().requestDisallowInterceptTouchEvent(true);  
        }  
  
        mLastTouchX = x - mScrollOffset[0];  
        mLastTouchY = y - mScrollOffset[1];  
  
        if (scrollByInternal(  
                canScrollHorizontally ? dx : 0,  
                canScrollVertically ? dy : 0,  // 关键点2
                e)) {  
            getParent().requestDisallowInterceptTouchEvent(true);  
        }  
        if (mGapWorker != null && (dx != 0 || dy != 0)) {  
            mGapWorker.postFromTraversal(this, dx, dy);  
        }  
    }  
}
```

以上是onTouchEvent()中处理MOVE事件的代码片段。虽然很长，但是关键点只有两个：

1. 进入滑动状态；
2. 触发滑动。

进入滑动状态指的就是将当前的状态设置为DRAGGING。这个东西在之前我们其实见到过：[[Study Log/android_study/recyclerview/1_start/1_2_1_step1#^0b200b|1_2_1_step1]]

其实也就是告诉RecyclerView“手已经放在屏幕上滑动啦！”。当设置完滑动状态之后，就会执行真正的滑动流程，也就是方法scrollByInternal()。它会在下图中的位置继续向下调用。这个过程就是注释中所说的"consume"：

![[Study Log/android_study/recyclerview/2_scroll/resources/Pasted image 20231222164449.png]]

注意，因为默认情况下RecyclerView只能垂直滑动，所以x是0而y是184。这里再提一嘴mReusableIntPair，它并没有什么特殊用途。只是为了返回两个int。在本例中，scrollStep执行完毕后，会填充这个数组，然后接着拿去用就行。在本例中，返回的两个int就是在水平方向和垂直方向已经消费的滑动像素数量。

我们先来看看scrollStep()的注释：

```java
/**  
 * Scrolls the RV by 'dx' and 'dy' via calls to 
 * {@link LayoutManager#scrollHorizontallyBy(int, Recycler, State)} and  
 * {@link LayoutManager#scrollVerticallyBy(int, Recycler, State)}.  
 * 
 * Also sets how much of the scroll was actually consumed in 'consumed' parameter (indexes 0 and 
 * 1 for the x axis and y axis, respectively). 
 * 
 * This method should only be called in the context of an existing scroll operation such that 
 * any other necessary operations (such as a call to {@link #consumePendingUpdateOperations()})  
 * is already handled. */
```

第一段是在说这个方法在干什么，也就是根据当前的dx和dy来判断是横着划还是竖着划（dx和dy必定有一个是0），然后调用LayoutManager的scrollXXXBy()来执行滑动操作。

第二段就是我刚刚提到的返回两个int，表示两个方向上都消费了多少像素。

第三段提到了一点，这个方法只能在存在的滑动事件里调用，因为在这之前必须调用类似consumePendingUpdateOperations()的方法来处理更新。会有这个东西的原因其实还是和RecyclerView的刷新机制有关。[[Study Log/android_study/recyclerview/1_start/1_2_2_step2#^099fd5|1_2_2_step2]]之前我们提到过，RecyclerView只会在一次layout中处理所有更新的请求。那在这个过程中能调用滑动吗？肯定不能啊！因为此时View的信息和Adapter的信息不一致，所以必须先更新View，让它和Adapter的信息一致了，才能继续执行滑动的流程。

在上面的截图里也能看到，scrollByInternal()就调用了consumePendingUpdateOperations()。而这个方法里面你点进去就能看到，如果有pending的更新，它是会进行dispatchLayout()的。

说完了这些条件，现在进入方法。刚才说了，dy是184，所以会进入垂直滑动的方法：

![[Study Log/android_study/recyclerview/2_scroll/resources/Pasted image 20231222170158.png]]

首先能看到，它将mRecycle设置为了true。这个属性在之前的流程中并没有提到，主要是因为对流程分析不影响。但是这里提他，是因为它第一次派上了大用场。

mRecycle本身是控制是否回收子View的。如果为true，表明LayoutManager此时**同意**回收子View。在本例中，是滑动的状态，随着不断滑动，肯定有View会逐渐退出屏幕外，对于那些已经退出屏幕外的View，我们当然要回收。所以LayoutManager在滑动的时候是允许回收子View的。

> [!stickies]
> #comment 为什么要这么设计？可以思考一下。

顺着这个思路，我们回顾一下以前mRecycle的变化：在[[Study Log/android_study/recyclerview/1_start/1_2_2_step2|1_2_2_step2]]中，LayoutManager的onLayoutChildren()方法里面就将它设置为了fasle。言外之意， #comment <u>当RecyclerView在布局子View的时候，是不允许回收子View的</u>！

接下来，到了一个比较重要的方法：updateLayoutState()。虽然这个方法只是更新一些信息，但是我们非常有必要知道这些信息是怎么算出来的。

经过我的debug，我认为这两个信息是比较关键的信息：

```txt
LinearLayoutManager
|
-- mLayoutState: LayoutState
	|
	-- mAvailable (Number of pixels that we should fill, in the layout direction.)
	|
	-- mScrollingOffset (Used when LayoutState is constructed in a scrolling state. It should be set the amount of scrolling we can make without creating a new view. Settings this is required for efficient view recycling.)
```

mAvailable表示我们应该在这个方向上接下去的**布局的长度**。举个例子，在初次加载的时候，这个值其实就是屏幕的高度2892。在原来的情况中，每次布局会减少1/4高度，也就是723。那么，在我们往下滑动的过程中，需要布局多少呢？

你可能会觉得，我们手滑动了184，所以这个值就是184吧！这样思考的思路是正确的，但是忽略了一些东西。这就是我一开始做出改动的原因：

![[Study Log/android_study/recyclerview/2_scroll/resources/Drawing 2023-12-22 16.02.58.excalidraw.png]]

在这种情况下，我往下滑动了184，需要布局的长度真的就是184吗？显然不是的！因为，多出来的这40，在初次布局的时候就已经布局过了！我们需要布局的长度应该是184 - 40：

![[Study Log/android_study/recyclerview/2_scroll/resources/Drawing 2023-12-22 17.24.00.excalidraw.png]]

也就是，图中阴影部分的高度才是我们真正要布局的高度！现在知道这个逻辑了。问题在于：*这个40我怎么算出来*？而这就是mScrollingOffset的作用。从注释也能看出，这个数值应该被赋值为“**在不需要布局的情况下，我们能滑动多少**”。那么在本例中，在不需要布局的情况下，我们能滑动的距离显然就是40。所以，接下来我们看看这个mScrollingOffset是怎么算出来的。

```java
// calculate how much we can scroll without adding new children (independent of layout)  
scrollingOffset = mOrientationHelper.getDecoratedEnd(child)  
        - mOrientationHelper.getEndAfterPadding();
```

当然，根据滑动方向的不同，这个值肯定也不一样。上面的代码是在算往下滑动的情况。我们取出最后一个子View的**end**，然后减去当前layout的"End Boundary"。在本例中，RecyclerView布满屏幕，所以End Boundary就是屏幕的高度2892。而最后一个子View的end是多少？通过上面的图很容易算出来，就是733 \* 4 = 2932（当然肯定不是真的这么算出来的）。这样他俩一减，就得到了我们想要的40：

![[Study Log/android_study/recyclerview/2_scroll/resources/Pasted image 20231222173701.png]]

算出来之后，它做了下面的事情：

```java
mLayoutState.mAvailable = requiredSpace;  
if (canUseExistingSpace) {  
    mLayoutState.mAvailable -= scrollingOffset;  
}  
mLayoutState.mScrollingOffset = scrollingOffset;
```

其中requiredSpace就是滑动时传入的dy，也就是184。而canUseExistingSpace传入的是true。所以最后我们需要布局的大小就算出来了：184 - 40 = 144。

知道了要布局多少，下一步是干嘛？布局！布局的流程是什么？就是fill()！在[[Study Log/android_study/recyclerview/1_start/1_2_2_step2#1.2.2.1 Fill|1_2_2_step2]]中我们提过fill()，但是只是大致说了一下它在干嘛，并没有提到一些细节。这里再给他丰富一下。回到首次加载的代码，也就是onLayoutChildren()中，我们能看到在fill()调用之前都会有这么一个方法：

```java
updateLayoutStateToFillStart(mAnchorInfo);
```

除了这个还有fillEnd()，点进去就可以看到，它们其实也更新了mAvailable和mScrollingOffset。只不过流程相对简单，没有这些计算过程。

回到我们的例子中，下一步就是调用fill()方法，传入我们刚刚修改的mLayoutState：

![[Study Log/android_study/recyclerview/2_scroll/resources/Pasted image 20231222175708.png]]

刚进入fill()，就走入了一个之前没走到的逻辑。在初次加载的时候，mScrollingOffset的值就是SCROLLING_OFFSET_NaN，所以这里不会走。而本次走进去做了什么呢？看名字就是回收View。但是可以告诉各位，本次执行的实际情况是什么也没回收。其实我们猜也能猜出来，仅仅滑动了184，所有的View肯定都还在显示，所以这里不回收理所应当。等之后什么时候回收了我们再来介绍这个逻辑。

接下来就是之前详细介绍的while循环里面的layoutChunk()。通过之前的介绍，我们更加能够熟悉这些指标的来源：

![[Study Log/android_study/recyclerview/2_scroll/resources/Pasted image 20231222180029.png]]

但是要注意，这里我们判断的条件是remainingSpace而不是mAvailable。它俩的区别就是前者比后者又多加了一个mExtraFillSpace。这个变量是什么呢？这就和