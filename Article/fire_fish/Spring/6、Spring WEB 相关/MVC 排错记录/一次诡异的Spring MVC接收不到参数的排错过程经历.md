[TOC]

# 1. 问题背景：

现有如下代码：

```java
@PostMapping(value = "/payment/create")
@ResponseBody
public CommonResult create(Payment payment) {

}
```
乍眼看去是不是很好，至少没啥问题很自然，像大自然一样自然，但是确实是有问题的

**问题现象**：通过postman发送post请求，payment 能收到参数；而通过分布式远程调用却接收不到参数，这是为什么呢

# 2. 问题处理

思路：先看看参数有没有发送过来，其次看看是不是Spring MVC处理参数失败了

* 首先在 `DispatcherServlet` 类的 `doDispatch` 方法上打了一个断点，用IDEA的debug窗口执行如下命令：

```java
// 查看post请求的请求体body
new String(((Http11InputBuffer) ((RequestFacade) request).request.coyoteRequest.inputBuffer).byteBuffer.hb)
```

> 很简单读者自行操作一下，查看请求体body的数据，确认下请求中有没有携带参数
>
> ![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-31-01-41-46-image.png)

通过查看http请求的body，发现参数数据是有的，**也就是说请求有参数但没有解析到变量payment中**。那问题自然出现在参数解析器上面。继续看

* 调查发现postman发送的请求类型是 `multipart/form-data` 类型，也就是表单提交类型，这种类型一般发生在前端直接提交请求到后台，而分布式调用一般是 `contextType=application/json` 类型

> 背景知识：参数解析器（HandlerMethodArgumentResolver）是有顺序的，不同的参数解析器能解析的参数不一样

* 到这里问题大致是定位到了，需要设置正确的contentType类型，接下来就是验证流程

> 原因是代码写的不对，我们代码针对的是表单形式的contentType而分布式环境下发送的是JSON形式的contentType

* 修改代码如下，添加 `@RequestBody` 注解

```java
@PostMapping(value = "/payment/create")
@ResponseBody
public CommonResult create(@RequestBody Payment payment) {

}
```

* 观察到参数payment成功接收到请求数据

# 3. 总结

<mark>总结：分布式环境下，默认都把 `@RequestBody` 和 `@ResponseBody` 注解加上，不给自己找麻烦！！！</mark>

传送门： <a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>

