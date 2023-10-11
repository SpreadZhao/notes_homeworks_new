
## 前置知识
springBoot装配原理。
1. `spring-boot-autoconfigure-2.1.3.RELEASE.jar`包中的`spring.factories`文件
2. org.springframework.boot.autoconfigure.EnableAutoConfiguration=org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration
3. `DataSourceAutoConfiguration`类

## 注入dataSource定义
1. 接上文，我们看下`DataSourceAutoConfiguration`类的定义
```java
@Configuration
@ConditionalOnClass({ DataSource.class, EmbeddedDatabaseType.class })
@EnableConfigurationProperties(DataSourceProperties.class)
@Import({ DataSourcePoolMetadataProvidersConfiguration.class,
		DataSourceInitializationConfiguration.class })
public class DataSourceAutoConfiguration {

	@Configuration
	@Conditional(PooledDataSourceCondition.class)
	@ConditionalOnMissingBean({ DataSource.class, XADataSource.class })
    // 在这里引入了Hikari类
	@Import({ DataSourceConfiguration.Hikari.class, DataSourceConfiguration.Tomcat.class,
			DataSourceConfiguration.Dbcp2.class, DataSourceConfiguration.Generic.class,
			DataSourceJmxConfiguration.class })
	protected static class PooledDataSourceConfiguration {

	}
}
```
2. 继续查看该类的定义
```java
	@ConditionalOnClass(HikariDataSource.class)
	@ConditionalOnMissingBean(DataSource.class)
	@ConditionalOnProperty(name = "spring.datasource.type", havingValue = "com.zaxxer.hikari.HikariDataSource", matchIfMissing = true)
	static class Hikari {

	    // 配置文件中前缀为"spring.datasource.hikari"的属性将被装配到"HikariDataSource"类中
		@Bean
		@ConfigurationProperties(prefix = "spring.datasource.hikari")
		public HikariDataSource dataSource(DataSourceProperties properties) {
			HikariDataSource dataSource = createDataSource(properties,
					HikariDataSource.class);
			if (StringUtils.hasText(properties.getName())) {
				dataSource.setPoolName(properties.getName());
			}
			return dataSource;
		}

	}
```
3. 到此为止，完成吧装配`HikariDataSource`的dataSource的bena。


## 属性绑定的通用原理
如下是主要方法：
1. propertyBinder.bindProperty 从source中获取属性值（source可以是environment）
2. 调用`property.setValue`方法吧属性值设置到`beanSupplier`中（beanSupplier是对target的封装）
```java
private <T> boolean bind(BeanSupplier<T> beanSupplier,
        BeanPropertyBinder propertyBinder, BeanProperty property) {
    String propertyName = property.getName();
    ResolvableType type = property.getType();
    Supplier<Object> value = property.getValue(beanSupplier);
    Annotation[] annotations = property.getAnnotations();
	// 1、获取属性值
    Object bound = propertyBinder.bindProperty(propertyName,
            Bindable.of(type).withSuppliedValue(value).withAnnotations(annotations));
    if (bound == null) {
        return false;
    }
    if (property.isSettable()) {
		// 2、把属性值设置到target对象中
        property.setValue(beanSupplier, bound);
    }
    else if (value == null || !bound.equals(value.get())) {
        throw new IllegalStateException(
                "No setter found for property: " + property.getName());
    }
    return true;
}
```

## 属性绑定到DataSource的原理
1. bean实例化阶段，第一次调用bind方法完成url、driverClassName、username、password基础属性
的绑定
2. bean初始化阶段，调用PostProcessor后置处理器第二次调用bind方法完成其他属性的绑定
### 实例化dataSource（第一次绑定，以 DataSourceProperties 作为数据源，把属性转换绑定到hikaciDataSource中。
常见类介绍：
1. DataSourceBuilder 是对url、driverClassName、username、password、type基础属性的封装对象，用于创建DataSource
2. DataSourceProperties 是springboot对spring.datasource开头属性的配置对象
3. HikariDataSource 是HikariCP对spring.datasource.hikari开头属性的配置对象

开始绑定。
```java
public HikariDataSource dataSource(DataSourceProperties properties) {
    HikariDataSource dataSource = createDataSource(properties,
            HikariDataSource.class);
    if (StringUtils.hasText(properties.getName())) {
        dataSource.setPoolName(properties.getName());
    }
    return dataSource;
}
```
第一次调用bind方法
```java
public T build() {
    Class<? extends DataSource> type = getType();
    DataSource result = BeanUtils.instantiateClass(type);
    maybeGetDriverClassName();
    bind(result);
    return (T) result;
}
```
接上文继续分析绑定的细节。
1. result、target、beanSupplier、value(Supplier<Object>) 是属性绑定的目标对象（只不过封装了）
2. source、binder、context 是属性的数据来源对象（只不过是封装了）
```java
private void bind(DataSource result) {
    ConfigurationPropertySource source = new MapConfigurationPropertySource(
            this.properties);
    ConfigurationPropertyNameAliases aliases = new ConfigurationPropertyNameAliases();
    // 就是这里哦
	aliases.addAliases("url", "jdbc-url");
    aliases.addAliases("username", "user");
    Binder binder = new Binder(source.withAliases(aliases));
    binder.bind(ConfigurationPropertyName.EMPTY, Bindable.ofInstance(result));
}

public <T> BindResult<T> bind(ConfigurationPropertyName name, Bindable<T> target,
    BindHandler handler) {
    Assert.notNull(name, "Name must not be null");
    Assert.notNull(target, "Target must not be null");
	// 绑定的处理器？
    handler = (handler != null) ? handler : BindHandler.DEFAULT;
    Context context = new Context();
	// 绑定细节
    T bound = bind(name, target, handler, context, false);
    return BindResult.of(bound);
}
```
Context对象实例化，context对象是Binder对象的内部类，具有binder对象的所有访问权限，而binder对象是对属性来源的封装。
```java
Context() {
	// 设置spring默认的"类型转换器"
    this.converter = BindConverter.get(Binder.this.conversionService,
            Binder.this.propertyEditorInitializer);
}

@Override
public Iterable<ConfigurationPropertySource> getSources() {
    if (this.sourcePushCount > 0) {
        return this.source;
    }
	// 返回的是"外部类"的sources，也就是我们之前设置的 source 了。就是有4个jdbc属性这个
    return Binder.this.sources;
}
```
```java
protected final <T> T bind(ConfigurationPropertyName name, Bindable<T> target,
        BindHandler handler, Context context, boolean allowRecursiveBinding) {
    context.clearConfigurationProperty();
    try {
        // 取回设置的目标对象
        target = handler.onStart(name, target, context);
        if (target == null) {
            return null;
        }
		// 绑定
        Object bound = bindObject(name, target, handler, context,
                allowRecursiveBinding);
        return handleBindResult(name, target, handler, context, bound);
    }
    catch (Exception ex) {
        return handleBindError(name, target, handler, context, ex);
    }
}
```
遇到了几个重要的lambda表达式
1. BeanPropertyBinder propertyBinder。 说明：bean的属性绑定，功能是完成属性的绑定。
2. 
```java
private Object bindBean(ConfigurationPropertyName name, Bindable<?> target,
        BindHandler handler, Context context, boolean allowRecursiveBinding) {
    if (containsNoDescendantOf(context.getSources(), name)
            || isUnbindableBean(name, target, context)) {
        return null;
    }
	// 第一个重要的lambda表达式
    BeanPropertyBinder propertyBinder = (propertyName, propertyTarget) -> bind(
            name.append(propertyName), propertyTarget, handler, context, false);
    Class<?> type = target.getType().resolve(Object.class);
    if (!allowRecursiveBinding && context.hasBoundBean(type)) {
        return null;
    }
	// 第二个重要的lambda表达式
    return context.withBean(type, () -> {
        Stream<?> boundBeans = BEAN_BINDERS.stream()
                .map((b) -> b.bind(name, target, context, propertyBinder));
        return boundBeans.filter(Objects::nonNull).findFirst().orElse(null);
    });
}
```
执行
```java
return context.withBean(type, () -> {
    Stream<?> boundBeans = BEAN_BINDERS.stream()
            .map((b) -> b.bind(name, target, context, propertyBinder));
    return boundBeans.filter(Objects::nonNull).findFirst().orElse(null);
});
```
```java
private <T> T withBean(Class<?> bean, Supplier<T> supplier) {
    this.beans.push(bean);
    try {
        return withIncreasedDepth(supplier);
    }
    finally {
        this.beans.pop();
    }
}
```
```java
private <T> T withIncreasedDepth(Supplier<T> supplier) {
    increaseDepth();
    try {
        return supplier.get();// 执行lambda
    }
    finally {
        decreaseDepth();
    }
}
```
执行到lambda。BEAN_BINDERS是一个list，初始有一个元素JavaBeanBinder类。
接着执行JavaBeanBinder的bind方法。在stream的收集阶段会真正执行stream的系列方法。
```java
return context.withBean(type, () -> {
    Stream<?> boundBeans = BEAN_BINDERS.stream()
        .map((b) -> b.bind(name, target, context, propertyBinder));
    return boundBeans.filter(Objects::nonNull).findFirst().orElse(null);
});
```
```java
public <T> T bind(ConfigurationPropertyName name, Bindable<T> target, Context context,
        BeanPropertyBinder propertyBinder) {
    boolean hasKnownBindableProperties = hasKnownBindableProperties(name, context);
    Bean<T> bean = Bean.get(target, hasKnownBindableProperties);
    if (bean == null) {
        return null;
    }
	// 这也是一个lambda，这个lambda可以取回要设置属性的target 。 
    BeanSupplier<T> beanSupplier = bean.getSupplier(target);
    boolean bound = bind(propertyBinder, bean, beanSupplier);
    return (bound ? beanSupplier.get() : null);
}
```
遍历目标type的所有属性（不是字段）
```java
private <T> boolean bind(BeanPropertyBinder propertyBinder, Bean<T> bean,
        BeanSupplier<T> beanSupplier) {
    boolean bound = false;
    for (BeanProperty beanProperty : bean.getProperties().values()) {
        bound |= bind(beanSupplier, propertyBinder, beanProperty);
    }
    return bound;
}
```
```java
private <T> boolean bind(BeanSupplier<T> beanSupplier,
        BeanPropertyBinder propertyBinder, BeanProperty property) {
    String propertyName = property.getName();
    ResolvableType type = property.getType();
    Supplier<Object> value = property.getValue(beanSupplier);
    Annotation[] annotations = property.getAnnotations();
	// 回调之前的lambda方法完成值的获取。【回调BeanPropertyBinder propertyBinder 这个lambda】
    Object bound = propertyBinder.bindProperty(propertyName,
            Bindable.of(type).withSuppliedValue(value).withAnnotations(annotations));
    if (bound == null) {
        return false;
    }
    if (property.isSettable()) {
        property.setValue(beanSupplier, bound);
    }
    else if (value == null || !bound.equals(value.get())) {
        throw new IllegalStateException(
                "No setter found for property: " + property.getName());
    }
    return true;
}
```
回调`BeanPropertyBinder propertyBinder`这个lambda
```java
protected final <T> T bind(ConfigurationPropertyName name, Bindable<T> target,
        BindHandler handler, Context context, boolean allowRecursiveBinding) {
    context.clearConfigurationProperty();
    try {
		// 生产者模式，取回要设置的目标对象target
        target = handler.onStart(name, target, context);
        if (target == null) {
            return null;
        }
		// 把source中绑定到目标对象
        Object bound = bindObject(name, target, handler, context,
                allowRecursiveBinding);
        return handleBindResult(name, target, handler, context, bound);
    }
    catch (Exception ex) {
        return handleBindError(name, target, handler, context, ex);
    }
}
```
继续
```java
private <T> Object bindObject(ConfigurationPropertyName name, Bindable<T> target,
        BindHandler handler, Context context, boolean allowRecursiveBinding) {
	// 从sorue中查找属性值
    ConfigurationProperty property = findProperty(name, context);
    if (property == null && containsNoDescendantOf(context.getSources(), name)) {
        return null;
    }
    AggregateBinder<?> aggregateBinder = getAggregateBinder(target, context);
    if (aggregateBinder != null) {
        return bindAggregate(name, target, handler, context, aggregateBinder);
    }
    if (property != null) {
        try {
			// 解析占位符、属性类型转换等。并没有吧属性值绑定到目标对象
            return bindProperty(target, context, property);
        }
        catch (ConverterNotFoundException ex) {
            // We might still be able to bind it as a bean
            Object bean = bindBean(name, target, handler, context,
                    allowRecursiveBinding);
            if (bean != null) {
                return bean;
            }
            throw ex;
        }
    }
	// 猜测，是递归绑定？针对多层次属性
    return bindBean(name, target, handler, context, allowRecursiveBinding);
}
```



### springboot的环境准备好事件背后的一些幕后动作。
1. springboot准备好environment环境后会触发一个事件`ApplicationEnvironmentPreparedEvent`
2. 接下来会有listener处理这个事件，listener有多个
```java
public void multicastEvent(final ApplicationEvent event, @Nullable ResolvableType eventType) {
    ResolvableType type = (eventType != null ? eventType : resolveDefaultEventType(event));
    for (final ApplicationListener<?> listener : getApplicationListeners(event, type)) {
        Executor executor = getTaskExecutor();
        if (executor != null) {
            executor.execute(() -> invokeListener(listener, event));
        }
        else {
            invokeListener(listener, event);
        }
    }
}
```
![](/Users/apple/Documents/Work/aliyun-oss/dev-images/2022-11-18-01-50-52-image.png)
这里以重要的`ConfigFileApplicationListener`说明。
3. 查看`ConfigFileApplicationListener`的定义，实现了`ApplicationListener`和`PostProcessor`2个重要接口
```java
public class ConfigFileApplicationListener
		implements EnvironmentPostProcessor, SmartApplicationListener, Ordered {
```
4. 因为实现了`ApplicationListener`接口执行如下方法
```java
private void onApplicationEnvironmentPreparedEvent(
        ApplicationEnvironmentPreparedEvent event) {
	// 获取自动装配的 EnvironmentPostProcessor 类型的PostProcessor。
        // 而且 ConfigFileApplicationListener 就是其中一个。
    List<EnvironmentPostProcessor> postProcessors = loadPostProcessors();
    postProcessors.add(this);
    AnnotationAwareOrderComparator.sort(postProcessors);
    for (EnvironmentPostProcessor postProcessor : postProcessors) {
        postProcessor.postProcessEnvironment(event.getEnvironment(),
                event.getSpringApplication());
    }
}
```
5. 因为`ConfigFileApplicationListener`是EnvironmentPostProcessor，所以执行如下方法
```java
public void postProcessEnvironment(ConfigurableEnvironment environment,
        SpringApplication application) {
    addPropertySources(environment, application.getResourceLoader());
}

protected void addPropertySources(ConfigurableEnvironment environment,
        ResourceLoader resourceLoader) {
    RandomValuePropertySource.addToEnvironment(environment);
    new Loader(environment, resourceLoader).load();
}


public void load() {
    this.profiles = new LinkedList<>();
    this.processedProfiles = new LinkedList<>();
    this.activatedProfiles = false;
    this.loaded = new LinkedHashMap<>();
    initializeProfiles();
    while (!this.profiles.isEmpty()) {
        Profile profile = this.profiles.poll();
        if (profile != null && !profile.isDefaultProfile()) {
            addProfileToEnvironment(profile.getName());
        }
		// 加载
        load(profile, this::getPositiveProfileFilter,
                addToLoaded(MutablePropertySources::addLast, false));
        this.processedProfiles.add(profile);
    }
    resetEnvironmentProfiles(this.processedProfiles);
    load(null, this::getNegativeProfileFilter,
            addToLoaded(MutablePropertySources::addFirst, true));
    addLoadedPropertySources();
}


private void load(Profile profile, DocumentFilterFactory filterFactory,
        DocumentConsumer consumer) {
	// 获取配置文件默认搜索的4个文件夹，在文件夹下搜索文件
    getSearchLocations().forEach((location) -> {
        boolean isFolder = location.endsWith("/");
        Set<String> names = isFolder ? getSearchNames() : NO_SEARCH_NAMES;
		// 处理文件夹下搜索到文件
        names.forEach(
                (name) -> load(location, name, profile, filterFactory, consumer));
    });
}
```
重点说一下：this.propertySourceLoaders 指的是配置源加载器，服务从文件中加载配置到environment中。
默认springboot配置2个"配置源加载器"，分别是：`PropertiesPropertySourceLoader`和`YamlPropertySourceLoader`
```java
private void load(String location, String name, Profile profile,
        DocumentFilterFactory filterFactory, DocumentConsumer consumer) {
    if (!StringUtils.hasText(name)) {
        for (PropertySourceLoader loader : this.propertySourceLoaders) {
            if (canLoadFileExtension(loader, location)) {
                load(loader, location, profile,
                        filterFactory.getDocumentFilter(profile), consumer);
                return;
            }
        }
    }
    Set<String> processed = new HashSet<>();
    for (PropertySourceLoader loader : this.propertySourceLoaders) {
        for (String fileExtension : loader.getFileExtensions()) {
            if (processed.add(fileExtension)) {
				// 加载配置到environment中
                loadForFileExtension(loader, location + name, "." + fileExtension,
                        profile, filterFactory, consumer);
            }
        }
    }
}
```
```java
private void load(PropertySourceLoader loader, String location, Profile profile,
        DocumentFilter filter, DocumentConsumer consumer) {
    try {
        Resource resource = this.resourceLoader.getResource(location);
		// 文件不存在
        if (resource == null || !resource.exists()) {
            if (this.logger.isTraceEnabled()) {
                StringBuilder description = getDescription(
                        "Skipped missing config ", location, resource, profile);
                this.logger.trace(description);
            }
            return;
        }
		// 文件不存在
        if (!StringUtils.hasText(
                StringUtils.getFilenameExtension(resource.getFilename()))) {
            if (this.logger.isTraceEnabled()) {
                StringBuilder description = getDescription(
                        "Skipped empty config extension ", location, resource,
                        profile);
                this.logger.trace(description);
            }
            return;
        }
		// 文件存在，开始用loader加载文件
        String name = "applicationConfig: [" + location + "]";
        List<Document> documents = loadDocuments(loader, name, resource);
        if (CollectionUtils.isEmpty(documents)) {
            if (this.logger.isTraceEnabled()) {
                StringBuilder description = getDescription(
                        "Skipped unloaded config ", location, resource, profile);
                this.logger.trace(description);
            }
            return;
        }
        List<Document> loaded = new ArrayList<>();
        for (Document document : documents) {
            if (filter.match(document)) {
                addActiveProfiles(document.getActiveProfiles());
                addIncludedProfiles(document.getIncludeProfiles());
                loaded.add(document);
            }
        }
        Collections.reverse(loaded);
        if (!loaded.isEmpty()) {
			// 用之前传的 consumer 消费 document。
            // 总之最后把配置添加到MutablePropertySources类的propertySourceList属性中，需要知道细节的自行看lambda回调函数
            loaded.forEach((document) -> consumer.accept(profile, document));
            if (this.logger.isDebugEnabled()) {
                StringBuilder description = getDescription("Loaded config file ",
                        location, resource, profile);
                this.logger.debug(description);
            }
        }
    }
}
```
```java
private List<Document> loadDocuments(PropertySourceLoader loader, String name,
        Resource resource) throws IOException {
    DocumentsCacheKey cacheKey = new DocumentsCacheKey(loader, resource);
    List<Document> documents = this.loadDocumentsCache.get(cacheKey);
    if (documents == null) {
		// 调用loader完成了加载，并把配置封装为一个数组。
        List<PropertySource<?>> loaded = loader.load(name, resource);
		// 把配置转换为document
        documents = asDocuments(loaded);
        this.loadDocumentsCache.put(cacheKey, documents);
    }
    return documents;
}
```
```java
private List<Document> asDocuments(List<PropertySource<?>> loaded) {
    if (loaded == null) {
        return Collections.emptyList();
    }
    return loaded.stream().map((propertySource) -> {
		// 创建Binder对象，在springboot配置绑定过程中用途很大。
        Binder binder = new Binder(
                ConfigurationPropertySources.from(propertySource),
                this.placeholdersResolver);
		// 返回Document对象
        return new Document(propertySource,
				// 调用bind方法
                binder.bind("spring.profiles", STRING_ARRAY).orElse(null),
                getProfiles(binder, ACTIVE_PROFILES_PROPERTY),
                getProfiles(binder, INCLUDE_PROFILES_PROPERTY));
    }).collect(Collectors.toList());
}
```
比如`PropertiesPropertySourceLoader`的load方法：
把properties文件中加载配置文件，并把配置封装为`OriginTrackedMapPropertySource`类。
```java
public List<PropertySource<?>> load(String name, Resource resource)
        throws IOException {
    Map<String, ?> properties = loadProperties(resource);
    if (properties.isEmpty()) {
        return Collections.emptyList();
    }
    return Collections
            .singletonList(new OriginTrackedMapPropertySource(name, properties));
}
```
### dataSource实例化阶段（第二次绑定，以配置文件为数据源，绑定到hikaciDataSource中）
1. 绑定的原理是应用后置处理器（ConfigurationPropertiesBindingPostProcessor），后置处理器把ApplicationContext都引入进来了，
所以当然任何属性都可以获取到了啊。
2. 绑定的过程跟第一次绑定一样，最后都是调用Binder对象的bind方法
入口位置：
```java
applyBeanPostProcessorsBeforeInitialization(wrappedBean, beanName);

for (BeanPostProcessor processor : getBeanPostProcessors()) {
    Object current = processor.postProcessBeforeInitialization(result, beanName);
    if (current == null) {
        return result;
    }
    result = current;
}
```
```java
private void bind(Object bean, String beanName, ConfigurationProperties annotation) {
    ResolvableType type = getBeanType(bean, beanName);
    Validated validated = getAnnotation(bean, beanName, Validated.class);
    Annotation[] annotations = (validated != null)
            ? new Annotation[] { annotation, validated }
            : new Annotation[] { annotation };
	// target 封装了要设置属性的bean
    Bindable<?> target = Bindable.of(type).withExistingValue(bean)
            .withAnnotations(annotations);
    try {
		// this.configurationPropertiesBinder 封装了ApplicationContext
        this.configurationPropertiesBinder.bind(target);
    }
}
```
1. 获取bean上的注解@ConfigurationProperties的前缀
2. 获取处理器（处理的不同体现在处理器上。IgnoreTopLevelConverterNotFoundBindHandler）
3. getBinder方法获取的Binder作为数据源。（这次的数据源来源是通过applicationContext的environment吧所有的配置变量都拿出来了）
4. 绑定的细节跟第一次绑定是一样的，不再赘述。
```java
public void bind(Bindable<?> target) {
	// 获取hikaciDataSource上的注解
    ConfigurationProperties annotation = target
            .getAnnotation(ConfigurationProperties.class);
    Assert.state(annotation != null,
            () -> "Missing @ConfigurationProperties on " + target);
    List<Validator> validators = getValidators(target);
	// 绑定该理器
    BindHandler bindHandler = getBindHandler(annotation, validators);
	// 绑定方法
    getBinder().bind(annotation.prefix(), target, bindHandler);
}
```



## 其他
### 为什么spring.datasource.url的配置会被应用到spring.datasource.hikari.jdbcUrl上
```java
@ConfigurationProperties(prefix = "spring.datasource.hikari")
public HikariDataSource dataSource(DataSourceProperties properties) {
    HikariDataSource dataSource = createDataSource(properties,
            HikariDataSource.class);
    if (StringUtils.hasText(properties.getName())) {
        dataSource.setPoolName(properties.getName());
    }
    return dataSource;
}

protected static <T> T createDataSource(DataSourceProperties properties,
        Class<? extends DataSource> type) {
    return (T) properties.initializeDataSourceBuilder().type(type).build();
}

public T build() {
    Class<? extends DataSource> type = getType();
    DataSource result = BeanUtils.instantiateClass(type);
    maybeGetDriverClassName();
    bind(result);
    return (T) result;
}

/**
 * this.properties 就是DataSourceBuilder中的属性，保存有jdbc最重要的4个属性：
 * driverClassName、username、password、url
 */
private void bind(DataSource result) {
    ConfigurationPropertySource source = new MapConfigurationPropertySource(
            this.properties);
    ConfigurationPropertyNameAliases aliases = new ConfigurationPropertyNameAliases();
    // 就是这里哦
	aliases.addAliases("url", "jdbc-url");
    aliases.addAliases("username", "user");
    Binder binder = new Binder(source.withAliases(aliases));
    binder.bind(ConfigurationPropertyName.EMPTY, Bindable.ofInstance(result));
}
```
原理
```java
public ConfigurationProperty getConfigurationProperty(
        ConfigurationPropertyName name) {
    Assert.notNull(name, "Name must not be null");
	// 从source中获取。如果跟原属性名称不一样那么获取不到
    ConfigurationProperty result = getSource().getConfigurationProperty(name);
    if (result == null) {
		// 获取不到之后，转换为别名，重新获取
        ConfigurationPropertyName aliasedName = getAliases().getNameForAlias(name);
        result = getSource().getConfigurationProperty(aliasedName);
    }
    return result;
}
```