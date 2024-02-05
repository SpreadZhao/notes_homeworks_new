---
title: 导航快捷键-Ubuntu; vscode-obsidian产生的空行
date: 2024-02-05
tags:
  - softwareqa/linux
  - softwareqa/obsidian
mtrace:
  - 2024-02-05
---

# 导航快捷键-Ubuntu

#date 2024-02-05

首先，`ctrl + alt + <-`和`ctrl + alt + ->`在Ubuntu中是被占用了的。先干掉它：

[gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right &quot;\[''\]&quot;](https://askubuntu.com/questions/82007/how-do-i-disable-ctrlaltleft-right)

```shell
 gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['']"
 gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['']"
```

干掉之后，就可以在IDEA中之类的设置了。

![[Knowledge/software_qa/resources/Pasted image 20240205142041.png]]

后来我发现，它其实就是系统里的这两个快捷键。但是之前设置的默认值也不是`ctrl + alt + <-`和`ctrl + alt + ->`。就挺奇怪的。

# VSCode - Obsidian

[从visual studio code复制代码后 产生的unicode的空格问题 - 疑问解答 - Obsidian 中文论坛](https://forum-zh.obsidian.md/t/topic/9332)