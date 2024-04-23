# 基于RecyclerView的高性能Feed流研究与应用

## 摘要

RecyclerView是安卓开发领域最重要的流式布局组件，市面上大多数的APP的Feed流都是基于RecyclerView进行开发。Feed流也就是流式信息流，目前很多流行的大众APP的核心业务场景都是一个Feed流，如淘宝、抖音、微信等。信息流的性能表现，直接决定着这些应用的整体用户体验。

RecyclerView几乎在所有现代Android App中都有所使用，并且应用场景往往是一个App最复杂的业务。因此开发者对于RecyclerView的自定义（无论是ViewHolder，还是数据绑定逻辑）往往是一个应用中逻辑最复杂，代码量最多，耗时最长的部分；同时开发者对于RecyclerView的掌握程度以及使用方式直接影响着大量用户的体验。在Google I/O 2016上，官方给出了RecyclerView产生的原因，并且给出了大致的RecyclerView工作方式。

然而，仅仅依靠Google给出的资料并不能让我们有效理解RecyclerView的内部原理，从而更好地使用甚至修改这个复杂的流式布局。越来越多的文章不断出现，解析RecyclerView内部的源码，并对其中的架构设计、代码链路、算法进行分析。

目前为止，国内外互联网大厂对于RecyclerView的研究依然没有停止，并且针对特定的业务场景，依然在不断寻找性能优化点，优化RecyclerView的启动、滑动、数据加载耗时。

本课题将深入研究RecyclerView的开发与性能优化手段，开发出一个高性能的Feed流，并基于真实的线上应用去验证一些性能优化手段。

## ABSTRACT

RecyclerView is the most important component for implementing a staggered layout in the field of Android development, and the majority of feed streams in popular apps on the market are developed based on RecyclerView. The feed stream, also known as a staggered information stream, is the core business scenario of many popular apps such as Taobao, TikTok, and WeChat etc. The performance of the information stream directly determines the overall user experience of these applications.

RecyclerView is almost universally used in all modern Android apps, and its application scenarios are often the most complex business logic in an app. Therefore, developers' customization of RecyclerView (whether it's ViewHolder or data binding logic) is often the most complicated, code-heavy, and time-consuming part of an application. At the same time, developers' understanding and usage of RecyclerView directly impact the experience of a large number of users. At Google I/O 2016, the official reasons for the creation of RecyclerView were given, along with a rough overview of how RecyclerView works.

However, relying solely on the information provided by Google does not effectively help us understand the internal principles of RecyclerView, thus making it difficult to better use or modify this complex staggered layout. More and more articles are constantly appearing, analyzing the source code of RecyclerView and dissecting its architecture, code paths, and algorithms.

So far, both domestic and international Internet giants have not ceased their research on RecyclerView, and they continue to explore performance optimization points for specific business scenarios, aiming to optimize the startup, scrolling, and data loading time of RecyclerView.

This paper will delve into the development and performance optimization techniques of RecyclerView, and develop a high-performance feed stream. Real-world online applications will be used to validate some of the performance optimization techniques.

## 目录



## 第一章 介绍

Android 是目前使用最广泛的系统。无论是手机、平板、电子书、车机还是嵌入式设备等都在运行 Android 系统。因此 Android 应用程序的开发和迭代也在日益增加。随着代码量不断增加，应用本身的业务逻辑也越来越臃肿。因此对于应用的主要业务场景，我们需要对其进行不断优化，才能削减业务代码增加带来的性能方面的负面影响。

Android 系统的大部分 UI 绘制是交由应用的主线程来执行。主线程从 ActivityThread 的 main 方法开始运行，通过消息机制来不断处理 UI 的绘制消息和应用内部在主线程执行的业务逻辑，从而让应用运行下去，并响应用户的操作行为而进行 UI 上的改变。在这个过程中，如果主线程进行了过多的操作导致消息不能及时处理，就会发生在主线程的卡顿，从而让 UI 不能及时刷新，影响用户的体验。因此，我们需要对主线程的代码进行不断优化和拆分，来让 UI 操作能够即使得到处理。

目前绝大部分 Android 应用的主要场景是一个信息流，用来给用户呈现最新的推荐信息。这些信息包括但不限于视频、新闻、帖子等各种各样格式和形式的流式信息。这些信息的刷新和展现大部分也都是由主线程来完成。而作为一个应用的主要场景，甚至是应用的门面，这些场景的业务代码通常更新频率非常高，业务逻辑迭代会非常快。因此，这些场景的代码的劣化速度也远高于其它场景。所以，这部分代码对流畅性的影响是我们一定要尽可能削减的。

这些流式信息为了能够方便用户进行浏览，通常也都会用流式布局来承载。其中应用最广泛的就是 RecyclerView，一个高性能的流式布局容器。当用户在 RecyclerView 中快速滑动时，它会根据目前的情况合理分配和回收每一个子项目的引用和视图，从而减少该布局对于内存和性能的开销。然而，随着业务代码的不断积累，RecyclerView 本身带来的性能收益也逐渐被淹没。但是由于 RecyclerView 已经承载了太多的业务逻辑，我们尝试基于它针对特定的业务场景进行深度优化，从而提高用户的流畅性体验。

显然，我们希望能够量化优化的结果。因此我们还需要一些手段来验证我们的优化结果。其中最复杂的部分就是如何找到采集指标信息的时机，并在这个时机进行信息的收集。最普遍的手段就是帧率指标，然而目前的帧率采集手段依然有一些不足。因此我们也要探究出一个更加准确的帧率采集手段，并在这个基础上，继续探索其它的性能指标来衡量我们对于 RecyclerView 的其它方面做出的优化成果。

## 第二章 Android 绘制系统

Android 系统底层采用 Skia，OpenGL 等引擎进行绘制，而在上层封装好的组件就是 Canvas 和 View 。View绘制系统是 Android 开发者最常用到的 UI 编写 API，同时各种动画、自定义样式等绘制操作也都是交由 View 和 Canvas 来完成。

本课题用到的优化机制，主要是针对 View 的，因此这里着重介绍一下 View 的绘制流程。在 Android 应用中，View 占据了一块屏幕上的矩形区域。在这个区域内，UI 将被显示给用户，同时这块区域也负责处理用户、应用本身输入的事件，从而和用户进行交互。View 的体系非常庞大，绘制系统也非常复杂。这里主要针对 View 的大致分类和普通 View 的绘制流程进行说明。

### 2.1 View 的分类

从总体的功能上看，View 只分为两种：普通的 View 以及 ViewGroup。顾名思义，ViewGroup是用来承载其它 View 和 ViewGroup 的容器；而普通的 View 无法承载其它的 View，只能作为直接和用户交互的组件。在 Android 系统中，View 体系通过树形结构来存储，因此，这棵树上所有的非叶子节点都是 ViewGroup，所有的叶子节点都是普通的 View。

从代码层面来看，ViewGroup 继承自 View，因此 ViewGroup 有着和普通的 View 相似的行为，也需要进行绘制和布局等流程。只不过，ViewGroup 更加关心的是自己内部的子 View 的测量流程，对它们进行统一的管理。

从内容层级来看，Android 应用程序从最顶层的 DecorView 出发（DecorView 本身被 ViewRootImpl 持有），到持有内容的容器 contentParent，最后到应用开发者主动向 Window 中添加的各种 View。这些系统级别的 View 一部分是为了管理系统的应用以及悬浮窗等 Window 的通用行为，另一部分是为了给开发者提供额外的扩展能力。因此，我们对于 View 的性能进行优化，主要优化的也是开发者自行添加的这一部分。

### 2.2 View 的绘制流程

要明确 Android 体系中 View 的渲染、绘制流程，需要先明确在 Android 系统中的屏幕刷新原理。这样才能对 View 本身的绘制有比较深刻的理解。同时，这里也会介绍卡顿情况产生的原因。后续我们会针对这些问题进行优化。

#### 2.2.1 Android 屏幕刷新原理

在 Android 系统中，屏幕的显示操作需要靠三个部分来完成：CPU，GPU 和显示器。其中，CPU 负责进行绘制信息的计算，其中就包括之后我们介绍的 View 的绘制流程。这些计算好的信息会交给 GPU 进行图形渲染，生成每一个屏幕像素点的颜色信息，并存储到一个缓存当中。当需要让显示器进行显示时，GPU 和显示器的缓存会进行交换，这样显示器得到的就是新的要显示的内容。下面针对屏幕刷新的情况介绍一些概念：

* 屏幕刷新率：一秒内屏幕刷新的次数。由于显示器拿到的每一个缓存都包含了屏幕上所有要更新的信息，因此屏幕的显示模式永远是固定的时间将屏幕上的所有像素点进行更新。不过某些情况下，如果前后两次的像素是一致的，那么可以选择不更新，但是这个操作取决于显示器。因此，即使我们提高了 GPU 将像素信息传送到显示器的速度，屏幕刷新率也是不变的，因为这个指标是对于显示器性能的衡量，而非实际情况；
* 逐行扫描：显示器显示像素的原理并不是一次性将缓存中所有的像素点真正更新到屏幕上，而是逐行进行扫描。因此，这段扫描的时间决定了显示器的素质。通常情况下， Android 手机的显示器扫描一次整个屏幕需要约16.67毫秒。因此，这个时间的结果就是屏幕每秒钟刷新的次数约为60次，也就是屏幕刷新率为60Hz；
* 帧率：与屏幕刷新率相对的，帧率表示实际情况下我们传送给显示器的速度。对于运行在 Android 系统的 CPU 来说，这个过程交给了应用的主线程。因此，如果主线程在执行任务的时候过于耗时，没能及时将数据传递给 GPU 和显示器，那么就会让这一帧无法显示在屏幕上，导致屏幕上显示的还是原来的像素，这就是卡顿产生的原因。因此，为了保证真实的帧率能够贴近屏幕刷新率，Android 应用的主线程在处理任务时应该尽可能快，这样才能保证所有的绘制操作顺利进行并最终显示在屏幕上。

在某些情况下，屏幕的显示可能会产生抖动。产生这种现象的原因是，当显示器读取缓存，并显示到屏幕上时，GPU 正在向缓存中写入数据。由于并没有做读写保护，所以前后的像素点并不是来自于同一帧。因此后果就是屏幕上的画面产生了撕裂感。解决这种问题的方法是使用双缓存。也就是 GPU 写入的缓存，和显示器读取的缓存并不是同一个。GPU 永远只写入 Back Buffer，显示器只读取 Frame Buffer。而到了需要刷新的时机时，两个缓存的引用会进行交换。由于这个交换的过程非常快，因此可以杜绝绝大部分的画面撕裂问题。

然而，在目前的双缓存机制下，卡顿的问题还是无法得到很好的解决。当 CPU（或者 GPU）在当前帧的持续时间内，无法及时完成图像信息的计算，那么就会发生卡顿。在这种情况下，我们会发现无论是 CPU 还是 GPU，都无法使用 Frame Buffer 或者 Back Buffer。因为前者需要被显示器读取来维持卡顿的帧；后者的数据还没有被显示器读取，等到卡顿帧结束之后，它们还需要被显示到屏幕上。这就导致如果在这个过程中 CPU 和 GPU 有计算任务，计算的结果没有地方保存，也就浪费了 CPU 和 GPU 的绘制时间。针对这个问题，Android 引入了三缓存（Triple Buffering）机制。在三缓存机制下，有两个 Back Buffer 存在，当其中一个因为卡顿而被占用时，CPU 和 GPU 的计算结果就可以存储到另一个缓存中。这样就能有效减少卡顿的传递性带来的连续卡顿。

%% 上图，Double Buffering & Triple Buffering的图。文字也要加上例子。 %%

下一个问题，就是两个缓存进行交换的时机。如果无法保证交换时的读写安全，那么依然会产生显示上的问题。当屏幕的最后一个像素显示完毕后，设备需要一段空闲时间，以便将指针移动回第一个像素来显示下一帧的内容。这段空闲的时间叫做 Vertical Blanking Interval(VBI)。在这段时间内，屏幕上的内容依然会保持原装，并且显示器也不会去读缓存中的内容。因此，这个时间就是进行缓存交换的最佳时刻。在VBI的时间内，系统会发射出用于同步时钟信号的垂直脉冲。这个垂直脉冲也就是VSync信号，是我们判断一帧到达的关键信息。

#### 2.2.2 Choreographer 和屏幕信号进行同步

以上的介绍很大程度上是在硬件层面描述 Android 系统中应用的刷新模式。下面我们从软件层面来说明这一过程，来看看在 Android 系统中，画面的刷新流程到底是怎样的。对于应用层的进程来讲，其和屏幕刷新相关的主要媒介是通过一个上层的 Framework 组建 —— Choreographer。

Choreographer 的职责是协调动画、用户输入事件（触摸，外接鼠标等）和绘制流程。它通过底层注册的驱动程序接受系统发出的时间脉冲（也就是上文提到的 VSync 信号），来组织下一帧应该绘制的信息。其中包括让 CPU 去处理下一帧的图像信息，也包括将这些计算好的信息提交给 GPU 来进行渲染。接下来提到的 View 的绘制以及其对于用户输入事件的处理也都是由 Choreographer 在每一帧发起的。

要了解 Choreographer 的具体工作流程，需要了解 Android 系统的消息机制。这里先做一个简单的说明。在 Android 应用中，每一个应用的主进程在启动时，都会开启一个 Looper。这个 Looper 的运行函数是一个无限循环，在每一次循环中，会从消息队列中取出一条消息执行，并不断重复这个过程。而向 Looper 提供一条消息的方式，就是通过另一个组件 Handler。Handler 可以发送各种类型的消息，同时具备延时功能。发送的消息会被添加到等待队列中，等待 Looper 将其取出并执行。显然，主线程对应的 Looper 就是主要用来处理各种绘制操作，而主线程的 Handler 用来向主线程提交各种类型的绘制操作任务。对于 Choreographer，当接收到底层发送的 VSync 信号时，就会向主线程提交一个这样的绘制任务。当这个任务被执行时，当前帧的绘制行为就会被完成。这就是 Android 应用程序中各种动态界面绘制的源头。

因为这样的绘制机制，我们在开发以及优化应用时，无需关心每一个 VSync 信号实际被发出的时间，只需要关心我们注册的监听器什么时候能接收到 VSync 信号。在这个信号到来时执行绘制的行为，并争取在下一个 VSync 信号到来之前完成它。因此，我们需要区分“帧”和“绘制行为”的区别。通常我们所说的帧指的是每两个 VSync 信号的间隔时间。这段时间内，绘制行为有可能完成，也有可能没有完成；而绘制行为指的是由 Choreographer 发起的从 CPU 到 GPU 最后到显示器的一系列操作。这一串行为在正常情况下只能在一个 VSync 信号到来时开始执行，并在下一个 VSync 信号到来前执行完毕。如果没有及时完成绘制行为，那么下一帧依旧只能显示上一帧的内容，直到绘制完成，缓存可用为止。了解了这些，能够帮助我们在收集流畅性指标时，制定更加精确的收集方案。

Choreographer 在一帧内所做的绘制工作主要有：

* 处理用户输入事件；
* 处理动画；
* 处理 View 的绘制流程。

这些绘制工作都作用在应用的 View 树上，通过遍历 View 层级中的各个 View 来对其进行重新绘制，相应触摸之后的新行为等等。在这个过程中，也涉及到很多的性能优化过程，比如增量更新以及脏区计算等等。因此，对于这部分逻辑的改动需要格外小心，确保在优化完毕后，View 的行为对于业务来说和优化之前保持一致。

#### 2.2.3 View 的测量、布局和绘制

Choreographer 在一帧中最主要的任务就是处理这一帧内 View 树中每个 View 的绘制流程。其中需要进行三轮不同的操作：测量（measure）、布局（layout）和绘制（draw）。在测量的过程中，需要确定每一个 View 所占据的矩形区域的大小。其中最典型也是最耗时的就是文本类型的 View 的测量。这些文本因为语言、字符宽度、文字方向等不同的因素，需要进行非常复杂的测量流程，最终才能确定文本的长和宽。因此，View 的测量流程通常也是 View 进行绘制的时候最耗时的一个过程；在布局过程中，需要根据每一个 ViewGroup 规定的布局方式对其中的子 View 进行布局，也就是确定其在 Window 上显示的位置。常见的 ViewGroup 有线性布局 LinearLayout，帧布局 FrameLayout和相对布局 RelativeLayout。这些不同的布局对于其中的子 View 有不同的布局要求。最终在这一阵进行布局的时候，就会把已经测量完毕的子 View 布局到屏幕上，也就是确定它们应该摆放的位置；最后一步就是绘制了，也就是真正将图形绘制到屏幕上的操作。这部分工作大部分是通过 Android 的上层渲染组件 Canvas 来完成的。 Canvas 会将各种类型的图形在 CPU 上进行计算，之后会将这些计算好的结果发送给 GPU 进行渲染。这也是大部分 Android 动画实现的原理。

对于 ViewGroup 来说，测量的流程需要特别强调。因为 ViewGroup 本身没有内容，它的作用是承载子 View。所以，ViewGroup 的主要测量过程就是去测量自己的子 View，并最终得到所有子 View 的综合属性。

然而，View 体系并没有限制 ViewGroup 应该在测量的时机一定得到子 View 的准确测量结果。这就意味着我们可以在测量的时候返回一个假值，并在后面的时机得到真正的值。RecyclerView 就是这样做的。因为它通常需要承载大量的子 View，因此它对于性能的要求非常高。所以它的测量流程作为非常耗时的一个流程，需要尽可能地减少测量的总次数以及避免重复测量。RecyclerView 真正测量子 View 是在布局流程中，在测量完子 View 之后会立刻对子 View 进行布局。这种方式能够避免子 View 在不适宜的时机请求父 View 测量而导致性能下降的问题。当 RecyclerView 在进行布局时，它会禁止子 View 进行布局请求，从而拦截子 View 的测量请求，从而减少不必要的测量次数。这部分之后会在xxx详细说明。

#### 2.2.4 用户输入事件的处理

当用户用手触摸屏幕时，触摸行为会定位到特定的 View 上。但是，这个触摸行为的响应只会在下一帧到来时进行响应。因为受限于屏幕的刷新率，只有在下一帧屏幕才能给出新的图像。所以等到 Choreographer 接收到下一个 VSync 信号时，新的绘制流程启动，这些积累的触摸事件就会在这个时候被消费。

说明白触摸的拦截流程，之后会用到。
[在 ViewGroup 中管理触摸事件  |  Views  |  Android Developers](https://developer.android.com/develop/ui/views/touch-and-input/gestures/viewgroup?hl=zh-cn)

## 第三章 Android 消息机制

## 第三章 RecyclerView 介绍

## 第四章  预渲染框架

## 第五章 预渲染优化验证

## 第六章 其它形式的优化手段

## 致谢

* 感谢西安电子科技大学计算机科学与技术学院王琨老师的论文指导；
* 感谢北京字节跳动的谢道旺给出的项目设计思路和一起研究并在线上验证的机会。

## 参考文献