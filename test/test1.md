---
cssclasses:
  - indent
---
# test1

Karl Marx was a German philosopher, economist, historian, sociologist, political theorist, journalist, and revolutionary socialist. He is one of the most influential figures in human history, and his work has had a profound impact on the development of modern social, economic, and political thought.  
Marx was born in Prussia (now Germany) in 1818 and studied law, philosophy, and history at the universities of Bonn and Berlin. He became interested in radical politics and eventually joined the Communist League, a group of radical communists. In 1848, Marx and his colleague Friedrich Engels published "The Communist Manifesto," which outlined their vision for a society in which the working class would overthrow the capitalist class and establish a socialist system.  
Marx's most famous work is "Das Kapital," a multi-volume analysis of capitalism and its contradictions. In this work, Marx argued that capitalism is inherently exploitative and that the exploitation of the working class is necessary for the profit and accumulation of capital. He also argued that capitalism is inherently unstable and that it will eventually be replaced by socialism, in which the means of production are owned and controlled by the workers themselves.  
Marx's ideas have had a significant impact on the development of socialist and communist movements around the world, and his work continues to be studied and debated by scholars and activists today.




```dataviewjs
let res = []
for (let page of dv.pages('"Knowledge/software_qa"')) {
	const date = new Date(page.date)
	const link = "[[" + page.file.path + "|" + getDateString(date) + "]]"
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
	["Date&Link", "Title", "Tags"], 
	res.map(x => [x.link, x.title, x.realtag])
)
```