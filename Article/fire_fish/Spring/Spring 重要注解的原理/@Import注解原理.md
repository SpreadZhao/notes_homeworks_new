
@[TOC](文章结构)

## 相关核心类
* ImportSelector(导入选择器) | DeferredImportSelector(延迟的导入选择器)
* ImportBeanDefinitionRegistrar(导入BeanDefinition注册器)
* Configuration(配置类)

## 注册"注解配置"的处理器
重点有注册了`ConfigurationClassPostProcessor`类，完成配置类的处理工作。

在处理配置类的过程中就会进行@Import的处理工作
```java
public class AnnotationConfigUtils {
	// 注册"注解配置"的处理器
   public static Set<BeanDefinitionHolder> registerAnnotationConfigProcessors(
           BeanDefinitionRegistry registry, Object source) {
	   // .........
      Set<BeanDefinitionHolder> beanDefs = new LinkedHashSet<BeanDefinitionHolder>(4);

	  // 1、注册"ConfigurationClassPostProcessor"处理器【用于处理"配置类"】【重点】
      if (!registry.containsBeanDefinition(CONFIGURATION_ANNOTATION_PROCESSOR_BEAN_NAME)) {
         RootBeanDefinition def = new RootBeanDefinition(ConfigurationClassPostProcessor.class);
         def.setSource(source);
         beanDefs.add(registerPostProcessor(registry, def, CONFIGURATION_ANNOTATION_PROCESSOR_BEAN_NAME));
      }

      // 2、注册"AutowiredAnnotationBeanPostProcessor"处理器【用于处理"自动装配"】【重点】
      if (!registry.containsBeanDefinition(AUTOWIRED_ANNOTATION_PROCESSOR_BEAN_NAME)) {
         RootBeanDefinition def = new RootBeanDefinition(AutowiredAnnotationBeanPostProcessor.class);
         def.setSource(source);
         beanDefs.add(registerPostProcessor(registry, def, AUTOWIRED_ANNOTATION_PROCESSOR_BEAN_NAME));
      }
	  // ...........

      return beanDefs;
   }
}
```

## @Import注解源码的入口位置

源码的入口位置在`ConfigurationClassParser#doProcessConfigurationClass`方法中，至于为什么是这个位置，先按下不表后续会填坑完善。
<a href="等待填坑">Spring如何解析配置类</a>

先简单看下Spring是如何处理配置类(Configuration | config class)的，在其中就处理了配置类中的`@Import`注解。
1. <1> 首先处理 "内部类"
2. <2> 处理 @PropertySource 注解
3. <3> 处理 @ComponentScan 注解
4. <4> 处理 @Import 注解
5. <5> 处理 @ImportResource 注解
6. **<6> 处理 @Bean 注解**
7. <7> 处理 接口的默认方法
8. <8> 处理 "父类或父接口"
```java
// 这个类的功能如名字所示的就是：完成所有Configuration的解析。至于原理就是递归递归递归.....
class ConfigurationClassParser {
	@Nullable
	protected final SourceClass doProcessConfigurationClass(ConfigurationClass configClass, SourceClass sourceClass)
			throws IOException {

		// Recursively process any member (nested) classes first
        // <1> 首先处理 "内部类"
		processMemberClasses(configClass, sourceClass);

		// Process any @PropertySource annotations
        // <2> 处理 @PropertySource 注解
		for (AnnotationAttributes propertySource : AnnotationConfigUtils.attributesForRepeatable(
				sourceClass.getMetadata(), PropertySources.class,
				org.springframework.context.annotation.PropertySource.class)) {
			if (this.environment instanceof ConfigurableEnvironment) {
				processPropertySource(propertySource);
			} else {
				logger.warn("Ignoring @PropertySource annotation on [" + sourceClass.getMetadata().getClassName() +
						"]. Reason: Environment must implement ConfigurableEnvironment");
			}
		}

		// Process any @ComponentScan annotations
		// <3> 处理 @ComponentScan 注解
		Set<AnnotationAttributes> componentScans = AnnotationConfigUtils.attributesForRepeatable(
				sourceClass.getMetadata(), ComponentScans.class, ComponentScan.class);
		if (!componentScans.isEmpty() &&
				!this.conditionEvaluator.shouldSkip(sourceClass.getMetadata(), ConfigurationPhase.REGISTER_BEAN)) {
			for (AnnotationAttributes componentScan : componentScans) {
				// The config class is annotated with @ComponentScan -> perform the scan immediately
				Set<BeanDefinitionHolder> scannedBeanDefinitions =
						this.componentScanParser.parse(componentScan, sourceClass.getMetadata().getClassName());
				// Check the set of scanned definitions for any further config classes and parse recursively if needed
                // 如果扫描的 definitions，有@Configuration，则递归进行解析
				for (BeanDefinitionHolder holder : scannedBeanDefinitions) {
					BeanDefinition bdCand = holder.getBeanDefinition().getOriginatingBeanDefinition();
					if (bdCand == null) {
						bdCand = holder.getBeanDefinition();
					}
					if (ConfigurationClassUtils.checkConfigurationClassCandidate(bdCand, this.metadataReaderFactory)) {
						parse(bdCand.getBeanClassName(), holder.getBeanName());
					}
				}
			}
		}

		// Process any @Import annotations
        // <4> 处理 @Import 注解
		processImports(configClass, sourceClass, getImports(sourceClass), true);

		// Process any @ImportResource annotations
		// <5> 处理 @ImportResource 注解
		AnnotationAttributes importResource =
				AnnotationConfigUtils.attributesFor(sourceClass.getMetadata(), ImportResource.class);
		if (importResource != null) {
			String[] resources = importResource.getStringArray("locations");
			Class<? extends BeanDefinitionReader> readerClass = importResource.getClass("reader");
			for (String resource : resources) {
				String resolvedResource = this.environment.resolveRequiredPlaceholders(resource);
				configClass.addImportedResource(resolvedResource, readerClass);
			}
		}

		// Process individual @Bean methods
        // <6> 处理 @Bean 注解
		Set<MethodMetadata> beanMethods = retrieveBeanMethodMetadata(sourceClass);
		for (MethodMetadata methodMetadata : beanMethods) {
			configClass.addBeanMethod(new BeanMethod(methodMetadata, configClass));
		}

		// Process default methods on interfaces
		// <7> 处理 接口的默认方法
		processInterfaces(configClass, sourceClass);

		// Process superclass, if any
        // <8> 处理 "父类或父接口"
		if (sourceClass.getMetadata().hasSuperClass()) {
			String superclass = sourceClass.getMetadata().getSuperClassName();
			if (superclass != null && !superclass.startsWith("java") &&
					!this.knownSuperclasses.containsKey(superclass)) {
				this.knownSuperclasses.put(superclass, configClass);
				// Superclass found, return its annotation metadata and recurse
				return sourceClass.getSuperClass();
			}
		}

		// No superclass -> processing is complete
		return null;
	}
}
```

## @Import注解原理
接上文，来到了@Import源码分析部分。
```java
// 代码位置：ConfigurationClassParser#doProcessConfigurationClass
processImports(configClass, sourceClass, getImports(sourceClass), true);
```
### 收集@Import注解
收集过程总体是采用递归的方式完成收集，而且**@Import注解的收集顺序是依据注解定义的上下先后顺序**
```java
// 代码位置：ConfigurationClassParser.class
class ConfigurationClassParser {
	private Set<SourceClass> getImports(SourceClass sourceClass) throws IOException {
		Set<SourceClass> imports = new LinkedHashSet<>();
		Set<SourceClass> visited = new LinkedHashSet<>();
		collectImports(sourceClass, imports, visited);
		return imports;
	}
}
```
```java
// 代码位置：ConfigurationClassParser.class
class ConfigurationClassParser {
    private void collectImports(SourceClass sourceClass, Set<SourceClass> imports, Set<SourceClass> visited)
            throws IOException {
    
        if (visited.add(sourceClass)) {
            for (SourceClass annotation : sourceClass.getAnnotations()) {
                String annName = annotation.getMetadata().getClassName();
                // 如果 sourceClass 注解了 @Import，则进行递归
                if (!annName.startsWith("java") && !annName.equals(Import.class.getName())) {
                    collectImports(annotation, imports, visited);
                }
            }
            // 把@Import注解的value值添加进 imports，完成@Import注解的收集
            imports.addAll(sourceClass.getAnnotationAttributes(Import.class.getName(), "value"));
        }
    }
}
```

### 处理收集的imports
上一步完成了被@Import注解的类的收集，那么下一步就是自然就是如何处理被收集的类。
处理过程如下：
* 如果是`ImportSelector`类型，则调用`selectImports`方法注册bean
* 如果是`ImportBeanDefinitionRegistrar`，则调用`registerBeanDefinitions`方法注册bean
* 如果是其他，则按`@Configuration`处理

```java
// 代码位置：ConfigurationClassParser#processImports 方法
for (SourceClass candidate : importCandidates) {
	// 1、如果是ImportSelector类型则
    if (candidate.isAssignable(ImportSelector.class)) {
        // 略......
    }
	// 2、如果是ImportSelector类型则
    else if (candidate.isAssignable(ImportBeanDefinitionRegistrar.class)) {
		// 略......
    }
	// 3、如果不是以上2种类型，则吧class当做@Configuration来处理
    else {
        this.importStack.registerImport(
                currentSourceClass.getMetadata(), candidate.getMetadata().getClassName());
        processConfigurationClass(candidate.asConfigClass(configClass));
    }
}
```

写在最后：
1. 一般的@Import的功能都是往容器注册Bean。
2. 上面的整个流程是由<mark>**ConfigurationClassPostProcessor**</mark>后置处理器"引发的。这个类是Spring生态很多注解的原理
   （如：`@PropertySource`、`@ComponentScan`、`@Import`、`@Bean`）。
3. 有兴趣的同学可以研究下`ConfigurationClassPostProcessor`原理，提示：涉及到很多递归，可以画个图，不然容易绕晕。

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>




