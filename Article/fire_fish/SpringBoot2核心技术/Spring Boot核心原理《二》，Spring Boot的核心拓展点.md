
@[TOC](文章结构)

# 1. 概述
**前提**：最好了解 Spring Boot 的启动流程 <a href="https://blog.csdn.net/yuchangyuan5237/article/details/128653091">Spring Boot核心原理《一》，Spring Boot的启动流程</a>

不夸张的说，下面的内容在帮助理解 Spring Boot 核心原理、各种组件与 Spring Boot 的集成原理的理解上(如 Nacos、Sentinal 等等）有事半功倍的特效！如果你觉得没有你来 diss 我！

口诀就是口诀就是 <mark>**3+4+5**，3大核心拓展 + 4大核心方法 + 5大核心事件</mark>

作者几乎对 Spring 所有核心源码做了非常详细的注释， <a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a> ，本文系 `FireFish` 原创作品，欢迎转载，觉得不错的小伙伴可以帮助 <a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">Gitee</a> 点个 Star 鼓励一下

# 2. Spring Boot 的核心拓展点

3 大核心拓展接口 + 4 大核心方法 + 5 大核心事件，但是太多了记不住怎么办？知道 3 个核心拓展接口即可

## 1.1 聊 Spring Boot 的 3 大拓展接口

### 2.1.1 Spring 核心拓展接口回顾

了解过 Spring 的同学可能会知道 Spring 有 `3大重要拓展接口` ，之所以说是 3 个而不是 4 个不是空穴来风的，在 <a href="https://docs.spring.io/spring-framework/docs/5.0.6.RELEASE/spring-framework-reference/core.html#beans-factory-extension">官方文档</a> 中介绍了这 3 个重要的接口分别是：

* **BeanPostProcessor**

  > 作用：用来对实例化后的 Bean 做功能增强
  >
  > 举例： `AutowiredAnnotationBeanPostProcessor`

* **BeanFactoryPostProcessor**

  >  作用：用来操作或修改 Bean 的元数据，元数据即是 `configuration metadata` ；简单点说就是可以修改 Bean 的 `BeanDefinition`
  >
  >  举例： `PropertySourcesPlaceholderConfigurer`

* **FactoryBean**

  >  作用：FactoryBean 接口主要用于与第三方接口的集成
  >
  >  举例：Spring 与 Mybatis 集成中的 `SqlSessionFactoryBean`

这 3 个拓展接口支撑了 Spring 的很多拓展功能，我们这里只是对接口功能的简单介绍， 详细内容在 <a href="先占坑">Spring 核心拓展接口</a> 专门有介绍

上面这 3 个接口非常非常非常重要！作为 Java 开发人员应该了解原理

### 2.1.2 <mark>Spring Boot 的 3 大拓展接口</mark>

接上文下面继续聊 Spring Boot 的 3 大拓展接口，先给出本人独家总结 3 大拓展接口如下：

* <mark>**ApplicationContextInitializer**</mark>

* <mark>**ApplicationListener**</mark>

* <mark>**EnableAutoConfiguration**</mark>

之所以说是 3 个接口而不是 4 个接口当然也不是空穴来风有观点佐证，您听我接着说，在我们的 Spring Boot 项目中一般都会引入 `spring-boot-starter-parent` 或 `spring-boot-dependencies` ，不管哪一个本身没有太大区别，都间接引入了 `spring-boot-starter` ，这个 starter 几乎只要是 Spring Boot 项目都会引入进来
重点是 `spring-boot-starter` 引入了 2 个关键的依赖 `spring-boot` 和 `spring-boot-autoconfigure` ，依赖定义如下：

```xml
<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot</artifactId>
        <version>2.6.4</version>
        <scope>compile</scope>
    </dependency>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-autoconfigure</artifactId>
        <version>2.6.4</version>
        <scope>compile</scope>
    </dependency>
</dependencies>
```
这2个依赖包就是 Spring Boot 的核心内容

* **spring-boot依赖包**

`spring-boot` 包中的 `spring.factories` 文件中的内容的作用是在 Spring Boot 的核心流程中发挥作用的(观众老爷们是不是觉得有点抽象，总之意思就是在 Spring Boot 启动流程中发挥重要作用)

在 `spring.factories` 文件众多的配置中，有且只有 2 个重要配置在 Spring Boot 启动流程(启动流程本文后文会讲)中发挥重要作用，就是 `ApplicationContextInitializer` 和 `ApplicationListener` ，这 2 个重要的配置内容举例如下：

```properties
# 代码位置：spring-boot-2.0.2.RELEASE.jar 的 spring.factories 文件
# Application Context Initializers
org.springframework.context.ApplicationContextInitializer=\
org.springframework.boot.context.ConfigurationWarningsApplicationContextInitializer,\
org.springframework.boot.context.ContextIdApplicationContextInitializer,\
org.springframework.boot.context.config.DelegatingApplicationContextInitializer,\
org.springframework.boot.web.context.ServerPortInfoApplicationContextInitializer

# Application Listeners
org.springframework.context.ApplicationListener=\
org.springframework.boot.ClearCachesApplicationListener,\
org.springframework.boot.builder.ParentContextCloserApplicationListener,\
org.springframework.boot.context.FileEncodingApplicationListener,\
org.springframework.boot.context.config.AnsiOutputApplicationListener,\
org.springframework.boot.context.config.ConfigFileApplicationListener,\
org.springframework.boot.context.config.DelegatingApplicationListener,\
org.springframework.boot.context.logging.ClasspathLoggingApplicationListener,\
org.springframework.boot.context.logging.LoggingApplicationListener,\
org.springframework.boot.liquibase.LiquibaseServiceLocatorApplicationListener
```

* **spring-boot-autoconfigure自动配置类依赖包**

`spring-boot-autoconfigure` 包中的 `spring.factories` 文件是专门用来存放 `自动配置类` 的，自动配置类是自动装配的核心以至于专门有一个依赖包用来存放自动配置的内容，自动配置类的 key 是 `EnableAutoConfiguration` ，代码举例如下：

```properties
# 代码位置：spring-boot-autoconfigure-2.0.2.RELEASE.jar 的 spring.factories 文件
# Auto Configure
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
org.springframework.boot.autoconfigure.admin.SpringApplicationAdminJmxAutoConfiguration,\
org.springframework.boot.autoconfigure.aop.AopAutoConfiguration,\
org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration
...... # 还有很多，略
```
嘿嘿，截止此处已经把 Spring Boot 的 3 大拓展接口说完了哦，记住了莓

## 2.2 聊 Spring Boot 启动流程的 4 大核心方法

Spring Boot 主体的启动流程的代码如下，其中我们只讨论核心方法（像 `printBanner` 、 `afterRefresh` 、 `callRunners` 非重点方法直接忽略！)

```java
listeners.starting(bootstrapContext, this.mainApplicationClass);
try {
    // <1> 把args参数封装为一个对象
    ApplicationArguments applicationArguments = new DefaultApplicationArguments(args);
    // <2> 核心方法：准备环境
    ConfigurableEnvironment environment = prepareEnvironment(listeners, bootstrapContext, applicationArguments);
    configureIgnoreBeanInfo(environment);
    // <3> 打印 banner 图
    Banner printedBanner = printBanner(environment);
    // <4> 核心方法：创建容器上下文
    context = createApplicationContext();
    context.setApplicationStartup(this.applicationStartup);
    // <5> 核心方法：在 refresh 前准备好必要的东西
    prepareContext(bootstrapContext, context, environment, listeners, applicationArguments, printedBanner);
    // <6> 核心方法：刷新上下文，也就是执行 ApplicationContext 的 onfresh 方法
    refreshContext(context);
    afterRefresh(context, applicationArguments);
    Duration timeTakenToStartup = Duration.ofNanos(System.nanoTime() - startTime);
    if (this.logStartupInfo) {
        new StartupInfoLogger(this.mainApplicationClass).logStarted(getApplicationLog(), timeTakenToStartup);
    }
    // <7> 触发重点事件
    listeners.started(context, timeTakenToStartup);
    // <8> 调用2个接口的方法
    callRunners(context, applicationArguments);
}
```

对上面注释中的 4 大核心方法做如下说明：

* `<2>` 处，**prepareEnvironment**

  * 创建或准备环境 `environment`

    > 别问我环境是什么兄弟，来这里 <a href="等待填坑">什么是Spring 的 Environment(环境) 呢</a> 。简单理解为一个有所有配置的容器
  * 触发环境准备好的监听事件 `Application PreparedEnvironmentEvent` 事件

* `<4>` 处，**createApplicationContext**

  > 作用：创建容器，根据不同的环境创建不同的容器

* `<5>` 处，<mark>**prepareContext**</mark>

  * 执行 `applyInitializers` 方法也就是调用上文中的 `ApplicationContextInitializer` 接口(记得否？)

    > 作用：很多的第三方组件基于这个做了拓展实现了组件功能与 Spring Boot 集成
  * 触发了 `Application ContextInitializedEvent` 事件 和 触发了 `Application PreparedEvent` 事件

* `<6>` 处，**refreshContext**

  > 作用：刷新容器，其实就是调用 `ApplicationContext` 的 `onfresh` 方法。别问来这里看Spring5官方源码注释 <a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">Spring5核心源码解析</a> ，安排得明明白白

## 2.3 聊 Spring Boot 引入的 5 种事件

**在 Spring Boot 容器的启动过程中会触发这 5 个事件**。Spring Framework 的事件机制是一种**低耦合的拓展机制**，比如第三方应用如 Nacos 就监听了这几个事件实现了自己的功能与 Spring Boot 的整合

> **注意**：这几个事件是需要引入 Spring Boot 才会有的；事件机制还是使用的 Spring Framework 事件机制，只不过事件不是 Spring Framework 中的事件

直接看代码，在注释中说明了事件的触发位置、触发事件的名称等

```java
// <1> Application StartingEvent（应用启动事件，在应用启动前触发）
listeners.starting(bootstrapContext, this.mainApplicationClass);
try {
    ApplicationArguments applicationArguments = new DefaultApplicationArguments(args);
    // <2> Application EnvironmentPreparedEvent（环境准备好事件，在environment准备好后触发）
    ConfigurableEnvironment environment = prepareEnvironment(listeners, bootstrapContext, applicationArguments);
    configureIgnoreBeanInfo(environment);
    Banner printedBanner = printBanner(environment);
    context = createApplicationContext();
    context.setApplicationStartup(this.applicationStartup);
    // <3> Application ContextInitializedEvent（应用 上下文初始化好了事件，在执行完上下文初始化器初始化后触发）
    // <4> Application PreparedEvent（应用准备好事件，在onfresh前的基础工作做好了后触发）
    prepareContext(bootstrapContext, context, environment, listeners, applicationArguments, printedBanner);
    // <5> 调用 Spring Framework 实现了容器的主要功能，说明了 Spring Boot 是对 Spring Framework 的拓展而不是代替
    refreshContext(context);
    afterRefresh(context, applicationArguments);
    Duration timeTakenToStartup = Duration.ofNanos(System.nanoTime() - startTime);
    if (this.logStartupInfo) {
        new StartupInfoLogger(this.mainApplicationClass).logStarted(getApplicationLog(), timeTakenToStartup);
    }
    // <6> Application StartedEvent（应用启动好了事件，在应用启动完成后触发）
    listeners.started(context, timeTakenToStartup);
    callRunners(context, applicationArguments);
}
```

对上面注释中的 5 大核心事件做如下说明：（注意用空格隔开是为了强调事件的关键词）：

* `<1>` 处， `Application StartingEvent`

> 作用：应用启动事件，在应用启动前触发

* `<2>` 处， `Application EnvironmentPreparedEvent`

> 作用：环境准备好事件，在environment准备好后触发

* `<3>` 处， `Application ContextInitializedEvent`

> 作用：应用 上下文初始化好了事件，在执行完上下文初始化器初始化后触发

* `<4>` 处， `Application PreparedEvent`

> 作用：应用准备好事件，在onfresh前的基础工作做好了后触发

* `<6>` 处， `Application StartedEvent`

> 作用：应用启动好了事件，在应用启动完成后触发

# 3. 以 Nacos 为例子看下 Nacos 是如何拓展的

这里以 Nacos 为例简单说下步骤：
1. 有没有实现 `ApplicationContextInitializer` 接口的。 Nacos 并没有使用这个拓展
2. 有没有实现 `ApplicationListener` 接口的。实现了，如 Nacos 的 `NacosContextRefresher`
```java
// 代码位置：xxxx
// 虽然是实现了 ApplicationListener 接口，但是是通过@Bean注解配置的Listener
// 有多种方式都可以配置Listener但是@Bean方式可能不能监听到某些事件，除非您很明确知道您要监听的事件的触发时机否则不是很建议这种配置方式

// 定义 NacosContextRefresher 监听器
@Bean
public NacosContextRefresher nacosContextRefresher(
    NacosConfigProperties nacosConfigProperties,
    NacosRefreshProperties nacosRefreshProperties,
    NacosRefreshHistory refreshHistory) {
    return new NacosContextRefresher(nacosRefreshProperties, refreshHistory,
    nacosConfigProperties.configServiceInstance());
}

// NacosContextRefresher 的类定义，监听特定事件 ApplicationReadyEvent
public class NacosContextRefresher implements ApplicationListener<ApplicationReadyEvent> {

	@Override
	public void onApplicationEvent(ApplicationReadyEvent event) {
		// many Spring context
		if (this.ready.compareAndSet(false, true)) {
			this.registerNacosListenersForApplications();
		}
	}
}
```
3. 看下nacos依赖引入了哪些自动配置类
```properties
# 如：spring-cloud-alibaba-nacos-config-2.1.0.RELEASE.jar!/META-INF/spring.factories文件
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
com.alibaba.cloud.nacos.NacosConfigAutoConfiguration
```
然后就需要耐心的顺藤摸瓜，慢慢摸索了！

# 4. 总结
相信大家从上面代码中的 Spring Boot 启动流程中也看出来了(特别是调用了 Spring 的 onfresh 方法)，Spring Boot 是在 Spring 的基础上做了拓展，Spring Boot 的本质还是 Spring，所以只有把 Spring 的底子打牢固了才能更好的理解 Spring Boot！

虽然上面总结了 `3大核心拓展 + 4大核心方法 + 5大核心事件` 帮助在理解 Spring Boot 原理上撕开了一个大口子，但是不得不说的是 Spring Boot 的 `一站式自动配置` 隐藏了很多细节，所以对于想理解组件如何实现自动集成也不是很容易，所以上文也以 Nacos 为例做了简单说明

一般的，把握了3大拓展点，特别是 `自动配置类引入了哪些组件` ，顺着这个线慢慢梳理也就能了解原理了，结束了哦！

传送门： <a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>
