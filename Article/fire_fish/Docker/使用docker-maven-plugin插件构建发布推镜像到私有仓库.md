[TOC]

本文描述了在Spring Boot项目中通过docker-maven-plugin插件把项目推送到私有docker仓库中，随后拉取仓库中的项目用docker run运行项目。作者自行构建，质量有保证。

# 1. 用docker-maven-plugin插件推送项目到私服docker

## 1.1. 构建镜像 v1.0

1、要想使用`docker-maven-plugin`，需要在`pom.xml`中添加该插件；

```pom
<build>
     <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
        <plugin>
            <groupId>io.fabric8</groupId>
            <artifactId>docker-maven-plugin</artifactId>
            <version>0.33.0</version>
            <configuration>
                <!-- Docker 推送镜像仓库地址(由于是推送到本地的docker镜像仓库) -->
                <pushRegistry>http://localhost:5000</pushRegistry>
                <images>
                    <image>
                        <!--由于推送到私有镜像仓库，镜像名需要添加仓库地址(相当于告诉去哪里拉取镜像)-->
                        <name>localhost:5000/fire-tiny/${project.name}:${project.version}</name>
                        <!--定义镜像构建行为-->
                        <build>
                            <!--定义基础镜像-->
                            <from>java:8</from>
                            <args>
                                <!-- jar的名称，一般配置为gav的av -->
                                <JAR_FILE>${project.build.finalName}.jar</JAR_FILE>
                            </args>
                            <!--定义哪些文件拷贝到容器中-->
                            <assembly>
                                <!--定义拷贝到容器的目录-->
                                <targetDir>/</targetDir>
                                <!--只拷贝生成的jar包-->
                                <descriptorRef>artifact</descriptorRef>
                            </assembly>
                            <!--定义容器启动命令-->
                            <entryPoint>["java", "-jar","/${project.build.finalName}.jar"]</entryPoint>
                            <!--定义维护者-->
                            <maintainer>firefish</maintainer>
                            <!--使用Dockerfile构建时打开-->
                            <!--<dockerFileDir>${project.basedir}</dockerFileDir>-->
                        </build>
                        <!--定义容器启动行为-->
                        <run>
                            <!--设置容器名，可采用通配符(一般配置为gav的a)-->
                            <containerNamePattern>${project.artifactId}</containerNamePattern>
                            <!--设置端口映射-->
                            <ports>
                                <port>8080:8080</port>
                            </ports>
                            <!--设置容器间连接(即容器需要连接mysql，需要外部环境提供mysql连接)-->
                            <links>
                                <link>mysql:db</link>
                            </links>
                        </run>
                    </image>
                </images>
            </configuration>
        </plugin>
    </plugins>
</build>
```

> 注：注意下db:3306
>
> ```yaml
> spring:
>   datasource:
>     url: jdbc:mysql://db:3306/fire?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai
>     username: root
>     password: root
> ```

2、我们构建镜像之前需要先将项目打包，然后再构建，否则会出错，直接使用如下命令即可

```shell
mvn package docker:build
```

3、打包完成后就可以在我们的本地上看到这个镜像了；

```shell
# 本地运行
[root@linux-local work]# docker images
REPOSITORY                                             TAG              IMAGE ID       CREATED             SIZE
localhost:5000/fire-tiny/fire-tiny-fabric              0.0.1-SNAPSHOT   9b7cf9c38c5d   About an hour ago   680MB
```

4、当然我们也可以设置使用`package`命令时直接打包镜像，修改`pom.xml`，在`<plugin>`节点下添加`<executions>`配置即可；

是额外添加的；不建立这么做在需要的时候在构建docker镜像就好了

```pom
<plugin>
    <groupId>io.fabric8</groupId>
    <artifactId>docker-maven-plugin</artifactId>
    <version>0.33.0</version>
    <executions>
        <!--如果想在项目打包时构建镜像添加-->
        <execution>
            <id>build-image</id>
            <phase>package</phase>
            <goals>
                <goal>build</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

## 1.2. 构建镜像 v2.0

构建镜像 v2.0 是对 v1.0 的升级，原来的缺点有构建docker镜像的步骤和项目的pom代码耦合严重，不利于后期修改且构建过程导致pom文件臃肿肥大。针对这些缺点 v2.0 采用 DockerFile方式把docker镜像的构建步骤和Spring Boot项目的pom文件分离。具体步骤如下：

1、新建DockerFile文件

在项目下新建DockerFile文件，内容自定义，参考内容如下：

```dockerfile
# 该镜像需要依赖的基础镜像
FROM java:8
# 拷贝target下的文件到容器中
ARG JAR_FILE
ADD target/${JAR_FILE} /
# 声明服务运行在8080端口
EXPOSE 8080
# 指定docker容器启动时运行jar包
ENTRYPOINT ["java", "-jar","/fire-tiny-fabric-0.0.1-SNAPSHOT.jar"]
# 指定维护者的名字
MAINTAINER mike
```

2、修改pom文件

构建docker镜像的过程现在只有 `<dockerFileDir>${project.basedir}</dockerFileDir>` 这一行，非常简洁。

```shell
<build>
     <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
        <plugin>
            <groupId>io.fabric8</groupId>
            <artifactId>docker-maven-plugin</artifactId>
            <version>0.33.0</version>
            <configuration>
                <!-- Docker 推送镜像仓库地址(由于是推送到本地的docker镜像仓库) -->
                <pushRegistry>http://localhost:5000</pushRegistry>
                <images>
                    <image>
                        <!--由于推送到私有镜像仓库，镜像名需要添加仓库地址(这个相当于告诉别人拉取镜像的时候去哪里拉取)-->
                        <name>localhost:5000/fire-tiny/${project.name}:${project.version}</name>
                        <!--定义镜像构建行为-->
                        <build>
                            <!--使用Dockerfile构建时打开-->
                            <dockerFileDir>${project.basedir}</dockerFileDir>
                        </build>
                    </image>
                </images>
            </configuration>
        </plugin>
    </plugins>
</build>
```

3、打包、构建、查看镜像

3步一套带走，比原来简洁很多看起来也舒服。

```shell
# 打包构建
mvn clean package docker:build
# 查看本地镜像
docker images
```

## 1.3. 推送到镜像仓库

1、指定build和push推送到私有仓库

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230727_3.png)

2、登录私有仓库地址：http://localhost:8280/，查看到刚推送的镜像

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230727_4.png)

# 2. 拉取私服docker镜像运行

把镜像推送到私有仓库后，就需要拉取镜像到本地并使用镜像啦。

1、拉取镜像到本地

因为我们是本地构建的镜像再推送到私有仓库的，需要先把原先构建的镜像删除，再去私有仓库拉取镜像

```shell
docker rmi "localhost:5000/fire-tiny/fire-tiny-fabric:0.0.1-SNAPSHOT"
docker pull "localhost:5000/fire-tiny/fire-tiny-fabric:0.0.1-SNAPSHOT"
```

2、运行容器

```shell
docker run --rm -d --name fire-tiny-fabric -p 8080:8080 "localhost:5000/fire-tiny/fire-tiny-fabric:0.0.1-SNAPSHOT"
```

3、访问下容器其中的一个接口

```shell
curl -X GET --header 'Accept: application/json' 'http://localhost:8080/brand/list?pageNum=1&pageSize=3'
```

但是比较遗憾，不出意外查看docker日志会显示数据库相关的报错。

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230727_5.png)

这是因为我们在前面步骤中构建fire-tiny-fabric项目的镜像时指定了是需要依赖mysql数据库的但是我们在docker run中没有指定数据库，所以会出现数据库连接方面的错误

4、重新运行容器

* 如果存在使用docker构建的数据库，那通过--link指定mysql数据库：

  ```shell
  docker run --rm -d --name fire-tiny-fabric -p 8080:8080 \
  --link mysql:db \
  "localhost:5000/fire-tiny/fire-tiny-fabric:0.0.1-SNAPSHOT"
  ```

  > 注：mysql:db 中的mysql是容器的名称(--name)，后面的db是构建fire-tiny-fabric时指定变量。--link的原理就是在/etc/hosts里面添加了一个alias的名称。

* 如果是本地自己构建的数据库，那指定ip地址端口

  我们在项目中连接数据库用的是db作为域名，所以只要给容器添加上一个db指向主机ip地址的域名映射就可以

  ```yaml
  spring:
    datasource:
      url: jdbc:mysql://db:3306/fire?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai
      username: root
      password: root
  ```

  ```shell
  # 域名db与主机ip的映射
  docker run --rm -d --name fire-tiny-fabric -p 8080:8080 \
  --add-host=db:192.168.1.6 \
  "localhost:5000/fire-tiny/fire-tiny-fabric:0.0.1-SNAPSHOT"
  ```

```shell
# 测试接口
curl -X GET --header 'Accept: application/json' 'http://localhost:8080/brand/list?pageNum=1&pageSize=3'
```

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230727_6.png)

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
