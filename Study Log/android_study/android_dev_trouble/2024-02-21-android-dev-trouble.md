---
title: NDK中调用pthread_join()产生的问题
date: 2024-02-21
tags:
  - language/coding/c
  - language/coding/java
  - "#question/coding/android/ndk"
mtrace:
  - 2024-02-21
---

#date 2024-02-21

# NDK中调用pthread_join()产生的问题

这篇文章写的有点晚了。因为我之前总觉得写过这个东西，但是今天排查tasks的时候发现居然没有。这篇文章也相当于回答了之前的那个问题：[[Study Log/java_kotlin_study/concurrency_art/4_1_thread_basic#^74d7f0|4_1_thread_basic]]

我之前在写[[Study Log/android_study/ndk/2_simple_timer#3.1.1 AttachCurrentThread|2_simple_timer]]的时候，有这么一段代码：

```cpp
// 创建线程标识符
pthread_t th;
// 创建并启动线程，参数按需传入。StartTimer是计时器的工作函数
pthread_create(&th, nullptr, StartTimer, &context);  
// main线程等待th结束
pthread_join(th, nullptr);
```

不知道我当时为什么就这么写下去了，总之一开始好像是这句join还没加上，当时是工作的。然后我手贱加了一个join，最后整个程序只要一启动就卡死。

这个问题其实非常简单。**和java的Thread对比一下**就知道，join的作用就是：暂停当前线程，等到被join的线程结束之后才从join返回。因此，我这里是在主线程调用的pthread\_join，因此这就代表着主线程要等到th结束之后才能继续。

这意味着什么？主线程负责刷新UI，那它暂停了，只有th还在运行。所以当时我看到的现象是“程序卡死，但是日志可以正常每秒打印出来”。这就是因为主线程被暂停了但是th还在运行导致的。

---

以上是pthread和Java Thread对比的第一个小点。下面是第二个，这个就是我随手测一测的事情。在Java中，只有所有非守护线程都结束的时候，程序才结束。这个在我的并发艺术笔记里也有提到：[[Study Log/java_kotlin_study/concurrency_art/4_1_thread_basic#^5e1737|4_1_thread_basic]]。

而在c中，只要main结束了，整个程序就会结束，不管其它线程是否执行完成。正因为如此我们才会习惯于在主线程最后等着给它生出来的线程收尸完才结束。这个我们pthread一开始就提到了：[[Study Log/c_study/pthread/1_create_thread|1_create_thread]]。