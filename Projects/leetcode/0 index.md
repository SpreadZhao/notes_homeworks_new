```dataviewjs
let res = [];
const pages = dv.pages('"Projects/leetcode"');
for (const page of pages) {
	if (page.num == undefined) {
		continue;
	}
	const num = page.num;
	const title = "[[" + page.file.path + "|" + page.title + "]]";
	const link = page.link;
	const difficulty = "#" + page.tags[0];
	res.push({num, title, link, difficulty});
}
res.sort((a, b) => a.num - b.num);
dv.table(
	["Num", "Title", "Link", "Difficulty"],
	res.map(x => [x.num, x.title, x.link, x.difficulty])
);
```

## TODO

```tasks
path regex matches /Projects/leetcode/
tags include TODO
sort by priority
```