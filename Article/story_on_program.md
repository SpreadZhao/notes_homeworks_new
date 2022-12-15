# 2022-11-1

今天偶然在群里看到有人问了个这样的问题：

![[RKQ]@K)LS$3~68]K9VDRXCQ.jpg]]

这里为什么会产生段错误呢？我立刻想到了[[os#^467bf0|操作系统中对段错误的描述]]。但是想了想却总是感觉不太对，直到我看到了这篇文章：

[输出char*的指针时为什么会发生段错误_51CTO博客_为什么char类型会输出问号](https://blog.51cto.com/u_13563176/4579500)

恍然大悟！原来是ASCII码！**这里产生seg fault的原因是，单个字符赋值的时候会解析成ASCII码，所以这句话相当于让p这个指针指向`\0`字符的ASCII码对应的虚拟地址上，在虚地址空间中这肯定是非法空间，所以os给他杀掉了，就产生了段错误**。。。。。吗？

好吧，是我错了，等我调试了一遍这个程序才发现其中的问题：

![[Pasted image 20221101162035.png]]

首先可以确定的是，`abcde`作为一个字符串常量，是放在静态数据区(数据段)里的。而p指向的正是这样一块内存。**而之后我们企图对p指向的内存进行修改，也就是要修改数据段**，这在c程序中是绝对不允许的，所以这也是一种非法访问，被操作系统检测到并杀掉了这个进程，产生了段错误。

而上面文章中，和我的os笔记中，确实是一类问题。看这个代码：

```c
#include <stdio.h>
int main()
{
	char* p1 = 1;          
	char* p2 = '1';
    printf("p1 = %c\n", *p1);  //段错误 
	printf("p2 = %c\n", *p2);  //段错误
    return 0;
}
```

这里的`char *p2 = '1';`就是在让p2去指向'1'的ASCII码对应的地址，因此这里是对虚地址的低地址进行访问，也是一种非法访问。

# 2022-11-30

**java为啥只有值传递**？这里先给一个非常简单的例子：

```java
public class Main {  
    public static void main(String[] args) {  
        int a = 0;  
        System.out.println("修改之前，a是：" + a);  
        // 调用changeToFive，企图把a改成5  
        changeToFive(a);  
        System.out.println("修改之后，a是：" + a);  
    }  
  
    public static void changeToFive(int num){  
        num = 5;  
    }  
}
```

执行结果也显而易见：

```shell
修改之前，a是：0
修改之后，a是：0
```

但是我们将这个int变成一个非基本类型Person：

```java
public class Main {  
    public static void main(String[] args) {  

		... ...

        Person person = new Person();  
        System.out.println("修改之前，person的年龄：" + person.age);  
        // 调用changeToFive，企图修改person的年龄  
        changeToFive(person);  
        System.out.println("修改之后，person的年龄：" + person.age);  
    }  
  
    public static void changeToFive(int num){  
        num = 5;  
    }  
    public static void changeToFive(Person p){  
        p.age = 5;  
    }  
}  
  
class Person{  
    public int age = 0;  
}
```

```shell
修改之前，a是：0
修改之后，a是：0
修改之前，person的年龄：0
修改之后，person的年龄：5
```

我们发现，**在方法中对非基本类型的成员进行修改时，是可以做到的**。那为什么这样






就行呢？我们再进行实验，不修改person的年龄，而是直接给一个新的Person：

```java
public class Main {  
    public static void main(String[] args) {  

		... ...
  
        // 调用newPerson，直接把参数变成一个新person  
        newPerson(person);  
        System.out.println("再次修改之后，person的年龄：" + person.age);  
    }  
  
    public static void changeToFive(int num){  
        num = 5;  
    }  
    public static void changeToFive(Person p){  
        p.age = 5;  
    }  
  
    public static void newPerson(Person p){  
        p = new Person(10);  
    }  
}  
  
class Person{  
    public int age = 0;  
  
    Person(){}  
  
    Person(int age){  
        this.age = age;  
    }  
}
```

在newPerson方法中，我们创建了一个新的Person，并把年龄设置成10。我们企图将当前的person的年龄由5修改成10。但是结果却是这样的：

```shell
修改之前，a是：0
修改之后，a是：0
修改之前，person的年龄：0
修改之后，person的年龄：5
再次修改之后，person的年龄：5
```

这样的结果和我们最开始int的情况一模一样。那么为什么**对非基本类型数据的成员进行修改时能成立**呢？这就要画出第二种情况的jvm图示了：

![[Excalidraw/Drawing 2022-11-30 11.18.52.excalidraw]]

我们创建出来的实例本身是存放在堆空间中的；而person(实参)和p(形参)只不过是指向这个实例的引用。因此，无论对它们俩谁进行修改，都修改的是同一个实例。

但是在最后一种情况中，就变成了这样：

![[Excalidraw/Drawing 2022-11-30 11.22.23.excalidraw]]

一开始person和p都指向同一个实例，年龄是5；但是执行了这句话之后：

```java
p = new Person(10);
```

p就指向了另一个实例。而这个函数执行完之后p和Another instance都会被java干掉，所以再输出person的年龄时结果就肯定是5了。

综上所述，看似修改了实参，但那只是被表象蒙蔽的结果。实际上还是由于**java复制了一份能指一块儿去的形参**而已。

---

上面的例子中，注意到两个类有这样的区别：

```java
public class Main{
	... ...
}

class Person{
	... ...
}
```

如果把Person前面也加上public，会报这样的错误：

```
Class 'Person' is public, should be declared in a file named 'Person.java'
```

为什么？是因为类的作用域。带有public的类，能在整个工程下找到，也就是包的外面也能访问。这也是为什么我在工程下建了一个model包，里面的类在MainActivity类里也能访问到的原因；而前面如果不加public，表示这个类只能在当前包下面访问到，出了这个包就访问不到了：

![[Article/resources/Pasted image 20221130113301.png]]

---

然后是String不可变的问题。有如下代码：

```java
List<String> list = new ArrayList<>();  
list.add("haha");  
list.add("hehe");  
list.forEach(System.out::println);  
  
list.set(0, "SpreadZhao");  
System.out.println("After change to SpreadZhao: ");  
list.forEach(System.out::println);
```

我们创建了一个数组，haha和hehe；之后循环输出一下；再之后把第一个元素改成SpreadZhao；最后再输出一下。由于使用的是自带的set方法，所以修改必定是成功的：

```shell
haha
hehe
After change to SpreadZhao: 
SpreadZhao
hehe
```

但是如果我们这样写：

```java
for(String elem : list){  
    elem = "SpreadZhao";  
}  
System.out.println("After change All to SpreadZhao");  
list.forEach(System.out::println);
```

我们企图**使用for循环**将列表中所有的元素都改成SpreadZhao，会发现结果是这样的：

```shell
After change All to SpreadZhao
SpreadZhao
hehe
```

并没有改动。为什么？看一看循环中的输出：

```java
for(String elem : list){  
    elem = "SpreadZhao";  
    System.out.println("elem: " + elem);  
}  
System.out.println("After change All to SpreadZhao");  
list.forEach(System.out::println);
```

```shell
elem: SpreadZhao
elem: SpreadZhao
After change All to SpreadZhao
SpreadZhao
hehe
```

循环里确实改了；但是外面却没改。这也是类似形参和实参的问题。由于循环中的elem只是通过调用list的get方法得到的实体，这个实体和list本身指向的是同一个字符串常量；但是我们执行了这句话后：

```java
elem = "SpreadZhao";
```

只不过是让这个临时的elem指向了一个新字符串常量而已，原来list中的那个元素并没有指向新的字符串常量，因此这里的修改是无效的。