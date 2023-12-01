---
title: RecyclerView初学
order: "1"
---
#TODO 

- [ ] UpdateOp Pool的设计（acquire）
- [ ] 为什么更新队列要分为pending和postponed？这个问题要从op的**consume**过程入手。
- [ ] adapter，adapterHelper，recyclerView的关系。mCallback就是adapterHelper需要的RecyclerView的能力。淦，感觉这个Callback的实现和ATMS里那个LifeCycle实在是太像了。

# RecyclerView初见

虽然我不是初见了。但是为了