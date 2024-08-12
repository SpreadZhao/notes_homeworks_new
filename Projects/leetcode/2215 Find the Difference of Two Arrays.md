---
num: "2215"
title: "Find the Difference of Two Arrays"
link: "https://leetcode.cn/problems/find-the-difference-of-two-arrays/"
tags:
  - leetcode/difficulty/easy
---
这题其实很好想，甚至可以直接想出来快的做法。反正性能提升点就在：判断一个数字是否属于一个列表。如果是vector，ArrayList这种结构，那判断起来就很慢；而如果是HashSet这种就很快了。因为HashSet可以直接用我要查的元素算哈希然后直接定位，不用一个个去遍历。

> [!note]
> 这里补充一点，HashSet其实和[[Study Log/java_kotlin_study/java_kotlin_study_diary/hash_map|HashMap]]几乎是一样的。区别就是HashSet的key和value都是key，存了一份重复的。你可以看看Java里HashSet的实现，一看就懂。另外，c++里的实现也是几乎一样的。

所以，你可以直接写出Kotlin的代码。构造两个set，然后选就行了。这里甚至可以配合filter直接一步到位：

```kotlin
fun findDifference(nums1: IntArray, nums2: IntArray): List<List<Int>> {
	val set1 = nums1.toSet()
	val set2 = nums2.toSet()
	return listOf(
		set1.filter { it !in set2 },
		set2.filter { it !in set1 }
	)
}
```

当然，c++我还不太熟。所以这里先给一个最蠢的解法，就是一个个判断：

```cpp
bool contains(vector<int> &nums, int target) {
    const auto res = find(nums.begin(), nums.end(), target);
    return res != nums.end();
}

vector<vector<int>> Solution::findDifference(vector<int>& nums1, vector<int>& nums2) {
    vector<int> list1;
    vector<int> list2;
    for (auto num : nums1) {
        if (!contains(nums2, num) && !contains(list1, num)) {
            list1.emplace_back(num);
        }
    }
    for (auto num : nums2) {
        if (!contains(nums1, num) && !contains(list2, num)) {
            list2.emplace_back(num);
        }
    }
    return vector<vector<int>> {list1, list2};
}
```

这里我们要注意if里面第二个条件，也就是`!contains(listX, num)`。之前我们kotlin实现中构造set的时候，**其实底层已经帮我们去重了**。所以我们自己写的时候，需要手动进行去重。

那么，怎么提高呢？当然是使用set。当然，c++的set使用和java没什么区别。所以代码也非常好看懂：

```cpp
vector<vector<int>> Solution::findDifference2(vector<int>& nums1, vector<int>& nums2) {
    unordered_set<int> set1, set2;
    for (int num : nums1) {
        set1.insert(num);
    }
    for (int num : nums2) {
        set2.insert(num);
    }
    vector<vector<int>> res(2);
    for (int num : set1) {
        if (!set2.count(num)) {
            res[0].push_back(num);
        }
    }
    for (int num : set2) {
        if (!set1.count(num)) {
            res[1].push_back(num);
        }
    }
    return res;
}
```