[TOC]

> 前言：请了解什么是CORS（跨域）
>
> 参考：https://gitee.com/firefish985/article-list/tree/master/Spring/Spring Web MVC/CORS/Spring MVC中的跨域概念名词解释.md

# 1. Spring MVC如何处理跨域请求呢

如果用一句话总结，其实非常简单：拦截请求根据跨域CORS的配置情况拒绝请求、设置一些响应头、允许请求

* 拒绝请求
* 给response添加一些CORS相关的响应头
* 允许请求

**主要目的就是添加一些CORS相关的响应头。**

# 2. Spring MVC处理CORS的几个组件

## 2.1. CorsFilter

* 作用

作用在CorsFilter类的注释上已经解释的很好了。

1、处理CORS preflight requests

2、拦截intercepts CORS simple and actual requests，并交给CorsProcesso（默认实现是DefaultCorsProcesso），处理的目的是根据CorsConfigurationSource**添加相关的响应头**

* CorsFilter的结构

```java
public class CorsFilter extends OncePerRequestFilter {

	private final CorsConfigurationSource configSource;

	private CorsProcessor processor = new DefaultCorsProcessor();
}
```

从CorsFilter的结构也能看出，它只包含了2个成员变量。`configSource`表示跨域配置，`processor`表示如何处理跨域。

* CorsFilter的详细原理

如果读者要研究详细的原理，请参考Spring源码的测试类`org.springframework.web.filter.CorsFilterTests`，作者在我的Spring 5源码研究项目`https://gitee.com/firefish985/spring-framework-deepanalysis`中有非常详细的介绍和说明，请参考。

## 2.2. @CrossOrigin

* 作用

用于特定的handler classes或特定的handler methods处理跨域请求。关键词：特定的，局部的，不是全局的

* CrossOrigin的使用

```java
@CORSsOrigin(maxAge = 3600)
@RestController
@RequestMapping("/account")
public class AccountController {

    @CORSsOrigin("http://domain2.com")
    @GetMapping("/{id}")
    public Account retrieve(@PathVariable Long id) {
        // ...
    }
}
```

* CrossOrigin的原理

如果读者要研究详细的原理，请参考Spring源码的测试类`org.springframework.web.servlet.mvc.method.annotation.CrossOriginTests`，作者在我的Spring 5源码研究项目`https://gitee.com/firefish985/spring-framework-deepanalysis`中有非常详细的介绍和说明，请参考