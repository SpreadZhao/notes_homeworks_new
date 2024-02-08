---
title: Obsidian的YAML中的List空的表示; Git同步失败
date: 2024-01-28
tags:
  - "#softwareqa/obsidian"
  - softwareqa/git
mtrace:
  - 2024-01-28
---

# Obsidian的YAML中的List空的表示

#date 2024-01-28

偶然间观察到，obsidian的YAML，如果类型为list，那么如果什么元素都没有的话，是这么表示的：

```yaml
title: Obsidian的YAML中的List空的表示
date: 2024-01-28
tags:
  - "#softwareqa/obsidian"
mtrace: []
```

上面的mtrace就是。而如果list有了元素，那么就会变成像tags那样的格式。为啥要这样呢？很简单。**如果没有元素的话，你咋知道这个属性是什么类型**？所以写一个空的中括号，用来表示这是一个list类型的属性，但是现在是空的。包括tags也是一样的逻辑。如果是空的话，也是一个中括号。

# Git同步失败

其实和之前[[Knowledge/software_qa/2024-01-21-software-qa#ssh去clone仓库，失败？？？|2024-01-21-software-qa]]的现象类似，都是push失败。但是现在的问题是，我使用GitHub Desktop可以push，但是使用自己的IDE就不行。我观察到，自己的IDE实际上就是在执行git命令行，所以，我猜测应该是命令行没有配置代理。最后发现果然是这样，给当前的仓库写一个配置：

```shell
git config http.proxy 127.0.0.1:7890
git config https.proxy 127.0.0.1:7890
```

没有加`--global`，默认就是本地的配置。我们可以通过下面的命令看配置是否生效：

```shell
git config -e
```

结果是这样的：

```
[core]
	repositoryformatversion = 0
	filemode = false
	bare = false
	logallrefupdates = true
	symlinks = false
	ignorecase = true
[submodule]
	active = .
[remote "origin"]
	url = https://github.com/SpreadZhao/KotlinStudy.git
	fetch = +refs/heads/*:refs/remotes/origin/*
[branch "master"]
	remote = origin
	merge = refs/heads/master
[lfs]
	repositoryformatversion = 0
[http]
	proxy = 127.0.0.1:7890
[https]
	proxy = 127.0.0.1:7890
```

这实际上就是仓库里`.git/config`文件。这样我们就配置成功了，之后再push也就没问题了。