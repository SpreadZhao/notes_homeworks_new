[TOC]

# 1. 如何修改Docker中的文件

可能你安装的Docker容器没有vi、vim这些编辑命令。当然没有你可以安装，但是每新建一个容器每一次编辑需求就安装一次太麻烦了，那么如何编辑Docker中的文件呢。常见的有3种方式：

* echo命令方式

* 使用 `docker cp` 来回复制文件方式

* 挂载 主机 和 容器方式

每次方式各有优点，echo命令足够简单方便，docker cp方式用途更广，挂载方式便于持久化

## 方式1，echo命令方式

**优点：** 1、每个容器都有2、对比其它方式足够简单、足够方便

**步骤：**

* 进入容器

```shell
docker exec -it lpg-promtail-1 /bin/bash
```

* 用cat查看源内容

```shell
cat /etc/promtail/config.yml
```

* 复制编辑新内容
* echo新内容进行覆写

```shell
# 把编辑后的内容输出了...处开始覆写
echo '...' > /etc/promtail/config.yml
```

## 方式2，来回复制文件方式

* 拷贝容器中的文件到主机上

```shell
# docker cp 源 目标
docker cp elasticsearch_8.7.1:/usr/share/elasticsearch/config/elasticsearch.yml elasticsearch.yml
```

* 在主机上修改文件

* 拷贝主机上的文件回容器覆盖容器原有文件

```shell
# 只要把docker cp 的源和目标反过来就行了
docker cp elasticsearch.yml elasticsearch_8.7.1:/usr/share/elasticsearch/config/elasticsearch.yml
```

* 修改完文件如果需要重启容器记得重启容器

## 方式3，挂载方式

通过 `-v` 命令可以把主机中的文件挂载到容器中，在启动容器时指定，举例如下：

```shell
docker run -p 3306:3306 --name mysql \
-v /mydata/mysql/log:/var/log/mysql \
-v /mydata/mysql/data:/var/lib/mysql \
-v /mydata/mysql/conf:/etc/mysql \
-e MYSQL_ROOT_PASSWORD=root  \
-d mysql:5.7
```
以上就把主机的 `/mydata/mysql/conf` 文件夹挂载到容器 `var/log/mysql` 目录。

**这种方法最大的优点是在删除容器后，该文件依然存在与主机中，下次启动新容器或许依然可以使用而不用重新配置一遍环境和恢复数据，这对需要持久化的容器特别友好，如mysql**。[Docker中MySQL的持久化、Docker如何持久化数据](https://gitee.com/firefish985/article-list/tree/master/Docker)

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
