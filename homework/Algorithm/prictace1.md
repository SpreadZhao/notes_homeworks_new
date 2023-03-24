# 1. 实验题目

## 1.1 Two Sum

Design and implement a $\Theta(nlogn)$time algorithm that, given a set S of n integers and another integer x, determines whether or not there exist two elements in S whose sum is exactly x.

## 1.2 Priority Queue

Implement **priority queue.**

## 1.3 Quick Sort

Implement Quicksort and answer the following questions. 

1. How many comparisons will Quicksort do on a list of _n_ elements that all have the same value?
2. What are the maximum and minimum number of comparisons will Quicksort do on a list of _n_ elements, give an instance for maximum and minimum case respectively.

## 1.4 Median of Two Sorted Arrays

Give a divide and conquer algorithm for the following problem: you are given two sorted lists of size $m$ and $n$, and are allowed unit time access to the ith element of each list. Give an $O(lg m + lgn)$ time algorithm for computing the kth largest element in the union of the two lists. (For simplicity, you can assume that the elements of the two lists are distinct).

# 2. 实验目的

掌握快速排序，优先级队列，双指针，分治等技术点。

# 3. 实验设计与分析

## 3.1 Two Sum

本题的要求时间复杂度是$\Theta(nlogn)$，并且题目要求和[leetcode第一题](https://leetcode.com/problems/two-sum/)是一样的。在leetcode的Solution中，有比这个要求更加快的算法，甚至达到了线性时间。如果只是要求$\Theta(nlogn)$的话，我们可以使用**任何复杂度为此的排序算法先将输入序列进行排序**，如归并排序，快速排序等等；之后再使用**双指针**策略对排好序的序列进行遍历，这样双指针部分在整个算法中作为非主导条件时间复杂度被忽略，因此整体的复杂度正是$\Theta(nlogn)$：

```cpp
bool SortHelper::sumToTarget(vector<int> nums, int target){   
    QuickSort(nums);  

	/* Double pointer stategy */
	... ...
}
```

首先是快速排序的实现，这部分直接。

然后是双指针策略的代码。这部分比较简单，每次算出两个指针指向值的和，如果正好就是`target`，返回即可；如果比它小，那代表小指针拖了后腿，因此小指针长高；反之大指针变矮：

```cpp
bool SortHelper::sumToTarget(vector<int> nums, int target){  
    QuickSort(nums);  
    auto i = nums.begin(), j = nums.end();  
    j--;  
    while(i < j){  
        int sum = *i + *j;  
        if(sum == target) return true;  
        if(sum < target) i++;  
        else j--;  
    }  
    return false;
}
```

## 3.2 Priority Queue

优先级队列并不像是队列，更像是一个大顶堆或者小顶堆。这种结构最简单的实现方式，就是牺牲`enqueue`和`dequeue`这两者之一的效率。比如我们就拿一个数组当优先队列，入队的时候就一个个往后排，但是出队的时候要扫出这里最大的那个移出**并调整剩下元素的位置以补齐空缺**；或者也可以在入队的时候就按从小到大排好，每次出队的都是最后一个元素。

以上两种方式并不好，因此我们使用大顶堆(或小顶堆)来实现。堆是一种完全二叉树，所有结点的编号都是相连的，因此不会有空洞：

![[homework/Algorithm/resources/Pasted image 20230325001742.png]]

> 左图：大顶堆；右图：小顶堆

当我们想要在大顶堆上插入一个元素时，要做这样一些事情：

1. 首先，让这个元素直接成为结构的最后一个元素：
  ![[homework/Algorithm/resources/Pasted image 20230325001908.png|200]]
2. 然后，看他和他的父亲谁大。如果它大，就要交换，并继续向上，直到没有他父亲大为止。
  ![[homework/Algorithm/resources/Pasted image 20230325002039.png|200]]

因此，我们发现，**堆顶就是我们每次要弹出的元素**。那么在`dequeue`操作中，就需要这样做：

1. 将堆顶和最后一个元素交换位置，并弹出最后一个元素(最后返回的就是它)；
  ![[homework/Algorithm/resources/Pasted image 20230325002217.png|200]]
2. 让新的堆顶不断和自己的左儿子和右儿子比较。如果根儿小，那根儿就下去，儿子上来。直到这个堆顶找到自己的位置。
  ![[homework/Algorithm/resources/Pasted image 20230325002353.png|200]]

通过以上叙述，我们首先总结一下我们需要的工具方法：

```cpp
// 通过我当前的结点，找到我父亲的结点编号
int parent(int index);

// 通过我当前的结点，找到我左右孩子的编号
int leftChild(int index);  
int rightChild(int index);

// 交换两个元素的值(参数只是index，并不是实际的值)
void swap(int, int);
```

下面给出这些方法的实现，它们都比较简单，只是在一个数组上操作而已。**注意，这里默认根节点的编号是0**。

```cpp
int PriorityQueue::parent(int index){  
    if(index <= 1) return 0;  
    if(index % 2 == 0) return index / 2 - 1;  
    return index / 2;  
}  

int PriorityQueue::leftChild(int index){  
    int left = index * 2 + 1;  
    return left > nums.size() - 1 ? -1 : left;  
}  

int PriorityQueue::rightChild(int index){  
    int right = index * 2 + 2;  
    return right > nums.size() - 1 ? -1 : right;  
}  

void PriorityQueue::swap(int a, int b){  
    int temp = nums.at(a);  
    nums.at(a) = nums.at(b);  
    nums.at(b) = temp;  
}
```

有了这个方法，接下来就是两个更加高级的方法：`shiftUp()`和`shiftDown()`。前者是在入堆的时候往上交换的函数；后者是出队的时候新的堆顶往下交换的函数。从前者开始，首先，我们要确定最后一个元素，也就是`nums.size() - 1`。然后，看它和它的父亲，即`parent(index)`谁更加大。如果最后一个元素大，就要交换它们，然后让`index`变成父亲的，并且**在本次循环中计算出这个父亲的父亲**：

```cpp
void PriorityQueue::shiftUp(){  
    int index = nums.size() - 1;  
    int parentIndex = parent(index);  
    while(parentIndex >= 0 && nums.at(index) > nums.at(parentIndex)){  
        swap(index, parentIndex);  
        index = parentIndex;  
        parentIndex = parent(parentIndex);  
    }  
}
```

向下交换的函数稍微复杂一点，但也并没有很复杂。从根节点开始，先和左孩子比比，再和右孩子比比。**只要比一个孩子小，那就要往下走，并成为那个孩子**：

```cpp
void PriorityQueue::shiftDown(){  
    int index = 0;  
    while(index < nums.size() - 1){  
        int maxVal = nums.at(index);  
        int maxIndex = index;  
  
        int leftIndex = leftChild(index);  
        if(leftIndex >= 0 && maxVal < nums.at(leftIndex)){  
            maxVal = nums.at(leftIndex);  
            maxIndex = leftIndex;  
        }  
  
        int rightIndex = rightChild(index);  
        if(rightIndex >= 0 && maxVal < nums.at(rightIndex)){  
            maxVal = nums.at(rightIndex);  
            maxIndex = rightIndex;  
        }  
  
        if(index == maxIndex) break;  
  
        swap(index, maxIndex);  
        index = maxIndex;  
    }  
}
```

这里需要注意的是，左和又的比较是两个if而不是if-else。这样如果父亲比两个孩子都小，**默认最后会和右孩子交换，因为右孩子是后比较的**。

通过上面的介绍，我们最终能写出优先队列的两个真正的接口函数：

```cpp
void PriorityQueue::enqueue(int val){  
    nums.push_back(val);  
    shiftUp();  
}  
  
int PriorityQueue::dequeue(){  
    if(nums.size() <= 0) return -1;  
    int root = *(nums.begin());  
    swap(0, nums.size() - 1);  
    nums.erase(nums.end() - 1);  
    shiftDown();  
    return root;  
}
```

这里完全按照之前的叙述编写，在上面又加了一些特殊情况的处理。

# 4. 实验环境

# 5. 项目测试