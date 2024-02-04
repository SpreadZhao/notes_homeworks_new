---
title: adb无法找到设备
date: 2024-02-04
tags:
  - "#question/coding/android/adb"
mtrace:
  - 2024-02-04
---

# adb无法找到设备

#date 2024-02-04

连接设备的时候是这样的：

![[Study Log/android_study/android_dev_trouble/resources/Pasted image 20240204163601.png]]

根据这篇文章：[Ubuntu adb 报错：no permissions (missing udev rules? user is in the plugdev group)；-CSDN博客](https://blog.csdn.net/weixin_43230861/article/details/119422383#commentBox)

一步步跟着来操作就成功了。主要的问题就是在`/etc/udev/rules.d`目录下存放的规则。新建一个规则，名字随便，然后里面把自己usb的信息填上去。执行：

```shell
lsusb
```

会输出如下信息：

```shell
Bus 008 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 007 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 006 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 005 Device 005: ID 18d1:4ee7 Google Inc. Nexus/Pixel Device (charging + debug)
Bus 005 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 004 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 003 Device 002: ID 174f:181e Syntek Integrated Camera
Bus 003 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 004: ID 0489:e0cd Foxconn / Hon Hai Wireless_Device
Bus 001 Device 003: ID 0c45:0520 Microdia MaxTrack Wireless Mouse
Bus 001 Device 006: ID 1532:007b Razer USA, Ltd RC30-0305 Gaming Mouse Dongle [Viper Ultimate (Wireless)]
Bus 001 Device 005: ID 1532:007e Razer USA, Ltd RC30-030502 Mouse Dock
Bus 001 Device 002: ID 2109:2210 VIA Labs, Inc. Hub
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
```

其中Bus005就是我的手机。

```rules
SUBSYSTEM=="usb",ATTRS{idVendor}=="18d1",ATTRS{idProduct}=="4ee7",MODE="0666",GROUP="plugdev",SYMLINK+="android",SYMLINK+="android_adb"
```

在这里面对应上Vendor和product的编号，就成功了。