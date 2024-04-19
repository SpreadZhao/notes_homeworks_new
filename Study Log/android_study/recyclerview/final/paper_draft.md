# 基于RecyclerView的高性能Feed流研究与应用

## 摘要

RecyclerView[^1]是安卓开发领域最重要的流式布局组件，市面上大多数的APP的Feed流都是基于RecyclerView进行开发。Feed流也就是流式信息流，目前很多流行的大众APP的核心业务场景都是一个Feed流，如淘宝、抖音、微信等。信息流的性能表现，直接决定着这些应用的整体用户体验。

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

## 第一章 Android View 绘制系统

## 第二章 Android 消息机制

## 第三章 RecyclerView 介绍

## 第四章  预渲染框架

## 第五章 预渲染优化验证

## 第六章 其它形式的优化手段

## 致谢

## 参考文献

[^1]: 测试文档 by S