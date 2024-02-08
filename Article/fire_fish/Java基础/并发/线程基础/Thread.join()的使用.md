

### join原理
含义：等待this线程死亡最多等待多久，其实就相当于this.wait(0);

理解这个方法可能存在误区，join相当于就是wait()，造成<mark>当前线程等待，而不是this线程等待</mark>

原理：
1. join方法的实现使用了(this.isAlive)条件循环，然后调用tiis.wait(0)
> Object类的wait方法造成当前线程T进入this object的"等待集合"中，并且放弃此对象的任何所有的同步声明；
2. **当this线程终止的时候，this.notifyAll方法会被调用**
> Object类的notifyAll方法造成当前线程T从this.object的"等待集合"中移出，然后可重新被线程调度器调度

举例：
```java
// 当前线程等待t1线程死亡，t1线程死亡后会调用t1.notifyAll，然后当前线程唤醒了
t1.join();

```

```java
public class Thread implements Runnable {
	/**
     * Waits for this thread to die.
     * 等同于join(0)
	 * @throws InterruptedException
	 */
	public final void join() throws InterruptedException {
		join(0);
	}


	/**
     * 当一个线程终止时，this.notifyAll会被调用
	 * @param millis
	 * @throws InterruptedException
	 */
	public final synchronized void join(long millis)
			throws InterruptedException {
		long base = System.currentTimeMillis();
		long now = 0;

		if (millis < 0) {
			throw new IllegalArgumentException("timeout value is negative");
		}

		if (millis == 0) {
			while (isAlive()) {
				wait(0);    // wait(0)表示"死等"，直到notify；当一个线程终止时会调用notifyAll方法
			}
		} else {
			while (isAlive()) {
				long delay = millis - now;
				if (delay <= 0) {
					break;
				}
				wait(delay);
				now = System.currentTimeMillis() - base;
			}
		}
	}
}
```