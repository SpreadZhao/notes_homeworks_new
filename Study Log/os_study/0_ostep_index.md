# Index

```dataviewjs
let res = [];
const pages = dv.pages('"Study Log/os_study"');
for (let page of pages) {
	if (page.file.name == "0_ostep_index" || page.title == undefined) {
		continue;
	}
	const title = page.title;
	const order = page.order;
	const path = "[[" + page.file.path + "|" + title + "]]";
	res.push({path, order});
}
res.sort((a, b) => a.order - b.order);
dv.list(res.map(x => x.path));
```

# TODO

```tasks
path regex matches /Study Log/os_study/
tags include TODO
sort by priority
```