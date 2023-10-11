
# web.xml引起的问题

一下列举常见一些错误原因
* 使用现成的、验证过的web.xml文件
* spring mvc最简单的web.xml配置可以只配置【dispatcherServlet + applicationContext.xml】。不当配置父子容器可以引起问题(作者也碰到过)。
<a href="https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-servlet">只配置dispatcherServlet官网参考</a>
* web.xml不是必须得，推荐使用java config的方式替换。
<a href="https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#mvc-container-config">java config官网参考</a>

作者也提供一个最简基础配置：
```xml
<servlet>
    <servlet-name>app</servlet-name>
    <servlet-class>org.springframework.web.servlet.DispatcherServlet</servlet-class>
    <init-param>
        <param-name>contextConfigLocation</param-name>
        <param-value>classpath:application.xml</param-value>
    </init-param>
    <load-on-startup>1</load-on-startup>
</servlet>

<servlet-mapping>
    <servlet-name>app</servlet-name>
    <url-pattern>/app/*</url-pattern>
</servlet-mapping>
```

# 应用外部tomcat引起的问题

## 字节码错误
方案：在程序中引入跟外部tomcat版本一致的tomcat代码，如下：
```xml
<dependency>
    <groupId>org.apache.tomcat</groupId>
    <artifactId>tomcat-catalina</artifactId>
    // 版本跟外部tomcat一致
    <version>8.5.51</version>
    <scope>provided</scope>
</dependency>
```

## 部署后发现controlelr不生效（95%有效）
正常部署的日志一般有如下特征，会出现配置文件名称、部署时间相对较长、controller映射等。
![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2022-10-28-01-44-03-image.png)

异常部署的特征有时间很短、只能访问静态文件如jsp、不能访问controller、日志不出现web.xml配置内容。

下面是常见解决方案 
### **确认代码位置**
要求代码格式符合规范，交给tomcat部署的代码位置正确。
![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2022-10-28-01-40-46-image.png)
### 确认打包方式**war**包
![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2022-10-28-00-47-37-image.png)

### 部署时是不是下面的图
![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2022-10-28-00-45-36-image.png)
如果不是可以按下图添加，然后重新选择`war exploded`部署即可。
![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2022-10-28-01-04-24-image.png)
