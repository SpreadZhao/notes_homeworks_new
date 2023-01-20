---
author: "Spread Zhao"
title: ea
category: inter_class
description: UC Berkeley-CS170，伯克利的算法设计课，更注重算法的理论基础与复杂度分析。课程内容涵盖了分治、图算法、最短路、生成树、贪心、动规、并查集、线性规划、网络流、NP 问题、随机算法、哈希算法等等。网站：[CS170](https://cs170.org/)。本笔记是在学习西电《算法分析于设计》之前所记，作为对其的补充和扩展。
---

<h1>Efficient Algorithms + Intractable Problems</h1>

# 1. Introduction

算加法，怎么算？数数呗！从小我们就知道，算5+7是多少，**就从5开始，数7个数，得到结果是12**。但是，这个过程从计算机的角度来讲，应该是什么呢？换句话说，**我们如何用计算机程序来模拟数数的过程呢**？计算机并不知道1的后面是2，2的后面是3。因此我们要是想模拟数数的过程，需要的Runtime时间$\leq 10^n \cdot n$。

#question 视频里这块完全不知道他在讲什么，好在没啥大用，就记结论了。

列竖式的思想其实也是这个， 我们算2568+347，就是这样：

```
	2 5 6 8
  +   3 4 7
   ---------
```

然而列竖式的时间复杂度仅仅是$n$。

---

接下来是乘法，列竖式的话，最多需要n位乘以n位，所以时间复杂度是$O(n^2)$。很长一段时间，人们都认为没有比这更快的算法了。下面我们给出这段时间内的一个证明，这也是之后的Divide and Conquer问题。比如我们算$5143 \times 291$，可以这样：

![[Excalidraw/Drawing 2023-01-20 17.15.11.excalidraw|300]]

在这个例子中，我们把每个数字分成了2份，因此，如果要算出x和y的话，就应该是：

$$
\begin{align}
x = x_h \cdot 10^{\frac{n}{2}} + x_l\\
y = y_h \cdot 10^{\frac{n}{2}} + y_l
\end{align}
$$

不是要算乘法吗？那就乘一乘，看看：

$$
x \cdot y = x_hy_h \cdot 10^n + (x_hy_l + x_ly_h) \cdot 10^{\frac{n}{2}} + x_ly_l
$$

我们看看这个式子需要花多长时间。每算一次x和y相乘，都要递归地算4次分割之后的乘法，并且还要算两次乘法，分别是$10^n$和$10^{\frac{n}{2}}$。但是由于这个乘法只是在最后加0，因此非常简单。算多少次呢？因为最长的是n所以最多算n次，也就是这些加0的操作花费是$cn$。因此算这个乘法的时间：

$$
T(n) \le \left\{
\begin{aligned}
& 4 \cdot T(\frac{n}{2}) + c \cdot n & n > 1 \\
& 1 & n = 1 \\
\end{aligned}
\right.
$$

为啥n=1的时候是1呢？因为99乘法表！当n=1时，意味着这时已经分到了1位数乘以1位数，那还算啥？乘法表都背下来，直接给结果就可以了！下一个问题：这个算法的时间复杂度是多少？

![[Excalidraw/Drawing 2023-01-20 17.50.21.excalidraw|500]]

递归的求和其实和等比数列很像。将这些框里的时间加起来就是最终的时间了。也就是$4^0 \cdot c \cdot n + 4^1 \cdot c \cdot \frac{n}{2} + 4^2 \cdot c \cdot \frac{n}{4} + \cdots = cn(1 + 2 + 2^2 + 2^3 + \cdots + 2^k)$。k是多少？观察一下就知道，这棵树有多深k就是多少。显然，当n除的是n的时候这棵树截至，那么分母的变化为$2^0,2^1,2^2,\cdots,2^l$。求出$l = log_2n$，因此$k = l + 1 = log_2n + 1$。根据等比求和公式，上面的式子结果是$cn(2^{k+1}-1)$，带入得到最终结果：$cn(4n-1) \longrightarrow \theta(n^2)$。**这里$\theta$和$O$的区别是，前者表示差不多相等，后者表示通常情况下都是(远)小于等于，后面给出的只是最复杂的情况**。

#question 老师的板书：

![[Algorithm/resources/Pasted image 20230120181557.png]]

![[Algorithm/resources/Pasted image 20230120181653.png]]

我怀疑老师的数学有点问题，那两个k根本就不是同一个变量。但是也无伤大雅。

**从这点我们能看出，递归通常是非常消耗时间的**。但是，有一个非常牛逼的科学家的朋友解决了这个问题，看看它是怎么想的。还是这个式子：

$$
x \cdot y = x_hy_h \cdot 10^n + (x_hy_l + x_ly_h) \cdot 10^{\frac{n}{2}} + x_ly_l
$$

我们给出如下定义：

$$
\begin{align}
& A = x_hy_h \\
& B = x_ly_l \\
& D = (x_h+x_l) \cdot (y_h + y_l)
\end{align}
$$

A和B都还好理解，但是这个D是个啥鬼？比如$5143 \times 0291$这个式子，我做的就是将51和43加起来，又把2和91加起来，最后再一乘。看起来这像是乱写的，但实际上你会发现，原式中中间的那部分，也就是$x_hy_l + x_ly_h = D - A - B$！所以，我们不用递归四次了，只需要递归三次：

$$
T(n) \le \left\{
\begin{aligned}
& 3 \cdot T(\frac{n}{2}) + c \cdot n & n > 1 \\
& 1 & n = 1 \\
\end{aligned}
\right.
$$

那么总时间的图就会变成这样：

![[Excalidraw/Drawing 2023-01-20 18.35.54.excalidraw|500]]

来算一下这棵树的总时间，就是$3^0 \cdot c \cdot n + 3^1 \cdot c \cdot \frac{n}{2} + 3^2 \cdot c \cdot \frac{n}{2^2} + \cdots + 3^l \cdot c \cdot \frac{n}{2^l} = cn(1 + \frac{3}{2} + (\frac{3}{2})^2 + (\frac{3}{2})^3 + \cdots + (\frac{3}{2})^k)$。树的深度并没有变，只是分叉少了一个。那么k还是$log_2n + 1$。带入之前的求和公式，能够得到最终的结果：

$$
\begin{align}
S & = cn \cdot \frac{1 \cdot [1 - (\frac{3}{2})^{k + 1}]}{1 - \frac{3}{2}} = cn \cdot (-2) \cdot \left[1 - \left(\frac{3}{2}\right)^{k + 1}\right] = 2cn \cdot \left[\left(\frac{3}{2}\right)^{log_2n + 2} - 1\right] \\
 & = 2cn \cdot \left(\frac{9 \cdot 3^{log_2n}}{4n} - 1\right) = c \cdot \frac{9 \cdot (2^{log_23})^{log_2n}}{2} - 2cn = \frac{9}{2}c \cdot n^{log_23} - 2cn \\
 & \rightarrow \theta(n^{log_23})
\end{align}
$$

#question 这里老师还是认为$k = log_2n$，我觉得还是有问题。

由于$log_23 < 2 = log_24$，因此这个被优化的算法是比正常乘法更快的！

啥时候用这个算法呢？如果我只算个$10 \times 10$，还需要这么大费周章吗？在Python的源代码中我们能找到答案。Python的long类型有个特点，就是它可以非常非常长，甚至是无限长。原因就是它存的方式就是字符串。那么咋计算呢？其实就是用到了上面这种方法。我们看一看源代码的注释：

![[Algorithm/resources/Pasted image 20230120212757.png]]

意思就是说，如果两个操作数的长度有一个小于等于70，就用在学校里学过的方法(模拟列竖式)；只有两个数字的长度都超过70的时候，采用这种比较复杂的算法。那么为啥是70呢？比如，一个$\theta(50n)$和一个$\theta(n^2)$的算法，我们该选那个？那就看这俩谁小呗！如果n < 50就选n2；如果大于50就选50n。这里也是一样的道理，只不过它们测出这个70的手段更高级一些。

下面是算乘法的记录：

![[Algorithm/resources/Pasted image 20230120214905.png]]

> 可以看到，就在最近的2019年，Harvey Vander Hoeven已经将两个整数相乘的算法复杂度提高到了$O(nlogn)$，这在从前是不敢想的。以后会不会更快，甚至到$O(logn)$的级别，也未可知。

