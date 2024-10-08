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