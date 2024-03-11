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

- [ ] 看下图，[[Study Log/java_kotlin_study/generics/generics_intro|kotlin泛型]]的一些东西还需要完善。还是不全捏。

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
- [ ] :luc_camera: [[Knowledge/resources/20240131_193313.jpg|面试记录-校招-王重]]
- [ ] :luc_camera: [[Knowledge/resources/20231226_105816.jpg|面试记录-小红书高级IOS]]
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
- [ ] #urgency/medium :cow:逼人的博客：[[Article/person_link|person_link]]
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
- [ ] #TODO ConcurrentModificationException: [how to avoid ConcurrentModificationException kotlin - Stack Overflow](https://stackoverflow.com/questions/50032000/how-to-avoid-concurrentmodificationexception-kotlin) [java - ArrayList.addAll() ConcurrentModificationException - Stack Overflow](https://stackoverflow.com/questions/28088085/arraylist-addall-concurrentmodificationexception) 复现这个问题，然后说明白为什么。很重要的！！！！！ 🔺 ➕ 2024-03-06
- [ ] binder：[Android系统Binder驱动分析（第5课就是第1课）_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1tW411i7aB/?spm_id_from=333.1007.top_right_bar_window_custom_collection.content.click&vd_source=64798edb37a6df5a2f8713039c334afb)
- [ ] [Tinder/Scarlet: A Retrofit inspired WebSocket client for Kotlin, Java, and Android (github.com)](https://github.com/Tinder/Scarlet)
- [ ] TTNet
- [ ] [MIT 6.S081: Operating System Engineering - CS自学指南 (csdiy.wiki)](https://csdiy.wiki/%E6%93%8D%E4%BD%9C%E7%B3%BB%E7%BB%9F/MIT6.S081/)
- [ ] 有栈协程 & 无栈协程

# Classified

## 进行中

- [/] #TODO 并发艺术：[[Study Log/java_kotlin_study/concurrency_art|concurrency_art]] ➕ 2024-01-01 🛫 2024-01-01
- [/] #TODO  毕设 ➕ 2023-12-01 🛫 2023-12-01

## 字节跳动

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

## 主要学的几个方向

1. 并发艺术
2. 飞书里的任务
3. bytetech知识地图
4. 本文档前面的那些

## Pieces

- [ ] [Android源码之为什么onResume方法中不可以获取View宽高 (qq.com)](https://mp.weixin.qq.com/s?__biz=MzA5MzI3NjE2MA==&mid=2650282000&idx=1&sn=308009a6837b2b56499ff24efd05c65f&chksm=8967c946a6dcea987c7461ac8378014a40d62ed51911ca5f7281bd90a00a7db43c55f1215d82&sessionid=1709048662&scene=126&subscene=91&clicktime=1709048669&enterid=1709048669&ascene=3&fasttmpl_type=0&fasttmpl_fullversion=7094201-zh_CN-zip&fasttmpl_flag=0&realreporttime=1709048669826&devicetype=android-34&version=28002c51&nettype=WIFI&abtest_cookie=AAACAA%3D%3D&lang=zh_CN&session_us=gh_15d5aef889d8&countrycode=TT&exportkey=n_ChQIAhIQoisFznaI817TKOrbESls%2BRLrAQIE97dBBAEAAAAAAL9vE2tkl2AAAAAOpnltbLcz9gKNyK89dVj0JFP4t%2FkbU2PJ%2FFwmb0kzLhFk7sxxw%2Fdyrzrc0tRlDCorTCGYWANY2qAFhCvDxToCADWucM5K26F%2FzWphGuby34Dyqgq5hY236kcfK4WgPsW8DA2xQsUoZe%2BKXg2MP3SUMBVtpsRPiSaunvoFaI5WJ6hxB0eeHxRgSmZunizu%2F38IyLtNhRy7BqZidLdaYuH7GRN4WU7QeVXO%2BMKjyYNTd4zbUckAizpfCdzSMBamiQfaW62lGhZ1KPH%2FJtDl52GRucZcf7c%3D&pass_ticket=YVI%2F84rfE0k1efSZNZiWSLrVH8an0ObiTSckHWfnmCUzQQjHnD0%2FUTbyV4XqyBSR1wH2kfHgy5daCKSmROiIoQ%3D%3D&wx_header=3)
- [ ] [一个 App 会创建多少个 Application 对象](https://mp.weixin.qq.com/s?__biz=MzUxMTUwOTcyMA==&mid=2247491484&idx=2&sn=f318575a3c151dc790badac33b288b3b&chksm=f973ca2bce04433df8d6615a22ffa302fdedbdfcb09781c2b4ab086bbf959832a3d86196fe55&mpshare=1&scene=23&srcid=02295oDc1i2zLY884k7ZpklY&sharer_shareinfo=5a96ec99a3e2311d5e735a4d4cae324a&sharer_shareinfo_first=5a96ec99a3e2311d5e735a4d4cae324a#rd)
- [ ] [大揭秘，Android Flow面试官最爱问的7个问题](https://mp.weixin.qq.com/s?__biz=MzAxMTI4MTkwNQ==&mid=2650852124&idx=1&sn=13eaab494b373697e1adc99aeeb4302c&chksm=80b71f82b7c09694176341c11e3254f7328eec8a49cf37698c20954417a9f9420a8002c6c9d8&mpshare=1&scene=23&srcid=0229xdLd4bBtsVaUaUvPXpyU&sharer_shareinfo=17c881531700d528267d4b2f9fae9b16&sharer_shareinfo_first=17c881531700d528267d4b2f9fae9b16#rd)
- [ ] [万字解析Android Handler实现原理 - 掘金 (juejin.cn)](https://juejin.cn/post/7326080299943280680)
- [ ] [why kotlin by lazy can cause memory leak in android? - Stack Overflow](https://stackoverflow.com/questions/51718733/why-kotlin-by-lazy-can-cause-memory-leak-in-android)

## 未来方向

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
9. gaming
	1. [Game Programming Patterns](https://gameprogrammingpatterns.com/)

## 其他方向

1. 微信公众号
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
2. bytetech关注和**收藏**（主要看Client Infra团队的）
3. 深入理解kotlin协程
4. 深入探索Android热修复技术原理（sophix）
5. AndroidStudy仓库：[axjlxm/AndroidStudy: 🔥 Android学习知识点总结 Jetpack、MVVM、MVI、Kotlin、ViewPager2、JUC多线程等，欢迎star！ (github.com)](https://github.com/axjlxm/AndroidStudy)
6. #urgency/low Clash for Android代码分析
7. #urgency/medium **vim usage**
8. AndroidStudy仓库：[crazyqiang/AndroidStudy: 🔥 Android学习知识点总结 Jetpack、MVVM、MVI、Kotlin、ViewPager2、JUC多线程等，欢迎star！ (github.com)](https://github.com/crazyqiang/AndroidStudy)
9. AndroidStudy仓库：[lwjobs/AndroidStudy: just for android studio (github.com)](https://github.com/lwjobs/AndroidStudy) 这个主要是蓝牙，嵌入式的安卓方向。
10. #urgency/medium **bytetech新人培训**
11. #urgency/high 飞书群：西瓜安卓业务技术分享交流会（里面有很多分享文章） #date 2024-02-01 现在该名字叫西瓜视频Android技术交流会
12. Ehviewer：[Ehviewer-Overhauled/Ehviewer: EhViewer overhauled with Material Design 3, Jetpack Compose and more (github.com)](https://github.com/Ehviewer-Overhauled/Ehviewer)
13. 飞书文档的收藏
14. #urgency/medium obsidian todo
15. [JetBrains/compose-multiplatform-ios-android-template: Compose Multiplatform iOS+Android Application project template (github.com)](https://github.com/JetBrains/compose-multiplatform-ios-android-template)
16. [running-libo/Tiktok: 高仿抖音APP (github.com)](https://github.com/running-libo/Tiktok)
17. #urgency/high Rust：[欢迎来到 Comprehensive Rust 🦀 - Comprehensive Rust 🦀 (google.github.io)](https://google.github.io/comprehensive-rust/zh-CN/)
18. #urgency/low 当时NIO的那些录屏。
19. #urgency/high bytetech机器人
20. #urgency/high ==***想进Infra，狠狠学字节码***==！

# Others

* [[Study Log/android_study/aa_android_study_outline|aa_android_study_outline]]
* [[Study Log/java_kotlin_study/aa_java_study|aa_java_study]]
* [[Study Log/java_kotlin_study/aa_kotlin_study|aa_kotlin_study]]