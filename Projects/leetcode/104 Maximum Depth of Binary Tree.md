---
num: "104"
title: "Maximum Depth of Binary Tree"
link: "https://leetcode.cn/problems/maximum-depth-of-binary-tree/description/"
tags:
  - leetcode/difficulty/easy
---

# 题解

说实话，这题不应该是easy，虽然看起来很简单。但是我想了好久没思路。当然层序遍历这个挺好想，但是我就是想一个直接遍历就能往最深走的办法。但是没有。。。

看了题解之后，有两种思路。一个个说：

1. 不断往深走。树的最大深度，其实就是**左子树的最大深度，和右子树的最大深度的最大值**。而这个递归一直往下走，走到头就是这棵（子）树只有一个节点，所以此时的它“贡献”的深度就是1。
2. 层序遍历。每到一层，cover当前层的每一个节点，并尝试把它们的孩子也加进来。每到一层就+1就行。这个最简单，完全等于层序遍历+深度记录。

## DFS

思想已经很明确了，代码也很简单。不过这里有几个小点需要明确：

1. 对于当前节点，我自己贡献的深度就是1；
2. “我”和“我”的子树贡献的节点，需要加起来，不断向上传递；
3. 当传递到根节点时，结果就是根节点贡献的深度（1）和根节点的子树贡献的深度。它们的和就是最终的答案。

举个例子：

![[Projects/leetcode/resources/Drawing 2024-09-21 21.25.38.excalidraw.svg]]

所以核心代码：

```cpp
int depth = 1; // 当前节点贡献的深度——1
depth += max(maxDepth(root->left), maxDepth(root->right));  // 做子树和右子树的最大值为子树贡献的深度
```

最后：

```cpp
int Solution::maxDepth(TreeNode *root) {
    if (root == nullptr) {
        return 0;
    }
    if (root->left == nullptr && root->right == nullptr) {
        return 1;
    }
    int depth = 1;
    depth += max(maxDepth(root->left), maxDepth(root->right));
    return depth;
}
```

## BFS

复习一下层序遍历：[[Projects/leetcode/102 Binary Tree Level Order Traversal|102 Binary Tree Level Order Traversal]]。这里重要的其实还是每一层的“控制”。必须在当前循环中，把这一层的所有节点都遍历到。

```cpp
int Solution::maxDepth2(TreeNode *root) {
    if (root == nullptr) {
        return 0;
    }
    queue<TreeNode*> q;
    q.push(root);
    int depth = 0;
    while (!q.empty()) {
        depth++;
        const size_t size = q.size();
        for (size_t i = 0; i < size; i++) {
            TreeNode *curr = q.front();
            if (curr->left != nullptr) {
                q.push(curr->left);
            }
            if (curr->right != nullptr) {
                q.push(curr->right);
            }
            q.pop();
        }
    }
    return depth;
}
```

只能说，除了depth变量的控制，剩下的和正常的层序遍历一点区别没有。
