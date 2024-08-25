工作日记，按照公司分类，里面是工作的时候遇到的事情。不会有太多技术上的问题。技术上的依然分类写到Study Log中。这里主要是积累工作经验，写点老板愿意听的东西。

# Bytedance

```dataviewjs
let res = []
for (let page of dv.pages('"Work Diary/bytedance"')) {
	const date = new Date(page.date)
	const link = "[[" + page.file.path + "|" + getDateString(date) + "]]"
	let title = page.title
	if (typeof title === "string") {
		title = title.split(";")
	}
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
	["Date&Link", "Title", "Tags"], 
	res.map(x => [x.link, x.title, x.realtag])
)
```