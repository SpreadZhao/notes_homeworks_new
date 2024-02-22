---
mtrace:
  - 2023-07-15
  - 2023-07-16
tags:
  - block_and_conquer
  - question/coding/android
  - difficulty/hard
  - language/coding/kotlin
  - question/coding/practice
  - question/coding/android/compose
---
# 单词绘制了两遍的问题

#date 2023-07-15

在某一个Composable函数中，我是这样写的：

```kotlin
@Composable  
fun TestManageWordScreen(  
    viewModel: JapViewModel  
) {  
    viewModel.getAllWords()  
    LazyColumn {  
        viewModel.wordsUI.forEach {  
            item {  
                JapaneseWordCard(  
                    word = it,  
                    sentence = it.sentenceContent,  
                    viewModel = viewModel  
                )  
            }  
        }    
	}
}
```

很简单，在这个页面出现的时候，就调用viewModel的getAllWords()方法得到一些数据。当得到之后，数据会存在wordsUI之中，然后在LazyColumn中显示出来。然而，我却发现，每次进入TestManageWordScreen中时，**这些数据都会被重复加载2遍**。之后我进行debug，发现确实`viewModel.getAllWords() `这个函数被执行了两遍。

之后，无论我在底层用什么方法实现（包括协程，自己实现回调监听，Kotlin Flow），都是同样的结果。所以我猜测是Compose的重绘导致的。

之后，我查到了这样的一个方法：

[Compose 中的附带效应  |  Jetpack Compose  |  Android Developers (google.cn)](https://developer.android.google.cn/jetpack/compose/side-effects?hl=zh-cn)

[Side-effects in Compose  |  Jetpack Compose  |  Android Developers](https://developer.android.com/jetpack/compose/side-effects)

好家伙，文章开头就提到了我们如何应对在Compose生命周期之外应该如何处理这样的逻辑。而网络请求，数据库请求这样的异步操作正属于此类。所以，我们只需要对获取数据的方法做这样的修改：

```kotlin
LaunchedEffect(Unit) {  
    viewModel.getAllWords()  
}
```

这样获取数据的操作被放在了一个单独的协程作用域中，也就不会受Compose生命周期的影响了。

# 使用Compose实现一个单选框

#date 2023-07-16

效果：

![[Article/story/resources/Pasted image 20230716141727.png|300]]

我们需要实现，**只能选择这些项目之中的一个**。

首先是最外层的布局，因为一旦超出屏幕，需要能够自动换行。所以我使用了FlowRow来做最外层的布局：

```kotlin
FlowRow {  
	...
}
```

然后，因为需要对每一个词性的名称，还有是否被选中加以记录（这是Compose中必须要实现的，和UI更新挂钩的变量），所以我创建了一个类，用来记录这个框的词性以及是否被选中：

```kotlin
data class WordTypeUI(  
    val value: Int,  
    val name: String,  
    var isChecked: Boolean  
)
```

其中Value是词性的代号，它们会用WordConstant来赋值：

```kotlin
object WordConstant {  
    const val NONE = -1  
    const val NOUN = 0  
    const val VERB_1 = 1  
    const val VERB_2 = 2  
    const val VERB_3 = 3  
    const val ADJECTIVE_1 = 4  
    const val ADJECTIVE_2 = 5  
    const val ADVERB = 6  
    const val CONJUNCTION = 7  
    const val INTERJECTION = 8

	fun getWordType(type: Int): String = when (type) {  
	    NOUN -> "名词"  
	    VERB_1 -> "动1"  
	    VERB_2 -> "动2"  
	    VERB_3 -> "动3"  
	    ADJECTIVE_1 -> "形1"  
	    ADJECTIVE_2 -> "形2"  
	    ADVERB -> "副词"  
	    CONJUNCTION -> "连词"  
	    INTERJECTION -> "感叹词"  
	    else -> "错误"  
	}
}
```

接下来，就是在Compose之中定义一个可以remember的列表，用来存这几个选择框的UI数据：

```kotlin
val wordTypeList = remember {  
    mutableStateListOf<WordTypeUI>().apply {  
        add(WordTypeUI(WordConstant.NOUN, "名词", false))  
        add(WordTypeUI(WordConstant.VERB_1, "动1", false))  
        add(WordTypeUI(WordConstant.VERB_2, "动2", false))  
        add(WordTypeUI(WordConstant.VERB_3, "动3", false))  
        add(WordTypeUI(WordConstant.ADJECTIVE_1, "形1", false))  
        add(WordTypeUI(WordConstant.ADJECTIVE_2, "形2", false))  
        add(WordTypeUI(WordConstant.ADVERB, "副词", false))  
        add(WordTypeUI(WordConstant.CONJUNCTION, "连词", false))  
        add(WordTypeUI(WordConstant.INTERJECTION, "感叹词", false))  
    }  
}
```

然后，该在FlowRow里填点逻辑了：

```kotlin
FlowRow {  
    wordTypeList.forEachIndexed { index, type ->  
        Row {  
            Checkbox(  
                checked = wordTypeList[index].isChecked,  
                onCheckedChange = {  
                    onCheck.invoke(index, type, it)  
                }  
            )  
            Text(text = type.name, modifier = Modifier.clickable {  
                onCheck.invoke(index, type, !wordTypeList[index].isChecked)  
            })  
        }  
    }
}
```

这里的参数type就是我们之前定义的WordTypeUI的一个实例。然而，你可能会注意到，我们在这里又额外给了一个index，并且**尽量都使用index来获取到实例，而不是直接用type**。比如在Checkbox中：

```kotlin
checked = wordTypeList[index].isChecked,
```

我们让checked是list中的第index个的状态，而不是type，但是理论上他俩应该是同一个东西。我为什么没这么写呢？当然是有问题呀！我们修改一下这里的逻辑，在onCheckedChange里面打上两条日志：

```kotlin
FlowRow {  
    wordTypeList.forEachIndexed { index, type ->  
        Row {  
            Checkbox(  
                checked = wordTypeList[index].isChecked,  
                onCheckedChange = {  
                    onCheck.invoke(index, type, it)  
                    Log.d(tag, "index result: ${wordTypeList[index].isChecked}")  
                    Log.d(tag, "type result: ${type.isChecked}")  
                }  
            )  
            Text(text = type.name, modifier = Modifier.clickable {  
                onCheck.invoke(index, type, !wordTypeList[index].isChecked)  
            })  
        }  
    }
}
```

然后观察一下输出：

![[Article/story/resources/Pasted image 20230716143311.png]]

我觉得不用解释什么了吧！我们选择了动1，index的方式打出了正确的结果，而type自己的结果却是错误的。下面我们把动1的勾去掉看看：

![[Article/story/resources/Pasted image 20230716143444.png]]

我们能看到，**type的数据总是比用index获取的要慢一拍**。而我目前还不知道为什么，只是猜测和Compose的生命周期有关。因为我现在是在调用forEachIndexed，本质是一个for循环，不像单个变量那样迅速就能执行完毕。

- [ ] #TODO #question/coding/android/compose 多选框的type为什么会慢一拍，原因要探究出来 🔽

接下来，就是这个高阶函数onCheck的实现逻辑了。其实，如果只实现悬浮窗的话，我们直接写在这个lambda里就好了，因为逻辑很简单：

```kotlin
val onCheck: (index: Int, type: WordTypeUI, check: Boolean) -> Unit = { index, type, check ->  
    wordTypeList[index] = wordTypeList[index].copy(isChecked = check)  
    for (i in wordTypeList.indices) {  
        if (wordTypeList[i].isChecked && i != index) {  
            wordTypeList[i] = wordTypeList[i].copy(isChecked = false)  
        }  
    }  
}
```

我们将这个isChecked变量重新用check赋值，然后循环遍历一下列表，将其他所有的框都置为false。然而如果将这段逻辑写在lambda里，后面的文字就是不可点击的了，除非 我们再抄一遍。但是那样总显得不够优雅，所以我把这个逻辑抽了出来。

比较重要的是，为什么这里使用了copy函数。如果我们这样写呢？

```kotlin
val onCheck: (index: Int, type: WordTypeUI, check: Boolean) -> Unit = { index, type, check ->  
    wordTypeList[index].isChecked = check
    for (i in wordTypeList.indices) {  
        if (wordTypeList[i].isChecked && i != index) {  
            wordTypeList[i].isChecked = false
        }  
    }  
}
```

如果用了这样的写法，那么后果是灾难性的。在实际使用的时候，会出现以下问题：

* 有的复选框根本选不了；
* 有的复选框选上了之后取消不了，只能通过点击其他复选框取消；
* 日志的输出完全混乱，甚至index的结果也出现了错误；
* 那些点不了的复选框，虽然UI显示没有选上，但是实际上是选上了的。

#block_and_conquer 为什么Compose中更新mutableList的成员时要用copy函数而不能修改成员

为什么会这样？我问了ChatGPT，它的回答如下：

> 在上述代码中，使用 `mutableStateListOf` 创建的 `wordTypeList` 是一个可变状态列表，但是对列表中的元素进行修改时，必须通过 `copy` 方法创建新的元素来确保状态更新。这是因为 Compose 的状态更新是基于不可变数据的。
> 
> 当你直接修改 `wordTypeList` 中的元素属性时，Compose 无法检测到状态的更改，从而无法触发 UI 的重新绘制。因此，为了正确触发状态更新，应该创建新的元素并替换列表中的旧元素。
> 
> 使用 `copy` 方法创建新的元素，实际上是复制了旧元素的属性，并进行了修改，从而创建了一个新的不可变元素。这样，Compose 就能检测到状态的更改，并重新绘制相关的 UI。
> 
> 另外，注意到你在 `onCheck` 函数中使用了 `wordTypeList[i] = wordTypeList[i].copy(isChecked = false)` 来更新元素，这是正确的做法。而直接修改 `wordTypeList[i].isChecked` 的方式不会触发状态更新，从而导致 UI 不会更新。
> 
> 总结起来，为了确保 Compose 可以正确检测到状态的更改并更新 UI，你应该使用不可变的数据，并通过创建新的元素（通过 `copy` 方法）来更新列表中的元素。这样可以确保状态的一致性，并正确触发 UI 的重新绘制。

我的理解就是，mutableStateListOf只能保证到**泛型里面的类型，也就是WordTypeUI**是能被观察到的，而如果我给这个类型里面的成员做改动，Compose是观察不到这样的变化的，也就无法更新到UI中。因此我必须让这个类型做出改变，自然就是要构造一个新的WordTypeUI实例，并改变这个实例里的成员，然后将它放到原来列表里的那个位置替换原来的WordTypeUI实例。这样意味着WordTypeUI本身发生了改变，自然Compose就能观察到了。**而copy函数本身就是一个能实现这样的功能的函数**。

ChatGPT也对我的理解表示认可：

> 是的，你的理解是正确的。
> 
> `mutableStateListOf` 创建的列表能够确保列表本身的可观察性，即当列表的引用发生变化时，Compose 可以检测到并更新相关的 UI。但是，它并不会深度观察列表中元素的属性的变化。
> 
> 当你直接修改列表中元素的属性时，列表本身的引用并没有发生变化，因此 Compose 无法察觉到状态的更改，从而无法触发 UI 的重新绘制。
> 
> 为了确保 Compose 可以正确检测到状态的更改并更新 UI，你需要创建一个新的元素实例，将修改后的属性值应用于新实例，并将新实例放回列表中原来的位置，以替换旧的元素实例。这样，列表本身的引用发生了变化，Compose 就能检测到状态的更改，并更新相关的 UI。
> 
> 所以，确保在修改可观察列表中元素的属性时，通过创建新的实例来进行更改，并将新实例放回列表中的原位置，是确保 Compose 能够正确观察到状态更改并更新 UI 的关键步骤。

# 使用Kotlin Flow实现延迟发送请求

#date 2023-07-16

[(45条消息) Kotlin Flow响应式编程，操作符函数进阶_kotlin 响应式delayed_guolin的博客-CSDN博客](https://blog.csdn.net/guolin_blog/article/details/127939641?spm=1001.2014.3001.5501)

这篇文章中就提到了使用debounce来进行延时操作。但是我的这个情况却有些不同。

在我的JapInHands项目中，是想用Jetpack Compose来实现这个功能，并且我的操作也不是网络请求，只不过是一个将用户输入的数据保存到ViewModel中的操作：

```kotlin
val saveWord: () -> Unit = {  
	Log.d(tag, "Word type choice: ${viewModel.wordTypeChoice.value}")  
	val word = Word(  
		kanji = kanjiText,  
		gana = ganaText,  
		meaning = meaningText,  
		notice = noticeText,  
		type = viewModel.wordTypeChoice.value ?: WordConstant.NONE,  
	)  
	Log.d(tag, "Save word: $word")  
	viewModel.saveWord(word)  
}
```

我们在任何地方调用`saveWord.invoke()`，就可以执行这段逻辑了。然而，如果我们把这段逻辑直接写在TextField的onValueChange中，就意味着只要文字发生了变化就执行一遍这样的逻辑。这显然是一种对性能的浪费。所以，我打算使用Kotlin Flow来实现**当停止输入1s时，才执行这段逻辑**。这也是我首次应用Kotlin Flow的功能，特此纪念。

首先，我们注意一下我们执行的逻辑：它没有需要传入的参数，也就是这是一段独立的逻辑。而这意味着**我们并没有任何可以包装成Flow的东西**。那怎么办？那就不传呗！我们只需要将一段没有任何用处的数据，**又或者直接就是Unit**包装到Flow对象中传递，然后当下游收集到这段数据时执行相应的逻辑就可以了。所以，我定义了一个没有任何东西的Flow：

```kotlin
val coroutineScope = rememberCoroutineScope()  
val inputFlow = remember {   
	MutableSharedFlow<Unit>()   
}
```

> 不需要关心MutableSharedFlow到底是什么。因为此时的我也不知道。之后我会在我的Kotlin Flow学习笔记中将它补全。
> 
> 
> - [ ] #TODO Kotlin Flow笔记 🔽

这样，我们只需要关心两件事：

* inputFlow的emit方法会发送一个数据，也就是Unit；
* inputFlow的collectXXX方法会收集到我们发送的Unit。

现在回到一开始郭神的文章，**控制延时的操作就在collect的过程中**。而发送的逻辑却不那么重要，有东西就发。所以，我们依然在输入框中直接写`inputFlow.emit(Unit)`就好[^1]。但是，这个逻辑也必须要在协程作用域里才能用。而这也是我们为什么要使用`rememberCofroutineScope()`来记住协程作用域的原因： ^94d033

```kotlin
TextField(  
    modifier = Modifier.fillMaxWidth().padding(8.dp),  
    value = meaningText,  
    onValueChange = {   
		meaningText = it  
        coroutineScope.launch { inputFlow.emit(Unit) }  
    },  
    label = { Text(text = "翻訳") }  
)
```

下一个问题就是，什么时候收呢？显然，我们需要一段业务逻辑来封装collectXXX。并且它还要一直保持这个执行的过程。其实，也就是在Composable函数中的协程作用域里执行这段逻辑罢了。联系[[Article/story/2023-07-15#单词绘制了两遍的问题|昨天]]的方法，我们这么写：

```kotlin
LaunchedEffect(Unit) {  
	coroutineScope.launch {  
		inputFlow  
			.debounce(1000) // 停止输入多少号毫秒之后执行  
			.collectLatest {  
				saveWord.invoke()  
			}  
	}    
}
```

```ad-warning
title: 注意

LaunchedEffect只是保证我们的周期会和它脱离，并不代表着这段代码只会执行一遍。昨天的那段逻辑是因为首次执行，并且没有Flow的东西，所以理应执行一次。

另外，这段逻辑接受的是谁？是**Unit**！可要记住咯！
```

现在能存单词了，我们再看一看存句子的情况。存句子是直接调用viewModel的方法实现的，并且在里面需要我们传入一个Sentence对象。显然，这个时候我们传的就不是Unit了，而是Sentence。然后照葫芦画瓢就可以：

```kotlin
LaunchedEffect(Unit) {  
    coroutineScope.launch {  
        inputFlow  
            .debounce(1000)  
            .distinctUntilChanged()  
            .collectLatest {  
                viewModel.saveSentence(it)  
            }  
    }
}

TextField(  
    modifier = Modifier.fillMaxWidth(),  
    value = sentenceText,  
    onValueChange = {  
        sentenceText = it  
        val sentence = Sentence(  
            content = sentenceText  
        )  
        coroutineScope.launch {  
            inputFlow.emit(sentence)  
        }  
    },  
    label = { Text(text = "例句") }  
)
```

这里需要注意几点。首先就是泛型里面从Unit换成了Sentence，这很好办。然后就是这个`distinctUntilChanged()`方法。这个方法在之前传Unit的时候是没有的，那如果我们加上了这个方法会出现什么呢？

答案是，如果我在单词页面加上了这个方法，**在输入文字的时候，无论怎么输入，最终saveWord只会执行一次**。我一开始还很奇怪，怎么会这样呢？*我每次传进去的单词对象都是和之前不一样的，为什么它不执行呢*？后来我意识到，我之前的想法从根本上就是错误的：**我传的是Unit，而不是单词啊**！由于每次传的都是Unit，每次都是一样的，所以distinctUnitChanged()方法就把除了第一次以外的所有请求都过滤了；然而，在存句子的时候，由于Sentence每次就是不一样的，所以才不需要这么做。

# View测量布局流程的再感悟

#date 2023-07-16

在我的View绘制流程笔记中，有[[Study Log/android_study/view_create_flow#^107fa1|这样]]一段话：*测量时，先测量子View的宽高，再测量父View的宽高。但是在布局时顺序则相反，是父View先确定自身的布局，再确认子View的布局*。

这句话我当时只是当结论记了，并没有思考一下到底是为什么。直到我看到了扔物线的视频，我才明白怎么回事。并且，这句话内部实际上是有歧义的，接着看下去吧！

我们之前也说过，onMeasure中的那两个参数是**父布局（不是父类）**对我们尺寸的期望。而经过我的实践，这个值实际上就是我们在XML中传入的参数：

![[Article/story/resources/Pasted image 20230716224716.png|400]]

不知道你是否也注意过，为什么有的参数前面要加上一个`layout`？这个代表着什么？现在这个谜底才揭晓：**这实际上就是<u>最终</u>需要传递给父布局的参数**。

假设SuquareImageView是ImageView的子类，那么实际情况就是，ImageView的onMeasure方法已经在SDK中被实现过了，我们可以直接拿来用。因此我们可以使用getMeasuredWidth()和getMeasuredHeight()来得到已经由父类测量过的尺寸：

![[Article/story/resources/Pasted image 20230716225748.png]]

然而，**这个由父类测量过的尺寸并不一定满足父布局的要求**，所以我们需要做适当的调整才能满足，最后调用setMeasuredDimension()方法来确定我们的尺寸：

![[Article/story/resources/Pasted image 20230716230010.png]]

```ad-important
注意体会父类和父布局的区别。什么叫父View？什么叫父布局？如果你把它们两个理解为同一个意思，那还好说，但是如果你把它们俩和父类理解成一个意思，那就坏了。

SuquareImageView是ImageView的子类这没错，**但在XML里它能在Image里面吗**？显然不能，它一定是被包裹在某一个**Layout，也就是布局，也就是ViewGroup**里的！所以实际上给我们限制的应该是真正写在XML中时，我们当前标签外部的那些布局标签。
```

因此，最终是SquareImageView将自己的尺寸计算完毕后返回给**父布局**，由父布局来统计出里面所有View的大小。而根节点的View自然就是最后被计算出来大小的那个。这也正对应了前半句“测量时，先测量子View的宽高，再测量父View的宽高”。

[^1]: [Unit 为啥还能当函数参数？面向实用的 Kotlin Unit 详解 - 掘金 (juejin.cn)](https://juejin.cn/post/7231345137850286138)