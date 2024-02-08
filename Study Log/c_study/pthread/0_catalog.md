```dataviewjs
let res = []
const pages = dv.pages('"Study Log/c_study/pthread"')
for (let page of pages) {
	if (page.file.name == "0_catalog") {
		continue
	}
	const name = page.file.name
	const order = Number(name.substring(0, name.indexOf("_")))
	const title = page.title
	const link = "[[" + page.file.path + "|" + title + "]]"
	res.push({link, order})
}
res.sort((a, b) => a.order - b.order)
dv.list(res.map(x => x.order + ": " + x.link))
```