遇到什么问题？都是怎么解决的？这篇文章总结的全部都是这样的问题。其他文件中的问题会贴出 #block_and_conquer 的标签。

# 1 测试的时候无法定位问题

在蔚来实习的时候，初期跟着测试在车上体验我们业务的全流程。那个时候经常是我手上拿着手机，然后一旦出现了问题或者触发了某个逻辑，就立刻记录一下当前的时间，等测试结束后再发给相应的开发看那个时间的日志。但是久而久之我发现，如果仅仅是记录时和分的化，依然很难定位具体的时间点。于是我想开发了一个悬浮窗，能够实时更新当前的时间，直接精确到毫秒级。然后拿着另一台手机对着这台手机排视频，这样不管什么时候出现了问题，都能在100ms的误差内报告某个逻辑的时间点。

- [ ] #TODO WindowManager和更新UI

在开发悬浮窗的时候，我还顺便了解了[[WindowManager]]这个东西以及[[切换到主线程更新UI的方法]]。

#TODO ANR

- [x] ANR问题怎么解决的？

之后，我在自己的手机上也重新写了一个版本。但是让我意外的是，居然遇到了ANR问题。

![[Article/interview/resources/2c51e9e770fa49a34fa371f74c083cf.png]]

![[Article/interview/resources/ANR问题.png]]

这中间，我排查了很多原因。比如悬浮窗构建时Context到底要选什么？一开始我选的是Activity，后来又换成Service和Application；之后又在[这篇文章](https://blog.csdn.net/weixin_38322371/article/details/119185227)中发现，把悬浮窗的实例放在Service里，是需要在Service里用Handler来更新悬浮窗的UI的，然而我自己当时的设计是在悬浮窗内部更新UI，所以我也换成了这样的模式。之后，在公司的手机上测试，又发现了绘制的Frame的事件没有交付完毕的情况。所以我又思考下面的代码：

```kotlin
private val refreshTimeTask = object : Runnable {  
	override fun run() {  
		window.refreshTime()  
		mHandler.postDelayed(this, 1000)  
	}  
}
```

如果就这样放着的话，这个程序放在后台一段时间，悬浮窗被回收了，而这个绘制过程恰好正在进行，那不是就不会提交了吗！于是，我又搞了一个[[监听屏幕开关的Listener]]，当屏幕关闭时，就上一个锁，不更新UI，然后等屏幕亮了就把它打开并让Handler提交一次任务；除了这些，还考虑了是否应该用前台Service。。。

以上，**没有任何作用**！最终，是我把应用的省电策略调成不限制，就不会有ANR问题了。。。。。。。。。。。

# 2 按钮元素居中

有一个按钮：

![[Article/interview/resources/Drawing 2023-07-28 23.45.00.excalidraw.png]]

左边是一个加载的动画，中间是按钮的文字。这两个控件使用的都是公司的公控，而这个加载动画本身是一个ViewGroup（因为它们内部需要解决一些问题，所以才定义成了ViewGroup）。现在的需求是：

* 当加载动画不显示的时候，让文字居中；
* 当加载动画显示的时候，让文字和加载动画合在一起居中。

首先，为了做测试，我仅仅是把这个ViewGroup中的drawable拿了过来。

由于按钮内部本身已经定义好了一个drawText()方法用来画文字，所以为了不修改别人写的逻辑，我不能自己使用canvas来重绘。本来，最简单的方式是使用这个方法：

```kotlin
canvas.translate()
```

[android - What does canvas.translate do? - Stack Overflow](https://stackoverflow.com/questions/5789813/what-does-canvas-translate-do)

这样直接就把文字和加载动画一起带过来了。然而，由于公控的按钮有一个背景，这个背景在移动了之后，点击效果就会出现偏移。就像正常点击一个按钮时会出现阴影：

![[Article/interview/resources/Drawing 2023-07-28 23.52.04.excalidraw.png]]

如果使用了`canvas.translate()`，点击的时候就变成了这样：

![[Article/interview/resources/Drawing 2023-07-28 23.52.58.excalidraw.png]]

也就是左边的一块给拖出去了。而这个背景的重绘也是别人负责的；另外，由于需求方最后还是要这个Button对象，所以我也不能再自定义一个ViewGroup。所以，**我只能试图以最小的代价，最小的代码侵入性来实现这个需求**。最后的实现如下：

1. 将Button和加载动画的这个ViewGroup放到一个FrameLayout中；
2. 在button内部定义一个是否正在加载的状态，并设置监听；
3. **让加载动画也向Button注册一个监听，监听是否加载的状态**；
4. 当显示为加载时，首先调用加载动画的回调，让他绘制出自己，然后通过自己安插接口来获得它的长宽属性；
5. 然后在Button自己这里进行绘制。此时我们就可以拿到加载动画的各个属性了，根据自己的属性进行绘制，来确定横纵坐标；
6. 当状态为不加载时，让加载动画停止显示，再调用Button的drawText把自己在中间画出来就可以了。

通过这样的操作，既实现了需求，又没有修改别人的代码，并且最后返回的依然是原来的Button。美中不足就是只能配合FrameLayout使用了。最后，在重写onTouchEvent触摸的时候，当按下按钮的时候，只需要改变Button的加载状态，就可以自动触发这一系列任务了。

# 其它位置

```dataviewjs
let data = [];
for (let page of dv.pages("#block_and_conquer")) {
	let fileStr = await dv.io.load(page.file.path);
	let lines = fileStr.split('\n');
	let headers = "";
	for (let line of lines) {
		let hashCount = 0;
		if (line.match(/^#+\s/)) {
			hashCount += (line.match(/#/g) || []).length;
			headers += generateNestedList(hashCount, line.replace(/^#+\s/, ""));
		}
	}
	let fileLink = "[[" + page.file.path + "]]";
	headers = "<div style=\"border: 2px solid #D58E06; padding: 10px;\">" + headers + "</div>";
	data.push({fileLink, headers})
}
function generateNestedList(level, content) {
	if (level === 0) { 
		return content; 
	} 
	const nestedListContent = generateNestedList(level - 1, content); 
	return `<ul><li>${nestedListContent}</li></ul>`; 
}
dv.table(
	["File Name", "Headers"],
	data.map(d => [d.fileLink, d.headers])
);
```