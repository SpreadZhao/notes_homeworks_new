[TOC]

# 1. 跨域中的概念

## 1.1. Origin

* 什么是Origin

Origin是HTTP请求头的一种，一般用于`跨域`。是`跨域`中的概念。

看一个例子：

```http
GET /resources/public-data/ HTTP/1.1
Host: bar.other
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:71.0) Gecko/20100101 Firefox/71.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Connection: keep-alive
Origin: https://foo.example
```

> 请求头有：Origin

* 服务端如何判断Origin

```java
// CorsUtils.class
public static boolean isCorsRequest(HttpServletRequest request) {
    return (request.getHeader(HttpHeaders.ORIGIN) != null);
}
```

* 服务端如何处理Origin

请看**跨域请求处理过程**

## 1.2. PreFlight

* 什么是PreFlight

是跨域（CORS）中的一个个概念。叫做“预飞行”请求。**本质就是一个特殊的浏览器请求。**

看一个请求的例子：

```http
OPTIONS /doc HTTP/1.1
Host: bar.other
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:71.0) Gecko/20100101 Firefox/71.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Connection: keep-alive
Origin: https://foo.example
Access-Control-Request-Method: POST
Access-Control-Request-Headers: X-PINGOTHER, Content-Type
```

> 请求方法是：OPTIONS
>
> 请求头有：Origin
>
> 请求头有：Access-Control-Request-Method

* 服务端如何判断PreFlight

```java
public abstract class CorsUtils {
	public static boolean isPreFlightRequest(HttpServletRequest request) {
		return (isCorsRequest(request) && HttpMethod.OPTIONS.matches(request.getMethod()) &&
				request.getHeader(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD) != null);
	}
}
```

即如果请求（request）携带了`Origin`请求头且请求方法是`OPTIONS`且请求头有`Access-Control-Request-Method`则是`PreFlight`请求。

> PreFlight请求的前提是请求头中一定会有`Origin`

* 服务端如何处理PreFlight

请看**跨域请求处理过程**



# 2. 跨域请求处理过程

1、浏览器发出请求（携带`Origin`请求头）

2、MVC获取到handlerMapping

3、指定handlerMapping的getHandler方法

```java
public final HandlerExecutionChain getHandler(HttpServletRequest request) throws Exception {

    ...
    
    // 如果request有Origin请求头，则给拦截器链添加拦截器
    if (CorsUtils.isCorsRequest(request)) {
        CorsConfiguration globalConfig = this.corsConfigurationSource.getCorsConfiguration(request);
        CorsConfiguration handlerConfig = getCorsConfiguration(handler, request);
        CorsConfiguration config = (globalConfig != null ? globalConfig.combine(handlerConfig) : handlerConfig);
        executionChain = getCorsHandlerExecutionChain(request, executionChain, config);
    }

    return executionChain;
}
```

> 以上方法就是MVC如何处理跨域请求。
>
> 1、如果是`PreFlight`请求，则添加PreFlightHandler到`处理器执行链`
>
> 2、如果是`Origin`请求，则添加CorsInterceptor到`处理器执行链`
>
> 3、这个2个组件的详细执行细节暂时不表。



# 3. 参考

CORS：https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#what_requests_use_cors

Spring处理CORS：https://docs.spring.io/spring-framework/docs/5.0.6.RELEASE/spring-framework-reference/web.html#mvc-cors
