---
author: Spread Zhao
title: handler_looper
category: 
description: 
link: 
tags:
  - "#question/coding/android"
  - "#language/coding/kotlin"
  - "#language/coding/java"
  - "#question/coding/practice"
  - "#question/coding/theory"
  - "#question/interview"
  - "#rating/high"
mtrace:
  - 2023-09-04
---

# 1 Looper和MessageQueue

首先，我们需要明确一点：**一个线程只能有0个或1个Looper**。通常情况下，不管我们是在Java中new Thread()还是在Kotlin里thread {}，其实创建的都是不含有Looper的线程。Looper在安卓中是一个非常重要的组成部分，而主线程里就是含有Looper的，这是因为SDK已经帮我们默认创建好了一个Looper。

那么，如何让一个线程含有Looper呢？我们看一看Looper的官方介绍就知道了：

![[Study Log/android_study/resources/Pasted image 20230729164212.png]]

Looper的prepare()函数是一个静态方法，我们来看一看它的实现：

```java
/** 
  * Initialize the current thread as a looper.  
  * This gives you a chance to create handlers that then reference  
  * this looper, before actually starting the loop. Be sure to call  
  * {@link #loop()} after calling this method, and end it by calling  
  * {@link #quit()}.  
  */
public static void prepare() {  
    prepare(true);  
}
```

通常，我们在一个Thread的run方法中首先调用一下这个方法，然后就可以使用**Looper.myLooper()**函数来获取到这个prepare过的Looper对象了。这个对象就是为这个线程专门准备好的Looper，它的内部有一个最重要的结构，叫做MessageQueue：

```java
/**  
 * Low-level class holding the list of messages to be dispatched by a 
 * {@link Looper}.  Messages are not added directly to a MessageQueue,  
 * but rather through {@link Handler} objects associated with the Looper.  
 * * <p>You can retrieve the MessageQueue for the current thread with  
 * {@link Looper#myQueue() Looper.myQueue()}.  
 */
public final class MessageQueue {
```

它就是一个消息队列，而这个队列里的消息，就是各种各样的Handler发过来的。那么现在问题来了：*Handler是怎么够得着这个MessageQueue的*？这就要从Handler的构造方法说起了。

# 2 Handler

Handler的构造方法非常非常多，但总得来说，只分为两类：

* 使用程序员提供给他的Looper来构造；
* 使用默认的Looper来构造。

非常清晰不是？！因为Handler要是想发送消息，必须能获得MessageQueue，而MessageQueue又是一个线程里的唯一一个Looper所保管的。所以，Handler的构造方法里必须提供一个Looper来指明**这个Handler是attach到哪个Looper，也就是哪个线程上的**。

实际上，Looper本身的作用，就是和依附于它的Handler们打交道，实现线程间通信的一种方式：

![[Study Log/android_study/resources/Drawing 2023-07-29 17.03.53.excalidraw.png]]

上图展示了，一个带有Looper的线程，和其它两个线程中依附于自己Looper的Handler打交道的场面。由此我们可以得出结论：**Handler在哪里创建不重要，重要的是它衣服的Looper是谁，在哪个线程里**。因为最终处理消息的时候，就会切换到Looper所在的线程中去执行。

接下来，解答前面的一个隐藏的疑惑：Handler的构造方法中，如果我们不提供Looper，那就会给一个默认的。那这个默认的是谁呢？答案就是：`myLooper()`！

```java
// Handler所有默认Looper构造方法的必经之路
mLooper = Looper.myLooper();  
if (mLooper == null) {  
    throw new RuntimeException(  
        "Can't create handler inside thread " + Thread.currentThread()  
                + " that has not called Looper.prepare()");  
}
```

也就是说，如果我们不提供Looper的画，那么当前运行的线程中的Looper就会被这个Handler依附。所以，我们可以实验一下：在MainActivity，或者只要是主线程的地方，随便调用一下无参构造：

```kotlin
val handler = Handler()
```

程序是不会异常的。因为主线程中SDK已经为我们准备好了一个Looper。现在切换到子线程中来一次：

```kotlin
thread {
	val handler = Handler()
}
```

果然抛出了异常！这和代码中定义的异常一模一样：

![[Study Log/android_study/resources/Pasted image 20230729171658.png|300]]

那么如何解决呢？给他个Looper呗！所以，我们通常的做法，都是在里面传入Looper.getMainLooper()来获得主线程默认的Looper：

```kotlin
thread {  
    val handler = Handler(Looper.getMainLooper())  
}
```

这下程序不会出错了，但是千万要知道到底是为什么，不要只要是构造Handler，就往里面塞Looper.getMainLooper()，而是，**我们想让Handler在哪个线程执行代码，就在哪个线程里构造Looper，然后把它塞到Handler里面去**。比如，我现在就想让这个Handler在我当前的线程里执行代码（纯属脱裤子放屁，教学需要而已），就可以这样做：

```kotlin
thread {  
    Looper.prepare()  
    val handler = Looper.myLooper()?.let { Handler(it) }  
    if (handler != null) {  
        Log.e("MainActivity", "Handler is not null!")  
    }  
}
```

由于Kotllin的强行判空机制，我们打印一条日志，来证明这个方法真的可行。结果当然是成功创建了Handler，并且Looper是我当前这个线程的，并不是主线程的Looper。

在绝大多数情况下，Handler的Looper都应该是其它线程的，因为Handler本身最大的作用就是实现线程间通信。所以，所有没有指定Looper的构造方法，如今都已经被标记成了Deprecated。其中最大的原因，就是时刻提醒我们：**一定要牢记你创建的Handler到底是和哪一个Looper关联的，也就是和哪一个线程关联的**。

# 3 post & send

Handler的使用最重要的就是这两类方法：

* postXXX
* sendXXX

它们的本质区别是，前者接收的参数是Runnable，后者接收的参数是Message。然而，这个区别其实也不算区别。我们来看看post的源码就清楚了：

```kotlin
public final boolean post(@NonNull Runnable r) {  
	return sendMessageDelayed(getPostMessage(r), 0);  
}
```

可以看到，其实最终发送的还是一个Message，而getPostMessage方法就是构造一个Message，然后把Runnable对象填进去：

```java
private static Message getPostMessage(Runnable r) {  
    Message m = Message.obtain();  
    m.callback = r;  
    return m;  
}
```

然后，就是Handler处理消息的方式。一共有三种：

1. Message里自带的Runnable，刚刚就提到过，使用postXXX发送的都是这种；
2. Handler里面有一个Callback接口，在构造Handler时，也可以传这个进去。而这个接口里面也就是一个handleMessage方法；
3. Handler自己的handleMessage方法。

这三者的优先级是从高到低的，也就是：

* 只要Message里自带Runnable，那么后两个都不会被执行；
* 如果Message里没有Runnable，那么如果我们在Handler构造的时候传了Callback进去，那么这里的handleMessage会先执行，**并返回一个布尔变量**；
* 如果之前返回的布尔变量是true，那么Handler自己的handleMessage就不会执行了；如果返回的是false，又或者Callback对象根本就不存在，那么Handler自己的handleMessage就会执行。

# 4 Summary

Handler出现最根本的原因：我不想我自己（子线程）执行这个方法，我要你（主线程）执行！

为什么一个线程最多只有一个Looper？你有多个也没卵用。因为Looper.loop是一个死循环，而这个循环结束了，也就代表线程消亡了。在主线程中，如果loop方法执行完，程序就退出了。所以，即使你给一个线程绑了两个looper，那一个线程的loop一旦启动，后面的也基本上不会执行到了，除非你这个设计本身的bug导致了循环退出。

# 5 Others

> [!question]- Handler 引起的内存泄露原因以及最佳解决方案
> 
> 因为Handler一般是作为Activity的内部类，可以发送延迟执行的消息，如果在延迟阶段，我们把Activity关掉，此时因为该Activity还被Handler这个内部类所持有，导致Activity无法被回收，没有真正退出并释放相关资源，因此就造成内存泄漏。
> 
> 工程上常用的方法是将 Handler 定义成静态的内部类，在内部持有 Activity 的弱引用，并在Acitivity的onDestroy()中调用handler.removeCallbacksAndMessages(null)及时移除所有消息。如果和面试官说了这两个方法，那你就100分过关了，但更进一步是建议将Handler抽离出来作为BaseHandler，然后每个Activity需要用到Handler的时候，就去继承BaseHandler。最佳解决方案具体代码：[[Study Log/android_study/resources/basehandler|basehandler]]

^b9e691

> [!question]- 为什么我们能在主线程直接使用 Handler，而不需要创建 Looper ？
> 
> 详情对应2.1小节，ActivityThread是主线程操作的管理者，在 ActivityThread.main() 方法中调用了 Looper.prepareMainLooper() ，该方法调用prepare()创建Looper。因此主线程不是不需要创建Looper，而是系统帮我们做了。
> 

> [!question]- Handler、Thread和HandlerThread的差别
> 
> 又是这种考区别的题目，不过还算是比较常见的三个知识点：
> 
> 1.  Handler：本文所学的知识，是Android的一种异步消息机制，负责发送和处理消息，可实现子线程和主线程的消息通讯；
> 2.  Thread：Java的一个多线程类，是Java进程中最小执行运算单位，用于给子类继承，创建线程/
> 3.  HandlerThread：从名字看就知道是由前面两者结合起来的。可以理解为“一个继承自Thread的Handler类”，因此本质上和父类一样是Thread，但其内部直接实现了Looper，我们可以直接在HandlerThread里面直接使用Handler消息机制。减少了手动调用Looper.prepare()和Looper.loop()这些方法。
> 

> [!question]- 子线程中怎么使用 Handler？
> 
> 这个题目就可以结合上面两个题目来拓展理解了。子线程中使用 Handler 需要先执行两个操作：Looper.prepare() 和 Looper.loop()，看到这里你应该要记得这两个函数执行顺序是不能变的哦。同时可以直接使用HandlerThread类即可。

> [!question]- 为什么在子线程中创建 Handler 会抛异常？
> 
> 不能在还没有调用 Looper.prepare() 方法的线程中创建 Handler。 因为抛出异常的地方，在Handler的构建函数，判断 mLooper 对象为null的时候， 会抛出异常

> [!question]- Handler 里藏着的 Callback 能干什么？
> 
> 详情对应2.4小节，当从消息队列获取到信息后，需要分配给对应的Handler去处理，总共有3种优先级。
> 
> 1.  handleCallback(msg)：Message里自带的callback优先级最高；对应Handler的post方法；
> 2.  mCallback.handleMessage(msg)：也就是Handler.Callback 写法；
> 3.  handleMessage(msg)：重写handlerMessage()方法，优先级最低；
> 
> 而Handler.Callback处于第二优先级，当一条消息被 Callback 处理并返回true，那么 Handler 的 handleMessage(msg) 方法就不会被调用了；但如果 Callback 处理后返回false，那么这个消息就先后被Handler.Callback和handleMessage(msg)都处理过。
> 

> [!question]- Handler 的 send 和 post 的区别？
> 
> 基于上道题继续展开，post方法，它会把传入的 Runnable 参数赋值给 Message 的 callback 成员变量。当 Handler 进行分发消息时，msg.callback 会最优先执行。
> 
> -   post是属于sendMessage的一种赋值callback的特例
> -   post和sendMessage本质上没有区别，两种都会涉及到内存泄露的问题
> -   post方式配合lambda表达式写法更精简
> 

> [!question]- 创建 Message 实例的最佳方式
> 
> 详情对应2.3小节，为了节省开销，Android 给 Message 设计了回收机制，所以我们在使用的时候尽量复用 Message ，减少内存消耗：
> 
> - [*] 通过 Message 的静态方法 Message.obtain()； 通过 Handler 的公有方法 handler.obtainMessage()。
> 

> [!question]- Message 的插入以及回收是如何进行的，如何实例化一个 Message 呢？
> 
> 插入对应2.5.1小节注释2，Message 往 MessageQueue 插入消息时，会根据 when 字段（相对时间）来判断插入的顺序.
> 
> 消息回收对应2.4小节loop()函数注释5，在消息执行完成之后，会进行回收消息，回收消息可见2.3小节recycleUnchecked()函数，只是 Message 的成员变量设置为0或者null；
> 
> 实例化 Message 的时候，也是件2.3小节，本文建议多次了，尽量使用 Message.obtain 方法，这是从缓存消息池链表里直接获取的实例，可以避免 Message 的重复创建。

> [!question]- 妙用Looper机制，或者你知道Handler机制的其他用途吗？
> 
> - 将 Runnable post 到主线程执行；
> - [*] 利用 Looper 判断当前线程是否是主线程；
> 
> ```java
> public boolean isMainThread() {
>     return Looper.getMainLooper() == Looper.myLooper();
> }
> ```

> [!question]- Looper.loop()死循环一直运行是不是特别消耗CPU资源呢？不会造成应用卡死吗？
> 
> 详情对应2.4和2.5小节。这还涉及linux多进程通讯方式：Pipe管道通讯。Android应用程序的主线程在进入消息循环过程前，会在内部创建一个Linux管道。首先在loop()方法中，调用queue的next()方法获取下一个消息。具体看2.5.2小节，next()源码分析说过，MessageQueue没有消息时，便阻塞在nativePollOnce()方法里，此时主线程会释放CPU资源进入休眠状态，因此并不特别消耗CPU资源。
> 
> 直到等待时长到了或者有新的消息时，通过往pipe管道写端写入数据来唤醒主线程工作。这里采用的epoll机制是一种IO多路复用机制，可以同时监视多个描述符。当一个描述符号准备好(读或写)时，立即通知相应的程序进行读或写操作，其实质是同步 I/O，即读写是阻塞的。其实主线程大多数时候都是处于这种休眠状态，并不会消耗大量CPU资源，更不会造成应用卡死。

> [!question]- MessageQueue 中如何等待消息？为何不使用 Java 中的 wait/notify 来实现阻塞等待呢？
> 
> 直接回答在 MessageQueue 的 nativePollOnce 函数阻塞，直到等待时长到了或者有新的消息时才重新唤醒MessageQueue。其实在 Android 2.2 及其以前，确实是使用wait/notify来实现阻塞和唤醒，但是现在MessageQueue源码涉及很多native的方法，因此Java层的wait/notify自然不过用了，而Pipe管道通讯是很底层的linux跨进程通讯机制，满足native层开发需求。

> [!question]- 你知道延时消息的原理吗？
> 
> 首先是信息插入：会根据when属性（需要处理消息的相对时间）进行排序，越早的时间的Message插在链表的越前面；
> 
> 在取消息处理时，如果时间还没到，就休眠到指定时间；如果当前时间已经到了，就返回这个消息交给 Handler 去分发，这样就实现处理延时消息了。

> [!question]- handler postDelay这个延迟是怎么实现的？
> 
> #TODO 
> 
> - [ ] handler postDelay这个延迟是怎么实现的？

> [!question]- 如何保证在msg.postDelay情况下保证消息次序？
> 
> 详情对应2.5.1小节，和上一题有所联系。handler.postDelay不是延迟一段时间再把Message放到MessageQueue中，而是直接进入MessageQueue，根据when变量（相对时间）的大小排序在消息池的链表里找到合适的插入位置，如此也保证了消息的次序的准确性。也就是本质上以MessageQueue的时间顺序排列和唤醒的方式结合实现的。

> [!question]- 更新UI的方式有哪些
> 
> 这个题目放到这一节确实比较靠前，但因为本节介绍了其中的两个。所以也提一下。
> 
> -   Activity.runOnUiThread(Runnable)
> -   View.post(Runnable)，View.postDelay(Runnable, long)
> -   Handler
> -   AsyncTask
> -   Rxjava
> -   LiveData
> 

> [!question]- 线程、Handler、Looper、MessageQueue 的关系？
> 
> 这里还是有必要说明一下，一个线程对应一个 Looper （可见2.1小节prepare()函数注释1的判断），同时对应一个 MessageQueue，对应多个 Handler。

> [!question]- 多个线程给 MessageQueue 发消息，如何保证线程安全？
> 见2.5.1 enqueueMessage()在插入Message的时候使用synchronized机制加锁。

> [!question]- View.post 和 Handler.post 的区别？
> 
> #TODO 
> 
> - [x] View.post和Handler.post的区别

> [!question]- 你知道IdleHandler吗？
> 
> 看看next()源码：
> 
> [[Study Log/android_study/resources/next|next]]
> 
> IdleHandler 是通过 MessageQueue.addIdleHandler 来添加到 MessageQueue 的，前面提到当 MessageQueue.next 当前没有需要处理的消息时就会进入休眠，而在进入休眠之前呢，会执行注释1，此时如果返回true，则调用该方法后继续保留，下次队列又空闲的时候继续调用。如果返回false，就会在注释2将当前的idler删除。