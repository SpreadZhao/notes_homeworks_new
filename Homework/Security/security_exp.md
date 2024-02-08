## 实验一：OpenSSL库的使用

### 一、实验原理

由于我使用的是Windows系统，想了很多办法获得OpenSSL库。最终发现，其实Git Bash里面就是自带OpenSSL的：

![[Homework/Security/resources/Pasted image 20231118171706.png]]

接下来，就是对于本次实验要实现的功能：

* 生成公钥和私钥；
* 能够选择加密算法；
* 对数据进行加密和解密

### 二、实验结果

总的来说，一共四个文件：

* 公钥
* 私钥
* 明文
* 密文

使用公钥将明文加密成密文；再使用私钥将密文解密回明文。

首先创建公钥和私钥对：

```shell
# 生成私钥
openssl genpkey -algorithm RSA -out private_key.pem
# 使用私钥生成公钥
openssl rsa -pubout -in private_key.pem -out public_key.pem
```

这将在目录下生成两个文件，就是公钥和私钥：

![[Homework/Security/resources/Pasted image 20231118172123.png]]

接下来，对数据进行加密。首先创建明文：

![[Homework/Security/resources/Pasted image 20231118172225.png]]

然后使用公钥进行加密：

```shell
openssl pkeyutl -encrypt -pubin -inkey public_key.pem -in plaintext.txt -out encrypted.txt
```

这样就会生成一个密文文件。由于是对字节进行加密，所以生成的字节流也不具备可读性：

![[Homework/Security/resources/Pasted image 20231118172438.png]]

接下来，使用私钥进行解密：

```shell
openssl pkeyutl -decrypt -inkey private_key.pem -in encrypted.txt -out decrypted.txt
```

同样会生成一个解密回来的文件。这个文件中的内容就是之前plaintext中的内容：

![[Homework/Security/resources/Pasted image 20231118172601.png]]

### 三、实验总结与收获

本次实验，作为一个小白首次尝试了一些加密库的使用。为什么Git默认会具有这些功能呢？作为一个版本管理工具，对于仓库在同步过程中的安全问题是要引起高度重视的。所以git默认也携带了很多关于加密方面的工具。我最常用的就是ssh-key了。因此本实验最主要的目的是开阔自己的眼界，能够见识到更多正在使用的加密算法和工具。

## 实验二：条形码(Barcode)生成和读取

### 一、实验原理

本实验基于Android 14平台和ZXing库来实现条形码的生成和扫描。前端界面使用Jetpack Compose编写。

### 二、实验结果

就不多介绍页面怎么编写了。条形码的库主要是通过ZXing的bitMatrix生成。ZXing提供了将字符编码为比特矩阵的能力。利用这个矩阵，我们就能够确定条形码图中哪些比特是黑色，哪些比特是白色。具体代码如下：

```kotlin
object ZXingWorker {

  fun textToBar(context: Context, text: String): Bitmap {
    val bitMatrix = MultiFormatWriter().encode(text, BarcodeFormat.CODE_128, 500, 200)
    return toBitMap(bitMatrix, context)
  }

  private fun toBitMap(bitMatrix: BitMatrix, context: Context): Bitmap {
    val height = bitMatrix.height
    val width = bitMatrix.width
    val bitMap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    for (x in 0 until width) {
      for (y in 0 until height) {
        bitMap.setPixel(
          x,
          y,
          if (bitMatrix.get(x, y)) ContextCompat.getColor(context, R.color.black)
          else ContextCompat.getColor(context, R.color.white))
      }
    }
    return bitMap
  }
}
```

这里最关键的就是两个for循环里面的逻辑，通过bitMatrix中获取到的信息来判断图中的颜色。如果能获取到信息，那就证明是有效位，该像素为黑色；反之为白色。

而ZXing也提供了二维码读取的能力，通过注册ScanContract来实现对二维码的读取：

```kotlin
val launcher = rememberLauncherForActivityResult(
    contract = ActivityResultContracts.StartActivityForResult()
  ) {
    if (it.resultCode == RESULT_OK) {
      val result =
        ScanIntentResult.parseActivityResult(it.resultCode, it.data)
      if (result.contents == null) {
        Toast.makeText(context, "null content", Toast.LENGTH_SHORT).show()
      } else {
        scanResult = result.contents
        getResult = true
      }
    }
  }
```

识别回来的结果被放到变量scanResult中。下面根据这些逻辑，编写前端界面：

```kotlin
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BarCodeSurface() {

  var input by remember {
    mutableStateOf("")
  }

  var scanResult by remember {
    mutableStateOf("")
  }
  
  var getResult by remember {
    mutableStateOf(false)
  }

  val context = LocalContext.current

  var bitmap by remember {
    mutableStateOf(ImageBitmap(500, 200))
  }

  val launcher = rememberLauncherForActivityResult(
    contract = ActivityResultContracts.StartActivityForResult()
  ) {
    if (it.resultCode == RESULT_OK) {
      val result =
        ScanIntentResult.parseActivityResult(it.resultCode, it.data)
      if (result.contents == null) {
        Toast.makeText(context, "null content", Toast.LENGTH_SHORT).show()
      } else {
        scanResult = result.contents
        getResult = true
      }
    }
  }

  Column {
    Image(
      bitmap = bitmap,
      contentDescription = "Bar code"
    )
    Row {
      TextField(value = input, onValueChange = { input = it }, modifier = Modifier.weight(2f))
      Button(
        onClick = {
          bitmap = ZXingWorker.textToBar(context, input).asImageBitmap()
        },
        modifier = Modifier
          .width(0.dp)
          .weight(1f)
          .align(CenterVertically)
      ) {
        Text(text = "Submit")
      }
    }
    Button(onClick = {
      getResult = false
      launcher.launch(ScanContract().createIntent(context, ScanOptions()))
    }) {
      Text(text = "Scan code")
    }
    if (getResult) {
      Text(text = "Scan result: $scanResult")
    }
  }
}
```

界面成品如下：

![[Homework/Security/resources/Pasted image 20231118184201.png|300]]

点击提交按钮，生成二维码。点击Scan code按钮，打开扫描二维码的activity，扫描到结果之后返回到Scan result。

### 三、实验总结与收获

本次实验我学习了ZXing库在安卓平台上的使用。如何通过明文生成二维码并扫描得到结果。