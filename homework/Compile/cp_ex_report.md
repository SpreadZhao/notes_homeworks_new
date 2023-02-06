# 一、实验目的

为了加深对编译器基本原理和方法的理解，巩固所学知识：

1. 会用正规式描述简单语言的词法
2. 会用CFG描述简单语言的语法
3. 会用递归下降子程序编写语言的解释器

本次实验要求为规定的函数绘图语言编写一个解释器，其输入为用函数绘图语言编写的源程序，输出则为屏幕上绘制的图形

# 二、实验环境

* 平台：Android 13(API 33)
* 语言：Kotlin
* jetback compose
* material design 3

# 三、实验内容

## 3.1 总体逻辑

点击draw之后，首先就是要拿到前端的输入信息，而输入信息是需要进行词法分析的，如果直接拿走也不是不可以。但是我们考虑到，Kotlin这种语言处理字符串的能力是很强的，为什么我们在这里不先处理一下呢？函数绘图语言的每一句话都是以分号结尾的，因此我们按照分号将输入信息分成一个个句子，同时删去每个分号和之后的换行符，这样就不需要后续去一句句地匹配了。这里的一个个句子我们选择用`List<String>`去储存

接着就是将我们处理好的输入信息传给词法分析器，进行词法分析

然后就是将词法分析的结果串给语法分析器，进行语法分析

拿到语法分析的结果，就可以开始画图了。我们采取了用Canvas打点的方式，只要给出每个点的横纵坐标，就可以在画布上打上对应的点。打完所有的点之后，图像旋转的处理我们采用了Canvas自带的`rotateRad`方法，可以直接以原点为中心旋转给定的弧度

## 3.2 词法分析

在定义Scanner时，我们将其定义为object类，Kotlin中的object类相当于Java的**单例模式**，全局只有一个实例。这是Kotlin对于单例模式开的一个小灶，只要我们定义为object类，单例模式需要的重复工作我们就都不需要去做了，用起来就像静态变量一样特别方便

做词法分析之前，我们先要明确词法分析的结果，就是一堆Token，以origin is (500,400)为例：

>origin —— id
>is —— id
>( —— 符号，左括号
>500 —— 数字，值为500
>, —— 符号，逗号
>400 —— 数字，值为400
>) —— 符号，右括号

由于我们先前将输入信息分成了多个List，为了将分析结果传出去，我们将识别结束后的所有Token序列存入一个List的List，第一层中每个元素是一个句子的Token序列，第二层中国是每个句子的各个Token，传出时就只需要将整个大的List传出去即可

我们在定义完这个大的List后，写了`val allTokens get() = _allTokens`这么一段话，这是Kotlin的特有写法。在所有要被公开的私有属性前加上一个下划线，然后再定义一个没有加下划线的属性并令其的get()方法值为前面那个属性，这样我们在外部拿这个属性时，只需要`Scanner.allTokens`即可。

```java
public ArrayList<ArrayList<Token>> getAlltokens(){
	return _allTokens;
}
```

如果是Java，我们只能采取上面这种写法，然后在外部用`Scanner.getAlltokens()`调用。但是我们想得到的只是Scanner的一个成员，`Scanner._allTokens`显然要更加直观，但在Java里由于它是私有属性，这样是访问不到的

拿到了处理好的输入信息，也明确了分析结果，接下来就正式进入词法分析的部分，我们要去对每一个`List<String>`去遍历，这时我们就得去思考如何达成识别的目的了。我们要做的就是寻找共同点：

1. 假设我们遍历到了一个字母“O/o”，那么它便有可能是关键字：origin，也有可能是变量：orange/ocean/octopus...，这俩类都是以字母开头的id，那么就意味着在分析时我们看到了一个字母，就可以继续往后遍历，直到找完这段序列
2. 假设我们遍历到了一个数字“5”，那么这段序列一定是一个数字，这个“5”的的后面还可能跟着一串的数字，甚至有可能是小数，涉及到小数点的处理
3. 假设我们遍历到了一个符号“(”，这类符号都是独立的，再往后就不是了

**抓住这些序列的共同点，我们就可以通过写正则表达式来区分了**。

```kotlin
// 识别一个id，以字母开头，后面跟上若干字母或者数字
private val regexId = Regex("[a-zA-Z]+(([a-zA-Z]|[0-9])*)?")
// 识别一个数字，整数或者小数
private val regexDigit = Regex("[0-9]+(\\.[0-9]*)?")
// 识别单个符号，都是程序允许出现的单个符号
private val regexSymbol = Regex("[,/\\(\\)\\*\\+\\-\\^]")
```

需要注意的是，在遍历的过程中，我们的下标i不能简单地累加。在遍历到id和数字序列时，我们要**把i移动到匹配后的坐标再继续遍历**，以防出现遍历完origin之后又从r处开始遍历的情况

在匹配id的方法中，我们就将遍历出的序列与关键字一一匹配，如果全部匹配失败就将其匹配为参数。这里要用到一系列Tokenxxx类，必须涵盖所有可能出现的id，所有的Tokenxxx类都是Token类的子类，这里我们着重看一下Token类：

```kotlin
enum class TokenType{
    NULL,
    ID, COMMENT,
    ORIGIN, SCALE, ROT, IS,
    TO, STEP, DRAW, FOR, FROM,
    PARAM,
    SEMICO, L_BRACKET, R_BRACKET, COMMA,
    PLUS, MINUS, MUL, DIV, POWER,
    FUNC,
    CONST_ID,
    NON_TOKEN,
    ERROR_TOKEN
}

open class Token {
    protected open var _type: TokenType = TokenType.NULL
    protected open var _originStr: String = ""
    protected open var _value: Double = Double.NaN
    /**
     * 所有token的type和原始字符串都可以给getter，
     * 所以写到父类中。
     */
    open val type get() = _type
    open val originStr get() = _originStr
}
```

>另外，Kotlin和Java不同，它默认不允许继承，想要实现继承需要在类前加上open，这一特性也使得Kotlin更加安全

在完成遍历之后，我们就得到了一个`List<Token>`，也就是当前句子分析完后的所有Token。由于之后我们还要进行语法分析，要按照句子去匹配，而语法分析是一个递归的过程，随时可能有很大的跨度，是不能用顺序结构处理的。分号表明一个句子的结束，但是我们之前处理输入信息时删去了分号，所以这里还需要手动在`List<Token>`的结尾添加分号

## 3.3 语法分析

我们采用的语法分析器是top-down parser，通过递归从底部的叶节点向根节点方向构造分析树，但从上往下进行分析，以下面这段程序为例：

>origin is (500,400);
>scale is (100,100);
>for t from 0 to 1000 step 8 draw (sin(t),cos(t));

我们能将其以分号为界，能分为三个句子；将三个句子再进一步细分，就是一个个Token。而top-down parser的思想也就是这么一个不断拆分的过程，把大结构拆成小结构。而拆分需要根据文法来进行：

![[homework/Compile/resources/Pasted image 20230205202028.png]]

而我们语法分析最核心的目的就是实现这个文法

最上层的工作就是匹配Program，经过之前的处理，我们的信息已经全部存储在一个大List中，只需要写一个循环遍历完这个List就可以了，下面我们来仔细看看这个大List的结构：

![[homework/Compile/resources/Drawing 2023-02-05 23.06.46.excalidraw.png]]

如果我们要拿到红圈位置的Token，在Java中是`allTokens.get(0).get(3)`，而Kotlin中只需要`allTokens[0][3]`，这和二维数组十分相似。既然如此，我们就把它当成二维数组来分析，遍历这个大List需要访问的下标组合如下：

* 00 01 02 03 04
* 10 11 12
* 20 21

**在扫描每一句话时，前面的下标不变，后面的下标累加；而在跳到下一句话时，前面的下标加一，后面的下标归零**。因此，我们在遍历时就需要拿两个参数：

1. statementIndex：指向是第几句话，也就是前面的下标
2. tokenIndex：指向是该句话的第几个Token，也就是后面的下标

按照前面总结的规律，**每当我们扫完一句话，我们都要将statementIndex累加并将tokenIndex归零**

进入下一层，我们要做的就是匹配Statement，Statement只有四个匹配结果，我们关注它们的首个Token进行区分：

1. OriginStatement：首个Token为Origin
2. ScaleStatement：首个Token为Scale
3. RotStatement：首个Token为Rot
4. ForStatement：首个Token为For

如果四种结果都匹配失败了，就给出报错信息“unrecognized sentence type”

再进入下一层，就是匹配xxxStatement了，这里我们以OriginStatement为例：依次匹配origin、is、左括号、Expression、逗号、Expression、右括号

在匹配单个Token时，我们设计了`matchToken(type:TokenType)`方法，这个方法的参数就是我们所设计的类型。用当前Token的类型与设计的类型相比较，无论相等与否，都要累加tokenIndex继续向后匹配，不相等时就需要给出相应的报错信息。例如匹配origin时，调用`matchToken(TokenType.ORIGIN)`即可

从Expression到Atom的层层匹配是整个实验项目最为复杂的一部分，这里通过一个表达式简单说明：

![[homework/Compile/resources/Drawing 2023-02-06 14.22.22.excalidraw.png]]

通过层层递归，上面这个表达式的Token能被一个个拆分出来，建成这么一个树，通过这棵树，我们以后序遍历的方式就可以计算出表达式的值

值得注意的是，**除了ForStatement，另外三种xxxStatement都不允许参数的存在**，因此在匹配时，我们需要对当中Expression建成的树进行遍历，一旦发现结点中有参数存在，就要给出报错信息“should not contain parameter”

而对于ForStatement，由于我们要进行参数的处理，在匹配完第一个参数后，必须将这个参数记录下来。后续在Expression处理中一旦扫到了参数，我们就可以进行判断，从而处理前后参数不一致的错误情况

# 四、心得体会

## 4.1 关于可组合函数

在MainActivity的`onCreate`方法中，我们需要设置好它的内容。这里比较关键的点在于我们向其中添加了一个函数`ShowCmd`，这个函数包含所有我们在程序界面能看到的信息

不得不提，`ShowCmd`函数是一个可组合函数，Kotlin的可组合函数有一个非常实用的特性，它可以在函数里定义函数，定义的函数作用域与当前函数作用域相同。不难发现，通过这种方式，函数与类就十分相似了，用起来会特别省心舒适

```kotlin
var text by remember {
    mutableStateOf("")
}
```

以text为例，在定义该函数所用的变量时，我们采取了上方这种写法，其实意思和`var text = ""`一样。这里采取这种写法的主要原因是：这些变量我们需要在前端显示，而可组合函数的生命周期比较乱，处理不好的话很容易出现变量值改变但前端未显示出来的情况，我们通过`by remember`则可以让程序随时记住变量的当前状态

## 4.2 小List的定义位置

关于词法分析`List<Token>`的定义位置也很有说法，之前我们想当然地将它定义在类的成员位置，那么在将其add到大List之后就必须将其clear以防影响下一次操作(如果不clear大List中将会是多个重复的第一句话分析结果)，结果调试后发现大List中是空的！

原来`add()`方法并不是把容器A中的东西复制一遍加到容器B中，而是把A容器的引用加到容器B中，这意味这add后A、B容器中的东西指向的是同一个东西，而clear清掉的正是它们指向的东西

为了解决这个问题，我们将`List<Token>`定义在循环内，这样意味着遍历每一句话前都会创建一个小List，就可以不用clear也不影响下一次操作了