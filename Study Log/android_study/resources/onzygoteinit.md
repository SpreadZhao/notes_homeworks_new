```cpp
virtual void onZygoteInit()
{
	sp<ProcessState> proc = ProcessState::self();
	ALOGV("App process: starting thread pool.\n");
	proc->startThreadPool();
}
```

在ProcessState的构造方法中：

```cpp
ProcessState::ProcessState(const char* driver)
      : mDriverName(String8(driver)),
        mDriverFD(-1),
        ... ... {
    base::Result<int> opened = open_driver(driver);

    ... ...
}
```

open_driver就是打开驱动的函数，而driver这个字符串传入的时候，就是`/dev/binder`。