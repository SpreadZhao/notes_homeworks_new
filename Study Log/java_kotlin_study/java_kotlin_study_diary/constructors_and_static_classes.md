---
mtrace:
  - 2023-09-01
  - 2023-11-28
title:
  - Java中的各种构造函数
  - 静态内部类
tags:
  - language/coding/java
  - constructor
  - static-internal-class
date: 2023-09-01
---
# Java中的各种构造函数

一个比较经典的问题：

```java
public class ConstructorTest {  
    class People {  
        int age;  
        String name;  
  
        static {  
            System.out.println("Static block of People");  
        }  
  
        public People() {  
            System.out.println("People()");  
        }  
  
        public People(int age, String name) {  
            System.out.println("People(age, name)");  
            this.age = age;  
            this.name = name;  
        }  
    }  
  
    class Student extends People {  
  
        int stuId;  
  
        static {  
            System.out.println("Static block of Student");  
        }  
  
  
  
        public Student() {  
            System.out.println("Student()");  
        }  
  
        public Student(int age, String name) {  
            super(age, name);  
            System.out.println("Student(age, name)");  
        }  
  
        public Student(int age, String name, int stuId) {  
            super(age, name);  
            System.out.println("Student(age, name, stuId)");  
            this.stuId = stuId;  
        }  
    }  
  
    public static void test() {  
        Student stu = new ConstructorTest().new Student();  
    }  
}
```

如果执行了test方法，会输出什么？这里需要注意一点，就是：

```java
new ConstructorTest().new Student(); 
```

参考这篇文章：[静态方法中不可直接new内部类实例对象问题_静态内部类可以new吗_华意大的博客-CSDN博客](https://blog.csdn.net/aizhihua19900214/article/details/79714235#:~:text=2%E3%80%81%E8%80%8C%E9%9D%99%E6%80%81mai,new%E5%86%85%E9%83%A8%E7%B1%BB%E4%BA%86%E3%80%82)因为Student作为ConstructorTest的内部类，在ConstructorTest的静态方法中，是无法获取到里面的成员的，**而People和Student虽然是内部类，但也算是它的成员，所以自然是获取不到的**。所以要么把People和Student给挪出去，要么像这样直接new一个类出来，然后通过这个实例再new出它的内部类。

它的结果是这样的：

```
Static block of People
Static block of Student
People()
Student()
```

也就是说，执行的顺序是：

```mermaid
graph LR
父类静态代码块 --> 子类静态代码块 --> 父类构造 --> 子类构造
```

而如果我们再添加上非静态代码块：

```java
public class ConstructorTest {  
    class People {  
        int age;  
        String name;  
  
        static {  
            System.out.println("Static block of People");  
        }  
        {  
            System.out.println("Non-static block of People");  
        }  
  
        public People() {  
            System.out.println("People()");  
        }  
  
        public People(int age, String name) {  
            System.out.println("People(age, name)");  
            this.age = age;  
            this.name = name;  
        }  
    }  
  
    class Student extends People {  
  
        int stuId;  
  
        static {  
            System.out.println("Static block of Student");  
        }  
        {  
            System.out.println("Non-static block of Student");  
        }  
  
  
        public Student() {  
            System.out.println("Student()");  
        }  
  
        public Student(int age, String name) {  
            super(age, name);  
            System.out.println("Student(age, name)");  
        }  
  
        public Student(int age, String name, int stuId) {  
            super(age, name);  
            System.out.println("Student(age, name, stuId)");  
            this.stuId = stuId;  
        }  
    }  
  
    public static void test() {  
        Student stu = new ConstructorTest().new Student();  
    }  
}
```

这次的结果是这样的：

```
Static block of People
Static block of Student
Non-static block of People
People()
Non-static block of Student
Student()
```

也就是说，**代码块是在构造函数之前调用的**。而实际上，它们在java中叫做Initializer：

[A Guide to Java Initialization | Baeldung](https://www.baeldung.com/java-initialization)

这篇文章有介绍这种单纯的代码块，~~其实我们几乎完全用不到这个特性。反而是kotlin里的init比较常用~~（<label class="ob-comment" title="为我的无知道歉" style=""> 为我的无知道歉 <input type="checkbox"> <span style=""> Initializer的作用是啥？很简单，就和它的名字一样，它是专门用来初始化静态成员的。因为静态成员的初始化逻辑可能很耗时，所以可以直接将这坨逻辑塞到里面用来初始化。自然，这里面是能调用静态方法的。 </span></label>。。。 #date 2023-11-28）。

现在，我们来观察另一个特点。看看Student的无参构造：

```java
public Student() {  
	System.out.println("Student()");  
}  
```

并没有`super()`对吧！然而我们在执行的时候，却看到了：

```
Static block of People
Static block of Student
People()  // 我可没写super啊？！
Student()
```

这就意味着，**当我们在构造子类的时候，没有显示地调用父类的构造方法，也就是`super(xxx)`时，会默认调用父类的无参构造`super()`**。

下面，我们修改一下Student的无参构造，来把`super()`给覆盖掉：

```java
public Student() {  
    super(1, "spread");  
    System.out.println("Student()");  
}
```

这下，我们强行让Student调用了父类的两个参数的构造方法。看看结果是怎样：

```
Static block of People
Static block of Student
Non-static block of People
People(age, name)  // 修改成功！！！
Non-static block of Student
Student()
```

可以看到，我们已经强行调用了父类的两个参数的构造方法。

```ad-note
其实，任何子类在构造的时候，都必须调用，且只能调用**一个**父类的构造方法。也就是用`super()`显式地指出来。并且它**还必须是子类构造方法的第一句**；如果我们不写`super()`的话，会自动给我们调用父类的无参构造。
```

举一反三，既然我们可以让Student的无参构造调用父类的双参数构造，自然也可以让Student的双参数构造调用父类的无参数构造。因为只需要调用任意一个父类的构造就可以了嘛！而方法也很简单：**删掉`super`不就行了**？

```java
public Student(int age, String name) {  
    System.out.println("Student(age, name)");  
}
```

现在我们执行一下子类的双参数构造：

```java
public static void test() {  
    Student stu = new ConstructorTest().new Student(2, "zhao");  
}
```

结果也自然可以推出来：

```
Static block of People
Static block of Student
Non-static block of People
People()
Non-static block of Student
Student(age, name)
```

# 静态内部类

> [!stickies]
> 关于静态内部类最重要的一点：静态的内部类允许我们在外面直接new；非静态的内部类必须new出外部类才能new。

在刚才的那篇文章中：

[静态方法中不可直接new内部类实例对象问题_静态内部类可以new吗_华意大的博客-CSDN博客](https://blog.csdn.net/aizhihua19900214/article/details/79714235#:~:text=2%E3%80%81%E8%80%8C%E9%9D%99%E6%80%81mai,new%E5%86%85%E9%83%A8%E7%B1%BB%E4%BA%86%E3%80%82)

提到了静态内部类的东西。而在这篇文章中有更详细的说明：

[Static class in Java - GeeksforGeeks](https://www.geeksforgeeks.org/static-class-in-java/)

文中提到了：

* 静态内部类在构造的时候不需要构造外部类的实例；
* 内部类可以访问到外部类的静态和非静态成员；而静态内部类只能访问外部类的静态成员。

> [!warning] Kotlin中的静态内部类
> [kotlin静态内部类和java静态内部类的区别_kotlin 静态内部类_沙漠一只雕得儿得儿的博客-CSDN博客](https://blog.csdn.net/cpcpcp123/article/details/110825084)
> 
> 千万要注意：Kotlin中的静态内部类就是class，而非静态内部类是inner class。看下面的例子，加上了inner之后，在静态方法中无法创建。这正对应了上面的第一条。不报错的时候，就是构造静态内部类的时候。
> 
> ![[Study Log/java_kotlin_study/resources/idea64_o91GamPVcq.gif]]
> 
> 而如果我们想要构造出内部类，需要先构造出外部的类的实例：
> 
> ![[Study Log/java_kotlin_study/resources/idea64_hINz9VwptT.gif]]
> 
> #date 2023-11-29
> 
> 可以这样理解：`inner`关键字的作用就是，构造的时候必须从外到内全部有实例才行，这其实就像一个成员属性一样，必须有外部类的实例才能访问，所以不是静态的。而不带`inner`的class就相当于java的`static class`。