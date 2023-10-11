背景：在spring 2.5中实现了一层注解的解析；在spring 3.0中实现了二层注解的解析；在spring4.0中实现了多层次注解的解析

核心类：MetaDataReader 用来从字节码中获取到类的注解信息、类信息
核心类：AnnotationMetaData 表示类的注解信息元数据
核心类：ClassMetadata 表示类的信息元数据



### 核心类MetaDataReader
官方解释：Simple facade for accessing class metadata, as read by an ASM org.objectweb.asm.ClassReader.
简单的门面用来访问class元数据，用ASM实现的。

先看下MetadataReader的定义。
```java
public interface MetadataReader {

	/**
     * 读取基础class元数据
	 * Read basic class metadata for the underlying class.
	 */
	ClassMetadata getClassMetadata();

	/**
     * 读取完整的注解元数据
	 * Read full annotation metadata for the underlying class.
	 */
	AnnotationMetadata getAnnotationMetadata();

}
```
再看下他的默认实现
```java
class SimpleMetadataReader implements MetadataReader {

	private final ClassReader classReader;

	private final ClassLoader classLoader;


	public SimpleMetadataReader(ClassReader classReader, ClassLoader classLoader) {
		this.classReader = classReader;
		this.classLoader = classLoader;
	}


	public ClassMetadata getClassMetadata() {
		// 默认，class元数据访问是：ClassMetadataReadingVisitor对象
		ClassMetadataReadingVisitor visitor = new ClassMetadataReadingVisitor();
		this.classReader.accept(visitor, true);
		return visitor;
	}

	public AnnotationMetadata getAnnotationMetadata() {
		// 默认，注解元数据访问是：AnnotationMetadataReadingVisitor对象
		AnnotationMetadataReadingVisitor visitor = new AnnotationMetadataReadingVisitor(this.classLoader);
		this.classReader.accept(visitor, true);
		return visitor;
	}

}
```
执行过滤时，会调用到MetadataReader的方法。

#### 看Spring 2.5的实现。
在spring 2.5的实现中有缺陷，只会解析一层注解；在spring 3.0中也有缺陷，只会解析2层注解；在spring 4.0中会递归解析所有层次的注解。
```java
/**
 * 只解析了一层注解元注解
 */
class AnnotationMetadataReadingVisitor extends ClassMetadataReadingVisitor implements AnnotationMetadata {
	/**
     * 
	 * @param desc          resource上的注解的名称
	 * @param visible
	 * @return
	 */
	public AnnotationVisitor visitAnnotation(final String desc, boolean visible) {
		final String className = Type.getType(desc).getClassName();
		final Map<String, Object> attributes = new LinkedHashMap<String, Object>();
		return new EmptyVisitor() {
			// 1、这个方法会先被调用
			public void visit(String name, Object value) {
				// 解析"明确定义"的属性值。属性覆盖的原理也在这里面深层地方
				attributes.put(name, value);
			}

			// 2、这个方法最后会被调用
			public void visitEnd() {
				try {
					Class annotationClass = classLoader.loadClass(className);
					// Check declared default values of attributes in the annotation type.
					Method[] annotationAttributes = annotationClass.getMethods();
					for (int i = 0; i < annotationAttributes.length; i++) {
						Method annotationAttribute = annotationAttributes[i];
						String attributeName = annotationAttribute.getName();
						Object defaultValue = annotationAttribute.getDefaultValue();
						if (defaultValue != null && !attributes.containsKey(attributeName)) {
							// 如果没有明确定义属性的值则用默认值
							attributes.put(attributeName, defaultValue);
						}
					}
					// Register annotations that the annotation type is annotated with.
					Annotation[] metaAnnotations = annotationClass.getAnnotations();
					Set<String> metaAnnotationTypeNames = new HashSet<String>();
					for (Annotation metaAnnotation : metaAnnotations) {
						metaAnnotationTypeNames.add(metaAnnotation.annotationType().getName());
					}
					
					// 把解析到注解存储起来【key=注解，vlaue=有哪些元注解】
					metaAnnotationMap.put(className, metaAnnotationTypeNames);
				} catch (ClassNotFoundException ex) {
					// Class not found - can't determine meta-annotations.
				}
				// 把解析到属性存储起来【key=注解，value=属性值】
				attributesMap.put(className, attributes);
			}
		};
	}
}
```
#### 看spring 3.0的实现

Spring 3.0是不是仅仅支持2层注解的嵌套，对于多层注解不支持呢(猜测)。答：是的，对于多层注解不支持。

```java
final class AnnotationAttributesReadingVisitor implements AnnotationVisitor {
	public void visitEnd() {
		// 1、把属性存储在 attributesMap 中
		this.attributesMap.put(this.annotationType, this.localAttributes);
		try {
			Class<?> annotationClass = this.classLoader.loadClass(this.annotationType);
			// Check declared default values of attributes in the annotation type.
			Method[] annotationAttributes = annotationClass.getMethods();
			for (Method annotationAttribute : annotationAttributes) {
				String attributeName = annotationAttribute.getName();
				Object defaultValue = annotationAttribute.getDefaultValue();
				if (defaultValue != null && !this.localAttributes.containsKey(attributeName)) {
					this.localAttributes.put(attributeName, defaultValue);
				}
			}
			// Register annotations that the annotation type is annotated with.
			Set<String> metaAnnotationTypeNames = new LinkedHashSet<String>();
			// 2、处理注解第一层
			for (Annotation metaAnnotation : annotationClass.getAnnotations()) {
				metaAnnotationTypeNames.add(metaAnnotation.annotationType().getName());
				// 如果属性已经存在了就不会往里面添加
				if (!this.attributesMap.containsKey(metaAnnotation.annotationType().getName())) {
					this.attributesMap.put(metaAnnotation.annotationType().getName(),
							AnnotationUtils.getAnnotationAttributes(metaAnnotation, true));
				}
				// 3、处理注解第二层
				for (Annotation metaMetaAnnotation : metaAnnotation.annotationType().getAnnotations()) {
					metaAnnotationTypeNames.add(metaMetaAnnotation.annotationType().getName());
				}
			}
			if (this.metaAnnotationMap != null) {
				this.metaAnnotationMap.put(this.annotationType, metaAnnotationTypeNames);
			}
		} catch (ClassNotFoundException ex) {
			// Class not found - can't determine meta-annotations.
		}
	}
}
```

#### spring 4.0

终于在spring 4.0中采用递归方式实现了多层次注解的解析工作。

```java
abstract class AbstractRecursiveAnnotationVisitor extends AnnotationVisitor {
	@Override
	public void doVisitEnd(Class<?> annotationClass) {
		super.doVisitEnd(annotationClass);
		List<AnnotationAttributes> attributes = this.attributesMap.get(this.annotationType);
		if (attributes == null) {
			this.attributesMap.add(this.annotationType, this.attributes);
		} else {
			attributes.add(0, this.attributes);
		}
		Set<String> metaAnnotationTypeNames = new LinkedHashSet<String>();
		for (Annotation metaAnnotation : annotationClass.getAnnotations()) {
			// 1、递归处理注解
			recursivelyCollectMetaAnnotations(metaAnnotationTypeNames, metaAnnotation);
		}
		if (this.metaAnnotationMap != null) {
			this.metaAnnotationMap.put(annotationClass.getName(), metaAnnotationTypeNames);
		}
	}
	
	private void recursivelyCollectMetaAnnotations(Set<String> visited, Annotation annotation) {
		if (visited.add(annotation.annotationType().getName())) {
			// Only do further scanning for public annotations; we'd run into IllegalAccessExceptions
			// otherwise, and don't want to mess with accessibility in a SecurityManager environment.
			if (Modifier.isPublic(annotation.annotationType().getModifiers())) {
				// 2、解析属性把属性放入 attributesMap 中
				this.attributesMap.add(annotation.annotationType().getName(),
						AnnotationUtils.getAnnotationAttributes(annotation, true, true));
				for (Annotation metaMetaAnnotation : annotation.annotationType().getAnnotations()) {
					// 2、递归处理注解
					recursivelyCollectMetaAnnotations(visited, metaMetaAnnotation);
				}
			}
		}
	}
}
	
```