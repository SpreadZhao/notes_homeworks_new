欢迎来到Spread Zhao的笔记仓库！**这里是我所有知识的积累，并且会持续更新下去**！使用前请先看[[#2023-01-30|最基本的设置]]！！！

有关每个文件夹的定义，可以到各个文件夹的`README`文件去查看，这里给出所有的课堂笔记：

```dataview
table description, link
from "/"
where category="inter_class"
```

然后是所有的课外笔记：

```dataview
table description, link
from "/"
where category = "self_study"
```

接下来列出所有的README文件，它们对你理解每个文件夹的内容有帮助

```dataview
table file.path as Path
from "/"
where file.name = "README"
```

> *以上查询使用了DataView插件，版本在下面。*

**==对于仓库内部细节的更新，我会以日记的形式更新在这下面==**，每一天的日记都会以横线分割。另外，介绍一下这个仓库中常用的标签，**它们有可能会并列出现**：

#TODO 这是我还没有完成的任务，可以是对仓库的更新任务；也可以是学习过程中立下的目标。这个标签下面紧跟着的就是各种任务的集合，就是`- [x]`这种形式。

#question 这是在任何时刻遇到的各种问题。有时是老师抛出来的，有时是我自己想到的；如果已经有了答案，会在下面直接给出。

#example 这是课上老师给的例题。

#homework 这是嵌在笔记中的作业题。通常是单独的一个标题，只是会在下面加上这样的标签。

#poe Point On Exam。这是考试有可能出现的考点

#idea 这是我突发奇想的点子，或者是一些我认为比较重要的东西。

#keypoint 关键点，任何可能的重点/难点都会使用此标签。

#rating Difficulty level for problems:

* #rating/basic
* #rating/medium 
* #rating/high

#date Exists after every title with the date format *mostly*. Because I have no reason to write every date-related articles in diary, so I have to put a tag to remember this.

#diary Just like what it looks like.

#emergency Emergency for techiques to learn:

* #urgency/low 
* #urgency/medium
* #urgency/high

# 日记维护流程

**如果文件需要添加进日记中，需要按照如下流程操作**。

新日记步骤：

1. 创建新的文档，并执行[[templates/update_mtrace|update_mtrace]]更新修改日期；
2. 新建日记，使用[[templates/diary|diary]]模板；
3. **在修改的模块上添加标签** #date YYYY-MM-DD

更新日期步骤：

1. 在当前文档执行[[templates/update_mtrace|update_mtrace]]更新修改日期；
2. **在修改的模块上添加标签** #date YYYY-MM-DD

```ad-note
emm，加标签只是为了区分你改了什么地方。不想改不加也行。对于一些疑难杂症却又很琐碎的小问题，就非常需要加上日期tag。这里我推荐直接用模板[[templates/date_title_with_tag|date_title_with_tag]]
```

---

# 2022-10-17

#date 2022-10-17

本仓库使用obsidian搭建，并且融合进了HappySE的仓库。关于HappySE仓库的作者信息如下：

[[Happy-SE-in-XDU-master/README]]

本仓库使用的obsidian第三方插件如下：

![[Pasted image 20221017125039.png]]

如果以后有更新也会在此文件中说明。由于我将`.obsidian`文件夹放在了`.gitignore`中(这是为了同步的方便)，所以诸如第三方插件这样的配置需要靠自己去搞定\~\~

**我是SpreadZhao，来自西电的一名码农。**

---

# 2022-10-18

#date 2022-10-18

新增了插件：

![[Pasted image 20221018121850.png]]

---

# 2022-10-19 

#date 2022-10-19

导出pdf的样式丑的要死，怀疑是1.0版本升级之后改成这个样子。解决办法参见[[software_qa#3.1 pdf导出|这里]]，但是解决成这样还是不太好看。

---

# 2022-10-21

#date 2022-10-21

增加了插件：

![[Pasted image 20221021211952.png]]

另外DataView插件要进行如下设置：

![[Pasted image 20221022185115.png]]

不然会和某些代码段冲突。

---

# 2022-11-10

#date 2022-11-10

由于引入了yaml模板，所以在Obsidian中要进行如下设置应用模板：

![[Pasted image 20221110232507.png]]

---

# 2022-11-21

#date 2022-11-21

增加了插件，下面给出目前的所有插件：

![[resources/Pasted image 20221121123025.png]]

另外给出文件链接的新设置，今天之后插入的连接也都是这种格式。

#TODO Update Link

- [ ] 将所有的图片都改成这种格式

![[resources/Pasted image 20221121161025.png]]

---

# 2022-11-24

#date 2022-11-24

如何使用本仓库？其实非常简单。

首先，去下面的网址下载obsidian：

[Obsidian](https://obsidian.md/)

![[resources/Pasted image 20221124143144.png]]

点击`Get Obsidian fo Windows`即可。下载安装完之后，会打开这样一个窗口：

![[resources/Pasted image 20221124143223.png]]

一个仓库说白了就是一个文件夹。那么我们只需要把我的仓库下下来然后选择打开本地仓库，就欧克了！

首先来到我的仓库地址：

[notes_homeworks: 之前的笔记仓库已经弃用，从Typora转为了Obsidian (gitee.com)](https://gitee.com/spreadzhao/notes_homeworks)

在里面你能够找到这个按钮：

![[resources/Pasted image 20221124143355.png]]

点击这个复制，这就是本项目的仓库地址。我们用这个地址把仓库下载下来。

去这个地址下载git工具：

[Git - Downloads (git-scm.com)](https://git-scm.com/downloads)

![[resources/Pasted image 20221124143455.png]]

点击这个windows，之后点击下面的按钮：

![[resources/Pasted image 20221124143551.png]]

下载完安装即可。安装的过程可能会有一点漫长，不过不要紧，全部默认就ok了。在安装完之后，在任意一个文件夹下右键都能看到这个：

![[resources/Pasted image 20221124143649.png]]

`Git Bash Here`就是我们最常用的功能了。我们在随便一个文件夹里点击它，会出现一个类似cmd的窗口：

![[resources/Pasted image 20221124143751.png]]

我们在这里下载我的仓库。输入如下命令：

```shell
git clone https://gitee.com/spreadzhao/notes_homeworks.git
```

这里的地址就是之前复制的仓库地址。**但是注意粘贴的方式不一样**，在gitbash中粘贴的快捷键是`SHIFT + INSERT` ，而不是`CTRL + V`。如果找不到的话鼠标右键粘贴也行。

等待一段时间，仓库就下载好了，之后我们就要在obsidian中打开这个仓库：

![[resources/Pasted image 20221124144100.png]]

点击打开后，选择刚刚下载好的文件夹，就可以使用了！！！

另外，如果仓库有更新，就来到下载的仓库目录下，右键打开`Git Bash Here`，输入如下命令：

```shell
git pull
```

这样就会自动将仓库更新成最新的。

> 最好自己注册一个gitee的账号，有可能进行git操作的时候会让你登录。

# 2022-12-29

#date 2022-12-29

更新了插件：

![[resources/Pasted image 20221229144203.png]]

# 2023-01-24

#date 2023-01-24

想要正常工作，只需要DataView和Excalidraw插件即可：

![[resources/Pasted image 20230124231029.png]]

# 2023-01-30

#date 2023-01-30

**重大更新！！！**

将插件设置和Obsidian本体设置进行汇总，保证所有的工作正常。

**DataView**

![[resources/Pasted image 20230130001011.png]]

---

**Excalidraw**

![[resources/Pasted image 20230130001111.png]]

![[resources/Pasted image 20230130001127.png]]

---

**Obsidian**

![[resources/Pasted image 20230130001216.png]]

# 2023-05-02

#date 2023-05-02

We are now begin using The Minimal Theme for obsidian. These are the plugins related to it:

* [Minimal Theme Settings](https://minimal.guide/Plugins/Minimal+Theme+Settings) allows you to customize [color schemes](https://minimal.guide/Features/Color+schemes), fonts, [Hotkeys](https://minimal.guide/Features/Hotkeys), and theme features. This plugin is highly recommended for all users of Minimal
* [Contextual Typography](https://minimal.guide/Plugins/Contextual+Typography) is required for advanced layout features such as [Image grids](https://minimal.guide/Block+types/Image+grids) and [Block width](https://minimal.guide/Features/Block+width)
* [Style Settings](https://minimal.guide/Plugins/Style+Settings) allows you to create custom [Color schemes](https://minimal.guide/Features/Color+schemes)

Below is the settings for Style Settings:

```css
{
  "minimal-style@@h1-size": "1.8em",
  "minimal-style@@h1-color@@dark": "#D51A1A",
  "minimal-style@@h1-weight": 700,
  "minimal-style@@h2-size": "1.6em",
  "minimal-style@@h2-color@@dark": "#D58E06",
  "minimal-style@@h3-size": "1.4em",
  "minimal-style@@h3-color@@dark": "#5569C8",
  "minimal-style@@h4-size": "1.0em",
  "minimal-style@@h4-color@@dark": "#1C829D",
  "minimal-style@@h5-size": "1em",
  "minimal-style@@h6-size": "1em",
  "minimal-style@@h1-l": true,
  "minimal-style@@h1-variant": "normal",
  "minimal-style@@spacing-p": "0.3em",
  "minimal-style@@zoom-off": true,
  "minimal-style@@sidebar-lines-off": false,
  "minimal-style@@sidebar-tabs-style": "sidebar-tabs-underline",
  "minimal-advanced@@cursor": "default",
  "minimal-style@@italic-color@@dark": "#4BACC5",
  "minimal-style@@hl2@@dark": "#8C7E7E",
  "minimal-style@@bold-weight": 600,
  "minimal-style@@bold-color@@dark": "#C10202",
  "minimal-style@@italic-color@@light": "#4BACC5",
  "minimal-style@@h1-color@@light": "#D51A1A",
  "minimal-style@@h2-color@@light": "#D58E06",
  "minimal-style@@h3-color@@light": "#5569C8",
  "minimal-style@@h4-color@@light": "#1C829D",
  "minimal-style@@hl2@@light": "#8C7E7E",
  "minimal-style@@bold-color@@light": "#C10202"
}
```

All plugins now:

![[resources/Pasted image 20230502234456.png]]

![[resources/Pasted image 20230502234507.png]]

Also, we create a css to center the images which also works when exported to pdf files. See [[Knowledge/software_qa#3.4 Center Images|this]] for detail.

# 2023-05-03

#date 2023-05-03

New Sytle Settings:

```css
{
  "minimal-advanced@@cursor": "default",
  "minimal-style@@h1-size": "1.8em",
  "minimal-style@@h1-color@@dark": "#D51A1A",
  "minimal-style@@h1-weight": 700,
  "minimal-style@@h2-size": "1.6em",
  "minimal-style@@h2-color@@dark": "#D58E06",
  "minimal-style@@h3-size": "1.4em",
  "minimal-style@@h3-color@@dark": "#5569C8",
  "minimal-style@@h4-size": "1.0em",
  "minimal-style@@h4-color@@dark": "#1C829D",
  "minimal-style@@h5-size": "1em",
  "minimal-style@@h6-size": "1em",
  "minimal-style@@h1-l": true,
  "minimal-style@@h1-variant": "normal",
  "minimal-style@@spacing-p": "0.3em",
  "minimal-style@@zoom-off": true,
  "minimal-style@@sidebar-lines-off": false,
  "minimal-style@@sidebar-tabs-style": "sidebar-tabs-underline",
  "minimal-style@@italic-color@@dark": "#4BACC5",
  "minimal-style@@hl2@@dark": "#52511D",
  "minimal-style@@bold-weight": 600,
  "minimal-style@@bold-color@@dark": "#C10202",
  "minimal-style@@italic-color@@light": "#4BACC5",
  "minimal-style@@h1-color@@light": "#D51A1A",
  "minimal-style@@h2-color@@light": "#D58E06",
  "minimal-style@@h3-color@@light": "#5569C8",
  "minimal-style@@h4-color@@light": "#1C829D",
  "minimal-style@@hl2@@light": "#ACAA44",
  "minimal-style@@bold-color@@light": "#C10202"
}
```

# 2023-05-07

#date 2023-05-07

Now we can use our own css snippet to custimize our own style!!!

```css
.square-solid {
	border-style: solid;
	background-color: transparent !important;
}
.square-solid-red {
	border-style: solid;
	border-color: red;
	background-color: transparent !important;
}
.square-solid-yellow {
	border-style: solid;
	border-color: yellow;
	background-color: transparent !important;
}
.square-solid-blue {
	border-style: solid;
	border-color: blue;
	background-color: transparent !important;
}
```

The [[templates/square-solid|new template]] is also defined under the existance of this style.

# 2023-05-08

#date 2023-05-08

To make the text bordered remains its color, we should **interit the color style from its parent**:

```css
.square-solid {
	border-style: solid;
	background-color: transparent !important;
	color: inherit !important;
}
.square-solid-red {
	border-style: solid;
	border-color: red;
	background-color: transparent !important;
	color: inherit !important;
}
.square-solid-yellow {
	border-style: solid;
	border-color: yellow;
	background-color: transparent !important;
	color: inherit !important;
}
.square-solid-blue {
	border-style: solid;
	border-color: blue;
	background-color: transparent !important;
	color: inherit !important;
}
```

You will get such result which is more comforting:

![[resources/Pasted image 20230508235852.png]]

# 2023-05-28

#date 2023-05-28

Add DB Folder plugin.

![[resources/Pasted image 20230528010756.png]]

# 2023-08-14

#date 2023-08-14

* [[Knowledge/software_qa#3.10 Hide answers using Callout|Hide answers using Callout]]
* [[Knowledge/software_qa#3.9 Code block wrap|Disable Code block wrap]]

# 2023-08-15

#date 2023-08-15

Obsidian translucent window not working on editor screen. My Version:

![[resources/Pasted image 20230815140257.png]]

Solution:

[Is Translucent Window Broken? - Help - Obsidian Forum](https://forum.obsidian.md/t/is-translucent-window-broken/44965)

```css
.workspace-leaf,
.workspace-tab-header-container {
  background: transparent;
}

.workspace-split.mod-root,
.workspace-split.mod-root .view-content,
.workspace-split.mod-root .view-header {
  background: transparent;
}

.view-header-title-container:not(.mod-at-end):after {
  background: transparent;
}
```