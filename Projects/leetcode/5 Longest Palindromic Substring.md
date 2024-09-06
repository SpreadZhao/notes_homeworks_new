---
num: "5"
title: "Longest Palindromic Substring"
link: "https://leetcode.cn/problems/longest-palindromic-substring/description/"
tags:
  - leetcode/difficulty/medium
---
# 题解

这道题和[[Projects/leetcode/516 Longest Palindromic Subsequence|516 Longest Palindromic Subsequence]]是类似的题。一个序列一个串。但是它俩的判断其实是完全不一样的。

先看[[Projects/leetcode/516 Longest Palindromic Subsequence|516 Longest Palindromic Subsequence]]，然后再看这道题。

我们还是搬出来之前的那张图：

![[Projects/leetcode/resources/Drawing 2024-09-06 23.25.00.excalidraw.svg]]

如果能确定中间的串的最长回文子串长度是n，那么左右加上两个一样的字母，最长回文字串的长度还是n+2吗？

**肯定不是**！！！串和序列的区别就在这里。序列只要它俩相等，就总有机会和中间的某些字母组合，因为序列就是可以cancel掉某些字母的；但是串不行。

所以我们根本不知道这两个字母可以和谁组合。换句话说，我们的动态规划去存“最长回文字串的长度”这个信息，是没有意义的。因为我们往两边放上字母的一刻，我们会意识到：我们连中间这个串的哪些部分是回文都不知道，我们存长度又有啥意义呢？

其实如果是回文串的话，我们其实只需要知道这样的信息：

**如果i和j指向的字母，它们构成的串是一个回文串，那么再往两边加一样的字母，那结果还是回文串**。

也就是说，我们只需要知道“**是不是回文**”这个信息就足够了。至于多长，我们直接取出来不就得了？！因为这是串不是序列，如果真的是回文，那么直接拿就行了，不需要像序列一样纠结到底是其中的哪部分。

所以，遍历的方式和[[Projects/leetcode/516 Longest Palindromic Subsequence|516 Longest Palindromic Subsequence]]一样，只不过不是看长度了，看是否是回文。

对于每一个i和j，判断`dp[i][j]`是true还是false。是true表示是回文。而基本情况是`dp[i][i] = true`。如果：

- i和j的距离是1，那么只要两个字母相等就是回文；
- 如果i和j的距离大于1，那么回文的条件是：`s[i] == s[j] && dp[i + 1][j - 1]`。

然后如果是回文，那么我们就收集一下这个回文字串，不断取最长的就好了。

```cpp
string Solution::longestPalindromicSubstring(string s) {  
    if (s.empty()) {  
        return "";  
    }  
    bool dp[s.size()][s.size()];  
    memset(dp, false, sizeof(dp));  
    for (int i = 0; i < s.size(); i++) {  
        dp[i][i] = true;  
    }  
    string res(1, s[0]);  
    for (int j = 1; j < s.size(); j++) {  
        for (int i = j - 1; i >= 0; i--) {  
            if (j - i == 1) {  
                dp[i][j] = s[i] == s[j];  
            } else {  
                dp[i][j] = s[i] == s[j] && dp[i + 1][j - 1];  
            }
            // 根据是否是回文，来收集最长的回文字串。不是回文我们直接不用看了。
            if (dp[i][j] && j - i + 1 > res.size()) {  
                res = s.substr(i, j - i + 1);  
            }  
        }  
    }  
    return res;  
}
```

总结一下，其实本题的动态规划的计算结果和[[Projects/leetcode/516 Longest Palindromic Subsequence|516 Longest Palindromic Subsequence]]不同，没有用来计算答案本身（516的动态规划计算的就是答案，最长回文子序列的长度），只是用来计算一个是否是回文的特征。我们用这个特征来计算回文串的长度，从而不断找到最优解。而本题之所以用动态规划，仅仅是因为：“**一个回文，左右加上两个一样的字母，还是回文**”这个状态转移方程实在太合适了。我们也可以暴力去判断是否是回文，然后不断找最长的。但是那样肯定会超时的。。。

# 遗漏的case

本题遗漏了这个case：

```cpp
// 根据是否是回文，来收集最长的回文字串。不是回文我们直接不用看了。
if (dp[i][j] && j - i + 1 > res.size()) {  
	res = s.substr(i, j - i + 1);  
}
```

这个`j - i + 1 > res.size()`。当时没加，不加的话我们就不是优中选优了。本来你已经找了一个长的，后面又遇到了一个短的回文，那答案就错了。

- [ ] #TODO tasktodo1725642644118 和[[Projects/leetcode/516 Longest Palindromic Subsequence|516 Longest Palindromic Subsequence]]做对比。为啥这两道题都需要双指针而不是单指针？因为这俩答案都可能来自中间的某些部分，所以我们需要两个指针向两个方向扩大才行；之后如果有更多串和序列成对出现的题，也要做对比。类似的系列文章之后也要收集到leetcode project中单独成文。比如字符串专题，动态规划专题等等。 ➕ 2024-09-07 🔼 🆔 9u28j5 