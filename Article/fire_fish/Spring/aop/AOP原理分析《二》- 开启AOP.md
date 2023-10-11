
@[TOC](文章结构)

### 如何开启AOP功能
* 通过注解方式
```java
@Configuration
@EnableAspectJAutoProxy
public class AppConfig {
    
}
```
* 通过xml配置方式
```xml
<aop:aspectj-autoproxy/>
```

### 开启的原理是什么
我们知道Spring提供了众多的拓展接口，BeanPOstProcessor是在bean初始化前后起作用的
重要拓展接口，而aop功能是通过代理实现的，那么很有可能就是通过BeanPostProcessor后置处理器实现的。
这里以xml开启aop为例开始分析：

#### 解析<aop:aspectj-autoproxy/>元素
在spring的xml解析文章中分析了spring解析xml文件的流程，简单回顾一下：
1、根据元素的namespace找到handler（如spring.handlers文件中的AopNamespaceHandler）
2、根据元素的名称找到对应的解析器（如<aop:aspectj-autoproxy/>的解析器是AspectJAutoProxyBeanDefinitionParser）
3、spring会回调解析器的parse方法得到BeanDefinition对象

#### 注册AnnotationAwareAspectJAutoProxyCreator
1、
当通过`@EnableAspectJAutoProxy`或`<aop:aspectj-autoproxy>`方式开启aop的功能，本质就是向容器中注册了一个BeanDefinition。

BeanDefinitionParser解析ao元素：
```java
	public BeanDefinition parse(Element element, ParserContext parserContext) {
		// 注册启用aop功能的bean【注册AspectJAnnotationAutoProxyCreator】
		AopNamespaceUtils.registerAspectJAnnotationAutoProxyCreatorIfNecessary(parserContext, element);

		// 解析子元素
		extendBeanDefinition(element, parserContext);
		return null;
	}
```
注册AnnotationAwareAspectJAutoProxyCreator：
```java
public static BeanDefinition registerAspectJAnnotationAutoProxyCreatorIfNecessary(
        BeanDefinitionRegistry registry, @Nullable Object source) {

    return registerOrEscalateApcAsRequired(AnnotationAwareAspectJAutoProxyCreator.class, registry, source);
}
```
2、给BeanDefinition添加属性
把xml解析到的子元素添加到BeanDefinition的`includePatterns`属性中。
```java
private void addIncludePatterns(Element element, ParserContext parserContext, BeanDefinition beanDef) {
    ManagedList<TypedStringValue> includePatterns = new ManagedList<>();
	// 获取节点的子元素
    NodeList childNodes = element.getChildNodes();
    for (int i = 0; i < childNodes.getLength(); i++) {
        Node node = childNodes.item(i);
        if (node instanceof Element) {
            Element includeElement = (Element) node;
            TypedStringValue valueHolder = new TypedStringValue(includeElement.getAttribute("name"));
            valueHolder.setSource(parserContext.extractSource(includeElement));
            includePatterns.add(valueHolder);
        }
    }
    if (!includePatterns.isEmpty()) {
        includePatterns.setSource(parserContext.extractSource(element));
        // 【最后吧子元素加入到BeanDefinition中的属性中】
        // 既然加入的是属性，那么你知道他会在"属性填充"阶段吧值填充到bean instance中把
        beanDef.getPropertyValues().add("includePatterns", includePatterns);
    }
}
```

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>

