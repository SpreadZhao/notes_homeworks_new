
@[TOC](文章结构)

# Redis 的持久化方案

## Rdb（Redis Database) 方式

Redis 默认的方式，redis 通过快照方式将数据持久化到磁盘中。当在指定的事件内发生多少次修改则把内存中的**全部数据持久化为一个紧凑的单文件**到磁盘中保存。

> 为什么叫做 rdb，因为是 Redis Database 的缩写

### 设置持久化快照的条件

> 当 60 秒发生 10000 次写操作则持久化一次；
>
> 当 300 秒 100 次写操作则持久化一次
>
> 当 3600 秒发生 1 次写操作则持久化一次

在 redis.conf 中修改持久化快照的条件：

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-05-02-12-31-image.png)

### 持久化文件的存储目录

在 redis.conf 中可以指定持久化文件的存储目录

> 备注：dbfilename 是 Redis Database Filename 的缩写

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-05-02-15-41-image.png)

### Rdb 的优点

1、是 Redis 数据的一个紧凑的单文件时间点表示

2、适合大规模的数据恢复

3、对数据完整性和一致性要求不高

4、加载速度要比 aof 快得多

### Rdb 的缺点

一旦 redis 非法关闭，那么会丢失最后一次持久化之后的数据，如果数据不重要，则不必要关心。 如果数据不能允许丢失，那么需要使用 aof 持久化方式

> 因为 save 是间隔性触发的

如果数据集很大 RDB 写入磁盘会导致 Redis 短暂的不能提供服务

## Aof（Append Only File） 方式

Redis 默认是不使用该方式持久化的。Aof 方式的持久化，是操作一次 redis 数据库，则将操作的记录存储到 aof 持久化文件中

* 第一步：开启 aof 方式持久化方案。 将 redis.conf 中的 appendonly 改为 yes，即开启 aof 方式的持久化方案

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-05-02-25-42-image.png)

* aof 文件存储的目录和 rdb 方式的一样。 aof 文件存储的名称

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-05-02-26-06-image.png)

在使用 aof 和 rdb 方式时，如果 redis 重启，则数据从 aof 文件加载

### aof 的优点

最多丢失 1 秒的数据

### aof 的缺点

aof 的文件大小比 rdb 更大，重启使从 aof 文件中恢复速度比 rdb 慢

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>


