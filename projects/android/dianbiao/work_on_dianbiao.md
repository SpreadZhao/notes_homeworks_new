# 1. Preview & Prepare

DianBiao is a android program imitated from the real app developed by **Robot xm**.

According to the [python implementation of the authority of Xidian CAS login system](https://github.com/xdlinux/libxduauth), we should firstly send GET http request to below interface:

```
http://ids.xidian.edu.cn/authserver/login?service=<service>&type=<type>
```

> where `<service>` is `https://ehall.xidian.edu.cn:443/login?service=https://ehall.xidian.edu.cn/new/index.html` and `<type>` is `userNameLogin`.

However, the response body is HTML formatted String, which means we should use String as the generic of `Call<>` and `Callback<>`. But after I have done this, I got an exception like this:

![[Projects/android/dianbiao/resources/Pasted image 20230209235809.png]]

Unlike OkHttp or HttpUrlConnection and others, to get String response in Retrofit, you should do a little more works, which include implementing a new ConverterFactory and add it to the retrofit builder **before the base convertor such as GSON**:

```kotlin
val retrofit = Retrofit.Builder()  
    .baseUrl("http://ids.xidian.edu.cn/")  
    .addConverterFactory(ToStringConverterFactory())  
    .addConverterFactory(GsonConverterFactory.create())  
    .build()

// Meanwhile
class ToStringConverterFactory: Converter.Factory() {  
  
    private val MEDIA_TYPE = MediaType.parse("text/plain")  
  
    override fun responseBodyConverter(  
        type: Type,  
        annotations: Array<out Annotation>,  
        retrofit: Retrofit  
    ): Converter<ResponseBody, *>? {  
        if(String.Companion::class.java == type){  
            return Converter<ResponseBody, String>{  
                value -> value.string()  
            }  
        }  
        return null  
    }  
  
    override fun requestBodyConverter(  
        type: Type?,  
        parameterAnnotations: Array<out Annotation>?,  
        methodAnnotations: Array<out Annotation>?,  
        retrofit: Retrofit?  
    ): Converter<*, RequestBody> {  
            return Converter<String, RequestBody>{ 
	            value -> RequestBody.create(MEDIA_TYPE, value) 
	        }  
    }  
}
```

The factory is used to convert `Responsebody` type to `String`, so `value`'s type is `Responsebody`, and if we're sure that it can absolutely be transformed to `String`, we can call `string()` to read the entire response as char sequence. What I have done is learned from [here](https://www.itcodar.com/java/how-to-get-string-response-from-retrofit2.html).