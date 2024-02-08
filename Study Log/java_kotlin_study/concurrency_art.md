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

YAML说明：

* 每一章的开头一定有title, order, chapter_root三个属性，并且chapter_root为true。其中order表示的是这个开头为第几章。比如下面的[[Study Log/java_kotlin_study/concurrency_art/3_jmm|3_jmm]]中的order就是3，表示这是第三章；如果一章的开头同时具有chapter属性，那么表示这一章只有这一个文件。比如[[Study Log/java_kotlin_study/concurrency_art/1_concurrency_challange|1_concurrency_challange]]和[[Study Log/java_kotlin_study/concurrency_art/2_concurrency_internal|2_concurrency_internal]]。此时order和chapter相等；
* 具体到每个文章，有title, chapter, order三个属性。其中chapter表示这个文章属于第几章，order表示这篇文章在当前章节下的顺序。不同章节中的文章的order没有大小关系。

# Java并发编程的艺术

```dataviewjs
let res = []
for (let page of dv.pages('"Study Log/java_kotlin_study/concurrency_art"')) {
	if (page.order != undefined && page.chapter_root == true) {
		const info = page.file.link + ": " + page.title
		const order = page.order
		res.push({info, order})
	}
}
res.sort(function(a, b) { return a.order - b.order })
dv.list(res.map(x => x.order + ": " + x.info))
```

```query
tag: #TODO 
path: "Study Log/java_kotlin_study/concurrency_art"
```