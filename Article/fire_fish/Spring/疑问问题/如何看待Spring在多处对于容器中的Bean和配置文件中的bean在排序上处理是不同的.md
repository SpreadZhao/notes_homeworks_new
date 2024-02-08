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
	
    ...
 
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

问题：针对几个组件是List类型的。如果是从DispatcherServlet.properties默认配置文件加载的则没有应用Ordered接口排序规则，而对于用户自定义注册的组件应用了排序规则，这是否应该认为Spring MVC没有提供统一的排序方式呢？
这是不是Spring的一个缺陷呢。你是如何理解和看待的。
