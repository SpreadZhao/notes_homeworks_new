---
title: What is fucking CAS ?
date: 2024-05-14
tags: 
mtrace: 
  - 2024-05-14
---

# What is fucking CAS ?

在[[Study Log/java_kotlin_study/concurrency_art/5_2_aqs#^ab3289|5_2_aqs]]中，提到了这个文章：[【锁思想】自旋 or CAS 它俩真的一样吗？一文搞懂 - 掘金 (juejin.cn)](https://juejin.cn/post/7252889628376842297)进去看了一下，发现了这个评论：

![[Study Log/java_kotlin_study/java_kotlin_study_diary/resources/Pasted image 20240514211045.png]]

在我的印象中，volatile的那个lock指令才是负责锁总线和缓存的。不过还可以看[[Study Log/java_kotlin_study/concurrency_art/resources/why_cas_has_volatile_semantics|why_cas_has_volatile_semantics]]。这里我们直接深入到嵌入式汇编去看，发现确实CAS也有lock指令，所以这人说的没问题。

- [ ] #TODO tasktodo1715692367305 彻底说一说CAS到底是什么，有什么优缺点，什么时候用，比起其他的有什么问题。 ➕ 2024-05-14 🔼 