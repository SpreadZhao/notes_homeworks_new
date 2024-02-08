
@[TOC](文章结构)

## 1 安装

> <mark>官方文档 MySQL 8.0 描述的是 最新版本最新版本的特性，可能跟你安装版本的特性有'小许差异'!!!</mark>，小的差异点很多，不列举了

### 1.1 生产环境安装 MySQL

一般的，我们使用 `RPM` 包的方式完成 `MySQL` 的安装，本教程参考了官方的安装说明，安装的具体步骤如下：

> 什么是 RPM：
>
> rpm（英文全拼：redhat package manager） 原本是 Red Hat Linux 发行版专门用来管理 Linux 各项套件的程序，由于它遵循 GPL 规则且功能强大方便，因而广受欢迎。逐渐受到其他发行版的采用。RPM 套件管理方式的出现，让 Linux 易于安装，升级，间接提升了 Linux 的适用度

1、下载

去 <a href="https://dev.mysql.com/downloads/mysql/">官网下载</a> **RPM Bundle**（包含了所有的rpm包）

> ![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-06-01-03-05-30-image.png)
>
> 注意：
>
> 我们下载的是 RPM Bundle 所包含的 rpm 包列表可能与官方安装文档列出的不一致，请以下载页面的 rpm 包列表为准！！！

2、安装

进入解压的文件夹执行

```shell
# 标准的 mysql 安装，包含服务端和客户端
sudo yum install mysql-community-{server,client,client-plugins,icu-data-files,common,libs}-*
# 只安装客户端
sudo yum install mysql-community-{client,client-plugins,common,libs}-*
```

> 注意：
>
> 1、我们下载的 MySQL 的 rpm 列表可能与官方文档表格列出的不完全一致，这是正常的，是因为小版本的差异
>
> 2、如果以上安装命令报错，那么我们可以选择逐个执行 rpm 包的安装
>
> 以 `mysql-8.0.26-1.el7.x86_64` 版本为例，执行如下命令安装：
>
> ```shell
> rpm -ivh mysql-community-common-8.0.26-1.el7.x86_64.rpm
> rpm -ivh mysql-community-client-plugins-8.0.26-1.el7.x86_64.rpm
> rpm -ivh mysql-community-libs-8.0.26-1.el7.x86_64.rpm
> rpm -ivh mysql-community-client-8.0.26-1.el7.x86_64.rpm
> rpm -ivh mysql-community-server-8.0.26-1.el7.x86_64.rpm
> ```

3、启动

```shell
systemctl start mysqld
```

4、查看初始密码

```shell
sudo grep 'temporary password' /var/log/mysqld.log
```

5、修改密码

```shell
mysql -uroot -p
```

```mysql
# 修改 mysql 密码
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'MyNewPass4!';
```

> 备注：如果设置的密码过于简单，是无法通过密码验证组件验证的，开发测试阶段我们可以卸载密码验证组件

6、卸载"验证密码"组件（可选）

```mysql
mysql> UNINSTALL COMPONENT 'file://component_validate_password';
```

7、还可能需要卸载"验证密码"插件（可选）

```mysql
mysql> UNINSTALL PLUGIN validate_password;
```

8、重新修改密码

```mysql
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';
```

### 1.2 Docker 安装 MySQL

如果只是使用 MySQL 可以用 Docker 安装，但是如果是学习 MySQL 不推荐，因为涉及到配置文件等等的修改，个人认为不是很方便。如下是官方的 Docker 安装参考

参考：https://dev.mysql.com/doc/refman/8.0/en/linux-installation-docker.html

## 2 MySQL 完全卸载（危险操作）

1、先停止服务

先用 service 或 systemctl 停止 mysqld 服务

```shell
systemctl stop mysqld.service
```

2、安全删除文件

查看配置文件 `/etc/my.cnf` 的内容（包含了数据文件位置、日志文件等）

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-06-01-12-01-28-image.png)

再删除其中配置的相关目录或文件

```shell
rm -rf /var/lib/mysql
rm -rf /var/log/mysqld.log
```

3、再删除配置文件 `my.cnf`

```shell
rm -rf /etc/my.cnf
```

4、再删除安装程序

用 yum remove 或  rpm 删除安装程序

```shell
# 查找安装了那些
rpm -qa | grep mysql
# 卸载所有的 mysql 相关的包
yum remove mysql-xxx mysql-xxx mysql-xxx mysql-xxxx
```

## 3 参考资料

官方下载： <a href="https://dev.mysql.com/downloads/mysql">https://dev.mysql.com/downloads/mysql</a>

官方rpm安装教程： <a href="https://dev.mysql.com/doc/refman/8.0/en/linux-installation-rpm.html">https://dev.mysql.com/doc/refman/8.0/en/linux-installation-rpm.html</a>

密码验证组件卸载： <a href="https://dev.mysql.com/doc/refman/8.0/en/validate-password-installation.html">https://dev.mysql.com/doc/refman/8.0/en/validate-password-installation.html</a>

Docker 安装： <a href="https://dev.mysql.com/doc/refman/8.0/en/linux-installation-docker.html">https://dev.mysql.com/doc/refman/8.0/en/linux-installation-docker.html</a>

传送门： <a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>
