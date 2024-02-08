# 1. Architecture Style

![[Lecture Notes/Software Architecture/resources/Pasted image 20230502131848.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230502131911.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230502131957.png]]

* 组件
* 连接件
* 它们之间的关系

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608131601.png]]

## 1.1 Data Flow

![[Lecture Notes/Software Architecture/resources/Pasted image 20230502134157.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230502134215.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230502135014.png]]

> These three topologies above, which one is not suitable for data flow architecture?
> 
> The answer is: A. Cause there's no way to **ensure** the dependency tree of datas in each component.

### 1.1.1 Batch Sequential

![[Lecture Notes/Software Architecture/resources/Pasted image 20230502135541.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230502135651.png]]

**The next system's input must be the <u>whole result</u> of the previous system.**

![[Lecture Notes/Software Architecture/resources/Pasted image 20230502135943.png]]

### 1.1.2 Pipe and Filter

**If only the data comes, components can work**, which is the biggest difference than the Batch Sequential. Such feature enables **parallel** among components.

![[Lecture Notes/Software Architecture/resources/Pasted image 20230503112524.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230503112601.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230503112646.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230503112850.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230503112902.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230503113010.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230503113135.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230503113151.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230503113338.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230503113441.png]]

## 1.2 Call Return

### 1.2.1 Main Program and Subroutines

其实就是C语言的面向过程设计。**和面向对象不同，无法实现数据的封装和隐藏**。根据功能划分，将大问题分解成若干子问题。每个子问题由一个或多个子程序来完成，并让**主程序来调用这些子程序**。这种特性导致了主程序一定是知道子程序的执行过程的，也就没法实现封装。并且，如果系统或者问题过于复杂，如果只用这种方法的话，子程序和子子程序之间的交互就会过于复杂。

* Component: 主程序，子过程
* Connector: 主程序怎么调用子过程，显示的
* Topology: 根据功能划分出来的结构

优点：可以设计大型程序；缺点：过于复杂不行，可靠性有问题。这种风格通常会和其他风格一起来定义。

### 1.2.2 OOP

![[Lecture Notes/Software Architecture/resources/Pasted image 20230605132437.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230605133030.png]]

优点：

![[Lecture Notes/Software Architecture/resources/Pasted image 20230605133524.png]]

缺点：

![[Lecture Notes/Software Architecture/resources/Pasted image 20230605134023.png]]

### 1.2.3 Layered

![[Lecture Notes/Software Architecture/resources/Pasted image 20230605134217.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230605134229.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230605134242.png]]

## 1.3 Data-centered

### 1.3.1 Repository

![[Lecture Notes/Software Architecture/resources/Pasted image 20230605140936.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230605141042.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230605141406.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230605141426.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230605141731.png]]

### 1.3.2 Blackboard

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608120626.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608120637.png]]

控制器可以获得黑板中数据的状态，并根据这些状态来判断哪个或者哪些知识源是可以工作的。被激活的知识源此时就可以读取黑板中的数据状态进行处理，并将黑板中相应的数据进行更新。

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608122447.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608122520.png]]

## 1.4 Virtual Machine

### 1.4.1 Interpreter

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608124101.png]]

### 1.4.2 Rule-based

**业务逻辑频繁变化的时候，用这个**。思考spring boot导配置文件的时候，配置文件是会经常发生变化的，而我们spring程序的主题逻辑却几乎不怎么变。所以这个固定+可变的模式就可以用Rule-based来实现。然而，即使这样还不行，因为你一旦把他俩分开了，就要让这个**固定的逻辑能够理解那些可变的规则**。因此我们还需要在中间插一个规则引擎用来加载外部的规则（配置文件）。

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608125810.png]]

## 1.5 Independent Components

### 1.5.1 Event System

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608132410.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608132826.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608132841.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608132851.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608132902.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608132914.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608133623.png]]

无独立Dispatcher Module：观察者

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608133850.png]]

邮件，新闻系统：只要订阅了，就疯狂给你发广告，不管你看不看。

有独立Dispatcher Module

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608134119.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608184746.png]]

选择广播又有两种策略：点对点和发布-订阅。其中点对点是基于消息队列的，

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608185036.png]]

> 外卖平台

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608185112.png]]

> 也可以用于新闻广告系统，正好这个消息的寿命就是新闻的时效。

# 2. Structure Discription

## 2.1 Principle

建立描述文档的基本原则：

* 从读者的角度写；
* 避免不必要的重复；
* 避免歧义；
* 使用标准的组织结构；
* 记录理由；
* 保持文档时效性**但不是频繁更新**（有限的稳定性）；
* 审查文档是否符合要求。

## 2.2 Modeling

### 2.2.1 View

视图的类型：

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608191157.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608191205.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608191217.png]]

#poe 4+1视图：

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608191447.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608191749.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608191803.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608191813.png]]

1. 都有什么类？什么对象？它们之间什么关系？-> Logic View
2. 整个项目的进程是什么样的？前前后后都会发生什么事情？-> Process View
3. 这些类和组件都该放到什么包里？都被划分成了哪些部分？-> Development View
4. 这些软件开发好后放在哪些硬件里？怎么分配？-> Physical View
5. 最后用户是咋用的？产品有什么功能？-> Senario

UML虽然一般用来建类图，但是因为学习成本低，好理解，在2.0版本也加入了很多用来建体系结构的元素。

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608192051.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608192122.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608192134.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608192144.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608192152.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608192238.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608192245.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608192257.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608192305.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608192327.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608192334.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608192345.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608192356.png]]

# 3. QA and its Tactics

Non-functional Requirements: Quality Attributes.

![[Lecture Notes/Software Architecture/resources/Pasted image 20230608193033.png]]

常见质量属性：

* 可用性（Availability）
* 可修改性（Modifiability）
* 性能（Performance）
* 安全性（Security）
* 可测试性（Testability）
* 易用性（Usability）

Quality Attribute Senario(质量属性场景)：

* 刺激源（source）：谁造成的刺激
* 刺激（stimulus）：影响系统的情况
* 制品（artifact）：系统被影响的地方
* 环境（environment）：刺激发生时系统所处的状态
* 响应（response）：刺激所产生的结果
* 响应衡量指标（response measure）：如何评估响应

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609111220.png]]

## 3.1 Availability

是否发生了**故障**？故障的后果？

Senario

* 刺激源：故障的迹象
* 刺激：系统出错，系统崩溃等等
* 制品：计算、存储、网络传输
* 环境：正常或者亚健康
* 响应：记录日志，回传给厂家，通知管理员或其它系统，关闭系统，维护期间不可用
* 响应衡量指标：故障时间百分比、修复故障所需时间、平均无故障时间

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609112220.png]]

故障检测

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609112227.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609112236.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609112243.png]]

故障恢复

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609112326.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609112333.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609112339.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609112345.png]]

## 3.2 Modifiability

关注点：**修改**的成本，系统的哪些部分被修改，修改发生的时间，修改由谁来进行

Senario

* 刺激源（source）：谁进行的修改
* 刺激（stimulus）：进行的具体修改
* 制品（artifact）：修改的系统功能还是UI还是交互的其它系统
* 环境（environment）：在什么时间进行的修改？
* 响应（response）：操作人员要理解如何修改，进行修改操作、测试、部署
* 响应衡量指标（response measure）：时间、成本

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609113215.png]]

限制修改范围

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609113229.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609113237.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609113249.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609113257.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609113303.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609113308.png]]

延迟绑定时间

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609113313.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609113354.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230609113411.png]]

## 3.3 Performance

关注点：系统**响应事件的速度**，和事件的数量和到达模式有关。

Senario

* 刺激源（source）：可能来自系统内部或者外部
* 刺激（stimulus）：事件到来
* 制品（artifact）：系统所提供的服务
* 环境（environment）：系统可能处于不同的模式
* 响应（response）：系统处理到来的事件，可能会导致状态变化
* 响应衡量指标（response measure）：处理事件花费的时间，单位时间内处理事件的数目、丢失率

算法，调度算法都是策略。

## 3.4 Security

关注点：在保证合法用户使用系统的前提下，**抵抗**对系统的攻击。

Senario

* 刺激源（source）：攻击可能由人或其它系统发起
* 刺激（stimulus）：对系统的攻击
* 制品（artifact）：系统所提供的服务或系统中的数据
* 环境（environment）：系统可能处于不同的环境下（online/offline）
* 响应（response）：合法用户正常使用，拒绝非法用户的使用，对攻击有威慑
* 响应衡量指标（response measure）：发起攻击的难度，从攻击中恢复的难度

Tactic

* 抵抗攻击
* 检测攻击
* 从攻击中恢复

## 3.5 Testability

关注点

* 让软件的**bug**容易被测试出来
* 验证软件产品与它的需求规格是否匹配
* 使用最小的成本和工作量来验证软件的质量

Senario

* 刺激源（source）：不同的角色发起
* 刺激（stimulus）：系统开发到达了里程碑
* 制品（artifact）：一个设计、一段代码、整个系统
* 环境（environment）：系统可能处于设计阶段/开发阶段/部署阶段/正常运行时
* 响应（response）：理想的响应是可以进行测试，并且可以观察到测试结果；当测试结果无法被观察到时，测试难度很大
* 响应衡量指标（response measure）：白盒测试中的覆盖率；未来继续发现bug的概率

Tactic

* 目标：让测试更轻松
* 方向1：黑盒测试
* 方向2：白盒测试

![[Lecture Notes/Software Architecture/resources/Pasted image 20230610133628.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230610133646.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230610133652.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230610133658.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230610133719.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230610133725.png]]

## 3.6 Usability

关注点：让**用户**使用软件的难度降低

Senario

* 刺激源（source）：终端用户
* 刺激（stimulus）：终端用户希望学习系统的使用、提高系统的使用效率、减少出错
* 制品（artifact）：整个系统
* 环境（environment）：系统处于运行时或配置时
* 响应（response）：系统响应用户的要求
* 响应衡量指标（response measure）：用户完成任务的事件；用户出错的次数；用户满意度；用户操作的成功率

Tactic

![[Lecture Notes/Software Architecture/resources/Pasted image 20230610134010.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230610134020.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230610134029.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230610134043.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230610134049.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230610134057.png]]

## 3.7 Summary

![[Lecture Notes/Software Architecture/resources/Pasted image 20230610134210.png]]

# 4. ATAM

Architecture Trade-off Analysis Mehtod

ATAM Phase 1 的六个步骤：

![[Lecture Notes/Software Architecture/resources/Pasted image 20230611110026.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230611110040.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230611110049.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230611110058.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230611110127.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230612170023.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230611110138.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230611110713.png]]

![[Lecture Notes/Software Architecture/resources/Pasted image 20230611110723.png]]

## 4.1 Sensitivity Points

能得到一个特定的**质量属性**的响应。

## 4.2 Risks

如果某个决策或需求可能会导致开发难题，那就是risk。

## 4.3 Non-risks

能证明正常运行的需求。

## 4.4 Tradeoffs

和Sensitivity Point的区别就是，它影响了多个质量属性。
















![[Lecture Notes/Software Architecture/resources/Pasted image 20230610153123.png]]