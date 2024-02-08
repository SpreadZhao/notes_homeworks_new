---
title: 一个线程筛质数的例子
---
写一个筛质数的小例子。下面是一个函数，用来判断一个数字是不是质数：

```c
static void checkIsPrimer(int num) {
	int j;
    for (j = 2; j < num / 2; j++) {
        if (num % j == 0) {
            mark = 0;
            break;
        }
    }
    if (mark) {
        printf("%d is a primer\n", i);
    }
}
```

可以看到，里面有一个for循环，这是主要的耗时逻辑。如果我们想做的是筛选30000000到30000200中的质数，那么这里就要调用201次。如果是在main线程中同步调用的话，显然性能巨差无比。因此我们现在做这样一个改动：让每次质数的判断都由一个新的线程去做。这样main线程的任务就变成了：不断产生新线程，并告诉这个线程你要判断哪个数字。

现在来写例子。首先是一些基础信息：

```c
#define LEFT    30000000
#define RIGHT   30000200
#define THRNUM  (RIGHT-LEFT+1)
```

然后声明每个线程要做的函数：

```c
static void *checkIsPrimer(void *);
```

这样，我们在main中就创建THRNUM个线程，传入checkIsPrimer和它们要判断的数字，最后等着给这些线程来收尸：

```c
int main() {
    int i, j, mark;
    pthread_t threads[THRNUM];

    for (i = LEFT; i <= RIGHT; i++) {
        pthread_create(threads + i - LEFT, NULL, checkIsPrimer, &i);
    }
    for (i = LEFT; i <= RIGHT; i++) {
        pthread_join(threads[i - LEFT], NULL);
    }
    
    exit(0);
}
```

这里注意`pthread_create`的最后一个参数。因为要传入的是`void *`，所以我们取了i的地址。当然这也给后续埋上了坑。

最后，我们改造一下最开始的判断质数的函数，让它能在这个线程上work：

```c
static void *checkIsPrimer(void *arg) {
    int i, j, mark;
    i = *(int *)arg;
    mark = 1;
    for (j = 2; j < i / 2; j++) {
        if (i % j == 0) {
            mark = 0;
            break;
        }
    }
    if (mark) {
        printf("%d is a primer\n", i);
    }
    pthread_exit(NULL);
}
```

主要就是改了一下arg的类型转换以及最后的exit。现在启动一下吧！

```shell
30000037 is a primer
30000149 is a primer
30000071 is a primer
30000059 is a primer
30000023 is a primer
30000059 is a primer
30000041 is a primer
30000001 is a primer
30000083 is a primer
30000137 is a primer
30000109 is a primer
30000079 is a primer
30000049 is a primer
30000133 is a primer
```

感觉还挺好？我们仔细探究一下就能发现问题：

```shell
<your built target> | wc -l
```

用上面的命令统计行数可以发现，每次都不一样！这问题可就大了。根本原因其实很简单，就是因为我们当时传了指针进入。现在想象这样的情况：

* main线程创建了一个新线程，并把第一个i也就是30000000传给了它，但是传的是指针；
* 在第一个线程**还没访问i的时候**，main线程的for循环已经把i给++了。

这样，30000000这个数字就根本没判断到！并且，还会出现两个或以上的线程判断的都是同一个数字的情况。那这样的结果肯定是错误的。

最简单的解决方式，就是直接传i，而不是传i的地址：

```c
pthread_create(threads + i - LEFT, NULL, checkIsPrimer, i);
```

然后在判断的时候也要强转回来：

```c
i = (int)arg;
```

但是，由于这种转换不像之前`int * <-> void *`之间的转换，`int`和`int * void *`是两个size完全不一样的东西：[c - Is sizeof(int) guaranteed to equal sizeof(void*) - Stack Overflow](https://stackoverflow.com/questions/8915918/is-sizeofint-guaranteed-to-equal-sizeofvoid)。因此，这种转换会出现编译器警告：

```shell
primer_wrong.c: In function ‘main’:
primer_wrong.c:17:65: warning: passing argument 4 of ‘pthread_create’ makes pointer from integer without a cast [-Wint-conversion]
   17 |         pthread_create(threads + i - LEFT, NULL, checkIsPrimer, i);
      |                                                                 ^
      |                                                                 |
      |                                                                 int
In file included from primer_wrong.c:4:
/usr/include/pthread.h:205:45: note: expected ‘void * restrict’ but argument is of type ‘int’
  205 |                            void *__restrict __arg) __THROWNL __nonnull ((1, 3));
      |                            ~~~~~~~~~~~~~~~~~^~~~~
primer_wrong.c: In function ‘checkIsPrimer’:
primer_wrong.c:28:9: warning: cast from pointer to integer of different size [-Wpointer-to-int-cast]
   28 |     i = (int)arg;
      |         ^
```

```ad-note
上面的文章中说`sizeof(void *)`是8个字节。这和Java中的long是一样的。所以也解释了为什么JNI中用long来表示c中的指针。
```

虽然不是很优雅，但是最终的结果是正确的。无论怎么执行，最终的行数都是18。

那么，如何才能做得优雅呢？看到`man pthread_exit`中有这么一句话：

> The value pointed to by retval should not be  located  on  the  **calling thread's  stack**,  since  the contents of that stack are undefined after the thread terminates.

现在我们的程序是啥情况？不就是这样吗！我们传进去的i就是位于main线程的栈空间的。那么咋办？不让它在栈空间就完了呗！比如我们可以自己在堆上malloc一个，或者用static。我这里就前者了：

```c
for (i = LEFT; i <= RIGHT; i++) {
	int *arg_num = malloc(sizeof(int));
	*arg_num = i;
	pthread_create(threads + i - LEFT, NULL, checkIsPrimer, arg_num);
}
```

然后判断的过程的类型转换也很简单：

```c
i = *(int *)arg;
```

现在问题来了。既然我们malloc了，就要想办法free。那么在哪里free呢？原则是，**谁malloc，谁free**。所以我们应该在main中。但是我怎么知道什么时候线程执行完呢？这个时候`pthread_exit`就起作用了：

```c
pthread_exit(arg); // 将arg返回，到pthread_join中释放
```

我们将arg返回，那么这段内存就传回去了。这样我们就能在main中检测到。咋检测？就是通过`pthread_join()`的第二个参数：

```c
int main() {
    int i, j, mark;
    pthread_t threads[THRNUM];
    void *arg_space;

    for (i = LEFT; i <= RIGHT; i++) {
        int *arg_num = malloc(sizeof(int));
        *arg_num = i;
        pthread_create(threads + i - LEFT, NULL, checkIsPrimer, arg_num);
    }
    for (i = LEFT; i <= RIGHT; i++) {
        pthread_join(threads[i - LEFT], &arg_space);
        free(arg_space);
    }
    
    exit(0);
}
```

我们创建了一个`void *`指针，这段空间每当一个thread执行完毕的时候，就会将它`pthread_exit`中传入的那段空间放到这里来。具体的方式就是，`pthread_join`的第二个参数是一个二级指针，而这个指针指向的指针指向的空间就是我们要free的。所以，这里传入`arg_space`的地址，最后free掉它。这样就不会产生内存泄漏了。

这样其实还不太完美。最契合`void *`类型的东西应该是什么？应该是个**结构体**！所以，我们这样写：

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

#define LEFT    30000000
#define RIGHT   30000200
#define THRNUM  (RIGHT-LEFT+1)

static void *checkIsPrimer(void *);

struct th_arg_num {
    int num;
};


int main() {
    int i, j, mark;
    pthread_t threads[THRNUM];
    struct th_arg_num *arg;
    void *return_arg;               // 用来接收thread返回的内存

    for (i = LEFT; i <= RIGHT; i++) {
        arg = malloc(sizeof(*arg));
        arg->num = i;
        pthread_create(threads + i - LEFT, NULL, checkIsPrimer, arg);
    }
    for (i = LEFT; i <= RIGHT; i++) {
        pthread_join(threads[i - LEFT], &return_arg);
        free(return_arg);
    }
    
    exit(0);
}

static void *checkIsPrimer(void *arg) {
    int i, j, mark;
    i = ((struct th_arg_num*)arg)->num;
    mark = 1;
    for (j = 2; j < i / 2; j++) {
        if (i % j == 0) {
            mark = 0;
            break;
        }
    }
    if (mark) {
        printf("%d is a primer\n", i);
    }
    pthread_exit(arg);      // 将arg返回，到pthread_join中释放
}
```

定义一个专门用来传参的结构体。里面就是我们要传入的值。具体的做法和之前非常类似，一看就懂。这里就不多说了。