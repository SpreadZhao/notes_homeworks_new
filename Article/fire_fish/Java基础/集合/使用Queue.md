

队列（`Queue`）是一种经常使用的集合。`Queue`实际上是实现了一个先进先出（FIFO：First In First Out）的有序表。
它和`List`的区别在于，`List`可以在任意位置添加和删除元素，而`Queue`只有两个操作：
* 把元素添加到队列末尾；
* 从队列头部取出元素。


在Java的标准库中，队列接口`Queue`定义了以下几个方法：
* `int size()`：获取队列长度；
* `boolean add(E)`/`boolean offer(E)`：添加元素到队尾；
* `E remove()`/`E poll()`：获取队首元素并从队列中删除；
* `E element()`/`E peek()`：获取队首元素但并不从队列中删除。

对于具体的实现类，有的Queue有最大队列长度限制，有的Queue没有。注意到添加、删除和获取队列元素总是有两个方法，
这是因为在添加或获取元素失败时，这两个方法的行为是不同的。我们用一个表格总结如下：

|           | throw Exception | 返回false或null       |
| --------- | --------------- | ------------------ |
| 添加元素到队尾   | add(E e)        | boolean offer(E e) |
| 取队首元素并删除  | E remove()      | E poll()           |
| 取队首元素但不删除 | E element()     | E peek()           |