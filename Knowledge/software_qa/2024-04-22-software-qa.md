---
title: VSCode
date: 2024-04-22
tags:
  - "#softwareqa/vscode"
mtrace:
  - 2024-04-22
---

## VSCode UTF-8 Highlight

[visual studio code - vscode The character U+0647 &quot;ه&quot; could be confused with the character U+006f &quot;o&quot;, which is more - Stack Overflow](https://stackoverflow.com/questions/70297324/vscode-the-character-u0647-%D9%87-could-be-confused-with-the-character-u006f-o)

![[Knowledge/software_qa/resources/Pasted image 20240422055324.png]]

## Code-OSS Official Extensions

[Can't Find certain extensions in CODE-OSS](https://stackoverflow.com/questions/64463768/cant-find-certain-extensions-in-code-ossopen-source-variant-of-visual-studio-c)

in Arch Linux, `product.json` is in `/usr/lib/code/product.json`, use

```shell
pacman -Ql code | grep "product.json"
```

to find it.