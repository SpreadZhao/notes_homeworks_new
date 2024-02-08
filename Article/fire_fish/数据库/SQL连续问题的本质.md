[TOC]

本文详细介绍如何求解SQL连续问题，连续问题的本质是什么，最后给出了在MySQL5.7和MySQL8.0的求解方案。

> 前言：本文系作者 2019 年原创，谢绝转载

# 1. sql连续问题的概念

sql编程中常听到关于 `连续` 的问题，如：游戏连续签到7天可以获得奖品、计算用户活跃度连续登陆4天即认为活跃等。那么如何写sql算出那些用户满足呢？

# 2. sql连续问题的本质

![表情包，分析一下 的图像结果](https://tse4-mm.cn.bing.net/th/id/OIP-C.RymJ7YqOj6_DLY0bY0-Z4wAAAA?w=155&h=169&c=7&r=0&o=5&dpr=2&pid=1.7)

这里先给出结论后面进行分析：

* 数据库中连续问题的本质就是：`单调递增的等差数列`，嘿，神奇吧跟数学联动起来啦

* 求解方法是：增加额外的等差递增的列，然后进行做差分组。**rowId（编号）** 是一个不错的选择

# 3. 分析过程（可直接看解决方案）

要解决的核心问题有：
 - 连续的概念
 - 怎么使不同的连续区间进入不同的分组

## 3.1. 如何计算用户连续登录7天

假设现在有张表记录了用户的登录日志，如下图，有2列分别是用户id列 `user_id`、登录时间列 `login_time`，一个用户可能有多条记录。问题：找出连续7天都登录的用户，具体是哪7天？

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/20221009_01.png)

![](https://img.tukuppt.com/png_preview/00/05/31/TVV8woZs51.jpg!/fw/780)

## 3.2. 连续登录在数据上的表现形式

怎么才叫连续，昨天登陆了，今天登陆了，就连续两天登陆了；如果明天也会登陆，那么就连续三天登陆了。这种含义在数据上是怎么表现的呢？如下：

* 今天的日期 - 昨天的日期 = 1，说明我连续两天登陆
* 明天的日期 - 今天的日期 = 1，说明我连续三天登陆了。那么差等于1的行都是连续的

但是，下一个问题就是，不同的连续登陆区间要怎么区分？

> 可能有的用户连续登录2天后，间隔了几天之后，又连续登录了3天

## 3.3. 如何用sql表现数据的这种关系

![表情包，砸键盘 的图像结果](https://tse1-mm.cn.bing.net/th/id/OIP-C.LxABEM9Uq9Py95hRh3t4xQAAAA?w=159&h=180&c=7&r=0&o=5&dpr=2&pid=1.7)

基于以上分析可以知道，是不是连续的关键就看做差是否一致，但遗憾的是数据库是非常 **不擅长行与行** 之间的操作，如：下一行减去上一行，数据库 **擅长列与列** 的操作或 **连接** 操作，那能不能把下一行减去上一行的操作转化为列与列的操作呢，考虑增加一列如何？

另外一个问题是我们怎么样保证不同连续区间进入不同分组？如果只是等于1，那么不同的登录区间进入一个分组。既然要分组，那么分组的条件是什么？

为了简单，我们简化一下模型。连续问题往往只有两列数据，那用户登录问题来说，一列是：用户名，一列是登录时间（年月日）
## 3.4. 解决问题

我们拿用户名分组，登录时间分组，或者用户名和登录时间分组都是不合适的，因为他们都不满足我们的要求：把连续登陆数据分到一组来的目的。可是我们的连续数据来源就只有用户名和登录时间，登陆时间是增加的，可能连续的，可能不连续的，**怎么在可能连续可能不连续的记录中找到共同点，成了问题的关键**

<mark>连续登录时间   +   [???]    =    固定的数据</mark>

从以上公式看，连续增加的数据加上什么数据等于不变的数据，必然是加上连续递增等差的数据，在数据库中常见的连续递增的数据是什么，不就是 `序号` ？那么故事的主角 **row_number** 出现了

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/20221009.png)

## 3.5. 结论

![表情包，perfect 的图像结果](https://tse3-mm.cn.bing.net/th/id/OIP-C.PYntdZJLGMdoCF8AtjFwZAAAAA?w=205&h=205&c=7&r=0&o=5&dpr=2&pid=1.7)

👍🏻👍🏻，看到这里其实你大概就已经知道了，尽管我几乎没有画任何分析图，以后不管任何复杂的连续问题都是 <mark>等差数列</mark> 的缩影。到这里其实以上提出的问题都解决了，剩下的大家可以自己思考或者直接看解决方案

# 4. 解决方案

下面描述了处理问题的步骤：

1. 新增一列rownum

   ```mysql
   -- mysql8.0的分窗函数
   ROW_NUMBER() OVER ( ORDER BY login_time ) AS rownum
   ```

   > 只要是等差单调递增的列就可以，在数据库中没有任何理由不用 `row_number`

2. 用时间与新增列做差

   ```mysql
   -- mysql8.0的分窗函数
   COUNT(1) OVER (PARTITION BY login_date - rownum) AS group_count
   ```

   > 如果差一致，说明与时间列相对静止，又新增列是连续的，所以时间列也是连续的，又新增列的单调的，所以不同连续区间的差是不一样的

3. 剩下的你根据需求改巴改巴就OK了
4. 解题完成。

## 4.1. Mysql8.0版本（正确的写法）

```sql
-- 加上新增列
WITH temp01 AS (SELECT user_id, DATE(login_time) AS login_date, ROW_NUMBER() OVER ( ORDER BY login_time ) AS rownum
                FROM user_log),
-- 做差，分组统计
     temp02 AS (SELECT user_id,
                       login_date,
                       COUNT(1) OVER (PARTITION BY login_date - rownum) AS group_count
                FROM temp01)
-- 得到结果
SELECT *
FROM temp02
WHERE group_count >= 3;
```
## 4.2. Mysql5.7版本（正确的写法）

![表情包，爆赞 的图像结果](https://tse4-mm.cn.bing.net/th/id/OIP-C.9HaJ5It3n-FYgARTA37TzQHaHa?w=195&h=196&c=7&r=0&o=5&dpr=2&pid=1.7)

```sql
-- mysql5.7对于这种或其他复杂查询只能使用临时表或者存储过程
CREATE TEMPORARY TABLE temp01 (
    -- 排名
    SELECT @rownum := @rownum + 1 AS rownum, user_id, DATE(login_time) AS login_date
    FROM user_log,
         (SELECT @rownum := 0) t
    ORDER BY login_time);
CREATE TEMPORARY TABLE temp02 (
-- 分组
    SELECT login_date - rownum AS group_id
    FROM temp01
    GROUP BY login_date - rownum
    HAVING COUNT(1) >= 3);
-- 具体业务查询
SELECT *
FROM temp01 a
         INNER JOIN temp02 b
                    ON (login_date - rownum) = b.group_id
```
# 5. 附录番外篇

## 5.1. 背景和问题

只有两列数据：`user_id` 列，`login_time` 列。现在有一下问题：找到连续登陆超过3天的用户

## 5.2. 分析过程

**1、怎么才叫连续登陆？**

答：我昨天登陆了，我今天也登陆了，我明天也登陆，就是连续登陆（现象）

**2、在数据上是什么表现？**

答：如果 `[今天日期-昨天日期=1且明天日期-今天日期=1]` 则说明连续三天登录，也就是错位相减。所以有下面的公式：

<mark>下一行日期 - 上一行日期 = 1【数据上】===> 连续登录【现象上】</mark>

但是数据库是不擅长行与行之间的操作，数据库擅长列与列直接的操作，怎么可以转换？

**3、不同的连续登陆区间(现象上)在数据上就是不同的分组，那么分组的条件是什么**

找到这个分组的 `group_id` 问题就解决了，首先肯定不能是 user_id，也不能是 login_time，但是只有这两列，我们可能需要引入第三方列，那对这个列有什么要求：

1. 这个列要怎么保证不同连续区间的 `group_id` 不同
2. 这个列要怎么保证相同连续区间的 `group_id` 相同

下面我只能说有想象成分:
1. 说根据数学知识，我们知道单调函数每个值，是不同的
2. 根据物理知识，我们知道相对静止的物体，距离是一样的。
3. 相对静止在这里表现为跟时间变化的差一样 ===> 等差数列
4. 单调在这里表现为 ===>  单调递增
5. 等差数列 + 单调递增 ===> 在数据库中用什么表示呢
   于是**row_number**就出现了

**4、结论**

`row_number`可以满足这个要求。
![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/20221009_02.png)
结束!!!

我不允许你看过后以后不会解连续问题！，不然惩罚你狠狠的关注我
