---
title: ssh去clone仓库，失败？？？
date: 2024-01-21
tags:
  - "#softwareqa/ssh"
  - "#softwareqa/git"
---

# ssh去clone仓库，失败？？？

#date 2024-01-21

不知道怎么出现的。反正用ssh协议去clone仓库，去pull，就会有这样的情况：

```shell
ssh: connect to host github.com port 22: Connection timed out
```

当然，我是有ssh的key的。那这个问题就很奇怪了。我先试了试重新安装ssh的client和server，按照官网的教程：

[Get started with OpenSSH for Windows | Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=powershell)

但是没用。之后看到了这篇文章：

[git - ssh: connect to host github.com port 22: Connection timed out - Stack Overflow](https://stackoverflow.com/questions/15589682/ssh-connect-to-host-github-com-port-22-connection-timed-out)

我在我的`.ssh`目录里也新建了一个config，写了这些：

```
Host github.com
  Hostname ssh.github.com
  Port 443
```

然后执行：

```shell
ssh -T git@github.com
```

然后将自己的密钥认证一下，就成功了。之后再clone也没问题了。