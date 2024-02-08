---
title: RecyclerView初学
order: "1"
chapter: "1"
hierarchy: "1"
---

# 1 RecyclerView初见

归根结底，RecyclerView也是个View。所以我们依然从它的measure，layout，draw流程说起。**本流程只涉及RecyclerView首次加载的时候的流程，也就是你的手不允许放在屏幕上滑来滑去！**

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