
@[TOC](文章结构)

# Redis 数据类型

在 redis7 版本中，数据类型有 10 种

* 常规的 5 种数据类型（**Strings、Lists、Sets、Sorted sets、Hashs**）
* 5 种不常见的（**Geospatial**、Streams、**HyperLogLog**、**Bitmaps**、Bitfields）

> 备注：本文只介绍其中标粗的常用部分

官方参考

```shell
# 各种数据类型总览（含总览和详细命令参考）
https://redis.io/docs/data-types/

# 官方数据类型教程
https://redis.io/docs/data-types/tutorial/

# 官方在线尝试及人门教程
https://try.redis.io/
```

以下的数据类型介绍参考了官网

## 1. Redis全局命令（跟key有关系，而跟value无关）

> **注意**：下面的这些命令跟 value 的无关，只跟 key 有关系

* Keys pattern
* Exists key

* del key
* Expire key second
* Ttl key
* Type key

## 2. Strings

### Getting and setting Strings

- [`SET`](https://redis.io/commands/set) stores a string value

- [`GET`](https://redis.io/commands/get) retrieves a string value

- [`SETNX`](https://redis.io/commands/setnx) stores a string value only if the key doesn't already exist. Useful for implementing locks

  > 对于实现锁很有用

- [`MGET`](https://redis.io/commands/mget) retrieves multiple string values in a single operation

### Managing counters

* [`INCRBY`](https://redis.io/commands/incrby) atomically increments (and decrements when passing a negative number) counters stored at a given key

  > 为什么要有 `INCR` 等这些命令，因为它们是**原子的**

  > 举例：
  >
  > ```shell
  > > INCR views:page:2
  > (integer) 1
  > > INCRBY views:page:2 10
  > (integer) 11
  > ```

## 3. Lists(L)

redis 的 list 用的是**链表**结构！

用途：

1、记住最新的更新（如网络上的最近10条数据）

> 记住最新的记录（如lpush和ltrim和lrange的配合可以获取最新的记录，ltrim会删除范围外的其他数据只保留范围内的最新记录）

2、2个进程的交流（如生产者消费者）

### Basic commands

* [`LPUSH`](https://redis.io/commands/lpush) adds a new element to the head of a list; [`RPUSH`](https://redis.io/commands/rpush) adds to the tail
* [`LPOP`](https://redis.io/commands/lpop) removes and returns an element from the head of a list; [`RPOP`](https://redis.io/commands/rpop) does the same but from the tails of a list
* [`LLEN`](https://redis.io/commands/llen) returns the length of a list
* [`LMOVE`](https://redis.io/commands/lmove) atomically moves elements from one list to another
* [`LTRIM`](https://redis.io/commands/ltrim) reduces a list to the specified range of elements

### Blocking commands

> 常用于生产者消费者模式？？？

支持不同的阻塞命令

* [`BLPOP`](https://redis.io/commands/blpop) removes and returns an element from the head of a list. If the list is empty, the command blocks until an element becomes available or until the specified timeout is reached

  > 要么阻塞要么超时

## 4. Sets(S)

唯一，但是无序

### Basic commands

* [`SADD`](https://redis.io/commands/sadd) adds a new member to a set

* [`SREM`](https://redis.io/commands/srem) removes the specified member from the set

* [`SISMEMBER`](https://redis.io/commands/sismember) tests a string for set membership

* [`SINTER`](https://redis.io/commands/sinter) returns the set of members that two or more sets have in common (i.e., the intersection)

  > 交集：sinter
  >
  > 差集：sdiff
  >
  > 并集：sunion

* [`SCARD`](https://redis.io/commands/scard) returns the size (a.k.a. cardinality) of a set

## 5. Hashes(H)

非常适合代表“对象”、效率非常高效

### Basic commands

* [`HSET`](https://redis.io/commands/hset) sets the value of one or more fields on a hash
* [`HGET`](https://redis.io/commands/hget) returns the value at a given field
* [`HMGET`](https://redis.io/commands/hmget) returns the values at one or more given fields
* [`HINCRBY`](https://redis.io/commands/hincrby) increments the value at a given field by the integer provided

## 6. Sorted sets(Z)

既有 set 的特征（key不重复）也有 hash 的特征（score，一个key对应一个分数）

基本同set，但是有一个分数；**所以非常适合用于获取范围的元素**，例如：前10，最后10个

### Basic commands

* [`ZADD`](https://redis.io/commands/zadd) adds a new member and associated score to a sorted set. If the member already exists, the score is updated

* [`ZRANGE`](https://redis.io/commands/zrange) returns members of a sorted set, sorted within a given range

* [`ZRANK`](https://redis.io/commands/zrank) returns the rank of the provided member, assuming the sorted is in ascending order

  > 排名：获取前多少的元素

* [`ZREVRANK`](https://redis.io/commands/zrevrank) returns the rank of the provided member, assuming the sorted set is in descending order

## 7. Bitmaps

是 String 数据类型的拓展，可以对象 string 像一个 bit 的向量；因为只能设置 0 和 1，所以适合是否判断的情况

1、操作上分为两组：设置获取值和对组的统计（统计值）

2、判断是否时，提供极大的空间节省（比如配合自增长id，就可以使用512M的空间判断4亿人是否在位图中）

### Basic commands

* [`SETBIT`](https://redis.io/commands/setbit) sets a bit at the provided offset to 0 or 1

* [`GETBIT`](https://redis.io/commands/getbit) returns the value of a bit at a given offset

* [`BITOP`](https://redis.io/commands/bitop) lets you perform bitwise operations against one or more strings

  > 备注：位操作

## 8. HyperLogLog（pf开头，发明算法的人的简写）

是一个概率性的数据结构，用来估算一个 set 的基数（基数就是不重复元素），是一种概率算法存在一定的误差，占用内存只有12kb但是非常适合超大数据量的统计，比如网站访客的统计

### Basic commands

* [`PFADD`](https://redis.io/commands/pfadd) adds an item to a HyperLogLog

* [`PFCOUNT`](https://redis.io/commands/pfcount) returns an estimate of the number of items in the set

  > 返回基数的估算值

* [`PFMERGE`](https://redis.io/commands/pfmerge) combines two or more HyperLogLogs into one

## 9. Geospatial（Geo）

地理位置坐标，即经纬度

### Basic commands

- geoadd：添加地理位置的坐标

- geopos：获取地理位置的坐标

- geodist：计算两个位置之间的距离

- georadius：根据用户给定的经纬度坐标来获取指定范围内的地理位置集合

  > 以某个点为中心，半径多少的范围

- geohash：返回一个或多个位置对象的 geohash 值

  > 备注：
  >
  > 1、返回 hash 值是为了不丢失精度
  >
  > 2、可以根据返回的 hash 值反向计算出经纬度

# Redis 应用

案例 1：生成一个 6 为数字的验证码，每天只能发送 3 次，5 分钟内有效

1、生成 6 个数字验证码（randon类）

2、计数的工具（redis的incr。   并且设计过期时间为24 * 60 * 60秒）

3、吧生成的验证码放入 redis 中

步骤：

1、校验是否满足次数要求

2、生成验证码放入 redis，并修改次数

3、对用户提交的验证码做

# Reids 命令帮助或资源

Redis 官网：<a href="https://redis.io">https://redis.io</a>

源码地址：<a href="https://github.com/redis/redis">https://github.com/redis/redis</a>

Redis 在线测试：<a href="http://try.redis.io">http://try.redis.io</a>

Redis 命令参考：<a href="http://doc.redisfans.com">http://doc.redisfans.com、</a><a href="https://redis.io/commands">https://redis.io/commands</a>（把命令按类 group 进行了分组）

获取 Redis 命令帮助：

1、直接用命令行获取参数的帮助

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-09-17-31-51-image.png)

2、在官方文档的命令帮助中可按组(group)或命令(command)直接查询

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-09-17-37-38-image.png)

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>

