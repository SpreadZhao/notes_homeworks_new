## 安装rocketmq-dashboard
1. 下载（release版本）的压缩包
https://github.com/apache/rocketmq-dashboard/archive/refs/tags/rocketmq-dashboard-1.0.0.zip

2. 准备好npm、yarn环境（参考《npm的入门使用.md》）
* 1、安装npm
* 2、安装yarn
* 使用国内镜像
```shell
npm config set registry https://registry.npm.taobao.org/
yarn config set registry https://registry.npm.taobao.org/
npm get registry 
yarn config get registry
```

3. 修改配置
修改其src/main/resources中的application.properties配置文件。
* 原来的端口号为8080，修改为一个不常用的
* 指定RocketMQ的name server地址
![](/Users/apple/Documents/Work/aliyun-oss/dev-images/2022-11-14-00-55-01-image.png)

5. 打包
```shell
mvn clean package -Dmaven.test.skip=true
```

6. 启动和使用
```shell
# 控制台启动
nohup java -jar target/rocketmq-dashboard-1.0.0.jar &
```
访问：http://127.0.0.1:8080

8. 可能报错解决
问题1：一直Fetching packages，因为网络问题
解决：一般的，安装好npm、yarn之后替换为淘宝的镜像可以解决，但是如果你也和我一样替换之后还是一直
Fetching packages，那么可以仔细看看日志，是不是有lock(锁)的关键字，那你把yarn.lock文件
删除之后重新打包应该就好了。


以下是我遇到的问题记录：
问题1：darwin包无法下载
mvn执行过程中的报错解决：
http://www.xrkw.net/article/details/1496302783426039809

1. 手动下载包

网址是：https://registry.npmmirror.com/binary.html?path=node/
根据提示去对应目录下载
如：

2. 根据提示的文件名称正确放入对应目录（可能要改名）

3. 重新打包
```shell
mvn clean package -Dmaven.test.skip=true
```
问题2：yarn包无法下载（Fetching packages fail）