
@[TOC](文章结构)

# 1 安装：

## 1.1 生产环境安装

> 注意：
>
> 1、如果安装过程有问题可以参考源代码中的 `README.md` 文件
>
> 2、如果服务器只安装一个 `redis` 通常选择 `/usr/local/redis` 作为安装目录，如果安装多台则建议带上 `服务名称` 区分（建议带上 `服务名称` 区分）。以下将以版本号作为区分安装在 `/usr/local/redis-6.2.5` 目录

1、下载、解压

```shell
cd /usr/local/src
wget https://download.redis.io/releases/redis-6.2.5.tar.gz
tar -xzf redis-6.2.5.tar.gz
cd redis-6.2.5
```

2、编译

```shell
make
```

3、Redis 安装在指定的目录（该命令在readme文件中提示）

```shell
make PREFIX=/usr/local/redis-6.2.5 install
```

4、启动先测试下

```shell
# 启动
./bin/redis-server
```

5、启动没问题后，复制配置文件到安装目录（后续步骤是`可选`的，根据需要执行）

```shell
cd /usr/local/redis-6.2.5
mkdir conf
cd conf
# 拷贝配置文件(6379.conf是要使用的配置文件)
cp /usr/local/src/redis-6.2.5/redis.conf redis.conf
cp /usr/local/src/redis-6.2.5/redis.conf redis.conf.back
cp /usr/local/src/redis-6.2.5/redis.conf 6379.conf
```

6、修改配置允许远程访问

```shell
# 编辑配置文件
vim /usr/local/redis-7.0.11-slave01/conf/6380.conf
```

* 注释掉 `bind` 配置

* 关闭保护模式，把 `protected-mode` 设置为 no

* 可以改掉默认的端口号 `6379`

* 关闭防火墙

* 推荐设置密码，属性是 `requirepass`

  > 有如下原因：
  >
  > 1、更加安全
  >
  > 2、副本、哨兵、集群都一般都需要使用到密码
  >
  > 不设置密码原因：
  >
  > 1、麻烦
  >
  > 2、后面的开机启动脚本在设置密码情况下不能完成 redis 的关闭因为要认证，可以使用 kill 命令强制杀死进程但暂时不想去修改脚本

7、官网对配置文件的修改有一些建议，我们针对建议和自己情况做如下修改

```shell
# redis 的数据目录
mkdir /var/redis
mkdir /var/redis/6379

# 编辑配置文件
vim /usr/local/redis-6.2.5/conf/6379.conf
```

关于配置文件的建议及其代码如下：

* Set **daemonize** to yes (by default it is set to no)
* Set the **pidfile** to `/var/run/redis_6379.pid` (modify the port if needed)
* Set the **logfile** to `/var/log/redis_6379.log`
* Set the **dir** to `/var/redis/6379` (very important step!)

```shell
daemonize yes
pidfile /var/run/redis_6379.pid
logfile /var/log/redis_6379.log
dir /var/redis/6379
```

7、修改启动脚本

修改启动脚本文件前面的环境变量

```shell
# 复制开机启动脚本
cp /usr/local/src/redis-6.2.5/utils/redis_init_script /etc/init.d/redis_6379
# 编辑配置文件
vim /etc/init.d/redis_6379

# 把配置文件开头的环境变量修改如下
REDISPORT=6379
EXEC=/usr/local/redis-6.2.5/bin/redis-server
CLIEXEC=/usr/local/redis-6.2.5/bin/redis-cli
PIDFILE=/var/run/redis_${REDISPORT}.pid
CONF="/usr/local/redis-6.2.5/conf/${REDISPORT}.conf"

# 用脚本关闭时需要增加密码才能关闭(修改脚本）
$CLIEXEC -a 你设置的密码 -p $REDISPORT shutdown
```

测试下脚本是否正常

```shell
# 单独测试下启动和关闭脚本
/etc/init.d/redis_6379 start
/etc/init.d/redis_6379 stop
```

8、配置开机启动

启动脚本的文件头部已经写明了服务名称、启动级别、关闭级别，如下图所示：

![image-20230425234244627](/Users/apple/Library/Application Support/typora-user-images/image-20230425234244627.png)

所以下面我们直接执行 `chkconfig` 把配置添加到开机启动中

```shell
# 直接添加就可以了，因为已经指明了启动级别、关闭级别
chkconfig --add redis_6379
```

前面已经单独测试启动脚本是否正常，此处可不必重启测试

```shell
# 重启
reboot
ps -ef | grep redis
```

## 1.2 Docker 安装 Redis（开发测试使用不要太爽）

如果受限于机器性能或只是开发测试可以直接用 Docker 安装，简单方便，还可以快速	安装不同的版本

> **注意**：容器内端口可以一样因为是不同的容器，但映射到主机的端口不可以一样

```shell
# Docker 拉取 redis6.2.5
docker pull redis
# Docker 拉取 redis7.0

# 启动 Docker 的 redis 容器
docker run -d --name redis-test -p 6379:6379 redis
# 进入 redis 容器中，来操作 redis
docker exec -it 9e38ce427c61 redis-cli
```

# 2 Redis 可视化工具

本文推荐一款工具**Redis Insight**，下载的地址是：https://redislabs.com/redisinsight/

> 推荐理由：好用，且官方推荐！

![image-20230426012724754](/Users/apple/Library/Application Support/typora-user-images/image-20230426012724754.png)

其他多种可用工具参考：https://blog.csdn.net/m0_67645544/article/details/125209547

# 3 数据类型

官方参考

```shell
# 各种数据类型总览（含总览和详细命令参考）
https://redis.io/docs/data-types/

# 官方数据类型教程
https://redis.io/docs/data-types/tutorial/

# 在线尝试及人门教程
https://try.redis.io/
```

## 3.1 Redis全局命令（跟key有关系，而跟value无关）

* Keys pattern
* Exists key

* del key
* Expire key second
* Ttl key
* Type key

## 3.2 Strings

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

## 3.3 Lists(L)

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

## 3.4 Sets(S)

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

## 3.5 Hashes(H)

非常适合代表“对象”、效率非常高效

### Basic commands

* [`HSET`](https://redis.io/commands/hset) sets the value of one or more fields on a hash
* [`HGET`](https://redis.io/commands/hget) returns the value at a given field
* [`HMGET`](https://redis.io/commands/hmget) returns the values at one or more given fields
* [`HINCRBY`](https://redis.io/commands/hincrby) increments the value at a given field by the integer provided

## 3.6 Sorted sets(Z)

既有 set 的特征（key不重复）也有 hash 的特征（score，一个key对应一个分数）

基本同set，但是有一个分数；**所以非常适合用于获取范围的元素**，例如：前10，最后10个

### Basic commands

* [`ZADD`](https://redis.io/commands/zadd) adds a new member and associated score to a sorted set. If the member already exists, the score is updated

* [`ZRANGE`](https://redis.io/commands/zrange) returns members of a sorted set, sorted within a given range

* [`ZRANK`](https://redis.io/commands/zrank) returns the rank of the provided member, assuming the sorted is in ascending order

  > 排名：获取前多少的元素

* [`ZREVRANK`](https://redis.io/commands/zrevrank) returns the rank of the provided member, assuming the sorted set is in descending order

## 3.7 Bitmaps

是 String 数据类型的拓展，可以对象 string 像一个 bit 的向量；因为只能设置 0 和 1，所以适合是否判断的情况

1、操作上分为两组：设置获取值和对组的统计（统计值）

2、判断是否时，提供极大的空间节省（比如配合自增长id，就可以使用512M的空间判断4亿人是否在位图中）

### Basic commands

* [`SETBIT`](https://redis.io/commands/setbit) sets a bit at the provided offset to 0 or 1

* [`GETBIT`](https://redis.io/commands/getbit) returns the value of a bit at a given offset

* [`BITOP`](https://redis.io/commands/bitop) lets you perform bitwise operations against one or more strings

  > 备注：位操作

## 3.8 HyperLogLog（pf开头，发明算法的人的简写）

是一个概率性的数据结构，用来估算一个 set 的基数（基数就是不重复元素），是一种概率算法存在一定的误差，占用内存只有12kb但是非常适合超大数据量的统计，比如网站访客的统计

### Basic commands

* [`PFADD`](https://redis.io/commands/pfadd) adds an item to a HyperLogLog

* [`PFCOUNT`](https://redis.io/commands/pfcount) returns an estimate of the number of items in the set

  > 返回基数的估算值

* [`PFMERGE`](https://redis.io/commands/pfmerge) combines two or more HyperLogLogs into one

## 3.9 Geospatial（Geo）

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


# 4 Redis 的持久化方案

## 4.1 Rdb（Redis Database) 方式

Redis 默认的方式，redis 通过快照方式将数据持久化到磁盘中

> 为什么叫做 rdb，因为是 Redis Database 的缩写

### 设置持久化快照的条件

在 redis.conf 中修改持久化快照的条件：

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-05-02-12-31-image.png)

### 持久化文件的存储目录

在 redis.conf 中可以指定持久化文件的存储目录

> 备注：dbfilename 是 Redis Database Filename 的缩写

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-05-02-15-41-image.png)

### Rdb 的问题

一旦 redis 非法关闭，那么会丢失最后一次持久化之后的数据

如果数据不重要，则不必要关心。 如果数据不能允许丢失，那么要使用 aof 方式

> 因为 save 是间隔性触发的

如果数据集很大 RDB 写入磁盘会导致 Redis 短暂的不能提供服务

### Rdb 的优点

是 Redis 数据的一个紧凑的单文件时间点表示

适合大规模的数据恢复

对数据完整性和一致性要求不高

加载速度要比 aof 快得多

## 4.2 Aof（Append Only File） 方式

Redis 默认是不使用该方式持久化的。Aof 方式的持久化，是操作一次 redis 数据库，则将操作的记录存储到 aof 持久化文件中

* 第一步：开启 aof 方式持久化方案。 将 redis.conf 中的 appendonly 改为 yes，即开启 aof 方式的持久化方案

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-05-02-25-42-image.png)

* aof 文件存储的目录和 rdb 方式的一样。 aof 文件存储的名称

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-05-02-26-06-image.png)

在使用 aof 和 rdb 方式时，如果 redis 重启，则数据从 aof 文件加载

### aop 的不足

aof 的文件大小比 rdb 更大，重启使从 aof 文件中恢复速度比 rdb 慢

# 5 应用

案例 1：生成一个 6 为数字的验证码，每天只能发送 3 次，5 分钟内有效

1、生成 6 个数字验证码（randon类）

2、计数的工具（redis的incr。   并且设计过期时间为24 * 60 * 60秒）

3、吧生成的验证码放入 redis 中

步骤：

1、校验是否满足次数要求

2、生成验证码放入 redis，并修改次数

3、对用户提交的验证码做

# 6 相关资源

Redis 官网：https://redis.io/

源码地址：https://github.com/redis/redis

Redis 在线测试：http://try.redis.io/

Redis 命令参考：http://doc.redisfans.com/、https://redis.io/commands/（把命令按类 group 进行了分组）

获取 Redis 命令帮助：

1、直接用命令行获取参数的帮助

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-09-17-31-51-image.png)

2、在官方文档的命令帮助中可按组(group)或命令(command)直接查询

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-09-17-37-38-image.png)

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>

