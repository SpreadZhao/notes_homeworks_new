```dataview
list
where contains(file.tags, "language/coding/kotlin")
```

# Test

```dataviewjs
for (let page of dv.pages("#language/coding/kotlin")) {
	let fileStr = await dv.io.load(page.file.path);
	let fileName = page.file.name;
	let lines = fileStr.split('\n');
	for (let line of lines) {
		if (line.match("# .*")) {
			dv.paragraph("- " + fileName + ": " + line.replace(/^#+\s/, ""));
		}
	}
}
```
