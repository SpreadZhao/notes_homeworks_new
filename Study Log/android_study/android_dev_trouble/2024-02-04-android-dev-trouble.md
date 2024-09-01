---
title:
  - adb无法找到设备
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

一步步跟着来操作就成功了。主要的问题就是在`/etc/udev/rules.d`目录下存放的规则。新建一个规则，名字随便（[参考](https://wiki.archlinux.org/title/Udev#Allowing_regular_users_to_use_devices)），然后里面把自己usb的信息填上去。执行：

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

#date 2024-08-31

今天发现，原来的方法不管用了。用Arch Linux，启动adb的时候报错：

```shell
   ~ ❯ adb devices                                                                                      took   5s at   22:41:00
* daemon not running; starting now at tcp:5037
ADB server did not ACK
Full server startup log: /tmp/adb.1000.log
Server had pid: 16953
--- adb starting (pid 16953) ---
08-31 22:41:02.597 16953 16953 I adb     : main.cpp:63 Android Debug Bridge version 1.0.41
08-31 22:41:02.597 16953 16953 I adb     : main.cpp:63 Version 35.0.2-12147458
08-31 22:41:02.597 16953 16953 I adb     : main.cpp:63 Installed as /home/spreadzhao/Android/Sdk/platform-tools/adb
08-31 22:41:02.597 16953 16953 I adb     : main.cpp:63 Running on Linux 6.6.48-1-lts (x86_64)
08-31 22:41:02.597 16953 16953 I adb     : main.cpp:63
08-31 22:41:02.598 16953 16953 I adb     : auth.cpp:416 adb_auth_init...
08-31 22:41:02.598 16953 16953 I adb     : auth.cpp:152 loaded new key from '/home/spreadzhao/.android/adbkey' with fingerprint 0CE68F4765A4FFA3E8CB4DDEFCAF3802409A87E308E68EB5A453033BC3ED148F
08-31 22:41:02.598 16953 16953 I adb     : auth.cpp:391 adb_auth_inotify_init...
08-31 22:41:02.599 16953 16953 I adb     : udp_socket.cpp:170 AdbUdpSocket fd=23
08-31 22:41:02.599 16953 16953 I adb     : udp_socket.cpp:170 AdbUdpSocket fd=13
08-31 22:41:02.599 16953 16953 I adb     : udp_socket.cpp:274 SetMulticastOutboundInterface for index=4
08-31 22:41:02.599 16953 16953 I adb     : udp_socket.cpp:533 bind endpoint=0.0.0.0:5353
08-31 22:41:02.599 16953 16953 I adb     : udp_socket.cpp:274 SetMulticastOutboundInterface for index=4
08-31 22:41:02.599 16953 16953 I adb     : udp_socket.cpp:558 bind endpoint=[0000:0000:0000:0000:0000:0000:0000:0000]:5353 scope_id=0
08-31 22:41:03.643 16953 16953 E adb     : usb_libusb.cpp:598 failed to open device: Access denied (insufficient permissions)
08-31 22:41:03.643 16953 16953 I adb     : transport.cpp:1153 HA1F7JKP: connection terminated: failed to open device: Access denied (insufficient permissions)

* failed to start daemon
adb: failed to check server version: cannot connect to daemon
```

没有权限。显然可以加sudo解决。但是我不想这么干。我找了很多资料都没发现到底是为什么。

我现在弄好的方法是，确保`lsusb`的输出：

```shell
Bus 005 Device 008: ID 18d1:4ee2 Google Inc. Nexus/Pixel Device (MTP + debug)
```

里面的信息和`/etc/udev/rules.d/`里文件的内容是一样的。我的文件现在是：

```rules
SUBSYSTEM=="usb",ATTRS{idVendor}=="18d1",ATTRS{idProduct}=="4ee2",MODE="0666",GROUP="plugdev",SYMLINK+="android",SYMLINK+="android_adb"
```

然后多试几次就行了。但是很奇怪，根据我找到的[资料](https://stackoverflow.com/questions/28704636/insufficient-permissions-for-device-in-android-studio-workspace-running-in-opens#comment45742469_28724457)，需要把`plugdev`用户组添加到系统里才可以。但是我找了我的用户组，[[Study Log/android_study/android_dev_trouble/resources/Pasted image 20240831225443.png|完全没找到]]。所以不知道到底是为什么。如果后面发现了就确定一下吧。就不记todo了。

补充一下，我的pixel需要如下条件：

1. rules生效；
2. usb连接模式必须调成文件传输（MTP）。