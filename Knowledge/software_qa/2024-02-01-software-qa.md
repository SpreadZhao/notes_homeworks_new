---
title: Ubuntu Things 2
date: 2024-02-01
tags:
  - softwareqa/linux
mtrace:
  - 2024-02-01
---

# Add/Remove icons in "Launcher"

#date 2024-02-01

Firstly, let us call this as **Launcher**: 

![[Knowledge/software_qa/resources/Pasted image 20240201111843.png]]

How to add or remove icons in it? All of its icons are contained in path `/usr/share/applications` which contains `.desktop` files:

![[Knowledge/software_qa/resources/Pasted image 20240201112047.png]]

All you need to do is add one `.desktop` file **pointing to the real program you would like to launch**. Such as:

```shell
[Desktop Entry]
Encoding=UTF-8
Name=Android Studio
Comment=Android Studio
Exec=/home/spreadzhao/Applications/android-studio/bin/studio.sh    # where is the program?
Icon=/home/spreadzhao/Applications/android-studio/bin/studio.png   # where is the icon of app?
Terminal=false
StartupNotify=true
Type=Application
Categories=Application;Development;
```

Also, by looking into the file, you can recognize the icons in the Launcher and remove it at your need.

# Ubuntu中文输入法

[Add / Remove a Folder to $PATH variable in Ubuntu 22.04 - FOSTips](https://fostips.com/add-to-path-ubuntu/)

# Ubuntu PATH

[Add / Remove a Folder to $PATH variable in Ubuntu 22.04 - FOSTips](https://fostips.com/add-to-path-ubuntu/)

上面的网址是一些常见的PATH变量所处的位置。但是我装了zsh，所以可以直接在.zshrc里面添加环境变量：

```shell
export PATH=:$PATH:/home/spreadzhao/Android/Sdk/platform-tools
```

这样就把adb添加到环境变量里了。

# What is keyring and how to control it?

* [如何在 Ubuntu 桌面上禁用默认密钥环输入密码解锁](https://cn.linux-console.net/?p=9148)
* [Copy URL To Clipboard](https://chromewebstore.google.com/detail/copy-url-to-clipboard/miancenhdlkbmjmhlginhaaepbdnlllc)

# 在Linux上拷贝网页链接带标题

现在我是用插件实现的：

* 老版商店：[复制链接到剪贴板 - Chrome 网上应用店](https://link.zhihu.com/?target=https%3A//chrome.google.com/webstore/detail/copy-url-to-clipboard/miancenhdlkbmjmhlginhaaepbdnlllc/related%3Fhl%3Dzh-CN "")
* 新版商店：[Copy URL To Clipboard](https://chromewebstore.google.com/detail/copy-url-to-clipboard/miancenhdlkbmjmhlginhaaepbdnlllc "Copy URL To Clipboard")

之后在设置里把快捷键设置上：

![[Knowledge/software_qa/resources/Pasted image 20240201141330.png]]

# 卸载Firefox

[在 Ubuntu 22.04 中卸载 Firefox](https://cn.linux-console.net/?p=13996)