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

