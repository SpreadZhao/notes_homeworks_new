[TOC]

[`点击跳转：Docker安装MySQL、Redis、RabbitMQ、Elasticsearch、Nacos等常见服务全套（质量有保证，内容详情）`](https://blog.csdn.net/yuchangyuan5237/article/details/130866065)

本文描述了如何用Docker安装Nacos的单机版，含单机非持久化版本和单机持久化版本

# 1. Docker搭建Nacos单机版

Nacos作为微服务的配置中心，无论是在开发测试和生产中，用户更希望Nacos能保存用户的配置，也就是要求Nacos具有持久化功能。但是默认情况是数据保在内存数据库Derby中，重启后数据消失，通过修改配置可以把Nacos数据持久化到MySQL中。下面分别介绍单机非持久化版本和单机持久化版本，**推荐用持久化版本。**

## 1.1. 单机非持久化

注意：如果只是简单的学习使用直接用下面的命令就好了。但是nacos所有元数据都会保存在容器内部，如果容器迁移会导致nacos元数据不复存在，所以通常我们通常会将nacos元数据保存在mysql中。

以nacos的2.1.1版本为例：

* 拉取镜像

```mysql
docker pull nacos/nacos-server:v2.1.1
```

不建议用最新版本，可能有意外的问题

* 创建容器

```shell
# 用最新版启动nacos容器
docker run -d --name nacos -p 8848:8848 \
-e MODE=standalone \
nacos/nacos-server:v2.1.1
```

> 也可以不拉取容器直接启动，docker会帮我们自动拉取镜像，`如果想要执行的版本请指定版本号`

* 进入界面 [http://localhost:8848/nacos](http://localhost:8848/nacos)

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230723_12.png)

> 注：初始账户密码均为 nacos，只要进入了页面就代表启动成功了

## 1.2. 单机持久化到MySQL

> 即使是开发测试环境也推荐使用持久化版本！

搭建单机且持久化到MySQL服务器的步骤如下：

* 启动一台mysql服务器，创建数据库nacos（可自定义），用 [sql语句源文件](https://github.com/alibaba/nacos/blob/master/distribution/conf/mysql-schema.sql) 初始化nacos数据库

* 考虑持久化的配置

Nacos 通过配置文件的方式指定了启动模式、持久化方法、连接哪台MySQL、MySQL用户名、MySQL密码等，Docker 通过变量的方式把这些需要用户执行的内容暴露出来。常见变量如下表：

| 变量                       | 说明                                                         |
| -------------------------- | ------------------------------------------------------------ |
| MODE                       | 模式。单机固定写 `standalone`                                |
| SPRING_DATASOURCE_PLATFORM | 数据平台。固定写 `mysql`                                     |
| **MYSQL_SERVICE_HOST**     | **主机**                                                     |
| MYSQL_SERVICE_PORT         | 端口。默认值 3306                                            |
| MYSQL_SERVICE_DB_NAME      | 数据库名称                                                   |
| MYSQL_SERVICE_USER         | 用户名                                                       |
| MYSQL_SERVICE_PASSWORD     | 密码                                                         |
| MYSQL_SERVICE_DB_PARAM     | jdbc 的 url 连接参数（可根据情况自定义添加，nacos是有默认值的） |

* 整理为如下的命令

用户根据自己的环境自行修改相应的变量参数值，我本地命令如下作为参考：

```shell
docker run -d -p 8848:8848 --name nacos \
-e JVM_XMS=256m \
-e JVM_XMX=256m \
-e MODE=standalone \
-e SPRING_DATASOURCE_PLATFORM=mysql \
-e MYSQL_SERVICE_HOST=192.168.1.3 \
-e MYSQL_SERVICE_PORT=3306 \
-e MYSQL_SERVICE_DB_NAME=nacos \
-e MYSQL_SERVICE_USER=root \
-e MYSQL_SERVICE_PASSWORD=root \
nacos/nacos-server:v2.1.1
```

<mark>唯一需要注意的是：`MYSQL_SERVICE_HOST` 一定要设置为主机的IP地址</mark>，因为是不同容器（nacos 和 mysql）间的连接，所以一定不能用 localhost

* 进入监管界面 [http://localhost:8848/nacos](http://localhost:8848/nacos)

用初始账户密码均为 nacos 登录即可

# 2. 参考资料

[nacos官网](https://nacos.io/zh-cn/index.html)

[Nacos 快速开始](https://nacos.io/zh-cn/docs/quick-start.html)

[https://github.com/alibaba/nacos](https://github.com/alibaba/nacos)

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
