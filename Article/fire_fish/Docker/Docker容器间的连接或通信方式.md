[TOC]

[`点击跳转：Docker安装MySQL、Redis、RabbitMQ、Elasticsearch、Nacos等常见服务全套（质量有保证，内容详情）`](https://blog.csdn.net/yuchangyuan5237/article/details/130866065)

# 1. Docker容器之间通信的主要方式

## 1.1 通过容器ip访问

容器重启后，ip会发生变化。通过容器ip访问不是一个好的方案。

## 1.2. 通过宿主机的ip:port访问

通过宿主机的`ip:port`访问，只能依靠监听在暴露出的端口的进程来进行有限的通信。

容器之间通信不能用 `localhost`、`127.0.0.1`，只能用宿主机的 `ip:port` 通信，但是主机的ip地址会随着宿主机的重启而变化

以 MySQL 容器为例如下：

* 创建容器

```shell
docker run -it -p 3306:3306 --name mysql -e MYSQL_ROOT_PASSWORD=root mysql:5.7
```

* 主机直接访问暴露的端口

如下图，暴露端口的方式很方便主机与容器之间的通信，跟连接主机本地一样

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230725_1.png)

## 1.3. 通过link建立连接（官方已不推荐使用）

运行容器时，指定参数link，使得源容器与被链接的容器可以进行相互通信，并且接受的容器可以获得源容器的一些数据，比如：环境变量。

```shell
# 源容器：mysql
docker run -itd --name mysql_test -e MYSQL_ROOT_PASSWORD=root mysql:5.7
#被链接容器 ubuntu
docker run -itd --name ubuntu_test --link test-mysql:mysql  ubuntu /bin/bash
#进入test-ubuntu
docker exec -it ubuntu_test /bin/bash
```

## 1.4. 通过 User-defined networks（推荐）

通过用户自定义网络，加入了这个网络的容器可以互相联通，通过`容器名称`即可互相访问，相当于在同一个局域网。

**推荐新建的容器 `-p` 和 `--network` 都配置。**

> 配置 `-p` 选项让宿主机和容器之间通过 `暴露端口` 来通信
>
> 配置 `--network` 选项让容器加入同一个网络，加入同一个网络后就可通过容器名称来通信。

以`centos`和`mysql`容器之间通信为例：

* 创建网络

docker network来创建一个桥接网络，在docker run的时候将容器指定到新创建的桥接网络中，这样同一桥接网络中的容器就可以通过互相访问。

```shell
docker network create dockerbetweennetwork
```

* 启动mysql容器时，加入创建的网络

创建mysql容器加入到dockerbetweennetwork网络，也暴露了3306端口给主机使用

```shell
# 创建mysql容器
docker run -p 3306:3306 --name mysql \
--network dockerbetweennetwork \
-e MYSQL_ROOT_PASSWORD=root \
-d mysql:5.7
```

* 启动centos容器时，加入创建的网络

```shell
# 创建centos容器
docker run -it --name centos \
--network dockerbetweennetwork \
--rm centos /bin/bash
```

> centos这种服务器性质的docker容器必须跟上命令，不然会默认退出；

* 查看mysql容器的ip地址

```shell
# 查看mysql容器ip地址
docker inspect mysql
```

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230802_3.png)

* 进入centos容器连接mysql

测试是否可以通过容器名称ping通mysql容器。

```shell
# 进入centos容器中
docker exec -it centos /bin/bash
# ping 上面得到的mysql容器的地址
ping mysql
```

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230802_4.png)

# 2. 参考资料

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
