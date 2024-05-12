---
title: Arch Linux
date: 2024-04-26
tags:
  - softwareqa/linux
mtrace:
  - 2024-04-26
---

# Arch Linux

安装archlinux + kde遇到的傻逼事情。

[Installation guide - ArchWiki (archlinux.org)](https://wiki.archlinux.org/title/installation_guide)

## 开启网卡

```shell
ip link set _<设备名>_ up
```

## 中文

中文显示：`/etc/locale.gen`里面把中文加上重启就行，其它的不要搞。然后，需要`locale-gen`，并且是已经安装了中文字体的前提。

[简体中文本地化 - Arch Linux 中文维基](https://wiki.archlinuxcn.org/wiki/%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87%E6%9C%AC%E5%9C%B0%E5%8C%96)

中文输入法：[Fcitx5 - Arch Linux 中文维基](https://wiki.archlinuxcn.org/wiki/Fcitx5)

- [fcitx5-im](https://archlinux.org/groups/x86_64/fcitx5-im/)
- [fcitx5-chinese-addons](https://archlinux.org/packages/?name=fcitx5-chinese-addons)

之后Input Method里面加Pinyin就行了：

![[Knowledge/software_qa/resources/Pasted image 20240427183710.png]]

## 安装流程

大致安装流程：

- 下载ISO；
- 进入；
- 联网，iwctl
- archinstall
	- 安装 dhcpcd iwd
	- 装NetworkManager
- 进入，再次联网， **ip link set ... up**
- 安装plasma sddm

具体的安装流程：

进入镜像之后，先联网：

> 进入镜像失败，我遇到了这个：[############### INIT NOT FOUND ############### : r/linuxmint (reddit.com)](https://www.reddit.com/r/linuxmint/comments/18eohux/init_not_found/)使用GRUB2模式启动就好了。

```shell
iwctl
```

使用iwctl进行链接。使用说明：[iwd - ArchWiki (archlinux.org)](https://wiki.archlinux.org/title/Iwd#iwctl)

直接连：

```shell
station <name> connnect <SSID>
```

比如，name通常是wlan0，ssid就是wifi的名字。也可以扫描一下。具体的使用wiki里都有。

然后archinstall，选自己喜欢的就好。我这里不知道为什么linux内核不能换，只能用默认的内核。

我没加任何额外的包，因为我装了NetworkManager，之后用这个联网就啥都能装了。

## 终端代理

终端需要设置代理，在随便一个脚本比如`.zshrc`里

```shell
export http_proxy=127.0.0.1:7897
export https_proxy=$http_proxy
export ftp_proxy=$http_proxy
export rsync_proxy=$http_proxy
export no_proxy="localhost,127.0.0.1"
```

后面的7897是clash端口。

[代理服务器 - Arch Linux 中文维基 (archlinuxcn.org)](https://wiki.archlinuxcn.org/wiki/%E4%BB%A3%E7%90%86%E6%9C%8D%E5%8A%A1%E5%99%A8)

## copyq, flameshot 不支持 wayland

copyq的快捷键和tray，flameshot的pin，都不支持wayland。所以最后用的x11。

## 显示器白屏还闪

连接显示器会白屏还会闪。用的 AMD 的 GPU，参考 [AMDGPU - ArchWiki](https://wiki.archlinux.org/title/AMDGPU#Screen_flickering_white_when_using_KDE) ，我用的是 grub。所以在`/etc/default/grub`的`GRUB_CMDLINE_LINUX_DEFAULT`加入`amdgpu.sg_display=0`。加完就像下面这样：

```config
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet amdgpu.sg_display=0"
```

然后 `grub-mkconfig -o /boot/grub/grub.cfg`，重启。验证的话，重启之后输入：

```shell
cat /proc/cmdline
```

结果样例：

```shell
BOOT_IMAGE=/vmlinuz-linux-lts root=UUID=c117dfc0-be87-46b6-b5fd-95995e77fda3 
rw zswap.enabled=0 rootfstype=ext4 loglevel=3 quiet amdgpu.sg_display=0
```

## pacman \& yay tips

- [pacman/Tips and tricks - ArchWiki](https://wiki.archlinux.org/title/Pacman/Tips_and_tricks#Removing_unused_packages_(orphans))
- [pacman - ArchWiki](https://wiki.archlinux.org/title/Pacman)
- [Jguer/yay: Yet another Yogurt - An AUR Helper written in Go](https://github.com/Jguer/yay)

## 稳定内核

[Arch Linux 更换到稳定版LTS内核 – 寻](https://poemdear.com/2019/03/27/arch-linux-%E6%9B%B4%E6%8D%A2%E5%88%B0%E7%A8%B3%E5%AE%9A%E7%89%88lts%E5%86%85%E6%A0%B8/)

## Grub Font Size

[HiDPI - ArchWiki](https://wiki.archlinux.org/title/HiDPI#Change_GRUB_font_size)

## SysRq

- [Keyboard shortcuts - ArchWiki](https://wiki.archlinux.org/title/Keyboard_shortcuts#Enabling)
- [Linux Magic System Request Key Hacks — The Linux Kernel documentation](https://docs.kernel.org/admin-guide/sysrq.html)
- [Magic SysRq key - Wikipedia](https://en.wikipedia.org/wiki/Magic_SysRq_key)