[TOC]

本文主要描述了在Java中使用RMI实现远程方法调用。

# 1. RPC与RMI

## 1.1. 什么是远程过程调用

RPC（Remote Processor Call）就是远程过程调用。是一个概念，既不是技术也不是框架。概念描述了以下信息：

* 客户端把『要调用什么类，什么方法，传什么参数』告诉服务器。

* 服务器根据要求完成调用，并把调用结果响应给客户端。

* 客户端就可以拿到响应的数据。

上面3步完成后，就完成了远程过程调用。 关于RPC的概念可以参考马士兵老师的视频：https://www.bilibili.com/video/BV1zE41147Zq/?from=search&seid=13740626242455157002

## 1.2. 什么是RMI

RMI全称是Remote Method Invocation，其实它可以被看作是RPC的Java版本。Java RMI支持存储于不同地址空间的程序级对象之间彼此进行通信，实现远程对象之间的无缝远程调用。

# 2. 使用Java远程方法调用（RMI）

使用RMI很简单，只需要如下的3个步骤：

* 抽取公共接口代码
* 客户端代码
* 服务端代码

以下以客户端（Client.java）调用服务端（UserServiceImpl.java）获取用户名（getName）为例：

## 2.1. 公共接口代码

这是一个客户端和服务端都依赖的接口，客户端有这个接口就知道服务端提供了哪些功能，服务端需要实现接口来提供功能。

```java
public interface UserService extends java.rmi.Remote {
	public String getName() throws RemoteException;
	public void updateName(String name) throws RemoteException;
}
```

## 2.2. 客户端代码

客户端代码指明了RMI去调用哪个服务器的哪个功能接口的哪个方法传什么参数。

* 客户端的调用代码

```java
public class Client {

	public static void main(String[] args) throws Exception {

		// 指明了我要去连那个服务器
		Registry registry = LocateRegistry.getRegistry("127.0.0.1", 8888);

		// 告诉服务端我需要这个"功能接口"
		UserService user = (UserService) registry.lookup("user");

		// 告诉服务端RPC的调用信息（什么接口、什么方法、什么参数），要求服务端完成调用并返回结果
		System.out.println("远程调用的结果是：" + user.getName());
	}
}
```

## 2.3. 服务端代码

* 注册服务

```java
public class Server {
	public static void main(String[] args) throws Exception {
		UserService liming = new UserServiceImpl();

		// 注册一个端口提供服务
		Registry registry = LocateRegistry.createRegistry(8888);

		// 暴露服务端的功能
		registry.bind("user",liming);

		System.out.println("registry is running...");

		System.out.println("liming is bind in registry");
	}
}
```

* 实现接口功能

```java
public class UserServiceImpl extends UnicastRemoteObject implements UserService {
	public String name;
	public int age;

	protected UserServiceImpl() throws RemoteException {
	}

	public String getName(){
		return "["+ "张三" +"]";
	}

	public void updateName(String name){
		this.name = name;
	}
}
```

## 2.4. RMI调用过程图

原理图如下，需要用户写的只有Client和Server，其它都是RMI系统底层实现。

![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20230813_1.png)
