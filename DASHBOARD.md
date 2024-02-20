---
cssclass: dashboard
---

# TODO

* by **<big>Priority</big>**: [[resources/tasks_by_priority|tasks_by_priority]]
* by **<big>Progress</big>**: [[resources/tasks_by_progress|tasks_by_progress]]
* **<big>Finished</big>**: [[resources/tasks_finished|tasks_finished]]

# Week progress

![[resources/every_week|every_week]]

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
	}
}
dv.list(data.map(it => [`${it.name}: ${it.description}`]));
```

---

- [>] Study Log
	- [[Study Log/android_study/aa_android_study|aa_android_study]]
	- [[Study Log/android_study/aa_android_study_outline|aa_android_study_outline]]
	- [[Study Log/java_kotlin_study/aa_java_study|aa_java_study]]
	- [[Study Log/java_kotlin_study/aa_kotlin_study|aa_kotlin_study]]
	- [[Article/jdbc_study|jdbc_study]]
	- [[Study Log/linux|linux]]
	- [[Study Log/the_missing_semester|the_missing_semester]]
- [>] Knowledge
	- [[Knowledge/front_end_style|front_end_style]]
	- [[Knowledge/markdown|markdown]]
	- [[Knowledge/software_qa|software_qa]]
	- [[Knowledge/techniques|techniques]]
	- [[Knowledge/obsidian_tutorial/example|example]]