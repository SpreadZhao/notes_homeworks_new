# 2.2 Data

### 2.2.1 All Change

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

#### 2.2.1.1 Before Layout

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

#### 2.2.1.2 In Layout

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

### 2.2.2 Partial Change

#### 2.2.2.1 Off-screen Change

接下来，我们展示一下最简单的局部更新。一共有10个元素，RV初次加载依然只显示最上面3个。此时：

* 在末尾插入一个元素；
* 删掉最末尾的元素。

它们的实现也非常简单：

```kotlin
fun removeLast() {
  val lastIndex = dataSet.lastIndex
  dataSet.removeLast()
  notifyItemRemoved(lastIndex)
}

fun append() {
  val dataNum = dataSet.size + 1
  val dataType = if (dataNum % 2 == 0) DATA_TYPE_EVEN else DATA_TYPE_ODD
  dataSet.add(Data(dataNum, dataType))
  notifyItemInserted(dataSet.lastIndex)
}
```

接下来我们所描述的操作都会带上更新和删除操作。首先，和notifyDataSetChanged()一样，也是会经过一系列观察者模式回调到RecyclerViewDataObserver中：

```java
@Override
public void onItemRangeRemoved(int positionStart, int itemCount) {
	assertNotInLayoutOrScroll(null);
	if (mAdapterHelper.onItemRangeRemoved(positionStart, itemCount)) {
		triggerUpdateProcessor();
	}
}

@Override
public void onItemRangeInserted(int positionStart, int itemCount) {
	assertNotInLayoutOrScroll(null);
	if (mAdapterHelper.onItemRangeInserted(positionStart, itemCount)) {
		triggerUpdateProcessor();
	}
}
```

除了全量更新，也就是onChanged()，其它的回调其实都差不多。都是先调用AdapterHelper对应的回调，然后再触发更新的流程。

我们首先来看AdapterHelper都做了什么：

```java
/**
 * @return True if updates should be processed.
 */
boolean onItemRangeInserted(int positionStart, int itemCount) {
	if (itemCount < 1) {
		return false;
	}
	mPendingUpdates.add(obtainUpdateOp(UpdateOp.ADD, positionStart, itemCount, null));
	mExistingUpdateTypes |= UpdateOp.ADD;
	return mPendingUpdates.size() == 1;
}

/**
 * @return True if updates should be processed.
 */
boolean onItemRangeRemoved(int positionStart, int itemCount) {
	if (itemCount < 1) {
		return false;
	}
	mPendingUpdates.add(obtainUpdateOp(UpdateOp.REMOVE, positionStart, itemCount, null));
	mExistingUpdateTypes |= UpdateOp.REMOVE;
	return mPendingUpdates.size() == 1;
}
```

这里面也只是在mPendingUpdates()里加入了一个UpdateOp，用来表示一次对RV的插入/删除操作。

> #question *为什么这里只有size为1的时候才是true？这玩意儿到底有啥用？*

除此之外，接下来只是在triggerUpdateProcessor()中又进行了一次requestLayout()，就没什么事情了。接下来我们还是从布局开始说。

来到step1。我们也说过，step1的主要工作就是进行预布局和动画。但是由于我们直接删掉了动画，所以这里的操作并不会影响什么。不过，我们还是要看看它到底做了什么，为之后介绍预布局和动画做铺垫。实际上，这里所作的事情就是消费刚才加入到mPendingUpdates中的更新操作。调用关系为dispatchLayoutStep1() -> processAdapterUpdatesAndSetAnimationFlags() -> consumeUpdatesInOnePass()：

```java
for (int i = 0; i < count; i++) {
	UpdateOp op = mPendingUpdates.get(i);
	switch (op.cmd) {
		case UpdateOp.ADD:
			mCallback.onDispatchSecondPass(op);
			mCallback.offsetPositionsForAdd(op.positionStart, op.itemCount);
			break;
		case UpdateOp.REMOVE:
			mCallback.onDispatchSecondPass(op);
			mCallback.offsetPositionsForRemovingInvisible(op.positionStart, op.itemCount);
			break;
	}
}
```

我只是截取了我们关心的部分。可以看到这里就是将pending的更新给取出来，然后调用callback，也就是RV自己的回调来处理这些事情。其中的这个SecondPass最终会回调到LayoutManger中，而LinearLayout并没有重写这个方法，所以这里是什么也不做；之后第二句是由RV来响应的，操作如下：

```java
void offsetPositionRecordsForInsert(int positionStart, int itemCount) {
	final int childCount = mChildHelper.getUnfilteredChildCount();
	for (int i = 0; i < childCount; i++) {
		final ViewHolder holder = getChildViewHolderInt(mChildHelper.getUnfilteredChildAt(i));
		if (holder != null && !holder.shouldIgnore() && holder.mPosition >= positionStart) {
			holder.offsetPosition(itemCount, false);
			mState.mStructureChanged = true;
		}
	}
	mRecycler.offsetPositionRecordsForInsert(positionStart, itemCount);
	requestLayout();
}
```

这里首先将RV直接的孩子都拿出来，每一个进行比较：`mPosition >= positionStart`。这个比较意味着什么？我们举个例子。比如原来的列表是这样

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Drawing 2024-01-03 11.46.41.excalidraw.png]]

这里模拟的是调用了`notifyItemInserted(3)`。也就是在原来的2号和3号之间新插入一个元素。那么带入到我们现在这个方法中，在布局之前，RV的孩子都是谁？1 2 3 4 5。那么对于这个`mPosition >= positionStart`条件，谁符合？3 4 5。插入了新元素之后，原来的3 4 5变成了什么？4 5 6。而原来的1 2并没有变。这里if块中的`holder.offsetPosition()`就是在做这样的操作。只不过，它考虑了不只是插入一个元素的情况，所以把插入元素的个数也传了进去。除了这里，该方法还考虑了Cache中的ViewHolder，这些VH虽然不在屏幕上，但是其中的数据是有效的，随时有可能回到屏幕内。比如还是上面的例子。如果我们没有停用RV的缓存，<u>那么0号就应该是在Cache中的元素</u>。那么如果我们是在0号处插入一个元素的话，执行到这里时，Recycler也会在`mRecycler.offsetPositionRecordsForInsert()`这里将0号元素的位置更新为1号。

> [!comment] 那么0号就应该是在Cache中的元素
> 有个前提，就是我们是从上往下滑动的。如果是从下往上滑动，那么在Cache中的很可能是6号。

对于删除的情况，可以看隔壁方法的实现。它们的目的是一样的，只不过由于是删除而不是增加，所以有一些改动会异于插入。

现在离开这个例子，回到最一开始的例子中。由于我们插入或者删除的是最末尾的操作，offsetPositionRecordsForInsert/Remove方法其实什么也不会做！因为插入的位置在10号（第11个），删除的位置在9号（第10个），而屏幕上的元素还只有0 1 2号。所以它们并不需要修改位置。

接下来，来到了最重要的step2，也就是布局的过程。在算完锚点，开始fill() + layoutChunk()之前，依然要回收一下屏幕上的View。上一次我们回收是在 #TODO/link notifyDataSetChanged()的时候，那个时候由于我们给View打上了INVALID标记，所以所有的View的数据都失效了，它们要被会受到Pool中。但是在本例中，并没有哪个操作标记了目前RV的子View中的哪个是无效的。因此我们要重新看一下回收的流程：

```java
if (viewHolder.isInvalid() && !viewHolder.isRemoved()
		&& !mRecyclerView.mAdapter.hasStableIds()) {
	removeViewAt(index);
	recycler.recycleViewHolderInternal(viewHolder);
} else {
	detachViewAt(index);
	recycler.scrapView(view);
	mRecyclerView.mViewInfoStore.onViewDetached(viewHolder);
}
```

if分支是我们之前介绍的回收流程。而在本次，我们走的是else分支。也就是仅仅将屏幕内的三个View给detach掉，然后scrap掉它们的ViewHolder。这里的Scrap依然不是Cache，不过我们这里依然不深入讨论，暂且可以把它当作一个和Cache不同的缓存，这里的VH的数据依然是有效的，复用的时候不用重新走bind流程。

注意，这里的detachViewAt()方法并不会触发Adapter的onViewDetachedFromWindow()，因为这里的detach只是暂时的。只有移除View的时候才会触发onViewDetachedFromWindow()。

剩下的流程，我们已经能猜出来了。因为0 1 2号元素都没有修改过，所以重新的布局会从Scrap中取出原来的三个ViewHolder直接布局，并不需要走onBindViewHolder流程。这里简单给一下从Scrap中取的逻辑：

```java
// 1) Find by position from scrap/hidden list/cache
if (holder == null) {
	holder = getScrapOrHiddenOrCachedHolderForPosition(position, dryRun);
	if (holder != null) {
		...
	}
	... ...
}
```

#### 2.2.2.2 On-screen Change

接下来，我们将难度升级一些：在2号增加一个元素，或者删除2号元素。也就是下图中的3要么被删除，要么被挤下去：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Pasted image 20240103135759.png|300]]

下面是实现：

```kotlin
fun insertAfter2() {
  val newItem = Data("Spread", DATA_TYPE_OTHER)
  dataSet.add(2, newItem)
  notifyItemInserted(2)
}

fun remove3() {
  dataSet.removeAt(2)
  notifyItemRemoved(2)
}
```

下面是效果：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/scrcpy_bbGusULcqF.gif|inl|300]] ![[Study Log/android_study/recyclerview/2_scroll_data/resources/scrcpy_gVURMcuZh7.gif|inl|300]]

我们先从insert开始说。我们这次是在2后面插入了一个元素。在layout执行之前，依然是在mPendingUpdates里加入一个UpdateOp，并没有什么不同。而在布局的step1中，依然是进行`mPosition >= positionStart`的比较。现在屏幕上是0 1 2号，而2号（也就是3）满足这个条件（2 >= 2），所以2号ViewHolder的position会被从2更新到3，也就是插入元素之后的下标。

之后在布局的过程中，对于0号和1号，都是按照原来的流程，通过getScrapOrHiddenOrCachedHolderForPosition()方法取出来，不用走bind。但是对于2号呢？由于之前的3的下标从2被改到了3，这里还能get出来吗？我们看看里面的源码：

```java
/**
 * Returns a view for the position either from attach scrap, hidden children, or cache.
 *
 * @param position Item position
 * @param dryRun  Does a dry run, finds the ViewHolder but does not remove
 * @return a ViewHolder that can be re-used for this position.
 */
ViewHolder getScrapOrHiddenOrCachedHolderForPosition(int position, boolean dryRun) {
	final int scrapCount = mAttachedScrap.size();

	// Try first for an exact, non-invalid match from scrap.
	for (int i = 0; i < scrapCount; i++) {
		final ViewHolder holder = mAttachedScrap.get(i);
		if (!holder.wasReturnedFromScrap() && holder.getLayoutPosition() == position
				&& !holder.isInvalid() && (mState.mInPreLayout || !holder.isRemoved())) {
			holder.addFlags(ViewHolder.FLAG_RETURNED_FROM_SCRAP);
			return holder;
		}
	}
	... ...
}
```

注意if里面的这个条件：

```java
holder.getLayoutPosition() == position
```

对于3这个元素，它的VH还满足这个条件吗？position是啥？我们想要的位置。是几？是2；3的下标是几？**原来是2，现在是3**。就是在step1中被修改的。因此，这个条件对于3来说是false。所以，3对应的VH不满足需求，不要了。

之后，还是会走到onCreateViewHolder去创建新的VH来绑定我们插入的元素。

然后是删除。虽然我们没给出过删除的代码，但是举一反三。我们已经能猜到了。在step1中，依然是修改那些可能由于删除而下标改动的元素。在本例中，没有。因为4还在屏幕外呢。不过，其实还有个操作，就是将3标记为删除：

```java
else if (holder.mPosition >= positionStart) {
	holder.flagRemovedAndOffsetPosition(positionStart - 1, -itemCount, applyToPreLayout);
	mState.mStructureChanged = true;
}

void flagRemovedAndOffsetPosition(int mNewPosition, int offset, boolean applyToPreLayout) {
	addFlags(ViewHolder.FLAG_REMOVED);
	offsetPosition(offset, applyToPreLayout);
	mPosition = mNewPosition;
}
```

这里的FLAG_REMOVED是为了做删除动画用的：

```java
/**
 * This ViewHolder points at data that represents an item previously removed from the
 * data set. Its view may still be used for things like outgoing animations.
 */
static final int FLAG_REMOVED = 1 << 3;
```

接下来在step2布局的时候，到了position为2的时候，通过getScrapOrHiddenOrCachedHolderForPosition()依然拿不到VH，因为原来3的VH刚被修改过位置。所以还是走bind流程绑定Adapter中对应位置的元素，也就是4。

这里你是否会有疑问：3的VH去哪儿了？当然是被回收到Scrap中了，和 #TODO/link 在step2中布局之前的流程一样。但是，我们在布局之后好像并没有用到3的VH呀！那这样就产生了一个问题：3的VH被temporarily detach之后，并没有再attach回来。然而View Group的注释是这么写的：

> Detaches a view from its parent. Detaching a view should be followed either by a call to attachViewToParent(View, int, ViewGroup.LayoutParams) or a call to removeDetachedView(View, boolean). **Detachment should only be temporary**; reattachment **or removal** should happen within the same drawing cycle as detachment. When a view is detached, its parent is null and cannot be retrieved by a call to getChildAt(int).
> * Params:
> 	* index – the index of the child to detach

啥意思？我们既然没有理由对3进行reattachment，那只能removal咯！所以，3之后是要被彻底干掉的。什么时候呢？就是我们一直没介绍的step3。

在step3中，调用了LayoutManger的removeAndRecycleScrapInt()方法来回收scrapped views。首先，彻底remove掉这个view：

```java
if (vh.isTmpDetached()) {
	mRecyclerView.removeDetachedView(scrap, false);
}
```

然后，将这个ViewHolder放到Pool中。显然我们能放Pool，还是别直接销毁的好。调用栈如下：

![[Study Log/android_study/recyclerview/2_scroll_data/resources/Pasted image 20240103171140.png]]