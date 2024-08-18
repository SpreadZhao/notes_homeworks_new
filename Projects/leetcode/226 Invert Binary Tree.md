---
num: "226"
title: "Invert Binary Tree"
link: "https://leetcode.cn/problems/invert-binary-tree/description/"
tags:
  - leetcode/difficulty/easy
---
这个题其实很好想，但是顺带着，我把树的层序遍历复习了一遍。甚至还搞了用层序遍历的输入来build一棵树。

# 思路

思路其实很简单：

![[Projects/leetcode/resources/Drawing 2024-08-17 01.34.28.excalidraw.svg]]

我们其实可以发现，对于任意一个根节点，将它们的左右孩子互换，就可以让底下所有的节点一起换。换言之，就是**交换了两个子树**：

![[Projects/leetcode/resources/Drawing 2024-08-17 01.37.49.excalidraw.svg]]

所以，只要我们给所有有孩子的节点进行一下这个操作，其实整棵树就已经交换了。代码非常好写：

```cpp
TreeNode *Solution::invertTree(TreeNode *root) {
    if (root == nullptr) {
        return root;
    }
    // 交换两颗子树
    TreeNode *temp = root->left;
    root->left = root->right;
    root->right = temp;
    // 对左右孩子也递归
    invertTree(root->left);
    invertTree(root->right);
    return root;
}
```

对于上面的例子，接下来就是交换6和9，还有1和3。

# 层序遍历复习

接下来，复习一下层序遍历。所谓层序，当然就是一排排输出。**层序遍历的思想起源于BFS**。每遍历到一个节点，接下来要遍历的就是**离这个节点最近的所有节点**。而在树中，最近的当然就是它的孩子们。

层序遍历使用队列。因为队列具有FIFO的性质，所以只要我们能按顺序将这些节点入队，那么出队的顺序就一定能够保证。具体的步骤如下：

1. 根节点入队；
2. 根节点出队（遍历到），并试图将它的左右孩子入队，先左后右；
3. 每次从队列里取出一个节点，取出代表出队，代表遍历到。这个时候将这个节点的左右孩子按顺序入队。

这个方法的其实点在于队列中一开始的三个节点：根节点和它的两个孩子：

![[Projects/leetcode/resources/Drawing 2024-08-17 01.49.49.excalidraw.svg]]

在一开始的时候，当4出队时，2和7在队列里，**正好是这个树中前两层的全部节点**。当开始遍历2和7的时候，**其实我们在做的事情，就是把第三层的节点按顺序入队**。而当2和7都出队后，队列里就只剩下第三层的节点。依次进行下去……

总之，**当我们逐一操作队列中第n层的节点时，就是在遍历第n层的节点的同时，将第n+1层的节点按照顺序入队**。这就是层序遍历的核心思想。

所以逻辑也很简单：

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

# 按照层序序列构建树

反过来怎么办？这道题的输入就是这样的。这里我给一个最简单的实现，然后再想别的办法。

按照数组排序。如果根节点编号是1，那么对于任意一个节点$i$，它的左孩子就是$i \times 2$，它的右孩子就是$i \times 2 + 1$。

因此直接给出代码：

```cpp
TreeNode *CommonUtil::buildTreeByDepth(const int nodes[], const int size) {
    TreeNode *nodesP[size + 1];
    for (int i = 1; i < size + 1; i++) {
        nodesP[i] = new TreeNode(nodes[i - 1]);
    }
    for (int i = 1; i <= size / 2; i++) {
        const int leftIndex = i * 2;
        const int rightIndex = i * 2 + 1;
        if (leftIndex <= size) {
            nodesP[i]->left = nodesP[leftIndex];
        }
        if (rightIndex <= size) {
            nodesP[i]->right = nodesP[rightIndex];
        }
    }
    return nodesP[1];
}
```

- [ ] #TODO tasktodo1723831166787 有没有类似BFS的办法通过层序序列构建二叉树？ ➕ 2024-08-17 🔼 🆔 0qnjv6
