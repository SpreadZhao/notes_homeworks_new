初次建立spring boot项目的经历。

从[start.spring.io](https://start.spring.io)下载项目，选择maven2.x，jdk17，添加Spring Web，Lombok，Spring DevTool等依赖，下载后在pom.xml中导入spring-jdbc，mybatis-plus-boot-starter，mysql-connector-java，gson等依赖；在resources下新建application.yml配置文件，写入如下信息：

```yml
spring:  
  datasource:  
    username: root  
    password: 'spreadzhao'  
    url: jdbc:mysql://localhost:3306/journey_reserve?serverTimezone=UTC&characterEncoding=utf8&useSSL=false  
    driver-class-name: com.mysql.cj.jdbc.Driver
```

别忘了安装插件！！！Spring Boot Assistant插件，安装后才能识别yml配置。如果以上都做了，但是报各种各样的错误，就看看下面的网站。我反正已经被这个b东西给搞疯了，最后弄好之后已经完全没有了写日志的欲望，它已经把我榨干了。。。

[(29条消息) idea项目启动，报错Cannot run program “D:\java\jdk\jdk1.8\bin\java.exe”_奶酪配榴莲的博客-CSDN博客](https://blog.csdn.net/weixin_52247889/article/details/121415054)

[(29条消息) springboot项目的yml文件不被识别_得得得！的博客-CSDN博客](https://blog.csdn.net/qq_40950903/article/details/108033741)

[(29条消息) 解决 IDEA 社区版没有 Spring Assistant 插件问题_L.B.Messi的博客-CSDN博客_idea没有spring assistant](https://blog.csdn.net/Libing2019/article/details/118701084)

[java - Error creating bean with name 'sqlSessionFactory' defined in class path resource mybatis-spring.xml: - Stack Overflow](https://stackoverflow.com/questions/58974268/error-creating-bean-with-name-sqlsessionfactory-defined-in-class-path-resource)

[(29条消息) SpringBoot3整合MyBatis报错：Property ‘sqlSessionFactory‘ or ‘sqlSessionTemplate‘ are required_程序员十三的博客-CSDN博客](https://blog.csdn.net/ZHENFENGSHISAN/article/details/128010240)

[解决mybatis无法给带有下划线属性赋值问题_java_脚本之家 (jb51.net)](https://www.jb51.net/article/235229.htm)

