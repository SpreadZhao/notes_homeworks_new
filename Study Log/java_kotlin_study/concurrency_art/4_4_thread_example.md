---
title: 4.4 线程池初见
chapter: "4"
order: "4"
---
## 4.4 线程池初见

> [!attention]
> 这里书上本来是“线程应用实例”。感觉其它的都没啥说的必要，唯一一个手搓一个简单线程池的这块还不错。

- [ ] #TODO c的线程池是不是也该快了？ ⏫

线程池的根本好处是，当你需要线程去执行任务时，直接丢到池子里就行。当有线程能干你这个活儿的时候，它就去了。这样我们可以用少量的几个线程去重复利用。这样就不用一直构建和销毁线程。

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-02-15 11.49.31.excalidraw.png]]

上图是线程池的基本思想。若干个job拍成一排，越早提交的任务就排在越前面。而一个Worker对应着一个线程。红色的Worker表示处于繁忙状态。每当有一个Worker闲下来的时候，它都会从队头取出一个job来运行。这里我们需要注意，**两个Worker不能同时取队头的job**。这就意味着，<u>对于job队列的修改操作必须是互斥的</u>。

然后，是任务比较少的情况：

![[Study Log/java_kotlin_study/concurrency_art/resources/Drawing 2024-02-15 11.57.15.excalidraw.png]]

现在的情况是，队列里已经没有job了，而Worker中有四个Worker因为没有拿到任务，从而闲置下来；而另一个Worker正在执行一个job。我们可以预见，如果之后一直没有新的job提交，那么这个红色的Worker最终也会变成蓝色。

通过以上描述，我们已经可以写出一个Worker的职责：

```kotlin
override fun run() {
	while (isRunning) {
		var job: JOB
		synchronized(jobs) {
			while (jobs.isEmpty()) {
				try {
					jobs.wait()
				} catch (_: InterruptedException) {
					Thread.currentThread().interrupt()
					return
				}
			}
			job = jobs.removeFirst()
		}
		try {
			job.run()
		} catch (_: Exception) {}
	}
}
```

只要jobs为空，那么就应该wait；反之就从jobs中取出一个job来运行。这里 kotlin `job.run()`的执行是写在一个线程里，所以就是这个线程在执行。

下一个问题：*什么时候notify*？显然，需要等到有job的时候才能notify，得让线程被唤醒之后能拿到job。所以：

```kotlin
override fun execute(job: JOB) {
	synchronized(jobs) {
		jobs.addLast(job)
		jobs.notify()
	}
}
```

每当向线程池提交一个任务时，先加到队列中，然后notify一下就好了。

最后，给出全部代码：

> [!attention]
> 突然发现这个线程池好多地方没讲清楚 。在真正搞线程池的时候捋一遍：[[Study Log/java_kotlin_study/concurrency_art/9_threadpool#9.1 以前线程池的总结|9_threadpool]]。

```kotlin
class DefaultThreadPool<JOB : Runnable> : ThreadPool<JOB> {

    companion object {
        private const val MAX_WORKER_NUMBERS = 10
        private const val DEFAULT_WORKER_NUMBERS = 5
        private const val MIN_WORKER_NUMBERS = 1
    }

    private val jobs = LinkedList<JOB>()
    private val workers = Collections.synchronizedList(ArrayList<Worker>())

    private var workerNum = DEFAULT_WORKER_NUMBERS
    private val threadNum = AtomicLong()

    constructor() {
        addWorkersInternal(DEFAULT_WORKER_NUMBERS)
    }

    constructor(num: Int) {
        workerNum = if (num > MAX_WORKER_NUMBERS) MAX_WORKER_NUMBERS else max(MIN_WORKER_NUMBERS, num)
        addWorkersInternal(workerNum)
    }

    private inner class Worker(var thread: Thread? = null) : Runnable {

        @Volatile
        private var isRunning = true

        override fun run() {
            while (isRunning) {
                var job: JOB
                synchronized(jobs) {
                    while (jobs.isEmpty()) {
                        try {
                            jobs.wait()
                        } catch (_: InterruptedException) {
                            Thread.currentThread().interrupt()
                            return
                        }
                    }
                    job = jobs.removeFirst()
                }
                try {
                    job.run()
                } catch (_: Exception) {}
            }
        }

        fun shutdown() {
            isRunning = false
            thread?.interrupt()
        }
    }

    private fun addWorkersInternal(num: Int) {
        repeat(num) {
            val worker = Worker()
            workers.add(worker)
            val thread = Thread(worker, "ThreadPool-Worker-${threadNum.incrementAndGet()}")
            worker.thread = thread
            thread.start()
        }
    }

    override fun execute(job: JOB) {
        synchronized(jobs) {
            jobs.addLast(job)
            jobs.notify()
        }
    }

    override fun shutdown() {
        workers.forEach { it.shutdown() }
    }

    override fun addWorkers(num: Int) {
        var n = num
        synchronized(jobs) {
            if (n + this.workerNum > MAX_WORKER_NUMBERS) {
                n = MAX_WORKER_NUMBERS - this.workerNum
            }
            addWorkersInternal(n)
            this.workerNum += n
        }
    }

    override fun removeWorker(num: Int) {
        synchronized(jobs) {
            if (num >= this.workerNum) {
                throw IllegalArgumentException("beyond workNum")
            }
            var count = 0
            while (count < num) {
                val worker = workers[count]
                if (workers.remove(worker)) {
                    worker.shutdown()
                    count++
                }
            }
            this.workerNum -= count
        }
    }

    override val jobSize: Int
        get() = jobs.size

    private fun Any.wait() =
        (this as java.lang.Object).wait()

    private fun Any.notify() =
        (this as java.lang.Object).notify()

}
```

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