---
title: ArchLinux Installation
date: 2024-04-26
tags:
  - softwareqa/linux
mtrace:
  - 2024-04-26
---

# ArchLinux Installation

安装archlinux + kde遇到的傻逼事情。

[Installation guide - ArchWiki (archlinux.org)](https://wiki.archlinux.org/title/installation_guide)

```shell
ip link set _<设备名>_ up
```

---

中文显示：`/etc/locale.gen`里面把中文加上重启就行，其它的不要搞。然后，需要`locale-gen`，并且是已经安装了中文字体的前提。

[简体中文本地化 - Arch Linux 中文维基](https://wiki.archlinuxcn.org/wiki/%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87%E6%9C%AC%E5%9C%B0%E5%8C%96)

中文输入法：[Fcitx5 - Arch Linux 中文维基](https://wiki.archlinuxcn.org/wiki/Fcitx5)

- [fcitx5-im](https://archlinux.org/groups/x86_64/fcitx5-im/)
- [fcitx5-chinese-addons](https://archlinux.org/packages/?name=fcitx5-chinese-addons)

之后Input Method里面加Pinyin就行了：

![[Knowledge/software_qa/resources/Pasted image 20240427183710.png]]

---

大致安装流程：

- 下载ISO；
- 进入；
- 联网，iwctl
- archinstall
	- 安装 dhcpcd iwd
	- 装NetworkManager
- 进入，再次联网， **ip link set ... up**
- 安装plasma sddm

---

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

---

copyq的快捷键和tray，flameshot的pin，都不支持wayland。所以最后用的x11。