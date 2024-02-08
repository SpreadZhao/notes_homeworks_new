[TOC]

`TZ` 是time zone的缩写，是Linux系统上的一个环境变量，该变量决定了使用哪个时区。本文描述了如何正确的修改Linux系统的时区和同步正确的北京时间。

# 1. 查看Linux当前时区

你可以使用如下命令非常容易地就查看到Linux系统的当前时区：

```shell
# 查看当前时间是否正确
date
```

```mysql
# 查看当前的时区是否是北京
echo $TZ
Asia/Tokyo			# 如这个就是东京时区，很明显不是北京
```

```shell
# 或者用date -R查看是不是+0800
date -R
Wed, 28 Jun 2023 08:13:04 +0900		# 这个一看就不是北京时间，不是+0800
```

# 2. 获取时区环境变量TZ的值

> 备注：其实这个步骤的所有操作都是为了获取正确的TZ值，如果你有正确的值直接配置到配置文件 `/etc/profile` 即可

要更改Linux系统时区首先得获知你所当地时区的TZ值，使用`tzselect`命令即可查看到正确的TZ值。

* 执行 `tzselect` 命令

```shell
# 选择查找时区的字符串 TZ 值
tzselect
```

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230628_5.png)

* 选择大洲，亚洲

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230628_6.png)

* 选择国家，中国

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230628_7.png)

* 选择时区，北京

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230628_8.png)

* 最后得到需要配置的TZ值为： `TZ='Asia/Shanghai'`

# 3. 配置环境变量TZ的值

每个Linux系统的登录用户登录时都会读取 `/etc/profile` 文件，所以选择在该文件的末尾添加TZ环境变量

> 备注：如果知道正确的TZ值，那么是不需要去获取TZ的值了

```shell
# 配置TZ值
vim /etc/profile
```

在配置文件最后一行添加内容『`TZ='Asia/Shanghai'; export TZ`』，如下图所示：

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230628_9.png)

# 4. 重新加载配置并检验是否生效

上面步骤配置的TZ值只针对新的登录会话才生效，要想我们这个会话生效需要重新加载一次配置文件，如下：

```shell
# 重新加载配置
source /etc/profile
# 检验时间是否正确
date
date -R
echo $TZ
# 如果时间还是不正确，有网络的可以同步一下北京时间
ntpdate ntp.aliyun.com
```

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>
