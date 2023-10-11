# 本项目用作测试 git 作为微服务的配置中心

本文描述了 Spring Cloud Config 会加载哪些配置文件，以及如何在 git 仓库中合理的安排这些配置文件的结构

# 1. Spring Cloud Config 加载哪些配置文件

基于 Spring 处理浏览器访问配置中心文件的请求处理器默认只处理一下 2 种形式的请求

* `/{label}/{name}-{profiles}.yml` 【这种更常用】
* `/{name}/{profiles:.*[^-].*}`

其中 label 被解析为 git 分支，name 被解析为配置文件的名称，profiles 被解析为 profiles，再加上 Spring 的默认配置文件有固定的 `application` ，所以当 `http://localhost:8080/master/order-dev.yml` 请求从浏览器发出，它找的是 git 的 master 分支上所有与 `order`、`application`、`order`、`yml` 相关的文件。即可能是：

```text
/order.yml
/order-dev.yml
/application.yml
/application-dev.yml
.....等等
```

> 注意是包括但不仅限于以上文件

<mark>注意注意即使浏览器 uri 中没有 application 也会加载 application.yml 等文件</mark>

**有个记忆技巧，就是把 git 当做 classpath 看待，原本 spring boot 如何查找配置文件现在也如何查找配置文件，这就很好理解了。**

> 其实作者看了一下 Spring Cloud Config 的原理，就是在配置中心启动时从 git 上把配置文件拉下来，然后完全是按照 classpath 来处理浏览器的请求的

# 2. git 作为配置中心存放配置文件的一些规则

> 原则是不要给自己找一些麻烦来解决

基于上面对配置中心原理的浅显讲解，提出了以下一些规则需要遵守：

1. 所有配置文件要求 `.yml` 结尾

2. 浏览器的请求对应到 git 上的规则

   如请求 `http://localhost:8080/master/order-dev.yml` 对应到 git 上规则是：

   > master 被解析为 git 分支
   >
   > order 被解析为 服务的名称（也包括 spring boot 默认的 application 哦哦）
   >
   > dev 被解析为 profiles
   >
   > 解析规则是基于上面提到的『`路径匹配`』

3. 如果把 git 作为多个项目的配置源

   给每个微服务分配一个文件夹，文件夹的名称是微服务名称；在文件夹内部写 `application.yml` 等配置文件。举例如下：

   > ```text
   > /order/application.yml
   > /order/application-dev.yml
   > /product/application.yml
   > /product/application-dev.yml
   > ```
   >
   > 当然写的如：`微服务名称.yml`、`微服务名称-dev.yml` 等文件也会加载，但是非常不建议

4. git 主目录不写任何配置文件，配置文件都要放到微服务的文件夹内

# 3. 参考资料

规划化的 git 仓库参考：<a href="https://gitee.com/firefish985/springcloud-config">https://gitee.com/firefish985/springcloud-config</a>

对 Spring Boot 默认加载 `application.yml` 等文件的理解

通过 debug 方式知道了 Spring 解析请求的规则

