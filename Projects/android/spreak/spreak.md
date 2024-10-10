之前已经有了对于keva的分享：，但是只是介绍了一些文件设计和总体上的原理。所以本次分享旨在详细深入keva，通过具体的例子来介绍keva究竟是如何实现键值对存储的。并在这个过程中穿插介绍相关的知识点（和西瓜业务上的东西）。


SpreaK是一个基于mmap的高性能键值对存储方案。实现轻量，可以替代MMKV使用。支持多进程，并且存储方案显示区分类型，不像MMKV需要手动decode。

> [!question] 为什么SpreaK存储String类型的时候，不需要关心字符串大小的问题？
> 因为我们是**先存value，然后再尝试修改指向**。这意味着，如果我连续调用两次`repo.storeString("key", "value")`，那么在第二次调用的时候，我们会先把value存到block文件中，找到位置，当然可能是fixed也可能是unfixed。这个时候，**两个"value"字符串在block file中是并存的**。然后，我们才会修改chunk文件中的chunk，让value\_block中的block\_index指向新的block。并把原来的block擦除掉。这样会导致block文件中出现空洞，但是由于我们每次存block的时候，都是寻找第一个能够装下value的blcok，所以这块空间之后是有几率被用上的。所以，SpreaK是不会主动整理文件的。这也是比MMKV要快的一点。

mmap介绍。译自《Operating Systems: Three Easy Pieces》

> 你可能已经注意到了，我们讨论`malloc()`和`free()`的时候，一点儿都没提过系统调用这回事儿。原因很简单：**这俩函数就不是系统调用**，而是标准库里的函数而已。因此，malloc library管理的是你的虚拟地址空间，但是这个library是构建在某些系统调用之上的。这些系统调用负责向操作系统申请一些内存，还有把一些内存还给操作系统。
> 
> 这些系统调用的其中之一是`brk`，这个系统调用的作用是：改变一个程序的**break**的位置。break是什么呢？**break指的是堆内存的尾部**。所以，`brk`做的事情就是：接收一个参数，这个参数就是新的break的地址，这样根据新地址和老地址比大小，就知道我是想**扩堆内存**还是**缩堆内存**。然后，还有个`sbrk`系统调用，传的不是绝对值，是增量。功能是一样的。
> 
> 当然，`brk`一族的系统调用，应用层你最好永远也别直接调用。因为他们只是为了`malloc`和`free`服务的，不应该暴露给用户态进程。
> 
> 最后，你你也可以用`mmap`系统调用来向操作系统申请内存。如果你传了适当的参数，`mmap`会在你的进程中给你创建一个**匿名的内存**——和任何文件都没关系，而是映射的你磁盘上的交换空间（swap space，也就是现在手机内存12G + 3G里面那3G）。这些映射后的内存之后就可以用做堆内存，并且像堆内存一样管理。

从这里看，`mmap`的功能其实就是：将某一块空间，映射成当前进程中的一段内存。置于“某一块空间”是什么，可以通过我们的参数指定。而无论是MMKV还是SpreaK，都利用了这一点：

```cpp
ptr_ = static_cast<uint8_t *>(mmap(nullptr, 
								   size_, 
								   PROT_READ | PROT_WRITE, 
								   MAP_SHARED, 
								   fd, 
								   0));
```

这是SpreaK中创建chunk file和block file的核心逻辑。就是将`fd`这个文件句柄（指向`.blk`和`.chk`文件）指向的空间映射到当前进程的一段虚拟内存中，从而可以被管理。

`mmap`是无法保证状态一致的，换句话说，内核不会保证对于映射内存的访问是**原子且事务**的。在下面的代码中，`p`是一个指向映射到文件的内存的指针：

```c
p->stack[p->n++] = atoi(argv[i]);
```

如果在`n++`之后程序立马终止，后面的赋值操作没有运行，会导致状态不一致。因此，我们在使用`mmap`时，可以配合比如`msync`系统调用来进行状态同步（[Is persistent memory persistent?](https://dl.acm.org/doi/pdf/10.1145/3397882)），以防止断电等导致的不一致；也可以使用`MAP_SHARED_VALIDATE | MAP_SYNC`来让kernel在写内存时强制产生一个缺页中断，在中断处理程序中将所有的改动写入映射的I/O空间（[Two more approaches to persistent-memory writes \[LWN.net\]](https://lwn.net/Articles/731706/)）。

> Instead, the pages are mapped read-only with a special flag, **forcing a page fault** when the process first attempts to perform a write to one of those pages. The fault handler will then flush out any dirty metadata synchronously, set the page permissions to allow the write, and return.

我也找到了linux内核中的很多代码证明这一点（没串起来，挺可惜的。。。）。

```c
/*
 * MAP_SYNC on a dax mapping guarantees dirty metadata is
 * flushed on write-faults (non-cow), but not read-faults.
 */
static bool dax_fault_is_synchronous(const struct iomap_iter *iter,
		struct vm_area_struct *vma)
{
	return (iter->flags & IOMAP_WRITE) && (vma->vm_flags & VM_SYNC) &&
		(iter->iomap.flags & IOMAP_F_DIRTY);
}
```

```c
#define MAP_SYNC		0x080000 /* perform synchronous page faults for the mapping */
```

```c
/* Supports synchronous page faults for mappings */
#define FOP_MMAP_SYNC		((__force fop_flags_t)(1 << 2))
```

```c
/**
 * dax_finish_sync_fault - finish synchronous page fault
 * @vmf: The description of the fault
 * @order: Order of entry to be inserted
 * @pfn: PFN to insert
 *
 * This function ensures that the file range touched by the page fault is
 * stored persistently on the media and handles inserting of appropriate page
 * table entry.
 */
vm_fault_t dax_finish_sync_fault(struct vm_fault *vmf, unsigned int order,
		pfn_t pfn)
{
	int err;
	loff_t start = ((loff_t)vmf->pgoff) << PAGE_SHIFT;
	size_t len = PAGE_SIZE << order;

	err = vfs_fsync_range(vmf->vma->vm_file, start, start + len - 1, 1);
	if (err)
		return VM_FAULT_SIGBUS;
	return dax_insert_pfn_mkwrite(vmf, pfn, order);
}
EXPORT_SYMBOL_GPL(dax_finish_sync_fault);
```

SpreaK没有采用这种方式，而是在写入所有内容之后，最后写入一个有效位来标记之前的内容已经全部写入。这种做法在绝大多数情况下还是可以保证数据的准确性的。

最后一点。也是在会上有人问：SpreaK是怎么保证进程被杀掉之后，依然能够确保写入正确的数据的？答案是：kernel保证的：[c - mmap, msync and linux process termination - Stack Overflow](https://stackoverflow.com/questions/5902629/mmap-msync-and-linux-process-termination)。在新的Linux内核中，mmap所申请的page已经被独立出来到内核中，进程即使被杀死，这部分page依然会被刷写到对应的磁盘空间中。

[Revisiting the MAP_SHARED_VALIDATE hack \[LWN.net\]](https://lwn.net/Articles/758594/)

所有的设计快速过。

## Java 层关键设计

那张KevaXXX的图

KevaValueWrapper，是在Java层保存在内存中的键值对缓存。保存在mValueMap中。当调用getRepo时，**会在native层反向调用KevaImpl中的回调方法**，将从chunk文件和block文件中读取到的信息加载到mValueMap中。这个过程也是Keva初始化中最耗时的流程，所以KevaFuture的作用就是将这个过程抛给线程池进行，并将加载的结果（Keva对象）保存到FutureTask中。

我们会注意到，KevaValueWrapper中的字段都使用volatile修饰，这也是Keva保证线程安全的方式。后面我们还会看到，关键的读写方法会通过Java监视器锁来实现。

## Native 层关键文件设计

### Chunk 文件

这里先提一下 chunk 文件和 block 文件的本质区别：chunk文件保存的是定长的值；而block文件保存的是不定长的值。有了这个铺垫，我们才能更好地理解keva安排键值对位置的方式。

Chunk 文件的总体结构是 Header + Content（block文件也是一样的）。其中header里会保存文件的版本信息，元数据等信息。Content中保存的是真正的一个个Chunk。

> 贴一张chunk file的简单图。

因为keva基于mmap，所以真正在保存的时候我们访问的都是内存，虚拟内存。下面是一段在chunk文件中获取一个chunk的代码：

```cpp
int64_t PickChunkAndGetOffsetOnce() {
	uint32_t index = bitmap->RequireChunk();
	return start + index * chunk_size;  // 假设start是chunk file的起始地址
}
```

> 当然，这段代码仅仅是为了理解。真正的实现要考虑很多情况。

没错，我们使用bitmap追踪被使用的chunk：我们提到过在repo加载的过程中，会从chunk文件和block文件中读取保存的键值对，并加载到Java层的内存中。在这个过程中，我们其实就可以**顺便将bitmap也初始化**：发现一个键值对，就在bitmap中标记对应位置的chunk已经被占用。

因此，bitmap当然是知道哪些chunk是空闲的。它可以返回空闲的chunk（们）的index。这里是index而不是地址的原因是，~~bitmap的一个bit表示一个chunk占用与否~~，bitmap并不关心当前它维护的文件到底是什么规模的。所以，这里要由chunk file自己来通过index计算出chunk的起始指针。而后面我们会看到，block文件也是用这种方式，复用了同一份bitmap。

现在到了关键的问题：存储定长值的chunk，究竟能保存什么？事实上，在常规的键值对场景下，除了String与二进制流，其它所有的类型都是可以定长存储的。而chunk文件中的一个个chunk保存的就是这些东西。

这里我们要注意一件事情：key是String。这代表着chunk是无法存储String的真实值的。而这也是keva介绍文档中的这段评论出现的原因：

> 飞书的评论图。

而对于int，double，long这种定长的类型，当然可以保存到chunk文件中。而对于不定长类型，我们会在chunk文件中保存一个引用，用来在block文件中寻找到真的值。

我们先来看chunk本身，然后再来看chunk file。由于我们要保存的定长值的长度也都大不相同，所以**chunk也分很多种**。但是所有的chunk的前4个字节都会保存一些固定的信息。我们先看这部分。先来介绍一下keva的键值对到底是怎么分布在chunk文件和block文件中的：

> chunk block locate.

chunk的组成可以是：

```
chunk == info + key_ref [+ value]
```

除了值本身，我们还需要保存一些元数据。比如这个chunk是否有效，这个chunk到底是什么类型等等。keva在所有类型的chunk头部预留了8个bit来保存这些信息（info）；而除了这些，键值对中的key在block文件中的索引也需要保存。我们提到过，String无法直接保存到chunk，只能存引用。所以接下来的24 bit就是用来存储这些；而根据要保存的value的大小不同，我们会选择性地再接上不同长度的bits。下面按照从小到大来介绍这些不同的chunk。

- 4 bytes (32 bits) - 8 + 24 + 0

不接。那我能存什么？其实，最前面8个bit中的其中一个，是用来保存布尔类型的真实值的：

> 32图。

4 5 6 7保存了value的具体类型。所以一共能保存$2^4 = 16$种类型。而如果是布尔类型，那么1号位保存的就是布尔类型的真实值。

- 8 bytes (64 bits) - 8 + 24 + 32

显然，这里保存的就是占用空间 $\leqslant$ 4的类型的value。不过目前keva只支持int和float。

> 64 图

这里注意一点，key_ref一共有24 bit，也就是最大值为$2^{24} - 1$。因此我们最多能存储这么多的键值对。而如果我们用同样的方式，即引用来保存String的value的话，自然也最多需要24bit即可。因此，这里凑了个整，使用32 bit来保存不定长类型的引用。keva的实现有String和ByteArray。

- 12 bytes (96 bits) - 8 + 24 + 64

显然，这种chunk保存的value就是long，double类型。

知道了chunk，介绍chunk file就很简单了。但是，有一个比较关键的问题需要考虑：我们使用bitmap追踪chunk的使用情况。但是chunk的大小对于不同类型是不一样的。所以我们如果直接把存入的chunk串一串保存在文件中，文件的结构会很复杂。追踪，查询起来也很麻烦：

> 复杂的chunk file

keva的解决方法是：

- 在文件的开头，预留一些定长的空间，这些空间内存放的chunk的大小是一样的。这样查询起来会更快；
- 在定长空间后面，才是像刚刚说的不定长空间。这里面的chunk的存放大小不一；
- 对于定长和不定长的空间，分别用不同的bitmap去追踪：
	- 定长的bitmap，一个bit对应一个chunk的占用情况；
	- 不定长的bitmap，一个bit对应文件中32bit的占用情况。所以，上面的三种类型的chunk，分别会占用1，2，3个bit。

因此，完整的Chunk File文件结构如下：

> 完整的chunk file