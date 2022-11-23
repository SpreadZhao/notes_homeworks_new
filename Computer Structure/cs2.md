---
author: "Spread Zhao"
title: cs2
category: inter_class
description: 计算机组成与结构2课堂笔记，蒋志平老师
---

# 1. Pipe Line

举个洗衣服的例子：

![[Pasted image 20221115130320.png]]

那么如果是**纯串行**的话，就是张三洗烘熨放；李四洗烘熨放……

![[Pasted image 20221115130443.png]]

这样一共要八个小时，也太浪费了。其实，第一个人在洗完之后，洗衣机完全就可以给第二个人用了，烘干机、熨斗、晾衣架也是如此。那么我们完全可以这样：

![[Pasted image 20221115130650.png]]

**由此例子，我们能总结出流水线任务的特点**：

* 可被拆解
* 拆解的段可同时执行

当然，流水线的特点不止这些：

![[Pasted image 20221115131321.png]]

* 大量：不能好多人只做一道题，那分也没啥意思
* 可分解：比如好多人都只做洗衣服，难道还要给某个人分工只放洗衣粉？
* 重复劳动：不能让一个人一会儿干这个，一会儿又干那个
* 交错式：Concurrent和Parrallel的区别。并发和同时进行的区别。多个人不一定在一个时刻干同一件事，它们是交错进行的。
* 时间特征：

  ![[Pasted image 20221115131545.png]]
  
  我们能看到，圈起来的空档是不饱和的，也就是流水线中的人没有都全部进入工作状态；而框起来的部分就是饱和的。

![[Pasted image 20221115131930.png]]

## 1.1 Classification

流水线的分类有以下几种：

* 单功能 vs 多功能
* 静态 vs 动态
* 级别（处理机级、部件级、宏级）
* 线性 vs 非线性
* 顺序 vs 乱序
* 标量 vs 向量

接下来我们就逐一讨论它们。

**单功能，多功能**

我们看这样一个流水线：

![[Pasted image 20221115161103.png]]

这8个就是当前流水线的各个**功能段**。我们注意到，这里面不仅有加减法，还有乘法。这代表这个流水线不止能完成加减运算，还能做乘除运算。那么我们如何去实现它们呢？显然是通过不同的编程模式，**让这8个stage中的某几个以不同的方式连接起来**，就能完成不同的操作：

![[Pasted image 20221115161305.png]]

像这样能通过编程来实现不同功能的流水线就叫做多功能流水线；反之，如果只能一条道走到黑，那就是单功能流水线。

---

**静态，动态**

比如我们要算加法和乘法。静态流水线就是，先算加法，当所有的加法全算完时，才能开始算乘法。中间宁可空闲也不能提前做：

![[Pasted image 20221115161916.png|300]]

而动态流水线就能很好得利用空闲，提前让一些人去做下一步任务。这样自然也增加了控制的难度，让流水线调度变复杂。

![[Pasted image 20221115162032.png]]

还是举之前单功能多功能的例子，对于静态和动态，它们的**时空图**就是这样的：

![[Pasted image 20221115162340.png|300]]   ![[Pasted image 20221115162418.png|300]]

---

**处理机级、部件级、宏级**

我们在上学期学过，处理器执行指令就分[[cs#2.1 Overview|四步走]]，那么对于这样重复的事情，很显然用流水线可以极大地提高性能。

![[Pasted image 20221115163001.png]]

那么比如我们取到了一个浮点加法的指令，我们之前也学过，浮点的加减法非常复杂，那么肯定会分成许多步骤去执行。那么在这里又可以使用流水线来提高性能。这样就相当于大流水线(处理机级)里夹了一个小流水线(部件级)。

![[Pasted image 20221115163211.png]]

宏级日常用不到，直接给了：

![[Pasted image 20221115163345.png]]

---

**线性，非线性**

![[Pasted image 20221115163527.png]]

![[Pasted image 20221115163537.png]]

---

**顺序，乱序**

比如有下面的指令：

```c
c = a + b; // 1
e = d + c; // 2
x = y + z; // 3
```

^ff3072

我按着1,2,3的顺序输入，那么输出的结果还会是1,2,3吗？在回答这个问题之前，首先分析一下代码：由于第二条中的c用到了第一条中的结果，那就意味着第二条语句一定不能在第一条语句之前执行。但是第三条语句和前两条语句并没有什么关系，所以顺序和乱序的区别就在这里体现出来：

* 如果是顺序流水线，那么输出就是1,2,3；
* 如果是乱序流水线，那么输出很可能是1,3,2或者3,1,2。

这样，乱序流水线就可以让3和1或者2并行，来提高效率。

---

**标量，向量**

![[Pasted image 20221115171017.png]]

---

Concurrent vs Parallel

前者就是流水线的思想：四个人分工，在不同的时刻干不同的事。而后者是完全意义上的并行，也就是不同的人在同一时刻干的就是同一个事。而这两者完全可以叠加起来，也就是时间并行+空间并行：

![[Pasted image 20221115171354.png]]

## 1.2 流水线性能分析

### 1.2.1 Throughput

比如一个人在一段时间内完成了一些活，那么它的吞吐率就是：

$$
TP = \frac{n}{t}
$$

^55901f

其中，n是有多少活，t是时间。比如一个人在100秒内做了1000个活，那吞吐率就是10。而由于有启动时间，或者中间有空档等等原因，吞吐率不一定时时刻刻都是最大的。而最大的吞吐率就叫做$TP_{max}$。那么我们可以推测出来一些信息：比如某个流水线的各个时间段相等，也就是每个stage所占的时间都是$\Delta t_0$。那么也就是说，在饱和后每经过$\Delta t_0$的时间，就会完成1个活，那么显然这个时候的最大吞吐率就是：

$$
TP_{max} = \frac{1}{\Delta t_0}
$$

而如果每个stage所占的时间不相等的话，比如下面这样：

![[Pasted image 20221115172139.png]]

显然这个最长的2，就限制了整个流水线。我们看下面的图：

![[Pasted image 20221115172309.png]] ^10b49a

最左下角的2可以在红圈里滑动，但是咋滑都没用，因为这个最长的2任务就限制了它运行的时间，不管你提前做还是后做，你都要等1这个人把2任务做完之后，2这个人才能做他的2任务。这样就导致了每个任务的输出间隔都变成了最长的$3\Delta t_0$，因此如果间隔不相等的话，最大吞吐率：

$$
TP_{max} = \frac{1}{max\{\Delta t_i\}}
$$

怎么解决这个问题？一个比较直观的方法是：将$3\Delta t_0$拆成三个$\Delta t_0$不就好了嘛！所以我们可以这样：

![[Pasted image 20221115172701.png]]

这种方法的问题显而易见：拆不了咋办？那也有招。我原来是让4个人干4个活，而第二个活用的时间是其他的三倍，**那我就找6个人干4个活，第二个活让三个人来干**。这样虽然进度是一样的，但是第二个活被加速了3倍，所以最终速度也是一样的。只不过这种方式的时空图不太好理解：

![[Pasted image 20221115173155.png]]

综上所述，完成n个任务所需要的总时间：

$$
T_{pl} = m\Delta t_0 + (n-1)\Delta t_0
$$

其中m和n的意义可以看下图：

![[Pasted image 20221117115226.png]]

m就是第一个任务在输出的时候已经经过了多少个段；而总任务是n个，已经完成了1个，剩下的就是n-1个，每隔$\Delta t_0$输出一个。

### 1.2.2 加速比

之前也学过，加速比

$$
S = \frac{T_{old}}{T_{new}}
$$

而如果我们要将它用在流水线上呢？那我们可以得出，$T_{old}$就是不采用流水线的时间，而$T_{new}$就是采用流水线的时间。当我们不采用流水线的时候，**有n个任务，而每个任务被拆成了m个stage**。这些stage不能交替执行，只能一个个来。那么如果每个stage需要的时间是$\Delta t_0$，那么每个任务需要的时间就是$m\Delta t_0$。这样n个任务完成的时间就是：

$$
T_{非流水} = nm\Delta t_0
$$

而当我们采用了流水线，那么总体的时间就是之前介绍过的：

$$
T_{流水} = m\Delta t_0 + (n-1)\Delta t_0
$$

那么加速比：

$$
S = \frac{nm\Delta t_0}{m\Delta t_0 + (n-1)\Delta t_0} = \frac{mn}{m+n-1} = \frac{m}{1+\frac{m-1}{n}}
$$

通过上式可以看出，当n >> m时，$S\rightarrow m$。同时，当n越大，m也越大时，加速比会非常高，性能会非常好。**这样就要求我们需要大量任务，同时每个任务切的要很细**。

#example Throughput

![[Pasted image 20221118204532.png]]

根据公式$T_{流水} = m\Delta t_0 + (n-1)\Delta t_0$，我们能得到该流水线的时间为

$$
T_{流水} = 4 \times 250ps + 99 \times 250ps = 25.75ns
$$

而如果不用流水线，就是常规的100个任务，每个任务4个stage，即$T_{非流水} = nm\Delta t_0$：

$$
T_{非流水} = 100 \times 4 \times 250ps = 100ns
$$

那么加速比很显然就是：

$$
S = \frac{T_{非流水}}{T_{流水}} = 3.88
$$

因为所有的stage持续时间都是$\Delta t_0$，那么最大吞吐率也很简单：

$$
TP_{max} = \frac{1}{\Delta t_0} = 4\ GFLOPS
$$

---

![[Pasted image 20221118205218.png]]

这道题的问题有两个：首先是每个stage的时间参差不齐，这对应上面的[[#^10b49a|这种情况]]；另外它也没给要执行多少个任务，只让求加速比。通过这点我们也能推测出来，**其实加速比和执行多少任务没有很大关系**。那么这个时候如何计算$T_{流水}$呢？这里需要一个比较灵活的思想。在处理流水线时，其实就是每隔$\Delta t$会完成一个任务。而如果不适用流水线，每隔$\Delta t1$才会完成一个任务。因此只需要让它们两个相除就能计算出大概的加速比了。

$$
T_{非流水} = 10 + 8 + 10 + 10 + 7 = 45\ ns
$$

算$T_{流水}$的时候，其实就是看多长时间能完成一个任务。那根据之前所说，就是最长的stage持续时间，也就是10ns。最后别忘了加上题里给的开销：

$$
T_{流水} = 10 + 1 = 11\ ns
$$

那么加速比

$$
S = \frac{45}{11} = 4.1
$$

---

#poe 非常爱考

![[Pasted image 20221118211007.png]]

上图表示的是一个流水线，如果算乘法的话，路线是1678；如果算加法，路线是123458。那么它要你去计算这样一个式子：

![[Pasted image 20221118211311.png]]

让你给出合理的规划。首先为什么要规划？因为乘法和加法交替算就根本没办法用流水线，所以我们需要对这个计算重新排序，让它尽可能先算乘法，后算加法。那么思想就是：先分别算$A1B1$ ... $A4B4$，然后再把这四个值加起来。因此需要算4次乘法和3次加法。下面是解法的其中之一：

![[Pasted image 20221118211523.png]]

根据这个思路，我们能画出时空图(我觉得还是比较简单的)：

![[Pasted image 20221118211705.png]]

需要注意的是，时空图最上面的一排是输出，也就是一个任务完成的标志。该题中一共输出了7个任务，正好就是我们之前分配的4个乘法和三个加法，它们每个都是一个任务。

假设每个stage持续时间都是t，那么根据[[#^55901f|Throughput的公式]]可以得出

$$
TP = \frac{7}{20t}
$$

然后是加速比，这就需要算两个时间了，首先是非流水的，很简单。有4个乘法，每个乘法是4个stage，那么总时间就是$4 \times 4 \times t = 16t$；还有3个加法，每个是6个stage，总时间是$3 \times 6 \times t = 18t$。最后加起来：

$$
T_{非流水} = 16t + 18t = 34t
$$

而采用了流水线，我们还用之前的公式？out了！时空图都在这儿摆着，我们不妨看看$T_{流水}$到底是什么：

![[Pasted image 20221117115226.png]]

**这不就是横坐标最长有多少时间嘛**！所谓的$T_{流水}$其实就是采用了流水线后完成这些任务的总时长，那么就对应的是时空图的坐标。在本题中，显然

$$
T_{流水} = 20t
$$

那么加速比就算出来了

$$
S = \frac{34t}{20t} = 1.7
$$

最后是效率，没啥好说的，数方块！

![[Pasted image 20221118212916.png]]

可以看到，太慢了。能不能快点，比如这样？

![[Pasted image 20221118213344.png]]

答案是：no！注意4,5之间的方块，这表示取A1B1和A2B2的值的操作。但是此时A1B1是有了，而A2B2正在进行输出，所以不能执行。而5,6之间的方块表示取A3B3和A4B4的值，此时正在输出A3B3，A4B4甚至还没开始写回，所以肯定不行。我们要改进，只能改进成这样：

![[Pasted image 20221118213608.png]]

可以看到，总的时间节省了1个t。

这就是这种综合题的考法：

* 静态流水线，给任务，让你规划
* 画时空图
* 算各种东西
* 优化

### 1.2.3 效率

简单来讲，就是：$E = \frac{平行四边形}{矩形}$。

![[Pasted image 20221117121249.png]]

比如这张图中，就是所有任务占的总格子数除以整个的时间格数。那么这里平行四边形的面积显然就是$mn$，而总的时间已经给出，那么它的效率

$$
E = \frac{mn}{[m\Delta t_0 + (n-1)\Delta t_0]\centerdot m}
$$

这样我们两边浪费的时间占比越小，我们就是越好地利用了这个流水线，将每个设备榨干到极致。

## 1.3 Pipeline Hazard

流水线固然能加速，但是用不好，也会产生很大的问题。Harzard的意思是"冒险"，这一节所介绍的全部都是**用冒险来换取CPU的性能**的操作。

### 1.3.1 Structure

![[Pasted image 20221117122633.png]]

在上图中，这个标红的MEM操作集合IF操作是不能同时进行的：一个表示写回，另一个表示取址。即使它俩写的和读的不是同一个地址，那对于一个硬件来说，它如果本身就不支持同时读写该咋办？这种和**硬件结构相关的错误**是最底层的。那么我们如何解决呢？先说一个不靠谱的方法：等。

![[Pasted image 20221117122922.png]]

在这里告诉它：你先等会儿，等他写完了你再读。但是这样属于治标不治本：后面还有MEM和IF冲突，甚至还有好多，所以我们需要别的方法。

其实，如今的存储系统早已不是单个的颗粒。我们的数据都是分散在**不同内存的不同颗粒、不同硬盘的不同分区的不同颗粒中的**。而这些颗粒在物理上必然不是一个芯片，那同时读写当然没问题。这也是我们为什么要分散存储的主要原因之一——提高并发性能。

### 1.3.2 Data

另外，我们[[#^ff3072|之前的例子]]中也提到过流水线的缺点。这是由于数据的读写顺序问题，并且**离得很近**的时候才会产生的。我们将它们分个类：

1. Read After Write(RAW)

下面的例子中：

```c
C = A + B;
E = C + B;
```

先写了C，之后紧接着又读了C。这样由于执行顺序问题就可能会出现错误。

2. Write After Write(WAW)

```c
C = A[100] + B[100];
C = m + n;
```

第二条指令执行的时间显然比第一条短。那么这个情况下很可能会让第二条先算完，最后C中的值变成了第一条的结果，产生错误。

3. Write After Read(WAR)

这种情况还是比较少会发生的。

```c
C = A + B[100];
A = m + n;
```

对第一条来说，A很快就读完了，将地址读出来放到寄存器里，这时候等着B去读。那么这个时候如果第二条指令先执行完了，那么A的地址中很可能就会变成m+n了。

下面是一个四种情况的例子：

![[Pasted image 20221117124426.png]]

---

如何解决这些问题？等！只有等。因为我们不知道程序是什么样的，只有拿到结果才能继续执行。但是，我们依然可以通过一些手段去缩减等的时间。

比如这个Forwarding技术。如果我们不使用Forwarding的话，下面是一个例子：

![[Pasted image 20221117125300.png]]

可以看到，因为k+2这个任务使用了k这个任务的结果，所以必须等k写回之后才能执行k+2。这样就会产生大量的空闲时间，k+2在$t_{i+3}$时刻才发生了读取。而如果我们让k计算出的结果**不但能写回内存，还能直接传给k+2**的话，那样效率就会提升很多了：

![[Pasted image 20221117125706.png]]

看到增加了回路之后，在$t_{i+1}$时刻就能发生读取了。

除了这种更改CPU构造的操作，我们还可以从编译器入手。比如对程序指令重新排序，在两条相邻并且有依赖关系的指令中间插入许多无关指令或者空指令。

### 1.3.3 Control

如果有下面的指令：

```c
if(compare()){
	...
}else{
	...
}
```

当执行到if语句的时候，问题来了：如果我要提前去取址的话，是取if里的还是else里的？必须得等`compare()`的结果得到之后才可以。那么这个时候就会产生空档：

![[Pasted image 20221117130810.png]]

> 图中的I3就可以当做比较的这个函数。在它写回之前不能提前去取址。

怎么解决？最简单的，等！但是这是几百年前的玩意儿了，我们弄个潮先。

取址移码执行写回，这些步骤中，执行其实是最快的，因为都在CPU内部。但是涉及到读内存的时候，就会非常浪费时间。那么我们可以提前将它们都做了，放到随便一个buffer里。这样等到执行的时候就快了：

```c
if(compare()){
	...
}else{
	...
}
```

上面两个分支我全都要！最后哪个被执行我选哪个。除了这些操作，目前CPU大量采用的还有**分支预测**技术，接下来我们就来讨论一下。

### 1.3.4 分支预测

什么是预测？就是赌！

![[Pasted image 20221119201917.png]]

还是那段代码：

```c
if(compare()){
	...
}else{
	...
}
```

理论上，**else分支是更快的**。原因就是当翻译为汇编之后，if分支对应的语句就是一句`jmp`，也就是会跳到别的地方去执行，而不挺跳直接向下继续执行往往是更快的。

那么我们就可以采取这种策略：运行前就规定好，每次我都赌这个程序不会跳转，只会继续执行(或者反之)。由于是提前规定好，所以这种方法叫做**静态预测分支**。

另外，静态预测分支还有其他的方法，比如由程序员去告诉编译器我跳的概率。在新版本c标准中，会有大量的`likely`或者`unlikely`标志(尤其是在linux kernel中，我在做qemu的时候也有体会)。这些标志就是用来告诉编译器翻译的时候就尽可能按着跳转或者不跳转去翻译，来提高性能。

总之，**静态分支预测的策略就是让编译器翻译出来的代码尽可能都是不会跳转的**。比如：

![[Pasted image 20221119202643.png]]

> a中基本上循环执行的时候每次都会提前去取**再后面**的指令，那相当于不断地白干活；而b中只有最后一次跳的时候才会取**循环体**中这些本来不会被执行的代码，只会错一次。

---

接下来就是相对应的**动态分支预测**了，这部分涉及到[[cp#3.3 Finite Automata|自动机]]的知识。动态的思想就是，在每个跳转的位置都打上一个标记，这个标记其实是一个表，每次运行到这里时都先根据表中的信息去决定跳不跳。首先是跳转的位置，比如一个循环：

```asm
	mov cx, 100
flag:
	mov ax, 1
	add ax, 2
	loop flag
```

`loop flag`就是一个跳转的位置，每当程序运行到这里时，都要去确定它到底要不要跳。如果跳就回到`flag`；如果不跳就继续往下执行。

接下来，我们用一个bit去实现动态分支预测。

* 首先规定：0表示不跳，1表示跳。如果我们一开始猜测所有的跳转位置都是不跳的话，那这个bit初值就是0。
* 当第一次运行到这里时，很显然是要跳的，这代表**我猜错了**，那么我就要把这个bit改成1并跳转。
* 之后运行的时候每次都会跳，也每次都是1，代表每次我都猜对了。这个时候每次都会对`mov ax, 1`和`add ax, 2`这两条指令**提前做取值译码之类的操作**。
* 只有最后一次要退出循环的时候才又错了，这个时候我不跳了，要继续往下执行了，那最后就将这个bit还原回0。

那么我们之前说的表是什么呢？一个有效位(这个标志是否有效)、这个标志本身(可以是地址或者其他的)、还有上面说的这个bit就是表中的每一项了，这也叫做**1位跳转历史表**：

![[Pasted image 20221119204537.png]]

由此我们也能画出上面过程的自动机：

![[Drawing 2022-11-19 20.46.01.excalidraw]]

除了1位的，我们还有2位的。这里首先给出4种状态的含义：

state bit | meaning
-- | --
00 | 强烈认为不会跳
01 | 我还是认为不会跳，但是有点动摇了
10 | 我认为会跳，但是也有点动摇
11 | 我强烈认为会跳

当处于00或者11时，都有一次猜错的机会。也就是虽然我猜错了，但是它还有可能是这样，所以我下次还不长记性。只有我下次又猜错了，我才知道我真的错了。

当处于01时，表示我认为不会跳，但是我有点动摇。这个时候如果下次真就是不会跳，那表示我的猜测还是不错的嘛！那我就变成强烈认为不会跳；而如果我猜错了，跳了，那我就变成墙头草，变成11，坚信认为会跳。处于10时的操作类似。那么根据这些，我们就能画出2位的自动机：

![[Drawing 2022-11-19 20.54.34.excalidraw|700]]

## 1.4 Even Faster

我们如何才能让计算机变的更快呢？接下来是一些策略。

**Superscalar**

这个就和我们之前的那个[[Pasted image 20221115171354.png|空间并行]]很相似(我感觉就是一个东西)。也就是CPU内部有多个流水线同时在做一件事，比如取值有3个人在同时取3个指令的地址；译码有3个人在同时译3个指令的码等等：

![[Computer Structure/resources/Pasted image 20221121160253.png]]

这种做法就是在纯纯地堆硬件，因为你得真有3个人才能这么干。

---

**Super Pipeline**

还是取值译码执行写回，那这4步中的每一步其实都可以拆成更细的stage，那么就不是4级，可能是40级甚至400级的流水线，这样效率也能提高。

![[Computer Structure/resources/Pasted image 20221121160711.png]]

---

**Superpipelined Superscalar**

就是前两种加起来，又有多个人，又拆：

![[Computer Structure/resources/Pasted image 20221121161413.png]]

对于这三种类型的流水线，我们可以给一个表格总结一下它们的性能：

Pipeline | Stage Time | Number of instructions in parallel | Time Between Emit | ILP
-- | -- | -- | -- | --
Standard | 1 | 1 | 1 | 1
m Superscalar | 1 | m | 1 | m
n Super Pipeline | $\frac{1}{n}$ | 1 | $\frac{1}{n}$ | n
m,n Superpipelined Superscalar | $\frac{1}{n}$ | m | $\frac{1}{n}$ | m \* n

下面就以取值译码执行写回这个例子来说明这个表格。正常的流水线，这4步中的每一步都是一个stage。那么每个stage的时间就是1；由于没有任何并行，就像这样：

![[Computer Structure/resources/Pasted image 20221121190519.png]]

因此在同一时刻实际上并行(空间并行)的任务只有一个。而在这种情况下，也是每隔1个时间就会发出一条指令，也就是`取址`-`等待1`-`下一个指令的取址`-`等待1`-...，这种情况对译码，执行，写回也同样适用；那么最终描述这个流水线性能的ILP(Instruction Level Parrallelism)就是1，相当于：**我用了执行完1套取址译码执行写回的时间真的就只执行了1套取址译码执行写回**。

当轮到m度的超标量流水线的时候，就可以开始并行了。因为它可以让多个人干一件事，也就是空间并行，所以如果有m个人的话，同一时刻并行的任务就是m个。这样虽然也是每隔1个时间发射(emit)一条指令，但是实际的执行情况是`指令1和指令2的取址`-`等待1`-`指令3和指令4的取址`-...。因此ILP为m，表示**我用了执行完1套取址译码执行写回的时间执行了m套取址译码执行写回，因为我有m个人同时干活**。

之后是超流水流水线，因为它拆了一下，所以原来的4个stage被拆成了n个小stage。那么和普通流水线唯一的区别是，stage持续时间从1变成了$\frac{1}{n}$。这样只需要$\frac{1}{n}$个时间就能完成1套取址译码执行写回，那么显然ILP应该等于n。

最后一行就是它俩加起来，那么就是**在完成1套取址译码执行写回的时间完成了m \* n 套这些操作**。

---

我们想一想，这些流水线谁最快？乍一想，肯定是Superpipelined Superscalar，因为它集成了这两者的优点。但实际情况却是这样：

![[Computer Structure/resources/Pasted image 20221121192315.png]]

最重要的原因就是：**Super Pipeline本身就是一个辣鸡设计**。它的思想就是将大stage拆成小的stage。但是其中的问题就是，**很多任务(最常见最常见的任务)在拆分完之后很多操作是不能交错执行的，甚至好多任务是不能拆的**。这样就导致了虽然看似搞的很细，实际上中间有大量的空洞，效率和速度反而降低了。

## 1.5 Out-of-Order Execution(OoOE)

CPU在执行某一条指令时，如果依赖于之前计算出的结果，就会发生等待。必须等结果出来之后才能继续执行。这在之前也已经提过许多次了。

![[Computer Structure/resources/Pasted image 20221121193918.png]]

比如本图中，第二条指令需要依赖R3这个结果，所以必须要在第一条指令算完之后才能执行。但是第一条执行的时间足足有4个stage，所以要等3个stage才行。另外，由于第三条指令企图修改R1，所以不能先执行它，否则第二条的结果可能会产生错误，所以第三条指令也要等。

**那么，我们能不能在等的这段时间里做点什么？**

乱序执行的概念比较像操作系统中[[Operating System/os#4.3.3 SJF Example(Preemptive)|进程的抢占]]，但是还不是一回事。比如第二条指令在等待的过程中，我先执行第三条指令，**但是不写回**：

![[Computer Structure/resources/Pasted image 20221121194742.png]]

这种做法就是乱序执行了。
