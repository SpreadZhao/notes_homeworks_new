<center>
<h1>题目名称：湿度测控仿真系统</h1>
</center>

## 一、题目要求

使用 Arduino UNO 微控制器，搭建一个 PC 上位机远程湿度检测控制系统。

## 二、设计思路

首先来看一下总体的系统框图：

![[Homework/Other/resources/Pasted image 20230922210145.png|600]]

简单来讲，就是**在Arduino中编写代码，控制我们自己定义的两个端口之间的通信**。其中一个端口发送一个字符串（成品中，发送的就是学号），在另一个端口上就能接收到这个字符串。

对于每一个Arduino程序，总体来讲主要分为下面的部分：

```c
void setup() {
	// 初始化操作
}

void loop() {
	// 主业务逻辑
}
```

下面我们来分析一下，在这些阶段我们都需要做什么。

* 初始化阶段
	* 初始化LCD屏幕（有多少行，多少列）
	* 初始化串口通信的波特率
	* 设置直流电机的电压控制端口为输出端口（这样才能控制转动）
* 主业务逻辑
	* 读取从另一端口发送过来的学号
	* 将学号显示在LCD屏幕上
	* 循环读取湿度，并显示在LCD屏幕和串口通信应用上
	* 根据读取到的湿度值，来判断是否应该让电机转动

根据以上的步骤，给出完整的操作流程。

### 2.1 准备工作

```ad-info
首先的首先，当然要把所有的软件都安装好啦\~，它们都包括：

* Proteus 8 pro - 仿真电路
* Arduino - 程序编写
* VSPD - 虚拟端口工具
* Serial Port Utility - 端口之间发送消息的工具
```

由于我们需要DHT库，所以先在Arduino中安装一下：

![[Homework/Other/resources/Pasted image 20230922212543.png]]

完成之后，在`C:\Users\<Your name>\Documents\Arduino\libraries`目录下就会出现DHT11需要的资源了：

![[Homework/Other/resources/Pasted image 20230922212627.png]]

然后，我们还要进行一个端口虚拟。这个很简单，在VSPD中新建一下就好了：

![[Homework/Other/resources/Pasted image 20230922212836.png]]

我创建出来的端口就是`COM2`和`COM3`。然后，就可以正式开始我们的编写了。

### 2.2 初始化

首先，要引入LCD显示屏的库以及DHT（湿度检测）库：

```c
#include <LiquidCrystal.h>
#include <DHT11.h>
```

然后，就是构建出LCD的实例以及DHT的实例了。首先来看LCD，它的电路图是这样的：


![[Homework/Other/resources/Pasted image 20230922213100.png]]

根据这些引脚的编排，以及LiquidCrystal库中的参数规定，我们可以写出LCD的构造：

```c
LiquidCrystal lcd(12, 11, 5, 4, 3, 2);
```

同理，湿度的控制只有一个端口`IO6`，所以直接构造就好了：

```c
DHT11 dht11(6);
```

然后，根据前面所说的步骤，初始化的代码就很简单了：

```c
int sensorValue = 0;
int humidity;
int threshold = 30;
int flag = 0;
int A = 7;

void setup() {
    lcd.begin(16, 2);       // LCD屏幕为16列，2行
    lcd.print("ID: ");      // 先输出一个ID
    Serial.begin(9600);     // 设置通信的波特率
    pinMode(A, OUTPUT);     // 设置IO7为输出端口，电压的高低
}
```

### 2.3 主业务逻辑

首先来看一下全部的功能：

> 功能：Arduino UNO（Atmega328P）通过串行接口组件与上位机 PC 进行双向通信，PC 机用串口调试助手软件向 Arduino UNO 发送学生自己的学号，Arduino UNO 收到后在 LCD 上显示学生的学号，并且向 PC 机发送当前的湿度值。PC机上的串口调试助手软件接收窗口显示收到的湿度值。
> 
> Arduino UNO 控制驱动直流电机，当环境湿度等于或低于预定的湿度（（30+学号末位数）%）时，启动直流电机转动；当环境湿度高于预定的湿度（（30+学号末位数）%）时，直流电机停止转动。同时，实时环境湿度在 LCD 和 PC 机的串口调试助手软件接收窗口显示。如：学生学号末位数为 3，手动降低湿度等于或低于设定的湿度值 33%（30+3=33）时，驱动直流电机开始顺时针方向转动。
> 
> * **LCD 第一行显示 ID:学号，第二行显示 RH: 湿度值%**
> * **PC 机串口调试助手软件发送窗口显示学号**
> * **PC 机串口调试助手软件接收窗口显示 Humidity: 湿度值%**

也就是说，我们需要单独发送一下学号，当读到学号之后，在LCD屏幕上打印出来。我们先来实现一下这部分逻辑。最重要的，其实就是*如何从端口中读*。代码如下：

```c
String ID = "";
while (Serial.available() > 0) {
	ID += char(Serial.read());
	delay(2);
}
```

当读取完之后，只需要：

* 获得学号最后一位
* 输出学号到LCD和调试程序
* 循环读取湿度

代码如下：

```c
lastNum = ID.charAt(ID.length() - 1) - '0';   // 得到学号的末位

/* 输出学号到lcd和调试程序 */
lcd.setCursor(3, 0);
lcd.println(ID);
humidity = dht11.readHumidity();
hum_serial += humidity;
hum_serial += " %\n";
hum_lcd += humidity;
hum_lcd += " %\n";
lcd.setCursor(0, 1);
lcd.println(hum_lcd);
Serial.write(hum_serial.c_str());
```

读取湿度，一句代码就搞定了：

```c
humidity = dht11.readHumidity();
```

然而我们要根据这个湿度来判断是否应该转动电机。所以还要一些附加的逻辑，其实也是一句话，去控制电机的转动，也就是向`IO7`端口输出高电压或者低电压：

```c
int A = 7;
digitalWrite(A, HIGH);
```

而控制的逻辑实际上就是threshold加上学号的最后一位：

```c
if (humidity <= threshold + lastNum) {
	digitalWrite(A, HIGH);      // 向IO7输出高电压，电机转动
} else {
	digitalWrite(A, LOW);       // 向IO7输出低电压，电机停止
}
```

除此之外，就还是把这些湿度输出到lcd和调试程序中的逻辑了，就不在这里展示。

### 2.4 Bug修复

在真正演示的时候有一个bug。就是**不管我怎么调节湿度，电机就是不转**。所以我猜测是我学号末位的计算出现了问题。经过调试，我发现下面的逻辑在读字符的时候，会多读一个换行符：

```c
String ID = "";
while (Serial.available() > 0) {
	ID += char(Serial.read());
	delay(2);
}
```

因此，我进行了判断，**只有字符在0到9之间，才拼接上去**。定义一个`isNum`函数：

```c
int isNum(char ch) {
	if (ch - '0' >= 0 && ch - '0' <= 9) {
		return 1;
	}
	return 0;
}
```

非常简单。下面就修改原来读取学号的逻辑吧：

```c
/* 读学号的逻辑 */
while (Serial.available() > 0) {
	char ch = char(Serial.read());      // 从串口的缓冲区中读字符
	if (isNum(ch) == 1) {
		ID += ch;
	}
	delay(2);
}
```

这样，读取的学号最后就不会出现换行符了，最后一位也能完美显示出来了。

## 三、仿真结果展示

首先，将程序编译成hex二进制文件：

![[Homework/Other/resources/Pasted image 20230922215740.png]]

然后，在电路里面进行设置。首先将Atmega328P的配置文件设置成这个hex：

![[Homework/Other/resources/Pasted image 20230922215829.png]]

然后，我们将串行接口组件的端口设置为COM2：

![[Homework/Other/resources/Pasted image 20230922215918.png]]

> 这个取决于我们之前虚拟出来的端口是多少。这里我将COM2作为接收方，将COM3作为发送方。

然后将电路运行，打开Serial Port Utility，设置发送端口为COM3，然后输入学号再发送，就能看到湿度了：

![[Homework/Other/resources/Pasted image 20230922220935.png]]

操作湿度传感器，我们也能够观察到LCD的变化以及控制台中的变化：

![[Homework/Other/resources/Pasted image 20230922221029.png]]

最后，就是电机的转动。我的学号末尾是3，所以，当$湿度 > 33$的时候，电机就会停止；当$湿度 \leqslant 33$的时候，电机就会开始转动。

![[Homework/Other/resources/Pasted image 20230922223934.png]]

![[Homework/Other/resources/Pasted image 20230922224013.png]]

## 四、程序设计

**流程图：**

![[Homework/Other/resources/Drawing 2023-09-22 22.42.07.excalidraw.png]]

**源代码：**

```c
#include <LiquidCrystal.h>  
#include <DHT11.h>  
  
LiquidCrystal lcd(12, 11, 5, 4, 3, 2);  
  
DHT11 dht11(6);  
  
int humidity;  // 湿度  
int threshold = 30; // 阈值  
int flag = 0;  // 控制是第一次读取还是之后的循环读取  
int A = 7;     // IO7引脚，控制电机的高低电压  
int lastNum = 0;  // 学号最后一位  
  
void setup() {  
    lcd.begin(16, 2);       // LCD屏幕为16列，2行  
    lcd.print("ID: ");      // 先输出一个ID  
    Serial.begin(9600);     // 设置通信的波特率  
    pinMode(A, OUTPUT);     // 设置IO7为输出端口，电压的高低  
}  
  
// 只有0-9才从COM中读取  
int isNum(char ch) {  
    if (ch - '0' >= 0 && ch - '0' <= 9) {  
        return 1;  
    }  
    return 0;  
}  
  
void loop() {  
    if (flag == 0) {  // 第一次读取  
        String ID = "";  
        String hum_serial = "Humidity: ";  
        String hum_lcd = "RH: ";  
        /* 读学号的逻辑 */        
        while (Serial.available() > 0) {  
            char ch =  
            char(Serial.read());      // 从串口的缓冲区中读字符  
            if (isNum(ch) == 1) {  
                ID += ch;  
            }  
            delay(2);  
        }  
        if (ID.length() > 0) {  
            lastNum = (ID.charAt(ID.length() - 1)) - '0';   // 得到学号的末位  
  
            /* 输出学号到lcd和调试程序 */            
            lcd.setCursor(3, 0);  
            lcd.println(ID);  
            humidity = dht11.readHumidity();  
            hum_serial += "ID: ";  
            hum_serial += ID;  
            hum_serial += " lastNum: ";  
            hum_serial += lastNum;  
            hum_lcd += humidity;  
            hum_lcd += " %\n";  
            lcd.setCursor(0, 1);  
            lcd.println(hum_lcd);  
            Serial.write(hum_serial.c_str());  
  
            flag = 1;   // 之后循环读取湿度  
        }  
    } else {  // 之后的循环读取  
        String hum_serial = "Humidity: ";  
        String hum_lcd = "RH: ";  
        humidity = dht11.readHumidity();    // 读取湿度  
  
        /* 输出到LCD，控制台 */        
        hum_serial += humidity;  
        hum_serial += " %\n";  
        hum_lcd += humidity;  
        hum_lcd += " %\n";  
        Serial.write(hum_serial.c_str());  
        lcd.setCursor(0, 1);  
        lcd.println(hum_lcd);  
  
        if (humidity <= threshold + lastNum) {  
            digitalWrite(A, HIGH);      // 向IO7输出高电压，电机转动  
        } else {  
            digitalWrite(A, LOW);       // 向IO7输出低电压，电机停止  
        }  
    }  
    delay(3000);    // 每3秒读取一次  
}
```