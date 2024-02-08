[TOC]

[`点击跳转：Docker安装MySQL、Redis、RabbitMQ、Elasticsearch、Nacos等常见服务全套（质量有保证，内容详情）`](https://blog.csdn.net/yuchangyuan5237/article/details/130866065)

# 1. 什么是Kibana

Kibana 是一款适用于Elasticsearch的**数据可视化和管理工具**，可以提供实时的直方图、线形图、饼状图和地图。支持用户安全权限体系，支持各种纬度的插件，通常搭配Elasticsearch、Logstash一起使用。

# 2. Docker安装Kibana

## 2.1. 前提

安装好**正确版本**的Elasticsearch，Docker安装Elasticsearch的正确方式，[Docker安装Elasticsearch服务](https://blog.csdn.net/yuchangyuan5237/article/details/132014872)

以Elasticsearch的6.6.2版本为例：

* 安装启动Elasticsearch

```shell
# 
docker run -p 9200:9200 -p 9300:9300 --name elasticsearch \
-e "discovery.type=single-node" \
-e "cluster.name=elasticsearch" \
-e "ES_JAVA_OPTS=-Xms512m -Xmx1024m" \
-d "docker.elastic.co/elasticsearch/elasticsearch:6.6.2"
```

* 访问下http://localhost:9200或https://localhost:9200看看

```shell
curl http://localhost:9200
```

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230801_2.png)

## 2.2. 安装Kibana

需要注意的是，**kibana 的版本需要与 elasticsearch 保持一致**，避免发生不必要的错误

以Kibana的6.6.2版本为例：

* 安装启动Kibana

```shell
# 
docker run -d --name kibana -p 5601:5601 \
--link elasticsearch:elasticsearch \
kibana:6.6.2
```

`--link`： 建立两个容器之间的关联，kibana关联到es。前面的是es容器的名称，刚好我们也取名为elasticsearch了，后面固定字符串 `elasticsearch`

> 注：--link方式用于容器间的网络连接，其实官方已经不推荐，推荐使用`docker network`方式

* 检查Kibana日志

```shell
docker logs -f kibana
```

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230722_6.png)

日志上没有什么报错

* 检查Kibana界面：http://localhost:5601

界面显示类似下图这样，基本没啥问题。有一个zipkin的index是因为使用过zipkin。

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230722_7.png)
