数据的改动，我们从全量更新开始。为了最简化，我们只讨论下面的情况。现在Adapter中有10个item。首屏加载能显示三个：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Pasted image 20231228190257.png|300]]

在**不滑动**的情况下，我将点击Reverse。这个按钮的作用非常简单：

```kotlin
fun reverse() {  
  nums.reverse()  
  notifyDataSetChanged()  
}
```

反转Adapter的数据元素，并调用notifyDataSetChanged()对RV进行全量刷新。我们看一看这个过程中发生了什么。

首先，通过一系列观察者模式的回调（这部分后面讲组件的架构设计的时候再聊，对现在叙述流程不影响），调用到了RecyclerViewDataObserver的onChanged()方法：

```java
@Override  
public void onChanged() {  
    assertNotInLayoutOrScroll(null);  
    mState.mStructureChanged = true;  
  
    processDataSetCompletelyChanged(true);  
    if (!mAdapterHelper.hasPendingUpdates()) {  
        requestLayout();  
    }  
}
```

这里面调用了processDataSetCompletelyChanged()方法。我们在[[Study Log/android_study/recyclerview/1_start/1_2_1_step1#1.2.1.3 Update Adapter|1_2_1_step1]]中提到过，setAdapter()也会调用这里。合情合理，换Adapter了，数据肯定会发生变化，所以全部刷新是没问题的。初次之外，还有一个位置也会调用processDataSetCompletelyChanged()，就是swapAdapter()：

```java
/**  
 * Swaps the current adapter with the provided one. It is similar to 
 * {@link #setAdapter(Adapter)} but assumes existing adapter and the new adapter uses the same  
 * {@link ViewHolder} and does not clear the RecycledViewPool.  
 * <p>  
 * Note that it still calls onAdapterChanged callbacks.  
 * 
 * @param adapter The new adapter to set, or null to set no adapter.  
 * @param removeAndRecycleExistingViews If set to true, RecyclerView will recycle all existing  
 *                                      Views. If adapters have stable ids and/or you want to 
 *                                      animate the disappearing views, you may prefer to set 
 *                                      this to false. 
 * @see #setAdapter(Adapter)  
 */
public void swapAdapter(@Nullable Adapter adapter, boolean removeAndRecycleExistingViews) {  
    // bail out if layout is frozen  
    setLayoutFrozen(false);  
    setAdapterInternal(adapter, true, removeAndRecycleExistingViews);  
    processDataSetCompletelyChanged(true);  
    requestLayout();  
}
```

可以看到，如果只是换Adapter的话，两个Adapter共存，并且共用一个Pool和里面的ViewHolder。

回到onChanged()，在处理完之后，它发起了一个requestLayout()，来重新布局。这个过程就和第一章的流程差不多了。不过我们还是要补充一些细节。

首先看它是如何标记所有的View都已经被改变的。先来分析现状。根据我们之前的分析，现在屏幕上的情况应该是这样的：只有三个ViewHolder，并且它们都在屏幕上，其它的数据还并没有被布局到。

而据我们所知，RecyclerView中的View有如下几种状态：

* 可见；
* 在Cache中（View的数据还在）；
* 在Pool中（View只剩空壳）；

而现在我们只有三个可见的View，并且之后数据会发生改变，显然它们是需要被放到Pool中的。接下来看看这个流程是什么样的。

进入processDataSetCompletelyChanged()方法：

```java
/**  
 * Processes the fact that, as far as we can tell, the data set has completely changed. 
 * 
 * <ul>  
 *   <li>Once layout occurs, all attached items should be discarded or animated.  
 *   <li>Attached items are labeled as invalid.  
 *   <li>Because items may still be prefetched between a "data set completely changed"  
 *       event and a layout event, all cached items are discarded. 
 * </ul>  
 *  
 * @param dispatchItemsChanged Whether to call  
 * {@link LayoutManager#onItemsChanged(RecyclerView)} during measure/layout.  
 */
void processDataSetCompletelyChanged(boolean dispatchItemsChanged) {  
    mDispatchItemsChangedEvent |= dispatchItemsChanged;  
    mDataSetHasChangedAfterLayout = true;  
    markKnownViewsInvalid();  
}
```

这里首先将dispatchItemsChanged亦或上去。意味着mDispatchItemsChangedEvent一旦被设置为true，之后就一直是true了。通过这个方法是不会置回false的；然后设置mDataSetHasChangedAfterLayout为true。这两个变量我们之后都会再遇到（其实之前就遇到过了）。

最后markKnownViewsInvalid()方法将所有已知的View全部置为失效。这也是为了刷新去考虑的。这里面涉及到非常多的调用，我将它们都拉出来梳理一遍：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Notepad_81d70sAv1I.png]]

一共是5步。可以看到，除了前两步，剩下的都是在操作Recycler中的这个mCachedViews。它其实就是我们在[[Study Log/android_study/recyclerview/2_scroll_data/2_1_scroll#2.1.4 View Recycle|2_1_scroll#2.1.4 View Recycle]]中说过的缓存Cache。然而经过我们的讨论，目前还没有被Cache的ViewHolder。所以我们只讨论前两步，之后等什么时候触发了后几步再说。

第一步，将RV下面所有的View所在的ViewHolder添加标记INVALID和UPDATE。下面是这两个标记的说明：

```java
/**  
 * The data this ViewHolder's view reflects is stale and needs to be rebound 
 * by the adapter. mPosition and mItemId are consistent. 
 */
static final int FLAG_UPDATE = 1 << 1;  
  
/**  
 * This ViewHolder's data is invalid. The identity implied by mPosition and mItemId
 * are not to be trusted and may no longer match the item view type. 
 * This ViewHolder must be fully rebound to different data. 
 */
static final int FLAG_INVALID = 1 << 2;
```

可以看到，UPDATE表示ViewHolder只有数据需要换，位置和id还是一样的；但是INVALID表示这个ViewHolder只剩一个空壳了，所有的信息都是无效的。

第二步，给RV下所有的View的mInsetsDirty设置为true。这个变量和子View周围的装饰有关，我们暂且不提。

总结起来，其实就是给目前可见的三个View设置了一个标记而已。下一步就是requestLayout()了，接下来就来到了之前走过的布局环节。

processAdapterUpdatesAndSetAnimationFlags()这个方法，在[[Study Log/android_study/recyclerview/1_start/1_2_1_step1#1.2.1.3 Update Adapter|1_2_1_step1#1.2.1.3 Update Adapter]]的一开始就介绍到了。它最一开始的逻辑是分发一个事件：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Pasted image 20231228204945.png]]

这里两个if的条件是啥？不就是我们刚才 #TODO/link 提到过的地方？因此，这里会将[[Study Log/android_study/recyclerview/1_start/1_2_1_step1#1.2.1.3.1 AdapterHelper|AdapterHelper]]中的数据重置，代表我们之后要重新统计“对Adapter的更新操作们”。下面是reset()方法：

```java
void reset() {  
    recycleUpdateOpsAndClearList(mPendingUpdates);  
    recycleUpdateOpsAndClearList(mPostponedList);  
    mExistingUpdateTypes = 0;  
}
```

到了分发事件的时候，因为之前 #TODO/link 我们将mDispatchItemsChangedEvent置为了true，所以我们在这里派发整个数据集改变的事件。默认情况下，这里是什么都不做的。不过我们可以通过重写LayoutManager的这个方法来做自己想做的逻辑：

```java
/**  
 * Called in response to a call to {@link Adapter#notifyDataSetChanged()} or  
 * {@link RecyclerView#swapAdapter(Adapter, boolean)} ()} and signals that the the entire  
 * data set has changed. 
 * 
 * @param recyclerView  
 */  
public void onItemsChanged(@NonNull RecyclerView recyclerView) {  
}
```

接下来，又到了我们介绍的最详细的fill() + layoutChunk()的流程了。不过在这之前，有一个首次加载时没有走到的流程——**我们好像到现在都还没回收View呐**！之前我们也只是打了个标记而已，然而这些View目前都还在那里放着。这样谁知道这个View该怎么办嘛！看detachAndScrapAttachedViews方法，它将recycler传了进去，来对View进行回收：

```java
/**  
 * Temporarily detach and scrap all currently attached child views. Views will be scrapped 
 * into the given Recycler. The Recycler may prefer to reuse scrap views before 
 * other views that were previously recycled. 
 * 
 * @param recycler Recycler to scrap views into  
 */
public void detachAndScrapAttachedViews(@NonNull Recycler recycler) {  
    final int childCount = getChildCount();  
    for (int i = childCount - 1; i >= 0; i--) {  
        final View v = getChildAt(i);  
        scrapOrRecycleView(recycler, i, v);  
    }  
}
```

由于我们之前给每个ViewHolder都打了INVALID标记，所以这里所有的ViewHolder都会被放到Pool中，而不是Scrap。关于Scrap的信息，以及它和Pool以及Cache的区别，之后会有统一的说明。这里我们只是最简单的情况，也就是所有的View都被回收到了Pool中。

不过我们还是稍微看一下回收到Pool中的逻辑：

```java
if (viewHolder.isInvalid() && !viewHolder.isRemoved()  
        && !mRecyclerView.mAdapter.hasStableIds()) {  
    removeViewAt(index);  
    recycler.recycleViewHolderInternal(viewHolder);  
}
```

此乃snapOrRecyclerView()的逻辑。如果是INVALID的ViewHolder，会直接让RV移除这个View，然后在内部回收这个ViewHolder。