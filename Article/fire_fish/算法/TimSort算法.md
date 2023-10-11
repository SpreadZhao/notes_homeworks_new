

## 什么是TimSort算法
TimSort算法是一种起源于归并排序和插入排序的混合排序算法，设计初衷是为了在真实世界中的各种数据中可以有较好的性能。

## 基本工作过程
1. 扫描数组，确定其中的单调上升段和严格单调下降段，将严格下降段反转。我们将这样的段称之为run。
2. 定义最小run长度，短于此的run通过插入排序合并为长度高于最小run长度；
3. 反复归并一些相邻run，过程中需要避免归并长度相差很大的run，直至整个排序完成；
4. 如何避免归并长度相差很大run呢， 依次将run压入栈中，若栈顶run X，run Y，run Z 的长度违反了**X>Y+Z 或 Y>Z** 
则Y run与较小长度的run合并，并再次放入栈中。 依据这个法则，能够尽量使得大小相同的run合并，以提高性能。
注意Timsort是稳定排序故只有相邻的run才能归并。


总之，timsort是工业级算法，其混用**插入排序**与**归并排序**，**二分搜索**等算法，
亮点是充分利用待排序数据可能部分有序的事实，并且依据待排序数据内容动态改变排序策略——选择性进行归并以及galloping。

## 代码示例
java的Collection.sort就是用的TimSort算法，分为标准的TimSort和mini-TimSort。
java.util.TimSort.sort
### mini_TimSort算法
```java
// 对于小数据量的使用"mini-TimSort"算法。
// 原理：1、扫描数组确定单调段2、运用插入排序吧后续元素插入到单调段中。
if (nRemaining < MIN_MERGE) {
    int initRunLen = countRunAndMakeAscending(a, lo, hi, c);    // 确定单调段
    binarySort(a, lo, hi, lo + initRunLen, c);  // 运用二分法吧后续元素插入到单调段
    return;
}
```

### 标准的TimSort算法
```java
// 确定最小单调段
int minRun = minRunLength(nRemaining);
do {
    // Identify next run
    // 确定run段
    int runLen = countRunAndMakeAscending(a, lo, hi, c);

    // If run is short, extend to min(minRun, nRemaining)
    // 单调段长度不够则拓展到minRun最小长度
    if (runLen < minRun) {
        int force = nRemaining <= minRun ? nRemaining : minRun;
		// 用"插入排序"把run段拓展到minRun长度
        binarySort(a, lo, lo + force, lo + runLen, c);
        runLen = force;
    }

    // Push run onto pending-run stack, and maybe merge
    // 记录run段位置，可能会合并。
    ts.pushRun(lo, runLen);
    ts.mergeCollapse();

    // Advance to find next run
    lo += runLen;
    nRemaining -= runLen;
} while (nRemaining != 0);

// Merge all remaining runs to complete sort
assert lo == hi;
// 最后强制合并之前在栈中保存的run段
ts.mergeForceCollapse();
assert ts.stackSize == 1;
```