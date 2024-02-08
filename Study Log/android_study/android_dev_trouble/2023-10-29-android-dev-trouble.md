---
title: unrecognized Attribute name MODULE
date: 2023-10-29
---
# 2023-10-29

#date 2023-10-29

又是编译失败的问题：

java.lang.AssertionError: annotationType(): unrecognized Attribute name MODULE 

查了这篇文章：[android - How can I fix java.lang.AssertionError: annotationType(): unrecognized Attribute name MODULE? - Stack Overflow](https://stackoverflow.com/questions/69457372/how-can-i-fix-java-lang-assertionerror-annotationtype-unrecognized-attribute)

看来是安卓sdk30左右的版本，都要用jdk11才行了。