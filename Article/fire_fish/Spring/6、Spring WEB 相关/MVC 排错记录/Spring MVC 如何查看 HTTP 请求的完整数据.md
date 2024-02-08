
@[TOC](文章结构)

我们可能会碰到 MVC 拿不到前端的参数，在排查时不知道是哪个环节出现了问题，但是总的确认下 http 请求中是不是把参数携带过来了吧，下面作者将介绍如何获取到请求中的数据

## 如果是 GET 请求

如果是 GET 请求，那么很简单，完整的数据都在 uri 中，你可以很方便的通过 `servlet` 规范提供的接口查到。比如你可以按下面的方法操作：

```java
// 打一个断点在 Spring MVC 的 DispatcherServlet 类的 doDispatch 方法上，在 IDEA 的 debug 窗口中执行
request.getParameterMap()   // 查看所有参数
```

## 如果是 POST 请求

如果是 POST 请求，会稍微麻烦点，因为它的数据是存放在流中的不太方便直接查看。通常有如下两种方法

### 方法1：DEBUG 窗口（爽、超级爽、吴迪爽）：

查看的步骤介绍如下：

1、打一个断点在 Spring MVC 的 DispatcherServlet 类的 doDispatch 方法上

2、post 请求中 body 的数据存放在这个位置： `((Http11InputBuffer) ((RequestFacade) request).request.coyoteRequest.inputBuffer).byteBuffer.hb`

3、然后把上面的字节数组转成字符串就行了。用 IDEA 的 debug 窗口执行下吧

4、完整命令如下：

```java
// 查看 post 请求中 body 数据的
new String(((Http11InputBuffer) ((RequestFacade) request).request.coyoteRequest.inputBuffer).byteBuffer.hb)
```

> 很简单读者自行操作一下：查看请求 body 的数据，确认下请求中有没有携带参数
>
> ![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2023-05-31-01-41-46-image.png)

5、随后你就可以方便快速的定位问题啦啦啦

### 方法2：写方法读取流中数据（繁琐，难用）：

> 注意事项：三种方式是冲突的，只能读取一次。重复读取会报 java.io.IOException: Stream closed 异常

写一个工具类来读取流的数据。工具代码如下：

```java
package com.firefish.pretty.handler;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import javax.servlet.ServletInputStream;
import javax.servlet.http.HttpServletRequest;

public class HttpServletRequestReader {
	// 字符串读取
	// 方法一
	public static String readBodyAsChars(HttpServletRequest request) {

		BufferedReader br = null;
		StringBuilder sb = new StringBuilder("");
		try {
			br = request.getReader();
			String str;
			while ((str = br.readLine()) != null) {
				sb.append(str);
			}
			br.close();
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			if (null != br) {
				try {
					br.close();
				} catch (IOException e) {
					e.printStackTrace();
				}
			}
		}
		return sb.toString();
	}

	// 方法二
	public static void readBodyAsChars2(HttpServletRequest request) {
		InputStream is = null;
		try {
			is = request.getInputStream();
			StringBuilder sb = new StringBuilder();
			byte[] b = new byte[4096];
			for (int n; (n = is.read(b)) != -1; ) {
				sb.append(new String(b, 0, n));
			}
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			if (null != is) {
				try {
					is.close();
				} catch (IOException e) {
					e.printStackTrace();
				}
			}
		}

	}

	// 二进制读取
	public static byte[] readBodyAsBytes(HttpServletRequest request) {

		int len = request.getContentLength();
		byte[] buffer = new byte[len];
		ServletInputStream in = null;

		try {
			in = request.getInputStream();
			in.read(buffer, 0, len);
			in.close();
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			if (null != in) {
				try {
					in.close();
				} catch (IOException e) {
					e.printStackTrace();
				}
			}
		}
		return buffer;
	}
}
```

传送门： <a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>
