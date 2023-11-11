```dataviewjs
let data = [];
for (let page of dv.pages("#language/coding/java")) {
	let fileStr = await dv.io.load(page.file.path);
	let lines = fileStr.split('\n');
	let headers = "";
	for (let line of lines) {
		let hashCount = 0;
		if (line.match(/^#+\s/)) {
			hashCount += (line.match(/#/g) || []).length;
			headers += generateNestedList(hashCount, line.replace(/^#+\s/, ""));
		}
	}
	let fileLink = "[[" + page.file.path + "]]";
	headers = "<div style=\"border: 2px solid #D58E06; padding: 10px;\">" + headers + "</div>";
	data.push({fileLink, headers})
}
function generateNestedList(level, content) {
	if (level === 0) { 
		return content; 
	} 
	const nestedListContent = generateNestedList(level - 1, content); 
	return `<ul><li>${nestedListContent}</li></ul>`; 
}
dv.table(
	["File Name", "Headers"],
	data.map(d => [d.fileLink, d.headers])
);
```