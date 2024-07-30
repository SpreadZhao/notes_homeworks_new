---
title: 泛型的实际应用
tags:
  - language/coding/java
  - language/coding/kotlin
  - question/coding/practice
date: 2024-01-01
mtrace:
  - 2024-01-01
---
定义一个IPowerfulAdder接口，用来相加两个东西，返回另一个东西。虽然没什么意思，但是我就是要练习泛型：

```java
public interface IPowerfulAdder<IN, OUT> {
  public OUT add(IN arg1, IN arg2);
}
```

那么，子类继承的时候，就可以用了。这里我先来一个任意类型作为输入，Integer作为输出的：

```java
public class AnyToIntAdder<IN extends Number> implements IPowerfulAdder<IN, Integer> {
  @Override
  public Integer add(IN arg1, IN arg2) {
    if (arg1 instanceof Double && arg2 instanceof Double) {
      return ((Double) ((Double) arg1 + (Double) arg2)).intValue();
    } else {
      return (Integer) arg1 + (Integer) arg2;
    }
  }
}
```

这里就涉及到非常多泛型的应用须知了。像我们之前介绍中的那种写法：

```java
public class ArrayList<E> extends AbstractList<E>
```

**这两个E其实不是一个东西**！前一个是在声明，说的是在我这个类的实现中，有个泛型叫E；而后一个E，表示的是这个E作为参数传递到了父类中。而我这里的写法：

```java
public class AnyToIntAdder<IN extends Number> implements IPowerfulAdder<IN, Integer> {
```

注意，父类的第二个泛型已经被固定成了Integer。也就是说，在构造AnyToIntAdder的时候，**我本身就有一种“OUT就应该是Integer”的需求**。然而，我这里却没有“IN应该是谁”的需求，所以就不用传进去。

另外，输入也肯定得是个数对吧，所以我给IN设置了一个上界，必须是Number的子类才可以。

至于具体的实现，这里我是乱写的，反正只是为了知道它怎么用而已。这里我只给两个都是Double的情况做了判断。那么下面就来测试验证一下：

```java
AnyToIntAdder<Double> adder = new AnyToIntAdder<>();
System.out.println("result: " + adder.add(1.1, 2.2));
```

这里的输出是3，就不多说了。

---

另外，再来一种所有泛型都被使用了的情况，来一个IntToStringAdder：

```java
public class IntToStringAdder implements IPowerfulAdder<Integer, String> {
  @Override
  public String add(Integer arg1, Integer arg2) {
    int res = arg1 + arg2;
    return Integer.toString(res);
  }
}
```

因为我这里不用泛型了，输入就是Integer，输出就是String，所以没必要再声明泛型了。然而，如果你还是想声明一个泛型做它用，那么这里完全可以再声明一个随意的，因为这东西本身跟你传到父类里的泛型就没啥关系。

这个类的验证是这样的：

```java
IntToStringAdder adder1 = new IntToStringAdder();
System.out.println("result2: " + adder1.add(3, 4));
```