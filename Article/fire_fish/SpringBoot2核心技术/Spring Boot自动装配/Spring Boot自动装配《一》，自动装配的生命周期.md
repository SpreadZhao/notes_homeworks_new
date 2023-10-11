
本文是继自动装配核心原理后的一篇文章，本文将详细讨论为什么会执行到自动装配的代码，以及一些核心接口的说明。

核心类：
* ConfigurationClassPostProcessor（配置类后置处理器. 作用:负责配置类的处理）
* AutoConfigurationImportSelector（自动配置类导入器. 作用:Spring Boot自动装配的导入器）
* DeferredImportSelector（延迟导入器. 作用:延迟的导入器，可能跟配置类的优先级有关，要不然为什么要延迟）
* annotationMetadata（注解元数据. 作用:含有所有的注解信息）




### @EnableAutoConfiguration 的生命周期

在前面的讨论中有选择性的忽略了AutoConfigurationImportSelector的接口层次性，而是直奔@EnableAutoConfiguration自动装配的实现逻辑。
下面把之前的内容补充完善一下。

#### 先看接口的定义
先看下AutoConfigurationImportSelector的定义
```java
public class AutoConfigurationImportSelector
		implements DeferredImportSelector, BeanClassLoaderAware, ResourceLoaderAware,
		BeanFactoryAware, EnvironmentAware, Ordered {

}
```
实现了DeferredImportSelector接口，该接口是ImportSelector的一个变种，从字面意义上分析，DeferredImportSelector可理解为Deferred（延时的）ImportSelector。

该接口DeferredImportSelector不同于ImportSelector，它不会立刻被处理，而是暂时保存起来延后处理。


#### 生命周期的入口位置
了解了AutoConfigurationImportSelector的定义在看下自动装配的入口位置，入口位置是`ConfigurationClassPostProcessor`后置处理器器的执行。
执行过程中一般会从一个主配置类primarySources出发，**递归**解析所有的配置类。

通过几个重载的parse方法递归地完成所有配置类的解析工作，接着处理延迟的Import，即处理DeferredImportSelectors特殊接口

如下是解析的方法(相关说明已经写在了代码的备注中)：
```java
class ConfigurationClassParser {
	public void parse(Set<BeanDefinitionHolder> configCandidates) {
		this.deferredImportSelectors = new LinkedList<>();

		// 1、递归解析所有的配置类：DeferredImportSelectors
		for (BeanDefinitionHolder holder : configCandidates) {
			BeanDefinition bd = holder.getBeanDefinition();
			
				if (bd instanceof AnnotatedBeanDefinition) {
					parse(((AnnotatedBeanDefinition) bd).getMetadata(), holder.getBeanName());
				} else if (bd instanceof AbstractBeanDefinition && ((AbstractBeanDefinition) bd).hasBeanClass()) {
					parse(((AbstractBeanDefinition) bd).getBeanClass(), holder.getBeanName());
				} else {
					parse(bd.getBeanClassName(), holder.getBeanName());
				}
		}
		
		// 2、处理特殊接口DeferredImportSelectors
		processDeferredImportSelectors();
	}

	// @Import 导入类的原理
	private void processImports(ConfigurationClass configClass, SourceClass currentSourceClass,
	                            Collection<SourceClass> importCandidates, boolean checkForCircularImports) {

		this.importStack.push(configClass);
		try {
			for (SourceClass candidate : importCandidates) {
				// 1、如果是 ImportSelector 接口，则这样处理
				if (candidate.isAssignable(ImportSelector.class)) {
					Class<?> candidateClass = candidate.loadClass();
					ImportSelector selector = BeanUtils.instantiateClass(candidateClass, ImportSelector.class);
					ParserStrategyUtils.invokeAwareMethods(
							selector, this.environment, this.resourceLoader, this.registry);
					// selector 是延迟的ImportSelector接口，即DeferredImportSelector，则暂时保存起来后续处理
					if (this.deferredImportSelectors != null && selector instanceof DeferredImportSelector) {
						this.deferredImportSelectors.add(
								new DeferredImportSelectorHolder(configClass, (DeferredImportSelector) selector));
					}
					else {
						String[] importClassNames = selector.selectImports(currentSourceClass.getMetadata());
						Collection<SourceClass> importSourceClasses = asSourceClasses(importClassNames);
						processImports(configClass, currentSourceClass, importSourceClasses, false);
					}
				}
				// 2、如果是 ImportBeanDefinitionRegistrar 接口，则这样处理
				else if (candidate.isAssignable(ImportBeanDefinitionRegistrar.class)) {
					Class<?> candidateClass = candidate.loadClass();
					ImportBeanDefinitionRegistrar registrar =
							BeanUtils.instantiateClass(candidateClass, ImportBeanDefinitionRegistrar.class);
					ParserStrategyUtils.invokeAwareMethods(
							registrar, this.environment, this.resourceLoader, this.registry);
					configClass.addImportBeanDefinitionRegistrar(registrar, currentSourceClass.getMetadata());
				}
				// 3、如果是一般配置类，则这样处理
				else {
					this.importStack.registerImport(
							currentSourceClass.getMetadata(), candidate.getMetadata().getClassName());
					processConfigurationClass(candidate.asConfigClass(configClass));
				}
			}
		}
		finally {
			this.importStack.pop();
		}
	}
}
```

#### 处理延迟的DeferredImportSelector类
Spring Boot自动装配注解@EnableAutoConfiguration通过@Import方式导入了AutoConfigurationImportSelector，而它又实现了DeferredImportSelector特殊接口。

特殊接口的在处理完所有的配置类后才处理的，处理逻辑在processDeferredImportSelectors方法中。

在该方法的处理步骤如下：
分组处理 ---> 取出grouping中的所有配置类 ---> 迭代处理每个配置类 ---> 再次回到processImports方法递归处理配置类
```java
class ConfigurationClassParser {
	private void processDeferredImportSelectors() {
		List<DeferredImportSelectorHolder> deferredImports = this.deferredImportSelectors;
		this.deferredImportSelectors = null;
		if (deferredImports == null) {
			return;
		}

		deferredImports.sort(DEFERRED_IMPORT_COMPARATOR);
		Map<Object, DeferredImportSelectorGrouping> groupings = new LinkedHashMap<>();
		Map<AnnotationMetadata, ConfigurationClass> configurationClasses = new HashMap<>();
		for (DeferredImportSelectorHolder deferredImport : deferredImports) {
			Class<? extends Group> group = deferredImport.getImportSelector().getImportGroup();
			// computeIfAbsent 跟 putIfAbsent 不同！！！
			DeferredImportSelectorGrouping grouping = groupings.computeIfAbsent(
					(group == null ? deferredImport : group),
					(key) -> new DeferredImportSelectorGrouping(createGroup(group)));
			grouping.add(deferredImport);
			configurationClasses.put(deferredImport.getConfigurationClass().getMetadata(),
					deferredImport.getConfigurationClass());
		}
		for (DeferredImportSelectorGrouping grouping : groupings.values()) {
			// 重点重点
			grouping.getImports()   // 取出grouping中的所有配置类
                    .forEach((entry) -> {       // 迭代处理每个配置类
				ConfigurationClass configurationClass = configurationClasses.get(
						entry.getMetadata());
				try {
					// 递归处理每个配置类
					processImports(configurationClass, asSourceClass(configurationClass),
							asSourceClasses(entry.getImportClassName()), false);
				} catch (BeanDefinitionStoreException ex) {
					throw ex;
				} catch (Throwable ex) {
					throw new BeanDefinitionStoreException(
							"Failed to process import candidates for configuration class [" +
									configurationClass.getMetadata().getClassName() + "]", ex);
				}
			});
		}
	}
}
```
下面挑选上面代码的重点方法单独叙述
* grouping.getImports()方法
```java
class ConfigurationClassParser {
	/**
	 * 功能：执行grouping的getImports方法
	 * @return
	 */
	public Iterable<Group.Entry> getImports() {
		for (DeferredImportSelectorHolder deferredImport : this.deferredImports) {
			this.group.process(deferredImport.getConfigurationClass().getMetadata(),
					deferredImport.getImportSelector());
		}
		return this.group.selectImports();
	}
}
```
* this.group.process方法
  继续看上面的this.group.process方法
```java
public class AutoConfigurationImportSelector
		implements DeferredImportSelector, BeanClassLoaderAware, ResourceLoaderAware,
		BeanFactoryAware, EnvironmentAware, Ordered {
	
	@Override
	public void process(AnnotationMetadata annotationMetadata,
	                    DeferredImportSelector deferredImportSelector) {
		// 自动装配配置文件中的所以配置类
		String[] imports = deferredImportSelector.selectImports(annotationMetadata);
		for (String importClassName : imports) {
			// 把配置类保存在entries中
			this.entries.put(importClassName, annotationMetadata);
		}
	}
}
```
* this.group.selectImports();方法
  该方法把配置类封装为Entry对象，entry对象中还携带了@EnableAutoConfiguration注解元数据，并返回配置类的迭代器
```java
public class AutoConfigurationImportSelector
		implements DeferredImportSelector, BeanClassLoaderAware, ResourceLoaderAware,
		BeanFactoryAware, EnvironmentAware, Ordered {
	@Override
	public Iterable<Entry> selectImports() {
		return sortAutoConfigurations().stream()
				.map((importClassName) -> new Entry(this.entries.get(importClassName),
						importClassName))
				.collect(Collectors.toList());
	}
}
```
* processImports方法
  又返回了之前的代码中，递归的处理每一个配置类

至此，关于@EnableAutoConfiguration 生命周期的谈论接近尾声，然而在AutoConfigurationGroup.selectImports()方法返回值是**排序**后的结果，排序在Spring Boot中
是如何管理的呢。