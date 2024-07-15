---
num: "101"
title: Symmetric Tree
link: https://leetcode.cn/problems/symmetric-tree/description/
tags:
  - leetcode/difficulty/easy
---

这道题要求我们判断一棵二叉树是否为镜像的（以根结点为对称轴，左右子树对称）

这道题让我想起了之前写的一道InvertBinaryTree的题目，那道题要求我们把一个二叉树反转过去，如下图所示：

![[Projects/leetcode/resources/Drawing 2023-03-21 14.38.35.excalidraw.png]]

我们把InvertBinaryTree的算法应用到本题中，如果我们把原二叉树反转过去之后，还能得到这棵树本身，不就能说明这棵树是镜像的了吗

1. 把原本的二叉树复制出一个副本保存下来
2. 反转原本的二叉树
3. 比较原本的二叉树与反转后的二叉树

第一步很简单，先序遍历将每个结点存到一个新二叉树中即可

第二步也是一样的思想，先序遍历对调每个结点的左右孩子

第三步就是最关键的比较，首先定义一个flag用来表示比较的结果，初值为true。然后依旧是先序遍历，如果两树相同位置的值不相等或一边有值而另一边为空，就将flag赋false。这里有一个问题，为什么我们需要定义一个flag而不是直接返回true/false的结果呢？因为二叉树的比较涉及了遍历，我们需要