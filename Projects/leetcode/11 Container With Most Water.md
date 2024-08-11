---
num: "11"
title: "Container With Most Water"
link: "https://leetcode.cn/problems/container-with-most-water/description/"
tags:
  - leetcode/difficulty/medium
---
找到两根棍，围成的面积最大。那显然，面积的计算是：**两根棍里矮的那个的高度$\times$两根棍的距离**。

最蠢的方法，我们可以把所有棍子的组合都来一遍，显然太慢了。所以我们换个思路。

想要让面积最大，有两点：

- 两根棍的距离越远越好；
- 两根棍的高度越高越好。

我们很难达成第二个目标，因为不遍历是很难得到棍子的高度的。所以，我们选择先满足第一点要求。让两根棍子的距离最远。

这一下就能想到双指针。因此，从左右两边开始，往中间来。

![[Projects/leetcode/resources/Pasted image 20240811174156.png]]

首先，我们算出边上两个棍子的面积。答案是8，那么很显然他不一定是最大的。所以我们要往中间去。那么现在就有问题了：双指针问题，我们往中间去的时候，都是：**因为怎么怎么样，移动i和j中的一个**。那这里的怎么怎么样是什么呢？

我们这么想：不管是i还是j，如果往中间去，那一定是：**会让棍子的距离变短**。那既然棍子的距离都变短了，面积还想要更大，那肯定是**2者中矮的那个要变高**。或者反过来说：

**当往中间走的时候，我首先要丢弃二者中矮的那根棍子**。因为你已经是现在二者中矮的那个了，当横向距离变短时，肯定是要保留高的棍子才对。

所以，在本例中应该让`i++`。反应到一般情况，当：

```cpp
if (height[i] < height[j]) {
	i++;
} else {
	j++;
}
```

然后，每次循环需要先把面积算出来，和最大的比一下。这样就搞定了。给出完整代码：

```cpp
int Solution::maxArea(vector<int>& height) {
    int i = 0, j = height.size() - 1;
    int maxVolume = 0;
    while (i < j) {
        int volume = (j - i) * min(height[i], height[j]);
        if (volume > maxVolume) {
            maxVolume = volume;
        }
        if (height[i] < height[j]) {
            i++;
        } else {
            j--;
        }
    }
    return maxVolume;
}
```

> [!note]
> 我个人感觉，这个解法有点贪心的意思。我每一步都是在寻找局部最优解。首先第一步开始，我要的就是宽度最大，然后当宽度不得不变小的时候，我希望高度最高，这就意味着我抛弃了二者中对最优解不利的那一个，而我的选择依然是一个局部最优解。