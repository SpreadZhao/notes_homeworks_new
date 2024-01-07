---
tags:
  - language/coding/java
  - language/coding/kotlin
link: https://github.com/SpreadZhao/KotlinStudy
description: Java并发编程艺术的读书笔记。
title: Concurrency Art Notes
---

ref

* [Java | Multithreading Part 1: Java Memory Model | by MrAndroid | Medium](https://medium.com/@MrAndroid/java-multithreading-part-1-java-memory-model-fb8e0cfab9d3)

# Java并发编程的艺术

```dataviewjs
let res = []
for (let page of dv.pages('"Study Log/java_kotlin_study/concurrency_art"')) {
	if (page.order != undefined && page.chapter == undefined) {
		const info = page.file.link + ": " + page.title
		const order = page.order
		res.push({info, order})
	}
}
res.sort(function(a, b) { return a.order - b.order })
dv.list(res.map(x => x.order + ": " + x.info))
```