两种可能导致卡片被回收的状态。这也是为什么isInIdleRequestLayout需要同时防住SETTLING和DRAGGING两种状态。综合起来就是`mIsInScroll == true`。

![[Study Log/android_study/recyclerview/x_tricks/resources/Pasted image 20240309180735.png]]