---
num: "109"
title: Convert Sorted List to Binary Search Tree
link: https://leetcode.cn/problems/convert-sorted-list-to-binary-search-tree/description/
tags:
  - leetcode/difficulty/medium
---

这道题要求我们将一个排好序的链表转换为二叉搜索树，为了达成平均搜索次数最小的目的，二叉搜索树要求我们尽可能将每一层的结点填充得最为充实，即**它的任何两棵子树层数差都不超过1**，拥有$2^n-1$个结点的二叉搜索树搜索到目标结点最多只需要搜索n次

参考Solution，运用**分治**的思想，我们需要五步来实现这个算法：

1. 将数组的中间元素设置为根结点
2. 递归地对左半部分和右半部分做同样的事
3. 获取左半部分的中间元素，并使其成为步骤一中创建的根的左孩子
4. 获取右半部分的中间元素，并使其成为步骤一中创建的根的右孩子
5. 先序输出这棵树

在进行递归之前，因为链表不支持随机访问，所以我们需要把它的值按顺序拿出来放入一个允许随机访问的有序数组中

然后开始递归，以Example 1为例，这个数组的中间元素是0，那么0就是这棵树的根结点。如果数组总共有四个元素，那么我们选择第三个元素作为树的根结点（index=size/2，除法默认舍尾）

0的左半边为\[-10,-3\]，中间元素为-3，将其作为0左子树的根结点；-3的左半边为\[-10\]，只有一个元素，-10的左右半边皆为空，将其看成中间元素，作为-3左子树的根结点，返回根结点-10；-3的右半边为空，返回根结点-3

0的右半边为\[5,9\]，中间元素为9，将其作为0右子树的根结点；9的左半边为\[5\]，只有一个元素，5的左右半边皆为空，将其看成中间元素，成为9左孩子的根结点，返回根结点5；9的右半边为空，返回根结点9

最后返回根结点0，至此二叉搜索树就建好了

