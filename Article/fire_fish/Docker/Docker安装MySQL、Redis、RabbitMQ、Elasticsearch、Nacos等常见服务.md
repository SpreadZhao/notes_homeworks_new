[TOC]

本文描述的是使用Docker来安装我们常用的一些服务，以下示例都是作者自己在用的，质量有保证。

至于为什么使用Docker，因为方便，不需要下载、配置乱七八糟的，

# 1. Docker容器间的连接或通信方式

安装常见服务之前先讨论下Docker容器间的连接或通信方式。随着安装的Docker容器越来越多，会发现存在一些复杂的场景，需要容器间的相互通信来为程序服务，而不仅仅是宿主机与容器的通信。**如：容器（Nacos、MySQL）来一起为程序（Spring Boot）服务，Nacos提供注册中心和配置中心服务，MySQL提供Nacos文件持久化服务，这时就需要Nacos与MySQL通信。**

容器之间通信不能用 `localhost`、`127.0.0.1`，因为此时 `localhost` 指的是容器本身而不是主机，**只能用主机的 `ip:port` 通信**，但是主机的 ip 地址会随着主机的重启而变化，所以通过 `-p` 暴露端口的方式不适合容器与容器之间的通信。

先给出结论：

* 配置 `-p` 选项让宿主机和容器之间通过 `暴露端口` 来通信

* 配置 `--network` 选项让容器加入同一个网络，加入同一个网络后就可通过容器名称来通信。

**推荐新建的容器 `-p` 和 `--network` 都配置**。具体的方法参考：[Docker容器间的连接或通信方式](https://blog.csdn.net/yuchangyuan5237/article/details/131908975)

# 2. Docker常见服务的安装

## 2.1. Docker安装MySQL

MySQL 是最流行的关系型数据库管理系统，在 WEB 应用方面 MySQL 是最好的 RDBMS(Relational Database Management System：关系数据库管理系统)应用软件之一。

Docker一键安装MySQL服务，[Docker安装MySQL服务](https://blog.csdn.net/yuchangyuan5237/article/details/132014810)

## 2.2. Docker安装Redis

Redis中的数据对于开发和测试来说，其实不是很重要，那就不做挂载了直接启动！

```shell
# Docker启动Redis
docker run -d --name redis -p 6379:6379 redis:7

# 进入Redis命令控制台(指定容器id或名称也可以)
docker exec -it redis
```

## 2.3. Docker安装RabbitMQ

```shell
docker run --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management
```

* 访问地址查看是否安装成功：http://localhost:15672
* 输入账号密码并登录：guest guest

## 2.4. Docker安装Elasticsearch

Elaticsearch，简称为es， es是一个开源的高扩展的分布式全文检索引擎，它可以近乎实时的存储、检索数据；本身扩展性很好，可以扩展到上百台服务器，处理PB级别的数据。es也使用Java开发并使用Lucene作为其核心来实现所有索引和搜索的功能，但是它的目的是通过简单的RESTful API来隐藏Lucene的复杂性，从而让全文搜索变得简单。

安装Elasticsearch最重要的就是确定Elasticsearch的版本！Docker安装Elasticsearch的正确方式，[Docker安装Elasticsearch服务](https://blog.csdn.net/yuchangyuan5237/article/details/132014872)

## 2.5. Docker单独安装Zipkin

Zipkin是Twitter的一个开源项目，可以用来获取和分析Spring Cloud Sleuth中产生的请求链路跟踪日志，它提供了Web界面来帮助我们直观地查看请求链路跟踪信息。常用语微服务的调用链路跟踪。

Zipkin的数据保存在内存中重启后数据会消失，如果需要保存可以整合Elasticsearch

```shell
# 单独安装zipkin
docker run -d --name zipkin -p 9411:9411 openzipkin/zipkin
```

* Zipkin页面访问地址：http://localhost:9411

## 2.6. Elasticsearch+Kibana整合

Kibana是一款适用于Elasticsearch的**数据可视化和管理工具**，可以提供实时的直方图、线形图、饼状图和地图。支持用户安全权限体系，支持各种纬度的插件，通常搭配Elasticsearch、Logstash一起使用。

**kibana 的版本最好与 elasticsearch 保持一致**，避免发生不必要的错误，Docker安装Kibana服务的正确方式，[Docker安装Kibana服务](https://blog.csdn.net/yuchangyuan5237/article/details/132015270)

## 2.7. Zipkin+Elasticsearch+Kibana整合

涉及到3个组件，它们的过程是这样的：Spring Cloud微服务把调用链路的日志发送给Zipkin，Zipkin把数据发送给Elasticsearch进行保存，Kibana图形化显示Elasticsearch的数据。

用Docker整合3个组件参考，[Docker+Zipkin+Elasticsearch+Kibana部署分布式链路追踪](https://blog.csdn.net/yuchangyuan5237/article/details/132053737)

## 2.8. Docker安装Consul

Consul是HashiCorp公司推出的开源软件，提供了微服务系统中的服务治理、配置中心、控制总线等功能。这些功能中的每一个都可以根据需要单独使用，也可以一起使用以构建全方位的服务网格，总之Consul提供了一种完整的服务网格解决方案。

Docker下安装Consul参考，[Docker安装Consul](https://blog.csdn.net/yuchangyuan5237/article/details/132053741)

## 2.9. Nacos+MySQL整合

Nacos是Alibaba开源的微服务组件，主要提供服务注册与发现、配置中心等功能。

可以单独使用，也可以与MySQL搭配使用，可参考，[手把手教你Docker搭建nacos单机版](https://blog.csdn.net/yuchangyuan5237/article/details/131878762)

## 2.10. Docker安装Oracle11g

## 2.11. Docker安装Oracle12c

参考：https://github.com/oracle/docker-images/tree/main/OracleDatabase/SingleInstance

oracle数据的官方镜像：https://hub.docker.com/_/oracle-database-enterprise-edition（需要登录注册等认证）

# 3. 参考资料

docker elastic 官方网址：[https://www.docker.elastic.co](https://www.docker.elastic.co)

docker elastic 官方镜像：[https://www.elastic.co/guide/en/enterprise-search/current/docker.html#docker-image](https://www.elastic.co/guide/en/enterprise-search/current/docker.html#docker-image)

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
