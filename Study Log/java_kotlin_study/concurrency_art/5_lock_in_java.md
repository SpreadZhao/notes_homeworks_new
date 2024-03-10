---
title: 5 Java中的锁
order: "5"
chapter_root: true
---

```dataviewjs
let res = []
for (let page of dv.pages('"Study Log/java_kotlin_study/concurrency_art"')) {
	if (page.chapter == 5) {
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