
## 一、什么是Sharding-JDBC
Sharding-JDBC定位为轻量级Java框架，在Java的JDBC层提供的额外服务。
它使用客户端直连数据库，以jar包形式提供服务，无需额外部署和依赖，可理解为增强版的JDBC驱动，
完全兼容JDBC和各种ORM框架

## 二、Sharding-JDBC能做什么
* 多数据源
* 分库 & 分表
* 读写分离
* 分布式主键
* 分布式事务

## 三、适用项目框架
Sharding-JDBC适用于：
* 何基于Java的ORM框架，如：JPA, Hibernate, Mybatis, Spring JDBC Template或直接使用JDBC。
* 基于任何第三方的数据库连接池，如：DBCP, C3P0, BoneCP, Druid, HikariCP等。
* 支持任意实现JDBC规范的数据库，目前支持MySQL，Oracle，SQLServer和PostgreSQL。


## 疑问
1. 分库分表(sharding) 和 读写分离(masterslave) 是不是不能一起配置，测试的时候反正出问题

## 观察发现
写在前面：关于分库分表，建议不同库中的表名是一样的，而不是（0，2，4；1，3，5），因为拓展性更好，需要更改的更少。
1. 配置很重要
先配置所有真实表，在配置分库规则，最后配置分表规则；一般的，需要配置分布式主键(雪花算法)
2. 如果是in 查询，sharding会对in中的id进行分析，如果发现来则多个表如order_1、order_2，就会把所有参数分别发往
这2个表；如果分析发现只来自一个表，则只发往一个表。
3. 如果分库分表中，不同库中的表是不同的，那么要求"分库分表"必须使用相同的字段；(不然会报错表不存在)。
   如果不同库中的表是相同的，那么"分库分表"字段可以不同。
4. 分库分表字段选择雪花算法的坑：雪花算法-数据量少尽量不取模2或4
注意：雪花ID 水平分割数据库 取模时，一定要避开 用 4、8、12 等取模，避开4的倍数即可！！！！感兴趣的同学可以自己试一下，用4、8、12 等取模结果会如何！
参考：https://blog.csdn.net/white_while/article/details/120901823

# 源码分析
## 与springboot结合的自动配置
从自动配置类SpringBootConfiguration来看，shardingsphere包括以下功能
1、SpringBootShardingRuleConfigurationProperties（配置的前缀: spring.shardingsphere.sharding  **分片**）
2、SpringBootMasterSlaveRuleConfigurationProperties（配置的前缀: spring.shardingsphere.masterslave **主从**）
3、SpringBootEncryptRuleConfigurationProperties（配置的前缀: ）
4、SpringBootPropertiesConfigurationProperties（配置的前缀: ）

```java
@Configuration
@EnableConfigurationProperties({
        // spring.shardingsphere.sharding 开头的配置
        SpringBootShardingRuleConfigurationProperties.class,    // sharding "分片"配置
        // spring.shardingsphere.masterslave 开头的配置
        SpringBootMasterSlaveRuleConfigurationProperties.class,     // masterslave 主从配置
        // spring.shardingsphere.encrypt 开头的配置
        SpringBootEncryptRuleConfigurationProperties.class,     // encrypt 加密配置
        // spring.shardingsphere 开头的配置
        SpringBootPropertiesConfigurationProperties.class})         // 
@AutoConfigureBefore(DataSourceAutoConfiguration.class)
public class SpringBootConfiguration implements EnvironmentAware {

	@Bean
	@Conditional(ShardingRuleCondition.class)
	public DataSource shardingDataSource() throws SQLException {
		return ShardingDataSourceFactory.createDataSource(dataSourceMap, new ShardingRuleConfigurationYamlSwapper().swap(shardingRule), props.getProps());
	}

	@Bean
	@Conditional(MasterSlaveRuleCondition.class)
	public DataSource masterSlaveDataSource() throws SQLException {
		return MasterSlaveDataSourceFactory.createDataSource(dataSourceMap, new MasterSlaveRuleConfigurationYamlSwapper().swap(masterSlaveRule), props.getProps());
	}

	@Bean
	@Conditional(EncryptRuleCondition.class)
	public DataSource encryptDataSource() throws SQLException {
		return EncryptDataSourceFactory.createDataSource(dataSourceMap.values().iterator().next(), new EncryptRuleConfigurationYamlSwapper().swap(encryptRule), props.getProps());
	}
}
```