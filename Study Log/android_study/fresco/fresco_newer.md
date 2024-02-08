Fresco在使用之前都要进行initialize，initialize操作主要分为三步：

1. 加载.so库，主要是一些第三方的native库，比如gitlib, libjpeg, libpng等等，用来做图片的解码；
2. 设置传入的参数imagePipelineConfig，初始化ImagePipelineFactory
	* 这个类包含了很多要初始化的参数，比如bitmap的配置，还有内存缓存的一些参数，但是这些东西都有默认值，所以我们通常只是传入一个context，其它的东西都用默认值就好。
3. 初始化DraweeView

想要让一个Fresco图片展示，最简单的办法，只要set一下uri就搞定了：

```kotlin
image.setImageURI(uri)
```

但是这背后的原理，需要我们好好探究一下。

```java
public void setImageURI(Uri uri, @Nullable Object callerContext) {  
  DraweeController controller =  
      mControllerBuilder  
          .setCallerContext(callerContext)  
          .setUri(uri)  
          .setOldController(getController())  
          .build();  
  setController(controller);  
}
```

看代码也能知道，我就说==我明明只要set一个uri就好了，但是demo里都要我设置一个controller，然后在controller里set这个uri==。原来是Fresco的setImageUri()也是这么做的。那么，重点肯定就是，这个Controller到底是什么了。 #TODO 之后要好好研究一下。

然后，还有一个点，是这个setOldController，为什么非要设置这个东西。在我的demo里，通常是这样写的：

```kotlin
val controller = Fresco.newDraweeControllerBuilder()  
        .setImageRequest(request)  
        .setOldController(mSimpleDraweeView.controller)  
        .build()
mSimpleDraweeView.controller = controller
```

也就是说，即使我们还没设置过controller，SimpleDraweeView也有一个自带的Controller。那么它是什么， #TODO 也需要好好看看。

我们从setUri开始。在setUri方法的内部，Fresco帮我们构造好了一个ImageRequest：

```java
// PipelineDraweeControllerBuilder.java
public PipelineDraweeControllerBuilder setUri(@Nullable Uri uri) {  
  if (uri == null) {  
    return super.setImageRequest(null);  
  }  
  ImageRequest imageRequest =  
      ImageRequestBuilder.newBuilderWithSource(uri)  
          .setRotationOptions(RotationOptions.autoRotateAtRenderTime())  
          .build();  
  return super.setImageRequest(imageRequest);  
}
```

一看到Builder，立马就应该想到，ImageRequest的构造方法应该是私有的，果然，它设置成了protected：

![[Study Log/android_study/fresco/resources/Pasted image 20231105172608.png]]

那么，接下来看看这个ImageRequestBuilder生成ImageRequest的具体流程吧！

```java
/**  
 * Creates a new request builder instance. The setting will be done according to the source type. 
 * 
 * @param uri the uri to fetch  
 * @return a new request builder instance  
 */
public static ImageRequestBuilder newBuilderWithSource(Uri uri) {  
  return new ImageRequestBuilder().setSource(uri);  
}
```

这里的ImageRequestBuilder()方法是一个空方法，而setSource也很简单，就是将自己的uri属性赋值。注意这里也说了，uri既支持http，也支持本地的：

```java
/**  
 * Sets the source uri (both network and local uris are supported). Note: this will enable disk 
 * caching for network sources, and disable it for local sources. 
 * 
 * @param uri the uri to fetch the image from  
 * @return the updated builder instance  
 */
public ImageRequestBuilder setSource(Uri uri) {  
  Preconditions.checkNotNull(uri);  
  mSourceUri = uri;  
  return this;
}
```

- [ ] #TODO 这里说了如果是用的网络，会默认开启disk cache，看看这部分逻辑在哪里实现的。

这部分搞定之后，接下来它还给我们设置了一下旋转：

```java
// PipelineDraweeControllerBuilder.java
public PipelineDraweeControllerBuilder setUri(@Nullable Uri uri) {  
  if (uri == null) {  
    return super.setImageRequest(null);  
  }  
  ImageRequest imageRequest =  
      ImageRequestBuilder.newBuilderWithSource(uri)  
	      // 就是这里
          .setRotationOptions(RotationOptions.autoRotateAtRenderTime())  
          .build();  
  return super.setImageRequest(imageRequest);  
}
```

setRotationOptions的具体实现：

![[Study Log/android_study/fresco/resources/Pasted image 20231105173558.png]]

而这里默认传进去的RotationOptions.autoRotateAtRenderTime()的意思是在渲染的时候进行旋转（？？其实我也不太懂）。这里点进去看看就行了，其实就是一些参数的设置，没什么含金量。

#question/coding/practice #language/coding/java 

关于这个最后的build()方法，我觉得有必要先普及一下Java的修饰符了：

[[Article/story/2023-05-04#2. Kotlin Modifier|2023-05-04]]

对于Java的protected的方法，在当前类，子类，同一目录（包）下的类是可以访问的。而ImageRequestBuilder和ImageRequest就是在一个包下的：

![[Study Log/android_study/fresco/resources/Pasted image 20231105174925.png|300]]

所以，最后能直接new并不奇怪：

```java
// ImageRequestBuilder.java
/**  
 * Builds the Request. 
 * @return a valid image request  
 */
public ImageRequest build() {  
  validate();  
  return new ImageRequest(this);  
}
```

我当时看过NIO的SkyNet，那里面需要build的类的构造方法是私有的，是因为它直接把这个类的Builder写成了这个类的内部类，自然就不需要protected。这也算是涨了一点知识吧（我怎么现在才意识到，555）。

![[Study Log/android_study/fresco/resources/Pasted image 20231105175438.png]]

可以看到，在Builder阶段最重要的uri被传了进来，并且还获取了一下这个uri的类型，这应该就和之前说的那个disk cache有关系。

现在我们先来回顾一下，setImageUri()这个最简单但是却又很全面的方法，我们总结出了哪些东西：

![[Study Log/android_study/fresco/resources/setimgurl.svg]]

好吧，我们好像只总结了setUri()。也就是构建ImageRequest的过程，而这里面其实也都没什么有价值的东西，就是给一些参数赋值，然后用Builder构建出来的过程而已。

一切的开始，要从Fresco的initialize()说起。这里面调用了initializeDrawee()方法，构建了一个builder：

```java
sDraweeControllerBuilderSupplier =
        new PipelineDraweeControllerBuilderSupplier(context, draweeConfig);
```

那么，这个PipelineDraweeControllerBuilderSupplier是什么？它实现了Supplier接口：

```java
/**
 * A class that can supply objects of a single type. Semantically, this could be a factory,
 * generator, builder, closure, or something else entirely. No guarantees are implied by this
 * interface.
 *
 * @author Harry Heymann
 * @since 2.0 (imported from Google Collections Library)
 */
@Nullsafe(Nullsafe.Mode.STRICT)
public interface Supplier<T> {
  /**
   * Retrieves an instance of the appropriate type. The returned object may or may not be a new
   * instance, depending on the implementation.
   *
   * @return an instance of the appropriate type
   */
  T get();
}
```

看起来非常简单，类如其名，Supplier就是提供一个类的。而这个类的类型就由泛型表明。因此我们看看PipelineDraweeControllerBuilderSupplier是怎么实现的：

```java
public class PipelineDraweeControllerBuilderSupplier
    implements Supplier<PipelineDraweeControllerBuilder> 
```

看，PipelineDraweeControllerBuilderSupplier就是提供PipelineDraweeControllerBuilder的，将类名尾部的Supplier删掉，就是它提供的东西。这玩意儿是提供一个Builder的！

