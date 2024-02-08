---
title: 创建线程
---
创建一个线程，使用：

```c
int pthread_create(pthread_t *thread, const pthread_attr_t *attr,
                          void *(*start_routine) (void *), void *arg);
```

其中的参数：

* thread：线程的id，也就是这个`pthread_t`类型。但是要记住，`pthread_t`只是一个规范。它到底是一个int，一个struct还是别的什么，是由操作系统自己决定的。只不过是大多数linux环境下，`pthread_t`恰好是一个int罢了；
* attr：线程的属性。这个我们之后再说，现在传入NULL就可以；
* start_routine：线程运行的函数，也是最重要的函数。可以类比为Java中重写的那个run()方法。这里参数和返回值都是void\*，代表可以是任意类型；
* arg：start_routine传入的参数。

返回值是一个int。如果是0,表示这个线程成功创建；如果是其它值，那就是创建失败的错误码。

最简单的例子：

```c
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

static void *foo(void *p)
{
    puts("Thread is working!");
    pthread_exit(NULL);
}

int main()
{
    pthread_t tid;
    puts("begin!");
    int err = pthread_create(&tid, NULL, foo, NULL);
    if (err) 
    {
        fprintf(stderr, "pthread_create error: %d", err);
    }
    puts("end!");                   // 然后才能打印end
    exit(0);
}
```

这个程序如果真跑起来，我们大概率会发现Thread is working!没有打印出来。又或者打印出来了，但是不在begin和end之间。这是因为还没等新的线程跑起来，main线程就结束了。并且调用了`exit(0)`使程序终止。因此看不到。

如果我们希望等子线程运行结束之后程序才终止的话，就需要在main线程结束之前等着这个新的线程结束。使用的是pthread_join：

```c
int pthread_join(pthread_t thread, void **retval);
```

第一个参数是我们希望等着哪个线程结束；第二个参数是线程终止之后的收尾内存。这里我们稍后会介绍，现在传入NULL就行。

```c
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

static void *foo(void *p)
{
    puts("Thread is working!");
    pthread_exit(NULL);
}

int main()
{
    pthread_t tid;
    puts("begin!");
    int err = pthread_create(&tid, NULL, foo, NULL);
    if (err) 
    {
        fprintf(stderr, "pthread_create error: %d", err);
    }
    pthread_join(tid, NULL);        // 等待线程运行结束后收尸
    puts("end!");                   // 然后才能打印end
    exit(0);
}
```

现在，只有等新的线程运行完毕，main线程才会输出end并终止程序。所以我们看到的会是：

```shell
begin!
Thread is working!
end!
```

还有一点，注意线程运行的foo函数：

```c
static void *foo(void *p)
{
    puts("Thread is working!");
    pthread_exit(NULL);
}
```

这里最后是用的pthread\_exit。这是用来退出一个线程的函数。里面的参数是用来做收尾工作的。这里面的东西到时候就可以和pthread\_join配合来进行内存释放工作。