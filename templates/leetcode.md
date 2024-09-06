<%*
const num = await tp.system.prompt("num");
const title = await tp.system.prompt("title");
const link = await tp.system.prompt("link");
const difficulty = await tp.system.prompt("difficulty");
await tp.file.rename(num + " " + title);
-%>---
num: "<% num %>"
title: "<% title %>"
link: "<% link %>"
tags:
  - leetcode/difficulty/<% difficulty %>
---

# 题解



# 遗漏的case

