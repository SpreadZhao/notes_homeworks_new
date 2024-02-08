
@[TOC](文章结构)

## ApplicationContext 接口说明
`ApplicationContext`接口是对`BeanFactory`接口的拓展。原始的`BeanFactory`只包括了ioc以来注入功能，而`ApplicationContext`新增了非常多的功能，
如：国际化、事件机制等等。
详细有哪些拓展请看`refresh`方法


## refresh 方法
主要是refresh方法（一个大概12个)。这12个方法的名称和作用其实是要求全部记住的，但是确实有点多哈。 记不住的重点理解几个方法。
* `obtainFreshBeanFactory`
* `invokeBeanFactoryPostProcessor`
* `registerBeanPostProcessor`
* `finishBeanFactoryInitlization`
* `finishRefresh`

12个方法的作用分别描述如下：
1. prepareRefresh（作用：准备标准环境；参数校验。<a href="先占坑">什么是 Spring 的 Environment(环境) 呢</a>）
2. <mark>**obtainFreshBeanFactory**</mark>（作用：获取BeanFactory，也就是ListableBeanFactory。<a href="先占坑">Spring最原始的容器接口BeanFactory</a>）
3. prepareBeanFactory（作用：最BeanFactory做一些设置）
4. postProcessBeanFactory（留给子类拓展）
5. <mark>**invokeBeanFactoryPostProcessor**</mark>（作用：执行`BeanFactoryPostProcessor`接口，是**执行**。<a href="先占坑">BeanFactoryPostProcessor介绍</a>）
6. <mark>**registerBeanPostProcessor**</mark>（作用：注册`BeanPostProcessor`接口，是**注册**哦，该<a href="先占坑">BeanPostProcessor介绍</a>）
7. initMessageSource（作用：国际化相关。<a href="https://blog.csdn.net/yuchangyuan5237/article/details/126804852">Spring国际化消息解析原理</a>）
8. initApplicationEventMuticaster（作用：事件广播器。<a href="先占坑">Spring事件监听机制原理</a>）
9. onRefresh（作用：留给子类拓展）
10. registerListener（作用：注册监听器。<a href="先占坑">Spring事件监听机制原理</a>）
11. <mark>**finishBeanFactoryInitlization**</mark>（作用：完成bean的实例化和初始化）
12. <mark>**finishRefresh**</mark>（作用：执行生命周期处理器。<a href="https://blog.csdn.net/yuchangyuan5237/article/details/126807799">什么是LifecycleProcessor</a>

以`XmlApplicationContext`为例说明拓展功能。
```java
public abstract class AbstractApplicationContext extends DefaultResourceLoader
		implements ConfigurableApplicationContext {
	@Override
	public void refresh() throws BeansException, IllegalStateException {
		synchronized (this.startupShutdownMonitor) {
			// Prepare this context for refreshing.
            // <1> 初始化前的准备工作，主要是一些系统属性、环境变量的校验，比如Spring启动需要某些环境变量，可以在这个地方进行设置和校验
			prepareRefresh();

			// Tell the subclass to refresh the internal bean factory.
			// <2> 获取bean工厂，ConfigurableListableBeanFactory是默认的容器，在这一步会完成工厂的创建以及beanDefinition的读取
			ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();

			// Prepare the bean factory for use in this context.
			// <3> 进入prepareBeanFactory前spring以及完成了对配置的解析，Spring的拓展从这里开始
			prepareBeanFactory(beanFactory);
			
            // Allows post-processing of the bean factory in context subclasses.
			// <4> 留给子类覆盖做拓展，这里一般不做任何处理
            postProcessBeanFactory(beanFactory);

            // Invoke factory processors registered as beans in the context.
			// <5> 调用所有的BeanFactoryPostProcessors，将结果存入参数beanFactory中
            invokeBeanFactoryPostProcessors(beanFactory);

            // Register bean processors that intercept bean creation.
			// <6> 注册BeanPostProcessors，这里只是注册，真正的调用是在doGetBean中
            registerBeanPostProcessors(beanFactory);

            // Initialize message source for this context.
			// <7> 初始化消息原，比如国际化
            initMessageSource();

            // Initialize event multicaster for this context.
			// <8> 初始化消息广播器
            initApplicationEventMulticaster();

            // Initialize other special beans in specific context subclasses.
			// <9> 留给子类类初始化其他的bean
            onRefresh();

            // Check for listener beans and register them.
			// <10> 注册监听器
            registerListeners();

            // Instantiate all remaining (non-lazy-init) singletons.
			// <11> 初始化剩下的单例bean，在这里才开始真正的对bean进行实例化和初始化
            finishBeanFactoryInitialization(beanFactory);

            // Last step: publish corresponding event.
			// <12> 完成刷新，通知生命周期处理器刷新过程。
            finishRefresh();
		}
	}
}
```

## 保姆式Spring5源码解析
作者以前吧Spring5的核心功能都在官方源码仓库做了注释，最近开始吧这些注释整理成文章，文章有不详之处可以clone我的仓库<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**Spring5源码解析**</a>或与我交流学习。

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>






