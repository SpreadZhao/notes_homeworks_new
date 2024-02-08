---
title: 清理线程
---
线程在退出的时候可以进行清理动作。这个清理的过程分为注册和调用。就像一个栈一样，注册的时候压栈是不会调用的，而弹出来的时候可以选择是否调用：

```c
pthread_cleanup_push(cleanup_func, "cleanup: 1");    // 注册
pthread_cleanup_pop(1);                              // 实际调用
```

在pop中，如果我们传入了非零的值，当时注册进去的函数就会被调用。看下面的例子：

```c
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

static void cleanup_func(void *p)
{
    puts(p);
}

static void *foo(void *p)
{
    puts("Thread is working!");
    pthread_cleanup_push(cleanup_func, "cleanup: 1");
    pthread_cleanup_push(cleanup_func, "cleanup: 2");
    pthread_cleanup_push(cleanup_func, "cleanup: 3");
    puts("push over");
    pthread_cleanup_pop(1);
    pthread_cleanup_pop(1);
    pthread_cleanup_pop(1);
    pthread_exit(NULL);
}

int main()
{
    pthread_t tid;
    puts("begin");
    pthread_create(&tid, NULL, foo, NULL);
    pthread_join(tid, NULL);
    puts("end");
    exit(0);
}
```

输出是这样的，很好理解：

```shell
begin
Thread is working!
push over
cleanup: 3
cleanup: 2
cleanup: 1
end
```

入栈的顺序是123，所以弹栈的时候反过来了。这里还需要注意的一点是，push有几个，pop就也要有几个，必须要成对儿出现。不然就会报**语法**错误。因为push和pop这两个东西本质其实是**宏**。