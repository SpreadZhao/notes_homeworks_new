# 操作系统课程设计实验报告

姓名：赵传博

学号：20009200303

## 专题1：内核引导

### 题目要求

* 新内核引导成功后，执行命令：`uname -a`，提交截屏结果1
* 进入目录`/boot`，执行命令`ls -l`，提交截屏结果2

### 软硬件配置

* 软件
  * Windows11
  * VMware Workstation 16 pro
  * ubuntukylin-20.04-pro-sp1-amd64
  * linux-5.17.5
* 硬件
  * Intel Core i5-10210U

### 关键步骤

* 下载内核源码

* 进入源码文件夹下`sudo make menuconfig`

* 选择`General setup -> Local version - append to kernel release`，在里面添加好自己的学号和姓名后保存退出

* 退出后执行`sudo make`开始编译内核

* 编译完成后，执行`sudo make modules_install`开始安装内核模块

* 执行`sudo make install`安装内核

* 最后检查grub配置文件，位于`/boot/grub/grub.cfg`；并且可以选择添加启动菜单，位于`etc/default/grub`，其中的配置如下：

  ```grub
  GRUB_DEFAULT=0
  GRUB_TIMEOUT_STYLE=menu
  GRUB_TIMEOUT=30
  GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
  GRUB_CMDLINE_LINUX_DEFAULT="text"
  GRUB_CMDLINE_LINUX="locale=zh_CN"
  ```

  * menu表示以菜单形式展示
  * 30表示菜单冷却时间30秒

### 结果展示

使用`uname`后，打印出的信息

* `uname -s`：打印内核版本，结果为Linux
* `uname -n `：打印主机名，也就是通过网络通信时主机的名字，结果为spreadzhao-virtual-machine
* `uname -r`：打印内核版本信息，**我们的实验改变的就是这里的内容**，改变后结果为5.17.5-SpreadZhao-20009200303
* `uname -v`：打印操作系统的版本，和虚拟机的镜像有关
* `uname -m`：打印机器的硬件名称，结果为x86_64
* `uname -p`：打印处理器架构，结果为x86_64
* `uname -i`：打印硬件平台，结果为x86_64
* `uname -o`：打印操作系统名称，结果为GNU/Linux
* `uname -a`：即all，打印所有信息

### 遇到的问题

* 在编译内核，即`sudo make`时报错：

  > 没有规则可制作的目标"debian/canonical-certs.pem"，由"certs/x509_certificate_list"需求。停止。

  这是由于内核的证书问题导致，主要是版权问题，和实验无关，因此将.config中的如下位置置空即可

  ```makefile
  CONFIG_MODULE_SIG_KEY="certs/signing_key.pem"
  CONFIG_MODULE_SIG_KEY_TYPE_RSA=y
  # CONFIG_MODULE_SIG_KEY_TYPE_ECDSA is not set
  CONFIG_SYSTEM_TRUSTED_KEYRING=y
  CONFIG_SYSTEM_TRUSTED_KEYS="debian/canonical-certs.pem" //将此处置空
  CONFIG_SYSTEM_EXTRA_CERTIFICATE=y
  CONFIG_SYSTEM_EXTRA_CERTIFICATE_SIZE=4096
  CONFIG_SECONDARY_TRUSTED_KEYRING=y
  ```

## 专题2：系统调用添加

### 题目要求

为Linux内核增加一个系统调用，并编写用户进程的程序来测试。要求该系统调用能够完成以下功能:

1. 该系统调用有1个整型参数，接收输入自己的学号;
2. 若参数为奇数，则返回自己学号的最后5位·如你的学号为16130120101 ，则返回20101 
3. 若参数为偶数，则返回自己的学号的最后6位。如你的学号为16130120102 ，则返回120102

### 软硬件配置

* 软件
  * Windows11
  * VMware Workstation 16 pro
  * ubuntukylin-20.04-pro-sp1-amd64
  * linux-5.17.5
* 硬件
  * Intel Core i5-10210U

### 关键步骤

* 在`linux-5.17.5/arch/x86/entry/syscalls`目录下找到`syscall_64.tbl`文件，该文件为系统调用表，包含系统调用函数名和系统调用号，在common的最后一列可以看到最后一个号是450，因此添加以下内容：

  > `451	common	spread	sys_spread`
  >
  > 以上内容的解释：
  >
  > * 451：系统调用号
  > * `common`：`abi`类型
  > * spread：函数名
  > * sys_spread：系统调用名

* 在`linux-5.17.5/include/linux`目录下找到`syscalls.h`文件，该文件中包含了系统调用函数的声明，在最后`#endif`之前的最后一行添加以下内容：

  > `asmlinkage long sys_spread(int num)`
  >
  > 关于`asmlinkage`的解释：
  >
  > 函数定义前加宏`asmlinkage` ,表示这些函数通过堆栈而不是通过寄存器传递参数。`gcc`编译器在汇编过程中调用c语言函数时传递参数有两种方法：一种是通过堆栈，另一种是通过寄存器。缺省时采用寄存器，假如你要在你的汇编过程中调用c语言函数，并且想通过堆栈传递参数，你定义的c函数时要在函数前加上宏`asmlinkage`

* 在`linux-5.17.5/kernel`目录下找到`sys.c`文件，该文件包含了上面系统调用函数的实现，在最后`#endif`之前的最后一行添加以下内容：

  > ```c
  > SYSCALL_DEFINE1(spread, int, id){
  >  if(id % 2 == 0)
  >      return 200303;
  >  else
  >      return 303;
  >  //这里因为我的学号后5位是00303，所以就返回303了(其实换成char*也不是不行)
  > }
  > ```
  >
  > `DEFINE1`表示该系统调用接收一个参数，首先是函数名，然后是每个参数的类型和参数名，所有变量之间都要逗号
  >
  > 由此代码以及**下面我犯的错误**可以看出内核编程和应用程序编程的差别：
  >
  > * 使用`printf`这样的函数会报错，因为内核编程时不能访问C库，因为C库太大了，因此一个小小的子集内核空间都受不了，但是很多常用的C函数都被包含在内核文件夹下
  > * 内核编程的时候需要使用GNU C
  > * 由于直接访问的是内存，所以实现浮点数很困难，并且对内存的访问也是任意的，无法被保护，出错直接会导致系统出错
  > * 64位计算机内核空间的栈空间是16KB，所以能执行的代码行数有限
  > * 考虑可移植性(OS比赛实在是好！)

### 遇到的问题

* 在第一次试验完成后，自定义的系统调用并没有作用，并且测试返回值为-1，原因是内核编译时出现错误，加的后缀含有无效字符，将后缀删掉后再重新编译就成功了
* 系统调用实现文件`sys.c`中添加的函数`SYSCALL_DEFINE1`里一开始使用的是`sys_spread`，后来改为spread后成功
* 一开始在调用表中写的系统调用名是`__x64_sys_spread`，之后编译的时候报错，原因是编译的时候会自动添加`__x64_`前缀，所以不需要手动再添加

## 专题3：内核模块

### 题目要求

题目一：编写一个内核模块； 编译该模块； 加载、卸载该模块；

题目二：自己在用户态下编写一个进程，并编写一个内核模块，该内核模块可获取该进程PCB中的信息，并将该信息以人可读懂的字符串的形式保存在一个文件中。

提交内容：内核模块加载/卸载截图

### 软硬件配置

* 软件
  * Windows10
  * VMware Workstation 16 pro
  * ubuntukylin-20.04-pro-sp1-amd64
  * linux-5.11.0-25
* 硬件
  * AMD Ryzen 5 3600

### 关键步骤

* 创建一个`haha.c`，并在其中编写内核模块的文件：

  ```c
  #include <linux/module.h>
  #include <linux/kernel.h>
  #include <linux/init.h>
  #include <linux/unistd.h>
  #include <linux/time.h>
  
  //在4.14版本之后，是linux/uaccess.h不是asm/uaccess.h
  #include <linux/uaccess.h>
  #include <linux/sched.h>
  #include <linux/kallsyms.h>
  
  //自定义的系统调用号
  #define __NR_syscall 336
  
  //系统调用表的初始地址，是要随时更换的，原因可以看下面的问题
  #define SYS_CALL_TABLE_ADDRESS 0xffffffff91800300
  
  unsigned int clear_and_return_cr0(void);
  
  void setback_cr0(unsigned int val);
  
  //存储cr0的原始值
  int orig_cr0;
  
  //保存系统调用表的指针
  unsigned long* sys_call_table = 0;
  
  static int (*anything_saved)(void);
  
  //定义这个别名是为了传参用
  typedef asmlinkage long(*sys_call_ptr_t) (const struct pt_regs);
  
  //汇编语言因为使用gcc编译，因此要用AT&T语法
  
  //其实就是清楚写保护，方法是将cr0的第16位置零，不过，你总得存一下没改过的吧，
  //方便设置回来呀！
  unsigned int clear_and_return_cr0(void){
      unsigned int cr0 = 0;
      unsigned int ret;
  
      //将cr0的值挪到rax寄存器中，同时输出到外部变量cr0
      //为啥还得移到rax中？直接移到cr0里不行吗？
      asm volatile(
          "movq %%cr0, %%rax"
          :"=a" (cr0)
      );
      ret = cr0;
      /**
      	0xfffeffff翻译成二进制为：
      		1111 1111 1111 1110 1111 1111 1111 1111
      	这个0正好是第16位，而cr0全是0，也是4个字节
      	按位与之后，不管cr0之前是什么样子的，这样操作之后，
      	其他位都是原样，而第16位一定是0
      */
      cr0 &= 0xfffeffff;
      
      /**
          haha，这就解释上面的问题了
          我们是把外部的cr0(改过的)映射为寄存器rax，然后传入
          内部的cr0寄存器中，返回的ret是没改过的cr0!
      */
      asm volatile(
          "movq %%rax, %%cr0"
          :
          :"a"(cr0)
      );
      return ret;
  }
  
  //设置回来，加上保护
  void setback_cr0(unsigned int val){
      //这里也是涉及AT&T语法，将val映射成rax寄存器
      //还是不太懂？？？
      asm volatile(
          "movq %%rax, %%cr0"
          :
          :"a" (val)
      );
  }
  
  //真正的系统调用(好短啊。。。)
  static asmlinkage long sys_zhao(const struct pt_regs *regs){
      printk("haha, spreadzhao!\n");
      return 20009200303;
  }
  
  //内核模块的入口函数
  static int __init init_addsyscall(void){
      //提示一下，我要初始化了！
      printk("Initializing zhao...\n");
      
      //保存系统调用表的起始位置，用地址保存哦！
      sys_call_table = (unsigned long*)(SYS_CALL_TABLE_ADDRESS);
      
      //输出一下这个位置
      printk("sys_call_table: 0x%p\n", sys_call_table);
      
      /**
      	保存原始系统调用
      	(int(*)(void))是一个函数指针类型
      	(*)说明是个指针，int返回值，void参数
      	这里sys_call_table能当做数组用，是因为它是long*类型
      	anything_saved就是用来：如果当前的系统调用号正被一个函数
      	占着，那就先存起来，因为我要抢你地方了！
      */
      anything_saved = (int(*)(void))(sys_call_table[__NR_syscall]);
      
      //设置cr0的值可更改，我要破你的防！
      orig_cr0 = clear_and_return_cr0();
      
      //这是把函数指针赋值给系统调用表，你懂得！
      //为啥这里是取地址？
      sys_call_table[__NR_syscall] = (unsigned long)&sys_zhao;
      
      //把cr0改回来，我破完防再给你改回去
      setback_cr0(orig_cr0);
      
      return 0;
  }
  
  //退出模块
  static void __exit exit_addsyscall(void){
      //还是破防！
      orig_cr0 = clear_and_return_cr0();
      
      //把之前存好的原来的系统调用(其实可能啥也没有。。。)弄回去
      sys_call_table[__NR_syscall] = (unsigned long)anything_saved;
      
      //关闭保护
      setback_cr0(orig_cr0);
      
      //走咯~~~
      printk("Exiting zhao...\n");
  }
  
  //这两句很重要哦！初始化和退出模块，参数是函数的指针
  module_init(init_addsyscall);
  module_exit(exit_addsyscall);
  
  //一些没啥用的信息，就一个证书就得了。。
  MODULE_LICENSE("GPL");
  ```

* **先不要编译**，执行`sudo cat /proc/kallsyms | grep sys_call_table`命令，发现如下结果：

  ```c
  ffffffff91800300 R sys_call_table			//这个数值是会变的
  ffffffff918013e0 R ia32_sys_call_table
  ffffffff918021c0 R x32_sys_call_table
  ```

  那么我们要的系统调用表的起始位置就是`ffffffff91800300`，再回到`haha.c`中，改写`SYS_CALL_TABLE_ADDRESS`宏的值为这个数，别忘了加`0x`前缀
  
* 然后编写`Makefile`文件

  ```makefile
  obj-m:=haha.o
  PWD:= $(shell pwd)
  KERNELDIR:= /lib/modules/$(shell uname -r)/build
  EXTRA_CFLAGS = -O0
  
  all:
          make -C $(KERNELDIR) M=$(PWD) modules
  
  clean:
          make -C $(KERNELDIR) M=$(PWD) clean
  ```
  
  注意，`haha.c`生成`haha.o`，名字要对上
  
* 执行`sudo make`编译文件，完毕后会生成好多文件

* 我们要的就是`haha.ko`，执行`sudo insmod haha.ko`插入模块

* 检查一下，插入成功了没？使用`lsmod | grep haha `，显示如下内容

  > `haha                   16384  0`

* 然后就可以编写测试函数了，随便写一个文件

  ```c
  #include <stdio.h>
  #include <unistd.h>
  
  int main(){
          long num;
          syscall(336);
          return 0;
  }
  ```

  然后执行它，再执行`dmesg`，查看日志，发现成功输出

  ```c
  [ 5163.760686] Initializing zhao...
  [ 5163.760689] sys_call_table: 0x0000000005b3d777
  [ 5868.949862] haha, spreadzhao!
  ```
  
* 然后输入`modinfo haha.ko`看一下模块信息

  ```c
  filename:       /home/spreadzhao/files/moduletest/haha.ko
  license:        GPL
  srcversion:     741903B4A75FFCD0E6164D4
  depends:        
  retpoline:      Y
  name:           haha
  vermagic:       5.11.0-25-generic SMP mod_unload modversions 
  ```

* 截止目前，我们写的系统调用是不含参数的，那么怎么让它能传递参数呢？别急，我们还没使用`pt_regs`呢！更改`haha.c`的代码：

  ```c
  ...
  static asmlinkage long sys_zhao(const struct pt_regs *regs){
          printk("haha, spreadzhao!\n");
          printk("the param is %d\n", (int)regs->di);
          return 20009200303;
  }
  ...
  ```

* 然后先卸载我们当前的模块，执行`sudo rmmod haha.ko`，会提示`已杀死`，然后**重启电脑！**为什么看下面的问题

* 重启之后，**重新获取当前的`sys_call_table`的起始位置**，然后修改`haha.c`文件的`SYS_CALL_TABLE_ADDRESS`宏，重新编译模块，插入模块，**别忘了修改测试函数，在后面加一个参数！**

  ```c
  #include <stdio.h>
  #include <unistd.h>
  
  int main(){
          long num;
          syscall(336, 303);
          return 0;
  }
  ```

  然后最激动人心的时刻来了！重新执行我们的测试函数！输入`dmesg`，发现成功调用！

  ```c
  [  267.805738] Initializing zhao...
  [  267.805742] sys_call_table: 0x0000000058f436f4
  [  282.374545] haha, spreadzhao!
  [  282.374549] the param is -296547592		//这个是我当时测试函数忘了加参数了。。。
  [  337.931506] haha, spreadzhao!
  [  337.931509] the param is 303			//我们自己添加的参数哦！
  ```

* 接下来是题目二，我们需要再写一个进程用来被入侵的程序，创建`victim.c`，代码如下：

  ```c
  #include <stdio.h>
  #include <unistd.h>
  
  int main(){
      printf("the target pid is: %d\n", getpid());
      getchar();
      return 0;
  }
  ```

  该进程只做了两件事

  * 暴露自己的`pid`给外部
  * 使用`getchar()`阻塞自己，等待被入侵

  所以才叫做“受害者”

* 有被入侵的程序，那肯定有入侵者，那入侵者我们不如就还是使用`hahatest.c`吧！

  ```c
  #include <stdio.h>
  #include <unistd.h>
  
  int main(){
      unsigned long tarPid;
      printf("Enter the pid of the process you want to access: ");
      scanf("%ld", &tarPid);
      long rs = syscall(336, tarPid);
      printf("result: %ld\n", rs);
      return 0;
  }
  ```

  该程序接收一个`pid`，通过调用我们自己模块中的系统调用来实现入侵，那么这个`pid`是什么呢？很显然就是受害者暴露给外部的，也就是受害者本身进程的`pid`

* 既然如此，我们肯定要修改`haha.c`中的源码了！只需要修改`sys_zhao`函数的部分：

  ```c
  static asmlinkage long sys_zhao(const struct pt_regs *regs){
  
          unsigned long tar_pid = (unsigned long)regs->di;
  
          //目标进程的pcb
          struct task_struct *tar_task;
  
          tar_task = pid_task(find_pid_ns(tar_pid, &init_pid_ns), PIDTYPE_PID);
  
          printk("The pcb of the target process:\n");
          printk("State: %ld", tar_task->state);
          printk("Current CPU: %d", tar_task->cpu);
          printk("Pid: %d", (unsigned int)tar_task->pid);
  
          return 20009200303;
  
  }
  ```

  我们通过一个`pid_task`函数来找到我们需要的目标进程的`pcb`，也就是一个`task_struct`结构，其中定义的就是`pcb`中保存的信息，更详细的描述在下面的问题中。然后，拿到了这个结构体，就很自然的可以输出其中包含的信息了

* 现在开始模拟入侵。首先，**重启电脑**，因为我们要彻底移除当前插入到内核中的`haha.ko`模块

* 重启之后，重新执行`sudo cat /proc/kallsyms | grep sys_call_table`来获取系统调用表的位置，并改动`haha.c`中的`SYS_CALL_TALBE_ADDRESS`宏

* 执行`sudo make`编译内核，成功后执行`sudo insmod haha.ko`插入内核

* 现在编译受害者和入侵者，分别执行`gcc -o victim victim.c`和`gcc -o hahatest hahatest.c`

* 之后先执行`./victim`，会看到如下信息：

  ```c
  the target pid is: 8935
  ```

  这就是我们要入侵的进程的`pid`

* 然后执行`./hahatest`，输入`8935`，程序结束，执行`dmesg`，查看到输出信息：

  ```c
  [   85.361943] Initializing zhao...
  [   85.361946] sys_call_table: 0x000000009fd3a51a
  [  117.980274] The pcb of the target process:
  [  117.980278] State: 1
  [  117.980279] Current CPU: 0
  [  117.980279] Pid: 8935
  ```

  然后，我们也能成功查看到系统调用的返回值：

  ```c
  Enter the pid of the process you want to access: 8935
  result: 20009200303
  ```
  
* 经过老师的指导，现在通过修改系统调用表来在模块中添加系统调用的方式是不提倡的。因此更改`haha.c`代码如下：

  ```c
  #include <linux/module.h>
  #include <linux/kernel.h>
  #include <linux/init.h>
  #include <linux/unistd.h>
  #include <linux/time.h>
  
  #include <linux/uaccess.h>
  #include <linux/sched.h>
  #include <linux/kallsyms.h>
  
  static int __init init_haha(void){
  	printk("haha_init...\n");
  	printk("Now printing some process's info...\n");
  	struct task_struct *p;
      //拿到process表的初始地址
  	p = &init_task;
  	int KernelThreadCount = 0, UserThreadCount = 0;
      //对每个process遍历
  	for_each_process(p){
          //比较名字可以使用strcmp，引入string.h
  		//if(p->comm != "victim\0") continue;
  		if(p->mm == NULL){
  			printk("\nKernel Thread info\n");
  			printk("comm = %s, pid = %d, state = %ld\n", p->comm, p->pid, p->state);
  			++KernelThreadCount;
  		}else{
  			printk("\nUser Thread info\n");
  			printk("comm = %s, pid = %d, state = %ld\n", p->comm, p->pid, p->state);
  			++UserThreadCount;
  		}
  	}
  	printk("\nResult: %d kernel; %d user.\n", KernelThreadCount, UserThreadCount);
  	return 0;
  }
  
  static void __exit exit_haha(void){
  	printk("haha_exit...\n");
  }
  
  module_init(init_haha);
  module_exit(exit_haha);
  
  MODULE_LICENSE("GPL");
  MODULE_AUTHOR("SpreadZhao");
  MODULE_DESCRIPTION("haha");
  ```

  然后再编译后执行，插入模块，会看到这样的结果

  ```c
  //victim:
  The target pid is: 3457
  
  //dmesg
  ...
                 User Thread info
  [ 5409.531868] comm = victim, pid = 3457, state = 1		//我们自己写的victim进程
  [ 5409.531868] 
                 User Thread info
  [ 5409.531869] comm = systemd-udevd, pid = 3905, state = 1
  [ 5409.531869] 
                 User Thread info
  [ 5409.531870] comm = sudo, pid = 3906, state = 1
  ...
  ```

  解释：

  * `task_struct`中的`comm`字段

    ```c
    /*
    	 * 进程名称
    	 * 可执行文件名，不包括路径。
    	 *
    	 * - 一般情况下在 setup_new_exec() 函数进行初始化
    	 * - 调用 [gs]et_task_comm() 函数获取
    	 * - lock it with task_lock()
    	 */
    	char				comm[TASK_COMM_LEN];
    ```

  * `task_struct`中的`mm`字段

    * `mm`为`mm_struct`类型的指针，指向`mm_struct`结构，对于普通的用户进程来说mm字段指向他的虚拟地址空间的用户空间部分，对于内核线程来说这部分为`NULL`。

### 遇到的问题

* 在编写内核模块的入口函数的时候，本来使用的是`kallsyms_lookup_name("sys_call_table")`函数来寻找系统调用表的位置，该函数的declare位于`/usr/include/linux/kallsyms.h`文件。但是，我并没有在自己的虚拟机里找到这个文件，并且在`make`的时候报错：`ERROR: modpost: “kallsyms_lookup_name” undefined`。最终找到了原因：Linux内核自从5.7版本以后，为了安全起见取消了该函数，因此使用以上的方法。

* 在编写完成后，也成功输出了添加的系统调用，但是我又执行了一次`sudo cat /proc/kallsyms | grep sys_call_table`，发现显示如下内容

  ```c
  ffffffff91800300 R sys_call_table
  ffffffff918013e0 R ia32_sys_call_table
  ffffffff918021c0 R x32_sys_call_table
  ffffffffc0aac408 b sys_call_table	[haha]
  ```

  多出来了一项，这个程序的实现不是靠修改系统调用表的空闲位置，让它指向我们自己定义的函数吗？为什么这里会多出来一项，而且这个R是read-only，*这个b又是什么意思？那个`ia32`和`x32`又是什么意思？*
  
* 在我上面那个系统调用函数实现的代码中：

  ```c
  static asmlinkage long sys_zhao(const struct pt_regs *regs){
          printk("haha, spreadzhao!\n");
          return 20009200303;
  }
  ```

  为什么参数是一个寄存器而不是实际应该传入的参数呢？我们看看Stack Overflow上的一篇提问：

  > I wrote an example of system call hooking from our Linux Kernel module.
  >
  > Updated open system call in system call table to use my entry point instead of the default.
  >
  > ```c
  > ...
  > 
  > static asmlinkage long my_open(const char __user *filename, int flags, umode_t mode)
  > {
  >     char user_msg[256];
  >     pr_info("%s\n",__func__);
  >     memset(user_msg, 0, sizeof(user_msg));
  >     long copied = strncpy_from_user(user_msg, filename, sizeof(user_msg));
  >     pr_info("copied:%ld\n", copied);
  >     pr_info("%s\n",user_msg);
  > 
  >     return old_open(filename, flags, mode);
  > }
  >     
  > ...
  > ```
  >
  > File gets created in my folder, but `strncpy_user` fails with bad address
  >
  > ```c
  > [  927.415905] my_open
  > [  927.415906] copied:-14
  > ```
  >
  > What is the mistake in the above code?

  这位仁兄写了一个自己的open，并加入到内核当中。但是，**他在实现的时候传递的是真实的参数，即文件名，打开标记，打开模式**。然后得到了报错，这是为什么呢？下面的大神是这么回答的：

  总的来说，4.17版本以后使用wrapper的方式来调用系统调用的实际函数，这样我们就不能从外部直接向函数传递参数。因此，唯一的办法是通过传入一个`pt_regs`**寄存器集合**。而这个寄存器有以下的使用方法：

  ```c
  asmlinkage long sys_recv(struct pt_regs *regs)
  {
      return SyS_recv(regs->di, regs->si, regs->dx, regs->r10);
  }
  ```

  也就是说，`di, si, dx, r10`这4个寄存器对应了传入的第1~4个参数

  回头看一下我们定义的别名：

  ```c
  typedef asmlinkage long(*sys_call_ptr_t) (const struct pt_regs);
  ```

  *这个`asmlinkage long(*sys_call_ptr_t)`是什么类型？转换成的`const struct pt_regs`又为什么能够加`const`关键字？*

  看到这里，回头看一下`init_addsyscall`函数源码的注释，就明白了。这里补充说明一下：

  * 关于`__init`

    > 在内核代码`include/linux/init.h`中有这样的定义
    >
    > ```c
    > #define __init  __section(.init.text) __cold notrace
    > #define __initdata __section(.init.data)
    > #define __initconst __section(.init.rodata)
    > 
    > #define __exitdata __section(.exit.data)
    > #define __exit_call __used __section(.exitcall.exit)
    > 
    >  
    > 
    > #ifdef MODULE
    > #define __exitused
    > #else
    > #define __exitused  __used
    > #endif
    > 
    > #define __exit          __section(.exit.text) __exitused __cold
    > ```
    >
    > 从中我们可以得出`__init`是告知编译器，**将变量或者函数放在一个特殊的区域**，这个区域定义在`vmlinux.lds`中。`__init`将函数放在代码段的一个子段 `.init.text`（初始化代码段）中，`__initdata`将数据放在数据段的子段`.init.data`（初始化数据段）中。
    > 标记`_init`的函数,表明该函数在使用一次后就会被丢掉，讲占用的内存释放
    >
    > 同理也就可以知道_exit 标记的函数只有对模块才起作用，是指明函数是放在代码段的`.exit.text`中，特点是只有在模块被卸载的时候该函数才会被调用

  * 关于`cr0`

    > `cr0`控制寄存器的第 16 位是写保护位，若设置为零，则允许超级权限往内核中写入数据。这样我们可以在修改`sys_call_table`数组的值前，将`cr0`寄存器的第 16 位清零，使其可以修改`sys_call_table`数组的内容 

* 卸载模块时使用`rmmod haha.ko`后提示`已杀死`，但是之后再插入的时候进程挂起，按了`ctrl + C`撤销后，再使用`lsmod | grep haha`，提示如下信息

  ```c
  haha                   16384  -1
  ```

  *这个-1是什么意思呢？*

  产生该问题的原因是：

  * `insmod`是临时加入系统的，重启后会被消除
  * `rmmod`是临时卸载的，重启后驱动还在

  > Linux系统开机后，首先加载`initramfs`文件中包含的驱动程序，如果相应的设备对应的驱动不在`initramfs`文件包含范围内，那么会去硬盘中存储的驱动库中去寻找匹配的驱动进行加载；硬盘中驱动库的位置即为：`/lib/modules/$(uname -r)/；`所以相应的驱动只要在硬盘的驱动库或者`initramfs`中至少存在一个就可以正常加载，一旦在`initramfs`中加载成功，无论硬盘中的驱动库中存在的驱动版本是否相同都不会重新去加载。`Initramfs`中包含的驱动`ko`文件在目录`lib/modules/`下，具体包含的`ko`可依次查看。

  **所以，最直接的办法是重启电脑(haha)**，但是重启之后想要改模块的话需要把`SYS_CALL_TABLE_ADDRESS`宏改一下，改的方法已经提过多次了

  然后，一个更牛b的命令来了，它就是`modprobe`！

  > `modprobe`不仅仅加载驱动，而且还会加载其依赖，当确定驱动模块不需要依赖的时候就用`insmod xxx `.不过这两种方法都只是临时的加载驱动，重启系统后就没有了，只作为临时调试用。

  我们来熟悉一下`modprobe`的使用：

  * 将`haha.ko`文件拷贝到`/lib/modules/5.11.0-25-generic/`目录下(最后那个取决于`uname -r`)是啥

  * **然后执行`sudo depmod`来更新模块信息，这一步很关键！是为了修改`/lib/modules/$(uname -r)/`目录下的`modules.dep`文件，执行完之后可以在其中搜索一下，是能找到`haha.ko`的！**

  * 然后执行`modprobe haha.ko`来安装模块

    > *为什么这一步还是会出现`modprobe: FATAL: Module haha.ko not found in directory /lib/modules/5.11.0-25-generic`?*
  
* 关于`cr0`的16位问题：我还搜到了有人将`cr0`的第17位置零，也能做到使内核空间可写，*那16位和17位到底是起什么作用呢？是相同？还是不同？或者是有区别？*

* 第一次执行的时候，`haha.c`中的宏是如下值：

  ```c
  #define SYS_CALL_TABLE_ADDRESS 0xffffffff91800300
  ```

  然后在`init_addsyscall`函数中，是如下的使用方式：

  ```c
  sys_call_table = (unsigned long*)(SYS_CALL_TABLE_ADDRESS);
  ```

  最终输出的结果如下：

  ```c
  [ 5163.760689] sys_call_table: 0x0000000005b3d777
  ```

  *这个过程之间发生了什么变化？为啥数字不一样了？*
  
* 第二题所涉及到的`task_struct`是定义在`/usr/include/sched.h`中，其中包含了`pcb`中的重要信息。部分代码如下：

  ```c
  struct task_struct {
  #ifdef CONFIG_THREAD_INFO_IN_TASK
  	/*
  	 * For reasons of header soup (see current_thread_info()), this
  	 * must be the first element of task_struct.
  	 */
  	struct thread_info		thread_info;
  #endif
  	/* -1 unrunnable, 0 runnable, >0 stopped: */
  	volatile long			state;
  
  	/*
  	 * This begins the randomizable portion of task_struct. Only
  	 * scheduling-critical items should be added above here.
  	 */
  	randomized_struct_fields_start
      /*
      	stack:
      	进程内核栈，进程通过alloc_thread_info函数分配它的内核栈，通过free_thread_info函数释放所分配的		    内核栈
      */  
  	void				*stack;
      
      /*
          usage:
          进程描述符使用计数，被置为2时，表示进程描述符正在被使用而且其相应的进程处于活动状态
      */
  	refcount_t			usage;
      
      /*
          flags
          flags是进程当前的状态标志(注意和运行状态区分)
              1) #define PF_ALIGNWARN    0x00000001: 显示内存地址未对齐警告
              2) #define PF_PTRACED    0x00000010: 标识是否是否调用了ptrace
              3) #define PF_TRACESYS    0x00000020: 跟踪系统调用
              4) #define PF_FORKNOEXEC 0x00000040: 已经完成fork，但还没有调用exec
              5) #define PF_SUPERPRIV    0x00000100: 使用超级用户(root)权限
              6) #define PF_DUMPCORE    0x00000200: dumped core  
              7) #define PF_SIGNALED    0x00000400: 此进程由于其他进程发送相关信号而被杀死 
              8) #define PF_STARTING    0x00000002: 当前进程正在被创建
              9) #define PF_EXITING    0x00000004: 当前进程正在关闭
              10) #define PF_USEDFPU    0x00100000: Process used the FPU this quantum(SMP only)  
              #define PF_DTRACE    0x00200000: delayed trace (used on m68k)  
      */
  	/* Per task flags (PF_*), defined further below: */
  	unsigned int			flags;
  	unsigned int			ptrace;
  
  ...
  };
  ```

* 在输出`pcb`信息时，遇到了信息显示不全的问题。第一次执行的时候结果如下：

  ```c
  [   85.361943] Initializing zhao...
  [   85.361946] sys_call_table: 0x000000009fd3a51a
  [  117.980274] The pcb of the target process:
  [  117.980278] State: 1
  [  117.980279] Current CPU: 0
  ```

  第二次执行的时候，结果如下：

  ```c
  [   85.361943] Initializing zhao...
  [   85.361946] sys_call_table: 0x000000009fd3a51a
  [  117.980274] The pcb of the target process:
  [  117.980278] State: 1
  [  117.980279] Current CPU: 0
  [  117.980279] Pid: 8935		//上次执行的pid，在这次才显示出来
  [  416.143435] The pcb of the target process:
  [  416.143440] State: 1
  [  416.143440] Current CPU: 0
  ```

  *每次执行完之后，最后一行的`pid`都不会显示，在下次执行的时候才会显示出来。并且之前的代码中是没有`pid`的，这时候就轮到`Current CPU`出现了同样的状况，即本次不显示，下次才显示。这是为什么？*

  > **根据老师的解答，是因为：`printk`函数的默认模式，是等缓冲区满了之后再刷到屏幕上。因此缓冲区没满的时候就有可能不给你打。解决办法是`printk`可以添加一些优先级，让他立刻给你打到屏幕上**
  
* 使用`rmmod`删除模块时，并没有打印退出模块函数中的信息，而是有如下输出

  ```c
  [ 2573.464184] haha_init...			//之前初始化模块的输出，以下是退出之后的dmesg
  [ 2611.786198] BUG: unable to handle page fault for address: ffffffffc092101c
  [ 2611.786205] #PF: supervisor instruction fetch in kernel mode
  [ 2611.786206] #PF: error_code(0x0010) - not-present page
  [ 2611.786207] PGD e015067 P4D e015067 PUD e017067 PMD 10515d067 PTE 0
  [ 2611.786237] Oops: 0010 [#1] SMP NOPTI
  [ 2611.786255] CPU: 15 PID: 283706 Comm: rmmod Tainted: G           OE     5.11.0-25-generic #27~20.04.1-Ubuntu
  [ 2611.786259] Hardware name: VMware, Inc. VMware Virtual Platform/440BX Desktop Reference Platform, BIOS 6.00 11/12/2020
  [ 2611.786261] RIP: 0010:0xffffffffc092101c
  [ 2611.786268] Code: Unable to access opcode bytes at RIP 0xffffffffc0920ff2.
  [ 2611.786269] RSP: 0018:ffffad9e90d0fed0 EFLAGS: 00010282
  [ 2611.786273] RAX: ffffffffc092101c RBX: 0000000000000000 RCX: 0000000000000000
  [ 2611.786274] RDX: ffff9e821f846200 RSI: ffffad9e90d0fed8 RDI: ffffffff831a0240
  [ 2611.786275] RBP: ffffad9e90d0ff30 R08: 0000000000000061 R09: fefefefefefefeff
  [ 2611.786276] R10: 0000000000000000 R11: 0000000000000000 R12: ffffffffc091e000
  [ 2611.786277] R13: 0000000000000000 R14: 0000000000000000 R15: 0000000000000000
  [ 2611.786279] FS:  00007f2a1b17e540(0000) GS:ffff9e82fa1c0000(0000) knlGS:0000000000000000
  [ 2611.786280] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
  [ 2611.786281] CR2: ffffffffc0920ff2 CR3: 0000000086bac001 CR4: 0000000000770ee0
  [ 2611.786309] PKRU: 55555554
  [ 2611.786311] Call Trace:
  [ 2611.786314]  ? __x64_sys_delete_module+0x14a/0x260
  [ 2611.786338]  ? exit_to_user_mode_prepare+0x3d/0x1a0
  [ 2611.786343]  do_syscall_64+0x38/0x90
  [ 2611.786367]  entry_SYSCALL_64_after_hwframe+0x44/0xa9
  [ 2611.786385] RIP: 0033:0x7f2a1b2c7a6b
  [ 2611.786387] Code: 73 01 c3 48 8b 0d 25 c4 0c 00 f7 d8 64 89 01 48 83 c8 ff c3 66 2e 0f 1f 84 00 00 00 00 00 90 f3 0f 1e fa b8 b0 00 00 00 0f 05 <48> 3d 01 f0 ff ff 73 01 c3 48 8b 0d f5 c3 0c 00 f7 d8 64 89 01 48
  [ 2611.786389] RSP: 002b:00007fff082eaaf8 EFLAGS: 00000206 ORIG_RAX: 00000000000000b0
  [ 2611.786391] RAX: ffffffffffffffda RBX: 000055ef087747a0 RCX: 00007f2a1b2c7a6b
  [ 2611.786392] RDX: 000000000000000a RSI: 0000000000000800 RDI: 000055ef08774808
  [ 2611.786393] RBP: 00007fff082eab58 R08: 0000000000000000 R09: 0000000000000000
  [ 2611.786394] R10: 00007f2a1b343ac0 R11: 0000000000000206 R12: 00007fff082ead30
  [ 2611.786395] R13: 00007fff082eb89a R14: 000055ef087742a0 R15: 000055ef087747a0
  [ 2611.786400] Modules linked in: haha(OE-) kmre_virtwifi(OE) cfg80211 nls_utf8 isofs bnep xt_u32 xt_tcpudp xt_TCPMSS xt_policy xt_owner xt_NFLOG xt_mark xt_IDLETIMER xt_connmark xt_CHECKSUM tcp_diag nfnetlink_log ipt_REJECT nf_reject_ipv4 iptable_raw iptable_mangle ip6t_REJECT nf_reject_ipv6 ip6table_raw ip6table_mangle ip6table_filter ip6_tables inet_diag bluetooth ecdh_generic ecc xt_conntrack xt_MASQUERADE nf_conntrack_netlink nfnetlink xfrm_user xfrm_algo xt_addrtype iptable_filter iptable_nat nf_nat nf_conntrack nf_defrag_ipv6 nf_defrag_ipv4 libcrc32c bpfilter br_netfilter bridge stp llc aufs overlay kmre_ashmem(OE) kmre_binder(OE) vsock_loopback vmw_vsock_virtio_transport_common vmw_vsock_vmci_transport vsock binfmt_misc nls_iso8859_1 snd_ens1371 snd_ac97_codec gameport crct10dif_pclmul ac97_bus ghash_clmulni_intel snd_pcm aesni_intel vmw_balloon snd_seq_midi crypto_simd snd_seq_midi_event cryptd snd_rawmidi glue_helper snd_seq input_leds joydev snd_seq_device serio_raw snd_timer
  [ 2611.786462]  snd soundcore vmw_vmci mac_hid sch_fq_codel vmwgfx ttm drm_kms_helper cec rc_core fb_sys_fops syscopyarea sysfillrect sysimgblt msr parport_pc ppdev lp drm parport ip_tables x_tables autofs4 hid_generic usbhid hid mptspi mptscsih crc32_pclmul psmouse ahci mptbase e1000 libahci scsi_transport_spi i2c_piix4 pata_acpi
  [ 2611.786503] CR2: ffffffffc092101c
  [ 2611.786509] ---[ end trace 1f0b51cbcd65bac1 ]---
  [ 2611.786511] RIP: 0010:0xffffffffc092101c
  [ 2611.786513] Code: Unable to access opcode bytes at RIP 0xffffffffc0920ff2.
  [ 2611.786514] RSP: 0018:ffffad9e90d0fed0 EFLAGS: 00010282
  [ 2611.786516] RAX: ffffffffc092101c RBX: 0000000000000000 RCX: 0000000000000000
  [ 2611.786517] RDX: ffff9e821f846200 RSI: ffffad9e90d0fed8 RDI: ffffffff831a0240
  [ 2611.786518] RBP: ffffad9e90d0ff30 R08: 0000000000000061 R09: fefefefefefefeff
  [ 2611.786519] R10: 0000000000000000 R11: 0000000000000000 R12: ffffffffc091e000
  [ 2611.786520] R13: 0000000000000000 R14: 0000000000000000 R15: 0000000000000000
  [ 2611.786521] FS:  00007f2a1b17e540(0000) GS:ffff9e82fa1c0000(0000) knlGS:0000000000000000
  [ 2611.786522] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
  [ 2611.786523] CR2: ffffffffc0920ff2 CR3: 0000000086bac001 CR4: 0000000000770ee0
  [ 2611.786545] PKRU: 55555554
  ```

  以下是`haha.c`改过之后的代码

  ```c
  static int __init init_haha(void){
          printk("haha_init...\n");
          return 0;
  }
  
  static void __init exit_haha(void){
          printk("haha_exit...\n");
  }
  
  module_init(init_haha);
  module_exit(exit_haha);
  
  MODULE_LICENSE("GPL");
  MODULE_AUTHOR("SpreadZhao");
  MODULE_DESCRIPTION("haha");
  ```
  
  > **原因很简单，下面退出模块的函数应该用`__exit`啊，而不是`__init`，当然会出问题**


## 专题4：驱动程序

### 题目要求

完善例子中的字符设备程序，使之满足以下功能：

1. 安装设备后从设备中读出字符串为你的学号；ok

2. 设备支持每次写入字符不超过1024个，超过部分被丢弃；ok

3. 用户可以读出最近写入到设备中的字符；ok

4. 设备关闭前不能被多次打开；ok

5. 设备支持系统调用`ioctl(int d, int req,…),req = 0x909090`, 清除设备中写入的字符串;ok

自己编写测试程序，验证以上功能

提交内容： 测试过程截图

### 软硬件配置

* 软件
  * Windows11
  * VMware Workstation 16 pro
  * ubuntukylin-20.04-pro-sp1-amd64
  * linux-5.11.0-25
* 硬件
  * 12th Gen Intel(R) Core(TM) i7-12700H

### 关键步骤

inuse的设计问题？

try_module_get和module_put的小缺陷

假定我们的设备名字就叫做`haha`，那我们就要编写`haha`的驱动

* 创建`hahadev.c`，并编写如下代码：

  ```c
  #include <linux/module.h>
  #include <linux/kernel.h>
  #include <linux/fs.h>
  #include <linux/uaccess.h>
  
  //0x909090就是用来发出清除缓冲区的指令
  #define RW_CLEAR 0x909090
  #define DEVICE_NAME "haha"
  
  #define RWBUF_MAX_SIZE 1024
  
  //既然缓冲区初始值为学号，那长度肯定是学号+结束位=12
  static int buflen = 12;
  
  /**
  	驱动所使用的缓冲区，读写操作就要使用它
  	初始值为学号，是为了加载模块的时候一打印就能打出来学号
  */
  static char hahabuf[RWBUF_MAX_SIZE] = "20009200303";
  
  
  //就像Strict Alternation那样的TURN锁，用于互斥访问Critical Region
  static int inuse = 0;
  
  
  int haha_open(struct inode *inode, struct file *file){
      //没人用的话，我就用
  	if(inuse == 0){
  		inuse = 1;
          //老版本使用的是MOD_INC_USE_COUNT，这里的更高级一点
          //当模块被驱动程序使用时，该模块不能够卸载
  		try_module_get(THIS_MODULE);
  		return 0;
  	}else{
  		return -1;
  	}
  }
  
  
  int haha_release(struct inode *inode, struct file *file){
  	inuse = 0;
      //对应MOD_DEC_USE_COUNT
  	module_put(THIS_MODULE);
  	return 0;
  }
  
  //从驱动程序里读
  ssize_t haha_read(struct file *file, char *buf, size_t count, loff_t *f_pos){
  	if(buflen > 0 && buflen <= RWBUF_MAX_SIZE){
          /**
          	把内容从驱动程序拷贝给用户
          	@param buf: 用户态的buffer用来接收数据
          	@param hahabuf: 当前设备驱动程序内置的buffer，用来提交数据
          	@param count: 拷贝多长？
          */
  		copy_to_user(buf, hahabuf, count);
  		printk("[hahabuf] Haha is reading! The length of the buffer used to read is: %d\n", buflen);
  		return count;
  	}else{
  		printk("[hahabuf] Haha failed while reading! The length of the buffer used to read is: %d\n", buflen);
  		return -1;
  	}
  }
  //向驱动程序里写
  ssize_t haha_write(struct file *file, const char *buf, size_t count, loff_t *f_pos){
  	if(count > 0){
          /**
          	这两个函数的方向都是param2 -> param1
          	所以hahabuf和buf要反过来
          	最大只能拷贝RWBUF_MAX_SIZE那么大，所以要加上一个限制
          */
  		copy_from_user(hahabuf, buf, count > RWBUF_MAX_SIZE ? RWBUF_MAX_SIZE : count);
          //写的时候buflen就是要拷贝的长度
  		buflen = count > RWBUF_MAX_SIZE ? RWBUF_MAX_SIZE : count;
  		printk("[hahabuf] Haha write successfully! The length of the buffer used to write is: %d\n", buflen);
  		return count;
  	}else{
  		printk("[hahabuf] Haha failed to write. The length of the string to be written: %lu\n", count);
  		return -1;
  	}
  }
  
  long haha_ioctl(struct file *file, unsigned int cmd, unsigned long arg){
  	printk("[hahabuf] [RW_CLEAR:%x], [cmd:%x]\n", RW_CLEAR, cmd);
  	if(cmd == RW_CLEAR){
          //清零操作只是把长度改成0就行，并没有真的把内容释放掉
  		buflen = 0;
  		printk("[hahabuf] I/O Control successfully. now buflen = %d\n", buflen);
  		return 0;
  	}else{
  		printk("[hahabuf] I/O Control failed. buflen = %d\n", buflen);
  		return -1;
  	}
      //这里其实应该有很多else if，每一个对应一个cmd，进行不同的io操作。而这里只实现清零操作罢了
  }
  
  //以上的函数都是自己明明的，真正和系统调用绑定的工作在这里完成
  static struct file_operations haha_fops = {
  	open : haha_open,
  	release : haha_release,
  	read : haha_read,
  	write : haha_write,
  	unlocked_ioctl : haha_ioctl
  };
  
  //驱动程序和模块是写在一起的
  static int __init haha_init(void){
  	int ret = -1;
  	printk("[hahabuf] Haha device is initializing...\n");
      /**
      	注册模块
      	60：设备号
      	再把绑定好的结构体指针传进去，就初始化好了
      */
  	ret = register_chrdev(60, DEVICE_NAME, &haha_fops);
  	if(ret != -1){
  		printk("[hahabuf] Haha device successfully initialized.\n");
  	}else{
  		printk("[hahabuf] Haha device failed when initializing.\n");
  	}
  	return ret;
  }
  
  
  static void __exit haha_exit(void){
  	unregister_chrdev(60, DEVICE_NAME);
  	printk("[hahabuf] Haha device successfully removed.\n");
  }
  
  module_init(haha_init);
  module_exit(haha_exit);
  MODULE_LICENSE("GPL");
  ```
  
* 然后编写`hahatest.c`来测试我们编写好的驱动程序

  ```c
  #include <stdio.h>
  #include <fcntl.h>
  #include <unistd.h>
  #include <sys/ioctl.h>
  
  //驱动程序的位置就在/dev/目录下，haha是我们在hahadev.c里自己写的名字-DEVICE_NAME
  #define DEVICE_NAME "/dev/haha"
  #define RW_CLEAR 0x909090
  
  int main(){
  	int fd;
  	int ret;
  	char buff[1024];
  
  	printf("Opening device %s...\n", DEVICE_NAME);
  
      //像打开一个文件一样打开设备文件
  	fd = open(DEVICE_NAME, O_RDWR);
  	if(fd == -1){
  		printf("Open device failed.\n");
  		return 0;
  	}
  
  
  	printf("\nSuccess!\nReading student id...\n");
      //读取设备和读取普通文件是一样的，fd是我们open之后拿到的我们编写的驱动程序的文件句柄，利用这个句柄就能对该文件进行读写等操作了
  	if(read(fd, buff, 12) > 0){
          //buff一共1024位，把11改成0，就只输出前11位，正好是读出来的学号
  		buff[11] = '\0';
  		printf("%s\n", buff);
  	}else{
  		printf("Failed at reading id...\n");
  		return 0;
  	}
  
  
  	char rubbish[1035];
  	for(int i = 0; i < 1035; i++){
  		rubbish[i] = 's';
  	}
  	printf("Write 1035 's' to haha...\n");
      /**
      	这里我们写了1035个，但是在真正调用的时候只会写1024个。
      	原因就是上面的haha_write函数中的操作
      */
  	if(write(fd, rubbish, 1035) == -1){
  		printf("Failed at writing...\n");
  		return 0;
  	}
  
  	printf("\nWrite successfully! Now read haha again...\n");
  	if(read(fd, buff, 1024) > 0){
  		buff[1023] = '\0';
  		printf("%s\n", buff);
  	}else{
  		printf("Failed at reading rubbish...\n");
  		return 0;
  	}
  
  	printf("Now it's time to say goodbye!");
      /**
      	执行清楚操作
      	第一个参数是要操作的文件句柄
      	第二个是操作名称，对应haha_ioctl里的cmd
      */
  	if(ioctl(fd, RW_CLEAR) == 0){
  		printf("Remove haha successfully!\n");
  	}else{
  		printf("Failed at removing haha...\n");
  		return 0;
  	}
  
  	ret = close(fd);
  	printf("Haha has been closed. Bye!\n");
  	
  	return 0;
  }
  ```

* 然后是设备驱动+内核模块的`Makefile`文件

  ```makefile
  obj-m := hahadev.o
  KERNELDIR := /lib/modules/$(shell uname -r)/build
  PWD := $(shell pwd)
  
  modules:
  	$(MAKE) -C $(KERNELDIR) M=$(PWD) modules
  
  clean:
  	rm -rf *.o *~ core .depend .*.cmd *.ko *.mod.c .tmp_versions modules.order Module.symvers
  ```

* 然后就可以开始编译内核模块了。执行`sudo make`，生成`hahadev.ko`文件

* 然后编译测试程序`gcc -o hahatest hahatest.c`

* 使用`mknod`命令来创建设备文件

  ```c
  sudo mknod /dev/haha c 60 0
  ```

  其中，c表示字符型设备文件，60就是`register_chrdev`里面起的设备号，0是次设备，没啥用

* 然后插入模块，执行`sudo insmod hahadev.ko`，在这个过程中，就会调用`init`函数，也就会调用其中的`register_chrdev`来注册我们的设备文件，这样，就可以在外部通过绑定好的通用调用来操作设备文件了

* 执行`./hahatest`来测试，会看到如下结果：

  ```c
  Opening device /dev/haha
  Open device failed.
  ```

  **错了，为什么？？？因为`/dev/`下的文件需要超级用户权限!为了实验需要，我们只改变`haha`的修改权限即可**

* 执行`chmod 777 /dev/haha`，然后再执行`./hahatest`就会看到成功输出的结果：

  ```c
  Opening device /dev/haha...
  
  Success!
  Reading student id...
  20009200303
  Write 1035 's' to haha...
  
  Write successfully! Now read haha again...
  sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss
  Now it's time to say goodbye!Remove haha successfully!
  Haha has been closed. Bye!
  ```

* 然后查看一下`printk`输出的信息。执行`dmesg`，会看到如下结果：

  ```terminal
  [ 3694.621552] hahadev: loading out-of-tree module taints kernel.
  [ 3694.621604] hahadev: module verification failed: signature and/or required key missing - tainting kernel
  [ 3694.623209] [hahabuf] Haha device is initializing...
  [ 3694.623214] [hahabuf] Haha device successfully initialized.
  [ 3721.271801] [hahabuf] Haha is reading! The length of the buffer used to read is: 12
  [ 3721.271809] [hahabuf] Haha write successfully! The length of the buffer used to write is: 1024
  [ 3721.271813] [hahabuf] Haha is reading! The length of the buffer used to read is: 1024
  [ 3721.271819] [hahabuf] [RW_CLEAR:909090], [cmd:909090]
  [ 3721.271820] [hahabuf] I/O Control successfully. now buflen = 0
  ```

* 最后，还差重复打开的测试，编写`reopen.c`代码：

  ```c
  #include <stdio.h>
  #include <fcntl.h>
  #include <unistd.h>
  #include <sys/ioctl.h>
  
  #define DEVICE_NAME "/dev/haha"
  
  int main(){
  	int fd;
  	fd = open(DEVICE_NAME, O_RDWR);
  	if(fd == -1){
  		printf("Open %s failed ...\n", DEVICE_NAME);
  		return 0;
  	}
  	printf("Trying to reopen %s...\n", DEVICE_NAME);
  	fd = open(DEVICE_NAME, O_RDWR);
  	if(fd == -1){
  		printf("You can't reopen %s...\n", DEVICE_NAME);
  	}
      int ret = close(fd);
  	return 0;
  }
  ```

* 然后编译通过之后，在还没移除模块的情况下，执行`./reopen`，会看到如下结果：

  ```terminal
  Trying to reopen /dev/haha...
  You can't reopen /dev/haha...
  ```

  证明了我们的设备文件是不能被重复打开的！

* 另外，为了证明我们真的只写了1024个字符串，统计了一下输出s的数目正好是1023个，包含结束符号就是1024

### 遇到的问题

* 本次实验的设备文件，其实就是定义在`hahadev.c`中的`static char hahabuf[RWBUF_MAX_SIZE]`，而这个变量是静态的，在插入模块后，就会一直存在，用来进行对文件的读写操作。那既然插入模块之后就会一直存在，为什么还要定义成`static`呢？
* 0x909090只是一个标记而已，是可以任意定义的，真正进行清零操作的是`buflen = 0`
* `haha_fops`定义的操作，是不是相当于在c里实现了函数的重写呢？用户能调用的是`open; read; write; ioctl`之类的系统调用，当找到的文件是设备文件时，就搜索模块中有没有重写过的操作函数`haha_open; haha_write`等，如果没有，就调用系统默认的。还有比如`haha_open`中最重要的一句话就是`try_module_get(THIS_MODULE)`，那么打开的操作(比如加载`inode`)有没有封装在这个函数中呢？如果封装了，函数的参数只有当前的模块，那`inode`等参数又是怎么传进去的呢?
* 既然`init`函数中是通过`register`函数来关联设备文件的，那一个模块也可以关联多个文件吧！

## 总结和启发

经过本学期的操作系统实验，我对于操作系统内核的知识有了大致的了解。如何编译一个内核？如何修改内核的配置文件？编译内核是为了什么？什么是内核模块？内核模块的具体功能又是什么？这些问题在实验的过程中都一一得到了解答。比较关键的是内核模块的具体功能：编写设备驱动，增强系统的可维护性和可扩展性。另外这个**通过模块来添加系统调用的方式，在现在是非常不好的做法**，因为这种行为破坏了内核本来的源码，会产生很多意外的后果。所以以后的实验过程中要避免这种行为。同时整个实验的重点也都是在一个新领域——内核中进行编程，和传统的在操作系统层面上的编程有很大的不同，难度也提升了很多。就在不久的将来，也要对于内核的整个构架有一个相对完整的了解，才能打好操作系统的基础，也是**一个合格的码农的基本的修养！**

