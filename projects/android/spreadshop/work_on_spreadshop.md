# 2022-10-20

昨天在写Retrofit的时候，使用了json传递数据，对象是拿到了，但是返回的都是空。后来才突然想起来，**`data class`里对应的成员名要和json中完全一致才可以**！

这是要传的json：

```json
{
	"status":"ok","query":"北京",
	"places":
	[
		{"name":"北京市","location":{"lat":39.9041999,"lng":116.4073963},
		"formatted_address":"中国?京市"},
		
		{"name":"北京西站","location":{"lat":39.89491,"lng":116.322056},
		"formatted_address":"中国 ?京市 丰台区 莲花池东路118号"},
		
		{"name":"北京南站","location":{"lat":39.865195,"lng":116.378545},
		"formatted_address":"中国 ?京市 丰台区 永外大街车站路12号"},
		
		{"name":"北京站(地铁站)","location":{"lat":39.904983,"lng":116.427287},
		"formatted_address":"中国 ?京市 东城区 2号线"}
	]
}
```

那么下面就是对应的`data class`：

```kotlin
data class PlaceResponse(val status: String, val places: List<Place>)

data class Place(val name: String, val location: Location, @SerializedName("formatted_address") val address: String)

data class Location(val lng: String, val lat: String)
```

由于JSON中一些字段的命名可能与Kotlin的命名规范不太一致，因此这里使用了`@SerializedName`注解的方式，来让JSON字段和Kotlin字段之间建立映射关系。

---

记录一下BindingView的写法，以下是郭神的文章：

[(29条消息) kotlin-android-extensions插件也被废弃了？扶我起来_guolin的博客-CSDN博客_kotlin-android-extensions废弃](https://blog.csdn.net/guolin_blog/article/details/113089706)

然后是Retrofit中Service的快速创建。如果不快速创建的话，正常写法是：

```kotlin
val retrofit = Retrofit.Builder()
	.baseUrl("http://10.0.2.2/")
	.addConverterFactory(GsonConverterFactory.create())
	.build()
val appService = retrofit.create(AppService::class.java)
```

如果每用到一次和`10.0.2.2`的连接就要写一堆这些，烦都烦死了。所以我们需要简化一下。在逻辑层的网络包，也就是`.logic.model`下新建`ServiceCreator`**单例类**： ^1e196a

```kotlin
object ServiceCreator {

	private const val BASE_URL = "http://10.0.2.2/"
	
	private val retrofit = Retrofit.Builder()
		.baseUrl(BASE_URL)
		.addConverterFactory(GsonConverterFactory.create())
		.build()

	//这里fun后面的<T>表示泛型声明，表明参数中有泛型
	fun <T> create(serviceClass: Class<T>): T = retrofit.create(serviceClass)
}
```

这样新建Service就只需要这样写：

```kotlin
val appService = ServiceCreator.create(AppService::class.java)
```

如果还是觉得麻烦，还可以再加一个函数：

```kotlin
inline fun <reified T> create(): T = create(T::class.java)
```

这样新建Service只需要这样写：

```kotlin
val appService = ServiceCreator.create<AppService>()
```

这里使用了Kotlin泛型实化。比如，如果定义一个函数：`fun getGenericType() = T::class.java`这里会产生语法错误。例如，假设我们创建了一个`List<String>`集合，虽然在编译时期只能向集合中添加字符串类型的元素，但是在运行时期JVM并不能知道它本来只打算包含哪种类型的元素，只能识别出来它是个List。所有基于JVM的语言，它们的泛型功能都是通过类型擦除机制来实现的，其中当然也包括了Kotlin。这种机制使得我们不可能使用`a is T`或者`T::class.java`这样的语法，因为T的实际类型在运行的时候已经被擦除了。因此，在编译时的泛型无法被具体实化成某个具体的类
但是，如果这样写：`inline fun <reified T> getGenericType() = T::class.java`
加上`inline`和`reified`，就可以在编译时通过了。

另外，郭神的《第一行代码》中的500页，第10.6讲也是在说这个事情。

---

在使用LiveData去保存登陆系统的用户名和密码的时候，出现了这样的问题。我们的LoginViewModel是这样的： ^fe2136

```kotlin
class LoginViewMode(uname: String, passwd: String): ViewModel() {  
  
    val username: LiveData<String>  
        get() = _username  
    private val _username = MutableLiveData<String>()  
  
    val password: LiveData<String>  
        get() = _password  
    private val _password = MutableLiveData<String>()  
  
    init{  
        _username.value = uname  
        _password.value = passwd  
    }  
  
    fun setUsername(uname: String){  
        _username.value = uname  
    }  
  
    fun setPassword(passwd: String){  
        _password.value = passwd  
    }  
  
}
```

这种写法是为了保存好数据的封装性。下划线开头的是真正的变量，而对应的没下划线的就是提供给外部访问的。而因为它们是`LiveData`类型，不可变。所以从外部是无法访问的，只能通过set方法来改变值。然后是在对应的LoginActivity中使用Retrofit来发起登陆请求。而这个请求的参数毫无疑问就是用户和密码。那么它们从哪儿来呢？如果不适用ViewModel + LiveData的话，就是定义在程序内部的变量，并从EditText处拿到值。也就是这样：

```kotlin
username = bindingLogin.accountEdit.text.toString()  
password = bindingLogin.passwordEdit.text.toString()
```

但是如今我们使用了LiveData，自然这些变量全要作为LiveData存到ViewModel中。那么在从EditText那里拿值的操作就变成了这样：

```kotlin
loginViewMode.setUsername(bindingLogin.accountEdit.text.toString())  
loginViewMode.setPassword(bindingLogin.passwordEdit.text.toString())
```

接下来就是真正使用Retrofit的Serivce接口去发请求了。这里遇到的问题是：由于数据被放在了LiveData中，而它的value字段有可能为空，但是kotlin中的变量类型默认不为空。所以我们只能采取下列写法：

```kotlin
if(loginViewMode.username.value != null && loginViewMode.password.value != null){  
    val username = loginViewMode.username.value  
    val password = loginViewMode.password.value  
    //Smart cast to 'String' is impossible, because 'loginViewMode.username.value' is a complex expression  
    loginResultService.getLoginResult(username!!, password!!)
    .enqueue(object: Callback<LoginResult> {  
        override fun onResponse(  
            call: Call<LoginResult>,  
            response: Response<LoginResult>  
        ) {  
            Log.d("SpreadShop", "on Response")  
            val loginResult = response.body()  
            if(loginResult != null){  
                Log.d("SpreadShop", 
                "loginResult.message: ${loginResult.message}")  
                if(loginResult.success){  
                    Log.d("SpreadShop", "Login Success")  
                }else{  
                    Log.d("SpreadShop", "Login Fail")  
                }  
            }else{  
                Log.d("SpreadShop", "LoginResult is Null")  
            }  
        }  
  
        override fun onFailure(call: Call<LoginResult>, t: Throwable) {  
            Log.d("SpreadShop", "on Failure")  
            t.printStackTrace()  
        }  
    })  
}
```

其实改变只有第一行if语句中的判断。因为我们在这里处理成了必须非空，然后才能在其中断言这两个变量是非空的。另外真正传参的时候还是要加上`!!`非空断言。

好吧，我上面的写法很傻，下面给出整个的登录按钮的注册监听：

```kotlin
bindingLogin.loginBtn.setOnClickListener {  
 
	loginViewMode.setUsername(bindingLogin.accountEdit.text.toString())  
	loginViewMode.setPassword(bindingLogin.passwordEdit.text.toString())  

	val username = loginViewMode.username.value  
	val password = loginViewMode.password.value  

	val loginResultService = ServiceCreator.create<LoginResultService>()  

	if(username != "" && password != ""){  
		Log.d("SpreadShopTest", "username: $username")  
		Log.d("SpreadShopTest", "password: $password")  
		//Smart cast to 'String' is impossible, because 'loginViewMode.username.value' is a complex expression  
		loginResultService.getLoginResult(username!!, password!!).enqueue(object: Callback<LoginResult> {  
			override fun onResponse(  
				call: Call<LoginResult>,  
				response: Response<LoginResult>  
			) {  
				Log.d("SpreadShopTest", "on Response")  
				val loginResult = response.body()  
				if(loginResult != null){  
					Log.d("SpreadShopTest", "loginResult.message: ${loginResult.message}")  
					if(loginResult.success){  
						Log.d("SpreadShopTest", "Login Success")  
					}else{  
						Log.d("SpreadShopTest", "Login Fail")  
					}  
				}else{  
					Log.d("SpreadShopTest", "LoginResult is Null")  
				}  
			}  

			override fun onFailure(call: Call<LoginResult>, t: Throwable) {  
				Log.d("SpreadShopTest", "on Failure")  
				t.printStackTrace()  
			}  
		})  
	}else{  
		Log.d("SpreadShopTest", "usernameEmpty: ${username == ""}")  
		Log.d("SpreadShopTest", "passwordEmpty: ${password == ""}")  
	}  

}// end bindingLogin.loginBtn.setOnClickListener
```

^afcf49

由于我们并不需要将username和password在屏幕上显示出来，所以根本不需要livedata的observe方法。所以在赋值完之后，直接使用就好。**还有一点，字符串为空并不是`== null`**。这里的空可不是c语言里的空指针，它是有实际内存的，只不过值为空。

# 2022-10-22

今天将这个项目彻底换成了MVVM架构，全部采用livedata，并且不使用协程去实现。原因就是我想彻底搞清楚MVVM架构的整体思路，而协程虽然能学到很多高级的Kotlin用法，但是对于自己思维的限制实在是太大了。如果用协程的话，我目前只知道抄书，所以想要打破一下这个局限。

首先从登陆这个功能开始。首先的首先，是它的请求数据对象：

```kotlin
data class LoginResult(val username: String, val passwd: String, val message: String, val success: Boolean)
```

确实，这里考虑到了返回的状态，也就是`success`成员。但是在传递Goods的时候当时并没有考虑到这一点，所以我们最后更改了那部分代码。这里`success`就是用来确定我的登陆是否成功，是密码错误还是账号不存在。 ^e4fa82

然后，就是登陆的Retrofit协议接口了：

```kotlin
interface LoginResultService {  
    @GET("login")  
    fun getLoginResult(@Query("username") username: String, @Query("password") password: String): Call<LoginResult>  
}
```

这里使用了`@Query`注解，这种注解是专门用来匹配下面的http请求的：

```http
http://localhost:8080/login?username=spreadzhao&password=1234
```

我们向`getLoginResult`函数中传递参数`spreadzhao`和`1234`，就能得到上面的http请求地址。

然后，是登陆的网络层接口，**这里的操作是关键，也是和书中不一样的地方**：

```kotlin
private val loginService = ServiceCreator.create<LoginResultService>()

fun getLoginResult(username: String, password: String) = loginService.getLoginResult(username, password)
```

在书中的MVVM架构里，网络层的代码非常复杂，又是高阶扩展函数又是挂起函数，其实都是为了使用协程而设计的。而我们不想去研究协程，那么改怎么办呢？我最一开始的代码是这样的：

```kotlin
private val goodsService = ServiceCreator.create<GoodsService>()

// 这里为什么能拿到cmd这个变量？是因为lambda表达式？  
fun getGoods(cmd: String) = goodsService.getGoods(cmd).enqueue(object: Callback<List<Goods>>{  
    override fun onResponse(call: Call<List<Goods>>, response: Response<List<Goods>>) {  
        val list = response.body()  
        if(list != null){  
            Log.d("SpreadShopTest", "[$cmd]list is not null")  
        }else{  
            Log.d("SpreadShopTest", "[$cmd]list is null")  
        }  
  
    }  
  
  
    override fun onFailure(call: Call<List<Goods>>, t: Throwable) {  
        t.printStackTrace()  
        Log.d("SpreadShopTest", "[showall]on failure")  
    }  
})
```

> 由于我的Login代码被删掉了，所以这里给出当时写的获取商品的代码，其实是一样的。

可以看到，我当时的设想是在这里直接得到相应的对象，并做相应的处理。这样经过仓库层再一包装，确实可以做到在Activity中一句话发起请求：

```kotlin
Repository.getLoginResult(username!!, password!!)
```

但是这种写法在我仔细想了想后，终于发现了问题：LiveData哪儿去了？首先，我们的目的是获取一个LoginResult类型的数据。但是如果按照我上面的写法去做的话，**那么这个数据在到达网络层就已经结束了**！因为我在网络层就已经处理了响应的代码。而我们的目的是将这个数据最终传递到ViewModel层，因为这才是MVVM架构的意义(拆分UI层减轻负担)。

另一个问题是，我在确定登陆成功之后，要打开MainAcitivity，而这个操作一定是由LoginActivity来做的。但是按照我这种写法，这个操作居然交给了网络层去做？显然这是不正确的。

由于以上两点，我们得出结论： ^02659f

* 返回的对象必须是LiveData；
* 返回的对象必须传递到ViewModel层，然后由LoginActivity去观察这个LiveData的变化，观察到变化之后再去处理响应操作(打开MainActivity或者提示登录失败)。

由此，我们才有了如今的这种写法，这也是我的**灵光一现**。而就是这个灵光一现，让我对于Retrofit的理解又深了几分。首先，是这个`enqueue`函数，到底是谁执行的？答案是`Call<T>`类型。那么既然如此，**我只需要将这个`Call<T>`对象的返回值层层传递到ViewModel层，然后将它包裹成LiveData**，上面的两个要求不就都实现了吗？！因此，我才有了这样的代码：

```kotlin
private val loginService = ServiceCreator.create<LoginResultService>()

fun getLoginResult(username: String, password: String) = loginService.getLoginResult(username, password)
```

^6a2640

可以看到，我只是调用了`loginService.getLoginResult()`函数去得到返回值然后再返回给上层。那么这个返回值的类型毫无疑问就是`Call<LoginResult>`类型。另外，第一行这种写法在昨天的日记中也已经[[#^1e196a|提到]]。

有了网络层，接下来就该是仓库层了。而这里的代码也很简单，不用像书上还要用`liveData`函数(书中使用这个函数也是因为协程)：

```kotlin
fun getLoginResult(username: String, password: String) = SpreadShopNetwork.getLoginResult(username, password)
```

依然是将这个返回值继续接力传递一下就行了，不需要任何其他操作。**因为仓库层主要的功能是从网络获取数据和从本地获取数据**。

接下来到了比较关键的ViewModel层，这里的代码就得说道说道了：

```kotlin
class LoginViewMode: ViewModel() {  
  
    val username: LiveData<String>  
        get() = _username  
    private val _username = MutableLiveData<String>()  
  
    val password: LiveData<String>  
        get() = _password  
    private val _password = MutableLiveData<String>()  
  
    val loginResult: LiveData<Call<LoginResult>>  
        get() = _loginResult  
    private val _loginResult = MutableLiveData<Call<LoginResult>>()  
  
    fun setUsername(uname: String){  
        _username.value = uname  
    }  
  
    fun setPassword(passwd: String){  
        _password.value = passwd  
    }  
  
  
    fun getLoginResult(username: String, password: String){  
        _loginResult.value = Repository.getLoginResult(username, password)  
    }  
  
}
```

`val loginResult: LiveData<Call<LoginResult>>`这句话之前的代码我们在[[#^fe2136|之前]]已经解释过了，接下来我们主要研究研究这段代码：

```kotlin
val loginResult: LiveData<Call<LoginResult>>  
	get() = _loginResult  
private val _loginResult = MutableLiveData<Call<LoginResult>>()  
```

结构和前面其实一模一样。唯一要强调的就是LiveData中包含的类型：`Call<LoginResult>`。这个类型其实就是我们在通过网络层，仓库层一次次传递回来的值。其实**从根本上讲**，它就是这个函数的返回值：

```kotlin
@GET("login")  
fun getLoginResult(@Query("username") username: String, @Query("password") password: String): Call<LoginResult>
```

因此我们要做的，就是将从仓库层拿来的`Call<LoginResult>`实体包裹进这个LiveData中，然后在LoginActivity里观察它就好了，而最终在ViewModel层的封装就是这样的：

```kotlin
fun getLoginResult(username: String, password: String){  
	_loginResult.value = Repository.getLoginResult(username, password)  
} 
```

因此当`_loginResult.value`发生变化是，我们观察的`loginResult`就业会跟着发生改变，因此这样就会触发LoginActivity中的Observer函数了。接下来我们就给出LoginActivity中的代码。首先是点击登录按钮之后的事件：

```kotlin
bindingLogin.loginBtn.setOnClickListener {

	loginViewMode.setUsername(bindingLogin.accountEdit.text.toString())  
	loginViewMode.setPassword(bindingLogin.passwordEdit.text.toString())  

	val username = loginViewMode.username.value  
	val password = loginViewMode.password.value  

	if(username != "" && password != ""){  
		Log.d("SpreadShopTest", "username: $username")  
		Log.d("SpreadShopTest", "password: $password")  
		loginViewMode.getLoginResult(username!!, password!!)  

	}else{  
		Log.d("SpreadShopTest", "usernameEmpty: ${username == ""}")  
		Log.d("SpreadShopTest", "passwordEmpty: ${password == ""}")  
	}  

}// end bindingLogin.loginBtn.setOnClickListener
```

和我们[[#^afcf49|之前的代码]]一对比，简直不要再简洁！首先，由于使用了网络层，而`loginResultService`的[[#^6a2640|实例就在其中]]，并且已经被包装到了ViewModel层，所以我们在这里只需要调用`loginViewModel`的`getLoginResult`方法就自动会一层层走下去。**而这样做的最终结果就是，`loginViewModel`中的`_loginResult.value`变成了`Repository.getLoginResult`的返回值**。而接下来我们要做的另一件是，就是在LoginActivity中去观察它的变化了：

```kotlin
loginViewMode.loginResult.observe(this){  
    it.enqueue(object: Callback<LoginResult>{  
        override fun onResponse(  
            call: Call<LoginResult>,  
            response: Response<LoginResult>  
        ) {  
            Log.d("SpreadShopTest", "on Response")  
            val loginResult = response.body()  
            if(loginResult != null){  
                Log.d("SpreadShopTest", "loginResult.message: ${loginResult.message}")  
                if(loginResult.success){  
                    Log.d("SpreadShopTest", "Login Success")  
                    val intent = Intent(this@LoginActivity, MainActivity::class.java)  
                    startActivity(intent)  
                }else{  
                    Log.d("SpreadShopTest", "Login Fail")  
                }  
            }else{  
                Log.d("SpreadShopTest", "LoginResult is Null")  
            }  
        }  
  
        override fun onFailure(call: Call<LoginResult>, t: Throwable) {  
            Log.d("SpreadShopTest", "on Failure")  
            t.printStackTrace()  
        }  
    })  
}
```

到了这一步，我们也算是终于完成了[[#^02659f|之前的两个要求]]：

* LoginResult作为LiveData封装到了ViewModel中
* 由LoginActivity去处理登陆的操作，而不是由网络层

另外补充一点，我们并没有使用`switchMap()`函数，是因为这个LiveData对象并不是来自外部，是我们ViewModel本身的，只不过是对它的`value`字段进行赋值而已。**更加详细的描述在郭神的《第一行代码》中的13.4.2节**。

---

之前也[[#^e4fa82|提到过]]，我更改了Goods的请求对象，原本我们返回的对象是`Call<List<Goods>>`，但是我们没有考虑过查询失败的情况。因此我们重新确定了数据模型，在上面进一步封装。下面给出数据模型的代码和网络接口的代码即可，剩下的修改就不多赘述了：

```kotlin
data class GoodsResponse(val success: Boolean, val goods: List<Goods>)

data class Goods(val goods_id: Int, val goods_name: String, val goods_category: String, val goods_storage: Int, val goods_price: Int)
```

```kotlin
@GET("searchgoods")  
fun getGoods(@Query("cmd") cmd: String): Call<GoodsResponse>
```

在修改之后，执行的时候不管怎么执行都是报错，而我很确定已经把所有的`List<Goods>`都改成了`GoodsResponse`。后来鉴定为编译器抽风，只需要Rebuild一下就好了。

---

接下来，是对于MainActivity的Material Design设计。首先是主题的更换，在`res/values/themes.xml`文件和`res/values-night/themes.xml`文件中，将style的parent更改成`Theme.MaterialComponents[.Light].NoActionBar`，这样就能够将主题更换成Material Design了，如果不更换的话，会出现崩溃的现象。另外，我们既然改成了`NoActionBar`，就需要我们自己去实现ActionBar了。在`activity_main.xml`中，就是如下的代码： ^1111b7

```xml
<?xml version="1.0" encoding="utf-8"?>  
<androidx.drawerlayout.widget.DrawerLayout  
    xmlns:android="http://schemas.android.com/apk/res/android"  
    xmlns:app="http://schemas.android.com/apk/res-auto"  
    android:id="@+id/drawer_layout"  
    android:layout_width="match_parent"  
    android:layout_height="match_parent"  
    >  
  
<!--  
    CoordinatorLayout是加强版的FrameLayout，它专为MaterialDesign设计，  
    能够监听其中控件的变化。-->  
  
    <androidx.coordinatorlayout.widget.CoordinatorLayout  
        android:layout_width="match_parent"  
        android:layout_height="match_parent">  
  
        <androidx.appcompat.widget.Toolbar            
	        android:id="@+id/toolbar"  
            android:layout_width="match_parent"  
            android:layout_height="?attr/actionBarSize"  
            android:background="@color/purple_200"  
            android:theme="@style/ThemeOverlay.AppCompat.Dark.ActionBar"  
            app:popupTheme="@style/ThemeOverlay.AppCompat.Light"  
            />  
  
    </androidx.coordinatorlayout.widget.CoordinatorLayout>  
  
    <com.google.android.material.navigation.NavigationView  
        android:id="@+id/nav_view"  
        android:layout_width="match_parent"  
        android:layout_height="match_parent"  
        android:layout_gravity="start"  
        app:menu="@menu/nav_menu"  
        app:headerLayout="@layout/nav_header"  
        />  
        
</androidx.drawerlayout.widget.DrawerLayout>
```

^de0cf0

我们将`ToolBar`包裹在了`CoordinatorLayout`中，这两个都是Material Design的组件。另外下面还有一个Navigation View，这也是我们的侧滑菜单的主要组件。

需要强调的有两点。一是我们最外层的组件：DrawerLayout，它能实现窗口想抽屉一样拉开。在所有的子组件中都会有一个`android:layout_gravity`属性，这个就是决定当前组件从哪个地方拉出来的选项。`start`表示根据语言判断。而这个DrawerLayout和Navigation View组合起来使用就能够实现侧滑菜单；第二点就是Navigation View中的`app:menu`属性和`app:headerLayout`属性。每一个Navigation View都由一个标题和一个菜单组成。而这两个文件就是我们接下来要介绍的。

首先是`nav_menu`，它在`res/menu/nav_menu.xml`。menu文件夹里所有的视图都是菜单。toolbar就是上面工具栏专用的菜单；nav_menu就是Navigation View专用的菜单。

```xml
<?xml version="1.0" encoding="utf-8"?>  
<menu xmlns:android="http://schemas.android.com/apk/res/android">  
<!--  
    group表示这些项被困成一个组  
    checkableBehavior="single"表示同时只能选中一个  
-->  
    <group android:checkableBehavior="single">  
        <item            
	        android:id="@+id/nav_mybag"  
            android:title="My Bag"  
            />  
  
        <item            
	        android:id="@+id/nav_order"  
            android:title="My Order"  
            />  
  
        <item            
	        android:id="@+id/nav_contact"  
            android:title="Contact Customer Service"  
            />  
  
        <item            
	        android:id="@+id/nav_logout"  
            android:title="Logout"  
            />
              
    </group>
    
</menu>
```

这样的话，侧滑菜单的选项就是这样的：

![[Pasted image 20221023122020.png]]

然后就是headerLayout了，它位于`res/layout/nav_header.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>  
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"  
    android:layout_width="match_parent"  
    android:padding="10dp"  
    android:background="@color/material_dynamic_primary40"  
    android:layout_height="200dp">  
  
    <de.hdodenhof.circleimageview.CircleImageView  
        android:id="@+id/user_icon"  
        android:layout_width="70dp"  
        android:layout_height="70dp"  
        android:src="@drawable/nav_user"  
        android:layout_centerInParent="true"  
        />  
  
    <TextView        
	    android:id="@+id/app_name"  
        android:layout_width="wrap_content"  
        android:layout_height="wrap_content"  
        android:layout_alignParentBottom="true"  
        android:text="Spread Shop"  
        android:textColor="@color/black"  
        android:textSize="14sp"  
        />  
  
    <TextView        
	    android:id="@+id/user_name"  
        android:layout_width="wrap_content"  
        android:layout_height="wrap_content"  
        android:layout_above="@id/app_name"  
        android:textColor="@color/material_dynamic_neutral60"  
        android:text="user name: null"  
        />  
  
</RelativeLayout>
```

需要注意的是，这里的`de.hdodenhof.circleimageview.CircleImageView`是我们引入的第三方库，专门用来把图片切成圆形。不妨就在这里列出项目所有的依赖吧：

```groovy
dependencies {  
  
    implementation 'androidx.core:core-ktx:1.7.0'  
    implementation 'androidx.appcompat:appcompat:1.5.1'  
    implementation 'com.google.android.material:material:1.5.0'  
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'  
    implementation 'com.squareup.retrofit2:retrofit:2.6.1'  
    implementation 'com.squareup.retrofit2:converter-gson:2.6.1'  
    implementation 'com.google.android.material:material:1.1.0'  
    implementation 'de.hdodenhof:circleimageview:3.0.1'  
    testImplementation 'junit:junit:4.13.2'  
    androidTestImplementation 'androidx.test.ext:junit:1.1.3'  
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.4.0'  
}
```

^8aea9b

接下来还有一点，就是我们主界面的[[#^1111b7|toolbar]]的菜单。既然是菜单文件，肯定是位于`res/menu`文件夹下了，我们就叫它`toolbar.xml`吧：

```xml
<?xml version="1.0" encoding="utf-8"?>  
<menu xmlns:android="http://schemas.android.com/apk/res/android"  
    xmlns:app="http://schemas.android.com/apk/res-auto">  
  
<!--  
    menu文件夹里的所有试图都是菜单  
        toolbar就是上面工具栏专用的菜单  
        而nav_menu就是Navigation View专用的菜单  
-->  
  
<!--  
    always: 永远显示再Toolbar中，空间不够不显示  
    ifRoom: 屏幕够就显示，不够显示再菜单中  
    never: 永远显示在菜单  
-->  
    <item  
        android:id="@+id/backup"  
        android:icon="@drawable/ic_backup"  
        android:title="Backup"  
        app:showAsAction="always"  
        />  
  
    <item        
	    android:id="@+id/delete"  
        android:icon="@drawable/ic_delete"  
        android:title="Delete"  
        app:showAsAction="ifRoom"  
        />  
  
    <item        
	    android:id="@+id/settings"  
        android:icon="@drawable/ic_settings"  
        android:title="Settings"  
        app:showAsAction="never"  
        />  
</menu>
```

非常好理解，就不用过多赘述了。有了所有的前端代码，接下来就是在MainActivity中将它们显示出来并注册点击事件。我们还是先从Navigation View开始，在MainActivity中需要想给按钮注册监听器一样给NavView里的菜单子项注册监听事件：

```kotlin
bindingMain.navView.setNavigationItemSelectedListener {  
    when(it.itemId){  
        R.id.nav_mybag -> Log.d("SpreadShopTest", "You clicked mybag")  
        R.id.nav_order -> Log.d("SpreadShopTest", "You clicked myorder")  
        R.id.nav_contact -> Log.d("SpreadShopTest", "You clicked Contact")  
        R.id.nav_logout -> Log.d("SpreadShopTest", "You clicked logout")  
    }  
    bindingMain.drawerLayout.closeDrawers()  
    true  
}
```

不管点击了任何按钮，最终都要调用`closeDrawers()`方法关闭所有的侧滑菜单。

好了，Navigation已经做完了！但是更重要的是接下来的Toolbar。因为只有有了Toolbar我们的程序才看起来会完整一些。首先，由于我们在[[#^1111b7|前面]]已经删掉了原本的ActionBar，所以我们需要设置新的ActionBar为我们自己定义的Toolbar：

```kotlin
setSupportActionBar(bindingMain.toolbar)
```

接下来，是展示左上角的侧滑菜单按钮。首先需要调用`getSupportActionBar`方法来得到这个ActionBar的实例(其实就是Toolbar)，然后将home图标显示出来并设置上我们自己的icon：

```kotlin
/*
supportActionBar?.let{  
	it.setDisplayHomeAsUpEnabled(true)  
	it.setHomeAsUpIndicator(R.drawable.ic_menu)  
} 
**/

//let和apply都可以  
supportActionBar?.apply {  
	setDisplayHomeAsUpEnabled(true)  
	setHomeAsUpIndicator(R.drawable.ic_menu)  
}
```

然后，我们还要做两件事：给Toolbar的menu菜单的子项注册监听事件；将Toolbar的menu菜单显示出来。这两件事要分别重写两个函数，代码不多，直接展示了：

```kotlin
override fun onOptionsItemSelected(item: MenuItem): Boolean {  
    when(item.itemId){  
        android.R.id.home -> bindingMain.drawerLayout.openDrawer(GravityCompat.START)  
        R.id.backup -> Log.d("SpreadShopTest", "you clicked backup")  
        R.id.delete -> Log.d("SpreadShopTest", "you clicked delete")  
        R.id.settings -> Log.d("SpreadShopTest", "you clicked settings")  
    }  
    return true  
}  
  
override fun onCreateOptionsMenu(menu: Menu?): Boolean {  
    menuInflater.inflate(R.menu.toolbar, menu)  
    return true  
}
```

`openDrawer()`有很多种重载函数，可以自己到源码中看一看。好了，今天的所有进展就到这里了。

# 2022-10-23

一个挺吓人的小问题，我修改了MainActivity的名字，然后觉得不妥又改回来了。但是在运行的时候报了一大堆错。好在下面这个网址和我的情况一样，看起来并不是改名字的问题，而是我引入了下面的依赖而引用了androidx库而导致的冲突：

```groovy
implementation 'androidx.recyclerview:recyclerview:1.0.0'
```

所以根据这个网站：

[编译报错Duplicate class android.support.v4.app.INotificationSideChannel found in modules classes - 北海南竹 - 博客园 (cnblogs.com)](https://www.cnblogs.com/beihainanzhu/p/16117713.html)

在`gradle.properties`里添加这个选项就好了：

```properties
android.enableJetifier=true
```

另外这段代码的解释在下面这个网站：

[(29条消息) [Android][踩坑]gradle中配置android.useAndroidX与android.enableJetifier使应用对support库的依赖自动转换为androidx的依赖_Ryan ZHENG的博客-CSDN博客_enablejetifier](https://blog.csdn.net/u014175785/article/details/115295136)

![[Pasted image 20221023140339.png]]

---

今天我们将MainActivity进行了大改，在DrawerLayout的基础上添加了很多东西，从`activity_main.xml`开始看，对比[[#^de0cf0|之前的]]CoordinatorLayout，添加了很多东西：

```xml
<?xml version="1.0" encoding="utf-8"?>  
<androidx.drawerlayout.widget.DrawerLayout  
    xmlns:android="http://schemas.android.com/apk/res/android"  
    xmlns:app="http://schemas.android.com/apk/res-auto"  
    android:id="@+id/drawer_layout"  
    android:layout_width="match_parent"  
    android:layout_height="match_parent"  
    >  
  
<!--  
    CoordinatorLayout是加强版的FrameLayout，它专为MaterialDesign设计，  
    能够监听其中控件的变化。-->  
  
    <androidx.coordinatorlayout.widget.CoordinatorLayout  
        android:layout_width="match_parent"  
        android:layout_height="match_parent">  
  
<!--  
    AppBarLayout可以让RecyclerView不遮挡Toolbar，  
    使用app:layout_behavior来指定  
-->  
        <com.google.android.material.appbar.AppBarLayout  
            android:layout_width="match_parent"  
            android:layout_height="wrap_content">  
  
            <androidx.appcompat.widget.Toolbar                
	            android:id="@+id/toolbar"  
                android:layout_width="match_parent"  
                android:layout_height="?attr/actionBarSize"  
                android:background="@color/purple_200"  
                android:theme="@style/ThemeOverlay.AppCompat.Dark.ActionBar"  
                app:popupTheme="@style/ThemeOverlay.AppCompat.Light"  
                />  
  
        </com.google.android.material.appbar.AppBarLayout>  
    
        <androidx.recyclerview.widget.RecyclerView            
	        android:id="@+id/category_recycler"  
            android:layout_width="match_parent"  
            android:layout_height="200dp"  
            app:layout_behavior="@string/appbar_scrolling_view_behavior"  
            />  
<!--  
    想让谁实现下拉刷新功能，就把谁放到SwipeRefresh里，  
    记得添加依赖  
    recyclerview里面的layout_behavior搬到外面  
-->  
        <androidx.swiperefreshlayout.widget.SwipeRefreshLayout  
            android:id="@+id/swipe_refresh"  
            android:layout_width="match_parent"  
            android:layout_height="wrap_content"  
            android:layout_marginTop="250dp"  
            app:layout_anchor="@id/category_recycler"  
            app:layout_anchorGravity="bottom"  
  
            >  
  
            <androidx.recyclerview.widget.RecyclerView                
	            android:id="@+id/goods_recycler"  
                android:layout_width="match_parent"  
                android:layout_height="wrap_content"  
                />  
  
        </androidx.swiperefreshlayout.widget.SwipeRefreshLayout>   
               
  
    </androidx.coordinatorlayout.widget.CoordinatorLayout>  
  
    <com.google.android.material.navigation.NavigationView  
        android:id="@+id/nav_view"  
        android:layout_width="match_parent"  
        android:layout_height="match_parent"  
        android:layout_gravity="start"  
        app:menu="@menu/nav_menu"  
        app:headerLayout="@layout/nav_header"  
        />  
</androidx.drawerlayout.widget.DrawerLayout>
```

多出来的东西全都在CoordinatorLayout中，分别是AppBarLayout、RecyclerView和SwipeRefreshLayout，并且SwipeRefreshLayout中又嵌入了一个RecyclerView。需要注意的是SwipeRefreshLayout中的`android:layout_marginTop="250dp"`属性，它在上方流出了一个空白，这样它才不会遮挡上面的`category_recycler`。**肯定有更好的解决方法，但是我目前没有找到**。

最重要的其实是这两个RecyclerView的东西，我们先从Category开始说起。这是为了加载返回的所有商品的属性的列表，也就是商城里常见的”商品分类“。这个RecyclerView中的项是`category_item.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>  
<com.google.android.material.card.MaterialCardView xmlns:android="http://schemas.android.com/apk/res/android"  
    android:layout_width="match_parent"  
    android:layout_height="match_parent">  
  
    <LinearLayout        
	    android:orientation="vertical"  
        android:layout_width="match_parent"  
        android:layout_height="wrap_content"  
        >  
  
        <LinearLayout            
	        android:orientation="horizontal"  
            android:layout_width="match_parent"  
            android:layout_height="wrap_content"  
            >  
  
            <ImageView                
	            android:id="@+id/category_image"  
                android:layout_width="300dp"  
                android:layout_height="100dp"  
                android:scaleType="fitCenter"  
                />  
  
            <TextView                
	            android:id="@+id/category_name"  
                android:layout_width="wrap_content"  
                android:layout_height="wrap_content"  
                android:layout_gravity="center"  
                android:text="test"  
                android:textColor="@color/black"  
                android:textSize="16sp"  
                />  
  
        </LinearLayout>  
  
    </LinearLayout>  
</com.google.android.material.card.MaterialCardView>
```

非常简单，没什么好说的。唯一的特点是图片的`android:scaleType="fitCenter"`这个属性，它是让图片从中间开始进行合适的缩放。

接下来自然是创建对应的Adapter来加载它了。创建`ui/goods/CategoryAdapter`类：

```kotlin
class CategoryAdapter(val context: Context, val categoryList: List<Category>): RecyclerView.Adapter<CategoryAdapter.ViewHolder>() {  

    inner class ViewHolder(view: View): RecyclerView.ViewHolder(view){  
        val categoryName: TextView = view.findViewById(R.id.category_name)  
        val categoryImage: ImageView = view.findViewById(R.id.category_image)  
    }  
  
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {  
        val view = LayoutInflater.from(context).inflate(R.layout.category_item, parent, false)  
        return ViewHolder(view)  
    }  
  
    override fun onBindViewHolder(holder: ViewHolder, position: Int) {  
        val category = categoryList[position]  
        holder.categoryName.text = category.category  
        Log.d("SpreadShopTest", "category name: ${category.category}")  
        val id: Int  
        when(category.category){  
            "手机" -> {  
                Log.d("SpreadShopTest", "category id: 手机")  
                id = R.drawable.ic_phone  
            }  
            "衣服" -> {  
                Log.d("SpreadShopTest", "category id: 衣服")  
                id = R.drawable.ic_cloth  
            }  
            "裤子" -> {  
                Log.d("SpreadShopTest", "category id: 裤子")  
                id = R.drawable.ic_trousers  
            }  
            else -> {  
                Log.d("SpreadShopTest", "category id: else")  
                id = R.drawable.test_maotai  
            }  
        }  
  
  
        Log.d("SpreadShopTest", "val id: $id")  
  
        Glide.with(context).load(id).into(holder.categoryImage)  
    }  
  
    override fun getItemCount() = categoryList.size  
}
```

这里我们使用了Glide插件去加载图片，因此我再给一遍当前项目中的所有依赖：

```groovy
dependencies {  
    implementation 'androidx.core:core-ktx:1.7.0'  
    implementation 'androidx.appcompat:appcompat:1.5.1'  
    implementation 'com.google.android.material:material:1.5.0'  
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'  
    implementation 'com.squareup.retrofit2:retrofit:2.6.1'  
    implementation 'com.squareup.retrofit2:converter-gson:2.6.1'  
    implementation 'com.google.android.material:material:1.1.0'  
    implementation 'de.hdodenhof:circleimageview:3.0.1'  
    implementation 'androidx.recyclerview:recyclerview:1.0.0'  
    implementation 'androidx.swiperefreshlayout:swiperefreshlayout:1.0.0'  
    implementation 'com.github.bumptech.glide:glide:4.9.0'  
    testImplementation 'junit:junit:4.13.2'  
    androidTestImplementation 'androidx.test.ext:junit:1.1.3'  
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.4.0'  
}
```

[[#^8aea9b|这是之前的依赖]]。

然后就是在MainActivity的categoryLiveData中去观察变量，并在相应处理中设置Adapter，这样就能在界面上显示拿到的结果了：

```kotlin
mainViewModel.categoryLiveData.observe(this){  
    it.enqueue(object: Callback<CategoryResponse>{  
        override fun onResponse(  
            call: Call<CategoryResponse>,  
            response: Response<CategoryResponse>  
        ) {  
            val categoryResponse = response.body()  
            if(categoryResponse != null){  
                if(categoryResponse.success){  
                    Log.d("SpreadShopTest", "category success")  
                    val list = categoryResponse.categories  
  
                    // category recycler  
                    val layoutManager = GridLayoutManager(this@MainActivity, 1)  
                    bindingMain.categoryRecycler.layoutManager = layoutManager  
                    val adapter = CategoryAdapter(this@MainActivity, list)  
                    bindingMain.categoryRecycler.adapter = adapter  
  
                    for(category in list){  
                        Log.d("SpreadShopTest", "category: $category")  
                    }  
                }else{  
                    Log.d("SpreadShopTest", "Category fail")  
                }  
            }else{  
                Log.d("SpreadShopTest", "category is null")  
            }  
        }  
  
        override fun onFailure(call: Call<CategoryResponse>, t: Throwable) {  
            t.printStackTrace()  
            Log.d("SpreadShopTest", "category on failure")  
        }  
    })  
}// end mainViewModel.categoryLiveData.observe
```

对于商品的处理和Category其实一模一样，**唯一的区别是显示上的一些细节**。所以我还是按照`xml -> Adapter -> MainActivity`的顺序直接给出相应代码：

```xml
<?xml version="1.0" encoding="utf-8"?>  
<com.google.android.material.card.MaterialCardView xmlns:android="http://schemas.android.com/apk/res/android"  
    android:layout_width="match_parent"  
    android:layout_height="match_parent">  
  
<!--  
    一张Material卡片，之后这一张张卡片都会添加到  
    recyclerView当中  
  
    centerCrop: 让图片保持原有比例填充满ImageView，  
    并将超出屏幕的部分裁剪掉-->  
    <LinearLayout  
        android:orientation="vertical"  
        android:layout_width="match_parent"  
        android:layout_height="wrap_content"  
        >  
  
        <ImageView            
	        android:id="@+id/goods_image"  
            android:layout_width="match_parent"  
            android:layout_height="100dp"  
            android:scaleType="centerCrop"  
            />  
  
        <TextView            
	        android:id="@+id/goods_name"  
            android:layout_width="wrap_content"  
            android:layout_height="wrap_content"  
            android:layout_gravity="center_horizontal"  
            android:layout_margin="5dp"  
            android:text="test"  
            android:textSize="16sp"  
            />  
  
    </LinearLayout>  
</com.google.android.material.card.MaterialCardView>
```

```kotlin
class GoodsAdapter(val context: Context, val goodsList: List<Goods>): RecyclerView.Adapter<GoodsAdapter.ViewHolder>(){  

    inner class ViewHolder(view: View): RecyclerView.ViewHolder(view){  
        val goodsImage: ImageView = view.findViewById(R.id.goods_image)  
        val goodsName: TextView = view.findViewById(R.id.goods_name)  
    }  
  
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {  
        val view = LayoutInflater.from(context).inflate(R.layout.goods_item, parent, false)  
        return ViewHolder(view)  
    }  
  
    override fun onBindViewHolder(holder: ViewHolder, position: Int) {  
        val goods = goodsList[position]  
        holder.goodsName.text = goods.goods_name
        // 所有商品暂时都是茅台的图片  
        Glide.with(context).load(R.drawable.test_maotai).into(holder.goodsImage)  
    }  
  
    override fun getItemCount() = goodsList.size  
}
```

```kotlin
mainViewModel.goodsLiveData.observe(this){  
    it.enqueue(object : Callback<GoodsResponse>{  
        override fun onResponse(call: Call<GoodsResponse>, response: Response<GoodsResponse>) {  
            val goodsResponse = response.body()  
            if(goodsResponse != null){  
                Log.d("SpreadShopTest", "goodsResponse is not null")  
                if(goodsResponse.success){  
                    Log.d("SpreadShopTest", "goodsResponse success!")  
                    val list = goodsResponse.goods  
  
                    // goods recycler  
                    val layoutManager = GridLayoutManager(this@MainActivity, 2)  
                    bindingMain.goodsRecycler.layoutManager = layoutManager  
                    val adapter = GoodsAdapter(this@MainActivity, list)  
                    bindingMain.goodsRecycler.adapter = adapter  
  
                    for(goods in list){  
                        Log.d("SpreadShopTest", "goods: ${goods.goods_name}")  
                    }  
                }else{  
                    Log.d("SpreadShopTest", "goodsResponse fail!")  
                }  
            }else{  
                Log.d("SpreadShopTest", "goodsResponse is null")  
            }  
        }  
  
        override fun onFailure(call: Call<GoodsResponse>, t: Throwable) {  
            t.printStackTrace()  
            Log.d("SpreadShopTest", "goodsResponse on failure")  
        }  
    })  
}// end mainViewModel.goodsLiveData.observe
```

# 2022-10-25

这次主要是做了下拉刷新的逻辑端操作，并且已经测试成功。需要注意的是，本次的更新改动比较大，将原来的Retrofit处理响应的操作整个更换了。

之前我们的思路是：如果接到Retrofit的响应数据，就在响应操作中设置RecyclerView的adapter之类的。但是，这种思路是**完全错误的！**首先，我们每发一次请求，都会调一次这个函数，那么这个函数每次都会新建一个adapter，而RecyclerView通常都是一个adapter用到底；其次，我们将adapter在这里设置成局部变量，在外部又如何能够通知数据发生了改变？

因此，我们首先需要将Adapter移到响应处理的外面，也就是直接包含在Activity的onCreate方法里：

```kotlin
override fun onCreate(savedInstanceState: Bundle?) {  

... ...

        // 打开MainActivity之后立刻发起请求获取所有的种类  
        mainViewModel.getAllCategory(Command.GET_ALL_CATEGORY)  
        // 打开之后获取一次推荐商品  
        mainViewModel.getGoods(Command.GET_RECOMMAND)  
  
        // 设置goodsRecycler的adapter  
        // 由于ArrayList的构造函数，所以goodsList不为空  
        val goodsLayoutManager = GridLayoutManager(this, 2)  
        bindingMain.goodsRecycler.layoutManager = goodsLayoutManager  
        val goodsAdapter = GoodsAdapter(this, mainViewModel.goodsList)  
        bindingMain.goodsRecycler.adapter = goodsAdapter  

... ...

    }// end onCreate
```

可以看到，我们在Activity创建的时候，就将goodsRecycler的LayoutManager和Adapter设置好。需要注意的是adapter中的第二个参数：`mainViewModel.goodsList`。这个是在MainViewModel中定义的一个`ArrayList`，专门用来存放最终获取到的结果。那么可想而知，在相应处理函数中我们就需要更新这个ArrayList了：

```kotlin
mainViewModel.goodsLiveData.observe(this){  
	it.enqueue(object : Callback<GoodsResponse>{  
		override fun onResponse(call: Call<GoodsResponse>, response: Response<GoodsResponse>) {  
			val goodsResponse = response.body()  
			if(goodsResponse != null){  
				Log.d("SpreadShopTest", "goodsResponse is not null")  
				if(goodsResponse.success){  
					Log.d("SpreadShopTest", "goodsResponse success!")  
					
					val list = goodsResponse.goods  

					mainViewModel.goodsList.clear()  
					mainViewModel.goodsList.addAll(list)  
					mainViewModel.isGotLiveData.value = true  
				}else{  
					Log.d("SpreadShopTest", "goodsResponse fail!")  
				}  
			}else{  
				Log.d("SpreadShopTest", "goodsResponse is null")  
			}  
		}  

		override fun onFailure(call: Call<GoodsResponse>, t: Throwable) {  
			t.printStackTrace()  
			mainViewModel.goodsList.clear()  
			mainViewModel.isGotLiveData.value = false  
			Log.d("SpreadShopTest", "goodsResponse on failure")  
		}  
	})  
}// end mainViewModel.goodsLiveData.observe
```

可以看到，如果我们成功得到了返回的`Callback<List<Goods>>`，我们就执行如下代码：

```kotlin
val list = goodsResponse.goods  
mainViewModel.goodsList.clear()  
mainViewModel.goodsList.addAll(list)  
mainViewModel.isGotLiveData.value = true  
```

首先将MainViewModel的goodsList清空，然后将我们得到的新数据全部放进去，最后设置其中的标志位为true；而如果我们没有拿回响应数据，就是这样的处理：

```kotlin
t.printStackTrace()  
mainViewModel.goodsList.clear()  
mainViewModel.isGotLiveData.value = false  
Log.d("SpreadShopTest", "goodsResponse on failure")  
```

只是清空列表，然后将标志位设置为false。**这两个标志位的设置非常重要，它会触发接下来的一个操作**：

```kotlin
mainViewModel.isGotLiveData.observe(this){  

	if(it == true){  
		Log.d("SpreadShopTest", "got live data!")  
	}else{  
		Log.d("SpredShopTest", "didn't got live data")  
		Toast.makeText(this@MainActivity, "refresh failed", 
			 Toast.LENGTH_SHORT).show()  
	}  
	
	runOnUiThread {  
		goodsAdapter.notifyDataSetChanged()  
		bindingMain.swipeRefresh.isRefreshing = false  
	}  
}
```

一旦标志位设置，我们就起一个新线程，告知adapter数据发生了改变，并取消刷新的进度条。通过这样设置，就能实现即使刷新失败也不会让那个圈圈一直转了。另外，刷新布局的监听器只需要做这样一件事：

```kotlin
bindingMain.swipeRefresh.setOnRefreshListener {  
    mainViewModel.getGoods(Command.GET_RECOMMAND)  
}
```

这样我们只要下拉一刷新，就会发起请求，就会调用enqueue函数，就会将标志位设置成一个新的值，就会触发标志livedata的observe，就会通知adapter数据发生了改变。经过这环环相扣的操作，从后端到前端都实现了数据更新操作。最后补充一下MainViewModel更新完的代码：

```kotlin
class MainViewModel: ViewModel() {  

    val goodsList = ArrayList<Goods>()  
  
    val isGotLiveData = MutableLiveData<Boolean>()  
  
    val goodsLiveData: LiveData<Call<GoodsResponse>>  
        get() = _goodsLiveData  
    private val _goodsLiveData = MutableLiveData<Call<GoodsResponse>>()  
  
    val categoryLiveData: LiveData<Call<CategoryResponse>>  
        get() = _categoryLiveData  
    private val _categoryLiveData = MutableLiveData<Call<CategoryResponse>>()  
  
    fun getGoods(cmd: String) {  
        _goodsLiveData.value = Repository.getGoods(cmd)  
    }  
  
    fun getAllCategory(cmd: String){  
        _categoryLiveData.value = Repository.getAllCategory(cmd)  
    }  
}
```

以及整个MainActivity的流程代码：

```kotlin
class MainActivity : AppCompatActivity() {  
  
    private lateinit var bindingMain: ActivityMainBinding  
    private lateinit var bindingNavHeader: NavHeaderBinding  
  
    override fun onCreate(savedInstanceState: Bundle?) {  
        super.onCreate(savedInstanceState)  
        bindingMain = ActivityMainBinding.inflate(layoutInflater)  
        bindingNavHeader = NavHeaderBinding.inflate(layoutInflater)  
        setContentView(bindingMain.root)  
  
        setSupportActionBar(bindingMain.toolbar)  

        //let和apply都可以  
        supportActionBar?.apply {  
            setDisplayHomeAsUpEnabled(true)  
            setHomeAsUpIndicator(R.drawable.ic_menu)  
        }  
  
        val username = intent.getStringExtra("username")  
        Log.d("SpreadShopTest", "Log in username: $username")  
        
        if(bindingMain.navView.headerCount > 0){  
            val header = bindingMain.navView.getHeaderView(0)  
            val uname = header.findViewById<TextView>(R.id.user_name)  
            uname.text = "user name: $username"  
        }  
  
  
  
        val mainViewModel = ViewModelProvider(this)
					        .get(MainViewModel::class.java)  
  
        // 打开MainActivity之后立刻发起请求获取所有的种类  
        mainViewModel.getAllCategory(Command.GET_ALL_CATEGORY)  
  
        // 打开之后获取一次推荐商品  
        mainViewModel.getGoods(Command.GET_RECOMMAND)  
  
        // 设置goodsRecycler的adapter  
        // 由于ArrayList的构造函数，所以goodsList不为空  
        val goodsLayoutManager = GridLayoutManager(this, 2)  
        bindingMain.goodsRecycler.layoutManager = goodsLayoutManager  
        val goodsAdapter = GoodsAdapter(this, mainViewModel.goodsList)  
        bindingMain.goodsRecycler.adapter = goodsAdapter    
  
        mainViewModel.goodsLiveData.observe(this){  
            it.enqueue(object : Callback<GoodsResponse>{  
                override fun onResponse(call: Call<GoodsResponse>, response: Response<GoodsResponse>) {  
                    val goodsResponse = response.body()  
                    if(goodsResponse != null){  
                        Log.d("SpreadShopTest", "goodsResponse is not null")  
                        if(goodsResponse.success){  
                            Log.d("SpreadShopTest", "goodsResponse success!")  
                            val list = goodsResponse.goods  
  
                            mainViewModel.goodsList.clear()  
                            mainViewModel.goodsList.addAll(list)  
                            mainViewModel.isGotLiveData.value = true  

                        }else{  
                            Log.d("SpreadShopTest", "goodsResponse fail!")  
                        }  
                    }else{  
                        Log.d("SpreadShopTest", "goodsResponse is null")  
                    }  
                }  
  
                override fun onFailure(call: Call<GoodsResponse>, t: Throwable) {  
                    t.printStackTrace()  
                    mainViewModel.goodsList.clear()  
                    mainViewModel.isGotLiveData.value = false  
                    Log.d("SpreadShopTest", "goodsResponse on failure")  
                }  
            })  
        }// end mainViewModel.goodsLiveData.observe  
  
        mainViewModel.categoryLiveData.observe(this){  
            it.enqueue(object: Callback<CategoryResponse>{  
                override fun onResponse(  
                    call: Call<CategoryResponse>,  
                    response: Response<CategoryResponse>  
                ) {  
                    val categoryResponse = response.body()  
                    if(categoryResponse != null){  
                        if(categoryResponse.success){  
                            Log.d("SpreadShopTest", "category success")  
                            val list = categoryResponse.categories  
  
                            // category recycler  
                            val categoryLayoutManager = 
		                            GridLayoutManager(this@MainActivity, 1)  
		                    
                            bindingMain.categoryRecycler.layoutManager = 
				                            categoryLayoutManager 


                            val adapter = 
		                            CategoryAdapter(this@MainActivity, list)  
		                        
                            bindingMain.categoryRecycler.adapter = adapter  

                        }else{  
                            Log.d("SpreadShopTest", "Category fail")  
                        }  
                    }else{  
                        Log.d("SpreadShopTest", "category is null")  
                    }  
                }  
  
                override fun onFailure(call: Call<CategoryResponse>, t: Throwable) {  
                    t.printStackTrace()  
                    Log.d("SpreadShopTest", "category on failure")  
                }  
            })  
        }// end mainViewModel.categoryLiveData.observe  
  
  
        mainViewModel.isGotLiveData.observe(this){  
            if(it == true){  
                Log.d("SpreadShopTest", "got live data!")  
            }else{  
                Log.d("SpredShopTest", "didn't got live data")  
                Toast.makeText(this@MainActivity, "refresh failed", Toast.LENGTH_SHORT).show()  
            }  
  
            runOnUiThread {  
                goodsAdapter.notifyDataSetChanged()  
                bindingMain.swipeRefresh.isRefreshing = false  
            }  
        }  
        bindingMain.navView.setNavigationItemSelectedListener {  
            when(it.itemId){  
                R.id.nav_mybag -> Log.d("SpreadShopTest", "You clicked mybag")  
                R.id.nav_order -> Log.d("SpreadShopTest", "You clicked myorder")  
                R.id.nav_contact -> Log.d("SpreadShopTest", "You clicked Contact")  
                R.id.nav_logout -> Log.d("SpreadShopTest", "You clicked logout")  
            }  
            bindingMain.drawerLayout.closeDrawers()  
            true  
        }  
  
        bindingMain.swipeRefresh.setOnRefreshListener {  
            mainViewModel.getGoods(Command.GET_RECOMMAND)  
        }  
  
    }// end onCreate  
  
    override fun onOptionsItemSelected(item: MenuItem): Boolean {  
        when(item.itemId){  
            android.R.id.home -> bindingMain.drawerLayout.openDrawer(GravityCompat.START)  
            R.id.backup -> Log.d("SpreadShopTest", "you clicked backup")  
            R.id.delete -> Log.d("SpreadShopTest", "you clicked delete")  
            R.id.settings -> Log.d("SpreadShopTest", "you clicked settings")  
        }  
        return true  
    }  
  
    override fun onCreateOptionsMenu(menu: Menu?): Boolean {  
        menuInflater.inflate(R.menu.toolbar, menu)  
        return true  
    }  
  
}
```

**注：此时Category的操作流程还没改，最后要改成和goods一样的模式。**

# 2022-10-26

今天我感觉并没有费多少功夫，但是今天对我项目的改变是最大的！

![[Pasted image 20221026211618.png|200]]

先来嘚瑟一下\~\~，我们按着昨天的思路来，将下拉刷新处理完毕之后，首先我们要做的是更改这个MaterialCardView，因为它之前实在是太丑了。在这里我就直接展示所有和商品信息相关的xml代码了：

首先是`activity_main.xml`中的SwipeRefreshLayout：

```xml
<androidx.swiperefreshlayout.widget.SwipeRefreshLayout  
    android:id="@+id/swipe_refresh"  
    android:layout_width="match_parent"  
    android:layout_height="wrap_content"  
    android:layout_marginTop="110dp"  
    app:layout_anchor="@id/category_recycler"  
    app:layout_anchorGravity="bottom"  
    app:layout_behavior="@string/appbar_scrolling_view_behavior"  
    >  
  
    <androidx.recyclerview.widget.RecyclerView        
	    android:id="@+id/goods_recycler"  
        android:layout_width="match_parent"  
        android:layout_height="wrap_content"  
        />  
  
  
</androidx.swiperefreshlayout.widget.SwipeRefreshLayout>
```

可以看到，我们只是把对上面的留白改成了110dp。接下来是这个RecyclerView中展示的卡片项目：

```xml
<?xml version="1.0" encoding="utf-8"?>  
<com.google.android.material.card.MaterialCardView xmlns:android="http://schemas.android.com/apk/res/android"  
    xmlns:app="http://schemas.android.com/apk/res-auto"  
    android:layout_width="match_parent"  
    android:layout_height="wrap_content"  
    app:rippleColor="@color/material_dynamic_neutral90"  
    android:layout_margin="5dp"  
    >  
  
<!--  
    app:strokeColor="@color/material_dynamic_neutral70"    app:strokeWidth="5dp"    app:cardElevation="8dp"    app:cardCornerRadius="8dp"-->  
  
<!--  
    一张Material卡片，之后这一张张卡片都会添加到  
    recyclerView当中  
  
    centerCrop: 让图片保持原有比例填充满ImageView，  
    并将超出屏幕的部分裁剪掉-->  
    <LinearLayout  
        android:orientation="vertical"  
        android:layout_width="match_parent"  
        android:layout_height="wrap_content"  
        >  
  
        <ImageView            
	        android:id="@+id/goods_image"  
            android:layout_width="match_parent"  
            android:layout_height="100dp"  
            android:scaleType="centerCrop"  
            />  
  
        <TextView            
	        android:id="@+id/goods_name"  
            android:layout_width="match_parent"  
            android:layout_height="wrap_content"  
            android:layout_gravity="center_horizontal"  
            android:layout_margin="5dp"  
            android:text="test"  
            android:textSize="16sp"  
            android:gravity="center"  
            android:background="@color/material_dynamic_neutral70"  
            android:textColor="@color/black"  
            />  
  
    </LinearLayout>  
</com.google.android.material.card.MaterialCardView>
```

最重要的是CardView中的layout_height属性，我之前就是写的match_parent，结果一张卡片直接和屏幕一样高。接下来，是展示类别的RecyclerView：

```xml
<androidx.recyclerview.widget.RecyclerView  
    android:id="@+id/category_recycler"  
    android:layout_width="match_parent"  
    android:layout_height="50dp"  
    app:layout_behavior="@string/appbar_scrolling_view_behavior"  
    />
```

这个的高度只有50dp，所以才能像这样短小精悍：

![[Pasted image 20221026212959.png]]

然后就是其中展示的类别卡片了：

```xml
<?xml version="1.0" encoding="utf-8"?>  
<com.google.android.material.card.MaterialCardView xmlns:android="http://schemas.android.com/apk/res/android"  
    xmlns:app="http://schemas.android.com/apk/res-auto"  
    android:layout_width="wrap_content"  
    android:layout_height="match_parent"  
    app:rippleColor="@color/material_dynamic_neutral90"  
    >  
  
  
        <LinearLayout            
	        android:orientation="horizontal"  
            android:layout_width="match_parent"  
            android:layout_height="match_parent"  
            >  
  
            <ImageView                
	            android:id="@+id/category_image"  
                android:layout_width="wrap_content"  
                android:layout_height="match_parent"  
                android:layout_gravity="center_vertical"  
                android:scaleType="fitCenter"  
                android:background="@color/material_dynamic_neutral90"  
                />  
  
            <TextView                
	            android:id="@+id/category_name"  
                android:layout_width="0dp"  
                android:layout_height="match_parent"  
                android:layout_weight="1"  
                android:layout_gravity="center"  
                android:text="test"  
                android:gravity="center"  
                android:textColor="@color/black"  
                android:textSize="16sp"  
                android:background="@color/material_dynamic_neutral70"  
                />  
  
        </LinearLayout>  
  
</com.google.android.material.card.MaterialCardView>
```

这里的精髓还是在最外层布局：width是wrap，所以横向上只会包住图片和文字的宽度；而height是match，而它的parent正好就是上面的RecyclerView，而它的高度是50dp，所以卡片的高度也是50dp。另外这里TextView的这两个参数：`layout_width`和`layout_weight`表示它会在宽度上占掉所有图片剩下来的空间。

另外，你还能看到，我在标题栏加了一个搜索栏，这用的是官方提供的SearchView。它被当成菜单项加到了Toolbar当中：

```xml
<com.google.android.material.appbar.AppBarLayout  
    android:layout_width="match_parent"  
    android:layout_height="wrap_content">  
  
    <androidx.appcompat.widget.Toolbar        
	    android:id="@+id/toolbar"  
        android:layout_width="match_parent"  
        android:layout_height="?attr/actionBarSize"  
        android:background="@color/material_dynamic_neutral60"  
        android:theme="@style/ThemeOverlay.AppCompat.Dark.ActionBar"  
        app:popupTheme="@style/ThemeOverlay.AppCompat.Light"  
        app:layout_scrollFlags="scroll|enterAlways|snap"  
        />  
  
</com.google.android.material.appbar.AppBarLayout>
```

```xml
<?xml version="1.0" encoding="utf-8"?>  
<menu xmlns:android="http://schemas.android.com/apk/res/android"  
    xmlns:app="http://schemas.android.com/apk/res-auto">  
  
<!--  
    menu文件夹里的所有试图都是菜单  
        toolbar就是上面工具栏专用的菜单  
        而nav_menu就是Navigation View专用的菜单  
-->  
  
<!--  
    always: 永远显示再Toolbar中，空间不够不显示  
    ifRoom: 屏幕够就显示，不够显示再菜单中  
    never: 永远显示在菜单  
-->  
  
    <item  
        android:id="@+id/search_edit"  
        android:icon="@drawable/ic_search"  
        app:actionViewClass="android.widget.SearchView"  
        app:showAsAction="always|collapseActionView"  
        android:title="search_edit"  
        />  
</menu>
```

`app:actionViewClass`就是制定当前的item到底是什么类型的。接下来，我就将按照如下顺序来展示我所有的前端代码的逻辑部分：

* GoodsAdapter实现
* CategoryAdapter实现
* SearchView实现

首先是GoodsAdapter，主要的操作就是，当我点击了每一项，都要打开商品详情的Activity：

```kotlin
class GoodsAdapter(val context: Context, val goodsList: List<Goods>): RecyclerView.Adapter<GoodsAdapter.ViewHolder>(){  
  
    inner class ViewHolder(view: View): RecyclerView.ViewHolder(view){  
        val goodsImage: ImageView = view.findViewById(R.id.goods_image)  
        val goodsName: TextView = view.findViewById(R.id.goods_name)  
    }  
  
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {  
        val view = LayoutInflater.from(context).inflate(R.layout.goods_item, parent, false)  
        val holder = ViewHolder(view)  
        holder.itemView.setOnClickListener {  
            val mainActivity = context as MainActivity  
            val position = holder.adapterPosition  
            val goods = goodsList[position]  
            val intent = Intent(context, GoodsActivity::class.java).apply {  
                putExtra("goods_name", goods.goods_name)  
                putExtra("goods_storage", goods.goods_storage)  
                putExtra("goods_price", goods.goods_price)  
                putExtra("goods_category", goods.goods_category)  
                putExtra("goods_id", goods.goods_id)  
                putExtra("username", mainActivity.mainViewModel.username)  
            }  
            context.startActivity(intent)  
        }  
        return holder  
//        return ViewHolder(view)  
    }  
  
    override fun onBindViewHolder(holder: ViewHolder, position: Int) {  
        val goods = goodsList[position]  
        holder.goodsName.text = goods.goods_name  
        val id = "ic_goods_${goods.goods_id}"  
        Glide.with(context).load(Command.getImageByReflect(id)).into(holder.goodsImage)  
    }  
  
    override fun getItemCount() = goodsList.size  
}
```

intent的部分特别简单，就不多说了。重要的是这个Glide的改变。我们之前只加载一个图片，而现在我们对于不同的商品能展示不同的图片了。这里我们定义了一个`getImageByReflect`函数，这个函数就是通过反射去获取真正的图片id：

```kotlin
fun getImageByReflect(imageName: String): Int{  
    var field: Class<*>  
    var res = 0  
    try {  
        field = Class.forName("com.example.spreadshop.R\$drawable")  
        res = field.getField(imageName).getInt(field)  
  
    }catch (e: java.lang.Exception){  
        e.printStackTrace()  
        Log.d("SpreadShopTest", "getImageByReflect exception!")  
    }  
  
    return res  
}
```

我们都知道，在`drawable`下创建了文件`ic_test.png`，那么对应的就会在`R.drawable`下新建一个Int类型的变量叫做`ic_test`。我们这个函数的目的就是通过前者去寻找后者。其中需要注意的是这个内部类的写法：`com.example.spreadshop.R\$drawable`在java中，我们只需要这么写：`com.example.spreadshop.R$drawable`，**但是kotlin增加了字符串嵌套变量的操作，所以要转义一下**。经过这么一个转换，我们就能按照`goods_id`去加载手机中已经存好的照片(这样其实是不对的，但是也没办法，我们还不知道怎么在MySQL中存图片)。

接下来是CategoryAdapter：

```kotlin
class CategoryAdapter(val context: Context, val categoryList: List<Category>): RecyclerView.Adapter<CategoryAdapter.ViewHolder>() {  
    inner class ViewHolder(view: View): RecyclerView.ViewHolder(view){  
        val categoryName: TextView = view.findViewById(R.id.category_name)  
        val categoryImage: ImageView = view.findViewById(R.id.category_image)  
    }  
  
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {  
        val view = LayoutInflater.from(context).inflate(R.layout.category_item, parent, false)  
        val holder = ViewHolder(view)  
        holder.itemView.setOnClickListener {  
            val position = holder.adapterPosition  
            val category = categoryList[position]  
            val mainActivity = context as MainActivity  
            mainActivity.mainViewModel.getGoods(Command.getCategoryGoods(category.category))  
        }  
        return holder  
//        return ViewHolder(view)  
    }  
  
    override fun onBindViewHolder(holder: ViewHolder, position: Int) {  
        val category = categoryList[position]  
        holder.categoryName.text = category.category  
        Log.d("SpreadShopTest", "category name: ${category.category}")  
        val id: Int  
        when(category.category){  
            "手机" -> {  
                Log.d("SpreadShopTest", "category id: 手机")  
                id = R.drawable.ic_phone  
            }  
            "衣服" -> {  
                Log.d("SpreadShopTest", "category id: 衣服")  
                id = R.drawable.ic_cloth  
            }  
            "裤子" -> {  
                Log.d("SpreadShopTest", "category id: 裤子")  
                id = R.drawable.ic_trousers  
            }  
            else -> {  
                Log.d("SpreadShopTest", "category id: else")  
                id = R.drawable.test_maotai  
            }  
        }  
  
  
        Log.d("SpreadShopTest", "val id: $id")  
  
        Glide.with(context).load(id).into(holder.categoryImage)  
    }  
  
    override fun getItemCount() = categoryList.size  
}
```

这里的变化就是，我们要对每一项设置监听器：当点击这个类别时，就发起按着这个类别去找商品的请求。而返回类型是GoodsResponse，那么自然就会刷新下面的GoodsRecyclerView了。

另外，我们不是将这个RecyclerView改成了横着的吗？只需要这么一句话：

```kotlin
val categoryLayoutManager = GridLayoutManager(this, 1)  
categoryLayoutManager.orientation = LinearLayoutManager.HORIZONTAL  
bindingMain.categoryRecycler.layoutManager = categoryLayoutManager  
val categoryAdapter = CategoryAdapter(this, mainViewModel.categoryList)  
bindingMain.categoryRecycler.adapter = categoryAdapter
```

就是第二行中的这句话，将方向变成了水平的。

然后是这个SearchView的逻辑代码。由于我们将它放在了Toolbar中作为菜单的一项，那么它的出生自然要在`onCreateOptionsMenu`方法中了：

```kotlin
override fun onCreateOptionsMenu(menu: Menu?): Boolean {  
	menuInflater.inflate(R.menu.toolbar, menu)  

	val searchItem = menu?.findItem(R.id.search_edit)  
	//searchEdit = findViewById(R.id.search_edit)  
	//searchEdit = MenuItemCompat.getActionView(searchItem) as SearchView 
	searchEdit = searchItem?.actionView as SearchView  

	searchEdit.isSubmitButtonEnabled = true  
	searchEdit.imeOptions = EditorInfo.IME_ACTION_SEARCH  

	searchEdit.setOnQueryTextListener(object : SearchView.OnQueryTextListener{  
		override fun onQueryTextSubmit(query: String?): Boolean {  
			if(query != null){  
				mainViewModel.getGoods(Command.getSearchGoods(query))  
			}else{  
				Log.d("SpreadShopTest", "SearchView: query is null")  
			}  
			inputMethodManager.hideSoftInputFromWindow(searchEdit.windowToken, InputMethodManager.HIDE_NOT_ALWAYS)  
			return true  
		}  


		override fun onQueryTextChange(newText: String?): Boolean {  
			if(newText == ""){  
				mainViewModel.getGoods(Command.GET_RECOMMAND)  
			}  
			return true  
		}  
	})  
	return true  
}
```

我们可以通过这两行代码从menu中获取到SearchView的实例：

```kotlin
val searchItem = menu?.findItem(R.id.search_edit)  
searchEdit = searchItem?.actionView as SearchView 
```

我注释掉的是java中已经过时的写法。接下来是对这个SearchView的参数进行一些设置。这里我就引入一些网站了：

[Android的SearchView详解 (wjhsh.net)](http://wjhsh.net/yueshangzuo-p-8685810.html)

[详细解读Android中的搜索框（三）—— SearchView - developer_Kale - 博客园 (cnblogs.com)](https://www.cnblogs.com/tianzhijiexian/p/4226675.html)

然后我们进行两个比较重要的设置：点击提交按钮发生的事，以及清空输入框发生的事。这里的代码很好看懂，唯一要注意的是在点击提交按钮后，要使用`hideSoftInputFromWindow`关闭输入法，这样能增加用户体验。

---

补充一点在NavigationView更新用户名的代码。如果直接使用binding去获取这个TextView并设置值是无效的，经过搜索找到了这种实现很像java的代码：

```kotlin
mainViewModel.username = intent.getStringExtra("username").toString()  
if(bindingMain.navView.headerCount > 0){  
	val header = bindingMain.navView.getHeaderView(0)  
	val uname = header.findViewById<TextView>(R.id.user_name)  
	uname.text = "user name: ${mainViewModel.username}"  
}
```

目前还并不清楚这么写起效果和不这么写没效果的原因，有待研究。

---

接下来是商品的详情页。这部分其实和《第一行代码》的12.7是一个模子，所以不重要的部分就一步带过了。首先是前端代码：

```xml
<?xml version="1.0" encoding="utf-8"?>  
<androidx.coordinatorlayout.widget.CoordinatorLayout  
    xmlns:android="http://schemas.android.com/apk/res/android"  
    xmlns:app="http://schemas.android.com/apk/res-auto"  
    android:layout_width="match_parent"  
    android:layout_height="match_parent"  
    android:fitsSystemWindows="true"  
    >  
  
    <com.google.android.material.appbar.AppBarLayout        
	    android:id="@+id/app_bar"  
        android:layout_width="match_parent"  
        android:layout_height="250dp"  
        android:fitsSystemWindows="true"  
        >  
  
        <com.google.android.material.appbar.CollapsingToolbarLayout            
	        android:id="@+id/collapsing_toolbar"  
            android:layout_width="match_parent"  
            android:layout_height="match_parent"  
            android:theme="@style/ThemeOverlay.AppCompat.Dark.ActionBar"  
            app:contentScrim="@color/teal_200"  
            app:layout_scrollFlags="scroll|exitUntilCollapsed">  
  
            <ImageView                
	            android:id="@+id/goods_image_detail"  
                android:layout_width="match_parent"  
                android:layout_height="match_parent"  
                android:scaleType="centerCrop"  
                app:layout_collapseMode="parallax"  
                />  
  
            <androidx.appcompat.widget.Toolbar                
	            android:id="@+id/toolbar_detail"  
                android:layout_width="match_parent"  
                android:layout_height="?attr/actionBarSize"  
                app:layout_collapseMode="pin"  
                />  
        </com.google.android.material.appbar.CollapsingToolbarLayout>    
    </com.google.android.material.appbar.AppBarLayout>  
    
    <androidx.core.widget.NestedScrollView        
	    android:layout_width="match_parent"  
        android:layout_height="match_parent"  
        app:layout_behavior="@string/appbar_scrolling_view_behavior">  
  
        <LinearLayout            
	        android:orientation="vertical"  
            android:layout_width="match_parent"  
            android:layout_height="wrap_content">  
  
            <com.google.android.material.card.MaterialCardView                
	            android:layout_width="match_parent"  
                android:layout_height="wrap_content"  
                android:layout_marginBottom="15dp"  
                android:layout_marginLeft="15dp"  
                android:layout_marginRight="15dp"  
                android:layout_marginTop="35dp"  
                app:cardCornerRadius="4dp"  
                >  
  
                <TextView                    
	                android:id="@+id/goods_text_detail"  
                    android:layout_width="wrap_content"  
                    android:layout_height="wrap_content"  
                    android:layout_margin="10dp"  
                    />  
            </com.google.android.material.card.MaterialCardView>        
	    </LinearLayout>  
  
    </androidx.core.widget.NestedScrollView>  
    <com.google.android.material.floatingactionbutton.FloatingActionButton        
	    android:id="@+id/buy_btn"  
        android:layout_width="wrap_content"  
        android:layout_height="wrap_content"  
        android:layout_margin="16dp"  
        android:src="@drawable/ic_backup"  
        app:layout_anchor="@id/app_bar"  
        app:layout_anchorGravity="bottom|end"  
        android:contentDescription="buy goods"  
        />  
  
</androidx.coordinatorlayout.widget.CoordinatorLayout>
```

然后是GoodsActivity和GoodsViewModel。没错，这里的逻辑又是比较复杂的，我们从Activity一步一步说起。

首先是展示Home键，这个键默认就是个返回的箭头，所以不用动：

```kotlin
setSupportActionBar(bindingGoods.toolbarDetail)  
supportActionBar?.setDisplayHomeAsUpEnabled(true)
```

然后是一些ViewModel的设置：

```kotlin
goodsViewModel = ViewModelProvider(this).get(GoodsViewModel::class.java)  
  
goodsViewModel.setGoodsName(intent.getStringExtra("goods_name") ?: "null")  
goodsViewModel.setGoodsCategory(intent.getStringExtra("goods_category") ?: "null")  
goodsViewModel.setGoodsPrice(intent.getIntExtra("goods_price", 9999))  
goodsViewModel.setGoodsStorage(intent.getIntExtra("goods_storage", -1))  
goodsViewModel.setGoodsId(intent.getIntExtra("goods_id", -1))  
goodsViewModel.username = intent.getStringExtra("username") ?: ""  
goodsViewModel.isSetFullyLiveData.value = true
```

都是我们从intent拿到的数据，放到了当前Activity的ViewModel层。当所有的LiveData都设置完成后，将`isSetFullyLiveData`置为true。没错，这和我们前面的代码很相似。也就是`isGotGoodsLiveData`和`isGotCategoryLiveData`这样的逻辑(本文章中原来叫`isGotLiveData`，后来改了名字)。那么一旦设置了这个值，就该调用这个方法了：

```kotlin
goodsViewModel.isSetFullyLiveData.observe(this){  
    if(it == true){  
        bindingGoods.collapsingToolbar.title = goodsViewModel.goodsNameLiveData.value  
        val imgId = "ic_goods_${goodsViewModel.goodsIdLiveData.value}"  
        Glide.with(this).load(Command.getImageByReflect(imgId)).into(bindingGoods.goodsImageDetail)  
        bindingGoods.goodsTextDetail.text = generateGoodsDetail()  
    }else{  
        Log.d("SpreadShopTest", "isSetFullyLiveData: false")  
    }  
}
```

这样我们就能将标题，图片，详细信息等乱七八糟的信息都加载上了。这里用到的`generateGoodsDetail`函数是这样的：

```kotlin
private fun generateGoodsDetail(): String{  
    val res = StringBuilder()  
    res.appendLine("goods_name: ${goodsViewModel.goodsNameLiveData.value}")  
    res.appendLine("goods_category: ${goodsViewModel.goodsCategoryLiveData.value}")  
    res.appendLine("goods_price: ${goodsViewModel.goodsPriceLiveData.value}")  
    res.appendLine("goods_storage: ${goodsViewModel.goodsStorageLiveData.value}")  
    val sb = goodsViewModel.goodsNameLiveData.value?.repeat(500)  
    res.append(sb)  
    return res.toString()  
}
```

非常简单，就不多赘述了。

---

接下来是购买功能，我打算用这个FloatButton去当购买按键，当点击之后，弹出一个窗口询问你购买的数量。而这时我恰好找到了一个非常好用的第三方库——XPopup：

[XPopup: 🔥XPopup2.0版本重磅来袭，2倍以上性能提升，带来可观的动画性能优化和交互细节的提升！！！功能强大，交互优雅，动画丝滑的通用弹窗！可以替代Dialog，PopupWindow，PopupMenu，BottomSheet，DrawerLayout，Spinner等组件，自带十几种效果良好的动画， 支持完全的UI和动画自定义！(Powerful and Beautiful Popup，can absolutely replace Dialog，PopupWindow，PopupMenu，BottomSheet，DrawerLayout，Spinner. With built-in animators , very easy to custom popup view.) (gitee.com)](https://gitee.com/lxj_gitee/XPopup)

安装的时候遇到一个小问题，就是gradle7.0之后所有的仓库引入都放到了settings.properties中了：

```groovy
dependencyResolutionManagement {  
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)  
    repositories {  
        google()  
        mavenCentral()  
        maven {url 'https://jitpack.io'}  // XPopup的依赖
    }}
```

这玩意儿非常好用，所以我直接给所有的代码了，一看就能看懂：

```kotlin
bindingGoods.buyBtn.setOnClickListener {  

	XPopup.Builder(this@GoodsActivity).asInputConfirm("Buying ${goodsViewModel.goodsNameLiveData.value}", "Please enter the purchase quantity: ", "1", object: OnInputConfirmListener{  
		override fun onConfirm(text: String?) {  
			if(goodsViewModel.isSetFullyLiveData.value == true && text != null && text != "" && text.isDigitsOnly()){  
				goodsViewModel.requestOrder(goodsViewModel.username, goodsViewModel.goodsIdLiveData.value!!, text.toInt())  
			}else if(text == ""){  
				goodsViewModel.requestOrder(goodsViewModel.username, goodsViewModel.goodsIdLiveData.value!!, 1)  
				Log.d("SpreadShopTest", "Only Buy One!")  
			}else{  
				Log.d("SpreadShopTest", "XPopInput return Nothing, buy fail")  
				return  
			}  
		}  
	}).show()  
}
```

这里还很贴心的给用户设置了一个默认值1，表示不输入默认购买一件，并且XPopup正好还支持提示，所以在提示里打上"1"就好了。

```kotlin
goodsViewModel.orderLiveData.observe(this){  
    it.enqueue(object : Callback<OrderResponse>{  
        override fun onResponse(  
            call: Call<OrderResponse>,  
            response: Response<OrderResponse>  
        ) {  
            val orderResponse = response.body()  
            if(orderResponse != null){  
                val order = orderResponse.order  
                if(orderResponse.success){  
                    XPopup.Builder(this@GoodsActivity).asConfirm("Order Info", order.message) {  
                val mainActivity = SpreadShopApplication.context as MainActivity  
                    mainActivity.mainViewModel.getGoods(Command.GET_RECOMMAND)  
                        this@GoodsActivity.finish()  
                    }.show()  
                }else{  
                    Log.d("SpreadShopTest", "orderResponse.success is fail, msg: ${order.message}")  
                    XPopup.Builder(this@GoodsActivity).asConfirm("Failed!!!", order.message  
                    ) {  
                        Toast.makeText(  
                            this@GoodsActivity,  
                            "buy failed over",  
                            Toast.LENGTH_SHORT  
                        ).show()  
                    }.show()  
                }  
            }else{  
                Log.d("SpreadShopTest", "orderResponse is null")  
            }  
        }  
  
        override fun onFailure(call: Call<OrderResponse>, t: Throwable) {  
            t.printStackTrace()  
            Log.d("SpreadShopTest", "orderResponse on failure")  
        }  
    })  
}
```

这里唯一需要注意的是这句话：

```kotlin
val mainActivity = SpreadShopApplication.context as MainActivity  
mainActivity.mainViewModel.getGoods(Command.GET_RECOMMAND)  
this@GoodsActivity.finish() 
```

当购买成功，用户点击确定后，我们首先再发起一次获取推荐请求，然后关闭当前Activity。这样购买完自动会回到商城页面，并且数据也是最新的。而这个获取到mainActivity的实例在《第一行代码》中的14.1有讲。***但是我还是不太清楚，为啥这里获得的context就恰好是MainActivity呢？*** ^e4d3d1

最后给一下GoodsViewModel的代码：

```kotlin
class GoodsViewModel: ViewModel() {  
    val goodsNameLiveData = MutableLiveData<String>()  
    val goodsStorageLiveData = MutableLiveData<Int>()  
    val goodsPriceLiveData = MutableLiveData<Int>()  
    val goodsCategoryLiveData = MutableLiveData<String>()  
    val goodsIdLiveData = MutableLiveData<Int>()  
  
    var username = ""  
  
    val orderLiveData: LiveData<Call<OrderResponse>>  
        get() = _orderLiveData  
    private val _orderLiveData = MutableLiveData<Call<OrderResponse>>()  
  
    val isSetFullyLiveData = MutableLiveData<Boolean>()  
  
    fun setGoodsName(n: String){  
        goodsNameLiveData.value = n  
    }  
  
    fun setGoodsStorage(s: Int){  
        goodsStorageLiveData.value = s  
    }  
  
    fun setGoodsPrice(p: Int){  
        goodsPriceLiveData.value = p  
    }  
  
    fun setGoodsCategory(c: String){  
        goodsCategoryLiveData.value = c  
    }  
  
    fun setGoodsId(i: Int){  
        goodsIdLiveData.value = i  
    }  
  
    fun requestOrder(username: String, goods_id: Int, number: Int){  
        _orderLiveData.value = Repository.requestOrder(username, goods_id, number)  
    }  
  
}
```

# 2022-10-27

结项了！！！最后的操作，只不过是在已经有的技术基础上加了亿点功能而已。所以这里我给出了整个项目的MVVM架构的图：

![[projects/android/spreadshop/resources/Drawing 2022-10-27 21.28.04.excalidraw.png]]

**实线箭头表示数据的流动方向；虚线箭头表示打开关系；每个箭头的颜色表示了数据是由哪个类掌管的，从Server或者SharedPreferences开始按着一个颜色走才能走通，黑色表示公共路径。**

---

另外遇到一个小插曲，就是实现记住密码功能的时候。一开始我是按照《第一行代码》中天气预报程序里保存搜索过的城市那样做的。其中使用了一个获取全局Context的方式，也就是[[#^e4d3d1|之前]]做购买成功自动返回MainActivity并发起网络请求功能时用到的技术。但是这个技术在这里居然行不通，只要一调用程序就会崩溃。之所以我这么做会这样，而书中却不会，最根本的原因就是：**书中的context是在Fragment中获取的，而我是在Activity中获取的。**在Fragment中获取时，Activity已经创建好了，所以这样的代码是没问题的：

```kotlin
override fun onCreate() {  
    super.onCreate()  
    context = applicationContext  
}
```

但是我现在做的操作是：在Activity的`onCreate`方法中去调用`applicationContext`方法，显然是不可能完成的，也就导致了context没有被初始化。所以，在Activity中想要将自己这个context传递出去，**还是老老实实把`this`当参数传出去吧**：

```kotlin
if(loginViewMode.isUserInfoSaved(this)){  
    val uinfo = loginViewMode.getSavedUserInfo(this)  
    // 给输入框设置值要用setText不能用语法糖  
    bindingLogin.accountEdit.setText(uinfo.username)  
    bindingLogin.passwordEdit.setText(uinfo.password)  
    bindingLogin.rememberPwd.isChecked = true  
}
```

---

***如果没有意外的话，SpreadShop这个项目就到此为止了，我的日记也会在此截止了，但是我对Kotlin和Android的探索会一直持续下去！！！***