---
num: "160"
title: "Intersection of Two Linked Lists"
link: "https://leetcode.cn/problems/intersection-of-two-linked-lists/"
tags:
  - leetcode/difficulty/easy
---
这道题一开始想思路其实很简单。既然想找两个链表的焦点，那么我们只需要：

- 遍历一个链表，从头到尾，并进行记录；
- 遍历另一个链表，看每一个节点是不是在之前的链表中出现过。

只要出现了，那么第一个出现的节点就是答案，如果一直没出现，那么返回null就好了。

我们不玩这个简单的。我们想一想更高级的思路。这里其实有一个公式，我们看这样的链表：

![[Projects/leetcode/resources/Drawing 2024-09-01 16.15.29.excalidraw.svg]]

我们把这两个链表的结构拆成这三部分。那么我们能得到：

- 遍历一遍第一个链表，走过的距离是`a + b`；
- 遍历一遍第二个链表，走过的距离是`c + b`。

我们会惊奇地发现：如果我们让两个链表一起走。当：

- 第一个链表到头时，从第二个链表开始；
- 第二个链表到头时，从第一个链表开始。

**那么我们会发现，会有这么一个时刻，两个指针走过的距离都是：`a + b + c`。其中**：

- 第一个指针先走了`a + b`，然后从第二个链表开始，再走了`c`；
- 第二个指针先走了`c + b`，然后从第一个链表开始，再走了`a`。

此时两个指针满足：`p1 == p2`。

因此，我们只需要一个循环，等两个指针相等的时候返回就可以了：

```cpp
ListNode *p1 = headA, *p2 = headB;
while (p1 != p2) {
	if (p1->next == nullptr) {
		p1 = headB;
	} else {
		p1 = p1->next;
	}
	if (p2->next == nullptr) {
		p2 = headA;
	} else {
		p2 = p2->next;
	}
}
return p1;
```

然后最开始再加上特殊情况处理：

```cpp
if (headA == nullptr || headB == nullptr) {
	return nullptr;
}
ListNode *p1 = headA, *p2 = headB;
while (p1 != p2) {
	if (p1->next == nullptr) {
		p1 = headB;
	} else {
		p1 = p1->next;
	}
	if (p2->next == nullptr) {
		p2 = headA;
	} else {
		p2 = p2->next;
	}
}
return p1;
```

看起来很好了吧。但是，结果超时了。。。

这是因为，如果两个链表完全没有相交的话，他们会一直走来走去，永远不会相等，自然就死循环了。

解决这个问题的办法有两个。第一个是，我们可以确定，**当第二次判断`p1`或者`p2`为空的时候，此时两个链表就一定不可能再相交了**。所以，我们可以设置一个标记位，判断是不是第二次为空：

```cpp
if (headA == nullptr || headB == nullptr) {
	return nullptr;
}
ListNode *p1 = headA, *p2 = headB;
int terminate = 0;
while (p1 != p2) {
	if (p1->next == nullptr) {
		p1 = headB;
		if (terminate > 0) {
			return nullptr;
		}
		terminate++;
	} else {
		p1 = p1->next;
	}
	if (p2->next == nullptr) {
		p2 = headA;
	} else {
		p2 = p2->next;
	}
}
return p1;
```

这个办法感觉有些不优雅。所以我们来个优雅的。

看我们目前的遍历方式，就以p1为例：

```cpp
if (p1->next == nullptr) {
	p1 = headB;
} else {
	p1 = p1->next;
}
```

我们发现，是当`p1->next == nullptr`的时候，我们就换另一个链表了。所以此时的迭代是**从一个链表的末尾变到另一个链表的头**，`p1`从来没有变成null过。

但是，我们如果看一个不相交的case：

![[Projects/leetcode/resources/Drawing 2024-09-01 16.28.16.excalidraw.svg]]

我们发现，如果是这种情况，也会有一个时刻，两个指针走过的距离都是`a + b`。具体就不说了，太简单。

既然会这样，那么肯定是两个指针一个指向5，另一个指向7。此时，如果再往前都走一步，两个指针都会指向null。所以，我们也可以利用这个时机去返回空。那么答案就很简单了，把刚刚的`p1->next == nullptr`换成`p1 == nullptr`就可以了。**我们需要让指针有机会指向空**：

```cpp
if (headA == nullptr || headB == nullptr) {  
    return nullptr;  
}  
ListNode *p1 = headA, *p2 = headB;  
while (p1 != p2) {  
    if (p1 == nullptr) {  
        p1 = headB;  
    } else {  
        p1 = p1->next;  
    }  
    if (p2 == nullptr) {  
        p2 = headA;  
    } else {  
        p2 = p2->next;  
    }  
}  
return p1;
```
