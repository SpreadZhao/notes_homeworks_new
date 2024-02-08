---
title: 最简单的视频播放UI
date: 2024-01-31
tags: 
mtrace:
  - 2024-01-31
---

# 最简单的视频播放UI

#date 2024-01-24

```kotlin
class MyVideoView : FrameLayout {

    private val mSurfaceView: SurfaceView
    private var mPlayer: Player? = null

    constructor(context: Context) : this(context, null)

    constructor(context: Context, attrs: AttributeSet?) : this(context, attrs, 0)

    constructor(context: Context, attrs: AttributeSet?, defStyleAttr: Int) : super(context, attrs, defStyleAttr) {
        this.mSurfaceView = SurfaceView(context)
        this.addView(mSurfaceView, 0)
    }

    fun setPlayer(player: Player) {
        if (mPlayer == null) {
            mPlayer = player
            if (player.isCommandAvailable(COMMAND_SET_VIDEO_SURFACE)) {
                player.setVideoSurfaceView(mSurfaceView)
            }
        }
    }

}
```

上面的播放View没有调整尺寸。所以播起来之后铺满了屏幕。如果想要调整，最简单的方式是借助UI库给我们提供的AspectRatioFrameLayout。只需要调用下面的方法：

```kotlin
mContentFrame.setAspectRatio(ratio)
```

mContentFrame显然就是AspectRatioFrameLayout，而这里面才是我们的SurfaceView。然后在这个方法内部它自己会设置好对应的宽高，并requestLayout。

那么，这个ratio怎么来呢？Player的Listener里有个onVideoSizeChanged方法，这就是视频的宽高改变时的回调。所以我们在这里面就能拿到新的视频的宽高并触发。下面是全部代码：

```kotlin
@OptIn(UnstableApi::class)
class MyVideoView : FrameLayout {

    private val mContentFrame: AspectRatioFrameLayout
    private val mSurfaceView: SurfaceView
    private var mPlayer: Player? = null
    private val playListener = PlayListener()

    constructor(context: Context) : this(context, null)

    constructor(context: Context, attrs: AttributeSet?) : this(context, attrs, 0)

    constructor(context: Context, attrs: AttributeSet?, defStyleAttr: Int) : super(context, attrs, defStyleAttr) {
        this.mContentFrame = AspectRatioFrameLayout(context).apply {
            layoutParams = LayoutParams(
                LayoutParams.MATCH_PARENT,
                LayoutParams.MATCH_PARENT,
                Gravity.CENTER
            )
        }
        this.mSurfaceView = SurfaceView(context)
        mContentFrame.addView(mSurfaceView, 0)
        this.addView(mContentFrame)
    }

    fun setPlayer(player: Player) {
        if (mPlayer == null) {
            mPlayer = player
            player.addListener(playListener)
            if (player.isCommandAvailable(COMMAND_SET_VIDEO_SURFACE)) {
                player.setVideoSurfaceView(mSurfaceView)
            }
        }
    }

    fun resizeVideo(videoSize: VideoSize) {
        val width = videoSize.width
        val height = videoSize.height
        val ratio = if (width == 0 || height == 0) 0F else (width * videoSize.pixelWidthHeightRatio) / height
        mContentFrame.setAspectRatio(ratio)
    }

    inner class PlayListener : Player.Listener {
        override fun onVideoSizeChanged(videoSize: VideoSize) {
            super.onVideoSizeChanged(videoSize)
            resizeVideo(videoSize)
        }
    }

}
```