---
title: Linux好物清单; git仓库统计
date: 2024-02-08
tags:
  - softwareqa/linux
  - softwareqa/git
mtrace:
  - 2024-02-08
  - 2024-02-13
---
#date 2024-02-08

# Linux好物清单



* 截图：Flameshot + peek (gif)
* AppImage：[TheAssassin/AppImageLauncher: Helper application for Linux distributions serving as a kind of &quot;entry point&quot; for running and integrating AppImages](https://github.com/TheAssassin/AppImageLauncher)
* 邮件：Thunderbird：[Thunderbird — Free Your Inbox. — Thunderbird](https://www.thunderbird.net/en-GB/)
* #date 2024-02-13 历史剪切板：[CopyQ](https://hluk.github.io/CopyQ/)
* #date 2024-03-22 img to PDF: [gscan2pdf-2.13.2](https://gscan2pdf.sourceforge.net/)

# Git仓库统计

[GitStats - git history statistics generator](https://gitstats.sourceforge.net/)

[hoxu/gitstats: git history statistics generator](https://github.com/hoxu/gitstats)

这个东西很简单。clone下来，然后`sudo make install`就行。但是它需要`python2`和`gnuplot`才能工作。用法：

```shell
gitstats [options] <gitpath..> <outputpath>
```

其中`<outputpath>`就是一个网站。之后它会告诉你怎么打开，进去就能看统计情况了：

![[Knowledge/software_qa/resources/Pasted image 20240208183007.png|400]]

上图是我统计的一个例子。