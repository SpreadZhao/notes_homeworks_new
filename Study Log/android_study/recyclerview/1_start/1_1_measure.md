---
title: 1.1 measure
chapter: "1"
order: "2"
hierarchy: "2"
---

## 1.1 measure

一切从简。RecyclerView在最一开始的measure流程中，如果没有经过其它特殊设置，会执行自己的defaultOnMeasure()方法：

```java
void defaultOnMeasure(int widthSpec, int heightSpec) {  
    // calling LayoutManager here is not pretty but that API is already public and it is better  
    // than creating another method since this is internal.    
    final int width = LayoutManager.chooseSize(widthSpec,  
            getPaddingLeft() + getPaddingRight(),  
            ViewCompat.getMinimumWidth(this));  
    final int height = LayoutManager.chooseSize(heightSpec,  
            getPaddingTop() + getPaddingBottom(),  
            ViewCompat.getMinimumHeight(this));  
  
    setMeasuredDimension(width, height);  
}
```

在我的例子中，父布局只有一个FrameLayout，其中的RecyclerView的宽和高都是match_parent。因此，这里测量完的高度就应该是手机屏幕的宽度和高度：

![[Study Log/android_study/recyclerview/1_start/resources/Pasted image 20231220142940.png]]

这就结束了！实际上这就是RecyclerView在初次测量时所做的事情：确定RecyclerView的长和宽。这和任何一个View在测量时所作的事情都一样。那么问题就在于，下面的那一坨代码是什么意思？我们可以简单分析一下：

```java
@Override  
protected void onMeasure(int widthSpec, int heightSpec) {  
    if (mLayout == null) {  
        defaultOnMeasure(widthSpec, heightSpec);  
        return;  
    }  
    if (mLayout.isAutoMeasureEnabled()) {  
        final int widthMode = MeasureSpec.getMode(widthSpec);  
        final int heightMode = MeasureSpec.getMode(heightSpec);  
  
        /**  
         * This specific call should be considered deprecated and replaced with         
         * {@link #defaultOnMeasure(int, int)}. It can't actually be replaced as it could  
         * break existing third party code but all documentation directs developers to not         
         * override {@link LayoutManager#onMeasure(int, int)} when  
         * {@link LayoutManager#isAutoMeasureEnabled()} returns true.  
         */        
         mLayout.onMeasure(mRecycler, mState, widthSpec, heightSpec);  
  
        final boolean measureSpecModeIsExactly =  
                widthMode == MeasureSpec.EXACTLY && heightMode == MeasureSpec.EXACTLY;  
        if (measureSpecModeIsExactly || mAdapter == null) {  
            return;  
        }  
  
        if (mState.mLayoutStep == State.STEP_START) {
        ... ...
    ... ...
```

其中mLayout.onMeasure()调用的其实也是defaultOnMeasure()，如果我们没有经过其它设置的话。从这里可以看出，如果经过mLayout的测量，宽和高是确定值的话，measure流程就可以结束了！

我们可以做一个实验：将recyclerView的高度改为wrap_content，那么在这个地方就不会return了：

![[Study Log/android_study/recyclerview/1_start/resources/Pasted image 20231220144250.png]]

![[Study Log/android_study/recyclerview/1_start/resources/Pasted image 20231220144347.png]]

可以看到，不但不会return，而且此时的高度也是0。因为此时处于初始化阶段，ViewHolder还没有创建，只是一个空壳而已。既然没有确定高度，此时的高度当然就是0。

measure剩下的流程其实就是在进行layout操作。这样设计其实也很合理。既然没有确定宽或者高的值，就先派发layout，等布局完成后这个值就有改变，也就能进一步确定还没确定的属性了。