---
title: 1.2 layout
chapter: "1"
order: "3"
hierarchy: "2"
---
## 1.2 layout

RecyclerView最关键的地方就是layout了。这里涉及的就是对Adapter的消费，布局其中的子item，以及回收，缓存等特性应用的地方。layout操作的整个流程在方法dispatchLayout()中，里面的流程分为三步。而这三步也并不都是由dispatchLayout()发起的。我们可以查找一下调用点，能得到：

* step1会由onMeasure()和dispatchLayout()调用；
* step2会由onMeasure()和dispatchLayout()调用；
* step3会只会由dispatchLayout()调用。

这三步所做的事情如下：

* step1
	* process adapter updates
	* decide which animation should run 
	* save information about current views 
	* If necessary, run predictive layout and save its information
* step2: do the **actual layout** of the views for the final state. This step might be run multiple times if necessary (e.g. measure).
* step3: save the information about views for animations, trigger animations and do any necessary cleanup.

以上是注释的原文。可以看到，第一步主要是将adapter的修改全部处理。比如我notifyItemInserted()，那么你就要去处理这个新加入的元素，将其中的状态改变，等待布局流程；第二步就是对这些修改过的流程进行**真正布局**。其中的"final state"其实就是指第一步的产出。另外，最后也说明了如果有必要，这一步会执行多次，比如在measure的流程中；第三步主要处理的是动画。关于动画比较独立，所以初见不会过多涉及到。

我们将非常详细地逐一解释其中的每一句代码，并在这个流程中补充一些RecyclerView的设计概念。

```dataviewjs
let res = []
const pages = dv.pages('"Study Log/android_study/recyclerview/1_start"')
for (let page of pages) {
	if (isSubHierarchy(page.hierarchy)) {
		const title = page.title
		const link = page.file.link
		const order = page.order
		res.push({title, link, order})
	}
}
function isSubHierarchy(hierarchy) {
	if (hierarchy == undefined) return false
	let targetHier = Number(hierarchy)
	let currHier = Number(dv.current().hierarchy) + 1
	return targetHier == currHier
}
res.sort((a, b) => a.order - b.order)
dv.list(res.map(x => x.title + ": " + x.link))
```