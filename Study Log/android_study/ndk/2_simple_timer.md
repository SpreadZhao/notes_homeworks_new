---
title: 简单计时器
order: "2"
---
[The Invocation API](https://docs.oracle.com/javase/8/docs/technotes/guides/jni/spec/invocation.html)

# 1 改造

## 1.1 Fragment

简单做一个计时器。但是在这之前先改造一下主页，变成Fragment的形式。

```xml
<androidx.drawerlayout.widget.DrawerLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:id="@+id/drawer_main"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    tools:context=".MainActivity">

	<!-- 这是自己加的Toolbar。 -->
    <FrameLayout
        android:layout_width="match_parent"
        android:layout_height="match_parent">

        <com.google.android.material.appbar.MaterialToolbar
            android:layout_width="match_parent"
            android:layout_height="?attr/actionBarSize" />
    </FrameLayout>

	<!-- 用来装所有的Fragment -->
    <FrameLayout
        android:id="@+id/fragment_container"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        />

	<!-- DrawerLayout左侧的NavigationView -->
    <com.google.android.material.navigation.NavigationView
        android:id="@+id/main_nav"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_gravity="start"
        app:menu="@menu/nav_menu" />

</androidx.drawerlayout.widget.DrawerLayout>
```

这里面有几点需要注意。首先是这个NavigationView的menu，在`res/menu`目录下创建：

![[Study Log/android_study/ndk/resources/Pasted image 20240210223248.png]]

然后最重要的是这个NavigationView的位置：[NavigationView导航视图与DrawerLayout绘制布局_navigationview getmenu-CSDN博客](https://blog.csdn.net/m0_57150356/article/details/134332218)。DrawerLayout也是按照Z轴摆放子View的。所以如果NavigationView不是最后一个子View，那么就不会响应触摸事件。

切换Fragment的核心逻辑：

```kotlin
private fun switchToFragment(fg: Fragment) {
	val fm = supportFragmentManager
	fm.beginTransaction()
			.replace(R.id.fragment_container, fg)
			.commit()
}
```

给它一个Fragment就能切换。所以，我们每次选中一个item，就创建一个对应的Fragment就可以了：

```kotlin
private val navListener = OnNavigationItemSelectedListener { item ->
	drawer.closeDrawers()
	val newFragment = when (item.itemId) {
		R.id.menu_item_simple_class_name -> SimpleClassNameFragment()
		R.id.menu_item_simple_timer -> SimpleTimerFragment()
		else -> null
	}
	newFragment?.let { switchToFragment(it) }
	true
}
```

接下来，我们去关心每个Fragment中的逻辑就可以了。

## 1.2 Multiple Native Libs

怎么拆分成多个`.cpp`文件？做一个通用的.h：

![[Study Log/android_study/ndk/resources/Pasted image 20240210224114.png]]

然后，每个.cpp都依赖这个.h就好了。但是，在CMakeLists.txt里面需要配置上对应的.cpp文件：

```cmake
add_library(${CMAKE_PROJECT_NAME} SHARED
        # List C/C++ source files with relative paths to this CMakeLists.txt.
        simple_class_name.cpp
        simple_timer.cpp
        )
```

[java - C++ std::string to jstring with a fixed length - Stack Overflow](https://stackoverflow.com/questions/27303316/c-stdstring-to-jstring-with-a-fixed-length)