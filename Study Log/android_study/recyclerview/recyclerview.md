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

#TODO 

- [ ] UpdateOp Pool的设计（acquire）
- [ ] 为什么更新队列要分为pending和postponed？这个问题要从op的**consume**过程入手。
- [ ] adapter，adapterHelper，recyclerView的关系。mCallback就是adapterHelper需要的RecyclerView的能力。淦，感觉这个Callback的实现和ATMS里那个LifeCycle实在是太像了。
- [ ] 关于triggerUpdateProcessor()，看看什么情况下会走下面的分支。
- [ ] ExtendLinearLayoutManger
- [ ] decorate和自己设置margin，这两种的性能比较