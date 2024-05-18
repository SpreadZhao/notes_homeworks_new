---
title: zsh
date: 2024-03-28
tags:
  - softwareqa/linux
mtrace:
  - 2024-03-28
---

# zsh

* 安装zsh：[Installing ZSH · ohmyzsh/ohmyzsh Wiki](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH)
* 安装oh-my-zsh：[Oh My Zsh - a delightful &amp; open source framework for Zsh](https://ohmyz.sh/#install)
* 安装主题：[romkatv/powerlevel10k: A Zsh theme](https://github.com/romkatv/powerlevel10k)
* 安装建议插件：[zsh-autosuggestions/INSTALL.md at master · zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#oh-my-zsh)

```shell
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```