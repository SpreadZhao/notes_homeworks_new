

### 什么是full和lite类型

1. 给BeanDefinition设置配置类属性。是full类型还是lite类型
```java
// 被Configuration注解的就是full
if (isFullConfigurationCandidate(metadata)) {
    beanDef.setAttribute(CONFIGURATION_CLASS_ATTRIBUTE, CONFIGURATION_CLASS_FULL);
}
else if (isLiteConfigurationCandidate(metadata)) {
    beanDef.setAttribute(CONFIGURATION_CLASS_ATTRIBUTE, CONFIGURATION_CLASS_LITE);
}
```

2. 什么情况是full类型
答案：注解元数据存在@Configuration注解就是full类型的配置类
```java
public class ConfigurationClassUtils {
	public static boolean isFullConfigurationCandidate(AnnotationMetadata metadata) {
		return metadata.isAnnotated(Configuration.class.getName());
	}
}
```

3. 什么情况是lite类型【candidateIndicators + 被@Bean注解标注】
```java
public class ConfigurationClassUtils {
	static {
		candidateIndicators.add(Component.class.getName());
		candidateIndicators.add(ComponentScan.class.getName());
		candidateIndicators.add(Import.class.getName());
		candidateIndicators.add(ImportResource.class.getName());
	}

	public static boolean isLiteConfigurationCandidate(AnnotationMetadata metadata) {
		for (String indicator : candidateIndicators) {
			if (metadata.isAnnotated(indicator)) {
				return true;
			}
		}

		return metadata.hasAnnotatedMethods(Bean.class.getName());
	}
}
```

### full和lite类型有什么区别
full类型的配置类会被cglib代理增强，而lite类型的配置类不会被增强