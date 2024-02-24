---
title: Java内存模型
order: "3"
chapter_root: true
---
## 3 Java内存模型

```dataviewjs
let res = []
for (let page of dv.pages('"Study Log/java_kotlin_study/concurrency_art"')) {
	if (page.chapter == 3) {
		const link = page.file.link
		const title = page.title
		const order = page.order
		const info = link + ": " + title
		res.push({info, order})
	}
}
res.sort((a, b) => a.order - b.order)
dv.list(res.map(x => x.info))
```