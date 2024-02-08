---
title: win11脚本
date: 2024-01-27
tags:
  - "#softwareqa/windows"
---
Windows11 最大劝退点就是这个右键菜单，复制粘贴都变成一点点的小图标，最气人的是点击底部的显示更多选项才能展示全部功能。让许多本来点一次就能完成的操作变成两次。其实使用一个小命令就能修改回win10版本的菜单。本期将分享四个简单的bat脚本，却能完美解决windows使用的四个痛点。

## 切换Windows10的右键菜单

管理员权限，打开cmd控制台，输入以下两行命令<br />切换到win10版右键菜单：

```shell
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
taskkill /f /im explorer.exe & start explorer.exe
```

恢复到win11版右键菜单：

```shell
reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f
taskkill /f /im explorer.exe & start explorer.exe
```

## 永久暂停Windows自动更新

众所周知，windows更新非常频繁，而且有时候会强制重启更新。设置里的暂停也最多暂停一个月。<br />下面这个脚本就可以永久暂停Windows更新。<br />管理员权限，打开cmd控制台，依次输入以下这行命令

```shell
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v FlightSettingsMaxPauseDays /t reg_dword /d 9999 /f
```

## 卸载小组件

Win11搜索框右侧的小组件，打开以后发现

![[Knowledge/resources/1.png]]

就是是纯纯的广告位，虽然可以在设置里面关闭这个按钮，但是依旧在后台占用着内存

![[Knowledge/resources/2.png]]

下面的命令就是永久卸载小组件<br />管理员权限，打开cmd控制台，依次输入以下这两行命令

```shell
winget uninstall MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy
taskkill /f /im explorer.exe & start explorer.exe
```

执行完即卸载的非常彻底，设置里得开关甚至都消失了。<br />重新安装小组件

```shell

winget install 9MSSGKG348SP

```

## 家庭版开启hyper-v

hyper-v是Windows自带的虚拟机平台，但是仅限专业版或者旗舰版用户开启。爬爬虾之前有一个视频完整介绍了hyper-v的用法。<br />如果你是Windows 10或者11的家庭版用户（右键我的电脑——属性，里面能看到Windows版本），想开启hyper-v功能，可以进行如下操作

1、新建一个文本文档，复制以下代码到文本文档中。

```powershell
pushd "%~dp0"
dir /b %SystemRoot%servicingPackages*Hyper-V*.mum >hv.txt
for /f %%i in ('findstr /i . hv.txt 2^>nul') do dism /online /norestart /add-package:"%SystemRoot%servicingPackages%%i"
del hv.txt
Dism /online /enable-feature /featurename:Microsoft-Hyper-V -All /LimitAccess /ALL
pause
```

2、将文本文档改名为"hv.bat"，需注意.bat是扩展名，如果看不到扩展名的话在文件夹窗口上方的查看-显示里勾选文件扩展名3、右键单击hv.bat，选择**以管理员身份**运行。4、你会看到命令行在安装Hyper-V，安装完成后会有以下显示。

![[Knowledge/resources/3.png]]

5、完成后重启电脑。