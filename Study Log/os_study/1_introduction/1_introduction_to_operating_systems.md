当程序启动时，它都做什么？其实很简单：

- 从内存中**取出**（fetch）指令；
- **解码**（decode）指令；
- **执行**（execute）指令。

每一秒内，CPU可能都会进行上百万次、千万次、上亿次甚至更多这样的过程。一个指令执行完，就跑到下一个指令上继续做这件事。直到程序完成为止。

这就是冯诺依曼（Von Neumann）体系的简单描述。但是作为OS，我们关注的是当程序运行时，在背后运行的很多其它事情，让整个系统更加**易于使用**。

为了让系统更加易于使用，OS使用了一种叫**虚拟化**（virtualization）的手段。也就是说，操作系统拿到的是**物理的硬件**，比如处理器，内存，磁盘等等。而OS负责将这些硬件转换成一种更加通用、强大、易用的**虚拟资源**。因此，我们有时候也管操作系统叫**虚拟机**。

除此之外，OS为了让我们更好地利用虚拟机的功能（比如启动一个程序、分配内存、访问文件等），还提供了我们可以调用的接口。比如最典型的就是**系统调用**（system calls），这些接口可以在我们自己写的程序里调用，用它们来实现启动程序、分配内存、访问文件等功能。而这些东西有时候也被称为标准库（standard library）。

最后，OS还是一个**资源管理者**（resource manager）。资源都有啥？

- CPU：很多程序可以**同时**运行，所以它们在共享CPU；
- 内存：很多程序可以**同时**访问它们自己的指令和数据；
- 设备：很多程序可以**同时**访问设备，比如硬盘、打印机等等。
- ……

这些东西都是资源，本身是硬件，但是被OS虚拟化之后，就能更好地被进程利用，最主要的是还可以同时利用。OS就负责调度这些资源，进行**合理、公平**的分配。

下面是一个例子：

```c
#include <stdio.h>
#include <sys/time.h>
#include <stdlib.h>
#include <assert.h>
#include "common.h"

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: cpu <string>\n");
        exit(1);
    }
    char *str = argv[1];
    while (1) {
        Spin(1);
        printf("%s\n", str);
    }
    return 0;
}
```

Spin函数可以理解为休眠1s。不过根据名字可以看出，这里的休眠不是真的休眠，而是忙等待：

```c
void Spin(int howlong) {
    double t = GetTime();
    while ((GetTime() - t) < (double) howlong);
}
```

这个程序的使用也很显然：

```shell
❯ ./cpu "A"
A
A
A
A
^C
```

现在，同时运行4个程序看看：

```shell
❯ ./cpu "A" & ./cpu "B" & ./cpu "C" & ./cpu "D" &
[1] 8565
[2] 8566
[3] 8567
[4] 8568
A
B
C
D
A
B
C
D
A
B
C
D
A
B
C
D
... ...
```

> [!note]
> 注意这里我们怎么让4个进程同时运行的。使用4个`&`，可以让程序在后台运行，这样就可以立刻读取下一个命令。当然，这里是在zsh中运行。如果是其他shell，结果会有所不同。

我们只有一个CPU，怎么同时运行四个程序？

答案是，操作系统的虚拟化，对CPU的虚拟化。操作系统会将一个单独的CPU（或者其中的一部分）变成很多个虚拟的CPU。

当然，如果我们想要同时运行多个程序，也会有很多问题。比如，*如果两个程序在一个时刻都要运行，那么应该运行谁*？这取决于操作系统的一些策略（policy）。这里也更加显现出OS的资源管理者的地位。

接下来是内存。物理内存非常简单，就是**一串字节**（an array of bytes）。要访问内存，就要知道内存的地址，不管是读，写还是更新。

**程序把所有的指令，数据结构都存在内存中**。指令本身就在内存中，然后这些指令执行的过程中，又会去访问内存去取数据来计算。因此每一次取指令的时候，都是对内存的访问。下面是一个例子：

```c
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include "common.h"

int main(int argc, char *argv[]) {
    int *p = malloc(sizeof(int));
    assert(p != NULL);
    printf("(%d) address pointed to by p: %p\n", getpid(), p);
    *p = 0;
    while (1) {
        Spin(1);
        *p = *p + 1;
        printf("(%d) p: %d\n", getpid(), *p);
    }
    return 0;
}
```

很简单，结果如下：

```shell
❯ ./mem
(16325) address pointed to by p: 0x55a3d8a562a0
(16325) p: 1
(16325) p: 2
(16325) p: 3
(16325) p: 4
(16325) p: 5
(16325) p: 6
^C
```

没啥，重要的是接下来，我们再启动多个程序：

```shell
❯ ./mem & ./mem &
[1] 17542
[2] 17543
(17542) address pointed to by p: 0x5555555592a0                                                                                                                     
(17543) address pointed to by p: 0x5555555592a0
(17542) p: 1                                                                             ≡ at 23:21:50
(17543) p: 1
(17542) p: 2
(17543) p: 2
(17542) p: 3
(17543) p: 3
(17542) p: 4
(17543) p: 4
```

我们发现，两个进程并没有共享同一块物理内存。它们访问的地址都是`0x5555555592a0`，但是却都正常工作，就好像这块内存是自己私有的一样。这就是OS对内存的虚拟化：让每个程序有自己**私有的虚拟地址空间**（private virtual address space），然后OS负责把虚拟的地址和物理的地址做一个映射，这样程序只需要关心虚拟地址的访问。

> [!attention]
> 你运行上面的程序，可能两个程序中p指向的地址不一样。这是因为你开启了地址空间随机化（address-space randomization）。在Linux中，这个叫ASLR：[Address space layout randomization - Wikipedia](https://en.wikipedia.org/wiki/Address_space_layout_randomization)。想要暂时关闭，参考：[kernel - How can I temporarily disable ASLR (Address space layout randomization)? - Ask Ubuntu](https://askubuntu.com/questions/318315/how-can-i-temporarily-disable-aslr-address-space-layout-randomization)

然后是并发。这里因为我们已经学过[[Study Log/java_kotlin_study/concurrency_art|concurrency_art]]了，就直接上例子了：

```c
#include <stdio.h>
#include <stdlib.h>
#include "common.h"
#include "common_threads.h"

volatile int counter = 0;
int loops;

void *worker(void *arg) {
    int i;
    for (i = 0; i < loops; i++) {
        counter++;
    }
    return NULL;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "usage: threads <value>\n");
        exit(1);
    }
    loops = atoi(argv[1]);
    pthread_t th1, th2;
    printf("Initial value: %d\n", counter);
    Pthread_create(&th1, NULL, worker, NULL);
    Pthread_create(&th2, NULL, worker, NULL);
    Pthread_join(th1, NULL);
    Pthread_join(th2, NULL);
    printf("Final value: %d\n", counter);
    return 0;
}
```

这里创建了两个线程th1和th2。它们的工作就是累加counter，一共累加loops次，而loops通过命令行参数传入。因此，如果我们输入10000，这个counter理论上会被累加20000次。显然，结果不是这样：

```shell
❯ ./threads 10000
Initial value: 0
Final value: 17924
❯ ./threads 10000
Initial value: 0
Final value: 20000
❯ ./threads 10000
Initial value: 0
Final value: 16092
❯ ./threads 10000
Initial value: 0
Final value: 20000
❯ ./threads 10000
Initial value: 0
Final value: 19094
```

执行好多次，每次结果都不一样。有的时候正常，有的时候不正常。因此，这里还需要锁之类的并发控制才行。

- [ ] #TODO #question/coding/c tasktodo1719157634445 为什么这里的`volatile`没用？它是干啥的？不对，当我没说，显然，java里这个例子也不会工作的。因为java的volatile也不是干这个的：[[Study Log/java_kotlin_study/concurrency_art/3_4_volatile_mm_semantics#3.4.1 volatile特性|3_4_volatile_mm_semantics]]。在java中，`counter++`也不能用volatile来控制。那么，c语言的volatile又是干什么的呢？java中的和c中的又有什么区别呢？ ➕ 2024-06-23 ⏫ 🆔 fji1jm

在c语言中，这个`counter++`也是包含三条指令：

1. 从内存中读取这个counter的值读到寄存器里；
2. 增加它；
3. 写回内存。

这些也是需要并发控制的。

最后一个主题就是持久化（persistence）。系统的内存是DRAM，也就是断电，东西就全没了。这个模式又叫volatile。因此，我们需要软件和硬件来让数据能够持久存储。当然，持久化最主要的设备就是磁盘（disk）。一个I/O设备。

> <small>volatile这个单词源自拉丁语“volatilis”，意为“飞翔的”或“轻快的”，在英语中常用来形容某物不稳定或易挥发。在编程中，volatile关键字用来表示变量的值是“不稳定的”或“易变的”，即可能在任何时候被其他程序或硬件修改。因此，编译器不能假设这个变量的值是固定不变的，从而不能对它进行优化。</small>
> 
> <small>C语言中的volatile也是这个意思，因为它易变，所以不要优化。直接从内存中读，不要从寄存器中读。java中的也是，直接从内存中读，不要从线程的本地内存中读。</small>

OS管理磁盘的方式是用一个叫**文件系统**（file system）的程序。和CPU，内存不同，OS不会给每一个程序一个虚拟的磁盘，而是通过**文件**来共享信息。我们写一个C程序，会用编辑器来写代码，首先就会创建一个`.c`的文件。在里面写完之后，由编译器来生成一个可执行的文件。下面是一个更加详细的例子：

```c
#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

int main(int argc, char * argv[]) {
    int fd = open("/tmp/file", O_WRONLY|O_CREAT|O_TRUNC, S_IRWXU);
    assert(fd > -1);
    int rc = write(fd, "hello world\n", 13);
    assert(rc == 13);
    close(fd);
    return 0;
}
```

打开文件，创建文件，写文件，关闭文件。这些函数就是**系统调用**，会走到文件系统中，然后就会处理这些请求并返回给用户。

OS是怎么写文件的？文件是存在磁盘中的，磁盘是个IO设备。想要写它，就要写驱动。同时，文件系统也有很多增加效率的方式，通常都是等要写的数据攒够了一坨之后，才一块写去。同时，为了处理写文件的时候出错，还设计了一些协议，比如日志文件系统（journaling）和写时复制（copy-on-write）。

OS设计目标：

- Abstraction：我们需要抽象。有了抽象，做一些事情才更容易。这也是操作系统最重要的目标之一。之后会看到，OS本身就是一个个抽象层摞起来的；
- Performance：虚拟化让OS更易于使用，当然也会带来更多开销（时间和空间上）。因此，我们需要尽可能减少这些开销来提升性能；
- Protection：安全很重要。比如进程的隔离（isolation），可以让程序更安全，也能防止恶意程序攻击OS本身；
- Reliability：系统当然不能老崩，即使崩了，也起码能debug查到原因（@蓝屏）；
- Energy-efficiency：保护环境，人人有责；
- Security：Protection的扩展，应对病毒之类的；
- Mobility：@Android @IOS。

