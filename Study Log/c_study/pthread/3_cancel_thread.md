---
title: 取消线程
---
线程的取消：

```c
int pthread_cancel(pthread_t thread);
```

通过man手册我们就能够比较好的分析出它的作用。这里给出总结：

* `pthread_cancel`本质上是给参数中的thread发送一个cancle请求；
* thread是否答应这个请求取决于两个东西：**cancelability state** 和 **type**；
* state由`pthread_setcancelstate()`函数设置。如果是disable，那么这个取消请求要进入队列等待，直到enable；如果是enable，那么由type来决定取消什么时候发生；
* type由`pthread_setcanceltype()`函数设置。有两种模式分别是 **asynchronous** 和 **deferred**。异步表示这个线程可以在任何时刻取消，通常是立刻，但是OS不保证；而推迟取消是等到下一个cancel点的时候才会取消；
* 默认的state和type分别是enable和deffered。

使用`pthread_testcancel()`可以创建一个取消点。