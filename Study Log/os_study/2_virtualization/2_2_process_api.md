## 2.2 Interlude: Process API

介绍三个OS提供的和进程相关的API：

- fork
- exec
- wait

### 2.2.1 fork

看这个程序：

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    printf("hello world (pid: %d)\n", (int)getpid());
    int rc = fork();
    if (rc < 0) {
        fprintf(stderr, "fork failed\n");
        exit(1);
    } else if (rc == 0) {
        printf("hello, I am child (pid: %d)\n", (int)getpid());
    } else {
        printf("hello, I am parent of %d (pid: %d)\n", rc, (int)getpid());
    }
    return 0;
}
```

运行结果：

```shell
❯ ./p1
hello world (pid: 16066)
hello, I am parent of 16067 (pid: 16066)
hello, I am child (pid: 16067)
```

有几点需要注意。首先是我们能观察出，**新诞生的进程似乎是原来进程的copy**。但是，这个新进程却没有从main开始执行，而是好像已经调用过`fork()`了一样。

因此，这个新进程并不是完全的copy。尽管这个进程已经有了和原来进程一样的地址空间（包括似有内存）和寄存器、自己的PC（Program Counter）等等，但是这个新进程的`fork()`的返回值是不一样的：

- 父进程接收到了子进程的PID，体现在变量rc；
- 子进程接收到了0。

通过fork的这个机制，我们就能处理父进程和子进程的不同行为。

另外，运行结果中的后两句的顺序也不是确定的。这主要取决于之后会介绍的Scheduler。

### 2.2.2 wait

程序稍微改一下，让父进程的那段话永远比子进程的晚：

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

int main(int argc, char *argv[]) {
    printf("hello world (pid: %d)\n", (int)getpid());
    int rc = fork();
    if (rc < 0) {
        fprintf(stderr, "fork failed\n");
        exit(1);
    } else if (rc == 0) {
        printf("hello, I am child (pid: %d)\n", (int)getpid());
    } else {
        int rc_wait = wait(NULL);
        printf("hello, I am parent of %d (rc_wait: %d) (pid: %d)\n", rc, rc_wait, (int)getpid());
    }
    return 0;
}
```

这里的wait就会等待子进程结束，结束了之后才会继续执行下面的代码。

> [!note]
> 这里和线程做一个对比：
> 
> - C中的主进程默认不会等待子进程结束；
> - 调用了`wait()`之后才会等待；
> - C中的线程的行为也是一样的。main线程不会等待其它线程是否结束，除非调用join；
> - 而java中不一样，只有所有非守护线程结束之后程序才会退出。
> 
> 另外可参考：[[Study Log/android_study/android_dev_trouble/2024-02-21-android-dev-trouble#^6d7bc5|2024-02-21-android-dev-trouble]]

然而，wait不是必然等待进程结束之后才返回的。实际上，它等待的是子进程状态的变化。参照[manual page](https://man7.org/linux/man-pages/man2/waitpid.2.html)：

> If a child has already changed state, then these calls return immediately.  Otherwise, they block until either a child changes state or <u>a signal handler interrupts the call</u> (assuming that system calls are not automatically restarted using the `SA_RESTART` flag of [sigaction(2)](https://man7.org/linux/man-pages/man2/sigaction.2.html)).

意思是说，如果一个Signal Handler中断了wait，那么wait也会停止。这里的Signal Handler就大概是指，比如你向调用wait的进程发送一个sigkill，那么就肯定没了。

### 2.2.3 exec

fork的缺点很明显：新进程只能执行和原来进程一样的代码。要想执行不同的代码，就可以用exec了。下面是一个例子：

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/wait.h>

int main(int argc, char *argv[]) {
    printf("hello world (pid:%d)\n", (int)getpid());
    int rc = fork();
    if (rc < 0) {
        fprintf(stderr, "fork failed\n");
        exit(1);
    } else if (rc == 0) {
        printf("hello, I am child (pid:%d)\n", (int) getpid());    
        char *myargs[3];
        myargs[0] = strdup("wc");
        myargs[1] = strdup("../p3.c");
        myargs[2] = NULL;
        execvp(myargs[0], myargs);
        printf("this shouldn't print out");
    } else {
        int rc_wait = wait(NULL);
        printf("hello, I am parent of %d (rc_wait:%d) (pid:%d)\n", rc, rc_wait, (int)getpid());
    }
    return 0;
}
```

这里的修改是给子进程调用execvp，并传入执行的程序和参数。结果如下：

```shell
hello world (pid:23690)
hello, I am child (pid:23691)
 26  86 750 ../p3.c
hello, I am parent of 23691 (rc_wait:23691) (pid:23690)
```

注意的是，这里是fork和exec配合使用。用fork产生进程，用exec修改子进程执行的指令。这里exec做的事情是，加载我们传入的程序和参数，覆盖掉原来fork复制出来的代码段和静态数据；并且把堆空间和栈空间和这个程序的其它空间都给重新初始化。

因此可以发现，**exec不会创建一个新的进程**，而是把当前运行的进程（fork出来的子进程）变成一个完全不同的进程。如果exec调用成功了，那么它是永远也不会返回的。

### 2.2.4 Why? Motivating the API

上面最大的问题估计就是：为啥fork，exec的设计这么奇怪？一个会复制进程，一个会修改进程还不会返回。*为什么这两个东西不能绑在一起，比如像`pthread_create()`一样，创建的同时直接把它该做什么也传进去不好吗*？

这里要拆开，最大的原因是为了构建UNIX shell。我们把fork和exec分开，就能**在fork和exec之间做一些可以定制的东西**。比如我们可以修改将要运行的程序的环境变量等等。

当我们在shell中输入了命令（比如`vim newfile.txt`）的时候：

1. shell会找到这个可执行的文件在文件系统的哪里；
2. 调用fork去创建一个新的进程；
3. 调用exec（家族中的某个函数）去修改进程，运行我们输入的命令；
4. 调用wait等待程序结束；
5. 程序结束时，shell会从wait返回并再次打印出一个prompt，等待你再次输入。

那么我们在fork和exec之间能做的东西有什么呢？举个例子，我们输入：

```shell
wc p3.c > newfile.txt
```

很简单，把`p3.c`中的内容redirect到`newfile.txt`里面。那么这里shell实际上是怎么做的呢？在上面的2 3步之间，也就是**创建出子进程，但是还没调用exec的时候**，这样做：**关闭标准输出流，并打开文件`newfile.txt`**。这样，本来wc的输出要到标准输出的。但是因为我们关闭了，就跑到文件里去了。

下面这个程序做的是同样的事情：

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <sys/stat.h>

int main(int argc, char *argv[]) {
    int rc = fork();
    if (rc < 0) {
        fprintf(stderr, "fork failed\n");
        exit(1);
    } else if (rc == 0) {
        close(STDOUT_FILENO);
        open("./p4.output", O_CREAT|O_WRONLY|O_TRUNC, S_IRWXU);
        char *myargs[3];
        myargs[0] = strdup("wc");
        myargs[1] = strdup("../p4.c");
        myargs[2] = NULL;
        execvp(myargs[0], myargs);
    } else {
        int rc_wait = wait(NULL);
    }
    return 0;
}
```

最关键的就是这两句：

```c
close(STDOUT_FILENO);
open("./p4.output", O_CREAT|O_WRONLY|O_TRUNC, S_IRWXU);
```

之所以能实现这样的功能，是因为OS管理文件描述符（file descriptor）的方式：**UNIX系统会从0开始找空闲的描述符**。因为我们关闭了stdout，所以此时stdout就是空闲的，所以它接下来就被新打开的文件指向了（通过调用open）。这样之后本来输出到终端的内容（比如调用`printf()`或者就是程序`wc`）就会跑到新打开的文件中了。

> [!note]
> `STDOUT_FILENO`和`stdout`的区别：[c - What's the difference between stdout and STDOUT_FILENO? - Stack Overflow](https://stackoverflow.com/questions/12902627/whats-the-difference-between-stdout-and-stdout-fileno)。stdout是一个`FILE*`一个IO流；而`STDOUT_FILENO`是一个int，就是1，标准输出的编号。编号更底层，使用只能用系统调用（比如close）。而`stdout`就可以用一些库函数（比如stdio），因此，上面的程序中，close那里可以换成：
> 
> ~~~c
> fclose(stdout);
> ~~~

### 2.2.5 Process Control and Users