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