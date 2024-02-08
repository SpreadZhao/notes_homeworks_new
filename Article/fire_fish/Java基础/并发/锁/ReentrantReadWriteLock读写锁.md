

### 什么是读写锁
之前提到锁（如ReentrantLock）基本都是**排他锁**，这些锁在同一时刻只允许一个线
程进行访问，而读写锁在同一时刻可以允许多个读线程访问，但是在写线程访问时，所有的读
线程和其他写线程均被阻塞。读写锁维护了一对锁，一个读锁和一个写锁，通过分离读锁和写
锁，使得并发性相比一般的排他锁有了很大提升。
**在读写锁中，读写锁互斥，写写锁互斥，只有读读锁可以共存**



### 读写锁的实现分析
接下来分析ReentrantReadWriteLock的实现，主要包括：读写锁的总体结构、读写状态的设计、写锁的获取与释
放、读锁的获取与释放以及锁降级（以下没有特别说明读写锁均可认为是ReentrantReadWriteLock）

#### 读写锁的总体结构

#### 读写状态的设计
读写锁同样依赖自定义同步器来实现同步功能，而读写状态就是其同步器的同步状态。
如何在AQS的state一个整形变量上设计出读写状态成为读写锁设计的关键。
如果在一个整型变量上维护多种状态，就一定需要“按位切割使用”这个变量，读写锁将
变量切分成了两个部分，**高16位表示读，低16位表示写**
以下图为例：
1. state状态的高16位表示读状态，值为2表示，被获取或重入了2次（至于每个读线程可重入锁的次数会在"**读锁的获取与释放**"说到）
2. state状态的低16位表示写状态，值为3表示，写锁被线程获取了一次，随后又被同样的线程重入了2次（因为写锁不能被不同的线程获取）
![](/Users/apple/Documents/Work/aliyun-oss/dev-images/2023-03-19-20-36-05-image.png)

#### 写锁的获取与释放
写锁是一个支持重进入的排它锁。如果当前线程已经获取了写锁，则增加写状态。如果当
前线程在获取写锁时，读锁已经被获取（读状态不为0）或者该线程不是已经获取写锁的线程，
则当前线程进入等待状态，获取写锁的代码如代码如下所示（代码解释在注释中已经详细说明了）：
```java
// ReentrantReadWriteLock的tryAcquire方法
public class ReentrantReadWriteLock
		implements ReadWriteLock, java.io.Serializable {

	abstract static class Sync extends AbstractQueuedSynchronizer {

		/**
         * 写锁的获取
		 * @param acquires
		 * @return
		 */
		protected final boolean tryAcquire(int acquires) {
			Thread current = Thread.currentThread();
			int c = getState();     // c的高16位表示"读锁"，低16位表示"写锁"；不为0表示存在锁
			int w = exclusiveCount(c);  // 获取写锁的值
			if (c != 0) {   // 说明一定有锁（只有读锁 或 只有写锁 或 读写锁均有）
				if (w == 0 || current != getExclusiveOwnerThread()) // 有读锁 或 写锁不是自己 直接失败【因为读写互斥，写写也互斥】【重点】
					return false;
				if (w + exclusiveCount(acquires) > MAX_COUNT)
					throw new Error("Maximum lock count exceeded");
				// 代码到这里说明：有写锁且是当前线程，可以直接设置状态
				setState(c + acquires); // 没有线程安全问题，因为获取了写锁，具有排他性，直接设置state
				return true;
			}
			// writerShouldBlock这个函数封装掉了 当前是公平还是非公平 的信息
			if (writerShouldBlock() ||
					!compareAndSetState(c, c + acquires)) // cas抢写锁
				return false;
			setExclusiveOwnerThread(current);
			return true;
		}

		/**
         * 写锁的释放
		 * @param releases
		 * @return
		 */
		protected final boolean tryRelease(int releases) {
			if (!isHeldExclusively())
				throw new IllegalMonitorStateException();
			int nextc = getState() - releases;
			boolean free = exclusiveCount(nextc) == 0;      // 表示释放后state的低16位的写锁状态
			if (free)   // 写锁被完全释放
				setExclusiveOwnerThread(null);
			setState(nextc);    // 写锁没有被完全释放。释放锁的线程就是写线程，没有其他线程参与，不存在线程安全问题
			return free;
		}
	}
}
```
代码说明：
1. 该方法除了重入条件（当前线程为获取了写锁的线程）之外，增加了一个读锁是否存在的判断。如果存在读锁，则写锁不能被获取（读写互斥、写写互斥）
2. 写锁的释放与ReentrantLock的释放过程基本类似，每次释放均减少写状态，当写状态为0时表示写锁已被释放

#### 读锁的获取与释放
读锁是一个支持重进入的共享锁，它能够被多个线程同时获取，在没有其他写线程访问
（或者写状态为0）时，读锁总会被成功地获取，而所做的也只是（线程安全的）增加读状态。如
果当前线程已经获取了读锁，则增加读状态。如果当前线程在获取读锁时，写锁已被其他线程
获取，则进入等待状态

获取读锁的实现从Java 5到Java 6变得复杂许多，主要原因是新增了一
些功能，例如getReadHoldCount()方法，作用是返回当前线程获取读锁的次数。**读状态是所有线
程获取读锁次数的总和，<mark>而每个线程各自获取读锁的次数只能选择保存在ThreadLocal中，由
线程自身维护</mark>，这使获取读锁的实现变得复杂**。因此，这里将获取读锁的代码做了删减，保留
必要的部分

读锁获取和释放的代码如下（代码解释在注释中已经详细说明了）：
```java
// ReentrantReadWriteLock的tryAcquireShared方法
public class ReentrantReadWriteLock
		implements ReadWriteLock, java.io.Serializable {

	abstract static class Sync extends AbstractQueuedSynchronizer {

		/**
         * 获取共享锁，是fullTryAcquireShared的快速版本，也没看出快速在哪里，无所谓直接看fullTryAcquireShared方法
		 */
		protected final int tryAcquireShared(int unused) {
			return fullTryAcquireShared(current);
		}

		/**
         * 完整的尝试获取读锁
		 * @param current
		 * @return
		 */
		final int fullTryAcquireShared(Thread current) {
			HoldCounter rh = null;
			for (;;) {
				// ============================第一部分=====================================
				int c = getState();
				if (exclusiveCount(c) != 0) { // 如果写锁被持有
					if (getExclusiveOwnerThread() != current)   // 如果写锁不是当前线程持有
						return -1;  // <1> 有写锁且不是当前线程，因读写互斥，直接返回false
                    /*else {
						// 如果写锁就是当前线程持有的，我们啥也不干，直接执行下一段代码
					}*/
				} else if (readerShouldBlock()) {   // <2>
					// Make sure we're not acquiring read lock reentrantly
					if (firstReader == current) {
						// assert firstReaderHoldCount > 0;
					} else {
						if (rh == null) {
							rh = cachedHoldCounter;
							if (rh == null || rh.tid != getThreadId(current)) {
								rh = readHolds.get();
								if (rh.count == 0)
									readHolds.remove();
							}
						}
						if (rh.count == 0)
							return -1;
					}
				}
				if (sharedCount(c) == MAX_COUNT)
					throw new Error("Maximum lock count exceeded");

				// ============================第二部分=====================================
				if (compareAndSetState(c, c + SHARED_UNIT)) {
					return 1;
				}
			}
		}
	}
}
```
代码解释：

<0>: 以上代码分为2个部分：
1. 第一部分负责判断当前线程符不符合继续获得锁的条件，如果不符合则返回-1退出自旋；如果符合，则继续执行第二部分
2. 第二部分负责CAS修改同步器的状态，如果修改成功，则继续完成善后操作；如果修改失败，继续下一次循环。

<1>: 从return -1的地方可知，获取读锁会因为当前写锁不是当前线程所持有而直接返回-1。
但获取读锁允许写锁是当前线程所持有而继续尝试获得。这也就是锁降级！

<2>: 分支进入，说明写锁没有被持有，且当前线程排在其他线程后面，即sync queue中至少有一个head后继。


#### 锁降级(TODO)
一个线程持有写锁后，可以继续去持有读锁，如果在这之后，这个线程释放了写锁，那么就称写锁现在降级为了读锁。

上面这个过程，细说的话，应该分为两个部分：

1. 一个线程持有写锁后，继续去持有读锁——锁的重入。
2. 同时持有读写锁后，先释放了写锁——锁降级。



#### 公平锁与非公平锁
<mark>公平锁和非公平锁针对的对象是等待队列的首节点</mark>，刚释放锁的线程和刚被唤醒的
队列首节点线程一起去抢锁，针对队列首节点线程而言这个抢锁是否公平！

参考博客：https://blog.csdn.net/anlian523/article/details/106964711/

先看公平锁与非公平锁的定义如下：
```java
public class ReentrantReadWriteLock
        implements ReadWriteLock, java.io.Serializable {

  /**
   * 非公平锁
   */
  static final class NonfairSync extends Sync {
    private static final long serialVersionUID = -8159625535654395037L;
    final boolean writerShouldBlock() {
      return false; // writers can always barge
    }
    final boolean readerShouldBlock() {
		// 【重点：一定概率下的非公平】
      return apparentlyFirstQueuedIsExclusive();
    }
  }

  /**
   * 公平锁
   */
  static final class FairSync extends Sync {
    private static final long serialVersionUID = -2274990926593161451L;
    final boolean writerShouldBlock() {
      return hasQueuedPredecessors();
    }
    final boolean readerShouldBlock() {
      return hasQueuedPredecessors();
    }
  }
}
```
公平锁：
hasQueuedPredecessors方法与公平性息息相关，该方法很好理解，有且只有当前线程为AQS队列节点的线程才行，
也就是严格按照AQS队列节点排队，非常公平

非公平锁：
1、writerShouldBlock方法固定返回false，通过查看方法的用途，在没有锁的情况下，<mark>写锁优先读锁被获取</mark>
2、readerShouldBlock方法：<mark>在一定概率下</mark>的非公平实现，是为了防止写锁无限等待。
在一定概率下是什么意思?

理解一定概率下的非公平锁设计
![](/Users/apple/Documents/Work/aliyun-oss/dev-images/20200626092842656.jpg)
上图中，写锁节点作为head后继阻塞等待中。考虑readerShouldBlock的现有实现的话，写锁节点只需要等待线程AB释放读锁后，就可以获得到写锁了。
而线程CDE作为new reader，不会去尝试获取读锁，而是将自己包装成读锁节点排在写锁节点的后面。
```java
      //非公平实现
      final boolean readerShouldBlock() {
          return false;
      }
```
如果readerShouldBlock如以下代码这样实现的话，线程CDE即使作为new reader，因为读读不互斥，所以也会去获取到读锁。
这下好了，写锁节点需要等待线程ABCDE释放读锁后，才可以获得到写锁了。
![](/Users/apple/Documents/Work/aliyun-oss/dev-images/20200626093736980.jpg)
但尽管readerShouldBlock是这样的非公平实现，也无法防止上图第二种情况的new reader的获取读锁动作，
所以说这只是一定概率下防止new reader获取读锁，但有概率的防止总比啥都不做强


#### ReentrantReadWriteLock中读写状态计数器的设计(上文在获取读锁省略部分的补充)
ReentrantReadWriteLock针对读写计数器有以下几种方法可以使用
1. getReadLockCount(获取读锁计数)
2. <mark>getReadHoldCount(获取当前线程的读锁计数)</mark>
3. getWriteHoldCount(获取写锁计数)
4. getCount(获取锁计数)
其他3个方法没什么好说的，直接根据AQS的state高16位获取总的读锁次数、低16位获取总的写锁次数、以及锁次数，重点看下如何标黄的设计！

背景知识最好了解点方便理解：
1. 弱引用
2. ThreadLocal类
3. <a href="https://blog.csdn.net/thewindkee/article/details/103726942">ThreadLocal与弱引用</a>（gc回收时可能触发ThreadLocal的回收）

**先看下Sync的结构如下：**
```java
abstract static class Sync extends AbstractQueuedSynchronizer {
	
	Sync() {
		// 在自定义队列同步器初始化时便创建了ThreadLocalHoldCounter对象，随后该对象会被设置到每个线程的threadLocalMap的Entry中的key中，
        // 然后就可以方便的从线程取出保存的计数对象HoldCounter
		readHolds = new ThreadLocalHoldCounter();
		setState(getState()); // ensures visibility of readHolds
	}
	
	// 用来保存每个线程的读锁计数
	static final class HoldCounter {
		int count = 0;
		final long tid = getThreadId(Thread.currentThread());
	}
	
	// 自定义的ThreadLocal
	static final class ThreadLocalHoldCounter extends ThreadLocal<HoldCounter> {
		public HoldCounter initialValue() {
			return new HoldCounter();
		}
	}
    
	// 对自定义threadLocal的引用，可以根据readHolds存储技术对象，这个值从头到尾都不变。
    // 改变量的存在保证了GC不会回收threadLocal(下面会用图片说明)
	private transient ThreadLocalHoldCounter readHolds;

	// 缓存"《上一次》"的HoldCounter对象，该变量像一个指针来回在不同线程间摆动       这个缓存设计个人觉得太精益求精了有点多此一举
	private transient HoldCounter cachedHoldCounter;
}
```

**在看下之前省略的代码片段：**
```java
// java.util.concurrent.locks.ReentrantReadWriteLock.Sync.fullTryAcquireShared方法的代码片段

// 1、如果设置读状态成功
if (compareAndSetState(c, c + SHARED_UNIT)) {
	// 如下代码仅仅是为了维护每个线程的读锁次数
	
	// 2、第一个线程特殊处理
    if (r == 0) {
        firstReader = current;
        firstReaderHoldCount = 1;
    } else if (firstReader == current) {
        firstReaderHoldCount++;
    }
	
	else {
        HoldCounter rh = cachedHoldCounter;
        if (rh == null || rh.tid != getThreadId(current))
			// 3、如果缓存中没有 或者 不是当前线程，所以需要初始化把readHolds引用设置到线程的Entry中的key中
            cachedHoldCounter = rh = readHolds.get();
        else if (rh.count == 0)
			// 4、缓存中的count为0，这种情况发生在当前线程缓存的count为0下，也即lock-unlock-lock情况下
            readHolds.set(rh);
        rh.count++;     // 给线程的缓存的计数加一
    }
    return true;
}
```

最后说明下为什么ThreadLocal使用了弱引用但是不用担心在GC时被回收(此处也是回顾ThreadLocal类知识)：
直接用图来解释吧。
![](/Users/apple/Documents/Work/aliyun-oss/dev-images/2023-03-20-00-56-41-image.png)
上图中，Sync的ThreadLocalHoldCounter对象的地址0x123456被设置到不同线程的
threadLocalMap中的Entry中的key中(调用readHolds.remove()会清除引用)，
所以只有锁变量lock存在就一直有对各个线程Entry中key的强引用，发生GC时各个线程的HoldCounter对象不会被回收。

**如下是对ThreadLocal的补充：**
![](/Users/apple/Documents/Work/aliyun-oss/dev-images/20191227095609730.png)

注意正如上图，如果没有失去对ThreadLocal本身的强引用，那么不会回收threadLocal。

而我们平时代码中写的那样，<mark>使用static final修饰threadLocal保留一个全局的threadLocal方便传递其他value</mark>
（threadLocal一直被强引用）。这样就不会让gc回收 作为key的threadLocal。即不会导致key为null。
