### 1. 概述

本文，我们来分享 MyBatis 的脚本模块，对应 `scripting` 包。如下图所示：
> ![](/Users/apple/Documents/Work/aliyun-oss/dev-images/mybatis的script模块结构图.png)

* 总结来说，scripting 模块，最大的作用，就是实现了 MyBatis 的动态 SQL 语句的功能。
  关于这个功能，对应文档为 <a href="http://www.mybatis.org/mybatis-3/zh/dynamic-sql.html">《MyBatis 文档 —— 动态 SQL》 </a>。

本文涉及的类如下图所示：
![](/Users/apple/Documents/Work/aliyun-oss/dev-images/script模块的类图.png)

对类图进行下分类：

* LanguageDriver类 --- [语言驱动，用于创建SQL源码的]
* SqlSource类 --- [代表了SQL源码]
* SqlNode类 --- [代表了SQL节点，如静态sql片段、动态sql标签节点等]
* NodeHandler类 --- [动态节点的处理器]
* 基于 OGNL 表达式 --- [对ognl又做了一些封装，如 OgnlCache、OgnlClassResolver]。Mybatis 的属性值访问方式是通过ognl表达式来完成的

下面，我们来逐个来瞅瞅。

### 2. LanguageDriver

`org.apache.ibatis.scripting.LanguageDriver` ，语言驱动接口。代码如下：

```java
// LanguageDriver.java

public interface LanguageDriver {

	//创建参数处理器
	ParameterHandler createParameterHandler(MappedStatement mappedStatement, Object parameterObject, BoundSql boundSql);

	//创建SQL源码(mapper xml方式)
	SqlSource createSqlSource(Configuration configuration, XNode script, Class<?> parameterType);

	//创建SQL源码(注解方式)
	SqlSource createSqlSource(Configuration configuration, String script, Class<?> parameterType);
}
```

#### 2.1 XMLLanguageDriver

<mark>默认的LanguageDriver接口实现类</mark>

`org.apache.ibatis.scripting.xmltags.XMLLanguageDriver` ，实现 LanguageDriver 接口，XML 语言驱动实现类。

##### 2.1.1 createParameterHandler

`#createParameterHandler(MappedStatement mappedStatement, Object parameterObject, BoundSql boundSql)` 方法，代码如下：

```java
// XMLLanguageDriver.java

@Override
public ParameterHandler createParameterHandler(MappedStatement mappedStatement,Object parameterObject,BoundSql boundSql){
		// 创建 DefaultParameterHandler 对象
		return new DefaultParameterHandler(mappedStatement,parameterObject,boundSql);
		}
```

* 创建的是 DefaultParameterHandler 对象。详细解析，见 `《精尽 MyBatis 源码分析 —— SQL 初始化（下）之 SqlSource》` 的 `「7.1 DefaultParameterHandler」`
  。

##### 2.1.2 createSqlSource

`SqlSource` 接口表示的就是SQL源码，只会在初始化的时候解析一次就可以；
而动态sql是根据解析好的 `SqlSource` 每次执行生成一个 `DynamicContext` 并最终生成发送给数据库的SQL。

`#createSqlSource(Configuration configuration, XNode script, Class<?> parameterType)` 方法，代码如下：

```java
// XMLLanguageDriver.java

@Override
public SqlSource createSqlSource(Configuration configuration,XNode script,Class<?> parameterType){
		// 创建 XMLScriptBuilder 对象，执行解析
		XMLScriptBuilder builder=new XMLScriptBuilder(configuration,script,parameterType);
		return builder.parseScriptNode();
		}
```

* 创建 XMLScriptBuilder 对象，执行 `XMLScriptBuilder#parseScriptNode()` 方法，执行解析。详细解析，见 `「3. XMLScriptBuilder」` 。

#### 2.2 RawLanguageDriver

#### 2.3 LanguageDriverRegistry

##### 2.3.1 初始化

在 Configuration 的构造方法中，会进行初始化。代码如下：

```java
// Configuration.java

/**
 * LanguageDriverRegistry 对象
 */
protected final LanguageDriverRegistry languageRegistry=new LanguageDriverRegistry();

public Configuration(){
		// ... 省略其它代码

		// 注册到 languageRegistry 中
		languageRegistry.setDefaultDriverClass(XMLLanguageDriver.class);
		languageRegistry.register(RawLanguageDriver.class);
		}
```

* 默认情况下，使用 `XMLLanguageDriver` 类。
* 大多数情况下，我们不会去设置使用的 `LanguageDriver` 类，而是使用 `XMLLanguageDriver` 类。
  从 `#getLanguageDriver(Class<? extends LanguageDriver> langClass)` 方法，可知。代码如下：

```java
// MapperBuilderAssistant.java

public LanguageDriver getLanguageDriver(Class<?extends LanguageDriver> langClass){
		// 获得 langClass 类
		if(langClass!=null){
		configuration.getLanguageRegistry().register(langClass);
		}else{
		// 如果为空，则使用默认类。获取默认的 defaultDriverClass
		langClass=configuration.getLanguageRegistry().getDefaultDriverClass();
		}
		// 获得 LanguageDriver 对象
		return configuration.getLanguageRegistry().getDriver(langClass);
		}
```

### 3. XMLScriptBuilder

`org.apache.ibatis.scripting.xmltags.XMLScriptBuilder` ，继承 `BaseBuilder` 抽象类，
XML 动态语句( SQL )构建器，负责将 SQL 解析成 SqlSource 对象。

#### 3.1 构造方法

```java
public class XMLScriptBuilder extends BaseBuilder {
// XMLScriptBuilder.java

	/**
	 * 当前 SQL 的 XNode 对象。如：insert、update
	 */
	private final XNode context;
	/**
	 * 是否为动态 SQL
	 */
	private boolean isDynamic;
	/**
	 * SQL 参数类型
	 */
	private final Class<?> parameterType;
	/**
	 * NodeNodeHandler 的映射. 9种mybatis动态sql标签处理器映射
	 */
	private final Map<String, NodeHandler> nodeHandlerMap = new HashMap<>();

	public XMLScriptBuilder(Configuration configuration, XNode context, Class<?> parameterType) {
		super(configuration);
		this.context = context;
		this.parameterType = parameterType;
	}
}
```

* 解析 insert、update、delete、select 标签时，会触发 SQL解析，最终会被解析为 SqlSource，触发位置如下：

```java
//解析成SqlSource，一般是DynamicSqlSource【动态sql】
SqlSource sqlSource=langDriver.createSqlSource(configuration,context,parameterTypeClass);
```

#### 3.2 parseScriptNode

`#parseScriptNode()` 方法，负责将 `SQL` 解析成 `SqlSource` 对象。代码如下：

```java
// XMLScriptBuilder.class
public class XMLScriptBuilder extends BaseBuilder {
	public SqlSource parseScriptNode() {

		// <1> 解析 SQL
		List<SqlNode> contents = parseDynamicTags(context);
		
		MixedSqlNode rootSqlNode = new MixedSqlNode(contents);

		// <2> 创建 SqlSource 对象
		SqlSource sqlSource = null;
		if (isDynamic) {
			sqlSource = new DynamicSqlSource(configuration, rootSqlNode);
		} else {
			sqlSource = new RawSqlSource(configuration, rootSqlNode, parameterType);
		}
		return sqlSource;
	}
}
```

* `<1>` 方法，调用 `#parseDynamicTags(XNode node)` 方法，解析 SQL 成 MixedSqlNode 对象。详细解析，见 `「3.3 parseDynamicTags」` 。
* `<2>` 方法，根据是否是动态 SQL ，创建对应的 DynamicSqlSource 或 RawSqlSource 对象。

#### 3.3 parseDynamicTags

解析动态节点，如果是动态标签就用对应的handler处理成对应的节点，如果是静态SQL文本就用StaticTextSqlNode节点，最后返回所有节点的集合。

```java
// XMLScriptBuilder.class
public class XMLScriptBuilder extends BaseBuilder {
	
	List<SqlNode> parseDynamicTags(XNode node) {
		// <1> 创建 SqlNode 数组
		List<SqlNode> contents = new ArrayList<SqlNode>();

		// <2> 遍历 SQL 节点的所有子节点
		NodeList children = node.getNode().getChildNodes();
		for (int i = 0; i < children.getLength(); i++) {
			XNode child = node.newXNode(children.item(i));

			// <2.1> 如果类型是 Node.CDATA_SECTION_NODE 或者 Node.TEXT_NODE 时
			// 如果是纯文本，纯文本包含了${}内容则也是动态SQL，因为${}可以改变sql的内容而#{}是参数占位符不改变sql的内容
			if (child.getNode().getNodeType() == Node.CDATA_SECTION_NODE || child.getNode().getNodeType() == Node.TEXT_NODE) {
				// <2.1.1> 获得内容
				String data = child.getStringBody("");
				// <2.1.2> 创建 TextSqlNode 对象
				TextSqlNode textSqlNode = new TextSqlNode(data);
				// <2.1.2.1> 如果是动态的 TextSqlNode 对象【如：带有${}的也是动态sql】
				if (textSqlNode.isDynamic()) {
					contents.add(textSqlNode);
					isDynamic = true;
					// <2.1.2.2> 如果是非动态的 TextSqlNode 对象
				} else {
					contents.add(new StaticTextSqlNode(data));
				}

				// <2.2> 如果类型是 Node.ELEMENT_NODE
				// 如果是元素节点，则判断它是不是mybatis的9种动态SQL标签，并返回标签的处理器
			} else if (child.getNode().getNodeType() == Node.ELEMENT_NODE) { // issue #628
				// <2.2.1> 根据子节点的标签，获得对应的 NodeHandler 对象
				String nodeName = child.getNode().getNodeName();
				NodeHandler handler = nodeHandlers(nodeName);
				// 获得不到，说明是未知的标签，抛出 BuilderException 异常
				if (handler == null) {
					throw new BuilderException("Unknown element <" + nodeName + "> in SQL statement.");
				}
				// <2.2.2> 执行 NodeHandler 处理
				handler.handleNode(child, contents);
				isDynamic = true;
			}
		}
		// <3> 创建 MixedSqlNode 对象
		return contents;
	}
}
```

* `<1>` 处，创建 SqlNode 数组。
* `<2>` 处，遍历 SQL 节点的所有子节点，处理每个子节点成对应的 SqlNode 对象，添加到数组中
    * `<2.1>` 处，如果节点类型是 `Node.CDATA_SECTION_NODE` 或者 `Node.TEXT_NODE` 时。
        * `<2.1.1>` 处， 获得节点的内容。
        * `<2.1.2>` 处，创建 TextSqlNode 对象。
            * `<2.1.2.1>` 处，如果是动态的 TextSqlNode 对象，则添加到 `contents` 中，并标记为动态 SQL 。例如：<mark>id = ${id}</mark>
            * `<2.1.2.2>` 处，如果非动态的 TextSqlNode 对象，则创建 StaticTextSqlNode 对象，并添加到 `contents` 中。例如：`SELECT * FROM subject`
    * `<2.2>` 处，如果节点类型是 `Node.ELEMENT_NODE`
      时。例如：`<where> <choose> <when test="${id != null}"> id = ${id} </when> </choose> </where>`
        * `<2.2.1>` 处，根据子节点的标签，获得对应的 NodeHandler 对象。
        * `<2.2.2>` 处，执行 NodeHandler 处理。
* `<3>` 处，将 `contents` 数组，封装成 MixedSqlNode 对象
* 关于这块逻辑，可以自己多多调试下。

#### 4. NodeHandler

9种标签和它们的处理器，以及被解析成为的节点如下表所示：

特殊的：

1. 文本节点均被解析为 `StaticTextSqlNode`
2. 只有 otherwise 标签的解析被解析为 `MixedSqlNode`，bind节点被解析为 `VarDeclSqlNode`，其他节点均带有标签信息。

解析过程：就是把标签信息封装成各种`SqlNode`节点，把所有`SqlNode`的节点列表返回。

| 标签        | 处理器类             | 解析成为的节点           |
|-----------|------------------|-------------------|
| trim      | TrimHandler      | TrimSqlNode       |
| where     | WhereHandler     | WhereSqlNode      |
| set       | SetHandler       | SetSqlNode        |
|           |                  |                   |
| choose    | ChooseHandler    | ChooseSqlNode     |
| when      | IfHandler        | IfSqlNode         |
| otherwise | OtherwiseHandler | MixedSqlNode      |
|           |                  |                   |
| foreach   | ForEachHandler   | ForEachSqlNode    |
| if        | IfHandler        | IfSqlNode         |
| bind      | BindHandler      | VarDeclSqlNode    |
|           |                  |                   |
| ${}       |                  | TextSqlNode       |
| 文本        | 无                | StaticTextSqlNode |

NodeHandler ，在 XMLScriptBuilder 类中，Node 处理器接口。代码如下:

```java
// XMLScriptBuilder.java
private interface NodeHandler {

	/**
	 * 处理 Node
	 *
	 * @param nodeToHandle 要处理的 XNode 节点
	 * @param targetContents 目标的 SqlNode 数组。实际上，被处理的 XNode 节点会创建成对应的 SqlNode 对象，添加到 targetContents 中
	 */
	void handleNode(XNode nodeToHandle, List<SqlNode> targetContents);

}
```

##### 4.1 BindHandler

BindHandler ，实现 NodeHandler 接口，`<bind />` 标签的处理器。代码如下：

```java
// XMLScriptBuilder.java

private class BindHandler implements NodeHandler {

	public BindHandler() {
		// Prevent Synthetic Access
	}

	@Override
	public void handleNode(XNode nodeToHandle, List<SqlNode> targetContents) {
		// 解析 name、value 属性
		final String name = nodeToHandle.getStringAttribute("name");
		final String expression = nodeToHandle.getStringAttribute("value");
		// 创建 VarDeclSqlNode 对象
		final VarDeclSqlNode node = new VarDeclSqlNode(name, expression);
		// 添加到 targetContents 中
		targetContents.add(node);
	}
}
```

* 解析 `name`、`value` 属性，并创建 VarDeclSqlNode 对象，最后添加到 `targetContents` 中。
* 关于 `VarDeclSqlNode` 类，详细解析，见 `「6.1 VarDeclSqlNode」` 。

##### 4.2 TrimHandler

TrimHandler ，实现 NodeHandler 接口，`<trim />` 标签的处理器。代码如下：

```java
// XMLScriptBuilder.java

private class TrimHandler implements NodeHandler {

	public TrimHandler() {
		// Prevent Synthetic Access
	}

	@Override
	public void handleNode(XNode nodeToHandle, List<SqlNode> targetContents) {
		// <1> 解析内部的 SQL 节点，成 MixedSqlNode 对象
		MixedSqlNode mixedSqlNode = parseDynamicTags(nodeToHandle);
		// <2> 获得 prefix、prefixOverrides、"suffix"、suffixOverrides 属性
		String prefix = nodeToHandle.getStringAttribute("prefix");
		String prefixOverrides = nodeToHandle.getStringAttribute("prefixOverrides");
		String suffix = nodeToHandle.getStringAttribute("suffix");
		String suffixOverrides = nodeToHandle.getStringAttribute("suffixOverrides");
		// <3> 创建 TrimSqlNode 对象
		TrimSqlNode trim = new TrimSqlNode(configuration, mixedSqlNode, prefix, prefixOverrides, suffix, suffixOverrides);
		// <4> 添加到 targetContents 中
		targetContents.add(trim);
	}
}
```

* `<1>` 处，调用 `#parseDynamicTags(XNode node)` 方法，解析内部的 SQL 节点，成 MixedSqlNode 对象。
  即 「3.3 parseDynamicTags」 的流程。
* `<2>` 处，获得 `prefix`、`prefixOverrides`、`suffix`、`suffixOverrides` 属性。
* `<3>` 处，创建 `TrimSqlNode` 对象。详细解析，见 `「6.2 TrimSqlNode」` 。
* `<4>` 处，添加到 `targetContents` 中。

##### 4.3 WhereHandler

WhereHandler ，实现 NodeHandler 接口，`<where />` 标签的处理器。

* 把标签解析为 `WhereSqlNode` 节点，和 TrimHandler 是一个套路的。

##### 4.4 SetHandler

SetHandler ，实现 NodeHandler 接口，`<set />` 标签的处理器。

* 把标签解析为 `WhereSqlNode` 节点，和 TrimHandler 是一个套路的。

##### 4.5 ForEachHandler

ForEachHandler ，实现 NodeHandler 接口，`<foreach />` 标签的处理器。

* 把标签解析为 `ForEachSqlNode` 节点，和 TrimHandler 是一个套路的。

##### 4.6 IfHandler

IfHandler ，实现 NodeHandler 接口，`<if />` 标签的处理器。

* 把标签解析为 `IfSqlNode` 节点，和 TrimHandler 是一个套路的。

##### 4.7 ChooseHandler

ChooseHandler ，实现 NodeHandler 接口，`<choose />` 标签的处理器。代码如下：

```java
// XMLScriptBuilder.java

private class ChooseHandler implements NodeHandler {

	public ChooseHandler() {
		// Prevent Synthetic Access
	}

	@Override
	public void handleNode(XNode nodeToHandle, List<SqlNode> targetContents) {
		// 存储解析到的 <when> 标签
		List<SqlNode> whenSqlNodes = new ArrayList<>();
		// 存储解析到的 <otherwise> 标签
		List<SqlNode> otherwiseSqlNodes = new ArrayList<>();
		// 解析 `<when />` 和 `<otherwise />` 的节点们
		handleWhenOtherwiseNodes(nodeToHandle, whenSqlNodes, otherwiseSqlNodes);
		// 获得 `<otherwise />` 的节点
		SqlNode defaultSqlNode = getDefaultSqlNode(otherwiseSqlNodes);
		// 创建 ChooseSqlNode 对象
		ChooseSqlNode chooseSqlNode = new ChooseSqlNode(whenSqlNodes, defaultSqlNode);
		// 添加到 targetContents 中
		targetContents.add(chooseSqlNode);
	}

	private void handleWhenOtherwiseNodes(XNode chooseSqlNode, List<SqlNode> ifSqlNodes, List<SqlNode> defaultSqlNodes) {
		List<XNode> children = chooseSqlNode.getChildren();
		for (XNode child : children) {
			String nodeName = child.getNode().getNodeName();
			NodeHandler handler = nodeHandlerMap.get(nodeName);
			// 收集 `<when />` 标签的情况
			if (handler instanceof IfHandler) {
				handler.handleNode(child, ifSqlNodes);
				// 收集 `<otherwise />` 标签的情况
			} else if (handler instanceof OtherwiseHandler) {
				handler.handleNode(child, defaultSqlNodes);
			}
		}
	}

	// 至多允许有一个 SqlNode 节点
	private SqlNode getDefaultSqlNode(List<SqlNode> defaultSqlNodes) {
		SqlNode defaultSqlNode = null;
		if (defaultSqlNodes.size() == 1) {
			defaultSqlNode = defaultSqlNodes.get(0);
		} else if (defaultSqlNodes.size() > 1) {
			throw new BuilderException("Too many default (otherwise) elements in choose statement.");
		}
		return defaultSqlNode;
	}
}
```

* 通过组合 IfHandler 和 OtherwiseHandler 两个处理器，实现对子节点们的解析。最终，生成 ChooseSqlNode 对象

##### 4.8 OtherwiseHandler

OtherwiseHandler ，实现 NodeHandler 接口，`<otherwise />` 标签的处理器。代码如下：

```java
// XMLScriptBuilder.java

private class OtherwiseHandler implements NodeHandler {

	public OtherwiseHandler() {
		// Prevent Synthetic Access
	}

	@Override
	public void handleNode(XNode nodeToHandle, List<SqlNode> targetContents) {
		// 解析内部的 SQL 节点，成 MixedSqlNode 对象
		MixedSqlNode mixedSqlNode = parseDynamicTags(nodeToHandle);
		// 添加到 targetContents 中
		targetContents.add(mixedSqlNode);
	}
}
```

* 对于 `<otherwise />` 标签，解析的结果是 MixedSqlNode 对象即可。因为，只需要把内容解析出来即可。

### 5. DynamicContext

`org.apache.ibatis.scripting.xmltags.DynamicContext` ，动态 SQL ，用于每次执行 SQL 操作时，记录动态 SQL 处理后的最终 SQL 字符串。
> `SqlSource` 接口表示的就是SQL源码，只会在初始化的时候解析一次就可以；
> 而动态sql是根据解析好的 `SqlSource` 每次执行生成一个 `DynamicContext` 并最终生成发送给数据库的SQL。

#### 5.1 构造方法

```java
// DynamicContext.java

public class DynamicContext {
	/**
	 * {@link #bindings} _parameter 的键，参数
	 */
	public static final String PARAMETER_OBJECT_KEY = "_parameter";
	/**
	 * {@link #bindings} _databaseId 的键，数据库编号
	 */
	public static final String DATABASE_ID_KEY = "_databaseId";

	static {
		// <1.2> 设置 OGNL 的属性访问器
		OgnlRuntime.setPropertyAccessor(ContextMap.class, new ContextAccessor());
	}

	/**
	 * 上下文的参数集合【重要】
	 */
	private final ContextMap bindings;
	/**
	 * 生成后的 SQL【最终SQL】
	 */
	private final StringBuilder sqlBuilder = new StringBuilder();
	/**
	 * 唯一编号。在 {@link org.apache.ibatis.scripting.xmltags.XMLScriptBuilder.ForEachHandler} 使用
	 */
	private int uniqueNumber = 0;

	// 当需要使用到 OGNL 表达式时，parameterObject 非空【把前端传的参数绑定到上下文中】
	public DynamicContext(Configuration configuration, Object parameterObject) {
		// <1> 初始化 bindings 参数
		if (parameterObject != null && !(parameterObject instanceof Map)) {
			MetaObject metaObject = configuration.newMetaObject(parameterObject); // <1.1>
			bindings = new ContextMap(metaObject);
		} else {
			bindings = new ContextMap(null);
		}
		// <2> 添加 bindings 的默认值
		bindings.put(PARAMETER_OBJECT_KEY, parameterObject);
		bindings.put(DATABASE_ID_KEY, configuration.getDatabaseId());
	}
}
```
* `<1>` 处，初始化 `bindings` 参数，创建 ContextMap 对象。
  * `parameterObject` 表示前端传过来的参数，是经过封装的。一般是null或者arg[0]或者Map
* `<2>` 处，添加 bindings 的默认值。目前有 `PARAMETER_OBJECT_KEY`、`DATABASE_ID_KEY` 属性。

目的就是为了添加2个参数？？？
> 个人觉得不仅仅是添加了2个参数，更重要的是在各种动态标签的SqlNode的处理中可以引用到

#### 5.2 bindings 属性相关的方法
```java
// DynamicContext.java

public Map<String, Object> getBindings() {
    return bindings;
}

public void bind(String name, Object value) {
    bindings.put(name, value);
}
```
* 可以往 `bindings` 属性中，添加新的 KV 键值对。

#### 5.3 sqlBuilder 属性相关的方法

表示最终的sql片段，每次追加sql片段。

```java
// DynamicContext.java

public void appendSql(String sql) {
    sqlBuilder.append(sql);
    sqlBuilder.append(" ");
}

public String getSql() {
    return sqlBuilder.toString().trim();
}
```
* 可以不断向 sqlBuilder 属性中，添加 SQL 段。

#### 5.5 ContextMap

ContextMap ，是 DynamicContext 的内部静态类，继承 HashMap 类，上下文的参数集合。代码如下：

```java
// DynamicContext.java

static class ContextMap extends HashMap<String, Object> {

    private static final long serialVersionUID = 2977601501966151582L;

    /**
     * parameter 对应的 MetaObject 对象
     */
    private MetaObject parameterMetaObject;

    public ContextMap(MetaObject parameterMetaObject) {
        this.parameterMetaObject = parameterMetaObject;
    }

    @Override
    public Object get(Object key) {
        // 如果有 key 对应的值，直接获得
        String strKey = (String) key;
        if (super.containsKey(strKey)) {
            return super.get(strKey);
        }

        // 从 parameterMetaObject 中，获得 key 对应的属性
        if (parameterMetaObject != null) {
            // issue #61 do not modify the context when reading
            return parameterMetaObject.getValue(strKey);
        }

        return null;
    }
}
```
* 该类在 HashMap 的基础上，增加支持对 `parameterMetaObject` 属性的访问。

#### 5.6 ContextAccessor
ContextAccessor ，是 DynamicContext 的内部静态类，实现 `ognl.PropertyAccessor` 接口，上下文访问器。代码如下：
```java
// DynamicContext.java

static class ContextAccessor implements PropertyAccessor {

	@Override
	public Object getProperty(Map context, Object target, Object name)
			throws OgnlException {
		Map map = (Map) target;

		// 优先从 ContextMap 中，获得属性
		Object result = map.get(name);
		if (map.containsKey(name) || result != null) {
			return result;
		}

		// <x> 如果没有，则从 PARAMETER_OBJECT_KEY 对应的 Map 中，获得属性
		Object parameterObject = map.get(PARAMETER_OBJECT_KEY);
		if (parameterObject instanceof Map) {
			return ((Map) parameterObject).get(name);
		}

		return null;
	}

	@Override
	public void setProperty(Map context, Object target, Object name, Object value)
			throws OgnlException {
		Map<Object, Object> map = (Map<Object, Object>) target;
		map.put(name, value);
	}
}
```
* `<x>` 处，为什么可以访问 `PARAMETER_OBJECT_KEY` 属性，并且是 Map 类型呢？回看 DynamicContext 构造方法，就可以明白了。
* 这里我有个疑问，为什么要把前端传的参数绑定到上下文中，而真正处理的时候并没有使用到上下文绑定的参数

### 6. SqlNode

`org.apache.ibatis.scripting.xmltags.SqlNode` ，SQL Node 接口，每个 XML Node 会解析成对应的 SQL Node 对象。代码如下：
```java
// SqlNode.java

public interface SqlNode {

    /**
     * 应用当前 SQL Node 节点
     *
     * @param context 上下文
     * @return 当前 SQL Node 节点是否应用成功。
     */
    boolean apply(DynamicContext context);

}
```

#### 6.1 VarDeclSqlNode

org.apache.ibatis.scripting.xmltags.VarDeclSqlNode ，实现 SqlNode 接口，`<bind />` 标签的 SqlNode 实现类。代码如下：

```java
// VarDeclSqlNode.java

public class VarDeclSqlNode implements SqlNode {

    /**
     * 名字
     */
    private final String name;
    /**
     * 表达式
     */
    private final String expression;

    public VarDeclSqlNode(String var, String exp) {
        name = var;
        expression = exp;
    }

    @Override
    public boolean apply(DynamicContext context) {
        // <1> 获得值
        final Object value = OgnlCache.getValue(expression, context.getBindings());
        // <2> 绑定到上下文
        context.bind(name, value);
        return true;
    }
}
```
* `<1>` 处，调用 `OgnlCache#getValue(String expression, Object root)` 方法，从context上下文绑定的参数中获得表达式对应的值。
* `<2>` 处，调用 `DynamicContext#bind(String name, Object value)` 方法，绑定到上下文。

#### 6.2 TrimSqlNode

`org.apache.ibatis.scripting.xmltags.TrimSqlNode` ，实现 SqlNode 接口，`<trim />` 标签的 SqlNode 实现类。

另外，在下文中，我们会看到，`<trim />` 标签是 `<where />` 和 `<set />` 标签的基础。

##### 6.2.1 构造方法
```java
// TrimSqlNode.java

/**
 * 内含的 SqlNode 节点
 */
private final SqlNode contents;
/**
 * 前缀
 */
private final String prefix;
/**
 * 后缀
 */
private final String suffix;
/**
 * 需要被删除的前缀
 */
private final List<String> prefixesToOverride;
/**
 * 需要被删除的后缀
 */
private final List<String> suffixesToOverride;
private final Configuration configuration;

public TrimSqlNode(Configuration configuration, SqlNode contents, String prefix, String prefixesToOverride, String suffix, String suffixesToOverride) {
    this(configuration, contents, prefix, parseOverrides(prefixesToOverride), suffix, parseOverrides(suffixesToOverride));
}

protected TrimSqlNode(Configuration configuration, SqlNode contents, String prefix, List<String> prefixesToOverride, String suffix, List<String> suffixesToOverride) {
    this.contents = contents;
    this.prefix = prefix;
    this.prefixesToOverride = prefixesToOverride;
    this.suffix = suffix;
    this.suffixesToOverride = suffixesToOverride;
    this.configuration = configuration;
}
```
`#parseOverrides(String overrides)` 方法，使用 `|` 分隔字符串成字符串数组，并都转换成大写。代码如下：
```java
// TrimSqlNode.java

private static List<String> parseOverrides(String overrides) {
    if (overrides != null) {
        final StringTokenizer parser = new StringTokenizer(overrides, "|", false);
        final List<String> list = new ArrayList<>(parser.countTokens());
        while (parser.hasMoreTokens()) {
            list.add(parser.nextToken().toUpperCase(Locale.ENGLISH));
        }
        return list;
    }
    return Collections.emptyList();
}
```
##### 6.2.2 apply
```java
// TrimSqlNode.java

@Override
public boolean apply(DynamicContext context) {
    // <1> 创建 FilteredDynamicContext 对象
    FilteredDynamicContext filteredDynamicContext = new FilteredDynamicContext(context);
    // <2> 执行 contents 的应用
    boolean result = contents.apply(filteredDynamicContext);
    // <3> 执行 FilteredDynamicContext 的应用
    filteredDynamicContext.applyAll();
    return result;
}
```
* `<1>` 处，创建 FilteredDynamicContext 对象。关于 FilteredDynamicContext 类，在 `「6.2.3 FilteredDynamicContext」` 。
> FilteredDynamicContext的作用是：相当于新建了一个上下文来存储trim标签中的SQL语句的内容，跟原来上下文的SQL语句内容区分开
* `<2>` 处，执行 contents 的应用。
> 此处执行完后，相当于trim标签内的SQL已经准备好了
* `<3>` 处，调用 `FilteredDynamicContext#applyAll()` 方法，执行 FilteredDynamicContext 的应用。
> 此处执行目的在于发挥trim标签的本来作用

##### 6.2.3 FilteredDynamicContext

FilteredDynamicContext ，是 TrimSqlNode 的内部类，继承 DynamicContext 类，支持 trim 逻辑的 DynamicContext 实现类。
主要是为了能区分存储trim标签内的SQL片段

###### 6.2.3.1 构造方法
```java
// TrimSqlNode.java

/**
 * 委托的 DynamicContext 对象【全局的sql片段上下文】
 */
private DynamicContext delegate;
/**
 * 是否 prefix 已经被应用
 */
private boolean prefixApplied;
/**
 * 是否 suffix 已经被应用
 */
private boolean suffixApplied;
/**
 * StringBuilder 对象 【trim标签内部的sql片段表示】
 */
private StringBuilder sqlBuffer;

public FilteredDynamicContext(DynamicContext delegate) {
    super(configuration, null);
    this.delegate = delegate;
    this.prefixApplied = false;
    this.suffixApplied = false;
    this.sqlBuffer = new StringBuilder();
}
```

###### 7.2.3.2 append
```java
// TrimSqlNode.java

@Override
public void appendSql(String sql) {
    sqlBuffer.append(sql);
}
```
* 该方法，将拼接的 `sql` ，暂时存储到 `sqlBuffer` 中。【暂存到FilteredDynamicContext中】
* 最终，会通过 `#applyAll()` 方法，将 `sqlBuffer` 处理完后，添加回 `delegate.sqlBuffer` 中。

###### 7.2.3.3 applyAll
```java
// TrimSqlNode.java

public void applyAll() {
    // <1> trim 掉多余的空格，生成新的 sqlBuffer 对象
    sqlBuffer = new StringBuilder(sqlBuffer.toString().trim());
    // <2> 将 sqlBuffer 大写，生成新的 trimmedUppercaseSql 对象
    String trimmedUppercaseSql = sqlBuffer.toString().toUpperCase(Locale.ENGLISH);
    // <3> 应用 TrimSqlNode 的 trim 逻辑
    if (trimmedUppercaseSql.length() > 0) {
        applyPrefix(sqlBuffer, trimmedUppercaseSql);
        applySuffix(sqlBuffer, trimmedUppercaseSql);
    }
    // <4> 将结果，添加到 delegate 中
    delegate.appendSql(sqlBuffer.toString());
}
```
* `<1>` 处，trim 掉多余的空格，生成新的 `sqlBuffer` 对象。
* `<2>` 处，将 `sqlBuffer` 大写，生成新的 `trimmedUppercaseSql` 对象。为什么呢？因为，TrimSqlNode 对 `prefixesToOverride` 和 
`suffixesToOverride` 属性，都进行了大写的处理，需要保持统一。但是，又不能直接修改 `sqlBuffer` ，因为这样就相当于修改了原始的 SQL 。
* `<3>` 处，应用 TrimSqlNode 的 trim 逻辑。
  * `#applyPrefix(StringBuilder sql, String trimmedUppercaseSql)` 方法，代码如下：
    ```java
    // TrimSqlNode.java
    // 重写sql的前缀
    private void applyPrefix(StringBuilder sql, String trimmedUppercaseSql) {
        if (!prefixApplied) {
            prefixApplied = true;
            // prefixesToOverride 非空，先删除
            if (prefixesToOverride != null) {
                for (String toRemove : prefixesToOverride) {
                    if (trimmedUppercaseSql.startsWith(toRemove)) {
                        sql.delete(0, toRemove.trim().length());
                        break;
                    }
                }
            }
            // prefix 非空，再添加
            if (prefix != null) {
                sql.insert(0, " ");
                sql.insert(0, prefix);
            }
        }
    }
    ```
    * `#applySuffix(StringBuilder sql, String trimmedUppercaseSql)` 方法，代码如下
    ```java
    // TrimSqlNode.java
    // 重写sql的后缀
    private void applySuffix(StringBuilder sql, String trimmedUppercaseSql) {
        if (!suffixApplied) {
            suffixApplied = true;
            // suffixesToOverride 非空，先删除
            if (suffixesToOverride != null) {
                for (String toRemove : suffixesToOverride) {
                    if (trimmedUppercaseSql.endsWith(toRemove) || trimmedUppercaseSql.endsWith(toRemove.trim())) {
                        int start = sql.length() - toRemove.trim().length();
                        int end = sql.length();
                        sql.delete(start, end);
                        break;
                    }
                }
            }
            // suffix 非空，再添加
            if (suffix != null) {
                sql.append(" ");
                sql.append(suffix);
            }
        }
    }
    ```
* `<4>` 处，将结果，添加到 delegate 中。

#### 6.3 WhereSqlNode

`org.apache.ibatis.scripting.xmltags.WhereSqlNode` ，继承 TrimSqlNode 类，`<where />` 标签的 SqlNode 实现类。代码如下：
```java
// WhereSqlNode.java

public class WhereSqlNode extends TrimSqlNode {

    private static List<String> prefixList = Arrays.asList("AND ", "OR ", "AND\n", "OR\n", "AND\r", "OR\r", "AND\t", "OR\t");

    public WhereSqlNode(Configuration configuration, SqlNode contents) {
        super(configuration, contents, "WHERE", prefixList, null, null);
    }

}
```
* 这就是为什么，说 WhereHandler 和 TrimHandler 是一个套路的原因。

#### 6.4 SetSqlNode

`org.apache.ibatis.scripting.xmltags.SetSqlNode` ，继承 TrimSqlNode 类，`<set />` 标签的 SqlNode 实现类。代码如下：
```java
// WhereSqlNode.java

public class SetSqlNode extends TrimSqlNode {

    private static List<String> suffixList = Collections.singletonList(",");

    public SetSqlNode(Configuration configuration, SqlNode contents) {
        super(configuration, contents, "SET", null, null, suffixList);
    }
}
```
* 这就是为什么，说 SetHandler 和 TrimHandler 是一个套路的原因。


#### 6.5 ForEachSqlNode

总体上，就是把形如 `#{item}` 变成 `__frch_idx_0` 和 `__frch_item_0`；并把这些奇怪变量绑定到上下文中，
最后在DefaultParameterHandler中绑定到JDBC的SQL中。

`org.apache.ibatis.scripting.xmltags.ForEachSqlNode` ，实现 SqlNode 接口，`<foreach />` 标签的 SqlNode 实现类。

##### 6.5.1 构造方法

```java
// ForEachSqlNode.java
public class ForEachSqlNode implements SqlNode {
    // item值的固定前缀
	public static final String ITEM_PREFIX = "__frch_";
	// ognl表达式计算
	private final ExpressionEvaluator evaluator;
	// 集合表达式，对应 collection 属性
	private final String collectionExpression;
	// foreach 标签中的内容节点
	private final SqlNode contents;
	// foreach 的开口
	private final String open;
	// foreach 的结束
	private final String close;
	// foreach 的分隔符
	private final String separator;
	// 每次迭代的值
	private final String item;
	// 每次迭代的索引，如果是map就是key
	private final String index;
	private final Configuration configuration;

	public ForEachSqlNode(Configuration configuration, SqlNode contents, String collectionExpression, String index, String item, String open, String close, String separator) {
		this.evaluator = new ExpressionEvaluator();
		this.collectionExpression = collectionExpression;
		this.contents = contents;
		this.open = open;
		this.close = close;
		this.separator = separator;
		this.index = index;
		this.item = item;
		this.configuration = configuration;
	}
}
```

##### 6.5.2 apply

用`FilteredDynamicContext`包装`PrefixedContext`，用`PrefixedContext`包装`DynamicContext`，完成功能的增强。

FilteredDynamicContext：
> 功能是：把形如 `#{item}` 替换为形如 `__frch_item_0`、`__frch_item_1`

PrefixedContext：
> 功能是：完成分隔符的拼接

```java
// ForEachSqlNode.java

public class ForEachSqlNode implements SqlNode {
	@Override
	public boolean apply(DynamicContext context) {
		Map<String, Object> bindings = context.getBindings();
		// <1> 获得遍历的集合的 Iterable 对象，用于遍历。
		final Iterable<?> iterable = evaluator.evaluateIterable(collectionExpression, bindings);
		if (!iterable.iterator().hasNext()) {
			return true;
		}
		boolean first = true;
		// <2> 添加 open 到 SQL 中
		applyOpen(context);
		int i = 0;
		for (Object o : iterable) {
			// <3> 记录原始的 context 对象
			DynamicContext oldContext = context;
			// <4> 生成新的 context
			if (first || separator == null) {
				context = new PrefixedContext(context, "");
			} else {
				context = new PrefixedContext(context, separator);
			}
			// <5> 获得唯一编号
			int uniqueNumber = context.getUniqueNumber();
			// Issue #709
			// <6> 绑定到 context 中
			if (o instanceof Map.Entry) {
				@SuppressWarnings("unchecked")
				Map.Entry<Object, Object> mapEntry = (Map.Entry<Object, Object>) o;
				applyIndex(context, mapEntry.getKey(), uniqueNumber);
				applyItem(context, mapEntry.getValue(), uniqueNumber);
			} else {
				applyIndex(context, i, uniqueNumber);
				applyItem(context, o, uniqueNumber);
			}
			// <7> 执行 contents 的应用
			contents.apply(new FilteredDynamicContext(configuration, context, index, item, uniqueNumber));
			// <8> 判断 prefix（分隔符） 是否已经插入
			if (first) {
				first = !((PrefixedContext) context).isPrefixApplied();
			}
			// <9> 恢复原始的 context 对象
			context = oldContext;
			i++;
		}
		// <10> 添加 close 到 SQL 中
		applyClose(context);
		// <11> 移除 index 和 item 对应的绑定
		context.getBindings().remove(item);
		context.getBindings().remove(index);
		return true;
	}
}
```
* 这个方法的逻辑，相对会比较复杂。最好自己也调试下。
* 我们假设以如下查询为示例：

```xml
<select id="getUserList" parameterType="List" resultType="List">
    SELECT id FROM users
    WHERE id IN
    <foreach collection="ids" index="idx" item="item" open="("  close=")" separator=",">
        #{item}
    </foreach>
</select>
```
* `<1>` 处，调用 `ExpressionEvaluator#evaluateBoolean(String expression, Object parameterObject)` 方法，
获得遍历的集合的 Iterable 对象，用于遍历。详细解析，见 `「7.4 ExpressionEvaluator」` 。
* `<2>` 处，调用 `#applyOpen(DynamicContext context)` 方法，添加 `open` 到 SQL 中。代码如下：
```java
// ForEachSqlNode.java
private void applyOpen(DynamicContext context) {
    if (open != null) {
        context.appendSql(open);
    }
}
```
* 下面开始，我们要遍历 `iterable` 了。
* `<3>` 处，记录原始的 `context` 对象。为什么呢？因为 `<4>` 处，会生成新的 `context` 对象。
* `<4>` 处，生成新的 `context` 对象。类型为 PrefixedContext 对象，只有在非首次，才会传入 `separator` 属性。
因为，PrefixedContext 处理的是集合元素之间的分隔符。详细解析，见 `「6.5.3 PrefixedContext」` 。
* `<5>` 处，获得唯一编号。
* `<6>` 处，绑定到 `context` 中。调用的两个方法，代码如下：
```java
// ForEachSql   Node.java

public static final String ITEM_PREFIX = "__frch_";

private void applyIndex(DynamicContext context, Object o, int i) {
    if (index != null) {
        context.bind(index, o);
        context.bind(itemizeItem(index, i), o);
    }
}

private void applyItem(DynamicContext context, Object o, int i) {
    if (item != null) {
        context.bind(item, o);
        context.bind(itemizeItem(item, i), o);
    }
}

private static String itemizeItem(String item, int i) {
    return ITEM_PREFIX + item + "_" + i;
}
```
> 上述代码完成的功能是把每次迭代的变量都绑定到上下文中，以备后续使用；至于每次都绑定一个index和item，后续也会使用？
* 另外，此处也根据是否为 Map.Entry 类型，分成了两种情况。官方文档说明如下：
> 你可以将任何可迭代对象（如 List、Set 等）、Map 对象或者数组对象作为集合参数传递给 foreach。
> 当使用可迭代对象或者数组时，index 是当前迭代的序号，item 的值是本次迭代获取到的元素。
> 当使用 Map 对象（或者 Map.Entry 对象的集合）时，index 是键，item 是值。

* `<7>` 处，执行 `contents` 的应用。
  * 例如说，此处 `contents` 就是上述示例的 `"#{item}"` 。
  * 另外，进一步将 `context` 对象，封装成 FilteredDynamicContext 对象。
* `<8>` 处，判断 `prefix` 是否已经插入。如果是，则 `first` 会被设置为 `false` 。然后，胖友回过头看看 `<4>` 处的逻辑，是不是清晰多了。
* `<9>` 处，恢复原始的 `context` 对象。然后，回过头看看 `<3>` 处的逻辑，是不是清晰多了。
* `<10>` 处，调用 `#applyClose(DynamicContext context)` 方法，添加 `close` 到 SQL 中。代码如下：
```java
// ForEachSqlNode.java

private void applyClose(DynamicContext context) {
    if (close != null) {
        context.appendSql(close);
    }
}
```
* `<11>` 处，移除 `index` 和 `item` 属性对应的绑定。这两个绑定，是在 `<6>` 处被添加的。

##### 6.5.3 PrefixedContext
PrefixedContext ，是 ForEachSqlNode 的内部类，继承 DynamicContext 类，支持添加 `<foreach />` 标签中，
多个元素之间的分隔符的 DynamicContext 实现类。代码如下：
```java
// ForEachSqlNode.java

private class PrefixedContext extends DynamicContext {

	private final DynamicContext delegate;
	private final String prefix;
	/**
	 * 是否已经应用 prefix
	 */
	private boolean prefixApplied;

	@Override
	public void appendSql(String sql) {
		// 如果未应用 prefix ，并且，方法参数 sql 非空
		// 则添加 prefix 到 delegate 中，并标记 prefixApplied 为 true ，表示已经应用
		if (!prefixApplied && sql != null && sql.trim().length() > 0) {
			delegate.appendSql(prefix);
			prefixApplied = true;
		}

		// 添加 sql 到 delegate 中
		delegate.appendSql(sql);
	}
}
```
* `prefix` 属性，虽然属性命名上是 `prefix` ，但是对应到 ForEachSqlNode 的 `separator` 属性。
* 重心在于 `#appendSql(String sql)` 方法的实现。逻辑还是比较简单的，就是判断之前是否添加过 `prefix` ，没有就进行添加。
而判断的依据，就是 `prefixApplied` 标识。

##### 6.5.4 FilteredDynamicContext

FilteredDynamicContext ，是 ForEachSqlNode 的内部类，继承 DynamicContext 类，实现 `<foreach />` 标签中形如
`#{item}` 变量的替换，替换为形如`__frch_item_0`、`__frch_item_1`，最后在`DefaultParameterHandler`中完成实际变量的替换。

```java
// ForEachSqlNode.java

private static class FilteredDynamicContext extends DynamicContext {
	
	@Override
	public void appendSql(String sql) {
		GenericTokenParser parser = new GenericTokenParser("#{", "}", content -> {
			// 将对 item 的访问，替换成 itemizeItem(item, index) 。
			String newContent = content.replaceFirst("^\\s*" + item + "(?![^.,:\\s])", itemizeItem(item, index));
			// 将对 itemIndex 的访问，替换成 itemizeItem(itemIndex, index) 。
			if (itemIndex != null && newContent.equals(content)) {
				newContent = content.replaceFirst("^\\s*" + itemIndex + "(?![^.,:\\s])", itemizeItem(itemIndex, index));
			}
			// 返回
			return "#{" + newContent + "}";
		});

		// 执行 GenericTokenParser 的解析
		// 添加到 delegate 中
		delegate.appendSql(parser.parse(sql));
	}
}
```
* 核心方法是 `#appendSql(String sql)` 方法的重写。可以集合下图示例，理解下具体的代码实现。
> ![](/Users/apple/Documents/Work/aliyun-oss/dev-images/foreach中item变量的替换.png)
* 如果变成这样，具体的值，在哪里设置呢？答案在 DefaultParameterHandler 类中。所以，继续往下看。哈哈哈哈。

#### 6.6 IfSqlNode

`org.apache.ibatis.scripting.xmltags.IfSqlNode` ，实现 SqlNode 接口，`<if />` 标签的 SqlNode 实现类。代码如下：
```java
// IfSqlNode.java

public class IfSqlNode implements SqlNode {

    private final ExpressionEvaluator evaluator;
    // 判断表达式
    private final String test;
    // 内嵌的 SqlNode 节点
    private final SqlNode contents;

    @Override
    public boolean apply(DynamicContext context) {
        // <1> 判断是否符合条件
        if (evaluator.evaluateBoolean(test, context.getBindings())) {
            // <2> 符合，执行 contents 的应用
            contents.apply(context);
            // 返回成功
            return true;
        }
        // <3> 不符合，返回失败
        return false;
    }
}
```
* `<1>` 处，会调用 `ExpressionEvaluator#evaluateBoolean(String expression, Object parameterObject)` 方法，判断是否符合条件。
* `<2>` 处，如果符合条件，则执行 `contents` 的应用，并返回成功 `true` 。
* `<3>` 处，如果不符条件，则返回失败 `false` 。 
😈 此处，终于出现一个返回 `false` 的情况，最终会在 ChooseSqlNode 中，会看到 `true` 和 `false` 的用处。

#### 6.7 ChooseSqlNode

`org.apache.ibatis.scripting.xmltags.ChooseSqlNode` ，实现 SqlNode 接口，`<choose />` 标签的 SqlNode 实现类。代码如下：

```java
// ChooseSqlNode.java

public class ChooseSqlNode implements SqlNode {

    // <otherwise /> 标签对应的 SqlNode 节点
    private final SqlNode defaultSqlNode;
    // <when /> 标签对应的 SqlNode 节点数组
    private final List<SqlNode> ifSqlNodes;

    public ChooseSqlNode(List<SqlNode> ifSqlNodes, SqlNode defaultSqlNode) {
        this.ifSqlNodes = ifSqlNodes;
        this.defaultSqlNode = defaultSqlNode;
    }

    @Override
    public boolean apply(DynamicContext context) {
        // <1> 先判断  <when /> 标签中，是否有符合条件的节点。
        // 如果有，则进行应用。并且只因应用一个 SqlNode 对象
        for (SqlNode sqlNode : ifSqlNodes) {
            if (sqlNode.apply(context)) {
                return true;
            }
        }
        // <2> 再判断  <otherwise /> 标签，是否存在
        // 如果存在，则进行应用
        if (defaultSqlNode != null) {
            defaultSqlNode.apply(context);
            return true;
        }
        // <3> 返回都失败
        return false;
    }

}
```
* `<1>` 处，先判断 `<when />` 标签中，是否有符合条件的节点。如果有，则进行应用。并且只因应用一个 SqlNode 对象。
这里，我们就看到了，`SqlNode#apply(context)` 方法，返回 `true` 或 `false` 的用途了。
* `<2>` 处，再判断 `<otherwise />` 标签，是否存在。如果存在，则进行应用。
* `<3>` 处，返回都失败。

#### 6.8 StaticTextSqlNode

`org.apache.ibatis.scripting.xmltags.StaticTextSqlNode` ，实现 SqlNode 接口，静态文本的 SqlNode 实现类。代码如下：

```java
// StaticTextSqlNode.java

public class StaticTextSqlNode implements SqlNode {

    // 静态文本
    private final String text;

    public StaticTextSqlNode(String text) {
        this.text = text;
    }

    @Override
    public boolean apply(DynamicContext context) {
        // 直接拼接到 context 中
        context.appendSql(text);
        return true;
    }

}
```
* 比较简单，直接拼接sql。

#### 6.9 TextSqlNode

`org.apache.ibatis.scripting.xmltags.TextSqlNode` ，实现 SqlNode 接口，文本的 SqlNode 实现类。
相比 StaticTextSqlNode 的实现来说，TextSqlNode **不确定是否为静态文本**，所以提供 #isDynamic() 方法，进行判断是否为动态文本。

##### 6.9.1 isDynamic

`#isDynamic()` 方法，判断是否为动态文本。代码如下：

```java
// TextSqlNode.java
public boolean isDynamic() {
    // <1> 创建 DynamicCheckerTokenParser 对象
    DynamicCheckerTokenParser checker = new DynamicCheckerTokenParser();
    // <2> 创建 GenericTokenParser 对象
    GenericTokenParser parser = createParser(checker);
    // <3> 执行解析
    parser.parse(text);
    // <4> 判断是否为动态文本
    return checker.isDynamic();
}
```
* `<2>` 处，调用 `#createParser(TokenHandler handler)` 方法，创建 GenericTokenParser 对象。
该类的作用是：处理#{}和${}参数
* `<3>` 处，调用 `GenericTokenParser#parse(String text)` 方法，执行解析，寻找 `${xxx}` 对。存在即为动态文本

##### 6.9.2 apply

```java
// TextSqlNode.class

public class TextSqlNode implements SqlNode {
	public boolean apply(DynamicContext context) {
		// <1> 创建 BindingTokenParser 对象
		// <2> 创建 GenericTokenParser 对象
		GenericTokenParser parser = createParser(new BindingTokenParser(context, injectionFilter));
		// <3> 执行解析
		// <4> 将解析的结果，添加到 context 中
		context.appendSql(parser.parse(text));
		return true;
	}
}
```
* `<2>` 处，创建 GenericTokenParser 对象
* `<3>` 处，调用 `GenericTokenParser#parse(String text)` 方法，执行解析。当解析到 `${xxx}` 时，
会调用 BindingTokenParser 的 `#handleToken(String content)` 方法，执行相应的逻辑。
* `<4>` 处，将解析的结果，添加到 `context` 中。
* `<1>` 处，创建 BindingTokenParser 对象。代码如下：
    ```java
    // TextSqlNode.java
    private static class BindingTokenParser implements TokenHandler {
        
        @Override
        public String handleToken(String content) {
            // 初始化 value 属性到 context 中
            Object parameter = context.getBindings().get("_parameter");
            if (parameter == null) {
                context.getBindings().put("value", null);
            } else if (SimpleTypeRegistry.isSimpleType(parameter.getClass())) {
                context.getBindings().put("value", parameter);
            }
            // 使用 OGNL 表达式，获得对应的值
            Object value = OgnlCache.getValue(content, context.getBindings());
            String srtValue = (value == null ? "" : String.valueOf(value)); // issue #274 return "" instead of "null"
            checkInjection(srtValue);
            // 返回该值（返回"" 或者 值，替换了${xxx}）
            return srtValue;
        }
    }
    ```
  * 对于该方法，如下的示例：
    ```sql
    SELECT * FROM subject WHERE id = ${id}
    ```
    * `id = ${id}` 的 `${id}` 部分，将被替换成对应的具体编号。例如说，`id` 为 1 ，则会变成 `SELECT * FROM subject WHERE id = 1` 。
  * 而对于如下的示例：
    ```sql
    SELECT * FROM subject WHERE id = #{id}
    ```
      * `id = #{id}` 的 `#{id}` 部分，则**不会进行替换**。

#### 6.10 MixedSqlNode

`org.apache.ibatis.scripting.xmltags.MixedSqlNode` ，实现 SqlNode 接口，混合的 SqlNode 实现类。代码如下：

```java
// MixedSqlNode.java

public class MixedSqlNode implements SqlNode {
    // 内嵌的 SqlNode 数组
    private final List<SqlNode> contents;

    public MixedSqlNode(List<SqlNode> contents) {
        this.contents = contents;
    }

    @Override
    public boolean apply(DynamicContext context) {
        // 遍历 SqlNode 数组，逐个应用
        for (SqlNode sqlNode : contents) {
            sqlNode.apply(context);
        }
        return true;
    }
}
```
* MixedSqlNode 内含有 SqlNode 数组。
* 在 `#apply(DynamicContext context)` 方法中，遍历 SqlNode 数组，逐个应用。

#### 参数绑定原理：

以含有动态标签为例

##### BoundSql

绑定的SQL,是从 `SqlSource` 而来，将动态内容都处理完成得到的SQL语句字符串，其中包括?,还有绑定的参数。

也就是说SqlSource中已经包含了发送给数据的SQL源码、参数占位符?、已经需要被绑定的参数

```java
public class DynamicSqlSource implements SqlSource {

	//得到绑定的SQL
	@Override
	public BoundSql getBoundSql(Object parameterObject) {
		//生成一个动态上下文
		DynamicContext context = new DynamicContext(configuration, parameterObject);
		// <1>、这里SqlNode.apply只是将${}这种参数替换掉，并没有替换#{}这种参数
		rootSqlNode.apply(context);
		//调用SqlSourceBuilder
		SqlSourceBuilder sqlSourceParser = new SqlSourceBuilder(configuration);
		Class<?> parameterType = parameterObject == null ? Object.class : parameterObject.getClass();
		// <2>、SqlSourceBuilder.parse,注意这里返回的是StaticSqlSource,解析完了就把那些参数都替换成?了，也就是最基本的JDBC的SQL写法
		SqlSource sqlSource = sqlSourceParser.parse(context.getSql(), parameterType, context.getBindings());
		//看似是又去递归调用SqlSource.getBoundSql，其实因为是StaticSqlSource，所以没问题，不是递归调用
		BoundSql boundSql = sqlSource.getBoundSql(parameterObject);
		for (Map.Entry<String, Object> entry : context.getBindings().entrySet()) {
			// <3>、添加实际参数
			boundSql.setAdditionalParameter(entry.getKey(), entry.getValue());
		}
		return boundSql;
	}
}
```

1. 首先从映射的语句对象 `MappedStatement` 中，得到初始化时解析好的 `SqlSource` 对象，然后进入上述代码流程
2. 在 <1> 处解析完所有的动态标签，得到了含变量 `#{xxx}` 的SQL源码
3. 在 <2> 处替换所有变量 `#{xxx}` 为 `?` ，且针对每个变量生成参数映射 `ParameterMapping`
4. 在 <3> 位置把 `context` 中绑定的参数设置到 `boundSql` 中

##### DefaultParameterHandler

```java
public class DefaultParameterHandler implements ParameterHandler {
	
	public void setParameters(PreparedStatement ps) throws SQLException {
		ErrorContext.instance().activity("setting parameters").object(mappedStatement.getParameterMap().getId());
		// <1>、得到sql的参数映射列表
		List<ParameterMapping> parameterMappings = boundSql.getParameterMappings();
		if (parameterMappings != null) {
			for (int i = 0; i < parameterMappings.size(); i++) {
				ParameterMapping parameterMapping = parameterMappings.get(i);
				if (parameterMapping.getMode() != ParameterMode.OUT) {
					Object value;
					// <2>、获取参数的属性
					String propertyName = parameterMapping.getProperty();
					// <3>、AdditionalParameter 中有没有参数值
					if (boundSql.hasAdditionalParameter(propertyName)) {
						value = boundSql.getAdditionalParameter(propertyName);
					} else if (parameterObject == null) {
						value = null;
					} else if (typeHandlerRegistry.hasTypeHandler(parameterObject.getClass())) {
						value = parameterObject;
					} else {
						// <4>、实在没办法从前端的传的参数中获取
						MetaObject metaObject = configuration.newMetaObject(parameterObject);
						value = metaObject.getValue(propertyName);
					}
					TypeHandler typeHandler = parameterMapping.getTypeHandler();
					JdbcType jdbcType = parameterMapping.getJdbcType();
					if (value == null && jdbcType == null) {
						jdbcType = configuration.getJdbcTypeForNull();
					}
					// <5>、最后调用typeHandler把参数的实际值设置到ps中
					typeHandler.setParameter(ps, i + 1, value, jdbcType); // 因为jdbc规范要求 paramIndex 从 1开始，所以这里必须要加1
				}
			}
		}
	}
}
```
* 在 `<1>`，从 `boundSql` 中获取参数列表 parameterMappings，稍后要遍历参数列表
* 在 `<2>`，获取到参数名称 `propertyName`
* 在 `<3>`，查看 boundSql 的额外参数中有没有这个属性的value
* 在 `<4>`，实在没办法从前端的传的参数 `parameterObject` 中获取属性的value
* 在 `<5>`、最后调用 `typeHandler` 把参数的实际值设置到 `ps` 中