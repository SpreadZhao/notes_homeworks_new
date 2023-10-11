# 1. 构件与中间件

分布式软件指运行在网络环境中的软件系统。分布式软件通常基于客户机/服务器（Client/Server）模型。如果一个系统两个组成部分存在如下关系：其中一方提出对信息或服务的请求（称为客户机），而另一方提供这种信息或服务（称为服务器），那么这种结构即可看作是一种客户机／服务器计算模型。

![[Lecture Notes/Middleware/resources/Pasted image 20230611115027.png]]

两层缺点： ^7d10e0

1. 客户端负担重
2. 客户端可移植性不好
3. 系统可维护性不好
4. 数据安全性不好

![[Lecture Notes/Middleware/resources/Pasted image 20230611115148.png]]

构件是什么？就是Component，你想一想组件是怎么隐藏，怎么封装，怎么组合到一起的，就知道构件的概念了。

![[Lecture Notes/Middleware/resources/Pasted image 20230611115828.png]]

中间件的三个支撑：

1. 提供构件运行环境

  ![[Lecture Notes/Middleware/resources/Pasted image 20230611151442.png|400]]

2. 提供互操作机制

  ![[Lecture Notes/Middleware/resources/Pasted image 20230611151458.png|400]]

  ![[Lecture Notes/Middleware/resources/Pasted image 20230611151527.png|400]]

3. 提供公共服务

  ![[Lecture Notes/Middleware/resources/Pasted image 20230611151537.png|400]]

  ![[Lecture Notes/Middleware/resources/Pasted image 20230611151548.png|400]]

在 Stub/Skeleton 结构中，**由客户端桩（Stub）替客户端完成与服务端程序交互的具体底层通信工作，客户程序中的远程对象引用实际上是对本地桩的引用；而服务端框架（Skeleton） 负责替服务端完成与客户端交互的具体底层通信工作**。由于客户端桩与服务端框架分别位于客户端与服务端程序的进程内，因此开发人员开发客户端与服务端程序时只需分别与本进程内的桩与框架构件交互即可实现与远端的交互，而负责底层通信的客户端桩与服务端框架在开发过程中自动生成而非由开发人员编写，从而为开发人员省去底层通信相关的开发工作。 ^b14646

![[Lecture Notes/Middleware/resources/Pasted image 20230611115937.png]]

中间件的类型：

* 数据访问中间件
* 远程过程调用中间件
* 消息中间件
* 事务中间件
* 构件中间件
* 集成中间件

# 2. J2EE

![[Lecture Notes/Middleware/resources/Pasted image 20230611174042.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611121849.png]]

支撑它们的有一系列服务，也就是绿色的：

* JMS: Java Message Service
* JNDI: Java Naming and Directory Interface
* JDBC: Java Database Connectivity
* JTA: Java Transaction API
* JCA: J2EE Connector Architecture
* Java IDL: 访问CORBA构件

以上都是开发时的服务，除此之外，还有运行时的服务

* Life cycle
* Transaction

  ![[Lecture Notes/Middleware/resources/Pasted image 20230612175526.png]]

* Security
* Persistence
* Resources

J2EE中的角色：

* J2EE Product Provider：程序员
  Tool Provider：工具
* Application Component Provider：集成开发环境
* Application Assembler：组装
* Deployer：部署
* Systerm Administrator：系统级别管理

Web

![[Lecture Notes/Middleware/resources/Pasted image 20230611152738.png]]

Cookie

![[Lecture Notes/Middleware/resources/Pasted image 20230611153634.png]]

Session

![[Lecture Notes/Middleware/resources/Pasted image 20230611153719.png]]

# 3. Web Service

![[Lecture Notes/Middleware/resources/Pasted image 20230611173559.png]]

## 3.1 SOA

SOA特征：

![[Lecture Notes/Middleware/resources/Pasted image 20230611160626.png]]

SOA要素：

1. 互操作
	1. 访问互操作
	2. 连接互操作
	3. 语义互操作
2. 软件复用
3. 解耦

SOA的三个参与者

* 服务提供者
* 服务请求者
* **服务代理者**（和前两个一样重要）

SOA的三个基本操作

* 发布服务
* 发现服务
* 基于服务描述绑定或调用

## 3.2 Web Service

Web Service是SOA一种重要的实现方式

![[Lecture Notes/Middleware/resources/Pasted image 20230611161517.png|500]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611161636.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611162328.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611162339.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611162503.png]]

BPEL是专为组合Web Services而制定的一项规范标准 ^fe8384

![[Lecture Notes/Middleware/resources/Pasted image 20230611162623.png]]

## 3.3 RESTful

**RE**presentational **S**tate **T**ransfer - RESTful API

要素：

1. 资源：表现层指的就是资源的表现层。资源可以是一段文本，图片，歌曲，视频，服务等等，每种资源对应一个特定的URI，每个资源拥有唯一的URI作为网络地址。
2. 表现层：文本可以用txt，html，xml，json，二进制来表现；图片可以用jpg，png来表现。
3. 状态转化：![[Lecture Notes/Middleware/resources/Pasted image 20230611163117.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611163138.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611163210.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611163322.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611163333.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611163340.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611163403.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611163409.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611163426.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611163433.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611163850.png]]

## 3.4 Service Composition

编制和编排的区别？**编制有一个控制的组件，而编排没有**。编制用的就是之前介绍过的[[#^fe8384|BPEL]]。 ^052374

编制的三个运行模式

1. 集中式执行引擎![[Lecture Notes/Middleware/resources/Pasted image 20230611164959.png]]
2. 基于Hub的分布式引擎![[Lecture Notes/Middleware/resources/Pasted image 20230611165026.png]]
3. 无Hub的分布式引擎![[Lecture Notes/Middleware/resources/Pasted image 20230611165043.png]]

静态组合vs动态组合

![[Lecture Notes/Middleware/resources/Pasted image 20230611165142.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611165148.png]]

# 4. Micro Services

出现动机：

1. 一大坨服务器代码，改一行要整个编译一遍，累死了
2. C++，Java混用，你怎么写成一个服务器
3. 只要有组件不够用了，就要扩展整个服务器

微服务 vs SOA

![[Lecture Notes/Middleware/resources/Pasted image 20230611170232.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611170238.png]]

# 5. Serverless

![[Lecture Notes/Middleware/resources/Pasted image 20230611170719.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611170744.png]]

架构

![[Lecture Notes/Middleware/resources/Pasted image 20230611170921.png]]

![[Lecture Notes/Middleware/resources/Pasted image 20230611171054.png]]

# 6. EJB

![[Lecture Notes/Middleware/resources/Pasted image 20230611171344.png]]

EJB的6种构件：

1. **Enterprise Bean**
	1. Session Bean：传输![[Lecture Notes/Middleware/resources/Pasted image 20230611173144.png]]
	2. Entity Bean：数据库![[Lecture Notes/Middleware/resources/Pasted image 20230611173446.png]]
	3. Message Driven Bean
2. **Home Interface**
3. **Remote Interface**
4. EJB Container
5. EJB Server
6. EJB Client

EJB构件技术：

* 分布式对象技术
* 服务端构件技术
* CTM(Component Transaction Monitor)技术

EJB的特点：

* 公共服务框架
* 平台独立性
* 封装特性
* 可定制性
* 协议无关性
* 通用性

