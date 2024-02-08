[Android 12 系统源码分析 | Native Binder 代码变迁 - 秋城 - 博客园 (cnblogs.com)](https://www.cnblogs.com/wanghongzhu/p/15551978.html)

# 1 Binder的创建

在讲SystemServer的时候，其实就已经提到过binder的创建过程了：

[[Study Log/android_study/system_server#2.2 Binder的创建|system_server]]

任何APP的创建过程中，都会走到这个进程，然后创建出这个进程的binder。在创建完binder之后，还要创建一个binder的线程池（依然在onZygoteInit中）。为什么？因为App中随时有很多处会同时获取我这个binder来进行通信。然而如果只有一个线程的话，七手八脚的通信很有可能就会阻塞住。所以才用一个线程池来进行管理。有人想要通信，那就创建一个线程然后把这个新的通信任务塞进去放到队列里跑就完事了。

# 2 Binder的管理

还是在讲SystemServer的时候说过，服务启动后会通过publishXXX方法把自己的binder派送到ServiceManager中：

[[Study Log/android_study/system_server#1.3 服务的发布|system_server]]

所以：

* 服务的管理者是SystemServer的内部类**SystemServiceManager**，只管理启动流程；
* 服务Binder的管理是在发布后派送的目标：**ServiceManager**。