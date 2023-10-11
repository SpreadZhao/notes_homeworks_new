
核心类：ConfigurationClassPostProcessor的部分功能介绍（cglib介绍）

### ConfigurationClassPostProcessor接口介绍

看接口定义，实现了特殊接口BeanDefinitionRegistryPostProcessor，该接口又实现了BeanFactoryPostProcessor。

```java
public class ConfigurationClassPostProcessor implements BeanDefinitionRegistryPostProcessor,
		PriorityOrdered, ResourceLoaderAware, BeanClassLoaderAware, EnvironmentAware {

	@Override
	public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) {
	}

	@Override
	public void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) {
	}
}
```
**根据Spring的启动过程中的invokeBeanFactoryPostProcessor方法的处理，
1、会先调用BeanDefinitionRegistryPostProcessor接口的postProcessBeanDefinitionRegistry方法完成@Configuration注解类的收集工作，
2、然后调用BeanFactoryPostProcessor的postProcessBeanFactory完成对@Configuration注解类的cglib增强(也就是对@Configuration中方法的拦截)**


### 解释什么时候会被增强拦截

只有@Configuration注解类是full类型才会被增强

```java
Map<String, AbstractBeanDefinition> configBeanDefs = new LinkedHashMap<>();
for (String beanName : beanFactory.getBeanDefinitionNames()) {
	// 是否是full类型
    if (ConfigurationClassUtils.isFullConfigurationClass(beanDef)) {
        configBeanDefs.put(beanName, (AbstractBeanDefinition) beanDef);
    }
}


for (Map.Entry<String, AbstractBeanDefinition> entry : configBeanDefs.entrySet()) {
    AbstractBeanDefinition beanDef = entry.getValue();
    beanDef.setAttribute(AutoProxyUtils.PRESERVE_TARGET_CLASS_ATTRIBUTE, Boolean.TRUE);
    Class<?> configClass = beanDef.resolveBeanClass(this.beanClassLoader);
    if (configClass != null) {
		// 是full类型的增强
        Class<?> enhancedClass = enhancer.enhance(configClass, this.beanClassLoader);
        if (configClass != enhancedClass) {
            beanDef.setBeanClass(enhancedClass);
        }
    }
}
```

### 增强了什么内容

增强内容是：BeanMethodInterceptor、BeanFactoryAwareMethodInterceptor这2个拦截器。
重点看BeanMethodInterceptor拦截器。如下是代理对象的创建

```java
Class<?> enhancedClass = createClass(newEnhancer(configClass, classLoader));
```
```java
class ConfigurationClassEnhancer {
	private static final Callback[] CALLBACKS = new Callback[]{
			new BeanMethodInterceptor(),
			new BeanFactoryAwareMethodInterceptor(),
			NoOp.INSTANCE
	};

	private Class<?> createClass(Enhancer enhancer) {
		// CALLBACKS 就是增强内容
		Enhancer.registerStaticCallbacks(subclass, CALLBACKS);
		return subclass;
	}
}
```

#### 看BeanMethodInterceptor类增强的内容
先看接口定义
```java
private static class BeanMethodInterceptor implements MethodInterceptor, ConditionalCallback {
	
}
```

##### 拦截条件
```java
private static class BeanMethodInterceptor implements MethodInterceptor, ConditionalCallback {
	// 条件匹配了才拦截【有@Bean注解才拦截】
    /*
        public static boolean isBeanAnnotated(Method method) {
            return AnnotatedElementUtils.hasAnnotation(method, Bean.class);
        }
	 */
	@Override
	public boolean isMatch(Method candidateMethod) {
		return (candidateMethod.getDeclaringClass() != Object.class &&
				BeanAnnotationHelper.isBeanAnnotated(candidateMethod));
	}
}
```
什么情况会被BeanMethodInterceptor拦截器拦截呢？ 把前面的内容总结下：
1. 在配置类是full模式，且，方法被标注了@Bean 才会被拦截！！
2. 配置类是lite模式，无论是否配置了@Bean都不会被拦截


##### 拦截方法

主要有下面2点：
1. 当前bean是不是正在创建中【99%情况下是这种的】
2. 不是在创建中的，执行"解析Bean的引用"【1%的情况下是这种】

```java
private static class BeanMethodInterceptor implements MethodInterceptor, ConditionalCallback {
	/**
     * 拦截方法
	 */
    @Override
    @Nullable
    public Object intercept(Object enhancedConfigInstance, Method beanMethod, Object[] beanMethodArgs,
                            MethodProxy cglibMethodProxy) throws Throwable {

        ConfigurableBeanFactory beanFactory = getBeanFactory(enhancedConfigInstance);
        String beanName = BeanAnnotationHelper.determineBeanNameFor(beanMethod);

        // 标注了@Scope，特殊处理
        Scope scope = AnnotatedElementUtils.findMergedAnnotation(beanMethod, Scope.class);
        if (scope != null && scope.proxyMode() != ScopedProxyMode.NO) {
            String scopedBeanName = ScopedProxyCreator.getTargetBeanName(beanName);
            if (beanFactory.isCurrentlyInCreation(scopedBeanName)) {
                beanName = scopedBeanName;
            }
        }

        if (factoryContainsBean(beanFactory, BeanFactory.FACTORY_BEAN_PREFIX + beanName) &&
                factoryContainsBean(beanFactory, beanName)) {
            Object factoryBean = beanFactory.getBean(BeanFactory.FACTORY_BEAN_PREFIX + beanName);
            if (factoryBean instanceof ScopedProxyFactoryBean) {
                // Scoped proxy factory beans are a special case and should not be further proxied
            }
            else {
                // It is a candidate FactoryBean - go ahead with enhancement
                return enhanceFactoryBean(factoryBean, beanMethod.getReturnType(), beanFactory, beanName);
            }
        }

		// 是不是正在创建中（99%情况下都是）
        if (isCurrentlyInvokedFactoryMethod(beanMethod)) {
			
			// 如果正在创建中，且是BeanFactoryPostProcessor类型就抛出警告⚠️【就是仅仅为了如果是BeanFactoryPostProcessor抛出警告】
            if (logger.isWarnEnabled() &&
                    BeanFactoryPostProcessor.class.isAssignableFrom(beanMethod.getReturnType())) {
                logger.warn(String.format("@Bean method %s.%s is non-static and returns an object " +
                                "assignable to Spring's BeanFactoryPostProcessor interface. This will " +
                                "result in a failure to process annotations such as @Autowired, " +
                                "@Resource and @PostConstruct within the method's declaring " +
                                "@Configuration class. Add the 'static' modifier to this method to avoid " +
                                "these container lifecycle issues; see @Bean javadoc for complete details.",
                        beanMethod.getDeclaringClass().getSimpleName(), beanMethod.getName()));
            }
			// 然后执行拦截器后的方法
            return cglibMethodProxy.invokeSuper(enhancedConfigInstance, beanMethodArgs);
        }

		// 剩下的1%情况，解析bean的引用，如果有直接从容器中拿到如果没有则创建【哪一个中这1%的情况呢】
        return resolveBeanReference(beanMethod, beanMethodArgs, beanFactory, beanName);
    }
}
```
看完几个疑问？

**疑问一**：如果是在创建中且是BeanFactoryPostProcessor类型，则抛出警告然后继续执行，为什么要抛出警告？给了什么解决方法？

为什么有警告信息：https://blog.csdn.net/u013202238/article/details/90315764
警告信息有什么影响：**不能被cglib增强，可能导致问题，所以spirng boot用了warn警告日志**
怎么避免：可以用static处理（原理后续会讲解到）



**疑问二**：那这1%的情况有哪些呢？

剩下的1%情况，解析bean的引用，如果有直接从容器中拿到如果没有则创建，创建后就拿到bean的引用了

常见的是@Bean注解的方法被调用时，如：
```java
@Configuration
class AppConfig {
	@Bean
    // 即是一个普通方法，也是一个Bean。
	// TODO 是一个普通方法所以能被拦截器拦截。
	Son son(){
		return new Son();
	}
	
	@Bean
	Parent parent(){
		// TODO 疑问：son()方法被拦截了 -----> 为什么能被拦截【拦截的条件是什么】
		return new Parent(son());
	}

	@Bean
	Parent parent1(Son son){
		// 注意：这种情况不同于上面的，直接走getBean(parent)方法就可以了，spring在处理parent初始化的过程中会进行依赖注入son对象
        //      
		return new Parent(son);
	}
}
```

**疑问三**：什么叫做"解析Bean的引用"
其实就是调用getBean方法。如果容器中有该bean则直接获取，如果容器中没有则创建。

