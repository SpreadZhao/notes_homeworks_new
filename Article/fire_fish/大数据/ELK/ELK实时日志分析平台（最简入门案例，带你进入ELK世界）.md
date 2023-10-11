[TOC]

本文通过最简单纯正的案例带你入门ELK世界。

# 1. 前言

ELK是Elasticsearch、Logstash、Kibana的缩写，如果对Elasticsearch、Logstash、Kibana不是很了解，可以参考文末的官网入门案例。

# 2. 安装

> 踩坑指南：
>
> * 作者在Mac用Docker或Docker-compose安装ELK环境各个各样的问题，一会是宿主主机权限不够、宿主主机磁盘剩余空间不足等等。
> * 最后还是没处理好，作者放弃了Docker。于是去Linux上用Docker试试，成功算成功了，但是很烦要开启一台Linux虚拟机。
> * 用Docker的目的是要带来方便，既然没有带来方便，我选择使在Mac上用**安装包或压缩包**的方式。

ELK的下载网址是：https://www.elastic.co/cn/downloads/past-releases

以Elasticsearch6.6.2为例：

* 下载

如果您是Windows用户请使用其它下载链接。

```shell
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.6.2.tar.gz
wget https://artifacts.elastic.co/downloads/kibana/kibana-6.6.2-darwin-x86_64.tar.gz
wget https://artifacts.elastic.co/downloads/logstash/logstash-6.6.2.tar.gz
```

# 3. 启动ELK

## 启动Elasticsearch

* 启动Elasticsearch

```shell
curl -L -O https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.6.2.tar.gz
tar -xvf elasticsearch-6.6.2.tar.gz
cd elasticsearch-6.6.2/bin
./elasticsearch
```

* 测试ES启动情况

```shell
curl http://localhost:9200
```

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230801_2.png)

## 启动Kibana

* 启动Kibana

```shell
curl -O https://artifacts.elastic.co/downloads/kibana/kibana-6.6.2-darwin-x86_64.tar.gz
# 校验shasum
shasum -a 512 kibana-6.6.2-darwin-x86_64.tar.gz
tar -xzf kibana-6.6.2-darwin-x86_64.tar.gz
cd kibana-6.6.2-darwin-x86_64/
./bin/kibana
```

* 访问下http://localhost:5601看看是否启动成功

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230722_7.png)

## 启动Logstash

* 新建配置`first-pipeline.conf`

```json
input {
    tcp {
        mode => "server"
        host => "0.0.0.0"
        port => 4560
    	codec => json_lines
    }
}
output {
    elasticsearch {
        hosts => ["http://localhost:9200"]
        index => "springboot-logstash-%{+YYYY.MM.dd}"
    }
}
```

> 接受任何来源的输入数据，不做任何处理，发送到本地的ES中

* 启动

```shell
bin/logstash -f first-pipeline.conf --config.reload.automatic
```

> 配置了`--config.reload.automatic`在修改first-pipeline.conf文件后不用重启

# 4. 测试ELK环境

* 用tcp发送一串json数据给logstash

```shell
echo '{"logstash": "hello world"}' | nc localhost 4560shell
```

* 在kibana中查看刚发送的日志信息hello world

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230804_9.png)

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230804_11.png)

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230804_12.png)

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230804_13.png)

看到了刚放发送的hello world的json消息啦。

# 5. 参考资料

以Elasticsearch6.6.2为例：

* 官方入门

https://www.elastic.co/guide/en/elasticsearch/reference/6.6/getting-started.html

https://www.elastic.co/guide/en/kibana/6.6/getting-started.html

https://www.elastic.co/guide/en/logstash/6.6/getting-started-with-logstash.html

* 作者翻译

[待完成编写]()

[待完成编写]()

[待完成编写]()