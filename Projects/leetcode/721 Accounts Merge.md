---
num: "721"
title: "Accounts Merge"
link: "https://leetcode.cn/problems/accounts-merge/description/"
tags:
  - leetcode/difficulty/medium
---
本题的解决思路是哈希表+并查集。因此先给出并查集的一些基础知识。

# 并查集

[01. 并查集知识 | 算法通关手册（LeetCode） (itcharge.cn)](https://algo.itcharge.cn/07.Tree/05.Union-Find/01.Union-Find/)

并查集是一个树。传统我们写一个树，比如用数组，都是用父节点的编号，获得儿子节点的编号：[[Homework/Algorithm/practice1#3.2 Priority Queue|practice1]]。但是并查集不一样，它是用**子节点指向父节点**。比如有一棵树是这样的：

![[Projects/leetcode/resources/Drawing 2024-07-21 02.16.12.excalidraw.svg]]

那么这个节点的数组应该是这样设计的：

| ... | 4   | 5   | 6   | 7   |
| --- | --- | --- | --- | --- |
| ... | 5   | 7   | 7   | 7   |

根节点指向自己，这样我们通过判断这个数组的编号和值相等就能判断出是否是根节点。

另外，这个数组的特点就是，index是节点本身，value是index的父节点。所以这个数组通常叫`parent`。

并查集一开始都是单独的元素。比如集合里一共有8个元素，那么一开始数组里就是：

| 0   | 1   | 2   | 3   | 4   | 5   | 6   | 7   |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0   | 1   | 2   | 3   | 4   | 5   | 6   | 7   |

每个index的父亲都指向自己，代表现在一共有8棵树，每棵树只有一个节点，它们都是根节点，所以`parent[index] = parent`。

代码如下：

```cpp
UnionFind::UnionFind(int n) {
    parent.resize(n);
    for (int i = 0; i < n; i++) {
        parent[i] = i;
    }
}
```

然后我们还是说个简单的，寻找元素。假设现在因为某些情况，这个并查集已经变成了这样：

![[Projects/leetcode/resources/Drawing 2024-07-21 02.26.34.excalidraw.svg]]

那数组就是这样的：

| 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1   | 2   | 3   | 5   | 7   | 7   | 7   | 8   |

有个函数叫find，那么对4，5，6，7调用find的结果应该都是7。所以思路就是，一直找，直到找到根节点为止。那么什么是根节点呢？我们刚刚说过，`parent[index] == index`就是。因此代码：

```cpp
int UnionFind::find(int index) {
    while (parent[index] != index) {
        index = parent[index];
    }
    return index;
}
```

最后是合并。其实合并才是并查集的核心功能。而且，并查集和树其实没有必然关系。也就是说，并查集可以不用树来实现。我们来看看并查集的核心操作：并。有个函数叫union，接受两个index。经过union之后，**两个index所属的集合**就被并到一块了。还是一开始的8棵树，现在如果我要调用`union(4, 5)`，结果就是：

$$
0, 1, 2, 3, \{4, 5\}, 6, 7
$$

然后我调用`union(6, 7)`，结果就是：

$$
0, 1, 2, 3, \{4, 5\}, \{6, 7\}
$$

最后调用`union(4, 6)`**或者**`union(4, 7)`或者。。。，反正是两个集合里的元素，结果就是：

$$
0, 1, 2, 3, \{4, 5, 6, 7\}
$$

union才是并查集的核心功能，find只是帮助你找它在哪个集合里。所以这里我们用树实现比较快。

要合并两棵树，我们只需要把一棵树的根节点指向另一棵树的根节点：

```cpp
void UnionFind::unionSet(int index1, int index2) {
    int root1 = find(index1);
    int root2 = find(index2);
    parent[root1] = root2;
}
```

有了这些功能，其实我们就已经可以开始做这道题了。所以剩下的内容（比如路径压缩等）就先不展开了，接下来再说。

# 思路

