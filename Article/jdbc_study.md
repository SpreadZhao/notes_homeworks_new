初次接触jdbc，一些比较简单的操作。

# 1. 小试牛刀

使用jdbc去连接mysql，或者是任何数据库，都需要这几个对象：

* JDBC Driver：连接驱动，提供创建java和数据库连接的基本API。
* Connection：连接对象，类似HttpUrlConnection对象。
* Statement：语句执行官，用来执行sql语句。
* Resultset：结果集，用来存放结果结合，本质是一个[[Lecture Notes/Database/db#5.1.4 Cursors|cursor]] ^c627c2

那么接下来，就给出每一步操作。首先是引入需要加载的驱动类。这个类并不是java自带的，而是要到各个数据库厂商对应的地方下载。比如如果要下载connector-java的MySQL版本，就可以到下面的网站：

[MySQL :: Download Connector/J](https://dev.mysql.com/downloads/connector/j/8.0.html)

下载到jar包之后，需要导入到我们的项目之中。然后就可以正常使用它了：

```java
Class.forName("com.mysql.cj.jdbc.Driver");
```

这句话通过一个反射去加载了这个类。有了驱动之后，接下来就开始获得连接对象来真正创建java程序和数据库的连接：

```java
Connection connection = DriverManager.getConnection(url, userName, password);
```

很好理解，但是重点是这三个参数都是什么：

```java
/**
url – a database url of the form jdbc:subprotocol:subname 
user – the database user on whose behalf the connection is being made 
password – the user's password
*/
String url = "jdbc:mysql://127.0.0.1:3306/?serverTimezone=GMT&useUnicode=true&characterEncoding=utf8&useSSL=false";  
String userName = "root";  
String password = "spreadzhao";
```

后面两个很好理解，但是这个url后面跟了很多参数。这些参数在我其他很多项目都做过，所以就只是在这里展示一下：

#TODO show param

- [x] 展示url的参数

在有了连接之后，我们要使用具体的某一个数据库。在mysql中，可以直接使用如`use database1`这种语句去使用。而在jdbc中，就需要这样：

```java
/**
setCatalog(String catalog);

Sets the given catalog name in order to select a subspace of this Connection object's database in which to work.

If the driver does not support catalogs, it will silently ignore this request.

Calling setCatalog has no effect on previously created or prepared Statement objects. It is implementation defined whether a DBMS prepare operation takes place immediately when the Connection method prepareStatement or prepareCall is invoked. For maximum portability, setCatalog should be called before a Statement is created or prepared.

Params:
catalog – the name of a catalog (subspace in this Connection object's database) in which to work

Throws:
SQLException – if a database access error occurs or this method is called on a closed connection
*/
connection.setCatalog("bank303");
```

然后就是在这个数据库中，创建我们执行sql语句的“执行官”了：

```java
/**
Creates a Statement object for sending SQL statements to the database. SQL statements without parameters are normally executed using Statement objects. If the same SQL statement is executed many times, it may be more efficient to use a PreparedStatement object.

Result sets created using the returned Statement object will by default be type TYPE_FORWARD_ONLY and have a concurrency level of CONCUR_READ_ONLY. The holdability of the created result sets can be determined by calling getHoldability.

Returns:
a new default Statement object

Throws:
SQLException – if a database access error occurs or this method is called on a closed connection
*/
Statement statement = connection.createStatement();
```

> createStatement()有许多的重载，我们这里只是最简单的执行sql语句，其实还可以以游标的方式去执行，后面**有可能**会介绍。

再然后，就可以真正去执行我们的sql语句了。这里因为非常简单，所以直接给整个的代码。如果我们的数据库中某张表是这样的：

![[Article/resources/Pasted image 20221107144409.png|300]]

那么我们就可以这样写：

```java
String selectall = "select * from account303";  
ResultSet resultSet = statement.executeQuery(selectall);

while (resultSet.next()){  

    System.out.println("account_number: " + resultSet.getString(1) + " | branch_name: " + resultSet.getString(2) + " | balance: " + resultSet.getDouble(3));  
    
    System.out.println("----------------------------------------");  
}
```

然后就能得到这样的结果：

```shell
account_number: A-001 | branch_name: Downtown | balance: 2122.0
----------------------------------------
account_number: A-101 | branch_name: Downtown | balance: 2122.0
----------------------------------------
account_number: A-102 | branch_name: Perryridge | balance: 1698.0
----------------------------------------
account_number: A-201 | branch_name: Brighton | balance: 3821.0
----------------------------------------
account_number: A-215 | branch_name: Mianus | balance: 2970.0
----------------------------------------
account_number: A-217 | branch_name: Brighton | balance: 3189.0
----------------------------------------
account_number: A-222 | branch_name: Redwood | balance: 2970.0
----------------------------------------
account_number: A-300 | branch_name: Perryridge | balance: 1698.0
----------------------------------------
account_number: A-301 | branch_name: Brighton | balance: 3821.0
----------------------------------------
account_number: A-302 | branch_name: Mianus | balance: 2970.0
----------------------------------------
account_number: A-303 | branch_name: Downtown | balance: 2122.0
----------------------------------------
account_number: A-304 | branch_name: Perryridge | balance: 1698.0
----------------------------------------
account_number: A-305 | branch_name: Round Hill | balance: 1492.0
----------------------------------------
account_number: A-306 | branch_name: Redwood | balance: 2970.0
----------------------------------------
account_number: A-307 | branch_name: Downtown | balance: 2122.0
----------------------------------------
account_number: A-308 | branch_name: Pownal | balance: 1698.0
----------------------------------------
account_number: A-309 | branch_name: Brighton | balance: 3821.0
----------------------------------------
account_number: A-310 | branch_name: Mianus | balance: 2970.0
----------------------------------------
account_number: A-311 | branch_name: Downtown | balance: 2122.0
----------------------------------------
account_number: A-312 | branch_name: Perryridge | balance: 1698.0
----------------------------------------
account_number: A-313 | branch_name: Brighton | balance: 3821.0
----------------------------------------
account_number: A-314 | branch_name: Mianus | balance: 2970.0
----------------------------------------
account_number: A-315 | branch_name: Downtown | balance: 2122.0
----------------------------------------
account_number: A-316 | branch_name: Perryridge | balance: 1698.0
----------------------------------------
account_number: A-317 | branch_name: Brighton | balance: 3821.0
----------------------------------------
account_number: A-318 | branch_name: Mianus | balance: 2970.0
----------------------------------------
account_number: A-319 | branch_name: Downtown | balance: 2122.0
----------------------------------------
account_number: A-320 | branch_name: Perryridge | balance: 1698.0
----------------------------------------
account_number: A-321 | branch_name: Brighton | balance: 3821.0
----------------------------------------
account_number: A-322 | branch_name: Mianus | balance: 2970.0
----------------------------------------
account_number: A-323 | branch_name: Downtown | balance: 2122.0
----------------------------------------
account_number: A-324 | branch_name: Perryridge | balance: 1698.0
----------------------------------------
account_number: A-325 | branch_name: Brighton | balance: 3821.0
----------------------------------------
account_number: A-326 | branch_name: Mianus | balance: 2970.0
----------------------------------------
account_number: A-327 | branch_name: Downtown | balance: 2122.0
----------------------------------------
account_number: A-328 | branch_name: Perryridge | balance: 1698.0
----------------------------------------
account_number: A-329 | branch_name: Brighton | balance: 3821.0
----------------------------------------
account_number: A-330 | branch_name: Mianus | balance: 2970.0
----------------------------------------
account_number: A-331 | branch_name: Downtown | balance: 2122.0
----------------------------------------
account_number: A-332 | branch_name: Perryridge | balance: 1698.0
----------------------------------------
account_number: A-333 | branch_name: Brighton | balance: 3821.0
----------------------------------------
account_number: A-334 | branch_name: Mianus | balance: 2970.0
----------------------------------------
account_number: A-335 | branch_name: Downtown | balance: 2122.0
----------------------------------------
account_number: A-336 | branch_name: Round Hill | balance: 1699.0
----------------------------------------
account_number: A-337 | branch_name: Brighton | balance: 3821.0
----------------------------------------
account_number: A-338 | branch_name: Mianus | balance: 2970.0
----------------------------------------

Process finished with exit code 0

```

注意这里resultSet和迭代器的用法非常像，就是因为[[#^c627c2|前面]]提到过，它本质是一个游标。

最后，我们需要**反向**关闭创建的资源：

```java
resultSet.close();  
statement.close();  
connection.close();
```

这样一个最简单的jdbc测试案例就写好了。下面给出完整代码：

```java
import java.sql.*;  

public class Main {  
    public static void main(String[] args) throws ClassNotFoundException, SQLException {  // 注意try-catch或者抛异常
        Class.forName("com.mysql.cj.jdbc.Driver");  
        String url = "jdbc:mysql://127.0.0.1:3306/?serverTimezone=GMT&useUnicode=true&characterEncoding=utf8&useSSL=false";  
        String userName = "root";  
        String password = "spreadzhao";  
        Connection connection = DriverManager.getConnection(url, userName, password);  
        connection.setCatalog("bank303");  
        Statement statement = connection.createStatement();  
        String selectall = "select * from account303";  
        ResultSet resultSet = statement.executeQuery(selectall);  
        while (resultSet.next()){  
            System.out.println("account_number: " + resultSet.getString(1) + " | branch_name: " + resultSet.getString(2) + " | balance: " + resultSet.getDouble(3));  
            System.out.println("----------------------------------------");  
        }  
        resultSet.close();  
        statement.close();  
        connection.close();  
    }  
}
```

# 2. Maven使用&初步封装

接下来，我们要使用maven去配置一个仓库。maven和gradle都是为了让我们更好得管理依赖而产生的工具，它们的使用并不难。首先，我们要[[software_qa#修改maven仓库位置|配置好本地的maven仓库]]，因为使用默认配置我感觉很不爽。然后，我们新建一个maven项目：

![[Article/resources/Pasted image 20221115113328.png]]

并且还可以做如下自定义设置：

![[Article/resources/Pasted image 20221115113414.png]]

这三个分别是包名，工程id，版本号。在新建完成之后，maven就会自动下载依赖到已经配置好的本地仓库中了。等下载完之后，我们就可以开始真正搭建jdbc了。

首先，在根目录下新建这样的文件夹，这里保存的是我们的配置文件：

![[Article/resources/Pasted image 20221115113603.png]]

在`db.properties`中写的就是mysql的几个基本属性：

```properties
jdbc.driver=com.mysql.cj.jdbc.Driver  
jdbc.url=jdbc:mysql://localhost:3306/?serverTimezone=GMT&useUnicode=true&useSSL=false  
jdbc.username=root  
jdbc.password=spreadzhao
```

然后，我们需要新建一个工具类，来初始化连接。在`org.example`包下新建`util`包，并在其中新建`JdbcUtil`类：

```java
public class JdbcUtil {  
    private static Properties properties = null;  
    private static final String dbConfig = "dbconfig/db.properties";  
  
    static {  
        properties = new Properties();  
        InputStream inputStream = Thread.currentThread().getContextClassLoader().getResourceAsStream(dbConfig);  
        try {  
            properties.load(inputStream);  
            System.out.println(properties.getProperty("jdbc.driver"));  
        }catch (IOException e){  
            e.printStackTrace();  
        }  
    }  
  
    public static void main(String[] args) {  
  
    }  
}
```

在java中加载配置文件有两种方式，分别是`Properties`工具类和`ResourcesBundle`。zfh在写我们的[[Projects/android/spreadshop/spread_shop_report#^31c4af|SpreadShop项目]]时使用的就是后者。它们的区别可以参考下面的网站：

[(29条消息) ResourceBundle与Properties_黄爱岗的博客-CSDN博客_resourcebundle 与 properties](https://blog.csdn.net/huangaigang6688/article/details/49496445)

[(29条消息) 属性文件操作:Properties和ResourceBundle_剑小纯的博客-CSDN博客](https://blog.csdn.net/xiaoyao2246/article/details/88534961)

这里我们使用的是`Properties`，而它最重要的操作就是调用`load`函数，它接收一个输入流，所以我们需要将当前类的类加载器获取到然后把我们之前写的配置文件变成输入流。这样操作后，我们就可以使用`getProperty`函数去获取每个key对应的属性了。

运行下面的空main函数，就能输出`jdbc.driver`后面对应的值：

```shell
com.mysql.cj.jdbc.Driver
```

另外注意一点，由于这些属性都是在程序一开始就要使用的，所以要写成静态类，并使用静态代码块去加载它们。

成功之后，下一步就完全是按照我们之前的步骤来了：加载Driver，创建Connection。我们先做这两步。首先，在静态代码块中加载上Driver：

```java
try {  
    properties.load(inputStream);  
    System.out.println(properties.getProperty("jdbc.driver"));  
    Class.forName(properties.getProperty("jdbc.driver"));  // load Driver
}catch (IOException e){  
    e.printStackTrace();  
} catch (ClassNotFoundException e) {  
    throw new RuntimeException(e);  
}
```

然后我们可以将获得Connection的操作封装成一个方法：

```java
public static Connection getConnection(){  
    String url = properties.getProperty("jdbc.url");  
    String uName = properties.getProperty("jdbc.username");  
    String pswd = properties.getProperty("jdbc.password");  
    Connection rs = null;  
    try {  
        rs = DriverManager.getConnection(url, uName, pswd);  
    } catch (SQLException e) {  
        throw new RuntimeException(e);  
    }  
    return rs;  
}
```

# 3. 对接作业

~~为了对接我的数据库最后一次上机作业，这里直接用jdbc+swing写一个图形界面。~~

好吧，我没有用jdbc，更没有用swing。只是用了mybatis plus和android。我还是选择在自己熟悉的平台上操作。下面是我的报告：

[[Homework/Database/4. journey_reserve_system]]