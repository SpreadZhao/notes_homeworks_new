
@[TOC](文章结构)

### Spring的3大拓展点
了解过Spring的同学可能会知道Spring有`3大重要拓展接口`，之所以说是3个而不是4个不是空穴来风，有<a href="https://docs.spring.io/spring-framework/docs/5.0.6.RELEASE/spring-framework-reference/core.html#beans-factory-extension">官方文档</a>说的.
这3个重要的接口就是：
1. **BeanPostProcessor**（**用途**：用来对实例化后的bean做功能增强。举例：`AutowiredAnnotationBeanPostProcessor`）
2. **BeanFactoryPostProcessor**（**用途**：它用来操作bean的`configuration metadata`配置元数据，简单点说就是用来生成bean的配置的也就是`BeanDefinition`。举例：`PropertySourcesPlaceholderConfigurer`）
3. **FactoryBean**（**用途**：如果你有复杂的初始化需求，举例：spring与mybatis的集成中的`SqlSessionFactoryBean`）
   这3大拓展接口支撑了Spring的很多的拓展功能，这里只对接口的功能简单介绍，详细的在我的另外文章专门有介绍。

上面这3个接口非常非常非常重要！作为Java开发人员应该了解原理。

### BeanFactory、BeanFactoryPostProcessor、BeanPostProcessor、FactoryBean的区别

如上文所说明的，Spring的3大拓展点对应了3个接口再加上`BeanFactory`接口，它们之间名字很相近，一定要注意区分它们的功能区别。

相同点：BeanFactoryPostProcessor、BeanPostProcessor、FactoryBean是spring三大拓展接口（spring官方文档都是这么说的，所以重要性不言而已）。

不同点：用如下表格列出：

| 接口  | 功能  | 用途及作用点 |
| --- | --- | --- |
| BeanFactory | 是spring的<mark>核心容器</mark> | 一切spring的基础 |
| BeanFactoryPostProcessor | 是对<mark>核心容器</mark>的<mark>增强</mark> | 针对容器的增强，一般在容器启动时起作用 |
| BeanPostProcessor | 是对<mark>bean</mark>的<mark>增强</mark> | 如aop，一般在getBean中起作用 |
| FactoryBean | 是对复杂bean创建的封装 | 如集成mybatis，一般在getBean中起作用 |

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>


