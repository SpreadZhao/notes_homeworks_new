---
title: 并发编程基础
order: "4"
chapter_root: true
---

## 4 并发编程基础

```dataviewjs
let res = []
for (let page of dv.pages('"Study Log/java_kotlin_study/concurrency_art"')) {
	if (page.chapter == 4) {
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