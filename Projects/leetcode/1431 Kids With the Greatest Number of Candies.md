---
num: "1431"
title: "Kids With the Greatest Number of Candies"
link: "https://leetcode.cn/problems/kids-with-the-greatest-number-of-candies/description/"
tags:
  - leetcode/difficulty/easy
---
这题真没啥好说的，直接一遍过。唯一要注意的，就是最多的candie可能有多个，所以是`>=`最大值：

```cpp
vector<bool> Solution::kidsWithCandies(vector<int> &candies, int extraCandies) {
    auto maxCandies = max_element(candies.begin(), candies.end());
    vector<bool> res;
    if (maxCandies != candies.end()) {
        const int maxCandiesCount = *maxCandies;
        for (const auto candie : candies) {
            res.emplace_back(candie + extraCandies > maxCandiesCount);
        }
    }
    return res;
}
```