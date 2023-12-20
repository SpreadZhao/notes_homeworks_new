---
title: RecyclerView剖析
chapter: "0"
order: "0"
hierarchy: "0"
---

```dataviewjs
let res = ""
const pages = dv.pages('"Study Log/android_study/recyclerview"')
pages.sort((a, b) => a.order - b.order)

for (let page of pages) {
	if (page.hierarchy == undefined || page.hierarchy <= 0) continue
	res += generateNestedList(Number(page.hierarchy), page.title)
}

dv.span(res)

function generateNestedList(level, content) {
	if (level <= 0) { 
		return content
	} 
	const nestedListContent = generateNestedList(level - 1, content); 
	return `<ul><li>${nestedListContent}</li></ul>`; 
}
```