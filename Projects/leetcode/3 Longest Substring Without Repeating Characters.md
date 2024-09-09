---
num: "3"
title: "Longest Substring Without Repeating Characters"
link: "https://leetcode.cn/problems/longest-substring-without-repeating-characters/description/"
tags:
  - leetcode/difficulty/medium
---

# 题解

## 垃圾版

首先，我之前做过。所以我知道这是个slide window。我第一眼看，就感觉应该是要去判断，一个字母是否出现过。所以我搞了个map：

```cpp
map<char, bool>showed;
```

然后挨个遍历每个字母，每次最后都要记为true。同时，如果已经是true了，那么就要重新统计。

这里是我犯傻逼的第一点。我的代码如下：

```cpp
// 确保s.size() > 1
int j = 1, temp = 1, res = 1;
while (j < s.size()) {
	if (showed[s[j]]) {
		showed.clear();
		if (temp > res) {
			res = temp;
		}
		temp = 1;
	} else {
		temp++;
	}
	showed[s[j]] = true;
	j++;
}
```

这里最傻逼的一点就是，当发现showed是true之后，直接把temp置回1就完事儿了。显然这是不对的。应该从滑动窗口起始点的下一个开始。不然的话，看[[#如滑]]。所以，代码改成如下：

```cpp
int i = 0, j = 1, temp = 1, res = 1;
map<char, bool>showed;
showed[s[0]] = true;
while (j < s.size()) {
	if (showed[s[j]]) {
		showed.clear();
		if (temp > res) {
			res = temp;
		}
		temp = 1;
		// 回溯，同时让i记住下一次回溯的位置
		j = i + 1;
		i = j;
	} else {
		temp++;
	}
	showed[s[j]] = true;
	j++;
}
```

这就结束了吗？没有。我又发现了一个遗漏的case。所以我太傻逼了：[[#你总是忘了else分支]]。

改了这个之后，总算过了。完整代码：

```cpp
int Solution::lengthOfLongestSubstring(string s) {
    if (s.empty()) {
        return 0;
    }
    if (s.size() == 1) {
        return 1;
    }
    if (s.size() == 2) {
        if (s[0] == s[1]) {
            return 1;
        }
        return 2;
    }
    int i = 0, j = 1, temp = 1, res = 1;
    map<char, bool>showed;
    showed[s[0]] = true;
    while (j < s.size()) {
        if (showed[s[j]]) {
            showed.clear();
            if (temp > res) {
                res = temp;
            }
            temp = 1;
            j = i + 1;
            i = j;
        } else {
            temp++;
        }
        showed[s[j]] = true;
        j++;
    }
    if (temp == res) {
        res = temp;
    }
    return res;
}
```

当然我感觉又臭又长写的像坨屎。所以我们看看怎么优化一下。

## 牛逼版

首先，还是用滑动窗口的思想。但是我们能不能不回溯？这个问题有一个关键，就是：**只有出现的字母全都不一样的时候，窗口的右边才会长**；而当出现了重复的时候，我们以前的策略是，重置窗口，从原来窗口左边的下一个字母开始。

但是，我们其实可以这样：当出现重复时，让窗口的左边向右滑，滑到不出现为止。我们来模拟一下：

![[Projects/leetcode/resources/Drawing 2024-09-10 01.10.11.excalidraw.svg]]

假设红色的区域内所有的字母都是不重复的。当扫描到蓝色的时候，出现了重复，**那么其实它一定是和红色区域内的某一个字母是重复的**。因此，只要我们能知道红色区域中，重复的字母在哪里，**我们就可以直接让i跳到它的下一个**：

![[Projects/leetcode/resources/Drawing 2024-09-10 01.12.19.excalidraw.svg]]

这样，我们就能够避免j的回溯导致的性能问题。那么问题就变成了：*怎么知道重复的字母在哪里*？其实非常好办，就用一开始的map，只不过value不是出现或者没出现了，而是**这个字母的下标**。这样，只要map中包含这个entry，我们做的就是让：

```cpp
i = showAt[ch] + 1;
```

然后，不管i和j谁变了，我们都在每次循环：

- 记录当前字母出现的下标；
- 更新最长的结果（`j - i + 1`）；
- `j++`。

所以，代码如下：

```cpp
int Solution::lengthOfLongestSubstring2(string s) {
    map<char, int>showAt;
    int i = 0, j = 0, res = 0;
    while (j < s.size()) {
        char ch = s[j];
        if (showAt.count(ch)) {
            i = showAt[ch] + 1;
        }
        showAt[ch] = j;
        res = max(res, j - i + 1);
        j++;
    }
    return res;
}
```

不过，这个代码还是错的。而且，这个代码也是我踩了坑之后才写粗来的。见：[[#你确定让窗口左边往右滑？]]和[[#为啥每次都要更新res？]]。最后正确的代码：

```cpp
int Solution::lengthOfLongestSubstring2(string s) {
    map<char, int>showAt;
    int i = 0, j = 0, res = 0;
    while (j < s.size()) {
        char ch = s[j];
        if (showAt.count(ch)) {
            i = max(i, showAt[ch] + 1);
        }
        showAt[ch] = j;
        res = max(res, j - i + 1);
        j++;
    }
    return res;
}
```

# 遗漏的case

## 如滑

这个case：

```
dvdf
```

答案应该是`vdf`的长度是3。但是我的代码是2。这就是因为我一开始的例子里面没有回溯。如果发现了一个重复的字母，在这里就是`d`，其实应该将指针回到`v`，而不是从第二个`d`继续。

## 你总是忘了else分支

这个case：

```
aab
```

应该输出2，但是我输出1。这么简单的case我咋能落？还真是个傻逼。其实是因为我忘记了跳出循环之后，如果是从else分支跳出的。它只更新了temp但是没有更新res。所以最后也要更新一下：

```cpp
while (j < s.size()) {
	if (showed[s[j]]) {
		showed.clear();
		if (temp > res) {
			res = temp;
		}
		temp = 1;
		j = i + 1;
		i = j;
	} else {
		temp++;
	}
	showed[s[j]] = true;
	j++;
}
if (temp == res) {
	res = temp;
}
```

所以，总结一下箴言：

> [!important]
> 当你的循环里面有if，else，或者各种类似switch分支的时候（总之就是，代码不一定全会执行），一定要检查一下从每种情况跳出循环后还是不是符合预期。

## 你确定让窗口左边往右滑？

首先，我们能肯定的是，那个滑动窗口，一定是只能往右滑的。要么你就别滑。所以看这个case：

```
tmmzuxt
```

最大值应该是5。但是上面的代码会输出4。少了谁？少了最后一个t。为啥会少？我们这么想：当j指向最后一个t的时候，`showAt.count(ch)`的结果是啥？true！那i要滑。往哪儿滑？卧槽？！滑到第二个`m`去了。但是在这之前，i是指向第三个m的。所以，这里的问题就是，滑动窗口要保证往右滑才行。所以i其实不能傻乎乎地就变成map里存的value，只有value比i原来的值大的时候才行：

```cpp
int Solution::lengthOfLongestSubstring2(string s) {
    map<char, int>showAt;
    int i = 0, j = 0, res = 0;
    while (j < s.size()) {
        char ch = s[j];
        if (showAt.count(ch)) {
	        // 保证滑动窗口往右滑
            i = max(i, showAt[ch] + 1);
        }
        showAt[ch] = j;
        res = max(res, j - i + 1);
        j++;
    }
    return res;
}
```

## 为啥每次都要更新res？

我还想这么写：

```cpp
int lengthOfLongestSubstring(string s) {
    map<char, int>showAt;
    int i = 0, j = 0, res = 0;
    while (j < s.size()) {
        char ch = s[j];
        if (showAt.count(ch)) {
            i = max(i, showAt[ch] + 1);
        } else {
	        res = max(res, j - i + 1);
	    }
        showAt[ch] = j;
        j++;
    }
    return res;
}
```

这里的改动就是，如果走的是if分支，也就是i要滑的时候，不更新res。我的理由是，i往右滑是让窗口变小的行为。所以我们这个时候没必要更新res。听着好像挺有道理，但是在`tmmzuxt`这里还是出问题了。

这个其实也是一个很边界的case。因为它满足：

1. 最后一次循环中走的是if分支；
2. 在这次循环中，i原地没动（因为t之前出现的位置是0，`0 + 1 < 2`，2是i现在指的位置）。

而在这次循环中，我们没更新最后的值，res还是上一次j指向`x`的时候的值，是4。之后就退出了。但是实际上答案应该是5。

所以和[[#你总是忘了else分支]]一样，我们也要检查这种case。不过说实话，还是不太好查的。