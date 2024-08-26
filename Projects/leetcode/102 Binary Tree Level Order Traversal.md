---
num: "102"
title: "Binary Tree Level Order Traversal"
link: "https://leetcode.cn/problems/binary-tree-level-order-traversal/description/"
tags:
  - leetcode/difficulty/medium
---
层序遍历之前我们早就已经介绍过了：[[Projects/leetcode/226 Invert Binary Tree#层序遍历复习|226 Invert Binary Tree]]。~~那个介绍的思想比这整道题都多~~。

好吧，我是傻逼。为什么这么简单的题我都想了这么久。之前的那个做法，虽然输出的序列是层序遍历，但是没有层数信息。这里最重要的问题就是我们怎么记住一个节点是哪层的。那么，看看我们之前的代码：

```cpp
void CommonUtil::traverseTreeByDepth(const TreeNode *root) {
    queue<const TreeNode*> nodes;
    nodes.push(root);
    while (!nodes.empty()) {
        const TreeNode *node = nodes.front();
        nodes.pop();
        cout << node->val << " ";
        if (node->left != nullptr) {
            nodes.push(node->left);
        }
        if (node->right != nullptr) {
            nodes.push(node->right);
        }
    }
}
```

这里，哪个信息能表明节点是哪层的？似乎，只有在if块里push的，是下一层的节点。但是**我们在这次while循环里pop出来的节点是哪层的，并没有进行控制**。

所以需要进一步研究：

1. 我们发现，如果树不是空的，那么至少会有一个跟节点；
2. 在第一次while循环中，**我们放入的节点正好是第二层的全部节点，一定是**。

正是因为这第二个条件，我们才有机会在这个循环里进行控制。在遍历完跟节点后，我们将它pop出去，然后把根节点的左右孩子放到队列中（如果有）。所以，**在第一次while循环之后，队列中的值一定是第一层（从0开始）的全部节点**。

所以，我们在这个while循环里再进行一次控制，每一次while循环里，都需要将当前层里所有的节点都拿出来，并将这些节点的所有孩子再次放入到队列中。

> [!attention]
> 注意这里的改动。
> 
> - 改动前：每一次while循环，处理队头的节点，将**它**的孩子放到队列中；
> - 改动后：每一次while循环，处理队列中所有的节点（正好是当前层的所有节点），将**它们**的孩子放到队列中。

正是上面的第二个条件，保证了在每一次的while循环中，队列里的节点一定是当前层的节点。

那么怎么改呢？很简单，既然每次while循环刚进入的时候，队列里所有的节点都是同一层的，并且全部就位，那么我们只需要再用一个for循环遍历一下这些节点就好了：

```cpp
// 在while循环中的代码
// nodes: 之前的那个队列
int currLevelSize = nodes.size();
for (int i = 0; i < currLevelSize; i++) {
	auto node = nodes.front();
	nodes.pop();
	// 拿到node，可以进行遍历，或者其它操作，这个for循环内，保证所有node属于同一层。
	if (node->left) { nodes.push(node->left); }
	if (node->right) { nodes.push(node->right); }
}
```

结合题目的要求，我们拿到node之后，只需要放到对应level的vector中就行了。并且还有一点，这里如果我们在for循环之前插入一个新的vector到结果队列中的队尾，那么这个vector就会是当前level的集合：

```cpp
vector<vector<int>> Solution::levelOrder(TreeNode *root) {
    vector<vector<int>> res;
    if (root == nullptr) {
        return res;
    }
    queue<TreeNode*> nodes;
    nodes.push(root);
    while (!nodes.empty()) {
        int currLevelSize = nodes.size();
        res.emplace_back();  // 当前level对应的集合
        for (int i = 0; i < currLevelSize; i++) {
            auto node = nodes.front();
            nodes.pop();
            res.back().emplace_back(node->val);  // 插入到当前level对应的集合
            if (node->left) { nodes.push(node->left); }
            if (node->right) { nodes.push(node->right); }
        }
    }
    return res;
}
```