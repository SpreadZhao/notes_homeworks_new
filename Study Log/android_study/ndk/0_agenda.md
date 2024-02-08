# Reference

* [Android JNI(一)——NDK与JNI基础 - 简书 (jianshu.com)](https://www.jianshu.com/p/87ce6f565d37)
* [Android - JNI 开发你所需要知道的基础 - 掘金 (juejin.cn)](https://juejin.cn/post/6844904192780271630)
* [Android NDK  |  Android Developers](https://developer.android.com/ndk?hl=en)

# Catalog

```dataviewjs
let res = []
const pages = dv.pages('"Study Log/android_study/ndk"')
for (let page of pages) {
	if (page.title == undefined || page.order == undefined) {
		continue
	}
	const order = page.order
	const title = page.title
	const link = page.file.link
	res.push({order, title, link})
}
pages.sort((a, b) => a.order - b.order)
dv.list(res.map(x => "[" + x.order + "]" + x.title + ": " + x.link))
```