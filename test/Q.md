有个问题想问下。正常ViewGroup拦截点击事件的时候，按照注释说的：

![[test/resources/Pasted image 20240101024555.png]]

如果在onInterceptTouchEvent()里返回false，那接下来的MOVE, UP事件也应该走这里这个方法。**RecyclerView在这里返回的是**：

```java
return mScrollState == SCROLL_STATE_DRAGGING;
```

正常情况下，第一次进来的是DOWN事件，这里返回的一定是false。然而在RecyclerView的onTouchEvent()里返回的是true。也就是说，普通的RecyclerView会自己消费这个DOWN事件。然后按照注释里框起来的所说，onInterceptTouchEvent()就不会再收到MOVE, UP事件了，而是直接走onTouchEvent()。总结下来就是，RecyclerView的：

1. onInterceptTouchEvent()拦截DOWN；
2. onTouchEvent()处理DOWN；
3. onTouchEvent()处理MOVE和UP。

我写了一个Demo，也验证了上面的流程是正确的。

但是，我发现项目里的一个RecyclerView的行为不是这样，概括来说，是这样的：

1. onInterceptTouchEvent()拦截DOWN；
2. **onInterceptTouchEvent()**拦截MOVE；
3. onTouchEvent()处理UP。

非常奇怪，明明第一次处理DOWN时返回的和自己写的Demo时一致的，但是有三处很重要的不同：

* onTouchEvent()没有处理一开始的DOWN事件；
* onInterceptTouchEvent()反而拦截了MOVE事件；
* onTouchEvent()也没有收到这个被拦截的MOVE事件。

我不知道有什么业务逻辑可以实现这一点，感到很奇怪。但是我确定应该是项目中的某些逻辑导致这个分发机制发生了改变。