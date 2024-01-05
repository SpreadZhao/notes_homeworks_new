卡片可见性分发草稿。

第一阶段，只做滚动的情况：

```kotlin
private fun isChildVisibleVertical(itemView: View): Boolean {
  val verticalHelper = getVerticalHelper(mRecyclerView.layoutManager) ?: return false
  val itemStart = verticalHelper.getDecoratedStart(itemView)
  val itemEnd = verticalHelper.getDecoratedEnd(itemView)
  return !(itemEnd <= 0 || itemStart >= mRecyclerView.height)
}

private fun handleAttachedVHVisibility() {
  for (i in 0 ..< mRecyclerView.childCount) {
    val child = mRecyclerView.getChildAt(i)
    val oldVisible = child.isVisible
    val newVisible = isChildVisibleVertical(child)
    if (oldVisible != newVisible) {
	  child.isVisible = newVisible
	  mListener?.let {
	    val holder = child.viewHolder ?: return@let
	    if (newVisible) { it.onViewHolderVisible(holder) } else { it.onViewHolderInvisible(holder) }
	  }
    }
  }
}

```

* 问题：所有的item只会显示一次Visible，没显示Invisible。
* 原因：如果你只往一个方向滑动的话，上面消失的item直接被remove掉，是没办法触发handleVisibility的。

所以加入了detach阶段：

```kotlin
private fun handleDetachedChildVisibility(itemView: View) {
  val oldVisible = itemView.isVisibleByTag
  if (oldVisible && mListener != null) {
    itemView.isVisibleByTag = false
    val holder = itemView.viewHolder ?: return
    mListener!!.onViewHolderInvisible(holder)
  }
}
```

在RV的detach或者Adapter的detach中调用这里，可以检测到：

* 滑出屏幕的VH；
* notiyItemRemoved()通知的消失VH。

由于必定消失，所以我们不需要调用isChildVisibleVertical()来计算可见性。并且，这里如果调用反而会出问题 #TODO/link 

但是现在依然不完善，看下面的动图：

![[Study Log/android_study/recyclerview/x_visibility_dispatch/resources/studio64_rrmvb7o2RR.gif]]

这里本来应该打印3的Invisible和Spread的Visible，但是结果是两个都没打印。所以还有我们没Cover到的时机。为了搞清楚这个时机是怎么回事，我们做这样一件事情：

上图中，我们给了额外的布局空间：

```kotlin
val layoutManager = object : LinearLayoutManager(this) {
  override fun getExtraLayoutSpace(state: RecyclerView.State?): Int {
	return height
  }
}
```

现在我们删掉这个，重新来一遍，发现3的Invisible打印出来了：

![[Study Log/android_study/recyclerview/x_visibility_dispatch/resources/studio64_levkz5Cj6L.gif]]

为什么会有这样的区别？这次3的Invisible打印出来显然是因为离开了布局空间，被detach了；而上次没有打印出来就是因为虽然离开了屏幕，但是由于额外布局空间存在，所以依然在屏幕内。

这两种情况的共同点就是：布局完成之后。很巧的是，layoutManager就可以接收到布局完成的通知：

```kotlin
override fun onLayoutCompleted(state: RecyclerView.State?) {
	super.onLayoutCompleted(state)
	dispatcher.dispatchVisibility(LayoutCompletedOccasion)
}
```

