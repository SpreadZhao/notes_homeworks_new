
ConfigurationClassPostProcessor 的功能是完成配置类的注册


### ConfigurationClassPostProcessor类说明
先看定义
```java
public class ConfigurationClassPostProcessor implements BeanDefinitionRegistryPostProcessor,
		PriorityOrdered, ResourceLoaderAware, BeanClassLoaderAware, EnvironmentAware {

}
```

实现了BeanDefinitionRegistryPostProcessor、PriorityOrdered特殊接口。Spring会在启动过程中的refresh方法中的invokeBeanFactoryPostProcessor方法中，
执行BeanDefinitionRegistryPostProcessor接口，从而执行到ConfigurationClassPostProcessor的processConfigBeanDefinitions方法

下面对Spring如何处理ConfigBeanDefinition的步骤简单说明：
步骤如下：
1. 收集容器中的所有bean定义（刚开始几乎没有几个Bean，还是从主配置类开始）
2. 检查配置类候选情况（主要是设置配置类的full类型或lite类型）
3. 只解析不处理注册【重点：只完成收集不完成具体注册】
4. 取出所有解析好的结果，来执行Bean的注册【重点方法：完成具体注册】
```java
public class ConfigurationClassPostProcessor implements BeanDefinitionRegistryPostProcessor,
		PriorityOrdered, ResourceLoaderAware, BeanClassLoaderAware, EnvironmentAware {

	/**
     * 功能：递归扫描所有的配置类，把Bean定义暂存，最后一起注册到容器中（如下代码有删减）
	 * @param registry
	 */
	public void processConfigBeanDefinitions(BeanDefinitionRegistry registry) {
		List<BeanDefinitionHolder> configCandidates = new ArrayList<>();
		// 1. 收集容器中的所有bean定义（刚开始几乎没有几个Bean，还是从主配置类开始）
		String[] candidateNames = registry.getBeanDefinitionNames();

		for (String beanName : candidateNames) {
			BeanDefinition beanDef = registry.getBeanDefinition(beanName);
			if (ConfigurationClassUtils.isFullConfigurationClass(beanDef) ||
					ConfigurationClassUtils.isLiteConfigurationClass(beanDef)) {
				if (logger.isDebugEnabled()) {
					logger.debug("Bean definition has already been processed as a configuration class: " + beanDef);
				}
				// 2. 检查配置类候选情况（主要是设置配置类的full类型或lite类型）
			} else if (ConfigurationClassUtils.checkConfigurationClassCandidate(beanDef, this.metadataReaderFactory)) {
				configCandidates.add(new BeanDefinitionHolder(beanDef, beanName));
			}
		}

		Set<BeanDefinitionHolder> candidates = new LinkedHashSet<>(configCandidates);
		Set<ConfigurationClass> alreadyParsed = new HashSet<>(configCandidates.size());
		do {
			// 3. 只解析不处理注册【重点：只完成收集不完成具体注册】
			parser.parse(candidates);
			parser.validate();
			
			Set<ConfigurationClass> configClasses = new LinkedHashSet<>(parser.getConfigurationClasses());
			configClasses.removeAll(alreadyParsed);

			// 4. 取出所有解析好的结果，来执行Bean的注册【重点方法：完成具体注册】
			this.reader.loadBeanDefinitions(configClasses);
			alreadyParsed.addAll(configClasses);
		}
		while (!candidates.isEmpty());
	}
}
```

### 配置类解析方法parser

对配置类的解析存在多种途径的递归，但最后都会递归到parse方法。下面看下parse方法的大致步骤

1. 处理配置类的内部类（**递归**，最后还是会递归到本方法）
2. 处理 @PropertySource 注解（因为该注解直接定义的属性源，跟环境变量相关，直接被处理到环境变量中了）
3. 处理 @ComponentScan 注解（**递归**，最后还是会递归到本方法）
4. 处理 @Import 注解（**存在递归**，但是有递归的出口
   * <mark>出口1：把相关信息添加到ConfigurationClass配置类importBeanDefinitionRegistrars属性中，只是添加，后面才会处理</mark>
   * <mark>出口2：把相关信息添加到ConfigurationClassParser类的deferredImportSelectors属性中，只是添加，后面才会处理</mark>
5. 处理 @ImportResource 注解（<mark>把相关信息添加到onfigurationClass配置类的importedResources属性中）</mark>
6. 处理配置类中的 @Bean 注解方法（<mark>把相关信息添加到onfigurationClass配置类的beanMethods属性中）</mark>
7. 处理 父类（**递归**，最后还是会递归到本方法）


```java
class ConfigurationClassParser {

	/**
     * 处理配置类的总体逻辑就是一个递归的过程，各种各样的递归都会回归到这个方法
	 * @param configClass
	 * @param sourceClass
	 * @return
	 */
	protected final SourceClass doProcessConfigurationClass(ConfigurationClass configClass, SourceClass sourceClass) throws IOException {
		// recursively process any member (nested) classes first
		processMemberClasses(configClass, sourceClass);

		// process any @PropertySource annotations
		for (AnnotationAttributes propertySource : AnnotationConfigUtils.attributesForRepeatable(
				sourceClass.getMetadata(), PropertySources.class, org.springframework.context.annotation.PropertySource.class)) {
			processPropertySource(propertySource);
		}

		// process any @ComponentScan annotations
		AnnotationAttributes componentScan = AnnotationConfigUtils.attributesFor(sourceClass.getMetadata(), ComponentScan.class);
		if (componentScan != null) {
			// the config class is annotated with @ComponentScan -> perform the scan immediately
			if (!this.conditionEvaluator.shouldSkip(sourceClass.getMetadata(), ConfigurationPhase.REGISTER_BEAN)) {
				Set<BeanDefinitionHolder> scannedBeanDefinitions =
						this.componentScanParser.parse(componentScan, sourceClass.getMetadata().getClassName());

				// check the set of scanned definitions for any further config classes and parse recursively if necessary
				for (BeanDefinitionHolder holder : scannedBeanDefinitions) {
					if (ConfigurationClassUtils.checkConfigurationClassCandidate(holder.getBeanDefinition(), this.metadataReaderFactory)) {
						parse(holder.getBeanDefinition().getBeanClassName(), holder.getBeanName());
					}
				}
			}
		}

		// process any @Import annotations
		processImports(configClass, sourceClass, getImports(sourceClass), true);

		// process any @ImportResource annotations
		if (sourceClass.getMetadata().isAnnotated(ImportResource.class.getName())) {
			AnnotationAttributes importResource = AnnotationConfigUtils.attributesFor(sourceClass.getMetadata(), ImportResource.class);
			String[] resources = importResource.getStringArray("value");
			Class<? extends BeanDefinitionReader> readerClass = importResource.getClass("reader");
			for (String resource : resources) {
				String resolvedResource = this.environment.resolveRequiredPlaceholders(resource);
				configClass.addImportedResource(resolvedResource, readerClass);
			}
		}

		// process individual @Bean methods
		Set<MethodMetadata> beanMethods = sourceClass.getMetadata().getAnnotatedMethods(Bean.class.getName());
		for (MethodMetadata methodMetadata : beanMethods) {
			configClass.addBeanMethod(new BeanMethod(methodMetadata, configClass));
		}

		// process superclass, if any
		if (sourceClass.getMetadata().hasSuperClass()) {
			String superclass = sourceClass.getMetadata().getSuperClassName();
			if (!this.knownSuperclasses.containsKey(superclass)) {
				this.knownSuperclasses.put(superclass, configClass);
				// superclass found, return its annotation metadata and recurse
				try {
					return sourceClass.getSuperClass();
				} catch (ClassNotFoundException ex) {
					throw new IllegalStateException(ex);
				}
			}
		}

		// no superclass, processing is complete
		return null;
	}
}
```

### 处理前面解析出来的结果
无论前面是如何递归递归递归解析，最后会把解析结果封装为ConfigurationClass对象，对该对象的处理就是对解析结果的处理，
处理过程也就是把解析结果注册到容器中，该对象的结构如下：
```java
final class ConfigurationClass {

	private final AnnotationMetadata metadata;

	private final Resource resource;

	@Nullable
	private String beanName;

	private final Set<ConfigurationClass> importedBy = new LinkedHashSet<>(1);
	
	// 该属性存储@Bean注解的解析结果
	private final Set<BeanMethod> beanMethods = new LinkedHashSet<>();

	// 该属性存储@ImportResource注解的解析结果
	private final Map<String, Class<? extends BeanDefinitionReader>> importedResources =
			new LinkedHashMap<>();

	// 该属性存储 ImportBeanDefinitionRegistrar 接口的解析结果
	private final Map<ImportBeanDefinitionRegistrar, AnnotationMetadata> importBeanDefinitionRegistrars =
			new LinkedHashMap<>();

	// 该属性存储 应该被跳过的配置类
	final Set<String> skippedBeanMethods = new HashSet<>();
}
```

处理过程的方法，步骤如下：
1. 把Import进来的类也注册为一个Bean
2. 处理@Bean注解的方法注册为Bean
3. 处理@ImportResource导入的内容，把内容注册为Bean（走Spring 的xml解析）
4. 处理ImportBeanDefinitionRegistrar接口，把内容注册为Bean

```java
class ConfigurationClassBeanDefinitionReader {
	private void loadBeanDefinitionsForConfigurationClass(
			ConfigurationClass configClass, TrackedConditionEvaluator trackedConditionEvaluator) {

		if (trackedConditionEvaluator.shouldSkip(configClass)) {
			String beanName = configClass.getBeanName();
			if (StringUtils.hasLength(beanName) && this.registry.containsBeanDefinition(beanName)) {
				this.registry.removeBeanDefinition(beanName);
			}
			this.importRegistry.removeImportingClass(configClass.getMetadata().getClassName());
			return;
		}

		// 配置类是不是import进来的，开始注册
		if (configClass.isImported()) {
			registerBeanDefinitionForImportedConfigurationClass(configClass);
		}
		
		// 注册Bean方法【@Bean注解】
		for (BeanMethod beanMethod : configClass.getBeanMethods()) {
			loadBeanDefinitionsForBeanMethod(beanMethod);
		}

		// 注册 ImportedResources【@ImportResource注解】
		loadBeanDefinitionsFromImportedResources(configClass.getImportedResources());
		
		// 注册Registrars。【ImportBeanDefinitionRegistrar接口】
		loadBeanDefinitionsFromRegistrars(configClass.getImportBeanDefinitionRegistrars());
	}
}
```