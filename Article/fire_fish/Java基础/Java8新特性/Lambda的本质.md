
结论：
1、Lambda其实是一个语法糖
2、本质就是一个特别的类（这个类也有方法、字段等）
3、我们传递的参数其实就是保存在了特别的类的字段中，随着lambda的传递参数也传递了。

举例：
```java
public class Test {
	// 定义一个Lambda函数，接受2个参数，返回DocumentFilter
	@FunctionalInterface
	private interface DocumentFilterFactory {
		DocumentFilter getDocumentFilter(String arg1, String arg2);
	}
}
```
当我们调用getDocumentFilter方法传递参数arg1=aaa,arg2=bbb时，参数就已经被保存到了返回的DocumentFilter对象中
![](/Users/apple/Documents/Work/aliyun-oss/dev-images/2023-01-19-14-16-02-image.png)
这样当后续调用lambda方法时就能拿到arg1和arg2的值
```java
public class Test {
	private DocumentFilter getPositiveProfileFilter(String arg1, String arg2) {
		return (Document document) -> {
			System.out.println(arg1);
			System.out.println(arg2);
			return true;
		};
	}
}
```
下面是完整的测试代码：
```java
public class Test {

	// ---------------------------定义接口-------------------------------------
	@FunctionalInterface
	private interface DocumentFilterFactory {
		DocumentFilter getDocumentFilter(String arg1, String arg2);
	}
	@FunctionalInterface
	private interface DocumentFilter {
		boolean match(Document document);
	}
	class Document {
	}

	// ------------------------lambda表达式----------------------------
	private DocumentFilter getPositiveProfileFilter(String arg1, String arg2) {
		return (Document document) -> {
			System.out.println(arg1);
			System.out.println(arg2);
			return true;
		};
	}
	
	// --------------------------------测试----------------------------
	public static void main(String[] args) {
		Test test = new Test();
		test.testAdd();
	}
	void testAdd(){
		add(this::getPositiveProfileFilter);
	}
	private void add(DocumentFilterFactory getPositiveProfileFilter) {
		DocumentFilter documentFilter = getPositiveProfileFilter.getDocumentFilter("aaa", "bbb");
		boolean match = documentFilter.match(new Document());
	}
}
```