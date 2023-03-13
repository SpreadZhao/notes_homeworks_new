---
author: "Spread Zhao"
title: ea
category: self_study
description: UC Berkeley-CS170，伯克利的算法设计课，更注重算法的理论基础与复杂度分析。课程内容涵盖了分治、图算法、最短路、生成树、贪心、动规、并查集、线性规划、网络流、NP 问题、随机算法、哈希算法等等。网站：[CS170](https://cs170.org/)。本笔记是在学习西电《算法分析于设计》之前所记，作为对其的补充和扩展。
link: "[(921) CS170 Spring 2020 - YouTube](https://www.youtube.com/playlist?list=PLkFD6_40KJIyKLUW_4cm44mIdXSUpZry3)"
---

<h1>Efficient Algorithms + Intractable Problems</h1>

# 1. The Efficiency of Arithmetic

算加法，怎么算？数数呗！从小我们就知道，算5+7是多少，**就从5开始，数7个数，得到结果是12**。但是，这个过程从计算机的角度来讲，应该是什么呢？换句话说，**我们如何用计算机程序来模拟数数的过程呢**？计算机并不知道1的后面是2，2的后面是3。因此我们要是想模拟数数的过程，需要的Runtime时间$\leq 10^n \cdot n$。

#question 视频里这块完全不知道他在讲什么，好在没啥大用，就记结论了。

列竖式的思想其实也是这个， 我们算2568+347，就是这样： ^429ac9

```
    2 5 6 8
  +   3 4 7
   ---------
```

然而列竖式的时间复杂度仅仅是$n$。

---

接下来是乘法，列竖式的话，最多需要n位乘以n位，所以时间复杂度是$O(n^2)$。很长一段时间，人们都认为没有比这更快的算法了。下面我们给出这段时间内的一个证明，这也是之后的Divide and Conquer问题。比如我们算$5143 \times 291$，可以这样： ^8b7991

![[Algorithm/resources/Drawing 2023-01-20 17.15.11.excalidraw.png]]

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

我们看看这个式子需要花多长时间。每算一次x和y相乘，都要递归地算4次分割之后的乘法，并且还要算两次乘法，分别是$10^n$和$10^{\frac{n}{2}}$。但是由于这个乘法只是在最后加0，因此非常简单。最后我们要将这些部分加起来，因为差不多都是n位，或者$\frac{n}{2},\ cn$位。也就是加起来的操作花费差不多是$cn$。因此算这个乘法的时间：

$$
T(n) \le \left\{
\begin{aligned}
& 4 \cdot T(\frac{n}{2}) + c \cdot n & n > 1 \\
& 1 & n = 1 \\
\end{aligned}
\right.
$$

为啥n=1的时候是1呢？因为99乘法表！当n=1时，意味着这时已经分到了1位数乘以1位数，那还算啥？乘法表都背下来，直接给结果就可以了！下一个问题：这个算法的时间复杂度是多少？

![[Algorithm/resources/Drawing 2023-01-20 17.50.21.excalidraw.png|400]]

递归的求和其实和等比数列很像。将这些框里的时间加起来就是最终的时间了。也就是$4^0 \cdot c \cdot n + 4^1 \cdot c \cdot \frac{n}{2} + 4^2 \cdot c \cdot \frac{n}{4} + \cdots = cn(1 + 2 + 2^2 + 2^3 + \cdots + 2^k)$。k是多少？观察一下就知道，这棵树有多深k就是多少。显然，当n除的是n的时候这棵树截至，那么分母的变化为$2^0,2^1,2^2,\cdots,2^l$。求出$l = log_2n$，因此$k = l + 1 = log_2n + 1$。根据等比求和公式，上面的式子结果是$cn(2^{k+1}-1)$，带入得到最终结果：$cn(4n-1) \longrightarrow O(n^2)$。**这里$\Theta$和$O$的区别是，前者表示差不多相等，后者表示通常情况下都是(远)小于等于，后面给出的只是最复杂的情况**。

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

![[Algorithm/resources/Drawing 2023-01-20 18.35.54.excalidraw.png|400]]

来算一下这棵树的总时间，就是$3^0 \cdot c \cdot n + 3^1 \cdot c \cdot \frac{n}{2} + 3^2 \cdot c \cdot \frac{n}{2^2} + \cdots + 3^l \cdot c \cdot \frac{n}{2^l} = cn(1 + \frac{3}{2} + (\frac{3}{2})^2 + (\frac{3}{2})^3 + \cdots + (\frac{3}{2})^k)$。树的深度并没有变，只是分叉少了一个。那么k还是$log_2n + 1$。带入之前的求和公式，能够得到最终的结果：

$$
\begin{align}
S & = cn \cdot \frac{1 \cdot [1 - (\frac{3}{2})^{k + 1}]}{1 - \frac{3}{2}} = cn \cdot (-2) \cdot \left[1 - \left(\frac{3}{2}\right)^{k + 1}\right] = 2cn \cdot \left[\left(\frac{3}{2}\right)^{log_2n + 2} - 1\right] \\
 & = 2cn \cdot \left(\frac{9 \cdot 3^{log_2n}}{4n} - 1\right) = c \cdot \frac{9 \cdot (2^{log_23})^{log_2n}}{2} - 2cn = \frac{9}{2}c \cdot n^{log_23} - 2cn \\
 & \rightarrow O(n^{log_23})
\end{align}
$$

#question 这里老师还是认为$k = log_2n$，我觉得还是有问题。

由于$log_23 < 2 = log_24$，因此这个被优化的算法是比正常乘法更快的！

啥时候用这个算法呢？如果我只算个$10 \times 10$，还需要这么大费周章吗？在Python的源代码中我们能找到答案。Python的long类型有个特点，就是它可以非常非常长，甚至是无限长。原因就是它存的方式就是字符串。那么咋计算呢？其实就是用到了上面这种方法。我们看一看源代码的注释：

![[Algorithm/resources/Pasted image 20230120212757.png]]

意思就是说，如果两个操作数的长度有一个小于等于70，就用在学校里学过的方法(模拟列竖式)；只有两个数字的长度都超过70的时候，采用这种比较复杂的算法。那么为啥是70呢？比如，一个$\Theta(50n)$和一个$\Theta(n^2)$的算法，我们该选那个？那就看这俩谁小呗！如果n < 50就选n2；如果大于50就选50n。这里也是一样的道理，只不过它们测出这个70的手段更高级一些。

下面是算乘法的记录：

![[Algorithm/resources/Pasted image 20230120214905.png]]

> 可以看到，就在最近的2019年，Harvey Vander Hoeven已经将两个整数相乘的算法复杂度提高到了$O(nlogn)$，这在从前是不敢想的。以后会不会更快，甚至到$O(logn)$的级别，也未可知。

# 2. More Skill

## 2.1 Fibonacci

What is Fibonacci Sequence? It starts from 0 and then 1, and then the next number is always the **sum** of the previous two numbers. Just like:

$$
0 \ 1 \ 1 \ 2 \ 3 \ 5 \ 8 \cdots
$$

### 2.1.1 Four Algorithms to Calculate Fibonacci

How to calculate `fib(n)`? We've all already learned this algorithm(**Index starts from 0**): 

```c
int fib(int n){
	if n <= 1 return n;
	else return fib(n - 1) + fib(n - 2);
}
```

This is also known as **Recursion Algorithm**, which seems to be terribly costly. Now let's analyze it's Run Time performance. We will count "flops"(**floating point ops**). The time cost is easy to configure: 

$$
T(n) = \left \{
\begin{align}
& 0 & n \leqslant 1 \\
& T(n - 1) + T(n - 2) + 1 & n > 1
\end{align}
\right.
$$

If n is less than or equal to 1, we don't cost time, **because we know the answer**; if n is bigger than 1, we should cost time of T(n - 1) and T(n - 2), **also the time to add the two, which is 1 flop**. To analyze the time cost, we should firstly look at the sequence itself:

$$
F_n = F_{n - 1} + F_{n - 2} \geqslant 2 \cdot F_{n - 2} \geqslant 2 \cdot 2 \cdot F_{n - 4} \geqslant \cdots \geqslant 2^{\frac{n}{2}}
$$

The similar argument says the similar thing in the recurrence. So the time cost is something like:

$$
T \geqslant 2^{.5n}\ (flops)
$$

#question I also don't know what is the teacher saying. Just remember that this alg takes **exponential flops of $cn$**, marked as **exp(cn).** **Flops! Not real time!**

---

Here's alg 2, which is the **Iteration**.

```c
int fasterFib(int n){
	if n <= 1 return n;
	A = 0;
	B = 1;
	for(int i = 2; i <= n; i++){ // At this time, i points to the temp.
		int temp = A + B;
		A = B;
		B = temp;
	}
	return B;
}
```

You can run it by yourself. `A` refers to the F(i - 2) and `B` refers to the F(i - 1). Everytime when a for loop starts, i points to the `temp` which is to be calculated, and we do it by add `A` with `B`. Then we move both `A` and `B` forward, which means now `B` is F(i) and `A` is F(i - 1). **Every time after a for loop, `B` will store the value of F(i).** So when the loop ends, we get F(n) because it stop calculating when `i == n`.

How many flops are there? **Only one in each for loop, which is in the sentence `int temp = A + B;`**. We do the loop for (n - 1) times, which means **there're (n - 1) flops in the algorithm**.

---

Next let's talk about another fast algorithm known as **Fast Matrix Powering**. We can define a matrix and a vector and multiply them. Then we'll get a vector contains $F_2$ and $F_1$.

$$
\left[
\begin{array}{l}
1 & 1 \\
1 & 0
\end{array}
\right]
\left[
\begin{array}{l}
F_1 \\
F_0
\end{array}
\right]
=
\left[
\begin{array}{c}
F_1 + F_0 \\
F_1
\end{array}
\right]
=
\left[
\begin{array}{l}
F_2 \\
F_1
\end{array}
\right]
$$

We give the conclusion here. If we mark the matrix $\left[ \begin{array}{l} 1 & 1 \\ 1 & 0 \end{array} \right]$ as A, we'll get a formula:

$$
A^n \left[
\begin{array}{l}
F_1 \\
F_0
\end{array}
\right]
=
\left[
\begin{array}{c}
F_{n + 1} \\
F_{n}
\end{array}
\right]
$$

As we learned in **Linear Algibra**, if we get $A^n$ quickly, we get the result quickly. ~~It's run time performance is also $O(n)$ the same as the alg above(`fasterFib`).~~ Now let's analyze it's run time performance. The mainly cost is the time to get $A^n$. So how long? Instead of a matrix, let's talk about the constant number first. **How long does it take to get $9^n$**? For example, let's calculate $9^{71}$:

$$
\begin{array}{l}
9^1 & 9^2 & 9^4 & 9^8 & 9^{16} & 9^{32} & 9^{64}
\end{array}
$$

At first, we got 9, with 0 time cost. Then we need one flop to get $9^2$, because of the mutiplication($9^1 \times 9^1$). We need one more flop to get $9^4(9^2 \times 9^2)$ ... So how many flops past before we get $9^n$?

$$
\begin{array}{l}
\underbrace{
\underbrace{
\underbrace{
\underbrace{
9^1 \ \  9^2
}_{1\ flop}
\ \ 9^4
}_{2\ flops}
\ \ 9^8
}_{3\ flops}
\ \ 9^{16} \ \ 9^{32} \ \ 9^{64}
}_{?\ flops}
\end{array}
$$

It seems that, **when we get $9^4$, we use 2 flops, which is $log_24$; when we get $9^8$, we use 3 flops, which is $log_28$**. So we can conclude that, **if we want to get $9^n$, we should use $log_2n$ flops**. And now let's make n 71. if we want to get $9^{71}$, we should use $log_271$ flops. But what is that? It is not an integer. So should we **round it down($[log_271]$)**, or  do something else? The result is that, **flops used to get $9^{71}$ is definitely integral**. Let's conquer it first:

$$
71 = 64 + 4 + 2 + 1
$$

Given this, we can combine $9^{71}$ like:

$$
9^{71} = 9^1 \times 9^2 \times 9^4 \times 9^{64}
$$

What does that mean? It means that we can get $9^{71}$ by:

* getting $9^2$ -> 1 flop
* getting $9^4$ -> 1 flop($9^2 \times 9^2$)
* getting $9^{64}$ -> 4 flops(from $9^4$, square it 4 times)
* multiplying them together -> 3 flops

So, the time for getting is $1 + 1 + 4 = 6$, which is just $log_271$, and the time for multiplying is just the constant time, which means almost no cost. **Change 71 to n, we'll get the same conclusion**. It means that, **the run time performance of getting $9^n$(or the power of any constant number) is something like $O(log_2n)$, or short as $O(logn)$**. If we turn the constant number to a matrix, we will find that, the time to multiply number and number is very similar to matrix and matrix. So the result is that, **the run time performance of the alg Fast Matrix Powering is $O(logn)$**. The alg that constantly multiply matrix and matrix is also known as **Repeated Squaring**.

---

Alg 4 is the fastest one, which only costs constant time(**may be**)! It gives you a formula, you bring the value of `n` to it, and you will get the result of `Fib(n)`. To approach this alg, you should use a lot of knowledge of Linear Algebra.

Such as the formula in alg 3: 

$$
A^n \left[
\begin{array}{l}
F_1 \\
F_0
\end{array}
\right]
=
\left[
\begin{array}{c}
F_{n + 1} \\
F_{n}
\end{array}
\right]
$$

We define the matrix $\left[ \begin{array}{l} F_1 \\ F_0 \end{array} \right]$ as vector $v$, so we should calculate the value of:

$$
A^nv
$$

And if we could give matrix $A$ a decomposition $A = Q \Lambda Q^T$, where:

* Q is a **orthogonal matrix**, which meats the condition $QQ^T = I$, and $I$ is a matrix like $\left[ \begin{array}{l} 1 & 0 \\ 0 & 1 \end{array} \right]$;
* and $\Lambda$ is a matrix like $\left[ \begin{array}{c} \lambda_1 & 0 \\ 0 & \lambda_2 \end{array} \right]$.

We have known that A is a constant matrix, whose number in itself does not change. Now we can define some numbers:

* $\phi = \frac{1+\sqrt{5}}{2},\ \psi = \frac{1-\sqrt{5}}{2}$
* $\lambda_1 = \phi,\ \lambda_2 = \psi$
* $Q = \left[ \begin{array}{l} \sqrt{\phi} & -\sqrt{-\psi} \\ \sqrt{-\psi} & \sqrt{\phi} \end{array} \right] \cdot \frac{1}{\sqrt[4]{5}}$

With these numbers, we can calculate `Fib(n)` easily(hehe) by the **exact formula**:

$$
F_n = \frac{1}{\sqrt{5}} \cdot (\phi^n - \psi^n)
$$

### 2.1.2 The Real Time of These Algorithms

* In the section ahead, we just talked about the flops each alg takes but the real time. Now let's see what it is on earth. Start with Alg 1, it costs **exp(cn)** flops, each of them cost the time of adding two numbers. Because the cost is so small, **the real time is supposed to be $exp(cn) \cdot small = exp(cn)$ too**.

* In the **Iterator** algorithm, we cost approximately n flops to get it. During each flop, we add two numbers together, so the time cost by the addition [[#^429ac9|is also n]]. This n time is almost the same as the $small$ in the 1st alg, **but we multiply it with n instead of $exp(cn)$**. So this time is not small in this case. The Runtime of alg 2 is at most $n \cdot n = n^2$.

> You may ask: these two n is not supposed to do mutiplication! One is the number of flops; the other is the time cost **when the two number is n digits long**. In all the cases above, **n is the index of the number in Fibonacci Sequence**. Does the index do have some relations to the length of the number? The answer is: Yes! Below is my illustration. In the alg 1, we see that Fibonacci number $F_n$ is at least $2^{\frac{n}{2}}$, **which means that $F_n$ grows at a exponential speed**. Given that, we can say that $F_n \approx exp(cn)$. Then the question becomes that **how long does a number of $exp(cn)$ or $exp(n)$ scale**? Let's take some example:
>
> * $2^1$ is $10$ in binary, which is 2 digits long;
> * $2^2$ is $100$ in binary, which is 3 digits long;
> * $2^3$ is $1000$ in binary, which is 4 digits long;
> * $\cdots$
> * $2^n$ is $\underbrace{100 \cdots 0}_{n+1\ digits}$ in binary, which is n+1 digits long.
> 
> For a number of $exp(n)$ scale, we can calculate its length by the exponent of it, or we can say that, the length of a number $x$ with such scale is approximately $log_2x$. Eventually we are able to give this conclusion: **the length of a number $F_n$ in Fibonacci Sequence with the index `n` is approximately $log_2F_n$**. Continue our deduction: 
>
> $$
> length \approx log_2F_n \approx log_2(exp(cn)) \approx log_2(exp(n)) \approx log_2(2^n) \approx n
> $$

* In the **Matrix Powering** alg, we multiply two matrix every flop. The multipication of two matrices costs $n^2$ time, **because the number in the matrix is also growing n digits long**. So the eventual Runtime of the alg is approximately $logn \cdot n^2$. Actually, the Runtime also depends on the algorithm you use to multiply those numbers in the matrix, [[#^8b7991|just as we have talked about]].

Alg | Flops | Runtime
-- | -- | --
recursive | $exp(cn)$ | $exp(cn) \cdot small$
iter | n | $n^2$
matrix powering | $logn$ | $logn \cdot n^2$

### 2.1.3 Asymptotic Notation

What is $O$, and what is $\Theta$? I'll show you some definition first. $f,\ g$ are functions mapping $\mathbb{Z^+}$ to $\mathbb{Z^+}$ where $\mathbb{Z^+}$ is positive integers. We can mark that:

* "Big Oh" -> $f = O(g)\ if\ \exists\ c > 0,\ s.t. \forall n,\ f(n) \leqslant c \cdot g(n)$. (*s.t. means "such that"*)
* "little oh" -> $f = o(g)\ if\ \lim\limits_{n \rightarrow \infty}\frac{f(n)}{g(n)} = 0$.
* "Big Omega" -> $f = \Omega(g)\ if\ g = O(f)$.
* "little omega" -> $f = \omega(g)\ if\ g = o(f)$.
* "Theta" -> $f = \Theta(g)\ if\ \left\{\begin{align} & f = O(g) \\ & f = \Omega(g) \end{align} \right.$.

**We can remember it with this analogy**:

$$
\begin{align}
O\ means\ \leqslant \\
o\ means\ < \\
\Omega\ means\ \geqslant \\
\omega\ means\ > \\
\Theta\ means\ =
\end{align}
$$

### 2.1.4 Divide and Conquer

In the 1st lecture, we talked about the **Kara Tsuba** Alg to multiply two integers, which is an example of **Divide-and-Conquer**. In that case, the time cost is like this:

$$
T(n) \le \left\{
\begin{aligned}
& 4 \cdot T(\frac{n}{2}) + c \cdot n & n > 1 \\
& 1 & n = 1 \\
\end{aligned}
\right.
$$

The result is to be $O(n^2)$ which equals to $O(n^{log_24})$. If we do 3 recursion instead of 4, the time cost:

$$
T(n) \le \left\{
\begin{aligned}
& 3 \cdot T(\frac{n}{2}) + c \cdot n & n > 1 \\
& 1 & n = 1 \\
\end{aligned}
\right.
$$

and the result is to be $O(n^{log_23})$. But what if we expand it to a common formula?

$$
T(n) \le \left\{
\begin{aligned}
& a \cdot T(\frac{n}{b}) + c \cdot n^d & n > 1 \\
& 1 & n = 1 \\
\end{aligned}
\right.
$$

**We do $a$ recursion instead of 3; we divide the number into $b$ pieces instead of 2; we cost $n^d$ time to put all of them together every recursion**. Now what is the time cost? After a series of decuction, the result is that:

#keypoint Master Theorem

$$
T(n) = \left\{ \begin{array}{lr} O(n^d \cdot logn) & a = b^d \\ O(n^d) & a < b^d \\ O(n^{log_ba}) & a > b^d \end{array} \right.
$$

The formula is called **Master Theorem**. You just plug numbers in it, and it gives you the answer. ^b745d8

# 3. More Divide and Conquer

## 3.1 Matrix Multiplication

How to calculate one element in a matrix? **You just need 1 loop to do that.** Fix the `i` row of Matrix X and the `j` colomn of Matrix Y, loop `k` from 0 to n, and sum those result up like:

```c
for(k = 0; k < n; k++){
	Z[i][j] += X[i][k] + Y[k][j];
}
```

After that loop, you got 1 elem. But what if we want to calculate the whole matrix? Obviously, **you should nest it with two more loops**, which cover the whole of Matrix X and Y:

```c
for(i = 0; i < n; i++){
	for(j = 0; j < n; j++){
		for(k = 0; k < n; k++){
			Z[i][j] += X[i][k] + Y[k][j];
		}
	}
}
```

So the time cost is $\Theta(n^3)$ for the nest for loops. Can we make it better with Divide and Conquer? The answer is yes!

![[Algorithm/resources/Pasted image 20230123144213.png]]

![[Algorithm/resources/Pasted image 20230123144232.png]]

> Matrix multiplication is unlike the integer one, we still don't have a relatively good alg to solve it.

## 3.2 Sorting(Merge sort)

If we have an array consist of just one elem: 3, and we have another array also consist of one elem: 5. We want to **merge them to an entire array** like:

![[Algorithm/resources/Drawing 2023-01-23 14.54.34.excalidraw.png]]

This is the core idea of Merge Sort. **We recursively divide the array in two pieces until is has only 1 elem**. Then we start to put them together, **but with order**. If somehow we have done everything before the last merge, we will get two arrays which has been in order:

![[Algorithm/resources/Drawing 2023-01-23 14.58.12.excalidraw.png]]

What we need to do is to merge them together. But how? Make 2 ponters, point to the smallest one: 

![[Algorithm/resources/Drawing 2023-01-23 15.00.11.excalidraw.png|300]]

**Which one is smaller? 2! So we put 2 to the new array**:

![[Algorithm/resources/Drawing 2023-01-23 15.02.02.excalidraw.png|500]]

Continuously do this, until both the two pointers reach the end. After that, we will get the merged array. So the structure of Merge Sort is supposed to be:

```c
MergeSort(a[1 .. n]){
	b[] = MergeSort(a[1 .. n/2]);
	c[] = MergeSort(a[n/2 + 1 .. n]);
	return Merge(B, C);
}
```

We do recursion for 2 times; we divide the entire into 2 pieces and we take $cn$ times to combine those together. With the [[#^b745d8|Master Thorem]] introduced in 2.1.4, we can write the time cost down:

$$
T(n) \leqslant 2 \cdot T(\frac{n}{2}) + cn
$$

which means that $a = 2,\ b = 2,\ d = 1$. Refers to the thorem, we can conclude that

$$
T(n) = O(nlogn)
$$

There're also other implements to achieve this time cost **without recursion**. One of them is using **a queue of list**. If the number to be sorted is like: 

```
8 5 7 3 9
```

what you should do is making a queue, and pushing all the elems in it, **one in a list**:

![[Algorithm/resources/Drawing 2023-01-27 00.08.55.excalidraw.png]]

Now you just need to do as the follow, until there're only 1 list in the queue:

* pop 2 lists
* merge them
* push the merged list to the tail

![[Algorithm/resources/Drawing 2023-01-27 00.11.17.excalidraw.png|400]]

Is there any algs which is faster than $O(nlogn)$? The answer is true when your computer can not only do comparison(Well, actually almost all computers now fit it). Let's take **Counting Sort** as an example. If every number to be sorted is between 1 to B, then I can make B-size buckets:

![[Algorithm/resources/Drawing 2023-01-27 00.27.09.excalidraw.png|300]]

And here is the array I want to sort:

![[Algorithm/resources/Drawing 2023-01-27 00.28.13.excalidraw.png]]

What I need to do is terribly easy: Go through the array. The 1st is 2, so we put it in the bucket 2; the next one is 4, so we put it in the bucket 4 ... . After we have went through the array, all the numbers have been put into their affiliated buckets. **So we just need to turn to the buckets by going through it.** Then we'll get the sorted array.

If the size of input(array) is `n`, the time cost is just `n` times to scanning the array and `B` time to allocate the buckets, which is $n + B$.

But if you assume the comparison based model, why $O(nlogn)$ is the fasted time you can achieve? Let's assume the input as **some unknown permutation $\sigma$ of $A_1,\ A_2,\ \cdots ,\ A_n$** and that all the thing I can do is just making **less than** comparison.

> *Why not equal comparison or bigger than comparison? Because it makes no sense. A is less than B just means that B is bigger than one; and A = B is no need in sorting algorithm, they're just the same!*

Then there's a machine constantly asking dummy questions like: $A_5 < A_7\ ?$. If the answer is yes, it strach to a new question like $A_4 < A_7\ ?$ ... ... When the machine stop asking questions, the sorting alg is over:

![[Algorithm/resources/Pasted image 20230127181051.png|300]]

If every question the machine asks just hits the point, the alg is faster; other wise like the machine is asking questions like: $A_1 < A_2\ ?\ A_2 < A_1\ ? \cdots$, the alg is slower. Whatever, once the process got to the end of the tree, we will get a bigger-less relation ship of the permutation. If it is assumed that the height of this tree is `T`(where `T` is just the times of comparison, or time cost), there're $2^T$ leaves in the tree, and **every permutation of the input must mapping a leaf itself**, which means **the number of leaves is at least the number of the permutations**:

$$
\begin{array}{lrcl}
&\#leaves & \geqslant & \#perms \\
\Rightarrow & 2^T & \geqslant & A_n^n = n! \\
\Rightarrow & T & \geqslant & log_2(n!) \\
& & \geqslant & n \cdot lnn - O(n) \\
& & = & \Omega(nlogn)
\end{array}
$$

## 3.3 (Median) Select

First let's recall the core idea of **Quick Sort**. The goal of every recursion in quick sort is **finding the right place of the pivot**. You chose a number as the pivot, and move all the numbers less than the pivot to the left; and all the numbers bigger than the pivot to the right.

Now given the array\[1 .. n\], and $1 \leqslant k \leqslant n$, what we want to do is **outputing the `kth` smallest entry of A**, where usually k is n/2, which called the **Median Select**. If deal it easily, you can just sort the array, then you absolutely know the kth smallest one; but this time we will do it in linear time instead of the $O(nlogn)$ sorting alg.

**Quick Select** is similar to Quick Sort, but you will do less(usually half) recursions. You also chose a pivot, **move all the numbers less or bigger than it to the left and right, just as what Quick Sort do**. Then the point is, because what we're doing is **select**, so if it(pivot) is just the kth smallest one, return it; if it is bigger than kth, recurse the left instead of both sides; if it is smaller than kth, recurse the right side also instead of both sides. This is why it costs usually half recursions than Quick Sort.

In Quick Select, your desire is:

$$
T(n) \leqslant T(\frac{n}{2}) + cn
$$

where $cn$ is the time of comparing the pivot with other elems in the array; $T(\frac{n}{2})$ is the time to recursively do this **when k = n/2**. However, notice that we say it **the desire**, because you <u>can't alway chose the most suitable pivot</u>. To solve this problem, **we have another algorithm to let you chose the best pivot in most cases(wow\~)**. 

> The algorithm below is based on one important thing: The final goal is to find the **kth** smallest elem in the array, not the median one. <u>Every "median" word we say below is just the way to find the best pivot for finding the kth smallest elem</u>.

Here's my array and it has **n distinct** entries. The next thing I will do looks like a little weird, but after that I will show you that the weirdness is not out of no where. **I'm going to group the entries with blocks of size 5**:

![[Algorithm/resources/Drawing 2023-01-28 20.18.04.excalidraw.png]]

Then I'll find the median of every group. The way I can use is various, like merge sort, bubble sort etc. Because the size of the group is constant, so **whatever the alg used to find the median is, the time cost is always constant**. For example, if I use Merge Sort to find the median, then the time cost will be:

$$
O(nlogn)\ when\ n\ is\ 5,\ namely\ O(5log5),\ which\ is\ constant\ time.
$$

Totally I've got the number of the groups of medians. Then I'll **recursively call the function to find the median of the medians**:

![[Algorithm/resources/Drawing 2023-01-28 20.26.08.excalidraw.png]]

> You may ask why recursively? Because the algorithm itself is a way to find the kth smallest elem in the array, so it absolutely fits our expectation when
>  
> $$
> k = \frac{number\ of\ groups}{2} = \frac{n}{10}.
> $$
> 
> So we could just **take $\frac{n}{10}$ as the parameter of the function(take the place of `k`)**.If there're 2 or more recursions, the number will goes down like:
>
>$$
>\begin{array}{c}
>k = \dfrac{n}{5}(base\ fun),\ k = \dfrac{n}{10}(1st\ recursion), \\
>k = \dfrac{n}{20}(2nd\ recursion),\ k = \dfrac{n}{40}(3rd\ recursion),\\
>\cdots
>\end{array}
>$$
> *Notice that k and n here are both refer to the origin value, instead of the actual argument passed to the function*.

The next thing I will do is obvious: **use the pivot to do Quick Select just as what we have done**. Let `L` be the stuff smaller than the pivot `p`; `R` be the numbers that is bigger than `p`. So the array is broken apart to:

```
[L p R]
```

We are to find the kth smallest one, so:

```c
/*
	Where |L| means the length of L,
	namely the number of elems in L.
*/
if(k = |L| + 1) return p;
else if(k <= |L|) return Something Recursively;
else return Something Else Recursively;
```

> Notice that the code above is **also** used to find the median of the group, or the median of the medians we've already talked.

Then I'll explain what the `Something Recursively` is. If `k <= |L|`, which means the kth smallest elem is in the array `L` instead of `p` or `R`, so we should recursive to the left side of the array which is `L` it self. On the other hand, if `k > |L| + 1`, which means the kth is in the array `R`, so we should do the recursion in the `R`. The complete code is:

```c
/*
	A: the target array
	k: the kth smallest one
*/
Select(A[1 .. n], k){
	groups = Break(A, 5); // Break A into group of size 5 each.
	B = FindMedians(group); // B is the array of medians in each group.

	// Size of B is n/5. The n/5/2th smallest one in B, which is the median.
	p = Select(B, n/10); // Recursively find the median of medians.

	// You can do the following funs in linear scan.
	L = Lessthaners(A, p); // Numbers less than p in A.
	R = Biggerthaners(A, p); // Numbers bigger than p in A.

	if(k = |L| + 1) return p;
	else if(k <= |L|) return Select(L, k);
	else return Select(R, k - |L| - 1);
}
```

> Notice the param in the last recursion. `k - |L| - 1` means that, if the kth smallest elem is in `R`, we're gonna say that **the kth smallest elem in `A` is the No. `k - |L| - 1` smallest one in `R`**. It's just a simple math question, I think you can do it!

Now let's analyze the time cost of this alg:

* At first we broke `A` into 5 groups, which cost a linear time $O(n)$.
* Then we spend some segments of constant time to find the medians of groups. There're n/5 groups in total, so the time cost is $\frac{n}{5} \cdot O(1)$.
* Then we recursively call the function itself, and the size of the array param is just the number of groups, which is n/5. So we cost $T(\frac{n}{5})$.
* Then we pivot around the array, namely do a linear scan on it to find `L` and `R`. So we cost another $O(n)$.
* Finally is the toughest thing. What if we do the recursion in `L` and `R`? Is it $T(\frac{n}{2})$? Notice that the best pivot is not always the midium of the array, **it is just bigger than half of the numbers in some groups, but not the half in the entire array**. So let's see what is the size of `L` and `R`.

  ![[Algorithm/resources/Pasted image 20230128214203.png]]

  The best pivot is **guaranteed to be in the product of the first selection**, which is just `B`. So the `p` is guaranteed to be bigger than half of the elems in `B`(From here, you could see, instead of the half of `A` which is the origin entire array). And the half of `B` which is smaller than `p` is also guaranteed to be bigger than half of the elems in **their respective group**. And the number of groups is ought to be:

  $$
 \frac{1}{2} \times \frac{n}{5}
 $$

  So the best pivot is guaranteed to be bigger or equal than 3 in each group above, namely:

  $$
p\ is\ bigger\ or\ equal\ than\  \frac{1}{2} \times \frac{n}{5} \times 3 = \frac{3n}{10}\ elems.
 $$

  That means the size of `L` or `R` is both no more than $n - \frac{3n}{10} = \frac{7n}{10}$. Finally we'll conclude that we'll cost $T(\frac{7n}{10})$ in either `L` recursion branch or `R` recursion branch.

To sum up, the time performance of this alg is:

$$
\begin{array}{rcl}
T(n) & \leqslant & O(n) + \dfrac{n}{5} \cdot O(1) + T(\dfrac{n}{5}) + O(n) + T(\dfrac{7n}{10}) \\
& \leqslant & T(\dfrac{n}{5}) + T(\dfrac{7n}{10}) + cn
\end{array}
$$

But how good is it? The answer is, **if we break the array into any odd numbers at least 5 blocks, the time cost is linear**. Now let's prove it via induction. We just guess the conclusion, and try to prove it with induction.

$$
Guess: T(n) \leqslant B \cdot n
$$

where B is a constant. So we're going to prove that **the constant B does actually exists**. The base case is that B is definitely a positive number which is at least 1, because even linearly scan the array still costs $n$ time, when B is 1. Then we use the **strong induction** that $T(\frac{n}{5})$ and $T(\frac{7n}{10})$ both fit the assume, which means:

$$
\begin{array}{l}
T(\dfrac{n}{5}) \leqslant B \cdot \dfrac{n}{5}, \\
T(\dfrac{7n}{10}) \leqslant B \cdot \dfrac{7n}{10}, \\
Assume\ that:\\
T(\dfrac{n}{5}) + T(\dfrac{7n}{10}) + cn \leqslant B \cdot \dfrac{n}{5} + B \cdot \dfrac{7n}{10} + cn \leqslant B \cdot n
\end{array}
$$

So the question becomes to: **is there any B exist so that the inquality above works**? If the answer is yes, we can say that **all the assume work when B is the answer we've got**. Evidently, we can easily solve this problem:

$$
\begin{array}{rl}
& B \cdot \dfrac{n}{5} + B \cdot \dfrac{7n}{10} + cn \leqslant B \cdot n \\
\Rightarrow & B(1 - \dfrac{1}{5} - \dfrac{7}{10}) \geqslant c \\
\Rightarrow & B \geqslant 10c
\end{array}
$$

Wonderful! B is really exists! We can say that, if B is bigger or equal than 10c, the following assume is do correct:

$$
T(n) \leqslant B \cdot n\ (B \geqslant 10c)
$$

Remember what we said: **at least 5 blocks**, how about 3? And how about an even number? The 2nd question is easy to solve, because the median is expected to be the only one; but the 1st question is a little bit harder. But I'll show the teacher's blackboard-writing as a tip:

![[Algorithm/resources/Pasted image 20230129011048.png]]

## 3.4 Polynomial Multipication

We have input like:

$$
\begin{array}{l}
A(x) = a_0 + a_1 \cdot x + a_2 \cdot x^2 + \cdots + a_{d-1} \cdot x^{d-1} \\
B(x) = b_0 + b_1 \cdot x + b_2 \cdot x^2 + \cdots + b_{d-1} \cdot x^{d-1}
\end{array}
$$

A(x) and B(x) are polynomials that have the degree **less than d**, and we need tu compute the vector of coefficients of:

$$
C = A \times B
$$

which means that

$$
C(x) = c_0 + c_1 \cdot x + \cdots + c_{2d-2} \cdot x^{2d-2}.
$$

The result $C(x)$ is a polynomial that have the degree less than 2d-1. So we're going to say that **all of A, B and C are polynomials that have the degree less than $n = 2d-1$**, because I can pad out A and B with 0 coeff.

> $A(x) = a_0 + a_1 \cdot x + a_2 \cdot x^2 + \cdots + a_{d-1} \cdot x^{d-1} + 0 \cdot x^d + \cdots + 0 \cdot x^{2d-2}$

Here we just talk about the coeffs of C, so let's try to find the law:

$$
c_0 = a_0b_0,\ c_1 = a_0b_1 + a_1b_0,\ c_2 = a_0b_2 + a_1b_1 + a_2b_0,\cdots
$$

We can induce that:

$$
c_k = \sum_{j=0}^k a_jb_{k-j}
$$

Notice that polynomial multiplication is simmilar to integer multiplication. If I want to calculate $1074 \times 2351$, we can say it in polynomial degree that:

$$
\begin{array}{l}
A(x) = 4 + 7 \cdot x + 0 \cdot x^2 + 1 \cdot x^3 \\
B(x) = 1 + 5 \cdot x + 3 \cdot x^2 + 2 \cdot x^3
\end{array}
$$

and when $C(x) = A(x) \cdot B(x)$, the result is just $C(10)$. Now let's think about the algs that solve the problem. The 1st one is the naive alg using nested for loops. We just go through the coeffs of the result, for each one, it involves at most n terms(j from 0 to k, and the maximum of k is n-1, when there's totally n terms). Evidently, the alg is $O(n^2)$ flops. However, notice what I said before, "at most n terms", which means that there're also some coeffs that cost little. For example, $c_1$ has only one term, so it needs only 1 flop to compute. **For nearly half of the coefficients of $C$, we need almost $\Omega(n)$ flops to get it**, and there're also nearly n/2 terms fit such case, so the total cost of these terms is nearly $\Omega(n^2)$. **Considering the 2 cases above, we can conclude that:**

$$
\left. 
\begin{array}{r}
T(n) = O(n^2) \\
T(n) = \Omega(n^2)
\end{array}
\right\}
\Rightarrow
T(n) = \Theta(n^2)(flops)
$$

We can also do KaraTsuba Alg in poly mult. And the trick to divide and conquer is also the same:

![[Algorithm/resources/Pasted image 20230131132601.png]]

