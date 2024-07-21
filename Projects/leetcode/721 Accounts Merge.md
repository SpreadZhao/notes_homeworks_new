---
num: "721"
title: "Accounts Merge"
link: "https://leetcode.cn/problems/accounts-merge/description/"
tags:
  - leetcode/difficulty/medium
---
本题的解决思路是哈希表+并查集。因此先给出并查集的一些基础知识。

# 并查集

[01. 并查集知识 | 算法通关手册（LeetCode） (itcharge.cn)](https://algo.itcharge.cn/07.Tree/05.Union-Find/01.Union-Find/)

并查集是一个树组成的森林。传统我们写一个树，比如用数组，都是用父节点的编号，获得儿子节点的编号：[[Homework/Algorithm/practice1#3.2 Priority Queue|practice1]]。但是并查集不一样，它是用**子节点指向父节点**。比如有一棵树是这样的：

![[Projects/leetcode/resources/Drawing 2024-07-21 02.16.12.excalidraw.svg]]

那么这个节点的数组应该是这样设计的：

| ... | 4   | 5   | 6   | 7   |
| --- | --- | --- | --- | --- |
| ... | 5   | 7   | 7   | 7   |

根节点指向自己，这样我们通过判断这个数组的编号和值相等就能判断出是否是根节点。

另外，这个数组的特点就是，index是节点本身，value是index的父节点。所以这个数组通常叫`parent`。

并查集一开始都是单独的元素。比如集合里一共有8个元素，那么一开始数组里就是：

| 0   | 1   | 2   | 3   | 4   | 5   | 6   | 7   |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0   | 1   | 2   | 3   | 4   | 5   | 6   | 7   |

每个index的父亲都指向自己，代表现在一共有8棵树，每棵树只有一个节点，它们都是根节点，所以`parent[index] == index`。

代码如下：

```cpp
UnionFind::UnionFind(int n) {
    parent.resize(n);
    for (int i = 0; i < n; i++) {
        parent[i] = i;
    }
}
```

然后我们还是说个简单的，寻找元素。假设现在因为某些情况，这个并查集已经变成了这样：

![[Projects/leetcode/resources/Drawing 2024-07-21 02.26.34.excalidraw.svg]]

那数组就是这样的：

| 1   | 2   | 3   | 4   | 5   | 6   | 7   | 8   |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1   | 2   | 3   | 5   | 7   | 7   | 7   | 8   |

有个函数叫find，那么对4，5，6，7调用find的结果应该都是7。所以思路就是，一直找，直到找到根节点为止。那么什么是根节点呢？我们刚刚说过，`parent[index] == index`就是。因此代码：

```cpp
int UnionFind::find(int index) {
    while (parent[index] != index) {
        index = parent[index];
    }
    return index;
}
```

最后是合并。其实合并才是并查集的核心功能。而且，并查集和树其实没有必然关系。也就是说，并查集可以不用树来实现。我们来看看并查集的核心操作：并。有个函数叫union，接受两个index。经过union之后，**两个index所属的集合**就被并到一块了。还是一开始的8棵树，现在如果我要调用`union(4, 5)`，结果就是：

$$
0, 1, 2, 3, \{4, 5\}, 6, 7
$$

然后我调用`union(6, 7)`，结果就是：

$$
0, 1, 2, 3, \{4, 5\}, \{6, 7\}
$$

最后调用`union(4, 6)`**或者**`union(4, 7)`或者。。。，反正是两个集合里的元素，结果就是：

$$
0, 1, 2, 3, \{4, 5, 6, 7\}
$$

union才是并查集的核心功能，find只是帮助你找它在哪个集合里。所以这里我们用树实现比较快。

要合并两棵树，我们只需要把一棵树的根节点指向另一棵树的根节点：

```cpp
void UnionFind::unionSet(int index1, int index2) {
    int root1 = find(index1);
    int root2 = find(index2);
    parent[root1] = root2;
}
```

有了这些功能，其实我们就已经可以开始做这道题了。所以剩下的内容（比如路径压缩等）就先不展开了，接下来再说。

# 思路

其实看到这道题，就能发现是一个典型的并查集的应用场景。为什么？并查集因为有【并】这个功能，所以它可以将分散在不同团体里的，但是属于同一个“人”的东西给提取出来并到一块儿。

首先，为了迎合并查集的思路，我们需要给所有的邮箱编一个号，邮箱就是一个字符串。因此如果出现了两个一样的邮箱，那么它们的编号也是一样的。这里我们用一个map，key用邮箱的字符串，value存邮箱的编号：

![[Projects/leetcode/resources/Pasted image 20240721151232.png]]

就像这样。代码写出来如下：

```cpp
map<string, int> emailToIndex;
int emailsCount = 0;
for (auto& account : accounts) {
	int size = account.size();
	// 从account[1]开始才是邮箱。
	for (int i = 1; i < size; i++) {
		string& email = account[i];
		if (!emailToIndex.count(email)) {
			emailToIndex[email] = emailsCount++;
		}
	}
}
```

这样，即使是不同的account内，只要用emailToIndex查一下，就能去操作同一个邮箱了。

下一步，我们需要【并】了。怎么并呢？显然，对于同一个account，里面的邮箱是肯定能并起来的：

![[Projects/leetcode/resources/Pasted image 20240721151843.png]]

所以，我们按照上面的编号，应该进行如下操作：

```
union(0, 1)
union(0, 2)
```

> 因为3和4只有一个，所以不操作了。

代码写出来是这样的：

```cpp
UnionFind uf(emailsCount);
for (auto& account : accounts) {
	string& firstEmail = account[1];
	int firstIndex = emailToIndex[firstEmail];
	int size = account.size();
	for (int i = 2; i < size; i++) {
		string& nextEmail = account[i];
		int nextIndex = emailToIndex[nextEmail];
		uf.unionSet(firstIndex, nextIndex);
	}
}
```

这里需要注意。假设一个account非常长，有mail0，mail1一直到mail100。那么把这101个邮箱全并完的思路就是用mail0去分别和剩下的100个做union操作。

并完之后的森林是这样的：

![[Projects/leetcode/resources/Drawing 2024-07-21 15.22.20.excalidraw.svg]]

我们惊奇地发现：现在0，1，2已经跑到一棵树里了。也就是说那个John已经被我们捕捉到了。下面其实只需要按照题目要求把这棵树打印出来就行了。

题解的思路是，先把每个森林的邮箱打印出来。具体的实现是，找到每棵树的根节点，然后这个根节点映射了一堆邮箱，就是这棵树里所有的邮箱。代码是这样的：

```cpp
map<int, vector<string>> indexToEmails;
for (auto& [email, _] : emailToIndex) {
	int index = uf.find(emailToIndex[email]);
	vector<string>& account = indexToEmails[index];
	account.emplace_back(email);
	indexToEmails[index] = account;
}
```

经过这个之后，indexToEmails的情况如下：

![[Projects/leetcode/resources/Pasted image 20240721153843.png]]

最后只需要找到2，3，4对应的人，然后把他们的邮箱（也就是indexToEmails的value）贴到后面就可以了。但是需要注意一下，我们还没有建立index -> name的映射。而这一步可以在最一开始编号的时候，也就是构建emailToIndex的时候同时完成：

```cpp
map<string, int> emailToIndex;
map<string, string> emailToName;
int emailsCount = 0;
for (auto& account : accounts) {
	string& name = account[0];
	int size = account.size();
	for (int i = 1; i < size; i++) {
		string& email = account[i];
		if (!emailToIndex.count(email)) {
			emailToIndex[email] = emailsCount++;
			emailToName[email] = name;
		}
	}
}
```

有了这个之后，想要知道0号对应的人是谁，只需要：

- 在indexToEmails里查0对应的邮箱；
- 在emailToName里查邮箱对应的人。

当然，我们这道题并不需要查0是谁。因为0 1 2都是一个人，而在indexToEmails里我们已经将这个东西都给归纳好了。所以，只需要遍历indexToEmails，将每个key对应的人查出来，然后将value里的邮箱贴到后面就完工了。

最后只需要按照题目要求进行排序即可：

```cpp
vector<vector<string>> merged;
for (auto& [_, emails] : indexToEmails) {
	sort(emails.begin(), emails.end());
	string& name = emailToName[emails[0]];
	vector<string> account;
	account.emplace_back(name);
	for (auto& email : emails) {
		account.emplace_back(email);
	}
	merged.emplace_back(account);
}
return merged;
```

完整代码如下：

```cpp
vector<vector<string>> Solution::accountsMerge(vector<vector<string>>& accounts) {
    map<string, int> emailToIndex;
    map<string, string> emailToName;
    int emailsCount = 0;
    for (auto& account : accounts) {
        string& name = account[0];
        int size = account.size();
        for (int i = 1; i < size; i++) {
            string& email = account[i];
            if (!emailToIndex.count(email)) {
                emailToIndex[email] = emailsCount++;
                emailToName[email] = name;
            }
        }
    }
    UnionFind uf(emailsCount);
    for (auto& account : accounts) {
        string& firstEmail = account[1];
        int firstIndex = emailToIndex[firstEmail];
        int size = account.size();
        for (int i = 2; i < size; i++) {
            string& nextEmail = account[i];
            int nextIndex = emailToIndex[nextEmail];
            uf.unionSet(firstIndex, nextIndex);
        }
    }
    map<int, vector<string>> indexToEmails;
    for (auto& [email, _] : emailToIndex) {
        int index = uf.find(emailToIndex[email]);
        vector<string>& account = indexToEmails[index];
        account.emplace_back(email);
        indexToEmails[index] = account;
    }
    vector<vector<string>> merged;
    for (auto& [_, emails] : indexToEmails) {
        sort(emails.begin(), emails.end());
        string& name = emailToName[emails[0]];
        vector<string> account;
        account.emplace_back(name);
        for (auto& email : emails) {
            account.emplace_back(email);
        }
        merged.emplace_back(account);
    }
    return merged;
}
```


