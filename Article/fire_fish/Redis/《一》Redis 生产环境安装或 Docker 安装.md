
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

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230425_1.png)

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

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>

