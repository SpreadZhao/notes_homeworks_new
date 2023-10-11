# 1. Apache服务器配置

## 1.1 修改配置文件

该文件位于Apache目录下的`conf/httpd.conf`。打开并编辑这个文件：

```
Define SRVROOT "D:/greenprogram/Apache24"
ServerRoot "${SRVROOT}"
Listen 80
ServerName localhost:80
```

## 1.2 安装Apache服务

使用管理员权限打开终端，并输入如下命令：

```shell
httpd -k install -n "Apache24"
```

其中，Apache24是我们可以自定义的服务名。

## 1.3 启动Apache服务

在此电脑的服务中打开，或者直接`net start Apache24`都可以打开Apache服务。另外，我们也可以通过`/bin/ApacheMonitor.exe`来检测Apache服务。图形化界面很简洁明了。

## 1.4 测试服务

当在浏览器中输入`localhost:80`的时候，显示`It works!`就代表启动成功了。

# 2. Git Usage

## 2.1 已经推送过的文件，但是本地发现他不用提交(比如clion的cmake-build-debug或者后来被加入到.gitignore的文件)

* 可使用如下代码来操作：

  ```git
  git rm --cached <files>
  ```

* 如果删除的文件不在当前目录下，而在子目录下，需要递归操作：

  ```git
  git rm -r --cached <d1/d2/files>
  ```

> 如果要删除一个目录，比如仓库根目录下的`out`目录，那就是：`git rm -r --cached out/`。注意`out/`前面不要加`/`。
  
* 如果不想直接删，只想列出删了什么，就加一个-n

  ```git
  git rm -r -n --cached <d1/d2/files>
  ```

* 然后还需要提交这次修改

  ```git
  git commit -m "deleted files"
  ```

* 最后push

  ```git
  git push
  ```

另外如果不想再继续提交，可以在删除这个文件之后添加到`.gitignore`。比如就是本仓库中的`.obsidian`和`.trash`文件夹在云端删除后可以新建`.gitignore`并这样填写：

```git
.obsidian/
.trash/
```

然后再正常进行提交就不会再提交已经删掉的文件了。

---

## 2.2 本地的文件删掉了，我在远程仓库也不要了，怎么把这个删除后的状态同步到远程仓库

* 如果目录中包含中文，使用如下命令配置

  ```git
  git config --global core.quotepath false
  ```

* 删除了本地文件，查看状态

  ```git
  git status
  ```

* 这时候会看到这样的情况

![[Knowledge/resources/gitst.png]]

* 然后，提交这次改动

  ```git
  git add -A
  ```

* 然后正常commit+push即可删除，这里-A表示删除mode

---

## 2.3 手动添加Git Bash Here到右键菜单

* 打开`regedit`

* 定位到`Computer\HKEY_CLASSES_ROOT\Directory\Background`

* 如图添加键值对

![[Knowledge/resources/gitbash.png]]

* ~~然后再添加图标和程序目录就好了~~

![[Knowledge/resources/gitbash2.png]]

* 上面这么做是错的！`command`应该建在子项中，参考`cmd`是咋做的

![[Knowledge/resources/gitbash3.png]]

  不过`icon`确实是加在那里

---

## 2.4 不clone仓库而添加远程仓库

* `git init`在当前目录下生成`.git`文件夹

* 在那边建好仓库，复制地址

* `git remote add origin <地址>`

  origin就是仓库的名字，可以随便起，只是给本地一个提示罢了，origin是clone下来默认的名字

* 如果改地址，那就`git remote set-url <仓库名> <新地址>`

---

## 2.5 gitee和github同步仓库，一次提交两次更新

* 首先有一个仓库，然后在另一个上面先import

* 然后在本地的`.git`里加上另一个的url

  ![[Knowledge/resources/newurl.png]]

* 这样在`remote -v`的时候就能看到多个地址

  ![[Knowledge/resources/remote.png]]

  > 我们能看到github的只支持push操作不支持pull操作

* 然后在修改提交过后就会有两次提交记录在shell中了

![[Knowledge/resources/push.png]]

# 3. Obsidian

## 3.1 pdf导出

安装minimal主题之后，代码段为黑色，并且表格非常难看，之后找到了这篇文章：

[PDF and print style reset with code syntax highlighting - Share & showcase - Obsidian Forum](https://forum.obsidian.md/t/pdf-and-print-style-reset-with-code-syntax-highlighting/31761)

因此新建如下代码片段放到`.obsidian/snippets`目录下，并在obsidian中应用即可：

```css
@media print {
  h1, h2, h3, h4, h5, h6, p, ul, li, ol {
    font-size: initial;
    font-weight: initial;
    font-family: initial;
    color: initial !important;
    background: none !important;
    outline: none !important;
    border: none !important;
    text-shadow: none !important;
  }

  th, td {
    font-size: initial;
    font-weight: initial;
    font-family: initial;
    color: initial !important;
    background: none !important;
    outline: none !important;
    text-shadow: none !important;
    border: 1px solid darkgray !important;
  }

  a {
    font-size: initial;
    font-weight: initial;
    font-family: initial;
    color: blue !important;
    text-decoration: underline !important;
    background: none !important;
    outline: none !important;
    border: none !important;
    text-shadow: none !important;
  }

  a[aria-label]::after {
    display: inline !important;
    content: " (" attr(aria-label) ")" !important;
    color: #666 !important;
    vertical-align: super !important;
    font-size: 70% !important;
    text-decoration: none !important;
  }

  pre,
  code span,
  code {
    color: black !important;
    background-color: white !important;
  }

  code {
    border: 1px solid darkgray !important;
    padding: 0 0.2em !important;
    line-height: initial !important;
    border-radius: 0 !important;
  }

  pre {
    border: 1px solid darkgray !important;
    margin: 1em 0px !important;
    padding: 0.5em !important;
    border-radius: 0 !important;
  }

  pre > code {
    font-size: 12px !important;
    border: none !important;
    border-radius: 0 !important;
    padding: 0 !important;
  }

  pre > code .token.em { font-style: italic !important; }
  pre > code .token.link { text-decoration: underline !important; }
  pre > code .token.strikethrough { text-decoration: line-through !important; }
  pre > code .token { color: #000 !important; }
  pre > code .token.keyword { color: #708 !important; }
  pre > code .token.number { color: #164 !important; }
  pre > code .token.variable {  }
  pre > code .token.punctuation {  }
  pre > code .token.property {  }
  pre > code .token.operator {  }
  pre > code .token.def { color: #00f !important; }
  pre > code .token.atom { color: #219 !important; }
  pre > code .token.variable-2 { color: #05a !important; }
  pre > code .token.type { color: #085 !important; }
  pre > code .token.comment { color: #a50 !important; }
  pre > code .token.string { color: #a11 !important; }
  pre > code .token.string-2 { color: #f50 !important; }
  pre > code .token.meta { color: #555 !important; }
  pre > code .token.qualifier { color: #555 !important; }
  pre > code .token.builtin { color: #30a !important; }
  pre > code .token.bracket { color: #997 !important; }
  pre > code .token.tag { color: #170 !important; }
  pre > code .token.attribute { color: #00c !important; }
  pre > code .token.hr { color: #999 !important; }
  pre > code .token.link { color: #00c !important; }
}
```

#TODO  learn dataview

- [x] 学习Dataview插件的使用

## 3.2 成块引用

比如有下面的东西：

> asdfasdg
> 
> asdgasgda
> 
> asdgasdg

我想一下把这三行的引用都删掉。以前版本是自带快捷键的：`ctrl + shift + .`

但是现在不行了，所以我在设置里找来找去，最后还真被我找到了：

![[Knowledge/resources/Pasted image 20221223140048.png]]

## 3.3 DataView

### 3.3.1  Implicit Fields

DataView has some default metadata, you can see that in this website:

[Metadata on Pages - Dataview (blacksmithgu.github.io)](https://blacksmithgu.github.io/obsidian-dataview/annotation/metadata-pages/)

### 3.3.2 Dataview js

List all places where I used dataview js to query the repository.

```query
content: "```dataviewjs"
```

## 3.4 Center Images

You need to create your own css file to realize this. See this for detail:

[Centering Images in Reading Mode : r/ObsidianMD (reddit.com)](https://www.reddit.com/r/ObsidianMD/comments/v1fs0f/centering_images_in_reading_mode/)

```css
img[alt*="center"] {
    display: block;
    margin-left: auto;
    margin-right: auto;
}
```

And below is how to use it:

```
![[haha.png|center|200x300]]
```

## 3.5 Alternative Checkboxes

Work with Minimal:

![[Knowledge/resources/Pasted image 20230502155741.png]]

## 3.6 Query

[Search - Obsidian Help](https://help.obsidian.md/Plugins/Search#Embed+search+results+in+a+note)

[Regular expressions - JavaScript | MDN (mozilla.org)](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions)

## 3.7 Minimal Image Filters

![[Knowledge/resources/Pasted image 20230525165603.png]]

## 3.8 File Embed

[嵌入文件 - Obsidian 中文帮助 - Obsidian Publish](https://publish.obsidian.md/help-zh/%E4%BD%BF%E7%94%A8%E6%8C%87%E5%8D%97/%E5%B5%8C%E5%85%A5%E6%96%87%E4%BB%B6)

## 3.9 Code block wrap

Disable word wrap for code block like this:

```java
public static void aVeryVeryLongAndLongAndLongAndLongAndLongAndLongAndLongAndLongAndLongAndLongFunction() {
}
```

https://forum.obsidian.md/t/live-preview-better-treatment-of-code-blocks-code-wrap-horizontal-scroll-and-smart-indent/33718/32

```css
/*un-wrap code*/
.HyperMD-codeblock {
    white-space: nowrap;
}

/*scroll codeblock in read mode*/
.markdown-reading-view code[class*="language-"] {
    overflow-x: scroll;
    white-space: pre;
    padding: 15px 0px;
}
```

## 3.10 Hide answers using Callout

Hide the answer of a question:

https://www.reddit.com/r/ObsidianMD/comments/onydkq/easiest_way_to_hide_text_spoilersanswers_to/

https://help.obsidian.md/Editing+and+formatting/Callouts

# 4. MySQL

## 4.1 MySQL的配置

下载MySQL的绿色版。然后解压缩，在里面会发现下面的结构：

![[Knowledge/resources/sql1.png]]

* 注：`my.ini`本来是没有的。

然后新建`my.ini`，并写入如下配置：

```yaml
[mysqld]
# 设置3306端口
port=3306

# 设置安装目录
basedir=D:\greenprogram\mysql

# 设置数据存放目录
datadir=D:\greenprogram\mysql\data

# 允许最大连接数
max_connections=200

# 允许链接失败的次数
max_connect_errors=10000

# 字符集
character-set-server=utf8mb4

# 默认存储引擎
default-storage-engine=INNODB

[mysql]
# 客户端默认字符集
default-character-set=utf8mb4

[client]
# 设置mysql客户端连接服务端时默认使用的端口和默认字符集
port=3306
default-character-set=utf8mb4
```

然后开始初始化MySQL。在`bin/`目录下使用`mysqld`执行初始化命令(**管理员**)：

```shell
mysqld --initialize --console
```

这是初始化MySQL，并将结果打印在控制台上。此时会出现一个**初始密码**，需要记住。

然后还要注册MySQL服务并启动它。

```shell
mysqld --install <serviceName>
net start <serviceName>
```

最后就可以用初始化密码登录了。

```shell
mysql -h localhost -u root -p
```

然后还要修改密码：

```shell
mysql> alter user 'root'@'localhost' identified with mysql_native_password by 'New Password';
```

退出：

```shell
quit
```

## 4.2 MySQL恢复备份

MySQL的逻辑备份是`.sql`文件，使用如下命令可以恢复。

首先进入mysql后，创建要恢复的数据库文件，比如`store`。然后在store下使用如下命令：

```sql
source <filename>
```

这样就能够恢复了。当然，还有其他的方式，这里贴出一个网址：

[How to Restore MySQL Database from Backup (Different ways) (devart.com)](https://blog.devart.com/how-to-restore-mysql-database-from-backup.html#use_mysql_command_to_restore_database)

# 5. Windows

## 5.1 备份/恢复驱动

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

## 5.2 Hyper-V和VM-Ware共存

因为WSA需要依靠Hyper-V启动，所以才会这样做。

它俩其实本来就能共存，只需要让VM-Ware里虚拟机的设置里的Processor那里的第一个勾，就是Intel什么什么的勾掉，这样就是以HyperV模式在运行，这样就可以启动虚拟机，并且可以同时运行WSA了。另外附上一个网址：

[www.reddit.com](https://www.reddit.com/r/vmware/comments/swjp4t/running_vmware_workstation_on_a_hyperv_enabled/)

## 5.3 安装系统的时候找不到Storage Driver

视频：[(188) How To Fix Lenovo Couldn't Find Storage Driver Load Error in Windows Install - YouTube](https://www.youtube.com/watch?v=41C71-dvv-4)

原因就是Intel VMD技术会将**固态介质**隐藏，因此我们加载不了分区。在BIOS中将Intel VMD功能关掉，之后就能够正常找到分区了。

## 5.4 恢复右键菜单

[有没有什么办法可以让win11右键默认显示更多选项？ - 知乎 (zhihu.com)](https://www.zhihu.com/question/480356710)

管理员运行：

```shell
reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve
```

恢复：

```shell
reg.exe delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /va /f
```

# 6. Linux

## 6.1 Ubuntu调整字体大小

安装`gnome-tweaks`工具即可，之后便会出现Tweaks工具。在里面就能设置字体大小了。

# 7. Idea

## 7.1 修改maven仓库位置

![[Knowledge/resources/Pasted image 20221115105545.png]]

Bundled代表idea自带的maven，而settings file默认就是自带maven的配置。所以我们需要自己将仓库迁移到别的位置，这里我迁移到了F盘。

# 8. WSL

## 8.1 添加环境变量

WSL中默认会添加windows的环境变量，在`/etc/`目录下新建`wsl.conf`文件，写上如下配置：

```properties
[interop]
appendWindowsPath=false
```

然后重启wsl，windows的环境变量就没了。另外，如果我们想自己添加环境变量，可以这样。修改`~`目录下的`.profile`文件，在最后追加：

```shell
export PATH=$PATH:/usr/lib/jvm/jdk-17./bin
```

之后source一下，这个`/usr/lib/jvm/jdk-17./bin`目录就添加到环境变量中了。**实际上，在这个文件的开头就能发现，每次WSL启动的时候都会默认执行一下这个脚本，所以不用担心**。

# 9. Source Insight

## 9.1 更改字体

[(45条消息) Source Insight 4.0 字体设置_sourceinsight4字体_wowocpp的博客-CSDN博客](https://blog.csdn.net/wowocpp/article/details/87274027)