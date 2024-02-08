[TOC]

我们使用Docker的目的就是图它方便下载部署，不用常规的经历下载、配置、安装等等繁琐的步骤。但是与此同时Docker也存在一些缺点，像删除容器后数据就都没有了。很显然，不能持久化对于需要数据持久化的MySQL数据库来说是不能接受的，那有没有方式可以解决。

有，通过**挂载方式**

# 1. Docker持久化MySQL

**挂载最大的优点是在删除容器后，该文件依然存在与主机中，下次启动新容器依然可以使用这些数据而不用重新配置一遍环境和恢复数据，这对需要持久化的容器特别友好，如mysql。**

至于使用，通过 `-v` 命令可以把主机中的文件挂载到容器中，在启动容器时指定，举例如下：

```shell
docker run -p 3306:3306 --name mysql \
-v /mydata/mysql/log:/var/log/mysql \
-v /mydata/mysql/data:/var/lib/mysql \
-v /mydata/mysql/conf:/etc/mysql \
-e MYSQL_ROOT_PASSWORD=root  \
-d mysql:5.7
```

# 2. 测试删除MySQL容器后新建容器，数据还在不在

1. 假设，存在名为 mysql_test 的容器中，创建了 spring_test 数据库

2. 现在删除 mysql_test 容器（如果不挂载那么所有数据库都会被删除）

   ```shell
   docker rm mysql_test
   ```

3. 重新安装挂载源文件到新的容器 mysql_test_new 中

   ```shell
   docker run -p 3306:3306 --name mysql_test_new \
   -v /mydata/mysql/log:/var/log/mysql \
   -v /mydata/mysql/data:/var/lib/mysql \
   -v /mydata/mysql/conf:/etc/mysql \
   -e MYSQL_ROOT_PASSWORD=root  \
   -d mysql:5.7
   ```

4. 登录发现原来的数据库 spring_test 的数据任然存在，哈哈，体验很棒

# 3. 参考资料

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
