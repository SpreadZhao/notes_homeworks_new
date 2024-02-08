[TOC]

# 1. Docker中搞定Elasticsearch

## 1.1. Docker安装Elasticsearch

1. 下载镜像

   ```shell
   docker pull docker.elastic.co/enterprise-search/enterprise-search:8.7.1
   ```

   > 注：es官方提供了自己的镜像仓库

2. 安装Elasticsearch

   用本地文件跟Docker中的文件映射，方便修改和查看文件。我的本地文件地址换成你自己的地址

   ```shell
   docker run -p 9200:9200 -p 9300:9300 --name elasticsearch_8.7.1 \
   -e "discovery.type=single-node" \
   -e "cluster.name=elasticsearch" \
   -e "ES_JAVA_OPTS=-Xms512m -Xmx1024m" \
   -v /Users/apple/Documents/Work/mydata/elasticsearch_8.7.1/plugins:/usr/share/elasticsearch/plugins \
   -v /Users/apple/Documents/Work/mydata/elasticsearch_8.7.1/data:/usr/share/elasticsearch/data \
   -d elasticsearch:8.7.1
   ```
3. 访问`http://localhost:9200`

   浏览器访问`http://localhost:9200`失败，那看下怎么处理吧

## 1.2. 解决访问http://localhost:9200失败

> https比http更加安全，现在存在很多应用，用http://ip:port不能访问，但用https://ip:port能访问。

既然浏览器访问http://localhost:9200失败，那查看下端口和日志（elasticsearch启动挺慢的，要在启动后测试）看看是不是端口没有开启或日志报错

   ```shell
   telnet localhost 9200
   ```

但是发现端口9200是开启的，那为啥不行呢，用 `curl http://localhost:9200` 试试   ![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230719_4.png)大概意思是没有认证，再用 `docker logs -f elasticsearch_8.7.1` 查看下日志得到如下日志   ![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230719_1.png)

日志的大概意思就是收到了请求但是是在 https 通道上，猜测是不是要用 `https://localhost:9200` 访问。

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230719_3.png)

试了一下确实可以访问，但是需要用户名和密码，密码是什么呢，一般密码是在日志文件中打印的，也只能继续去官网查看消息。

> 现在的elasticsearch对比之前版本加强了安全防护，需要用https且要求用户名和密码

### 1.2.1. 用密码访问方式

1. 去官网找默认用户和密码的信息

   比较遗憾的时按照我们上面的启动方式而不是按照[官网的启动方式](https://www.elastic.co/guide/en/enterprise-search/current/docker.html#docker-image)，是没有办法看到打印出来的日志的密码的（官网的启动方式是可以的），那只能根据官网提示的方式去修改密码

   ```shell
   # 在docker容器中执行命令修改用户elastic的密码
   bin/elasticsearch-reset-password -u elastic
   ```

   ![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230719_5.png)

   用新用户名`elastic`和密码`I7ZU7vuE7Dm=a7weqJ3i`登录`https://localhost:9200`访问成功，会得到如下一串JSON

   ```json
   {
     "name": "04f5d152fa87",
     "cluster_name": "elasticsearch",
     "cluster_uuid": "z0r22Tg3Q4aYpSDJBMJeaQ",
     "version": {
       "number": "8.7.1",
       "build_flavor": "default",
       "build_type": "docker",
       "build_hash": "f229ed3f893a515d590d0f39b05f68913e2d9b53",
       "build_date": "2023-04-27T04:33:42.127815583Z",
       "build_snapshot": false,
       "lucene_version": "9.5.0",
       "minimum_wire_compatibility_version": "7.17.0",
       "minimum_index_compatibility_version": "7.0.0"
     },
     "tagline": "You Know, for Search"
   }
   ```

### 1.2.2. 不用密码访问方式

也有不用密码访问http://localhost:9200的方式，而且在开发测试阶段很推荐使用，方法如下：

1. 进入到docker的elasticsearch_8.7.1容器中，修改配置文件 `config/elasticsearch.yml`

   ```shell
   docker exec -it elasticsearch_8.7.1 /bin/bash
   # 编辑文件
   vi config/elasticsearch.yml
   ```

2. 把有关加密的配置都修改为false

3. 但遗憾的是vi命令在docker容器是没有安装的。常规修改docker容器中文件的方法是`使用主机和容器间来回拷贝`，介绍如下：

   * 拷贝容器文件到主机

     ```shell
     # 拷贝
     docker cp elasticsearch_8.7.1:/usr/share/elasticsearch/config/elasticsearch.yml elasticsearch.yml
     ```

   * 修改文件（把有关加密的都修改为false）

     ![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230719_6.png)

   * 拷贝主机文件回容器覆盖原有的配置

     ```shell
     docker cp elasticsearch.yml elasticsearch_8.7.1:/usr/share/elasticsearch/config/elasticsearch.yml
     ```

     

4. 重启容器`docker restart elasticsearch_8.7.1`访问`http://localhost:9200`发现不要用户名和密码了。哈哈

# 2. 参考资料

我的文章：[《如何查看一个Docker镜像有哪些版本.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《Docker设置国内镜像源.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《Docker快速入门实用教程.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《Docker安装MySQL、Redis、RabbitMQ、Elasticsearch、Nacos等常见服务.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《Docker安装Nacos服务.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《如何修改Docker中的文件.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《Docker容器间的连接或通信方式.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《Docker安装的MySQL如何持久化数据库数据.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《制作Docker私有仓库.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《使用docker-maven-plugin插件构建发布推镜像到私有仓库.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

我的文章：[《解决Docker安装Elasticsearch后访问9200端口失败.md》](https://gitee.com/firefish985/article-list/tree/master/Docker)

---

传送门：[**保姆式Spring5源码解析**](https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍)

欢迎与作者一起交流技术和工作生活

[**联系作者**](https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者)
