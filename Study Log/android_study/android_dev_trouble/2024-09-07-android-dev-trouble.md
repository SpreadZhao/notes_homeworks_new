---
title: One Big Discovery When Doing Killing Capture
date: 2024-09-07
tags: 
mtrace: 
  - 2024-09-07
---

# One Big Discovery When Doing Killing Capture

本来我想做一个app杀死的监听。参考：[stackoverflow.com/questions/40021274/…](http://stackoverflow.com/questions/40021274/ontaskremoved-of-a-android-service-is-never-being-called-why?noredirect=1#comment72416170_40021274)。大体的思路就是：写一个Service，然后在onTaskRemove()里面做一些事情。这样就能监听用户在最近任务里面上划干掉进程的情况。

但是我发现了一个很诡异的情况：

![[Study Log/android_study/android_dev_trouble/resources/Pasted image 20240907022001.png]]

解释一下。先看aosp，我做的事情是在Application里面启动service，打印的是`[5730]...`这句话。自然之后就会调用到onStartCommand，从而打印第二句话。然后我上划干掉进程，自然而然就会执行on task removed这句话。

但是代码完全没变，换到三星的设备上就奇怪了。第一次启动没问题。但是在我上划之后，居然又打印了一遍`start kill service`。这个日志可是我在Application的onCreate里写的。也就意味着这实际上是在我干掉进程之后，系统主动又调用了一遍Application的onCreate！这个操作就很奇怪了。

为了进一步验证，我在中括号里打印的就是pid。可以证明，三星的设备两次打印的pid是不一样的。

然后还有一点，上面的三星是把当前应用的电量管理设置成Unrestricted。如果设置称Restricted，结果是这样：

![[Study Log/android_study/android_dev_trouble/resources/Pasted image 20240907022645.png]]

也就是说，如果限制了电量，那么这个service根本就不会被调用到onTaskRemoved。这个说法和我找到的资料也是一致的：[android - onTaskRemoved() not getting called in HUAWEI and XIAOMI devices - Stack Overflow](https://stackoverflow.com/questions/40660216/ontaskremoved-not-getting-called-in-huawei-and-xiaomi-devices/42120277#42120277)

接下来继续验证。在service上也打印pid，可以发现无论是哪个设备，应用进程和Service的进程都是同一个：

![[Study Log/android_study/android_dev_trouble/resources/Pasted image 20240907023207.png]]

但是我们观察一个点：在AOSP中，同一个进程在退出，调用onTaskRemoved之后，就结束了；但是在三星的设备上（没有限制电量），当系统重新调用Application的onCreate创建一个进程，然后调用了onTaskRemoved，在这之后又启动了一下这个Service。这就导致8684号最后是没有退出的状态的。这个通过开发者模式也能看到：

![[Study Log/android_study/android_dev_trouble/resources/Pasted image 20240907023701.png]]

- [ ] #TODO tasktodo1725647957400 所以这个问题接下来还是有一些研究的价值的。看看到底是什么原因导致的，其它的手机会有类似的问题吗？AOSP虽然没问题，但是如果我们在onTaskRemoved里面做了太多事情，又会怎样？最后终极目的就是我们能不能有一个准确的，应用被杀掉的时机，并在这个时候做一些事情呢？同时，Android Service相关的知识也是需要补一补的。 ➕ 2024-09-07 ⏫ 🆔 eu4qn9 