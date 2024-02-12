---
title: java线程的启动
date: 2024-02-12
tags:
  - language/coding/java
mtrace:
  - 2024-02-12
---

# java线程的启动

#date 2024-02-12

看OpenJDK源码。参考文档：[Thread.javaのstart()はrun()をどのように呼ぶのか？（備忘録） #Java - Qiita](https://qiita.com/c_keita/items/c2f035dd02c8a5799297)

主要的逻辑就在`jdk/hotspot/src/os/linux/vm/os_linux.cpp`中的`java_start(Thread *)`函数。

JVM线程的结构在`jdk/hotspot/src/share/vm/runtime/thread.hpp`的注释中有：

```cpp
// Class hierarchy
// - Thread
//   - NamedThread
//     - VMThread
//     - ConcurrentGCThread
//     - WorkerThread
//       - GangWorker
//       - GCTaskThread
//   - JavaThread
//   - WatcherThread
```

