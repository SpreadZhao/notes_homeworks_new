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

#### 基础

- [x] RecyclerView首次加载的流程
- [x] RV滑动时布局的流程
- [ ] RV数据刷新时的流程
	- [x] 全量刷新
	- [ ] 局部刷新
		- [ ] 单线程
		- [ ] 多线程
- [ ] RV缓存的设计、用途
- [ ] RV离屏预渲染
	- [ ] 基本原理
	- [ ] 实现方法
	- [ ] 卡片可见性
	- [ ] bad case
		- [x] 手动滑-下一张detach
		- [x] 自动滑-下一张detach
- [ ] RV滑动帧率检测
- [ ] RV异步加载
	- [x] 学会使用AsyncLayoutInflater
	- [x] 学会使用AsyncListUtil
	- [ ] 自己实现异步预加载
	- [ ] 子View的异步measure
- [ ] Diff异步计算
- [ ] 其实是RecyclerView包里的所有东西

#### 开发

- [x] 改造视频起播UI
- [ ] #date 2024-02-15 下一步：
	- [ ] #urgency/high 分析视频prepare耗时；
	- [ ] #urgency/high 看能不能同时装载两个视频，实现播放当前视频时，对下个视频进行prepare
- [ ] 做出来播控