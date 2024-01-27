---
title: 备份windows驱动
date: 2024-01-27
tags:
  - windows
---

# 备份Windows驱动

#date 2024-01-27

[Backup and Restore Device Drivers in Windows 11 Tutorial | Windows 11 Forum (elevenforum.com)](https://www.elevenforum.com/t/backup-and-restore-device-drivers-in-windows-11.8678/#Five)

使用pnputil来进行驱动的备份和恢复。

```shell
pnputil /export-driver * "D:\drivers"
```

上面的命令将所有驱动备份到`D:\drivers`目录中。将他们拷出来，重做系统之后，再拷回去，然后执行：

```shell
pnputil /add-driver "D:\drivers\*.inf" /subdirs /install /reboot
```

之后驱动就都装好了。重启电脑即可。