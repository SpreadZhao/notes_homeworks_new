
@[TOC](文章结构)

本文介绍一个在 Mybatis 中不常见的操作，但是可能有些朋友刚好需要用到，<mark>Mybatis 如何实现返回多个结果集</mark>

**什么情况会返回多个结果集**：

* 存储过程
* 多个 select 语句

具体过程如下（作者实测：跟着观战就完事了）：

1、首先你要在 url 连接中开启『`多结果集查询`』`allowMultiQueries=true`
```xml
url: jdbc:mysql://localhost:3306/football?characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai&rewriteBatchedStatements=true&AllowPublicKeyRetrieval=True&allowMultiQueries=true
```

2、Mybatis 的 mapper 层代码：

```java
List<List<?>> testMultiQueries();
```

> 因为有多个结果，结果集的类型是不一样的，所以用泛型，返回类型定义为 `List<List<?>>`

3、xml 文件代码：

```xml
<!-- 因为我后面用不到第一个结果集，所以随便定义个 Map 来接收 -->
<resultMap id="tempResultMap" type="java.util.Map">
</resultMap>

<!--
	1、在 resultMap 指定多个结果集映射
	2、BaseResultMap 是我要使用的结果集映射，没贴出来
-->
<select id="testMultiQueries" resultMap="tempResultMap,BaseResultMap">
    -- 第一个 select
    SELECT @min_price:=MIN(hafu) as minPrice, @max_price:=MAX(hafu) as maxPrice FROM match_info;
    -- 第二个 select
    SELECT * FROM match_info WHERE hafu=@min_price OR hafu=@max_price;
</select>
```

> 备注：
>
> 1、定义了 2 个 resultMap 结果集。第一个结果集tempResultMap后面用不到随便定义一个，第二个结果集BaseResultMap映射业务类
>
> 2、定义了 2 个 select 语句。会被一起发送给 mysql 服务器，服务器执行后会返回 2 个结果集，mybatis 框架完成 2 个结果集的映射

4、取回多结果集截图
![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-06-02-20-57-27-image.png)

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>
