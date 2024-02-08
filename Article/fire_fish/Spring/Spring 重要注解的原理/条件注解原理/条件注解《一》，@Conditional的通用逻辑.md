
条件注解用于控制Bean是否注册到容器中。

本文介绍了条件注解起作用的入口位置和其他所有条件注解依赖的@Conditional它的一个通用逻辑

### Conditional条件注解判断位置有几处
在ConfigurationClassParser解析配置类和ConfigurationClassPostProcessor处理Bean注册的过程中，
会存在多处位置判断是否跳过Bean的注册，如跳过则不会解析，否则继续解析。

这些位置有如下几个地方（应该就只要这2个地方）

1. 注册Bean方法时候
```java
class ConfigurationClassBeanDefinitionReader {
	// 代码有删减
	private void loadBeanDefinitionsForBeanMethod(BeanMethod beanMethod) {
		// 判断是否把 beanMethod 注册还是跳过
		if (this.conditionEvaluator.shouldSkip(beanMethod.getMetadata(), ConfigurationPhase.REGISTER_BEAN)) {
			return;
		}
	}
}
```
2. 解析配置类的时候
```java
class ConfigurationClassParser {
	// 代码有删减
	protected void processConfigurationClass(ConfigurationClass configClass) throws IOException {
		// 判断是否把 beanMethod 注册还是跳过
		if (this.conditionEvaluator.shouldSkip(configClass.getMetadata(), ConfigurationPhase.PARSE_CONFIGURATION)) {
			return;
		}
	}
}
```

### 各种Condition*注解通用的逻辑部分（暂不涉及具体条件注解）
如下代码：
```java
class ConditionEvaluator {
	public boolean shouldSkip(@Nullable AnnotatedTypeMetadata metadata, @Nullable ConfigurationPhase phase) {
		// 1. 如果注解元数据没有@Conditional条件注解，那当然可以注册，直接返回false
		if (metadata == null || !metadata.isAnnotated(Conditional.class.getName())) {
			return false;
		}

		// 如果存在phase，则要递归一下（为什么有phase呢）
		if (phase == null) {
			if (metadata instanceof AnnotationMetadata &&
					ConfigurationClassUtils.isConfigurationCandidate((AnnotationMetadata) metadata)) {
				return shouldSkip(metadata, ConfigurationPhase.PARSE_CONFIGURATION);
			}
			return shouldSkip(metadata, ConfigurationPhase.REGISTER_BEAN);
		}

		// 2. 获取条件注解@Conditional的属性配置的值（也就是具体的执行类，如：OnClassCondition、OnSystemPropertyCondition等）
		// 2. 也就是具体执行类
        List<Condition> conditions = new ArrayList<>();
		for (String[] conditionClasses : getConditionClasses(metadata)) {
			for (String conditionClass : conditionClasses) {
				Condition condition = getCondition(conditionClass, this.context.getClassLoader());
				conditions.add(condition);
			}
		}

		AnnotationAwareOrderComparator.sort(conditions);

		// 3. 执行matches匹配方法
		for (Condition condition : conditions) {
			ConfigurationPhase requiredPhase = null;
			if (condition instanceof ConfigurationCondition) {
				requiredPhase = ((ConfigurationCondition) condition).getConfigurationPhase();
			}
			if ((requiredPhase == null || requiredPhase == phase) && !condition.matches(this.context, metadata)) {
				return true;
			}
		}

		return false;
	}
}
```
继续看matches方法
```java
public abstract class SpringBootCondition implements Condition {
	public final boolean matches(ConditionContext context,
	                             AnnotatedTypeMetadata metadata) {
		String classOrMethodName = getClassOrMethodName(metadata);
		 
			ConditionOutcome outcome = getMatchOutcome(context, metadata);
			logOutcome(classOrMethodName, outcome);
			recordEvaluation(context, classOrMethodName, outcome);
			return outcome.isMatch();

	}

	public abstract ConditionOutcome getMatchOutcome(ConditionContext context,
	                                                 AnnotatedTypeMetadata metadata);
}
```
matches方法是父类的一个通用方法，且从代码可以看出outcome已经表示了匹配的结果，所以我们需要重点看getMatchOutcome方法

`getMatchOutcome`方法是子类实现的，各个子类不同，如果读者需要看各种条件注解的原理，重点查看这个方法。