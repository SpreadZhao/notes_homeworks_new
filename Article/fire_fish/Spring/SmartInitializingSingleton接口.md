SmartInitializingSingleton接口是ApplicationContext对BeanFactory的增强功能。

@[TOC](文章结构)

### 什么是SmartInitializingSingleton接口
SmartInitializingSingleton接口是ApplicationContext对BeanFactory的增强功能
可以理解为spring容器固有功能，因为现在都是用ApplicationContext

### 在什么时候起作用
在bean的初始化完成后，会回调SmartInitializingSingleton接口
```java
for (String beanName : beanNames) {
    Object singletonInstance = getSingleton(beanName);
    if (singletonInstance instanceof SmartInitializingSingleton) {
        SmartInitializingSingleton smartSingleton = (SmartInitializingSingleton) singletonInstance;
        if (System.getSecurityManager() != null) {
            AccessController.doPrivileged((PrivilegedAction<Object>) () -> {
                smartSingleton.afterSingletonsInstantiated();
                return null;
            }, getAccessControlContext());
        }
        else {
            smartSingleton.afterSingletonsInstantiated();
        }
    }
}
```

### 有什么用途
很多的第三方应用通过该接口完成功能的强化

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>
