# Apache服务器配置

## 1. 修改配置文件

该文件位于Apache目录下的`conf/httpd.conf`。打开并编辑这个文件：

```
Define SRVROOT "D:/greenprogram/Apache24"
ServerRoot "${SRVROOT}"
Listen 80
ServerName localhost:80
```

## 2. 安装Apache服务

使用管理员权限打开终端，并输入如下命令：

```shell
httpd -k install -n "Apache24"
```

其中，Apache24是我们可以自定义的服务名。

## 3. 启动Apache服务

在此电脑的服务中打开，或者直接`net start Apache24`都可以打开Apache服务。另外，我们也可以通过`/bin/ApacheMonitor.exe`来检测Apache服务。图形化界面很简洁明了。

## 4. 测试服务

当在浏览器中输入`localhost:80`的时候，显示`It works!`就代表启动成功了。