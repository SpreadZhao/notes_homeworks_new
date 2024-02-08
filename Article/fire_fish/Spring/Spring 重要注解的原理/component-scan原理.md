

介绍：
component-scan的职责是扫描特定包下的类，把满足条件的组件注册为Spring Bean。

前提：
了解Spring 的可拓展的Xml机制

核心类：
ComponentScanBeanDefinitionParser

结论：
1、默认情况下，includeFilters仅包括Component注解；excludeFilters为空
2、是否是候选组件由：includeFilters、excludeFilters、MetadataReader共同决定

### spring 可拓展的xml机制

根据xml可拓展的xml机制，在xml文件中配置的component-scan会调用到ComponentScanBeanDefinitionParser类的parse方法；
因为BeanDefinitionHolder类代表了Spring Bean，所以scanner.doScan是重点方法。

```java
public class ComponentScanBeanDefinitionParser implements BeanDefinitionParser {
	public BeanDefinition parse(Element element, ParserContext parserContext) {
		// 1、查找xx属性
		String[] basePackages =
				StringUtils.commaDelimitedListToStringArray(element.getAttribute(BASE_PACKAGE_ATTRIBUTE));

		// Actually scan for bean definitions and register them.
		ClassPathBeanDefinitionScanner scanner = configureScanner(parserContext, element);
		
		// 3、扫描获取到所有的Spring Bean定义的BeanDefinition【重点】
		Set<BeanDefinitionHolder> beanDefinitions = scanner.doScan(basePackages);
		
		// 4、注册
		registerComponents(parserContext.getReaderContext(), beanDefinitions, element);

		return null;
	}
}
```


### 查找候选组件

```java
public class ClassPathBeanDefinitionScanner extends ClassPathScanningCandidateComponentProvider {
	protected Set<BeanDefinitionHolder> doScan(String... basePackages) {
		Set<BeanDefinitionHolder> beanDefinitions = new LinkedHashSet<BeanDefinitionHolder>();
		for (int i = 0; i < basePackages.length; i++) {
			// 查找候选组件
			Set<BeanDefinition> candidates = findCandidateComponents(basePackages[i]);
			for (BeanDefinition candidate : candidates) {
				String beanName = this.beanNameGenerator.generateBeanName(candidate, this.registry);
				if (candidate instanceof AbstractBeanDefinition) {
					postProcessBeanDefinition((AbstractBeanDefinition) candidate, beanName);
				}
				ScopeMetadata scopeMetadata = this.scopeMetadataResolver.resolveScopeMetadata(candidate);
				if (checkCandidate(beanName, candidate)) {
					BeanDefinitionHolder definitionHolder = new BeanDefinitionHolder(candidate, beanName);
					definitionHolder = applyScope(definitionHolder, scopeMetadata);
					beanDefinitions.add(definitionHolder);
					registerBeanDefinition(definitionHolder, this.registry);
				}
			}
		}
		return beanDefinitions;
	}
}
```

### 查找候选组件，，并根据查找结果进行一些过滤判断，最后形成了Spring Bean集合。

候选组件的资源地址如何决定的：比如包名是com.firefish，则查找的资源地址是[classpath*:com/firefish/**/.class]。

查找组件的代码如下：
```java
public class ClassPathScanningCandidateComponentProvider implements ResourceLoaderAware {
	public Set<BeanDefinition> findCandidateComponents(String basePackage) {
		Set<BeanDefinition> candidates = new LinkedHashSet<BeanDefinition>();
        String packageSearchPath = ResourcePatternResolver.CLASSPATH_ALL_URL_PREFIX +
                resolveBasePackage(basePackage) + "/" + this.resourcePattern;
        Resource[] resources = this.resourcePatternResolver.getResources(packageSearchPath);
        for (int i = 0; i < resources.length; i++) {
            Resource resource = resources[i];
            if (resource.isReadable()) {
				// 重点
                MetadataReader metadataReader = this.metadataReaderFactory.getMetadataReader(resource);
                if (isCandidateComponent(metadataReader)) {
                    ScannedGenericBeanDefinition sbd = new ScannedGenericBeanDefinition(metadataReader);
                    sbd.setResource(resource);
                    sbd.setSource(resource);
                    if (isCandidateComponent(sbd)) {
                        candidates.add(sbd);
                    }
                }
            }
        }
		return candidates;
	}
}
```
是否是组件的判断代码如下：
```java
public class ClassPathScanningCandidateComponentProvider implements ResourceLoaderAware {
	protected boolean isCandidateComponent(MetadataReader metadataReader) throws IOException {
		for (TypeFilter tf : this.excludeFilters) {
			if (tf.match(metadataReader, this.metadataReaderFactory)) {
				return false;
			}
		}
		for (TypeFilter tf : this.includeFilters) {
			if (tf.match(metadataReader, this.metadataReaderFactory)) {
				return true;
			}
		}
		return false;
	}
}
```
所有关键看ClassPathScanningCandidateComponentProvider的includeFilters和excludeFilters的值来决定是否是候选组件。
继续看代码：
```java
public class ClassPathScanningCandidateComponentProvider implements ResourceLoaderAware {

	// 因为默认useDefaultFilters参数是true，所以最后includeFilters仅包括Component注解；excludeFilters为空
    // 也就是说默认情况下只有@Component注解才是候选组件
	public ClassPathScanningCandidateComponentProvider(boolean useDefaultFilters) {
		if (useDefaultFilters) {
			registerDefaultFilters();
		}
	}
	
	protected void registerDefaultFilters() {
		this.includeFilters.add(new AnnotationTypeFilter(Component.class));
	}
}
```

```java
public class CachingMetadataReaderFactory extends SimpleMetadataReaderFactory {
	public MetadataReader getMetadataReader(Resource resource) throws IOException {
		synchronized (this.classReaderCache) {
			MetadataReader metadataReader = this.classReaderCache.get(resource);
			if (metadataReader == null) {
				// 重点是获取 metadataReader 对象
				metadataReader = super.getMetadataReader(resource);
				this.classReaderCache.put(resource, metadataReader);
			}
			return metadataReader;
		}
	}
}
```

```java
public class SimpleMetadataReaderFactory implements MetadataReaderFactory {
	public MetadataReader getMetadataReader(Resource resource) throws IOException {
		InputStream is = resource.getInputStream();
		try {
            // 读取字节码文件，创建了 SimpleMetadataReader 对象 
			return new SimpleMetadataReader(new ClassReader(is), this.resourceLoader.getClassLoader());
		} finally {
			is.close();
		}
	}
}	
```

### 其他问题
1、component-scan扫描到的类是如何决定bean的名称的
```java
public class AnnotationBeanNameGenerator implements BeanNameGenerator {
	public String generateBeanName(BeanDefinition definition, BeanDefinitionRegistry registry) {
		// 1、如果有注解执行名称，则用该名称
		if (definition instanceof AnnotatedBeanDefinition) {
			String beanName = determineBeanNameFromAnnotation((AnnotatedBeanDefinition) definition);
			if (StringUtils.hasText(beanName)) {
				// Explicit bean name found.
				return beanName;
			}
		}
		// 2、如果没有，就用类名简写
		return buildDefaultBeanName(definition, registry);
	}
}
```