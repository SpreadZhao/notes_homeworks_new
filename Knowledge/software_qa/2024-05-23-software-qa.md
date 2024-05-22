---
title: GitHub CLI
date: 2024-05-23
tags:
  - softwareqa/git
mtrace:
  - 2024-05-23
---

# GitHub CLI

 GitHub有一个非常好的功能：GitHub CLI，用来帮助你验证一些乱七八糟的东西，比如 Access Token。我最近又遇到了ssh无法push pull clone的问题，还没试[[Knowledge/software_qa/2024-01-21-software-qa|2024-01-21-software-qa]]的方法，就想直接用 HTTPS 了。参考这个：[Caching your GitHub credentials in Git - GitHub Docs](https://docs.github.com/en/get-started/getting-started-with-git/caching-your-github-credentials-in-git#github-cli)安装 GitHub CLI，然后：

```shell
gh auth login
```

然后选HTTPS协议，按照提示来就行了。这样之后push和pull的时候就不会每次都要你输入用户名和 Access Token 了。