```java
// 这个是BaseHandler
public abstract class BaseHandler<T> extends Handler {
    private final WeakReference<T> mWeakReference; //弱引用

    protected BaseHandler(T t) {
        mWeakReference = new WeakReference<T>(t);
    }

    protected abstract void handleMessage(T t, Message msg);

    @Override
    public void handleMessage(Message msg) {
        super.handleMessage(msg);
        if (mWeakReference == null) {
            return;
        }

        T t = mWeakReference.get();
        if (t != null) {
            handleMessage(t, msg);
        }
    }
}

//然后在某个Activity中使用
private static class H extends BaseHandler<XuruiActivity> { //静态的内部类哦
	public H(XuruiActivity activity) {
		super(activity);
	}
	
	@Override
	protected void handleMessage(XuruiActivity activity, Message msg) {
		//do something
	}
}

//同时Activity的onDestroy函数取消掉所有消息
@Override
protected void onDestroy() {
    mMyHandler.removeCallbacksAndMessages(null);
    super.onDestroy();
}
```