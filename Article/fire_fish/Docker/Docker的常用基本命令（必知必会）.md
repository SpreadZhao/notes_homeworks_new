[TOC]

[`点击跳转：Docker安装MySQL、Redis、RabbitMQ、Elasticsearch、Nacos等常见服务全套（质量有保证，内容详情）`](https://blog.csdn.net/yuchangyuan5237/article/details/130866065)

本文主要介绍了Docker的**安装、镜像操作、容器操作**！

# 1. Docker简介

Docker是一个开源的应用容器引擎，让开发者可以打包应用及依赖包到一个可移植的镜像中，然后发布到任何流行的Linux或Windows机器上。**使用Docker可以更方便地打包、测试以及部署应用程序。**

**重要概念：**

images = 镜像（镜像相当于类概念）

container = 容器（container相当于实例的概念）

# 3. Docker环境安装

## Mac安装

如果是Mac用户，请点击以下链接下载 [Install Docker Desktop on Mac](https://docs.docker.com/docker-for-mac/install/) ，选择"Mac with Intel chip"

## Windows安装

如果是Windows用户，请点击以下链接下载 [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)，点击"Docker Desktop for Windows"

## Linux安装

* 安装`yum-utils`；

```shell
yum install -y yum-utils device-mapper-persistent-data lvm2
```

* 为yum源添加docker仓库位置；

```shell
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

* 安装docker服务；

```shell
yum install docker-ce
```

* 启动docker服务。

```shell
systemctl start docker
```

# 4. 配置镜像加速

可以使用阿里云的镜像加速，参考：https://www.runoob.com/docker/docker-mirror-acceleration.html

> **注意**：阿里云上有图文操作文档，无论你是Windows还是Mac按文档操作即可，一点不担心。如下是我的配置图：
>
> ![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-25-12-21-59-image.png)

使用自己的账号有自己专属的阿里云镜像地址

docker的配置是通过json文件来配置的，这里配置镜像也需要通过json文件来配置

```json
{
  "registry-mirrors": ["https://nubcahe0.mirror.aliyuncs.com"]
}
```

# 5. Docker镜像常用命令

## 列出镜像列表

```shell
docker images
```

## 搜索镜像

```shell
docker search redis
```

## 下载镜像

```shell
docker pull redis
```

## 查看镜像版本

> 由于`docker search`命令只能查找出是否有该镜像，不能找到该镜像支持的版本。详细参考：[如何查看一个docker镜像有哪些版本](https://blog.csdn.net/yuchangyuan5237/article/details/130868348)

## 删除镜像

* 指定名称删除镜像

```shell
# 删除latest
docker rmi redis

# 删除指定tag
docker rmi redis:7
```

* 指定`IMAGE ID`删除镜像

```shell
docker rmi 5d89766432d0
```

## 构建镜像

* 从Dockerfile构建镜像

```shell
# -t 表示指定镜像仓库名称/镜像名称:镜像标签 .表示使用当前目录下的Dockerfile文件
docker build -t fire/fire-admin:1.0-SNAPSHOT .
# 查看刚构建的镜像
docker images
```

* 从容器的修改构建镜像

```shell
# 从容器b9480afc7572构建镜像
docker commit b9480afc7572 myubuntu:1.0
# 查看刚构建的镜像
docker images
```

## 推送镜像

* 推送到私有仓库

```shell
# 打私有标签
docker tag myubuntu:1.0 localhost:5000/myubuntu:1.0
# 推送
docker push localhost:5000/myubuntu:1.0
```

* 推送到Docker Hub

```shell
# 登录Docker Hub
docker login
# 推送到远程仓库
docker push firefishdocker/fire-admin:1.0-SNAPSHOT
```

## 私有仓库相关

### 安装私有仓库

> 参考：[制作Docker私有仓库](https://blog.csdn.net/yuchangyuan5237/article/details/131971898)

### 构建新镜像并推送到私有仓库

> 参考：[Docker之将本地镜像推送到私有库](https://blog.csdn.net/xiaoyu070321/article/details/130871703)

* 从容器构建新镜像

```shell
docker commit b9480afc7572 myubuntu:1.0
```

* 给新镜像打上私有仓库标签

```shell
docker tag myubuntu:1.0 localhost:5000/myubuntu:1.0
```

* 推送之前查看有哪些镜像

```shell
curl http://localhost:5000/v2/_catalog
# {"repositories":[]}
```

* 推送到私有仓库

```shell
# 打私有标签
docker tag myubuntu:1.0 localhost:5000/myubuntu:1.0
# 推送
docker push localhost:5000/myubuntu:1.0
```

* 推送成功：

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230801_7.png)

* 推送之后查询有哪些镜像，以及tag列表

```shell
curl http://localhost:5000/v2/_catalog
# {"repositories":["myubuntu"]}

curl http://localhost:5000/v2/myubuntu/tags/list
# {"name":"myubuntu","tags":["1.0"]}
```

* 从私库拉取镜像

```shell
# 不要写成http://localhost:5000/myubuntu:1.0
docker pull localhost:5000/myubuntu:1.0
```

# 6. Docker容器常用命令

## 新建并启动容器

```shell
    docker run -p 6379:6379 --name redis \
    -e TZ="Asia/Shanghai" \
    -v /mydata/redis/data:/data \
    -d redis:7 redis-server --appendonly yes
```

- `-p`：将宿主机和容器端口进行映射，格式为：宿主机端口:容器端口；（**建议设置**）

> 宿主机端口用户可指定，容器端口是预定义的；
>
> 宿主机端口不能重复，容器端口可以重复；
>
> 设置后宿主机才能与容器连接

- `--name`：指定容器名称，之后可以通过容器名称来操作容器；（**强烈建议设置**）

> 设置名称便于后续的操作

- `-e`：设置容器的环境变量，这里设置的是时区；
- `-v`：将宿主机上的文件挂载到宿主机上，格式为：宿主机文件目录:容器文件目录；

> 这类需求通常是`挂载配置文件目录`、`挂载数据存储目录`

- `-d`：表示容器以后台方式运行。（**建议设置**）

## 列出容器

* 列出运行中的容器：

```shell
docker ps
```

* 列出所有容器：

```shell
docker ps -a
```

##  停止容器

可以用容器名称或容器ID

> 注：体现了docker run时指定--name的重要性

```shell
# NAMES
docker stop redis

# CONTAINER ID
docker stop c5f5d5125587
```

## 启动容器

启动之前创建过的容器

```shell
docker start redis
```

## <mark>进入容器</mark>

> 进入容器的命令格式是：docker exec -it 容器 命令

```shell
# 进入redis容器的命令行操作中
docker exec -it 9e38ce427c61 redis-cli

# 或者
docker exec -it redis /bin/bash

# 或者
docker exec -it redis sh
```

## 删除容器（慎用）

删除容器会删除容器的所有数据，不可恢复，慎重使用

```shell
docker rm redis
```

## 查看日志状态

```shell
docker logs -f redis
```

## 文件复制

一般用来修改容器中的文件

```shell
# 格式是：docker cp 源文件 目标文件
# 容器 ---> 宿主机
docker cp redis:/data/dump.rdb dump.rdb
# 宿主机 ---> 容器
docker cp test.log redis:/data
```

---

# 7. 参考资料

[《如何查看一个Docker镜像有哪些版本.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

[《Docker设置国内镜像源.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

[《Docker快速入门实用教程.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

---

传送门：[**保姆式Spring5源码解析**](https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍)

欢迎与作者一起交流技术和工作生活

[**联系作者**](https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者)
