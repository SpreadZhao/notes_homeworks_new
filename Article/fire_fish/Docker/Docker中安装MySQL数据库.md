[TOC]

[`点击跳转：Docker安装MySQL、Redis、RabbitMQ、Elasticsearch、Nacos等常见服务全套（质量有保证，内容详情）`](https://blog.csdn.net/yuchangyuan5237/article/details/130866065)

# 1. 前言

虽然 docker 安装 mysql 不是一个很好的方案，但是为了个人使用方便，使用 docker 安装 mysql 还是没什么问题的。

且安装时把主机文件挂载到容器上，保证了 mysql 的持久化，对开发和测试也很友好。

# 2. Docker中安装MySQL服务

以下以mysql5.7版本为例，mysql8.0的步骤也是一样的

## 2.1. 查看可用的MySQL版本

```shell
# 搜索镜像
docker search mysql
```

## 2.2. 拉取MySQL镜像

```mysql
# 拉取镜像
docker pull mysql:5.7

# 或者
docker pull mysql:latest
```

## 2.3. 查看本地镜像

使用以下命令来查看是否已安装了 mysql镜像

```mysql
docker images
```

## 2.4. 运行容器

**MySQL是常用的关系型数据库，一般的，希望它能永久的保存数据，哪怕是当容器被删除了数据也不要删除，此时就需要把主机文件夹挂载到容器上，这样可以保证即使容器删除后新建的MySQL容器可以使用之前的数据。**

* 先准备好本地的目录

```shell
mkdir -p /mydata/mysql/log
mkdir -p /mydata/mysql/data
mkdir -p /mydata/mysql/conf
```

* 挂载目录，启动容器

```shell
# Docker启动MySQL容器
docker run -p 3306:3306 --name mysql \
-v /mydata/mysql/log:/var/log/mysql \
-v /mydata/mysql/data:/var/lib/mysql \
-v /mydata/mysql/conf:/etc/mysql \
-e MYSQL_ROOT_PASSWORD=root \
-d mysql:5.7
```

> `-p 3306:3306`：指定宿主机端口与容器端口映射关系
>
> `-v`：挂载主机文件夹 `/mydata/mysql/data` 到 容器`/var/lib/mysq` 挂载点
>
> `-e`：指定容器需要的变量
>
> `-it`：表示交互式终端；
>
> `-d`：后台运行mysql容器

## 2.5. 查看正在运行的容器

```shell
# 查看正在运行的容器
docker ps
# 查看所有的docker容器
docker ps -a
```

这个时候如果显示的是up状态，那就是启动成功了。如果是restarting，说明是有问题的。我们可以查看日志：

```shell
docker logs -f mysql
```

## 2.6. 查看容器内部

```shell
docker exec -it mysql /bin/bash
```

## 2.7. 授权root远程登录

* 进入容器

```shell
docker exec -it mysql /bin/bash
```

* 登录mysql

```shell
mysql -uroot -p
```

* 查看用户、插件

```mysql
mysql> use mysql;
Database changed
mysql> select host,user,plugin from user;
+-----------+---------------+-----------------------+
| host      | user          | plugin                |
+-----------+---------------+-----------------------+
| localhost | root          | mysql_native_password |
| localhost | mysql.session | mysql_native_password |
| localhost | mysql.sys     | mysql_native_password |
| %         | root          | mysql_native_password |
+-----------+---------------+-----------------------+
4 rows in set (0.00 sec)

mysql> 
```

查看结果，不仅仅看到了`root@'localhost'`也看到了`root@'%'`，`root@'%'`就是允许远程登录的账号，跟我们预期的结果还不一样，只能说mysql的docker镜像做的挺良心的，知道docker更多的是用于开发测试，把root的远程登录直接出厂设置了。

* 直接退出吧

## 2.8. 在宿主机连接到容器的MySQL

```mysql
# 用命令行测试端口连通性
telnet localhost 3306
# 查看能不能连接上MySQL
mysql -u root -P 3306 -h 127.0.0.1 -proot
# 查看容器日志
docker logs -f mysql
```

## 2.9. 用Navicat连接容器的MySQL

* 配置连接的参数

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230731_9.png)

* 连接上了

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230731_10.png)

# 3. 如果是MySQL8.0可能需要执行

不得不说，mysql的docker镜像很人性化，**不仅默认出产设置帮我们取消了安全限制，也允许root远程登录**，爆赞、爆赞、爆赞。所以这一步其实什么都不需要做，如果有问题才继续看后面。

> 注：docker安装mysql一般用于开发测试，所以默认出厂设置帮用户做了一些设置。但是Linux下安装的mysql8.0默认是有一些安全限制和限制root远程登录。

## 3.1. 授权root远程登录

* 进入mysql容器

```shell
docker exec -it mysql /bin/bash
```

* 登录mysql

```shell
mysql -uroot -p
```

```mysql
mysql> use mysql
Database changed
mysql> select host,user,plugin from user;
+-----------+------------------+-----------------------+
| host      | user             | plugin                |
+-----------+------------------+-----------------------+
| %         | root             | caching_sha2_password |
| localhost | mysql.infoschema | caching_sha2_password |
| localhost | mysql.session    | caching_sha2_password |
| localhost | mysql.sys        | caching_sha2_password |
| localhost | root             | caching_sha2_password |
+-----------+------------------+-----------------------+
5 rows in set (0.00 sec)

mysql>
```

可以看到出厂就创建了`root@'%'`账号。如果没有就自行创建下把

* 创建root@'%'账号

```shell
mysql> create user root@'%' identified by 'root';
Query OK, 0 rows affected (0.01 sec)

mysql>
```

* 授权所有权限给root@'%'账号

```shell
mysql> grant all on *.* to root@'%';
Query OK, 0 rows affected (0.00 sec)

mysql> 
```

## 3.2. 取消密码强度限制

* 卸载"验证密码"组件

```shell
mysql> UNINSTALL COMPONENT 'file://component_validate_password';
ERROR 3537 (HY000): Component specified by URN 'file://component_validate_password' to unload has not been loaded before.
mysql>
```

> docker的mysql镜像默认没有安装

* 卸载"验证密码"插件

```shell
mysql> UNINSTALL PLUGIN validate_password;
ERROR 1305 (42000): PLUGIN validate_password does not exist
mysql> 
```

> docker的mysql镜像默认没有安装

# 4. 参考资料

[在生产环境安装MySQL 8.0](https://blog.csdn.net/yuchangyuan5237/article/details/130980241)