```dataviewjs
let res = []
for (let page of dv.pages('"Study Log/java_kotlin_study/java_kotlin_study_diary"')) {
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
				console.log("find illegal tag: " + tag)
			}
			realtag = realtag + tags[i] + " "
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