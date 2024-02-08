```java
Message next() {
    ···
    for (;;) {
        //1:阻塞操作，当等待nextPollTimeoutMillis时长，或者消息队列被唤醒，都会返回 
        nativePollOnce(ptr, nextPollTimeoutMillis);
        ···
        synchronized (this) {
           //获取消息
            ···
        }

        // 此时没有信息需要处理就跑到这里
        for (int i = 0; i < pendingIdleHandlerCount; i++) {
            final IdleHandler idler = mPendingIdleHandlers[i];
            mPendingIdleHandlers[i] = null; // release the reference to the handler

            boolean keep = false;
            try {
                keep = idler.queueIdle(); //1
            } catch (Throwable t) {
                Log.wtf(TAG, "IdleHandler threw exception", t);
            }

            if (!keep) {
                synchronized (this) {
                    mIdleHandlers.remove(idler);
                }
            }
        }
        ...
    }
}
```