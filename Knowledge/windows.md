# 1. 备份/恢复驱动

备份：cmd管理员

```shell
DISM /Online /Export-Driver /Destination:"D:\DriverBackup"
```

如果是win10 1607以上的版本，也可以用：

```shell
pnputil /export-driver * D:\DriverBackup
```

用powershell的话，还有别的招：

```shell
Export-WindowsDriver -Online -Destination D:\DriverBackup
```

恢复在设备管理器那里就能恢复了，自动搜索。