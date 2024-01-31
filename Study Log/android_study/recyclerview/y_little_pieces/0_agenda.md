```dataviewjs
let res = []
for (let page of dv.pages('"Study Log/android_study/recyclerview/y_little_pieces"')) {
	if (page.file.name == "0_agenda") {
		continue
	}
	const date = new Date(page.date)
	const link = "[[" + page.file.path + "|" + getDateString(date) + "]]"
	console.log("Test: " + page.title)
	const title = page.title.split("; ")
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