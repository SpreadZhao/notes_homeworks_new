MySQL 提供了一些非常好的用来演示 MySQL 各项功能的示例数据库，同 Oracle 也提供了示例数据库。但是很少有人知道 MySQL 也提供，或许是因为它没有像 Oracle 一样在安装的时候提供用户安装

## 1 下载 MySQL 的示例数据库

访问：https://dev.mysql.com/doc/

点击： `More`

下拉找到： `Example Databases`

下载图片参考下图：

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-06-17-02-55-23-image.png)

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-06-17-02-56-06-image.png)

## 2 示例数据库介绍以及安装

| 数据库                                                       | 说明                                      | 是否需要下载 | 安装教程                   |
| ------------------------------------------------------------ | ----------------------------------------- | ------------ | -------------------------- |
| world database                                               | 最简单的数据库                            | 下载         | 官方网站有                 |
| world_x database                                             | 类似 world 数据库，稍复杂                 | 下载         | 官方网站有                 |
| sakila database                                              | 复杂，涉及到储存过程、函数、视图等        | 下载         | 官方网站有                 |
| menagerie database                                           |                                           | 下载         | 参考下载文件的 `README.txt` |
| employee data (large dataset, includes data and test/verification suite) | 大数据集，                                | 暂不下载     | 官方网站有                 |
| airportdb database (large dataset, intended for MySQL on OCI and HeatWave) | 大数据集，倾向于在 OCI 和 HeatWave 上使用 | 暂不下载     | 官方网站有                 |

通常只需要使用到 `world database` 、 `world_x database` 、 `sakila database` 、 `menagerie database` ，安装的教程在官方的**HTML Setup Guide**有介绍。特别的 `menagerie database` 安装是在下载文件的 `README.txt` 中介绍的


## 3 后续就是自己使用了

后续学习 MySQL 请参考买一本参考书和查阅官方文档

《MySQL是怎样运行的》

## 4 参考资料

官方文档地址： <a href="https://dev.mysql.com/doc/">https://dev.mysql.com/doc/</a>

官方实例数据库下载地址： <a href="https://dev.mysql.com/doc/index-other.html">https://dev.mysql.com/doc/index-other.html</a>

推荐图书：《MySQL是怎样运行的》，作名: 小孩子4919