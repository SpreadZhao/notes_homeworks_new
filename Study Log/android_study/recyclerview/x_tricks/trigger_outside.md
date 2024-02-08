![[Study Log/android_study/recyclerview/x_tricks/resources/Pasted image 20240206144903.png]]

bind流程中设置封面是最耗时的。其中唯一最耗时的就是这个取色的逻辑。这里就先放在这里不搞异步，不然bind的耗时是无法体现出来的。

![[Study Log/android_study/recyclerview/x_tricks/resources/Pasted image 20240206145448.png]]

发现在滑动停止预渲染的情况下，基本上都是bind之后才播放视频。证明我们的prerender流程其实已经阻塞了视频的起播。因此，我们希望能让bind流程避开视频的首帧。