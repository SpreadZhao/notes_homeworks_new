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

## 第二章 Android View & Handler

## 第三章 RecyclerView 介绍

## 第四章  预渲染框架

## 第五章 预渲染优化验证

## 第六章 其它形式的优化手段

## 致谢

## 参考文献