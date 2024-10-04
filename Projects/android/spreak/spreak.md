SpreaK是一个基于mmap的高性能键值对存储方案。实现轻量，可以替代MMKV使用。支持多进程，并且存储方案显示区分类型，不像MMKV需要手动decode。

> [!question] 为什么SpreaK存储String类型的时候，不需要关心字符串大小的问题？
> 因为我们是**先存value，然后再尝试修改指向**。这意味着，如果我连续调用两次`repo.storeString("key", "value")`，那么在第二次调用的时候，我们会先把value存到block文件中，找到位置，当然可能是fixed也可能是unfixed。这个时候，**两个"value"字符串在block file中是并存的**。然后，我们才会修改chunk文件中的chunk，让value\_block中的block\_index指向新的block。并把原来的block擦除掉。这样会导致block文件中出现空洞，但是由于我们每次存block的时候，都是寻找第一个能够装下value的blcok，所以这块空间之后是有几率被用上的。所以，SpreaK是不会主动整理文件的。这也是比MMKV要快的一点。