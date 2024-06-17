---
title: ADB insufficient permissions
date: 2024-06-17
tags: 
mtrace: 
  - 2024-06-17
---

# ADB insufficient permissions

和[[Study Log/android_study/android_dev_trouble/2024-02-04-android-dev-trouble|2024-02-04-android-dev-trouble]]类似的问题。启动的时候报这个错误：

```shell
❯ adb start-server
* daemon not running; starting now at tcp:5037
"ADB server didn't ACK"
Full server startup log: /tmp/adb.1000.log
Server had pid: 18677
--- adb starting (pid 18677) ---
06-17 18:39:00.076 18677 18677 I adb     : main.cpp:63 Android Debug Bridge version 1.0.41
06-17 18:39:00.076 18677 18677 I adb     : main.cpp:63 Version 35.0.1-11580240
06-17 18:39:00.076 18677 18677 I adb     : main.cpp:63 Installed as /home/spreadzhao/Android/Sdk/platform-tools/adb
06-17 18:39:00.076 18677 18677 I adb     : main.cpp:63 Running on Linux 6.6.33-1-lts (x86_64)
06-17 18:39:00.076 18677 18677 I adb     : main.cpp:63 
06-17 18:39:00.078 18677 18677 I adb     : auth.cpp:416 adb_auth_init...
06-17 18:39:00.078 18677 18677 I adb     : auth.cpp:152 loaded new key from '/home/spreadzhao/.android/adbkey' with fingerprint B49ECCA55A02F9D7F709C6F57398C69B04D3866E0559361FF52D64D1697D40E4
06-17 18:39:00.078 18677 18677 I adb     : auth.cpp:391 adb_auth_inotify_init...
06-17 18:39:01.078 18677 18677 E adb     : usb_libusb.cpp:571 failed to open device: Access denied (insufficient permissions)
06-17 18:39:01.078 18677 18677 I adb     : transport.cpp:1150 38101FDJH004N6: connection terminated: failed to open device: Access denied (insufficient permissions)

* failed to start daemon
error: cannot connect to daemon
```

说没有权限。所以自然我可以加上sudo启动。但是这样肯定是不对的。

解决方法在这里找到的：[SOLVED ADB gives out an error on Linux mint - Linux Mint Forums](https://forums.linuxmint.com/viewtopic.php?t=417944)

很奇怪，把usb改成文件传输确实解决了。但是以前没这样过，记录一下。

另外，系统是：

```shell
                   -`                    spreadzhao@spread-arch 
                  .o+`                   ---------------------- 
                 `ooo/                   OS: Arch Linux x86_64 
                `+oooo:                  Host: MS-7D20 1.0 
               `+oooooo:                 Kernel: 6.6.33-1-lts 
               -+oooooo+:                Uptime: 5 hours, 57 mins 
             `/:-:++oooo+:               Packages: 687 (pacman) 
            `/++++/+++++++:              Shell: zsh 5.9 
           `/++++++++++++++:             Resolution: 2560x1080 
          `/+++ooooooooooooo/`           DE: MATE 1.28.0 
         ./ooosssso++osssssso+`          WM: Metacity (Marco) 
        .oossssso-````/ossssss+`         Theme: BlackMATE [GTK2/3] 
       -osssssso.      :ssssssso.        Icons: mate [GTK2/3] 
      :osssssss/        osssso+++.       Terminal: mate-terminal 
     /ossssssss/        +ssssooo/-       Terminal Font: ComicShannsMono Nerd Font 15 
   `/ossssso+/:-        -:/+osssso+-     CPU: Intel i5-10400F (12) @ 4.300GHz 
  `+sso+:-`                 `.-/+oso:    GPU: NVIDIA GeForce GTX 1650 
 `++:.                           `-/+/   Memory: 7868MiB / 31995MiB 
 .`                                 `/
```