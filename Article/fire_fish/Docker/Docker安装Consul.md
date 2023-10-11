[TOC]

[`点击跳转：Docker安装MySQL、Redis、RabbitMQ、Elasticsearch、Nacos等常见服务全套（质量有保证，内容详情）`](https://blog.csdn.net/yuchangyuan5237/article/details/130866065)

# 1. 什么是Consul

Consul是HashiCorp公司推出的开源软件，提供了微服务系统中的服务治理、配置中心、控制总线等功能。这些功能中的每一个都可以根据需要单独使用，也可以一起使用以构建全方位的服务网格，总之Consul提供了一种完整的服务网格解决方案。

# 2. Docker安装启动Consul

* 拉取Consul镜像

```shell
docker pull consul # 默认拉取latest
docker pull consul:1.6.1 # 拉取指定版本
```

* 安装并运行

```shell
docker run -d -p 8500:8500 --name=consul \
consul:1.6.1 \
consul agent -dev \
-ui -node=n1 -bootstrap-expect=1 -client=0.0.0.0
```

> 以下是consul的命令或参数介绍：
>
> * `consul agent -dev` 使用开发模式启动
> * `-ui` 开启网页可视化管理界面
> * `-node` 指定该节点名称，注意**每个节点的名称必须唯一不能重复**！上面指定了第一台服务器节点的名称为`n1`，那么别的节点就得用其它名称
> * `-bootstrap-expect` 最少集群的`Server`节点数量，少于这个值则集群失效，这个选项**必须指定**，由于这里是单机部署，因此设定为`1`即可
> * `-client` 指定可以外部连接的地址，`0.0.0.0`表示外网全部可以连接

* 访问Consul的UI：http://localhost:8500/

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230723_8.png)