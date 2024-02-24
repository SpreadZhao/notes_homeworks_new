# 1. Introduction

## 1.1 Insertion Sort

遍历一遍数组，为每一个元素找到它的位置。从第一个元素开始，由于目前还没有排序，所以它就在那里；之后第二个元素，需要和第一个元素比大小；第三个元素需要和前两个元素比大小；第四个元素需要和前三个元素比大小……我们的目的是，**把小的数字插回去，大的数字不用插**。

这样看起来，其实**从第二个元素开始就可以了，因为第一个元素一定是有序的**。下面给出伪代码：

![[Lecture Notes/Algorithm/resources/Pasted image 20230531124013.png|500]]

kotlin代码：

```kotlin
class InsertionSort {  
	fun sort(array: IntArray) {  
		for (i in 1 until array.size) {  
			val key = array[i]; var j = i - 1  
			while (j >= 0 && array[j] > key) {  
				array[j + 1] = array[j]  
				j--  
			}  
			array[j + 1] = key  
		}  
	}  
}
```

#homework Insertion Sort

Using Figure 2.2 as a model, illustrate the operation of INSERTION -SORT on the array A=<31, 41, 59, 26, 41, 58>.

---

> [!attention]
> 框里的是i指向的元素，加粗的是被插回去的小数。

1. After loop `i == 1`

  > 31, <mark class="square-solid">41</mark>, 59, 26, 41, 58

2. After loop `i == 2`

  > 31, 41, <mark class="square-solid">59</mark>, 26, 41, 58

3. After loop `i == 3`

  > **26**, 31, 41, <mark class="square-solid">59</mark>, 41, 58 (26是小数，要插回去)

4. After loop `i == 4`

  > 26, 31, 41, **41**, <mark class="square-solid">59</mark>, 58  (41是小数，要插回去，注意两个41的位置，通过while循环的条件)

5. After loop `i == 5`

  > 26, 31, 41, 41, **58**, <mark class="square-solid">59</mark>

## 1.2 loop-invariant

使用循环不变式证明算法的正确，需要三个步骤：

* Initialization: 循环开始前就正确
* Maintenance: 在某一次循环之前是正确的，在下一次循环之前还是正确的
* Termination: 循环结束时的结果时正确的

![[Lecture Notes/Algorithm/resources/Pasted image 20230531124245.png|500]]

使用loop-invariant证明插入排序的正确性：

* 在循环开始之前，由于从第二个元素（j = 2）开始迭代，所以初始序列就是A\[1\]，它包含了原始序列的元素A\[1\]，并且**有序（这就代表最终的输出在一开始是对的）**；
* 当其中一次循环开始前，对于第j个元素，它前面的序列A\[1..j-1\]是有序的；当一次循环结束时，我们给A\[j\]找到了它的位置。这证明我们中间的结果A\[1..j\]也是有序的；
* 当j = n + 1时，我们跳出了循环，此时A\[1..j-1\]就是我们要的输出，所以结果也是有序的。

#homework Invariant

Consider the searching problem:

**Input**: A sequence of n numbers A = <a1, a2; …, an> and a value v.

**Output**: An index i such that v = A\[i\] or the special value NIL if v does not appear in A. 

Write pseudocode for linear search, which scans through the sequence, looking for v. Using a loop invariant, prove that your algorithm is correct. Make sure that your loop invariant fulfills the three necessary properties.

---

Pseudocode:

```kotlin
fun search(A[1..n]) {
	for (i in 1 .. n) {
		if (A[i] == v) return i
	}
	return NIL
}
```

Proof:

1. Initialization：在循环开始前，序列是空的，不包括v，符合题目要求的后者（NIL）；
2. Maintainance：当一次循环开始前，之前的序列A\[1..i-1\]是不包括v的，符合后者，在这次循环结束后，要么包括v（前者），要么不包括v（后者），也都是正确的；
3. Termination：当`i == n + 1`时，序列中一定不包括v，会返回NIL，也就是后者（*注意，`i == n`时，其实是属于第二步的*）。

# 2. Divide and Conquer

![[Lecture Notes/Algorithm/resources/Pasted image 20230531130007.png|500]]

> **recursivevly千万不能落**！

## 2.1 Merge Sort

[[Lecture Notes/Algorithm/ea#3.2 Sorting(Merge sort)]]

```kotlin
class MergeSort {  
	fun sort(array: IntArray) {  
		core(array, 0, array.lastIndex)  
	}  
	  
	private fun core(array: IntArray, low: Int, high: Int) {  
		if (low < high) {  
			val mid = (low + high) / 2  
			core(array, low, mid)  
			core(array, mid + 1, high)  
			merge(array, low, mid, high)  
		}  
	}  
	  
	private fun merge(array: IntArray, low: Int, mid: Int, high: Int) {  
		val left = array.copyOfRange(low, mid + 1) + intArrayOf(Int.MAX_VALUE)  
		val right = array.copyOfRange(mid + 1, high + 1) + intArrayOf(Int.MAX_VALUE)  
		var i = 0; var j = 0  
		for (k in low .. high) {  
			if (left[i] < right[j]) {  
				array[k] = left[i]  
				i++  
			} else {  
				array[k] = right[j]  
				j++  
			}  
		}  
	}  
}
```

#homework Merge Sort

Using Figure 2.4 as a model, illustrate the operation of merge sort on the array A = <3, 41, 52, 26, 38, 57, 9, 49>.

![[Lecture Notes/Algorithm/resources/Pasted image 20230607195538.png|center|500]]

## 2.2 Solving Recurrence

Using substitution method to solve the recurrence:

$$
T(n) = 4T(\frac{n}{2}) + 100n
$$

* Guess: we guess that: $T(n) \leqslant cn^3$

For $k = \dfrac{n}{2}$, this inequality should also be correct, which means:

$$
T(k) \leqslant ck^3 \Longrightarrow T(\frac{n}{2}) \leqslant c \cdot (\frac{n}{2})^3
$$

Put this in to the origin equation:

$$
\begin{array}{rcl}
T(n) & = & 4T(\dfrac{n}{2}) + 100n \\
& \leqslant & 4c \cdot (\dfrac{n}{2})^3 + 100n \\
& = & (\dfrac{c}{2})n^3 + 100n \\
& = & cn^3 - [(\dfrac{c}{2})n^3 - 100n] \\
& \leqslant & cn^3
\end{array}
$$

**一道容易错的题**：

![[Lecture Notes/Algorithm/resources/Pasted image 20230531215550.png|500]]

> 上面这么写是没问题的，但是最后这个cn+1你能说T(n) <= cn吗？你明明在最后加了个1，但还是硬说T(n) <= cn，所以这是不严谨的。

Recurtion Tree

![[Lecture Notes/Algorithm/resources/Pasted image 20230531220321.png|500]]

![[Lecture Notes/Algorithm/resources/Pasted image 20230531220806.png|500]]

![[Lecture Notes/Algorithm/resources/Pasted image 20230531220936.png|500]]

> **对于递归树的高度，它的底数一定是大于一的**！

## 2.3 Master Theorem

[[Lecture Notes/Algorithm/ea#^6cdbcb|Master Theorem]]

## 2.4 Maximum Subarray Problem

[[Homework/Algorithm/practice2#3.4 Max Sum|Maximum Subarray Problem]]，使用Divide and Conquer:

```kotlin
class MaximumSubarray {  
	fun maxSumDivideConquer(array: IntArray): Int {  
		return coreDC(array, 0, array.lastIndex)  
	}  
	  
	private fun coreDC(array: IntArray, low: Int, high: Int): Int {  
		return if (low == high) array[low]  
		else {  
			val mid = (low + high) / 2  
			val leftMaxSum = coreDC(array, low, mid)  
			val rightMaxSum = coreDC(array, mid + 1, high)  
			val crossMaxSum = coreDCCrossing(array, low, mid, high)  
			maxOf(leftMaxSum, rightMaxSum, crossMaxSum)  
		}  
	}  
	  
	private fun coreDCCrossing(array: IntArray, low: Int, mid: Int, high: Int): Int {  
		var leftMaxSum = Int.MIN_VALUE  
		var sum = 0  
		for (i in mid downTo low) {  
			sum += array[i]  
			if (sum > leftMaxSum) leftMaxSum = sum  
		}  
		var rightMaxSum = Int.MIN_VALUE  
		sum = 0  
		for (j in mid + 1 .. high) {  
			sum += array[j]  
			if (sum > rightMaxSum) rightMaxSum = sum  
		}  
		return leftMaxSum + rightMaxSum  
	}  
}
```

核心思想就是，对于一个序列，它的最大和只能出现在以下三种情况：

* 只包含在前一半
* 只包含在后一半
* 跨越前一半和后一半

所以，我们要分别计算这三种情况，最后三个数比大小。第一种，如果只包含前一半，那么直接使用原函数递归就可以，也就是从`low`到`mid`，对于后一半也是一样，从`mid + 1`到`high`。而比较麻烦的，是第三种跨越的情况。我们可以思考一下，如果是第三种，最后的答案**一定是包括`mid`和`mid + 1`这两个元素**。因此，我们使用两个循环，分别计算出包含`mid`的左边的最大和，以及包含`mid + 1`的右边的最大和：

```kotlin
private fun coreDCCrossing(array: IntArray, low: Int, mid: Int, high: Int): Int {  
	var leftMaxSum = Int.MIN_VALUE  
	var sum = 0  
	for (i in mid downTo low) {  // 左边最大和
		sum += array[i]  
		if (sum > leftMaxSum) leftMaxSum = sum  
	}  
	var rightMaxSum = Int.MIN_VALUE  
	sum = 0  
	for (j in mid + 1 .. high) {  // 右边最大和
		sum += array[j]  
		if (sum > rightMaxSum) rightMaxSum = sum  
	}  
	return leftMaxSum + rightMaxSum  
}  
```

最后返回的结果，**一定是把他们两个加起来，一定是**！！！因为如果你不加的话，等于承认结果中不包含`mid`或者不包含`mid + 1`，而这样的话其实和那三种情况的前两种是重的，我们的计算也就没有意义了。

## 2.5 Matrix Multiplication

[[Lecture Notes/Algorithm/ea#3.1 Matrix Multiplication|Matrix Multiplication]]

## 2.6 Heap

Heap:

[src/algo/MaxHeap.kt · SpreadZhao/leetcode - 码云 - 开源中国 (gitee.com)](https://gitee.com/spreadzhao/leetcode/blob/master/src/algo/MaxHeap.kt)

构造函数中加了一个`Int.MIN_VALUE`是因为为了空出第一个节点，这样真正的堆中的元素是从第二个元素开始算。对于**自底向上**，也就是上面代码中的构建大顶堆的方式，时间复杂度是$O(n)$，并不是$O(nlogn)$。

`heapify()`的过程，就是对于我想调整的结点，先和它的左孩子比比，再和它的右孩子比比，然后**寻找它们三个里最大的那个，如果不是父亲的话，那就把父亲换下去，把最大的那个换上来**，直到不用再换了或者已经到了叶子结点为止。

构件大顶堆的过程，就是从第一个不是叶子的结点开始往会找，调整每一个结点。

[[Homework/Algorithm/practice1#3.2 Priority Queue|Priority Queue]]:

[src/algo/PriorityQueue.kt · SpreadZhao/leetcode - 码云 - 开源中国 (gitee.com)](https://gitee.com/spreadzhao/leetcode/blob/master/src/algo/PriorityQueue.kt)

## 2.7 Quick Sort

QuickSort:

[[Homework/Algorithm/practice1#3.3 Quick Sort|practice1]]

[src/algo/QuickSort.kt · SpreadZhao/leetcode - 码云 - 开源中国 (gitee.com)](https://gitee.com/spreadzhao/leetcode/blob/master/src/algo/QuickSort.kt)

里面介绍了另一种方法来进行partition操作：

```kotlin
private fun partition2(arr: IntArray, low: Int, high: Int): Int {  
	val pivot = arr[high]  
	var i = low - 1  
	for (j in low until high) {  
		if (arr[j] < pivot) {  
			i++  
			swap(arr, i, j)  
		}  
	}  
	swap(arr, i + 1, high)  
	return i + 1  
}
```

在这个方法中，我们只需要**找出所有比`arr[high]`小的元素，并把`arr[high]`放在这些元素的右边即可**。走一走循环我们就能发现，我们并不关心比pivot大的元素在哪里，因为只需要有*最后一句swap*，就能保证所有比pivot大的元素都出现在pivot的右边。而for循环中做的就是找到所有比pivot小的元素，**并让i记住他们中的最后一个**。

> *最后一句swap*：`swap(arr, i + 1, high)`

## 2.8 Other Sort

Counting Sort

Counting Sort的核心思想就是：如果有5个数（包含我自己）小于等于我，那么我就可以被放在第5号。因为，从第6号开始，都一定是大于我的数字，所以我放在第五位一定是正确的。

```kotlin
class CountingSort {  
	fun sort(arr: IntArray, range: IntRange): IntArray {  
		val res = IntArray(arr.size)  
		val location = IntArray(range.last + 1) { 0 }  
		for (j in arr.indices) location[arr[j]]++  
		for (i in 2 .. range.last) location[i] += location[i - 1]  
		for (j in arr.lastIndex downTo 0) {  
			res[location[arr[j]] - 1] = arr[j]  
			location[arr[j]]--  
		}  
		return res  
	}  
}
```

第一个for循环：

```kotlin
for (j in arr.indices) location[arr[j]]++
```

是为了记录每个元素出现的次数：

![[Lecture Notes/Algorithm/resources/Pasted image 20230601182115.png|500]]

比如此时，1022就分别是1234在A中出现的次数。但是，即使这样还不行，因为我要知道**有多少个数字是小于等于我的**。而我目前只知道有多少个数字（包括自己）是等于我的。因此，下一个for循环就是为了计算这个：

```kotlin
for (i in 2 .. range.last) location[i] += location[i - 1]  
```

从第一个往后叠加，像多米诺骨牌一样，把前面的和不断累加到后面，最终C里存的就应该是我们要的，小于等于（包括自己）的数字有多少个。

![[Lecture Notes/Algorithm/resources/Pasted image 20230601182438.png|500]]

最后，我们从A的最后一个数字开始，找到它的位置。比如3，我知道整个数组中，**小于等于它（也包括它自己这个3）的数字有3个，所以它至少也要放在第三名**。因此，我们将3放在`小于等于这个3的数字的个数`名：

```kotlin
res[location[arr[j]] - 1] = arr[j]
```

> 这里需要注意，第三名是从1开始的，因此对应的下标还需要-1。

![[Lecture Notes/Algorithm/resources/Pasted image 20230601182714.png|500]]

那么，如果之后又遇到3该咋办？那么顺理成章，它应该放在第二名。所以我们直接把C中的值减掉，这样之后就能顺利放到对的位置：

```kotlin
location[arr[j]]--
```

![[Lecture Notes/Algorithm/resources/Pasted image 20230601182824.png|500]]

![[Lecture Notes/Algorithm/resources/Pasted image 20230601222257.png]]

[十种基本的排序算法 - 掘金 (juejin.cn)](https://juejin.cn/post/6844904023821123592)

[[Happy-SE-in-XDU-master/Algorithm/supplement_all#^13e1e0|supplement_all]]

# 3. Dynamic Programming

Dynamic Programming

![[Lecture Notes/Algorithm/resources/Pasted image 20230602134555.png|500]]

1. 刻画最优解的结构
2. 递归定义最优解的值
3. 自底向上计算最优解的值
4. 使用子问题的解计算最优解

Assembly Line

![[Lecture Notes/Algorithm/resources/Pasted image 20230612123240.png]]

> 如果是从我这条路过来的，那直接用上一个工位的时间加上我这个工位的结果就行；而如果是从另一条线上的工位过来的，那还要额外加上一个传送的时间t。

## 3.1 Matrix-chain Product

[[Homework/Algorithm/practice2#3.1 Matrix-chain Product|Matrix-chain Product]]

![[Lecture Notes/Algorithm/resources/Pasted image 20230612123223.png]]

补充一下最优解的计算：

```kotlin
fun minCount3(p: IntArray): Int {  
	val n = p.size  
	val dp = Array(n) { IntArray(n) { -1 } }  
	val cut = Array(n) { IntArray(n) }  
	for (i in 1 until n) dp[i][i] = 0  
	for (l in 2 until n) {  
		for (i in 1 until n - l + 1) {  
			val j = i + l - 1  
			// if (j == n) continue  
			dp[i][j] = Int.MAX_VALUE  
			for (k in i until j) {  
				val q = dp[i][k] + dp[k + 1][j] + p[i - 1] * p[k] * p[j]  
				if (q < dp[i][j]) {  
					dp[i][j] = q  
					cut[i][j] = k // Remember where I've cut in the best solution  
				}  
			}  
		}  
	}  
	return dp[1][n - 1]  
}
```

`cut`数组记录了每一刀的位置。我们在得到结果之后，**从后往前查**：

![[Lecture Notes/Algorithm/resources/Pasted image 20230603151012.png|250x250]] ![[Lecture Notes/Algorithm/resources/Pasted image 20230603151045.png|350x250]]

```kotlin
val arr3 = intArrayOf(30, 35, 15, 5, 10, 20, 25)
```

首先查`cut[1][6]`，发现是3，所以第一刀应该砍在$A_3$的后面：

$$
A_1A_2A_3|A_4A_5A_6
$$

由于这一刀把序列砍成了两半，所以我们要递归地搜索左右两半的最优解。左边，查的是`cut[1][3]`，得到的是1，所以应该这样：

$$
A_1|A_2A_3|A_4A_5A_6
$$

这一刀的左边只有一个，所以不用查，对于右边，查的就是`cut[2][3]`，在2后面，所以：

$$
A_1|A_2|A_3|A_4A_5A_6
$$

这里我们需要注意了，虽然我们模拟的是刀，但是我们需要区分**刀和递归之间的关系**。毕竟，刀和括号还是不一样的。每砍一刀，实际上是将序列看成了两半，**并给这两半分别都加上括号**。因此，上面这个看起来跟没砍一样的序列实际上是这样的：

$$
(A_1((A_2)(A_3)))(A_4A_5A_6)
$$

仔细分析一下能发现，我们先算的还是$A_2$和$A_3$，这和递归的逻辑是一样的。对于$A_4 \sim A_6$，也是一样的操作方法。

## 3.2 Rod Cutting

对于切木棍这个问题，我们可以这么想：如果采用暴力手段，就是考虑第一刀的位置，然后递归地考虑左半边和右半边的第一刀。这和矩阵相乘的问题非常类似，但是要简单得多。因为，**我们不需要考虑切成的段之间有什么区别**，比如这样：

$$
A_1A_2A_3A_4
$$

这四个矩阵，$A_1A_2A_3$和$A_2A_3A_4$是不一样的，但是如果他们都是木头的话，那就没啥区别了。

```kotlin
fun bestVal(profit: IntArray): Int {  
	val n = profit.size - 1  
	return bruceForce(profit, n)  
}  
  
private fun bruceForce(profit: IntArray, n: Int): Int {  
	if (n == 0) return 0  
	var res = Int.MIN_VALUE  
	for (i in 1 .. n) {  
		res = max(  
			res,  
			profit[i] + bruceForce(profit, n - i)  
		)  
	}  
	return res  
}
```

这里`i`表示的还是这刀会砍在第i段的后面。输入需要注意一下：

```kotlin
val profit = intArrayOf(0, 1, 5, 8, 9, 10, 17, 17, 20, 24, 30)
```

第0号元素不计入，从1开始，表示长度为1的一段木头的价值是1。`i`从1遍历到n，~~这个n其实表示的是**最后一段木头的编号**，这和矩阵相乘中的`j`是一个意思~~，这个n表示的是**当前要切的木头的长度**，和矩阵相乘不同，因为不需要知道木头的编号，只需要知道**还剩多少段木头**就可以了。

这个方法的缺点也非常明显：overlapping问题比矩阵相乘还要严重。因为每一段木头的价值都是固定的，所以比如我们在切第5段到第8段木头的时候，就要算一下1段、2段、3段木头的价值。然而，这些东西我们早就算过无数遍了。**你要是说算$A_5 \sim A_8$的时候还有可能没算$A_5 \sim A_6$的最优解，那我还可能相信**。

我们想一想，如果我们记住了切成每一段的最优解，该是个什么情况。比如，一段的价值是2，两段的价值是5， 三段的价值是6。现在有一个长为三段的木头要切。那显然，应该切成1+2或者2+1的形式能得到最佳价值7。**如果我们能把3段以下（1段\~2段）所有的最佳情况都记住的话，那么我们其实只需要考虑最后一刀。切在第一段后面？答案是2+5（<mark class="square-solid">之所以不是2+(2+2)，是因为我们在算2段长的时候已经把2+2这种情况优化掉了，因为5>4</mark>）；切在第二段后面？答案是5+2；切在第三段后面？答案是6。因此，我们能得到最优解7**。这段解释==非常非常==重要，一定要弄懂！！！！！！

```kotlin
fun bestVal2(profit: IntArray): Int {  
	if (profit.isEmpty()) return 0  
	val dp = IntArray(profit.size) { Int.MIN_VALUE }  
	val cut = IntArray(profit.size)
	dp[0] = 0  
	for (j in 1 until profit.size) {  
		for (i in 1 .. j) {  
			if (dp[j] < profit[i] + dp[j - i]) {  
				dp[j] = profit[i] + dp[j - i]  
				cut[j] = i // 记住刀的位置
			}  
		}  
	}  
	return dp.last()  
}
```

> <font color="yellow">在i &#60 j的时候，所有的情况都必定在之前的循环中计算过最优解</font>。

## 3.3 Top-down versus Bottom-up

Top-down 和 Bottom-up有什么优缺点？

Top-down:

- [p] **子问题我真用的时候才回去求，不算没用的东西**。
- [c] 子问题老反复求，效率低。
- [c] 并且还有额外的递归开销。

Bottom-up:

- [p] 由小到大，有规律，节省时间和空间开销。
- [p] 充分利用了overlapping的特点，不用反复算子问题。
- [c] **把所有的子问题都给算了。有时候，我们是不需要所有子问题的解的**。

鉴于Bottom-up的缺点，我们发明了dp的变形，也就是递归动态规划，也叫**备忘录**。其实在[[Homework/Algorithm/practice2#3.1.2 Dynamic Programming|practice2]]中已经介绍过这个方法了。它既是自顶向下的计算，而且只计算我需要的问题，并且效率还和Bottom-up差不多。

## 3.4 Longest Common Subsequence

[[Homework/Algorithm/practice2#3.2 Longset Common Subsequence|Longest Common Subsequence]]

![[Lecture Notes/Algorithm/resources/Pasted image 20230603175547.png|500]]

> * 如果相等：就是左上角的值+1；
> * 如果不相等：就看上和左哪个大。如果上和左的值相等，那优先取上。
> * 这里的相等指的是**字母字母字母**！！！不是数字！！！不相等里面的上和左相等指的才是格子里面的数字。

![[Lecture Notes/Algorithm/resources/Pasted image 20230603175755.png|400]]

这些箭头的作用就是打印出子序列的值。沿着箭头走，**只要遇到左上的箭头**，就把两边的字母取出来就可以了，并且它们也一定是相等的。在实际实现的时候，~~箭头可以用二维布尔数组来存~~。箭头分为上、左、左上，所以还是得用3种状态的东西来存。

老师讲的：

$$
c[i, j] = \left \{
\begin{array}{ll}
c[i - 1, j - 1] + 1 & if \  i, j > 0 \  and \ x_i = y_j\\
max(c[i, j - 1], c[i - 1, j]) & otherwise
\end{array}
\right.
$$

这里的c数组实际上就是我们写的dp数组。考试题：

![[Lecture Notes/Algorithm/resources/Pasted image 20230609103627.png]]

c数组表示的是x序列和y序列的最长公共子序列的长度，c数组是最优解的值。**这俩空问的都是c数组**。

## 3.5 0-1 Knapsack

[[Homework/Algorithm/practice3#3.1.2 0/1 Knapsack Problem|0-1 Knapsack Problem]]

$$
c[i,j] = max(c[i - 1, j],\ c[i - 1, j - w_i] + v_i)
$$

# 4. Greedy

![[Lecture Notes/Algorithm/resources/Pasted image 20230607191547.png|500]]

问题的全局最优解是通过局部的最优选择或者贪心选择得到的。

## 4.1 Activity Selection

贪心4步走：

1. 按照结束时间从小到大排序；
2. 选出第一个活动，也就是最早结束的哪个；
3. 将所有与这个活动冲突的活动删掉；
4. 继续在剩下的活动里选最早结束的那个，直到没得选为止。

## 4.2 Dijkstra

[[Lecture Notes/Networking/dn#19.5.2 Dijkstra|Dijkstra]]

注意，我们每次都在未选集合顶点中选择距离最短的那个顶点，将它加入到已选集合中。传统的方式，是对所有未选顶点遍历一遍。那么有没有比较好的方式呢？有！就是[[Homework/Algorithm/practice1#3.2 Priority Queue|优先队列]]！另外，我们还可以使用一个先进先出的队列来管理。但是，这是有条件的，条件就是**这个图是无权图，或者所有边的权值都一样**。

![[Lecture Notes/Algorithm/resources/Pasted image 20230605101411.png|500]]

# 5. Graph

## 5.1 Floyd

[[Homework/Algorithm/practice3#3.4 All-pairs shortest paths|Floyd]]

$$
c_{ij}^{(k)} = min\{c_{ij}^{(k - 1)},\ c_{ik}^{(k - 1)} + c_{kj}^{(k - 1)}\}
$$

如果Floyd想得到最优解，可以再创建一个二维数组，每一行表示~~以当前行下标元素为起点，到达其它结点的父亲~~从i到j中间需要经过的结点。每当在第三层for循环中算出最优解时，就把这个数组中相应的中间节点也给更新上。这样就能同时得到最优解和最优解的值。

```kotlin
fun floyd(link: Array<IntArray>): Int {  
    val pathNode = Array(link.size) { IntArray(link.size) { -1 } }  
    for (k in link.indices) {  
        for (i in link.indices) {  
            for (j in link.indices) {  
                if (link[i][k] == Int.MAX_VALUE || link[k][j] == Int.MAX_VALUE) continue  
                if (link[i][j] > link[i][k] + link[k][j]) {  
                    link[i][j] = link[i][k] + link[k][j]  
                    pathNode[i][j] = k  
                }  
            }  
        }  
    }  
    return 1  
}
```

这个`pathNode`的用法还是要好好想想的。比如我们想找5号结点到4号结点的路径，那么自然是看`pathNode[5][4]`，然后查到是3号，那么接下来咋办？注意，这个3号将路径砍成了两份，所以我们要**递归地找`pathNode[5][3]`和`pathNode[3][4]`**，直到查到某一个值是-1为止。

![[Lecture Notes/Algorithm/resources/Pasted image 20230613115212.png]]