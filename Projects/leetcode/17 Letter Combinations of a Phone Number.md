---
num: "17"
title: "Letter Combinations of a Phone Number"
link: "https://leetcode.cn/problems/letter-combinations-of-a-phone-number/"
tags:
  - leetcode/difficulty/medium
---
这题就属于最经典的树型展开。因为要输出的是所有组合，并且是按照输入的字母顺序的组合。

比如我们输入`569`：

![[Projects/leetcode/resources/Pasted image 20240825175913.png|200]] 

![[Projects/leetcode/resources/Drawing 2024-08-25 17.59.41.excalidraw.svg]]

而去遍历这样的树型，最常用的方式就是递归。那么首先就要知道，**每一次递归都需要做什么**。现在举个粒子。假设我们处于下图中的位置：

![[Projects/leetcode/resources/Drawing 2024-08-25 18.09.05.excalidraw.svg]]

那么我们其实应该已经得到了一个字符串`jm`，然后我们要做的，就应该是：**分别把`w, x, y, z`拼到字符串`jm`上，生成`jmw, jmx, jmy, jmz`并添加到结果集合中**。

非常清晰。并且，这样也意味着，每生成了一个字符串，我们也要将它传递给更深层的递归以便其拼接。

我们就叫这个函数为`putCh`：

```cpp
void putCh(vector<string> &res, string digits, string letters, int digitIndex) {
    // 1. 得到当前数字对应的所有字母
    // 2. 对每个字母，将其拼接到已有的字母letters后面，然后进行递归
}
```

显然，这个递归终止的条件，就是“没有数字了”。所以只需要判断`digitIndex`和`digits.size()`的大小即可。

最后，一个小问题，怎么得到当前数字对应的字母。有114514种方法，这里我就随便写了一个。直接上代码：

```cpp
static const vector<string> digitsToLetters = {
    "",         // 0
    "",         // 1
    "abc",
    "def",
    "ghi",
    "jkl",
    "mno",
    "pqrs",
    "tuv",
    "wxyz"      // 9
};

void putCh(vector<string> &res, string digits, string letters, int digitIndex) {
    if (digitIndex >= digits.size()) {
        res.emplace_back(letters);
        return;
    }
    for (auto ch : digitsToLetters[digits[digitIndex] - '0']) {
	    // ch is [a, b, c] or [d, e, f] or ...
        putCh(res, digits, letters + ch, digitIndex + 1);
    }
}
```

> [!attention]
> 这里需要注意我是怎么拼接的。直接传入`letters + ch`，这样实参`letters`就总是上一次递归经过拼接的新内容。

最后，只需要从第一个数字开始递归，最后res里面存的就是答案：

```cpp
vector<string> Solution::letterCombinations(string digits) {
    if (digits.empty()) {
        return {};
    }
    vector<string> letters;
    putCh(letters, digits, "", 0);
    return letters;
}
```
