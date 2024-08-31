---
title:
  - Awesome WM Issues
date: 2024-08-31
tags:
  - softwareqa/linux
  - wm/awesome
mtrace:
  - 2024-08-31
---

# Awesome WM Issues

## 窗口无法tile，也无法用鼠标移动

我注意到某一天，edge浏览器上多了个这样的标志：

![[Knowledge/software_qa/resources/Pasted image 20240831181101.png]]

一个加号，然后这个加号出现就导致：

- 窗口只能最大化，不能改大小；
- 只能float，不能tile。

我一开始以为是什么rule导致的，按照这篇文章改了一下：[Chromium Apps won't tile : r/awesomewm](https://www.reddit.com/r/awesomewm/comments/10pvpym/chromium_apps_wont_tile/)。但是没什么用，所以又搜了一下，终于找到了：

[unix.stackexchange.com/questions/44364/…](https://unix.stackexchange.com/questions/44364/how-to-maximise-a-window-horizontal-or-vertically)

所以这个➕的意思其实是maximized。我们只需要按`Mod4 + m`就可以取消掉了。