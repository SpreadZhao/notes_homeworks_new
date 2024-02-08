当时想把仓库从typora迁移到obsidian，但是obsidian居然不支持这样的html语法：

```html
<img src="xxx" alt="yyy"/>
```

所以图片在obsidian里根本显示不了。所以我只能把图片改成下面的形式：

```markdown
![img](xxx)
```

具体的思路就是，打开一个文件，然后逐行扫描。对于每一行，判断它是不是以`<img src=`开头，如果是的话，就把其中的文件名提取出来，然后构建一个新字符串`![img](xxx)`，并把xxx替换成提取出来的文件名，最终把这一行写到一个新文件里面去。直接上完整代码！没啥含金量。。。

```java
public class Main {
	
	static String testFileName = "E:/temp/test.txt";
	static String F1 = "E:/temp/notes/Computer Structure/cs.md";
	static String F2 = "E:/temp/notes/Compile/cp.md";
	static String F3 = "E:/temp/notes/Database/db.md";
	static String F4 = "E:/temp/notes/Knowledge/git.md";
	static String F5 = "E:/temp/notes/Networking/dn.md";
	static String F6 = "E:/temp/notes/Operating System/os.md";
	
	public static void main(String[] args) {
		File file = new File(F6);
		File newFile = new File("E:/temp/result.md");
		if(file.exists()) {
			System.out.println("ok!");
		}else {
			System.out.println("fail!");
		}
		try {
			BufferedReader br = new BufferedReader(new FileReader(file));
			BufferedWriter bw = new BufferedWriter(new FileWriter(newFile, true));
			String line;
			String graph_name;
			String newLine;
			while((line = br.readLine()) != null) {
				System.out.println(line);
				if (line.contains("<img src=")){
					System.out.println("test contains!");
					graph_name = line.substring(line.indexOf("\"") + 1, line.indexOf("\"", line.indexOf("\"") + 1));
					System.out.println("test graph_name: " + "[" + graph_name + "]");
					newLine = "![img](" + graph_name + ")";
					System.out.println("test newLine: " + newLine);
					bw.write(newLine + "\r\n");
				}else{
					bw.write(line + "\r\n");
				}
			}
			br.close();
			bw.close();
		} catch (IOException e) {
			e.printStackTrace();// TODO: handle exception
		} finally {

		}
	}
}
```