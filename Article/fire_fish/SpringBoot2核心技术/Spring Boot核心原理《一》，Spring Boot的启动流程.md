@[TOC](文章结构)

本文以 Spring Boot 版本 `2.0.2.RELEASE` 为例介绍

## 1. 容器启动入口

首先从 `SpringBoot` 启动流程进去

```java
public class MyApplicationContext {
	public static void main(String[] args) {
		// 启动方法入口
		SpringApplication.run(MyApplicationContext.class, args);
	}
}
```

## 2. 初始化 SpringApplication

```java
public class SpringApplication {
	public static ConfigurableApplicationContext run(Class<?> primarySource, String... args) {
		// <1> 把传入的类作为“primarySource”，即“主要源”
		return run(new Class<?>[]{primarySource}, args);
	}

	public static ConfigurableApplicationContext run(Class<?>[] primarySources, String[] args) {
		// <2> 创建 SpringApplication
		return new SpringApplication(primarySources).run(args);
	}
}
```

* `<1>` 处，把传的 MyApplicationContext 参数当做“主要源”
* `<2>` 处，创建 SpringApplication

### 2.1 构造器

通过构造器完成了 SpringApplication 对象的创建，代码如下：

```java
public class SpringApplication {

    public SpringApplication(Class<?>... primarySources) {
        this(null, primarySources);
    }

    public SpringApplication(ResourceLoader resourceLoader, Class<?>... primarySources) {
        this.resourceLoader = resourceLoader;
        Assert.notNull(primarySources, "PrimarySources must not be null");
        this.primarySources = new LinkedHashSet<>(Arrays.asList(primarySources));
        // <1> 决定 webApplicationType 类型
        this.webApplicationType = deduceWebApplicationType();
        // <2> 实例化 ApplicationContextInitializer 类型并设置
        setInitializers((Collection) getSpringFactoriesInstances(
            ApplicationContextInitializer.class));
        // <3> 实例化 ApplicationListener 类型并设置
        setListeners((Collection) getSpringFactoriesInstances(ApplicationListener.class));
        // <4> 决定 main 方法的类
        this.mainApplicationClass = deduceMainApplicationClass();
    }
}
```

* `<1>` 处，决定 `webApplicationType` 类型，便于后面实例化何种类型的上下文

* `<2>` 处，实例化 `ApplicationContextInitializer` 类型并设置到 `SpringApplication` 中。该接口是 Boot 重要的拓展接口之一，后面会用

  >ApplicationContextInitializer 接口要求必须有一个参数列表是<mark>[SpringApplication application, String[] args]</mark>的构造器，为啥呢？往下看
  >
  >```java
  >private SpringApplicationRunListeners getRunListeners(String[] args) {
  >    // 参数列表。后面会用这个参数列表来查找构造器
  >    Class<?>[] types = new Class<?>[] { SpringApplication.class, String[].class };
  >    return new SpringApplicationRunListeners(logger, getSpringFactoriesInstances(
  >        SpringApplicationRunListener.class, types, this, args));
  >}
  >```
  >
  >```java
  >private <T> List<T> createSpringFactoriesInstances(Class<T> type,
  >			Class<?>[] parameterTypes, ClassLoader classLoader, Object[] args,
  >    		Set<String> names) {
  >    List<T> instances = new ArrayList<>(names.size());
  >    for (String name : names) {
  >        Class<?> instanceClass = ClassUtils.forName(name, classLoader);
  >        Assert.isAssignable(type, instanceClass);
  >        Constructor<?> constructor = instanceClass
  >            .getDeclaredConstructor(parameterTypes);	// <1>
  >        T instance = (T) BeanUtils.instantiateClass(constructor, args);	// <2>
  >        instances.add(instance);
  >    }
  >    return instances;
  >}
  >```
  >
  >* `<1>` 处，用参数列表 parameterTypes 来 type 中查找构造器
  >* `<2>` 处，用构造器来实例化，构造器参数 args 的第一个参数是 springApplication，后续参数是命令行参数 args



* `<3>` 处，实例化 `ApplicationListener` 类型并设置到 `SpringApplication` 中。该接口是 Boot 重要的拓展接口之一，后面会用

* `<4>` 处，决定 main 方法使用哪个类

#### 2.1.1 deduceWebApplicationType

应用通过 `deduceWebApplicationType` 方法决定上下文类型，代码如下：

```java
public class SpringApplication {

	private static final String REACTIVE_WEB_ENVIRONMENT_CLASS = "org.springframework."
			+ "web.reactive.DispatcherHandler";

	private static final String MVC_WEB_ENVIRONMENT_CLASS = "org.springframework."
			+ "web.servlet.DispatcherServlet";

	private static final String[] WEB_ENVIRONMENT_CLASSES = {"javax.servlet.Servlet",
			"org.springframework.web.context.ConfigurableWebApplicationContext"};

	// 根据类是否存在来决定上下文类型
	private WebApplicationType deduceWebApplicationType() {
		// <1> 使用reactive类型(如果reactive存在且web不存在)
		if (ClassUtils.isPresent(REACTIVE_WEB_ENVIRONMENT_CLASS, null)
				&& !ClassUtils.isPresent(MVC_WEB_ENVIRONMENT_CLASS, null)) {
			return WebApplicationType.REACTIVE;
		}
		// <2> 使用none类型，也就是普通的应用上下文(如果WEB_ENVIRONMENT_CLASSES都不存在)
		for (String className : WEB_ENVIRONMENT_CLASSES) {
			if (!ClassUtils.isPresent(className, null)) {
				return WebApplicationType.NONE;
			}
		}
		// <3> 其他情况使用servet类型
		return WebApplicationType.SERVLET;
	}
}
```

* `<1>` 处，如果存在 REACTIVE_WEB_ENVIRONMENT_CLASS 存在且 MVC_WEB_ENVIRONMENT_CLASS 不存在，则使用 `REACTIVE`

* `<2>` 处，如果 WEB_ENVIRONMENT_CLASSES 不存在，则上下文类型是 `NONE`

* `<3>` 处，其他情况上下文类型使用： `SERVLET`

#### 2.2.2 createApplicationContext

根据上下文类型 `this.webApplicationType` 创建 Spring Boot 容器的应用上下文对象，代码如下：

```java
public class SpringApplication {
	// web 环境的上下文对象
	public static final String DEFAULT_WEB_CONTEXT_CLASS = "org.springframework.boot."
			+ "web.servlet.context.AnnotationConfigServletWebServerApplicationContext";

	// reactive 环境的上下文对象
	public static final String DEFAULT_REACTIVE_WEB_CONTEXT_CLASS = "org.springframework."
			+ "boot.web.reactive.context.AnnotationConfigReactiveWebServerApplicationContext";

	// 非 web 环境的上下文对象
	public static final String DEFAULT_CONTEXT_CLASS = "org.springframework.context."
			+ "annotation.AnnotationConfigApplicationContext";

	// 具体上下文应用哪个类
	protected ConfigurableApplicationContext createApplicationContext() {
		Class<?> contextClass = this.applicationContextClass;
		if (contextClass == null) {
			try {
        // <1> 决定实例化的上下文容器类型
				switch (this.webApplicationType) {
					// <1.1> 如果是servlet类型
					case SERVLET:
						contextClass = Class.forName(DEFAULT_WEB_CONTEXT_CLASS);
						break;
					// <1.2> 如果是reactive类型
					case REACTIVE:
						contextClass = Class.forName(DEFAULT_REACTIVE_WEB_CONTEXT_CLASS);
						break;
					// <1.3> 如果是none类型
					default:
						contextClass = Class.forName(DEFAULT_CONTEXT_CLASS);
				}
			} catch (ClassNotFoundException ex) {
			}
		}
		// <2> 对上下文实例化
		return (ConfigurableApplicationContext) BeanUtils.instantiateClass(contextClass);
	}
}
```

* `<1>` 处，决定实例化的上下文容器类型
  * `<1.1>` 处，如果是 servlet 类型，则使用 `AnnotationConfigServletWebServerApplicationContext` 上下文
  * `<1.2>` 处，如果是 reactive 类型，则使用 `AnnotationConfigReactiveWebServerApplicationContext` 上下文
  * `<1.3>` 处，如果是 none 类型，则使用 `AnnotationConfigApplicationContext` 上下文

* `<2>` 处，对上下文的 `contextClass` 实例化并返回

## 3. run 方法

这就是 Spring Boot 启动的主体流程，看着很长其实就几个重点方法。代码如下：

```java
public class SpringApplication {
	public ConfigurableApplicationContext run(String... args) {
		StopWatch stopWatch = new StopWatch();
		stopWatch.start();
		ConfigurableApplicationContext context = null;
		Collection<SpringBootExceptionReporter> exceptionReporters = new ArrayList<>();
		configureHeadlessProperty();
		// <1> 实例化 SpringApplicationRunListener
		SpringApplicationRunListeners listeners = getRunListeners(args);
		// <2> 触发 ApplicationStartedEvent 事件
		listeners.starting();
		try {
			// <3> 【 prepareContext 前的基本准备工作】，有命令行参数、准备环境environment、banner图、创建容器等
			ApplicationArguments applicationArguments = new DefaultApplicationArguments(
					args);
			ConfigurableEnvironment environment = prepareEnvironment(listeners,
					applicationArguments);
			configureIgnoreBeanInfo(environment);
			Banner printedBanner = printBanner(environment);
			context = createApplicationContext();
			exceptionReporters = getSpringFactoriesInstances(
					SpringBootExceptionReporter.class,
					new Class[]{ConfigurableApplicationContext.class}, context);

			// <4> 【prepareContext 方法(重点)】。单独介绍
			prepareContext(context, environment, listeners, applicationArguments,
					printedBanner);

			// <5> 【refreshContext 方法(重点)】。单独介绍
			refreshContext(context);

			afterRefresh(context, applicationArguments);
			stopWatch.stop();
			// <6> 触发了核心事件：ApplicationStartedEvent(应用启动好了事件)
			listeners.started(context);
			// <7> 调用了 ApplicationRunner、CommandLineRunner 接口
			callRunners(context, applicationArguments);
		} catch (Throwable ex) {
			handleRunFailure(context, ex, exceptionReporters, listeners);
			throw new IllegalStateException(ex);
		}

		try {
			// <8> 触发了核心事件：ApplicationReadyEvent(应用准备好了事件)
			listeners.running(context);
		} catch (Throwable ex) {
			handleRunFailure(context, ex, exceptionReporters, null);
			throw new IllegalStateException(ex);
		}
		return context;
	}
}
```

* prepareContext 前的基本准备工作
  * `<1>` 处，加载了 SpringApplicationRunListener，该接口的作用其实是在特定事件发生后用来广播事件给监听的 Listener
  * `<2>` 处，触发了核心事件：ApplicationStartingEvetnt(应用启动中事件)
  * `<3>` 处，有命令行参数、准备环境 environment、banner 图、创建容器等
* **prepareContext 方法(重点)**，看『 `prepareContext` 』
* **refreshContext 方法(重点)**，看『 `prepareContext` 』
* refreshContext 后续完善工作
  * `<6>` 处，触发事件 ApplicationStartedEvent
  * `<7>` 处，调用了 ApplicationRunner、CommandLineRunner 接口
  * `<8>` 处，触发了事件 ApplicationReadyEvent


### 3.1 prepareContext 方法(重点)

这个方法的作用是在 `Application` 执行 refresh(刷新)前，准备好一切东西。重点就是执行了 `applyInitializers` 方法和触发了几个Spring Boot 的关键事件，代码如下：

```java
public class SpringApplication {

	private void prepareContext(ConfigurableApplicationContext context,
	                            ConfigurableEnvironment environment, SpringApplicationRunListeners listeners,
	                            ApplicationArguments applicationArguments, Banner printedBanner) {
		context.setEnvironment(environment);
		postProcessApplicationContext(context);
		// <1> 核心方法：应用 ApplicationContextInitializer 接口
		applyInitializers(context);
		// <2> 核心方法：该版本没有触发事件，但是后续的 Spring Boot版本触发了 ApplicationContextInitializedEvent 事件
		listeners.contextPrepared(context);

		// <3> 向容器中注册2个特殊bean
		context.getBeanFactory().registerSingleton("springApplicationArguments",
				applicationArguments);
		if (printedBanner != null) {
			context.getBeanFactory().registerSingleton("springBootBanner", printedBanner);
		}

		// <4> 加载所有配置源
		Set<Object> sources = getAllSources();
		Assert.notEmpty(sources, "Sources must not be empty");
		load(context, sources.toArray(new Object[0]));
		// <5> 核心方法：触发 ApplicationPreparedEvent(应用准备好了事件) 事件
		listeners.contextLoaded(context);
	}
}
```

* `<1>` 处，应用了 `ApplicationContextInitializer` 接口，该接口是Spring Boot的重要拓展点，Spring Cloud 的很多功能是通过这个接口完成的

* `<2>` 处，在当前版本 `2.0.2.RELEASE` 什么时间都没有触发。但作者看了 Spring Boot 的后续版本触发了一个 `ApplicationContextInitializedEvent` 事件

* `<3>` 处，向容器中注入了 2 个特殊的 bean 方便我们后续使用，这个 2 个 bean 分别是 `springApplicationArguments` 、 `springBootBanner`

* `<4>` 处，用 BeanDefinitionLoader 来加载配置中的 Bean 定义

* `<5>` 处，触发了 `ApplicationPreparedEvent` 事件

  > ```java
  > public void contextLoaded(ConfigurableApplicationContext context) {
  >     // <1>
  >     for (ApplicationListener<?> listener : this.application.getListeners()) {
  >         if (listener instanceof ApplicationContextAware) {
  >             ((ApplicationContextAware) listener).setApplicationContext(context);
  >         }
  >         context.addApplicationListener(listener);
  >     }
  >     // <2>
  >     this.initialMulticaster.multicastEvent(
  >         new ApplicationPreparedEvent(this.application, this.args, context));
  > }
  > ```
  >
  > * `<1>` 处，完成了一件很重要的事情，**把 Spring Boot 配置中定义的事件加入了到了上下文中**，后续的 context 也能触发配置好的事件了
  > * `<2>` 处，触发了 ApplicationPreparedEvent 事件

### 3.2 refreshContext 方法(重点)

这个方法的作用是刷新容器，其实就是 ApplicationContext 的核心方法，从这里也能略见 Spring Boot 是对 Spring 的拓展而不是代替
从内容上不属于 Spring Boot 的范畴，所以我把内容介绍放在了 <a href="https://blog.csdn.net/yuchangyuan5237/article/details/128653081">
ApplicationContext容器启动</a>"

传送门： <a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>