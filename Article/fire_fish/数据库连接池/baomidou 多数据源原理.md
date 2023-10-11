## 引入依赖
```xml
<!-- 实现对 dynamic-datasource 的自动化配置 -->
<dependency>
    <groupId>com.baomidou</groupId>
    <artifactId>dynamic-datasource-spring-boot-starter</artifactId>
    <version>2.5.7</version>
</dependency>
```

## 分析自动装配的bean
```java
@Configuration
// 属性以spring.datasource.dynamic开头
@EnableConfigurationProperties(DynamicDataSourceProperties.class)
// 先把数据源配置好把
@AutoConfigureBefore(DataSourceAutoConfiguration.class)
// 需要导入哪些bean定义
@Import(DruidDynamicDataSourceConfiguration.class)
// 要有这些属性
@ConditionalOnProperty(prefix = DynamicDataSourceProperties.PREFIX, name = "enabled", havingValue = "true", matchIfMissing = true)
public class DynamicDataSourceAutoConfiguration {

	// 添加aop拦截器
	@Bean
	@ConditionalOnMissingBean
	public DynamicDataSourceAnnotationAdvisor dynamicDatasourceAnnotationAdvisor(
			DsProcessor dsProcessor) {
		DynamicDataSourceAnnotationInterceptor interceptor = new DynamicDataSourceAnnotationInterceptor();
		interceptor.setDsProcessor(dsProcessor);
		DynamicDataSourceAnnotationAdvisor advisor = new DynamicDataSourceAnnotationAdvisor(
				interceptor);
		advisor.setOrder(properties.getOrder());
		return advisor;
	}
}
```
1. DynamicDataSourceAutoConfiguration
2. DynamicDataSourceProperties（配置类：以`spring.datasource.dynamic`开头
3. DynamicDataSourceAnnotationAdvisor（实现了`Advisor`，会被aop收集起来作为增强器）

## 分析DynamicDataSourceAnnotationAdvisor的原理

因为DynamicDataSourceAnnotationAdvisor实现了Advisor接口，会被aop收集起来作为增强器。

1. 当开启aop功能时，会向容器中注入一个`AnnotationAwareAspectJAutoProxyCreator`的bean，另外由于它实现了InstantiationAwareBeanPostProcessor接口，
   所以会在每个bean的doCreateBean方法之前被调用
2. 就是由这个bean完成aop中Advisor接口 或 @Advisor注解 的所有的收集
3. 会从收集的中挑选出满足当前bean的增强器
4. 到这里也就得到了适用当前bean的增强器。就可以借由增强器创建代理了
5. 。。。后续真正调用代码方法的时候就可以对方法进行增强了

### 寻找候选增强器（使用的是aop原理）

createBean方法
```java
try {
    // Give BeanPostProcessors a chance to return a proxy instead of the target bean instance.
    // 这个方法在每次真正创建bean之前都会调用，而在这方法中会调用InstantiationAwareBeanPostProcessor接口的postProcessBeforeInstantiation方法
    // 而只要开启aop功能，就会有一个AnnotationAwareAspectJAutoProxyCreator接口会执行
    // 而    AnnotationAwareAspectJAutoProxyCreator   会负责收集容器中实现了Advisor接口的bean
    Object bean = resolveBeforeInstantiation(beanName, mbdToUse);
    if (bean != null) {
        return bean;
    }
	// 真正创建bean
	Object beanInstance = doCreateBean(beanName, mbdToUse, args);
}
```
AnnotationAwareAspectJAutoProxyCreator完成Advisor接口的收集
`List<Advisor> candidateAdvisors = findCandidateAdvisors();`查找候选的增强器
```java
protected List<Advisor> findCandidateAdvisors() {
    // Add all the Spring advisors found according to superclass rules.
        // 1、查找实现了Advisor接口的
    List<Advisor> advisors = super.findCandidateAdvisors();
    // Build Advisors for all AspectJ aspects in the bean factory.
    if (this.aspectJAdvisorsBuilder != null) {
		// 2、也查找被@Advisor注解标识的
        advisors.addAll(this.aspectJAdvisorsBuilder.buildAspectJAdvisors());
    }
    return advisors;
}
```
我们这里看实现了Advisor接口的
```java
public List<Advisor> findAdvisorBeans() {
	String[] advisorNames = BeanFactoryUtils.beanNamesForTypeIncludingAncestors(
                this.beanFactory, Advisor.class, true, false);
	
    List<Advisor> advisors = new ArrayList<>();
    for (String name : advisorNames) {
        if (isEligibleBean(name)) {     // 要求合法的
            if (this.beanFactory.isCurrentlyInCreation(name)) {
                if (logger.isTraceEnabled()) {
                    logger.trace("Skipping currently created advisor '" + name + "'");
                }
            }
			// 总要把bean创建好把，才能作为advisor把，所以要等待bean创建完成
            else {
                advisors.add(this.beanFactory.getBean(name, Advisor.class));
            }
        }
    }
    return advisors;
}
```

### 获取适配当前bean的增强器
获取`DynamicDataSourceAnnotationAdvisor`接口实现了Advisor接口的getPointcut方法的
```java
  public Pointcut getPointcut() {
    return this.pointcut;
  }
```
继续看`buildPointcut`方法
```java
  private Pointcut buildPointcut() {
	// 获取DS注解标识的类
    Pointcut cpc = new AnnotationMatchingPointcut(DS.class, true);
	// 获取@DS注解标识的方法
    Pointcut mpc = AnnotationMatchingPointcut.forMethodAnnotation(DS.class);
	// 结合2种匹配规则
    return new ComposablePointcut(cpc).union(mpc);
  }
```
继续看ComposablePointcut类
```java
public ComposablePointcut(Pointcut pointcut) {
    Assert.notNull(pointcut, "Pointcut must not be null");
    this.classFilter = pointcut.getClassFilter();
	// 方法匹配：当匹配到瞒足这个的方法时就把增强器加入到列表中用于后续增强
    this.methodMatcher = pointcut.getMethodMatcher();
}
```
接着上面就有了2种匹配规则
1. AnnotationMethodMatcher（匹配标识了特定注解的方法）
2. TrueMethodMatcher（匹配任何方法）

```java
// TrueMethodMatcher类
public boolean matches(Method method, Class<?> targetClass) {
    return true;
}
```

```java
// AnnotationMethodMatcher 类
// 只匹配 标注了 annotationType  类型的注解的方法
	public boolean matches(Method method, Class<?> targetClass) {
		if (matchesMethod(method)) {
			return true;
		}
		// Proxy classes never have annotations on their redeclared methods.
		if (Proxy.isProxyClass(targetClass)) {
			return false;
		}
		// The method may be on an interface, so let's check on the target class as well.
		Method specificMethod = AopUtils.getMostSpecificMethod(method, targetClass);
		return (specificMethod != method && matchesMethod(specificMethod));
	}

	private boolean matchesMethod(Method method) {
		return (this.checkInherited ? AnnotatedElementUtils.hasAnnotation(method, this.annotationType) :
				method.isAnnotationPresent(this.annotationType));
	}
```
到这里就确定了该类适用于哪些增强器

### 真正执行时被代理拦截

如果在类 或 方法上注解了@DS，则当前bean就会被DynamicDataSourceAnnotationInterceptor增强，方法也就会被拦截。


cglib拦截器
```java
retVal = new CglibMethodInvocation(proxy, target, method, args, targetClass, chain, methodProxy).proceed();
```
DynamicDataSourceAnnotationInterceptor的拦截方法
```java
public Object invoke(MethodInvocation invocation) throws Throwable {
 try {
   DynamicDataSourceContextHolder.push(determineDatasource(invocation));
   return invocation.proceed();
 } finally {
   DynamicDataSourceContextHolder.poll();
 }
}
```
继续determineDatasource
```java
  private String determineDatasource(MethodInvocation invocation) throws Throwable {
	// 如果方法有注解就用方法的@DS注解的内容
    // 如果方法没有注解就用@DS注解的类的内容。
    // 如果都没有注解。那么就不会存在拦截当前方法了.....就是另外的逻辑了。
    Method method = invocation.getMethod();
    DS ds = method.isAnnotationPresent(DS.class)
        ? method.getAnnotation(DS.class)
        : AnnotationUtils.findAnnotation(RESOLVER.targetClass(invocation), DS.class);
    String key = ds.value();
    return (!key.isEmpty() && key.startsWith(DYNAMIC_PREFIX)) ? dsProcessor
        .determineDatasource(invocation, key) : key;
  }
```
### 如果类 或 方法 没有被@DS注解标注
如果类 或 方法 没有被@DS注解标注，走的就不会 DynamicDataSourceAnnotationInterceptor 拦截方法的逻辑，是另外的逻辑。
比如方法仅仅被@Tranactional标注了。

就会走spring的事务逻辑，会从当前线程中取出TransactionInfo定义，如果当前线程没有就会采用特殊方法决定使用哪一个DataSource来生成事务信息。
让我们从事务的拦截方法开始分析
```java
 public Object invoke(MethodInvocation invocation) throws Throwable {
     
     Class<?> targetClass = (invocation.getThis() != null ? AopUtils.getTargetClass(invocation.getThis()) : null);
	 
     return invokeWithinTransaction(invocation.getMethod(), targetClass, invocation::proceed);
 }
```
获取事务信息
```java
TransactionInfo txInfo = createTransactionIfNecessary(tm, txAttr, joinpointIdentification);

// 从事务管理器获取事务信息
status = tm.getTransaction(txAttr);
```
准备好事务的连接并绑定到线程
```java
public final TransactionStatus getTransaction(@Nullable TransactionDefinition definition) {
        boolean newSynchronization = (getTransactionSynchronization() != SYNCHRONIZATION_NEVER);
        DefaultTransactionStatus status = newTransactionStatus(
        definition, transaction, true, newSynchronization, debugEnabled, suspendedResources);
		// 继续看doBegin方法
        doBegin(transaction, definition);
        prepareSynchronization(status, definition);
        return status;	
}
```
继续看doBegin方法，**获取连接**
```java
protected void doBegin(Object transaction, TransactionDefinition definition){
	// 当期线程是否有连接
    if(!txObject.hasConnectionHolder()||txObject.getConnectionHolder().isSynchronizedWithTransaction()){
       // 获取连接（重点）
       Connection newCon=obtainDataSource().getConnection();
       // 设置连接到当前线程
       txObject.setConnectionHolder(new ConnectionHolder(newCon),true);
    }
    // 如果当前线程有链接，直接返回
    txObject.getConnectionHolder().setSynchronizedWithTransaction(true);
}
```
继续看obtainDataSource()，进入baomidou
```java
  public Connection getConnection() throws SQLException {
    return determineDataSource().getConnection();
  }
```
```java
  public DataSource determineDataSource() {
    return getDataSource(DynamicDataSourceContextHolder.peek());  // peek取出之前存入的DataSource，如果之前有@DS注解配置就会存入，这里默认没有
  }
```
这里我们没有设置
```java
  public DataSource getDataSource(String ds) {
	// 如果之前没有设置@DS
    if (StringUtils.isEmpty(ds)) {
      return determinePrimaryDataSource();
    } else if (!groupDataSources.isEmpty() && groupDataSources.containsKey(ds)) {
      log.debug("dynamic-datasource switch to the datasource named [{}]", ds);
      return groupDataSources.get(ds).determineDataSource();
	// 如果之前设置了@DS，就用设置的
    } else if (dataSourceMap.containsKey(ds)) {
      log.debug("dynamic-datasource switch to the datasource named [{}]", ds);
      return dataSourceMap.get(ds);
    }
    if (strict) {
      throw new RuntimeException("dynamic-datasource could not find a datasource named" + ds);
    }
    return determinePrimaryDataSource();
  }
```
继续看determinePrimaryDataSource。
**如果之前没有设置@DS，就用默认的primary数据源。**
```java
private DataSource determinePrimaryDataSource() {
 log.debug("dynamic-datasource switch to the primary datasource");
 return groupDataSources.containsKey(primary) ? groupDataSources.get(primary)
     .determineDataSource() : dataSourceMap.get(primary);
}
```
