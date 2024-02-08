@[TOC](文章结构)

本文作为 `Spring Boot` 自动装配原理的第一篇文章，直接讨论自动装配的核心部分

```shell
【Spring Boot 自动装配的入口原理】http://www.baidu.com
```

## Spring Boot 自动装配（核心原理）

以下方法返回的字符串数组就是需要自动装配的配置类列表，总体获取配置类列表的代码如下：

```java
// AutoConfigurationImportSelector.class
public String[] selectImports(AnnotationMetadata annotationMetadata) {
    if (!isEnabled(annotationMetadata)) {
        return NO_IMPORTS;
    }
    // <1> 加载所有的jar包中的 `META-INF/spring-autoconfigure-metadata.properties` 文件
    AutoConfigurationMetadata autoConfigurationMetadata = AutoConfigurationMetadataLoader
        .loadMetadata(this.beanClassLoader);
    // <2> 从@EnableAutoConfiguration注解的元数据AnnotationMetadata中获取所有的属性
    AnnotationAttributes attributes = getAttributes(annotationMetadata);
    // <3> 加载所有jar包中的 `META-INF/spring.factories` 配置文件，获取key=EnableAutoConfiguration的所有自动配置类
    List<String> configurations = getCandidateConfigurations(annotationMetadata, attributes);
    // <4> 移除重复的配置类
    configurations = removeDuplicates(configurations);
    // <5> 获取需要排除的条件
    Set<String> exclusions = getExclusions(annotationMetadata, attributes);
    // <6> 检查排除的类
    checkExcludedClasses(configurations, exclusions);
    // <7> 移除排除的类
    configurations.removeAll(exclusions);
    // <8> 执行filter过滤
    configurations = filter(configurations, autoConfigurationMetadata);
    // <9> 触发事件
    fireAutoConfigurationImportEvents(configurations, exclusions);
    return StringUtils.toStringArray(configurations);
}
```

先介绍下参数 `annotationMetadata` ，该参数表示注解元数据，包含了该注解的所有完整信息，谁导入( `@Import` )了selectImports方法所在的类这个注解就表示谁，所以此处annotationMetadata表示的是注解 `EnableAutoConfiguration` 的元数据信息

接下来对上述方法做简单说明：

* `<1>` 处，加载所有的jar包中的 `META-INF/spring-autoconfigure-metadata.properties` 文件，并缓存，为后面过滤服务

* `<2>` 处，从 `@EnableAutoConfiguration` 注解的元数据 `AnnotationMetadata` 中获取所有的属性

* `<3>` 处，读取 `META-INF/spring.factories` 配置文件，获取 `key=EnableAutoConfiguration` 的所有自动配置类，见下文『`getCandidateConfigurations 方法`』

* `<4>` 处，移除重复的配置类

* `<5>` 处，获取需要排除的条件，见下文『`getExclusions 方法`』

  > 包含：
  >
  > 1、 `exclude` 属性
  >
  > 2、 `excludeName` 属性
  >
  > 3、 `spring.autoconfigure.exclude` 环境配置

* `<6>` 处，检查排除的类

* `<7>` 处，移除排除的类

* `<8>` 处，排除完 3 种需要排除的情况后，还需要执行 filter 过滤，见下文『`filter 方法`』

* `<9>` 处，触发了事件

### getCandidateConfigurations 方法

通过读取 `META-INF/spring.factories` 配置文件中key为 `EnableAutoConfiguration` 的配置，获取到所有的候选装配组件

```java
public class AutoConfigurationImportSelector
		implements DeferredImportSelector, BeanClassLoaderAware, ResourceLoaderAware,
		BeanFactoryAware, EnvironmentAware, Ordered {
	protected List<String> getCandidateConfigurations(AnnotationMetadata metadata,
	                                                  AnnotationAttributes attributes) {
        // <1> 读取所有jar包中的 META-INF/spring.factories 文件中 key 为 EnableAutoConfiguration的条目
		List<String> configurations = SpringFactoriesLoader.loadFactoryNames(
				getSpringFactoriesLoaderFactoryClass(), getBeanClassLoader());
		Assert.notEmpty(configurations,
				"No auto configuration classes found in META-INF/spring.factories. If you "
						+ "are using a custom packaging, make sure that file is correct.");
		return configurations;
	}

	protected Class<?> getSpringFactoriesLoaderFactoryClass() {
		return EnableAutoConfiguration.class;
	}
}
```

### getExclusions 方法

该方法的作用是获取需要排除的自动装配类的情况，有下面 3 种：

* @EnableAutoConfiguration 的 exclude 属性
* @EnableAutoConfiguration 的 excludeName 属性
* 环境变量 `spring.autoconfigure.exclude`

```java
public class AutoConfigurationImportSelector
		implements DeferredImportSelector, BeanClassLoaderAware, ResourceLoaderAware,
		BeanFactoryAware, EnvironmentAware, Ordered {

	private static final String PROPERTY_NAME_AUTOCONFIGURE_EXCLUDE = "spring.autoconfigure.exclude";

	protected Set<String> getExclusions(AnnotationMetadata metadata,
	                                    AnnotationAttributes attributes) {
		Set<String> excluded = new LinkedHashSet<>();
        // <1> 从注解属性中获取 exclude
		excluded.addAll(asList(attributes, "exclude"));
        // <2> 从注解属性中获取 excludeName
		excluded.addAll(Arrays.asList(attributes.getStringArray("excludeName")));
        // <3> 从环境 env 中获取 spring.autoconfigure.exclude
		excluded.addAll(getExcludeAutoConfigurationsProperty());
		return excluded;
	}

    // 从环境中获取 spring.autoconfigure.exclude
	private List<String> getExcludeAutoConfigurationsProperty() {
		if (getEnvironment() instanceof ConfigurableEnvironment) {
			Binder binder = Binder.get(getEnvironment());
			return binder.bind(PROPERTY_NAME_AUTOCONFIGURE_EXCLUDE, String[].class)
					.map(Arrays::asList).orElse(Collections.emptyList());
		}
		String[] excludes = getEnvironment()
				.getProperty(PROPERTY_NAME_AUTOCONFIGURE_EXCLUDE, String[].class);
		return (excludes != null ? Arrays.asList(excludes) : Collections.emptyList());
	}
}
```

### filter 方法

作用：通过 `AutoConfigurationImportFilter` 配置（即自动配置导入过滤器）来过滤掉一些不满足条件的配置类

举例：以 `OnClassCondition` 为例，通过把配置类依赖的Class条件提前列出来，然后检测依赖的Class是否存在于 classpath 中来提前过滤掉一些配置类，相对 `@ConditionalOnClass` 注解原理具有更好的效率

> 备注：类 OnClassCondition 和 @ConditionalOnClass 注解作用是一样的，可被@ConditionalOnClass代替

该方法代码如下：


```java
// AutoConfigurationImportSelector.class

// <1> autoConfigurationMetadata 参数
private List<String> filter(List<String> configurations,
                            AutoConfigurationMetadata autoConfigurationMetadata) {
    long startTime = System.nanoTime();
    String[] candidates = StringUtils.toStringArray(configurations);
    // <2> 最终需要过滤掉的配置类结果数组，默认是false保留配置类，为true过滤掉配置类
    boolean[] skip = new boolean[candidates.length];
    boolean skipped = false;
    // <3> 获取过滤器列表
    for (AutoConfigurationImportFilter filter : getAutoConfigurationImportFilters()) {
        invokeAwareMethods(filter);
        // <4> 是否跟过滤器匹配【期待：match数组是false，false表示跳过该配置类】
        boolean[] match = filter.match(candidates, autoConfigurationMetadata);
        for (int i = 0; i < match.length; i++) {
            if (!match[i]) {
                skip[i] = true;
                skipped = true;
            }
        }
    }
    if (!skipped) {
        return configurations;
    }
    List<String> result = new ArrayList<>(candidates.length);
    // <5> 最终的自动装配类
    for (int i = 0; i < candidates.length; i++) {
        if (!skip[i]) {
            result.add(candidates[i]);
        }
    }
    return new ArrayList<>(result);
}
```

* `<1>` 处， `autoConfigurationMetadata` 参数内容来自 `META-INF/spring-autoconfigure-metadata.properties`

* `<2>` 处，skip 数组记录最终需要跳过的配置类结果

* `<3>` 处，获取所有配置的过滤器，用 `SpringFactoriesLoader.loadFactories` 方式获取 key 为 `AutoConfigurationImportFilter` 的自动配置类导入过滤器

  > Spring Boot 2.0.2.RELEASE 默认只配置了 `OnClassCondition` ，配置如下：
  >
  > ```properties
  > // spring.factories 文件
  > # Auto Configuration Import Filters
  > org.springframework.boot.autoconfigure.AutoConfigurationImportFilter=\
  > org.springframework.boot.autoconfigure.condition.OnClassCondition
  > ```

* `<4>` 处，执行某个过滤器的匹配，**匹配结果为 false 则表示跳过该配置类**，为 true 不处理

* `<5>` 处，根据 skip 结果只添加满足条件的配置类，并返回配置类列表

#### autoConfigurationMetadata 的来源
META-INF/spring-autoconfigure-metadata.properties 文件可认为是准备好的用于过滤的元数据，用于帮助提前过滤掉一些配置类、设置配置类装配的相对顺序、设置配置类装配的绝对顺序等作用

```java
final class AutoConfigurationMetadataLoader {

   protected static final String PATH = "META-INF/spring-autoconfigure-metadata.properties";

   public static AutoConfigurationMetadata loadMetadata(ClassLoader classLoader) {
      return loadMetadata(classLoader, PATH);
   }
}
```
spring-autoconfigure-metadata.properties 文件内容举例：
```properties
# AutoConfigureAfter（在某个配置类之后）
org.springframework.boot.autoconfigure.web.client.RestTemplateAutoConfiguration.AutoConfigureAfter=org.springframework.boot.autoconfigure.http.HttpMessageConvertersAutoConfiguration
# AutoConfigureBefore（在某个配置类之前）
org.springframework.boot.autoconfigure.mongo.embedded.EmbeddedMongoAutoConfiguration.AutoConfigureBefore=org.springframework.boot.autoconfigure.mongo.MongoAutoConfiguration
# ConditionalOnClass（对应的类必须存在）
org.springframework.boot.autoconfigure.jooq.JooqAutoConfiguration.ConditionalOnClass=org.jooq.DSLContext

```

#### OnClassCondition 过滤器

在 Spring Boot 2.0.2.RELEASE 版本中，OnClassCondition 过滤器是默认配置的一个 AutoConfigurationImportFilter 自动配置导入过滤器，该配置如下：

```properties
# Auto Configuration Import Filters
org.springframework.boot.autoconfigure.AutoConfigurationImportFilter=\
org.springframework.boot.autoconfigure.condition.OnClassCondition
```

从 OnClassCondition 的英文名称中也可以看出作用是**基于class条件来判断是否加载配置类**，依赖的 class 存在于 classpath 中则加载配置类，依赖的 class 不存在于 classpath 中则不加载配置类

具体的，根据 match 方法返回的数组，数据项为 true 表示 class 存在于 classpath 中，为 false 表示 class 不存在于 classpath 中

match 方法代码如下：

```java
class OnClassCondition extends SpringBootCondition
		implements AutoConfigurationImportFilter, BeanFactoryAware, BeanClassLoaderAware {

	public boolean[] match(String[] autoConfigurationClasses,
	                       AutoConfigurationMetadata autoConfigurationMetadata) {
		ConditionEvaluationReport report = getConditionEvaluationReport();
		// <1> 计算匹配情况
		ConditionOutcome[] outcomes = getOutcomes(autoConfigurationClasses,
				autoConfigurationMetadata);
		boolean[] match = new boolean[outcomes.length];
		for (int i = 0; i < outcomes.length; i++) {
			// <2> 转换匹配情况【期待整体是false，即不等于null 且 match = false，则跳过该配置类】
			match[i] = (outcomes[i] == null || outcomes[i].isMatch());
            // 这里是记录不匹配的情况，把不匹配的原因详情设置到报告器report中
            if (!match[i] && outcomes[i] != null) {
				logOutcome(autoConfigurationClasses[i], outcomes[i]);
				if (report != null) {
					report.recordConditionEvaluation(autoConfigurationClasses[i], this,
							outcomes[i]);
				}
			}
		}
		return match;
	}

    // <3> 计算匹配结果（分2半处理）
	private ConditionOutcome[] getOutcomes(String[] autoConfigurationClasses,
			AutoConfigurationMetadata autoConfigurationMetadata) {

		int split = autoConfigurationClasses.length / 2;
		// 第一个解析器：ThreadedOutcomesResolver
		OutcomesResolver firstHalfResolver = createOutcomesResolver(
				autoConfigurationClasses, 0, split, autoConfigurationMetadata);
		// 第二个解析器：StandardOutcomesResolver
		OutcomesResolver secondHalfResolver = new StandardOutcomesResolver(
				autoConfigurationClasses, split, autoConfigurationClasses.length,
				autoConfigurationMetadata, this.beanClassLoader);
		// 第 2 个解析
		ConditionOutcome[] secondHalf = secondHalfResolver.resolveOutcomes();
		// 第 1 个解析
		ConditionOutcome[] firstHalf = firstHalfResolver.resolveOutcomes();
		ConditionOutcome[] outcomes = new ConditionOutcome[autoConfigurationClasses.length];
		System.arraycopy(firstHalf, 0, outcomes, 0, firstHalf.length);
		System.arraycopy(secondHalf, 0, outcomes, split, secondHalf.length);
		return outcomes;
	}
}
```

* `<1>` 处，计算候选配置类的匹配情况

* `<2>` 处，把匹配情况转换为匹配数组

  > 备注：
  >
  > 1、要想数组项为 false，则要求 2 个条件都为 false
  >
  > 2、要想数组项为 true，只要 2 个条件有一个为 true 即可

* `<3>` 处，用到了二分法，使用到了 2 个解析器对候选配置类进行解析，一个解析一半配置类

##### StandardOutcomesResolver 解析器

StandardOutcomesResolver 解析器计算配置类的 ConditionalOnClass 配置是否都存在在 claspath 中

```java
private final class StandardOutcomesResolver implements OutcomesResolver {

    // 解析
    @Override
    public ConditionOutcome[] resolveOutcomes() {
        return getOutcomes(this.autoConfigurationClasses, this.start, this.end,
                this.autoConfigurationMetadata);
    }

    private ConditionOutcome[] getOutcomes(String[] autoConfigurationClasses,
            int start, int end, AutoConfigurationMetadata autoConfigurationMetadata) {
        ConditionOutcome[] outcomes = new ConditionOutcome[end - start];

        // <1> 迭代候选配置类
        for (int i = start; i < end; i++) {
            String autoConfigurationClass = autoConfigurationClasses[i];
            // <2> 获取配置类的 ConditionalOnClass 条件
            Set<String> candidates = autoConfigurationMetadata
                    .getSet(autoConfigurationClass, "ConditionalOnClass");
            if (candidates != null) {
                // <3> 计算candidates是否满足
                outcomes[i - start] = getOutcome(candidates);
            }
        }
        return outcomes;
    }
}
```

* `<1>` 处，迭代二分法中的候选配置类
* `<2>` 处，从元数据中取出某配置类的 ConditionalOnClass 条件集合
* `<3>` 处，具体的计算candidates是否满足

继续看 getOutcome 方法

```java
private ConditionOutcome getOutcome(Set<String> candidates) {
    try {
        // <1> 计算 candidates 和 MISSING 的匹配情况
        List<String> missing = getMatches(candidates, MatchType.MISSING,
                                          this.beanClassLoader);
        if (!missing.isEmpty()) {
            // <2> 此时 match 为 false
            return ConditionOutcome.noMatch(
                ConditionMessage.forCondition(ConditionalOnClass.class)
                .didNotFind("required class", "required classes")
                .items(Style.QUOTE, missing));
        }
    }
    catch (Exception ex) {
        // We'll get another chance later
    }
    return null;
}
```

* `<1>` 处，计算 candidates 和 MISSING 的匹配情况；因为是 MISSING 类型，返回的 missing 表示缺失的集合；**只要集合不为空则表示有缺失则表示检测失败，该配置类不应该被装配**

那继续看集合什么情况下不为空，代码如下：

```java
private List<String> getMatches(Collection<String> candidates, MatchType matchType,
                                ClassLoader classLoader) {
    List<String> matches = new ArrayList<>(candidates.size());
    for (String candidate : candidates) {
        // 要求 match
        if (matchType.matches(candidate, classLoader)) {
            matches.add(candidate);
        }
    }
    return matches;
}
```

继续看 MISSING 类型的 matches 方法
```java
private enum MatchType {

	MISSING {
		@Override
		public boolean matches(String className, ClassLoader classLoader) {
            // className 是否存在于 classpath 中
			return !isPresent(className, classLoader);
		}
	};
}
```

当 className 不存在于 classpath 中时matches方法返回 true，getMatches方法返回非空的缺失集合

### 触发自动装配事件
继续探讨 `fireAutoConfigurationImportEvents(configurations, exclusions)` 方法的实现
```java
public class AutoConfigurationImportSelector
		implements DeferredImportSelector, BeanClassLoaderAware, ResourceLoaderAware,
		BeanFactoryAware, EnvironmentAware, Ordered {

	private void fireAutoConfigurationImportEvents(List<String> configurations,
	                                               Set<String> exclusions) {
		// 获取配置的监听器
		List<AutoConfigurationImportListener> listeners = getAutoConfigurationImportListeners();
		if (!listeners.isEmpty()) {
			// 创建事件
			AutoConfigurationImportEvent event = new AutoConfigurationImportEvent(this,
					configurations, exclusions);
			for (AutoConfigurationImportListener listener : listeners) {
				invokeAwareMethods(listener);
				// 执行事件
				listener.onAutoConfigurationImportEvent(event);
			}
		}
	}
}
```
Spring Boot 在框架层面为开发人员提供了拓展的途径，使得我们可以评估自动配置类的装载情况，以 Spring Boot 2.0.2.RELEASE 为例，默认配置了一个 AutoConfigurationImportListener 的实现 ConditionEvaluationReportAutoConfigurationImportListener，该实现类用于记录自动装配的条件的评估详情。该配置在 META-INF/spring.factories 文件中，如下：

```properties
# Auto Configuration Import Listeners
org.springframework.boot.autoconfigure.AutoConfigurationImportListener=\
org.springframework.boot.autoconfigure.condition.ConditionEvaluationReportAutoConfigurationImportListener

```

传送门： <a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>
