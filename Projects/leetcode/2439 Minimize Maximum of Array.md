---
num: "2439"
title: "Minimize Maximum of Array"
link: "https://leetcode.cn/problems/minimize-maximum-of-array/description/"
tags:
  - leetcode/difficulty/medium
---

# 题解

让一个数组的最大值最小。只能用这种操作：让第i个值-1，然后让第i - 1个值+1。可以进行无限次这种操作。

这道题就属于那种，做过的都会做，但是没做过的咋jb想也想不出来。这道题需要知道下面的观点：

> [!attention] 假想
> 我们假想，一个数组对应着一堆方块。比如`[1, 2, 3]`对应着三摞方块，高度分别是1 2 3。

1. 就像一堆方块一样，我可以把当前这个位置的方块**往前抹**，但是不能往后；
2. 如果前面的方块比这个位置的高，那是抹不回去的；
3. 一次虽然只能抹一个方块，但是没限制次数，所以其实就是可以**无限抹**。

比如，这个数组和对应的方块是是这样的：

![[Projects/leetcode/resources/Drawing 2024-10-04 01.30.46.excalidraw.svg]]

那么，其实我**抹匀**之后，可以是这样的：

![[Projects/leetcode/resources/Drawing 2024-10-04 01.33.10.excalidraw.svg]]

> 颜色不重要，只要抹匀了就行。

所以我们可以发现，对于任意一个位置k，只要试图抹匀从1-k的所有方块，里面的最大值就是我想要的。换句话说：

```cpp
int avg = sum(0, k - 1) / k;
```

这里的avg就是我能要的最大值。当然要做**向上取整**，因为多出来的方块只能摞在最上面。

所以，我们对于这个数组的每一个元素（除了第一个，因为没用）做一遍这个操作，得到一堆avg，从里面选一个最大的，就是这道题的答案。这就有点像动态规划的思想了（我之前认为是贪心，但是现在看还是动态规划），一共n个数，编号0-n-1。我们对于每一个下标i (0 < i < n)，我们考虑的都是规模为i的时候的最优解。然后从这些最优解里选一个最最优的。这个好像和[[Homework/Algorithm/practice2#3.4 Max Sum|Max Sum]]的思路有点像。

上代码：

```cpp
int Solution::minimizeArrayValue(vector<int> &nums) {
    long minMax = nums[0];
    long sum = minMax;
    for (int i = 1; i < nums.size(); i++) {
        sum += nums[i];
        long avg;
        if (sum % (i + 1) == 0) {
            avg = sum / (i + 1);
        } else {
            avg = sum / (i + 1) + 1;
        }
        minMax = max(minMax, avg);
    }
    return static_cast<int>(minMax);
}
```

- [ ] #TODO tasktodo1727977693064 二分查找的解法。 ➕ 2024-10-04 🔽 🆔 ye6vpk 

# 遗漏的case

## 能抹几次？

我一开始就没意识到最重要的一点，可以抹无限次。所以我每次遍历到i，只算了i和i-1的抹，然后真的把数组修改了，然后寄托于这个修改结果能传递下去：

```cpp
int Solution::minimizeArrayValueError(vector<int> &nums) {
    int minMax = nums[0];
    for (int i = 1; i < nums.size(); i++) {
        if (nums[i] > minMax) {
            int sum = nums[i] + nums[i - 1];
            if (sum % 2 == 0) {
                nums[i - 1] = sum / 2;
                nums[i] = sum / 2;
            } else {
                nums[i - 1] = sum / 2;
                nums[i] = sum / 2 + 1;
            }
            if (i == 1) {
                minMax = nums[i];
            } else if (nums[i] > minMax) {
                minMax = nums[i];
            }
        }
    }
    return minMax;
}
```

然后我发现，这个虽然能过那两个测试case，但是问题很大。就比如最一开始的1, 2, 6：

![[Projects/leetcode/resources/Drawing 2024-10-04 01.30.46.excalidraw.svg]]

如果带入我这个方法，那么算1和2的时候结果不变还是1 2，因为我把大值保持在后一位；然后算2 6的时候就有问题了，结果是4 4。但是真正答案应该是三个一起算，结果是3。我只算i和i-1就是不对的，应该从0-i全部考虑进来。

## 报了

emm，就是字面意思。所以我结果里换成了long。