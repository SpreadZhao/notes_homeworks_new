
### MyBatis 编程步骤
1. 创建 SqlSessionFactory 对象。
2. 通过 SqlSessionFactory 获取 SqlSession 对象。
3. 通过 SqlSession 获得 Mapper 代理对象。
4. 通过 Mapper 代理对象，执行数据库操作。
5. 执行成功，则使用 SqlSession 提交事务。
6. 执行失败，则使用 SqlSession 回滚事务。
7. 最终，关闭会话。

### 当实体类中的属性名和表中的字段名不一样 ，怎么办？
第一种，通过在查询的 SQL 语句中定义字段名的别名，让字段名的别名和实体类的属性名一致（不使用）

第二种，是第一种的特殊情况。大多数场景下，数据库字段名和实体类中的属性名近似相同，区别是
数据库使用下划线风格，实体类使用驼峰风格，在这种情况下，可以直接配置如下，实现自动的下划线转驼峰的功能
<mark>😈 也就说，约定大于配置。非常推荐！大多数情况使用</mark>
```xml
<setting name="mapUnderscoreToCamelCase" value="true" />
```

第三种，通过 <resultMap> 来映射字段名和实体类属性名的一一对应的关系（个别情况使用）

### 如何使用mybatis实现的批量插入
参考：https://www.jianshu.com/p/cce617be9f9e

结论：
1. **循环插入单条数据虽然效率极低，但是代码量极少**，因此，在需求插入数据数量不多的情况下肯定用它了。
```java
@Transactional
public void add1(List<Item> itemList) {
    itemList.forEach(itemMapper::insertSelective);
}
```
2. **xml拼接sql是最不推荐的方式**，使用时有大段的xml和sql语句要写，很容易出错，工作效率很低。
更关键点是，虽然效率尚可，但是真正需要效率的时候你挂了，要你何用？
3. <mark>**批处理执行**</mark>是有大数据量插入时推荐的做法，使用起来也比较方便。（**推荐**）
实例代码如下：
```java
    public void add(List<Item> itemList) {
        SqlSession session = sqlSessionFactory.openSession(ExecutorType.BATCH,false);
        ItemMapper mapper = session.getMapper(ItemMapper.class);
        for (int i = 0; i < itemList.size(); i++) {
            mapper.insertSelective(itemList.get(i));
            if(i%1000==999){//每1000条提交一次防止内存溢出
                session.commit();
                session.clearCache();
            }
        }
        session.commit();
        session.clearCache();
    }
```

### 如何在 Mapper 接口传递参数
1. 如果只有一个参数，那么其实可以传递`对象`、`Array数组`、`List集合`、`Map集合`
2. 如果有多个参数，强烈推荐使用`@Param`注解

### 在 Mapper 中如何传递多个参数?
第一种，使用 Map 集合，装载多个参数进行传递

第二种，<mark>保持传递多个参数，使用 `@Param` 注解</mark>

### mybatis 如何使用它的缓存
建议MyBatis缓存特性在生产环境中进行关闭，<mark>**单纯作为一个ORM框架使用**</mark>可能更为合适；
针对缓存建议直接使用`Redis`等分布式缓存可能成本更低，安全性也更高。

在MyBatis的配置文件中禁用一级缓存
```xml
<setting name="localCacheScope" value="STATEMENT"/>
```
在MyBatis的配置文件中禁用二级缓存
```xml
<setting name="cacheEnabled" value="false"/>
```

### mybatis的多对多关联查询
mybatis支持一对一的关联查询、一对多的关联查询、多对多的关联查询，我们以多对多关联查询为例。

关联对象查询，有两种实现方式：
1. 一种是单独发送一个 SQL 去查询关联对象，赋给主对象，然后返回主对象。
好处是多条 SQL 分开，相对简单，坏处是发起的 SQL 可能会比较多。
2. 另一种是使用嵌套查询，嵌套查询的含义为使用 `join` 查询，一部分列是 A 对象的属性值，另外一部分列是关联对象 B 的属性值。
好处是只发一个 SQL 查询，就可以把主对象和其关联对象查出来，坏处是 SQL 可能比较复杂。

那么问题来了，`join` 查询出来 100 条记录，如何确定主对象是 5 个，而不是 100 个呢？
其去重复的原理是 `<resultMap>` 标签内的 `<id>` 子标签，指定了唯一确定一条记录的 `id` 列。
Mybatis 会根据 `<id>` 列值来完成 100 条记录的去重复功能，`<id>` 可以有多个，代表了联合主键的语意。

<mark>重点是在使用嵌套查询时，mybatis可以通过 `<id>` 标签实现复杂对象的组装(或者称为去重复对象)</mark>

### 解决 "N+1 查询问题" 的方法
使用 Mybatis 进行复杂对象查询时，有时会有如下情况：
* 你执行了一个单独的 SQL 语句来获取结果的一个列表（就是“+1”）。
* 对列表返回的每条记录，你执行一个 select 查询语句来为每条记录加载详细信息（就是“N”）。

这个问题被称为“N+1 查询问题”。

如何解决 N+1 问题呢？
* 使用嵌套查询（常用）
* 使用存储过程（不会使用）

