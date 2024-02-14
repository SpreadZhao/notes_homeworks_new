---
title: 4.4 线程池初见
chapter: "4"
order: "4"
---
## 4.4 线程池初见

```ad-info
这里书上本来是“线程应用实例”。感觉其它的都没啥说的必要，唯一一个手搓一个简单线程池的这块还不错。
```

- [ ] #TODO c的线程池是不是也该快了？

线程池的根本好处是，当你需要线程去执行任务时，直接丢到池子里就行。当有线程能干你这个活儿的时候，它就去了。这样我们可以用少量的几个线程去重复利用。这样就不用一直构建和销毁线程。




---

```dataviewjs
const pages = dv.pages('"Study Log/java_kotlin_study/concurrency_art"')
let nextChapterHead = undefined
let res = undefined
const current = dv.current()
for (let page of pages) {
	if (page.chapter_root == true && page.order == Number(current.chapter) + 1) {
		console.log("found next head: " + page.name)
		nextChapterHead = page
		continue
	}
	if (page.chapter == undefined || page.chapter != current.chapter) {
		console.log("not current chapter: " + page.file.name)
		continue
	}
	if (page.order == Number(current.order) + 1) {
		res = page
	}
}
console.log("res: " + res)
console.log("next: " + nextChapterHead)
if (res == undefined) {
	res = nextChapterHead
}
let text = ""
if (res != undefined) {
	const path = res.file.path
	const title = res.title
	const decoLink = "[[" + path + "|" + title + "]]"
	text = "Next Article: " + decoLink
} else {
	text = "旅途的终点！"
}
dv.el("p", text, { attr: { align: "right" } })
```