[TOC]

本文先后介绍LPG、LPG的实验、官方的[Getting started](https://grafana.com/docs/loki/latest/getting-started/#getting-started)入门案例，非常有意思，过程会耗费几个小时，来一起体验吧！

> 之前一直使用的日志收集方案是ELK，动辄占用几个G的内存，有些配置不好的服务器有点顶不住！最近发现一套轻量级日志收集方案： Loki+Promtail+Grafana（简称LPG）， 几百M内存就够了，而且界面也挺不错的，推荐给大家！
>
> 前言：环境是Linux机器，不是mac，也不是windows！

# 1. LPG简介

LPG日志收集方案内存占用很少，经济且高效！它不像ELK日志系统那样为日志建立索引，而是为每个日志流设置一组标签。下面分别介绍下它的核心组件：

* Promtail：日志收集器，有点像Filebeat，可以收集日志文件中的日志，并把收集到的数据推送到Loki中去。

* Loki：聚合并存储日志数据，可以作为Grafana的数据源，为Grafana提供可视化数据。

* Grafana：从Loki中获取日志信息，进行可视化展示。

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/plg_start_06-5d8f3f5f.jpg)

> 对上图的解释：
>
> 1、每台服务器需要部署一台`Promtail`，责任是**监控采集**这台服务器的日志并**推送**给Loki存储服务，默认是监控和采集`/var/log`目录
>
> 2、Loki负责日志存储
>
> 3、Grafana是数据的可视化，负责读取Loki中的日志

# 2. 安装

> 实现这套日志收集方案需要安装Loki、Promtail、Grafana这些服务，直接使用`docker-compose`来安装非常方便。

我们采用官网的[Install with Docker Compose](https://grafana.com/docs/loki/v2.8.x/installation/docker/#install-with-docker-compose)方案，下面简单介绍下官网的方案。

1、首先您需要安装好Docker Compose（请自行安装）

2、下载docker-compose脚本，然后执行

```shell
wget https://raw.githubusercontent.com/grafana/loki/v2.8.0/production/docker-compose.yaml -O docker-compose.yaml
docker-compose -f docker-compose.yaml up
```

因为网站在国外默认是无法访问的的，作者提供了我下载好的脚本[docker-compose.yaml](https://gitee.com/firefish985/article-list/blob/a7704652a60a4c7672039443571ff0d5a6744dd9/%E5%A4%A7%E6%95%B0%E6%8D%AE/LGP/v1/docker-compose.yaml)可直接使用。读者也可以用参考博客[解决 raw.githubusercontent.com 无法访问的问题](https://www.agedcat.com/post/96c1dcbf.html)尝试解决。本文末尾的附录也提供了完整的脚本和说明。

3、运行成功后，可以使用`docker ps`命令查看到3个服务

```shell
[root@server123 ~]# docker ps
CONTAINER ID   IMAGE                    COMMAND                  CREATED             STATUS              PORTS                                       NAMES
a519d567e6a4   grafana/promtail:2.8.0   "/usr/bin/promtail -…"   About an hour ago   Up About a minute                                               plg-promtail-1
c880ad914857   grafana/grafana:latest   "sh -euc 'mkdir -p /…"   About an hour ago   Up About a minute   0.0.0.0:3000->3000/tcp, :::3000->3000/tcp   plg-grafana-1
dcc6c716cd69   grafana/loki:2.8.0       "/usr/bin/loki -conf…"   About an hour ago   Up About a minute   0.0.0.0:3100->3100/tcp, :::3100->3100/tcp   plg-loki-1
```

# 3. 测试日志方案的效果

## 3.1. 测试1：Promtail监控`/var/log`目录的变化

实验目的：测试Promtail能否监控/var/log目录的变化

实验过程：

1、在/var/log目录下新建一个文件

```shell
# 输出'hello lpg'到/var/log/lpg.log 文件
echo 'hello lpg' > /var/log/lpg.log
```

2、在控制台监控到了/var/log/lpg.log文件

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230730_1.png)

这也就印证了Promtail的作用：监控服务器的特定目录（默认是`/var/log`）的变化并把日志发送给Loki。

3、继续验证

* 如果在`/var/log/test.sql`中输入内容，能被监控到吗？
* 如果在`/var/log/fire/spring.log`中输入内容，能被监控到吗？

## 3.2. 测试2：Grafana可视化查看日志

实验目的：通过可视化平台Grafana查看Promtail监控的日志

实验过程：

1. 登录Grafana，账号密码为`admin:admin`，登录成功后需要添加Loki为数据源，访问地址：http://192.168.56.123:3000/

   ![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/loki_start_01-bb3bd339.png)

2. 运行docker-compose.yml脚本后默认添加了一个Loki数据源

   ![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230730_3.png)

3. 查看下默认添加的数据源。之后你也可以设置下你的Loki访问地址，点击`Save&test`保存并测试，显示绿色提示信息表示设置成功。

   下图中的http://loki:3100是loki是脚本安装的network，可以了解下`docker network`

   ![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230730_7.png)

4. 接下来在`Explore`选择Loki，并输入查询表达式（Loki query）为`{filename="/var/log/lpg.log"}`，就可以看到`测试1`的日志了

   ![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230730_9.png)

## 3.3. 测试3：可以预见部署Spring Boot程序的日志也可以被Grafana查看

实验目的：分布式监控Spring Boot的日志

实验过程：

在实验中，随便新建了一个Spring Boot应用，在Spring Boot的配置文件application.yml中通过`logger.path=/var/log`指定了日志的输出目录是/var/log，Spring Boot日志文件默认输出名称是spring.log，也就是说/var/log/spring.log文件作为输出的日志文件。该文件符合Promtail配置的规则`/var/log/*.log`，所以应该会被监控到，最后在可视化平台Grafana查看是否可以查询到日志。

步骤如下：

1、Spring Boot应用的application.yml部分配置内容

```yml
# 配置日志文件的输出目的地
logging:
  path: /var/log
```

2、准备好的Spring Boot应用的jar包，上传到Promtail服务器

3、启动应用，观察/var/log/spring.log是否有内容

```shell
java -jar fire-tiny-loki-1.0-SNAPSHOT.jar
tail -f /var/log/spring.log
```

4、在可视化平台Grafana搜索日志

登录http://loki:3100，接下来在`Explore`选择Loki，并输入查询表达式（Loki query）为`{filename="/var/log/spring.log"}`，就可以看到`测试1`的日志了

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230730_11.png)

**总结：**每一台服务器都需要部署一个Promtail服务，服务监控特定日志目录，当目录发生变化时把内容发送给Loki进行日志存储，最后在Grafana可视化平台可以看到所有微服务的日志信息。

## 3.4. 踩坑记录

作者属实是被坑惨了，把踩坑过程记录下来以为后事之师。

在`实验1`介绍了，Promtail默认是监控/var/log目录的，但是发生了一些奇怪的问题，作者的/var/log/fire/spring.log、/var/log/test.sql等等这些文件都无法通过Grafana可视化平台查到，为啥，o(╯□╰)o

**分析过程：**

1、能监控到一些文件如前文的/var/log/lpg.log，但是一些文件又监控不到，猜测可能是配置问题

2、进入Promtail容器查看配置文件`/etc/promtail/config.yml`，部分内容如下：

```yml
# ...
# 部分内容
scrape_configs:
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: varlogs
      __path__: /var/log/*.log
```

3、观察配置文件的`__path__: /var/log/*log`，按照这个配置**只会监控/var/log目录下以.log结尾的文件**，那么我们配置的/var/log/fire/spring.log、/var/log/test.sql自然就不会被查询到。既然问题找到那就查询[官网](https://grafana.com/docs/loki/latest/clients/promtail/configuration/#static_configs)，`__path__`采用`glob patterns`，那把配置修改为为`/var/log/**/*.log`试试，这种配置风格也类似ant-style风格，在Spring中也常用，应该问题不大，那就开始修改吧

4、直接修改容器的`/etc/promtail/config.yml`配置内容，但Promtail容器默认没有安装vi等编辑命令，但是没事，我们用Linux最最最原始的`echo`命令来覆写`/etc/promtail/config.yml`文件（主要是偷懒，这种最简单）

```shell
# 1、先进入容器
docker exec -it lpg-promtail-1 /bin/bash
# 2、cat查看内容
cat /etc/promtail/config.yml
# 3、把内容复制到编辑器进行编辑
# 只改动一行，把/var/log/*.log改为/var/log/**/*.log
# 4、把编辑后的内容输出了...处开始覆写
echo '...' > /etc/promtail/config.yml
# 5、最后退出promtail容器
```

重启3个容器

```shell
docker-compose down
docker-compose up
```

5、重启后，创建几个新文件并通过http://192.168.56.123:3100访问

⚠️⚠️⚠️特别注意⚠️⚠️⚠️，下图中filename特指promtail配置中的`__path__: /var/log/**/*.log`，所以使用诸如`/app/logs/fire/spring.log`肯定就访问不到。毕竟主机跟可视化工具Grafana有毛线关系，只有Promtail跟Grafana有关系！

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230731_2.png)

6、通过主机与容器挂载的方式修改Promtail配置文件（5、6步骤任选其一即可）

在主机上修改配置文件，通过主机与容器挂载的方式间接修改了Promtail配置文件，具体步骤如下：

* 停止docker-compose，并删除原来创建的3个docker容器

  ```shell
  # 停止容器
  docker-compose down
  # 删除容器
  docker rm lpg-grafana-1;
  docker rm lpg-loki-1;
  docker rm lpg-promtail-1;
  ```

* 主机上新建配置文件`/app/etc/promtail/config.yml`文件

  拷贝附录中config.yml文件

  ```shell
  # 创建目录
  mkdir -p /app/etc/promtail
  # 复制附录内容填写到...位置
  echo '...' > /app/etc/promtail/config.yml
  ```

  对文件进行微调`__path__`即可

  ```yml
  # ...
  # 部分内容
  scrape_configs:
  - job_name: system
    static_configs:
    - targets:
        - localhost
      labels:
        job: varlogs
        __path__: /var/log/**/*.log
  ```

* 修改部分docker-compose.yml脚本内容如下：

  ```shell
  # 创建目录
  mkdir -p /app/logs
  ```

  ```yml
    # 日志收集器
    promtail:
      image: grafana/promtail
      container_name: lpg-promtail
      volumes:
        # 把主机的/app/logs挂载到容器的/var/log
        - /app/logs/:/var/log/
        - /app/etc/promtail:/etc/promtail/
      # 这里指的是容器内部的/etc/promtail/promtail.yml文件
      command: -config.file=/etc/promtail/promtail.yml
  ```

* 一些准备就绪重启docker-compose

  ```shell
  docker-compose up
  ```

* 重启后，创建几个新文件并通过http://192.168.56.123:3100访问，也是完全没有问题的

# 4. 官方入门案例介绍

> 前言：请准备好Linux的Docker compose环境

在本文前面的部分，单纯的是LPG的入门并没有引入其它一些组件，而在官方的入门案例介绍中体系更庞大引入了其它一些组件。下面我们来一起体验下！[官方Getting starting地址](https://grafana.com/docs/loki/latest/getting-started/#getting-started)

> 本指南帮助读者创建和使用一个简单的Loki集群。该集群旨在进行测试、开发和评估；它将不能满足大多数生产要求。

**实验过程介绍：**

1、测试环境运行flog应用程序来生成日志行。

2、Promtail是测试环境的代理（或客户端），它捕获日志行并通过网关将它们推送到Loki集群。

> 在一个典型的环境中，日志生成应用程序和代理程序一起运行，

3、Grafana提供了一种针对存储在Loki中的日志提出查询并可视化查询结果的方法。

**架构图：**

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/simple-scalable-test-environment.png)

**下面对上图简单说明：**

* flog 是一个开发的测试日志生成器，它可以生成一些常见（如Apache、Nginx、RFC3164或Json）格式的日志

* Promtail监控产生的日志，并推送到gateway（即nginx）的接口。

  > flog 和 Promtail用虚线框起来，理解为客户端

* gateway 其实就是nginx实现请求转发

  > 1、转发Promtail推日志的请求
  >
  > 2、转发Grafana查日志的请求

* Loki write component 负责写gateway推送过来的日志

* Loki read component 负责读取存储在MiniO中的日志

* Grafana 是可视化平台，可用于浏览器访问日志

**官方入门案例实验步骤：**

## 4.1. 获得测试环境

1、准备一个单独的目录

```shell
mkdir evaluate-loki
cd evaluate-loki
```

> 注：启动容器后flog生成的日志是存在在当前文件夹（即evaluate-loki）的隐藏目录`.data`中。

2、下载 `loki-config.yaml`, `promtail-local-config.yaml`, and `docker-compose.yaml` 3个脚本

```shell
wget https://raw.githubusercontent.com/grafana/loki/main/examples/getting-started/loki-config.yaml -O loki-config.yaml
wget https://raw.githubusercontent.com/grafana/loki/main/examples/getting-started/promtail-local-config.yaml -O promtail-local-config.yaml
wget https://raw.githubusercontent.com/grafana/loki/main/examples/getting-started/docker-compose.yaml -O docker-compose.yaml
```

因为网站在国外默认是无法访问的的，作者提供了我下载好的脚本[一个3个脚本](https://gitee.com/firefish985/article-list/tree/a7704652a60a4c7672039443571ff0d5a6744dd9/%E5%A4%A7%E6%95%B0%E6%8D%AE/LGP/v2)可直接使用。读者也可以用参考博客[解决 raw.githubusercontent.com 无法访问的问题](https://www.agedcat.com/post/96c1dcbf.html)尝试解决。本文末尾的附录也提供了完整的脚本和说明。

## 4.2. 部署环境

进入evaluate-loki当前目录，使用下面的命令后台启动

```shell
docker-compose up
```

启动后在控制台可以看到间隔有日志输出，这是flog在起作用输出日志。每一条json日志都被Promtail通过gateway推送到了接口`/loki/api/v1/push`。

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230731_3.png)

访问下http://192.168.56.123:3101/ready看看loki read有没有准备好

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230731_6.png)

访问下http://192.168.56.123:3102/ready看看loki write有没有准备好

查看下docker-compose.yaml脚本中定义的docker容器有没有都启动，都启动应该就没有大问题了。可以看到一共启动了7个服务。

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230731_5.png)

## 4.3. 使用Grafana测试

登录http://192.168.56.123:3000，默认已经配置好了一个datasource，接下来点击`Explore`选择Loki，并输入查询表达式（Loki query）为`{container="evaluate-loki-flog-1"}`，点击查询。

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230731_7.png)

反复点击查询可以查看最新的flog生成的日志，日志每秒一条跟flog的配置完全符合。官网还提供了其他很多查询表达式可自行尝试。

```text
{container="evaluate-loki-flog-1"} |= "GET"
{container="evaluate-loki-flog-1"} |= "POST"
{container="evaluate-loki-flog-1"} | json | status="401"
{container="evaluate-loki-flog-1"} != "401"
```

# 4. 附录

## 4.1. docker-compose脚本文件

脚本文件中定义了3个服务，分别是loki、promtail、grafana，了解下脚本文件还是有必要的！

原始docker-compose文件内容如下（添加了备注）：

```yml
version: "3"

# 创建docker容器的网络，方便互通
networks:
  loki:

services:
  loki:
    image: grafana/loki:2.8.0
    ports:
      - "3100:3100"
    # loki执行的命令是容器中的/etc/loki/local-config.yaml来启动loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - loki

  promtail:
    image: grafana/promtail:2.8.0
    # 执行主机与docker容器的文件挂载关系
    volumes:
      - /var/log:/var/log
    # promtail执行的命令是容器中的/etc/promtail/config.yml来启动promtail
    command: -config.file=/etc/promtail/config.yml
    networks:
      - loki

  grafana:
    environment:
      - GF_PATHS_PROVISIONING=/etc/grafana/provisioning
      - GF_AUTH_ANONYMOUS_ENABLED=true
      - GF_AUTH_ANONYMOUS_ORG_ROLE=Admin
    # grafana启动所执行的脚本
    entrypoint:
      - sh
      - -euc
      - |
        mkdir -p /etc/grafana/provisioning/datasources
        cat <<EOF > /etc/grafana/provisioning/datasources/ds.yaml
        apiVersion: 1
        datasources:
        - name: Loki
          type: loki
          access: proxy 
          orgId: 1
          url: http://loki:3100
          basicAuth: false
          isDefault: true
          version: 1
          editable: false
        EOF
        /run.sh
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    networks:
      - loki
```

## 4.2. local-config.yaml文件

使用docker容器中的`/etc/loki/local-config.yaml`来启动loki。从loki容器中拿出来的原始文件内容如下（添加了备注）：

```yml
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

ruler:
  alertmanager_url: http://localhost:9093

# By default, Loki will send anonymous, but uniquely-identifiable usage and configuration
# analytics to Grafana Labs. These statistics are sent to https://stats.grafana.org/
#
# Statistics help us better understand how Loki is used, and they show us performance
# levels for most users. This helps us prioritize features and documentation.
# For more information on what's sent, look at
# https://github.com/grafana/loki/blob/main/pkg/usagestats/stats.go
# Refer to the buildReport method to see what goes into a report.
#
# If you would like to disable reporting, uncomment the following lines:
#analytics:
#  reporting_enabled: false
```

## 4.3. config.yml文件

使用docker容器中的`/etc/promtail/config.yml`来启动promtail。从promtail容器中拿出来的原始文件内容如下（添加了备注）：

```yml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
- job_name: system
  static_configs:
  - targets:
      - localhost
    labels:
      job: varlogs
      __path__: /var/log/*.log
```

* `erver` 属性配置了 Promtail 作为 HTTP 服务器的行为。
* `positions` 属性配置了 Promtail 保存文件的位置，表示它已经读到了文件什么程度。当 Promtail 重新启动时需要它，以允许它从中断的地方继续读取日志。
* `scrape_configs` 属性配置了 Promtail 如何使用指定的发现方法从一系列目标中抓取日志。
  * `static_configs` 抓取日志静态目标配置，静态配置允许指定一个目标列表和标签集
  * `label` 定义一个要抓取的日志文件和一组可选的附加标签，以应用于由__path__定义的文件日志流。

详细的配置参考：

* Promtail 配置文件说明：https://cloud.tencent.com/developer/article/1824988

* Promtail官方文档：https://grafana.com/docs/loki/latest/clients/promtail/configuration/

## 4.4. 官方入门案例脚本

### 4.4.1. docker-compose.yaml

这个脚本是docker-compose的构建脚本，简单介绍下：

1、定义了架构图中的几个服务（如：flog、nginx、promtail、loki read、loki write、minio、grafana）

2、各个服务的启动基本上是通过`command`或`sh`脚本方式启动的

* flog、loki read、loki write、promtail就是通过command方式
* nginx、minio、grafana就是通过sh脚本方式

3、服务之间是有依赖关系的

* 如loki read、loki write都依赖于minio，minio才是最后提供存储服务的

4、通过`volumes`挂载服务就使用到了下载的`loki-config.yaml`、`promtail-local-config.yaml`配置文件

```yml
---
version: "3"

networks:
  loki:

services:
  read:
    image: grafana/loki:2.8.3
    command: "-config.file=/etc/loki/config.yaml -target=read"
    ports:
      - 3101:3100
      - 7946
      - 9095
    volumes:
      - ./loki-config.yaml:/etc/loki/config.yaml
    depends_on:
      - minio
    healthcheck:
      test: [ "CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3100/ready || exit 1" ]
      interval: 10s
      timeout: 5s
      retries: 5
    networks: &loki-dns
      loki:
        aliases:
          - loki

  write:
    image: grafana/loki:2.8.3
    command: "-config.file=/etc/loki/config.yaml -target=write"
    ports:
      - 3102:3100
      - 7946
      - 9095
    volumes:
      - ./loki-config.yaml:/etc/loki/config.yaml
    healthcheck:
      test: [ "CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3100/ready || exit 1" ]
      interval: 10s
      timeout: 5s
      retries: 5
    depends_on:
      - minio
    networks:
      <<: *loki-dns

  promtail:
    image: grafana/promtail:2.8.3
    volumes:
      - ./promtail-local-config.yaml:/etc/promtail/config.yaml:ro
      - /var/run/docker.sock:/var/run/docker.sock
    command: -config.file=/etc/promtail/config.yaml
    depends_on:
      - gateway
    networks:
      - loki

  minio:
    image: minio/minio
    entrypoint:
      - sh
      - -euc
      - |
        mkdir -p /data/loki-data && \
        mkdir -p /data/loki-ruler && \
        minio server /data
    environment:
      - MINIO_ROOT_USER=loki
      - MINIO_ROOT_PASSWORD=supersecret
      - MINIO_PROMETHEUS_AUTH_TYPE=public
      - MINIO_UPDATE=off
    ports:
      - 9000
    volumes:
      - ./.data/minio:/data
    healthcheck:
      test: [ "CMD", "curl", "-f", "http://localhost:9000/minio/health/live" ]
      interval: 15s
      timeout: 20s
      retries: 5
    networks:
      - loki

  grafana:
    image: grafana/grafana:latest
    environment:
      - GF_PATHS_PROVISIONING=/etc/grafana/provisioning
      - GF_AUTH_ANONYMOUS_ENABLED=true
      - GF_AUTH_ANONYMOUS_ORG_ROLE=Admin
    depends_on:
      - gateway
    entrypoint:
      - sh
      - -euc
      - |
        mkdir -p /etc/grafana/provisioning/datasources
        cat <<EOF > /etc/grafana/provisioning/datasources/ds.yaml
        apiVersion: 1
        datasources:
          - name: Loki
            type: loki
            access: proxy
            url: http://gateway:3100
            jsonData:
              httpHeaderName1: "X-Scope-OrgID"
            secureJsonData:
              httpHeaderValue1: "tenant1"
        EOF
        /run.sh
    ports:
      - "3000:3000"
    healthcheck:
      test: [ "CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1" ]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - loki

  gateway:
    image: nginx:latest
    depends_on:
      - read
      - write
    entrypoint:
      - sh
      - -euc
      - |
        cat <<EOF > /etc/nginx/nginx.conf
        user  nginx;
        worker_processes  5;  ## Default: 1

        events {
          worker_connections   1000;
        }

        http {
          resolver 127.0.0.11;

          server {
            listen             3100;

            location = / {
              return 200 'OK';
              auth_basic off;
            }

            location = /api/prom/push {
              proxy_pass       http://write:3100\$$request_uri;
            }

            location = /api/prom/tail {
              proxy_pass       http://read:3100\$$request_uri;
              proxy_set_header Upgrade \$$http_upgrade;
              proxy_set_header Connection "upgrade";
            }

            location ~ /api/prom/.* {
              proxy_pass       http://read:3100\$$request_uri;
            }

            location = /loki/api/v1/push {
              proxy_pass       http://write:3100\$$request_uri;
            }

            location = /loki/api/v1/tail {
              proxy_pass       http://read:3100\$$request_uri;
              proxy_set_header Upgrade \$$http_upgrade;
              proxy_set_header Connection "upgrade";
            }

            location ~ /loki/api/.* {
              proxy_pass       http://read:3100\$$request_uri;
            }
          }
        }
        EOF
        /docker-entrypoint.sh nginx -g "daemon off;"
    ports:
      - "3100:3100"
    healthcheck:
      test: ["CMD", "service", "nginx", "status"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - loki

  flog:
    image: mingrammer/flog
    command: -f json -n 1000 -l
    networks:
      - loki
```

### 4.4.2. loki-config.yaml

```yml
---
server:
  http_listen_port: 3100
memberlist:
  join_members:
    - loki:7946
schema_config:
  configs:
    - from: 2021-08-01
      store: boltdb-shipper
      object_store: s3
      schema: v11
      index:
        prefix: index_
        period: 24h
common:
  path_prefix: /loki
  replication_factor: 1
  storage:
    s3:
      endpoint: minio:9000
      insecure: true
      bucketnames: loki-data
      access_key_id: loki
      secret_access_key: supersecret
      s3forcepathstyle: true
  ring:
    kvstore:
      store: memberlist
ruler:
  storage:
    s3:
      bucketnames: loki-ruler
```

### 4.4.3. promtail-local-config.yaml

```yml
---
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://gateway:3100/loki/api/v1/push
    tenant_id: tenant1

scrape_configs:
  - job_name: flog_scrape 
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s
    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        regex: '/(.*)'
        target_label: 'container'
```

