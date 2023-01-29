---
author: Spread Zhao
title: The Missing Semester
category: self_study
description: MIT学校的The Missing Section课程，能学到一些非常有用的编程知识和技巧
link: https://missing.csail.mit.edu/2020/
---

# 1. The Shell

## 1.1 echo

`echo`命令：将文本显示在终端。它被添加到环境变量中。

## 1.2 which

`which`命令：用于输出环境变量的某个文件的绝对路径。比如我安装了好多echo，想要知道用的是安装在哪里的echo，就只需要输入`which echo`。

## 1.3 escape

Escape：这个是之前没有想到的。比如我要创建一个目录叫做`"My Photos"`。但是因为中间有空格，所以如果我执行`mkdir My Photos`，这其实创建了两个目录。所以通常我的做法是`mkdir "My Photos"`。但是别忘了转义的作用，**如果我想表示空格只是一个空格，并不是分隔参数的符号**，那么我完全可以`mkdir My\ Photos`。这样其实也能达到一样的效果。

## 1.4 redirection

任何文件/程序打开时都默认会打开两个流：

* standard input stream - keyboard
* standard output stream - screen

所以我们可以通过任意组合来达到一些复杂的效果。比如我执行`echo hello`，这只是将hello这串字符显示在我的终端。如果我不想让它显示在(输出到)终端，而是输出到一个文本文件中，我们可以这样做：

```shell
echo haha > hello.txt
```

`>`这个符号可以**更改输出流**，这样输出的对象就不再是默认的屏幕，而是`hello.txt`这个文件了。

---

而如果我们想要更改输入流，自然是使用`<`符号。比如我们想要查看`hello.txt`中的内容，通常是：

```shell
cat hello.txt
```

但是我们还可以这样：

```shell
cat < hello.txt
```

这时发生的就是：shell打开hello.txt，读取其中的内容，作为cat程序的输入流；而cat从它的输入流拿到东西之后，就要把这些内容放到输出流。由于没有设置输出流，自然就是默认的屏幕了。所以我们会在终端看到其中的内容：

接下来，我们更改一下这个输出流，将输出的内容放在hello2.txt文件中：

```shell
cat < hello.txt > hello2.txt
```

这样我们就能够看到新建了一个hello2.txt文件，其中的内容正是haha。我们不难发现，这其实正是copy操作所做的事情。只不过我们这个程序只支持文本文件罢了。

#question/coding/practice 为啥这里我用`echo < hello.txt`就不能在屏幕上输出haha？理论上不是输入流从键盘变成了hello.txt这个文件吗？然后echo从它的输入流拿到了内容haha，然后显示在屏幕上？难道echo不能改输入流，只能用键盘？

---

另外还有一个重定向的符号：`>>`这个符号表示追加输出。比如我们在当前基础上执行：

```shell
cat < hello.txt >> hello2.txt
```

这时hello2.txt中的内容就会变成：

![[Study Log/resources/Pasted image 20221215225631.png]]

## 1.5 pipe

通常我们过滤结果的时候会这样：

```shell
cat haha.txt | grep hehe
```

![[Study Log/resources/Pasted image 20221215225739.png]]

这是找出haha.txt这个文件中包含hehe字符串的所有行。但是我们似乎从来没考虑过中间的这个`|`到底是什么。其实它就是pipe，管道的意思就是，**左边的输出是右边的输入**。因此，`cat haha.txt`的输出是文件中的所有字符，这些字符就作为grep程序的输入，然后grep程序会从输入中过滤出我们想要的东西。我们可以再通过几个例子来看看：

```shell
ls -l | tail -n1
```

![[Study Log/resources/Pasted image 20221215225900.png]]

`ls -l`列出当前文件夹下的文件，而`tail`表示只是输出最后几行，而`-n1`表示输出最后一行。所以如果我们想要查看haha.txt文件中的最后两行文本，就可以这样写：

```shell
cat haha.txt | tail -n2
```

![[Study Log/resources/Pasted image 20221215225940.png]]

从这里我们也能发现，**pipe其实就是帮助我们重定向了这些程序的输入流和输出流**。

## 1.6 sudo, tee

有时候，即使我们在前面加上了`sudo`，还是会得到Permission denied的错误。这是为什么呢？我们从一个例子来看看。`/sys/class/backlight/`目录里存的是屏幕亮度。如果我们打算修改这个亮度：

```shell
echo 500 > brightness
```

此时会报出Permission denied错误。这是因为我们没有资格修改`/sys`目录下的文件。那么我们自然会想到这样做：

```shell
sudo echo 500 > brightness
```

但是这时候还是会报一模一样的错，为什么？这其实和[[#1.5 pipe|pipe]]中介绍的机制是一样的。cat和grep；ls和tail，它们都只是合作关系，cat不知道grep对它的输出做了什么；同时tail也不知道它的输入是从哪儿来的(只知道是从自己的输入流来的)。**装载输入流和输出流的操作是shell完成的**。在这个例子中，我们只知道，执行sudo这个程序，传递参数echo和500。因此我会以超级用户去执行echo程序，输出500；之后重定向到brightness文件中。但是此时因为重定向的工作是shell去做的，而shell也是当前用户执行的，所以它没有权限修改brightness文件，从而报错。所以我们只能切换到超级用户之后再执行重定向的工作：

```shell
sudo su
echo 500 > brightness
```

同时我们也能发现，终端的开始符号也从`$`变成了`#`。这也是区分root用户和普通用户的方式。

---

另外，除了这种方式，我们还可以借助tee这个程序：

```shell
echo 1000 | sudo tee brightness
```

tee其实就是从输入流拿到序列，写到输出流中。因此它通过pipe从echo的输出流拿到了1000。然后写入到brightness文件中。但是由于这里是sudo执行的，所以不会产生错误。接下来我们看一个例子。`/sys/class`中有一个`leds/`目录，这里存的是电脑上的灯。所以如果我进入`input1::capslock`目录，将其中的brightness文件做如下修改：

```shell
echo 1 | sudo tee brightness
```

这时就会发现电脑的CapsLock键盘灯已经亮了。

## 1.7 Lecture notes

### 1.7.1 Motivation

As computer scientists, we know that computers are great at aiding in repetitive tasks. However, far too often, we forget that this applies just as much to our _use_ of the computer as it does to the computations we want our programs to perform. We have a vast range of tools available at our fingertips that enable us to be more productive and solve more complex problems when working on any computer-related problem. Yet many of us utilize only a small fraction of those tools; we only know enough magical incantations by rote to get by, and blindly copy-paste commands from the internet when we get stuck.

This class is an attempt to address this.

We want to teach you how to make the most of the tools you know, show you new tools to add to your toolbox, and hopefully instill in you some excitement for exploring (and perhaps building) more tools on your own. This is what we believe to be the missing semester from most Computer Science curricula.

### 1.7.2 Class structure

The class consists of 11 1-hour lectures, each one centering on a [particular topic](https://missing.csail.mit.edu/2020/). The lectures are largely independent, though as the semester goes on we will presume that you are familiar with the content from the earlier lectures. We have lecture notes online, but there will be a lot of content covered in class (e.g. in the form of demos) that may not be in the notes. We will be recording lectures and posting the recordings online.

We are trying to cover a lot of ground over the course of just 11 1-hour lectures, so the lectures are fairly dense. To allow you some time to get familiar with the content at your own pace, each lecture includes a set of exercises that guide you through the lecture’s key points. After each lecture, we are hosting office hours where we will be present to help answer any questions you might have. If you are attending the class online, you can send us questions at [missing-semester@mit.edu](mailto:missing-semester@mit.edu).

Due to the limited time we have, we won’t be able to cover all the tools in the same level of detail a full-scale class might. Where possible, we will try to point you towards resources for digging further into a tool or topic, but if something particularly strikes your fancy, don’t hesitate to reach out to us and ask for pointers!

### 1.7.3 The Shell

#### 1.7.3.1 What is the shell?

Computers these days have a variety of interfaces for giving them commands; fanciful graphical user interfaces, voice interfaces, and even AR/VR are everywhere. These are great for 80% of use-cases, but they are often fundamentally restricted in what they allow you to do — you cannot press a button that isn’t there or give a voice command that hasn’t been programmed. To take full advantage of the tools your computer provides, we have to go old-school and drop down to a textual interface: The Shell.

Nearly all platforms you can get your hand on has a shell in one form or another, and many of them have several shells for you to choose from. While they may vary in the details, at their core they are all roughly the same: they allow you to run programs, give them input, and inspect their output in a semi-structured way.

In this lecture, we will focus on the Bourne Again SHell, or “bash” for short. This is one of the most widely used shells, and its syntax is similar to what you will see in many other shells. To open a shell _prompt_ (where you can type commands), you first need a _terminal_. Your device probably shipped with one installed, or you can install one fairly easily.

#### 1.7.3.2 Using the shell

When you launch your terminal, you will see a _prompt_ that often looks a little like this:

```shell
missing:~$ 
```

This is the main textual interface to the shell. It tells you that you are on the machine `missing` and that your “current working directory”, or where you currently are, is `~` (short for “home”). The `$` tells you that you are not the root user (more on that later). At this prompt you can type a _command_, which will then be interpreted by the shell. The most basic command is to execute a program:

```shell
missing:~$ date
Fri 10 Jan 2020 11:49:31 AM EST
missing:~$ 
```

Here, we executed the `date` program, which (perhaps unsurprisingly) prints the current date and time. The shell then asks us for another command to execute. We can also execute a command with _arguments_:

```shell
missing:~$ echo hello
hello
```

In this case, we told the shell to execute the program `echo` with the argument `hello`. The `echo` program simply prints out its arguments. The shell parses the command by splitting it by whitespace, and then runs the program indicated by the first word, supplying each subsequent word as an argument that the program can access. If you want to provide an argument that contains spaces or other special characters (e.g., a directory named “My Photos”), you can either quote the argument with `'` or `"` (`"My Photos"`), or escape just the relevant characters with `\` (`My\ Photos`).

But how does the shell know how to find the `date` or `echo` programs? Well, the shell is a programming environment, just like Python or Ruby, and so it has variables, conditionals, loops, and functions (next lecture!). When you run commands in your shell, you are really writing a small bit of code that your shell interprets. If the shell is asked to execute a command that doesn’t match one of its programming keywords, it consults an _environment variable_ called `$PATH` that lists which directories the shell should search for programs when it is given a command:

```shell
missing:~$ echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
missing:~$ which echo
/bin/echo
missing:~$ /bin/echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

When we run the `echo` command, the shell sees that it should execute the program `echo`, and then searches through the `:`-separated list of directories in `$PATH` for a file by that name. When it finds it, it runs it (assuming the file is _executable_; more on that later). We can find out which file is executed for a given program name using the `which` program. We can also bypass `$PATH` entirely by giving the _path_ to the file we want to execute.

#### 1.7.3.3 Navigating in the shell

A path on the shell is a delimited list of directories; separated by `/` on Linux and macOS and `\` on Windows. On Linux and macOS, the path `/` is the “root” of the file system, under which all directories and files lie, whereas on Windows there is one root for each disk partition (e.g., `C:\`). We will generally assume that you are using a Linux filesystem in this class. A path that starts with `/` is called an _absolute_ path. Any other path is a _relative_ path. Relative paths are relative to the current working directory, which we can see with the `pwd` command and change with the `cd` command. In a path, `.` refers to the current directory, and `..` to its parent directory:

```shell
missing:~$ pwd
/home/missing
missing:~$ cd /home
missing:/home$ pwd
/home
missing:/home$ cd ..
missing:/$ pwd
/
missing:/$ cd ./home
missing:/home$ pwd
/home
missing:/home$ cd missing
missing:~$ pwd
/home/missing
missing:~$ ../../bin/echo hello
hello
```

Notice that our shell prompt kept us informed about what our current working directory was. You can configure your prompt to show you all sorts of useful information, which we will cover in a later lecture.

In general, when we run a program, it will operate in the current directory unless we tell it otherwise. For example, it will usually search for files there, and create new files there if it needs to.

To see what lives in a given directory, we use the `ls` command:

```shell
missing:~$ ls
missing:~$ cd ..
missing:/home$ ls
missing
missing:/home$ cd ..
missing:/$ ls
bin
boot
dev
etc
home
...
```

Unless a directory is given as its first argument, `ls` will print the contents of the current directory. Most commands accept flags and options (flags with values) that start with `-` to modify their behavior. Usually, running a program with the `-h` or `--help` flag will print some help text that tells you what flags and options are available. For example, `ls --help` tells us:

```shell
  -l                         use a long listing format
```

```shell
missing:~$ ls -l /home
drwxr-xr-x 1 missing  users  4096 Jun 15  2019 missing
```

This gives us a bunch more information about each file or directory present. First, the `d` at the beginning of the line tells us that `missing` is a directory. Then follow three groups of three characters (`rwx`). These indicate what permissions the owner of the file (`missing`), the owning group (`users`), and everyone else respectively have on the relevant item. A `-` indicates that the given principal does not have the given permission. Above, only the owner is allowed to modify (`w`) the `missing` directory (i.e., add/remove files in it). To enter a directory, a user must have “search” (represented by “execute”: `x`) permissions on that directory (and its parents). To list its contents, a user must have read (`r`) permissions on that directory. For files, the permissions are as you would expect. Notice that nearly all the files in `/bin` have the `x` permission set for the last group, “everyone else”, so that anyone can execute those programs.

Some other handy programs to know about at this point are `mv` (to rename/move a file), `cp` (to copy a file), and `mkdir` (to make a new directory).

If you ever want _more_ information about a program’s arguments, inputs, outputs, or how it works in general, give the `man` program a try. It takes as an argument the name of a program, and shows you its _manual page_. Press `q` to exit.

```shell
missing:~$ man ls
```

#### 1.7.3.4 Connecting programs

In the shell, programs have two primary “streams” associated with them: their input stream and their output stream. When the program tries to read input, it reads from the input stream, and when it prints something, it prints to its output stream. Normally, a program’s input and output are both your terminal. That is, your keyboard as input and your screen as output. However, we can also rewire those streams!

The simplest form of redirection is `< file` and `> file`. These let you rewire the input and output streams of a program to a file respectively:

```shell
missing:~$ echo hello > hello.txt
missing:~$ cat hello.txt
hello
missing:~$ cat < hello.txt
hello
missing:~$ cat < hello.txt > hello2.txt
missing:~$ cat hello2.txt
hello
```

Demonstrated in the example above, `cat` is a program that con`cat`enates files. When given file names as arguments, it prints the contents of each of the files in sequence to its output stream. But when `cat` is not given any arguments, it prints contents from its input stream to its output stream (like in the third example above).

You can also use `>>` to append to a file. Where this kind of input/output redirection really shines is in the use of _pipes_. The `|` operator lets you “chain” programs such that the output of one is the input of another:

```shell
missing:~$ ls -l / | tail -n1
drwxr-xr-x 1 root  root  4096 Jun 20  2019 var
missing:~$ curl --head --silent google.com | grep --ignore-case content-length | cut --delimiter=' ' -f2
219
```

We will go into a lot more detail about how to take advantage of pipes in the lecture on data wrangling.

#### 1.7.3.5 A versatile and powerful tool

On most Unix-like systems, one user is special: the “root” user. You may have seen it in the file listings above. The root user is above (almost) all access restrictions, and can create, read, update, and delete any file in the system. You will not usually log into your system as the root user though, since it’s too easy to accidentally break something. Instead, you will be using the `sudo` command. As its name implies, it lets you “do” something “as su” (short for “super user”, or “root”). When you get permission denied errors, it is usually because you need to do something as root. Though make sure you first double-check that you really wanted to do it that way!

One thing you need to be root in order to do is writing to the `sysfs` file system mounted under `/sys`. `sysfs` exposes a number of kernel parameters as files, so that you can easily reconfigure the kernel on the fly without specialized tools. **Note that sysfs does not exist on Windows or macOS.**

For example, the brightness of your laptop’s screen is exposed through a file called `brightness` under

```shell
/sys/class/backlight
```

By writing a value into that file, we can change the screen brightness. Your first instinct might be to do something like:

```shell
$ sudo find -L /sys/class/backlight -maxdepth 2 -name '*brightness*'
/sys/class/backlight/thinkpad_screen/brightness
$ cd /sys/class/backlight/thinkpad_screen
$ sudo echo 3 > brightness
An error occurred while redirecting file 'brightness'
open: Permission denied
```

This error may come as a surprise. After all, we ran the command with `sudo`! This is an important thing to know about the shell. Operations like `|`, `>`, and `<` are done _by the shell_, not by the individual program. `echo` and friends do not “know” about `|`. They just read from their input and write to their output, whatever it may be. In the case above, the _shell_ (which is authenticated just as your user) tries to open the brightness file for writing, before setting that as `sudo echo`’s output, but is prevented from doing so since the shell does not run as root. Using this knowledge, we can work around this:

```shell
$ echo 3 | sudo tee brightness
```

Since the `tee` program is the one to open the `/sys` file for writing, and _it_ is running as `root`, the permissions all work out. You can control all sorts of fun and useful things through `/sys`, such as the state of various system LEDs (your path might be different):

```shell
$ echo 1 | sudo tee /sys/class/leds/input6::scrolllock/brightness
```

### 1.7.4 Next steps

At this point you know your way around a shell enough to accomplish basic tasks. You should be able to navigate around to find files of interest and use the basic functionality of most programs. In the next lecture, we will talk about how to perform and automate more complex tasks using the shell and the many handy command-line programs out there.

### 1.7.5 Exercises

All classes in this course are accompanied by a series of exercises. Some give you a specific task to do, while others are open-ended, like “try using X and Y programs”. We highly encourage you to try them out.

We have not written solutions for the exercises. If you are stuck on anything in particular, feel free to send us an email describing what you’ve tried so far, and we will try to help you out.

1.  For this course, you need to be using a Unix shell like Bash or ZSH. If you are on Linux or macOS, you don’t have to do anything special. If you are on Windows, you need to make sure you are not running cmd.exe or PowerShell; you can use [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/) or a Linux virtual machine to use Unix-style command-line tools. To make sure you’re running an appropriate shell, you can try the command `echo $SHELL`. If it says something like `/bin/bash` or `/usr/bin/zsh`, that means you’re running the right program.
2.  Create a new directory called `missing` under `/tmp`.
3.  Look up the `touch` program. The `man` program is your friend.
4.  Use `touch` to create a new file called `semester` in `missing`.
5.  Write the following into that file, one line at a time:
    
    ```shell
    #!/bin/sh
    curl --head --silent https://missing.csail.mit.edu
    ```
    
    The first line might be tricky to get working. It’s helpful to know that `#` starts a comment in Bash, and `!` has a special meaning even within double-quoted (`"`) strings. Bash treats single-quoted strings (`'`) differently: they will do the trick in this case. See the Bash [quoting](https://www.gnu.org/software/bash/manual/html_node/Quoting.html) manual page for more information.
    
6.  Try to execute the file, i.e. type the path to the script (`./semester`) into your shell and press enter. Understand why it doesn’t work by consulting the output of `ls` (hint: look at the permission bits of the file).
7.  Run the command by explicitly starting the `sh` interpreter, and giving it the file `semester` as the first argument, i.e. `sh semester`. Why does this work, while `./semester` didn’t?
8.  Look up the `chmod` program (e.g. use `man chmod`).
9.  Use `chmod` to make it possible to run the command `./semester` rather than having to type `sh semester`. How does your shell know that the file is supposed to be interpreted using `sh`? See this page on the [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) line for more information.
10.  Use `|` and `>` to write the “last modified” date output by `semester` into a file called `last-modified.txt` in your home directory.
11.  Write a command that reads out your laptop battery’s power level or your desktop machine’s CPU temperature from `/sys`. Note: if you’re a macOS user, your OS doesn’t have sysfs, so you can skip this exercise.

# 2. Shell Tools and Scripting

## 2.1 variable

我们可以在命令行中定义变量：

```shell
foo=bar
echo $foo
```

![[Study Log/resources/Pasted image 20221216144012.png]]

在字符串中也可以嵌套这些变量(这其实才是最主要的用途)：

```shell
echo "value is $foo"
```

![[Study Log/resources/Pasted image 20221216144030.png]]

但是要注意两点。首先是空格的问题，这个问题[[#1.3 escape|第一章]]也提到了：

```shell
# error, should not use space
foo = bar
```

在这种情况下，shell会把foo当成程序，等号和bar会被当作参数，自然就会报错了：

![[Study Log/resources/Pasted image 20221216144054.png]]

第二点是单引号和双引号的问题。双引号中的变量可以被替换，而单引号不行：

```shell
echo "value is $foo" # value is bar
echo 'value is $foo' # value is $foo
```

![[Study Log/resources/Pasted image 20221216144114.png]]

## 2.2 script fuction

我们可以把命令行的命令封装成函数。比如我们可以定义一个创建目录并进入它的函数：

```shell
# mcd.sh
mcd(){
	mkdir -p "$1"
	cd "$1"
}
```

这里的`$1`是什么之后再说，先运行一下这个命令：

```shell
source mcd.sh
mcd test
```

这样就能够创建test目录并进入它。这里我们其实就能看出来，test就是\$1。在脚本语言中，\$符号就是用来表示参数的占位符的。加上一个数字就表示第几个参数，显然，\$0就表示第零个参数，也就是程序本身。接下来我们来一个复杂的例子：

```shell
#!/usr/bin/bash
echo "Starting program at $(date)"

echo "running program $0 with $# arguments with pid $$"

for file in "$@"; do
	grep foobar "$file" > /dev/null 2> /dev/null
	if [[ "$?" -ne 0 ]]; then
		echo "file $file does not have any foobar, adding one"
		echo "# foobar" >> "$file"
	fi
done
```

这个例子中，我们首先输出当前的时间，使用`$(...)`来保存程序执行的结果，并将其嵌套入字符串中。接下来，就是\$0，也就是程序的名字。\$\#表示参数的个数；\$\$表示该进程的pid。然后是一个for循环，在其中的每个变量file都是一个字符串，比如这样来执行：

```shell
sudo ./example.sh bashtest1 bashtest2 bashtest3
```

那么file就会从bashtest1一直遍历到bashtest3。而\$@符号表示所有的参数列表。在for循环内部，我们进行了grep操作。从"\$file"这个字符串中找有没有foobar这段字符。如果有，那么我们将其重定向到`/dev/null`中。**这里注意后面的2>**，这表示如果出现错误，比如没有foobar这段字符，那么就用**标准错误流**将其输出到/dev/null中。

然后，我们判断`$?`和0是否相等。`$?`会返回上个命令的错误码，如果是0则表示成功。因此如果不想等(-ne)的话，就手动添加一个。

以上的脚本文件执行起来就是这样的。如果我们有测试文件bashtest1, bashtest2, bashtest3。其中的内容是这样的：

![[Study Log/resources/Pasted image 20221216150511.png]]

那么这个脚本的执行结果就是：

![[Study Log/resources/Pasted image 20221216150651.png]]

> 能看到，由于1和3中都没有foobar，所以它在后面添加了一个。

## 2.3 wildcard

在脚本语言中也可以使用各种通配符。比如我有如下文件：

![[Study Log/resources/Pasted image 20221216150900.png|200]]

那么注意观察下面两条命令的执行结果，就明白是什么意思了。

![[Study Log/resources/Pasted image 20221216151047.png]]

单个问号只占一个位置，而星号表示任意位数的字符串。

---

如果我想一次创建多个文件夹，可以这样：

![[Study Log/resources/Pasted image 20221216151229.png]]

这其实就相当于下面的命令：

```shell
mkdir test1 test2 test3
```

甚至还可以进行循环和嵌套：

![[Study Log/resources/Pasted image 20221216151428.png]]

## 2.4 process substitution

从2.1的介绍我们能知道，如果想查看某些特殊的输出，比如想同时输出当前目录的文件和父目录的文件，可以这样：

![[Study Log/resources/Pasted image 20221216152200.png]]

> 这里的-e表示翻译转义字符，比如里面的\n。

但是还有另外一种方式，就是process substitution：

![[Study Log/resources/Pasted image 20221216152317.png]]

`<(...)`符号的工作原理是，让程序执行的结果放在一个临时文件中。如何证明呢？用一个程序：diff。它比较的是文件，能输出它们的不同。下面的例子很好看懂：

![[Study Log/resources/Pasted image 20221216152800.png]]

> 这里将ls程序执行的结果放到了临时文件中，并比较这两个临时文件的不同。

## 2.5 logic cal

在脚本语言里也可以写逻辑运算，只不过和程序语言中有一些不同。比如下面的例子：

```shell
false || echo haha # will run
true || echo hehe # will not run
false && echo haha # will not run
true && echo hehe # will run
```

这些程序都是从左到右执行的。或运算是：左边执行失败了，就执行右边，如果左边成功了，就不执行右边了；而与运算是：只要有一个执行失败就结束。所以这些程序的输出是这样的：

![[Study Log/resources/Pasted image 20221216153320.png]]

## 2.6 nifty tools

下面介绍一些实用的小工具。首先是tldr，它相当于一个精简的man，只列出有用的帮助：

![[Study Log/resources/Pasted image 20221216153629.png]]

---

find，这个很常用，就是搜索。下面给出一个比较常用的例子：

```shell
find . -name "*.sh" -type f # 找文件
find . -name "test*" -type d # 找文件夹
```

![[Study Log/resources/Pasted image 20221216153921.png]]

---

locate，这个就是有索引地找。

![[Study Log/resources/Pasted image 20221216154025.png]]

它比find快很多，但是需要建立索引的过程：

```shell
sudo updatedb
```

## 2.7 Lecture notes

In this lecture, we will present some of the basics of using bash as a scripting language along with a number of shell tools that cover several of the most common tasks that you will be constantly performing in the command line.

### 2.7.1 Shell Scripting

So far we have seen how to execute commands in the shell and pipe them together. However, in many scenarios you will want to perform a series of commands and make use of control flow expressions like conditionals or loops.

Shell scripts are the next step in complexity. Most shells have their own scripting language with variables, control flow and its own syntax. What makes shell scripting different from other scripting programming language is that it is optimized for performing shell-related tasks. Thus, creating command pipelines, saving results into files, and reading from standard input are primitives in shell scripting, which makes it easier to use than general purpose scripting languages. For this section we will focus on bash scripting since it is the most common.

To assign variables in bash, use the syntax `foo=bar` and access the value of the variable with `$foo`. Note that `foo = bar` will not work since it is interpreted as calling the `foo` program with arguments `=` and `bar`. In general, in shell scripts the space character will perform argument splitting. This behavior can be confusing to use at first, so always check for that.

Strings in bash can be defined with `'` and `"` delimiters, but they are not equivalent. Strings delimited with `'` are literal strings and will not substitute variable values whereas `"` delimited strings will.

```shell
foo=bar
echo "$foo"
# prints bar
echo '$foo'
# prints $foo
```

As with most programming languages, bash supports control flow techniques including `if`, `case`, `while` and `for`. Similarly, `bash` has functions that take arguments and can operate with them. Here is an example of a function that creates a directory and `cd`s into it.

```shell
mcd () {
    mkdir -p "$1"
    cd "$1"
}
```

Here `$1` is the first argument to the script/function. Unlike other scripting languages, bash uses a variety of special variables to refer to arguments, error codes, and other relevant variables. Below is a list of some of them. A more comprehensive list can be found [here](https://tldp.org/LDP/abs/html/special-chars.html).

-   `$0` - Name of the script
-   `$1` to `$9` - Arguments to the script. `$1` is the first argument and so on.
-   `$@` - All the arguments
-   `$#` - Number of arguments
-   `$?` - Return code of the previous command
-   `$$` - Process identification number (PID) for the current script
-   `!!` - Entire last command, including arguments. A common pattern is to execute a command only for it to fail due to missing permissions; you can quickly re-execute the command with sudo by doing `sudo !!`
-   `$_` - Last argument from the last command. If you are in an interactive shell, you can also quickly get this value by typing `Esc` followed by `.` or `Alt+.`

Commands will often return output using `STDOUT`, errors through `STDERR`, and a Return Code to report errors in a more script-friendly manner. The return code or exit status is the way scripts/commands have to communicate how execution went. A value of 0 usually means everything went OK; anything different from 0 means an error occurred.

Exit codes can be used to conditionally execute commands using `&&` (and operator) and `||` (or operator), both of which are [short-circuiting](https://en.wikipedia.org/wiki/Short-circuit_evaluation) operators. Commands can also be separated within the same line using a semicolon `;`. The `true` program will always have a 0 return code and the `false` command will always have a 1 return code. Let’s see some examples

```shell
false || echo "Oops, fail"
# Oops, fail

true || echo "Will not be printed"
#

true && echo "Things went well"
# Things went well

false && echo "Will not be printed"
#

true ; echo "This will always run"
# This will always run

false ; echo "This will always run"
# This will always run
```

Another common pattern is wanting to get the output of a command as a variable. This can be done with _command substitution_. Whenever you place `$( CMD )` it will execute `CMD`, get the output of the command and substitute it in place. For example, if you do `for file in $(ls)`, the shell will first call `ls` and then iterate over those values. A lesser known similar feature is _process substitution_, `<( CMD )` will execute `CMD` and place the output in a temporary file and substitute the `<()` with that file’s name. This is useful when commands expect values to be passed by file instead of by STDIN. For example, `diff <(ls foo) <(ls bar)` will show differences between files in dirs `foo` and `bar`.

Since that was a huge information dump, let’s see an example that showcases some of these features. It will iterate through the arguments we provide, `grep` for the string `foobar`, and append it to the file as a comment if it’s not found.

```shell
#!/bin/bash

echo "Starting program at $(date)" # Date will be substituted

echo "Running program $0 with $# arguments with pid $$"

for file in "$@"; do
    grep foobar "$file" > /dev/null 2> /dev/null
    # When pattern is not found, grep has exit status 1
    # We redirect STDOUT and STDERR to a null register since we do not care about them
    if [[ $? -ne 0 ]]; then
        echo "File $file does not have any foobar, adding one"
        echo "# foobar" >> "$file"
    fi
done
```

In the comparison we tested whether `$?` was not equal to 0. Bash implements many comparisons of this sort - you can find a detailed list in the manpage for [`test`](https://www.man7.org/linux/man-pages/man1/test.1.html). When performing comparisons in bash, try to use double brackets `[[ ]]` in favor of simple brackets `[ ]`. Chances of making mistakes are lower although it won’t be portable to `sh`. A more detailed explanation can be found [here](http://mywiki.wooledge.org/BashFAQ/031).

When launching scripts, you will often want to provide arguments that are similar. Bash has ways of making this easier, expanding expressions by carrying out filename expansion. These techniques are often referred to as shell _globbing_.

-   Wildcards - Whenever you want to perform some sort of wildcard matching, you can use `?` and `*` to match one or any amount of characters respectively. For instance, given files `foo`, `foo1`, `foo2`, `foo10` and `bar`, the command `rm foo?` will delete `foo1` and `foo2` whereas `rm foo*` will delete all but `bar`.
-   Curly braces `{}` - Whenever you have a common substring in a series of commands, you can use curly braces for bash to expand this automatically. This comes in very handy when moving or converting files.

```shell
convert image.{png,jpg}
# Will expand to
convert image.png image.jpg

cp /path/to/project/{foo,bar,baz}.sh /newpath
# Will expand to
cp /path/to/project/foo.sh /path/to/project/bar.sh /path/to/project/baz.sh /newpath

# Globbing techniques can also be combined
mv *{.py,.sh} folder
# Will move all *.py and *.sh files


mkdir foo bar
# This creates files foo/a, foo/b, ... foo/h, bar/a, bar/b, ... bar/h
touch {foo,bar}/{a..h}
touch foo/x bar/y
# Show differences between files in foo and bar
diff <(ls foo) <(ls bar)
# Outputs
# < x
# ---
# > y
```

Writing `bash` scripts can be tricky and unintuitive. There are tools like [shellcheck](https://github.com/koalaman/shellcheck) that will help you find errors in your sh/bash scripts.

Note that scripts need not necessarily be written in bash to be called from the terminal. For instance, here’s a simple Python script that outputs its arguments in reversed order:

```shell
#!/usr/local/bin/python
import sys
for arg in reversed(sys.argv[1:]):
    print(arg)
```

The kernel knows to execute this script with a python interpreter instead of a shell command because we included a [shebang](https://en.wikipedia.org/wiki/Shebang_(Unix)) line at the top of the script. It is good practice to write shebang lines using the [`env`](https://www.man7.org/linux/man-pages/man1/env.1.html) command that will resolve to wherever the command lives in the system, increasing the portability of your scripts. To resolve the location, `env` will make use of the `PATH` environment variable we introduced in the first lecture. For this example the shebang line would look like `#!/usr/bin/env python`.

Some differences between shell functions and scripts that you should keep in mind are:

-   Functions have to be in the same language as the shell, while scripts can be written in any language. This is why including a shebang for scripts is important.
-   Functions are loaded once when their definition is read. Scripts are loaded every time they are executed. This makes functions slightly faster to load, but whenever you change them you will have to reload their definition.
-   Functions are executed in the current shell environment whereas scripts execute in their own process. Thus, functions can modify environment variables, e.g. change your current directory, whereas scripts can’t. Scripts will be passed by value environment variables that have been exported using [`export`](https://www.man7.org/linux/man-pages/man1/export.1p.html)
-   As with any programming language, functions are a powerful construct to achieve modularity, code reuse, and clarity of shell code. Often shell scripts will include their own function definitions.

### 2.7.2 Shell Tools

#### 2.7.2.1 Finding how to use commands

At this point, you might be wondering how to find the flags for the commands in the aliasing section such as `ls -l`, `mv -i` and `mkdir -p`. More generally, given a command, how do you go about finding out what it does and its different options? You could always start googling, but since UNIX predates StackOverflow, there are built-in ways of getting this information.

As we saw in the shell lecture, the first-order approach is to call said command with the `-h` or `--help` flags. A more detailed approach is to use the `man` command. Short for manual, [`man`](https://www.man7.org/linux/man-pages/man1/man.1.html) provides a manual page (called manpage) for a command you specify. For example, `man rm` will output the behavior of the `rm` command along with the flags that it takes, including the `-i` flag we showed earlier. In fact, what I have been linking so far for every command is the online version of the Linux manpages for the commands. Even non-native commands that you install will have manpage entries if the developer wrote them and included them as part of the installation process. For interactive tools such as the ones based on ncurses, help for the commands can often be accessed within the program using the `:help` command or typing `?`.

Sometimes manpages can provide overly detailed descriptions of the commands, making it hard to decipher what flags/syntax to use for common use cases. [TLDR pages](https://tldr.sh/) are a nifty complementary solution that focuses on giving example use cases of a command so you can quickly figure out which options to use. For instance, I find myself referring back to the tldr pages for [`tar`](https://tldr.ostera.io/tar) and [`ffmpeg`](https://tldr.ostera.io/ffmpeg) way more often than the manpages.

#### 2.7.2.2 Finding files

One of the most common repetitive tasks that every programmer faces is finding files or directories. All UNIX-like systems come packaged with [`find`](https://www.man7.org/linux/man-pages/man1/find.1.html), a great shell tool to find files. `find` will recursively search for files matching some criteria. Some examples:

```shell
# Find all directories named src
find . -name src -type d
# Find all python files that have a folder named test in their path
find . -path '*/test/*.py' -type f
# Find all files modified in the last day
find . -mtime -1
# Find all zip files with size in range 500k to 10M
find . -size +500k -size -10M -name '*.tar.gz'
```

Beyond listing files, find can also perform actions over files that match your query. This property can be incredibly helpful to simplify what could be fairly monotonous tasks.

```shell
# Delete all files with .tmp extension
find . -name '*.tmp' -exec rm {} \;
# Find all PNG files and convert them to JPG
find . -name '*.png' -exec convert {} {}.jpg \;
```

Despite `find`’s ubiquitousness, its syntax can sometimes be tricky to remember. For instance, to simply find files that match some pattern `PATTERN` you have to execute `find -name '*PATTERN*'` (or `-iname` if you want the pattern matching to be case insensitive). You could start building aliases for those scenarios, but part of the shell philosophy is that it is good to explore alternatives. Remember, one of the best properties of the shell is that you are just calling programs, so you can find (or even write yourself) replacements for some. For instance, [`fd`](https://github.com/sharkdp/fd) is a simple, fast, and user-friendly alternative to `find`. It offers some nice defaults like colorized output, default regex matching, and Unicode support. It also has, in my opinion, a more intuitive syntax. For example, the syntax to find a pattern `PATTERN` is `fd PATTERN`.

Most would agree that `find` and `fd` are good, but some of you might be wondering about the efficiency of looking for files every time versus compiling some sort of index or database for quickly searching. That is what [`locate`](https://www.man7.org/linux/man-pages/man1/locate.1.html) is for. `locate` uses a database that is updated using [`updatedb`](https://www.man7.org/linux/man-pages/man1/updatedb.1.html). In most systems, `updatedb` is updated daily via [`cron`](https://www.man7.org/linux/man-pages/man8/cron.8.html). Therefore one trade-off between the two is speed vs freshness. Moreover `find` and similar tools can also find files using attributes such as file size, modification time, or file permissions, while `locate` just uses the file name. A more in-depth comparison can be found [here](https://unix.stackexchange.com/questions/60205/locate-vs-find-usage-pros-and-cons-of-each-other).

#### 2.7.2.3 Finding code

Finding files by name is useful, but quite often you want to search based on file _content_. A common scenario is wanting to search for all files that contain some pattern, along with where in those files said pattern occurs. To achieve this, most UNIX-like systems provide [`grep`](https://www.man7.org/linux/man-pages/man1/grep.1.html), a generic tool for matching patterns from the input text. `grep` is an incredibly valuable shell tool that we will cover in greater detail during the data wrangling lecture.

For now, know that `grep` has many flags that make it a very versatile tool. Some I frequently use are `-C` for getting **C**ontext around the matching line and `-v` for in**v**erting the match, i.e. print all lines that do **not** match the pattern. For example, `grep -C 5` will print 5 lines before and after the match. When it comes to quickly searching through many files, you want to use `-R` since it will **R**ecursively go into directories and look for files for the matching string.

But `grep -R` can be improved in many ways, such as ignoring `.git` folders, using multi CPU support, &c. Many `grep` alternatives have been developed, including [ack](https://github.com/beyondgrep/ack3), [ag](https://github.com/ggreer/the_silver_searcher) and [rg](https://github.com/BurntSushi/ripgrep). All of them are fantastic and pretty much provide the same functionality. For now I am sticking with ripgrep (`rg`), given how fast and intuitive it is. Some examples:

```shell
# Find all python files where I used the requests library
rg -t py 'import requests'
# Find all files (including hidden files) without a shebang line
rg -u --files-without-match "^#!"
# Find all matches of foo and print the following 5 lines
rg foo -A 5
# Print statistics of matches (# of matched lines and files )
rg --stats PATTERN
```

Note that as with `find`/`fd`, it is important that you know that these problems can be quickly solved using one of these tools, while the specific tools you use are not as important.

#### 2.7.2.4 Finding shell commands

So far we have seen how to find files and code, but as you start spending more time in the shell, you may want to find specific commands you typed at some point. The first thing to know is that typing the up arrow will give you back your last command, and if you keep pressing it you will slowly go through your shell history.

The `history` command will let you access your shell history programmatically. It will print your shell history to the standard output. If we want to search there we can pipe that output to `grep` and search for patterns. `history | grep find` will print commands that contain the substring “find”.

In most shells, you can make use of `Ctrl+R` to perform backwards search through your history. After pressing `Ctrl+R`, you can type a substring you want to match for commands in your history. As you keep pressing it, you will cycle through the matches in your history. This can also be enabled with the UP/DOWN arrows in [zsh](https://github.com/zsh-users/zsh-history-substring-search). A nice addition on top of `Ctrl+R` comes with using [fzf](https://github.com/junegunn/fzf/wiki/Configuring-shell-key-bindings#ctrl-r) bindings. `fzf` is a general-purpose fuzzy finder that can be used with many commands. Here it is used to fuzzily match through your history and present results in a convenient and visually pleasing manner.

Another cool history-related trick I really enjoy is **history-based autosuggestions**. First introduced by the [fish](https://fishshell.com/) shell, this feature dynamically autocompletes your current shell command with the most recent command that you typed that shares a common prefix with it. It can be enabled in [zsh](https://github.com/zsh-users/zsh-autosuggestions) and it is a great quality of life trick for your shell.

You can modify your shell’s history behavior, like preventing commands with a leading space from being included. This comes in handy when you are typing commands with passwords or other bits of sensitive information. To do this, add `HISTCONTROL=ignorespace` to your `.bashrc` or `setopt HIST_IGNORE_SPACE` to your `.zshrc`. If you make the mistake of not adding the leading space, you can always manually remove the entry by editing your `.bash_history` or `.zhistory`.

#### 2.7.2.5 Directory Navigation

So far, we have assumed that you are already where you need to be to perform these actions. But how do you go about quickly navigating directories? There are many simple ways that you could do this, such as writing shell aliases or creating symlinks with [ln -s](https://www.man7.org/linux/man-pages/man1/ln.1.html), but the truth is that developers have figured out quite clever and sophisticated solutions by now.

As with the theme of this course, you often want to optimize for the common case. Finding frequent and/or recent files and directories can be done through tools like [`fasd`](https://github.com/clvv/fasd) and [`autojump`](https://github.com/wting/autojump). Fasd ranks files and directories by [_frecency_](https://web.archive.org/web/20210421120120/https://developer.mozilla.org/en-US/docs/Mozilla/Tech/Places/Frecency_algorithm), that is, by both _frequency_ and _recency_. By default, `fasd` adds a `z` command that you can use to quickly `cd` using a substring of a _frecent_ directory. For example, if you often go to `/home/user/files/cool_project` you can simply use `z cool` to jump there. Using autojump, this same change of directory could be accomplished using `j cool`.

More complex tools exist to quickly get an overview of a directory structure: [`tree`](https://linux.die.net/man/1/tree), [`broot`](https://github.com/Canop/broot) or even full fledged file managers like [`nnn`](https://github.com/jarun/nnn) or [`ranger`](https://github.com/ranger/ranger).

### 2.7.3 Exercises

1.  Read [`man ls`](https://www.man7.org/linux/man-pages/man1/ls.1.html) and write an `ls` command that lists files in the following manner
    
    -   Includes all files, including hidden files
    -   Sizes are listed in human readable format (e.g. 454M instead of 454279954)
    -   Files are ordered by recency
    -   Output is colorized
    
    A sample output would look like this
    
    ```
     -rw-r--r--   1 user group 1.1M Jan 14 09:53 baz
     drwxr-xr-x   5 user group  160 Jan 14 09:53 .
     -rw-r--r--   1 user group  514 Jan 14 06:42 bar
     -rw-r--r--   1 user group 106M Jan 13 12:12 foo
     drwx------+ 47 user group 1.5K Jan 12 18:08 ..
    ```
    
2.  Write bash functions `marco` and `polo` that do the following. Whenever you execute `marco` the current working directory should be saved in some manner, then when you execute `polo`, no matter what directory you are in, `polo` should `cd` you back to the directory where you executed `marco`. For ease of debugging you can write the code in a file `marco.sh` and (re)load the definitions to your shell by executing `source marco.sh`.
    
3.  Say you have a command that fails rarely. In order to debug it you need to capture its output but it can be time consuming to get a failure run. Write a bash script that runs the following script until it fails and captures its standard output and error streams to files and prints everything at the end. Bonus points if you can also report how many runs it took for the script to fail.
    
    ```
     #!/usr/bin/env bash
    
     n=$(( RANDOM % 100 ))
    
     if [[ n -eq 42 ]]; then
        echo "Something went wrong"
        >&2 echo "The error was using magic numbers"
        exit 1
     fi
    
     echo "Everything went according to plan"
    ```
    
4.  As we covered in the lecture `find`’s `-exec` can be very powerful for performing operations over the files we are searching for. However, what if we want to do something with **all** the files, like creating a zip file? As you have seen so far commands will take input from both arguments and STDIN. When piping commands, we are connecting STDOUT to STDIN, but some commands like `tar` take inputs from arguments. To bridge this disconnect there’s the [`xargs`](https://www.man7.org/linux/man-pages/man1/xargs.1.html) command which will execute a command using STDIN as arguments. For example `ls | xargs rm` will delete the files in the current directory.
    
    Your task is to write a command that recursively finds all HTML files in the folder and makes a zip with them. Note that your command should work even if the files have spaces (hint: check `-d` flag for `xargs`).
    
    If you’re on macOS, note that the default BSD `find` is different from the one included in [GNU coreutils](https://en.wikipedia.org/wiki/List_of_GNU_Core_Utilities_commands). You can use `-print0` on `find` and the `-0` flag on `xargs`. As a macOS user, you should be aware that command-line utilities shipped with macOS may differ from the GNU counterparts; you can install the GNU versions if you like by [using brew](https://formulae.brew.sh/formula/coreutils).
    
5.  (Advanced) Write a command or script to recursively find the most recently modified file in a directory. More generally, can you list all files by recency?

# 3. Vim

vim这种东西还是得多用才行。所以我直接贴了官方的学习笔记，列出一些重点。

Writing English words and writing code are very different activities. When programming, you spend more time switching files, reading, navigating, and editing code compared to writing a long stream. It makes sense that there are different types of programs for writing English words versus code (e.g. Microsoft Word versus Visual Studio Code).

As programmers, we spend most of our time editing code, so it’s worth investing time mastering an editor that fits your needs. Here’s how you learn a new editor:

-   Start with a tutorial (i.e. this lecture, plus resources that we point out)
-   Stick with using the editor for all your text editing needs (even if it slows you down initially)
-   Look things up as you go: if it seems like there should be a better way to do something, there probably is

If you follow the above method, fully committing to using the new program for all text editing purposes, the timeline for learning a sophisticated text editor looks like this. In an hour or two, you’ll learn basic editor functions such as opening and editing files, save/quit, and navigating buffers. Once you’re 20 hours in, you should be as fast as you were with your old editor. After that, the benefits start: you will have enough knowledge and muscle memory that using the new editor saves you time. Modern text editors are fancy and powerful tools, so the learning never stops: you’ll get even faster as you learn more.

## 3.1  Which editor to learn?

Programmers have [strong opinions](https://en.wikipedia.org/wiki/Editor_war) about their text editors.

Which editors are popular today? See this [Stack Overflow survey](https://insights.stackoverflow.com/survey/2019/#development-environments-and-tools) (there may be some bias because Stack Overflow users may not be representative of programmers as a whole). [Visual Studio Code](https://code.visualstudio.com/) is the most popular editor. [Vim](https://www.vim.org/) is the most popular command-line-based editor.

### Vim

All the instructors of this class use Vim as their editor. Vim has a rich history; it originated from the Vi editor (1976), and it’s still being developed today. Vim has some really neat ideas behind it, and for this reason, lots of tools support a Vim emulation mode (for example, 1.4 million people have installed [Vim emulation for VS code](https://github.com/VSCodeVim/Vim)). Vim is probably worth learning even if you finally end up switching to some other text editor.

It’s not possible to teach all of Vim’s functionality in 50 minutes, so we’re going to focus on explaining the philosophy of Vim, teaching you the basics, showing you some of the more advanced functionality, and giving you the resources to master the tool.

## 3.2 Philosophy of Vim

When programming, you spend most of your time reading/editing, not writing. For this reason, Vim is a _modal_ editor: it has different modes for inserting text vs manipulating text. Vim is programmable (with Vimscript and also other languages like Python), and Vim’s interface itself is a programming language: keystrokes (with mnemonic names) are commands, and these commands are composable. Vim avoids the use of the mouse, because it’s too slow; Vim even avoids using the arrow keys because it requires too much movement.

The end result is an editor that can match the speed at which you think.

## 3.3 Modal editing

Vim’s design is based on the idea that a lot of programmer time is spent reading, navigating, and making small edits, as opposed to writing long streams of text. For this reason, Vim has multiple operating modes.

-   **Normal**: for moving around a file and making edits
-   **Insert**: for inserting text
-   **Replace**: for replacing text
-   **Visual** (plain, line, or block): for selecting blocks of text
-   **Command-line**: for running a command

Keystrokes have different meanings in different operating modes. For example, the letter `x` in Insert mode will just insert a literal character ‘x’, but in Normal mode, it will delete the character under the cursor, and in Visual mode, it will delete the selection.

In its default configuration, Vim shows the current mode in the bottom left. The initial/default mode is Normal mode. You’ll generally spend most of your time between Normal mode and Insert mode.

You change modes by pressing `<ESC>` (the escape key) to switch from any mode back to Normal mode. From Normal mode, enter Insert mode with `i`, Replace mode with `R`, Visual mode with `v`, Visual Line mode with `V`, Visual Block mode with `<C-v>` (Ctrl-V, sometimes also written `^V`), and Command-line mode with `:`.

You use the `<ESC>` key a lot when using Vim: consider remapping Caps Lock to Escape ([macOS instructions](https://vim.fandom.com/wiki/Map_caps_lock_to_escape_in_macOS)).

## 3.4 Basics

### Inserting text

From Normal mode, press `i` to enter Insert mode. Now, Vim behaves like any other text editor, until you press `<ESC>` to return to Normal mode. This, along with the basics explained above, are all you need to start editing files using Vim (though not particularly efficiently, if you’re spending all your time editing from Insert mode).

### Buffers, tabs, and windows

Vim maintains a set of open files, called “buffers”. A Vim session has a number of tabs, each of which has a number of windows (split panes). Each window shows a single buffer. Unlike other programs you are familiar with, like web browsers, there is not a 1-to-1 correspondence between buffers and windows; windows are merely views. A given buffer may be open in _multiple_ windows, even within the same tab. This can be quite handy, for example, to view two different parts of a file at the same time.

By default, Vim opens with a single tab, which contains a single window.

### Command-line

Command mode can be entered by typing `:` in Normal mode. Your cursor will jump to the command line at the bottom of the screen upon pressing `:`. This mode has many functionalities, including opening, saving, and closing files, and [quitting Vim](https://twitter.com/iamdevloper/status/435555976687923200).

-   `:q` quit (close window)
-   `:w` save (“write”)
-   `:wq` save and quit
-   `:e {name of file}` open file for editing
-   `:ls` show open buffers
-   `:help {topic}` open help
    -   `:help :w` opens help for the `:w` command
    -   `:help w` opens help for the `w` movement

## 3.5 Vim’s interface is a programming language

The most important idea in Vim is that Vim’s interface itself is a programming language. Keystrokes (with mnemonic names) are commands, and these commands _compose_. This enables efficient movement and edits, especially once the commands become muscle memory.

### Movement

You should spend most of your time in Normal mode, using movement commands to navigate the buffer. Movements in Vim are also called “nouns”, because they refer to chunks of text.

-   Basic movement: `hjkl` (left, down, up, right)
-   Words: `w` (next word), `b` (beginning of word), `e` (end of word)
-   Lines: `0` (beginning of line), `^` (first non-blank character), `$` (end of line)
-   Screen: `H` (top of screen), `M` (middle of screen), `L` (bottom of screen)
-   Scroll: `Ctrl-u` (up), `Ctrl-d` (down)
-   File: `gg` (beginning of file), `G` (end of file)
-   Line numbers: `:{number}<CR>` or `{number}G` (line {number})
-   Misc: `%` (corresponding item)
-   Find: `f{character}`, `t{character}`, `F{character}`, `T{character}`
    -   find/to forward/backward {character} on the current line
    -   `,` / `;` for navigating matches
-   Search: `/{regex}`, `n` / `N` for navigating matches

### Selection

Visual modes:

-   Visual: `v`
-   Visual Line: `V`
-   Visual Block: `Ctrl-v`

Can use movement keys to make selection.

### Edits

Everything that you used to do with the mouse, you now do with the keyboard using editing commands that compose with movement commands. Here’s where Vim’s interface starts to look like a programming language. Vim’s editing commands are also called “verbs”, because verbs act on nouns.

-   `i` enter Insert mode
    -   but for manipulating/deleting text, want to use something more than backspace
-   `o` / `O` insert line below / above
-   `d{motion}` delete {motion}
    -   e.g. `dw` is delete word, `d$` is delete to end of line, `d0` is delete to beginning of line
-   `c{motion}` change {motion}
    -   e.g. `cw` is change word
    -   like `d{motion}` followed by `i`
-   `x` delete character (equal do `dl`)
-   `s` substitute character (equal to `cl`)
-   Visual mode + manipulation
    -   select text, `d` to delete it or `c` to change it
-   `u` to undo, `<C-r>` to redo
-   `y` to copy / “yank” (some other commands like `d` also copy)
-   `p` to paste
-   Lots more to learn: e.g. `~` flips the case of a character

### Counts

You can combine nouns and verbs with a count, which will perform a given action a number of times.

-   `3w` move 3 words forward
-   `5j` move 5 lines down
-   `7dw` delete 7 words

### Modifiers

You can use modifiers to change the meaning of a noun. Some modifiers are `i`, which means “inner” or “inside”, and `a`, which means “around”.

-   `ci(` change the contents inside the current pair of parentheses
-   `ci[` change the contents inside the current pair of square brackets
-   `da'` delete a single-quoted string, including the surrounding single quotes

## 3.6 Demo

Here is a broken [fizz buzz](https://en.wikipedia.org/wiki/Fizz_buzz) implementation:

```python
def fizz_buzz(limit):
    for i in range(limit):
        if i % 3 == 0:
            print('fizz')
        if i % 5 == 0:
            print('fizz')
        if i % 3 and i % 5:
            print(i)

def main():
    fizz_buzz(10)
```

We will fix the following issues:

-   Main is never called
-   Starts at 0 instead of 1
-   Prints “fizz” and “buzz” on separate lines for multiples of 15
-   Prints “fizz” for multiples of 5
-   Uses a hard-coded argument of 10 instead of taking a command-line argument

See the lecture video for the demonstration. Compare how the above changes are made using Vim to how you might make the same edits using another program. Notice how very few keystrokes are required in Vim, allowing you to edit at the speed you think.

## 3.7 Customizing Vim

Vim is customized through a plain-text configuration file in `~/.vimrc` (containing Vimscript commands). There are probably lots of basic settings that you want to turn on.

We are providing a well-documented basic config that you can use as a starting point. We recommend using this because it fixes some of Vim’s quirky default behavior. **Download our config [here](https://missing.csail.mit.edu/2020/files/vimrc) and save it to `~/.vimrc`.**

Vim is heavily customizable, and it’s worth spending time exploring customization options. You can look at people’s dotfiles on GitHub for inspiration, for example, your instructors’ Vim configs ([Anish](https://github.com/anishathalye/dotfiles/blob/master/vimrc), [Jon](https://github.com/jonhoo/configs/blob/master/editor/.config/nvim/init.vim) (uses [neovim](https://neovim.io/)), [Jose](https://github.com/JJGO/dotfiles/blob/master/vim/.vimrc)). There are lots of good blog posts on this topic too. Try not to copy-and-paste people’s full configuration, but read it, understand it, and take what you need.

## 3.8 Extending Vim

There are tons of plugins for extending Vim. Contrary to outdated advice that you might find on the internet, you do _not_ need to use a plugin manager for Vim (since Vim 8.0). Instead, you can use the built-in package management system. Simply create the directory `~/.vim/pack/vendor/start/`, and put plugins in there (e.g. via `git clone`).

Here are some of our favorite plugins:

-   [ctrlp.vim](https://github.com/ctrlpvim/ctrlp.vim): fuzzy file finder
-   [ack.vim](https://github.com/mileszs/ack.vim): code search
-   [nerdtree](https://github.com/scrooloose/nerdtree): file explorer
-   [vim-easymotion](https://github.com/easymotion/vim-easymotion): magic motions

We’re trying to avoid giving an overwhelmingly long list of plugins here. You can check out the instructors’ dotfiles ([Anish](https://github.com/anishathalye/dotfiles), [Jon](https://github.com/jonhoo/configs), [Jose](https://github.com/JJGO/dotfiles)) to see what other plugins we use. Check out [Vim Awesome](https://vimawesome.com/) for more awesome Vim plugins. There are also tons of blog posts on this topic: just search for “best Vim plugins”.

## 3.9 Vim-mode in other programs

Many tools support Vim emulation. The quality varies from good to great; depending on the tool, it may not support the fancier Vim features, but most cover the basics pretty well.

### Shell

If you’re a Bash user, use `set -o vi`. If you use Zsh, `bindkey -v`. For Fish, `fish_vi_key_bindings`. Additionally, no matter what shell you use, you can `export EDITOR=vim`. This is the environment variable used to decide which editor is launched when a program wants to start an editor. For example, `git` will use this editor for commit messages.

### Readline

Many programs use the [GNU Readline](https://tiswww.case.edu/php/chet/readline/rltop.html) library for their command-line interface. Readline supports (basic) Vim emulation too, which can be enabled by adding the following line to the `~/.inputrc` file:

```
set editing-mode vi
```

With this setting, for example, the Python REPL will support Vim bindings.

### Others

There are even vim keybinding extensions for web [browsers](http://vim.wikia.com/wiki/Vim_key_bindings_for_web_browsers) - some popular ones are [Vimium](https://chrome.google.com/webstore/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb?hl=en) for Google Chrome and [Tridactyl](https://github.com/tridactyl/tridactyl) for Firefox. You can even get Vim bindings in [Jupyter notebooks](https://github.com/lambdalisue/jupyter-vim-binding). Here is a [long list](https://reversed.top/2016-08-13/big-list-of-vim-like-software) of software with vim-like keybindings.

## 3.10 Advanced Vim

Here are a few examples to show you the power of the editor. We can’t teach you all of these kinds of things, but you’ll learn them as you go. A good heuristic: whenever you’re using your editor and you think “there must be a better way of doing this”, there probably is: look it up online.

### Search and replace

`:s` (substitute) command ([documentation](http://vim.wikia.com/wiki/Search_and_replace)).

-   `%s/foo/bar/g`
    -   replace foo with bar globally in file
-   `%s/\[.*\](\(.*\))/\1/g`
    -   replace named Markdown links with plain URLs

### Multiple windows

-   `:sp` / `:vsp` to split windows
-   Can have multiple views of the same buffer.

### Macros

-   `q{character}` to start recording a macro in register `{character}`
-   `q` to stop recording
-   `@{character}` replays the macro
-   Macro execution stops on error
-   `{number}@{character}` executes a macro {number} times
-   Macros can be recursive
    -   first clear the macro with `q{character}q`
    -   record the macro, with `@{character}` to invoke the macro recursively (will be a no-op until recording is complete)
-   Example: convert xml to json ([file](https://missing.csail.mit.edu/2020/files/example-data.xml))
    -   Array of objects with keys “name” / “email”
    -   Use a Python program?
    -   Use sed / regexes
        -   `g/people/d`
        -   `%s/<person>/{/g`
        -   `%s/<name>\(.*\)<\/name>/"name": "\1",/g`
        -   …
    -   Vim commands / macros
        -   `Gdd`, `ggdd` delete first and last lines
        -   Macro to format a single element (register `e`)
            -   Go to line with `<name>`
            -   `qe^r"f>s": "<ESC>f<C"<ESC>q`
        -   Macro to format a person
            -   Go to line with `<person>`
            -   `qpS{<ESC>j@eA,<ESC>j@ejS},<ESC>q`
        -   Macro to format a person and go to the next person
            -   Go to line with `<person>`
            -   `qq@pjq`
        -   Execute macro until end of file
            -   `999@q`
        -   Manually remove last `,` and add `[` and `]` delimiters

## 3.11 Resources

-   `vimtutor` is a tutorial that comes installed with Vim - if Vim is installed, you should be able to run `vimtutor` from your shell
-   [Vim Adventures](https://vim-adventures.com/) is a game to learn Vim
-   [Vim Tips Wiki](http://vim.wikia.com/wiki/Vim_Tips_Wiki)
-   [Vim Advent Calendar](https://vimways.org/2019/) has various Vim tips
-   [Vim Golf](http://www.vimgolf.com/) is [code golf](https://en.wikipedia.org/wiki/Code_golf), but where the programming language is Vim’s UI
-   [Vi/Vim Stack Exchange](https://vi.stackexchange.com/)
-   [Vim Screencasts](http://vimcasts.org/)
-   [Practical Vim](https://pragprog.com/titles/dnvim2/) (book)

## 3.12 Exercises

1.  Complete `vimtutor`. Note: it looks best in a [80x24](https://en.wikipedia.org/wiki/VT100) (80 columns by 24 lines) terminal window.
2.  Download our [basic vimrc](https://missing.csail.mit.edu/2020/files/vimrc) and save it to `~/.vimrc`. Read through the well-commented file (using Vim!), and observe how Vim looks and behaves slightly differently with the new config.
3.  Install and configure a plugin: [ctrlp.vim](https://github.com/ctrlpvim/ctrlp.vim).
    1.  Create the plugins directory with `mkdir -p ~/.vim/pack/vendor/start`
    2.  Download the plugin: `cd ~/.vim/pack/vendor/start; git clone https://github.com/ctrlpvim/ctrlp.vim`
    3.  Read the [documentation](https://github.com/ctrlpvim/ctrlp.vim/blob/master/readme.md) for the plugin. Try using CtrlP to locate a file by navigating to a project directory, opening Vim, and using the Vim command-line to start `:CtrlP`.
    4.  Customize CtrlP by adding [configuration](https://github.com/ctrlpvim/ctrlp.vim/blob/master/readme.md#basic-options) to your `~/.vimrc` to open CtrlP by pressing Ctrl-P.
4.  To practice using Vim, re-do the [Demo](https://missing.csail.mit.edu/2020/editors/#demo) from lecture on your own machine.
5.  Use Vim for _all_ your text editing for the next month. Whenever something seems inefficient, or when you think “there must be a better way”, try Googling it, there probably is. If you get stuck, come to office hours or send us an email.
6.  Configure your other tools to use Vim bindings (see instructions above).
7.  Further customize your `~/.vimrc` and install more plugins.
8.  (Advanced) Convert XML to JSON ([example file](https://missing.csail.mit.edu/2020/files/example-data.xml)) using Vim macros. Try to do this on your own, but you can look at the [macros](https://missing.csail.mit.edu/2020/editors/#macros) section above if you get stuck.

# 4. Data Wrangling

本节主要讲的是正则表达式和sed程序的使用，放官方笔记：

Have you ever wanted to **take data in one format and turn it into a different format**? Of course you have! That, in very general terms, is what this lecture is all about. Specifically, massaging data, whether in text or binary format, until you end up with exactly what you wanted.

We’ve already seen some basic data wrangling in past lectures. Pretty much any time you use the `|` operator, you are performing some kind of data wrangling. Consider a command like `journalctl | grep -i intel`. It finds all system log entries that mention Intel (case insensitive). You may not think of it as wrangling data, but it is going from one format (your entire system log) to a format that is more useful to you (just the intel log entries). Most data wrangling is about knowing what tools you have at your disposal, and how to combine them.

Let’s start from the beginning. To wrangle data, we need two things: data to wrangle, and something to do with it. Logs often make for a good use-case, because you often want to investigate things about them, and reading the whole thing isn’t feasible. Let’s figure out who’s trying to log into my server by looking at my server’s log:

```shell
ssh myserver journalctl
```

That’s far too much stuff. Let’s limit it to ssh stuff:

```shell
ssh myserver journalctl | grep sshd
```

Notice that we’re using a pipe to stream a _remote_ file through `grep` on our local computer! `ssh` is magical, and we will talk more about it in the next lecture on the command-line environment. This is still way more stuff than we wanted though. And pretty hard to read. Let’s do better:

```shell
ssh myserver 'journalctl | grep sshd | grep "Disconnected from"' | less
```

Why the additional quoting? Well, our logs may be quite large, and it’s wasteful to stream it all to our computer and then do the filtering. Instead, we can do the filtering on the remote server, and then massage the data locally. `less` gives us a “pager” that allows us to scroll up and down through the long output. To save some additional traffic while we debug our command-line, we can even stick the current filtered logs into a file so that we don’t have to access the network while developing:

```shell
$ ssh myserver 'journalctl | grep sshd | grep "Disconnected from"' > ssh.log
$ less ssh.log
```

There’s still a lot of noise here. There are _a lot_ of ways to get rid of that, but let’s look at one of the most powerful tools in your toolkit: `sed`.

`sed` is a “stream editor” that builds on top of the old `ed` editor. In it, you basically give short commands for how to modify the file, rather than manipulate its contents directly (although you can do that too). There are tons of commands, but one of the most common ones is `s`: substitution. For example, we can write:

```shell
ssh myserver journalctl
 | grep sshd
 | grep "Disconnected from"
 | sed 's/.*Disconnected from //'
```

What we just wrote was a simple _regular expression_; a powerful construct that lets you match text against patterns. The `s` command is written on the form: `s/REGEX/SUBSTITUTION/`, where `REGEX` is the regular expression you want to search for, and `SUBSTITUTION` is the text you want to substitute matching text with.

(You may recognize this syntax from the “Search and replace” section of our Vim [lecture notes](https://missing.csail.mit.edu/2020/editors/#advanced-vim)! Indeed, Vim uses a syntax for searching and replacing that is similar to `sed`’s substitution command. Learning one tool often helps you become more proficient with others.)

## 4.1 Regular expressions

Regular expressions are common and useful enough that it’s worthwhile to take some time to understand how they work. Let’s start by looking at the one we used above: `/.*Disconnected from /`. Regular expressions are usually (though not always) surrounded by `/`. Most ASCII characters just carry their normal meaning, but some characters have “special” matching behavior. Exactly which characters do what vary somewhat between different implementations of regular expressions, which is a source of great frustration. Very common patterns are:

-   `.` means “any single character” except newline
-   `*` zero or more of the preceding match
-   `+` one or more of the preceding match
-   `[abc]` any one character of `a`, `b`, and `c`
-   `(RX1|RX2)` either something that matches `RX1` or `RX2`
-   `^` the start of the line
-   `$` the end of the line

`sed`’s regular expressions are somewhat weird, and will require you to put a `\` before most of these to give them their special meaning. Or you can pass `-E`.

So, looking back at `/.*Disconnected from /`, we see that it matches any text that starts with any number of characters, followed by the literal string “Disconnected from ”. Which is what we wanted. But

beware, regular expressions are trixy. What if someone tried to log in with the username “Disconnected from”? We’d have:

```shell
Jan 17 03:13:00 thesquareplanet.com sshd[2631]: Disconnected from invalid user Disconnected from 46.97.239.16 port 55920 [preauth]
```

What would we end up with? Well, `*` and `+` are, by default, “greedy”. They will match as much text as they can. So, in the above, we’d end up with just

```shell
46.97.239.16 port 55920 [preauth]
```

Which may not be what we wanted. In some regular expression implementations, you can just suffix `*` or `+` with a `?` to make them non-greedy, but sadly `sed` doesn’t support that. We _could_ switch to perl’s command-line mode though, which _does_ support that construct:

```
perl -pe 's/.*?Disconnected from //'
```

We’ll stick to `sed` for the rest of this, because it’s by far the more common tool for these kinds of jobs. `sed` can also do other handy things like print lines following a given match, do multiple substitutions per invocation, search for things, etc. But we won’t cover that too much here. `sed` is basically an entire topic in and of itself, but there are often better tools.

Okay, so we also have a suffix we’d like to get rid of. How might we do that? It’s a little tricky to match just the text that follows the username, especially if the username can have spaces and such! What we need to do is match the _whole_ line:

```shell
 | sed -E 's/.*Disconnected from (invalid |authenticating )?user .* [^ ]+ port [0-9]+( \[preauth\])?$//'
```

Let’s look at what’s going on with a [regex debugger](https://regex101.com/r/qqbZqh/2). Okay, so the start is still as before. Then, we’re matching any of the “user” variants (there are two prefixes in the logs). Then we’re matching on any string of characters where the username is. Then we’re matching on any single word (`[^ ]+`; any non-empty sequence of non-space characters). Then the word “port” followed by a sequence of digits. Then possibly the suffix `[preauth]`, and then the end of the line.

Notice that with this technique, as username of “Disconnected from” won’t confuse us any more. Can you see why?

There is one problem with this though, and that is that the entire log becomes empty. We want to _keep_ the username after all. For this, we can use “capture groups”. Any text matched by a regex surrounded by parentheses is stored in a numbered capture group. These are available in the substitution (and in some engines, even in the pattern itself!) as `\1`, `\2`, `\3`, etc. So:

```shell
 | sed -E 's/.*Disconnected from (invalid |authenticating )?user (.*) [^ ]+ port [0-9]+( \[preauth\])?$/\2/'
```

As you can probably imagine, you can come up with _really_ complicated regular expressions. For example, here’s an article on how you might match an [e-mail address](https://www.regular-expressions.info/email.html). It’s [not easy](https://emailregex.com/). And there’s [lots of discussion](https://stackoverflow.com/questions/201323/how-to-validate-an-email-address-using-a-regular-expression/1917982). And people have [written tests](https://fightingforalostcause.net/content/misc/2006/compare-email-regex.php). And [test matrices](https://mathiasbynens.be/demo/url-regex). You can even write a regex for determining if a given number [is a prime number](https://www.noulakaz.net/2007/03/18/a-regular-expression-to-check-for-prime-numbers/).

Regular expressions are notoriously hard to get right, but they are also very handy to have in your toolbox!

## 4.2 Back to data wrangling

Okay, so we now have

```shell
ssh myserver journalctl
 | grep sshd
 | grep "Disconnected from"
 | sed -E 's/.*Disconnected from (invalid |authenticating )?user (.*) [^ ]+ port [0-9]+( \[preauth\])?$/\2/'
```

`sed` can do all sorts of other interesting things, like injecting text (with the `i` command), explicitly printing lines (with the `p` command), selecting lines by index, and lots of other things. Check `man sed`!

Anyway. What we have now gives us a list of all the usernames that have attempted to log in. But this is pretty unhelpful. Let’s look for common ones:

```shell
ssh myserver journalctl
 | grep sshd
 | grep "Disconnected from"
 | sed -E 's/.*Disconnected from (invalid |authenticating )?user (.*) [^ ]+ port [0-9]+( \[preauth\])?$/\2/'
 | sort | uniq -c
```

`sort` will, well, sort its input. `uniq -c` will collapse consecutive lines that are the same into a single line, prefixed with a count of the number of occurrences. We probably want to sort that too and only keep the most common usernames:

```shell
ssh myserver journalctl
 | grep sshd
 | grep "Disconnected from"
 | sed -E 's/.*Disconnected from (invalid |authenticating )?user (.*) [^ ]+ port [0-9]+( \[preauth\])?$/\2/'
 | sort | uniq -c
 | sort -nk1,1 | tail -n10
```

`sort -n` will sort in numeric (instead of lexicographic) order. `-k1,1` means “sort by only the first whitespace-separated column”. The `,n` part says “sort until the `n`th field, where the default is the end of the line. In this _particular_ example, sorting by the whole line wouldn’t matter, but we’re here to learn!

If we wanted the _least_ common ones, we could use `head` instead of `tail`. There’s also `sort -r`, which sorts in reverse order.

Okay, so that’s pretty cool, but what if we’d like these extract only the usernames as a comma-separated list instead of one per line, perhaps for a config file?

```shell
ssh myserver journalctl
 | grep sshd
 | grep "Disconnected from"
 | sed -E 's/.*Disconnected from (invalid |authenticating )?user (.*) [^ ]+ port [0-9]+( \[preauth\])?$/\2/'
 | sort | uniq -c
 | sort -nk1,1 | tail -n10
 | awk '{print $2}' | paste -sd,
```

If you’re using macOS: note that the command as shown won’t work with the BSD `paste` shipped with macOS. See [exercise 4 from the shell tools lecture](https://missing.csail.mit.edu/2020/shell-tools/#exercises) for more on the difference between BSD and GNU coreutils and instructions for how to install GNU coreutils on macOS.

Let’s start with `paste`: it lets you combine lines (`-s`) by a given single-character delimiter (`-d`; `,` in this case). But what’s this `awk` business?

## 4.3 awk – another editor

`awk` is a programming language that just happens to be really good at processing text streams. There is _a lot_ to say about `awk` if you were to learn it properly, but as with many other things here, we’ll just go through the basics.

First, what does `{print $2}` do? Well, `awk` programs take the form of an optional pattern plus a block saying what to do if the pattern matches a given line. The default pattern (which we used above) matches all lines. Inside the block, `$0` is set to the entire line’s contents, and `$1` through `$n` are set to the `n`th _field_ of that line, when separated by the `awk` field separator (whitespace by default, change with `-F`). In this case, we’re saying that, for every line, print the contents of the second field, which happens to be the username!

Let’s see if we can do something fancier. Let’s compute the number of single-use usernames that start with `c` and end with `e`:

```shell
 | awk '$1 == 1 && $2 ~ /^c[^ ]*e$/ { print $2 }' | wc -l
```

There’s a lot to unpack here. First, notice that we now have a pattern (the stuff that goes before `{...}`). The pattern says that the first field of the line should be equal to 1 (that’s the count from `uniq -c`), and that the second field should match the given regular expression. And the block just says to print the username. We then count the number of lines in the output with `wc -l`.

However, `awk` is a programming language, remember?

```shell
BEGIN { rows = 0 }
$1 == 1 && $2 ~ /^c[^ ]*e$/ { rows += $1 }
END { print rows }
```

`BEGIN` is a pattern that matches the start of the input (and `END` matches the end). Now, the per-line block just adds the count from the first field (although it’ll always be 1 in this case), and then we print it out at the end. In fact, we _could_ get rid of `grep` and `sed` entirely, because `awk` [can do it all](https://backreference.org/2010/02/10/idiomatic-awk/), but we’ll leave that as an exercise to the reader.

## 4.4 Analyzing data

You can do math directly in your shell using `bc`, a calculator that can read from STDIN! For example, add the numbers on each line together by concatenating them together, delimited by `+`:

```shell
 | paste -sd+ | bc -l
```

Or produce more elaborate expressions:

```shell
echo "2*($(data | paste -sd+))" | bc -l
```

You can get stats in a variety of ways. [`st`](https://github.com/nferraz/st) is pretty neat, but if you already have [R](https://www.r-project.org/):

```shell
ssh myserver journalctl
 | grep sshd
 | grep "Disconnected from"
 | sed -E 's/.*Disconnected from (invalid |authenticating )?user (.*) [^ ]+ port [0-9]+( \[preauth\])?$/\2/'
 | sort | uniq -c
 | awk '{print $1}' | R --no-echo -e 'x <- scan(file="stdin", quiet=TRUE); summary(x)'
```

R is another (weird) programming language that’s great at data analysis and [plotting](https://ggplot2.tidyverse.org/). We won’t go into too much detail, but suffice to say that `summary` prints summary statistics for a vector, and we created a vector containing the input stream of numbers, so R gives us the statistics we wanted!

If you just want some simple plotting, `gnuplot` is your friend:

```shell
ssh myserver journalctl
 | grep sshd
 | grep "Disconnected from"
 | sed -E 's/.*Disconnected from (invalid |authenticating )?user (.*) [^ ]+ port [0-9]+( \[preauth\])?$/\2/'
 | sort | uniq -c
 | sort -nk1,1 | tail -n10
 | gnuplot -p -e 'set boxwidth 0.5; plot "-" using 1:xtic(2) with boxes'
```

## 4.5 Data wrangling to make arguments

Sometimes you want to do data wrangling to find things to install or remove based on some longer list. The data wrangling we’ve talked about so far + `xargs` can be a powerful combo.

For example, as seen in lecture, I can use the following command to uninstall old nightly builds of Rust from my system by extracting the old build names using data wrangling tools and then passing them via `xargs` to the uninstaller:

```shell
rustup toolchain list | grep nightly | grep -vE "nightly-x86" | sed 's/-x86.*//' | xargs rustup toolchain uninstall
```

## 4.6 Wrangling binary data

So far, we have mostly talked about wrangling textual data, but pipes are just as useful for binary data. For example, we can use ffmpeg to capture an image from our camera, convert it to grayscale, compress it, send it to a remote machine over SSH, decompress it there, make a copy, and then display it.

```shell
ffmpeg -loglevel panic -i /dev/video0 -frames 1 -f image2 -
 | convert - -colorspace gray -
 | gzip
 | ssh mymachine 'gzip -d | tee copy.jpg | env DISPLAY=:0 feh -'
```

## 4.7 Exercises

1.  Take this [short interactive regex tutorial](https://regexone.com/).
2.  Find the number of words (in `/usr/share/dict/words`) that contain at least three `a`s and don’t have a `'s` ending. What are the three most common last two letters of those words? `sed`’s `y` command, or the `tr` program, may help you with case insensitivity. How many of those two-letter combinations are there? And for a challenge: which combinations do not occur?
3.  To do in-place substitution it is quite tempting to do something like `sed s/REGEX/SUBSTITUTION/ input.txt > input.txt`. However this is a bad idea, why? Is this particular to `sed`? Use `man sed` to find out how to accomplish this.
4.  Find your average, median, and max system boot time over the last ten boots. Use `journalctl` on Linux and `log show` on macOS, and look for log timestamps near the beginning and end of each boot. On Linux, they may look something like:

    ```
    Logs begin at ...
    ```   
    
    and
    
    ```
    systemd[577]: Startup finished in ...
    ```
    
    On macOS, [look for](https://eclecticlight.co/2018/03/21/macos-unified-log-3-finding-your-way/):
    
    ```
    === system boot:
    ```
    
    and
    
    ```
    Previous shutdown cause: 5
    ```
    
5.  Look for boot messages that are _not_ shared between your past three reboots (see `journalctl`’s `-b` flag). Break this task down into multiple steps. First, find a way to get just the logs from the past three boots. There may be an applicable flag on the tool you use to extract the boot logs, or you can use `sed '0,/STRING/d'` to remove all lines previous to one that matches `STRING`. Next, remove any parts of the line that _always_ varies (like the timestamp). Then, de-duplicate the input lines and keep a count of each one (`uniq` is your friend). And finally, eliminate any line whose count is 3 (since it _was_ shared among all the boots).
6.  Find an online data set like [this one](https://stats.wikimedia.org/EN/TablesWikipediaZZ.htm), [this one](https://ucr.fbi.gov/crime-in-the-u.s/2016/crime-in-the-u.s.-2016/topic-pages/tables/table-1), or maybe one [from here](https://www.springboard.com/blog/free-public-data-sets-data-science-project/). Fetch it using `curl` and extract out just two columns of numerical data. If you’re fetching HTML data, [`pup`](https://github.com/EricChiang/pup) might be helpful. For JSON data, try [`jq`](https://stedolan.github.io/jq/). Find the min and max of one column in a single command, and the difference of the sum of each column in another.

# 5. Command-line Environment

## 5.1 Job Control

sleep是一个程序，可以直接在终端里敲，就是进行睡眠。 在睡眠的时候，我们按ctrl + C，可以终止这个程序，那么原理是什么？实际上，在按ctrl + c的时候，就会给该进程发一个信号，叫做`SIGINT`，也就是中断(interrupt)的信号。因此，我们完全可以在进程中就捕获这个信号，并去做相应的处理。下面写一个程序，这个程序用ctrl + c也停止不了：

```c
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <signal.h>

void handler(int signum){
    printf("I got %d signum, but I don't deal with it.\n", signum);
}

int main(){
    int i = 0;
    signal(SIGINT, handler);
    while(1){
        sleep(1);
        printf("%d", i++);
        fflush(stdout);
        printf("\r\033[k");
    }
    return 0;
}
```

我们在下面这句话中注册了信号处理：

```c
signal(SIGINT, handler);
```

第一个参数是我们要注册什么信号；第二个参数是注册到信号后干嘛。signal函数会将信号自动传递给函数，因此我们在handler函数中就能接收到SIGINT这个信号。下面是这个程序执行的结果，按了ctrl + c之后还是停止不了：

![[Study Log/resources/Pasted image 20221219213915.png]]

> 这个程序的更多细节可以在[[Article/story/2022-12-19|我的开发日记]]里看到。

那么问题来了，如何停止呢？答案是按ctrl + \\，这其实是发送了一个SIGQUIT信号，而这个程序不能处理SIGQUIT信号，因此终止了。

---

当我们想停止程序的时候，可以按ctrl + z：

![[Study Log/resources/Pasted image 20221219214448.png]]

这个时候进程其实并没有结束，那么在哪里呢？我们通过`jobs`命令可以看到：

![[Study Log/resources/Pasted image 20221219214540.png]]

可以看到它的状态是stopped，所以并不是真正被杀死了，只是被暂停了。那么如何让它继续呢？在说这个之前，先说一件事，就是有些进程，比如在一个很大的文件夹里找一个文件。这种进程会持续很久，我们如果不想让它干扰我们的操作，就要让它在后台运行。如何做到呢？像这样： ^acf89f

```shell
sleep 1000 &
```

只需要在最后加上一个`&`符号，这个进程就会在后台执行了。

![[Study Log/resources/Pasted image 20221219214848.png]]

然后，如果我要让这个正在后台进程的程序暂停，该如何做到呢？这时就可以用`kill`指令。我们早就知道kill指令可以发送信号给进程，所以只需要：

![[Study Log/resources/Pasted image 20221219215023.png]]

这样我们就看到第二个进程被暂停了。接下来就回到了[[#^acf89f|前面的问题]]：如何让它继续？这里就涉及到了两种启动任务的命令：

* `bg` - background
* `fg` - foreground

![[Study Log/resources/Pasted image 20221219215310.png]]

---

需要强调的是SIGHUP这个信号，这表示hung up，也就是挂断的时候的信号。当这个进程的终端被关掉时，这个进程就会收到这个信号，那么自然这个进程也会结束。我们可以做个实验：给一个进程发送SIGHUP，**之后这个进程在很短的时间内会处于hungup状态，然后马上就死了**：

![[Study Log/resources/Pasted image 20221219215818.png]]

然而有一种命令可以无视这种信号，这样在终端挂掉的时候，这个进程还是会继续进行下去。这种进程是使用nohup启动的：

```shell
nohup sleep 1001 &
```

![[Study Log/resources/Pasted image 20221219220144.png]]

> 这个时候，向这个进程发送SIGHUP：
>  * 如果这个进程正在运行，它会无视SIGHUP，继续运行；
>  * 如果这个进程已经停止，它不但不会死掉，反而还是会继续运行。

## 5.2 Terminal Multiplexer

### 5.2.1 Session

将终端变成多窗口！超级炫酷！目前最常用的Multiplexer就是tmux。我们安装好之后，只需要输入下面的命令：

```shell
tmux
```

就可以开启一个新的终端(好像是这样)：

![[Study Log/resources/Pasted image 20230111141316.png]]

但是，实际上我们只是新建了一个session。每使用一次`tmux`命令，都会新建一个session。我们可以把它当成一个新的终端来使用：

![[Study Log/resources/Pasted image 20230111141354.png]]

从当前的session**暂时**返回到主终端，我们可以这样做：先按`Ctrl + b`，然后再按一下`d`。我们也能发现，在主终端上出现了下面的字样：

![[Study Log/resources/Pasted image 20230111141421.png]]

`detach`就表示暂时断开连接，attach的反义词。因此我们又会到了主终端。但是，那个session中的程序实际上还是在运行的，我们可以使用如下命令返回到那个session：

```shell
tmux a
```

我们也可以使用下面的命令来列出当前新建了多少个session：

```shell
tmux ls
```

![[Study Log/resources/Pasted image 20230111141445.png]]

还可以给新建的session起一个名字：

```shell
tmux new -t haha
```

这样我们就新建了一个名叫haha的session。和之前默认的一起，我们可以看到它们的情况：

![[Study Log/resources/Pasted image 20230111141522.png]]

有了多个session，还可以通过session的编号和名字去attach它们：

```shell
tmux a -t 0
tmux a -t haha
```

### 5.2.2 Window

说完了session，下面看看每个session里都能干什么。实际上，session中的操作和vim多窗口有点像。我们可以按`Ctrl + b`，然后再按一下`c`来create一个新的window：

在屏幕的最下面能看到当前处于哪一个window。下一个问题显而易见了：怎么在Window之间切换呢？使用`Ctrl + b`和`p`来切换到上一个(previous)window；使用`Ctrl + b`和`n`来切换到下一个(next)window。

session可以改名字，window当然也可以改！在当前的window下，使用`Ctrl + b`和`,`来给当前的window改名字：

![[Study Log/resources/Pasted image 20230111141640.png]]

> 第三个window被改成了spreadzhao。

每个window都有编号，从0开始。我们也可以使用`Ctrl + b`和数字来定位到那个window。

### 5.2.3 Pane

到目前为止，我们也只是实现了类似浏览器标签那种样子，但是真正的分屏多窗口还没有实现。而pane就是用来做这件事的。每一个window都可以新建若干个pane，使用`Ctrl + b`和`"`在当前window下分两屏：

![[Study Log/resources/Pasted image 20230111141824.png]]

可以看到，这样是垂直切割。那么怎么水平切割呢？使用`Ctrl + b`和`%`就可以了：

![[Study Log/resources/Pasted image 20230111141856.png]]

和window一样，如何在pane之前来回切换呢？使用`Ctrl + b`和`方向键`就可以了。如果我觉得这种排版不合适，可以使用`Ctrl + b`和`space`。多用几次，它会给你不同的排版：

![[Study Log/resources/Pasted image 20230111141917.png]]

比如我在某一个pane里打开vim，发现窗口太小了，怎么放大呢？使用`Ctrl + b`和z来放大(zoom)当前窗口。如果我用完了，再来一遍就可以缩回去。

![[Study Log/resources/Pasted image 20230111142035.png]]

![[Study Log/resources/Pasted image 20230111142101.png]]

**最后来说一下关闭。不管是pane，window还是session，统一使用`Ctrl + d`来关闭**。

## 5.3 Dotfiles

dotfile实际上就是那些前面带点的文件：`.bashrc`，`.vimrc`，`.gitignore`等等。这些都是配置文件，而通常它们都在`~`目录下。这些东西就是每次打开一个终端的时候都会加载好的，因此这些配置虽然不写到环境变量里，但是却随时都能生效。

我们有时候可能会有这样的需求：某一个配置文件在一个仓库里用，但是这个仓库的配置和我本机的配置不一样。而且这个配置文件还总会变。那我该咋办？如果每写一个项目就要改一下配置文件那也太麻烦了！所以才有了dotfile repository的概念。我们将用户目录改成下面的结构：

![[Study Log/resources/Pasted image 20230111133634.png]]

这两个最基础的`.bashrc`和`.vimrc`里并没有内容，只是有链接。它们指向不同的配置文件。使用这种方式，当我们想要切换文件的时候，只需要把这个指向的链接修改了就可以了。

#idea 其实这种思想和项目里经常看到的多重include很像。我经常在项目里看到，某一个.h文件打开之后就一句话，就是include了许多.h。这种做法其实也是为了便于切换引用的库。

## 5.4 Lecture Notes

In this lecture we will go through several ways in which you can improve your workflow when using the shell. We have been working with the shell for a while now, but we have mainly focused on executing different commands. We will now see how to run several processes at the same time while keeping track of them, how to stop or pause a specific process and how to make a process run in the background.

We will also learn about different ways to improve your shell and other tools, by defining aliases and configuring them using dotfiles. Both of these can help you save time, e.g. by using the same configurations in all your machines without having to type long commands. We will look at how to work with remote machines using SSH.

### 5.4.1 Job Control

In some cases you will need to interrupt a job while it is executing, for instance if a command is taking too long to complete (such as a `find` with a very large directory structure to search through). Most of the time, you can do `Ctrl-C` and the command will stop. But how does this actually work and why does it sometimes fail to stop the process?

#### 5.4.1.1Killing a process

Your shell is using a UNIX communication mechanism called a _signal_ to communicate information to the process. When a process receives a signal it stops its execution, deals with the signal and potentially changes the flow of execution based on the information that the signal delivered. For this reason, signals are _software interrupts_.

In our case, when typing `Ctrl-C` this prompts the shell to deliver a `SIGINT` signal to the process.

Here’s a minimal example of a Python program that captures `SIGINT` and ignores it, no longer stopping. To kill this program we can now use the `SIGQUIT` signal instead, by typing `Ctrl-\`.

```shell
#!/usr/bin/env python
import signal, time

def handler(signum, time):
    print("\nI got a SIGINT, but I am not stopping")

signal.signal(signal.SIGINT, handler)
i = 0
while True:
    time.sleep(.1)
    print("\r{}".format(i), end="")
    i += 1
```

Here’s what happens if we send `SIGINT` twice to this program, followed by `SIGQUIT`. Note that `^` is how `Ctrl` is displayed when typed in the terminal.

```shell
$ python sigint.py
24^C
I got a SIGINT, but I am not stopping
26^C
I got a SIGINT, but I am not stopping
30^\[1]    39913 quit       python sigint.py
```

While `SIGINT` and `SIGQUIT` are both usually associated with terminal related requests, a more generic signal for asking a process to exit gracefully is the `SIGTERM` signal. To send this signal we can use the [`kill`](https://www.man7.org/linux/man-pages/man1/kill.1.html) command, with the syntax `kill -TERM <PID>`.

#### 5.4.1.2 Pausing and backgrounding processes

Signals can do other things beyond killing a process. For instance, `SIGSTOP` pauses a process. In the terminal, typing `Ctrl-Z` will prompt the shell to send a `SIGTSTP` signal, short for Terminal Stop (i.e. the terminal’s version of `SIGSTOP`).

We can then continue the paused job in the foreground or in the background using [`fg`](https://www.man7.org/linux/man-pages/man1/fg.1p.html) or [`bg`](http://man7.org/linux/man-pages/man1/bg.1p.html), respectively.

The [`jobs`](https://www.man7.org/linux/man-pages/man1/jobs.1p.html) command lists the unfinished jobs associated with the current terminal session. You can refer to those jobs using their pid (you can use [`pgrep`](https://www.man7.org/linux/man-pages/man1/pgrep.1.html) to find that out). More intuitively, you can also refer to a process using the percent symbol followed by its job number (displayed by `jobs`). To refer to the last backgrounded job you can use the `$!` special parameter.

One more thing to know is that the `&` suffix in a command will run the command in the background, giving you the prompt back, although it will still use the shell’s STDOUT which can be annoying (use shell redirections in that case).

To background an already running program you can do `Ctrl-Z` followed by `bg`. Note that backgrounded processes are still children processes of your terminal and will die if you close the terminal (this will send yet another signal, `SIGHUP`). To prevent that from happening you can run the program with [`nohup`](https://www.man7.org/linux/man-pages/man1/nohup.1.html) (a wrapper to ignore `SIGHUP`), or use `disown` if the process has already been started. Alternatively, you can use a terminal multiplexer as we will see in the next section.

Below is a sample session to showcase some of these concepts.

```shell
$ sleep 1000
^Z
[1]  + 18653 suspended  sleep 1000

$ nohup sleep 2000 &
[2] 18745
appending output to nohup.out

$ jobs
[1]  + suspended  sleep 1000
[2]  - running    nohup sleep 2000

$ bg %1
[1]  - 18653 continued  sleep 1000

$ jobs
[1]  - running    sleep 1000
[2]  + running    nohup sleep 2000

$ kill -STOP %1
[1]  + 18653 suspended (signal)  sleep 1000

$ jobs
[1]  + suspended (signal)  sleep 1000
[2]  - running    nohup sleep 2000

$ kill -SIGHUP %1
[1]  + 18653 hangup     sleep 1000

$ jobs
[2]  + running    nohup sleep 2000

$ kill -SIGHUP %2

$ jobs
[2]  + running    nohup sleep 2000

$ kill %2
[2]  + 18745 terminated  nohup sleep 2000

$ jobs

```

A special signal is `SIGKILL` since it cannot be captured by the process and it will always terminate it immediately. However, it can have bad side effects such as leaving orphaned children processes.

You can learn more about these and other signals [here](https://en.wikipedia.org/wiki/Signal_(IPC)) or typing [`man signal`](https://www.man7.org/linux/man-pages/man7/signal.7.html) or `kill -l`.

### 5.4.2 Terminal Multiplexers

When using the command line interface you will often want to run more than one thing at once. For instance, you might want to run your editor and your program side by side. Although this can be achieved by opening new terminal windows, using a terminal multiplexer is a more versatile solution.

Terminal multiplexers like [`tmux`](https://www.man7.org/linux/man-pages/man1/tmux.1.html) allow you to multiplex terminal windows using panes and tabs so you can interact with multiple shell sessions. Moreover, terminal multiplexers let you detach a current terminal session and reattach at some point later in time. This can make your workflow much better when working with remote machines since it avoids the need to use `nohup` and similar tricks.

The most popular terminal multiplexer these days is [`tmux`](https://www.man7.org/linux/man-pages/man1/tmux.1.html). `tmux` is highly configurable and by using the associated keybindings you can create multiple tabs and panes and quickly navigate through them.

`tmux` expects you to know its keybindings, and they all have the form `<C-b> x` where that means (1) press `Ctrl+b`, (2) release `Ctrl+b`, and then (3) press `x`. `tmux` has the following hierarchy of objects:

-   **Sessions** - a session is an independent workspace with one or more windows
    -   `tmux` starts a new session.
    -   `tmux new -s NAME` starts it with that name.
    -   `tmux ls` lists the current sessions
    -   Within `tmux` typing `<C-b> d` detaches the current session
    -   `tmux a` attaches the last session. You can use `-t` flag to specify which
-   **Windows** - Equivalent to tabs in editors or browsers, they are visually separate parts of the same session
    -   `<C-b> c` Creates a new window. To close it you can just terminate the shells doing `<C-d>`
    -   `<C-b> N` Go to the _N_ th window. Note they are numbered
    -   `<C-b> p` Goes to the previous window
    -   `<C-b> n` Goes to the next window
    -   `<C-b> ,` Rename the current window
    -   `<C-b> w` List current windows
-   **Panes** - Like vim splits, panes let you have multiple shells in the same visual display.
    -   `<C-b> "` Split the current pane horizontally
    -   `<C-b> %` Split the current pane vertically
    -   `<C-b> <direction>` Move to the pane in the specified _direction_. Direction here means arrow keys.
    -   `<C-b> z` Toggle zoom for the current pane
    -   `<C-b> [` Start scrollback. You can then press `<space>` to start a selection and `<enter>` to copy that selection.
    -   `<C-b> <space>` Cycle through pane arrangements.

For further reading, [here](https://www.hamvocke.com/blog/a-quick-and-easy-guide-to-tmux/) is a quick tutorial on `tmux` and [this](http://linuxcommand.org/lc3_adv_termmux.php) has a more detailed explanation that covers the original `screen` command. You might also want to familiarize yourself with [`screen`](https://www.man7.org/linux/man-pages/man1/screen.1.html), since it comes installed in most UNIX systems.

### 5.4.3 Aliases

It can become tiresome typing long commands that involve many flags or verbose options. For this reason, most shells support _aliasing_. A shell alias is a short form for another command that your shell will replace automatically for you. For instance, an alias in bash has the following structure:

```shell
alias alias_name="command_to_alias arg1 arg2"
```

Note that there is no space around the equal sign `=`, because [`alias`](https://www.man7.org/linux/man-pages/man1/alias.1p.html) is a shell command that takes a single argument.

Aliases have many convenient features:

```shell
# Make shorthands for common flags
alias ll="ls -lh"

# Save a lot of typing for common commands
alias gs="git status"
alias gc="git commit"
alias v="vim"

# Save you from mistyping
alias sl=ls

# Overwrite existing commands for better defaults
alias mv="mv -i"           # -i prompts before overwrite
alias mkdir="mkdir -p"     # -p make parent dirs as needed
alias df="df -h"           # -h prints human readable format

# Alias can be composed
alias la="ls -A"
alias lla="la -l"

# To ignore an alias run it prepended with \
\ls
# Or disable an alias altogether with unalias
unalias la

# To get an alias definition just call it with alias
alias ll
# Will print ll='ls -lh'
```

Note that aliases do not persist shell sessions by default. To make an alias persistent you need to include it in shell startup files, like `.bashrc` or `.zshrc`, which we are going to introduce in the next section.

### 5.4.4 Dotfiles

Many programs are configured using plain-text files known as _dotfiles_ (because the file names begin with a `.`, e.g. `~/.vimrc`, so that they are hidden in the directory listing `ls` by default).

Shells are one example of programs configured with such files. On startup, your shell will read many files to load its configuration. Depending on the shell, whether you are starting a login and/or interactive the entire process can be quite complex. [Here](https://blog.flowblok.id.au/2013-02/shell-startup-scripts.html) is an excellent resource on the topic.

For `bash`, editing your `.bashrc` or `.bash_profile` will work in most systems. Here you can include commands that you want to run on startup, like the alias we just described or modifications to your `PATH` environment variable. In fact, many programs will ask you to include a line like `export PATH="$PATH:/path/to/program/bin"` in your shell configuration file so their binaries can be found.

Some other examples of tools that can be configured through dotfiles are:

-   `bash` - `~/.bashrc`, `~/.bash_profile`
-   `git` - `~/.gitconfig`
-   `vim` - `~/.vimrc` and the `~/.vim` folder
-   `ssh` - `~/.ssh/config`
-   `tmux` - `~/.tmux.conf`

How should you organize your dotfiles? They should be in their own folder, under version control, and **symlinked** into place using a script. This has the benefits of:

-   **Easy installation**: if you log in to a new machine, applying your customizations will only take a minute.
-   **Portability**: your tools will work the same way everywhere.
-   **Synchronization**: you can update your dotfiles anywhere and keep them all in sync.
-   **Change tracking**: you’re probably going to be maintaining your dotfiles for your entire programming career, and version history is nice to have for long-lived projects.

What should you put in your dotfiles? You can learn about your tool’s settings by reading online documentation or [man pages](https://en.wikipedia.org/wiki/Man_page). Another great way is to search the internet for blog posts about specific programs, where authors will tell you about their preferred customizations. Yet another way to learn about customizations is to look through other people’s dotfiles: you can find tons of [dotfiles repositories](https://github.com/search?o=desc&q=dotfiles&s=stars&type=Repositories) on Github — see the most popular one [here](https://github.com/mathiasbynens/dotfiles) (we advise you not to blindly copy configurations though). [Here](https://dotfiles.github.io/) is another good resource on the topic.

All of the class instructors have their dotfiles publicly accessible on GitHub: [Anish](https://github.com/anishathalye/dotfiles), [Jon](https://github.com/jonhoo/configs), [Jose](https://github.com/jjgo/dotfiles).

#### 5.4.4.1 Portability

A common pain with dotfiles is that the configurations might not work when working with several machines, e.g. if they have different operating systems or shells. Sometimes you also want some configuration to be applied only in a given machine.

There are some tricks for making this easier. If the configuration file supports it, use the equivalent of if-statements to apply machine specific customizations. For example, your shell could have something like:

```shell
if [[ "$(uname)" == "Linux" ]]; then {do_something}; fi

# Check before using shell-specific features
if [[ "$SHELL" == "zsh" ]]; then {do_something}; fi

# You can also make it machine-specific
if [[ "$(hostname)" == "myServer" ]]; then {do_something}; fi
```

If the configuration file supports it, make use of includes. For example, a `~/.gitconfig` can have a setting:

```shell
[include]
    path = ~/.gitconfig_local
```

And then on each machine, `~/.gitconfig_local` can contain machine-specific settings. You could even track these in a separate repository for machine-specific settings.

This idea is also useful if you want different programs to share some configurations. For instance, if you want both `bash` and `zsh` to share the same set of aliases you can write them under `.aliases` and have the following block in both:

```shell
# Test if ~/.aliases exists and source it
if [ -f ~/.aliases ]; then
    source ~/.aliases
fi
```

### 5.4.5 Remote Machines

It has become more and more common for programmers to use remote servers in their everyday work. If you need to use remote servers in order to deploy backend software or you need a server with higher computational capabilities, you will end up using a Secure Shell (SSH). As with most tools covered, SSH is highly configurable so it is worth learning about it.

To `ssh` into a server you execute a command as follows

```shell
ssh foo@bar.mit.edu
```

Here we are trying to ssh as user `foo` in server `bar.mit.edu`. The server can be specified with a URL (like `bar.mit.edu`) or an IP (something like `foobar@192.168.1.42`). Later we will see that if we modify ssh config file you can access just using something like `ssh bar`.

#### 5.4.5.1 Executing commands

An often overlooked feature of `ssh` is the ability to run commands directly. `ssh foobar@server ls` will execute `ls` in the home folder of foobar. It works with pipes, so `ssh foobar@server ls | grep PATTERN` will grep locally the remote output of `ls` and `ls | ssh foobar@server grep PATTERN` will grep remotely the local output of `ls`.

#### 5.4.5.2 SSH Keys

Key-based authentication exploits public-key cryptography to prove to the server that the client owns the secret private key without revealing the key. This way you do not need to reenter your password every time. Nevertheless, the private key (often `~/.ssh/id_rsa` and more recently `~/.ssh/id_ed25519`) is effectively your password, so treat it like so.

##### 5.4.5.2.1 Key generation

To generate a pair you can run [`ssh-keygen`](https://www.man7.org/linux/man-pages/man1/ssh-keygen.1.html).

```shell
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519
```

You should choose a passphrase, to avoid someone who gets hold of your private key to access authorized servers. Use [`ssh-agent`](https://www.man7.org/linux/man-pages/man1/ssh-agent.1.html) or [`gpg-agent`](https://linux.die.net/man/1/gpg-agent) so you do not have to type your passphrase every time.

If you have ever configured pushing to GitHub using SSH keys, then you have probably done the steps outlined [here](https://help.github.com/articles/connecting-to-github-with-ssh/) and have a valid key pair already. To check if you have a passphrase and validate it you can run `ssh-keygen -y -f /path/to/key`.

##### 5.4.5.2.2 Key based authentication

`ssh` will look into `.ssh/authorized_keys` to determine which clients it should let in. To copy a public key over you can use:

```shell
cat .ssh/id_ed25519.pub | ssh foobar@remote 'cat >> ~/.ssh/authorized_keys'
```

A simpler solution can be achieved with `ssh-copy-id` where available:

```shell
ssh-copy-id -i .ssh/id_ed25519 foobar@remote
```

#### 5.4.5.2 Copying files over SSH

There are many ways to copy files over ssh:

-   `ssh+tee`, the simplest is to use `ssh` command execution and STDIN input by doing `cat localfile | ssh remote_server tee serverfile`. Recall that [`tee`](https://www.man7.org/linux/man-pages/man1/tee.1.html) writes the output from STDIN into a file.
-   [`scp`](https://www.man7.org/linux/man-pages/man1/scp.1.html) when copying large amounts of files/directories, the secure copy `scp` command is more convenient since it can easily recurse over paths. The syntax is `scp path/to/local_file remote_host:path/to/remote_file`
-   [`rsync`](https://www.man7.org/linux/man-pages/man1/rsync.1.html) improves upon `scp` by detecting identical files in local and remote, and preventing copying them again. It also provides more fine grained control over symlinks, permissions and has extra features like the `--partial` flag that can resume from a previously interrupted copy. `rsync` has a similar syntax to `scp`.

#### 5.4.5.3 Port Forwarding

In many scenarios you will run into software that listens to specific ports in the machine. When this happens in your local machine you can type `localhost:PORT` or `127.0.0.1:PORT`, but what do you do with a remote server that does not have its ports directly available through the network/internet?.

This is called _port forwarding_ and it comes in two flavors: Local Port Forwarding and Remote Port Forwarding (see the pictures for more details, credit of the pictures from [this StackOverflow post](https://unix.stackexchange.com/questions/115897/whats-ssh-port-forwarding-and-whats-the-difference-between-ssh-local-and-remot)).

**Local Port Forwarding**

![[Study Log/resources/Pasted image 20230111143410.png]]

**Remote Port Forwarding**

![[Study Log/resources/Pasted image 20230111143424.png]]

The most common scenario is local port forwarding, where a service in the remote machine listens in a port and you want to link a port in your local machine to forward to the remote port. For example, if we execute `jupyter notebook` in the remote server that listens to the port `8888`. Thus, to forward that to the local port `9999`, we would do `ssh -L 9999:localhost:8888 foobar@remote_server` and then navigate to `locahost:9999` in our local machine.

#### 5.4.5.4 SSH Configuration

We have covered many many arguments that we can pass. A tempting alternative is to create shell aliases that look like

```shell
alias my_server="ssh -i ~/.id_ed25519 --port 2222 -L 9999:localhost:8888 foobar@remote_server
```

However, there is a better alternative using `~/.ssh/config`.

```shell
Host vm
    User foobar
    HostName 172.16.174.141
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
    LocalForward 9999 localhost:8888

# Configs can also take wildcards
Host *.mit.edu
    User foobaz
```

An additional advantage of using the `~/.ssh/config` file over aliases is that other programs like `scp`, `rsync`, `mosh`, &c are able to read it as well and convert the settings into the corresponding flags.

Note that the `~/.ssh/config` file can be considered a dotfile, and in general it is fine for it to be included with the rest of your dotfiles. However, if you make it public, think about the information that you are potentially providing strangers on the internet: addresses of your servers, users, open ports, &c. This may facilitate some types of attacks so be thoughtful about sharing your SSH configuration.

Server side configuration is usually specified in `/etc/ssh/sshd_config`. Here you can make changes like disabling password authentication, changing ssh ports, enabling X11 forwarding, &c. You can specify config settings on a per user basis.

#### 5.4.5.5 Miscellaneous

A common pain when connecting to a remote server are disconnections due to your computer shutting down, going to sleep, or changing networks. Moreover if one has a connection with significant lag using ssh can become quite frustrating. [Mosh](https://mosh.org/), the mobile shell, improves upon ssh, allowing roaming connections, intermittent connectivity and providing intelligent local echo.

Sometimes it is convenient to mount a remote folder. [sshfs](https://github.com/libfuse/sshfs) can mount a folder on a remote server locally, and then you can use a local editor.

### 5.4.6 Shells & Frameworks

During shell tool and scripting we covered the `bash` shell because it is by far the most ubiquitous shell and most systems have it as the default option. Nevertheless, it is not the only option.

For example, the `zsh` shell is a superset of `bash` and provides many convenient features out of the box such as:

-   Smarter globbing, `**`
-   Inline globbing/wildcard expansion
-   Spelling correction
-   Better tab completion/selection
-   Path expansion (`cd /u/lo/b` will expand as `/usr/local/bin`)

**Frameworks** can improve your shell as well. Some popular general frameworks are [prezto](https://github.com/sorin-ionescu/prezto) or [oh-my-zsh](https://ohmyz.sh/), and smaller ones that focus on specific features such as [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) or [zsh-history-substring-search](https://github.com/zsh-users/zsh-history-substring-search). Shells like [fish](https://fishshell.com/) include many of these user-friendly features by default. Some of these features include:

-   Right prompt
-   Command syntax highlighting
-   History substring search
-   manpage based flag completions
-   Smarter autocompletion
-   Prompt themes

One thing to note when using these frameworks is that they may slow down your shell, especially if the code they run is not properly optimized or it is too much code. You can always profile it and disable the features that you do not use often or value over speed.

### 5.4.7 Terminal Emulators

Along with customizing your shell, it is worth spending some time figuring out your choice of **terminal emulator** and its settings. There are many many terminal emulators out there (here is a [comparison](https://anarc.at/blog/2018-04-12-terminal-emulators-1/)).

Since you might be spending hundreds to thousands of hours in your terminal it pays off to look into its settings. Some of the aspects that you may want to modify in your terminal include:

-   Font choice
-   Color Scheme
-   Keyboard shortcuts
-   Tab/Pane support
-   Scrollback configuration
-   Performance (some newer terminals like [Alacritty](https://github.com/jwilm/alacritty) or [kitty](https://sw.kovidgoyal.net/kitty/) offer GPU acceleration).

### 5.4.8 Exercises

#### 5.4.8.1 Job control

1.  From what we have seen, we can use some `ps aux | grep` commands to get our jobs’ pids and then kill them, but there are better ways to do it. Start a `sleep 10000` job in a terminal, background it with `Ctrl-Z` and continue its execution with `bg`. Now use [`pgrep`](https://www.man7.org/linux/man-pages/man1/pgrep.1.html) to find its pid and [`pkill`](http://man7.org/linux/man-pages/man1/pgrep.1.html) to kill it without ever typing the pid itself. (Hint: use the `-af` flags).
    
2.  Say you don’t want to start a process until another completes. How would you go about it? In this exercise, our limiting process will always be `sleep 60 &`. One way to achieve this is to use the [`wait`](https://www.man7.org/linux/man-pages/man1/wait.1p.html) command. Try launching the sleep command and having an `ls` wait until the background process finishes.
    
    However, this strategy will fail if we start in a different bash session, since `wait` only works for child processes. One feature we did not discuss in the notes is that the `kill` command’s exit status will be zero on success and nonzero otherwise. `kill -0` does not send a signal but will give a nonzero exit status if the process does not exist. Write a bash function called `pidwait` that takes a pid and waits until the given process completes. You should use `sleep` to avoid wasting CPU unnecessarily.
    

#### 5.4.8.2 Terminal multiplexer

1.  Follow this `tmux` [tutorial](https://www.hamvocke.com/blog/a-quick-and-easy-guide-to-tmux/) and then learn how to do some basic customizations following [these steps](https://www.hamvocke.com/blog/a-guide-to-customizing-your-tmux-conf/).

#### 5.4.8.3 Aliases

1.  Create an alias `dc` that resolves to `cd` for when you type it wrongly.
    
2.  Run `history | awk '{$1="";print substr($0,2)}' | sort | uniq -c | sort -n | tail -n 10` to get your top 10 most used commands and consider writing shorter aliases for them. Note: this works for Bash; if you’re using ZSH, use `history 1` instead of just `history`.
    

#### 5.4.8.4 Dotfiles

Let’s get you up to speed with dotfiles.

1.  Create a folder for your dotfiles and set up version control.
2.  Add a configuration for at least one program, e.g. your shell, with some customization (to start off, it can be something as simple as customizing your shell prompt by setting `$PS1`).
3.  Set up a method to install your dotfiles quickly (and without manual effort) on a new machine. This can be as simple as a shell script that calls `ln -s` for each file, or you could use a [specialized utility](https://dotfiles.github.io/utilities/).
4.  Test your installation script on a fresh virtual machine.
5.  Migrate all of your current tool configurations to your dotfiles repository.
6.  Publish your dotfiles on GitHub.

#### 5.4.8.5 Remote Machines

Install a Linux virtual machine (or use an already existing one) for this exercise. If you are not familiar with virtual machines check out [this](https://hibbard.eu/install-ubuntu-virtual-box/) tutorial for installing one.

1.  Go to `~/.ssh/` and check if you have a pair of SSH keys there. If not, generate them with `ssh-keygen -o -a 100 -t ed25519`. It is recommended that you use a password and use `ssh-agent` , more info [here](https://www.ssh.com/ssh/agent).
2.  Edit `.ssh/config` to have an entry as follows
    
    ```shell
     Host vm
         User username_goes_here
         HostName ip_goes_here
         IdentityFile ~/.ssh/id_ed25519
         LocalForward 9999 localhost:8888
    ```
    
3.  Use `ssh-copy-id vm` to copy your ssh key to the server.
4.  Start a webserver in your VM by executing `python -m http.server 8888`. Access the VM webserver by navigating to `http://localhost:9999` in your machine.
5.  Edit your SSH server config by doing `sudo vim /etc/ssh/sshd_config` and disable password authentication by editing the value of `PasswordAuthentication`. Disable root login by editing the value of `PermitRootLogin`. Restart the `ssh` service with `sudo service sshd restart`. Try sshing in again.
6.  (Challenge) Install [`mosh`](https://mosh.org/) in the VM and establish a connection. Then disconnect the network adapter of the server/VM. Can mosh properly recover from it?
7.  (Challenge) Look into what the `-N` and `-f` flags do in `ssh` and figure out a command to achieve background port forwarding.

# 6. Version Control

你是否有过这样的经历：

![[Study Log/resources/Pasted image 20230112134327.png|300]]

在我们初学git的时候，项目出现错误了。那以我当时的水平，能做的就是：删掉现在的项目，clone原来没错的版本。然而经过本章的学习，就不会再做这样的事情了。因为git强大到很轻松就能应付这类问题。

git使用的是Directed Asyclic Graph(有向无环图)来管理版本信息。从简单的角度来讲，比如我整个仓库首次上传的时候，有一个最初的状态：

![[Study Log/resources/Drawing 2023-01-12 14.11.16.excalidraw.png]]

那么当我开发出下一个版本时，这个新状态就会指向原来的版本，也就是它的父亲：

![[Study Log/resources/Drawing 2023-01-12 14.12.17.excalidraw.png]]

接下来我们遇到了一些困难：当前开发出来的这个新版本有一些bug要修；而于此同时，我还有一些新的特性要加进去。这个时候，git就可以同时产生两个状态，它们都指向这个新版本。

![[Study Log/resources/Drawing 2023-01-12 14.14.17.excalidraw.png]]

之后，我的新特性添加完了，同时我的bug也修完了。那我当然要把它俩合为一体。这个时候又出现一个新状态，它同时指向这两个分支：

![[Study Log/resources/Drawing 2023-01-12 14.16.16.excalidraw.png]]

## 6.1 Git Overview

接下来我们开始正式使用git吧！新建一个`demo`文件夹，在里面进行`git init`，然后创建一个文件：

```shell
echo haha > haha.txt
```

这样我们就创建好了一个由git管理的最小的项目。现在我们查看一下当前的状态：

![[Study Log/resources/Pasted image 20230112144142.png]]

我们看到，这个`haha.txt`是还没有被track的文件。也就是说，它还没受git的管理。那么我们如何让他被管理呢？就是使用`add`命令：

```shell
git add haha.txt
```

![[Study Log/resources/Pasted image 20230112144331.png]]

接下来，自然是进行提交。而每次提交都代表着什么？我们要先说说这个事儿。在上面图中的每一个状态，其实都代表着一次提交。而提交必定不止有文件本身，还要有一些说明信息：

```c
typedef struct{
	byte * parents;
	char * author;
	char * message;
	Tree snapshot;
}Commit;
```

`parents`就是图中指向父亲的指针，另外还要有作者信息，提交时的说明，整个项目的快照(这里存的只是id)等等。因此我们每次提交的过程中都要给出这些信息：

```shell
git commit
```

![[Study Log/resources/Pasted image 20230112145103.png]]

保存退出后看到如下信息：

![[Study Log/resources/Pasted image 20230112145346.png]]

这其实就相当于创建了一个新的状态结点，并且这里的commit信息也存了下来：

![[Study Log/resources/Drawing 2023-01-12 17.39.05.excalidraw.png]]

这个`c4cf3ec`是什么？实际上就是sha-1码，对应的就是我们刚才添加进去的说明信息。我们可以使用`git cat-file`命令来查看这些信息：

![[Study Log/resources/Pasted image 20230112174228.png]]

最后一行就是我们写的commit信息，没问题。那前面这些乱七八糟的码是什么？我们从这个tree开始。我们依然可以使用上面的命令查看它：

![[Study Log/resources/Pasted image 20230112174420.png]]

我们可以看到，**当前的tree中有一个blob，就是我们创建的`haha.txt`**。那么我们再看看这个blob里有什么：

![[Study Log/resources/Pasted image 20230112174554.png]]

这不就是`haha.txt`文件中的内容吗！因此，我们已经捋清楚了git项目的结构：

![[Study Log/resources/Drawing 2023-01-12 17.46.33.excalidraw.png]]

> tree就是文件夹，blob就是文件。tree可以包含tree和blob，而blob不能包含任何blob和tree。

## 6.2 Log

接下来我们对当前的仓库做出一些改变。在`haha.txt`中追加一行：

```shell
echo "heihei" >> haha.txt
```

然后再次添加，查看状态，提交：

![[Study Log/resources/Pasted image 20230112180819.png]]

此时我们相当于又新建了一个结点，指向之前的结点，并且也包含提交信息：

![[Study Log/resources/Drawing 2023-01-12 18.08.44.excalidraw.png]]

这下有了多个结点，我们可以回顾我们的历史纪录了：

```shell
git log
```

![[Study Log/resources/Pasted image 20230112181200.png]]

这样看纯文本有点没意思，我们给log指令加一些参数：

```shell
git log --all --graph --decorate
```

![[Study Log/resources/Pasted image 20230112181314.png]]

这个星号就是我们图上的圆圈，新的提交在上面，旧的提交在下面。下一个问题是，括号里的`HEAD -> master`是什么意思？git仓库在创建时，会默认生成一个master分支。因此我们所在的位置就是master。**我们可以把master想象成一个指针，它总是指向最新的一次commit**。

现在我们已经处于第二个结点了，但是我们要是想回看第一个结点中的东西应该咋办？不用怕！git已经帮我们记下来了！**我们只需要输入想要的commit的hash的前缀就可以了**：

![[Study Log/resources/Pasted image 20230112182025.png]]

我们将HEAD指向第一次修改，然后查看`haha.txt`中的内容，发现文本又变回第一次提交时的状态了。我们再查看一下日志，看看会发生什么：

![[Study Log/resources/Pasted image 20230112182229.png]]

HEAD的位置从上面变到了下面。而我们要想回去呢？照葫芦画瓢呗！只是，**除了输入一长串hash之外，我们还可以这样**：

![[Study Log/resources/Pasted image 20230112182412.png]]

只需要输入master就可以了！那么我们不禁会想：master和那一长串东西之间有关系啊！没错！这就是**reference**。在git中有许多reference，它其实就是将一长串人不可读的代号变成可读的字符串。

## 6.3 Diff

接下来是`git diff`的介绍。我们再修改一下`haha.txt`：

![[Study Log/resources/Pasted image 20230112183017.png]]

我们比较的是谁？**是当前还没add的版本，和HEAD指向的版本(相当于`git diff HEAD haha.txt`)**。因此，如果我想要和最一开始的版版本比较，就可以：

![[Study Log/resources/Pasted image 20230112183148.png]]

## 6.4 Branch

接下来我们介绍git中的分支。首先建立一个`animal.c`，写上如下内容：

```c
#include <stdio.h>
#include <unistd.h>
#include <string.h>

void animal(){
    printf("animal program!\n");
}

int main(int argc, char ** argv){
    printf("argc: %d\n", argc);
    if(argc == 1) animal();
    return 0;
}    
```

很简单的一个小程序。从这个时候开始，我们建立分支。首先，使用`git branch`命令可以看到当前创建的所有分支：

![[Study Log/resources/Pasted image 20230112185947.png]]

接下来，我们就可以创建分支了。使用如下命令建立一个名为cat的分支：

```shell
git branch cat
```

我们使用`git log --all --graph --decorate`来查看一下当前的情况：

![[Study Log/resources/Pasted image 20230112190146.png]]

可以看到，唯一的变化就是多了一个cat，而HEAD指向的还是master而不是cat。那么如何切换到cat呢？使用如下命令：

```shell
git checkout cat
```

![[Study Log/resources/Pasted image 20230112190312.png]]

> 这里出了点问题，我应该先提交animal再创建cat分支。这里搞反了，所以使用`git branch --delete cat`删除cat分支，然后添加上新的东西再提交到master里，最后应该变成这个样子：
> 
> ![[Study Log/resources/Pasted image 20230112190658.png]]

既然到了cat分支，我们就该加点cat的东西。修改`animal.c`：

```c
#include <stdio.h>
#include <unistd.h>
#include <string.h>

void animal(){
    printf("animal program!\n");
}

void cat(){
    printf("miao~\n");
}

int main(int argc, char ** argv){
    printf("argc: %d\n", argc);
    if(argc == 1) animal();
    else {
        if(strcmp(argv[1], "cat") == 0) cat();
    }

    return 0;
}
```

在我们commit之后再查看日志，就会发现：

![[Study Log/resources/Pasted image 20230112191117.png]]

那么就可以干点好玩儿的了，现在就能够回到master中，并且查看当时我们的代码：

![[Study Log/resources/Pasted image 20230112191312.png]]

> 这里的注释是因为我一开始在master中就把所有代码写好了，在cat分支中只是把注释去掉了。

接下来，我要加一个dog分支。这个分支干了什么？添加dog的特性啊！它和cat分支是**并行**的，所以我们要先回到master后，再创建dog分支：

![[Study Log/resources/Pasted image 20230112191626.png]]

> 这里涉及的细节：
> 
> * `--oneline`表示简略地显示log，每个commit只占一行
> * 创建dog分支并切换到它应该是`git branch dog; git checkout dog`，我们可以用图中的命令替代这两句。

接下来，我们修改`animal.c`，加入dog元素：

```c
#include <stdio.h>
#include <unistd.h>
#include <string.h>

void animal(){
	printf("animal program!\n");
}

void dog(){
	printf("wang!\n");
}

int main(int argc, char ** argv){
	printf("argc: %d\n", argc);
	if(argc == 1) animal();
	else {
		if(strcmp(argv[1], "dog") == 0) dog();
	}
	return 0;
}
```

> 这里不应包括cat中的内容，因为cat和dog是并行的。

我们将这次修改commit之后再查日志，就能看到最重要的结果了：

![[Study Log/resources/Pasted image 20230112192353.png]]

我们看到，master分了两个岔。一个是cat而另一个是dog。这正于我们的设想吻合。接下来，我们将这两个分支都合并回master，这也对应了我们一开始图中的内容。**注意，要合并回master，最好先checkout到master中**。

![[Study Log/resources/Pasted image 20230112193225.png]]

![[Study Log/resources/Pasted image 20230112193244.png]]

合并cat的时候没问题，但是合并dog的时候出事了。因此我们可以进入`animal.c`中看看为什么：

```c
#include <stdio.h>
#include <unistd.h>
#include <string.h>

void animal(){
    printf("animal program!\n");
}

## 6.1 Git Overview

接下来我们开始正式使用git吧！新建一个`demo`文件夹，在里面进行`git init`，然后创建一个文件：

```shell
echo haha > haha.txt
```

这样我们就创建好了一个由git管理的最小的项目。现在我们查看一下当前的状态：

![[Study Log/resources/Pasted image 20230112144142.png]]

我们看到，这个`haha.txt`是还没有被track的文件。也就是说，它还没受git的管理。那么我们如何让他被管理呢？就是使用`add`命令：

```shell
git add haha.txt
```

![[Study Log/resources/Pasted image 20230112144331.png]]

接下来，自然是进行提交。而每次提交都代表着什么？我们要先说说这个事儿。在上面图中的每一个状态，其实都代表着一次提交。而提交必定不止有文件本身，还要有一些说明信息：

```c
typedef struct{
	byte * parents;
	char * author;
	char * message;
	Tree snapshot;
}Commit;
```

`parents`就是图中指向父亲的指针，另外还要有作者信息，提交时的说明，整个项目的快照(这里存的只是id)等等。因此我们每次提交的过程中都要给出这些信息：

```shell
git commit
```

![[Study Log/resources/Pasted image 20230112145103.png]]

保存退出后看到如下信息：

![[Study Log/resources/Pasted image 20230112145346.png]]

这其实就相当于创建了一个新的状态结点，并且这里的commit信息也存了下来：

![[Study Log/resources/Drawing 2023-01-12 17.39.05.excalidraw.png]]

这个`c4cf3ec`是什么？实际上就是sha-1码，对应的就是我们刚才添加进去的说明信息。我们可以使用`git cat-file`命令来查看这些信息：

![[Study Log/resources/Pasted image 20230112174228.png]]

最后一行就是我们写的commit信息，没问题。那前面这些乱七八糟的码是什么？我们从这个tree开始。我们依然可以使用上面的命令查看它：

![[Study Log/resources/Pasted image 20230112174420.png]]

我们可以看到，**当前的tree中有一个blob，就是我们创建的`haha.txt`**。那么我们再看看这个blob里有什么：

![[Study Log/resources/Pasted image 20230112174554.png]]

这不就是`haha.txt`文件中的内容吗！因此，我们已经捋清楚了git项目的结构：

![[Study Log/resources/Drawing 2023-01-12 17.46.33.excalidraw.png]]

> tree就是文件夹，blob就是文件。tree可以包含tree和blob，而blob不能包含任何blob和tree。

## 6.2 Log

接下来我们对当前的仓库做出一些改变。在`haha.txt`中追加一行：

```shell
echo "heihei" >> haha.txt
```

然后再次添加，查看状态，提交：

![[Study Log/resources/Pasted image 20230112180819.png]]

此时我们相当于又新建了一个结点，指向之前的结点，并且也包含提交信息：

![[Study Log/resources/Drawing 2023-01-12 18.08.44.excalidraw.png]]

这下有了多个结点，我们可以回顾我们的历史纪录了：

```shell
git log
```

![[Study Log/resources/Pasted image 20230112181200.png]]

这样看纯文本有点没意思，我们给log指令加一些参数：

```shell
git log --all --graph --decorate
```

![[Study Log/resources/Pasted image 20230112181314.png]]

这个星号就是我们图上的圆圈，新的提交在上面，旧的提交在下面。下一个问题是，括号里的`HEAD -> master`是什么意思？git仓库在创建时，会默认生成一个master分支。因此我们所在的位置就是master。**我们可以把master想象成一个指针，它总是指向最新的一次commit**。

现在我们已经处于第二个结点了，但是我们要是想回看第一个结点中的东西应该咋办？不用怕！git已经帮我们记下来了！**我们只需要输入想要的commit的hash的前缀就可以了**：

![[Study Log/resources/Pasted image 20230112182025.png]]

我们将HEAD指向第一次修改，然后查看`haha.txt`中的内容，发现文本又变回第一次提交时的状态了。我们再查看一下日志，看看会发生什么：

![[Study Log/resources/Pasted image 20230112182229.png]]

HEAD的位置从上面变到了下面。而我们要想回去呢？照葫芦画瓢呗！只是，**除了输入一长串hash之外，我们还可以这样**：

![[Study Log/resources/Pasted image 20230112182412.png]]

只需要输入master就可以了！那么我们不禁会想：master和那一长串东西之间有关系啊！没错！这就是**reference**。在git中有许多reference，它其实就是将一长串人不可读的代号变成可读的字符串。

## 6.3 Diff

接下来是`git diff`的介绍。我们再修改一下`haha.txt`：

![[Study Log/resources/Pasted image 20230112183017.png]]

我们比较的是谁？**是当前还没add的版本，和HEAD指向的版本(相当于`git diff HEAD haha.txt`)**。因此，如果我想要和最一开始的版版本比较，就可以：

![[Study Log/resources/Pasted image 20230112183148.png]]

## 6.4 Branch

接下来我们介绍git中的分支。首先建立一个`animal.c`，写上如下内容：

```c
#include <stdio.h>
#include <unistd.h>
#include <string.h>

void animal(){
    printf("animal program!\n");
}

int main(int argc, char ** argv){
    printf("argc: %d\n", argc);
    if(argc == 1) animal();
    return 0;
}    
```

很简单的一个小程序。从这个时候开始，我们建立分支。首先，使用`git branch`命令可以看到当前创建的所有分支：

![[Study Log/resources/Pasted image 20230112185947.png]]

接下来，我们就可以创建分支了。使用如下命令建立一个名为cat的分支：

```shell
git branch cat
```

我们使用`git log --all --graph --decorate`来查看一下当前的情况：

![[Study Log/resources/Pasted image 20230112190146.png]]

可以看到，唯一的变化就是多了一个cat，而HEAD指向的还是master而不是cat。那么如何切换到cat呢？使用如下命令：

```shell
git checkout cat
```

![[Study Log/resources/Pasted image 20230112190312.png]]

> 这里出了点问题，我应该先提交animal再创建cat分支。这里搞反了，所以使用`git branch --delete cat`删除cat分支，然后添加上新的东西再提交到master里，最后应该变成这个样子：
> 
> ![[Study Log/resources/Pasted image 20230112190658.png]]

既然到了cat分支，我们就该加点cat的东西。修改`animal.c`：

```c
#include <stdio.h>
#include <unistd.h>
#include <string.h>

void animal(){
    printf("animal program!\n");
}

void cat(){
    printf("miao~\n");
}

int main(int argc, char ** argv){
    printf("argc: %d\n", argc);
    if(argc == 1) animal();
    else {
        if(strcmp(argv[1], "cat") == 0) cat();
    }

    return 0;
}
```

在我们commit之后再查看日志，就会发现：

![[Study Log/resources/Pasted image 20230112191117.png]]

那么就可以干点好玩儿的了，现在就能够回到master中，并且查看当时我们的代码：

![[Study Log/resources/Pasted image 20230112191312.png]]

> 这里的注释是因为我一开始在master中就把所有代码写好了，在cat分支中只是把注释去掉了。

接下来，我要加一个dog分支。这个分支干了什么？添加dog的特性啊！它和cat分支是**并行**的，所以我们要先回到master后，再创建dog分支：

![[Study Log/resources/Pasted image 20230112191626.png]]

> 这里涉及的细节：
> 
> * `--oneline`表示简略地显示log，每个commit只占一行
> * 创建dog分支并切换到它应该是`git branch dog; git checkout dog`，我们可以用图中的命令替代这两句。

接下来，我们修改`animal.c`，加入dog元素：

```c
#include <stdio.h>
#include <unistd.h>
#include <string.h>

void animal(){
	printf("animal program!\n");
}

void dog(){
	printf("wang!\n");
}

int main(int argc, char ** argv){
	printf("argc: %d\n", argc);
	if(argc == 1) animal();
	else {
		if(strcmp(argv[1], "dog") == 0) dog();
	}
	return 0;
}
```

> 这里不应包括cat中的内容，因为cat和dog是并行的。

我们将这次修改commit之后再查日志，就能看到最重要的结果了：

![[Study Log/resources/Pasted image 20230112192353.png]]

我们看到，master分了两个岔。一个是cat而另一个是dog。这正于我们的设想吻合。接下来，我们将这两个分支都合并回master，这也对应了我们一开始图中的内容。**注意，要合并回master，最好先checkout到master中**。

![[Study Log/resources/Pasted image 20230112193225.png]]

![[Study Log/resources/Pasted image 20230112193244.png]]

合并cat的时候没问题，但是合并dog的时候出事了。因此我们可以进入`animal.c`中看看为什么：

```c
#include <stdio.h>
#include <unistd.h>
#include <string.h>

void animal(){
    printf("animal program!\n");
}

void cat(){
    printf("miao~\n");
}


void dog(){
    printf("wang!\n");
}

int main(int argc, char ** argv){
    printf("argc: %d\n", argc);
    if(argc == 1) animal();
    else {
<<<<<<< HEAD
        if(strcmp(argv[1], "cat") == 0) cat();
=======
//      if(strcmp(argv[1], "cat") == 0) cat();
        if(strcmp(argv[1], "dog") == 0) dog();
>>>>>>> dog
    }

    return 0;
}
```

我们发现，是因为先合并的cat和之后的dog中间出了冲突，git认为这样的合并可能会出问题。所以把问题抛给了程序员。我们可以发现，这样写实际上没啥问题，所以直接删掉就好：

```c
#include <stdio.h>
#include <unistd.h>
#include <string.h>

void animal(){
    printf("animal program!\n");
}


void cat(){
    printf("miao~\n");
}


void dog(){
    printf("wang!\n");
}

int main(int argc, char ** argv){
    printf("argc: %d\n", argc);
    if(argc == 1) animal();
    else {
        if(strcmp(argv[1], "cat") == 0) cat();
        if(strcmp(argv[1], "dog") == 0) dog();
    }
    return 0;
}
```

修理好错误之后，我们就可以重新merge了。在merge之前，还要重新添加一下修改的文件才可以：

![[Study Log/resources/Pasted image 20230112193758.png]]

现在，我们再查看一下日志，就会发现最终的结果：

![[Study Log/resources/Pasted image 20230112193851.png]]

## 6.5 Lecture Notes

Version control systems (VCSs) are tools used to track changes to source code (or other collections of files and folders). As the name implies, these tools help maintain a history of changes; furthermore, they facilitate collaboration. VCSs track changes to a folder and its contents in a series of snapshots, where each snapshot encapsulates the entire state of files/folders within a top-level directory. VCSs also maintain metadata like who created each snapshot, messages associated with each snapshot, and so on.

Why is version control useful? Even when you’re working by yourself, it can let you look at old snapshots of a project, keep a log of why certain changes were made, work on parallel branches of development, and much more. When working with others, it’s an invaluable tool for seeing what other people have changed, as well as resolving conflicts in concurrent development.

Modern VCSs also let you easily (and often automatically) answer questions like:

-   Who wrote this module?
-   When was this particular line of this particular file edited? By whom? Why was it edited?
-   Over the last 1000 revisions, when/why did a particular unit test stop working?

While other VCSs exist, **Git** is the de facto standard for version control. This [XKCD comic](https://xkcd.com/1597/) captures Git’s reputation:

![[Study Log/resources/Pasted image 20230112201122.png]]

Because Git’s interface is a leaky abstraction, learning Git top-down (starting with its interface / command-line interface) can lead to a lot of confusion. It’s possible to memorize a handful of commands and think of them as magic incantations, and follow the approach in the comic above whenever anything goes wrong.

While Git admittedly has an ugly interface, its underlying design and ideas are beautiful. While an ugly interface has to be _memorized_, a beautiful design can be _understood_. For this reason, we give a bottom-up explanation of Git, starting with its data model and later covering the command-line interface. Once the data model is understood, the commands can be better understood in terms of how they manipulate the underlying data model.

### 6.5.1 Git’s data model

There are many ad-hoc approaches you could take to version control. Git has a well-thought-out model that enables all the nice features of version control, like maintaining history, supporting branches, and enabling collaboration.

#### 6.5.1.1 Snapshots

Git models the history of a collection of files and folders within some top-level directory as a series of snapshots. In Git terminology, a file is called a “blob”, and it’s just a bunch of bytes. A directory is called a “tree”, and it maps names to blobs or trees (so directories can contain other directories). A snapshot is the top-level tree that is being tracked. For example, we might have a tree as follows:

```
<root> (tree)
|
+- foo (tree)
|  |
|  + bar.txt (blob, contents = "hello world")
|
+- baz.txt (blob, contents = "git is wonderful")
```

The top-level tree contains two elements, a tree “foo” (that itself contains one element, a blob “bar.txt”), and a blob “baz.txt”.

#### 6.5.1.2 Modeling history: relating snapshots

How should a version control system relate snapshots? One simple model would be to have a linear history. A history would be a list of snapshots in time-order. For many reasons, Git doesn’t use a simple model like this.

In Git, a history is a directed acyclic graph (DAG) of snapshots. That may sound like a fancy math word, but don’t be intimidated. All this means is that each snapshot in Git refers to a set of “parents”, the snapshots that preceded it. It’s a set of parents rather than a single parent (as would be the case in a linear history) because a snapshot might descend from multiple parents, for example, due to combining (merging) two parallel branches of development.

Git calls these snapshots “commit”s. Visualizing a commit history might look something like this:

```
o <-- o <-- o <-- o
            ^
             \
              --- o <-- o
```

In the ASCII art above, the `o`s correspond to individual commits (snapshots). The arrows point to the parent of each commit (it’s a “comes before” relation, not “comes after”). After the third commit, the history branches into two separate branches. This might correspond to, for example, two separate features being developed in parallel, independently from each other. In the future, these branches may be merged to create a new snapshot that incorporates both of the features, producing a new history that looks like this, with the newly created merge commit shown in bold:

```
o <-- o <-- o <-- o <---- o
            ^            /
             \          v
              --- o <-- o
```

Commits in Git are immutable. This doesn’t mean that mistakes can’t be corrected, however; it’s just that “edits” to the commit history are actually creating entirely new commits, and references (see below) are updated to point to the new ones.

#### 6.5.1.3 Data model, as pseudocode

It may be instructive to see Git’s data model written down in pseudocode:

```
// a file is a bunch of bytes
type blob = array<byte>

// a directory contains named files and directories
type tree = map<string, tree | blob>

// a commit has parents, metadata, and the top-level tree
type commit = struct {
    parents: array<commit>
    author: string
    message: string
    snapshot: tree
}
```

It’s a clean, simple model of history.

#### 6.5.1.4 Objects and content-addressing

An “object” is a blob, tree, or commit:

```
type object = blob | tree | commit
```

In Git data store, all objects are content-addressed by their [SHA-1 hash](https://en.wikipedia.org/wiki/SHA-1).

```
objects = map<string, object>

def store(object):
    id = sha1(object)
    objects[id] = object

def load(id):
    return objects[id]
```

Blobs, trees, and commits are unified in this way: they are all objects. When they reference other objects, they don’t actually _contain_ them in their on-disk representation, but have a reference to them by their hash.

For example, the tree for the example directory structure [above](https://missing.csail.mit.edu/2020/version-control/#snapshots) (visualized using `git cat-file -p 698281bc680d1995c5f4caaf3359721a5a58d48d`), looks like this:

```
100644 blob 4448adbf7ecd394f42ae135bbeed9676e894af85    baz.txt
040000 tree c68d233a33c5c06e0340e4c224f0afca87c8ce87    foo
```

The tree itself contains pointers to its contents, `baz.txt` (a blob) and `foo` (a tree). If we look at the contents addressed by the hash corresponding to baz.txt with `git cat-file -p 4448adbf7ecd394f42ae135bbeed9676e894af85`, we get the following:

```
git is wonderful
```

#### 6.5.1.5 References

Now, all snapshots can be identified by their SHA-1 hashes. That’s inconvenient, because humans aren’t good at remembering strings of 40 hexadecimal characters.

Git’s solution to this problem is human-readable names for SHA-1 hashes, called “references”. References are pointers to commits. Unlike objects, which are immutable, references are mutable (can be updated to point to a new commit). For example, the `master` reference usually points to the latest commit in the main branch of development.

```
references = map<string, string>

def update_reference(name, id):
    references[name] = id

def read_reference(name):
    return references[name]

def load_reference(name_or_id):
    if name_or_id in references:
        return load(references[name_or_id])
    else:
        return load(name_or_id)
```

With this, Git can use human-readable names like “master” to refer to a particular snapshot in the history, instead of a long hexadecimal string.

One detail is that we often want a notion of “where we currently are” in the history, so that when we take a new snapshot, we know what it is relative to (how we set the `parents` field of the commit). In Git, that “where we currently are” is a special reference called “HEAD”.

#### 6.5.1.6 Repositories

Finally, we can define what (roughly) is a Git _repository_: it is the data `objects` and `references`.

On disk, all Git stores are objects and references: that’s all there is to Git’s data model. All `git` commands map to some manipulation of the commit DAG by adding objects and adding/updating references.

Whenever you’re typing in any command, think about what manipulation the command is making to the underlying graph data structure. Conversely, if you’re trying to make a particular kind of change to the commit DAG, e.g. “discard uncommitted changes and make the ‘master’ ref point to commit `5d83f9e`”, there’s probably a command to do it (e.g. in this case, `git checkout master; git reset --hard 5d83f9e`).

### 6.5.2 Staging area

This is another concept that’s orthogonal to the data model, but it’s a part of the interface to create commits.

One way you might imagine implementing snapshotting as described above is to have a “create snapshot” command that creates a new snapshot based on the _current state_ of the working directory. Some version control tools work like this, but not Git. We want clean snapshots, and it might not always be ideal to make a snapshot from the current state. For example, imagine a scenario where you’ve implemented two separate features, and you want to create two separate commits, where the first introduces the first feature, and the next introduces the second feature. Or imagine a scenario where you have debugging print statements added all over your code, along with a bugfix; you want to commit the bugfix while discarding all the print statements.

Git accommodates such scenarios by allowing you to specify which modifications should be included in the next snapshot through a mechanism called the “staging area”.

### 6.5.3 Git command-line interface

To avoid duplicating information, we’re not going to explain the commands below in detail. See the highly recommended [Pro Git](https://git-scm.com/book/en/v2) for more information, or watch the lecture video.

#### 6.5.3.1 Basics

-   `git help <command>`: get help for a git command
-   `git init`: creates a new git repo, with data stored in the `.git` directory
-   `git status`: tells you what’s going on
-   `git add <filename>`: adds files to staging area
-   `git commit`: creates a new commit
    -   Write [good commit messages](https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)!
    -   Even more reasons to write [good commit messages](https://chris.beams.io/posts/git-commit/)!
-   `git log`: shows a flattened log of history
-   `git log --all --graph --decorate`: visualizes history as a DAG
-   `git diff <filename>`: show changes you made relative to the staging area
-   `git diff <revision> <filename>`: shows differences in a file between snapshots
-   `git checkout <revision>`: updates HEAD and current branch

#### 6.5.3.2 Branching and merging

-   `git branch`: shows branches
-   `git branch <name>`: creates a branch
-   `git checkout -b <name>`: creates a branch and switches to it
    -   same as `git branch <name>; git checkout <name>`
-   `git merge <revision>`: merges into current branch
-   `git mergetool`: use a fancy tool to help resolve merge conflicts
-   `git rebase`: rebase set of patches onto a new base

#### 6.5.3.3 Remotes

-   `git remote`: list remotes
-   `git remote add <name> <url>`: add a remote
-   `git push <remote> <local branch>:<remote branch>`: send objects to remote, and update remote reference
-   `git branch --set-upstream-to=<remote>/<remote branch>`: set up correspondence between local and remote branch
-   `git fetch`: retrieve objects/references from a remote
-   `git pull`: same as `git fetch; git merge`
-   `git clone`: download repository from remote

#### 6.5.3.4 Undo

-   `git commit --amend`: edit a commit’s contents/message
-   `git reset HEAD <file>`: unstage a file
-   `git checkout -- <file>`: discard changes

### 6.5.4 Advanced Git

-   `git config`: Git is [highly customizable](https://git-scm.com/docs/git-config)
-   `git clone --depth=1`: shallow clone, without entire version history
-   `git add -p`: interactive staging
-   `git rebase -i`: interactive rebasing
-   `git blame`: show who last edited which line
-   `git stash`: temporarily remove modifications to working directory
-   `git bisect`: binary search history (e.g. for regressions)
-   `.gitignore`: [specify](https://git-scm.com/docs/gitignore) intentionally untracked files to ignore

### 6.5.5 Miscellaneous

-   **GUIs**: there are many [GUI clients](https://git-scm.com/downloads/guis) out there for Git. We personally don’t use them and use the command-line interface instead.
-   **Shell integration**: it’s super handy to have a Git status as part of your shell prompt ([zsh](https://github.com/olivierverdier/zsh-git-prompt), [bash](https://github.com/magicmonty/bash-git-prompt)). Often included in frameworks like [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh).
-   **Editor integration**: similarly to the above, handy integrations with many features. [fugitive.vim](https://github.com/tpope/vim-fugitive) is the standard one for Vim.
-   **Workflows**: we taught you the data model, plus some basic commands; we didn’t tell you what practices to follow when working on big projects (and there are [many](https://nvie.com/posts/a-successful-git-branching-model/) [different](https://www.endoflineblog.com/gitflow-considered-harmful) [approaches](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)).
-   **GitHub**: Git is not GitHub. GitHub has a specific way of contributing code to other projects, called [pull requests](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests).
-   **Other Git providers**: GitHub is not special: there are many Git repository hosts, like [GitLab](https://about.gitlab.com/) and [BitBucket](https://bitbucket.org/).

### 6.5.6 Resources

-   [Pro Git](https://git-scm.com/book/en/v2) is **highly recommended reading**. Going through Chapters 1–5 should teach you most of what you need to use Git proficiently, now that you understand the data model. The later chapters have some interesting, advanced material.
-   [Oh Shit, Git!?!](https://ohshitgit.com/) is a short guide on how to recover from some common Git mistakes.
-   [Git for Computer Scientists](https://eagain.net/articles/git-for-computer-scientists/) is a short explanation of Git’s data model, with less pseudocode and more fancy diagrams than these lecture notes.
-   [Git from the Bottom Up](https://jwiegley.github.io/git-from-the-bottom-up/) is a detailed explanation of Git’s implementation details beyond just the data model, for the curious.
-   [How to explain git in simple words](https://smusamashah.github.io/blog/2017/10/14/explain-git-in-simple-words)
-   [Learn Git Branching](https://learngitbranching.js.org/) is a browser-based game that teaches you Git.

### 6.5.7 Exercises

1.  If you don’t have any past experience with Git, either try reading the first couple chapters of [Pro Git](https://git-scm.com/book/en/v2) or go through a tutorial like [Learn Git Branching](https://learngitbranching.js.org/). As you’re working through it, relate Git commands to the data model.
2.  Clone the [repository for the class website](https://github.com/missing-semester/missing-semester).
    1.  Explore the version history by visualizing it as a graph.
    2.  Who was the last person to modify `README.md`? (Hint: use `git log` with an argument).
    3.  What was the commit message associated with the last modification to the `collections:` line of `_config.yml`? (Hint: use `git blame` and `git show`).
3.  One common mistake when learning Git is to commit large files that should not be managed by Git or adding sensitive information. Try adding a file to a repository, making some commits and then deleting that file from history (you may want to look at [this](https://help.github.com/articles/removing-sensitive-data-from-a-repository/)).
4.  Clone some repository from GitHub, and modify one of its existing files. What happens when you do `git stash`? What do you see when running `git log --all --oneline`? Run `git stash pop` to undo what you did with `git stash`. In what scenario might this be useful?
5.  Like many command line tools, Git provides a configuration file (or dotfile) called `~/.gitconfig`. Create an alias in `~/.gitconfig` so that when you run `git graph`, you get the output of `git log --all --graph --decorate --oneline`. Information about git aliases can be found [here](https://git-scm.com/docs/git-config#Documentation/git-config.txt-alias).
6.  You can define global ignore patterns in `~/.gitignore_global` after running `git config --global core.excludesfile ~/.gitignore_global`. Do this, and set up your global gitignore file to ignore OS-specific or editor-specific temporary files, like `.DS_Store`.
7.  Fork the [repository for the class website](https://github.com/missing-semester/missing-semester), find a typo or some other improvement you can make, and submit a pull request on GitHub (you may want to look at [this](https://github.com/firstcontributions/first-contributions)).

# 7. Debugging and Profiling

A golden rule in programming is that code does not do what you expect it to do, but what you tell it to do. Bridging that gap can sometimes be a quite difficult feat. In this lecture we are going to cover useful techniques for dealing with buggy and resource hungry code: debugging and profiling.

## 7.1 Debugging

### 7.1.1 Printf debugging and Logging

“The most effective debugging tool is still careful thought, coupled with judiciously placed print statements” — Brian Kernighan, _Unix for Beginners_.

A first approach to debug a program is to add print statements around where you have detected the problem, and keep iterating until you have extracted enough information to understand what is responsible for the issue.

A second approach is to use logging in your program, instead of ad hoc print statements. Logging is better than regular print statements for several reasons:

-   You can log to files, sockets or even remote servers instead of standard output.
-   Logging supports severity levels (such as INFO, DEBUG, WARN, ERROR, &c), that allow you to filter the output accordingly.
-   For new issues, there’s a fair chance that your logs will contain enough information to detect what is going wrong.

[Here](https://missing.csail.mit.edu/static/files/logger.py) is an example code that logs messages:

```shell
$ python logger.py
# Raw output as with just prints
$ python logger.py log
# Log formatted output
$ python logger.py log ERROR
# Print only ERROR levels and above
$ python logger.py color
# Color formatted output
```

One of my favorite tips for making logs more readable is to color code them. By now you probably have realized that your terminal uses colors to make things more readable. But how does it do it? Programs like `ls` or `grep` are using [ANSI escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code), which are special sequences of characters to indicate your shell to change the color of the output. For example, executing `echo -e "\e[38;2;255;0;0mThis is red\e[0m"` prints the message `This is red` in red on your terminal, as long as it supports [true color](https://github.com/termstandard/colors#truecolor-support-in-output-devices). If your terminal doesn’t support this (e.g. macOS’s Terminal.app), you can use the more universally supported escape codes for 16 color choices, for example `echo -e "\e[31;1mThis is red\e[0m"`.

The following script shows how to print many RGB colors into your terminal (again, as long as it supports true color).

```shell
#!/usr/bin/env bash
for R in $(seq 0 20 255); do
    for G in $(seq 0 20 255); do
        for B in $(seq 0 20 255); do
            printf "\e[38;2;${R};${G};${B}m█\e[0m";
        done
    done
done
```

### 7.1.2 Third party logs

As you start building larger software systems you will most probably run into dependencies that run as separate programs. Web servers, databases or message brokers are common examples of this kind of dependencies. When interacting with these systems it is often necessary to read their logs, since client side error messages might not suffice.

Luckily, most programs write their own logs somewhere in your system. In UNIX systems, it is commonplace for programs to write their logs under `/var/log`. For instance, the [NGINX](https://www.nginx.com/) webserver places its logs under `/var/log/nginx`. More recently, systems have started using a **system log**, which is increasingly where all of your log messages go. Most (but not all) Linux systems use `systemd`, a system daemon that controls many things in your system such as which services are enabled and running. `systemd` places the logs under `/var/log/journal` in a specialized format and you can use the [`journalctl`](https://www.man7.org/linux/man-pages/man1/journalctl.1.html) command to display the messages. Similarly, on macOS there is still `/var/log/system.log` but an increasing number of tools use the system log, that can be displayed with [`log show`](https://www.manpagez.com/man/1/log/). On most UNIX systems you can also use the [`dmesg`](https://www.man7.org/linux/man-pages/man1/dmesg.1.html) command to access the kernel log.

For logging under the system logs you can use the [`logger`](https://www.man7.org/linux/man-pages/man1/logger.1.html) shell program. Here’s an example of using `logger` and how to check that the entry made it to the system logs. Moreover, most programming languages have bindings logging to the system log.

```
logger "Hello Logs"
# On macOS
log show --last 1m | grep Hello
# On Linux
journalctl --since "1m ago" | grep Hello
```

As we saw in the data wrangling lecture, logs can be quite verbose and they require some level of processing and filtering to get the information you want. If you find yourself heavily filtering through `journalctl` and `log show` you can consider using their flags, which can perform a first pass of filtering of their output. There are also some tools like [`lnav`](http://lnav.org/), that provide an improved presentation and navigation for log files.

### 7.1.3 Debuggers

When printf debugging is not enough you should use a debugger. Debuggers are programs that let you interact with the execution of a program, allowing the following:

-   Halt execution of the program when it reaches a certain line.
-   Step through the program one instruction at a time.
-   Inspect values of variables after the program crashed.
-   Conditionally halt the execution when a given condition is met.
-   And many more advanced features

Many programming languages come with some form of debugger. In Python this is the Python Debugger [`pdb`](https://docs.python.org/3/library/pdb.html).

Here is a brief description of some of the commands `pdb` supports:

-   **l**(ist) - Displays 11 lines around the current line or continue the previous listing.
-   **s**(tep) - Execute the current line, stop at the first possible occasion.
-   **n**(ext) - Continue execution until the next line in the current function is reached or it returns.
-   **b**(reak) - Set a breakpoint (depending on the argument provided).
-   **p**(rint) - Evaluate the expression in the current context and print its value. There’s also **pp** to display using [`pprint`](https://docs.python.org/3/library/pprint.html) instead.
-   **r**(eturn) - Continue execution until the current function returns.
-   **q**(uit) - Quit the debugger.

Let’s go through an example of using `pdb` to fix the following buggy python code. (See the lecture video).

```python
def bubble_sort(arr):
    n = len(arr)
    for i in range(n):
        for j in range(n):
            if arr[j] > arr[j+1]:
                arr[j] = arr[j+1]
                arr[j+1] = arr[j]
    return arr

print(bubble_sort([4, 2, 1, 8, 7, 6]))
```

Note that since Python is an interpreted language we can use the `pdb` shell to execute commands and to execute instructions. [`ipdb`](https://pypi.org/project/ipdb/) is an improved `pdb` that uses the [`IPython`](https://ipython.org/) REPL enabling tab completion, syntax highlighting, better tracebacks, and better introspection while retaining the same interface as the `pdb` module.

For more low level programming you will probably want to look into [`gdb`](https://www.gnu.org/software/gdb/) (and its quality of life modification [`pwndbg`](https://github.com/pwndbg/pwndbg)) and [`lldb`](https://lldb.llvm.org/). They are optimized for C-like language debugging but will let you probe pretty much any process and get its current machine state: registers, stack, program counter, &c.

### 7.1.4 Specialized Tools

Even if what you are trying to debug is a black box binary there are tools that can help you with that. Whenever programs need to perform actions that only the kernel can, they use [System Calls](https://en.wikipedia.org/wiki/System_call). There are commands that let you trace the syscalls your program makes. In Linux there’s [`strace`](https://www.man7.org/linux/man-pages/man1/strace.1.html) and macOS and BSD have [`dtrace`](http://dtrace.org/blogs/about/). `dtrace` can be tricky to use because it uses its own `D` language, but there is a wrapper called [`dtruss`](https://www.manpagez.com/man/1/dtruss/) that provides an interface more similar to `strace` (more details [here](https://8thlight.com/blog/colin-jones/2015/11/06/dtrace-even-better-than-strace-for-osx.html)).

Below are some examples of using `strace` or `dtruss` to show [`stat`](https://www.man7.org/linux/man-pages/man2/stat.2.html) syscall traces for an execution of `ls`. For a deeper dive into `strace`, [this article](https://blogs.oracle.com/linux/strace-the-sysadmins-microscope-v2) and [this zine](https://jvns.ca/strace-zine-unfolded.pdf) are good reads.

```
# On Linux
sudo strace -e lstat ls -l > /dev/null
4
# On macOS
sudo dtruss -t lstat64_extended ls -l > /dev/null
```

Under some circumstances, you may need to look at the network packets to figure out the issue in your program. Tools like [`tcpdump`](https://www.man7.org/linux/man-pages/man1/tcpdump.1.html) and [Wireshark](https://www.wireshark.org/) are network packet analyzers that let you read the contents of network packets and filter them based on different criteria.

For web development, the Chrome/Firefox developer tools are quite handy. They feature a large number of tools, including:

-   Source code - Inspect the HTML/CSS/JS source code of any website.
-   Live HTML, CSS, JS modification - Change the website content, styles and behavior to test (you can see for yourself that website screenshots are not valid proofs).
-   Javascript shell - Execute commands in the JS REPL.
-   Network - Analyze the requests timeline.
-   Storage - Look into the Cookies and local application storage.

### 7.1.5 Static Analysis

For some issues you do not need to run any code. For example, just by carefully looking at a piece of code you could realize that your loop variable is shadowing an already existing variable or function name; or that a program reads a variable before defining it. Here is where [static analysis](https://en.wikipedia.org/wiki/Static_program_analysis) tools come into play. Static analysis programs take source code as input and analyze it using coding rules to reason about its correctness.

In the following Python snippet there are several mistakes. First, our loop variable `foo` shadows the previous definition of the function `foo`. We also wrote `baz` instead of `bar` in the last line, so the program will crash after completing the `sleep` call (which will take one minute).

```python
import time

def foo():
    return 42

for foo in range(5):
    print(foo)
bar = 1
bar *= 0.2
time.sleep(60)
print(baz)
```

Static analysis tools can identify this kind of issues. When we run [`pyflakes`](https://pypi.org/project/pyflakes) on the code we get the errors related to both bugs. [`mypy`](http://mypy-lang.org/) is another tool that can detect type checking issues. Here, `mypy` will warn us that `bar` is initially an `int` and is then casted to a `float`. Again, note that all these issues were detected without having to run the code.

```shell
$ pyflakes foobar.py
foobar.py:6: redefinition of unused 'foo' from line 3
foobar.py:11: undefined name 'baz'

$ mypy foobar.py
foobar.py:6: error: Incompatible types in assignment (expression has type "int", variable has type "Callable[[], Any]")
foobar.py:9: error: Incompatible types in assignment (expression has type "float", variable has type "int")
foobar.py:11: error: Name 'baz' is not defined
Found 3 errors in 1 file (checked 1 source file)
```

In the shell tools lecture we covered [`shellcheck`](https://www.shellcheck.net/), which is a similar tool for shell scripts.

Most editors and IDEs support displaying the output of these tools within the editor itself, highlighting the locations of warnings and errors. This is often called **code linting** and it can also be used to display other types of issues such as stylistic violations or insecure constructs.

In vim, the plugins [`ale`](https://vimawesome.com/plugin/ale) or [`syntastic`](https://vimawesome.com/plugin/syntastic) will let you do that. For Python, [`pylint`](https://github.com/PyCQA/pylint) and [`pep8`](https://pypi.org/project/pep8/) are examples of stylistic linters and [`bandit`](https://pypi.org/project/bandit/) is a tool designed to find common security issues. For other languages people have compiled comprehensive lists of useful static analysis tools, such as [Awesome Static Analysis](https://github.com/mre/awesome-static-analysis) (you may want to take a look at the _Writing_ section) and for linters there is [Awesome Linters](https://github.com/caramelomartins/awesome-linters).

A complementary tool to stylistic linting are code formatters such as [`black`](https://github.com/psf/black) for Python, `gofmt` for Go, `rustfmt` for Rust or [`prettier`](https://prettier.io/) for JavaScript, HTML and CSS. These tools autoformat your code so that it’s consistent with common stylistic patterns for the given programming language. Although you might be unwilling to give stylistic control about your code, standardizing code format will help other people read your code and will make you better at reading other people’s (stylistically standardized) code.

## 7.2 Profiling

Even if your code functionally behaves as you would expect, that might not be good enough if it takes all your CPU or memory in the process. Algorithms classes often teach big _O_ notation but not how to find hot spots in your programs. Since [premature optimization is the root of all evil](http://wiki.c2.com/?PrematureOptimization), you should learn about profilers and monitoring tools. They will help you understand which parts of your program are taking most of the time and/or resources so you can focus on optimizing those parts.

### 7.2.1 Timing

Similarly to the debugging case, in many scenarios it can be enough to just print the time it took your code between two points. Here is an example in Python using the [`time`](https://docs.python.org/3/library/time.html) module.

```python
import time, random
n = random.randint(1, 10) * 100

# Get current time
start = time.time()

# Do some work
print("Sleeping for {} ms".format(n))
time.sleep(n/1000)

# Compute time between start and now
print(time.time() - start)

# Output
# Sleeping for 500 ms
# 0.5713930130004883
```

However, wall clock time can be misleading since your computer might be running other processes at the same time or waiting for events to happen. It is common for tools to make a distinction between _Real_, _User_ and _Sys_ time. In general, _User_ + _Sys_ tells you how much time your process actually spent in the CPU (more detailed explanation [here](https://stackoverflow.com/questions/556405/what-do-real-user-and-sys-mean-in-the-output-of-time1)).

-   _Real_ - Wall clock elapsed time from start to finish of the program, including the time taken by other processes and time taken while blocked (e.g. waiting for I/O or network)
-   _User_ - Amount of time spent in the CPU running user code
-   _Sys_ - Amount of time spent in the CPU running kernel code

For example, try running a command that performs an HTTP request and prefixing it with [`time`](https://www.man7.org/linux/man-pages/man1/time.1.html). Under a slow connection you might get an output like the one below. Here it took over 2 seconds for the request to complete but the process only took 15ms of CPU user time and 12ms of kernel CPU time.

```
$ time curl https://missing.csail.mit.edu &> /dev/null
real    0m2.561s
user    0m0.015s
sys     0m0.012s
```

### 7.2.2 Profilers

#### 7.2.2.1 CPU

Most of the time when people refer to _profilers_ they actually mean _CPU profilers_, which are the most common. There are two main types of CPU profilers: _tracing_ and _sampling_ profilers. Tracing profilers keep a record of every function call your program makes whereas sampling profilers probe your program periodically (commonly every millisecond) and record the program’s stack. They use these records to present aggregate statistics of what your program spent the most time doing. [Here](https://jvns.ca/blog/2017/12/17/how-do-ruby---python-profilers-work-) is a good intro article if you want more detail on this topic.

Most programming languages have some sort of command line profiler that you can use to analyze your code. They often integrate with full fledged IDEs but for this lecture we are going to focus on the command line tools themselves.

In Python we can use the `cProfile` module to profile time per function call. Here is a simple example that implements a rudimentary grep in Python:

```python
#!/usr/bin/env python

import sys, re

def grep(pattern, file):
    with open(file, 'r') as f:
        print(file)
        for i, line in enumerate(f.readlines()):
            pattern = re.compile(pattern)
            match = pattern.search(line)
            if match is not None:
                print("{}: {}".format(i, line), end="")

if __name__ == '__main__':
    times = int(sys.argv[1])
    pattern = sys.argv[2]
    for i in range(times):
        for file in sys.argv[3:]:
            grep(pattern, file)
```

We can profile this code using the following command. Analyzing the output we can see that IO is taking most of the time and that compiling the regex takes a fair amount of time as well. Since the regex only needs to be compiled once, we can factor it out of the for.

```
$ python -m cProfile -s tottime grep.py 1000 '^(import|\s*def)[^,]*$' *.py

[omitted program output]

 ncalls  tottime  percall  cumtime  percall filename:lineno(function)
     8000    0.266    0.000    0.292    0.000 {built-in method io.open}
     8000    0.153    0.000    0.894    0.000 grep.py:5(grep)
    17000    0.101    0.000    0.101    0.000 {built-in method builtins.print}
     8000    0.100    0.000    0.129    0.000 {method 'readlines' of '_io._IOBase' objects}
    93000    0.097    0.000    0.111    0.000 re.py:286(_compile)
    93000    0.069    0.000    0.069    0.000 {method 'search' of '_sre.SRE_Pattern' objects}
    93000    0.030    0.000    0.141    0.000 re.py:231(compile)
    17000    0.019    0.000    0.029    0.000 codecs.py:318(decode)
        1    0.017    0.017    0.911    0.911 grep.py:3(<module>)

[omitted lines]
```

A caveat of Python’s `cProfile` profiler (and many profilers for that matter) is that they display time per function call. That can become unintuitive really fast, especially if you are using third party libraries in your code since internal function calls are also accounted for. A more intuitive way of displaying profiling information is to include the time taken per line of code, which is what _line profilers_ do.

For instance, the following piece of Python code performs a request to the class website and parses the response to get all URLs in the page:

```python
#!/usr/bin/env python
import requests
from bs4 import BeautifulSoup

# This is a decorator that tells line_profiler
# that we want to analyze this function
@profile
def get_urls():
    response = requests.get('https://missing.csail.mit.edu')
    s = BeautifulSoup(response.content, 'lxml')
    urls = []
    for url in s.find_all('a'):
        urls.append(url['href'])

if __name__ == '__main__':
    get_urls()
```

If we used Python’s `cProfile` profiler we’d get over 2500 lines of output, and even with sorting it’d be hard to understand where the time is being spent. A quick run with [`line_profiler`](https://github.com/pyutils/line_profiler) shows the time taken per line:

```
$ kernprof -l -v a.py
Wrote profile results to urls.py.lprof
Timer unit: 1e-06 s

Total time: 0.636188 s
File: a.py
Function: get_urls at line 5

Line #  Hits         Time  Per Hit   % Time  Line Contents
==============================================================
 5                                           @profile
 6                                           def get_urls():
 7         1     613909.0 613909.0     96.5      response = requests.get('https://missing.csail.mit.edu')
 8         1      21559.0  21559.0      3.4      s = BeautifulSoup(response.content, 'lxml')
 9         1          2.0      2.0      0.0      urls = []
10        25        685.0     27.4      0.1      for url in s.find_all('a'):
11        24         33.0      1.4      0.0          urls.append(url['href'])
```

#### 7.2.2.2 Memory

In languages like C or C++ memory leaks can cause your program to never release memory that it doesn’t need anymore. To help in the process of memory debugging you can use tools like [Valgrind](https://valgrind.org/) that will help you identify memory leaks.

In garbage collected languages like Python it is still useful to use a memory profiler because as long as you have pointers to objects in memory they won’t be garbage collected. Here’s an example program and its associated output when running it with [memory-profiler](https://pypi.org/project/memory-profiler/) (note the decorator like in `line-profiler`).

```
@profile
def my_func():
    a = [1] * (10 ** 6)
    b = [2] * (2 * 10 ** 7)
    del b
    return a

if __name__ == '__main__':
    my_func()
```

```
$ python -m memory_profiler example.py
Line #    Mem usage  Increment   Line Contents
==============================================
     3                           @profile
     4      5.97 MB    0.00 MB   def my_func():
     5     13.61 MB    7.64 MB       a = [1] * (10 ** 6)
     6    166.20 MB  152.59 MB       b = [2] * (2 * 10 ** 7)
     7     13.61 MB -152.59 MB       del b
     8     13.61 MB    0.00 MB       return a
```

#### 7.2.2.3 Event Profiling

As it was the case for `strace` for debugging, you might want to ignore the specifics of the code that you are running and treat it like a black box when profiling. The [`perf`](https://www.man7.org/linux/man-pages/man1/perf.1.html) command abstracts CPU differences away and does not report time or memory, but instead it reports system events related to your programs. For example, `perf` can easily report poor cache locality, high amounts of page faults or livelocks. Here is an overview of the command:

-   `perf list` - List the events that can be traced with perf
-   `perf stat COMMAND ARG1 ARG2` - Gets counts of different events related a process or command
-   `perf record COMMAND ARG1 ARG2` - Records the run of a command and saves the statistical data into a file called `perf.data`
-   `perf report` - Formats and prints the data collected in `perf.data`

#### 7.2.2.4 Visualization

Profiler output for real world programs will contain large amounts of information because of the inherent complexity of software projects. Humans are visual creatures and are quite terrible at reading large amounts of numbers and making sense of them. Thus there are many tools for displaying profiler’s output in an easier to parse way.

One common way to display CPU profiling information for sampling profilers is to use a [Flame Graph](http://www.brendangregg.com/flamegraphs.html), which will display a hierarchy of function calls across the Y axis and time taken proportional to the X axis. They are also interactive, letting you zoom into specific parts of the program and get their stack traces (try clicking in the image below).

![[Study Log/resources/cpu-bash-flamegraph.svg]]

Call graphs or control flow graphs display the relationships between subroutines within a program by including functions as nodes and functions calls between them as directed edges. When coupled with profiling information such as the number of calls and time taken, call graphs can be quite useful for interpreting the flow of a program. In Python you can use the [`pycallgraph`](https://pycallgraph.readthedocs.io/) library to generate them.

![[Study Log/resources/Pasted image 20230113125922.png]]

### 7.2.3 Resource Monitoring

Sometimes, the first step towards analyzing the performance of your program is to understand what its actual resource consumption is. Programs often run slowly when they are resource constrained, e.g. without enough memory or on a slow network connection. There are a myriad of command line tools for probing and displaying different system resources like CPU usage, memory usage, network, disk usage and so on.

-   **General Monitoring** - Probably the most popular is [`htop`](https://htop.dev/), which is an improved version of [`top`](https://www.man7.org/linux/man-pages/man1/top.1.html). `htop` presents various statistics for the currently running processes on the system. `htop` has a myriad of options and keybinds, some useful ones are: `<F6>` to sort processes, `t` to show tree hierarchy and `h` to toggle threads. See also [`glances`](https://nicolargo.github.io/glances/) for similar implementation with a great UI. For getting aggregate measures across all processes, [`dstat`](http://dag.wiee.rs/home-made/dstat/) is another nifty tool that computes real-time resource metrics for lots of different subsystems like I/O, networking, CPU utilization, context switches, &c.
-   **I/O operations** - [`iotop`](https://www.man7.org/linux/man-pages/man8/iotop.8.html) displays live I/O usage information and is handy to check if a process is doing heavy I/O disk operations
-   **Disk Usage** - [`df`](https://www.man7.org/linux/man-pages/man1/df.1.html) displays metrics per partitions and [`du`](http://man7.org/linux/man-pages/man1/du.1.html) displays **d**isk **u**sage per file for the current directory. In these tools the `-h` flag tells the program to print with **h**uman readable format. A more interactive version of `du` is [`ncdu`](https://dev.yorhel.nl/ncdu) which lets you navigate folders and delete files and folders as you navigate.
-   **Memory Usage** - [`free`](https://www.man7.org/linux/man-pages/man1/free.1.html) displays the total amount of free and used memory in the system. Memory is also displayed in tools like `htop`.
-   **Open Files** - [`lsof`](https://www.man7.org/linux/man-pages/man8/lsof.8.html) lists file information about files opened by processes. It can be quite useful for checking which process has opened a specific file.
-   **Network Connections and Config** - [`ss`](https://www.man7.org/linux/man-pages/man8/ss.8.html) lets you monitor incoming and outgoing network packets statistics as well as interface statistics. A common use case of `ss` is figuring out what process is using a given port in a machine. For displaying routing, network devices and interfaces you can use [`ip`](http://man7.org/linux/man-pages/man8/ip.8.html). Note that `netstat` and `ifconfig` have been deprecated in favor of the former tools respectively.
-   **Network Usage** - [`nethogs`](https://github.com/raboof/nethogs) and [`iftop`](http://www.ex-parrot.com/pdw/iftop/) are good interactive CLI tools for monitoring network usage.

If you want to test these tools you can also artificially impose loads on the machine using the [`stress`](https://linux.die.net/man/1/stress) command.

#### 7.2.3.1 Specialized tools

Sometimes, black box benchmarking is all you need to determine what software to use. Tools like [`hyperfine`](https://github.com/sharkdp/hyperfine) let you quickly benchmark command line programs. For instance, in the shell tools and scripting lecture we recommended `fd` over `find`. We can use `hyperfine` to compare them in tasks we run often. E.g. in the example below `fd` was 20x faster than `find` in my machine.

```
$ hyperfine --warmup 3 'fd -e jpg' 'find . -iname "*.jpg"'
Benchmark #1: fd -e jpg
  Time (mean ± σ):      51.4 ms ±   2.9 ms    [User: 121.0 ms, System: 160.5 ms]
  Range (min … max):    44.2 ms …  60.1 ms    56 runs

Benchmark #2: find . -iname "*.jpg"
  Time (mean ± σ):      1.126 s ±  0.101 s    [User: 141.1 ms, System: 956.1 ms]
  Range (min … max):    0.975 s …  1.287 s    10 runs

Summary
  'fd -e jpg' ran
   21.89 ± 2.33 times faster than 'find . -iname "*.jpg"'
```

As it was the case for debugging, browsers also come with a fantastic set of tools for profiling webpage loading, letting you figure out where time is being spent (loading, rendering, scripting, &c). More info for [Firefox](https://profiler.firefox.com/docs/) and [Chrome](https://developers.google.com/web/tools/chrome-devtools/rendering-tools).

## 7.3 Exercises

### 7.3.1 Debugging

1.  Use `journalctl` on Linux or `log show` on macOS to get the super user accesses and commands in the last day. If there aren’t any you can execute some harmless commands such as `sudo ls` and check again.
    
2.  Do [this](https://github.com/spiside/pdb-tutorial) hands on `pdb` tutorial to familiarize yourself with the commands. For a more in depth tutorial read [this](https://realpython.com/python-debugging-pdb).
    
3.  Install [`shellcheck`](https://www.shellcheck.net/) and try checking the following script. What is wrong with the code? Fix it. Install a linter plugin in your editor so you can get your warnings automatically.
    
    ```
    #!/bin/sh
    ## Example: a typical script with several problems
    for f in $(ls *.m3u)
    do
      grep -qi hq.*mp3 $f \
        && echo -e 'Playlist $f contains a HQ file in mp3 format'
    done
    ```
    
4.  (Advanced) Read about [reversible debugging](https://undo.io/resources/reverse-debugging-whitepaper/) and get a simple example working using [`rr`](https://rr-project.org/) or [`RevPDB`](https://morepypy.blogspot.com/2016/07/reverse-debugging-for-python.html).

### 7.3.2 Profiling

5.  [Here](https://missing.csail.mit.edu/static/files/sorts.py) are some sorting algorithm implementations. Use [`cProfile`](https://docs.python.org/3/library/profile.html) and [`line_profiler`](https://github.com/pyutils/line_profiler) to compare the runtime of insertion sort and quicksort. What is the bottleneck of each algorithm? Use then `memory_profiler` to check the memory consumption, why is insertion sort better? Check now the inplace version of quicksort. Challenge: Use `perf` to look at the cycle counts and cache hits and misses of each algorithm.
    
6.  Here’s some (arguably convoluted) Python code for computing Fibonacci numbers using a function for each number.
    
    ```
    #!/usr/bin/env python
    def fib0(): return 0
    
    def fib1(): return 1
    
    s = """def fib{}(): return fib{}() + fib{}()"""
    
    if __name__ == '__main__':
    
        for n in range(2, 10):
            exec(s.format(n, n-1, n-2))
        # from functools import lru_cache
        # for n in range(10):
        #     exec("fib{} = lru_cache(1)(fib{})".format(n, n))
        print(eval("fib9()"))
    ```
    
    Put the code into a file and make it executable. Install prerequisites: [`pycallgraph`](https://pycallgraph.readthedocs.io/) and [`graphviz`](http://graphviz.org/). (If you can run `dot`, you already have GraphViz.) Run the code as is with `pycallgraph graphviz -- ./fib.py` and check the `pycallgraph.png` file. How many times is `fib0` called?. We can do better than that by memoizing the functions. Uncomment the commented lines and regenerate the images. How many times are we calling each `fibN` function now?
    
7.  A common issue is that a port you want to listen on is already taken by another process. Let’s learn how to discover that process pid. First execute `python -m http.server 4444` to start a minimal web server listening on port `4444`. On a separate terminal run `lsof | grep LISTEN` to print all listening processes and ports. Find that process pid and terminate it by running `kill <PID>`.
    
8.  Limiting processes resources can be another handy tool in your toolbox. Try running `stress -c 3` and visualize the CPU consumption with `htop`. Now, execute `taskset --cpu-list 0,2 stress -c 3` and visualize it. Is `stress` taking three CPUs? Why not? Read [`man taskset`](https://www.man7.org/linux/man-pages/man1/taskset.1.html). Challenge: achieve the same using [`cgroups`](https://www.man7.org/linux/man-pages/man7/cgroups.7.html). Try limiting the memory consumption of `stress -m`.
    
9.  (Advanced) The command `curl ipinfo.io` performs a HTTP request and fetches information about your public IP. Open [Wireshark](https://www.wireshark.org/) and try to sniff the request and reply packets that `curl` sent and received. (Hint: Use the `http` filter to just watch HTTP packets).

# 8. Metaprogramming

What do we mean by “metaprogramming”? Well, it was the best collective term we could come up with for the set of things that are more about _process_ than they are about writing code or working more efficiently. In this lecture, we will look at systems for building and testing your code, and for managing dependencies. These may seem like they are of limited importance in your day-to-day as a student, but the moment you interact with a larger code base through an internship or once you enter the “real world”, you will see this everywhere. We should note that “metaprogramming” can also mean “[programs that operate on programs](https://en.wikipedia.org/wiki/Metaprogramming)”, whereas that is not quite the definition we are using for the purposes of this lecture.

## 8.1 Build systems

If you write a paper in LaTeX, what are the commands you need to run to produce your paper? What about the ones used to run your benchmarks, plot them, and then insert that plot into your paper? Or to compile the code provided in the class you’re taking and then running the tests?

For most projects, whether they contain code or not, there is a “build process”. Some sequence of operations you need to do to go from your inputs to your outputs. Often, that process might have many steps, and many branches. Run this to generate this plot, that to generate those results, and something else to produce the final paper. As with so many of the things we have seen in this class, you are not the first to encounter this annoyance, and luckily there exist many tools to help you!

These are usually called “build systems”, and there are _many_ of them. Which one you use depends on the task at hand, your language of preference, and the size of the project. At their core, they are all very similar though. You define a number of _dependencies_, a number of _targets_, and _rules_ for going from one to the other. You tell the build system that you want a particular target, and its job is to find all the transitive dependencies of that target, and then apply the rules to produce intermediate targets all the way until the final target has been produced. Ideally, the build system does this without unnecessarily executing rules for targets whose dependencies haven’t changed and where the result is available from a previous build.

`make` is one of the most common build systems out there, and you will usually find it installed on pretty much any UNIX-based computer. It has its warts, but works quite well for simple-to-moderate projects. When you run `make`, it consults a file called `Makefile` in the current directory. All the targets, their dependencies, and the rules are defined in that file. Let’s take a look at one:

```
paper.pdf: paper.tex plot-data.png
	pdflatex paper.tex

plot-%.png: %.dat plot.py
	./plot.py -i $*.dat -o $@
```

Each directive in this file is a rule for how to produce the left-hand side using the right-hand side. Or, phrased differently, the things named on the right-hand side are dependencies, and the left-hand side is the target. The indented block is a sequence of programs to produce the target from those dependencies. In `make`, the first directive also defines the default goal. If you run `make` with no arguments, this is the target it will build. Alternatively, you can run something like `make plot-data.png`, and it will build that target instead.

The `%` in a rule is a “pattern”, and will match the same string on the left and on the right. For example, if the target `plot-foo.png` is requested, `make` will look for the dependencies `foo.dat` and `plot.py`. Now let’s look at what happens if we run `make` with an empty source directory.

```
$ make
make: *** No rule to make target 'paper.tex', needed by 'paper.pdf'.  Stop.
```

`make` is helpfully telling us that in order to build `paper.pdf`, it needs `paper.tex`, and it has no rule telling it how to make that file. Let’s try making it!

```
$ touch paper.tex
$ make
make: *** No rule to make target 'plot-data.png', needed by 'paper.pdf'.  Stop.
```

Hmm, interesting, there _is_ a rule to make `plot-data.png`, but it is a pattern rule. Since the source files do not exist (`data.dat`), `make` simply states that it cannot make that file. Let’s try creating all the files:

```
$ cat paper.tex
\documentclass{article}
\usepackage{graphicx}
\begin{document}
\includegraphics[scale=0.65]{plot-data.png}
\end{document}
$ cat plot.py
#!/usr/bin/env python
import matplotlib
import matplotlib.pyplot as plt
import numpy as np
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-i', type=argparse.FileType('r'))
parser.add_argument('-o')
args = parser.parse_args()

data = np.loadtxt(args.i)
plt.plot(data[:, 0], data[:, 1])
plt.savefig(args.o)
$ cat data.dat
1 1
2 2
3 3
4 4
5 8
```

Now what happens if we run `make`?

```
$ make
./plot.py -i data.dat -o plot-data.png
pdflatex paper.tex
... lots of output ...
```

And look, it made a PDF for us! What if we run `make` again?

```
$ make
make: 'paper.pdf' is up to date.
```

It didn’t do anything! Why not? Well, because it didn’t need to. It checked that all of the previously-built targets were still up to date with respect to their listed dependencies. We can test this by modifying `paper.tex` and then re-running `make`:

```
$ vim paper.tex
$ make
pdflatex paper.tex
...
```

Notice that `make` did _not_ re-run `plot.py` because that was not necessary; none of `plot-data.png`’s dependencies changed!

## 8.2 Dependency management

At a more macro level, your software projects are likely to have dependencies that are themselves projects. You might depend on installed programs (like `python`), system packages (like `openssl`), or libraries within your programming language (like `matplotlib`). These days, most dependencies will be available through a _repository_ that hosts a large number of such dependencies in a single place, and provides a convenient mechanism for installing them. Some examples include the Ubuntu package repositories for Ubuntu system packages, which you access through the `apt` tool, RubyGems for Ruby libraries, PyPi for Python libraries, or the Arch User Repository for Arch Linux user-contributed packages.

Since the exact mechanisms for interacting with these repositories vary a lot from repository to repository and from tool to tool, we won’t go too much into the details of any specific one in this lecture. What we _will_ cover is some of the common terminology they all use. The first among these is _versioning_. Most projects that other projects depend on issue a _version number_ with every release. Usually something like 8.1.3 or 64.1.20192004. They are often, but not always, numerical. Version numbers serve many purposes, and one of the most important of them is to ensure that software keeps working. Imagine, for example, that I release a new version of my library where I have renamed a particular function. If someone tried to build some software that depends on my library after I release that update, the build might fail because it calls a function that no longer exists! Versioning attempts to solve this problem by letting a project say that it depends on a particular version, or range of versions, of some other project. That way, even if the underlying library changes, dependent software continues building by using an older version of my library.

That also isn’t ideal though! What if I issue a security update which does _not_ change the public interface of my library (its “API”), and which any project that depended on the old version should immediately start using? This is where the different groups of numbers in a version come in. The exact meaning of each one varies between projects, but one relatively common standard is [_semantic versioning_](https://semver.org/). With semantic versioning, every version number is of the form: major.minor.patch. The rules are:

-   If a new release does not change the API, increase the patch version.
-   If you _add_ to your API in a backwards-compatible way, increase the minor version.
-   If you change the API in a non-backwards-compatible way, increase the major version.

This already provides some major advantages. Now, if my project depends on your project, it _should_ be safe to use the latest release with the same major version as the one I built against when I developed it, as long as its minor version is at least what it was back then. In other words, if I depend on your library at version `1.3.7`, then it _should_ be fine to build it with `1.3.8`, `1.6.1`, or even `1.3.0`. Version `2.2.4` would probably not be okay, because the major version was increased. We can see an example of semantic versioning in Python’s version numbers. Many of you are probably aware that Python 2 and Python 3 code do not mix very well, which is why that was a _major_ version bump. Similarly, code written for Python 3.5 might run fine on Python 3.7, but possibly not on 3.4.

When working with dependency management systems, you may also come across the notion of _lock files_. A lock file is simply a file that lists the exact version you are _currently_ depending on of each dependency. Usually, you need to explicitly run an update program to upgrade to newer versions of your dependencies. There are many reasons for this, such as avoiding unnecessary recompiles, having reproducible builds, or not automatically updating to the latest version (which may be broken). An extreme version of this kind of dependency locking is _vendoring_, which is where you copy all the code of your dependencies into your own project. That gives you total control over any changes to it, and lets you introduce your own changes to it, but also means you have to explicitly pull in any updates from the upstream maintainers over time.

## 8.3 Continuous integration systems

As you work on larger and larger projects, you’ll find that there are often additional tasks you have to do whenever you make a change to it. You might have to upload a new version of the documentation, upload a compiled version somewhere, release the code to pypi, run your test suite, and all sort of other things. Maybe every time someone sends you a pull request on GitHub, you want their code to be style checked and you want some benchmarks to run? When these kinds of needs arise, it’s time to take a look at continuous integration.

Continuous integration, or CI, is an umbrella term for “stuff that runs whenever your code changes”, and there are many companies out there that provide various types of CI, often for free for open-source projects. Some of the big ones are Travis CI, Azure Pipelines, and GitHub Actions. They all work in roughly the same way: you add a file to your repository that describes what should happen when various things happen to that repository. By far the most common one is a rule like “when someone pushes code, run the test suite”. When the event triggers, the CI provider spins up a virtual machines (or more), runs the commands in your “recipe”, and then usually notes down the results somewhere. You might set it up so that you are notified if the test suite stops passing, or so that a little badge appears on your repository as long as the tests pass.

As an example of a CI system, the class website is set up using GitHub Pages. Pages is a CI action that runs the Jekyll blog software on every push to `master` and makes the built site available on a particular GitHub domain. This makes it trivial for us to update the website! We just make our changes locally, commit them with git, and then push. CI takes care of the rest.

### 8.3.1 A brief aside on testing

Most large software projects come with a “test suite”. You may already be familiar with the general concept of testing, but we thought we’d quickly mention some approaches to testing and testing terminology that you may encounter in the wild:

-   Test suite: a collective term for all the tests
-   Unit test: a “micro-test” that tests a specific feature in isolation
-   Integration test: a “macro-test” that runs a larger part of the system to check that different feature or components work _together_.
-   Regression test: a test that implements a particular pattern that _previously_ caused a bug to ensure that the bug does not resurface.
-   Mocking: to replace a function, module, or type with a fake implementation to avoid testing unrelated functionality. For example, you might “mock the network” or “mock the disk”.

## 8.4 Exercises

1.  Most makefiles provide a target called `clean`. This isn’t intended to produce a file called `clean`, but instead to clean up any files that can be re-built by make. Think of it as a way to “undo” all of the build steps. Implement a `clean` target for the `paper.pdf` `Makefile` above. You will have to make the target [phony](https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html). You may find the [`git ls-files`](https://git-scm.com/docs/git-ls-files) subcommand useful. A number of other very common make targets are listed [here](https://www.gnu.org/software/make/manual/html_node/Standard-Targets.html#Standard-Targets).
2.  Take a look at the various ways to specify version requirements for dependencies in [Rust’s build system](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html). Most package repositories support similar syntax. For each one (caret, tilde, wildcard, comparison, and multiple), try to come up with a use-case in which that particular kind of requirement makes sense.
3.  Git can act as a simple CI system all by itself. In `.git/hooks` inside any git repository, you will find (currently inactive) files that are run as scripts when a particular action happens. Write a [`pre-commit`](https://git-scm.com/docs/githooks#_pre_commit) hook that runs `make paper.pdf` and refuses the commit if the `make` command fails. This should prevent any commit from having an unbuildable version of the paper.
4.  Set up a simple auto-published page using [GitHub Pages](https://pages.github.com/). Add a [GitHub Action](https://github.com/features/actions) to the repository to run `shellcheck` on any shell files in that repository (here is [one way to do it](https://github.com/marketplace/actions/shellcheck)). Check that it works!
5.  [Build your own](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/building-actions) GitHub action to run [`proselint`](http://proselint.com/) or [`write-good`](https://github.com/btford/write-good) on all the `.md` files in the repository. Enable it in your repository, and check that it works by filing a pull request with a typo in it.

# 9. Security and Cryptography

Last year’s [security and privacy lecture](https://missing.csail.mit.edu/2019/security/) focused on how you can be more secure as a computer _user_. This year, we will focus on security and cryptography concepts that are relevant in understanding tools covered earlier in this class, such as the use of hash functions in Git or key derivation functions and symmetric/asymmetric cryptosystems in SSH.

This lecture is not a substitute for a more rigorous and complete course on computer systems security ([6.858](https://css.csail.mit.edu/6.858/)) or cryptography ([6.857](https://courses.csail.mit.edu/6.857/) and 6.875). Don’t do security work without formal training in security. Unless you’re an expert, don’t [roll your own crypto](https://www.schneier.com/blog/archives/2015/05/amateurs_produc.html). The same principle applies to systems security.

This lecture has a very informal (but we think practical) treatment of basic cryptography concepts. This lecture won’t be enough to teach you how to _design_ secure systems or cryptographic protocols, but we hope it will be enough to give you a general understanding of the programs and protocols you already use.

## 9.1 Entropy

[Entropy](https://en.wikipedia.org/wiki/Entropy_(information_theory)) is a measure of randomness. This is useful, for example, when determining the strength of a password.

![[Study Log/resources/Pasted image 20230113131438.png]]

As the above [XKCD comic](https://xkcd.com/936/) illustrates, a password like “correcthorsebatterystaple” is more secure than one like “Tr0ub4dor&3”. But how do you quantify something like this?

Entropy is measured in _bits_, and when selecting uniformly at random from a set of possible outcomes, the entropy is equal to `log_2(# of possibilities)`. A fair coin flip gives 1 bit of entropy. A dice roll (of a 6-sided die) has ~2.58 bits of entropy.

You should consider that the attacker knows the _model_ of the password, but not the randomness (e.g. from [dice rolls](https://en.wikipedia.org/wiki/Diceware)) used to select a particular password.

How many bits of entropy is enough? It depends on your threat model. For online guessing, as the XKCD comic points out, ~40 bits of entropy is pretty good. To be resistant to offline guessing, a stronger password would be necessary (e.g. 80 bits, or more).

## 9.2 Hash functions

A [cryptographic hash function](https://en.wikipedia.org/wiki/Cryptographic_hash_function) maps data of arbitrary size to a fixed size, and has some special properties. A rough specification of a hash function is as follows:

```
hash(value: array<byte>) -> vector<byte, N>  (for some fixed N)
```

An example of a hash function is [SHA1](https://en.wikipedia.org/wiki/SHA-1), which is used in Git. It maps arbitrary-sized inputs to 160-bit outputs (which can be represented as 40 hexadecimal characters). We can try out the SHA1 hash on an input using the `sha1sum` command:

```
$ printf 'hello' | sha1sum
aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d
$ printf 'hello' | sha1sum
aaf4c61ddcc5e8a2dabede0f3b482cd9aea9434d
$ printf 'Hello' | sha1sum 
f7ff9e8b7bb2e09b70935a5d785e0cc5d9d0abf0
```

At a high level, a hash function can be thought of as a hard-to-invert random-looking (but deterministic) function (and this is the [ideal model of a hash function](https://en.wikipedia.org/wiki/Random_oracle)). A hash function has the following properties:

-   Deterministic: the same input always generates the same output.
-   Non-invertible: it is hard to find an input `m` such that `hash(m) = h` for some desired output `h`.
-   Target collision resistant: given an input `m_1`, it’s hard to find a different input `m_2` such that `hash(m_1) = hash(m_2)`.
-   Collision resistant: it’s hard to find two inputs `m_1` and `m_2` such that `hash(m_1) = hash(m_2)` (note that this is a strictly stronger property than target collision resistance).

Note: while it may work for certain purposes, SHA-1 is [no longer](https://shattered.io/) considered a strong cryptographic hash function. You might find this table of [lifetimes of cryptographic hash functions](https://valerieaurora.org/hash.html) interesting. However, note that recommending specific hash functions is beyond the scope of this lecture. If you are doing work where this matters, you need formal training in security/cryptography.

### 9.2.1 Applications

-   Git, for content-addressed storage. The idea of a [hash function](https://en.wikipedia.org/wiki/Hash_function) is a more general concept (there are non-cryptographic hash functions). Why does Git use a cryptographic hash function?
-   A short summary of the contents of a file. Software can often be downloaded from (potentially less trustworthy) mirrors, e.g. Linux ISOs, and it would be nice to not have to trust them. The official sites usually post hashes alongside the download links (that point to third-party mirrors), so that the hash can be checked after downloading a file.
-   [Commitment schemes](https://en.wikipedia.org/wiki/Commitment_scheme). Suppose you want to commit to a particular value, but reveal the value itself later. For example, I want to do a fair coin toss “in my head”, without a trusted shared coin that two parties can see. I could choose a value `r = random()`, and then share `h = sha256(r)`. Then, you could call heads or tails (we’ll agree that even `r` means heads, and odd `r` means tails). After you call, I can reveal my value `r`, and you can confirm that I haven’t cheated by checking `sha256(r)` matches the hash I shared earlier.

## 9.3 Key derivation functions

A related concept to cryptographic hashes, [key derivation functions](https://en.wikipedia.org/wiki/Key_derivation_function) (KDFs) are used for a number of applications, including producing fixed-length output for use as keys in other cryptographic algorithms. Usually, KDFs are deliberately slow, in order to slow down offline brute-force attacks.

### 9.3.1 Applications

-   Producing keys from passphrases for use in other cryptographic algorithms (e.g. symmetric cryptography, see below).
-   Storing login credentials. Storing plaintext passwords is bad; the right approach is to generate and store a random [salt](https://en.wikipedia.org/wiki/Salt_(cryptography)) `salt = random()` for each user, store `KDF(password + salt)`, and verify login attempts by re-computing the KDF given the entered password and the stored salt.

## 9.4 Symmetric cryptography

Hiding message contents is probably the first concept you think about when you think about cryptography. Symmetric cryptography accomplishes this with the following set of functionality:

```
keygen() -> key  (this function is randomized)

encrypt(plaintext: array<byte>, key) -> array<byte>  (the ciphertext)
decrypt(ciphertext: array<byte>, key) -> array<byte>  (the plaintext)
```

The encrypt function has the property that given the output (ciphertext), it’s hard to determine the input (plaintext) without the key. The decrypt function has the obvious correctness property, that `decrypt(encrypt(m, k), k) = m`.

An example of a symmetric cryptosystem in wide use today is [AES](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard).

### 9.4.1 Applications

-   Encrypting files for storage in an untrusted cloud service. This can be combined with KDFs, so you can encrypt a file with a passphrase. Generate `key = KDF(passphrase)`, and then store `encrypt(file, key)`.

## 9.5 Asymmetric cryptography

The term “asymmetric” refers to there being two keys, with two different roles. A private key, as its name implies, is meant to be kept private, while the public key can be publicly shared and it won’t affect security (unlike sharing the key in a symmetric cryptosystem). Asymmetric cryptosystems provide the following set of functionality, to encrypt/decrypt and to sign/verify:

```
keygen() -> (public key, private key)  (this function is randomized)

encrypt(plaintext: array<byte>, public key) -> array<byte>  (the ciphertext)
decrypt(ciphertext: array<byte>, private key) -> array<byte>  (the plaintext)

sign(message: array<byte>, private key) -> array<byte>  (the signature)
verify(message: array<byte>, signature: array<byte>, public key) -> bool  (whether or not the signature is valid)
```

The encrypt/decrypt functions have properties similar to their analogs from symmetric cryptosystems. A message can be encrypted using the _public_ key. Given the output (ciphertext), it’s hard to determine the input (plaintext) without the _private_ key. The decrypt function has the obvious correctness property, that `decrypt(encrypt(m, public key), private key) = m`.

Symmetric and asymmetric encryption can be compared to physical locks. A symmetric cryptosystem is like a door lock: anyone with the key can lock and unlock it. Asymmetric encryption is like a padlock with a key. You could give the unlocked lock to someone (the public key), they could put a message in a box and then put the lock on, and after that, only you could open the lock because you kept the key (the private key).

The sign/verify functions have the same properties that you would hope physical signatures would have, in that it’s hard to forge a signature. No matter the message, without the _private_ key, it’s hard to produce a signature such that `verify(message, signature, public key)` returns true. And of course, the verify function has the obvious correctness property that `verify(message, sign(message, private key), public key) = true`.

### 9.5.1 Applications

-   [PGP email encryption](https://en.wikipedia.org/wiki/Pretty_Good_Privacy). People can have their public keys posted online (e.g. in a PGP keyserver, or on [Keybase](https://keybase.io/)). Anyone can send them encrypted email.
-   Private messaging. Apps like [Signal](https://signal.org/) and [Keybase](https://keybase.io/) use asymmetric keys to establish private communication channels.
-   Signing software. Git can have GPG-signed commits and tags. With a posted public key, anyone can verify the authenticity of downloaded software.

### 9.5.2 Key distribution

Asymmetric-key cryptography is wonderful, but it has a big challenge of distributing public keys / mapping public keys to real-world identities. There are many solutions to this problem. Signal has one simple solution: trust on first use, and support out-of-band public key exchange (you verify your friends’ “safety numbers” in person). PGP has a different solution, which is [web of trust](https://en.wikipedia.org/wiki/Web_of_trust). Keybase has yet another solution of [social proof](https://keybase.io/blog/chat-apps-softer-than-tofu) (along with other neat ideas). Each model has its merits; we (the instructors) like Keybase’s model.

## 9.6 Case studies

### 9.6.1 Password managers

This is an essential tool that everyone should try to use (e.g. [KeePassXC](https://keepassxc.org/), [pass](https://www.passwordstore.org/), and [1Password](https://1password.com/)). Password managers make it convenient to use unique, randomly generated high-entropy passwords for all your logins, and they save all your passwords in one place, encrypted with a symmetric cipher with a key produced from a passphrase using a KDF.

Using a password manager lets you avoid password reuse (so you’re less impacted when websites get compromised), use high-entropy passwords (so you’re less likely to get compromised), and only need to remember a single high-entropy password.

### 9.6.2 Two-factor authentication

[Two-factor authentication](https://en.wikipedia.org/wiki/Multi-factor_authentication) (2FA) requires you to use a passphrase (“something you know”) along with a 2FA authenticator (like a [YubiKey](https://www.yubico.com/), “something you have”) in order to protect against stolen passwords and [phishing](https://en.wikipedia.org/wiki/Phishing) attacks.

### 9.6.3 Full disk encryption

Keeping your laptop’s entire disk encrypted is an easy way to protect your data in the case that your laptop is stolen. You can use [cryptsetup + LUKS](https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_a_non-root_file_system) on Linux, [BitLocker](https://fossbytes.com/enable-full-disk-encryption-windows-10/) on Windows, or [FileVault](https://support.apple.com/en-us/HT204837) on macOS. This encrypts the entire disk with a symmetric cipher, with a key protected by a passphrase.

### 9.6.4 Private messaging

Use [Signal](https://signal.org/) or [Keybase](https://keybase.io/). End-to-end security is bootstrapped from asymmetric-key encryption. Obtaining your contacts’ public keys is the critical step here. If you want good security, you need to authenticate public keys out-of-band (with Signal or Keybase), or trust social proofs (with Keybase).

### 9.6.5 SSH

We’ve covered the use of SSH and SSH keys in an [earlier lecture](https://missing.csail.mit.edu/2020/command-line/#remote-machines). Let’s look at the cryptography aspects of this.

When you run `ssh-keygen`, it generates an asymmetric keypair, `public_key, private_key`. This is generated randomly, using entropy provided by the operating system (collected from hardware events, etc.). The public key is stored as-is (it’s public, so keeping it a secret is not important), but at rest, the private key should be encrypted on disk. The `ssh-keygen` program prompts the user for a passphrase, and this is fed through a key derivation function to produce a key, which is then used to encrypt the private key with a symmetric cipher.

In use, once the server knows the client’s public key (stored in the `.ssh/authorized_keys` file), a connecting client can prove its identity using asymmetric signatures. This is done through [challenge-response](https://en.wikipedia.org/wiki/Challenge%E2%80%93response_authentication). At a high level, the server picks a random number and sends it to the client. The client then signs this message and sends the signature back to the server, which checks the signature against the public key on record. This effectively proves that the client is in possession of the private key corresponding to the public key that’s in the server’s `.ssh/authorized_keys` file, so the server can allow the client to log in.

## 9.7 Resources

-   [Last year’s notes](https://missing.csail.mit.edu/2019/security/): from when this lecture was more focused on security and privacy as a computer user
-   [Cryptographic Right Answers](https://latacora.micro.blog/2018/04/03/cryptographic-right-answers.html): answers “what crypto should I use for X?” for many common X.

## 9.8 Exercises

1.  **Entropy.**
    1.  Suppose a password is chosen as a concatenation of four lower-case dictionary words, where each word is selected uniformly at random from a dictionary of size 100,000. An example of such a password is `correcthorsebatterystaple`. How many bits of entropy does this have?
    2.  Consider an alternative scheme where a password is chosen as a sequence of 8 random alphanumeric characters (including both lower-case and upper-case letters). An example is `rg8Ql34g`. How many bits of entropy does this have?
    3.  Which is the stronger password?
    4.  Suppose an attacker can try guessing 10,000 passwords per second. On average, how long will it take to break each of the passwords?
2.  **Cryptographic hash functions.** Download a Debian image from a [mirror](https://www.debian.org/CD/http-ftp/) (e.g. [from this Argentinean mirror](http://debian.xfree.com.ar/debian-cd/current/amd64/iso-cd/)). Cross-check the hash (e.g. using the `sha256sum` command) with the hash retrieved from the official Debian site (e.g. [this file](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/SHA256SUMS) hosted at `debian.org`, if you’ve downloaded the linked file from the Argentinean mirror).
3.  **Symmetric cryptography.** Encrypt a file with AES encryption, using [OpenSSL](https://www.openssl.org/): `openssl aes-256-cbc -salt -in {input filename} -out {output filename}`. Look at the contents using `cat` or `hexdump`. Decrypt it with `openssl aes-256-cbc -d -in {input filename} -out {output filename}` and confirm that the contents match the original using `cmp`.
4.  **Asymmetric cryptography.**
    1.  Set up [SSH keys](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2) on a computer you have access to (not Athena, because Kerberos interacts weirdly with SSH keys). Make sure your private key is encrypted with a passphrase, so it is protected at rest.
    2.  [Set up GPG](https://www.digitalocean.com/community/tutorials/how-to-use-gpg-to-encrypt-and-sign-messages)
    3.  Send Anish an encrypted email ([public key](https://keybase.io/anish)).
    4.  Sign a Git commit with `git commit -S` or create a signed Git tag with `git tag -s`. Verify the signature on the commit with `git show --show-signature` or on the tag with `git tag -v`.

# 10. Potpourri

## 10.1 Keyboard remapping

As a programmer, your keyboard is your main input method. As with pretty much anything in your computer, it is configurable (and worth configuring).

The most basic change is to remap keys. This usually involves some software that is listening and, whenever a certain key is pressed, it intercepts that event and replaces it with another event corresponding to a different key. Some examples:

-   Remap Caps Lock to Ctrl or Escape. We (the instructors) highly encourage this setting since Caps Lock has a very convenient location but is rarely used.
-   Remapping PrtSc to Play/Pause music. Most OSes have a play/pause key.
-   Swapping Ctrl and the Meta (Windows or Command) key.

You can also map keys to arbitrary commands of your choosing. This is useful for common tasks that you perform. Here, some software listens for a specific key combination and executes some script whenever that event is detected.

-   Open a new terminal or browser window.
-   Inserting some specific text, e.g. your long email address or your MIT ID number.
-   Sleeping the computer or the displays.

There are even more complex modifications you can configure:

-   Remapping sequences of keys, e.g. pressing shift five times toggles Caps Lock.
-   Remapping on tap vs on hold, e.g. Caps Lock key is remapped to Esc if you quickly tap it, but is remapped to Ctrl if you hold it and use it as a modifier.
-   Having remaps being keyboard or software specific.

Some software resources to get started on the topic:

-   macOS - [karabiner-elements](https://karabiner-elements.pqrs.org/), [skhd](https://github.com/koekeishiya/skhd) or [BetterTouchTool](https://folivora.ai/)
-   Linux - [xmodmap](https://wiki.archlinux.org/index.php/Xmodmap) or [Autokey](https://github.com/autokey/autokey)
-   Windows - Builtin in Control Panel, [AutoHotkey](https://www.autohotkey.com/) or [SharpKeys](https://www.randyrants.com/category/sharpkeys/)
-   QMK - If your keyboard supports custom firmware you can use [QMK](https://docs.qmk.fm/) to configure the hardware device itself so the remaps works for any machine you use the keyboard with.

## 10.2 Daemons

You are probably already familiar with the notion of daemons, even if the word seems new. Most computers have a series of processes that are always running in the background rather than waiting for a user to launch them and interact with them. These processes are called daemons and the programs that run as daemons often end with a `d` to indicate so. For example `sshd`, the SSH daemon, is the program responsible for listening to incoming SSH requests and checking that the remote user has the necessary credentials to log in.

In Linux, `systemd` (the system daemon) is the most common solution for running and setting up daemon processes. You can run `systemctl status` to list the current running daemons. Most of them might sound unfamiliar but are responsible for core parts of the system such as managing the network, solving DNS queries or displaying the graphical interface for the system. Systemd can be interacted with the `systemctl` command in order to `enable`, `disable`, `start`, `stop`, `restart` or check the `status` of services (those are the `systemctl` commands).

More interestingly, `systemd` has a fairly accessible interface for configuring and enabling new daemons (or services). Below is an example of a daemon for running a simple Python app. We won’t go in the details but as you can see most of the fields are pretty self explanatory.

```
# /etc/systemd/system/myapp.service
[Unit]
Description=My Custom App
After=network.target

[Service]
User=foo
Group=foo
WorkingDirectory=/home/foo/projects/mydaemon
ExecStart=/usr/bin/local/python3.7 app.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Also, if you just want to run some program with a given frequency there is no need to build a custom daemon, you can use [`cron`](https://www.man7.org/linux/man-pages/man8/cron.8.html), a daemon your system already runs to perform scheduled tasks.

## 10.3 FUSE

Modern software systems are usually composed of smaller building blocks that are composed together. Your operating system supports using different filesystem backends because there is a common language of what operations a filesystem supports. For instance, when you run `touch` to create a file, `touch` performs a system call to the kernel to create the file and the kernel performs the appropriate filesystem call to create the given file. A caveat is that UNIX filesystems are traditionally implemented as kernel modules and only the kernel is allowed to perform filesystem calls.

[FUSE](https://en.wikipedia.org/wiki/Filesystem_in_Userspace) (Filesystem in User Space) allows filesystems to be implemented by a user program. FUSE lets users run user space code for filesystem calls and then bridges the necessary calls to the kernel interfaces. In practice, this means that users can implement arbitrary functionality for filesystem calls.

For example, FUSE can be used so whenever you perform an operation in a virtual filesystem, that operation is forwarded through SSH to a remote machine, performed there, and the output is returned back to you. This way, local programs can see the file as if it was in your computer while in reality it’s in a remote server. This is effectively what `sshfs` does.

Some interesting examples of FUSE filesystems are:

-   [sshfs](https://github.com/libfuse/sshfs) - Open locally remote files/folder through an SSH connection.
-   [rclone](https://rclone.org/commands/rclone_mount/) - Mount cloud storage services like Dropbox, GDrive, Amazon S3 or Google Cloud Storage and open data locally.
-   [gocryptfs](https://nuetzlich.net/gocryptfs/) - Encrypted overlay system. Files are stored encrypted but once the FS is mounted they appear as plaintext in the mountpoint.
-   [kbfs](https://keybase.io/docs/kbfs) - Distributed filesystem with end-to-end encryption. You can have private, shared and public folders.
-   [borgbackup](https://borgbackup.readthedocs.io/en/stable/usage/mount.html) - Mount your deduplicated, compressed and encrypted backups for ease of browsing.

## 10.4 Backups

Any data that you haven’t backed up is data that could be gone at any moment, forever. It’s easy to copy data around, it’s hard to reliably backup data. Here are some good backup basics and the pitfalls of some approaches.

First, a copy of the data in the same disk is not a backup, because the disk is the single point of failure for all the data. Similarly, an external drive in your home is also a weak backup solution since it could be lost in a fire/robbery/&c. Instead, having an off-site backup is a recommended practice.

Synchronization solutions are not backups. For instance, Dropbox/GDrive are convenient solutions, but when data is erased or corrupted they propagate the change. For the same reason, disk mirroring solutions like RAID are not backups. They don’t help if data gets deleted, corrupted or encrypted by ransomware.

Some core features of good backups solutions are versioning, deduplication and security. Versioning backups ensure that you can access your history of changes and efficiently recover files. Efficient backup solutions use data deduplication to only store incremental changes and reduce the storage overhead. Regarding security, you should ask yourself what someone would need to know/have in order to read your data and, more importantly, to delete all your data and associated backups. Lastly, blindly trusting backups is a terrible idea and you should verify regularly that you can use them to recover data.

Backups go beyond local files in your computer. Given the significant growth of web applications, large amounts of your data are only stored in the cloud. For instance, your webmail, social media photos, music playlists in streaming services or online docs are gone if you lose access to the corresponding accounts. Having an offline copy of this information is the way to go, and you can find online tools that people have built to fetch the data and save it.

For a more detailed explanation, see 2019’s lecture notes on [Backups](https://missing.csail.mit.edu/2019/backups).

## 10.5 APIs

We’ve talked a lot in this class about using your computer more efficiently to accomplish _local_ tasks, but you will find that many of these lessons also extend to the wider internet. Most services online will have “APIs” that let you programmatically access their data. For example, the US government has an API that lets you get weather forecasts, which you could use to easily get a weather forecast in your shell.

Most of these APIs have a similar format. They are structured URLs, often rooted at `api.service.com`, where the path and query parameters indicate what data you want to read or what action you want to perform. For the US weather data for example, to get the forecast for a particular location, you issue GET request (with `curl` for example) to https://api.weather.gov/points/42.3604,-71.094. The response itself contains a bunch of other URLs that let you get specific forecasts for that region. Usually, the responses are formatted as JSON, which you can then pipe through a tool like [`jq`](https://stedolan.github.io/jq/) to massage into what you care about.

Some APIs require authentication, and this usually takes the form of some sort of secret _token_ that you need to include with the request. You should read the documentation for the API to see what the particular service you are looking for uses, but “[OAuth](https://www.oauth.com/)” is a protocol you will often see used. At its heart, OAuth is a way to give you tokens that can “act as you” on a given service, and can only be used for particular purposes. Keep in mind that these tokens are _secret_, and anyone who gains access to your token can do whatever the token allows under _your_ account!

[IFTTT](https://ifttt.com/) is a website and service centered around the idea of APIs — it provides integrations with tons of services, and lets you chain events from them in nearly arbitrary ways. Give it a look!

## 10.6 Common command-line flags/patterns

Command-line tools vary a lot, and you will often want to check out their `man` pages before using them. They often share some common features though that can be good to be aware of:

-   Most tools support some kind of `--help` flag to display brief usage instructions for the tool.
-   Many tools that can cause irrevocable change support the notion of a “dry run” in which they only print what they _would have done_, but do not actually perform the change. Similarly, they often have an “interactive” flag that will prompt you for each destructive action.
-   You can usually use `--version` or `-V` to have the program print its own version (handy for reporting bugs!).
-   Almost all tools have a `--verbose` or `-v` flag to produce more verbose output. You can usually include the flag multiple times (`-vvv`) to get _more_ verbose output, which can be handy for debugging. Similarly, many tools have a `--quiet` flag for making it only print something on error.
-   In many tools, `-` in place of a file name means “standard input” or “standard output”, depending on the argument.
-   Possibly destructive tools are generally not recursive by default, but support a “recursive” flag (often `-r`) to make them recurse.
-   Sometimes, you want to pass something that _looks_ like a flag as a normal argument. For example, imagine you wanted to remove a file called `-r`. Or you want to run one program “through” another, like `ssh machine foo`, and you want to pass a flag to the “inner” program (`foo`). The special argument `--` makes a program _stop_ processing flags and options (things starting with `-`) in what follows, letting you pass things that look like flags without them being interpreted as such: `rm -- -r` or `ssh machine --for-ssh -- foo --for-foo`.

## 10.7 Window managers

Most of you are used to using a “drag and drop” window manager, like what comes with Windows, macOS, and Ubuntu by default. There are windows that just sort of hang there on screen, and you can drag them around, resize them, and have them overlap one another. But these are only one _type_ of window manager, often referred to as a “floating” window manager. There are many others, especially on Linux. A particularly common alternative is a “tiling” window manager. In a tiling window manager, windows never overlap, and are instead arranged as tiles on your screen, sort of like panes in tmux. With a tiling window manager, the screen is always filled by whatever windows are open, arranged according to some _layout_. If you have just one window, it takes up the full screen. If you then open another, the original window shrinks to make room for it (often something like 2/3 and 1/3). If you open a third, the other windows will again shrink to accommodate the new window. Just like with tmux panes, you can navigate around these tiled windows with your keyboard, and you can resize them and move them around, all without touching the mouse. They are worth looking into!

## 10.8 VPNs

VPNs are all the rage these days, but it’s not clear that’s for [any good reason](https://gist.github.com/joepie91/5a9909939e6ce7d09e29). You should be aware of what a VPN does and does not get you. A VPN, in the best case, is _really_ just a way for you to change your internet service provider as far as the internet is concerned. All your traffic will look like it’s coming from the VPN provider instead of your “real” location, and the network you are connected to will only see encrypted traffic.

While that may seem attractive, keep in mind that when you use a VPN, all you are really doing is shifting your trust from you current ISP to the VPN hosting company. Whatever your ISP _could_ see, the VPN provider now sees _instead_. If you trust them _more_ than your ISP, that is a win, but otherwise, it is not clear that you have gained much. If you are sitting on some dodgy unencrypted public Wi-Fi at an airport, then maybe you don’t trust the connection much, but at home, the trade-off is not quite as clear.

You should also know that these days, much of your traffic, at least of a sensitive nature, is _already_ encrypted through HTTPS or TLS more generally. In that case, it usually matters little whether you are on a “bad” network or not – the network operator will only learn what servers you talk to, but not anything about the data that is exchanged.

Notice that I said “in the best case” above. It is not unheard of for VPN providers to accidentally misconfigure their software such that the encryption is either weak or entirely disabled. Some VPN providers are malicious (or at the very least opportunist), and will log all your traffic, and possibly sell information about it to third parties. Choosing a bad VPN provider is often worse than not using one in the first place.

In a pinch, MIT [runs a VPN](https://ist.mit.edu/vpn) for its students, so that may be worth taking a look at. Also, if you’re going to roll your own, give [WireGuard](https://www.wireguard.com/) a look.

## 10.9 Markdown

There is a high chance that you will write some text over the course of your career. And often, you will want to mark up that text in simple ways. You want some text to be bold or italic, or you want to add headers, links, and code fragments. Instead of pulling out a heavy tool like Word or LaTeX, you may want to consider using the lightweight markup language [Markdown](https://commonmark.org/help/).

You have probably seen Markdown already, or at least some variant of it. Subsets of it are used and supported almost everywhere, even if it’s not under the name Markdown. At its core, Markdown is an attempt to codify the way that people already often mark up text when they are writing plain text documents. Emphasis (_italics_) is added by surrounding a word with `*`. Strong emphasis (**bold**) is added using `**`. Lines starting with `#` are headings (and the number of `#`s is the subheading level). Any line starting with `-` is a bullet list item, and any line starting with a number + `.` is a numbered list item. Backtick is used to show words in `code font`, and a code block can be entered by indenting a line with four spaces or surrounding it with triple-backticks:

````
```
code goes here
```
````

To add a link, place the _text_ for the link in square brackets, and the URL immediately following that in parentheses: `[name](url)`. Markdown is easy to get started with, and you can use it nearly everywhere. In fact, the lecture notes for this lecture, and all the others, are written in Markdown, and you can see the raw Markdown [here](https://raw.githubusercontent.com/missing-semester/missing-semester/master/_2020/potpourri.md).

## 10.10 Hammerspoon (desktop automation on macOS)

[Hammerspoon](https://www.hammerspoon.org/) is a desktop automation framework for macOS. It lets you write Lua scripts that hook into operating system functionality, allowing you to interact with the keyboard/mouse, windows, displays, filesystem, and much more.

Some examples of things you can do with Hammerspoon:

-   Bind hotkeys to move windows to specific locations
-   Create a menu bar button that automatically lays out windows in a specific layout
-   Mute your speaker when you arrive in lab (by detecting the WiFi network)
-   Show you a warning if you’ve accidentally taken your friend’s power supply

At a high level, Hammerspoon lets you run arbitrary Lua code, bound to menu buttons, key presses, or events, and Hammerspoon provides an extensive library for interacting with the system, so there’s basically no limit to what you can do with it. Many people have made their Hammerspoon configurations public, so you can generally find what you need by searching the internet, but you can always write your own code from scratch.

### Resources

-   [Getting Started with Hammerspoon](https://www.hammerspoon.org/go/)
-   [Sample configurations](https://github.com/Hammerspoon/hammerspoon/wiki/Sample-Configurations)
-   [Anish’s Hammerspoon config](https://github.com/anishathalye/dotfiles-local/tree/mac/hammerspoon)

## 10.11 Booting + Live USBs

When your machine boots up, before the operating system is loaded, the [BIOS](https://en.wikipedia.org/wiki/BIOS)/[UEFI](https://en.wikipedia.org/wiki/Unified_Extensible_Firmware_Interface) initializes the system. During this process, you can press a specific key combination to configure this layer of software. For example, your computer may say something like “Press F9 to configure BIOS. Press F12 to enter boot menu.” during the boot process. You can configure all sorts of hardware-related settings in the BIOS menu. You can also enter the boot menu to boot from an alternate device instead of your hard drive.

[Live USBs](https://en.wikipedia.org/wiki/Live_USB) are USB flash drives containing an operating system. You can create one of these by downloading an operating system (e.g. a Linux distribution) and burning it to the flash drive. This process is a little bit more complicated than simply copying a `.iso` file to the disk. There are tools like [UNetbootin](https://unetbootin.github.io/) to help you create live USBs.

Live USBs are useful for all sorts of purposes. Among other things, if you break your existing operating system installation so that it no longer boots, you can use a live USB to recover data or fix the operating system.

## 10.12 Docker, Vagrant, VMs, Cloud, OpenStack

[Virtual machines](https://en.wikipedia.org/wiki/Virtual_machine) and similar tools like containers let you emulate a whole computer system, including the operating system. This can be useful for creating an isolated environment for testing, development, or exploration (e.g. running potentially malicious code).

[Vagrant](https://www.vagrantup.com/) is a tool that lets you describe machine configurations (operating system, services, packages, etc.) in code, and then instantiate VMs with a simple `vagrant up`. [Docker](https://www.docker.com/) is conceptually similar but it uses containers instead.

You can also rent virtual machines on the cloud, and it’s a nice way to get instant access to:

-   A cheap always-on machine that has a public IP address, used to host services
-   A machine with a lot of CPU, disk, RAM, and/or GPU
-   Many more machines than you physically have access to (billing is often by the second, so if you want a lot of computing for a short amount of time, it’s feasible to rent 1000 computers for a couple of minutes)

Popular services include [Amazon AWS](https://aws.amazon.com/), [Google Cloud](https://cloud.google.com/), [Microsoft Azure](https://azure.microsoft.com/), [DigitalOcean](https://www.digitalocean.com/).

If you’re a member of MIT CSAIL, you can get free VMs for research purposes through the [CSAIL OpenStack instance](https://tig.csail.mit.edu/shared-computing/open-stack/).

## 10.13 Notebook programming

[Notebook programming environments](https://en.wikipedia.org/wiki/Notebook_interface) can be really handy for doing certain types of interactive or exploratory development. Perhaps the most popular notebook programming environment today is [Jupyter](https://jupyter.org/), for Python (and several other languages). [Wolfram Mathematica](https://www.wolfram.com/mathematica/) is another notebook programming environment that’s great for doing math-oriented programming.

## 10.14 GitHub

[GitHub](https://github.com/) is one of the most popular platforms for open-source software development. Many of the tools we’ve talked about in this class, from [vim](https://github.com/vim/vim) to [Hammerspoon](https://github.com/Hammerspoon/hammerspoon), are hosted on GitHub. It’s easy to get started contributing to open-source to help improve the tools that you use every day.

There are two primary ways in which people contribute to projects on GitHub:

-   Creating an [issue](https://help.github.com/en/github/managing-your-work-on-github/creating-an-issue). This can be used to report bugs or request a new feature. Neither of these involves reading or writing code, so it can be pretty lightweight to do. High-quality bug reports can be extremely valuable to developers. Commenting on existing discussions can be helpful too.
-   Contribute code through a [pull request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/about-pull-requests). This is generally more involved than creating an issue. You can [fork](https://help.github.com/en/github/getting-started-with-github/fork-a-repo) a repository on GitHub, clone your fork, create a new branch, make some changes (e.g. fix a bug or implement a feature), push the branch, and then [create a pull request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request). After this, there will generally be some back-and-forth with the project maintainers, who will give you feedback on your patch. Finally, if all goes well, your patch will be merged into the upstream repository. Often times, larger projects will have a contributing guide, tag beginner-friendly issues, and some even have mentorship programs to help first-time contributors become familiar with the project.

# 11. Q&A

## Any recommendations on learning Operating Systems related topics like processes, virtual memory, interrupts, memory management, etc

First, it is unclear whether you actually need to be very familiar with all of these topics since they are very low level topics. They will matter as you start writing more low level code like implementing or modifying a kernel. Otherwise, most topics will not be relevant, with the exception of processes and signals that were briefly covered in other lectures.

Some good resources to learn about this topic:

-   [MIT’s 6.828 class](https://pdos.csail.mit.edu/6.828/) - Graduate level class on Operating System Engineering. Class materials are publicly available.
-   Modern Operating Systems (4th ed) - by Andrew S. Tanenbaum is a good overview of many of the mentioned concepts.
-   The Design and Implementation of the FreeBSD Operating System - A good resource about the FreeBSD OS (note that this is not Linux).
-   Other guides like [Writing an OS in Rust](https://os.phil-opp.com/) where people implement a kernel step by step in various languages, mostly for teaching purposes.

## What are some of the tools you’d prioritize learning first?

Some topics worth prioritizing:

-   Learning how to use your keyboard more and your mouse less. This can be through keyboard shortcuts, changing interfaces, &c.
-   Learning your editor well. As a programmer most of your time is spent editing files so it really pays off to learn this skill well.
-   Learning how to automate and/or simplify repetitive tasks in your workflow because the time savings will be enormous…
-   Learning about version control tools like Git and how to use it in conjunction with GitHub to collaborate in modern software projects.

## When do I use Python versus a Bash scripts versus some other language?

In general, bash scripts are useful for short and simple one-off scripts when you just want to run a specific series of commands. bash has a set of oddities that make it hard to work with for larger programs or scripts:

-   bash is easy to get right for a simple use case but it can be really hard to get right for all possible inputs. For example, spaces in script arguments have led to countless bugs in bash scripts.
-   bash is not amenable to code reuse so it can be hard to reuse components of previous programs you have written. More generally, there is no concept of software libraries in bash.
-   bash relies on many magic strings like `$?` or `$@` to refer to specific values, whereas other languages refer to them explicitly, like `exitCode` or `sys.args` respectively.

Therefore, for larger and/or more complex scripts we recommend using more mature scripting languages like Python or Ruby. You can find online countless libraries that people have already written to solve common problems in these languages. If you find a library that implements the specific functionality you care about in some language, usually the best thing to do is to just use that language.

## What is the difference between `source script.sh` and `./script.sh`

#keypoint source and ./

In both cases the `script.sh` will be read and executed in a bash session, the difference lies in which session is running the commands. For `source` the commands are executed in your current bash session and thus any changes made to the current environment, like changing directories or defining functions will persist in the current session once the `source` command finishes executing. When running the script standalone like `./script.sh`, your current bash session starts a new instance of bash that will run the commands in `script.sh`. Thus, if `script.sh` changes directories, the new bash instance will change directories but once it exits and returns control to the parent bash session, the parent session will remain in the same place. Similarly, if `script.sh` defines a function that you want to access in your terminal, you need to `source` it for it to be defined in your current bash session. Otherwise, if you run it, the new bash process will be the one to process the function definition instead of your current shell.

## What are the places where various packages and tools are stored and how does referencing them work? What even is `/bin` or `/lib`?

Regarding programs that you execute in your terminal, they are all found in the directories listed in your `PATH` environment variable and you can use the `which` command (or the `type` command) to check where your shell is finding a specific program. In general, there are some conventions about where specific types of files live. Here are some of the ones we talked about, check the [Filesystem, Hierarchy Standard](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard) for a more comprehensive list.

-   `/bin` - Essential command binaries
-   `/sbin` - Essential system binaries, usually to be run by root
-   `/dev` - Device files, special files that often are interfaces to hardware devices
-   `/etc` - Host-specific system-wide configuration files
-   `/home` - Home directories for users in the system
-   `/lib` - Common libraries for system programs
-   `/opt` - Optional application software
-   `/sys` - Contains information and configuration for the system (covered in the [first lecture](https://missing.csail.mit.edu/2020/course-shell/))
-   `/tmp` - Temporary files (also `/var/tmp`). Usually deleted between reboots.
-   `/usr/` - Read only user data
    -   `/usr/bin` - Non-essential command binaries
    -   `/usr/sbin` - Non-essential system binaries, usually to be run by root
    -   `/usr/local/bin` - Binaries for user compiled programs
-   `/var` - Variable files like logs or caches

## Should I `apt-get install` a python-whatever, or `pip install` whatever package?

There’s no universal answer to this question. It’s related to the more general question of whether you should use your system’s package manager or a language-specific package manager to install software. A few things to take into account:

-   Common packages will be available through both, but less popular ones or more recent ones might not be available in your system package manager. In this case, using the language-specific tool is the better choice.
-   Similarly, language-specific package managers usually have more up to date versions of packages than system package managers.
-   When using your system package manager, libraries will be installed system wide. This means that if you need different versions of a library for development purposes, the system package manager might not suffice. For this scenario, most programming languages provide some sort of isolated or virtual environment so you can install different versions of libraries without running into conflicts. For Python, there’s virtualenv, and for Ruby, there’s RVM.
-   Depending on the operating system and the hardware architecture, some of these packages might come with binaries or might need to be compiled. For instance, in ARM computers like the Raspberry Pi, using the system package manager can be better than the language specific one if the former comes in form of binaries and the latter needs to be compiled. This is highly dependent on your specific setup.

You should try to use one solution or the other and not both since that can lead to conflicts that are hard to debug. Our recommendation is to use the language-specific package manager whenever possible, and to use isolated environments (like Python’s virtualenv) to avoid polluting the global environment.

## What’s the easiest and best profiling tools to use to improve performance of my code?

The easiest tool that is quite useful for profiling purposes is [print timing](https://missing.csail.mit.edu/2020/debugging-profiling/#timing). You just manually compute the time taken between different parts of your code. By repeatedly doing this, you can effectively do a binary search over your code and find the segment of code that took the longest.

For more advanced tools, Valgrind’s [Callgrind](http://valgrind.org/docs/manual/cl-manual.html) lets you run your program and measure how long everything takes and all the call stacks, namely which function called which other function. It then produces an annotated version of your program’s source code with the time taken per line. However, it slows down your program by an order of magnitude and does not support threads. For other cases, the [`perf`](http://www.brendangregg.com/perf.html) tool and other language specific sampling profilers can output useful data pretty quickly. [Flamegraphs](http://www.brendangregg.com/flamegraphs.html) are a good visualization tool for the output of said sampling profilers. You should also try to use specific tools for the programming language or task you are working with. For example, for web development, the dev tools built into Chrome and Firefox have fantastic profilers.

Sometimes the slow part of your code will be because your system is waiting for an event like a disk read or a network packet. In those cases, it is worth checking that back-of-the-envelope calculations about the theoretical speed in terms of hardware capabilities do not deviate from the actual readings. There are also specialized tools to analyze the wait times in system calls. These include tools like [eBPF](http://www.brendangregg.com/blog/2019-01-01/learn-ebpf-tracing.html) that perform kernel tracing of user programs. In particular [`bpftrace`](https://github.com/iovisor/bpftrace) is worth checking out if you need to perform this sort of low level profiling.

## What browser plugins do you use?

Some of our favorites, mostly related to security and usability:

-   [uBlock Origin](https://github.com/gorhill/uBlock) - It is a [wide-spectrum](https://github.com/gorhill/uBlock/wiki/Blocking-mode) blocker that doesn’t just stop ads, but all sorts of third-party communication a page may try to do. This also covers inline scripts and other types of resource loading. If you’re willing to spend some time on configuration to make things work, go to [medium mode](https://github.com/gorhill/uBlock/wiki/Blocking-mode:-medium-mode) or even [hard mode](https://github.com/gorhill/uBlock/wiki/Blocking-mode:-hard-mode). Those will make some sites not work until you’ve fiddled with the settings enough, but will also significantly improve your online security. Otherwise, the [easy mode](https://github.com/gorhill/uBlock/wiki/Blocking-mode:-easy-mode) is already a good default that blocks most ads and tracking. You can also define your own rules about what website objects to block.
-   [Stylus](https://github.com/openstyles/stylus/) - a fork of Stylish (don’t use Stylish, it was shown to [steal users’ browsing history](https://www.theregister.co.uk/2018/07/05/browsers_pull_stylish_but_invasive_browser_extension/)), allows you to sideload custom CSS stylesheets to websites. With Stylus you can easily customize and modify the appearance of websites. This can be removing a sidebar, changing the background color or even the text size or font choice. This is fantastic for making websites that you visit frequently more readable. Moreover, Stylus can find styles written by other users and published in [userstyles.org](https://userstyles.org/). Most common websites have one or several dark theme stylesheets for instance.
-   Full Page Screen Capture - [Built into Firefox](https://screenshots.firefox.com/) and [Chrome extension](https://chrome.google.com/webstore/detail/full-page-screen-capture/fdpohaocaechififmbbbbbknoalclacl?hl=en). Lets you take a screenshot of a full website, often much better than printing for reference purposes.
-   [Multi Account Containers](https://addons.mozilla.org/en-US/firefox/addon/multi-account-containers/) - lets you separate cookies into “containers”, allowing you to browse the web with different identities and/or ensuring that websites are unable to share information between them.
-   Password Manager Integration - Most password managers have browser extensions that make inputting your credentials into websites not only more convenient but also more secure. Compared to simply copy-pasting your user and password, these tools will first check that the website domain matches the one listed for the entry, preventing phishing attacks that impersonate popular websites to steal credentials.
-   [Vimium](https://github.com/philc/vimium) - A browser extension that provides keyboard-based navigation and control of the web in the spirit of the Vim editor.

## What are other useful data wrangling tools?

Some of the data wrangling tools we did not have time to cover during the data wrangling lecture include `jq` or `pup` which are specialized parsers for JSON and HTML data respectively. The Perl programming language is another good tool for more advanced data wrangling pipelines. Another trick is the `column -t` command that can be used to convert whitespace text (not necessarily aligned) into properly column aligned text.

More generally a couple of more unconventional data wrangling tools are vim and Python. For some complex and multi-line transformations, vim macros can be a quite invaluable tool to use. You can just record a series of actions and repeat them as many times as you want, for instance in the editors [lecture notes](https://missing.csail.mit.edu/2020/editors/#macros) (and last year’s [video](https://missing.csail.mit.edu/2019/editors/)) there is an example of converting an XML-formatted file into JSON just using vim macros.

For tabular data, often presented in CSVs, the [pandas](https://pandas.pydata.org/) Python library is a great tool. Not only because it makes it quite easy to define complex operations like group by, join or filters; but also makes it quite easy to plot different properties of your data. It also supports exporting to many table formats including XLS, HTML or LaTeX. Alternatively the R programming language (an arguably [bad](http://arrgh.tim-smith.us/) programming language) has lots of functionality for computing statistics over data and can be quite useful as the last step of your pipeline. [ggplot2](https://ggplot2.tidyverse.org/) is a great plotting library in R.

## What is the difference between Docker and a Virtual Machine?

#keypoint 容器和虚拟机的区别

Docker is based on a more general concept called containers. The main difference between containers and virtual machines is that virtual machines will execute an entire OS stack, including the kernel, even if the kernel is the same as the host machine. Unlike VMs, containers avoid running another instance of the kernel and instead share the kernel with the host. In Linux, this is achieved through a mechanism called LXC, and it makes use of a series of isolation mechanisms to spin up a program that thinks it’s running on its own hardware but it’s actually sharing the hardware and kernel with the host. Thus, containers have a lower overhead than a full VM. On the flip side, containers have a weaker isolation and only work if the host runs the same kernel. For instance if you run Docker on macOS, Docker needs to spin up a Linux virtual machine to get an initial Linux kernel and thus the overhead is still significant. Lastly, Docker is a specific implementation of containers and it is tailored for software deployment. Because of this, it has some quirks: for example, Docker containers will not persist any form of storage between reboots by default.

## What are the advantages and disadvantages of each OS and how can we choose between them (e.g. choosing the best Linux distribution for our purposes)?

Regarding Linux distros, even though there are many, many distros, most of them will behave fairly identically for most use cases. Most of Linux and UNIX features and inner workings can be learned in any distro. A fundamental difference between distros is how they deal with package updates. Some distros, like Arch Linux, use a rolling update policy where things are bleeding-edge but things might break every so often. On the other hand, some distros like Debian, CentOS or Ubuntu LTS releases are much more conservative with releasing updates in their repositories so things are usually more stable at the expense of sacrificing newer features. Our recommendation for an easy and stable experience with both desktops and servers is to use Debian or Ubuntu.

Mac OS is a good middle point between Windows and Linux that has a nicely polished interface. However, Mac OS is based on BSD rather than Linux, so some parts of the system and commands are different. An alternative worth checking is FreeBSD. Even though some programs will not run on FreeBSD, the BSD ecosystem is much less fragmented and better documented than Linux. We discourage Windows for anything but for developing Windows applications or if there is some deal breaker feature that you need, like good driver support for gaming.

For dual boot systems, we think that the most working implementation is macOS’ bootcamp and that any other combination can be problematic on the long run, specially if you combine it with other features like disk encryption.

## Vim vs Emacs?

The three of us use vim as our primary editor but Emacs is also a good alternative and it’s worth trying both to see which works better for you. Emacs does not follow vim’s modal editing, but this can be enabled through Emacs plugins like [Evil](https://github.com/emacs-evil/evil) or [Doom Emacs](https://github.com/hlissner/doom-emacs). An advantage of using Emacs is that extensions can be implemented in Lisp, a better scripting language than vimscript, Vim’s default scripting language.

## Any tips or tricks for Machine Learning applications?

Some of the lessons and takeaways from this class can directly be applied to ML applications. As it is the case with many science disciplines, in ML you often perform a series of experiments and want to check what things worked and what didn’t. You can use shell tools to easily and quickly search through these experiments and aggregate the results in a sensible way. This could mean subselecting all experiments in a given time frame or that use a specific dataset. By using a simple JSON file to log all relevant parameters of the experiments, this can be incredibly simple with the tools we covered in this class. Lastly, if you do not work with some sort of cluster where you submit your GPU jobs, you should look into how to automate this process since it can be a quite time consuming task that also eats away your mental energy.

## Any more Vim tips?

A few more tips:

-   Plugins - Take your time and explore the plugin landscape. There are a lot of great plugins that address some of vim’s shortcomings or add new functionality that composes well with existing vim workflows. For this, good resources are [VimAwesome](https://vimawesome.com/) and other programmers’ dotfiles.
-   Marks - In vim, you can set a mark doing `m<X>` for some letter `X`. You can then go back to that mark doing `'<X>`. This lets you quickly navigate to specific locations within a file or even across files.
-   Navigation - `Ctrl+O` and `Ctrl+I` move you backward and forward respectively through your recently visited locations.
-   Undo Tree - Vim has a quite fancy mechanism for keeping track of changes. Unlike other editors, vim stores a tree of changes so even if you undo and then make a different change you can still go back to the original state by navigating the undo tree. Some plugins like [gundo.vim](https://github.com/sjl/gundo.vim) and [undotree](https://github.com/mbbill/undotree) expose this tree in a graphical way.
-   Undo with time - The `:earlier` and `:later` commands will let you navigate the files using time references instead of one change at a time.
-   [Persistent undo](https://vim.fandom.com/wiki/Using_undo_branches#Persistent_undo) is an amazing built-in feature of vim that is disabled by default. It persists undo history between vim invocations. By setting `undofile` and `undodir` in your `.vimrc`, vim will store a per-file history of changes.
-   Leader Key - The leader key is a special key that is often left to the user to be configured for custom commands. The pattern is usually to press and release this key (often the space key) and then some other key to execute a certain command. Often, plugins will use this key to add their own functionality, for instance the UndoTree plugin uses `<Leader> U` to open the undo tree.
-   Advanced Text Objects - Text objects like searches can also be composed with vim commands. E.g. `d/<pattern>` will delete to the next match of said pattern or `cgn` will change the next occurrence of the last searched string.

## What is 2FA and why should I use it?

Two Factor Authentication (2FA) adds an extra layer of protection to your accounts on top of passwords. In order to login, you not only have to know some password, but you also have to “prove” in some way you have access to some hardware device. In the most simple case, this can be achieved by receiving an SMS on your phone, although there are [known issues](https://www.kaspersky.com/blog/2fa-practical-guide/24219/) with SMS 2FA. A better alternative we endorse is to use a [U2F](https://en.wikipedia.org/wiki/Universal_2nd_Factor) solution like [YubiKey](https://www.yubico.com/).

## Any comments on differences between web browsers?

The current landscape of browsers as of 2020 is that most of them are like Chrome because they use the same engine (Blink). This means that Microsoft Edge which is also based on Blink, and Safari, which is based on WebKit, a similar engine to Blink, are just worse versions of Chrome. Chrome is a reasonably good browser both in terms of performance and usability. Should you want an alternative, Firefox is our recommendation. It is comparable to Chrome in pretty much every regard and it excels for privacy reasons. Another browser called [Flow](https://www.ekioh.com/flow-browser/) is not user ready yet, but it is implementing a new rendering engine that promises to be faster than the current ones.