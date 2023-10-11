```markmap

- 泛型
	- Why
	- How
		- 泛型类
		- 泛型方法
		- 泛型的上界和下届
		- 类型擦除
	- 变形
		- 不变（Invariant）
		- 协变（Covariant）
		- 逆变（Contravariant）
	- Kotlin 泛型

```

# 泛型

#language/coding/java #language/coding/kotlin #question/coding/practice #question/coding/theory #rating/high #question/interview 

#TODO 

- [x] 泛型笔记

[Java基础常见面试题总结(下) | JavaGuide(Java面试 + 学习指南)](https://javaguide.cn/java/basis/java-basic-questions-03.html#%E4%BB%80%E4%B9%88%E6%98%AF%E6%B3%9B%E5%9E%8B-%E6%9C%89%E4%BB%80%E4%B9%88%E4%BD%9C%E7%94%A8)

[【每次一个技术点】为什么要用泛型_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1Z54y1f7RJ/?spm_id_from=333.337.search-card.all.click&vd_source=64798edb37a6df5a2f8713039c334afb)

## Why

如果没有泛型，比如我们想要创建一个列表，而这个列表里可以放各种元素，那么我要么给每一种类型编写一个逻辑，要么给一个父类编写这样的逻辑，并在这之后进行强转，就比如Java的Object数组。而这样的作法显然是不优雅的，所以才有了泛型。其实，Java的泛型是一个小手段，修改了编译的规则，将一些类型转换的错误**从运行时提前到了代码检查时**。这样就可以避免一些未知的隐患。

```ad-note
没有泛型，只能用Object数组（或一个父类数组） + 强转。这样很容易出现运行时异常。
```

## How

### 泛型类

首先是泛型类：

```java
public class ArrayList<E> extends AbstractList<E>
```

在类的后面加上泛型的声明，就可以在类的方法中使用这个泛型了。这里是ArrayList的实现，里面的E其实就是我们实际填的String, Integer等等。而如果想要使用，就是这样：

```java
public E get(int index) {  
	Objects.checkIndex(index, size);  
	return elementData(index);  
}
```

我们返回一个类型为E的东西，此时不知道它究竟是什么类型，但能知道的是**它和我之前构造ArrayList时填进去的类型一定是一样的，否则编译的时候就报错了**。并且，我们也没有写类似`(Object) elementData(index)`的语句，也就是说，**编译器是会自动帮我们实现类型转换的**。

如果我们想在里面添加多种泛型，那么就在`<>`里面加就好了：

```java
public class HashMap<K,V> extends AbstractMap<K,V>
```

```ad-info
title: 补充

泛型接口和泛型类的使用基本一致。
```

### 泛型方法

然后是泛型方法。这里你可能会问：*上面的get方法难道不是泛型方法吗*？不是的，它们只是普通的成员方法。而泛型方法的定义是这样的：

```java
public <T> get(T obj) {
	return ...
}
```

为啥要有泛型方法？我在类里面写上泛型，难道方法里不可以用吗？确实可以。但是，**静态方法呢**？由于静态方法根本不会属于任何一个这个类的实例，所以静态方法也不可能会持有构造这个类时填进去的类型，也就不知道它是啥。所以，静态方法如果想使用泛型，就必须定义成泛型方法。这里我们自己定义一个List来实现一下：

```java
public class MyList<T> {  
	private Object[] list;  
	  
	private int size = 0;  
	  
	public MyList(int size) {  
		this.list = new Object[size];  
		this.size = size;  
	}  
	  
	public void set(int index, T val) {  
		if (index < 0 || index >= size) {  
			return;  
		}  
		list[index] = val;  
	}  
	  
	@SuppressWarnings("unchecked")  
	public T get(int index) {  
		if (index < 0 || index >= size) {  
			throw new IndexOutOfBoundsException("Oops!");  
		}  
		return (T) list[index];  
	}  
}
```

^14755d

没什么，就是用Object数组仿照了一下ArrayList的写法，现在来使用一下：

```java
public static void main(String[] args) {  
	MyList<Integer> list1 = new MyList<>(3);  
	list1.set(0, 11);  
	list1.set(1, 22);  
	list1.set(2, 33);  
	System.out.println("0: " + list1.get(0) + ", 1: " + list1.get(1) + ", 2: " + list1.get(2));  
	MyList<String> list2 = new MyList<>(3);  
	list2.set(0, "spread");  
	list2.set(1, "zhao");  
	list2.set(2, "haha");  
	System.out.println("0: " + list2.get(0) + ", 1: " + list2.get(1) + ", 2: " + list2.get(2));  
}
```

![[Article/story/resources/Pasted image 20230726163323.png]]

这就完成了。现在，我要定义一个静态方法，输出一下这个列表里的变量。如果不写成泛型方法的话：

![[Article/story/resources/Pasted image 20230726163501.png]]

看！编译器都告诉我们，需要让这个方法变成非静态的。也就是非静态的方法本身是可以访问的：

```java
public static <E> void printList(MyList<E> list) {  
	for (int i = 0; i < list.size; i++) {  
		System.out.print(list.get(i) + " ");  
	}  
	System.out.println();  
}  
  
public void printListNotStatic(MyList<T> list) {  
	for (int i = 0; i < list.size; i++) {  
		System.out.print(list.get(i) + " ");  
	}  
	System.out.println();  
}
```

这样，我们就实现好了两个版本的方法。现在来使用一下：

```java
public static void main(String[] args) {  
	MyList<Integer> list1 = new MyList<>(3);  
	list1.set(0, 11);  
	list1.set(1, 22);  
	list1.set(2, 33);   
	list1.printListNotStatic(list1);  
	MyList<String> list2 = new MyList<>(3);  
	list2.set(0, "spread");  
	list2.set(1, "zhao");  
	list2.set(2, "haha");  
	MyList.printList(list2);  
}
```

![[Article/story/resources/Pasted image 20230726164013.png]]

### 泛型的上界和下届

[一篇文章带你搞定 Java 中受限泛型 - 掘金 (juejin.cn)](https://juejin.cn/post/6924945898384392206)

```ad-error
title: Deprecated

从这里到下面的类型擦除之间的全部内容，都可以废弃了。请读者不要将其放在心上，不然可能会对后续的阅读产生影响。
```

现在我们把MyList中的代码改一下，只改这里就可以：

```java
public class MyList<T extends Integer> {
	...
}
```

你会发现，报错了。原因也很简单。现在，MyList中的这个泛型只应该是Integer的子类。所以，我在main函数里是不可以添加String进去的；另外，在MyList中的静态方法也报错了，这是因为静态方法的参数声明也要给设置一个上界才可以：

```java
public static <E extends Integer> void printList(MyList<E> list) {  
	for (int i = 0; i < list.size; i++) {  
		System.out.print(list.get(i) + " ");  
	}  
	System.out.println();  
}
```

这就是在定义时上界的作用。~~而换到声明时，语法要稍微变一下。现在我们把修改的代码改回去，然后修改main函数~~：

```java
public static void main(String[] args) {  
	MyList<? super Constable> list1 = new MyList<>(3);  
	list1.set(0, 11);  
	list1.set(1, "haha");  
	list1.set(2, 33);  
	MyList.printList(list1);
}
```

我们将语法改成了super，并设置~~添加进去的必须是Constable的子类~~。这样我就可以同时传进去Integer和String类型的变量了。看到这里，你可能会有一头雾水，我们来梳理一下：

- [?] *为什么使用Constable*？
- ["] 很简单，Integer和String都实现了这个接口，所以可以用来测试。使用Object的结果也是一样的。

---

- [?] *为什么最后使用静态方法来打印输出，而没有用那个非静态的*？
- ["] 我们现在换成非静态的方法试一试：
  ![[Article/story/resources/Pasted image 20230726171748.png]]
  可以看到，方法中传入的参数是T，而我实际给他的是`<? super Constable>`。这实际上会导致类型溢出。根本原因是在定义类的时候我没有为这个方法做好处理。那现在问题又来了：*凭啥静态方法就没这个错误呢*？我们看一看静态方法的实现：

  ```java
  public static <E> void printList(MyList<E> list) {  
	  for (int i = 0; i < list.size; i++) {  
		  System.out.print(list.get(i) + " ");  
	  }  
	  System.out.println();  
  }
  ```

  这里使用的实际上是一个新的泛型E。**而这个泛型由于没有设置上界，所以默认是Object**。那实际上不管你传入的是什么都不会报错了。

---

- [?] *`<? extends Constable>`和`<? super Constable>`有什么区别？为什么定义类的时候用的是extends表示上界；到了构造实例的时候就变成super了*？
- ["] 这个问题也困扰了我很久。明明两个关键字是一样的，为什么它们的作用却不一样。答案是，~~前者的写法并不是在规定上界~~，**这个我们在之后的协变、逆变、和不变的时候会讨论**。

### 类型擦除

下面的代码执行结果是true：

```java
List<String> list1 = new ArrayList<>();  
List<Integer> list2 = new ArrayList<>();  
System.out.println(list1.getClass() == list2.getClass());
```

这意味着两个list实际上是同一个类，但其中的泛型并不一样。这就证明，**在运行的时候，泛型的相关信息已经被擦除了**。Java为什么要这样做呢？我们可以以ArrayList的代码作为参考：

![[Article/story/resources/Pasted image 20230726181418.png|600]]

我们发现，擦除后的代码，和jdk1.5以前的版本是一样的。而这就是泛型擦除的原因：向下兼容。因为设计者当时并没有预料到Java会引入泛型，所以才给自己埋了一个巨坑。虽然泛型擦除解决了这个问题，但给使用者带来了几个很重要的影响：

1. 泛型只支持引用类型，不支持基本类型

所有引用类型的父类都是Object，所以Java泛型擦除的规律是：**如果一个泛型设定了上界，那么擦除后这里的类型会被替换成第一个上界；如果没有指定上界，那么会被替换成Object**。从头到尾，都没有提到过基本类型的事情，因为Object本身是不能存储基本类型的信息的。所以我们才不能传基本类型进去。其实，这个问题也不大。

---

2. 不能检测带了不同泛型的同样的类的类型

这个其实就是我们一开始的例子。

---

3. 泛型无法实例化

这个问题其实在开发的时候曾经讨论过：[[Projects/android/spreadshop/work_on_spreadshop#^c00665|work_on_spreadshop]]。如果没有泛型擦除的话，改是什么类型就是什么类型，在实际运行时是完全可以知道的。所以这个缺点是完完全全的累赘，而Kotlin巧妙地用内联函数把当时的实例给搬了过来，从而绕过了这个机制。关于这个问题，可以用MyList再说明一下：

![[Article/story/resources/Pasted image 20230726182911.png|400]] ![[Article/story/resources/Pasted image 20230726183031.png|400]]

左边的写法编译报错，右边的写法会运行时错误。根本原因都是我试图构造一个类型为泛型的实例。

## 变形

我们从一个现象级的例子说起：

```java
List<Number> list1 = new ArrayList<>();  
List<Integer> list2 = new ArrayList<>();
```

我们刚刚说过，由于泛型擦除机制，Number和Integer在实际运行时都会被抹去。那我的问题是：*list1可以赋值给list2吗？list2又可以赋值给list1吗*？实验一下就可以知道，**这两个问题的答案都是不可以**！由于编译器的类型检查，使得我们不可以将两个不一样的类型做赋值操作。但是，Integer可是Number的子类呀！这意味着，至少将list2赋值给list1是合理的。。。。吗？我们看一看这篇文章：

[java generics covariance - Stack Overflow](https://stackoverflow.com/questions/2660827/java-generics-covariance)

其实也就是这样的操作：

```java
List<Number> list1 = new ArrayList<>();  
List<Integer> list2 = new ArrayList<>();  
list1 = list2;  
list1.add(2.2);
```

如果第三条语句是合理的，那可就出大问题了！第三条语句所做的操作是，**让list1指向一个List，它是一个应该只含有Integer的ArrayList，虽然类型是List\<Number\>**。这样的话，你又凭什么往这个List里面加浮点数呢？

### 不变（Invariant）

Java的泛型就是不变的。因为`List<Number>`和`List<Integer>`没有任何关系，当然也包括继承关系。所有的不变都是为了保证安全性，但同时也牺牲了便利性。比如，我们无法统一操作`List<Number>`类型的数据，然后通过多态映射到每一个子类。

### 协变（Covariant）

如果list1真的可以指向那个全是Integer的ArrayList的话，这种形式就是**协变**。协变的概念是：如果B是A的子类，那么$f(B)$也要是$f(A)$的子类。这个过程可以用Object的clone()方法来说明。在[[Study Log/kotlin_study/copy#浅拷贝和深拷贝|这篇文章]]中，我们重写了Object的clone()方法。而我们注意到，在Object中，clone()方法返回的是Object类型，而我们重写的方法返回的是User类型。而User是Object的子类，clone(User)返回的是User，clone(Object)返回的是Object，正好也是父子关系。所以这就是一种协变。

```ad-tldr
title: Q&A

这里你可能会问，clone()方法没有参数啊！你怎么传了个User还有Object进去？参数其实根本不需要真的放到参数里。clone()方法的作用就是clone()自己，所以**我们完全可以认为它传了一个this进去呀**！

[java - What is a covariant return type? - Stack Overflow](https://stackoverflow.com/questions/1882584/what-is-a-covariant-return-type#:~:text=The%20covariant%20return%20type%20in%20java%2C%20allows%20narrowing,always%20%20works%20only%20for%20non-primitive%20return%20types.)

[Java中的协变与逆变 - Modnar - 博客园 (cnblogs.com)](https://www.cnblogs.com/stevenshen123/p/9215750.html#:~:text=%E2%91%A0%20%E5%AD%90%E7%B1%BB%E5%AE%8C%E5%85%A8%E6%8B%A5%E6%9C%89%E7%88%B6%E7%B1%BB%E7%9A%84%E6%96%B9%E6%B3%95%EF%BC%8C%E4%B8%94%E5%85%B7%E4%BD%93%E5%AD%90%E7%B1%BB%E5%BF%85%E9%A1%BB%E5%AE%9E%E7%8E%B0%E7%88%B6%E7%B1%BB%E7%9A%84%E6%8A%BD%E8%B1%A1%E6%96%B9%E6%B3%95%EF%BC%9B%20%E2%91%A1%20%E5%AD%90%E7%B1%BB%E4%B8%AD%E5%8F%AF%E4%BB%A5%E5%A2%9E%E5%8A%A0%E8%87%AA%E5%B7%B1%E7%9A%84%E6%96%B9%E6%B3%95%EF%BC%9B%20%E2%91%A2%20%E5%BD%93%E5%AD%90%E7%B1%BB%E8%A6%86%E7%9B%96%E6%88%96%E5%AE%9E%E7%8E%B0%E7%88%B6%E7%B1%BB%E7%9A%84%E6%96%B9%E6%B3%95%E6%97%B6%EF%BC%8C%E6%96%B9%E6%B3%95%E7%9A%84%E5%BD%A2%E5%8F%82%E8%A6%81%E6%AF%94%E7%88%B6%E7%B1%BB%E6%96%B9%E6%B3%95%E7%9A%84%E6%9B%B4%E5%8A%A0%E5%AE%BD%E6%9D%BE%EF%BC%9B,%E2%91%A3%20%E5%BD%93%E5%AD%90%E7%B1%BB%E8%A6%86%E7%9B%96%E6%88%96%E5%AE%9E%E7%8E%B0%E7%88%B6%E7%B1%BB%E7%9A%84%E6%96%B9%E6%B3%95%E6%97%B6%EF%BC%8C%E6%96%B9%E6%B3%95%E7%9A%84%E8%BF%94%E5%9B%9E%E5%80%BC%E8%A6%81%E6%AF%94%E7%88%B6%E7%B1%BB%E6%96%B9%E6%B3%95%E7%9A%84%E6%9B%B4%E5%8A%A0%E4%B8%A5%E6%A0%BC%E3%80%82%20%E9%92%88%E5%AF%B9LSP%E5%9B%9B%E5%B1%82%E5%90%AB%E4%B9%89%E7%9A%84%E2%91%A2%E2%91%A3%E6%9D%A1%EF%BC%8C%E5%B0%B1%E5%BC%95%E5%87%BA%E4%BA%86%E5%8D%8F%E5%8F%98%20%28Covariance%29%E5%92%8C%E9%80%86%E5%8F%98%20%28Contravariance%29%E7%9A%84%E6%A6%82%E5%BF%B5%EF%BC%9A%20%E5%8D%8F%E5%8F%98%EF%BC%8C%E7%AE%80%E8%A8%80%E4%B9%8B%EF%BC%8C%E5%B0%B1%E6%98%AF%E7%88%B6%E7%B1%BB%E5%9E%8B%E5%88%B0%E5%AD%90%E7%B1%BB%E5%9E%8B%EF%BC%8C%E5%8F%98%E5%BE%97%E8%B6%8A%E6%9D%A5%E8%B6%8A%E5%85%B7%E4%BD%93%EF%BC%8C%E5%9C%A8Java%E4%B8%AD%E4%BD%93%E7%8E%B0%E5%9C%A8%E8%BF%94%E5%9B%9E%E5%80%BC%E7%B1%BB%E5%9E%8B%E4%B8%8D%E5%8F%98%E6%88%96%E6%9B%B4%E5%8A%A0%E5%85%B7%E4%BD%93%20%28%E5%BC%82%E5%B8%B8%E7%B1%BB%E5%9E%8B%E4%B9%9F%E6%98%AF%E5%A6%82%E6%AD%A4%29%E7%AD%89%E3%80%82)
```

在泛型中，我们可以认为，`List<User>` 这样的类型，就是将User作为参数，返回的一个类型。所以，如果想要泛型支持协变的话，需要满足如下条件：

* `Child`是`Parent`的子类；
* `List<Child>`是`List<Parent>`的子类。

这两个条件很好理解。但是，Child和Parent到底都是什么呢？至少我们知道，不可能是像Number和Integer那样。而答案，其实我们在之前讨论上下界的时候就提到过了，也就是`<? extends Constable>`和`<? super Constable>`。这两个关键字可以让泛型支持协变和逆变，我们现在需要的就是前者。现在来修改代码吧：

```java
List<? extends Number> list1 = new ArrayList<>();  
List<Integer> list2 = new ArrayList<>();  
list1 = list2;
```

现在，list1可以指向list2了，因为我们强行让list1支持了协变。但是，就像刚才提到的，如果它支持了协变的话，我之后再往里面添加一个不是Integer的元素不就出问题了？所以，为了应对这个问题，Java选择了一刀切：**任何支持协变的泛型集合，都只能是只读的（它是如何实现的呢？请继续看下去）**。所以，我们其实已经无法向list1中添加任何元素了，无论是Integer还是Float还是其它： ^01a511

![[Study Log/java_study/resources/Pasted image 20230727155523.png|500]]

那问题又来了：只读不写，那你这个东西还有啥用啊？你别说，还真有点用，其中最大的用处其实就是协变的本身：多态。在刚才QA中的那个参考文档：[Java中的协变与逆变 - Modnar - 博客园 (cnblogs.com)](https://www.cnblogs.com/stevenshen123/p/9215750.html#:~:text=%E2%91%A0%20%E5%AD%90%E7%B1%BB%E5%AE%8C%E5%85%A8%E6%8B%A5%E6%9C%89%E7%88%B6%E7%B1%BB%E7%9A%84%E6%96%B9%E6%B3%95%EF%BC%8C%E4%B8%94%E5%85%B7%E4%BD%93%E5%AD%90%E7%B1%BB%E5%BF%85%E9%A1%BB%E5%AE%9E%E7%8E%B0%E7%88%B6%E7%B1%BB%E7%9A%84%E6%8A%BD%E8%B1%A1%E6%96%B9%E6%B3%95%EF%BC%9B%20%E2%91%A1%20%E5%AD%90%E7%B1%BB%E4%B8%AD%E5%8F%AF%E4%BB%A5%E5%A2%9E%E5%8A%A0%E8%87%AA%E5%B7%B1%E7%9A%84%E6%96%B9%E6%B3%95%EF%BC%9B%20%E2%91%A2%20%E5%BD%93%E5%AD%90%E7%B1%BB%E8%A6%86%E7%9B%96%E6%88%96%E5%AE%9E%E7%8E%B0%E7%88%B6%E7%B1%BB%E7%9A%84%E6%96%B9%E6%B3%95%E6%97%B6%EF%BC%8C%E6%96%B9%E6%B3%95%E7%9A%84%E5%BD%A2%E5%8F%82%E8%A6%81%E6%AF%94%E7%88%B6%E7%B1%BB%E6%96%B9%E6%B3%95%E7%9A%84%E6%9B%B4%E5%8A%A0%E5%AE%BD%E6%9D%BE%EF%BC%9B,%E2%91%A3%20%E5%BD%93%E5%AD%90%E7%B1%BB%E8%A6%86%E7%9B%96%E6%88%96%E5%AE%9E%E7%8E%B0%E7%88%B6%E7%B1%BB%E7%9A%84%E6%96%B9%E6%B3%95%E6%97%B6%EF%BC%8C%E6%96%B9%E6%B3%95%E7%9A%84%E8%BF%94%E5%9B%9E%E5%80%BC%E8%A6%81%E6%AF%94%E7%88%B6%E7%B1%BB%E6%96%B9%E6%B3%95%E7%9A%84%E6%9B%B4%E5%8A%A0%E4%B8%A5%E6%A0%BC%E3%80%82%20%E9%92%88%E5%AF%B9LSP%E5%9B%9B%E5%B1%82%E5%90%AB%E4%B9%89%E7%9A%84%E2%91%A2%E2%91%A3%E6%9D%A1%EF%BC%8C%E5%B0%B1%E5%BC%95%E5%87%BA%E4%BA%86%E5%8D%8F%E5%8F%98%20%28Covariance%29%E5%92%8C%E9%80%86%E5%8F%98%20%28Contravariance%29%E7%9A%84%E6%A6%82%E5%BF%B5%EF%BC%9A%20%E5%8D%8F%E5%8F%98%EF%BC%8C%E7%AE%80%E8%A8%80%E4%B9%8B%EF%BC%8C%E5%B0%B1%E6%98%AF%E7%88%B6%E7%B1%BB%E5%9E%8B%E5%88%B0%E5%AD%90%E7%B1%BB%E5%9E%8B%EF%BC%8C%E5%8F%98%E5%BE%97%E8%B6%8A%E6%9D%A5%E8%B6%8A%E5%85%B7%E4%BD%93%EF%BC%8C%E5%9C%A8Java%E4%B8%AD%E4%BD%93%E7%8E%B0%E5%9C%A8%E8%BF%94%E5%9B%9E%E5%80%BC%E7%B1%BB%E5%9E%8B%E4%B8%8D%E5%8F%98%E6%88%96%E6%9B%B4%E5%8A%A0%E5%85%B7%E4%BD%93%20%28%E5%BC%82%E5%B8%B8%E7%B1%BB%E5%9E%8B%E4%B9%9F%E6%98%AF%E5%A6%82%E6%AD%A4%29%E7%AD%89%E3%80%82)已经告诉了我们，协变的来源其实就是里氏替换原则。其中的第四条是：**当子类覆盖或实现父类的方法时，方法的返回值要比父类方法的更加严格**。就像一开始举的clone()的例子，在子类中返回的是父类中的儿子，自然是越来越严格。所以，如果我们有一个方法：

```java
public static void printList(List<? extends Number> list) {  
	list.forEach(System.out::println);  
}
```

这段代码就可以接受任何继承自Number的List：

```java
List<Double> list1 = List.of(2.2, 3.3, 4.4);  
List<Integer> list2 = List.of(1, 2, 3);  
printList(list1);  
printList(list2);
```

而如果我们只是接受Number的话，这里一定是会报错的。

另外还要强调一个重点，就是这样做带来的后果。我们在[[#^14755d|MyList]]中定义一个方法：

```java
public boolean contains(T t) {  
	return true;  
}
```

然后我们在测试类中调用一下：

```java
MyList<? extends Number> list = new MyList<>(5);  
list.contains(3);
```

又报错了，为什么？在定义这个类时，我们声明的类型是T，在实际构造的时候，我们给的类型是? extends Number，也就是说T就是? extends Number。而contains()函数需要的参数也是T，证明我们需要传入一个? extends Number的类型进去。然而由于它只读不写的特性，我们无法用任何方式将其它类型转换成? extends Number。

```ad-note
这里你可能又会有问题：它是咋实现只读不写的？我在contains()方法里也根本没写它呀！凭啥这种情况你不能推导出来呢？实际情况是，? extends Number这种写法叫做Wildcard，这种类型**只能在形参里面使用**，否则就会报出这样的错误：

![[Study Log/java_study/resources/Pasted image 20230727164033.png]]

所以，这里的“只读不写”其实不太恰当，**真实情况远比只读不写要严格得多**。这里的情况和[[#^01a511|之前]]我们不能向集合中添加元素的问题是同一个。
```

这样的结果，也印证了JDK中的一个设计。我们来看看Collection类：

```java
public interface Collection<E> extends Iterable<E> {
	... ...
	boolean add(E e);
	boolean remove(Object o);
	boolean contains(Object o);
	... ...
}
```

这三个方法，**操作的都是Collection中填进去的泛型**。有意思的是，add方法是泛型，而remove和contains都是Object。为什么？其实就是因为上面的错误。如果remove和contains也声明了泛型，那我实际构造的时候，如果弄一个：

```java
Collection<? extends Number> collection = new ArrayList<>();  
collection.contains(3);
```

这样，contains方法就不会报错了，而add方法会报错，也就**正好迎合了“只读不写”的要求**。所以，我们自己在定义这样的类时，应该遵循这个原则，实现出类似的“只读不写”特性。

```ad-warning
title: 注意

`remove`和`contains`都是确保不会修改这个集合的方法。只有这种方法才能采用这种设计。
```

除了多态，泛型的协变还有一个比较重要的好处：**可以访问上界的方法**。这是因为，在类型擦除时，如果没有上界，就变成Object了；而有了上界，就只会变成第一个上界。所以编译器是允许我们调用其中的方法的：

![[Study Log/java_study/resources/Pasted image 20230727165552.png]]

---

下面，要讲一个Java中的例外：数组。Java的数组是支持协变的：[java - Why are arrays covariant but generics are invariant? - Stack Overflow](https://stackoverflow.com/questions/18666710/why-are-arrays-covariant-but-generics-are-invariant)。当把一个类型操作成数组时，父类数组依然是子类数组的父类。这样就导致我们会写这样的代码：

![[Study Log/java_study/resources/Pasted image 20230727165900.png]]

那么接下来，出一道题，这也是一道比较经典的面试题：

```java
String[] a = new String[2];
Object[] b = a;
a[0] = "hi";
b[1] = Integer.valueOf(42);
```

由于数组支持协变，我们完全可以让b指向一个String数组，因为由于协变，**String数组就是Object数组的子类**。但是，我们往里面加了一个Integer，那就会在运行时报错了。而如果我们禁止了数组的协变，那么在第二行其实就会报错了。

```ad-info
title: 注意

在泛型方法一章，我们
```

### 逆变（Contravariant）

现在我们回到之前的一个问题：让List里面可以添加不同类型的元素。当时我们是这样做的：

```java
MyList<? super Constable> list1 = new MyList<>(3);  
list1.set(0, 11);  
list1.set(1, "haha");  
list1.set(2, 33);
```

为什么这么做不报错呢？我们来画一个图：

![[Study Log/java_study/resources/Drawing 2023-07-27 17.27.34.excalidraw.png]]

我们现在向集合中加入的是Constable的子类，而如果我们把它换成父类：

![[Study Log/java_study/resources/Pasted image 20230727172958.png]]

为啥会报错？难道逆变不是可以传Number（Constable也是一样）的父类吗？如果你这么认为，那和当时的我一样，混淆了一个概念：**参数类型和接收的类型**。之前在说? extends Number的时候，我们是这么做的：

```java
List<? extends Number> list1 = new ArrayList<>();  
List<Integer> list2 = new ArrayList<>();  
list1 = list2;
```

现在我们把extends换成Super试试：

![[Study Log/java_study/resources/Pasted image 20230727173403.png]]

然后，我们把Integer换成Object试试：

![[Study Log/java_study/resources/Pasted image 20230727173428.png]]

不报错了！现在你应该明白参数类型和接收类型的区别了。后者其实是**改变引用的指向**。而协变和逆变，最根本的特性就是这个指向。现在，list1可以指向任何以Number为**下界**的List，也就是只要泛型里是Number的父类，都可以。那么这样有什么用呢？当然就是一开始说的呀！

![[Study Log/java_study/resources/Drawing 2023-07-27 17.37.36.excalidraw.png]]

我们设置了一个下界Constable，意味着这个类型只能**指向**类型为Constable父类的集合，这也就意味着，我向这个集合中添加Constable及其子类的元素，是**百分百安全的**！而这也就是不报错的根本原因。

相对的，在协变中，我们设置了一个上界Constable，意味着这个类型只能**指向**类型为Constable子类的集合，这也就意味着，我向这个集合中添加**任何**类型都是不安全的。因为**这个子类有多子**，我在运行前是完全不知道的。

所以，协变和逆变虽然长得像，所做的事情像，但**它们的目的是完完全全不同的**。协变是为了多态，向子类兼容；而逆变是为了让当前的集合更加具有包容性，能接收（这里说添加、操作更好）更多的类型。有多多呢？**下界之下，All OK**！

**以上，就是我对于泛型逆变，协变以及不变的全部理解。而以上的三段，就是我对于这些理解概括出来的总结**。

```ad-warning
title: 注意

协变，逆变，不变都不是为了泛型而存在的！！！它们只是一种编程的规范，而Java正是为了迎合这些编程规范才设计了这些乱七八糟的东西。
```

## Kotlin 泛型

Kotlin的泛型和Java中的模式完全一样，只不过语法上有变化。我们现在来看一看：

定义一个泛型类，里面含有泛型方法：

```kotlin
class MyList2<T>(  
val size: Int  
) {  
	private var list: Array<Any>? = null  
	
	init {  
		list = Array(size) { 0 }  
	}  
	
	fun set(index: Int, value: T) {  
		list?.let { it[index] = value as Any }  
	}  
	
	fun get(index: Int): T {  
		return list!![index] as T  
	}  
	
	companion object {  
		@JvmStatic  
		fun <E> print(l: MyList2<E>) {  
			for (i in 0 until l.size) {  
				print("${l.get(i)} ")  
			}  
		}  
	}  
	
}
```

使用这个类：

```kotlin
val list = MyList2<Int>(3)  
list.set(0, 11)  
list.set(1, 22)  
list.set(2, 33)  
MyList2.print(list)
```

在定义中设置泛型的上界：

```kotlin
class MyList2<T : Number>  // Class
fun <E : Number> print(l: MyList2<E>)  // Method
```

```ad-warning
title: 这里再次强调一下！

在定义类时设置上届，和在构造时设置上界有着一样的效果。而这也是我废弃掉之前代码的原因。在定义类时只能设置上界；在构造时都可以设置。
```

然后就是协变与逆变。在Kotlin中：

* `out`对应关键字`extends`，都是“从...出来”的意思；
* `in`对应关键字`super`。这里我认为`in`在语义上更加适合，in本身就含有“在...之内”的意思，也就是说，在声明的类之内，都是安全区域，可以随意操作，添加，调用方法。

```kotlin
fun main() {
	// Covariant  
	var list1: ArrayList<out Number> = ArrayList()  
	val list2 = ArrayList<Int>()  
	list1 = list2  
	  
	  
	val list3 = arrayListOf(3, 4, 5)  
	val list4 = arrayListOf(3.3, 4.4, 5.5)  
	// 两个方法都正确输出
	printList(list3) 
	printList(list4)  
	  
	// Contravariant  
	var list5: ArrayList<in Number> = ArrayList()  
	val list6 = ArrayList<Any>()  
	list5 = list2  // 编译错误
	list5 = list6  // 编译通过
	// Int和Double都可以添加
	list5.add(1)  
	list5.add(1.1)  
}  
  
fun printList(list: ArrayList<out Number>) {  
	list.forEach { print("$it ") }  
}
```

最后说一点。你可能会感觉这篇文章里的某些代码实际没有什么意义。比如为什么要让list1的类型是`ArrayList<out Number>`。这样做确实没什么意义，通常协变和逆变都是在参数中出现才能发挥大作用的。就像这篇文章提到的：

[Generics](https://kotlinlang.org/docs/generics.html)

```kotlin
fun fill(dest: Array<in String>, value: String) { ... }
```

这才是它们更加常用的地方，有了上面的函数，你就可以这样调用：

```kotlin
val dest = Array<Any>(5) { }  
fill(dest, "haha")
```

形参是`Array<in String>`类型，它指向了一个`Array<Any>`类型。而由于逆变的存在，`Array<in String>`反而是`Array<Any>`的父类。**根据多态的规则，这样的传参是合情合理的**。

其它可以参考的文章：

* [# 扔物线Kotlin讲解学习（三）----kotlin泛型与 in，out，where，reified的点点滴滴](https://blog.csdn.net/XJ200012/article/details/122647899)