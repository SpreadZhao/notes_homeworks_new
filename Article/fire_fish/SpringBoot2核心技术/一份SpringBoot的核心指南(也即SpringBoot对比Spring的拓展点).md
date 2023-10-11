
@[TOC](文章结构)

# 概述
可以不夸张的说，下面的内容在帮助理解springboot核心原理、各种组件与springboot的集成原理的理解上(如nacos、sentinal等等），
有着事半功倍的特效！，如果没有你来diss我。

口诀就是<mark>**3+4+5**，3大核心拓展 + 4大核心方法 + 5大核心事件</mark>。

作者几乎对spring的所有核心源码做了非常详细的注释，<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>，
本文系`FireFish`原创作品，欢迎转载，觉得不错的小伙伴球球帮我的<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">gitee</a>点个starter鼓励。

# 3大核心拓展 + 4大核心方法 + 5大核心事件
## spirngboot的3点拓展

### spring的拓展点回顾
了解过Spring的同学可能会知道spring有`3大重要拓展接口`，之所以说是3个不是空穴来风，有<a href="https://docs.spring.io/spring-framework/docs/5.0.6.RELEASE/spring-framework-reference/core.html#beans-factory-extension">官方文档</a>说的.
这3个重要的接口就是：
1. **BeanPostProcessor**（用途：用来对实例化后的bean做功能增强。举例：`AutowiredAnnotationBeanPostProcessor`）
2. **BeanFactoryPostProcessor**（用途：它用来操作bean的`configuration metadata`配置元数据，简单点说就是用来生成bean的配置的也就是`BeanDefinition`。举例：`PropertySourcesPlaceholderConfigurer`）
3. **FactoryBean**（用途：如果你有复杂的初始化需求，举例：spring与mybatis的集成中的`SqlSessionFactoryBean`）
这3大拓展接口支撑起了spring的很多的拓展功能，这里只对接口的功能简单介绍，详细的在我的另外文章专门有介绍。

上面这3个接口非常非常非常重要！必须会必须理解原理。

### springboot的3大拓展点
接上文下面继续聊springboot的3大拓展，先给出本人的独家总结3大拓展点如下：
1. <mark>**ApplicationContextInitializer**</mark>
2. <mark>**ApplicationListener**</mark>
3. <mark>**EnableAutoConfiguration**</mark>

当然也不是空穴来风有观点佐证，您听我接着说。
我们的springboot项目中一般都会引入`spring-boot-starter-parent` 或 `spring-boot-dependencies`，不管是哪个本身没有太大区别，但是间接引入了
`spring-boot-starter`。 这个starter几乎只要是springboot项目都会引入进来，重点来了spring-boot-starter引入了2个关键的依赖`spring-boot`和`spring-boot-autoconfigure`，
如下：
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
这2个依赖包就是springboot的核心内容了。
* **spring-boot依赖包**

`spring-boot`包中的`spring.factories`文件中的内容的作用是在springboot的核心流程中发挥作用的(观众老爷们是不是觉得有点抽象，总之意思就是在springboot启动流程中发挥重要作用)。
在`spring.factories`文件中的众多配置中，有且只有2个重要的配置在springboot的启动流程(启动流程本文后文会讲)中发挥重要作用，他两就是`ApplicationContextInitializer`
和`ApplicationListener`。
* **spring-boot-autoconfigure自动配置类依赖包**
`spring-boot-autoconfigure`包中的`spring.factories`文件是专门用来存放`自动配置类`的配置。自动配置自然而然的是springboot和核心配置了，以至于专门有一个依赖包来存在自动配置的内容。
自动配置类的key是`EnableAutoConfiguration`

嘿嘿，已经把springboot的3大拓展点说完了哦

## 聊springboot启动流程的4大核心方法
所谓的6的核心方法也就是忽略了非关键方法(像`printBanner`、`afterRefresh`、`callRunners`这些都不重要直接忽略！)，只摘出重点方法，如下：
1. **prepareEnvironment**
作用：
* 准备好环境`environment`。别问我环境是什么兄弟，好好复习spring吧，去看<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">Spring5核心源码解析</a>。简单理解为一个有所有配置的容器。
* 触发一个监听事件`Application PreparedEnvironmentEvent`事件(准备好了环境事件)
2. **createApplicationContext**
作用：创建容器，根据不同的环境创建不同的容器
3. <mark>prepareContext</mark>
作用：提起精神，核心中的重点方法啦。 
* 执行`applyInitializers`方法也就是调用上文中的`ApplicationContextInitializer`(记得否？)，很多的第三方组件基于这个做了拓展实现了组件功能与springboot的集成。
* 触发了`Application ContextInitializedEvent`事件 和 触发了`Application PreparedEvent`事件
4. **refreshContext**
作用：刷新容器，其实就是调用`ApplicationContext`的`onfresh`方法。别问我，去看<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">Spring5核心源码解析</a>

```java
    listeners.starting(bootstrapContext, this.mainApplicationClass);
    try {
        // 把args参数封装为一个对象
        ApplicationArguments applicationArguments = new DefaultApplicationArguments(args);
        // 核心方法：准备环境
        ConfigurableEnvironment environment = prepareEnvironment(listeners, bootstrapContext, applicationArguments);
        configureIgnoreBeanInfo(environment);
        // 打印banner图
        Banner printedBanner = printBanner(environment);
        // 核心方法：创建容器上下文
        context = createApplicationContext();
        context.setApplicationStartup(this.applicationStartup);
        // 核心方法：在onfresh前准备好必要的东西
        prepareContext(bootstrapContext, context, environment, listeners, applicationArguments, printedBanner);
        // 核心方法：刷新上下文，也就是执行ApplicationContext的onfresh方法
        refreshContext(context);
        afterRefresh(context, applicationArguments);
        Duration timeTakenToStartup = Duration.ofNanos(System.nanoTime() - startTime);
        if (this.logStartupInfo) {
            new StartupInfoLogger(this.mainApplicationClass).logStarted(getApplicationLog(), timeTakenToStartup);
        }
        // 触发重点事件
        listeners.started(context, timeTakenToStartup);
        // 调用2个接口的方法
        callRunners(context, applicationArguments);
    }
```

## springboot引入的5大核心事件
**在springboot容器的启动过程中发触发这5个事件**（注意下我用空格断开了强调了后面的关键词），而其他的第三方应用如nacos就监听了这个事件实现了自己的功能与springboot的整合。
下面详细看看这几个springboot事件。
1. `Application StartingEvent`（应用启动事件，在应用启动前触发）
2. `Application EnvironmentPreparedEvent`（环境准备好事件，在environment准备好后触发）
3. `Application ContextInitializedEvent`（应用 上下文初始化好了事件，在执行完上下文初始化器初始化后触发）
4. `Application PreparedEvent`（应用准备好事件，在onfresh前的基础工作做好了后触发）
5. `Application StartedEvent`（应用启动好了事件，在应用启动完成后触发）

在springboot的启动过程中分别触发了这5个springboot事件，直接下代码，在注释中说明了触发位置
```java
    // 1. `Application StartingEvent`（应用启动事件，在应用启动前触发）
    listeners.starting(bootstrapContext, this.mainApplicationClass);
    try {
        ApplicationArguments applicationArguments = new DefaultApplicationArguments(args);
        // 2. `Application EnvironmentPreparedEvent`（环境准备好事件，在environment准备好后触发）
        ConfigurableEnvironment environment = prepareEnvironment(listeners, bootstrapContext, applicationArguments);
        configureIgnoreBeanInfo(environment);
        Banner printedBanner = printBanner(environment);
        context = createApplicationContext();
        context.setApplicationStartup(this.applicationStartup);
        //  3. `Application ContextInitializedEvent`（应用 上下文初始化好了事件，在执行完上下文初始化器初始化后触发）
        //  4. `Application PreparedEvent`（应用准备好事件，在onfresh前的基础工作做好了后触发）
        prepareContext(bootstrapContext, context, environment, listeners, applicationArguments, printedBanner);
		// 调用了spring的ApplicationContext的onfresh方法实现了容器的主要功能。springboot是对spring的拓展而不是代替
        refreshContext(context);
        afterRefresh(context, applicationArguments);
        Duration timeTakenToStartup = Duration.ofNanos(System.nanoTime() - startTime);
        if (this.logStartupInfo) {
            new StartupInfoLogger(this.mainApplicationClass).logStarted(getApplicationLog(), timeTakenToStartup);
        }
        // 5. `Application StartedEvent`（应用启动好了事件，在应用启动完成后触发）
        listeners.started(context, timeTakenToStartup);
        callRunners(context, applicationArguments);
    }
```

# 以nacos为例子看下nacos是如何拓展的
这里以nacos为例简单说下步骤：
1. 有没有实现`ApplicationContextInitializer`接口的。 没找到示例尴尬了
2. 有没有实现`ApplicationListener`接口的。如nacos的`NacosContextRefresher`
3. 看下nacos依赖引入了哪些自动配置类
```properties
# 如：spring-cloud-alibaba-nacos-config-2.1.0.RELEASE.jar!/META-INF/spring.factories文件
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
com.alibaba.cloud.nacos.NacosConfigAutoConfiguration
```
然后就需要耐心的顺藤摸瓜，慢慢摸索了！

# 总结
相信大家从上面代码中的springboot启动流程中也看出来了(特别是调用了spring的onfresh方法)，springboot是在spring的基础上做了拓展，
springboot的本质还是spring，所以只有把spring的底子打牢固了才能更好的理解springboot。
虽然上面总结了`3大核心拓展 + 4大核心方法 + 5大核心事件`帮助在理解springboot原理上撕开了一个大口子，
但是不得不说的是springboot的`一站式自动配置`隐藏了很多细节，所以对于想理解组件如何实现自动集成也不是很容易，所以上文也以nacos为例简单说了下。

一般的，把握了3大拓展点，特别是`自动配置类引入了哪些组件`，顺着这个线慢慢梳理也就能了解原理了。
结束了哦

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>

