首先来看一段代码：

```xml
<RelativeLayout>  

    <TextView/>  
  
    <LinearLayout>  
        <TextView/>  
        <EditText/>  
    </LinearLayout> 
     
    <LinearLayout>  
        <TextView/>  
        <EditText/>  
    </LinearLayout>
      
    <LinearLayout>  
        <CheckBox/>  
        <TextView/>  
    </LinearLayout>
      
    <Button/>  
    <Button/>  
    <Button/>  
  
</RelativeLayout>
```

删掉了内部，只看轮廓。这是一个简单的登录窗口：

![[homework/Web/resources/Pasted image 20230407182942.png]]

发现，和html本质其实差不多。

安卓前端界面的实现也是靠这种静态的xml布局。在源代码中，可以使用比如findViewById这种函数，或者kotlin内置的组件，又或者最新的binding机制来得到这个前端组件对象的实例，从而编辑其中的内容。

组件，都有什么？

# 四大组件

* Activity

> 大家打开手机看一看，微信的主界面就是一个Activity，而点击联系人跳转到的聊天页面，又是另一个Activity，上面的图中就是登录界面的Activity。

* Service

> 大家打开听歌的软件播放一首歌，然后退出应用，甚至是锁屏。只要这个应用还留在后台，音乐就一直在播放，靠的就是Service。

* Broadcast Receiver

> 在B站刷视频的时候，你不停地点下面的推荐，就会刷出一个有一个Activity。这个时候如果你想要回到主界面，需要不停按返回，把之前的Activity都一一退出。但是实际上，在左上角有一个房子按钮，点一下就能回到主界面并**杀死所有已经打开的Activity**。这个功能就可以使用广播来实现。
> 
> ![[homework/Web/resources/Screenshot_20230407_190400.jpg|300]]

* Content Provider

> 我们在用输入法时，如果打出了通讯录里存的联系人，输入法自动就能提示。这个靠的就是Content Provider；另外，我们在某些笔记应用里记的电话号，点击就能拨打电话，也是靠CP将电话号从笔记应用传递到了电话应用。

# 更多组件

* Intent

> 当我们点进视频详情页的时候，会发现名字和标题加载的很快，但是头像闪了一下才加载出来。如果让我来解释的话，头像会重新发起一个网络请求，而标题和名字用Intent就可以传过来。后来测试了一下，如果用intent会有bug

* TextView
* EditText
* Button
* ListView
* RecyclerView

> 自定义Adapter，onCreateViewHolder, onBindViewHolder，getItemCount。

# 什么是布局

* LinearLayout
* RelativeLayout
* CollapsingToolbarLayout 稍后再说，在demo里

# 数据是怎么来的

* Http Request
* Retrofit
* MVVM architecture

# SpreadShop演示

# Jetpack Compose

* 介绍概念，展示Demo