```dataviewjs
let res = []
for (let page of dv.pages('"Study Log/android_study/recyclerview/y_little_pieces"')) {
	if (page.file.name == "agenda") {
		continue
	}
	const date = new Date(page.date)
	console.log("date: " + page.date)
	const link = "[[" + page.file.path + "|" + getDateString(date) + "]]"
	const title = page.title
	res.push({link, date, title})
}
function getDateString(date) {
	const year = date.getFullYear()
	const month = date.getMonth() + 1
	const day = date.getDate()
	return year + "年" + month + "月" + day + "日"
}
res.sort((a, b) => a.date - b.date)
dv.list(res.map((x) => x.link + ": " + x.title))
```