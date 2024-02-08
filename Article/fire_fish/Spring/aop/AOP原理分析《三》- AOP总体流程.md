
@[TOC](文章结构)

## 总体流程图
![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2022-09-12-12-05-17-image.png)

### 介绍后置处理器
开启aop后的BeanDefinition的注册在上文已经说明了。

在注册阶段只是向容器中注册了一个BeanDefinition的定义，而这个BeanDefinition又不是一个简单的BeanDefinition而是实现了一些特殊的接口，
不妨先了解下这个注册的BeanDefinition的结构。
#### AnnotationAwareAspectJAutoProxyCreator的结构
分析了该bean的体系结构，如下图：
![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2022-09-11-20-11-46-image.png)
可以看出实现了SmartInstantiationAwareBeanPostProcessor、InstantiationAwareBeanPostProcessor、BeanPostProcessor等重要的拓展接口，
那么可以猜测aop功能大致是通过在每个bean初始化前后运行"bean后置处理器"来完成aop的。

<mark>分别介绍一下这几个接口</mark>
（如果方法找不到请下载spring源码全局搜索一下或者找慢点）


| 接口                                       | 起作用的代码位置                                      |                      |
| ---------------------------------------- | --------------------------------------------- | -------------------- |
| SmartInstantiationAwareBeanPostProcessor | addSingletonFactory方法                         | 在第三级缓存这里             |
| InstantiationAwareBeanPostProcessor      | resolveBeforeInstantiation方法 或 populateBean方法 | getBean的实例化前后 或 属性填充 |
| BeanPostProcessor                        | invokeInitMethods方法前后                         | 在bean初始化前后           |

### 找到合适的增强器并创建代理
AnnotationAwareAspectJAutoProxyCreator实现了几个特殊的接口，但是观察了对应的实现代码也就只有`BeanPostProcessor`的
`postProcessAfterInitialization`跟目标接近，而我们对AOP逻辑的分析也从这里开始。

查找增强器并创建代理：
```java
protected Object wrapIfNecessary(Object bean, String beanName, Object cacheKey) {
    if (StringUtils.hasLength(beanName) && this.targetSourcedBeans.contains(beanName)) {
        return bean;
    }

    // 1、如果不需要代理，则直接返回原始bean就好了
    if (Boolean.FALSE.equals(this.advisedBeans.get(cacheKey))) {
        return bean;
    }

    // 2、advisedBeans 记录不需要代理的bean
    if (isInfrastructureClass(bean.getClass()) || shouldSkip(bean.getClass(), beanName)) {
        this.advisedBeans.put(cacheKey, Boolean.FALSE);
        return bean;
    }

    // Create proxy if we have advice.
    // 3、获取AdvicesAndAdvisors增强，并创建代理    
    Object[] specificInterceptors = getAdvicesAndAdvisorsForBean(bean.getClass(), beanName, null);
    if (specificInterceptors != DO_NOT_PROXY) {
        this.advisedBeans.put(cacheKey, Boolean.TRUE);
		// 根据增强器创建代理对象
        Object proxy = createProxy(
                bean.getClass(), beanName, specificInterceptors, new SingletonTargetSource(bean));
        // proxyTypes 缓存了代理结果
		this.proxyTypes.put(cacheKey, proxy.getClass());
        return proxy;
    }

    this.advisedBeans.put(cacheKey, Boolean.FALSE);
    return bean;
}
```
后文继续分析如何获取增强器

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>

