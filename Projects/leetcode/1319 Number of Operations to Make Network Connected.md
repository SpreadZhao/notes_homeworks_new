---
num: "1319"
title: "Number of Operations to Make Network Connected"
link: "https://leetcode.cn/problems/number-of-operations-to-make-network-connected/description/"
tags:
  - leetcode/difficulty/medium
---
# DFS

这道题首先要看一下DFS的实现思路。我记得之前写过一个：[[Article/story/2023-03-22|2023-03-22]]。当时的我还是很蠢，现在重新给一下dfs的实现。

leetcode的dfs不是用二维数组的。是类似这样：

```cpp
[[0,1],[0,2],[1,2]]
```

也就是直接给边。所以我们可以自己稍微构造一下。不然查的时候会比较麻烦。

```cpp
map<int, vector<int>> buildMapForEdges(const vector<vector<int>> &edges) {
    map<int, vector<int>> m;
    for (auto &edge : edges) {
        int a = edge[0];
        int b = edge[1];
        if (!m.count(a)) {
            m[a] = vector<int>{};
        }
        if (!m.count(b)) {
            m[b] = vector<int>{};
        }
        m[a].emplace_back(b);
        m[b].emplace_back(a);
    }
    return m;
}
```

上面的逻辑很好懂，就不讲了。这样我们用这个map一查，就能查到一个节点的所有邻居。

然后是DFS的逻辑。我们先从单个结点的dfs讲。也就是：**从一个节点开始搜索，一直搜到搜不到为止**。

因此，我们首先就是需要有一个标记，去看每个节点是否被访问过：

```cpp
bool visited[n];
fill_n(visited, n, false);
```

比如现在我们这个图有6个节点，我要从3号开始搜索。那么思路就是：

- 如果3号已经被访问过，直接返回；
- 将3号标记为访问；
- 得到3号的所有邻居，通过刚刚的map；
- 如果邻居没被访问过，那么对邻居重复上面的动作。

我们画个图来解释一下：

![[Projects/leetcode/resources/Drawing 2024-08-09 00.26.01.excalidraw.svg]]

这个情况，构建出来的map应该是这样的：

```cpp
<0, [1, 3]>
<1, [0, 4]>
<2, [5]>
<3, [0, 4]>
<4, [1, 3]>
<5, [2]>
```

现在假设这个图还都没被访问过，我们从3号开始访问。

首先，标记3号访问：

![[Projects/leetcode/resources/Drawing 2024-08-09 00.30.44.excalidraw.svg]]

然后，开始拿3号的邻居，那肯定是0号。所以对0号执行递归dfs。之后0号也被标记访问：

![[Projects/leetcode/resources/Drawing 2024-08-09 00.31.53.excalidraw.svg]]

然后就要拿0的邻居了。首先是1，所以1号也递归执行dfs。1号也被标记：

![[Projects/leetcode/resources/Drawing 2024-08-09 00.33.08.excalidraw.svg]]

然后拿1号的邻居。这里拿到的第一个是0，已经被访问过了，所以拿第二个，也就是4号。之后访问4号。

之后，1号所有的邻居都访问完了。所以跳回上一次递归，也就是之前0号的邻居那里。

跳回去之后会拿0的第二个邻居3，但是3早就被访问过了。所以0号也跳出递归。

这一跳就是到了最初层0的邻居。开始拿第二个也就是4，但是4也被访问过了，所以这里就最终退出了。

**经过DFS，我们找到了一个孤岛**。

看这些逻辑，我们很容易写出dfs的核心代码：

```cpp
void dfsCore(int start, const map<int, vector<int>>& edgesMap, bool visited[]) {
	// 如果已经被访问过了，直接返回。
    if (visited[start]) {
        return;
    }
    // 访问它。
    visited[start] = true;
    // 这里是因为有些单个的节点，如果不加这个后面就crash了。
    if (!edgesMap.count(start)) {
        return;
    }
    // 开始遍历它的邻居，如果没访问过就递归它。
    for (const auto neighbor : edgesMap.at(start)) {
        if (!visited[neighbor]) {
            dfsCore(neighbor, edgesMap, visited);
        }
    }
}
```

上面是对一个节点的DFS。通常我们需要对图中的每个节点进行DFS，来收集一些信息。比如说本题中的孤岛的个数。

所以，总体的思路如下：

- 创建每个节点的访问标记，初始都是false；
- 构建节点连接关系的结构，二维数组或者临界表都行；
- 对每个节点，如果这个节点没访问过，对它进行DFS；
- 如果成功进行DFS，将孤岛个数+1，表示发现一个新岛屿。
- 返回岛屿的个数。

```cpp
int dfs(const int n, const vector<vector<int>>& edges) {
    int num = 0;
    bool visited[n];
    fill_n(visited, n, false);
    const auto map = buildMapForEdges(edges);
    // dfs from 0 to n-1
    for (int i = 0; i < n; i++) {
        if (!visited[i]) {
            num++;
            dfsCore(i, map, visited);
        }
    }
    return num;
}
```

# Solution

那么这题的思路是什么呢？我们要明确一些事情：

- n个节点，有多少个边能保证连通？当然是越多越好。但是最少的边是多少个？答案是n-1个。**因为一个图，边最少，还保证连通的情况下，那它就是个树**；
- 通过对整个图的每个节点进行DFS，就能得到图中所有孤岛的个数。而每个孤岛，都是1个或多个节点组成的；
- 那些多个节点组成的孤岛，必然是有边。而这里面的边就可能会有多出来的。因为这个孤岛一定是连通的，所以这个孤岛的边数必然是`>= n - 1`的；
- 一个孤岛和一个节点有区别吗？没有！当然，是指在连通性上。**如果我们有m个孤岛，那让这些孤岛也连通的最小边数还是m-1**；
- 现在这么想：我们总共的边数是知道的。如果边数e确定能保证`e >= n - 1`，那么这必然是个有解的，反之必然无解，要返回-1；
- 在有解的情况下，我们需要的最小边数是多少？其实就是让所有孤岛连通的边数m-1。我们不要被题里的**移动边**这个操作给迷惑，它只问了移动的个数，所以移动这个行为我们是不用关心的。

- [ ] #TODO tasktodo1723135765294 证明为什么这样的移动不会破坏孤岛的连通性。

所以，这题的解题思路就是：

- 如果给的边数不够n-1，直接返回-1；
- 对每个节点DFS，找到孤岛的个数；
- 返回孤岛的个数-1。

```cpp
int Solution::makeConnected(int n, vector<vector<int>>& connections) {
    if (connections.size() < n - 1) {
        return -1;
    }
    CommonUtil::DFSResponse response = CommonUtil::dfs(n, connections);
    return response.islandNum - 1;
}
```

- [ ] #TODO tasktodo1723135784737 还有并查集的解决思路。
