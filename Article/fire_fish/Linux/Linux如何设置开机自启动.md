@[TOC](文章结构)

# 1. Linux 如何设置开机自启动

<mark>在 `/etc/rc.local` 脚本中写启动命令，是不推荐使用，可能会无效，禁止使用禁止使用禁止使用！！！</mark>

## 方式1，如果是 CentOS6 就用 chkconfig（推荐）

编写脚本关键内容介绍：

* `Provides: redis_6379` 指定了服务的名称

* `chkconfig: 2345 20 80`

  * `2345` 指服务运行级别，一般的，就固定为 `2345` 就好

  * `20` 指定该服务开机启动优先级，值越小越先启动；80指定该服务关机停止优先级，值越小越先关闭；对于有依赖关系的服务注意设置该值的大小

以 redis 服务为例，使用步骤如下：

* 在 `/etc/init.d` 目录编写好脚本

> 推荐脚本名称或服务名称用：关键字+端口号

```shell
cd /etc/init.d
# 编辑服务自启动脚本文件
vim redis_6379
```
```shell
#!/bin/sh
# Provides:		redis_6379			# 指定服务的名称
# chkconfig:	2345 20 80			# 指定服务的缺省启动的运行级、启动优先级、停止优先级
# descriptiong: redis服务的开机启动脚本	# 指定服务的描述
#
# 以上是脚本的头，下面写自己的内容
case "$1" in
    stop)
      /usr/local/scripts/redis_6379 stop
      ;;
    start)
      /usr/local/scripts/redis_6379 start
      ;;
    status)
      echo "请执行ps命令自行查看"
      ;;
    restart)
      /usr/local/scripts/redis_6379 stop
      /usr/local/scripts/redis_6379 start
      ;;
    *)
       echo $"Usage: $0 {start|stop|status|restart}"
      ;;
esac
```
* 加执行权限

```shell
# 加执行权限
chmod 755 redis_6379
```
* 测试效果

```shell
# 停止 服务
service redis_6379 stop
# 启动 服务
service redis_6379 start
# 查看 服务状态
service redis_6379 status
```

* 加入自启动

```shell
# 添加 开机自启动
chkconfig --add redis_6379
# 开启 开机自启动
chkconfig redis_6379 on
# 查看 chkconfig管理的服务列表
chkconfig --list
```

* 删除开机自启动

```shell
# 删除 开机自启动
chkconfig --del redis_6379
```

## 方式2，如果是CentOS7就用systemctl（推荐）

使用步骤如下：

1、进入 `/usr/lib/systemd/system` 目录

```shell
cd /usr/lib/systemd/system
```
2、创建脚本，如 `nacos.service` 文件

3、编写脚本文件（后面有示例）

4、先运行脚本测试

```shell
# 启动 服务
systemctl start nacos.service
```
5、设置开机自启动

```shell
systemctl enable nacos.service
```

关于 `systemclt` 命令的使用
```shell
# 查看 服务状态
systemctl status nacos.service
# 启动 服务
systemctl start nacos.service
# 停止 服务
systemctl stop nacos.service
# 设置 开机自启动
systemctl enable nacos.service
# 禁止 开机自启动
systemctl disable nacos.service
```

# 2. 常见服务的开机自启动脚本

## MySQL 服务

```shell
# 一般安装的mysql都有mysqld.service文件，直接设置开机自启动
systemctl enable mysqld.service
```

## Redis 服务

```shell
cd /usr/lib/systemd/system
vim redis.service
```
redis.service文件
```shell
[Unit]
Description=redis
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/scripts/redis_6379 start
ExecStop=/usr/local/scripts/redis_6379 stop
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

## Nacos 服务

```shell
cd /usr/lib/systemd/system
vim nacos.service
```
nacos.service文件
```shell
[Unit]
Description=nacos
After=network.target
# 设置在mysqld.service服务启动之后启动，因为nacos以来mysql来持久化
After=mysqld.service

[Service]
Type=forking
ExecStart=/usr/local/nacos/bin/startup.sh -m standalone
ExecReload=/usr/local/nacos/bin/shutdown.sh
ExecStop=/usr/local/nacos/bin/shutdown.sh
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

## Sentinel 服务

```shell
cd /usr/lib/systemd/system
vim sentinel.service
```
sentinel.service文件
```shell
[Unit]
Description=sentinel
After=network.target
# 在nacos服务之后启动
After=nacos.service

[Service]
Type=forking
ExecStart=/usr/local/scripts/sentinel.sh
ExecStop=/usr/local/scripts/sentinel_shutdown.sh
PrivateTmp=true

[Install]
WantedBy=multi-user.targe
```

## 其他服务

```shell
mongodb.service
mysqld.service
nacos.service
redis.service
rabbitmq-server.service
sentinel.service
elasticesearch.service
kibana.service
```

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>
