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

## 3.3 Quick Sort

快速排序的核心思想，就是选出一个pivot，将比它小的和比它大的放在两边，并递归地进行左半边和右半边。因此，总体思想是这样的：

```cpp
void SortHelper::QSort(vector<int>& nums, int low, int high){  
    int pivot;  
    if(low < high){  
        pivot = partition(nums, low, high);  
        QSort(nums, low, pivot - 1);  
        QSort(nums, pivot + 1, high);  
    }  
}
```

其中，`partition()`函数会修改`nums`这个序列，将我们选择的pivot放到该去的位置，并将它的坐标返回。下面我们来着重讲解一下这个函数的实现。

首先，是pivot的选择，这个选择可以很随意，也可以很精巧。我们可以每次都选择序列(或子序列)中的第一个元素作为pivot，也可以使用比较靠谱的算法来进行选择(比如[[Algorithm/ea#3.3 (Median) Select|Median Select]])。在下面的实现中，我们使用前者。之后，就是对这个数组的操作了。我们现在要做的，**是给这个pivot选定一个位置，让所有比它小的在它左边，所有比它大的在它右边**。

```cpp
int SortHelper::partition(vector<int>& nums, int low, int high){  
    int pivot = nums.at(low);  
    while(low < high){  
        while(low < high && nums.at(high) >= pivot) high--;  
        swap(nums, low, high);  
        while(low < high && nums.at(low) <= pivot) low++;  
        swap(nums, low, high);  
    }  
    return low;  
}
```

我们来逐行解释一下这个while循环。首先是第一句：

```cpp
while(low < high && nums.at(high) >= pivot) high--;  
```

这句话的意思是，只要high指针指向的元素比pivot大，那么就不统计它了，直接让high往回走。因此只要符合条件，就让high--。之后，如果一旦跳出了这个循环，**就表示high指针发现了一个比pivot小的元素**。那此时，我们就清楚了pivot的位置：至少是这里！由于我们让low就是pivot，因此这里直接将low和high指向的元素互换：

```cpp
swap(nums, low, high);
```

互换完之后，low这个位置就变成了那个**原来比pivot小的元素**。因此在下一个while循环中，第一次是一定会符合条件的，会让low++。在之后的循环中，我们的目的就是找到那个比pivot大的元素，并让它位于pivot的右边：

```cpp
while(low < high && nums.at(low) <= pivot) low++;
    swap(nums, low, high);  
```

我们可以发现，这个函数神奇的地方就在与，它使用两个指针，**这两个指针扫过的区域，都是已经确定了和pivot大小关系的元素**：

![[homework/Algorithm/resources/Drawing 2023-03-26 12.58.40.excalidraw.png]]

**而low和high中的一个，就负责承载pivot这个元素**。每一次交换的过程中，这个pivot要么被换到了low身上，要么被换到了high身上。随着not sure区域逐渐变短，我们就逐渐地为pivot找到了它该去的地方。

下面，是题目中的那两个问题。

<h2>How many comparisons will Quicksort do on a list of n elements that all have the same value?</h2>

从上面的叙述中也看到了，**只有比pivot小或者比pivot大的时候，才会进行交换，即改变pivot的下标**。如果所有元素都一样的话，最终pivot依然还是处于low的位置。此时两边的子序列中一个是空，另一个是除了pivot以外的其它元素。在右边的元素进行递归时，依然会进行同样的过程。这意味着，**我们每一次递归只能处理好一个元素的位置**。如果我们将这个比较过程画成一个树，那么将是一棵斜树，树的深度就是我们要进行递归的次数。因此，我们比较的次数为：

$$
(n - 1) + (n - 2) + \cdots + 1 = \frac{n(n - 1)}{2}
$$

此时时间复杂度为：

$$
O(n^2)
$$

---

<h2>What are the maximum and minimum number of comparisons will Quicksort do on a list of n elements, give an instance for maximum and minimum case respectively.</h2>

既然一边倒的划分会导致最坏情况，那么均匀的分配就是最好的情况了。如果我们每次都恰好让pivot处于中间的位置，那么两边的元素会非常平均。如果我们把它画成一棵树的话，这棵树的左右子树会非常均匀，因此这棵树的深度大概为：

$$
\lfloor log_2n \rfloor + 1
$$

因此，我们只需要根据Divide and Conquer的思想，将每个结点需要的时间加起来，就能得到最终的时间复杂度：

$$
\begin{array}{rclcl}
T(n) & \leqslant & 2T(\dfrac{n}{2}) + n \\
& \leqslant & 2(2T(\dfrac{n}{4}) + \dfrac{n}{2}) + n & = & 4T(\dfrac{n}{4}) + 2n \\
& \leqslant & 4(2T(\dfrac{n}{8}) + \dfrac{n}{4}) + 2n & = & 8T(\dfrac{n}{8}) + 3n \\
\cdots \\
& \leqslant & n(T(1) + (log_2n)) \times n & = & O(nlogn)
\end{array}
$$

至于最坏的情况，在第一个问题中已经叙述了，就是序列原本就有序，或者元素都相同的情况下。根本原因就是pivot最终处于序列的端点而非正中间。以下是二者的举例：

```c
// 最好：
[2, 6, 1, 8, 3, 7, 5, 4]

// 最坏：
[1, 2, 3, 4, 5]
```

## 3.4 Median of Two Sorted Arrays

本题的描述很像力扣的第四题，难度为Hard：

[Median of Two Sorted Arrays - LeetCode](https://leetcode.com/problems/median-of-two-sorted-arrays/)

> *我受力扣的影响，以为成了第k小的元素。因此下面的大实际上是认为**数字越小越大**。而题中的要求就是kth largest。所以算法理应将大小相互调换，不过无伤大雅。*

我们要在两个已经有序的序列中，找出第k大的元素。稍微想一想就能知道，这个元素一定位于这两个数组中某一个的**前面一段的位置**，而这个前面一段就和k的大小有关。如果k是3的话，那这个值存在的区间就是`nums1[0] ~ nums1[2]`以及`nums2[0] ~ nums2[2]`。但是我们要注意，这只是k存在的区间，**而在k已经确定的条件下，我们能确定点儿什么呢**？下面我们来学习一下牛人的思想：

![[homework/Algorithm/resources/Drawing 2023-03-26 14.34.00.excalidraw.png]]

我们从这两个序列中一共选出k个元素。其中nums1选x个，nums2选y个(至于x和y是多少，之后再讨论)。因此，位于这个区域边缘的两个数字的编号就是x - 1和y - 1。那么，如果`nums1[x - 1] > nums2[y - 1]`这个条件成立的话，会发生什么呢？我们能说：**`nums2`目前选中的所有数字，都是比我们最终选出的target要大的**！换句话说，就是它们正好被包含在了k这个范围内。

![[homework/Algorithm/resources/Drawing 2023-03-26 14.40.51.excalidraw.png]]

为什么会这样说呢？我们给一个例子：

```c
// nums1
[7, 8, 9, 10, ...]

// nums2
[1, 2, 3, 4, 5, 6, 21, ...]
```

如果我们要选出第8大的，也就是数字8。而我们选择的区域是这样的：

![[homework/Algorithm/resources/Pasted image 20230326144416.png]]

正好是8个元素。那么既然9要比5大，就说明**1到5这几个数字都不可能是第8大的**，它们正好被包含在了前8位中。

> *这里注意，我认为1是最大的，2是第二大的... ...，数字越大，认为它越小。读者可以认为是**考试成绩的排名**之类的，第一名是最大的。*

何出此言？我们使用反证法证明一下：如果第8大的数字target出现在了`nums[2]`的前5位中，并且它在`nums[2]`是第r位，我们能够得到一系列的结论：

1. `nums2[y - 1]`(也就是上图中的5，nums2的第y个元素)一定要比target大，因为都是升序排列的；
2. 由于r一定$\leqslant$y，因此r也一定$\leqslant x + y = k$；
3. `nums2`的前r - 1个元素一定$\leqslant$target，`nums2`从第r + 1个元素开始必定要大于target，依然是因为升序排列。这其中也必然包括第y个元素；
4. 由于$r - 1 \leqslant k$，而nums2只有r - 1个元素比target小，所以`nums1`中从第一个元素开始，必然有$k - (r - 1) = x + y - (r - 1)$个元素比target小；

从第2个结论可以得到，$y - r \geqslant 0$，再根据第4个结论，可以得到`nums1`中比target小的元素是$x + y - (r - 1) \geqslant x$个。那么就意味着，从`nums[x - 1]`开始，之后的所有元素都满足下面的条件：

```
it <= target <= nums2[y - 1]
```

不等式的后半部分出自结论3。很显然，**这和我们之前的假设`nums[x - 1] > nums[y - 1]`是矛盾的**。因此，target必定不会出现在`nums2`的前y个元素中。根据这个结论，我们就可以做出响应的操作了：

* 从两个序列中框出k个元素；
* 比较边缘的两个元素的大小；
* **舍弃小的那个元素以及其左边的所有元素**；
* 从新的两个表中继续上述过程。

下面是上述过程的代码实现：

```cpp
int SortHelper::medianSelect(vector<int>& nums1, vector<int>& nums2, int k) {  
    int m = nums1.size();  
    int n = nums2.size();  
    if (m > n) {  
        return medianSelect(nums2, nums1, k);  
    }  
    if (m == 0) {  
        return nums2[k - 1];  
    }  
    if (k == 1) {  
        return std::min(nums1[0], nums2[0]);  
    }  
    int i = std::min(m, k / 2);  
    int j = k - i;  
    if (nums1[i - 1] < nums2[j - 1]) {  
        vector<int> nums1_new(nums1.begin() + i, nums1.end());  
        return medianSelect(nums1_new, nums2, k - i);  
    } else {  
        vector<int> nums2_new(nums2.begin() + j, nums2.end());  
        return medianSelect(nums1, nums2_new, k - j);  
    }  
}
```

其中最核心的部分，就是上面介绍的一大堆：

```cpp
int i = std::min(m, k / 2);  
int j = k - i;  
if (nums1[i - 1] < nums2[j - 1]) {  
	vector<int> nums1_new(nums1.begin() + i, nums1.end());  
	return medianSelect(nums1_new, nums2, k - i);  
} else {  
	vector<int> nums2_new(nums2.begin() + j, nums2.end());  
	return medianSelect(nums1, nums2_new, k - j);  
}  
```

其中的i和j就是我们说过的x和y。而i和j的取值，就保证了i + j = k的成立。至于为什么是m和k/2中小的那个，就是让每次框到两个序列中数字的个数尽量差不多，但不能比这个序列的长度还多。**我们每次都让nums1是更短的那个序列，也是为了不让这句代码出现异常**：

```cpp
int m = nums1.size();  
int n = nums2.size();  
if (m > n) {  
	return medianSelect(nums2, nums1, k);  
}
```

现在说回刚才的例子：

![[homework/Algorithm/resources/Pasted image 20230326144416.png]]

如果我们舍弃了`nums2`的前5个元素，那么就意味着，**在新的序列里，我们只需要选出第8 - 5 = 3大的数字了**。所以，k变成了1的时候，我们只需要看这两个序列开头的元素谁更小，返回就可以了。

至于`m == 0`的情况，就是当断的序列中根本不存在元素时，这时第k大的数就是`nums2`中第k大的数字。所以直接返回就可以了。

# 4. 实验环境

* OS: Windows 11
* IDE: Clion
* Compiler: g++, CMake

# 5. 项目测试

## 5.1 Two Sum

```cpp
vector<int> nums{  
    10, 20, 14, 1, 3, 77, 33, 18  
};  
int target = 19;  
  
SortHelper sh;  
std::cout << sh.sumToTarget(nums, target) << std::endl;
```

![[homework/Algorithm/resources/Pasted image 20230326151924.png]]

---

```cpp
vector<int> nums{  
    10, 20, 14, 1, 3, 77, 33, 18  
};  
int target = 999;  
  
SortHelper sh;  
std::cout << sh.sumToTarget(nums, target) << std::endl;
```

![[homework/Algorithm/resources/Pasted image 20230326151953.png]]

## 5.2 Priority Queue

```cpp
int val[] = {  
    1, 5, 6, 4, 3  
};  
  
PriorityQueue q(val, sizeof(val) / sizeof(int));  
std::cout << q.dequeue() << " ";  
std::cout << q.dequeue() << " ";  
std::cout << q.dequeue() << " ";  
std::cout << q.dequeue() << " ";  
std::cout << q.dequeue() << " ";  
std::cout << q.dequeue() << " ";  
std::cout << q.dequeue() << " ";
```

![[homework/Algorithm/resources/Pasted image 20230326152356.png]]

> -1表示队列已经空了，无法再出队。

## 5.3 Quick Sort

```cpp
vector<int> nums{  
    10, 20, 14, 1, 3, 77, 33, 18  
};  
  
SortHelper s;  
s.QuickSort(nums);  
for(auto n : nums) std::cout << n << " ";
```

![[homework/Algorithm/resources/Pasted image 20230326152605.png]]

## 5.4 Median Select

```cpp
vector<int> a{1, 4, 5, 6, 7, 8};  
vector<int> b{3, 12, 15, 19};  
  
SortHelper sh;  
  
for(int i = 10; i >= 1; i--) 
	std::cout << "k = " << i << ": " << sh.medianSelect(a, b, i) << std::endl;
```

![[homework/Algorithm/resources/Pasted image 20230326152909.png]]