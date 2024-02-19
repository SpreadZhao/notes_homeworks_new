---
title: 自定义Mutex的并发问题
date: 2024-02-19
tags:
  - language/coding
mtrace:
  - 2024-02-19
---

#date 2024-02-19

# 自定义Mutex的并发问题

起因是我写《并发编程艺术》笔记的时候，在[[Study Log/java_kotlin_study/concurrency_art/5_lock_in_java|5_lock_in_java]]自己实现的一个Mutex：

```kotlin
class LockTest {

    companion object {
        var i = 1
        var currThNum = 1
        val mutex = Mutex()
    }

    class MutexPrintThread(private val thNum: Int, private val otherNum: Int) : Thread("mutex-thread-$thNum") {
        override fun run() {
            while (i < 100) {
                mutex.lock()
                if (currThNum != thNum && mutex.isLocked) {
                    mutex.unlock()
                    continue
                }
                println("thread $thNum print $i")
                currThNum = otherNum
                i++
                mutex.unlock()
            }
        }
    }
}
```

也是多线程交替输出的例子。目前这个是可以工作的。但是我发现，这个`mutex.lock()`总是感觉多余。因为你如果获取锁失败，那么就在这里锁住了，会不断尝试获取，然后获取了发现当前轮不到我打印，然后又解锁回头重来。。。

好吧，这样实现好像是对的。其实我就是想改成tryLock的实现：

```kotlin
while (i < 100) {
	val got = mutex.tryLock()
	if (currThNum != thNum) {
		if (got) mutex.unlock()
		continue
	}
	println("thread $thNum print $i")
	currThNum = otherNum
	i++
	mutex.unlock()
}
```

- [ ] #TODO 这样实现会抛出异常。为啥？如果我改成这样就对了：

```kotlin
while (i < 100) {
	val got = mutex.tryLock()
	if (!got) continue
	if (currThNum != thNum) {
		mutex.unlock()
		continue
	}
	println("thread $thNum print $i")
	currThNum = otherNum
	i++
	mutex.unlock()
}
```

不过我倒是总结出一个关于这种并发控制的基本思路：

先保证进入到临界区，之后的事情你在临界区里管。比如这里的获取锁，只有got为true的时候才证明成功进入到了临界区。而我们要知道，currThNum这个变量毫无疑问是临界区中的变量。所以，所有读写这个变量的代码都视为临界区代码。换句话说，**你在判断是不是我该打印的这一刻开始，你就已经在临界区里面了**。所以，你应该想的是如果不是轮到我，就退出临界区。

而那个错误的实现，它把退出临界区的操作`if (got) mutex.unlock()`用一个临界区外的`got`变量来标识，这样的写法从设计角度上就是存在问题的。更致命的错误是，**如果got为false，那么本身你就没有权利进入临界区**！但是那个错误的实现并不是这样的。它在临界区里面才读got变量，就相当于==我在临界区里面判断我是不是该进临界区==，这么写不出问题才怪。

```ad-error
title: Deprecated

下面删掉的一堆看看就成，都是错的。直接看最后的总结。
```

~~理解了这个问题。我发现，即使只用volatile我们都能实现！~~

```kotlin
class OneToHundred2 {
    companion object {
        @Volatile
        var inCritical = false
        var currTh = 1
        var num = 1
    }

    class PrintThread(
        private val thNum: Int,
        private val nextThNum: Int
    ) : Thread("thread-$thNum") {
        override fun run() {
            while (num < 100) {
                if (inCritical) continue
                // 从这行开始进入临界区
                inCritical = true
                if (currTh != thNum) {
                    inCritical = false
                    continue
                }
                println("thread $thNum: $num")
                currTh = nextThNum
                num++
                inCritical = false
            }
        }
    }
}
```

~~这个程序也能做到多个线程交替输出。并且仅仅只用了一个volatile变量来标识目前是否处于临界区。但是需要注意的是，这样的实现方式只有在这个例子中是正确的。~~

~~现在想象这样的情况：两个线程同时发现inCritical为false，因此都打算执行`inCritical = true`这句话。但是，由于volatile的写内存语义（写后读）， 两个线程会排队。第一个线程能将inCritical从false置为true，而第二个线程会将inCritical从true置为true。但是由于有`currTh != thNum`的判断，所以最终也只会有一个线程能进行输出，其余线程只能再次返回到while循环。~~

~~在这个过程中，已经出现了“多个线程同时进入临界区”的情况。所以虽然这样做的结果是正确的，但是这个实现却很tricky。~~

~~好吧，我挺傻的。下面的实现也正常：~~

```kotlin
class OneToHundred2 {
    companion object {
        var currTh = 1
        var num = 1
    }

    class PrintThread(
        private val thNum: Int,
        private val nextThNum: Int
    ) : Thread("thread-$thNum") {
        override fun run() {
            while (num < 100) {
                if (currTh != thNum) continue
                println("thread $thNum: $num")
                num++
                currTh = nextThNum
            }
        }
    }
}
```

~~对比一下之前我们的实现：[[Study Log/java_kotlin_study/java_kotlin_study_diary/lock_in_java#^legacy|lock_in_java]]，我当时真是个sb。我当时的实现，如果`currTh != thNum`的话，直接在那里空转。这就导致了~~

行吧，说这么多也累了，发现错误越说越多。所幸这里直接来一个总结：

1. 先进入临界区，在临界区里面再判断是否要退出临界区。这个操作是正确的；
2. 我上面删掉的那些实现，无论是volatile的，还是啥也没有的，包括我之前实现的那个[[Study Log/java_kotlin_study/java_kotlin_study_diary/lock_in_java#^legacy|lock_in_java]]，都是错误的。错就错在没有按照第一条的规矩来。你可以试试，如果并发量一旦提高，那么出错的概率会明显增加。

而我们自己实现的那个Mutex，不管是tryLock()的版本还是lock()的版本，不管你用多少个线程，甚至是99个，最后的结果也都是正确的。

那么，tryLock()的版本和lock()的版本真正的区别是什么呢？其实就是，二者在获取不到锁时的行为不同。我们抽离出来看：

```kotlin
// lock()版本
mutex.lock()
```

```kotlin
// tryLock()版本
val got = mutex.tryLock()
if (!got) continue
```

lock()版本在获取失败时会直接阻塞在这里；而tryLock()版本在获取失败时会继续执行，只不过会返回一个false。这个其实就是busyWaiting和sleep \& wakeup的区别。所以，面试官应该是倾向于第一种实现，因为更高级。

另外，lock()版本中判断线程的时候：

```kotlin
if (currThNum != thNum && mutex.isLocked) {
	mutex.unlock()
	continue
}
```

后面的`mutex.isLocked`是多余的。因为在阻塞的情况下，程序如果不阻塞唯一的可能就是已经获得了锁。所以这句话永远是true。