
@[TOC](文章结构)

### 获取增强器细节补充
#### 先介绍下几个核心类

| 接口                                       | 功能                  | 说明                                  |
|------------------------------------------|---------------------|-------------------------------------|
| AspectJAdvisorFactory                    | 用来创建增强方法的工厂         | 一般实现类是：ReflectiveAspectJAdvisorFactory |
| AspectJExpressionPointcut                | 封装了<mark>切入点</mark> | 即@PointCut注解的信息                     |
| InstantiationModelAwarePointcutAdvisorImpl | 封装了<mark>增强器</mark>信息 | 封装思想                                |
| Advice                                   | 增强器                 | 增强器是有多种类型的，关于增强器的介绍见下表              |

#### 再介绍不同类型的增强器（Advice）：

| 类型                          | 功能        | 说明        |
|-----------------------------|-----------|-----------|
| AspectJAroundAdvice         | 环绕增强      | 对应`@Around`注解 |
| AspectJMethodBeforeAdvice   | 前置增强      | 对应`@Before`注解 |
| AspectJAfterAdvice          | 后置增强（要求无异常） | 对应`@After`注解 |
| AspectJAfterReturningAdvice | 返回增强      | 对应`@AfterReturning`注解 |
| AspectJAfterThrowingAdvice  | 异常增强      | 对应`@AfterThrowing`注解 |

#### 说明上文为何在源码没有看到@Before注解等
`@Before`注解的解析必然在处理候选增强器的某个步骤遗漏了。
重看查找候选增强器的方法
```java
protected List<Advisor> findEligibleAdvisors(Class<?> beanClass, String beanName) {
    // 查找"候选的"增强方法
    List<Advisor> candidateAdvisors = findCandidateAdvisors();

    // 查找适应当前bean的增强方法
    List<Advisor> eligibleAdvisors = findAdvisorsThatCanApply(candidateAdvisors, beanClass, beanName);

    // 拓展advisors
    extendAdvisors(eligibleAdvisors);
    if (!eligibleAdvisors.isEmpty()) {
        // 排序
        eligibleAdvisors = sortAdvisors(eligibleAdvisors);
    }
    return eligibleAdvisors;
}
```
查看findCandidateAdvisors的实现发现有2个，但是我们是从AnnotationAwareAspectJAutoProxyCreator调用过来的，
所以这里是调用的子类的findCandidateAdvisors方法。继续看子类的findCandidateAdvisors方法。
```java
protected List<Advisor> findCandidateAdvisors() {
    // Add all the Spring advisors found according to superclass rules.
    // 添加所有的Spring的advisors（根据父类规则找到的。直白一点就是处理xml和实现Advisor接口的）
    List<Advisor> advisors = super.findCandidateAdvisors();
    // Build Advisors for all AspectJ aspects in the bean factory.
    // 直白一点就是处理 @Aspect 注解的
    if (this.aspectJAdvisorsBuilder != null) {
        advisors.addAll(this.aspectJAdvisorsBuilder.buildAspectJAdvisors());
    }
    return advisors;
}
```
在该方法中，先调用父类的findCandidateAdvisors得到一批候选增强器，其实就是通过实现`Advisor`接口来增强的方法（上文已经分析了）；
而在buildAspectJAdvisors也得到一批增强器，其实就是通过`@AspectJ`注解来增强的方法。继续看buildAspectJAdvisors方法。
```java
// 查找AspectJ注解的bean在当前容器中，并返回AOP Advisors来表示它们
public List<Advisor> buildAspectJAdvisors() {
    List<String> aspectNames = this.aspectBeanNames;

    // 1、第一次调用代码时才会进入（因为只有初始化时才会为null，执行过一次后就会是一个集合）
    if (aspectNames == null) {
        synchronized (this) {
            aspectNames = this.aspectBeanNames;
            if (aspectNames == null) {
                List<Advisor> advisors = new ArrayList<>();
                aspectNames = new ArrayList<>();
                // 2、获取容器中所有对象名称（不像父类一样只获取Advisor接口的bean名称）
                String[] beanNames = BeanFactoryUtils.beanNamesForTypeIncludingAncestors(
                        this.beanFactory, Object.class, true, false);
                // 3、遍历
                for (String beanName : beanNames) {
                    // 4、判断beanType是否是一个切面（是不是有@Aspect注解）
                    if (this.advisorFactory.isAspect(beanType)) {
                        aspectNames.add(beanName);
                        AspectMetadata amd = new AspectMetadata(beanType, beanName);
                        if (amd.getAjType().getPerClause().getKind() == PerClauseKind.SINGLETON) {
                            MetadataAwareAspectInstanceFactory factory =
                                    new BeanFactoryAspectInstanceFactory(this.beanFactory, beanName);

                            // -------------核心方法------------
                            // 5、获取切切面的"增强（advisor）"
                            List<Advisor> classAdvisors = this.advisorFactory.getAdvisors(factory);
                            if (this.beanFactory.isSingleton(beanName)) {
                                this.advisorsCache.put(beanName, classAdvisors);
                            }
                            else {
                                this.aspectFactoryCache.put(beanName, factory);
                            }
                            advisors.addAll(classAdvisors);
                        }
                        else {
                            // Per target or per this.
                            if (this.beanFactory.isSingleton(beanName)) {
                                throw new IllegalArgumentException("Bean with name '" + beanName +
                                        "' is a singleton, but aspect instantiation model is not singleton");
                            }
                            MetadataAwareAspectInstanceFactory factory =
                                    new PrototypeAspectInstanceFactory(this.beanFactory, beanName);
                            this.aspectFactoryCache.put(beanName, factory);
                            advisors.addAll(this.advisorFactory.getAdvisors(factory));
                        }
                    }
                }
                this.aspectBeanNames = aspectNames;
                return advisors;
            }
        }
    }
```
重点看下获取切面增强的核心方法
```java
List<Advisor> classAdvisors = this.advisorFactory.getAdvisors(factory);
```
遍历该类的每个方法，查找增强：
```java
	public List<Advisor> getAdvisors(MetadataAwareAspectInstanceFactory aspectInstanceFactory) {
		List<Advisor> advisors = new ArrayList<>();
		// 查找切面类的Advisors方法
		for (Method method : getAdvisorMethods(aspectClass)) {
			Advisor advisor = getAdvisor(method, lazySingletonAspectInstanceFactory, advisors.size(), aspectName);
			if (advisor != null) {
				advisors.add(advisor);
			}
		}
		return advisors;
	}
```
查看方法是否配置了@Before等切面注解，随后把切面方法初始化为一个Advisor增强。
```java
public Advisor getAdvisor(Method candidateAdviceMethod, MetadataAwareAspectInstanceFactory aspectInstanceFactory,
    int declarationOrderInAspect, String aspectName) {

    validate(aspectInstanceFactory.getAspectMetadata().getAspectClass());

    // 返回封装了注解、表达式等AspectJ计算规则的类
    AspectJExpressionPointcut expressionPointcut = getPointcut(
    candidateAdviceMethod, aspectInstanceFactory.getAspectMetadata().getAspectClass());
    if (expressionPointcut == null) {
        return null;
    }

	// 针对method创建增强，并封装为InstantiationModelAwarePointcutAdvisorImpl对象
    return new InstantiationModelAwarePointcutAdvisorImpl(expressionPointcut, candidateAdviceMethod,
    this, aspectInstanceFactory, declarationOrderInAspect, aspectName);
    }
```
实例化增强方法：
```java
this.instantiatedAdvice = instantiateAdvice(this.declaredPointcut);
```
实例化增强方法的具体实现：
```java
	@Nullable
	public Advice getAdvice(Method candidateAdviceMethod, AspectJExpressionPointcut expressionPointcut,
			MetadataAwareAspectInstanceFactory aspectInstanceFactory, int declarationOrder, String aspectName) {

		// 是诸如 @Before 等的注解
		AspectJAnnotation<?> aspectJAnnotation =
				AbstractAspectJAdvisorFactory.findAspectJAnnotationOnMethod(candidateAdviceMethod);
		if (aspectJAnnotation == null) {
			return null;
		}

		AbstractAspectJAdvice springAdvice;

		// 判断注解的类型
		switch (aspectJAnnotation.getAnnotationType()) {
			case AtPointcut:
				if (logger.isDebugEnabled()) {
					logger.debug("Processing pointcut '" + candidateAdviceMethod.getName() + "'");
				}
				return null;
			case AtAround:
				springAdvice = new AspectJAroundAdvice(
						candidateAdviceMethod, expressionPointcut, aspectInstanceFactory);
				break;
			case AtBefore:
				springAdvice = new AspectJMethodBeforeAdvice(
						candidateAdviceMethod, expressionPointcut, aspectInstanceFactory);
				break;
			case AtAfter:
				springAdvice = new AspectJAfterAdvice(
						candidateAdviceMethod, expressionPointcut, aspectInstanceFactory);
				break;
			case AtAfterReturning:
				springAdvice = new AspectJAfterReturningAdvice(
						candidateAdviceMethod, expressionPointcut, aspectInstanceFactory);
				AfterReturning afterReturningAnnotation = (AfterReturning) aspectJAnnotation.getAnnotation();
				if (StringUtils.hasText(afterReturningAnnotation.returning())) {
					springAdvice.setReturningName(afterReturningAnnotation.returning());
				}
				break;
			case AtAfterThrowing:
				springAdvice = new AspectJAfterThrowingAdvice(
						candidateAdviceMethod, expressionPointcut, aspectInstanceFactory);
				AfterThrowing afterThrowingAnnotation = (AfterThrowing) aspectJAnnotation.getAnnotation();
				if (StringUtils.hasText(afterThrowingAnnotation.throwing())) {
					springAdvice.setThrowingName(afterThrowingAnnotation.throwing());
				}
				break;
			default:
				throw new UnsupportedOperationException(
						"Unsupported advice type on method: " + candidateAdviceMethod);
		}
		return springAdvice;
	}
```
经过了一层层的剥洋葱似的源码分析，终于找到了@Before等注解的处理的地方，不同的注解类型被实例化为不同类型的Advice对象，
不同类型的Advice对象被封装成了Advisor对象（实现类是：InstantiationModelAwarePointcutAdvisorImpl），
<mark>所以Advice或Advisor名字不同但其实表达的意思基本是一样的。</mark>

#### 补充说明一下增强器的分类
在疑问中提出了这个问题，从代码上看是分`IntroductionAdvisor`和`PointcutAdvisor`两类的。
而我们通过@AspectJ注解方法的都是封装成了InstantiationModelAwarePointcutAdvisorImpl类，而它就是PointcutAdvisor，
<mark>所以一般关注`PointcutAdvisor`类型就够了</mark>

### 总结获取增强器
1、获取候选增强器基本可以等同为吧标注了特殊注解的方法信息等封装为InstantiationModelAwarePointcutAdvisorImpl实例返回，
这个实例就代表了`Advisor`增强
2、适配当前bean的增强器，本质就是通过matches方法比较method是不是符合切入点表达式的规则。
本质上是一个表达式语言的解析。

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>

