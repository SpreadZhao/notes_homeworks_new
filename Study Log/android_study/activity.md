---
mtrace:
  - 2024-01-21
---
[[Article/android_articles/guolin_wechat_articles/Activity的五种启动模式.pdf|Activity的五种启动模式]]

- [ ] #TODO 启动模式前半部分不太行。需要给出每个例子具体的行为，画画图。 🔽 ➕ 2024-01-21

# 以前的总结

![[Article/interview/android_interview#1. Activity|android_interview]]

# 1 生命周期Practice

实操：在一个Activity上打开另一个Activity，执行的流程：

![[Study Log/android_study/resources/Pasted image 20230717110057.png]]

我们发现，当A执行了onPause之后，并没有立刻执行onStop，而是在第二个Activity执行完onCreate -> onStart -> onResume之后才会执行onStop。

将SecondActivity换成Dialog的形式之后：

![[Study Log/android_study/resources/Pasted image 20230717110634.png]]

会发现MainActivity的onStop不会执行，因为此时用户是能看见这个Activity的。

当在Dialog显示的时候，点击空白处以关闭Dialog，回到MainActivity时：

![[Study Log/android_study/resources/Pasted image 20230717111508.png]]

我们也能发现，当MainActivity真的已经显示在最顶层（onResume）之后，Dialog才会进行销毁，也就是onStop和onDestroy。

现在把Dialog再换成普通的Activity，退出时的操作：

![[Study Log/android_study/resources/Pasted image 20230717111803.png]]

通过以上的情况，我们能总结出来：**当Activity要发生切换时，一个Activity的onPause方法就是为另一个Activity让步的**。在一个Activity的onPause执行完毕后，另一个Activity会**立刻**试图执行到onResume以显示。当显示完毕后，之前让步的Activity才会继续往下走流程。

# 2 启动模式Practice

在starndard模式下，连续启动了三次我自己： ^83ed41

![[Study Log/android_study/resources/Pasted image 20230717114110.png]]

每次的ID都不一样，所以每次都会创建出一个新的Activity到返回栈中，将原来的压下去。

在singletop模式下，无论我启动多少次我自己，都只有最一开始创建的信息： ^bf3b95

![[Study Log/android_study/resources/Pasted image 20230717134047.png]]

然而，如果我在MainActivity和SecondActivity之间反复横跳（**不是通过返回键**）的话，结果又不一样了：

![[Study Log/android_study/resources/Pasted image 20230717134943.png]]

现在MainActivity和SecondActivity都是singletop模式，然而我们发现依然会创建新的实例。也就是这个模式下不在栈顶的Activity还是会创建新的实例的。

现在把这两个Activity都换成singletask模式：

![[Study Log/android_study/resources/Pasted image 20230717140410.png]]

MainActivity在反复横跳的过程中，只会创建一次了。然而SecondActivity却会创建多次。这是因为，我们在SecondActivity中启动MainActivity，系统检测到MainActivity是singletask的，并且**它此刻就在栈下面**。所以直接就调用类似返回的逻辑了：

![[Study Log/android_study/resources/Pasted image 20230717140703.png]]

于是再启动SecondActivity的时候，就会走创建一个Activity的流程了。

# 3 启动模式介绍

[Android 面试黑洞——当我按下 Home 键再切回来，会发生什么？_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV1CA41177Se/?spm_id_from=333.999.0.0&vd_source=64798edb37a6df5a2f8713039c334afb)

当我们点击了手机上的那个方块键，或者手机上滑之后，看到的这一个个的，是什么呢？

![[Study Log/android_study/resources/msedge_9YVkfrEkA0.gif|500]]

答案是**Task**。当我们点击了一个桌面上的App图标时，那个配置了MAIN+LAUNCHER的Activity就会被启动：

![[Study Log/android_study/resources/Pasted image 20230803143730.png]]

同时，这个Activity也会被放进系统新创建出的一个Task里：

![[Study Log/android_study/resources/Pasted image 20230803143807.png|300]]

比如，下图中展示的，就是后台的四个Task。其中最下面的是用户正在打开的**前台Task**：

![[Study Log/android_study/resources/Pasted image 20230803143932.png|500]]

**每一个Task都有一个~~或多个~~返回栈来管理这些Activity**，当我们在一个任务中不停点返回键，这些Activity就会依次被关闭（onDestroy），直到最后一个Activity被关闭，这个Task的生命周期也就结束了。然而，即使这个Task不存在了，我们在切到最近任务时，依然可以看见它：

![[Study Log/android_study/resources/Pasted image 20230803144331.png|500]]

这并不代表这个程序没有被杀死，而是只是系统为这个应用保留了一个“残影”。当我们点击它时，**加载的动画是程序启动的动画，而不是从后台跳出来的动画**： ^edf677

![[Study Log/android_study/resources/msedge_KC4qAJBV6z.gif|500]]

## 3.1 Standard

接下来，我们来说一下跨进程，跨应用启动的过程。我们新建两个应用，ActivityTest1和ActivityTest2。ActivityTest1里面有一个启动ActivityTest2的MainActivity的按钮：

```kotlin
class MainActivity : ComponentActivity() {  
    override fun onCreate(savedInstanceState: Bundle?) {  
        super.onCreate(savedInstanceState)  
        setContent {  
            ActivityTest1Theme {  
                // A surface container using the 'background' color from the theme  
                Surface(  
                    modifier = Modifier.fillMaxSize(),  
                    color = MaterialTheme.colorScheme.background  
                ) {  
//                    Greeting("Android")  
                    LaunchModeTest()  
                }  
            }        
		}    
	}  
}  
  
@Composable  
fun LaunchModeTest() {  
    val context = LocalContext.current  
  
    Column {  
        Button(onClick = {  
            context.startActivity(  
                Intent().setComponent(  
                    ComponentName("com.example.activitytest2", "com.example.activitytest2.MainActivity")  
                )  
            )  
        }) {  
            Text(text = "Start Other App's Activity")  
        }  
    }
}
```

而ActivityTest2里面只有一个TextField用来输入文字：

```kotlin
class MainActivity : ComponentActivity() {  
    override fun onCreate(savedInstanceState: Bundle?) {  
        super.onCreate(savedInstanceState)  
        setContent {  
            ActivityTest2Theme {  
                // A surface container using the 'background' color from the theme  
                Surface(  
                    modifier = Modifier.fillMaxSize(),  
                    color = MaterialTheme.colorScheme.background  
                ) {  
//                    Greeting("Android")  
                    Edit()  
                }  
            }        
		}    
	}  
}  
  
@OptIn(ExperimentalMaterial3Api::class)  
@Composable  
fun Edit() {  
    var text by remember {  
        mutableStateOf("")  
    }  
    Column {  
        TextField(  
            value = text,  
            onValueChange = { text = it }  
        )  
    }  
}
```

我们首先启动ActivityTest2，在里面输入一串文字，然后通过ActivityTest1里的按钮来启动这个ActivityTest2。现在来看看效果：

![[Study Log/android_study/resources/scrcpy_EuKV6nkAF6.gif|300]]

可以看到，我们自己启动的ActivityTest2的MainActivty，和通过ActivityTest1的按钮启动的ActivityTest2的MainActivity，它们的数据是**不共享的**！这和我们之前的Practice中的内容也是一致的：[[#^83ed41]]

接下来，用一个动画来演示一下这个跨应用的情况：

![[Study Log/android_study/resources/msedge_1GBwQHaXpH.gif|500]]

就像视频中说的，*为什么这么设计*？为什么别的应用的Activity，可以被我这个应用任意支配呢？甚至不会影响那个提供Activity应用本身？我们现在考虑一种使用情况：我在QQ中点击了一个邮箱链接，想发送邮件。那么此时的操作显然是从QQ当前的Activity，跳转到了邮箱App中的Activity。就像这样：

![[Study Log/android_study/resources/scrcpy_Oa3SK6GZYs.gif|300]]

然而，**如果我不想这样操作了呢**？或者说，我不想发邮件了呢？从用户的角度来想，**按一下返回不就好了嘛！并且，在绝大多数情况下，我也希望按下返回之后，我回到的应用应该是QQ而不是Outlook**。我们来实验一下：

![[Study Log/android_study/resources/scrcpy_0N2PbOQVeu.gif|300]]

果然回到了原来的应用！而这也就是安卓默认启动模式standard的特点：Activity在start的时候都会创建出一个新的实例。而这样的特性，使得它在给其它应用提供功能时变得更加灵活，且不会影响自己；另外，我们也能注意到，**这个写邮件的Activity和QQ是相关的，因为它就是从QQ打开的；和Outlook本身却是不相关的，因为我只是想写个邮件，并没有用到其它Outlook中的功能**。你可能会问：如果我手滑点了一下返回，那我写的邮件不就没了？别担心，Outlook早就考虑了这一点。我们回到QQ之后，再打开Outlook，是可以看到它为我们保存了一份草稿的：

![[Study Log/android_study/resources/Pasted image 20230803160857.png|300]]

这个功能的实现就很多样了，可能是定时备份，也可能是在Activity退出的时候执行。

 > #question/coding/practice 
> 
> - [ ] #TODO Activity退出的时候，哪一个阶段适合做这样的操作？ 🔽

```ad-info
我没有用视频中短信和通讯录的例子，因为我的手机里短信和通讯录是合在一起的一个应用；相反，我的邮件倒是和他Standard的例子是一样的（视频中邮件被用作SingleTask的例子）。

其实，这个Outlook的Activity最有可能是SingleInstance的，只是在目前看来，它和Standard模式的效果差不多，所以就这么讲了。
```

## 3.2 SingleTask

接下来，我们再来看一看SingleTask的例子。还是之前的AT1和AT2。我们仅仅是将AT2的MainActivity的启动模式换一下：

```xml
<activity  
    android:name=".MainActivity"  
    android:exported="true"  
    android:label="@string/app_name"  
    android:theme="@style/Theme.ActivityTest2"  
    android:launchMode="singleTask"  
    >  
    <intent-filter>        
	    <action android:name="android.intent.action.MAIN" />  
        <category android:name="android.intent.category.LAUNCHER" />  
    </intent-filter>
</activity>
```

换成了SingleTask之后，重新运行一下AT2，然后输入一串字符，之后从AT1的按钮里启动AT2：

![[Study Log/android_study/resources/scrcpy_a70JXZkBr7.gif|300]]

这下结果就完全不一样了！不是一个新的Activity，而是原来带有我们输入的字符的Activity。我们再深入了解一下：修改AT2的代码，加入一个新的Activity：

```kotlin
class EditActivity : ComponentActivity() {  
    override fun onCreate(savedInstanceState: Bundle?) {  
        super.onCreate(savedInstanceState)  
        setContent {  
            ActivityTest2Theme {  
                // A surface container using the 'background' color from the theme  
                Surface(  
                    modifier = Modifier.fillMaxSize(),  
                    color = MaterialTheme.colorScheme.background  
                ) {  
                    Edit()  
                }  
            }        
		}    
	}  
}  
  
@OptIn(ExperimentalMaterial3Api::class)  
@Composable  
fun Edit() {  
    var text by remember {  
        mutableStateOf("")  
    }  
    Column {  
        TextField(  
            value = text,  
            onValueChange = { text = it }  
        )  
    }  
}
```

我们将输入框的部分移到了一个新的EditActivity中，并让MainActivity能够启动它：

```kotlin
class MainActivity : ComponentActivity() {  
    override fun onCreate(savedInstanceState: Bundle?) {  
        super.onCreate(savedInstanceState)  
        setContent {  
            ActivityTest2Theme {  
                // A surface container using the 'background' color from the theme  
                Surface(  
                    modifier = Modifier.fillMaxSize(),  
                    color = MaterialTheme.colorScheme.background  
                ) {  
                    StartEdit()  
                }  
            }        
		}    
	}  
}  
  
@Composable  
fun StartEdit() {  
    val context = LocalContext.current  
    Column {  
        Button(onClick = {  
            val intent = Intent(context, EditActivity::class.java)  
            context.startActivity(intent)  
        }) {  
            Text(text = "StartEdit")  
        }  
    }
}
```

然后，我们把MainActivity的启动模式改回Standard，把EditActivity的启动模式改成SingleTask：

```xml
<activity  
    android:name=".EditActivity"  
    android:exported="false"  
    android:label="@string/title_activity_edit"  
    android:theme="@style/Theme.ActivityTest2"  
    android:launchMode="singleTask"  
/>  
<activity  
    android:name=".MainActivity"  
    android:exported="true"  
    android:label="@string/app_name"  
    android:theme="@style/Theme.ActivityTest2">  
    <intent-filter>        
	    <action android:name="android.intent.action.MAIN" />  
        <category android:name="android.intent.category.LAUNCHER" />  
    </intent-filter>
</activity>
```

AT1的代码不用修改，还是启动MainActivity就好。我们来观察一下实际的情况。**首先是，确保清除掉AT2的后台，然后启动AT1**：

![[Study Log/android_study/resources/scrcpy_DSSfpDEr50.gif|300]]

一切正常。按照之前我们介绍的逻辑（standard），应该是这样的：

![[Study Log/android_study/resources/Drawing 2023-08-03 16.56.52.excalidraw.png]]

**但是，如果我们启动了AT2，再进行一遍流程的话：**

![[Study Log/android_study/resources/scrcpy_YcrPiQW6tG.gif|300]]

*为什么中间出现了两个AT2的MainActivity*？如果我们深入了解了SingleTask的机制，就能够知道：**[[Study Log/android_study/resources/Drawing 2023-08-03 16.56.52.excalidraw.png|之前的那张图]]其实是错误的**！AT2的EditActivity是一个SingleTask，所以它的启动可不是简简单单地向当前的任务中堆一个Activity而已。

我们先把这个问题放一放。~~因为，我们是用ComponentName的方式启动它的~~[^错误的原因]。我们先做一个比较简单的案例。修改AT2的代码，再增加一个SingleTask的Activity： ^9b0410

```kotlin
class EditActivity2 : ComponentActivity() {  
    override fun onCreate(savedInstanceState: Bundle?) {  
        super.onCreate(savedInstanceState)  
        setContent {  
            ActivityTest2Theme {  
                // A surface container using the 'background' color from the theme  
                Surface(  
                    modifier = Modifier.fillMaxSize(),  
                    color = MaterialTheme.colorScheme.background  
                ) {  
                    Text(text = "I'm EditActivty2")  
                }  
            }        
		}    
	}  
}
```

然后配置一下这个Activity，让他能接收一个Action：

```xml
<activity  
    android:name=".EditActivity2"  
    android:exported="true"  
    android:label="@string/title_activity_edit2"  
    android:theme="@style/Theme.ActivityTest2"  
    android:launchMode="singleTask"  
    >  
    <intent-filter>        
	    <action android:name="com.example.activitytest2.ACTION_TEST" />  
        <category android:name="android.intent.category.DEFAULT" />  
    </intent-filter>
</activity>
```

```ad-warning
这里的exported一定要写成true！否则我们在其它应用中是没有权限启动它的！
```

然后，在AT1的代码中加上一个按钮，来启动这个Activity：

```kotlin
Button(onClick = {  
    val intent = Intent("com.example.activitytest2.ACTION_TEST")  
    context.startActivity(intent)  
}) {  
    Text(text = "Start EditActivity2")  
}
```

开始验证！我们依然分成两种情况。首先是**后台干干净净**： ^668c26

![[Study Log/android_study/resources/scrcpy_03pSkdNpyk.gif|300]]

可以看到，从EditActivity2直接回到了AT1的MainActivity。接下来，是**启动AT2的情况下**： ^3d44fa

![[Study Log/android_study/resources/scrcpy_CCvlUkRgd9.gif|300]]

**神奇的事情来了！启动了AT2之后，在中间多出来了一个AT2的MainActivity**。而这就是SingleTask的模式：在目标Task上新建出我想打开的Activity，然后把整个Task都压在我当前的Task上面。而这也就意味着，**如果之前目标的Task已经是启动状态的话，里面已经存在的Activity也回被顺带压过来**。图解就是这样的：

![[Study Log/android_study/resources/Drawing 2023-08-03 17.35.09.excalidraw.png]]

上图是启动了AT2之后进行操作的过程；而如果是后台干干净净的情况，AT2.MainActivity就不会存在了，~~甚至Task2也不会存在~~甚至在一开始（没有启动EditActivity2的时候）Task2也是不存在的。

到了现在，我们能回答[[#^9b0410|之前那个问题]]了吗？答案是肯定的。想一想之前我们是怎么做的：启动一个Standard的Activity（此时这个Activity还是属于Task1），然后在这个上面启动了一个SingleTask的Activity。这就意味着**如果之前AT2已经运行了**，就会把AT2整个Task都搬过来，这样两个AT1中的AT2.MainActivity和AT2里面已经启动的AT2.MainActivity就贴在一起了：

![[Study Log/android_study/resources/Drawing 2023-08-03 18.03.39.excalidraw.png]]

而这就是中间出现了两次StartEdit的原因。下面，用一个动画来演示一下SingleTask启动的整个过程：

![[Study Log/android_study/resources/msedge_3hWkSszdz9.gif|500]]

### 3.2.1 前台Task和后台Task

**下面，我们进行一个，你可能从来没有意识到过的操作**。还是之前那个EditActivity2的例子。这次，在AT2运行的状态下进行操作：

1. 运行AT1；
2. 点击Start EditActivity2；
3. **上划，进入任务列表，然后再进入这个应用**；
4. 持续按返回键。

你会得到一个，完全出乎你意料的结果！

![[Study Log/android_study/resources/scrcpy_YmVmsrR0zp.gif|300]]

我的AT1.MainActivity呢？怎么没了？这涉及到前台Task和后台Task的问题。**我们正在运行的应用所在的Task，就是前台Task。而如果我们像[[Study Log/android_study/resources/Drawing 2023-08-03 18.03.39.excalidraw.png|刚才]]一样，使用SingleTask将Task进行了叠加，那么这多个Task共同作为前台Task**。

当我们进行以下操作时，前台Task会进入后台：

1. 按Home键进入桌面；
2. 进入最近任务列表。

```ad-warning
这里要注意第二条的**“进入”**二字。并不是<u>切换到其它应用之后</u>之前的前台Task才会进入后台，而是进入这个最近任务视图的一瞬间就切换到后台了。
```

而如果我们是那种多个Task叠在一起的情况，在进入后台时，**全部都会被拆开**。所以，才会导致上面AT1.MainActivity消失的情况。因为，那条表示了叠放关系的链子已经断了： ^32e55d

![[Study Log/android_study/resources/Drawing 2023-08-03 19.35.23.excalidraw.png]]

### 3.2.2 SingleTask的特殊情况

接下来，我们继续修改EditActivity2的例子。首先，我们要让AT2的MainActivity能够启动EditActivity2（之前只能通过AT1的隐式Intent启动）：

```kotlin
Button(onClick = {  
    context.startActivity(Intent(context, EditActivity2::class.java))  
}) {  
    Text(text = "StartEdit2")  
}
```

其实就是添加一个按钮嘛。然后，我们在EditActivity2里加上一点日志，在onCreate方法里和onNewIntent方法里加：

```kotlin
class EditActivity2 : ComponentActivity() {  
    private val TAG = "EditActivity2"  
    override fun onCreate(savedInstanceState: Bundle?) {  
        super.onCreate(savedInstanceState)  
        Log.e(TAG, "onCreate: $this")  
        setContent {  
            ActivityTest2Theme {  
                // A surface container using the 'background' color from the theme  
                Surface(  
                    modifier = Modifier.fillMaxSize(),  
                    color = MaterialTheme.colorScheme.background  
                ) {  
                    Column {  
                        Text(text = "I'm EditActivty2")  
                        Button(onClick = {  
                            startActivity(Intent(this@EditActivity2, TestActivity::class.java))  
                        }) {  
                            Text(text = "Start TestActivity")  
                        }  
                    }                
				}            
			}        
		}    
	}  
  
    override fun onNewIntent(intent: Intent?) {  
        super.onNewIntent(intent)  
        Log.e(TAG, "onNewIntent: $this")  
    }  
}
```

这里你可能注意到了，我们又加了一个按钮，又加了一个新的Activity叫TestActivity，放在EditActivity2的上面：

```kotlin
class TestActivity : ComponentActivity() {  
    private val TAG = "TestActivity"  
    override fun onCreate(savedInstanceState: Bundle?) {  
        super.onCreate(savedInstanceState)  
        Log.e(TAG, "onCreate: $this")  
        setContent {  
            ActivityTest2Theme {  
                // A surface container using the 'background' color from the theme  
                Surface(  
                    modifier = Modifier.fillMaxSize(),  
                    color = MaterialTheme.colorScheme.background  
                ) {  
                    Greeting4("TestActivity")  
                }  
            }        
		}    
	}  
  
    override fun onDestroy() {  
        Log.e(TAG, "onDestroy: $this")  
        super.onDestroy()  
    }  
}
```

在TestActivity的onCreate和onDestroy里也同样打了日志。接下来，我们进行下列操作：

1. 运行AT2，依次打开MainActivity, EditActivity2, TestActivity；
2. 回到桌面，打开AT1（不要杀后台）；
3. 从AT1启动AT2的EditActivity2。

配合着日志，我们来看一看现象：

![[Study Log/android_study/resources/studio64_jVMG4svpQZ.gif]]

首先，因为我们在EditActivity2和TestActivity的onCreate中都加了日志，所以这两条信息代表我们点击了两个按钮，依次打开它们：

```java
onCreate: com.example.activitytest2.EditActivity2@f2d40af
onCreate: com.example.activitytest2.TestActivity@f015ead
```

然后，我们从AT1启动了这个来自AT2的EditActivity2，并且还是一个SingleTask。此时神奇的事情又发生了：**TestActivity被销毁了**！最有力的证据，就是我们看到了TestActivity的onDestroy得到了执行：

```java
onDestroy: com.example.activitytest2.TestActivity@f015ead
```

并且，连Activity的ID都是一样的。同时，我们也看到EditActivity2的onCreate并没有重复执行，而是执行了onNewIntent方法：

```java
onNewIntent: com.example.activitytest2.EditActivity2@f2d40af
```

也是同一个Activity。通过这个现象，我们也可以画出一个Task栈图了：

![[Study Log/android_study/resources/Drawing 2023-08-04 11.43.56.excalidraw.png]]

**当目标Activity为SingleTask并且已经在目标Task中启动了。此时如果这个Activity的上面还压着Activity，它们会全部被清掉（调用onDestroy）来保证目标Activity出现在栈顶**。同时，也会调用onNewIntent方法来刷新这个Activity中的内容。下面我们来使用一下这个特性。修改AT2的EditActivity2：

```kotlin
class EditActivity2 : ComponentActivity() {  
    private val TAG = "EditActivity2"  
    override fun onCreate(savedInstanceState: Bundle?) {  
        super.onCreate(savedInstanceState)  
        Log.e(TAG, "onCreate: $this")  
        setContent {  
            ActivityTest2Theme {  
                // A surface container using the 'background' color from the theme  
                Surface(  
                    modifier = Modifier.fillMaxSize(),  
                    color = MaterialTheme.colorScheme.background  
                ) {  
                    ContentInEditActivity2(context = this, name = TAG)  
                }  
            }        
		}    
	}  
  
    override fun onNewIntent(intent: Intent?) {  
        super.onNewIntent(intent)  
        val newName = intent?.getStringExtra("name")  
        setContent {  
            ActivityTest2Theme {  
                // A surface container using the 'background' color from the theme  
                Surface(  
                    modifier = Modifier.fillMaxSize(),  
                    color = MaterialTheme.colorScheme.background  
                ) {  
                    ContentInEditActivity2(context = this, name = newName ?: "")  
                }  
            }        
		}
		Log.e(TAG, "onNewIntent: $this")  
    }  
}  
  
@Composable  
fun ContentInEditActivity2(context: Context, name: String) {  
    Column {  
        Text(text = "I'm $name")  
        Button(onClick = {  
            context.startActivity(Intent(context, TestActivity::class.java))  
        }) {  
            Text(text = "Start TestActivity")  
        }  
    }
}
```

在onNewIntent中，如果得到了Intent，就将里面的name提取出来，显示在屏幕上。然后，在AT1中，将这个name字段传进去：

```kotlin
Button(onClick = {  
    val intent = Intent("com.example.activitytest2.ACTION_TEST").apply {  
        putExtra("name", "Spread")  
    }  
    context.startActivity(intent)  
}) {  
    Text(text = "Start EditActivity2")  
}
```

现在再试一下吧：

![[Study Log/android_study/resources/scrcpy_WRnYfMH2mC.gif|300]]

可以看到，原来的EditActivity2已经成功变成了Spread。

## 3.3 SingleInstance

SingleInstance和SingleTask的逻辑基本是一致的。前台后台Task、onNewIntent等等，都是一样的。然而，SingleInstance有一个更加严格的限制：**Task里只能有一个Activity，就是这个SingleInstance的Activity**。还是EditActivity2的例子。目前的图是这样的： ^4a1468

![[Study Log/android_study/resources/Drawing 2023-08-03 17.35.09.excalidraw.png]]

而如果我们将EditActivity2的启动模式换成了SingleInstance，会发生什么呢？

```xml
<activity  
    android:name=".EditActivity2"  
    android:exported="true"  
    android:label="@string/title_activity_edit2"  
    android:launchMode="singleInstance"  
    android:theme="@style/Theme.ActivityTest2">  
    <intent-filter>        
	    <action android:name="com.example.activitytest2.ACTION_TEST" />  
        <category android:name="android.intent.category.DEFAULT" />  
    </intent-filter>
</activity>
```

![[Study Log/android_study/resources/scrcpy_44dPzZUiZ2.gif|300]]

可以看到，和SingleTask最明显的区别，就是**即使AT2已经处于运行中了，也是不会回到AT2的MainActivity的，而是直接回到AT1的MainActivity**。因为它们的逻辑图是这样的：

![[Study Log/android_study/resources/Drawing 2023-08-04 12.14.29.excalidraw.png]]

我们也可以思考一下，如果是从AT2自己启动了EditActivity2，会是什么情况。这个问题巨简单，就直接给图了：

![[Study Log/android_study/resources/Drawing 2023-08-04 12.16.56.excalidraw.png]]

接下来，是SingleInstance最需要注意的地方：*如果从SingleInstance的Activity启动Activity，会发生什么*？首先，我们创建一个标准模式的EditActivity3，并让EditActivity2能够启动它： ^ed5c54

```kotlin
class EditActivity3 : ComponentActivity() {  
    override fun onCreate(savedInstanceState: Bundle?) {  
        super.onCreate(savedInstanceState)  
        setContent {  
            ActivityTest2Theme {  
                // A surface container using the 'background' color from the theme  
                Surface(  
                    modifier = Modifier.fillMaxSize(),  
                    color = MaterialTheme.colorScheme.background  
                ) {  
                    Greeting5("EditActivity3")  
                }  
            }        
		}    
	}  
}
```

```kotlin
Button(onClick = {  
    context.startActivity(Intent(context, EditActivity3::class.java))  
}) {  
    Text(text = "Start EditActivity3")  
}
```

然后，我们要尝试几种可能了。首先是只和AT2有关系的。在AT2上启动MainActivity, EditActivity2, EditActivity3，然后观察现象：

![[Study Log/android_study/resources/JXGa7jrLSD.gif|300]]

**原本在最下面的MainActivity，现在跑到中间去了**！而通过这个现象我们能推测出来：在SingleInstance上启动Activity时，会优先从目标的App的Task上创建，并将它整个压在当前Task上面：

![[Study Log/android_study/resources/Drawing 2023-08-04 12.38.36.excalidraw.png]]

---

Case2：在**AT2未运行的情况下**，通过AT1的MainActivity启动AT2的EditActivity2，并在上面启动EditActivity3：

![[Study Log/android_study/resources/ACE4IR6AB0.gif|300]]

可以看到，出栈的顺序和进栈一模一样。所以EditActivity3是新找了一个Task，**而不是在AT1的Task中创建的**：

![[Study Log/android_study/resources/Drawing 2023-08-04 12.44.28.excalidraw.png]]

---

Case3：在AT2已运行的情况下，执行Case2的操作：

![[Study Log/android_study/resources/scrcpy_SLQZi7MYwC.gif|300]]

我想我们已经可以举一反三了：

![[Study Log/android_study/resources/Drawing 2023-08-04 12.49.54.excalidraw.png]]

总结一下，就是SingleInstance上启动其它Activity时，**首先趋向于找目标App的Task**，没有就创建新的。

---

接下来，讲一点SingleTask和SingleInstance的区别。在AT2中，EditActivity是SingleTask，而EditActivity2是SingleInstance。那么，它们有什么区别呢？我们来操作一下：

* 运行AT2，进入EditActivity，回到桌面，打开AT2；
* 运行AT2，进入EditActivity2，回到桌面，打开AT2。

你会得到两个完全不一样的结果：

![[Study Log/android_study/resources/scrcpy_WTXjqibt3g.gif|300]]

在SingleTask中，EditActivity还在；**而在SingleInstance中，EditActivity2居然没了**？？？并且，如果你此时进入任务视图也会看到，只存在一个Task，而不是两个。我们可以思考一下，这两种情况的本质区别是什么：**其实就是Task的个数嘛**！SingleTask的例子中，MainActivity和EditActivity在同一个Task里；而在SingleInstance的例子中，它们在不同的Task里。实际上，SingleInstance中那个“消失”了的EditActivity2，并没有被杀死，依然在后台运行着。只是在视图上是不会显示出来的。 ^fa1cb5

```ad-note
* 在任务视图显示的Task，未必还活着；[[#^edf677]]
* 在任务视图未显示的Task，也未必死了。

> #question/coding/android 如何证明？ -> [[#4.1 死了？没死？]]
```

^b1c631

那么，如何让它能显示出来呢？非常简单，只需要修改一个叫"taskAffinity"的属性就可以。修改EditActivity2的配置：

```xml
<activity  
    android:name=".EditActivity2"  
    android:exported="true"  
    android:label="@string/title_activity_edit2"  
    android:launchMode="singleInstance"  
    android:theme="@style/Theme.ActivityTest2"  
    android:taskAffinity="hahaha.hehe"  
    >  
    <intent-filter>        
	    <action android:name="com.example.activitytest2.ACTION_TEST" />  
        <category android:name="android.intent.category.DEFAULT" />  
    </intent-filter>
</activity>
```

```ad-warning
这里taskAffinity的值中间必须带上`.`，否则会报这样的错误：`INSTALL_PARSE_FAILED_MANIFEST_MALFORMED`。
```

之后再进行一次操作，你会看到：虽然最终打开的还是MainActivity，但是我们在最近任务视图里已经能**看到两个Task**了：

![[Study Log/android_study/resources/scrcpy_OFU6vRIMsl.gif|300]]

## 3.4 Task Affinity

接下来，我们就来说说这个Task Affinity到底是什么东西。

[了解任务和返回堆栈# 处理亲和性  |  Android 开发者  |  Android Developers (google.cn)](https://developer.android.google.cn/guide/components/activities/tasks-and-back-stack?hl=zh-cn#Affinities)

Activity, Application, 整个APP以及Task本身都有taskAffinity属性。而

* Activity的taskAffinity默认取自Application的taskAffinity；
* Application的taskAffinity默认取自应用的taskAffinity（manifest标签）；
* 应用的taskAffinity**默认是程序的包名**；
* Task的taskAffinity是在它创建时，**栈底**的Activity的taskAffinity。

所以，如果我们不进行任何自定义的话，一个App的所有taskAffinity都是程序的包名。而在Android中，**我们在任务视图里看到的一个个Task，它们的taskAffinity必须是不一样的。如果有一样的，那么只会显示最近展示过的那一个**。而这，就是之前[[#^fa1cb5|EditActivity2"消失"了]]的原因。

接下来，我们再来说说为什么SingleTask会直接把整个Task都压过来，也就是这张图：[[Study Log/android_study/resources/Drawing 2023-08-03 17.35.09.excalidraw.png]]。我们在Task1里启动了AT1.MainActivity，此时Task1的taskAffinity就是AT1.MainActivity的taskAffinity，也就是AT1的包名；而之后在这上面启动了一个SingleTask的EditActivity2：此时系统就会**比较EditActivity2和Task1的Activity是否相同**。

1. 如果相同，就会直接入栈（就和启动自己App的SingleTask一样）；
2. 而如果不同，就会寻找是否存在和EditActivity2的taskAffinity相同的Task：
	1. 如果找到了（大多数情况，就是AT2这个App所在的Task），就会在这个找到的Task上创建出EditActivity2，并把这整个Task压到Task1上；
	2. 如果没找到，就会创建出一个新的Task，将EditActivity2创建在这里（此时这个新的Task的taskAffinity也必定是EditActivity2的taskAffinity），然后把这个新的Task压到Task1上。

2.1和2.2，其实就分别对应着之前[[#^3d44fa|AT2启动]]和[[#^668c26|后台干干净净]]的情况；另外，[[#^ed5c54|SingleInstance的那些]]情况也可以用这个结论解释。这个自己思考一下就可以了。

## 3.5 Single Top

已经有了这些铺垫，SingleTop模式就显得非常简单了。它和Standard模式非常类似，唯一的区别是：**如果要启动的Activity刚好就在栈顶，那么就不新建了**。从之前的[[#^bf3b95|Practice]]也能看出来，在绝大多数情况下，都是"我启我自己"这种情况。而如果是跨应用的话，那和Standard就没啥区别了。这里我把EditActivity2改成了singleTop模式，并实验了一下，就直接放结果图吧：

![[Study Log/android_study/resources/Drawing 2023-08-04 15.14.01.excalidraw.png]]

可以看到，不管AT2运行情况怎么样，只是因为EditActivity2**不在Task1的**栈顶，就创建，就这么简单。

# 4 证明

## 4.1 死了？没死？

这是为了证明之前的结论：[[#^b1c631]]。

我们可以配合Activity的生命周期来证明。首先是第一条，当Activity被杀死后，系统还会给它留一个残影。这个需要配合开发者模式的”不保留Activity“功能使用：

![[Study Log/android_study/resources/Pasted image 20230804153759.png|300]]

打开这个功能后，再测试一下：

![[Study Log/android_study/resources/studio64_OQzYmWdlIe.gif]]

可以看到，在Activity执行了onDestroy之后，还是会保留这个Task的影像的。

然后就是第二条，这条要用之前的SingleInstance的EditActivity2来验证。首先，关闭开发者模式的那个选项，然后修改EditActivity2的配置，**singleInstance，并且去掉taskAffinity**。

![[Study Log/android_study/resources/studio64_sPW9xSxQJS.gif]]

我们发现，这里EditActivity2的onDestroy并没有执行（我肯定是写了日志的），而再次打开EditActivity2时，会调用onNewIntent方法来刷新界面。由于我在AT2的MainActivity中并没有传有内容的Intent，所以你会看到`I'm `后面的东西消失了。

这里还有一个发现，其实和SingleTask的那个[[#^32e55d|拆Task特性]]是对应的，我们[[#^4a1468|之前]]也强调过。就是在EditActivity2上进入最近任务视图，再回来，之后就不会回到MainActivity了，而是会直接回到桌面。**然而，最大的发现不是这个，而是居然执行了onDestroy方法**！

![[Study Log/android_study/resources/studio64_PkPHc5tiw8.gif]]

之所以我之前说需要配合开发者模式使用，就是因为我测试的所有结果都显示，**如果Activity是最后一个Activity，按返回键的时候是不会杀死这个Activity的**。然而这里却杀死了，为什么呢？唯一的解释，就是**这个进程里还有其它的Activity**。显然，这个其它指的就是MainActivity。因为它还存在，所以虽然回到了桌面，但是EditActivity2还是被杀死了。既然如此，我又提出了一个设想：如果我在EditActivity2中把MainActivity干掉了，此时退出的话，还会执行onDestroy吗？

```ad-info
为什么不会onDestroy呢？[[Article/android_articles/guolin_wechat_articles/Activity的五种启动模式.pdf#page=6|Activity的五种启动模式]]
```

- [ ] #TODO 这个设想，等有时间再证明吧。 ⏬

## 4.2 onNewIntent调用的时机

这个问题很重要，也就是刷新的时机。配合动图和日志来看一下，然后直接给结论了：

![[Study Log/android_study/resources/studio64_hyrJ8hLIa6.gif]]

![[Study Log/android_study/resources/Drawing 2023-08-04 16.13.16.excalidraw.png|center|600]]

## 4.3 onSaveInstance调用的时机

[Save and Restore Instance State Made Easy! | by Heather Gallop | Medium](https://medium.com/@doyouseeitmyway/save-and-restore-instance-state-made-easy-cf6f175f54b0#:~:text=onSaveInstanceState%20%28%29%3A%20This%20method%20is%20called%20before%20onStop,be%20called%20after%20onStop%20%28%29%20for%20newer%20versions.)

这篇文章提到了，在新版安卓中，onSaveInstance调用的时机是在onStop之后的。而我用自己的手机测试也确实是这样：

![[Study Log/android_study/resources/Pasted image 20230805145603.png|400]]

而网上大多数资料都说的是在onPause和onStop之间执行。我当时就怀疑是新版本已经做了更改。而这篇文章也说明了这一点：

[Android 11源码分析：onSaveInstanceState到底做了什么？你知道的调用时机真的是正确的吗？ - 掘金 (juejin.cn)](https://juejin.cn/post/6995791487426363405)

- [ ] #TODO 这个配合着Window去学，把Activity外面的东西搞懂之后再弄会更轻松。 🔽

[^错误的原因]: ComponentName和Action的方式，只是显式和隐式的区别。