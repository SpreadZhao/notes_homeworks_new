---
author: "Spread Zhao"
title: cs2
category: inter_class
description: 计算机组成与结构2课堂笔记，蒋志平老师
---

# 1. Pipe Line

举个洗衣服的例子：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115130320.png]]

那么如果是**纯串行**的话，就是张三洗烘熨放；李四洗烘熨放……

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115130443.png]]

这样一共要八个小时，也太浪费了。其实，第一个人在洗完之后，洗衣机完全就可以给第二个人用了，烘干机、熨斗、晾衣架也是如此。那么我们完全可以这样：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115130650.png]]

**由此例子，我们能总结出流水线任务的特点**：

* 可被拆解
* 拆解的段可同时执行

当然，流水线的特点不止这些：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115131321.png]]

* 大量：不能好多人只做一道题，那分也没啥意思
* 可分解：比如好多人都只做洗衣服，难道还要给某个人分工只放洗衣粉？
* 重复劳动：不能让一个人一会儿干这个，一会儿又干那个
* 交错式：Concurrent和Parrallel的区别。并发和同时进行的区别。多个人不一定在一个时刻干同一件事，它们是交错进行的。
* 时间特征：

  ![[Lecture Notes/Computer Structure/resources/Pasted image 20221115131545.png]]

  > #keypoint 数字表示的是第几个任务。因此有4个1表示1任务被拆成4段。2任务，3任务等等也是同理。而有了这个概念，我们还能发现，纵轴表示的正好就是每个任务被拆成了多少个段。**如果纵轴有n段，那么这个流水线就是n级流水线**。

  我们能看到，圈起来的空档是不饱和的，也就是流水线中的人没有都全部进入工作状态；而框起来的部分就是饱和的。

![[Lecture Notes/Computer Structure/resources/Pasted image 20230301162726.png]]

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115131930.png]]

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

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115161103.png]]

这8个就是当前流水线的各个**功能段**。我们注意到，这里面不仅有加减法，还有乘法。这代表这个流水线不止能完成加减运算，还能做乘除运算。那么我们如何去实现它们呢？显然是通过不同的编程模式，**让这8个stage中的某几个以不同的方式连接起来**，就能完成不同的操作：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115161305.png]]

像这样能通过编程来实现不同功能的流水线就叫做多功能流水线；反之，如果只能一条道走到黑，那就是单功能流水线。

---

**静态，动态**

比如我们要算加法和乘法。静态流水线就是，先算加法，当所有的加法全算完时，才能开始算乘法。中间宁可空闲也不能提前做：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115161916.png|300]]

而动态流水线就能很好得利用空闲，提前让一些人去做下一步任务。这样自然也增加了控制的难度，让流水线调度变复杂。

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115162032.png]]

还是举之前单功能多功能的例子，对于静态和动态，它们的**时空图**就是这样的：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115162340.png|300]]   ![[Lecture Notes/Computer Structure/resources/Pasted image 20221115162418.png|300]]

---

**处理机级、部件级、宏级**

我们在上学期学过，处理器执行指令就分[[Lecture Notes/Computer Structure/cs#2.1 Overview|四步走]]，那么对于这样重复的事情，很显然用流水线可以极大地提高性能。

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115163001.png]]

那么比如我们取到了一个浮点加法的指令，我们之前也学过，浮点的加减法非常复杂，那么肯定会分成许多步骤去执行。那么在这里又可以使用流水线来提高性能。**这样就相当于大流水线(处理机级)里夹了一个小流水线(部件级)**。

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115163211.png]]

宏级日常用不到，直接给了：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115163345.png]]

---

**线性，非线性**

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115163527.png]]

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115163537.png]]

---

**顺序，乱序** ^f151cf

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

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115171017.png]]

---

Concurrent vs Parallel

前者就是流水线的思想：四个人分工，在不同的时刻干不同的事。而后者是完全意义上的并行，也就是不同的人在同一时刻干的就是同一个事。而这两者完全可以叠加起来，也就是时间并行+空间并行：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115171354.png]]

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

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115172139.png]]

显然这个最长的2，就限制了整个流水线。我们看下面的图：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115172309.png]] ^10b49a

最左下角的2可以在红圈里滑动，但是咋滑都没用，因为这个最长的2任务就限制了它运行的时间，不管你提前做还是后做，你都要等1这个人把2任务做完之后，2这个人才能做~~他的2任务~~**第二个任务的第二段，即使第二个任务的第一段很早就把第二个任务的第一段做完了也不行，得等着**。这样就导致了每个任务的输出间隔都变成了最长的$3\Delta t_0$，因此如果间隔不相等的话，最大吞吐率：

$$
TP_{max} = \frac{1}{max\{\Delta t_i\}}
$$

怎么解决这个问题？一个比较直观的方法是：将$3\Delta t_0$拆成三个$\Delta t_0$不就好了嘛！所以我们可以这样：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115172701.png]]

这种方法的问题显而易见：拆不了咋办？那也有招。我原来是让4个人干4个活，而第二个活用的时间是其他的三倍，**那我就找6个人干4个活，第二个活让三个人来干**。这样虽然进度是一样的，但是第二个活被加速了3倍，所以最终速度也是一样的。只不过这种方式的时空图不太好理解：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221115173155.png]]

综上所述，完成n个任务所需要的总时间：

$$
T_{pipe\_line} = m\Delta t_0 + (n-1)\Delta t_0
$$

其中m和n的意义可以看下图：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221117115226.png]]

> **m就是第一个任务在输出的时候已经经过了多少个段，我们发现它总是等于流水线的级数，也就是每个任务拆成了多少个stage；而总任务是n个，已经完成了1个，剩下的就是n-1个，每隔$\Delta t_0$输出一个**。

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

### 1.2.3 效率

简单来讲，就是：$E = \frac{平行四边形}{矩形}$。

![[Lecture Notes/Computer Structure/resources/Pasted image 20221117121249.png]]

比如这张图中，就是所有任务占的总格子数除以整个的时间格数。那么这里平行四边形的面积显然就是$mn$(底是n，高是m(stage个数))，而总的时间已经给出，那么它的效率

$$
E = \frac{mn}{[m\Delta t_0 + (n-1)\Delta t_0]\centerdot m}
$$

这样我们两边浪费的时间占比越小，我们就是越好地利用了这个流水线，将每个设备榨干到极致。

### 1.2.4 Exercise

#example Throughput

![[Lecture Notes/Computer Structure/resources/Pasted image 20221118204532.png]]

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

![[Lecture Notes/Computer Structure/resources/Pasted image 20221118205218.png]]

这道题的问题有两个：首先是每个stage的时间参差不齐，这对应上面的[[#^10b49a|这种情况]]；另外它也没给要执行多少个任务，只让求加速比。通过这点我们也能推测出来，**其实加速比和执行多少任务没有很大关系**。那么这个时候如何计算$T_{流水}$呢？这里需要一个比较灵活的思想。在处理流水线时，其实就是每隔$\Delta t$会完成一个任务。而如果不使用流水线，每隔$\Delta t1$才会完成一个任务。因此只需要让它们两个相除就能计算出大概的加速比了。

$$
T_{非流水} = 10 + 8 + 10 + 10 + 7 = 45\ ns / task
$$

算$T_{流水}$的时候，其实就是看多长时间能完成一个任务。那根据之前所说，就是最长的stage持续时间，也就是10ns。最后别忘了加上题里给的开销：

$$
T_{流水} = 10 + 1 = 11\ ns/task
$$

那么加速比

$$
S = \frac{45}{11} = 4.1
$$

---

#poe 非常爱考

![[Lecture Notes/Computer Structure/resources/Pasted image 20221118211007.png|400]]

上图表示的是一个流水线，如果算乘法的话，路线是1678；如果算加法，路线是123458。那么它要你去计算这样一个式子：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221118211311.png]]

让你给出合理的规划。首先为什么要规划？因为乘法和加法交替算就根本没办法用流水线，所以我们需要对这个计算重新排序，让它尽可能先算乘法，后算加法。那么思想就是：先分别算$A1B1$ ... $A4B4$，然后再把这四个值加起来。因此需要算4次乘法和3次加法。下面是解法的其中之一：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221118211523.png]]

根据这个思路，我们能画出时空图(我觉得还是比较简单的)：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221118211705.png]]

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

![[Lecture Notes/Computer Structure/resources/Pasted image 20221117115226.png]]

**这不就是横坐标最长有多少时间嘛**！所谓的$T_{流水}$其实就是采用了流水线后完成这些任务的总时长，那么就对应的是时空图的坐标。在本题中，显然

$$
T_{流水} = 20t
$$

那么加速比就算出来了

$$
S = \frac{34t}{20t} = 1.7
$$

最后是效率，没啥好说的，数方块！

![[Lecture Notes/Computer Structure/resources/Pasted image 20221118212916.png]]

可以看到，太慢了。能不能快点，比如这样？

![[Lecture Notes/Computer Structure/resources/Pasted image 20221118213344.png]]

答案是：no！注意4,5之间的方块，这表示取A1B1和A2B2的值的操作。但是此时A1B1是有了，而A2B2正在进行输出，所以不能执行。而5,6之间的方块表示取A3B3和A4B4的值，此时正在输出A3B3，A4B4甚至还没开始写回，所以肯定不行。我们要改进，只能改进成这样：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221118213608.png]]

可以看到，总的时间节省了1个t。

这就是这种综合题的考法：

* 静态流水线，给任务，让你规划
* 画时空图
* 算各种东西
* 优化

## 1.3 Pipeline Hazard

流水线固然能加速，但是用不好，也会产生很大的问题。Hazard的意思是"冒险"，这一节所介绍的全部都是**用冒险来换取CPU的性能**的操作。

![[Lecture Notes/Computer Structure/resources/Pasted image 20230301171727.png]]

![[Lecture Notes/Computer Structure/resources/Pasted image 20230301172023.png]]

> 比如还是[[#^ff3072|之前]]那个例子，如果我能在后面插一条和它们不相关的指令，让这个无关指令和第一条`c = a + b;`并行，之后用到c的时候，这条指令就算完了，不用等。因此这种相关性是**能绕开**的，所以被称为局部性相关。

### 1.3.1 Structure Hazard

![[Lecture Notes/Computer Structure/resources/Pasted image 20221117122633.png]]

在上图中，这个标红的MEM操作集合IF操作是不能同时进行的：一个表示写回，另一个表示取址。即使它俩写的和读的不是同一个地址，那对于一个硬件来说，它如果本身就不支持同时读写该咋办？这种和**硬件结构相关的错误**是最底层的。那么我们如何解决呢？先说一个不靠谱的方法：等。

![[Lecture Notes/Computer Structure/resources/Pasted image 20221117122922.png]]

在这里告诉它：你先等会儿，等他写完了你再读。但是这样属于治标不治本：后面还有MEM和IF冲突，甚至还有好多，所以我们需要别的方法。

其实，如今的存储系统早已不是单个的颗粒。我们的数据都是分散在**不同内存的不同颗粒、不同硬盘的不同分区的不同颗粒中的**。而这些颗粒在物理上必然不是一个芯片，那同时读写当然没问题。这也是我们为什么要分散存储的主要原因之一——提高并发性能。

避免结构相关的方法：

* 所有功能单元完全流水化；
* 设置足够多的硬件资源

### 1.3.2 Data Harzard

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

下面是一个这些情况的例子：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221117124426.png]]

---

如何解决这些问题？等！只有等。因为我们不知道程序是什么样的，只有拿到结果才能继续执行。但是，我们依然可以通过一些手段去缩减等的时间。

比如这个Forwarding(直通)技术。如果我们不使用Forwarding的话，下面是一个例子：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221117125300.png]]

可以看到，因为k+2这个任务使用了k这个任务的结果，所以必须等k写回之后才能执行k+2。这样就会产生大量的空闲时间，k+2在$t_{i+3}$时刻才发生了读取。而如果我们让k计算出的结果**不但能写回内存，还能直接传给k+2**的话，那样效率就会提升很多了：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221117125706.png]]

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

^5c1c35

当执行到if语句的时候，问题来了：如果我要提前去取址的话，是取if里的还是else里的？必须得等`compare()`的结果得到之后才可以。那么这个时候就会产生空档：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221117130810.png]]

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

### 1.3.4 Branch Prediction

什么是预测？就是赌！

![[Lecture Notes/Computer Structure/resources/Pasted image 20221119201917.png]]

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

![[Lecture Notes/Computer Structure/resources/Pasted image 20221119202643.png]]

> a中基本上循环执行的时候每次都会提前去取**再后面**的指令，那相当于不断地白干活；而b中只有最后一次跳的时候才会取**循环体**中这些本来不会被执行的代码，只会错一次。

---

接下来就是相对应的**动态分支预测**了，这部分涉及到[[Lecture Notes/Compile/cp#3.3 Finite Automata|自动机]]的知识。动态的思想就是，在每个跳转的位置都打上一个标记，这个标记其实是一个表，**每次运行到这里时都先根据表中的信息去决定跳不跳**。首先是跳转的位置，比如一个循环：

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

![[Lecture Notes/Computer Structure/resources/Pasted image 20221119204537.png]]

由此我们也能画出上面过程的自动机：

![[Lecture Notes/Computer Structure/resources/Drawing 2022-11-19 20.46.01.excalidraw.png]]

除了1位的，我们还有2位的。这里首先给出4种状态的含义：

state bit | meaning
-- | --
00 | 强烈认为不会跳
01 | 我还是认为不会跳，但是有点动摇了
10 | 我认为会跳，但是也有点动摇
11 | 我强烈认为会跳

当处于00或者11时，都有一次猜错的机会。也就是虽然我猜错了，但是它还有可能是这样，所以我下次还不长记性。只有我下次又猜错了，我才知道我真的错了。

当处于01时，表示我认为不会跳，但是我有点动摇。这个时候如果下次真就是不会跳，那表示我的猜测还是不错的嘛！那我就变成强烈认为不会跳；而如果我猜错了，跳了，那我就变成墙头草，变成11，坚信认为会跳。处于10时的操作类似。那么根据这些，我们就能画出2位的自动机：

![[Lecture Notes/Computer Structure/resources/Drawing 2022-11-19 20.54.34.excalidraw.png]]

## 1.4 Even Faster

我们如何才能让计算机变的更快呢？接下来是一些策略。

**Superscalar**

这个就和我们之前的那个[[Lecture Notes/Computer Structure/resources/Pasted image 20221115171354.png|空间并行]]很相似(我感觉就是一个东西)。也就是CPU内部有多个流水线同时在做一件事，比如取值有3个人在同时取3个指令的地址；译码有3个人在同时译3个指令的码等等：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221121160253.png]]

这种做法就是在纯纯地堆硬件，因为你得真有3个人才能这么干。

---

**Super Pipeline**

还是取值译码执行写回，那这4步中的每一步其实都可以拆成更细的stage，那么就不是4级，可能是40级甚至400级的流水线，这样效率也能提高。

![[Lecture Notes/Computer Structure/resources/Pasted image 20221121160711.png]]

---

**Superpipelined Superscalar**

就是前两种加起来，又有多个人，又拆：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221121161413.png]]

对于这三种类型的流水线，我们可以给一个表格总结一下它们的性能：

Pipeline | Stage Time | Number of instructions in parallel | Time Between Emit | ILP
-- | -- | -- | -- | --
Standard | 1 | 1 | 1 | 1
m Superscalar | 1 | m | 1 | m
n Super Pipeline | $\dfrac{1}{n}$ | 1 | $\dfrac{1}{n}$ | n
m,n Superpipelined Superscalar | $\dfrac{1}{n}$ | m | $\dfrac{1}{n}$ | $m \times n$

下面就以取值译码执行写回这个例子来说明这个表格。正常的流水线，这4步中的每一步都是一个stage。那么每个stage的时间就是1；由于没有任何**空间**并行，就像这样：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221121190519.png]]

因此在同一时刻实际上并行(空间并行)的任务只有一个。而在这种情况下，也是每隔1个时间就会发出一条指令，也就是`取址(1st second)`-`下一个指令的取址(2nd second)`-...，这种情况对译码，执行，写回也同样适用；那么最终描述这个流水线性能的ILP(Instruction Level Parrallelism)就是1，相当于：**我用了执行完1套取址译码执行写回的时间真的就只执行了1套取址译码执行写回**。

当轮到m度的超标量流水线的时候，就可以开始并行了。因为它可以让多个人干一件事，也就是空间并行，所以如果有m个人的话，同一时刻并行的任务就是m个。这样虽然也是每隔1个时间发射(emit)一条指令，但是实际的执行情况是`指令1和指令2的取址(1st second)`-`指令3和指令4的取址(2nd second)`-...。因此ILP为m，表示**我用了执行完1套取址译码执行写回的时间执行了m套取址译码执行写回，因为我有m个人同时干活**。

之后是超流水流水线，因为它拆了一下，所以原来的4个stage被拆成了n个小stage。那么和普通流水线唯一的区别是，stage持续时间从1变成了$\frac{1}{n}$。这样只需要$\frac{1}{n}$个时间就能完成1套取址译码执行写回，那么显然ILP应该等于n。

最后一行就是它俩加起来，那么就是**在完成1套取址译码执行写回的时间完成了m \* n 套这些操作**。

---

我们想一想，这些流水线谁最快？乍一想，肯定是Superpipelined Superscalar，因为它集成了这两者的优点。但实际情况却是这样：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221121192315.png]]

最重要的原因就是：**Super Pipeline本身就是一个辣鸡设计**。它的思想就是将大stage拆成小的stage。但是其中的问题就是，**很多任务(最常见最常见的任务)在拆分完之后很多操作是不能交错执行的，甚至好多任务是不能拆的**。这样就导致了虽然看似搞的很细，实际上中间有大量的空洞，效率和速度反而降低了。

## 1.5 Out-of-Order Execution(OoOE)

CPU在执行某一条指令时，如果依赖于之前计算出的结果，就会发生等待。必须等结果出来之后才能继续执行。这在之前也已经提过许多次了。

![[Lecture Notes/Computer Structure/resources/Pasted image 20221121193918.png]]

比如本图中，第二条指令需要依赖R3这个结果，所以必须要在第一条指令算完之后才能执行。但是第一条执行的时间足足有4个stage，所以要等3个stage才行。另外，由于第三条指令企图修改R1，所以不能先执行它，否则第二条的结果可能会产生错误，所以第三条指令也要等。

**那么，我们能不能在等的这段时间里做点什么？**

乱序执行的概念比较像操作系统中[[Lecture Notes/Operating System/os#4.3.3 SJF Example(Preemptive)|进程的抢占]]，但是还不是一回事。比如第二条指令在等待的过程中，我先执行第三条指令，**但是不写回**：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221121194742.png]]

这种做法就是乱序执行了。

### 1.5.1 静态多发射

实现乱序执行有许多方式，其中之一是**在编译器编译的时候就处理好**，哪些指令能够并行。这样CPU直接按着编译器编好的去执行，就一定是个乱序执行。这种方式就叫做**静态多发射**。

### 1.5.2 Scoreboard

静态多发射非常依赖于CPU的架构，比如Zen4架构的avx-512指令集，虽然能带来很大提升，但是只是对于这个CPU。所以CPU还要有自己的方式去实现乱序执行。**计分板**就是一个非常经典的方法。比如我们要执行下面的几条指令：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125125455.png]]

其中第一列是指令的类型。LD表示加载；MULT，SUBD等等就是计算。第二列是算的结果放在哪里，也就是destination。第三列和第四列是source。比如第一条指令，表示加载一个指令，来自R2寄存器，结果放到F6中。

需要注意的是，**这里的每一行是一个指令，是一个任务，是一个流水线**。每一行被拆分成了4步：

* Issue
* Read Operands
* Execution
* Write Result

这4步是什么，跟着下面的例子就能看懂。

接下来就一步步试着执行它。首先，我们来到第一个时刻：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125130042.png]]

上图中的Issue表示**指令译码**，此时我们需要检测[[#1.3.1 Structure|结构相关]]的东西。这个时刻，我们需要做的是加载指令，那么需要一个部件，叫做`Integer`。那么此时这个部件开始工作，自然是处于Busy的状态；另外它要从R2处取数据，存放到F6中：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125130157.png]]

最后一列是Fk这个寄存器是否就绪。因为是第一条指令，很显然是就绪的，因此为Yes，表示我可以开始加载操作了。当加载完成后，我们将结果存放到结果集合中：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125130314.png]]

上图表示**在第一个时钟内，我使用Integer部件对F6进行了操作**。

接下来来到第二个时刻。由于LD操作全程都要由Integer部件来执行，而又只有一个Integer部件，所以我们不能在第二个时刻开始第二条指令![[Lecture Notes/Computer Structure/resources/Pasted image 20221125131500.png|150]]的Issue。其实，这就是[[#1.3.1 Structure|结构相关]]的原因。那么我们就正常开始第一条指令的Read Oper操作了：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125131705.png]]

此时，由于依然是Integer部件在操作，所以功能部件和结果都是一样的( #idea 这里读的就有可能是`34+`，这应该是个立即数，所以可以直接读，不经过寄存器)：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125131753.png]]

之后是第三个时刻，几乎都是一样，只有唯一一点区别：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125131849.png]]

为什么R2的就绪状态变为了No？因为这里是真正执行的过程。之前其实都是在做准备而已，并没有真正发生读写。而此时才是真正从R2中读数据写道了F6中。因此一个正在被读的寄存器一定是不能被使用的，也就是非就绪状态。

另一个问题是，第三个时刻能不能发射第三条指令![[Lecture Notes/Computer Structure/resources/Pasted image 20221125132352.png|150]]，也就是执行它的Issue？答案是不行的。虽然没有数据相关，也没有结构相关，但是由于**记分牌是一种顺序发射的策略**，所以只有前一条指令发射了(至少执行了Issue)，下一条指令才能发射。

接下来到了第四个时刻。此时已经开始写回结果，Integer部件被彻底释放(因为写回是CPU干的事)。所以此时的状态就变成了这样：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125132639.png]]

然后是第五个时刻，此时开始执行第二条LD指令的Issue。那么除了寄存器会改变，其他和第一个时刻是一样的：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125132745.png]]

真正起作用的是第六个时刻。此时开始执行第二条指令的Read Oper。但是由于第二条指令已经发射了，那么此时完全可以开始发射第三条(**只是开始**)：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125133148.png]]

那么此时，Integer部件和Mult1部件就可以同时工作起来。Mult1部件要把数据写到F0中；从F2和F4处取操作数；下面看的就是F2和F4是否都就绪了。我们一眼丁真，F2此时正在被Integer部件操作，而F4此时是空闲的。所以F2显然没有就绪，而F4就绪了()：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125133624.png]]

> 上图中的Qj和Qk表示产生Fj和Fk的是谁。如果没写表示开始之前就有。比如这里的Integer就表示产生F2的罪魁祸首就是Integer。
> 
> **总结一下：Mult1发现Qj是Integer，并且Integer是Busy，因此确定了F2是No**。

能继续Read Oper吗？不行啊！**因为F2都正在被使用呢，而操作数就从F2来**。显然是不能执行的。所以到这里就被卡住了，只有等第二条指令写回之后才能继续。

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125134221.png]]

接下来是第七个时刻。此时第二条指令开始Exec了，第三体条指令被卡住了。但是我可以发射第四条指令了。因为第三条虽然不能执行，但是已经发射过了：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125134325.png]]

接下来就是确定这个SUBD操作谁来干了。显然是Add部件干的(Add既能做加法又能做减法)。结果写回到F8中；从F6和F2取操作数。但是由于F2仍然没有就绪，所以还是会被卡住：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125134717.png]]

> Add发现Qk是Integer，Integer是Busy，所以F2是No。

此时的结果：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125134911.png]]

然后是第八个时刻。由于3，4条指令都被卡住了，所以这个时刻做的就是第5条指令的Issue和第二条指令的Write。首先来看第5条指令的发射：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125135231.png]]

这个操作交给Divide部件来做。将结果写回到F10；操作苏从F0和F6来。而F0是Mult1产生的，Mult1此时正处于Busy，所以F0没有就绪，F6就绪：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125135410.png]]

自然这条指令也会被卡住。看一下结果吧：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125135448.png]]

之后是第八个时刻的第2条指令的写回：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125135521.png]]

这个时候，终于可以把Integer给解放了！**并且正是因为此，表中所有由于Integer而产生的不就绪也都可以改为就绪**：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125135636.png]]

而这个时候结果集合也可以把Integer给去掉了：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125135713.png]]

然后是第九个时刻。这时第三条和第四条指令终于可以开始Read Oper了。那么我可不可以发射最后一条指令了呢？发射这条指令，其实就是对它做Issue。那么我们就要知道Issue到底是什么。通过前面的介绍已经不难看出，**Issue其实就是填Functional unit status这张表**(这其实就是译码的过程)。因此我们要看最后一条指令能不能填表？不能！为什么？因为表里现在就有东西啊：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125162249.png]]

所以我们不能发射最后一条指令。因此最终这个时钟内的操作就只有两个Read Oper：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125162351.png]]

这里还有个问题：**记分牌是顺序发射，乱序执行，乱序完成**。那么我理应给所有已经发射了的指令都往后执行一步。也就是，这个DIVD指令也应该进行Read Oper了。但是，由于DIVD指令依靠F0(前面在表格里已经展示过了)，所以这条指令在MULTD指令写回之前还不能取操作数。

执行完成后，其他的结果都不会改变，但是需要注意一件事情：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125163342.png]]

这里的10和2，表示在接下来的Execution阶段分别需要10个时钟和2个时钟。

接下来是第10个周期，这时做的就是第三、第四条指令的Execution。由于需要时间很长，所以没有执行完，不能写在Instruction status里；Functional unit中Time会发生改变，递减1，并且两个源地址寄存器的就绪状态也都变成了No：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125163617.png]]

第11个周期结束时，SUBD指令执行完毕，而MULTD指令还需要8个时钟。此时可以在SUBD的Execution里写上11了：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125163744.png]]

第12个周期，SUBD指令开始做写回。因此清楚Add这一行，并且结果集中的Add也被删掉。

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125164248.png]]

MULTD指令没有执行完；DIVD指令没有F0还是没法Read Oper；另外ADDD指令还是不能写到表格里。因为这个时候虽然Add这行是空的，但是以防写回的时候出错，还是暂时不动，等下个时钟。

接下来是13周期。MULTD没执行完，DIVD还没等到F0；因此只是发射一下ADDD：

![[Lecture Notes/Computer Structure/resources/Pasted image 20221125165012.png]]

## 1.6 HyperThreading

超线程，现在最流行的东西，又叫做**并行多线程**。就是现在说的“8核16线程”之类的。

# 2. IO

## 2.1 Bus

### 2.1 Bus Bandwidth

总线带宽的意思，和[[Lecture Notes/Networking/dn#^ca317a|计算机网络中对于带宽的定义]]中的一种类似，也就是Bit rate。但是，不同于bps这个单位，我们更常采用byte per second这个单位。因为这并不是远程网络，数字通常非常大。

$$
总线带宽 = 数据线宽度 \times 总线工作频率
$$

数据线宽度就是CPU的数据线有多少个bit，比如32位的CPU数据线宽度就是32bit；而总线工作频率一般就是只干活的频率。[[Lecture Notes/Networking/dn#^84ab18|频率就是一秒扑腾的次数]]，而每次我们的扑腾能传n bit。所以将他们乘起来就是我们常见的bps。

#homework Bus Bandwidth

![[Lecture Notes/Computer Structure/resources/Pasted image 20230305121752.png]]

**注意"一个总线周期由5个时钟周期完成这句话"，它的意思是CPU每计算5次才能传一次数据**。因此真正总线传数据的频率是$\dfrac{66MHz}{5}$。因此用它乘上8byte才是最后的答案。

![[Lecture Notes/Computer Structure/resources/Pasted image 20230305123351.png|400]]

#example Bus Bandwidth

*PCI总线的时钟频率为33MHZ/66MHZ，当该总线进行32/64位数据传送时，总线带宽是多少？*

按照公式，我们的解法就是看一秒扑腾多少次？是33M或者66M次。而每次扑腾可以传32或者64个bit。因此我们将这些数字分别乘起来，就是最终的答案。但是，由于这个数字很大，而且**PPT中的定义就是byte per second，所以我们还要除上一个8**：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230302171336.png|400]]

#homework PCI Bus

![[Lecture Notes/Computer Structure/resources/Pasted image 20230305123632.png]]

1992 年由 Intel 公司推出的 PCI（外部设备互连）总线标准，该总线具有很好的 性能和特点，一经推出立即就得到广泛地应用。 PCI 总线是一种不依赖任何具体 CPU 的局部总线，也就是说它独立于 CPU。详 细描述 PCI 够写一本书，这里只说明 PCI 的一些特点。

1. **高性能**：PCI 的总线时钟频率为 33MHz/66MHz。而且在进行 64 位数据传送时，其数据传送速率可达到 66M×8B＝528MB/s。这样高的传输速率是此前其他内总线所无法达到的。在 PCI 的插槽上，可以插上 32 位的电路板（卡）也可插上 64 位的电路板（卡），实现两者相兼容。
2. **总线设备工作与 CPU 相对独立**：在 CPU 对 PCI 总线上的某设备进行读写时，要读写的数据先传送到缓冲器中，通过 PCI 总线控制器进行缓冲，再由 CPU 处理。当写数据时，CPU 只将数据传送到缓冲器中,由 PCI 总线控制器将数据再写入规定的设备。在此过程中 CPU 完全可以去执行其他操作。可见，PCI 的工作与 CPU 是不同步的，CPU 速度可能很快而PCI 相对要慢一些，它们是相对独立的。这一特点就使得 PCI 可以支持各种不同型号的 CPU，具有更长的生命周期。
3. **即插即用**：即插即用就是在 PCI 总线上的电路板（卡），插在 PCI 总线上立即就可以工作。PCI 总线的这一特点为用户带来极大的方便。在此前的总线上，例如 ISA 上，可以插上不同厂家生产的电路板（卡）。但不同厂家的电路板（卡）有可能发生地址竞争而无法正常工作。解决的办法就是利用的电路板（卡）上的跳线开关通过跳线改变地址而克服地址竞争。在 PCI 总线上就不存在这样的问题，此总线上的接口地址是由 PCI 控制器自动配置，不可能发生竞争。所以，电路板（卡）插上就可用。
4. 支持多主控设备：接在 PCI 总线上的设备均可以提出总线请求，通过 PCI 管理器中的仲裁机构允许该设备成为主控设备，由它来控制 PCI 总线，实现主控设备与从属设备间点对点的数据传输。并且，PCI 总线上最多可以支持 10 个设备。
5. 错误检测及报告：PCI 总线能够对所传送地址及数据信号进行奇偶校验检测，并通过某些信号线来报告错误的发生。
6. 两种电压坏境：PCI 总线可以在 5V 的电压环境下工作，也可以在 3.3V 的电压环境下工作。
7. 两种兼容卡槽：PCI 总线定义了两种 PCI 扩展卡及连接器（即主板上的 PCI 插槽）：即长卡和短卡。短卡为 32 位总线而设计，插槽分为 A、B 两边，每边定义 62 个引脚信号。故短卡共有 124 个引脚。长卡为 64 位总线而设计，插槽分为 A、B 两边，每边定义 94 个引脚信号。很显然，长卡的 A、B 两边，每边的前 62 个引脚信号与短卡信号是完全一样的，以便长卡完全兼容短卡。

### 2.1.2 Data Transformation

这部分内容和计网的4.3.1，4.3.2完全一样，而且补充的特点也是一样的。

### 2.1.3 Bus Arbitration

![[Lecture Notes/Computer Structure/resources/Pasted image 20230302173418.png]]

## 2.2 Storage

![[Lecture Notes/Computer Structure/resources/Pasted image 20230302175134.png]]

![[Lecture Notes/Computer Structure/resources/Pasted image 20230302175142.png]]

#poe 磁盘存储

* Return-to-Zero(RZ):

![[Lecture Notes/Computer Structure/resources/Pasted image 20230302175319.png]]

> * **使用4个bit编码一个信息bit**。中间凸出来表示1，凹进去表示0。这种方法，我实际的容量仅仅是我提供的容量的1/4。
> * 由于不管是0还是1，你只要经过了当前bit，都得翻转。所以最小翻转**间隔**和最大翻转**间隔**都是1。因此自同步能力为1/1 = 1。

---

* Non-Return-to-Zero(NRZ)

![[Lecture Notes/Computer Structure/resources/Pasted image 20230305130244.png]]

![[Lecture Notes/Computer Structure/resources/Pasted image 20230302175535.png]]

> * 高就是1，低就是0。这种做法每个bit都很有效地表示了信息。
> * 最好的情况是01交替，此时最小翻转间隔就是1；而如果存了连续的0或者1，那永远也不会翻转。因此最大翻转间隔是$\infty$。自同步能力为$1/\infty = 0$。

---

* Non-Return-to-Zero1(NRZ1)

![[Lecture Notes/Computer Structure/resources/Pasted image 20230305130247.png]]

![[Lecture Notes/Computer Structure/resources/Pasted image 20230302175730.png]]

> * 变就是1，不变就是0。这样，至少需要2个bit才能表示一个信息bit。存储密度是1/2。
> * 和NRZ一样的自同步能力，只是情况不同。

---

* Frequency-Modulation(FM)

![[Lecture Notes/Computer Structure/resources/Pasted image 20230305130253.png]]

![[Lecture Notes/Computer Structure/resources/Pasted image 20230302175953.png]]

> * 变得快的是1，变得慢的是0。
> * 最小只需要经过1个bit就翻转；而即使是长连0，也是经过2个bit就翻。因此自同步能力为1/2。

---

* Modified-Frequency-Modulation(MFM)

![[Lecture Notes/Computer Structure/resources/Pasted image 20230305130256.png]]

![[Lecture Notes/Computer Structure/resources/Pasted image 20230302180116.png]]

> * 和FM的区别就是，**0和1是连着的！！！**
> * #keypoint  **当存1111时，最小翻转间隔2；存101时，最大翻转间隔4**。因此自同步能力1/2。

---

* Phase-Modulation(PM)

![[Lecture Notes/Computer Structure/resources/Pasted image 20230305130259.png]]

![[Lecture Notes/Computer Structure/resources/Pasted image 20230302180328.png]]

> * 往上走就是1；往下走就是0。
> * 自同步：1/2。

会考自同步能力，就是最小反转间隔 / 最大反转间隔：

#keypoint **翻转间隔就是两个竖线中间有多少bit**。

![[Lecture Notes/Computer Structure/resources/Pasted image 20230110144343.png]]

* 道密度：半径方向单位长度有多少个磁道。也就是**总磁道数/半径**；
* 位密度：圆周方向上单位长度能记录多少bit/byte。可以用**一道的总容量(bit or byte)/周长**得到。
* 数据传输率：$每一道上的扇区个数 \times 每个扇区有多少个字节 \times 磁盘的转速$。

#poe 磁盘容量计算

![[Lecture Notes/Computer Structure/resources/Pasted image 20230110144620.png]]

#keypoint ==**送命题：磁盘内外圈容量一样吗？答案是一样！！！！！！**==

![[Lecture Notes/Computer Structure/resources/Pasted image 20230110155432.png]]

在磁盘转起来之后，我们要保证所有道的传输速率一样，但是外圈的线速度大，所以我们只能降低外圈的容量密度。~~所以这道题中，总容量就是$50 \times 2\pi \times 0.9$。你可能会疑惑：难道不是每一道的容量吗？我都说了，既然每一道的容量都是一样的，这里的50kb/英寸就是所有道的单位容量，你可以理解为一个**单位扇形**的容量~~。

上面的表述有大问题。是每一道(圈)的容量是$50 \times 2\pi \times 0.9$。而传输速率就是值在一道上转的过程中读取的速率。

## 2.3 Interface

$$
IO系统 = 外部设备 + 设备控制器(接口)
$$

![[Lecture Notes/Computer Structure/resources/Pasted image 20230303165956.png|300]]

#poe  *What can IO Interface do?*

* **传递数据**
* **设备选择 - 选地址**
* **设备控制 - 发命令**
* **获取设备状态 - 读状态字**
* 信号形式转换
* 速度匹配
* 数据缓存
* 错误检测
* 负载匹配
* 支持中断
* ... ...

> 对于某些复杂的外设，IO接口还应是具有**智能**的控制器。

---

[[Lecture Notes/Operating System/os#^530c0b|IO设备编址]]

![[Lecture Notes/Computer Structure/resources/Pasted image 20230303170243.png|340]]  ![[Lecture Notes/Computer Structure/resources/Pasted image 20230303170320.png|340]]

---

*How does CPU access IO device?*

> 这部分在操作系统的[[Lecture Notes/Operating System/os#8. I/O|I/O]]那张也提及过，可以一起看。

* 程序直接控制IO
* Interrupt
* DMA
* 通道

#example IO Device Access

![[Lecture Notes/Computer Structure/resources/Pasted image 20230303171004.png]]

首先是鼠标。我们要看的就是，一秒钟**应该**有多少时间是给鼠标的。鼠标每秒钟要查询30次，而每次操作需要100个周期。并且每个周期持续时间是$T = \dfrac{1}{50M}s$。因此，鼠标1秒内的时间是：

$$
30 \times 100 \times \frac{1}{50M}
$$

所以花费的比率就是上面的时间除以1秒就可以了。

接下来是硬盘。硬盘每秒要传2MB的数据，也就是$2 \times 1024 \times 1024 \times 8$个bit。而每次传输只能传32个bit。因此我们能得到每秒钟要传的次数就是

$$
\frac{2 \times 1024 \times 1024 \times 8}{32}
$$

和鼠标一样，用次数乘以每次需要的周期(100)和周期的持续时间(T)，除以1s就是最后的答案。根据结果我们能分析得到，查询鼠标不消耗多少时间，但是查询磁盘需要的比率甚至超过了100%。**这代表着即使把CPU所有的性能榨干用来满足磁盘，也是做不到的**！

---

在使用中断来access IO设备的方式中，每一条指令执行完，CPU都会主动tracking当前是否有中断。如果有，就会进入中断处理的模式。而中断又分为单重中断和多重中断。所谓的多重，就是在中断处理程序执行的过程中又产生了中断，从而切换到更下一级的中断：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304120151.png|300]]

我们首先来看单重中断。每当一条指令执行完毕后，都要主动查看一下当前是否有中断。如果有的话，就要进入中断响应的过程。然而，为了能接着执行我当前的任务，我还要保存一下现场的状态和数据。具体的实现方式当然就是用栈，因为栈的LIFO特性正好能保证**最下面一级的现场数据最先被提取出来**。然而，我们需要注意的是，就像游戏的存档过程一样，如果存档这个模块本身出现了bug，那么存下的档很有可能就是一个坏档。因此，**入栈的过程也需要被保护**。下一个问题就是，如何保护呢？当然就是拒绝接收新的中断啦！一但我发现了中断，并且知道是谁发的了，我就决定去做这个中断的事。首先第一步就是不再接受任何其他的中断。如果我此时没有关掉中断，在保存现场，也就是入栈的指令执行完毕后，CPU还是会查看有没有中断，这样显然是对保护现场的不负责。因此，关闭中断的过程是很有必要的。

下一个问题是，什么时候开中断？这和单重中断和多重中断有关。在单重中断中，我们**不允许中断处理程序运行的时候再有其他的中断插进来**。因此要在~~ISR执行完毕后~~恢复现场后(读档的过程也不能被插进来！)才能打开中断；而在多重中断中，允许这样的操作，因此在保护现场(入栈)的指令执行完毕后就可以打开中断了。

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304120945.png|400]]

#poe 中断运行过程

1. 发送INTA，**识别中断源(知道中断是谁发的)**
2. 清中断，**关中断**
3. 保存断点，当前pc，标志寄存器
4. 得到中断向量，查询出ISR(Interrupt Service Routine)
5. 保存现场，通用寄存器(保存到主存，压栈)
6. 开中断
7. 执行中断服务
8. 关中断
9. 恢复现场
10. IRET(中断返回)
11. 开中断
12. 中断返回

> ~~其中的6，7，8着三个过程就是多重中断的要素~~。而第7条本身就可以是一个1-12的过程。
>
> 上面的叙述有问题，在多重中断中，保存好现场后就可以开中断，来接受其他的中断处理程序。而第八条关中断，是为了保护这个恢复现场的过程不被其它中断打扰。这和游戏的读档过程是一样的道理。

#example Interrupt

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304121452.png]]

频率就是1s扑腾的次数。因此中断最大频率就是1秒钟能执行的中断次数的最大值。我们假设这个值是f，能得到每个中断执行的时间就是1/f。因此有

$$
\begin{array}{l}
& \dfrac{1}{f} = 50ns + 150ns = 200ns \\
\Rightarrow & f = 5 \times 10^6(次/s)
\end{array}
$$

中断的额外开销指的是**除了执行中断处理程序以外的时间**。因此这部分时间就是50ns+60ns=110ns。比例就是110/200 = 55%。

对于这个字节设备，它每次只能传一个byte。而我们要求1s内要传10MB的数据。这意味这我们要在1s内执行10M次传输操作。将1s分成10M份，约等于(1024和1000的区别)$10^{-7}s = 100ns$。也就是整个中断处理程序要在100ns内执行完毕。而题中的配置显然不过关。

#poe 中断向量表

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304123219.png|300]]

在内存中开辟1KB的空间用作中断向量表。**每4个byte为一组**。这样做的原因是，我要是想定位到一个中断处理程序，需要的就是中断向量(就是ISR的起始地址)。中断向量的定义就是`CS:IP`(CS段开始，偏移IP个地址)。而[[Lecture Notes/Computer Structure/img/wl.png|CS和IP每个都占2byte]]，因此每4个byte才能表示1个中断处理程序的入口。既然如此，如果我要找到第n个中断处理程序的入口，只需要将n乘以4，就能拿到它那个组的起点，往后数4个byte，就是CS和IP了！**注意，先是IP后是CS**！

如果给出`INT 3`，会怎么样呢？将3\*4=12，因此我们找到00CH这里的后两个数据，也就是IP和CS。**`CS:IP`就是中断处理程序的起始地址**。给个例子，如果中断向量是4AH的话，将4AH\*4得到的是128H。那么IP就是128H和129H，而CS就是12AH和12BH。

#TODO 8259

#poe DMA的工作方式

![[Lecture Notes/Computer Structure/resources/Pasted image 20230110154122.png]]

> 这7步实际上是分为三部分：取得总线控制权(1-4)，传输数据(5)，释放控制权(6-7)。

那么DMA和CPU之间是如何分配总线的呢？有三种方式：

* 停止CPU方式：只要DMA要，CPU就给，这样有点欺负CPU。
* 交替分时工作：

  ![[Lecture Notes/Computer Structure/resources/Pasted image 20230110154634.png]]

* 周期挪用方式：上一个方法中，虽然是一半一半的时间，但是CPU很多时间内并不需要读写内存(传输数据)。因此CPU只要没使用总线，就应该把总线让给DMA。

  ![[Lecture Notes/Computer Structure/resources/Pasted image 20230110154845.png]]

![[Lecture Notes/Computer Structure/resources/Pasted image 20230110155929.png]]

[[Lecture Notes/Networking/dn#^84ab18|500MHz表示每秒钟能扑腾500M下]]，也就是每秒钟能走完500M个时钟。但是每条指令都能消耗2个时钟。因此每秒能执行的指令就是500M / 2 = 250M个。然后每秒传0.5MB，而每次传送的大小是32bit，也就是4byte。因此每秒传送的次数就是$\dfrac{0.5 \times 10^6}{4}$。题中说的"对应的中断服务程序"指的就是**传送这32bit数据**的指令。因此20条指令用来传送数据。而"其他的开销相当于"指的就是把那些不是传送数据的乱七八糟的指令也当成数据。因此我们一共需要"假装"执行25条传送指令。那么显然消耗的时钟就是25\*2=50个。 这段时间也是CPU用于IO的时间；~~那么整个CPU时间是什么？其实就是对外设来说，它接受到一共32bit数据的时间。这段时间CPU一直在做事，其中一部分是IO。这段时间结束之后，一共传了一次，也就是32bit的数据。因此我们将每秒传送的次数取倒数，就是每次传送需要的时间~~。即CPU时间就是$\dfrac{4}{0.5 \times 10^6}$。那么最终的占比就是$(50 \times \dfrac{1}{500M}) \div (\dfrac{4}{0.5 \times 10^6})$。除了这种方式，还有另一种思考：每秒能传那么多次，我就看500M个时钟，也就是1s内能做多少事。那么显然1s内就能够执行$\dfrac{0.5 \times 10^6}{4}$轮那么多(25条)指令。因此用$\dfrac{0.5 \times 10^6}{4} \times 25 \times 2$，就得到了1s内执行的指令所消耗的时钟。用这个数再除以500M，也能得到相同的结果。

> PPT中写的这里是错误的，和第二问一样，都只看除以500M的方法。这里要强调一个概念。使用$\dfrac{0.5MB}{4B}$得到的答案，是每秒传输的次数。然而，分子这个0.5MB是一种**要求**。这意味着它的倒数是**我要求你每次传输指令的执行时间是这些秒**。并不是CPU时间。CPU时间只和CPU的主频有关，也就是这500MHZ。

第二问我们也用两种思路。DMA每次能传$\frac{5MB}{5000B} = 1000$个数据块。也就是DMA要工作1000次。而DMA每次工作要花费250个周期。因此DMA的IO时间就是250 \* 1000个周期。用这个数再除以500M就可以了；~~另外我们也可以精确到一次。DMA工作一次的时间就是传5000B的时间。因此用5000 / 5M能得到传5000B需要千分之一秒。这个数字也是CPU总时间。而IO时间就是执行250条指令的时间，因此用$(250 \times \frac{1}{500M}) \div (\frac{1}{1000})$也能得到正确结果~~。

> 使用DMA，就看DMA每次传输的总开销就可以了，不用再看CPU每条指令要多少CLOCK。

## 2.4 8253

8253内部封装了3个计数器：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304160007.png|400]]

每个计数器都能设置6种工作模式。下面来看一下这六种都是啥。其实，这6种模式两两一组可以被分为3组，每一组都有自己的功能。首先看第一组，它的功能是**倒计时**。

### 2.4.1 Timer(0 & 1)

我们一点一点来分析。首先是这个：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304160323.png|300]]

当我们输入4时，就是在说：你从4开始倒计时！而在方式0中，如果GATE信号一直为高电平，那么在N=4这个信号的下一个下降沿，就会从4开始计时。每经过一个下降沿就减掉1，当变成0的那个下降沿时，输出信号变回高电平。

但是如果有了GATE信号的干预，就不一样了。我们发现，当GATE信号一旦变为低电平，在下一个下降沿就会一直保持**暂停状态**。知道GATE信号回到高电平的下一个下降沿才继续倒计时：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304160622.png|300]]

除了GATE信号的影响，输入本身有什么影响呢？如果我在倒计时还没结束的时候又输入了一下：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304160735.png|300]]

此时刚刚数到2，之后N=3这个信号传进来了。那么在下一个下降沿就会**立刻**开始这个新的倒计时，放弃原来的。

> ![[Lecture Notes/Computer Structure/resources/Pasted image 20230304163234.png]]

---

然后是方式1。它和方式0的输出一模一样，唯一的区别是开始的条件。方式0是只要输入信号来了，在下一个下降沿就立刻开始；而方式1是不管你输入来没来，只有GATE信号动了才让你开始：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304162336.png|300]]

因此，方式0和方式1的GATE信号的区别就是，**前者用来暂停，后者用来开始**。而如果我多次给GATE信号，会发生什么呢？我们猜也能猜出来，就是重新开始计时。不过要注意的是，是**立刻重新开始最近一次输入的计时**：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304162519.png|300]] ![[Lecture Notes/Computer Structure/resources/Pasted image 20230304162530.png|300]]

左图中只有一次输入N=4，因此第二次GATE信号重新从4开始倒计时；而右图中在N=3这个计时开始后，又输入了个2，此时依然还在进行N=3的倒计时；而GATE信号又动了一次，这时才开始N=2的计时。

> 我们还要注意一点，方式0和方式1在计时完成后都不会自动重复这个计时的过程，只有额外又有输入的时候才开始工作。这与接下来的频率产生器是不同的。

### 2.4.2 Frequence Generator(2 & 3)

方式2和方式0的原理很像，只是干的活儿不一样。当输入N=3的时候，还是从3开始数。只不过这次不是倒计时了，而是产生一个高-低的波形。高有2个，低有1个。总之，如果输入的是N，那么高有N-1个，低有1个。

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304163512.png|300]]

> 注意这里和方式0和1的区别，频率并不像倒计时，**产生完一次之后是会自动重复的**！

GATE信号在方式2的作用和方式0也一样，都是暂停：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304163724.png|300]]

当有多个输入时，和方式0又有区别了。方式0会立刻终止当前的计数而开始新的；而方式2并不会结束正在生成的波形，只有当波形生成完毕后，下一个下降沿才会开始生成新的波形：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304163834.png|300]]

> ![[Lecture Notes/Computer Structure/resources/Pasted image 20230304165226.png]]

---

然后是方式3，它和方式2的区别是波形不同。方式2是N-1高1低；而方式3是对半开，也就是所谓的**方波**。当输入是N时，先是高的波形有$\lceil \dfrac{N}{2} \rceil$，然后是低的波形有$\lfloor \dfrac{N}{2} \rfloor$。也就是说，如果是偶数个的话，那么就是完全对半开；如果是奇数个的话，高的比低的会多一个：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304164159.png|300]] ![[Lecture Notes/Computer Structure/resources/Pasted image 20230304164212.png|300]]

GATE信号在方式3的作用和方式2不一样，并且方式2并不会改变波形，而方式3会。

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304164650.png|300]]

假设没有这个GATE信号的话，应该是红色的波形，并且也是正常计数。但是在数到2时，**这个波刚走下来**之后非常短的时间内，GATE信号变成了低电平。此时数字停在了2，直到GATE信号恢复为高电平后的下一个下降沿**重新从4开始**数。而且，波形在GATE信号变第后的下一个下降沿被强行拉高，直到GATE信号重新变高之后的下一个下降沿才继续从这个高开始产生波形。

> 简单来说，方式3的GATE信号用来重置，并且重置的过程中输出波形被强行拉高；方式2的GATE信号单纯用来暂停，并且也不会改变波形。

方式3如果有多个输入，也和方式0一样会立刻改变：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304165347.png]]

### 2.4.3 Timer(4 & 5)

方式4和方式5依然是计数器，和01的区别就在输出的波形。01是数到0时回到高电平；而45是每一次数到0之后下去一下。首先是4，它和0一样，在输入后的下一个下降沿开始数数：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304165813.png|300]]

方式4的GATE信号完全用来开始。只有GATE为高时才能运行计时，否则不会运行。这和前面GATE动一下就开始是不一样的。我们可以认为，前面的GATE是按钮，而这个是开关。

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304170247.png|300]]

> #question/class 我感觉这图错了，是GATE变高后的下一个下降沿才开始从4数。

如果有多个输入，和方式0一样，从下一个下降沿开始立刻进行新的计时：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304170432.png|300]]

---

方式5和方式1很像，GATE信号动一下才能开始：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304170712.png|300]]

当有多个GATE信号时，下个下降沿会立刻开始最近的一次输入：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304170755.png|300]] ![[Lecture Notes/Computer Structure/resources/Pasted image 20230304170803.png|300]]

> #keypoint **注意：基本上方式4和方式5的所有图都是错的**！！！原因是，这是计时的功能而不是产生频率的功能。所以并不会重复进行。因此方式4中在结束后是不会继续进行的，也就没有后面的数字。而上面两张图中，左边是错误的，右边是正确的，具体的原因自己分析。

### 2.4.4 Initialization

回到一开始的那张图：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304160007.png|400]]

我要是想让8253开始工作，就得将我要控制谁，从几开始计数这些东西写到计数器里。那怎么写呢？就是通过左下这个控制寄存器。我们传进去8个bit，这8个bit就是控制这三个计数器里的某一个的工作方式(上面那6种)的。

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304172525.png]]

> 假设我们想让计数器0工作在方式3，那么前两个bit就是00，而第5\~7个bit就是011或者111。

接下来说一些不一样的。首先是最后一个bit，这表示我们采用BCD编码还是二进制数。如果我们想要表示35这个十进制数，使用BCD码是`0011 0101`；而使用二进制数就是`0010 0011`。下面我们通过几道题来看。

### 2.4.5 Exercise

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304173001.png|500]]

注意，我们操控的是控制寄存器，因此重点对象是`3F3H`。其它地址要么是用作写1234这种初始值，要么就是用来迷惑你的！现在我们选用BCD编码，那这个控制字就应该是：

```
00??0111B
```

中间的问号就是RW1和RW2。这里我们让它们是11，因为我们需要写寄存器的计数值。这里注意先写低8位，后写高8位。因此我们需要先把34写进去，再把12写进去。下面开始逐步写完整的汇编代码。首先将控制字写到寄存器中：

```asm
mov al, 00110111B
```

然后将DX写成控制寄存器的地址，并将控制字送进去。这个操作我们经常用到，比如在[[Homework/Assembly/3. easy_io|计组实验中的一次作业]]。

```asm
mov dx, 3F3H
out dx, al
```

再接下来就是告诉计数器0从1234开始数了。我们先写34：

```asm
mov dx, 3F0H ;将寄存器0的地址写入dx
mov al, 34H
out dx, al
```

再写12：

```asm
mov al, 12H
out dx, al
```

> #keypoint 重中之重：BCD码我们好像没提啊！仔细思考，1234这个数字使用BCD码编写，正好需要2个byte，也就是16bit。因此先低8位后高8位正好分别就是34和12这两个数字的BCD码。而**如果16进制数中只有0-9，那么和BCD码是没有任何区别的**！这才是我们为什么直接传16进制数就能当BCD码用的原因。

---

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304175721.png]]

唯一的区别是，前者是初始化的操作，现在是已经开始运行了，我要读它。因此，我们应该更改控制字。只需要更改RW1和RW2就好了，改成00，即`00000111B`。读的时候，我们每次都只能读出一个byte，因此需要读两次才能把所有都读出来。而第一次读取是读的低8位，第二次读取读高8位。因此这一部分的代码如下：

```asm
mov al, 00000111B
mov dx, 3F3H
out dx, al

mov dx, 3F0H
in al, dx
in ah, dx
```

题中要的是正向的数值，而我们要的是倒计时，因此最后还要用1235减去读到的结果(从1开始数，1235-1234正好就是1)：

```asm
mov cx, 1234 + 1
sub cx, ax
```

PPT中用了一种非常脱裤子放屁的方法，它读计数器的时候，先把低8位读到al，然后把al放到ah，又把高8位读到al，最后将al和ah交换：

```asm
mov al, 00000111B
mov dx, 3F3H
out dx, al

mov dx, 3F0H
in al, dx
mov ah, al
in al, dx
xchg ah, al

mov cx, 1234 + 1
sub cx, ax
```

---

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304181152.png]]

我们先只挑会的看。计数器0要在100微秒之后产生中断，就是一个简单的数数，因此应该用方式0。问题是，从几开始数呢？这就和CLK的频率有关了。2MHz代表每个周期是$\dfrac{1}{2 \times 10^6}s$，也就是$0.5\mu s$。而我们需要记$100\mu s$，正好就是$\dfrac{100}{0.5} = 200$个数。因此要从200开始数；

计数器1要产生方波，那肯定是方式3了。而每个方波要$10\mu s$，也就是20下；

计数器2要每隔1ms产生负脉冲，而不是经过多长时间只产生一个负脉冲。因此要用方式2而不是方式5。注意是毫秒不是微秒，因此要从2000开始数。

有了上面的分析，我们很轻松就能编写出它们三个的控制字：

计数器0：

```
00110001
```

计数器1：

```
01110111
```

计数器2：

```
10110101
```

然后是这学期没有涉及到的部分：咋计算地址啊？看到那个74138了没，就用它！我们需要将$A_{15}$ \~ $A_{0}$的值全部都确定下来，才能确定这个8253的地址范围。

首先是A15-A8以及A2。因为它们都一起经过一个与非门，所以这些值必须全都是1才能保证$\overline{G_{2A}}$为0；然后是A7和A6，它们或在一起需要是0，因此它俩都是0；再然后是A5到A3，看到那个连出去的$\overline{Y_0}$了吗？只有它为0的时候，才会选中当前的8253。那什么时候它为0呢？就是ABC这三位表示的二进制啊！因此A5-A3全都是0。最后只有A1和A0不确定了，它们的功能如下：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304183956.png]]

因此，我们将这一长串二进制写出来，再转化成16进制，能得到最终的地址范围：

```
FF04: 计数器0
FF05：计数器1
FF06：计数器2
FF07：控制寄存器
```

有了这个，代码就好写了。下面给出例子，但是例子的控制字方式不同，比较专业：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304185134.png]]

## 2.5 8255

在[[Homework/Assembly/4. coding_8255|计组实验的作业四]]中，我们也使用过8255。8255是一个非常绕，非常反人类的芯片，它的结构：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304200513.png|400]]

* A组包括A口和C口的高4位；
* B组包括B口和C口的低4位。

8255用作外设和系统总线之间的接口，用来对接外设和CPU之间的输入和输出：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304200635.png|400]]

![[Lecture Notes/Computer Structure/resources/Pasted image 20230308205043.png|400]]

我们只考方式0，因此我们只介绍ABC这三个口工作在方式0的配置。配置当然也是输入控制字。而8255的控制字也是8个bit，其中第一个bit是用来控制：

* 1 -> 配置ABC口的输入输出和方式
* 0 -> 单独修改C口中的某一位

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304215813.png]]

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304215824.png]]

我们通过一个例题来看：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304215903.png]]

首先，A口的箭头是从左向右，表示数据从8255输出到打印机。因此A口是输出口；同理能得到，C口的高4位是输出，C口的低4位是输入；B口不使用。因此，我们能写出第一个控制字。第一个bit是1，2-3bit是A口的模式，也就是00；第四个bit是A口的输入输出，是0；第5个bit是C口高4位的输入输出，是0；6bit是B口的工作方式(**因为B口只能工作在方式0或者方式1**)，第7个bit是B口的输入输出，由于没有提及，所以就默认0；最后第八个bit是C口低4位的输入输出，是输入所以是1。因此总的控制字：

```
10000001
```

然后是C口的单独配置。为什么要单独配置？因为$PC_6$连的是$\overline{STB}$，而在时序图中$\overline{STB}$信号是从高电平开始的。因此我们要将它置为1，按照上面的配置信息，可以很轻松写出：

```
00001101
```

接下来，和8253一样，还是要算出来总的地址，也就是确定$A_9$\~$A_0$的所有可能。能得到下面的信息：

$A_9 - A_2$ | $A_1,\ A_0$ 
-- | --
11 1000 00 | 00
11 1000 00 | 01
11 1000 00 | 10
11 1000 00 | 11

按照8255的控制信息，我们能得到如下结论：

![[Lecture Notes/Computer Structure/resources/Pasted image 20230304222256.png]]

因此初始化过程要先写0383H。下面是代码：

```asm
mov al, 10000001B
mov dx, 0383H
out dx, al
mov al, 00001101B
out dx, al
```

> * 第八章作业：3 7 10 18 22 24 27 33 34
> * 第六章作业：5 9 10