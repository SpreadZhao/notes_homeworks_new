---
description: 要学的东西，都在这个里面。不管是安卓的，还是其它乱七八糟的，只要能想到的，都在这里面。
---
> [!warning] 写在前面
> 原本，我想在obsidian里记录要学的具体知识点，在三星笔记里记我的todo。后来我发现，这两者的内容经常会冲突，并且有时候我也不知道我现在看到的我想学的这个东西应该记在哪里好。所以，索性我直接把完整版全部放在这里了！
> 
> * 分类看看就行，乱写的。主要目的是 ***==全==*** 而不是分类；
> * 只有正在进行的任务会放到[[#进行中]]

- [ ] #TODO 这么多要学的技术，文档还没写呢！！！

# Unclassified

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

- [ ] 看下图，[[Study Log/java_kotlin_study/java_kotlin_study_diary/generics_intro|kotlin泛型]]的一些东西还需要完善。还是不全捏。

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
- [ ] #urgency/high LightRx 西瓜自研的轻量级RxJava，非常有含金量！
- [ ] 多仓开发的思想
- [ ] LiveData 的设计思想
- [ ] Block框架
- [ ] ImmersiveViewHolder的预加载（ImmersiveVideoTemplate）
- [ ] gkd: [gkd-kit/gkd: 基于 无障碍 + 高级选择器 + 订阅规则 的自定义屏幕点击 Android APP (github.com)](https://github.com/gkd-kit/gkd)
- [ ] 就不多列了，所有GitHub，Gitee的star都算是
- [ ] trace的原理，为什么有的时候不准
- [ ] Compose网易云：[sskEvan/NCMusicDesktop: Compose Desktop仿写网易云桌面应用 (github.com)](https://github.com/sskEvan/NCMusicDesktop)
- [ ] 为什么RecyclerView往后面填数据的时候就不会滑动，往前面填数据的时候会自动滑倒开头？
- [ ] 点赞组件DiggComponent，还有旁边的收藏组件设计模式
- [ ] AndroidStudio官方教学
- [ ] Quick架构-性能优势与异步开发范式
- [ ] 开源阅读：[gedoor/legado: Legado 3.0 Book Reader with powerful controls & full functions❤️阅读3.0, 阅读是一款可以自定义来源阅读网络内容的工具，为广大网络文学爱好者提供一种方便、快捷舒适的试读体验。 (github.com)](https://github.com/gedoor/legado)
- [ ] Github的star里面其实都可以算。
- [ ] #urgency/high inflater的第三个参数究竟有什么用？
- [ ] plt hook, inline hook
	- [ ] [ARM64 汇编 (qq.com)](https://mp.weixin.qq.com/s/s_Z07b2RWujXhgfeSnDV5w)
- [ ] [ICU Documentation | ICU is a mature, widely used set of C/C++ and Java libraries providing Unicode and Globalization support for software applications. The ICU User Guide provides documentation on how to use ICU. (unicode-org.github.io)](https://unicode-org.github.io/icu/)
- [ ] [[Knowledge/resources/20240131_193313.jpg|面试记录-校招-王重]]
- [ ] [[Knowledge/resources/20231226_105816.jpg|面试记录-小红书高级IOS]]
- [ ] mmkv ^mmkv
	- [ ] [Tencent/MMKV: An efficient, small mobile key-value storage framework developed by WeChat. Works on Android, iOS, macOS, Windows, and POSIX. (github.com)](https://github.com/Tencent/MMKV)
	- [ ] [【面试黑洞】Android 的键值对存储有没有最优解？哔哩哔哩bilibili](https://www.bilibili.com/video/BV1FU4y197dL/?spm_id_from=333.337.search-card.all.click) （这个视频12:38，说增量式更新是性能提升不重要的原因，和薛秋实说的正好是相反的 :confused:； 另外，最后说什么dataStore用协程完全不卡，我觉得完全在扯蛋。[[Knowledge/resources/Pasted image 20240217215509.png|有个评论也是这么说的]]）
- [ ] Gradle: [Gradle 教程 已完结 (基于Kotlin DSL讲解) 4K蓝光画质 超强的脚本式项目依赖和构建工具_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1Fc411x7xF/?spm_id_from=333.1007.top_right_bar_window_custom_collection.content.click&vd_source=64798edb37a6df5a2f8713039c334afb)
- [ ] An Android critical vulnerability:
	- [ ]  [de53890aaca2ae08b3ee2d6e3fd25f702fdfa661 - platform/packages/modules/Bluetooth - Git at Google](https://android.googlesource.com/platform/packages/modules/Bluetooth/+/de53890aaca2ae08b3ee2d6e3fd25f702fdfa661)
	- [ ]  [CVE-2024-0031: Google Android att_protocol.cc attp_build_read_by_type_value_cmd out-of-bounds write](https://vuldb.com/?id.253964)
	- [ ] [In attp_build_read_by_type_value_cmd of att_protocol.cc ,... · CVE-2024-0031 · GitHub Advisory Database](https://github.com/advisories/GHSA-h32h-58mq-6fgc)
- [ ] OSTEP：[computer-science/coursepages/ostep/README.md at master · ossu/computer-science](https://github.com/ossu/computer-science/blob/master/coursepages/ostep/README.md)
- [ ] Android 动态化
- [ ] #TODO :cow:逼人的博客：[[Article/person_link|person_link]] ⏫ ➕ 2024-05-01
- [ ] fresco: [[Study Log/android_study/fresco|fresco]]
- [ ] #urgency/high 飞书任务
- [ ] #urgency/high 字节码
- [ ] 西电搭子
- [ ] 透明Activity？
- [ ] FrameLayout, LinearLayout, RelativeLayout绘制子View的流程
- [ ] LayoutInflater源码解析，vs View.inflate
- [ ] **什么时候需要用WeakReference？**
- [ ] Modern C++: [federico-busato/Modern-CPP-Programming: Modern C++ Programming Course (C++11/14/17/20/23) (github.com)](https://github.com/federico-busato/Modern-CPP-Programming)
- [ ] **互联网上的免费书**：[ruanyf/free-books: 互联网上的免费书籍 (github.com)](https://github.com/ruanyf/free-books?tab=readme-ov-file)
- [ ] Android学习路线（韩国的GDE）：[skydoves/android-developer-roadmap: 🗺 The Android Developer Roadmap offers comprehensive learning paths to help you understand Android ecosystems. (github.com)](https://github.com/skydoves/android-developer-roadmap)
- [ ] [zhanghai/ComposePreference: Preference implementation for Jetpack Compose Material 3 (github.com)](https://github.com/zhanghai/ComposePreference?tab=readme-ov-file)
- [ ] My Github stars：[Your Stars (github.com)](https://github.com/SpreadZhao?tab=stars)
- [ ] v8引擎内存申请，申请一大块，用系统的profiler看不出内存泄漏。
- [/] #TODO ConcurrentModificationException: [how to avoid ConcurrentModificationException kotlin - Stack Overflow](https://stackoverflow.com/questions/50032000/how-to-avoid-concurrentmodificationexception-kotlin) [java - ArrayList.addAll() ConcurrentModificationException - Stack Overflow](https://stackoverflow.com/questions/28088085/arraylist-addall-concurrentmodificationexception) 复现这个问题，然后说明白为什么。很重要的！！！！！ 🔺 ➕ 2024-03-06 🛫 2024-05-05

> [!todo] ConcurrentModificationException
> [[Study Log/java_kotlin_study/java_kotlin_study_diary/2024-05-05-java-kotlin-study|2024-05-05-java-kotlin-study]]

- [ ] binder：[Android系统Binder驱动分析（第5课就是第1课）_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1tW411i7aB/?spm_id_from=333.1007.top_right_bar_window_custom_collection.content.click&vd_source=64798edb37a6df5a2f8713039c334afb)
- [ ] [Tinder/Scarlet: A Retrofit inspired WebSocket client for Kotlin, Java, and Android (github.com)](https://github.com/Tinder/Scarlet)
- [ ] TTNet
- [ ] [MIT 6.S081: Operating System Engineering - CS自学指南 (csdiy.wiki)](https://csdiy.wiki/%E6%93%8D%E4%BD%9C%E7%B3%BB%E7%BB%9F/MIT6.S081/)
- [ ] 有栈协程 & 无栈协程
- [ ] SharedPreference源码要研究一下
- [ ] 强软若虚引用，深入看一看
- [ ] 图片库不能执着于fresco，还要多调研一下其它的。（最好看看字节的）
- [ ] [facebook/folly: An open-source C++ library developed and used at Facebook.](https://github.com/facebook/folly) 无锁环形队列
- [ ] litho拍平视图：[facebook/litho: A declarative framework for building efficient UIs on Android.](https://github.com/facebook/litho)
- [ ] 各个语言对于lambda内变量的捕获：[How Kotlin lambda capture variable | by yawei | Medium](https://medium.com/@yangweigbh/how-kotlin-lambda-capture-variable-ef90e11e531d#id_token=eyJhbGciOiJSUzI1NiIsImtpZCI6ImFkZjVlNzEwZWRmZWJlY2JlZmE5YTYxNDk1NjU0ZDAzYzBiOGVkZjgiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiIyMTYyOTYwMzU4MzQtazFrNnFlMDYwczJ0cDJhMmphbTRsamRjbXMwMHN0dGcuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiIyMTYyOTYwMzU4MzQtazFrNnFlMDYwczJ0cDJhMmphbTRsamRjbXMwMHN0dGcuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMDQ2MjIyMDYwMDQ1OTM4Mzc5MjUiLCJlbWFpbCI6InNwcmVhZHpoYW9AZ21haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsIm5iZiI6MTcxMTM0OTEyOCwibmFtZSI6IlNwcmVhZCBaaGFvIiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0lpXzhPYkctU0Fyc1JtQUtPR3ZFcFZjd2hhZXAxclpsbTl3ZFFlM1M2b3pRPXM5Ni1jIiwiZ2l2ZW5fbmFtZSI6IlNwcmVhZCIsImZhbWlseV9uYW1lIjoiWmhhbyIsImlhdCI6MTcxMTM0OTQyOCwiZXhwIjoxNzExMzUzMDI4LCJqdGkiOiIzZWEwZDE2NzQ1OGE5ODgzZmI3ZjcwNGU5Yjk2YmY4ZGUwNTJiZTY1In0.iuX7VLxACdhmAAAtxCgC7vBvEs7dgTJ9Fs0JRUuX_251z3OG-6QYK9rnJuN6CYpbg0pGAovdUHcwig7aB3IV_ufFB3WCI0id767itfz-sTlOXOf_S54X0HhlJx8RH7ZhSjdWH2hiUwxLAhTPhOwno0uNw8AKi5ObSxEOH4Q6T0yiIzBCi8tqMcIaN0-Dh2oamYeML6SILfJqrwYeMtw8L532RADnCDvWQhVQE3a9JRURr1_Npq1myjpNDrD_ROjeaM55e5BDkcuR6DJ3UQFFgczQ5yBbIpBtxUEHly0e6hFrxQ61Xvm3nyk20MAh75RFOzJhaQpNVroSYfjQJtbkiA)
- [ ] 内存踩踏是什么？？？
- [ ] [MIT 6.824: Distributed System - CS自学指南](https://csdiy.wiki/%E5%B9%B6%E8%A1%8C%E4%B8%8E%E5%88%86%E5%B8%83%E5%BC%8F%E7%B3%BB%E7%BB%9F/MIT6.824/)
- [ ] [绿导师原谅你了的个人空间-绿导师原谅你了个人主页-哔哩哔哩视频](https://space.bilibili.com/202224425/channel/collectiondetail?sid=2237004&spm_id_from=333.788.0.0) 南京大学 蒋炎岩 操作系统
- [ ] [谭玉刚的个人空间-谭玉刚个人主页-哔哩哔哩视频 (bilibili.com)](https://space.bilibili.com/41036636) 主要讲UEFI，CS和OS的基础知识。
- [ ] [android/architecture-samples: A collection of samples to discuss and showcase different architectural tools and patterns for Android apps.](https://github.com/android/architecture-samples) 官方的案例，比如讲Hilt之类的例子，应用到具体应用上。

# Classified

## 进行中

- [/] #TODO 并发艺术：[[Study Log/java_kotlin_study/concurrency_art|concurrency_art]] ➕ 2024-01-01 🛫 2024-01-01
- [x] #TODO  毕设 ➕ 2023-12-01 🛫 2023-12-01 ✅ 2024-06-04
- [/] #TODO keva ➕ 2024-03-20 🛫 2024-03-20
- [/] #TODO RTC程序设计 ➕ 2024-03-20 🛫 2024-03-20 

## 计划

1. WebRTC
	1. [Android WebRTC完整入门教程01: 使用相机 - 简书](https://www.jianshu.com/p/eb5fd116e6c8)
	2. [GetStream/webrtc-android: 🛰️ A versatile WebRTC pre-compiled Android library that reflects the recent WebRTC updates to facilitate real-time video chat for Android and Compose.](https://github.com/GetStream/webrtc-android)
	3. [ddssingsong/webrtc_android: webrtc VideoCall VideoConference 视频通话 视频会议 (github.com)](https://github.com/ddssingsong/webrtc_android)
2. 音视频
	1. 安卓Native音视频介绍：Android系统攻城狮（公众号，这人要出书）
	2. media3
	3. [音视频并不难学，保姆级别音视频就业路线详解，进来看看适不适合你_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1xi4y1Y7U2/?spm_id_from=333.1007.top_right_bar_window_custom_collection.content.click&vd_source=64798edb37a6df5a2f8713039c334afb)
	4. Bytetech
	5. [0voice/audio_video_streaming: 音视频流媒体权威资料整理，500+份文章，论文，视频，实践项目，协议，业界大神名单。 (github.com)](https://github.com/0voice/audio_video_streaming)
	6. Android系统攻城狮出的书
	7. RTC程序设计 - 实时音视频权威指南
	8. [FFmpeg原理介绍 · FFmpeg原理](https://ffmpeg.xianwaizhiyin.net/)
3. 稳定性：KOOM为主，matrix，知识地图里的课程
4. hook
	1. Lancet
	2. codelocator
	3. gradle插庄（jupiter之类的都算）
5. 端智能
6. 插件：mira
7. 虚拟机
	1. [Crafting Interpreters](https://craftinginterpreters.com/)
		1. [munificent/craftinginterpreters: Repository for the book "Crafting Interpreters" (github.com)](https://github.com/munificent/craftinginterpreters)
	2. hotspot
	3. GC
8. 浏览器
	1. [How browsers work (taligarsiel.com)](https://taligarsiel.com/Projects/howbrowserswork1.htm)
	2. webkit
	3. chromium
	4. [Servo, the embeddable, independent, memory-safe, modular, parallel web rendering engine](https://servo.org/)
9. gaming
	1. [Game Programming Patterns](https://gameprogrammingpatterns.com/)

## 字节跳动

### 杂项

* 包大小：PK150
* Slardar
* Lancet
* quality和apm两个质量保证的库
* 插件化：mira
* 基础技术
	* milo
	* Tiktok基础技术
* ABLock in Xigua
* keva vs [[#^mmkv|mmkv]]
* 西瓜ServiceManager
* 抓包工机具使用
	* Charles
	* Wireshark
	* 任意门原理（bytetech视频）
* Handler消息屏障，在onCreate中能获得View宽高？
* PriorityLinearLayout
* 把Spread-All in One搬过来
* TaskInfo怎么存的
* xg_library
* 置顶的所有
	* 西瓜视频Android技术交流会
	* ByteTech
	* 视频会议
	* 抖音客户端技术论坛

### Spread - All in One

- [ ] #TODO tasktodo1715588821510 Spread - All in One!!! 🔼 ➕ 2024-05-13

## 主要学的几个方向

1. 并发艺术
2. 飞书里的任务
3. bytetech知识地图
4. 本文档前面的那些

## Pieces

- [x] #TODO Pieces中的东西需要尽快开始！ 🔺 ➕ 2024-03-20 ✅ 2024-08-06

> Pieces中的东西，不需要尽快开始了。麻痹的这种东西写了也没鸡毛用。

- [ ] [Android源码之为什么onResume方法中不可以获取View宽高 (qq.com)](https://mp.weixin.qq.com/s?__biz=MzA5MzI3NjE2MA==&mid=2650282000&idx=1&sn=308009a6837b2b56499ff24efd05c65f&chksm=8967c946a6dcea987c7461ac8378014a40d62ed51911ca5f7281bd90a00a7db43c55f1215d82&sessionid=1709048662&scene=126&subscene=91&clicktime=1709048669&enterid=1709048669&ascene=3&fasttmpl_type=0&fasttmpl_fullversion=7094201-zh_CN-zip&fasttmpl_flag=0&realreporttime=1709048669826&devicetype=android-34&version=28002c51&nettype=WIFI&abtest_cookie=AAACAA%3D%3D&lang=zh_CN&session_us=gh_15d5aef889d8&countrycode=TT&exportkey=n_ChQIAhIQoisFznaI817TKOrbESls%2BRLrAQIE97dBBAEAAAAAAL9vE2tkl2AAAAAOpnltbLcz9gKNyK89dVj0JFP4t%2FkbU2PJ%2FFwmb0kzLhFk7sxxw%2Fdyrzrc0tRlDCorTCGYWANY2qAFhCvDxToCADWucM5K26F%2FzWphGuby34Dyqgq5hY236kcfK4WgPsW8DA2xQsUoZe%2BKXg2MP3SUMBVtpsRPiSaunvoFaI5WJ6hxB0eeHxRgSmZunizu%2F38IyLtNhRy7BqZidLdaYuH7GRN4WU7QeVXO%2BMKjyYNTd4zbUckAizpfCdzSMBamiQfaW62lGhZ1KPH%2FJtDl52GRucZcf7c%3D&pass_ticket=YVI%2F84rfE0k1efSZNZiWSLrVH8an0ObiTSckHWfnmCUzQQjHnD0%2FUTbyV4XqyBSR1wH2kfHgy5daCKSmROiIoQ%3D%3D&wx_header=3)
- [ ] [一个 App 会创建多少个 Application 对象](https://mp.weixin.qq.com/s?__biz=MzUxMTUwOTcyMA==&mid=2247491484&idx=2&sn=f318575a3c151dc790badac33b288b3b&chksm=f973ca2bce04433df8d6615a22ffa302fdedbdfcb09781c2b4ab086bbf959832a3d86196fe55&mpshare=1&scene=23&srcid=02295oDc1i2zLY884k7ZpklY&sharer_shareinfo=5a96ec99a3e2311d5e735a4d4cae324a&sharer_shareinfo_first=5a96ec99a3e2311d5e735a4d4cae324a#rd)
- [ ] [大揭秘，Android Flow面试官最爱问的7个问题](https://mp.weixin.qq.com/s?__biz=MzAxMTI4MTkwNQ==&mid=2650852124&idx=1&sn=13eaab494b373697e1adc99aeeb4302c&chksm=80b71f82b7c09694176341c11e3254f7328eec8a49cf37698c20954417a9f9420a8002c6c9d8&mpshare=1&scene=23&srcid=0229xdLd4bBtsVaUaUvPXpyU&sharer_shareinfo=17c881531700d528267d4b2f9fae9b16&sharer_shareinfo_first=17c881531700d528267d4b2f9fae9b16#rd)
- [ ] [万字解析Android Handler实现原理 - 掘金 (juejin.cn)](https://juejin.cn/post/7326080299943280680)
- [ ] [why kotlin by lazy can cause memory leak in android? - Stack Overflow](https://stackoverflow.com/questions/51718733/why-kotlin-by-lazy-can-cause-memory-leak-in-android)
- [ ] [另一种绕过 Android P以上非公开API限制的办法 | Weishu's Notes](https://weishu.me/2019/03/16/another-free-reflection-above-android-p/)
- [ ] [LoveSyKun - 一个通用的纯 Java 安卓隐藏 API 限制绕过方案](https://lovesykun.cn/archives/android-hidden-api-bypass.html)
- [ ] [c++ - What's the difference between constexpr and const? - Stack Overflow](https://stackoverflow.com/questions/14116003/whats-the-difference-between-constexpr-and-const)
- [ ] [破解 Android P 对隐藏Api访问的限制 - 灰色飘零 - 博客园](https://www.cnblogs.com/renhui/p/14214996.html)
- [ ] 所有仓库里注释里的todo
- [ ] 日记：分析横屏请求请求数据降低，修改snap分发逻辑。
- [ ] SpreadAndroidStudy之后全部归档
- [/] #TODO 到底为什么不能在子线程更新UI？ 🔺 ➕ 2024-04-10 🛫 2024-08-22 
	- [ ] [Android在子线程更新View](https://mp.weixin.qq.com/s/PL_mFVQ7ax82YhmKkNQAYQ)
	- [ ] 之后把这些东西更新到一个android diary里。
- [ ] [wurensen/TaskScheduler: 基于Kotlin协程以及DAG（有向无环图）实现的Android任务调度框架，可以根据任务间的依赖关系进行调度。 (github.com)](https://github.com/wurensen/TaskScheduler)
- [ ] [kpali/wolf-flow: wolf-flow是一个简单的、支持有向无环图（DAG）的轻量级作业调度引擎 (github.com)](https://github.com/kpali/wolf-flow)
- [ ] 为什么 Interface 里的方法必须是 public 的？
- [ ] 日记：谁的职责就写在谁的类里。FeedFpsSettings.sampleForVideoPlay判断，是block中了实验才加listener而不是director通过实验判断是否应该加listener
- [ ] pdd攻击分享总结一下
- [ ] #TODO work diary 回滚 经常记录产出 工作日记同步 ➕ 2024-04-18 🔼 
- [ ] #TODO 组合优于继承，有时候你加一个方法，只能在接口里加，导致很多子类有很多空实现。 ➕ 2024-04-18 🔼 
- [ ] #TODO viewtreeobserver的scroll在首刷的时候会触发吗？ ➕ 2024-04-19 🔼 
- [ ] #TODO View.post do what? ➕ 2024-04-22 ⏫ 
- [ ] #TODO [从一次实际经历来说说IdleHandler的坑 - 掘金 (juejin.cn)](https://juejin.cn/post/6936440588635996173) ➕ 2024-04-24 ⏫ 
- [ ] [[TODO/todos|todos]]
- [ ] #TODO tasktodo1722531383729 如何不占用系统状态栏 & 调研SurfaceFlinger是怎么合成状态栏的。 ➕ 2024-08-02 🔼 🆔 z1trn5
	- [ ] [SurfaceFlinger 图层合成过程分析上 (qq.com)](https://mp.weixin.qq.com/s/J6oyAIsz-kbSllsVd0TGxw)
- [ ] #TODO tasktodo1722531423113 西瓜的OOM检测原理。native和java都看。 ➕ 2024-08-02 ⏫ 🆔 grvai7
- [/] #TODO tasktodo1722531454096 开发debug工具在spreadlib，摇一摇打印日志。 ➕ 2024-08-02 🔺 🆔 0cqkq9 🛫 2024-08-23 
- [ ] #TODO tasktodo1722531892427 RecyclerView onFling的时候，子View的属性如何？尤其是visibility？这个写到rv的学习目录里，就是毕设的那个。 ➕ 2024-08-02 🔺 🆔 cz51hx
- [ ] #TODO tasktodo1722531948117 c++的两个踩坑视频： ➕ 2024-08-02 🔼 🆔 ghn6oy
	- [ ] [C++：指针生而自由。Rust：麻了_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1uK421v7Ub/?spm_id_from=333.999.0.0)
	- [ ] [C++：引用不能瞎用！Rust：我笑死_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1bu4m1M74A/?spm_id_from=333.999.0.0)
	- [ ] 学C++一定要多犯错误，不要不敢写，写的再狗屎，也是给之后打基础。
- [ ] #TODO tasktodo1722610175504 西瓜的DBData是怎么实现的。 ➕ 2024-08-02 ⏫ 🆔 540bvg
- [ ] #TODO tasktodo1722878403244 西瓜启动框架分析。飞鼠文档里有。我记得是Task和一个Taskxxx来着。 ➕ 2024-08-06 ⏫ 🆔 ckzlk5
- [ ] #TODO tasktodo1722878444046 单例模式大全。所有单例模式都是怎么写的。【Java 进阶一定要读的书是哪本？】 【精准空降到 02:47】 https://www.bilibili.com/video/BV1VM4m1S7Jv/?share_source=copy_web&vd_source=e9e5bdd775043518f43e2e425553d7e9&t=167 ➕ 2024-08-06 🔺 🆔 kasqlf
- [ ] #TODO tasktodo1722878583685 整理公众号相关的东西。这是公众号相关的一个小任务。 ➕ 2024-08-06 🔺 🆔 u3brzu
	- [ ] 自定义View相关公众号：[Android 自定义 View 高仿飞书日历 (qq.com)](https://mp.weixin.qq.com/s/c_D_BzEYFFugvPHmmSDxDw)
	- [ ] ViewPager：[5年了，ViewPager2 终于支持 overScrollMode，没错，我干的。 (qq.com)](https://mp.weixin.qq.com/s/evFfPZ02xCb8ViQ7sOGmDw)
	- [ ] 给公众号分一个类吧哥。不能光攒不看啊！
- [/] #TODO tasktodo1723039760161 西瓜标题组件，世辉写的组件的文档里遇到的踩坑总结上。并且把这个组件抽出来变成AsyncSpannable。 🆔 7bq01j 🔺 ➕ 2024-08-07 🛫 2024-08-11
- [ ] #TODO tasktodo1723283820042 抖音客户端技术论坛里有很多干货，狠狠冲！ ➕ 2024-08-10 🔺 🆔 oxhbiv
- [ ] #TODO tasktodo1723649618998 TTExecutor in Xigua ➕ 2024-08-14 ⏫ 🆔 4jifms
- [ ] #TODO tasktodo1724250510907 pintos: [Pintos Projects: Table of Contents](https://web.stanford.edu/class/cs140/projects/pintos/pintos.html) ➕ 2024-08-21 🔽 🆔 eivkfq
- [ ] #TODO tasktodo1725548165776 西瓜视频基础产品的周会，每个周会有个小讨论。里面的技术点可以学一学。比如之前就介绍过抖音的一个hook方案，排查一个npe的bug ➕ 2024-09-05 ⏫ 🆔 0w0gwj 
- [ ] #TODO tasktodo1725548220142 wx公众号，动态线程池。这个可以合到[[Study Log/java_kotlin_study/concurrency_art/9_threadpool|9_threadpool]]里面。 [美团二面拷打：如何设计一个动态线程池？](https://mp.weixin.qq.com/s?__biz=Mzg2OTA0Njk0OA==&mid=2247545457&idx=1&sn=e943871bdcdb4e47e9bfafb3d1ddc546&chksm=cf663654bcf8f505dadfb7cf09c10cc9f237af9708f08359420cae84155732733c954bb16fdb#rd) ➕ 2024-09-05 ⏫ 🆔 dyb7pi 
- [ ] #TODO tasktodo1725548355191 最近处理了一个创作相关的内存泄漏。确实，kotlin的let和apply还有一个之前没考虑过的区别。说一说。 ➕ 2024-09-05 🔺 🆔 ctwy5c 

## 其他方向

### 微信公众号

- [/] #TODO 要看看具体有哪些公众号，别放过！ 🛫 1999-01-01
- [ ] *注意：这里的个人链接只是ta发过的一篇文章的链接*
- [ ] Android架构师成长之路：[Weixin Official Accounts Platform (qq.com)](https://mp.weixin.qq.com/s/393u9BdmhtYKKA-PjNKX3w)
- [ ] **Kotlin社区**：[Weixin Official Accounts Platform (qq.com)](https://mp.weixin.qq.com/s/b7oD937xZpwcWJePAVw2qQ)
- [ ] 码上加油站：[Weixin Official Accounts Platform (qq.com)](https://mp.weixin.qq.com/s/SyX-HtPxECICFFnu3J_XSw)
- [ ] 鸿洋：[Google对于开发者的一些架构建议 (qq.com)](https://mp.weixin.qq.com/s/d9Xjnr2NzM1QjWH5WpeQjw)
- [ ] 虎哥Lovedroid：[Weixin Official Accounts Platform (qq.com)](https://mp.weixin.qq.com/s/Bdjet69579KCEbaYhK-k3g)
- [ ] 原点技术：[mp.weixin.qq.com/s/Mm8PqPM1vULK9Yr8tOnOgg](https://mp.weixin.qq.com/s/Mm8PqPM1vULK9Yr8tOnOgg)
- [ ] 沐雨花飞蝶：[mp.weixin.qq.com/s/6DcNIp1LL8wKBx1iQXgNpA](https://mp.weixin.qq.com/s/6DcNIp1LL8wKBx1iQXgNpA)
- [ ] **勤奋的oyoung**：[mp.weixin.qq.com/s/SzZm7jbRN_A1KoYjSHPbaQ](https://mp.weixin.qq.com/s/SzZm7jbRN_A1KoYjSHPbaQ)
- [ ] 每日面试题非常好
- [ ] **彬sir哥**：[mp.weixin.qq.com/s/n49eZwtVYGeopzlkWjZB4w](https://mp.weixin.qq.com/s/n49eZwtVYGeopzlkWjZB4w)
- [ ] 有很多比如自定义View的编程实战
- [ ] 黄大官AOSP：[mp.weixin.qq.com/s/59oEs4v8jwbozV6Gf0WiQg](https://mp.weixin.qq.com/s/59oEs4v8jwbozV6Gf0WiQg)
- [ ] **Android 开发者**：[mp.weixin.qq.com/s/W7UsoDbayGHz_Eb-rlOIMQ](https://mp.weixin.qq.com/s/W7UsoDbayGHz_Eb-rlOIMQ)
- [ ] 开发者说DTalk
- [ ] Android老皮：[Android开源框架面试题：谈谈Glide框架的缓存机制设计 (qq.com)](https://mp.weixin.qq.com/s/OUlP4ghB2CCC4vJe6ia6cw)
- [ ] 群英传：[真•文本环绕问题的探究和分享 (qq.com)](https://mp.weixin.qq.com/s/6IHsfp9SiG1tVgyFwCccIw)
- [ ] 混沌致知
- [ ] 技术基本功修炼
- [ ] 字节流动
- [ ] 北院的牛顿
- [ ] DFIR
- [ ] 硬核物理
- [ ] 稀有猿诉
- [ ] 徐公
- [ ] 千里马学框架
- [ ] 网易云音乐技术团队
- [ ] 鸿洋
- [ ] 古哥E下
- [ ] 千里马学框架
- [ ] GSYTech
- [ ] 我怀里的猫
- [ ] 代码说
- [ ] TechMerger
- [ ] 悖论的技术小屋
- [ ] AndroidPub
- [ ] 稀土掘金技术社区
- [ ] Android茶话会
- [ ] Android补给站
- [ ] 51CTO技术栈
- [ ] 阿豪讲framework
- [ ] Rust学习日记
- [ ] **牛晓伟**：Framework
- [ ] 网易传媒技术团队
- [ ] 大前端开发入门
- [ ] Germen的编码日记
- [ ] OPPO安珀实验室
- [ ] **Android系统攻城狮**
- [ ] AndroidPerformance
- [ ] 二进制磨剑
- [ ] ZZH的Android
- [ ] 梦兽编程
- [ ] 张可
- [ ] 程序员Android
- [ ] 腾讯音乐技术团队
- [ ] 日拱一题
- [ ] Android施行
- [ ] 敲行代码再睡觉
- [ ] 老伯伯软件站
- [ ] 老蒋出马
- [ ] 虎哥LoveOpenSource
- [ ] 字节忍者
- [ ] java小白翻身
- [ ] BennuCTech
- [ ] 逆向与采集
- [ ] 三翼鸟数字化科技
- [ ] JavaBuild888
- [ ] 终码一生
- [ ] 雨乐聊编程
- [ ] 王小二的技术栈
- [ ] 三翼鸟数字化科技
- [ ] 程序员陆业聪
- [ ] 11来了
- [ ] Android技术之家
- [ ] 神兽小白
- [ ] 深度Linux

- [ ] #TODO 最近微信收藏的文章都要看看！ ⏫

1. bytetech关注和**收藏**（主要看Client Infra团队的）
2. 深入理解kotlin协程
3. 深入探索Android热修复技术原理（sophix）
4. AndroidStudy仓库：[axjlxm/AndroidStudy: 🔥 Android学习知识点总结 Jetpack、MVVM、MVI、Kotlin、ViewPager2、JUC多线程等，欢迎star！ (github.com)](https://github.com/axjlxm/AndroidStudy)
5. #urgency/low Clash for Android代码分析
6. #urgency/medium **vim usage**
7. AndroidStudy仓库：[crazyqiang/AndroidStudy: 🔥 Android学习知识点总结 Jetpack、MVVM、MVI、Kotlin、ViewPager2、JUC多线程等，欢迎star！ (github.com)](https://github.com/crazyqiang/AndroidStudy)
8. AndroidStudy仓库：[lwjobs/AndroidStudy: just for android studio (github.com)](https://github.com/lwjobs/AndroidStudy) 这个主要是蓝牙，嵌入式的安卓方向。
9. #urgency/medium **bytetech新人培训**
10. #urgency/high 飞书群：西瓜安卓业务技术分享交流会（里面有很多分享文章） #date 2024-02-01 现在该名字叫西瓜视频Android技术交流会
11. Ehviewer：[Ehviewer-Overhauled/Ehviewer: EhViewer overhauled with Material Design 3, Jetpack Compose and more (github.com)](https://github.com/Ehviewer-Overhauled/Ehviewer)
12. 飞书文档的收藏
13. #urgency/medium obsidian todo
14. [JetBrains/compose-multiplatform-ios-android-template: Compose Multiplatform iOS+Android Application project template (github.com)](https://github.com/JetBrains/compose-multiplatform-ios-android-template)
15. [running-libo/Tiktok: 高仿抖音APP (github.com)](https://github.com/running-libo/Tiktok)
16. #urgency/high Rust：[欢迎来到 Comprehensive Rust 🦀 - Comprehensive Rust 🦀 (google.github.io)](https://google.github.io/comprehensive-rust/zh-CN/)
17. #urgency/low 当时NIO的那些录屏。
18. #urgency/high bytetech机器人
19. #urgency/high ==***想进Infra，狠狠学字节码***==！

# Others

* [[Study Log/android_study/aa_android_study_outline|aa_android_study_outline]]
* [[Study Log/java_kotlin_study/aa_java_study|aa_java_study]]
* [[Study Log/java_kotlin_study/aa_kotlin_study|aa_kotlin_study]]