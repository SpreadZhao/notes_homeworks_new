---
title: ellipsize失效的问题
date: 2023-11-25
---

# ellipsize失效的问题

#date 2023-11-25

ellipsize失效？这个问题我之前倒是从来没遇到过。不过在公司的时候遇到了。通常来讲，ellipsize在属性为end的时候是很难失效的，即使是文本行数为多行的时候。但是今天失效的原因很奇怪，我直接说结论吧：

他们用的是一个自定义的SpanableTextView，继承自AppCompatTextView。自定义这个的原因，我通过粗略的看代码看出来，大概是为了能处理emoji表情，以及在文本中加入超链接。

![[Study Log/android_study/android_dev_trouble/resources/Pasted image 20231125222729.png]]

然而，我要做的是上面这个标题，这里面顶多有个表情，也没有超链接呀！所以，我不太清楚他们为什么要用SpanableTextView而不用TextView。

然后，在这个自定义View的setText()方法里，有这样一句话：

```java
setMovementMethod(MyLinkMovementMethod.getInstance());
```

这个MyLinkMovementMethod是LinkMovementMethod的子类，看起来也是为了处理一些触摸事件所做的。

**正是这个方法，导致TextView的ellipsized属性失效了**。我中间试过无数可能：字体大小，margin，fontStyle等等，这些改了通通不会影响ellipsized，唯独这个玩意儿。这还是因为，我当时实在没办法，就把SpanableTextView换回了TextView，结果居然问题就解决了，这才意识到是这里面写出来的问题。最后又一步步排除法，才排除到这句代码上来。

解决办法呢？我看了看这个文章：

[android - Make ellipsized a TextView which has LinkMovementMethod - Stack Overflow](https://stackoverflow.com/questions/20245862/make-ellipsized-a-textview-which-has-linkmovementmethod)

感觉没啥参考价值，我也试过替换为OnTouchListener。但是无奈他自定义的这个东西里面调用了super的onTouchEvent，而OnTouchListener是个接口，它可没有super，有也不是super.onTouchEvent()里的实现。所以只能放弃。

后来，我突然想到，是不是可以这样搞：

```java
public void setPlainText(CharSequence text) {
	super.setText(text);
}
```

这样不是就行了？如果我想避开那个方法，我只需要调用这个，就不会走到原来的setText()里面了。答案是，我太天真了，这个错误其实我之前已经发现过了：

```java
public class Child extends Parent {
  @Override
  public void print() {
    super.print();
  }

  @Override
  public void realPrint() {
    System.out.println("child");
  }
}
```

```java
public class Parent {
  public void print() {
    realPrint();
  }

  public void realPrint() {
    System.out.println("parent");
  }
}
```

```java
public class Test {
  public static void main(String[] args) {
    Parent person = new Child();
    System.out.print("result: ");
    person.print();
  }
}
```

执行完Test的main之后，输出是什么？是parent还是child？这个问题就已经说明了刚才我犯的错误。person是一个Parent，但是由Child实现。所以调用print()的时候，虽然是Parent的print，但是会根据多态走到Child里的print。**但是Child里面是一个super.print()，这和我们之前的super.setText()是同一个道理**，我们希望不走Child自己的实现，走Parent的实现。然而Java不允许我们这样做：在super.print()走到Parent之后，调用了Parent的realPrint()。**但是Child也重写了这个realPrint()**，所以又会根据多态走到Child的realPrint()中。最终的结果就是`result: child`。

*所以，super.setText()最终还是会走到自己的setText()里的。。。。的吗*？

草，我突然意识到，我的想法是错误的。我只要将Parent代码改成：

```java
public class Parent {
  public void print() {
    System.out.println("parent print");
  }

  public void realPrint() {
    System.out.println("parent");
  }
}
```

结果就变成`result: parent print`了。并不是那样。这个例子中之所以会走到Child，是因为realPrint()的关系。但是setText()并没有这个过程，也就是说，我在setPlainText()里面调用super.setText()，就是TextView的setText()，不是SpanableTextView的。

那为什么依然不行呢？在我debug的时候，发现SpanableTextView的setText()依然能被调用，查看调用栈发现，是初始化的时候做的。所以我们根本没法避免这个方法被调用。

所以，最终的大招就是，再写一个SpanableTextView2，在setText()里面把那句话去掉，就没问题了。