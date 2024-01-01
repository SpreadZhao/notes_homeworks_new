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

这里面调用了processDataSetCompletelyChanged()方法。我们在[[Study Log/android_study/recyclerview/1_start/1_2_1_step1#1.2.1.3 Update Adapter|1_2_1_step1]]中提到过，setAdapter()也会调用这里。合情合理，换Adapter了，数据肯定会发生变化，所以全部刷新是没问题的。除此之外，还有一个位置也会调用processDataSetCompletelyChanged()，就是swapAdapter()：

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

而据我们**有限**的所知，RecyclerView中的View有如下几种状态：

* 可见；
* 在Cache中（View的数据还在）；
* 在Pool中（View只剩空壳）；

而现在我们只有三个可见的View，并且之后<label class="ob-comment" title="数据会发生改变" style=""> 数据会发生改变 <input type="checkbox"> <span style=""> 这里所说的数据改变，显然指的是notifyDataSetChanged()方法，而不是滑动之类的操作。如果我们往下滑，这些ViewHolder会被放到Cache中（前提是RV的Cache被设置为正常工作），而不是Pool中。 </span></label>，显然它们是需要被放到Pool中的。接下来看看这个流程是什么样的。

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

这里首先将dispatchItemsChanged亦或上去。意味着mDispatchItemsChangedEvent一旦被设置为true，通过这个方法是不会置回false的；然后设置mDataSetHasChangedAfterLayout为true。这两个变量我们之后都会再遇到（其实[[Study Log/android_study/recyclerview/1_start/1_2_1_step1#1.2.1.3 Update Adapter|之前]]就遇到过了）。

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

接下来，就是传统的fill() + layoutChunk()流程了。和之前不同的是，因为我们刚刚回收了View，所以现在不需要create，而是直接从Pool中拿！之前创建新的逻辑是[[Study Log/android_study/recyclerview/1_start/1_2_2_step2#1.2.2.2.1 Find View|1_2_2_step2#1.2.2.2.1 Find View]]，我们现在看的位于它的上面：

```java
if (holder == null) { // fallback to pool   
    holder = getRecycledViewPool().getRecycledView(type);  
}
```

删掉其它的干扰代码，重要的就这一句。我们来看看里面的逻辑。

```java
/**  
 * Acquire a ViewHolder of the specified type from the pool, or {@code null} if none are  
 * present. 
 * 
 * @param viewType ViewHolder type.  
 * @return ViewHolder of the specified type acquired from the pool, or {@code null} if none  
 * are present. 
 */
@Nullable  
public ViewHolder getRecycledView(int viewType) {  
    final ScrapData scrapData = mScrap.get(viewType);  
    if (scrapData != null && !scrapData.mScrapHeap.isEmpty()) {  
        final ArrayList<ViewHolder> scrapHeap = scrapData.mScrapHeap;  
        for (int i = scrapHeap.size() - 1; i >= 0; i--) {  
            if (!scrapHeap.get(i).isAttachedToTransitionOverlay()) {  
                return scrapHeap.remove(i);  
            }  
        }  
    }  
    return null;  
}
```

要看这里，就要先介绍一下Pool的结构了。Pool最核心的成员是一个Map，它的key是View的类型，Value是一个叫ScrapData的结构。而ScrapData中最重要的就是一个`ArrayList<ViewHolder>`，也就是被放到Pool中的ViewHolder。

之所以这样设计，是因为Pool在一开始就是可以被多个Adapter复用的，并且即使是一个Adapter，也可以有多种不同类型的ItemView（比如MultiTypeAdapter的原理就是基于这个特性）。所以对于我们写的这种简单的单类型RV来说，我们只用到了这个mScrap的一个Value而已。

现在问个问题：这个scrapHeap的size是多少？当然是3，因为我们之前就回收了3个View，它们最终其实就是被放在了这里。现在的逻辑，就是再次把它们都取出来。

OK，除此之外的逻辑和初次加载就没什么区别了。经过这样一操作，所有View（也就3个）的bind就都会被触发。由于我们反转了数据，重新绑定的话，0 1 2 号就不是原来的数据了，这样就让原来的那三个ViewHolder显示了新的三个数字：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Pasted image 20231229111117.png|300]]

现在我们让事情变复杂一点。滑到下图的情况时，再点击Reverse：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Pasted image 20231229145429.png|300]]

这里我又做了一个调整。给ViewHolder添加了ViewType。制作的方法也非常简单，记住一句话：**数据驱动UI**。我先将数据集改成了一个类：

```kotlin
private val dataSet = createListData(1..10, 11, 22)
```

这个方法很简单，就是按照奇偶数分配不同的type。然后在onCreateViewHolder中按照viewType分配颜色：

```kotlin
override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): MyViewHolder {  
  val view = LayoutInflater.from(parent.context).inflate(R.layout.big_text, parent, false).apply {  
    layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, ONE_THIRD_HEIGHT + 10)  
    background = if (viewType == 11) {  
      ColorDrawable(Color.parseColor("#CC0033"))  
    } else {  
      ColorDrawable(Color.parseColor("#0066CC"))  
    }  
  }  
  return MyViewHolder(view)  
}
```

最后最重要的一点：重写getItemViewType()。返回dataSet中对应元素的类型即可：

```kotlin
override fun getItemViewType(position: Int): Int {  
  return dataSet[position].type  
}
```

getItemViewType()这个方法看起来是给开发者用的，然而事实确实给RV用的。在我们介绍过的tryGetViewHolderForPositionByDeadline()方法中，获取ViewHolder之前就要先得到当前这个位置的类型：

```kotlin
final int type = mAdapter.getItemViewType(offsetPosition);
```

然后，我依然保持Cache为默认大小，也就是2。现在滑动到这个状态的时候，RV的状态是怎样的？通过之前的猜测，我们可以推测出：

* 2和3的ViewHolder还在Cache中，数据依然有效；
* 1的ViewHolder被顶到了Pool中，按照1之前ViewHolder的viewType保存到mScrap对应的序列中。

但是可别忘了！由于我们设置的高度比三分之一屏幕要高。如果Item7刚好贴着屏幕底下还没出现的时候，Item4就会超出屏幕上面一块。这就意味着，**此时Item3已经被回收到Cache中了**！也就意味着，此时Item1已经被添加到Pool中了！也就意味着，**Item7出现的时候不会创建新的ViewHolder，而是复用Item1的ViewHolder**！因为7和1都是奇数，所以我们规定的ViewType是一样的。

这一点可以通过日志来证实：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Pasted image 20231229152429.png]]

3刚离开屏幕，立马回收1。然后7显示的时候，复用的holder就是之前1的holder。

所以，现在真实的情况是：只有2和3的ViewHolder在Cache中，Pool中什么也没有。4 5 6 7处于可见状态。因此，点击Reverse后，会出现这样的事情：

1. 将4 5 6 7的VH添加UPDATE | INVALID标记；
2. 将4 5 6 7的<label class="ob-comment" title="LP" style=""> LP <input type="checkbox"> <span style=""> RecyclerView.LayoutParams </span></label>的mInsetsDirty设置为true；
3. 将2 3的LP的mInsetsDirty设置为true；
4. 将2 3的VH添加UPDATE | INVALID标记；
5. **将2 3的VH回收到Pool中**。

这里的操作可以再看一遍这张图，都是一一对应的：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Notepad_81d70sAv1I.png]]

所以现在Pool里一共有2个ViewHolder。<u>在onLayoutChildren()中的 #TODO/link 依然会调用detachAndScrapAttachedViews()方法回收可见的4 5 6 7的VH。</u>此时Pool中共有6个VH，按照type不同对半分。之后进行fill() + layoutChunk()的时候就会重新从Pool里拿出4个ViewHolder重新进行bind。

