

## 装配原理
当然也是应用springboot的后置处理器完成配置文件到DruidDataSource的属性绑定。
详细的细节我写在了《集成HikariCP连接池.md》一文中。

## DruidDataSource 与 HikaciDataSource 装配原理的比较
1. HikaciDataSource 装配兼容了spring.datasource；采用了2阶段装配，第一阶段通过DataSourceBuilder把spring.datasource
开头的5个基础属性配置好，第二阶段应用boot的属性绑定机制吧hikaci开头的属性也配置好。
2. 而 DruidDataSource 直接采用@autowired吧DataSourceProperties直接装配进来，而不是采用DataSourceBuilder方式，
看起来更加简单容易理解了。哈哈哈。

## 其他问题（疑问待解答）
spring.datasource.druid.filter.stat.log-slow-sql    这些类似的属性好像不在DruidDataSource中，他们是怎么设置的呢