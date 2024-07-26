---
num: "881"
title: "Boats to Save People"
link: "https://leetcode.cn/problems/boats-to-save-people/description/"
tags:
  - leetcode/difficulty/medium
---
经典的贪心思想。我想用最少数量的船来装这些人，那么就要保证**2个人的船的数量是最多的**。因此，我们希望的是每一个人上船之后，都能再带上一个人。

然而，那些很重的人如果上了船，就很有可能无法再带人了。比如limit是5，但是一个人重就是5，那么显然这个人**必须只能用一条船去带**。所以，我们的思路就是：

**从最重的那个人开始算，能带一个算一个**。

那么现在问题来了。举个例子：

```c
// 默认排序，后面也是这样
people: [1 2 3 4 5 6]
limit: 8
```

那么我先让6上去，然后尽可能带。那问题是：*带谁*？好像1和2都可以。那么我到底带谁，才能保证本次的解法是最优的呢？

想当然，我们会带最轻的那个人。因为只有他是最有可能和最重的那个人一起上船的。但是，有没有一种可能，带了最轻的反而让船的数量变多了呢？

我们举个例子。假设：

```c
people: [a b c d]
limit: e
```

这样的话，如果：

```c
d + b <= e
c + a <= e
```

就只需要两条船就行。

如果出现：

```c
d + a <= e
b + c > e
```

就需要3条船才行。因为b和c都只能用1条船来接。

现在我们希望证明的就是，后面这种情况不存在。联立一下这些式子：

```c
d + b <= e                // 1
c + a <= e                // 2
d + a <= e                // 3
b + c > e                 // 4
a <= b <= c <= d <= e     // 5
```

我们能发现，如果1 2 3 5都成立的话，4是不可能出现的。其实只需要1 4 5就可以了。如果`d + b <= e`的话，d还是一个大的数字。那么`c`这个比`d`还小的数字其实加上b最多也就是等于e，不可能大于。因此这个情况是不存在的。

总之，我们只要保持：每个最重的尽可能带一个最轻的，就是最优解了。

很容易想到双指针：

```cpp
int Solution::numRescueBoats(vector<int> &people, int limit) {
    int i = 0, j = people.size() - 1;
    std::sort(people.begin(), people.end());
    int numOfBoats = 0;
    while (i <= j) {
        if (i == j) {
            numOfBoats++;
            break;
        }
        int heavy = people.at(j);
        int light = people.at(i);
        if (heavy + light <= limit) {
	        // 带一个最轻的
            i++;
            j--;
        } else {
	        // 带不了
            j--;
        }
        numOfBoats++;
    }
    return numOfBoats;
}
```

代码简化一下：

```cpp
int Solution::numRescueBoats(vector<int> &people, int limit) {
    std::sort(people.begin(), people.end());
    int i = 0, j = people.size() - 1;
    int numOfBoats = 0;

    while (i <= j) {
        if (people[i] + people[j] <= limit) {
            i++;
        }
        j--;
        numOfBoats++;
    }
    return numOfBoats;
}
```

