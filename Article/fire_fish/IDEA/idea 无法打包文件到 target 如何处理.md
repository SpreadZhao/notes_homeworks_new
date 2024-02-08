# 1. 一般原因就是文件的资源没有设置

比如常见的 maven 项目，必须标记资源的类别，否则就有可能无法编译到target

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230720_4.png)

# 2. 还有可能是打包的配置中没有包含xxx.xml,xxx.sql等

maven 插件默认只会打包标准 maven 项目的文件，像我们在 java 目录添加的如：xxx.sql、xxx.xml文件等可能就不会打包（如下图）

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/20180113180018014)

这种情况你需要配置打包插件（如下）

```xml
<build>
    <!-- 资源目录 -->    
    <resources>    
        <resource>    
            <!-- 设定主资源目录  -->    
            <directory>src/main/java</directory>       
            <includes>
                <include>**/*.xml</include>
            </includes>     
            <excludes>  
                <exclude>**/*.yaml</exclude>  
            </excludes>  
            <filtering>true</filtering>     
        </resource>  			
    </resources> 	
</build>
```

# 3. 还有一种情况是，因为缓存

Idea 的很多奇怪的问题，很大可能就是因为缓存，一般可以通过`清除缓存并重启`很好的解决

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230720_1.png)

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230720_3.png)