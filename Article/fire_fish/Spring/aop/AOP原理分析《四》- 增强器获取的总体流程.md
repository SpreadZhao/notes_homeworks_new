
@[TOC](文章结构)

增强方法的获取代码：
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
对于增强方法的处理，首先是获取了"候选的"增强方法，然后缩小范围，获取了适应当前bean使用的增强方法。
所谓的适配就是指是不是符合切入点表达式。
这里可以猜测到获取"候选的"增强肯定是被缓存起来的。

### 获取增强器

#### 获取候选的增强器
```java
public List<Advisor> findAdvisorBeans() {
    // 是否已经被缓存过
    String[] advisorNames = this.cachedAdvisorBeanNames;
    if (advisorNames == null) {
        // 查找容器中所有实现了Advisor的beanNames
        advisorNames = BeanFactoryUtils.beanNamesForTypeIncludingAncestors(
                this.beanFactory, Advisor.class, true, false);
        this.cachedAdvisorBeanNames = advisorNames;
    }
    if (advisorNames.length == 0) {
        return new ArrayList<>();
    }

    List<Advisor> advisors = new ArrayList<>();
    for (String name : advisorNames) {
        // 实例化Advisor类型的bean，并把它们加入到advisors中
        advisors.add(this.beanFactory.getBean(name, Advisor.class));
    }
    return advisors;
}
```
#### 查找适配当前bena的增强器

```java
public static List<Advisor> findAdvisorsThatCanApply(List<Advisor> candidateAdvisors, Class<?> clazz) {
    if (candidateAdvisors.isEmpty()) {
        return candidateAdvisors;
    }
    List<Advisor> eligibleAdvisors = new ArrayList<>();
    for (Advisor candidate : candidateAdvisors) {
        if (candidate instanceof IntroductionAdvisor && canApply(candidate, clazz)) {
            eligibleAdvisors.add(candidate);
        }
    }
    boolean hasIntroductions = !eligibleAdvisors.isEmpty();
    for (Advisor candidate : candidateAdvisors) {
        if (candidate instanceof IntroductionAdvisor) {
            // already processed
            continue;
        }
        if (canApply(candidate, clazz, hasIntroductions)) {
            eligibleAdvisors.add(candidate);
        }
    }
    return eligibleAdvisors;
}
```
看了方法的内容无非就是遍历"候选增强器"，虽然是2个循环，但是主要不同点是`canApply`方法的参数不同。
那么需要看下`canApply`方法。
```java
public static boolean canApply(Advisor advisor, Class<?> targetClass, boolean hasIntroductions) {
    if (advisor instanceof IntroductionAdvisor) {
        return ((IntroductionAdvisor) advisor).getClassFilter().matches(targetClass);
    }
    else if (advisor instanceof PointcutAdvisor) {
		// 一般都是这个类型
        PointcutAdvisor pca = (PointcutAdvisor) advisor;
        return canApply(pca.getPointcut(), targetClass, hasIntroductions);
    }
    else {
        // It doesn't have a pointcut so we assume it applies.
        return true;
    }
}
```
canApply方法分类判断了`IntroductionAdvisor`类型和`PointcutAdvisor`类型2种情况。
IntroductionAdvisor类型的直接就执行了matches方法，而PointcutAdvisor代码如下：
```java
public static boolean canApply(Pointcut pc, Class<?> targetClass, boolean hasIntroductions) {

    // 添加目标类的所有接口，既然后续查找了所有的方法那么这是有必要？？？
    classes.addAll(ClassUtils.getAllInterfacesForClassAsSet(targetClass));

    for (Class<?> clazz : classes) {
        // 递归查找 clazz的所有方法
        Method[] methods = ReflectionUtils.getAllDeclaredMethods(clazz);
        for (Method method : methods) {
            if (introductionAwareMethodMatcher != null ?
                    introductionAwareMethodMatcher.matches(method, targetClass, hasIntroductions) :
                    methodMatcher.matches(method, targetClass)) {
                return true;
            }
        }
    }
    return false;
}
```
看到最后我们还是发现最后是调用了matches方法进行匹配，如果匹配上说明增强器适配当前的bena，匹配不上则不适配。而对于matches就不什么研究了。
猜测是matches调用了底层aop表达式解析方法进行了适配。

到这里我们不免提出几个疑问：
* `@Before`等注解在哪里处理的，肯定是我们在哪里遗漏了
* 我们多次在"增强器适配"的方法中看到了分类谈论，如按`candidate`类型分类而且<mark>似乎就是分为2类</mark>
下篇文章解决下上面的问题和介绍增强器获取的核心组件。

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>

