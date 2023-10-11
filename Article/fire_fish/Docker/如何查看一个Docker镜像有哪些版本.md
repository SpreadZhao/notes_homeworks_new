[TOC]

[`点击跳转：Docker安装MySQL、Redis、RabbitMQ、Elasticsearch、Nacos等常见服务全套（质量有保证，内容详情）`](https://blog.csdn.net/yuchangyuan5237/article/details/130866065)

本文介绍如何查看某个Docker镜像有哪些版本

# 1. 如何查看一个 Docker 镜像有哪些版本

因为通过 `docker search` 并不能查看某个镜像的版本信息，如我需要特定版本的 redis 那怎么办呢~

本文提供了如下几种方式，大家可以<mark>**分别逐个尝试下**</mark>~

> 为什么有几种方式呢，因为官方的查找镜像网址 Docker Hub 常常因为特殊原因无法访问，且在国内没有找到提供搜索服务的 Docker 代理点

> 如果朋友们知道国内哪里有 Docker 搜索服务提供商欢迎交流

## 方式 1，通过 Docker Hub

> 查看一个docker镜像所有版本的方法：1、进入dockerhub网站；2、搜索镜像名称；3、点击查看详情；4、点击Tags，即可看见所有的版本
> **注意**：可能因为国内网络限制原因无法访问

要想查看镜像的版本和TAG,需要在 docker hub 查看

地址如下：https://hub.docker.com

1、进入之后，在页面左上角搜索框搜索，例如搜索redis

2、点击查看详情

3、点击Tags，即可看见所有的版本

4、找到Tags 后，就可以根据需要的版本来下载了。如tags为6.2.5的版本

```shell
# 按照 Docker 的格式来拉取不同 tags 的 redis 镜像，用冒号隔开
docker pull redis:6.2.5
```

## 方式 2，通过官网看有没有命令

> 以 redis 为例

查看 redis 的安装章节，链接如下：

https://redis.io/download/

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-25-15-15-22-image.png)

遗憾的是官方还是让去 Docker Hub 上查找下载，还是可能因为网络原因无法完成

## 方式 3，通过尝试加版本号猜测

> 以 redis 为例：

我们从官网上知道了 redis 有 `6.2.5` 版本 和 `7.0.11` 版本，再结合 Docker 的规则(以:分割)，就可以猜测到拉取 redis 6.2.5 的命令如下：

```shell
# 从国内阿里镜像仓库拉取 redis 6.2.5 镜像
docker pull redis:6.2.5
# 从国内阿里镜像仓库拉取 redis 7.0.11 镜像
docker pull redis:7.0.11
```

尝试了下还真成功了，挺好，说明也是有迹可循的

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-25-15-25-10-image.png)

> 如果朋友们知道国内哪里有 Docker 搜索服务提供商欢迎交流

# 2. 参考资料

Docker 官方仓库：[https://hub.docker.com](https://hub.docker.com)

我的文章：[《如何查看一个Docker镜像有哪些版本.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《Docker设置国内镜像源.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《Docker快速入门实用教程.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《Docker安装MySQL、Redis、RabbitMQ、Elasticsearch、Nacos等常见服务.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

