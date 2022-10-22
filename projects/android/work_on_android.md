#2022-10-20

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

#2022-10-22

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