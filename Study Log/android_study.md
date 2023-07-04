# 1 Android Boot Process

[Android Boot Process (tutorialspoint.com)](https://www.tutorialspoint.com/android-boot-process)

[Android Boot Process - GeeksforGeeks](https://www.geeksforgeeks.org/android-boot-process/)

Android Boot Process is a process of starting a computer for using it. A computer system can be started by switching on the power supply. When the computer is started it is able to read only the part of storage called **Read only memory**. A small program is started on launching the computer which is stored and called as **firmware**. *It allows accessing other types of memory such as main memory and hard disk*. The firmware is used to load big programs and run it into the computer's main memory. Boot Manager is run in all devices whether it may be a mobile device, computer system or others.

安卓系统的启动流程分为六个步骤，总的来说可以看下图：

![[Study Log/resources/Pasted image 20230704151749.png]]

## 1.1 Boot ROM

ROM也就是Read-Only Memory，这部分中的代码是提前写死在硬件里的。当手机上电的时候，这部分的代码将会执行。而在安卓系统中，ROM的主要工作就是将BootLoader加载到主存中。

## 1.2 BootLoader

所谓的BL锁指的就是BootLoader锁。这部分程序是在操作系统启动之前就执行的。手机厂商通常都会将加密的逻辑放在这个部分去执行，从而对手机进行全面的控制。而BootLoader加载的过程通常分为两部分：

1. 在主存中分配一段空间，加载一个程序，给第二阶段使用；
2. 使用这段程序分配内存，设置网络环境，用来加载**内核**。

## 1.3 Kernel

也就是Linux内核的加载。当加载结束后，它会找到init方法，这里就是安卓系统真正启动的开始。

关于内核的更多介绍，可以看我的[[Lecture Notes/Operating System/os|操作系统笔记]]。

## 1.4 Init

刚才说init是内核的最后一个步骤，同时它也是用户空间的第一个步骤，第一个程序。这个进程其实有一点像linux中的systemd进程，负责fork出其它的用户空间进程。这个进程会读取`/init.rc`目录中的配置文件并开启一些重要的服务和守护进程。当然，这个进程是以root用户的权限启动的，它负责设置手机的安全政策，挂载文件系统，设置用户的网络环境等等，同时更重要的，是**启动Android Runtime，用来启动Android Framework和各种真正的安卓程序**。

## 1.5 Zygote and Dalvik VM

Init进程启动的程序中，其中一个就是Zygote。而这个程序是运行在一个特殊的虚拟机，Dalvik VM中的。DVM是JVM的变体，对移动设备进行了很多能效比的优化。DVM会调用Zygote进程的main方法。这个进程启动之后，会进行一次fork，在另一段内存空间中复制出一个副本。

## 1.6 System Servers

当zygote进程加载完了所有的类和资源之后，就会启动System Server。这是安卓系统的核心进程，它加载了安卓服务的原生接口以提供原生的功能。当这些服务和功能都加载好之后，就会按顺序去加载剩下的一些服务。当所有的这些都完成之后，就会发送这个启动完成的广播：`ACTION_BOOT_COMPLETED`。

# 2 应用启动流程

从点击桌面的APP图标，到APP主页显示出来，大致会经过以下流程：

1.  点击桌面App图标，Launcher进程采用Binder跨进程机制向system_server进程发起startActivity请求；
2.  system_server进程接收到请求后，向Zygote进程发送创建进程的请求，Zygote进程fork出新的子进程，即新启动的App进程；
3.  App进程，通过Binder机制向sytem_server进程发起attachApplication请求（绑定Application）；
4.  system_server进程在收到请求后，进行一系列准备工作后，再通过binder机制向App进程发送scheduleLaunchActivity请求；
5.  App进程的binder线程（ApplicationThread）在收到请求后，通过handler向主线程发送LAUNCH_ACTIVITY消息。主线程在收到Message后，通过发射机制创建目标Activity，并回调Activity.onCreate()/onStart()/onResume()等方法，经过UI渲染结束后便可以看到App的主界面。

一些基础知识：

-   冷启动：当启动应用时，后台没有该应用的进程，这时系统会重新创建一个新的进程分配给该应用，这个启动方式就是冷启动，下文讲述的APP启动流程属于冷启动；
-   热启动：当启动应用时，后台已有该应用的进程（例：按back键、home键，应用虽然会退出，但是该应用的进程是依然会保留在后台，可进入任务列表查看），所以在已有进程的情况下，这种启动会从已有的进程中来启动应用，这个方式叫热启动；
-   一个APP就是一个单独的进程，对应一个单独的Dalvik虚拟机；[Android Runtime (ART) 和 Dalvik  |  Android 开源项目  |  Android Open Source Project](https://source.android.com/docs/core/runtime?hl=zh-cn)
-   Launcher：我们打开手机桌面，手机桌面其实就是一个系统应用程序，这个应用程序就叫做“Launcher”。同样的，下拉菜单其实也是一个应用程序，叫做“SystemUI”；
-   Binder：跨进程通讯的一种方式。
-   Zygote：Android系统基于Linux内核，当Linux内核加载后会启动一个叫“init”的进程，并fork出“Zygote”进程。Zygote意为“受精卵”，无论是系统服务进程，如ActivityManagerService、PackageManagerService、WindowManagerService等等，还是用户启动的APP进程，都是由Zygote进程fork出来的；
-   system_server：系统服务进程，也是Zygote进程fork出来的。该进程和Zygote进程是Android系统中最重要的两个进程，系统服务ActivityManagerService、PackageManagerService、WindowManagerService等等都是在system_server中启动的；
-   ActivityManagerService：活动管理服务，简称AMS，负责系统中所有的Activity的管理；
-   App与AMS通过Binder进行跨进程通信，AMS与Zygote通过Socket进行跨进程通信；
-   Instrumentation：主要用来监控应用程序和系统的交互，是完成对Application和Activity初始化和生命周期的工具类。每个Activity都持有Instrumentation对象的一个引用，但是整个进程只会存在一个Instrumentation对象；
-   ActivityThread：依赖于UI线程，ActivityThread不是指一个线程，而是运行在主线程的一个对象。App和AMS是通过Binder传递信息的，那么ActivityThread就是专门与AMS的外交工作的。ActivityThread是APP的真正入口，APP启动后从ActivityThread的main()函数开始运行；
-   ActivityStack：Activity在AMS的栈管理，用来记录经启动的Activity的先后关系，状态信息等。通过ActivtyStack决定是否需要启动新的进程；
-   ApplicationThread：是ActivityThread的内部类，是ActivityThread和ActivityManagerServie交互的中间桥梁。在ActivityManagerSevice需要管理相关Application中的Activity的生命周期时，通过ApplicationThread的代理对象与ActivityThread通信；

## 2.1 startActivity请求

系统启动过程中，会启动PMS服务，该服务会扫描解析系统中所有APP的AndroidManifest文件，在Launcher应用启动后，会将每个APP的图标和相关启动信息封装在一起。回想平时应用开发中，启动一个新的Activity是通过startAcitvity()方法。因此在桌面点击应用图标，也是在Luancher这个应用程序里面根据当前点击的APP的启动信息，执行startAcitvity()方法，通过Binder通信，最后调用ActivityManagerService的startActivity()方法。流程图如下：

![[Study Log/resources/Pasted image 20230704161238.png]]

## 2.2 Zygote fork新进程

![[Study Log/resources/Pasted image 20230704164058.png]]

当执行到startSpecificActivityLocked()方法时，会进行一次判断：

* 如果当前的程序已经有正在运行的Application，那么直接执行startActivity()即可；
* 如果并没有关联的进程，那么需要通过socket通道传递给Zygote进程，让它fork初一个新的进程来绑定这个Activity。

## 2.3 绑定Application

ActivityThread的main函数主要执行两件事情：

-   依次调用Looper.prepareLoop()和Looper.loop()来开启消息循环；
-   调用attach()方法，将给该新建的APP进程和指定的Application绑定起来；

## 2.4 启动Activity

经过2.2\~2.3后，系统就有了当前新APP的进程了，接下里的调用顺序就相当于从一个已经存在的进程中启动一个新的Actvity。因此回到2.2，如果当前Activity所在的Application有运行的话，就会执行realStartActivityLocked()方法，并调用scheduleLaunchActivity();

scheduleLaunchActivity()发送一个LAUNCH_ACTIVITY消息到消息队列中, 通过 handleLaunchActivity()来处理该消息。在 handleLaunchActivity()通过performLaunchActiivty()方法回调Activity的onCreate()方法和onStart()方法，然后通过handleResumeActivity()方法，回调Activity的onResume()方法，最终显示Activity界面。

![[Study Log/resources/Pasted image 20230704164706.png]]