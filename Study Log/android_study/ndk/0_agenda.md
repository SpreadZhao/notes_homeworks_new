# Reference

* [Android JNI(一)——NDK与JNI基础 - 简书 (jianshu.com)](https://www.jianshu.com/p/87ce6f565d37)
* [Android - JNI 开发你所需要知道的基础 - 掘金 (juejin.cn)](https://juejin.cn/post/6844904192780271630)
* [Android NDK  |  Android Developers](https://developer.android.com/ndk?hl=en)
* [NDK第一讲(入门基础知识)哔哩哔哩bilibili](https://www.bilibili.com/video/BV1wz4y1x7tr/?spm_id_from=333.788.recommend_more_video.-1&vd_source=64798edb37a6df5a2f8713039c334afb) [jiangchaochao/NDK: NDK开发扫盲资料及demo (github.com)](https://github.com/jiangchaochao/NDK)

# Catalog

```dataviewjs
let res = []
const pages = dv.pages('"Study Log/android_study/ndk"')
for (let page of pages) {
	if (page.title == undefined) {
		continue
	}
	const name = page.file.name
	const order = Number(name.substring(0, name.indexOf("_")))
	const title = page.title
	const link = page.file.link
	res.push({order, title, link})
}
pages.sort((a, b) => a.order - b.order)
dv.list(res.map(x => "[" + x.order + "]" + x.title + ": " + x.link))
```