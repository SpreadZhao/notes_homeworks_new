---
mtrace:
  - 2023-10-26
  - 2023-10-29
  - 2023-11-25
tags:
  - question/coding/android
  - language/coding/kotlin
  - language/coding/java
  - question/coding
description: 安卓开发遇到的问题，bug，编译错误之类的。
---
# 安卓开发遇到的问题

```dataviewjs
let res = []
for (let page of dv.pages('"Study Log/android_study/android_dev_trouble"')) {
	const date = new Date(page.date)
	const link = "[[" + page.file.path + "|" + getDateString(date) + "]]"
	const title = page.title
	const tags = page.tags
	let realtag = ""
	if (tags != undefined) {
		for (let i = 0; i < tags.length; i++) {
			const tag = tags[i]
			if (tag.indexOf("#") !== 0) {
				tags[i] = "#" + tag
			}
			realtag = realtag + tags[i]
			if (i != tags.length - 1) {
				realtag += " "
			}
		}
	} else {
		realtag += "No tag"
	}
	res.push({link, date, title, realtag})
}
function getDateString(date) {
	const year = date.getFullYear()
	const month = date.getMonth() + 1
	const day = date.getDate()
	return year + "年" + month + "月" + day + "日"
}
res.sort((a, b) => b.date - a.date)
dv.table(
	["Date&Link", "Title"], 
	res.map(x => [x.link, x.title])
)
```