
@[TOC](文章结构)

### 什么是Spring的生命周期处理器
<mark>**即LifecycleProcessor接口**</mark>

在Spring中还提供了Lifecycle接口，Lifecycle接口中包含start/stop方法，实现此接口后Spring会保证在启动的时候调用其start方法开始生命周期，并在Spring关闭的时候调用stop方法来结束生命周期，通常用来配置后台程序，如启动后一直运行（如对MQ进行轮询等）。而ApplicationContext的初始化最后一步就是保证了这一功能的实现。

### 如何实现的
* 生命周期处理器是有<mark>固定的名称</mark>，即`lifecycleProcessor`；
* 也是有<mark>优先级</mark>的，优先级是通过`phase`表现的
```java
protected void finishRefresh() {
    // Initialize lifecycle processor for this context.
    // 初始化生命周期处理器。这个bena也是有固定名称的
    initLifecycleProcessor();

    // Propagate refresh to lifecycle processor first.
    // 启动生命周期处理器
    getLifecycleProcessor().onRefresh();

    // Publish the final event.
    // 发布 ContextRefreshedEvent 事件
    publishEvent(new ContextRefreshedEvent(this));
}
```
1、initLifecycleProcessor方法
```java
protected void initLifecycleProcessor() {
    ConfigurableListableBeanFactory beanFactory = getBeanFactory();
    if (beanFactory.containsLocalBean(LIFECYCLE_PROCESSOR_BEAN_NAME)) {
        this.lifecycleProcessor =
                beanFactory.getBean(LIFECYCLE_PROCESSOR_BEAN_NAME, LifecycleProcessor.class);
        if (logger.isTraceEnabled()) {
            logger.trace("Using LifecycleProcessor [" + this.lifecycleProcessor + "]");
        }
    }
    else {
        DefaultLifecycleProcessor defaultProcessor = new DefaultLifecycleProcessor();
        defaultProcessor.setBeanFactory(beanFactory);
        this.lifecycleProcessor = defaultProcessor;
        beanFactory.registerSingleton(LIFECYCLE_PROCESSOR_BEAN_NAME, this.lifecycleProcessor);
        if (logger.isTraceEnabled()) {
            logger.trace("No '" + LIFECYCLE_PROCESSOR_BEAN_NAME + "' bean, using " +
                    "[" + this.lifecycleProcessor.getClass().getSimpleName() + "]");
        }
    }
}
```
2、onRefresh方法
```java
public void onRefresh() {
    startBeans(true);
    this.running = true;
}
```
可以看到响应优先级的`phases`，也可以看到最后通过star启动了
```java
private void startBeans(boolean autoStartupOnly) {
    // 获取
    Map<String, Lifecycle> lifecycleBeans = getLifecycleBeans();
    // 分组、缓存
    Map<Integer, LifecycleGroup> phases = new HashMap<>();
    lifecycleBeans.forEach((beanName, bean) -> {
        if (!autoStartupOnly || (bean instanceof SmartLifecycle && ((SmartLifecycle) bean).isAutoStartup())) {
            int phase = getPhase(bean);
            LifecycleGroup group = phases.get(phase);
            if (group == null) {
                group = new LifecycleGroup(phase, this.timeoutPerShutdownPhase, lifecycleBeans, autoStartupOnly);
                phases.put(phase, group);
            }
            // 加入组（没看见组内的排序，那么组内是否排序呢）
            group.add(beanName, bean);
        }
    });
    if (!phases.isEmpty()) {
        List<Integer> keys = new ArrayList<>(phases.keySet());
        // 排序（Integer是自然排序）
        Collections.sort(keys);
        for (Integer key : keys) {
            // 启动start
            phases.get(key).start();
        }
    }
}
```

### 用途
是Spring提供的重要拓展方式！！
通常用来配置后台程序，如启动后一直运行（如对MQ进行轮询等）

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>
