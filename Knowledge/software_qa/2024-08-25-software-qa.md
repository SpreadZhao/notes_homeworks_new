---
title: 解决IntellIJ产品无法输入中文
date: 2024-08-25
tags: 
mtrace: 
  - 2024-08-25
---

# 解决IntellIJ产品无法输入中文

我用的是fctix5，按照[[Knowledge/software_qa/2024-04-26-software-qa#中文|2024-04-26-software-qa]]里的安装。但是在IntellIJ的产品里，包括Android Studio，都无法输入中文。最后的解决方式是按照[Fcitx5 - Arch Linux 中文维基](https://wiki.archlinuxcn.org/wiki/Fcitx5#X11)里的方法，在`/etc/environment`里添加：

```
GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
INPUT_METHOD=fcitx
GLFW_IM_MODULE=ibus
```

这样之后就可以输入中文了。