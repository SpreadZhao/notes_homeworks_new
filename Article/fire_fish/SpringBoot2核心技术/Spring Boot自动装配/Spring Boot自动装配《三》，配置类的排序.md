
排序核心类：AutoConfigurationSorter

自动配置类的排序思想是：
1. 局部排序即可不需要整体排序
2. 先按字母大小排序、再按order数值进行绝对排序、再按依赖相对排序
3. 依赖必须排好序。 思想是：找出某个配置类所有依赖的配置类列表，并对配置依赖排序
4. 当每一个配置类的依赖都排好序后其实整体的配置类就已经排好序了


### 排序的入口位置
在返回配置类的迭代器时，会对配置列排序
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


### 名词解释

* AutoConfigureOrder（绝对自动装配顺序：直接指定大小）
* AutoConfigureAfter（相对自动装配顺序：该配置要在其他配置文件之后）
* AutoConfigureBefore（相对自动装配顺序：该配置要在其他文件之前）

```properties
org.springframework.boot.autoconfigure.web.reactive.WebFluxAutoConfiguration.AutoConfigureAfter=\
   org.springframework.boot.autoconfigure.web.reactive.ReactiveWebServerFactoryAutoConfiguration,\
  org.springframework.boot.autoconfigure.http.codec.CodecsAutoConfiguration,\
  org.springframework.boot.autoconfigure.validation.ValidationAutoConfiguration

org.springframework.boot.autoconfigure.web.reactive.error.ErrorWebFluxAutoConfiguration.AutoConfigureBefore=\
  org.springframework.boot.autoconfigure.web.reactive.WebFluxAutoConfiguration

org.springframework.boot.autoconfigure.web.servlet.DispatcherServletAutoConfiguration.AutoConfigureOrder=-2147483648
```
以上面的配置为例。
org.springframework.boot.autoconfigure.web.reactive.WebFluxAutoConfiguration配置类必须在org.springframework.boot.autoconfigure.web.reactive.ReactiveWebServerFactoryAutoConfiguration等
3个配置之后才能配置。即A.AutoConfigureAfter=B，即A依赖B

org.springframework.boot.autoconfigure.web.reactive.error.ErrorWebFluxAutoConfiguration需要在org.springframework.boot.autoconfigure.web.reactive.WebFluxAutoConfiguration
配置之前才能配置。即A.AutoConfigureBefore=B，即B依赖A

但是对WebFluxAutoConfiguration而言，结合before和after的含义，实际上它依赖上面3个配置类！！哈哈

排序时只要找到A依赖那些配置类和那些配置类依赖A即可。
A依赖的配置类：A.AutoConfigureAfter=xxx 和 xxx.AutoConfigureBefore=A


### 自动配置类排序的定义
看核心类AutoConfigurationSorter的定义：
```java
class AutoConfigurationSorter {
	private final MetadataReaderFactory metadataReaderFactory;

	// 自动配置类的元数据，该配置来自预定义好的META-INF/spring-autoconfigure-metadata.properties文件，
    // 也就是会参考该文件的内容
	private final AutoConfigurationMetadata autoConfigurationMetadata;

	/**
     * 功能：根据预定义的元数据来排序
	 * @param classNames    需要排序的配置类
	 * @return
	 */
	public List<String> getInPriorityOrder(Collection<String> classNames) {
		// 1、根据预定义的配置数据解析为classes变量，把AutoConfigureAfter和AutoConfigureBefore都解析好了
		AutoConfigurationClasses classes = new AutoConfigurationClasses(
				this.metadataReaderFactory, this.autoConfigurationMetadata, classNames);
		List<String> orderedClassNames = new ArrayList<>(classNames);
		// ---------------2、排序-----------------
		// Initially sort alphabetically【1、先按字母排序】
		Collections.sort(orderedClassNames);
		// Then sort by order【2、根据order排序。 o1表示后面元素o2表示前面元素，所以是根据order升序排序】
		orderedClassNames.sort((o1, o2) -> {
			int i1 = classes.get(o1).getOrder();
			int i2 = classes.get(o2).getOrder();
			return Integer.compare(i1, i2);
		});
		// Then respect @AutoConfigureBefore @AutoConfigureAfter【3、对@AutoConfigureBefore @AutoConfigureAfter处理】
		orderedClassNames = sortByAnnotation(classes, orderedClassNames);
		return orderedClassNames;
	}

	private List<String> sortByAnnotation(AutoConfigurationClasses classes,
	                                      List<String> classNames) {
		// 需要排序的
		List<String> toSort = new ArrayList<>(classNames);
		toSort.addAll(classes.getAllNames());
		// 排序好的数组
		Set<String> sorted = new LinkedHashSet<>();
		// 正在处理的
		Set<String> processing = new LinkedHashSet<>();
		while (!toSort.isEmpty()) {
			doSortByAfterAnnotation(classes, toSort, sorted, processing, null);
		}
		sorted.retainAll(classNames);
		return new ArrayList<>(sorted);
	}
}
```

### 解析配置资源为AutoConfigurationClasses类

```java
class AutoConfigurationSorter {
	// 构造器
	AutoConfigurationClasses(MetadataReaderFactory metadataReaderFactory,
	                         AutoConfigurationMetadata autoConfigurationMetadata,
	                         Collection<String> classNames) {
		addToClasses(metadataReaderFactory, autoConfigurationMetadata, classNames,
				true);
	}

	// 递归解析资源 或 解析
	private void addToClasses(MetadataReaderFactory metadataReaderFactory,
	                          AutoConfigurationMetadata autoConfigurationMetadata,
	                          Collection<String> classNames, boolean required) {
		for (String className : classNames) {
			if (!this.classes.containsKey(className)) {
				AutoConfigurationClass autoConfigurationClass = new AutoConfigurationClass(
						className, metadataReaderFactory, autoConfigurationMetadata);
				boolean available = autoConfigurationClass.isAvailable();
				if (required || available) {
					this.classes.put(className, autoConfigurationClass);
				}
				if (available) {
					addToClasses(metadataReaderFactory, autoConfigurationMetadata,
							autoConfigurationClass.getBefore(), false);
					addToClasses(metadataReaderFactory, autoConfigurationMetadata,
							autoConfigurationClass.getAfter(), false);
				}
			}
		}
	}
	
	// 如果配置文件资源中有，就用配置文件的，否则用@AutoConfigureBefore注解
	public Set<String> getBefore() {
		if (this.before == null) {
			this.before = (wasProcessed()
					? this.autoConfigurationMetadata.getSet(this.className,
					"AutoConfigureBefore", Collections.emptySet())
					: getAnnotationValue(AutoConfigureBefore.class));
		}
		return this.before;
	}
	// 如果配置文件资源中有，就用配置文件的，否则用 @AutoConfigureAfter 注解
	public Set<String> getAfter() {
		if (this.after == null) {
			this.after = (wasProcessed()
					? this.autoConfigurationMetadata.getSet(this.className,
					"AutoConfigureAfter", Collections.emptySet())
					: getAnnotationValue(AutoConfigureAfter.class));
		}
		return this.after;
	}
	// 如果配置文件资源中有，就用配置文件的，否则用 @AutoConfigureOrder 注解，默认值是0
	private int getOrder() {
		if (wasProcessed()) {
			return this.autoConfigurationMetadata.getInteger(this.className,
					"AutoConfigureOrder", AutoConfigureOrder.DEFAULT_ORDER);
		}
		Map<String, Object> attributes = getAnnotationMetadata()
				.getAnnotationAttributes(AutoConfigureOrder.class.getName());
		return (attributes != null ? (Integer) attributes.get("value")
				: AutoConfigureOrder.DEFAULT_ORDER);
	}
}
```

### 对某配置类递归处理分析

<mark>排序的思想是：遍历所有配置列，**把每一个配置类所依赖的配置类列表都安排好**(存在传递就递归)，那么最后总体上也就是排序好的</mark>
方法：
* classes.getClassesRequestedAfter(current) 负责取出current所有的依赖配置类列表
* doSortByAfterAnnotation 方法负责每次排序一个配置类和它的依赖

```java
class AutoConfigurationSorter {
	private final MetadataReaderFactory metadataReaderFactory;

	/**
     * 
	 * @param classes           所有的配置类的封装  
	 * @param toSort            需要排序的列表
	 * @param sorted            排序好的集合
	 * @param processing        正在处理的集合
	 * @param current           初始值是null
	 */
	private void doSortByAfterAnnotation(AutoConfigurationClasses classes,
	                                     List<String> toSort, Set<String> sorted, Set<String> processing,
	                                     String current) {
		if (current == null) {
			// 每次排序时从需要排序的列表中移除一个出来
			current = toSort.remove(0);
		}
		processing.add(current);
		for (String after : classes.getClassesRequestedAfter(current)) {
			Assert.state(!processing.contains(after),
					"AutoConfigure cycle detected between " + current + " and " + after);
			// 排序好的中没有，但是需要排序列表有，然后递归
			if (!sorted.contains(after) && toSort.contains(after)) {
				doSortByAfterAnnotation(classes, toSort, sorted, processing, after);
			}
		}
		processing.remove(current);
		sorted.add(current);
	}

	/**
     * 功能：获取配置className它所依赖的配置列表（有2个来源）
	 * @param className     
	 * @return
	 */
	public Set<String> getClassesRequestedAfter(String className) {
		Set<String> classesRequestedAfter = new LinkedHashSet<>();
		// 【className依赖的配置来源1：我在哪些配置类之后】
		classesRequestedAfter.addAll(get(className).getAfter());
		// 遍历所有的配置类，查找在className之前的配置类
		this.classes.forEach((name, autoConfigurationClass) -> {
			// 【className依赖的配置来源2：哪些配置类在我之前】
			if (autoConfigurationClass.getBefore().contains(className)) {
				classesRequestedAfter.add(name);
			}
		});
		return classesRequestedAfter;
	}
}
```