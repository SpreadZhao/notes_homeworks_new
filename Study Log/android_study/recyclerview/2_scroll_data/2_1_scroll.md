---
title: 2.1 Scroll
chapter: "2"
order: "6"
hierarchy: "2"
---

## 2.1 Scroll

为了更好地说明滑动时RecyclerView发生的变化，我对itemView做出了一些修改：

```kotlin
override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): MyViewHolder {  
  val view = LayoutInflater.from(parent.context).inflate(R.layout.big_text, parent, false).apply {  
    layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, QUARTER_SCREEN_HEIGHT + 10)  
  }  
  return MyViewHolder(view)  
}
```

将View的高度修改为四分之一屏幕高度+10。屏幕原本的高度是2892，四分之一就是723。原本情况下，屏幕正好能容纳四个item，只要一滑动，第五个item就会走创建的逻辑。然而，为了更好地演示在滑动，创建，bind过程中穿插的**计算流程**，将高度多加上10，这样每个item的高度变为733，四个View的总高度变为2932，比原本的屏幕高出了40：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Drawing 2023-12-22 16.02.58.excalidraw.png]]

### 2.1.1 Enter Scroll

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

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Pasted image 20231222164449.png]]

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

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Pasted image 20231222170158.png]]

首先能看到，它将mRecycle设置为了true。这个属性在之前的流程中并没有提到，主要是因为对流程分析不影响。但是这里提他，是因为它第一次派上了大用场。

mRecycle本身是控制是否回收子View的。如果为true，表明LayoutManager此时**同意**回收子View。在本例中，是滑动的状态，随着不断滑动，肯定有View会逐渐退出屏幕外，对于那些已经退出屏幕外的View，我们当然要回收。所以LayoutManager在滑动的时候是允许回收子View的。

> [!stickies]
> #comment 为什么要这么设计？可以思考一下。

顺着这个思路，我们回顾一下以前mRecycle的变化：在[[Study Log/android_study/recyclerview/1_start/1_2_2_step2|1_2_2_step2]]中，LayoutManager的onLayoutChildren()方法里面就将它设置为了fasle。言外之意， #comment <u>当RecyclerView在布局子View的时候，是不允许回收子View的</u>！

### 2.1.2 Calculate Info

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

你可能会觉得，我们手滑动了184，所以这个值就是184吧！这样思考的思路是正确的，但是忽略了一些东西。这就是我一开始做出改动(+10)的原因：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Drawing 2023-12-22 16.02.58.excalidraw.png]]

在这种情况下，我往下滑动了184，需要布局的长度真的就是184吗？显然不是的！因为，**多出来的这40，在初次布局的时候就已经布局过了**！我们需要布局的长度应该是184 - 40：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Drawing 2023-12-22 17.24.00.excalidraw.png]]

也就是，图中阴影部分的高度才是我们真正要布局的高度！现在知道这个逻辑了。问题在于：*这个40我怎么算出来*？而这就是mScrollingOffset的作用。从注释也能看出，这个数值应该被赋值为“**在不需要布局的情况下，我们能滑动多少**”。那么在本例中，在不需要布局的情况下，我们能滑动的距离显然就是40。所以，接下来我们看看这个mScrollingOffset是怎么算出来的。

```java
// calculate how much we can scroll without adding new children (independent of layout)  
scrollingOffset = mOrientationHelper.getDecoratedEnd(child)  
        - mOrientationHelper.getEndAfterPadding();
```

当然，根据滑动方向的不同，这个值肯定也不一样。上面的代码是在算往下滑动的情况。我们取出最后一个子View的**end**，然后减去当前layout的"End Boundary"。在本例中，RecyclerView布满屏幕，所以End Boundary就是屏幕的高度2892。而最后一个子View的end是多少？通过上面的图很容易算出来，就是733 \* 4 = 2932（当然肯定不是真的这么算出来的）。这样他俩一减，就得到了我们想要的40：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Pasted image 20231222173701.png]]

算出来之后，它做了下面的事情：

```java
mLayoutState.mAvailable = requiredSpace;  
if (canUseExistingSpace) {  
    mLayoutState.mAvailable -= scrollingOffset;  
}  
mLayoutState.mScrollingOffset = scrollingOffset;
```

其中requiredSpace就是滑动时传入的dy，也就是184。而canUseExistingSpace传入的是true。所以最后我们需要布局的大小就算出来了：184 - 40 = 144。

### 2.1.3 Fill Again

知道了要布局多少，下一步是干嘛？布局！布局的流程是什么？就是fill()！在[[Study Log/android_study/recyclerview/1_start/1_2_2_step2#1.2.2.1 Fill|1_2_2_step2]]中我们提过fill()，但是只是大致说了一下它在干嘛，并没有提到一些细节。这里再给他丰富一下。回到首次加载的代码，也就是onLayoutChildren()中，我们能看到在fill()调用之前都会有这么一个方法：

```java
updateLayoutStateToFillStart(mAnchorInfo);
```

除了这个还有fillEnd()，点进去就可以看到，它们其实也更新了mAvailable和mScrollingOffset。只不过流程相对简单，没有这些计算过程。

回到我们的例子中，下一步就是调用fill()方法，传入我们刚刚修改的mLayoutState：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Pasted image 20231222175708.png]]

刚进入fill()，就走入了一个之前没走到的逻辑。在初次加载的时候，mScrollingOffset的值就是SCROLLING_OFFSET_NaN，所以这里不会走。而本次走进去做了什么呢？看名字就是回收View。但是可以告诉各位，本次执行的实际情况是什么也没回收。其实我们猜也能猜出来，仅仅滑动了184，所有的View肯定都还在显示，所以这里不回收理所应当。等之后什么时候回收了我们再来介绍这个逻辑。

接下来就是之前详细介绍的while循环里面的layoutChunk()。通过之前的介绍，我们更加能够熟悉这些指标的来源：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Pasted image 20231222180029.png]]

但是要注意，这里我们判断的条件是remainingSpace而不是mAvailable。它俩的区别就是前者比后者又多加了一个mExtraFillSpace。这个变量是什么呢？这就和之后的离屏预渲染有关了。我们先不介绍这个东西。

在每次layoutChunk()的时候，当然不能只做这些简单的工作：

```ad-info
这里之后，手机换了。高度为2199，等分三份是733。这里我每个item多加了10，就是743。
```

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Drawing 2023-12-25 14.42.16.excalidraw.png]]

根据每次滑动的距离不同，都会做出不同的动作。从例子中可以看到如下情况：

1. 首次滑动392。此时超出的部分，也就是mScrollingOffset是30。我们要布局的空间是362。等while循环走完之后，也只布局了一个View。所以最后fill()返回的是一个View的高度743。
2. 但是，在LayoutManager的scrollBy()中可以看到，实际上滑动的距离是我们请求的距离392以及消费的距离（30 + 743）中的小值。所以最后也还是滑动了392。
3. 第一次滑动应用完毕后，也就是将所有Item向上移动392。得到中间图的情况。
4. 第二次滑动了74，此时mScrollingOffset是381。在这种情况下，不需要布局，所以while循环根本不会走。最终滑动的距离就是74。
5. 第三次滑动了5749。 #question *这里因为277 < 307，所以Item1会被回收（why？）*。

这里最大的问题，就是为什么会回收？我们回顾一下fill() + layoutChunk()的流程：

```java
int fill() {  

	先尝试回收

    while (还有地方布局) {  
		layoutChunk 布局一个View
		
        再尝试回收
    }  
    
    return 返回布局的总长度;  
}
```

这里就引出了一个问题，*为什么布局之前和布局之后都要尝试进行回收*？我们先来看布局之后的这个回收。

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Drawing 2023-12-25 19.52.13.excalidraw.png]]

可以看到，我滑动的距离越多，布局的距离也就越多。而我们滑动的距离和第一个Item距离尾部的位置，也就决定了第一个Item是否要被回收。可以看到，在上图中，如果scroll > 743，Item1就应该被回收；如果scroll > 743 * 2，那么Item1和Item2都应该被回收。

既然如此，scroll是怎么来的？看一下fill()的代码就能够知道，其实scroll就是mScrollingOffset。这个时候你可能会问？mScrollingOffset不是[[#2.1.2 Calculate Info]]开头的时候就说了，是“不需要布局的情况下，最长能滑动的距离”吗？为什么这里又变成实际滑动的距离了？

这个问题的答案我也是现在才弄明白。注意注释里说的"**set** the amount of"，关键就在这个set。如果没有这个set，那它确实应该一直保存不需要布局的距离。但是有了这个set，就仅仅代表**这个变量的初值是不需要布局的距离**。在之后的计算（while循环）中，mScrollingOffset会不断增加，增加的也就是实际滑动的距离。其实，这也是这个变量名的本意，就是**滑动的偏移量**。

回答了这个问题，再回头看代码，是否更加清晰了！每次layoutChunk()执行完毕，mScrollingOffset都会变成最新的滑动距离。然后这个距离就参与了和每个Item的底部到RecyclerView顶部距离的比较。这部分逻辑就在recycleByLayoutState()中：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Pasted image 20231225200859.png]]

大于号的左边就是每个Item的底部到RecyclerView顶部的距离；右边就是mScrollingOffset，也就是提到过的scroll。

然后就是，为什么回收的逻辑要在for循环里？因为scroll可能非常大，所以可能很多个Item的底部到RV顶部的距离都比scroll小，换句话说，就是很多个Item都会被移出屏幕。自然就都要回收啦！

---

然后是，while循环执行之前，也就是布局开始之前，也会尝试一次回收。为什么又要有这个逻辑？既然每次循环之后我都会尝试回收，那么理论上下一次布局之前应该不用回收呀！这就回到之前的那张图了：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Drawing 2023-12-25 20.31.29.excalidraw.png]]

这是之前**三连发**的最右边那张。我是自己定义了三个按钮来模拟这三次滑动的：

```kotlin
findViewById<Button>(R.id.scroll).setOnClickListener {  
  recyclerView.scrollBy(0, 392)  
}  
findViewById<Button>(R.id.scroll2).setOnClickListener {  
  recyclerView.scrollBy(0, 74)  
}  
findViewById<Button>(R.id.scroll3).setOnClickListener {  
  recyclerView.scrollBy(0, 第三次滑动的scroll)  
}
```

你也可以写一个Demo来复线我的例子。现在我们需要讨论一下：还是像之前那样，如果scroll > 277，那么Item1就会被回收，反之就不会回收。

但是还有个问题，就是**while循环一定会执行吗**？显然，只有scroll > 307的时候才会执行（我们就不讨论等于了，没什么意思）。因为小于307的时候我们是不需要布局的。这就产生了一个尴尬的情况：如果你只在while循环里才有回收的逻辑，那么就代表当277 < scroll < 307的时候，就没人回收了！

为了解决这个问题，就有了while循环之前的recycleByLayoutState()。但是最大的问题就是，**我如何能证明277 < scroll < 307**？我们来分析一下代码：

```java
// fill()中while之前的回收逻辑
if (layoutState.mScrollingOffset != LayoutState.SCROLLING_OFFSET_NaN) {  
    // TODO ugly bug fix. should not happen  
    if (layoutState.mAvailable < 0) {  
        layoutState.mScrollingOffset += layoutState.mAvailable;  
    }  
    recycleByLayoutState(recycler, layoutState);  
}
```

在执行这段之前，mScrollingOffset是多少？毫无疑问，就是307。也就是我们提过许多遍的“不需要布局最长滑动距离”。那么，mAvailable是多少？然后，这个mAvailable为什么还会小于0？

首先，mAvailable的定义很明确，就是**我们需要布局的长度**。现在回想一下，它是咋算出来的？[[#2.1.2 Calculate Info]]的最后我们说过，就是我们`实际滑动的距离 - mScrollingOffset`。那么，我们带入一个(277, 307)之间的数字，比如280。这种情况下，mAvailable是多少？是个负数！因为这个范围内的数字都小于307，而mScrollingOffset的初值就是307。

通过上面的叙述。我们能总结出来mAvailable什么时候会小于0：**我们实际滑动的距离，还不够去布局新的View**。因此，在实际情况中，(0, 307)之间的滑动距离其实都会走这里。只不过，如果你处于(277, 307)之间，就要考虑回收的事情。

### 2.1.4 View Recycle

接下来看看View是如何被回收的。具体来讲分为两步：

1. RecyclerView移除此View，并回调onViewDetachedFromWindow()；
2. Recycler回收此View的ViewHolder，打入Cache或者Pool。

这里Cache，Pool相关的可以看这篇文章：[Anatomy of RecyclerView: a Search for a ViewHolder | by Pavel Shmakov | AndroidPub | Medium](https://medium.com/android-news/anatomy-of-recyclerview-part-1-a-search-for-a-viewholder-404ba3453714#8179)。我们之后也会专门对RV的缓存做深入讲解。

最重要的一点就是，**Cache中的ViewHolder不需要bind就可以直接复用；而Pool中的ViewHolder需要重新bind**。

大概粘一张图：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Pasted image 20231225172904.png]]

Cache的默认大小是2，Pool的默认大小是5（这里我们简单认为Cache和Pool就是一个容器，不要细看类型什么的）。当Cache满了之后，里面的第一个（最老的）元素会被弹到Pool中：

```java
// Retire oldest cached view  
int cachedViewSize = mCachedViews.size();  
if (cachedViewSize >= mViewCacheMax && cachedViewSize > 0) {  // mViewCacheMax默认值是2
    recycleCachedViewAt(0);  
    cachedViewSize--;  
}

/**  
 * Recycles a cached view and removes the view from the list. Views are added to cache 
 * if and only if they are recyclable, so this method does not check it again. 
 * 
 * A small exception to this rule is when the view does not have an animator reference  
 * but transient state is true (due to animations created outside ItemAnimator). In that 
 * case, adapter may choose to recycle it. From RecyclerView's perspective, the view is 
 * still recyclable since Adapter wants to do so. 
 * 
 * @param cachedViewIndex The index of the view in cached views list  
 */
 void recycleCachedViewAt(int cachedViewIndex) {  
    if (DEBUG) {  
        Log.d(TAG, "Recycling cached view at index " + cachedViewIndex);  
    }  
    ViewHolder viewHolder = mCachedViews.get(cachedViewIndex);  
    if (DEBUG) {  
        Log.d(TAG, "CachedViewHolder to be recycled: " + viewHolder);  
    }  
    addViewHolderToRecycledViewPool(viewHolder, true);  // 放到Pool中
    mCachedViews.remove(cachedViewIndex);  
}
```

上面的逻辑位于Recycler的recycleViewHolderInternal()方法，也是回收View的核心方法。需要注意的是，**为什么是>=而不是>**？不是超过了缓存的最大值才会弹出去吗？

答案是，这个操作是先做的。我们举一个例子：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Drawing 2023-12-25 17.44.12.excalidraw.png]]

在这个状态下，如果我们继续向上滑，会出现什么？当然是3会移出屏幕。那么3去哪儿了？去Cache里！那既然3要进Cache，谁要出Cache？当然是1！那么如果我先把1移出Cache，再把3放进Cache，移出的时候Cache大小是多少？2！

就是这样。如果我们是先放进3，再移出1，那么就应该是大于而不是>=了。不过这种做法肯定是不合理的，因为有一瞬间Cache的大小是3而不是2。

RV之所以叫RecyclerView，显然最大头的就是Recycle。所以Cache本身其实不是那么重要。重要的是Pool。

下面，介绍一下上图中，如果继续向下滑会出现的事情：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Drawing 2023-12-25 21.27.23.excalidraw.png]]

在我们的例子中，由于每个Item都是一样高的，所以可以投机取巧计算出来滑动到这个位置时的情况：

$$
end = mScrollingOffset - 30
$$

这也就意味着，end < mScrollingOffset是一定成立的！而当实际滑动的距离变化时，会有这样的情况：

* 如果scroll < mScrollingOffset，那么mAvailable < 0，最终的（while循环执行之前）mScrollingOffset = scroll，并且limit = scroll；
* 如果scroll > mScrollingOffset，那么mAvailable > 0，最终的mScrollingOffset还是初始值，limit = mScrollingOffset。

而end < mScrollingOffset。所以我们可以得出结论：

* 如果scroll > mScrollingOffset，while循环之前的那个回收一定会回收Item 3；
* 如果end < scroll < mScrollingOffset，while循环之前的那个回收也会回收Item3；
* 如果0 < scroll < end，不会回收Item3，**但是Item 7也不可能显示出来**。

除了标红的那一段，剩下的都是之前就总结过的结论。问题是，会不会存在不回收Item3，但是Item7也能显示出来的情况呢？讨论这个问题，我们可以通过仅改变Item 6的高度入手。这个时候，mScrollingOffset就不是end + 30，而是一个随意的值（end是定值）。

而如果mScrollingOffset被调整到 < end的时候，会发生什么？答案是：**while循环之前的那个回收一定不会回收Item3**。因为在**while循环执行之前**，limit只有这两个情况：

* limit = scroll < mScrollingOffset**的初值** < end；limit = scroll = mScrollingOffset的终值 < end；
* limit = mScrollingOffset < (end, scroll)。

因此，limit绝对不会超过end，那个for循环里的if条件也绝对不会满足，也就绝对不会回收。这个时候，**回收Item3就要靠while循环里的那个回收了，当layoutChunk()布局了Item7之后，就会更新mScrollingOffset，此时再去判断是否要回收Item3**。

我上面讨论这么复杂一堆，根本目的是什么？答案是：==***证明当回收和复用在一次滑动事件中发生时，回收一定先于复用发生***==。你可能会问，最后这个例子不是还说mScrollingOffset < end的时候Item3不会先回收吗？注意。这种情况下，和Item7就没啥关系了。因为这种情况下在这次滑动中，如果Item7显示出来而Item3没有被回收，**那根本就不算“回收和复用在一次滑动事件中发生”**。所以，只发生回收（Item6非常长），只发生复用，或者都没发生，这些情况不在我们讨论范围内。

```ad-important
现在回到这个例子。当scroll > mScrollingOffset的时候，这一次滑动会导致Item7显示，Item3回收。而Item3回收是一定先于Item7显示的。因为此时Item3回收位于while循环之前，Item7显示在while循环里面。
```

我们可以随便改，改Item的高度，让每个Item都不一样。但是无论怎么改，只要在一次滑动中同时发生了回收和复用，都可以像这样讨论，答案一定是回收先于复用。