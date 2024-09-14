---
num: "235"
title: "Lowest Common Ancestor of a Binary Search Tree"
link: "https://leetcode.cn/problems/lowest-common-ancestor-of-a-binary-search-tree/description/"
tags:
  - leetcode/difficulty/medium
---

# 题解

## 傻逼版

我一开始还是想的最简单的做法：

- 先找一个节点，用一个集合记录下来寻找过程中的每一个节点；
- 再找另一个节点。一开始应该会有一样的路径。当发现第一个不一样的节点的时候，那么之前的那个就是两个节点的最近公共祖先。

看着很简单。但是中间有很多问题。

首先，我们从跟节点开始，寻找p节点：

```cpp
TreeNode *curr = root;
int target = p->val;
set<TreeNode *>route;
while (curr->val != target) {
	route.insert(curr);
	if (curr->val < target) {
		curr = curr->right;
	} else {
		curr = curr->left;
	}
}
```

当跳出来的时候，curr就应该指向p节点了。而route里面也包括了寻找路线中所有的节点。但是要注意，这里route不包括curr节点本身。所以这是我漏的第一个case：[[#没记全？]]

接下来，我们开始找第二个节点。方法是一样的，同一个循环。但是要注意这里有两种情况：

1. 在循环中，发现route中已经不包含curr节点了。这个时候就应该是已经开始分叉了。所以往回倒一个就是分叉的位置，及最近公共祖先；
2. 如果最终跳出了while循环，代表我们已经找到了q节点。此时curr就指向q节点。同时，这个过程中，一直都包含在找p的路径里。所以这种情况下p和q应该在同一条线上。

对于第一种情况，我们需要引入一个prev指针。总是指向curr的前一个。当一样的时候就返回：

```cpp
curr = root;
TreeNode *prev = nullptr;
target = q->val;
while (curr->val != target) {
	if (!route.count(curr)) {
		// curr不在找p路径里，所以应该已经分叉了。
		// 此时prev指向的就是最后一个没分叉的地方。
		return prev;
	}
	prev = curr;
	if (curr->val < target) {
		curr = curr->right;
	} else {
		curr = curr->left;
	}
}
```

对于第二种情况，已经跳出了循环。所以我们应该返回什么呢？我们在遗漏的地方说：[[#你真是个傻逼]]

最终代码：

```cpp
TreeNode * Solution::lowestCommonAncestor(TreeNode *root, TreeNode *p, TreeNode *q) {
    TreeNode *curr = root;
    int target = p->val;
    set<TreeNode *>route;
    while (curr->val != target) {
        route.insert(curr);
        if (curr->val < target) {
            curr = curr->right;
        } else {
            curr = curr->left;
        }
    }
    route.insert(curr);
    curr = root;
    TreeNode *prev = nullptr;
    target = q->val;
    while (curr->val != target) {
        if (!route.count(curr)) {
            return prev;
        }
        prev = curr;
        if (curr->val < target) {
            curr = curr->right;
        } else {
            curr = curr->left;
        }
    }
    if (route.count(curr)) {
        return curr;
    }
    return prev;
}
```

## 牛逼版

这个在题解里叫一次遍历。思想非常简单，就是放到一起去看。

既然两个节点一开始的路径都是一样的，那么在一开始的遍历中，**我无论是找p还是找q，指针的移动应该都是一样的**！也就是说，找p如果往左去，那么找q也要往左去。

那么一旦p和q想去的地方不一样了，那么就是分叉了！那此时直接把当前节点就返回就行了！好吧，看了这个，感觉我更他妈像傻逼了。

```cpp
TreeNode * Solution::lowestCommonAncestor2(TreeNode *root, TreeNode *p, TreeNode *q) {
    TreeNode *curr = root;
    while (true) {
        if (curr->val < p->val && curr->val < q->val) {
            curr = curr->right;
        } else if (curr->val > p->val && curr->val > q->val) {
            curr = curr->left;
        } else {
            break;
        }
    }
    return curr;
}
```

# 遗漏的case

## 没记全？

我一开始的代码是：

```cpp
TreeNode *curr = root;
int target = p->val;
set<TreeNode *>route;
while (curr->val != target) {
	route.insert(curr);
	if (curr->val < target) {
		curr = curr->right;
	} else {
		curr = curr->left;
	}
}
curr = root;
TreeNode *prev = nullptr;
target = q->val;
while (curr->val != target) {
	if (!route.count(curr)) {
		return prev;
	}
	prev = curr;
	if (curr->val < target) {
		curr = curr->right;
	} else {
		curr = curr->left;
	}
}
return nullptr;
```

当然后面就不用看了，错的一塌糊涂。我们只看这个case：

```
root = [6, 2, 8, 0, 4, 7, 9, null, null, 3, 5]
p = 2, q = 4
```

其实就是这样一棵树：

![[Projects/leetcode/resources/Drawing 2024-09-14 23.32.15.excalidraw.svg]]

他俩的最近公共祖先应该是2。那么问题就是。我先找2，路径是啥？因为我没包含最后一个节点，所以应该只有6。那么我之后找4的时候，我会发现，第一个不存在于route的节点居然是2。这就导致，prev指向的还是6，就被返回了。

这里根本的问题就在于：**当寻找p的时候，p本身也应该在route里面**。所以如果p节点本身就是分叉的话，那route里没有p，不就出问题了？所以，加上这一句： ^24b89b

```cpp
TreeNode *curr = root;
int target = p->val;
set<TreeNode *>route;
while (curr->val != target) {
	route.insert(curr);
	if (curr->val < target) {
		curr = curr->right;
	} else {
		curr = curr->left;
	}
}
// p本身也是route的一部分。
route.insert(curr);
curr = root;
TreeNode *prev = nullptr;
target = q->val;
while (curr->val != target) {
	if (!route.count(curr)) {
		return prev;
	}
	prev = curr;
	if (curr->val < target) {
		curr = curr->right;
	} else {
		curr = curr->left;
	}
}
return nullptr;
```

## 你真是个傻逼

我一开始的代码真就是向刚才上面那样，跳出循环了就返回空了。可能是因为我烫头发上的氨味儿熏得脑子不好使了。然后我一想不太对啊，是不是得返回点东西？所以我就返回一个prev。随便返回的，真的，我一点都没思考。完全没想过几天前的那个：[[Projects/leetcode/3 Longest Substring Without Repeating Characters#^7a2ff0|3 Longest Substring Without Repeating Characters]]。这个其实是类似的：

> [!important]
> 当你的循环退出的时候，好好想想循环退出之后，用于迭代的变量现在是什么状态。如果你还需要使用这个变量，好好想想它可能处于什么状态。比如这里，循环里面是curr，那退出循环就代表找到了。所以curr就指向了q节点。那么q节点处于什么状态？比如，**它他妈在route里吗**？
> 
> 除此之外，还有特殊的循环过程。最常见的就是，如果循环根本没走就直接退出了。好好想想，你的case里面会不会有这种情况，如果有，应该怎么处理？

从上面的总结，应该也能看出来了。这里的漏了两个地方：

看这个case：

```
root = [2, 1]
p = 1, q = 2
```

![[Projects/leetcode/resources/Drawing 2024-09-14 23.28.38.excalidraw.svg]]

先找p，找完之后route是2和1。然后找q。从2开始。诶呀？！找到了！那咋办，**一次while循环都没走直接退出了**。那这个时候，我应该返回啥？是不是就应该返回2。所以这里需要返回curr：

```cpp
if (prev == nullptr) {
	return curr;
}
```

另一个case：

```
root = [5, 3, 6, 2, 4, null, null, 1]
p = 1, q = 3
```

![[Projects/leetcode/resources/Drawing 2024-09-14 23.52.42.excalidraw.svg]]

先找1，route是5 3 2 1。然后找3。找到3了退出。那么这个时候，prev指向谁？5。curr指向谁？3。我应该返回谁？curr。但是，我有没有可能返回prev？当然也有可能。什么时候？如果route里不包含3，比如我找的是6，那么退出来的时候curr指向6，prev指向5。这个时候我就应该返回5了。

总结下来就是：退出循环后，我还要看curr是否包含在route。因为除了curr节点，其他的节点是在while循环里面判断的，而curr没看。而和[[#^24b89b|之前所说]]一样，**curr也应该是找q的路线中的一部分**。

代码：

```cpp
if (route.count(curr)) {
	return curr;
}
return prev;
```

然后，我们发现，如果prev是空的话，curr一定是root。而`route.count(root)`一定是true。所以之前的那个case可以用这个顶掉。