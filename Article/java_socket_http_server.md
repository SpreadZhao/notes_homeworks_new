使用java自己搭建的http服务器，这部分的教学来自这个网站：

[A Simple HTTP Server in Java (commandlinefanatic.com)](https://commandlinefanatic.com/cgi-bin/showarticle.cgi?article=art076)

The repository of my coding:

[java_http_server: A simple HTTP server written in java, all ground techniques. (gitee.com)](https://gitee.com/spreadzhao/java_http_server)

# 1. MI AI

但是在开始这个项目之前，我们先来看一个比较简单的，也是我之前做过的一个项目。这个项目模拟了智能语音助手的简单工作方式，其实就是服务端在监听，客户端去发送信息，当服务端检测到信息之后，传回对应的对象即可。

我们使用的是流来进行数据交互，核心的方法是下面两个：

```java
readObject()
writeObject()
```

因此我们的数据也是`Object`类型。现在就从服务端开始来逐个解释。

首先，服务端需要监听一个指定的端口，那么我们用socket做到这一点呢？有一个`ServerSocket`类，这个类中有一个`accept`方法，官方的描述是这样的：

![[Article/resources/Pasted image 20221029185127.png]]

所以这就是两个socket之间的第一次交互。首先是客户端的socket，当它想要尝试登陆(如何登陆之后再说)某一个服务端时，首先要见一见服务端的socket，而这个方法就会在服务端那边得到客户端socket的实例。而当服务端这里啥事没有的时候，就会一直阻塞着，直到有人来为止。那么我们服务端代码的写法就已经很清晰了：

```java
public class Server {  
    private int port;  
    private ServerSocket serverSocket;  
    private boolean isRunning;  
  
    public Server(int port){  
        this.port = port;  
        isRunning = true;  
    }  
  
    public void start(){  
        try{  
            serverSocket = new ServerSocket(port);  
            System.out.println("[server.Server]started, listening port: " + serverSocket.getLocalPort());  
            while (isRunning){  
                Socket clientSocket = serverSocket.accept();  
                System.out.println("[server.Server] " + clientSocket.getRemoteSocketAddress() + " connect successfully!");  
                new Thread(new ClientSocketHandlingTask(clientSocket)).start();  
            }  
        }catch (IOException e){  
            e.printStackTrace();  
        }  
    }  
}
```

这里唯一我们还不清晰的，是这句话：

```java
new Thread(new ClientSocketHandlingTask(clientSocket)).start();
```

这句话新建了一个`Runnable`的子类，并起了一个线程去运行它，而这就是服务端在成功得到一个client的socket之后做的事，那么这个`Runnable`肯定就是和客户端交互的逻辑了。我们接下来就来看看其中的细节：

```java
public class ClientSocketHandlingTask implements Runnable{  
  
    private Socket clientSocket;  
    private ObjectInputStream inputStream;  
    private ObjectOutputStream outputStream;  
    private String clientName;  
    private static int id = 0;  
  
    public ClientSocketHandlingTask(Socket socket){  
        this.clientSocket = socket;  
        this.clientName = "[user " + ++id + "]";  
        try {  
            inputStream = new ObjectInputStream(clientSocket.getInputStream());  
            outputStream = new ObjectOutputStream(clientSocket.getOutputStream());  
        } catch (IOException e) {  
            throw new RuntimeException(e);  
        }  
    }  
  
    @Override  
    public void run() {  
        Object msg = null;  
        try {  
            while((msg = inputStream.readObject()) != null){  
                System.out.println("[Server]receive " + clientName + "'s message: " + msg);  
            }  
        }  catch (ClassNotFoundException | IOException e) {  
            e.printStackTrace();  
        }  
    }  
}
```

^25f69e

在构造这个任务的时候，我们最重要的任务就是**拿到客户端的输入流和输出流**，借助这两个流我们就能从客户端读信息和向客户端写信息了。

当这个任务被执行的时候，它会调用输入流的`readObject`方法(~~注意，客户端的输入流是服务端的输出流~~)，为了弄清楚这段代码到底是怎么运行的，我重写了一下：

```java
public void run() {  
    Object msg = null;  
    try {  
        System.out.println("haha");  
        while(true){  
            msg = inputStream.readObject();  
            System.out.println("[Server]test");  
            if(msg != null){  
                System.out.println("[Server]receive " + clientName + "'s message: " + msg);  
            }else{  
                System.out.println("[Server]msg is null");  
                break;            }  
        }  
    }  catch (ClassNotFoundException | IOException e) {  
        e.printStackTrace();  
    }  
}
```

我看到的执行结果是这样的：

```shell
[Server]enter port to listen: 1234
[server.Server]started, listening port: 1234
[server.Server] /127.0.0.1:50526 connect successfully!
haha
[Server]test
[Server]receive [user 1]'s message: asdf
[Server]test
[Server]receive [user 1]'s message: fgh
```

这里的test只在输入时才打印，因此我们能推测出来：**`readObject`是一个阻塞方法**，只有收到了客户端发来的消息时才会继续执行。接下来就是客户端的代码了，这部分代码非常简单：

```java
public class client {  
    public static void main(String[] args) {  
        Scanner input = new Scanner(System.in);  
        Socket socket = null;  
        ObjectOutputStream outputStream = null;  
        ObjectInputStream inputStream = null;  
        String msg;  
  
        try {  
            System.out.print("[Client]Enter port to log in: ");  
            socket = new Socket("localhost", input.nextInt());  
            System.out.println("[Client]connection success!");  
  
            outputStream = new ObjectOutputStream(socket.getOutputStream());  
            inputStream = new ObjectInputStream(socket.getInputStream());  
  
            while(true){  
                System.out.print("[Client]please enter: ");  
                msg = input.next();  
                outputStream.writeObject(msg);  
                outputStream.flush();  
            }  
        } catch (IOException e) {  
            throw new RuntimeException(e);  
        } finally {  
            try {  
                assert inputStream != null;  
                inputStream.close();  
                outputStream.close();  
                input.close();  
            } catch (IOException e){  
                e.printStackTrace();  
            }  
        }  
    }  
}
```

最关键的还是这两行代码：

```java
outputStream.writeObject(msg);  
outputStream.flush();
```

接下来，如果客户端想要接到服务端返回的数据，聪明的你肯定也已经想到了：继续调用这个阻塞的函数等待服务端返回即可！这里我们就只给我之前写的例子了：

```java
Object returnMsg = inStream.readObject();
//如果返回值是文件，播放文件
if(returnMsg instanceof File) {
	new Thread(new PlayMusicTask((File)returnMsg)).start();
}else if("bye".equals(returnMsg)){
	break;
}else {
	System.out.println("[客户端]小爱说：" + returnMsg);
}
```

# 2. Beginning

## 2.1 Duplicate Works

有了这个小爱同学的例子，我们已经对socket编程有了一个最最基本的认识。那么接下来就开始用java来手撸一个服务器罢！

首先是最基础的类：`HttpServer`，这个类做的事就和小爱同学中的`Server`是一样的——**去监听一个端口，并等待客户登入**。

```java
public class HttpServer {  
    private ServerSocket serverSocket;  
    private Socket clientSocket;  
    private int port;  
  
    public HttpServer(int port){  
        this.port = port;  
    }  
  
    public void start() throws IOException{  
        serverSocket = new ServerSocket(port);  
        System.out.println("[Server]Listening port " + serverSocket.getLocalPort());  
        while((clientSocket = serverSocket.accept()) != null){  
            System.out.println("[Server]User " + clientSocket.getRemoteSocketAddress().toString() + " log in!");  
  
        }  
    }  
}
```

这个while循环还没写完，接下来的事情就是去处理用户的连接了。在做这件事之前，我们先要明确一件事：我们是要处理http请求，而Socket传输的通常都是Object。因此我们要单独定义一些方法去将从客户端接收过来的object变成http请求的接口。

## 2.2 Request

我们都知道，http请求分为Request和Response。前者是客户端发给服务端；后者反过来。那么我们就先从这两个对象开始说起。首先是Request，它内部含有一个`BufferedReader`：

```java
private BufferedReader in;
```

而这个实际上就是**客户端的输入流**。我们可以用这个流不断地读取用户发送来的数据，从而得到相应的HTTP请求。我们从最简单的开始一步步来，首先给出Request的部分简单代码：

```java
public class Request {  
    private BufferedReader in;  
  
    public Request(BufferedReader in){  
        this.in = in;  
    }  
  
    public boolean parse() throws IOException{  
        String initialLine = in.readLine();  
        log(initialLine);  
        return false;  
    }  
  
    private void log(String msg){  
        System.out.println(msg);  
    }  
}
```

这里非常简单，只是将从in这个对象读出来的东西打印在终端上而已。那么接下来，我们来测试一下这个功能，也就是实现SocketHandler类：

```java
public class SocketHandler implements Runnable{  
  
    private Socket clientSocket;  
  
    public SocketHandler(Socket socket){  
        this.clientSocket = socket;  
    }  
  
    @Override  
    public void run() {  
        BufferedReader in = null;  
        OutputStream out = null;  
  
        try {  
            in = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));  
            out = clientSocket.getOutputStream();  
  
            Request request = new Request(in);  
            request.parse();  
        }catch (IOException e){  
            e.printStackTrace();  
        }  
    }  
}
```

这段代码对应的是小爱同学中的[[#^25f69e|这里]]。而我们现在的操作很显然更高级一点：之前我们将客户端的输入流和输出流都放在了Handler里，这导致我们对于所有的请求都要使用同一种处理方法。但是，http请求本身就是多样的，有GET，POST，DELETE等等。因此我们对于不同的请求需要做不同的处理。这里的做法就是将客户端的输入流直接封装到Request对象中，当需要读取其中的数据时，只需要在Request中调用这个in的readLine方法就可以了。

好了，现在设想一下：如果我们用在浏览器中输入`http://localhost:1234`的话，这里就会接收到这个连接(前提是服务器要监听这个端口)，然后在HttpServer中就会启动一个线程来执行SocketHandler中的代码，自然就会首先构造出一个Request对象，当调用parse方法时，自然就会调用其中的log方法，将我们readLine读出来的结果打印到终端上！好！说干就干，接下来只需要完善一下HttpServer并且写一个测试类，就能工作了：

```java
public class HttpServer {  
    private ServerSocket serverSocket;  
    private Socket clientSocket;  
    private int port;  
  
    public HttpServer(int port){  
        this.port = port;  
    }  
  
    public void start() throws IOException{  
        serverSocket = new ServerSocket(port);  
        System.out.println("[Server]Listening port " + serverSocket.getLocalPort());  
        
        while((clientSocket = serverSocket.accept()) != null){  
            System.out.println("[Server]User " + clientSocket.getRemoteSocketAddress().toString() + " log in!");   
            new Thread(new SocketHandler(clientSocket)).start();  
        }  
    }  
}
```

```java
public class Test {  
    public static void main(String[] args) {  
        int port;  
        Scanner input = new Scanner(System.in);  
        System.out.print("enter port to listen: ");  
        try {  
            new HttpServer(input.nextInt()).start();  
        }catch (IOException e){  
            e.printStackTrace();  
        }  
  
    }  
}
```

OK！现在启动程序，并监听1234端口，然后打开浏览器，输入上面的地址，就能看到如下结果：

```shell
enter port to listen: 1234
[Server]Listening port 1234
[Server]User /0:0:0:0:0:0:0:1:64607 log in!
[Server]User /0:0:0:0:0:0:0:1:64609 log in!
GET /haha?s=y HTTP/1.1
[Server]User /0:0:0:0:0:0:0:1:64636 log in!
GET / HTTP/1.1
```

我们能看出来，请求的信息被打印了出来，那么接下来就是通过这个打印的信息，去分析它需要的东西了。自然，**我们要从Request类的`parse`函数入手**。

## 2.3 Recognize HTTP Request

在继续书写之前，我们要先了解一下java的StringTokenizer类：

[Java StringTokenizer 类使用方法 | 菜鸟教程 (runoob.com)](https://www.runoob.com/w3cnote/java-stringtokenizer-intro.html)

我们能看到，我们的整个请求是这样的：

```http
GET /haha?s=y Http/1.1
```

这分为三个部分，被两个空格分开。因此我们解析也是要使用StringTokenizer将它分成三份：

```java
public boolean parse() throws IOException{  
    String initialLine = in.readLine();  
    log("request", initialLine);  
    
    StringTokenizer tok = new StringTokenizer(initialLine);  
    String[] components = new String[3];  
    for(int i = 0; i < components.length; i++){  
        if(tok.hasMoreTokens()){  
            components[i] = tok.nextToken();  
            log("components " + i, components[i]);  
        }else{  
            return false;  
        }  
    }  
    
    return false;  
}
```

如果详细看了关于StringTokenizer的介绍，这部分代码是很好看懂的。注意，我又升级了一下log函数，现在它变成了这样：

```java
private void log(String tag, String msg){  
    System.out.print("[" + tag + "]" + " " + msg + "\n");  
}
```

接下来，我们就这样再进行一次测试，看看这次会有什么结果：

```java
enter port to listen: 1234
[Server]Listening port 1234
[Server]User /0:0:0:0:0:0:0:1:65303 log in!
[Server]User /0:0:0:0:0:0:0:1:65304 log in!
[request] GET /hehe?a=b HTTP/1.1
[components 0] GET
[components 1] /hehe?a=b
[components 2] HTTP/1.1
```

和我们想象得一模一样，非常nice！接下来，就是将这三个变量找个地方放一下，自然就是Request类中的成员了：

```java
public class Request {  
    private BufferedReader in;  
    private String method;  
    private String fullUrl;  
  
    public Request(BufferedReader in)...
  
    public boolean parse()...
  
    private void log(String tg, String msg)...
}
```

`method`就是我们请求的类型，而`fullUrl`就是请求的全部细节。

在使用这些成员之前，我们还是要回到http协议本身上。这个协议可不像我们想象得这么简单只有这么短短的一行：

```http
http://localhost:1234/haha?sb=you&dsb=me
```

它的实际结构在开头的网站中是这样描述的：

> Per the HTTP standard, `Request` expects a CR-LF delimited list of lines whose first line is of the form: **`VERB PATH VERSION`** followed by a variable-length list of headers in the form `NAME: VALUE` <u>and a closing empty line indicating that the header list is complete</u>. If the `VERB` supports an entity-body (like POST or PUT), the rest of the request is that entity body. I'm only worrying about `GET`s here, so I assume there's no entity body. Once this method completes, assuming everything was syntactically correct, `Request`'s internal `method, path, fullUrl` and `headers` member variables are filled in.

注意其中的`VERB PATH VERSION`，这其实就是我们刚刚解析出来的三个components。而这后面，还用键值对形式跟着许多行。那么它们都是什么呢？我们不妨做个试验来看看：

```java
public boolean parse() throws IOException{  
	String initialLine = in.readLine();  
	log("request", initialLine);  
	StringTokenizer tok = new StringTokenizer(initialLine);  
	String[] components = new String[3];  
	for(int i = 0; i < components.length; i++){  
		if(tok.hasMoreTokens()){  
			components[i] = tok.nextToken();  
			log("components " + i, components[i]);  
		}else{  
			return false;  
		}  
	}  
	
	while(true){  
		String headerLine = in.readLine();  
		log("headerline", headerLine);  
		if(headerLine.length() == 0) break;  
	}  
	return false;  
}
```

我们使用一个不停在读的while循环，直到读不出来为止。因此我们能在终端里看到我们一个简简单单的http请求到底都包含了什么：

```shell
enter port to listen: 1234
[Server]Listening port 1234
[Server]User /0:0:0:0:0:0:0:1:49558 log in!
[Server]User /0:0:0:0:0:0:0:1:49559 log in!
[request] GET /haha?sb=you&dsb=me HTTP/1.1
[components 0] GET
[components 1] /haha?sb=you&dsb=me
[components 2] HTTP/1.1
[headerline] Host: localhost:1234
[headerline] Connection: keep-alive
[headerline] sec-ch-ua: "Microsoft Edge";v="107", "Chromium";v="107", "Not=A?Brand";v="24"
[headerline] sec-ch-ua-mobile: ?0
[headerline] sec-ch-ua-platform: "Windows"
[headerline] Upgrade-Insecure-Requests: 1
[headerline] User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36 Edg/107.0.1418.26
[headerline] Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9
[headerline] Sec-Fetch-Site: none
[headerline] Sec-Fetch-Mode: navigate
[headerline] Sec-Fetch-User: ?1
[headerline] Sec-Fetch-Dest: document
[headerline] Accept-Encoding: gzip, deflate, br
[headerline] Accept-Language: zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6
[headerline] Cookie: Webstorm-536eb0eb=2c33d83d-2784-48b5-9dcf-9ebcee3fa1db
[headerline] 
```

这里的最后一行也正应了文章中的这句话：

> and a closing empty line indicating that the header list is complete.

因此为了便于后期使用，这里使用了一个HashMap将它们存起来：

```java
public class Request {  
    private BufferedReader in;  
    private String method;  
    private String fullUrl;
    private Map<String, String> headers = new HashMap<String, String>();
  
    public Request(BufferedReader in)...
  
    public boolean parse()...
  
    private void log(String tg, String msg)...
}

```

然后每一次循环就只需要进行这样的操作：

```java
while(true){  
	String headerLine = in.readLine();  
	log("headerline", headerLine);  
	if(headerLine.length() == 0) break;  

	int separator = headerLine.indexOf(":");  
	if(separator == -1) return false;  
	String key = headerLine.substring(0, separator);  
	String val = headerLine.substring(separator + 1);  
	log("key", key);  
	log("val", val);  
	headers.put(key, val);  
	System.out.println("----------------------------");  

}
```

这样我们就能够得到这样的结果了：

```shell
enter port to listen: 1234
[Server]Listening port 1234
[Server]User /0:0:0:0:0:0:0:1:50288 log in!
[Server]User /0:0:0:0:0:0:0:1:50289 log in!
[request] GET /haha?sb=you&dsb=me HTTP/1.1
[components 0] GET
[components 1] /haha?sb=you&dsb=me
[components 2] HTTP/1.1
[headerline] Host: localhost:1234
[key] Host
[val]  localhost:1234
----------------------------
[headerline] Connection: keep-alive
[key] Connection
[val]  keep-alive
----------------------------
[headerline] sec-ch-ua: "Microsoft Edge";v="107", "Chromium";v="107", "Not=A?Brand";v="24"
[key] sec-ch-ua
[val]  "Microsoft Edge";v="107", "Chromium";v="107", "Not=A?Brand";v="24"
----------------------------
[headerline] sec-ch-ua-mobile: ?0
[key] sec-ch-ua-mobile
[val]  ?0
----------------------------
[headerline] sec-ch-ua-platform: "Windows"
[key] sec-ch-ua-platform
[val]  "Windows"
----------------------------
[headerline] Upgrade-Insecure-Requests: 1
[key] Upgrade-Insecure-Requests
[val]  1
----------------------------
[headerline] User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36 Edg/107.0.1418.26
[key] User-Agent
[val]  Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36 Edg/107.0.1418.26
----------------------------
[headerline] Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9
[key] Accept
[val]  text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9
----------------------------
[headerline] Sec-Fetch-Site: none
[key] Sec-Fetch-Site
[val]  none
----------------------------
[headerline] Sec-Fetch-Mode: navigate
[key] Sec-Fetch-Mode
[val]  navigate
----------------------------
[headerline] Sec-Fetch-User: ?1
[key] Sec-Fetch-User
[val]  ?1
----------------------------
[headerline] Sec-Fetch-Dest: document
[key] Sec-Fetch-Dest
[val]  document
----------------------------
[headerline] Accept-Encoding: gzip, deflate, br
[key] Accept-Encoding
[val]  gzip, deflate, br
----------------------------
[headerline] Accept-Language: zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6
[key] Accept-Language
[val]  zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6
----------------------------
[headerline] Cookie: Webstorm-536eb0eb=2c33d83d-2784-48b5-9dcf-9ebcee3fa1db
[key] Cookie
[val]  Webstorm-536eb0eb=2c33d83d-2784-48b5-9dcf-9ebcee3fa1db
----------------------------
[headerline] 
```

#TODO java socket http server

- [x] Keep going!!!! fkkkkk!!!

After dealing with the "key-val" formed header list, it's time to turn to the `path` and it's query params. In the first line of HTTP request, **`componens[0]` is method and `components[1]` is the full Url which we care about most**:

```java
method = components[0];  
fullUrl = components[1];
```

The `fullUrl` contains all the params which we need to analyze and handle. So let's find the law first. If our http request is like this:

```url
http://localhost:1234/doc/main
```

The `fullUrl` would be like this:

```shell
[components 1]/doc/main
```

---

In another case, if our request contains query params:

```url
http://localhost:1234/doc/main?category=computer
```

The variable is like this:

```shell
[components 1]/doc/main?category=computer
```

---

If we don't have any element after the port number:

```url
http://localhost:1234
```

The result is:

```shell
[components 1]/
```

To conclude the 3 cases above, we say that:

* If the Url does not contain the character `?` which means the query param token, we can think that the whole Url is the path;
* if the Url contain the character `?`, we should make the sub string before it the path, and we should also **parse every query param formed key-val after that guy**.

Now let's code for these conclusions:

```java
public class Request {  
    private BufferedReader in;  
    private String method;  
    private String fullUrl;  
    private String path;  
    private Map<String, String> headers = new HashMap<>();  
  
    public Request(BufferedReader in) ...
  
    public boolean parse() throws IOException {  

		... ...
  
        if(!fullUrl.contains("?")) path = fullUrl;  
        else {  
            path = fullUrl.substring(0, fullUrl.indexOf("?"));  
            parseQueryParameters(fullUrl.substring(fullUrl.indexOf("?") + 1));  
        }  
        return false;  
    }  
  
    private void parseQueryParameters(String queryString){  
		  ... ...
    }  
  
    private void log(String tag, String msg) ...
}
```

Everything is obvious and clear except **how we parse the query params**, which is the task of `parseQueryParameters()`. Now let's take a look at it:

```java
private void parseQueryParameters(String queryString){  
    for(String param : queryString.split("&")){  
        int separator = param.indexOf("=");  
        if(separator > -1){  
            queryParams.put(param.substring(0, separator), param.substring(separator + 1));  
        }else {  
            queryParams.put(param, null);  
        }  
    }  
}
```

For a Url like this:

```url
http://localhost:8080/haha/hehe?name=spread&age=20&sex=male
```

the `queryString` has been cut down to this:

```url
name=spread&age=20&sex=male
```

So we need to **split it by `&`** to determine each key-val query param, and put the things before a `=` to the key and the things after it to the val.

## 2.4 Handle the Parse Result

During the parse job, once we were failed, the `parse()` method will return false. So if we get that, we should **respond to the client as an Intra Server Error**:

```java
public class SocketHandler implements Runnable{  
  
    private Socket clientSocket;   
    public SocketHandler(Socket socket) ...
  
    @Override  
    public void run() {  
        BufferedReader in = null;  
        OutputStream out = null;  
  
        try {  
            ... ...
            Request request = new Request(in);  
            if(!request.parse()){  
                respond(500, "Unable to parse request", out);  
                return;            
            }  
        }catch (IOException e){  
            e.printStackTrace();  
        }  
    }  
  
    private void respond(int statusCode, String msg, OutputStream out) throws IOException {  
        ... ...
    }  
}
```

in the `respond()` method, we should use the Output Stream of client to return the status code and the detail message to it. So the implementation is like this:

```java
private void respond(int statusCode, String msg, OutputStream out) throws IOException {  
    String responseLine = "HTTP/1.1 " + statusCode + " " + msg + "\r\n\r\n";  
    out.write(responseLine.getBytes());  
}
```

> SocketHandler means one-time Request handling, while HttpServer continously creates different SocketHandler to deal with multiple requests.

What if we have successfully parse the request? **It's time to find a handler**! For a GET method, we have a series of handlers to do with it. Everybody of them is associated with a certain `PATH`. For example, there's a handler **A** which is capable of dealing with all GET methods under the path below:

```url
/hello
```

The case means that, if the client send a request like this:

```url
http://localhost:1234/hello?name=spread
```

After the server has parsed it, we know that **A** is the target handler to deal with such request. To implement that, we use a **Map of String and Map** to indicate the internal stucture:

```java
private Map<String, Map<String, Handler>> handlers;
```

The key of the first level Map is the **method**, such as GET, POST, DELETE, etc. The second level key is the **path** which the specific handler cares about. The SocketHandler parses the request, so it will know the method and path after the performing. We use these variables to query the target handler from the two-level map:

```java
Request request = new Request(in);  
if(!request.parse()){  
	respond(500, "Unable to parse request", out);  
	return;            
}  
boolean foundHandler = false;  
Response response = new Response(out);  

// Filter for method  
Map<String, Handler> methodHandlers = handlers.get(request.getMethod());  
if(methodHandlers == null){  
	respond(405, "Method not supported", out);  
	return;            
}  

// Filter for path  
if(methodHandlers.containsKey(request.getPath())){  
	methodHandlers.get(request.getPath()).handle(request, response);  
	response.send();  
	foundHandler = true;  
}
```

You will notice that I have implement the Response class, which is very easy and listed below:

```java
public class Response {  
    private OutputStream out;  
    private int statusCode;  
    private String msg;  
    private Map<String, String> headers = new HashMap<>();  
    private String body;  
  
    public Response(OutputStream out){ this.out = out; }  
    public void setResponseCode(int code, String msg){  
        this.statusCode = code;  
        this.msg = msg;  
    }  
    public void addHeader(String headerName, String headerValue){  
        this.headers.put(headerName, headerValue);  
    }  
    public void addBody(String body){  
        headers.put("Content-Length", Integer.toString(body.length()));  
        this.body = body;  
    }  
    public void send() throws IOException {  
        headers.put("Connection", "Close");  
        out.write(("HTTP/1.1 " + statusCode + " " + msg + "\r\n").getBytes());  
        for(String headerName : headers.keySet()){  
            out.write((headerName + ": " + headers.get(headerName) + "\r\n").getBytes());  
        }  
        out.write("\r\n".getBytes());  
        if(body != null) out.write(body.getBytes());  
    }  
}
```

## 2.5 Finish of First Release

The next thing is: **what is the handler it self? How and When to fill the handlers Map**? Both of the two questions is easy. The handler is just an interface which is **thread safe**:

```java
public interface Handler {  
    void handle(Request request, Response response) throws IOException;  
}
```

When to add it? Absolutely when we create the server! Let's implement a demo handler and add it:

```java
public class DemoHandler implements Handler{  
    @Override  
    public void handle(Request request, Response response) throws IOException {  
        String html = "<html><body>it works!</body></html>";  
        response.setResponseCode(200, "OK");  
        response.addHeader("Content-Type", "text/html");  
        response.addBody(html);  
    }  
}
```

To add the demo handler, we should determine which type of request and which path we care about.

```java
public class Main {  
    public static void main(String[] args) {  
        int port;  
        Scanner input = new Scanner(System.in);  
        System.out.print("Enter port to listen: ");  
        try {  
            HttpServer server = new HttpServer(input.nextInt());  
            server.addHandler("GET", "/demo", new DemoHandler());  
            server.start();  
        } catch (IOException e) {  
            e.printStackTrace();  
        }  
    }  
}
```

> Notice that, **the origin two-level Map `handlers` is located in HttpServer**, once a time a handling thread starts, the specific SocketHandler is created, and the Map is transformed into it:
> 
> ```java
> // Constructor of SocketHandler
> public SocketHandler(Socket socket, Map<String, Map<String, Handler>> handlers){  
>     this.clientSocket = socket;  
>     this.handlers = handlers;  
> }
> ```

Now it's time to witness our effort! Start our server, visit the demo Url of that demo, we'll see:

![[Article/resources/Pasted image 20230402200739.png|300]]