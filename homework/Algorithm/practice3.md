# 1. 实验题目

## 1.1 Knapsack Problem.

There are 5 items that have a value and weight list below, the knapsack can contain at most 100 Lbs. Solve the problem both as fractional knapsack and 0/1 knapsack.

![[Homework/Algorithm/resources/Pasted image 20230430092113.png]]

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

如果一件物品要么放，要么不放，那限制变多了，解决思路也变复杂了。如果我们依然按照贪心的思想去放性价比最高的，**很有可能出现最好的选择反而不是性价比最高的那些物品的情况**。因此，我们不能按照贪心的思路来想。首先，考虑一种最暴力的方案：算出所有物品的所有组合(1件、两件、……、n件)，将所有组合的总价值和总重量算出来，选出重量达标的，价值最高的那个组合即可。显然，这个和[[homework/algorithm/practice2#3.2 longset common subsequence|第二次实验的最长子序列]]有异曲同工之妙，对于每一件物品，**我都可以选择放或者不放**。因此这又是一个递归的问题：

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

![[Homework/Algorithm/resources/Drawing 2023-04-30 18.53.43.excalidraw.png|center|600]]

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

本题非常简单：给一些任务的执行时间，输出最短的**平均完成时间**。具体的细节可以看[[Lecture Notes/Operating System/os#4.3.2 SJF Example(Non Preemptive)|操作系统笔记]]对这部分的讲解。在本题中，**我们假设所有任务的到达时间都是0**。

既然要算最小的平均完成时间，那么只需要让完成时间之和最小就可以了，因为分母一定是任务的总数，不会改变。如果想要让完成时间的总和最小，那么一定是**越短的任务越要出现在前面**。因为出现在前面的任务加的次数就多，所以这样做总和就能达到最小。因此我们只需要对时间数组进行一个排序，然后按顺序将完成时间计算好就可以了。实际上，虽然没有很复杂的操作，也是体现出了贪心算法的思想。我们每次总是选择了最短的那个任务，也就让完成时间达到了最小。

```kotlin
fun minAverageCompletion(time: IntArray): Double {  
	time.sort()  
	var ac = 0.0; var sum = 0.0  
	for (t in time) {  
		sum += t  
		ac += sum / time.size  
	}  
	return ac  
}
```

## 3.3 Single-source shortest paths

最短路径最常见的算法就是Dijkstra和Bellman Ford。二者在[[Lecture Notes/Networking/dn#19.5 Algorithms in RIP and OSPF|计算机网络笔记]]中都有过介绍。而如果是带负边的图，我们只能用Bellman Ford。想象这种情况：

![[Homework/Algorithm/resources/Drawing 2023-05-01 13.25.00.excalidraw.png | center | 200]]

这三个节点到达任意节点的最短距离都是负无穷。因为每绕一圈都会导致距离变小。如果想检测出这种负环，那么只能使用Bellman Ford算法。代价就是，它比Dijsktra的时间复杂度要高。

现在想象，我已经知道了起点A到达当前节点C的最短距离是D。而如果我们找到了一条新的边L满足：

* L的起点是B；
* L的终点是C；
* **A到达起点B的距离不是无穷大**，

> 第三个条件我们之后会解释

那么这条边就很有可能成为一个新的候选人，只要它满足：

$$
A到达B的距离 + L的长度 \lt D
$$

这就说明，A到达C的最短距离不是D了，而是从A到B再沿着这条新的边走到C的距离。下面，我们通过实际代码来把这部分逻辑实现出来。首先思考一下都需要什么数据，如果像题目要求，只传入邻接矩阵的话，我们根本没办法进行这样的遍历，**因为我们需要对每条边都进行遍历**；另外，我们还需要知道每条边的起点是谁，终点是谁，权值是多少。因此，我们首先需要生成一个边的集合：

```kotlin
class ShortestPath {  
    inner class Edge(val start: Int, val end: Int, val weight: Int)   
    private fun generateEdges(link: Array<IntArray>): ArrayList<Edge> {  
        val edges = ArrayList<Edge>()  
        for (i in link.indices) {  
            for (j in link.indices) {  
                if (link[i][j] != Int.MAX_VALUE) {  
                    edges.add(Edge(i, j, link[i][j]))  
                }  
            }  
        }  
        return edges  
    }  
}
```

参数link就是题目传入的邻接矩阵，我们在里面构建出每一条边。只要权值不是`Int.MAX_VALUE`，就记录下它的起点，终点和权值。有了这样的操作，我们就可以真正开始Bellman Ford算法了：

```kotlin
class ShortestPath {  
    inner class Edge(val start: Int, val end: Int, val weight: Int) 
    
    fun shortestPath(link: Array<IntArray>): IntArray {  
        val edges = generateEdges(link)  
        ...
    }  
  
    private fun generateEdges(link: Array<IntArray>): ArrayList<Edge>
}
```

构建出每一条边后，我们自然要遍历每一条边，去进行上面所说的判断。这个过程也叫做**松弛操作**：

```kotlin
class ShortestPath {  
  
    inner class Edge(val start: Int, val end: Int, val weight: Int)  
  
    fun shortestPath(link: Array<IntArray>): IntArray {  
        val edges = generateEdges(link)  
        val res = IntArray(link.size) { Int.MAX_VALUE }  
        res[0] = 0  
		for (j in edges.indices) {  
			if (res[edges[j].start] == Int.MAX_VALUE) continue  
			if (res[edges[j].end] > res[edges[j].start] + edges[j].weight) {  
				res[edges[j].end] = res[edges[j].start] + edges[j].weight  
			}  
		}  
    }  
  
    private fun generateEdges(link: Array<IntArray>): ArrayList<Edge>
}
```

在这里，我们构建了一个结果数组，用来存A节点到达每个节点的最短距离。初始状态，除了A自己是0，剩下的都是`Int.MAX_VALUE`。对于每条边，我都要看看，你当前的新距离是否应该更新。比如，从A到B的距离一开始是`Int.MAX_VALUE`，然而，如果我遍历到了一条边，它的起点是A，终点是B，它的权值是2的话。那么显然，从A到A距离是0，加上2还是2，显然要比`Int.MAX_VALUE`小。这样B的距离就更新成了2。

下面来说一说这句话的作用：

```kotlin
if (res[edges[j].start] == Int.MAX_VALUE) continue
```

如果我们有下面这张图：

![[Homework/Algorithm/resources/Drawing 2023-05-01 13.48.01.excalidraw.png|center|200]]

我们能发现，这道题的答案显然是除了A自己都是不可达。然而，如果没有这个if判断的话，拿A到B来举个例子。A到B的这条边的长度是`Int.MAX_VALUE`，而从A到A的距离是0，加上`Int.MAX_VALUE`之后还是`Int.MAX_VALUE`，并不大于原来的值`Int.MAX_VALUE`。这看起来似乎没啥问题。我们继续往下看：当遍历到B到C这条边时，目前到C的最短距离是`Int.MAX_VALUE`，而从B到C的长度是2，加上从A到B的最短距离`Int.MAX_VALUE`之后会导致**溢出**，变成一个复数。这显然比原来`Int.MAX_VALUE`要小啊！这样就把这个值给换了。**而我们的本意是不应该替换的，因为从A本来就无法到达C**。因此，**只要当前遍历到的边的起点是无法从A到达的，那这个松弛操作就不应该做**！导致这种情况的原因，实际上是代码所限。在实际情况中是不会出现的。

到此为止，写完了吗？并没有！请看一看[这篇文章](https://blog.csdn.net/qq_24884193/article/details/104357889)。由于边的顺序可能并不固定，会导致我们不能及时更新所有节点的信息。最坏情况下，如果相连着A的那些边在最后才出现的话，那么我们只有在循环最后面才会更新结果信息。因此，我们必须做多次循环才可以。通过证明可以得出，即使一次只能更新一条信息，最多也只需要N - 1次循环就能够得到A到达所有节点的最短距离(其中N是节点的数量)。

下面的问题是，如果出现开头那样的负环会如何？显然，如果最短距离每次都能变短的话，那么就能一直松弛下去。而最多只需要N - 1次循环，就意味着如果我再遍历**一遍**所有的边，如果发现还能松弛的话，图中就一定存在负环。那么，这次的逻辑是什么呢？还是和之前一样？别忘了我们说过的那个不可达导致溢出的问题。在这里如果单纯按照原来的逻辑判断，也是会导致溢出从而疯狂报告你有负环。所以我们也要把这个条件给加上。下面是完整的代码：

```kotlin
class ShortestPath {  
  
    inner class Edge(val start: Int, val end: Int, val weight: Int)  
  
    fun shortestPath(link: Array<IntArray>): IntArray {  
	    val edges = generateEdges(link)  
	    val res = IntArray(link.size) { Int.MAX_VALUE }  
	    res[0] = 0  
	    for (i in 1 until link.size) {  
	        var changed = false  
	        for (j in edges.indices) {  
	            if (res[edges[j].start] == Int.MAX_VALUE) continue  
	            if (res[edges[j].end] > 
		            res[edges[j].start] + edges[j].weight) {  
	                res[edges[j].end] = res[edges[j].start] + edges[j].weight  
	                changed = true  
	            }  
	        }  
	        if (!changed) return res  
	    }  
	    for (i in edges.indices) {  
	        if (res[edges[i].end] > 
		        res[edges[i].start] + edges[i].weight && 
		        res[edges[i].start] != Int.MAX_VALUE) {  
	            println("Negative ring")  
	        }  
	    }  
	    return res  
	}
  
    private fun generateEdges(link: Array<IntArray>): ArrayList<Edge> {  
        val edges = ArrayList<Edge>()  
        for (i in link.indices) {  
            for (j in link.indices) {  
                if (link[i][j] != Int.MAX_VALUE) {  
                    edges.add(Edge(i, j, link[i][j]))  
                }  
            }  
        }  
        return edges  
    }  
}
```

上面代码又进行了一次优化。比如，如果在一次对所有边的遍历中没有发生任何改变，那么其实也没有必要再遍历下去了。所以我们通过一个布尔标记来记录，如果没有改变，直接跳出循环就可以了。并且，这种情况也没必要检测负环，因为检测的手段和循环里的东西也是一样的。

# 4. 实验环境

* OS: Windows 11
* IDE: IDEA
* Language: Kotlin

# 5. 项目测试