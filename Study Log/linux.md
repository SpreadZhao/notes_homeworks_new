# Linux系统编程

* `gcc -E`：预处理命令

* 比较两个文件是否相同：`diff A B`，如果没有提示，那就是一样的

* `ps axm`查看进程之中的线程，下面的`--`就是

* `ps ax -L`看到`Linux`中是以线程来消耗`pid`的

* `.c`源文件->可执行文件需要：

  > .c -> 预处理 -> 编译 -> 汇编 -> 链接 -> 可执行文件
  >
  > 预处理： `gcc -E test.c`，保存预处理的结果，使用重定向：`gcc -E test.c > test.i`
  >
  > 编译：`gcc -S test.i`，之后会生成一个`test.s`文件，就是编译好的汇编文件
  >
  > 汇编：`gcc -c test.s`，生成`test.o`文件，这个文件人就看不懂了
  >
  > 链接：`gcc test.o -o test`最终生成可执行文件
>  ^ac781a

- [ ] #TODO 这部分的详细流程，每个步骤到底做了什么事情，有时间要总结一下。 🔼

* `makefile`编写：仿照`gcc`的编译过程，逆向递归来写

```makefile
tool:main.o tool1.o tool2.o
        gcc main.o tool1.o tool2.o -o tool

main.o:main.c
        gcc -c main.c

tool1.o:tool1.c
        gcc -c tool1.c

tool2.o:tool2.c
        gcc -c tool2.c
```

还可以加一些调试信息：

```makefile
tool:main.o tool1.o tool2.o
        gcc main.o tool1.o tool2.o -o tool

main.o:main.c
        gcc -c -Wall -g main.c

tool1.o:tool1.c
        gcc -c -Wall -g tool1.c

tool2.o:tool2.c
        gcc -c -Wall -g tool2.c

clean:
        rm *.o tool -rf
# clean表示删除，这样执行 make clean 就等于执行了下面的命令
```

加上变量的使用：

```makefile
OBJS=main.o tool1.o tool2.o
CC=gcc
CFLAGS+=-c -Wall -g

tool:main.o tool1.o tool2.o
        $(CC) $(OBJS) -o tool

main.o:main.c
        $(CC) $(CFLAGS) main.c

tool1.o:tool1.c
        $(CC) $(CFLAGS) tool1.c

tool2.o:tool2.c
        $(CC) $(CFLAGS) tool2.c

clean:
        rm *.o tool -rf
```

我们发现：`target:source`这一对总是被使用，因此：

```makefile
OBJS=main.o tool1.o tool2.o
CC=gcc
CFLAGS+=-c -Wall -g

# $^代表右边的source
# $@代表左边的target

tool:$(OBJS)
        $(CC) $^ -o $@

main.o:main.c
        $(CC) $(CFLAGS) $^

tool1.o:tool1.c
        $(CC) $(CFLAGS) $^

tool2.o:tool2.c
        $(CC) $(CFLAGS) $^

clean:
        rm *.o tool -rf
```

最后发现，`main, tool1, tool2`这三个执行的过程特别像，因此可以使用通配符：

```makefile
OBJS=main.o tool1.o tool2.o
CC=gcc
CFLAGS+=-c -Wall -g

tool:$(OBJS)
        $(CC) $^ -o $@

%.o:%.c
        $(CC) $(CFLAGS) $^


clean:
        rm *.o tool -rf
```

