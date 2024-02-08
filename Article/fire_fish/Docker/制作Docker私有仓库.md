[TOC]

# 1. 安装私有镜像仓库

> 由于之后我们需要推送到私有镜像仓库，我们预先安装好，使用的是Docker公司开发的私有镜像仓库Registry。

* 下载Registry的Docker镜像；

  ```shell
  docker pull registry:2
  ```

* 使用Docker容器运行Registry服务，需要添加环境变量`REGISTRY_STORAGE_DELETE_ENABLED=true`开启删除镜像的功能；

  ```shell
  # --restart=always 表示开机启动
  docker run -p 5000:5000 --name registry2 \
  --restart=always \
  -e REGISTRY_STORAGE_DELETE_ENABLED="true" \
  -d registry:2
  ```

* 修改Docker Daemon的配置文件，文件位置为`/etc/docker/daemon.json`，由于Docker默认使用HTTPS推送镜像，而我们的镜像仓库没有支持，所以需要添加如下配置，改为使用HTTP推送；

  ```json
  {
    "insecure-registries": ["192.168.56.120:5000"]
  }
  ```

  > 修改ip地址为docker所在的地址，如果是本地也可以用localhost

* 最后使用如下命令重启Docker服务

  ```shell
  systemctl daemon-reload && systemctl restart docker
  ```

# 2. 镜像仓库可视化

由于私有镜像仓库管理比较麻烦，而`docker-registry-ui`有专门的页面可以方便地管理镜像，所以我们安装它来管理私有镜像仓库。

* 下载`docker-registry-ui`的Docker镜像；

  ```shell
  docker pull joxit/docker-registry-ui:static
  ```

* 使用Docker容器运行`docker-registry-ui`服务；

  ```shell
  docker run -p 8280:80 --name registry-ui \
  --link registry2:registry2 \
  -e REGISTRY_URL="http://registry2:5000" \
  -e DELETE_IMAGES="true" \
  -e REGISTRY_TITLE="Registry2" \
  -d joxit/docker-registry-ui:static
  ```

* 随便找一个docker镜像来测试我们建的私有镜像仓库可用性（以busybox为例）

  ```shell
  docker pull busybox
  ```

* 给镜像`busybox`打上私有仓库的标签，并设置版本为`v1.0`；

  ```shell
  docker tag busybox localhost:5000/busybox:v1.0
  ```

* 之后推送到私有镜像仓库去；

  ```shell
  docker push localhost:5000/busybox:v1.0
  ```

* 访问`docker-registry-ui`管理界面，即可查看到`busybox`镜像，地址：http://localhost:8280

  ![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230728_2.png)

# 3. 参考资料

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
