---
mtrace:
  - 2023-07-15
tags:
  - question/coding/android
  - question/coding/practice
---
# LiveData的setValue不能在子线程中调用

就像不能在子线程更新UI一样，因为LiveData本身最大的价值就是在UI上展示，所以给LiveData设置值的时候，也是不能在子线程的。