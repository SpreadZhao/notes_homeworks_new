[TOC]

[`点击跳转：Docker安装MySQL、Redis、RabbitMQ、Elasticsearch、Nacos等常见服务全套（质量有保证，内容详情）`](https://blog.csdn.net/yuchangyuan5237/article/details/130866065)

# 1. Docker阿里云镜像加速

在国内，从官方的Docker Hub仓库拉取镜像常常会遇到网络很慢甚至不能下载的情况，体验很不好，此时需要配置国内的镜像来加速下载。很多云服务商都提供了Docker镜像加速服务，这里选择**阿里云**。

**步骤如下**：

* 阿里云镜像获取地址：https://cr.console.aliyun.com/cn-hangzhou/instances/mirrors，登陆后，左侧菜单选中镜像加速器就可以看到你的专属地址了

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-25-14-17-06-image.png)

* 修改配置文件

> 阿里云针对各种平台都提供了操作文档，按文档操作即可

有的可以通过图形化方式修改，有的需要修改配置文件

* 重启 docker

```shell
service docker restart
```

* 查看是否成功

执行 docker info 命令查看是否配置成功，如下图所示我配置成功

```shell
docker info
```

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-25-14-21-06-image.png)

# 2. 参考资料

Docker 官方仓库：[https://hub.docker.com](https://hub.docker.com)

我的文章：[《如何查看一个Docker镜像有哪些版本.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《Docker设置国内镜像源.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《Docker快速入门实用教程.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《Docker安装MySQL、Redis、RabbitMQ、Elasticsearch、Nacos等常见服务.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《Docker安装Nacos服务.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《如何修改Docker中的文件.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《Docker容器间的连接或通信方式.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《Docker安装的MySQL如何持久化数据库数据.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《制作Docker私有仓库.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《使用docker-maven-plugin插件构建发布推镜像到私有仓库.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《解决Docker安装Elasticsearch后访问9200端口失败.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

---

传送门：[**保姆式Spring5源码解析**](https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍)

欢迎与作者一起交流技术和工作生活

[**联系作者**](https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者)
