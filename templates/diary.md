# What I wrote today

```dataviewjs
let pages = dv.pages()
let res = []
for (let page of pages) {
	let file = page.file
	if (typeof page.mtrace !== "undefined") {
		let trace = String(page.mtrace)
		if (trace.includes("{{title}}")) {
			console.log("push!" + trace)
			res.push(file.link)
		} else {
			console.log("mtrace not equal: " + trace)
		}
	}
}
dv.list(res)
```

# Current Progress

![[resources/every_week|every_week]]