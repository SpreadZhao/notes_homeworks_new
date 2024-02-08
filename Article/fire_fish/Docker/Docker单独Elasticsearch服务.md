[TOC]

[`点击跳转：Docker安装MySQL、Redis、RabbitMQ、Elasticsearch、Nacos等常见服务全套（质量有保证，内容详情）`](https://blog.csdn.net/yuchangyuan5237/article/details/130866065)

# 1. 什么是Elasticsearch

Elaticsearch，简称为es， es是一个开源的高扩展的分布式全文检索引擎，它可以近乎实时的存储、检索数据；本身扩展性很好，可以扩展到上百台服务器，处理PB级别的数据。es也使用Java开发并使用Lucene作为其核心来实现所有索引和搜索的功能，但是它的目的是通过简单的RESTful API来隐藏Lucene的复杂性，从而让全文搜索变得简单。

# 2. Docker安装Elasticsearch

安装Elasticsearch最重要的就是确定Elasticsearch的版本！根据您的Spring Boot项目确定好Elasticsearch的版本，其它跟es相关的服务在安装时要求与es的版本保持一致。如何确定Elasticsearch的版本是本文讨论的重点！**版本、版本、版本，重要的事情说3遍！**

## 2.1 确定Elasticsearch的版本

Spring Boot项目与es整合时版本的**兼容性很重要**，不兼容的版本会导致意想不到的错误或直接导致不能使用，所以安装es之前必须先确定好版本。版本兼容性查看官方的[兼容性矩阵](https://docs.spring.io/spring-data/elasticsearch/docs/current/reference/html/#preface.versions)。具体如下图：

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230722_1.png)

以上图举例：假设我们的Spring Boot项目的版本是2.1.x，那么对应要求es的最低版本是6.2.2，**注意是最低版本**，如果测试时还是不能正常使用那么**需要修改es的版本为6.2.2的邻近版本但是最好不要超过上一个的限制**（上表中是6.8.12）。

> 作者就遇到过项目的Spring Boot版本是2.1.3.RELEASE，按照兼容性要求使用了es的6.2.2，安装后发现不仅Spring Boot项目不能正常启动而且es的6.2.2版本没有对应版本的中文分词器IKAnalyzer与之对应，所以调整为邻近的6.6.2后都正常了。

## 2.2. Docker安装Elasticsearch

以Elasticsearch的6.6.2版本为例：

* 安装Elasticsearch

```shell
# 注意下：Elasticsearch的Docker镜像是Elasticsearch官方自己维护的
docker run -p 9200:9200 -p 9300:9300 --name elasticsearch \
-e "discovery.type=single-node" \
-e "cluster.name=elasticsearch" \
-e "ES_JAVA_OPTS=-Xms512m -Xmx1024m" \
-d "docker.elastic.co/elasticsearch/elasticsearch:6.6.2"
```

注意下：es的Docker镜像是es官方自己维护的，[Docker安装es官方参考](https://www.elastic.co/guide/en/enterprise-search/current/docker.html#docker-image)

* 查看容器日志：

```shell
docker logs -f elasticsearch
```

* 访问是否会返回版本信息：http://localhost:9200

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230801_2.png)

## 2.3. 给Elasticsearch安装中文分词器IKAnalyzer（可选）

以Elasticsearch的6.6.2版本为例：

- 下载中文分词器IKAnalyzer，注意下载与es对应的版本，下载地址：https://github.com/medcl/elasticsearch-analysis-ik/releases

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230722_3.png)

- 拷贝安装包到容器的特定目录`/usr/share/elasticsearch`

```shell
docker cp elasticsearch-analysis-ik-6.6.2.zip elasticsearch:/usr/share/elasticsearch
```

- 解压到es容器的`/usr/share/elasticsearch/plugins`目录

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230722_2.png)

> 注意目录结构，别多一层或少一层目录

* 重新启动服务：

```shell
docker restart elasticsearch
```

* 再次检查日志和访问http://localhost:9200

```shell
docker logs -f elasticsearch
```

