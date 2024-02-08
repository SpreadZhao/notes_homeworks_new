[TOC]

# 1. 什么是ABA问题

如果另一个线程把值A，先修改为B，再修改为A。当前线程看到的值还是A，并不知道值中间是否发生过变化。这就是ABA问题。

举个🌰：在你非常渴的情况下你发现一个盛满水的杯子，你一饮而尽。之后再给杯子里重新倒满水。然后你离开，当杯子的真正主人回来时看到杯子还是盛满水，他当然不知道是否被人喝完重新倒满。

我们考虑下面一种ABA的情况：

1. 在多线程的环境中，线程a从共享的地址X中读取到了对象A。
2. 在线程a准备对地址X进行更新之前，线程b将地址X中的值修改为了B。
3. 接着线程b将地址X中的值又修改回了A。
4. 最新线程a对地址X执行CAS，发现X中存储的还是对象A，对象匹配，CAS成功。

AtomicInteger无法解决ABA问题的代码如下：

```java
private static void aba() throws InterruptedException {
    CountDownLatch latch = new CountDownLatch(2);
    AtomicInteger atomicInteger = new AtomicInteger(100);
    new Thread(() -> {
        System.out.println("当前线程是t1，初始值是：" + atomicInteger.get());
        try { TimeUnit.SECONDS.sleep(1);} catch (InterruptedException e) { e.printStackTrace(); }
        atomicInteger.compareAndSet(100, 200);
        System.out.println("当前线程是t1，值是：" + atomicInteger.get());
        atomicInteger.compareAndSet(200, 100);
        System.out.println("当前线程是t1，值是：" + atomicInteger.get());
        latch.countDown();
    }, "t1").start();

    new Thread(() -> {
        System.out.println("当前线程是t2，初始值是：" + atomicInteger.get());
        // 睡眠2秒让线程t1发生ABA问题
        try { TimeUnit.SECONDS.sleep(2);} catch (InterruptedException e) { e.printStackTrace(); }
        atomicInteger.compareAndSet(100, 300);
        System.out.println("当前线程是t2，值是：" + atomicInteger.get());
        latch.countDown();
    }, "t2").start();
    latch.await();
    System.out.println("最终值是：" + atomicInteger.get() + "，会发现AtomicInteger没办法解决ABA问题");
}
```

* t1线程把atomicInteger值先由100更新为200，再由200更新为100，目的是模拟发生了aba问题
* t2线程在等待t1线程发生aba问题的前提下，还是可以正常更新原子值。没有解决aba问题

# 2. 如何解决ABA问题

有的情况，只要现在的值跟原始值保持一致就可以，并不在乎中间是否发生过变化，这种情况就不需要解决ABA问题。但是，也有的情况，很在乎值中间是否发生过变化，这就需要解决ABA问题。

**解决ABA问题的通常手段就是用版本号，对应到Java中就是Stamp（戳）**

AtomicStampedReference通过邮戳版本号解决ABA问题的代码如下：

```java
private static void abaResolve() throws InterruptedException {
    CountDownLatch latch = new CountDownLatch(2);
    AtomicStampedReference<Integer> num = new AtomicStampedReference(100, 1);

    new Thread(() -> {
        Integer source = num.getReference();
        Integer abaTmpValue = new Integer(200);
        System.out.println("当前线程是t3，初始版本号是：" + num.getStamp());
        try { TimeUnit.SECONDS.sleep(1);} catch (InterruptedException e) { e.printStackTrace(); }
        boolean b = num.compareAndSet(source, abaTmpValue, num.getStamp(), num.getStamp() + 1);
        System.out.println("compareAndSet是否成功：" + b + "，当前线程是t3，2次版本号是：" + num.getStamp());
        b = num.compareAndSet(abaTmpValue, source, num.getStamp(), num.getStamp() + 1);
        System.out.println("compareAndSet是否成功：" + b + "，当前线程是t3，3次版本号是：" + num.getStamp());
        latch.countDown();
    }, "t3").start();
    new Thread(() -> {
        Integer source = num.getReference();
        Integer target = new Integer(300);
        int stamp = num.getStamp();
        System.out.println("当前线程是t4，初始版本号是：" + num.getStamp());
        // 睡眠2秒等到t3线程发生aba问题
        try { TimeUnit.SECONDS.sleep(2);} catch (InterruptedException e) { e.printStackTrace(); }
        boolean b = num.compareAndSet(source, target, stamp, stamp + 1);
        System.out.println("compareAndSet是否成功：" + b + "，当前线程是t4，当前版本号是：" + num.getStamp());
        latch.countDown();
    }, "t4").start();
    
    latch.await();
    System.out.println("最终版本号是：" + num.getStamp() + "，会发现加入stamp版本号后，t4线程更新失败，ABA问题得到解决");
}
```

