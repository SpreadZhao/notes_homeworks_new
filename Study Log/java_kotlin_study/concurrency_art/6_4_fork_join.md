---
title: 6.4 Fork/Join 框架
chapter: "6"
order: "4"
---

## 6.4 Fork/Join 框架

说实话，我之前从来没听说过这个东西，第一次见。

这个框架的主要作用就是把大任务拆（fork）成小任务，小任务由不同的线程去并发完成，最终把这些小任务的结果合并（join）成最终的结果。

从这个描述里可以看出来，这些拆出来的小任务，**在并发执行的时候**，之间不能产生依赖。本质上这也是Divide and Conquer的思想。

我们先用两个简单的小例子来熟悉一下这个框架。第一个是：计算$m + (m + 1) + \cdots + n (n > m)$。

我们规定最小的任务是两个数字相加。因此如果我们输入了$1 + 2 + 3 + 4$，需要从中间分开，计算$1 + 2$和$3 + 4$，最后把两个的结果合起来。其实就是不断二分，找到最终的结果。

两个数字设置为THRESHOLD：

```kotlin
private const val THRESHOLD = 2
```

让我们的任务继承自最常用的RecursiveTask，它用于有返回值的任务：

```kotlin
class CountTask(
    private val start: Int,
    private val end: Int
) : RecursiveTask<Int>()
```

继承之后，需要重写`compute()`方法。这是一个递归的方法，需要进行二分的判断。如果传入的长度超过了THRESHOLD，需要二分进行递归计算；如果不是的话，就是递归到头儿了，就可以真正开始计算了：

```kotlin
override fun compute(): Int {
	var sum = 0
	if (end - start > THRESHOLD) {
		val middle = (start + end) / 2
		val leftTask = CountTask(start, middle)
		val rightTask = CountTask(middle + 1, end)
		leftTask.fork()
		rightTask.fork()
		val leftRes = leftTask.join()
		val rightRes = rightTask.join()
		sum = leftRes + rightRes
	} else {
		for (i in start .. end) {
			sum += i
		}
	}
	return sum
}
```

最后给出带上测试代码的完整版：

```kotlin
class CountTask(
    private val start: Int,
    private val end: Int
) : RecursiveTask<Int>() {

    companion object {
        private const val THRESHOLD = 2
    }

    override fun compute(): Int {
        var sum = 0
        if (end - start > THRESHOLD) {
            val middle = (start + end) / 2
            val leftTask = CountTask(start, middle)
            val rightTask = CountTask(middle + 1, end)
            leftTask.fork()
            rightTask.fork()
            val leftRes = leftTask.join()
            val rightRes = rightTask.join()
            sum = leftRes + rightRes
        } else {
            for (i in start .. end) {
                sum += i
            }
        }
        return sum
    }
}

fun main() {
    val forkJoinPool = ForkJoinPool()
    val task = CountTask(1, 100)
    val result = forkJoinPool.submit(task)
    println(result.get()) // 5050
}
```

需要注意的是这里的sum并不需要传入到递归中，因为递归计算的结果会经过`join()`方法给到`leftRes`和`rightRes`，在递归的过程中这两个变量才是用于传递小任务的结果的。

---

第二个例子是，计算斐波那契数列的第n个数字是几。其实就是前两位的合。这里我直接给出简单实现的版本：

```kotlin
class Fibonacci(private val n: Int) : RecursiveTask<Int>() {
    override fun compute(): Int {
        var num = 0
        when (n) {
            1 -> {
                num = 1
            }
            2 -> {
                num = 1
            }
            else -> {
                val task1 = Fibonacci(n - 1)
                val task2 = Fibonacci(n - 2)
                task1.fork()
                task2.fork()
                val sum1 = task1.join()
                val sum2 = task2.join()
                num = sum1 + sum2
            }
        }
        return num
    }
}

fun main() {
    val forkJoinPool = ForkJoinPool()
    for (i in 1 .. 10) {
        val task = Fibonacci(i)
        val res = forkJoinPool.submit(task)
        print("${res.get()} ") // 1 1 2 3 5 8 ...
    }
}
```

在RecursiveTask的注释里其实有一个更精简的版本，但是那个不太好理解。所以这里先给出和刚才的那个例子差不多的写法，之后随着介绍再补上。

从这两个例子里我们可以看出，Fork/Join框架的整体思路就是这样的：

![[Study Log/java_kotlin_study/concurrency_art/resources/Pasted image 20240721161848.png]]

只要我们不满意，就可以一直分。直到分到我们可以计算为止。最后将计算后的结果合并起来得到总任务的结果。当然，这里的任务其实可以没有结果，比如每个任务就是去加载一些数据之类的。

- [ ] #TODO tasktodo1721550093160 介绍Fork/Join框架的原理。因为用的少，所以不是那么重要。 ➕ 2024-07-21 🔽 🆔 p650ba

---

```dataviewjs
const pages = dv.pages('"Study Log/java_kotlin_study/concurrency_art"')
let nextChapterHead = undefined
let res = undefined
const current = dv.current()
for (let page of pages) {
	if (page.chapter_root == true && page.order == Number(current.chapter) + 1) {
		console.log("found next head: " + page.name)
		nextChapterHead = page
		continue
	}
	if (page.chapter == undefined || page.chapter != current.chapter) {
		console.log("not current chapter: " + page.file.name)
		continue
	}
	if (page.order == Number(current.order) + 1) {
		res = page
	}
}
console.log("res: " + res)
console.log("next: " + nextChapterHead)
if (res == undefined) {
	res = nextChapterHead
}
let text = ""
if (res != undefined) {
	const path = res.file.path
	const title = res.title
	const decoLink = "[[" + path + "|" + title + "]]"
	text = "Next Article: " + decoLink
} else {
	text = "旅途的终点！"
}
dv.el("p", text, { attr: { align: "right" } })
```