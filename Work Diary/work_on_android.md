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

如果每用到一次和`10.0.2.2`的连接就要写一堆这些，烦都烦死了。所以我们需要简化一下。在逻辑层的网络包，也就是`.logic.model`下新建`ServiceCreator`**单例类**：

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

在使用LiveData去保存登陆系统的用户名和密码的时候，出现了这样的问题。我们的LoginViewModel是这样的：

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

由于我们并不需要将username和password在屏幕上显示出来，所以根本不需要livedata的observe方法。所以在赋值完之后，直接使用就好。**还有一点，字符串为空并不是` == null`**。这里的空可不是c语言里的空指针，它是有实际内存的，只不过值为空。