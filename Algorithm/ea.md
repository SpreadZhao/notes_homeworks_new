---
author: "Spread Zhao"
title: ea
category: inter_class
description: UC Berkeley-CS170，伯克利的算法设计课，更注重算法的理论基础与复杂度分析。课程内容涵盖了分治、图算法、最短路、生成树、贪心、动规、并查集、线性规划、网络流、NP 问题、随机算法、哈希算法等等。网站：[CS170](https://cs170.org/)。本笔记是在学习西电《算法分析于设计》之前所记，作为对其的补充和扩展。
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

![[Excalidraw/Drawing 2023-01-20 17.50.21.excalidraw|500]]

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

![[Excalidraw/Drawing 2023-01-20 18.35.54.excalidraw|500]]

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

If we have an array consist of just 1 elem: 3, and we also have another array also consist of 1 elem: 5. We want to **merge them to an entire array** like:

![[Excalidraw/Drawing 2023-01-23 14.54.34.excalidraw|200]]

This is the core idea of Merge Sort. **We recursively divide the array in two pieces until is has only 1 elem**. Then we start to put them together, **but with order**. If somehow we have done anything before the last merge, we will get two arrays which has been in order:

![[Excalidraw/Drawing 2023-01-23 14.58.12.excalidraw|500]]

What we need to do is to merge them together. But how? Make 2 ponters, point to the smallest one: 

![[Excalidraw/Drawing 2023-01-23 15.00.11.excalidraw|250]]

**Which one is smaller? 2! So we put 2 to the new array**:

![[Excalidraw/Drawing 2023-01-23 15.02.02.excalidraw|500]]

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

