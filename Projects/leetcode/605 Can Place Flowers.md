---
num: "605"
title: "Can Place Flowers"
link: "https://leetcode.cn/problems/can-place-flowers/description/"
tags:
  - leetcode/difficulty/easy
---
这个问题非常煞笔。我一开始的思路非常脑残：

- 从头开始，找到第一个1；
- 从头到第一个1中间如果有n个0，那么
	- n是偶数，可以种$\dfrac{n}{2}$朵花；
	- n是奇数，可以种$\dfrac{n - 1}{2}$朵花；
- 之后不断寻找下一个1。每找到一个，算出中间0的数量。如果：
	- n是偶数，可以种$\dfrac{n}{2} - 1$朵花；
	- n是奇数，可以种$\dfrac{n + 1}{2} - 1$朵花；
- 最后找不到了，开始统计最后一个1后面的0的个数。如果：
	- n是偶数，可以种$\dfrac{n}{2}$朵花；
	- n是奇数，可以种$\dfrac{n - 1}{2}$朵花；
- 如果从头开始，连一个1都没找到，那么证明整个数组全是0，此时统计0的数量。如果：
	- n是偶数，可以种$\dfrac{n}{2}$朵花；
	- n是奇数，可以种$\dfrac{n + 1}{2}$朵花。

感觉很蠢对吧。蠢就对了。这个b逻辑导致我写出了下面的狗屎代码：

```cpp
int findNext1(vector<int> &flowerbed, int start) {
    for (int i = start + 1; i < flowerbed.size(); ++i) {
        int flower = flowerbed.at(i);
        if (flower == 1) {
            return i;
        }
    }
    return -1;
}

bool Solution::canPlaceFlowers(vector<int> &flowerbed, int n) {
    int zeroCount = 0, lastIndexOf1 = 0, indexOf1 = 0, flowerCount = 0;
    int first1Index = findNext1(flowerbed, -1);
    if (first1Index >= 0) {
        zeroCount = first1Index;
        if (isEven(zeroCount)) {
            flowerCount += zeroCount / 2;
        } else {
            flowerCount += (zeroCount - 1) / 2;
        }
        indexOf1 = first1Index;
        lastIndexOf1 = first1Index;
        while ((indexOf1 = findNext1(flowerbed, indexOf1)) >= 0) {
            zeroCount = indexOf1 - lastIndexOf1 - 1;
            if (isEven(zeroCount)) {
                flowerCount += zeroCount / 2 - 1;
            } else {
                flowerCount += (zeroCount + 1) / 2 - 1;
            }
            lastIndexOf1 = indexOf1;
        }
        if (lastIndexOf1 < flowerbed.size() - 1) {
            zeroCount = flowerbed.size() - lastIndexOf1 - 1;
            if (isEven(zeroCount)) {
                flowerCount += zeroCount / 2;
            } else {
                flowerCount += (zeroCount - 1) / 2;
            }
        }
    } else {
        zeroCount = flowerbed.size();
        if (isEven(zeroCount)) {
            flowerCount += zeroCount / 2;
        } else {
            flowerCount += (zeroCount + 1) / 2;
        }
    }
    return flowerCount >= n;
}
```

中间很多变量，而且很多边界case调来调去。最后总算是过了。

直到我看到我最一开始的版本，才发现我就是一个大傻逼。首先，是`1000...0001`这种情况，其实偶数的情况是根本没必要的。比如中间有4个0，那么最多也是只能种1朵花。但是没必要用$\dfrac{n}{2} - 1$了，你即使带到$\dfrac{n + 1}{2} - 1$里答案也是1。所以中间大while循环里的if分支根本就是p用没有。

还有就是一开始的连续0和最后的连续0。为什么要搞一堆乱七八糟的公式？其实如果是`001`这样的情况，其实完全可以在左边再补上一个`10`变成`10001`，这样就和$\dfrac{n + 1}{2} - 1$这个公式对齐了；对于最右边的连续0也是一样的。

综上，写出下面的代码：

```cpp
int findNext12(vector<int> &flowerbed, int start) {
    for (int i = start + 1; i < flowerbed.size(); ++i) {
        int flower = flowerbed.at(i);
        if (flower == 1) {
            return i;
        }
    }
    return flowerbed.size();
}

bool Solution::canPlaceFlowers2(vector<int> &flowerbed, int n) {
    int i = -1, j = -1, flowerCount = 0;
    while (i < flowerbed.size()) {
        j = findNext12(flowerbed, i);
        int zeroCount = j - i - 1;
        if (i == -1) zeroCount++;
        if (j == flowerbed.size()) zeroCount++;
        flowerCount += zeroCount == 0 ? 0 : (zeroCount + 1) / 2 - 1;
        i = j;
    }
    return flowerCount >= n;
}
```

最后，您猜怎么着？还是没过！后来debug我惊讶地发现，在第一次while循环里，i是-1，flowerbed的size是5。但是结果居然是false！我感觉就是不同类型的变量比较的时候的问题。看了这篇文章[c++ - Why is (-1 < a.size()) false, even though std::vector's size is positive? - Stack Overflow](https://stackoverflow.com/questions/16250058/why-is-1-a-size-false-even-though-stdvectors-size-is-positive)后发现，是因为`flowerbed.size()`的类型是无符号的，所以用-1去比较是根本没法比较的。所以这里还要加上一个条件：

```cpp
while (i == -1 || i < flowerbed.size())
```