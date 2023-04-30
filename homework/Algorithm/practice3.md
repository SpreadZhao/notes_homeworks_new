# 1. 实验题目

## 1.1 Knapsack Problem.

There are 5 items that have a value and weight list below, the knapsack can contain at most 100 Lbs. Solve the problem both as fractional knapsack and 0/1 knapsack.

![[homework/Algorithm/resources/Pasted image 20230430092113.png]]

## 1.2 A simple scheduling problem

We are given jobs _j1, j2… jn,_ all with known running times _t1, t2… tn_, respectively. We have a single processor. What is the best way to schedule these jobs in order to minimize the average completion time. Assume that it is a nonpreemptive scheduling: once a job is started, it must run to completion. The following is an instance.

(j1, j2, j3, j4) : (15,8,3,10)

## 1.3 Single-source shortest paths

The following is the adjacency matrix, vertex A is the source.

```
    A   B   C   D   E
A      -1   3
B           3   2   2
C
D       1   5
E              -3
```

# 2. 实验目的

学习动态规划思想。

# 3. 实验设计与分析

## 3.1 Knapsack Problem

本题分为两部分。第一部分是Fractional，第二部分是0/1。两种问题的思考方式截然不同。前者是根据贪心的思想，而后者是根据动态规划的思想。下面是两道问题的解释。

[Fractional Knapsack Problem - GeeksforGeeks](https://www.geeksforgeeks.org/fractional-knapsack-problem/)

[0/1 Knapsack Problem - GeeksforGeeks](https://www.geeksforgeeks.org/0-1-knapsack-problem-dp-10/)

### 3.1.1 Fractional Knapsack Problem

如果我们允许将物品拆开的话。那么我们其实一定能够将背包正好填满。因此，最大的问题其实是**如何让填进去的东西价值最高**。如果某一个物品的重量是W，价值是V，那么其实我们能够知道，它单位重量的价值是：

$$
R = \frac{V}{W}
$$

而**R越大的物品，就越应该被放进背包里**。因此，我们可以对所有物品按照这个R值去排一个序：

```kotlin
arr.sortWith { item1, item2 ->  
    val p1 = item1?.profit ?: -1  
    val w1 = item1?.weight ?: -1  
    val p2 = item2?.profit ?: -1  
    val w2 = item2?.weight ?: -1  
    val cp1 = p1.toDouble() / w1  
    val cp2 = p2.toDouble() / w2  
    if (cp1 < cp2) 1 else -1  
}
```

通过上面的Comparator，就能够按照R值对arr数组进行降序排序。那么第一个元素就是R值最大的，也就最应该被放进背包里。我们就从它开始。对于数组中的每一个元素，如果它的重量$\leqslant$背包**剩余**的容量，那么它可以被完全放进去；一旦发现了比背包剩余容量大的元素，就只能**拿出一小块来放进去并终止算法**：

```kotlin
var totalPft = 0.0  
var cap = capacity  
for (i in arr) {  
	val curWt = i.weight  
	val curPft = i.profit  
	if (cap >= curWt) {  
		cap -= curWt  
		totalPft += curPft  
	} else {  
		val fraction = cap.toDouble() / curWt  
		totalPft += curPft * fraction  
		cap -= (curWt * fraction).toInt()  
		break  
	}  
}
```

最终我们将`totalPft`返回即可。很简单的一个贪心算法。

### 3.1.2 0/1 Knapsack Problem

#### 3.1.2.1 BF Recursion

如果一件物品要么放，要么不放，那限制变多了，解决思路也变复杂了。如果我们依然按照贪心的思想去放性价比最高的，**很有可能出现最好的选择反而不是性价比最高的那些物品的情况**。因此，我们不能按照贪心的思路来想。首先，考虑一种最暴力的方案：算出所有物品的所有组合(1件、两件、……、n件)，将所有组合的总价值和总重量算出来，选出重量达标的，价值最高的那个组合即可。显然，这个和[[homework/Algorithm/practice2#3.2 Longset Common Subsequence|第二次实验的最长子序列]]有异曲同工之妙，对于每一件物品，**我都可以选择放或者不放**。因此这又是一个递归的问题：

```kotlin
fun zeroOneKnap(capacity: Int, wt: IntArray, pft: IntArray, n: Int): Int {  
    if (n == 0 || capacity == 0) return 0
    return if (wt[n - 1] > capacity) zeroOneKnap(capacity, wt, pft, n - 1)  
    else max(  
        pft[n - 1] + zeroOneKnap(capacity - wt[n - 1], wt, pft, n - 1),  
        zeroOneKnap(capacity, wt, pft, n - 1)  
    )  
}
```

如果我们的输入是这样的：

```kotlin
val profit = intArrayOf(60, 100, 120)  
val weight = intArrayOf(10, 20, 30)  
val w = 50
```

那么代表有三件物品，它们的价值分别是60，100，120；重量分别是10，20，30；背包的容量是50。那么从后往前，对于每一件物品，我都可以选择要或者不要(当然，只有背包剩余容量够的情况下我才会做出选择，否则选都不用选)

![[homework/Algorithm/resources/Drawing 2023-04-30 18.53.43.excalidraw.png|600]]

上面的递归树只是全部情况，有些是不可能发生的(容量不够)。因此我们按照这个思路来走，肯定能找到最终最好的那个。如果容量不够，那直接拜拜，看下一个人了；如果容量够的话，那么我既要看看放了你价值是多少，又要看看不放你价值是多少(把容量留给后面的物品)，二者选一个最大值。

#### 3.2.2.2 Recursion Using Memory

一样的思路，上面的递归树中有很多是重复计算的。因此我们可以用一个数组去把答案记下来，之后抄就可以了。问题是，数组的下标代表这什么。通过观察我们可以发现，变化的量其实只有两个，也就是**正在考虑哪个物品**和**当前背包的剩余容量**。如果这两个值都是相等的，即使它们之前的道路不一样，它们之后要计算步骤也一定是一模一样的，因为我们一定又会从当前这个物品一直回到第一个物品，去看它们要不要的价值。因此，我们将这些数据记录在一个二维数组里就可以了：

```kotlin
fun zeroOneKnap2(capacity: Int, wt: IntArray, pft: IntArray, n: Int): Int {  
    val dp = Array(n + 1) { IntArray(capacity + 1){-1} }  
    return zok(capacity, wt, pft, n, dp)  
}  
  
private fun zok(capacity: Int, wt: IntArray, pft: IntArray, n: Int, dp: Array<IntArray>): Int {  
    if (n == 0 || capacity == 0) return 0  
    if(dp[n][capacity] != -1) return dp[n][capacity]  
    return if (wt[n - 1] > capacity) {  
        dp[n][capacity] = zok(capacity, wt, pft, n - 1, dp)  
        dp[n][capacity]  
    } else {  
        dp[n][capacity] = max(  
            pft[n - 1] + zok(capacity - wt[n - 1], wt, pft, n - 1, dp),  
            zok(capacity, wt, pft, n - 1, dp)  
        )  
        dp[n][capacity]  
    }  
}
```

代码和[[#3.1.2.1 BF Recursion|暴力递归]]几乎没有区别，只是能抄的时候就先抄，不能抄了就计算并保存。

#### 3.2.2.3 DP

使用动态规划的话，依然是从小到大的思想。如果这个背包的容量是W，那么就要考虑背包容量从0到W的每一个过程；对于物品，也要考虑每一个物品是否被考虑进去。

定义数组`dp[i][w]`表示考虑第i件物品**及其之前的物品**时，容量为w的情况下最好的价值是多少。其中`0 <= i <= n`，`0 <= w <= W`。注意两个都带等于号，是因为有容量或考虑的数量为0的情况。因此总行数为`n + 1`，总列数为`W + 1`。

初始情况如下：**如果我一个物品都不考虑；或者我的背包容量为0，那么不管另一个条件如何变化，最后的价值都只能是0**。也就是`dp`数组的第一行和第一列都是0。

接下来，开始考虑第一件物品。如果背包的容量小于我当前物品的容量，那根本就不能放。因此这里的价值就是没放这件物品的价值，也就是`dp[i - 1][w]`；如果容量够的话，那么我放还是不放呢？要看那个收益好。也就是“不放”和“放了”二者的最大值。不放的情况很简单，就是`dp[i - 1][w]`；而放的情况是多少？我们思考一下。如果放了当前的物品，**就意味着我的背包容量少了`wt[i - 1]`**。而更巧的是，**由于`w - wt[i - 1]`一定要小于等于w，这意味着这种情况我们已经算过了**。比如当前背包的容量是3，而物品的重量是2。如果我放了这件物品，我就要查一查**当背包容量是1，并且也是在考虑这个物品时的最好情况**。用那个值加上当前物品的pft，就是放了当前物品的情况。放或者不放的最大值就是当前格子里的答案。

```kotlin
fun zeroOneKnap3(capacity: Int, wt: IntArray, pft: IntArray, n: Int): Int {  
    val dp = Array(n + 1) { IntArray(capacity + 1) {0} }  
    for (i in 0..n) {  
        for (w in 0..capacity) {  
            dp[i][w] = if (i == 0 || w == 0) 0  
                else if (wt[i - 1] <= w)  
                    max(pft[i - 1] + dp[i - 1][w - wt[i - 1]], dp[i - 1][w])  
                else  
                    dp[i - 1][w]  
        }  
    }  
    return dp[n][capacity]  
}
```

> 注意，由于无论如何都会涉及到`dp[i - 1][w]`，因此即使最好的情况出现在数组中间部分，它也一定能够传递到最后一个元素上。

## 3.2 A simple scheduling problem



## 3.3 Longest Common Substring

这道题和上道题唯一的区别是：**这道题只能向左上方要数据**！因为是字串而不是子序列，所以两个指针必须同时往左去，才代表之前的序列。而只要当前的字符不相等，那么直接可以肯定：**这两个符串从i到j的结果就是0**：

```kotlin
fun longestCommonSubstring(x: String, y: String, m: Int, n: Int): Int {  
    val dp = Array(m + 1){IntArray(n + 1)}  
    var res = 0  
    for(i in 0..m){  
        for(j in 0..n){  
            if(i == 0 || j == 0) dp[i][j] = 0  
            else if(x[i - 1] == y[j - 1]){  
                dp[i][j] = dp[i - 1][j - 1] + 1  
                res = max(res, dp[i][j])  
            }  
            else  
                dp[i][j] = 0  
        }  
    }  
    return res  
}
```

另一个区别是，我们不返回最后的`dp[m][n]`，而是返回这个数组中的最大值，为什么呢？因为前者`dp[m][n]`一定同时也是最大值！如果统计的是子序列的话，对于整个两个字符串来说，最长子序列的长度本身也一定是最长的；而最长字串却没有这样的特点。

## 3.4 Max Sum

此题为leetcode第53题：[Maximum Subarray - LeetCode](https://leetcode.com/problems/maximum-subarray/)

此题是一道比较小的动态规划，并且也不需要大量的空间。我们从头开始遍历，只要满足：

```kotlin
pre + curr > curr
```

这是什么意思？也就是这个序列前面已经算出来的最优解如果加上当前的值比当前这个数大。我们可能会有这样的疑问：如果想让这个和越来越大，不应该是新的结果比原来的大吗？也就是：

```kotlin
pre + curr > pre
```

注意，我们的目的并不是从头开始寻找某个序列，而是**不一定从哪个位置开始**。因此前者的条件只要不成立，那么curr的位置就应该是一个新的候选人的开始。为什么这么说？如果不成立的话，那就代表`pre <= 0`，这意味着之前的序列对于当前的curr是一个**拖后腿**的存在。所以我们只能往后进行统计。并且更重要的是，我们每一次保存的并不是全局的最优解，而是**对于当前这个元素的局部最优解**。如果条件不成立的话，那么这个最优解将成为新的开始。

于此同时，我们在每一次确定了新的局部最优解后，都要不断选择最大的，从而最终确定全局的最优解。

```kotlin
fun maxSum(arr: IntArray): Int {  
	var b = arr[0]  // 局部最优解
	var sum = b  // 全局最优解
	for (i in 1 until arr.size) {  
		b = if(b + arr[i] > b) b + arr[i] else arr[i]  
		if(b > sum) sum = b  
	}  
	return sum  
}
```

另外，本题的代码可以简化为：

```kotlin
fun maxSum(arr: IntArray): Int {  
	var b = arr[0]  
	var sum = b  
	for (i in 1 until arr.size) {  
		if(b > 0) b += arr[i]  
		else b = arr[i]  
		if(b > sum) sum = b  
	}  
	return sum  
}
```

# 4. 实验环境

* OS: Windows 11
* IDE: IDEA
* Language: Kotlin

# 5. 项目测试

![[homework/Algorithm/resources/Pasted image 20230425124105.png]]

![[homework/Algorithm/resources/Pasted image 20230425124137.png]]

![[homework/Algorithm/resources/Pasted image 20230425124206.png]]

![[homework/Algorithm/resources/Pasted image 20230425124523.png]]