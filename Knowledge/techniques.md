---
description: 要学的东西，都在这个里面。不管是安卓的，还是其它乱七八糟的，只要能想到的，都在这里面。
---
#TODO Techniques

- [ ] 这么多要学的技术，文档还没写呢！！！

- [ ] ActivityResultLauncher

[玩转ActivityResultLauncher领略设计之美 - 掘金 (juejin.cn)](https://juejin.cn/post/7181452064919126071)

[Jetpack：使用 ActivityResult 处理 Activity 之间的数据通信 - 掘金 (juejin.cn)](https://juejin.cn/post/7049158466140635173#comment)

一句话打开悬浮窗设置：

```kotlin
registerForActivityResult(ActivityResultContracts.StartActivityForResult()) {  
    if (it.resultCode == ComponentActivity.RESULT_OK &&  
        Settings.canDrawOverlays(this)) {  
        startService(  
            Intent(this, MainService::class.java)  
        )  
    }  
}.launch(  
    Intent(  
        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,  
        Uri.parse("package:$packageName")  
    )  
)
```

- [ ] Fragment

[使用标签管理 Android Fragment - 掘金 (juejin.cn)](https://juejin.cn/post/6948992343471030308)

- [ ] ActivityThread

[(39条消息) ActivityThread的理解和APP的启动过程_小河同学的博客-CSDN博客](https://blog.csdn.net/hzwailll/article/details/85339714)

- [ ] Double Check

[(41条消息) 单例模式中的double check_单例模式的doublecheck_十一月上的博客-CSDN博客](https://blog.csdn.net/xdzhouxin/article/details/81192344)

也可以使用内部类Holder来实现

- [ ] 自定义View

- [ ] try with resources

自动关闭资源

- [ ] APK大小优化

- [ ] 安全编码

- [ ] 如何把debug包和release包分开

- [ ] Executors.newSingleThreadExecutor()

[ExecutorService 看这一篇就够了 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/85696638)

- [ ] Looper idleHandler

- [ ] 悬浮窗

[Android悬浮窗看这篇就够了_android应用内悬浮窗_AndroidLMY的博客-CSDN博客](https://blog.csdn.net/qq_37750825/article/details/115754647)

[(45条消息) Android中自定义悬浮窗flagnotfocusable_淼森007的博客-CSDN博客](https://blog.csdn.net/weixin_38322371/article/details/119185227)

- [ ] Gradle添加依赖库

[添加 build 依赖项  |  Android 开发者  |  Android Developers (google.cn)](https://developer.android.google.cn/studio/build/dependencies?hl=zh-cn)

- [ ] 切换回主线程更新UI

[(45条消息) 【Android】快速切换到主线程更新UI的几种方法_da_caoyuan的博客-CSDN博客](https://blog.csdn.net/da_caoyuan/article/details/52931007)

- [ ] Gradle获取git提交记录，类似嵌入SQL语句

- [ ] Nanohttpd

[A Guide to NanoHTTPD | Baeldung](https://www.baeldung.com/nanohttpd)

- [ ] sharedUserId

- [ ] 使用ComponentName打开系统自带文件管理

- [ ] 手动杀死其他进程

forceStopPackage()

- [ ] 跑马灯

- [ ] 获取IP地址

- [ ] MVVM仓库层得到网络的结果后，调用listener的回调来实现监听

- [ ] JobScheduler

[深入理解JobScheduler与JobService的使用 - 掘金 (juejin.cn)](https://juejin.cn/post/6951224625095245861)

- [ ] ContentObserver

- [ ] Compose透明任务栏rememberSystemUiController

[(45条消息) Android Compose 透明状态栏实现_淘气章鱼哥的博客-CSDN博客](https://blog.csdn.net/qq_41899289/article/details/120290837#:~:text=%E7%9B%AE%E5%89%8D%E7%9F%A5%E9%81%93%E7%9A%84%E6%9C%89%E4%B8%A4%E7%A7%8D%EF%BC%9A%20%E7%AC%AC%E4%B8%80%E7%A7%8D%EF%BC%8C%E6%98%AF%E7%9C%8B%E6%9C%B1%E6%B1%9F%E7%9A%84demo%E9%87%8C%E7%94%A8%E7%9A%84%E6%96%B9%E6%B3%95%EF%BC%9A%20%2F%2A%2A%20%2A,%E8%AE%BE%E7%BD%AE%E9%80%8F%E6%98%8E%E7%8A%B6%E6%80%81%E6%A0%8F%20%2A%2F%20fun%20Activity.transparentStatusBar%28%29%20%7B)

[(45条消息) Android Jetpack Compose 沉浸式/透明状态栏 ProvideWindowInsets SystemUiController_YD-10-NG的博客-CSDN博客](https://blog.csdn.net/sinat_38184748/article/details/119345811)

- [ ] Kotlin单方法接口使用简化写法会改变this指向（this和this@）

- [ ] Room框架

[Room  |  Android Developers](https://developer.android.com/training/data-storage/room)

[Android Room persistance library. Drop Table - Stack Overflow](https://stackoverflow.com/questions/55226859/android-room-persistance-library-drop-table)

[使用 Room DAO 访问数据  |  Android 开发者  |  Android Developers (google.cn)](https://developer.android.google.cn/training/data-storage/room/accessing-data?hl=zh-cn#simple-queries)

- [ ] Hilt框架

[使用 Hilt 实现依赖项注入  |  Android 开发者  |  Android Developers](https://developer.android.com/training/dependency-injection/hilt-android?hl=zh-cn)

我是如何用Hilt实现在ViewModel中共享wordDao对象的？

- [ ] CopyOnWiteArrayList

- [ ] movableContent() + LookaheadLayout()实现跨页面共享数据

- [ ] startActivityForResult deprecated

- [ ] 使用filePicker实现选择多个文件

[使用“存储访问框架”打开文件  |  Android 开发者  |  Android Developers (google.cn)](https://developer.android.google.cn/guide/topics/providers/document-provider?hl=zh-cn)

[(45条消息) Android SAF（Storage Access Framework）使用攻略_android saf_残风乱了温柔的博客-CSDN博客](https://blog.csdn.net/fitaotao/article/details/112966577)

[(45条消息) Jetpack Compose中的startActivityForResult的正确姿势_川峰的博客-CSDN博客](https://blog.csdn.net/lyabc123456/article/details/128638139)

[复制和粘贴  |  Android 开发者  |  Android Developers (google.cn)](https://developer.android.google.cn/guide/topics/text/copy-paste?hl=zh-cn)

多个文件的实现是Intent中的getClipData()方法。

如何获取到得到的文件的名称？ContentResolver的cursor有一个getColumnIndex方法。里面传入OpenableColumns.DISPLAY_NAME。

- [ ] Compose传参

[Compose导航完全解析 - 掘金 (juejin.cn)](https://juejin.cn/post/7108633789051944997#comment)

[使用 Compose 进行导航  |  Jetpack Compose  |  Android Developers (google.cn)](https://developer.android.google.cn/jetpack/compose/navigation?hl=zh-cn#retrieving-complex-data)

[在目的地之间传递数据  |  Android 开发者  |  Android Developers (google.cn)](https://developer.android.google.cn/guide/navigation/navigation-pass-data?hl=zh-cn#supported_argument_types)

- [ ] Side Effects

[Jetpack Compose Side Effect：如何处理副作用 - 掘金 (juejin.cn)](https://juejin.cn/post/6930785944580653070#comment)

[可组合项的生命周期  |  Jetpack Compose  |  Android Developers (google.cn)](https://developer.android.google.cn/jetpack/compose/lifecycle?hl=zh-cn)

- [ ] PendingIntent比startForResult好，尤其是隐私密码

- [ ] 新的LifeCycle使用方法：

[@OnLifecycleEnvent 被废弃，替代方案更简单 - 掘金 (juejin.cn)](https://juejin.cn/post/7025407355093254151)

- [ ] SnapHelper在西瓜视频的用处

[让你明明白白的使用RecyclerView——SnapHelper详解 - 简书 (jianshu.com)](https://www.jianshu.com/p/e54db232df62)

- [ ] 看下图，kotlin泛型的一些东西还需要完善。还是不全捏。

![[Knowledge/resources/Pasted image 20231024152138.png]]

- [ ] #urgency/medium MultiTypeAdapter

* [MultiType-Adapter 优雅的实现RecyclerVIew中的复杂布局 - 简书 (jianshu.com)](https://www.jianshu.com/p/032a6773620b)
* [MultiTypeAdapter在recycleView中的使用和点击事件处理 - 掘金 (juejin.cn)](https://juejin.cn/post/6922799056309714952)
* [drakeet/MultiType: Flexible multiple types for Android RecyclerView. (github.com)](https://github.com/drakeet/MultiType)
* [Android 复杂的列表视图新写法 MultiType (v3.1.0 修订版) - 掘金 (juejin.cn)](https://juejin.cn/post/6844903487986204680)

- [ ] #urgency/high  西瓜视频开源的Scene，了解一下，看看能不能用Kotlin重构一下。

[bytedance/scene: Android Single Activity Applications framework without Fragment. (github.com)](https://github.com/bytedance/scene)

- [ ] #urgency/high Jupiter，西瓜内部的编译框架，**一定要研究**！

- [ ] #urgency/low Clash for Android，看起来！

- [ ] #urgency/medium  字节的资源分发系统Geckox，看起来很牛逼！

# 学习计划

原本，我想在obsidian里记录要学的具体知识点，在三星笔记里记我的todo，后来我发现，这两者的内容经常会冲突，并且有时候我也不知道我现在看到的我想学的这个东西应该记在哪里好。所以，索性我直接把完整版全部放在这里了！

## 进行中

1. 并发艺术：[[Study Log/java_study/concurrency_art|concurrency_art]]
2. fresco：[[Study Log/android_study/fresco|fresco]]
3. 毕设
4. 西电搭子

## 主要学的几个方向

1. 并发艺术
2. 飞书里的任务
3. bytetech知识地图
4. 本文档前面的那些

## 其他方向

1. 微信公众号
	- [ ] #TODO 要看看具体有哪些公众号，别放过！
	- [ ] *注意：这里的个人链接只是ta发过的一篇文章的链接*
	- [ ] Android架构师成长之路：[Weixin Official Accounts Platform (qq.com)](https://mp.weixin.qq.com/s/393u9BdmhtYKKA-PjNKX3w)
	- [ ] Kotlin社区：[Weixin Official Accounts Platform (qq.com)](https://mp.weixin.qq.com/s/b7oD937xZpwcWJePAVw2qQ)
	- [ ] 码上加油站：[Weixin Official Accounts Platform (qq.com)](https://mp.weixin.qq.com/s/SyX-HtPxECICFFnu3J_XSw)
	- [ ] 鸿洋：[Google对于开发者的一些架构建议 (qq.com)](https://mp.weixin.qq.com/s/d9Xjnr2NzM1QjWH5WpeQjw)
	- [ ] 虎哥Lovedroid：[Weixin Official Accounts Platform (qq.com)](https://mp.weixin.qq.com/s/Bdjet69579KCEbaYhK-k3g)
	- [ ] 原点技术：[mp.weixin.qq.com/s/Mm8PqPM1vULK9Yr8tOnOgg](https://mp.weixin.qq.com/s/Mm8PqPM1vULK9Yr8tOnOgg)
	- [ ] 沐雨花飞蝶：[mp.weixin.qq.com/s/6DcNIp1LL8wKBx1iQXgNpA](https://mp.weixin.qq.com/s/6DcNIp1LL8wKBx1iQXgNpA)
	- [ ] 勤奋的oyoung：[mp.weixin.qq.com/s/SzZm7jbRN_A1KoYjSHPbaQ](https://mp.weixin.qq.com/s/SzZm7jbRN_A1KoYjSHPbaQ)
	- [ ] 彬sir哥：[mp.weixin.qq.com/s/n49eZwtVYGeopzlkWjZB4w](https://mp.weixin.qq.com/s/n49eZwtVYGeopzlkWjZB4w)
	- [ ] 黄大官AOSP：[mp.weixin.qq.com/s/59oEs4v8jwbozV6Gf0WiQg](https://mp.weixin.qq.com/s/59oEs4v8jwbozV6Gf0WiQg)
	- [ ] Android 开发者：[mp.weixin.qq.com/s/W7UsoDbayGHz_Eb-rlOIMQ](https://mp.weixin.qq.com/s/W7UsoDbayGHz_Eb-rlOIMQ)
	- [ ] Android老皮：[Android开源框架面试题：谈谈Glide框架的缓存机制设计 (qq.com)](https://mp.weixin.qq.com/s/OUlP4ghB2CCC4vJe6ia6cw)
2. bytetech收藏
3. bytetech关注（主要看Client Infra团队的）
4. 深入理解kotlin协程
5. 深入探索Android热修复技术原理（sophix）
6. AndroidStudy仓库：[axjlxm/AndroidStudy: 🔥 Android学习知识点总结 Jetpack、MVVM、MVI、Kotlin、ViewPager2、JUC多线程等，欢迎star！ (github.com)](https://github.com/axjlxm/AndroidStudy)
7. #urgency/low Clash for Android代码分析
8. #urgency/medium **vim usage**
9. AndroidStudy仓库：[crazyqiang/AndroidStudy: 🔥 Android学习知识点总结 Jetpack、MVVM、MVI、Kotlin、ViewPager2、JUC多线程等，欢迎star！ (github.com)](https://github.com/crazyqiang/AndroidStudy)
10. AndroidStudy仓库：[lwjobs/AndroidStudy: just for android studio (github.com)](https://github.com/lwjobs/AndroidStudy) 这个主要是蓝牙，嵌入式的安卓方向。
11. #urgency/medium **bytetech新人培训**
12. #urgency/high 飞书群：西瓜安卓业务技术分享交流会（里面有很多分享文章）
13. Ehviewer：[Ehviewer-Overhauled/Ehviewer: EhViewer overhauled with Material Design 3, Jetpack Compose and more (github.com)](https://github.com/Ehviewer-Overhauled/Ehviewer)
14. 飞书文档的收藏