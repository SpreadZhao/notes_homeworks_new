[TOC]

# 1. Redis命令行显示中文乱码

## 1.1. 启动redis-cli时在其后面加上--raw参数

加上`--raw`后中文显示正常了

```shell
root@d6953cbf770c:/data# redis-cli --raw
127.0.0.1:6379> JSON.GET product:1 .name .subTitle
{".name":"小米8",".subTitle":"全面屏游戏智能手机 6GB+64GB 黑色 全网通4G 双卡双待"}
127.0.0.1:6379> 
127.0.0.1:6379> 
127.0.0.1:6379> 
127.0.0.1:6379> JSON.GET product:1 .name .subTitle
{".name":"小米8",".subTitle":"全面屏游戏智能手机 6GB+64GB 黑色 全网通4G 双卡双待"}
127.0.0.1:6379> 
```

## 1.2. 设置连接服务器的客户端为utf8

常用的Linux的客户端工具有`Xshell`、`SecureCRT` 、`PuTTY`、`MobaXterm`、`FinalShell`。设置它们连接Linux的编码为utf8

## 1.3. 设置Linux服务器的编码为utf8

一般的，Linux服务器没有设置就是utf8编码的，设置方法如下：

```shell
export LANG="en_US.UTF-8"
```



