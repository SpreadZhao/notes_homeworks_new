---
cssclass: dashboard
---

# Recent Modified

```dataviewjs
await dv.list(dv.pages('').sort(f=>f.file.mtime.ts,"desc").limit(10).file.link)
```

# CS Study Notes

- [>] Lecture Notes

```dataviewjs
let data = []
for (let page of dv.pages('"Lecture Notes"')) {
	if (page.category == "inter_class") {
		let name = page.file.link;
		let description = page.description;
		data.push({name, description});
	} else {
		console.log(page.file.category);
	}
}
dv.list(data.map(it => [`${it.name}: ${it.description}`]));
```

---

- [>] Study Log
	- [[Study Log/android_study/aa_android_study|aa_android_study]]
	- [[Study Log/android_study/aa_android_study_outline|aa_android_study_outline]]
	- [[Study Log/java_study/aa_java_study|aa_java_study]]
	- [[Study Log/kotlin_study/aa_kotlin_study|aa_kotlin_study]]
	- [[Article/jdbc_study|jdbc_study]]
	- [[Study Log/linux|linux]]
	- [[Study Log/the_missing_semester|the_missing_semester]]
- [>] Knowledge
	- [[Knowledge/front_end_style|front_end_style]]
	- [[Knowledge/markdown|markdown]]
	- [[Knowledge/software_qa|software_qa]]
	- [[Knowledge/techiques|techiques]]