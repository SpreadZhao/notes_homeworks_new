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

## Arch Font

Arch Linux 用的字体就是 Linux 内核的字体：[term](https://wiki.archlinux.org/title/Linux_console#Fonts)，名字叫`CONFIG_FONT_TER16x32`。字体的官网：[Terminus Font Home Page](https://terminus-font.sourceforge.net/)，字体的ttf版本：[Terminus Font](http://terminus-font.sf.net/)

## Mate Shortcut

我发现，按照之前 Ubuntu 的设置，把那两个导航快捷键干掉之后还是不行。所以我当时就怀疑还有其它的快捷键给拦截了。看一下 gsettings，可以发现它有查询的功能，按照下图查找：

![[Knowledge/software_qa/resources/Pasted image 20240513143038.png]]

发现果然有。把这两个也干掉之后，log out一下再回来就没问题了。

## DWM

彻底配置一遍 Arch Linux + DWM。

### DWM 准备工作

首先，dwm最好用xinit启动，同时一些资源需要读取x的数据库。所以安装：

```
xorg-xinit xorg-xrdb
```

#### 缩放

整体的缩放也要调，就是 100\%, 200\% 之类的。dwm 读取的也是 X Resources 的内容，所以参考：

- [X resources - ArchWiki](https://wiki.archlinux.org/title/X_resources#xinitrc)
- [HiDPI - ArchWiki](https://wiki.archlinux.org/title/HiDPI#X_Resources)

在`~/.Xresources`里加入：

```Xresources
Xft.dpi: 192
```

然后在`~/.xinitrc`里：

```shell
[[ -f ~/.Xresources ]] && xrdb -merge -I$HOME ~/.Xresources
```

#### 自启动

[xinit - ArchWiki](https://wiki.archlinux.org/title/xinit#Autostart_X_at_login)

对于zsh，有一个profile：

- `/etc/zsh/zprofile` Used for executing commands at start for all users, will be read when starting as a _**login shell**_. Please note that on Arch Linux, by default it contains [one line](https://gitlab.archlinux.org/archlinux/packaging/packages/zsh/-/blob/main/zprofile) which sources `/etc/profile`. See warning below before wanting to remove that!
    - `/etc/profile` This file should be sourced by all POSIX sh-compatible shells upon login: it sets up `$PATH` and other environment variables and application-specific (`/etc/profile.d/*.sh`) settings upon login.

在`~/.zprofile`中加入：

```shell
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
  exec startx
fi
```

> 空格不能省，不然报语法错误；`-z` 表示字符串判空，这里的意思是，环境变量`$DISPLAY`没有定义的时候为true。

设置到这里，还是差一步，我们在login的时候zsh会执行`.zprofile`的内容，从而调用`startx`，这个时候就会执行`.xinitrc`里的内容，导入rdb的资源。最后还差的就是真正启动dwm：

```shell
exec dwm
```

#### 多显示器

多显示器：[xrandr - ArchWiki](https://wiki.archlinux.org/title/xrandr)。我用的前端是arandr。

#### 状态栏

参考[suckless](https://dwm.suckless.org/tutorial/)，状态栏可以用xsetroot修改，所以需要安装`xorg-xsetroot`。显示电量并且修改的话参考[Advanced Linux Sound Architecture - ArchWiki](https://wiki.archlinux.org/title/Advanced_Linux_Sound_Architecture)，安装`alsa-utils`工具。在`~/.xinitrc`里加入这个脚本，这样在startx之后会执行：

```shell
#!/bin/bash
# Taken from:
#	https://raw.github.com/kaihendry/Kai-s--HOME/master/.xinitrc
#

xrdb -merge $HOME/.Xresources

while true
do
	VOL=$(amixer get Master | tail -1 | sed 's/.*\[\([0-9]*%\)\].*/\1/')
	LOCALTIME=$(date "%H:%M +%Y-%m-%d")
	OTHERTIME=$(TZ=Europe/London date +%Z\=%H:%M)
	IP=$(for i in `ip r`; do echo $i; done | grep -A 1 src | tail -n1) # can get confused if you use vmware
	TEMP="$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))C"

	if acpi -a | grep off-line > /dev/null
	then
		BAT="Bat. $(acpi -b | awk '{ print $4 " " $5 }' | tr -d ',')"
		xsetroot -name "$BAT $VOL $TEMP $LOCALTIME"
	else
		xsetroot -name "$VOL $TEMP $LOCALTIME"
	fi
	sleep 20s
done &

exec dwm
```

> 该脚本改编自[suckless tutorial最后的Status](https://dwm.suckless.org/tutorial/)里面的[xinitrc](https://dwm.suckless.org/tutorial/xinitrc.example)。

当然，上面只是一个实例，我自己优化之后的版本：

```shell
#!/bin/bash
# Taken from:
#	https://raw.github.com/kaihendry/Kai-s--HOME/master/.xinitrc
#

xrdb -merge $HOME/.Xresources

while true
do
	VOL="🔈 $(amixer get Master | tail -1 | sed 's/.*\[\([0-9]*%\)\].*/\1/')"
	LOCALTIME=$(date "+%H:%M %Y-%m-%d") 
	OTHERTIME=$(TZ=Europe/London date +%Z\=%H:%M)
	IP=$(for i in `ip r`; do echo $i; done | grep -A 1 src | tail -n1) # can get confused if you use vmware
	TEMP="$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))C"

	if [[ $(acpi -a | awk '{ print $3 }') = "on-line" ]]; then
		BATPRE="🔌"
	else
		BATPRE="🔋"
	fi
	BAT="$BATPRE $(acpi -b | awk '{ print $4 }' | tr -d ',')"
	xsetroot -name "$BAT | $VOL | $LOCALTIME"
	sleep 20s
done &

exec dwm
```

### DWM 源码修改

字体，在`config.h`里修改：

```c
static const char *fonts[] = { "Terminus (TTF):size=18" };
static const char dmenufont[] = "Terminus (TTF):size=18";
```

st的字体也需要单独设置，默认给的pixelsize，改成size才是跟随缩放的：

```c
/*
 * appearance
 *
 * font: see http://freedesktop.org/software/fontconfig/fontconfig-user.html
 */
static char *font = "Terminus (TTF):size=12:antialias=true:autohint=true";
```