---
title: Android Studio下载慢的真正原因
date: 2024-01-10
---

# Android Studio下载慢的真正原因

#date 2024-01-10

从网上看到的，所有的Android Studio下载Gradle wrapper慢的原因，都是因为什么外网访问慢，让你换成国内的镜像。

外网确实慢，但是我有梯子啊！为什么还是走不到？我当时就在疑惑，是不是因为Android Studio根本没走本地的代理。现在看果然是这样，而且设置也非常简单。首先看你代理的本地端口号：

![[Study Log/android_study/android_dev_trouble/resources/Pasted image 20240110215342.png]]

然后，在Android Studio的设置里，设置本机的ip，然后填上代理的端口：

![[Study Log/android_study/android_dev_trouble/resources/Pasted image 20240110215517.png]]

同时，还可以点下面的Check connection来测试代理是否跑通。

最后提一嘴，Clash上不用开LAN，你这是本机，又不是局域网，还NM没网呢。。。