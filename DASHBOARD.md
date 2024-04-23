
# TODO

* by **Priority (only unchecked)**: [[resources/tasks_by_priority|tasks_by_priority]]
* by **<big>Progress</big>**: [[resources/tasks_by_progress|tasks_by_progress]]
* **<big>Finished</big>**: [[resources/tasks_finished|tasks_finished]]

- [ ] #TODO work diary 回滚 经常记录产出 工作日记同步 ➕ 2024-04-18 🔼 
- [ ] #TODO 组合优于继承，有时候你加一个方法，只能在接口里加，导致很多子类有很多空实现。 ➕ 2024-04-18 🔼 
- [ ] #TODO viewtreeobserver的scroll在首刷的时候会触发吗？ ➕ 2024-04-19 🔼 
- [ ] #TODO View.post do what? ➕ 2024-04-22 ⏫ 
- [ ] #TODO [从一次实际经历来说说IdleHandler的坑 - 掘金 (juejin.cn)](https://juejin.cn/post/6936440588635996173) ➕ 2024-04-24 ⏫ 

# Week progress

![[resources/every_week|every_week]]

# Recently Modified

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