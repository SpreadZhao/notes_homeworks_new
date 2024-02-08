[TOC]

CompletableFuture是Future的增强版，是多线程开发的利器。本文通俗易懂的介绍了CompletableFuture的用法，最后祭出CompletableFuture的一般使用范式，开箱即用，质量可靠。

# 1. 什么是CompletableFuture

```java
public class CompletableFuture<T> implements Future<T>, CompletionStage<T> {
    
}
```

* Future：代表异步计算的**结果**
* CompletionStage：代表异步计算的一个**阶段**，代表了复杂计算

从以上定义可以看出，CompletableFuture不仅实现了Future接口，还实现了CompletionStage接口，是对Future功能的增强。从Java 8开始引入了`CompletableFuture`，它针对`Future`做了改进，可以传入回调对象，当异步任务完成或者发生异常时，自动调用回调对象的回调方法。

# 2. 为什么需要CompletableFuture

使用`Future`获得异步执行结果时，要么调用阻塞方法`get()`，要么轮询看`isDone()`是否为`true`，这两种方法都不是很好，因为主线程也会被迫等待。

当需要异步回调、需要复杂计算的支持的时候，CompletableFuture也能大显身手。

# 3. 使用CompletableFuture

CompletableFuture类的方法非常多，单纯记忆很麻烦，我们需要对它进行分类

## 创建类

* **supplyAsync：异步执行，有返回值**

* runAsync：异步执行，无返回值

* anyOf：任意一个执行完成，就可以进行下一步动作
* allOf：全部完成所有任务，才可以进行下一步任务

```java
// 返回一个0
CompletableFuture.supplyAsync(() -> 0);
```

## 接续类(thenXxx)

* 接续类是CompletableFuture最重要的特性，没有这个的话，CompletableFuture就没意义了，用于注入回调行为。

* 我们知道Java 8函数式接口有4种常见类型Function、Supplier、Consumer、Runnable，好巧不巧的是CompletableFuture的续传方法也支持这4种类型的接口，一一对应关系列出如下表：

| Java 8函数式接口         | CompletableFuture的接续方法   | 说明                                  |
| ------------------------ | ----------------------------- | ------------------------------------- |
| Function（有参数有返回） | thenApply方法                 | **不使用thenApplyAsync异步**          |
| Supplier（无参数有返回） | supplyAsync方法，runAsync方法 | **在创建CompletableFuture时使用过了** |
| Consumer（有参数无返回） | thenAccept方法                | **不使用thenAcceptAsync异步**         |
| Runnable（无参数无返回） | thenRun方法                   | **不使用thenRunAsync异步**            |

* 使用thenXxx方法即可，必要使用Async后缀的异步方法。因为后一个步骤依赖前一个步骤的结果

```java
// 以异步计算1+2+3为例
CompletableFuture.supplyAsync(() -> {
    return 0;
}).thenApply(v -> {
    try { TimeUnit.SECONDS.sleep(1);} catch (InterruptedException e) { e.printStackTrace(); }
    return v + 1;
}).thenApply(v -> {
    try { TimeUnit.SECONDS.sleep(1);} catch (InterruptedException e) { e.printStackTrace(); }
    return v + 2;
}).thenApply(v -> {
    try { TimeUnit.SECONDS.sleep(1);} catch (InterruptedException e) { e.printStackTrace(); }
    return v + 3;
});
System.out.println("main线程可以异步干点别的事情，不用等待计算完成");
```

# 4. 使用CompletableFuture的一般范式

一般的，我们使用CompletableFuture就是为了使用多线程异步加快查询速度的，更多的读操作而不是写操作，所以就有必要创建多个CompletableFuture对象。

假设，在微服务架构中，需要一次性返回用户端的订单、收货地址，而这些信息分别在订单微服务、收货地址微服务中，为了快速响应用户，必然是选择开启多个线程同时查询2个微服务最后合并查询结果返回给用户。

一般的，使用以下CompletableFuture的一般范式就可以，复制粘贴开箱即用。

```java
Result result = new Result();
// <1> 查询订单
CompletableFuture<List<Order>> orderCompletableFuture = CompletableFuture.supplyAsync(() -> {
    // <1.1> http查询订单
    List<Order> orderList = queryOrderList(uid);
    // <1.2> 设置结果集
    result.setOrderList(orderList);
    return orderList;
})
// <2> 后续处理
.thenApply(v -> {
    System.out.println("此处可以继续处理...");
    return v;
});

CompletableFuture<List<Address>> addressCompletableFuture = CompletableFuture.supplyAsync(() -> {
    List<Address> addressList = queryAddressList(uid);
    result.setAddressList(addressList);
    return addressList;
});

// <3> 等待所有任务执行完成
CompletableFuture.allOf(orderCompletableFuture, addressCompletableFuture);

// <4> 记录异常信息并抛出
List<String> errMessage = new ArrayList<>();
List<CompletableFuture<?>> completableFutures = Arrays.asList(whenComplete, whenComplete1);
for (int i = 0; i < completableFutures.size(); i++) {
    CompletableFuture<?> future = completableFutures.get(i);
    int finalI = i;
    future.exceptionally(ex -> {
        String str = "列表位置索引" + finalI + "处发生异常，异常信息是" + ex.getMessage();
        errMessage.add(str);
        throw new RuntimeException("Error occurred: " + ex);
    });
}

// <5> 异常处理
if(CollUtil.isNotEmpty(errMessage)){
    log.error("计算过程发生异常，异常有{}处，异常详细信息是：{}", errMessage.size(), errMessage);
    throw new RuntimeException("存在异常，可能有多处请逐个排查，异常信息列表是" + errMessage);
}
// <6> 返回结果给用户
return result;
```

* 在`<1>`处，使用了`CompletableFuture.supplyAsync`方法，异步且有返回，这是最常用的方式

  > supplyAsync方法是异步有返回值，而runAsync是异步没有返回值，supplyAsync方法更加通用，选择它就完事了

  * 在`<1.1>`处，可以通过RestTemplate或Ribbon等等方式从订单微服务查询订单并解析
  * 在`<1.2>`处，设置订单信息到结果集中

* 在`<2>`处，可以对上一步的信息做进一步处理。**可选的。**

  > 此处可以使用thenApply、thenAccept、thenRun等方法
  >
  > 因为依赖上一步的结果，所以建议这里**都使用thenXxx方法**而没有必要使用thenXxxAsync异步方法

* 在`<3>`处，等待订单查询和地址查询都完成

* 在`<4>`处，记录异常日志并重新抛出异常。**必要的。**

  > 必须记录日志，如果不记录异常，会导致异常信息丢失

* 在`<5>`处，是否重新抛出异常。**可选的。**

  > 有的情况下，个别接口异常我们也是可以接受的，可以不抛出异常，但是必须记录异常。

* 在`<6>`处，给用户返回订单和地址的结果集