
## 报错一：Failed to connect to 127.0.0.1 port 1181: Connection refused

出现上述的错误是因为使用了 proxy 代理，所以要解决这个问题的关键操作就是要取消代理的设置

查看有没有使用代理

```shell
git config --global http.proxy
```

取消代理设置

```shell
git config --global --unset http.proxy
```

## 报错二：SSL_connect: SSL_ERROR_SYSCALL in connection to github.com:443

查看是否设置了[http]和[https]选项

如果代理设置错误了的话，使用下面语句移除代理

```shell
git config --global --unset http.proxy
git config --global --unset https.proxy
```

传送门： <a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>
