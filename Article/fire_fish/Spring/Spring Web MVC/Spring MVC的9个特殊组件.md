[TOC]

# 1. Spring MVC中的9个特殊组件

DispatcherServlet委托特殊的bean来处理请求并呈现适当的响应。所谓“特殊bean”，我们指的是由spring管理的、实现WebFlux框架契约的对象实例。**它们通常带有内置契约，但您可以自定义它们的属性、扩展或替换它们**

下表列出了一些常见的特殊bean：

| Bean type                             | 描述                                                         |
| ------------------------------------- | ------------------------------------------------------------ |
| **HandlerMapping**                    | **映射一个request到handler上**（handler也包含一系列的前置和后置拦截器）。映射是基于各种HandlerMapping接口实现。<br /> |
| **HandlerAdapter**                    | HandlerAdapter的主要目的是保护DispatcherServlet不受这些细节的影 |
| **HandlerExceptionResolver**          | **处理异常解析器**                                           |
| ViewResolver                          | 视图解析器（如果是前后端分离项目直接忽略该部分）             |
| LocaleResolver, LocaleContextResolver |                                                              |
| ThemeResolver                         |                                                              |
| **MultipartResolver**                 | **文件上传解析器**                                           |
| FlashMapManager                       |                                                              |

# 2. 9个组件的注册原理

* 因为DispatcherServlet也是Servlet，根据Servlet规范会调用Servlet的`public void init(ServletConfig config) throws ServletException;`，最后会调用到DispatcherServlet的初始化会加载如下的代码。

下面代码就是用来初始化DispatcherServlet的9种特殊bean。

```java
// 负责初始化以上各个组件
protected void initStrategies(ApplicationContext context) {
    initMultipartResolver(context);
    initLocaleResolver(context); //
    initThemeResolver(context);
    initHandlerMappings(context);//
    initHandlerAdapters(context);
    initHandlerExceptionResolvers(context);
    initRequestToViewNameTranslator(context);
    initViewResolvers(context);
    initFlashMapManager(context);
}
```

* 以上9个组件的初始化，**除了`MultipartResolver`，其他组件如果用户没有自定义则会从DispatcherServlet.properties加载默认的配置**

> MultipartResolver太特殊了，默认没有配置，也就是说Spring MVC默认是不支持”文件上传“

* `DispatcherServlet.properties`文件内容

```properties
# 刚好是8个组件（除了没有MultipartResolver）
org.springframework.web.servlet.LocaleResolver=org.springframework.web.servlet.i18n.AcceptHeaderLocaleResolver

org.springframework.web.servlet.ThemeResolver=org.springframework.web.servlet.theme.FixedThemeResolver

org.springframework.web.servlet.HandlerMapping=org.springframework.web.servlet.handler.BeanNameUrlHandlerMapping,\
	org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping,\
	org.springframework.web.servlet.function.support.RouterFunctionMapping

org.springframework.web.servlet.HandlerAdapter=org.springframework.web.servlet.mvc.HttpRequestHandlerAdapter,\
	org.springframework.web.servlet.mvc.SimpleControllerHandlerAdapter,\
	org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerAdapter,\
	org.springframework.web.servlet.function.support.HandlerFunctionAdapter


org.springframework.web.servlet.HandlerExceptionResolver=org.springframework.web.servlet.mvc.method.annotation.ExceptionHandlerExceptionResolver,\
	org.springframework.web.servlet.mvc.annotation.ResponseStatusExceptionResolver,\
	org.springframework.web.servlet.mvc.support.DefaultHandlerExceptionResolver

org.springframework.web.servlet.RequestToViewNameTranslator=org.springframework.web.servlet.view.DefaultRequestToViewNameTranslator

org.springframework.web.servlet.ViewResolver=org.springframework.web.servlet.view.InternalResourceViewResolver

org.springframework.web.servlet.FlashM
```

# 3. 对Spring MVC注册组件的质疑

在DispatcherServlet的`protected void initStrategies(ApplicationContext context)`方法中。注册了Spring MVC的特殊组件，但是对于几个List类型的组件，自定义的时候使用了Spring的排序规则`AnnotationAwareOrderComparator`，而对从`DispatcherServlet.properties`加载的配置没有应用排序规则，**是否应该认为Spring没有提供统一的排序方式呢？**

以initHandlerMappings()方法为例：

```java
private void initHandlerMappings(ApplicationContext context) {
    this.handlerMappings = null;
 
        Map<String, HandlerMapping> matchingBeans =
            BeanFactoryUtils.beansOfTypeIncludingAncestors(context, HandlerMapping.class, true, false);
        if (!matchingBeans.isEmpty()) {
            this.handlerMappings = new ArrayList<>(matchingBeans.values());
            // <1> 从容器中获取的bean就应用了排序规则
            AnnotationAwareOrderComparator.sort(this.handlerMappings);
        }
 
 
    if (this.handlerMappings == null) {
        // <2> 针对从DispatcherServlet.properties加载的配置没有应用排序规则
        this.handlerMappings = getDefaultStrategies(context, HandlerMapping.class);
        if (logger.isTraceEnabled()) {
            logger.trace("No HandlerMappings declared for servlet '" + getServletName() +
                         "': using default strategies from DispatcherServlet.properties");
        }
    }
}
```

# 3. 参考

官网：https://docs.spring.io/spring-framework/docs/5.0.6.RELEASE/spring-framework-reference/web.html#mvc-servlet-special-bean-types