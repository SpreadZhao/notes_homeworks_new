---
num: "300"
title: "Longest Increasing Subsequence"
link: "https://leetcode.cn/problems/longest-increasing-subsequence/description/"
tags:
  - leetcode/difficulty/medium
---
[最长递增子序列（nlogn 二分法、DAG 模型 和 延伸问题） | 春水煎茶](https://writings.sh/post/longest-increasing-subsequence-revisited)

这题有点男崩。属于是我好久没写动态规划，写迷糊了。

我想得太复杂了，我想的是用双指针，表示子区间里的最长递增序列。这个其实没问题，但是我想了另一件事：

**如果x和序列S要组成最长递增序列的话，那么x要小于S的最长子序列的最小值**。单看这个是没问题的。但是如果加上for循环遍历，就会发现这个信息根本没法收集。比如`4 5 3`这个例子，因为你只往一个方向遍历，你会先遍历到`5 3`，然后才会遍历到`4 5 3`。这个时候，你会发现4不是比`5 3`中的最小值`3`小的，所以你认为4没办法和前面构成一个最长的递增序列。单事实上，`4 5`本身也是一个最长自序列。所以这里会遗漏一些case。

贴粗来我错误的代码：

```cpp
int Solution::lengthOfLIS(vector<int> &nums) {
    const size_t size = nums.size();
    int dp[size][size];
    int dp2[size][size];
    memset(dp, 0, sizeof(dp));
    memset(dp2, 0, sizeof(dp2));
    for (int i = 0; i < size; i++) {
        dp[i][i] = nums[i];
        dp2[i][i] = 1;
    }
    for (int j = 1; j < size; j++) {
        for (int i = j - 1; i >= 0; i--) {
            if (nums[i] < dp[i + 1][j]) {
                dp[i][j] = nums[i];
                dp2[i][j] = dp2[i + 1][j] + 1;
            } else {
                dp[i][j] = dp[i + 1][j];
                dp2[i][j] = dp2[i + 1][j];
            }
        }
    }
    return dp2[0][size - 1];
}
```

接下来重新来一遍。如果已经有了一个序列，它的最长递增子序列已知，为S，长度为n：

![[Projects/leetcode/resources/Drawing 2024-08-23 23.14.30.excalidraw.svg]]

那么如果后面要再接一个字符。这个新序列S'的长度只有可能是两种情况：

- n
- n+1

这里，我们**必须选择接的字符！必须选择接的字符！必须选择接的字符**！因为只有选择了，我们才能把之前序列S的结果传递下去。即使长度没变，也要传递。

~~然后我们就能发现，如果已经知道了序列S的最长自序列，那么其实我们等于知道了，序列S的所有从0开始的子串的最长子序列的长度。还是按照dp来举例子，如果我们已经把前i个字符都确定了，那么实际上，从`0-0`到`0-i`的所有串的最长自序列的长度我们都是知道的。因此将这个存成dp数组，得到：~~

```cpp
dp[0] = 1;  // 从第0个字符到第0个字符的字串的最长自序列的长度是1
dp[i] >= 1; // 从第0个字符到第i个字符的字串的最长自序列的长度至少是1
```

~~而对于任意一个序列S右边的字符j，只要`nums[j] > nums[i]`其实就能得到~~

```cpp
dp[j] = dp[i] + 1;
```

~~你可能不知道我在说什么，画个图：~~

~~![[Projects/leetcode/resources/Drawing 2024-08-23 23.27.01.excalidraw.svg]]~~

~~如果右边的数字，比左边的数字大，那么以左边的数字为结尾的序列，它的最长自序列就一定可以~~

当我上面全部都在放屁。这个思想没这么复杂。现在假设就2个数字：

```
x y
```

x我们已知，结果一定是1。那么x和y合起来，最后的结果就要看y>x是不是成立。如果成立，那么序列就是2。如果不成立，那么就还是1。

```
x y z
```

现在看x y z。在讨论z的时候，我们已经把x和y的所有结果都确定了。所以我们就是逐个遍历x和y，如果z比x大，那么结果应该是x对应的值+1；如果z比y大，那么结果应该是y对应的值+1……最后，我们要在哲里面再取一个最大的。

上面这部分的代码就是：

```cpp
for (int j = 0; j < i; j++) {
	if(nums[i] > nums[j]) {
		dp[i] = std::max(dp[i], dp[j] + 1);
	}
}
```

当然，如果自己跟自己，结果一定是1。

好了，这题就讲完了。代码：

```cpp
// 注意这里i和j是反的，草了
int Solution::lengthOfLIS(vector<int> &nums) {
    const size_t size = nums.size();
    int dp[size];
    memset(dp, 0, sizeof(dp));
    dp[0] = 1;
    int res = 1;
    for (int i = 1; i < size; i++) {
        dp[i] = 1;
        for (int j = 0; j < i; j++) {
            if(nums[i] > nums[j]) {
                dp[i] = std::max(dp[i], dp[j] + 1);
            }
        }
        res = std::max(res, dp[i]);
    }
    return res;
}
```

当然，这个图：

![[Projects/leetcode/resources/Drawing 2024-08-23 23.27.01.excalidraw.svg]]

还是对的。如果大于成立，那么我们找的就是框起来的这部分子序列的长度。如果不大于的话，那选的还是不带j的框起来的子序列的长度。然后对于每一个i，我们都要选一个长度，在所有的长度里取最大值。

最后，这里返回的最终答案，又进行了一次筛选：

```cpp
res = std::max(res, dp[i]);
```

我们看这个例子。如果数组是：

```cpp
[1,3,6,7,9,4,10,5,6]
```

我们最后的dp数组是：

![[Projects/leetcode/resources/Pasted image 20240823235326.png|200]]

这里就会发现，7和8并不是最大的。回到数字中，能发现最后两个数字是5 6，都比10小。这就代表着一件最重要的事情：

`dp[i]`表示的其实是，从0开始，到第i个字符为止。它们的子序列里，**以第i个字符为结尾**的子序列里最长的长度。而并不是所有子序列里最长的长度。

如果你不理解这个点，你永远也不会知道这个答案到底在算什么。

- [ ] #TODO tasktodo1724428598756 后面好好重新树立一下这个算法，还有其它的方法也补上。 ➕ 2024-08-23 🔼 🆔 97zb3t 