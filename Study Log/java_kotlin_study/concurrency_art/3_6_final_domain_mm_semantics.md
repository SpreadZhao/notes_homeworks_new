---
title: 3.6 final域的内存语义
chapter: "3"
order: "9"
---
## 3.6 final域的内存语义

我们还是通过一个例子来看final的内存语义：

```java
public class FinalExample {  
    int i;                              // 普通变量
    final int j;                        // final变量 
    static FinalExample obj;  
  
    public FinalExample() {             // 构造方法  
        i = 1;                          // 写普通域  
        j = 2;                          // 写final域  
    }  
  
    public static void writer() {       // 写线程A执行  
        obj = new FinalExample();  
    }  
  
    public static void reader() {       // 读线程B执行  
        FinalExample example = obj;     // 读对象引用  
        int a = example.i;              // 读普通域  
        int b = example.j;              // 读final域  
    }  
}
```

<label class="ob-comment" title="还是假设writer先执行，随后reader才执行" style=""> 还是假设writer先执行，随后reader才执行 <input type="checkbox"> <span style=""> 我觉得这里有必要把这个条件说得更详细一些。writer先执行，reader后执行的意思并不是等writer执行完毕之后reader才开始执行。不然我们也不用讨论并发了。这里说的就是只要writer执行了，reader随时可以执行。具体的时许还得看java的编译器和CPU是怎么决定的了。 </span></label>。首先，Java的任何变量都只能存在于类里对吧！那这样的话，final修饰的一定是一个类的一个成员。就比如上面的`j`。那么，final域的重排序规则是这样的：

**<center>对final域的写，禁止重排序到final域之外。</center>**

- [ ] #TODO 第三章剩下的内容等学完代码再来补上吧。太tm难啃了。 🔽

---

```dataviewjs
const pages = dv.pages('"Study Log/java_kotlin_study/concurrency_art"')
let nextChapterHead = undefined
let res = undefined
const current = dv.current()
for (let page of pages) {
	if (page.chapter_root == true && page.order == Number(current.chapter) + 1) {
		console.log("found next head: " + page.name)
		nextChapterHead = page
		continue
	}
	if (page.chapter == undefined || page.chapter != current.chapter) {
		console.log("not current chapter: " + page.file.name)
		continue
	}
	if (page.order == Number(current.order) + 1) {
		res = page
	}
}
console.log("res: " + res)
console.log("next: " + nextChapterHead)
if (res == undefined) {
	res = nextChapterHead
}
let text = ""
if (res != undefined) {
	const path = res.file.path
	const title = res.title
	const decoLink = "[[" + path + "|" + title + "]]"
	text = "Next Article: " + decoLink
} else {
	text = "旅途的终点！"
}
dv.el("p", text, { attr: { align: "right" } })
```