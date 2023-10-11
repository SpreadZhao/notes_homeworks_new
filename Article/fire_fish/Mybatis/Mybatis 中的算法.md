

### include 节点的解析原理
`org.apache.ibatis.builder.xml.XMLIncludeTransformer` ，XML `<include />` 标签的转换器，
负责将 SQL 中的 <include /> 标签转换成对应的 `<sql />` 的内容，最终使用纯文本替换原来的 `<include />` 标签内容

原理是：
1. 递归思想
2. dom的Node的使用


#### 3.1 构造方法
```java
// XMLIncludeTransformer.java

private final Configuration configuration;
private final MapperBuilderAssistant builderAssistant;

public XMLIncludeTransformer(Configuration configuration, MapperBuilderAssistant builderAssistant) {
    this.configuration = configuration;
    this.builderAssistant = builderAssistant;
}
```

#### 3.2 applyIncludes
`#applyIncludes(Node source)` 方法，将 `<include />` 标签，替换成引用的 `<sql />` 。代码如下：
```java
// XMLIncludeTransformer.java

public void applyIncludes(Node source) {
    // <1> 创建 variablesContext ，并将 configurationVariables 添加到其中
    Properties variablesContext = new Properties();
    Properties configurationVariables = configuration.getVariables();
    if (configurationVariables != null) {
        variablesContext.putAll(configurationVariables);
    }
    // <2> 处理 <include />
    applyIncludes(source, variablesContext, false);
}
```
* `<1>` 处，创建 `variablesContext` ，并将 `configurationVariables` 添加到其中。
这里的目的是，避免 `configurationVariables` 被下面使用时候，可能被修改。实际上，从下面的实现上，不存在这个情况。
* `<2>` 处，调用 `#applyIncludes(Node source, final Properties variablesContext, boolean included)` 方法，处理 `<include />` 。

---

`#applyIncludes(Node source, final Properties variablesContext, boolean included)` 方法，使用递归的方式，
将 `<include />` 标签，替换成引用的 `<sql />`，最终替换为纯文本 。代码如下：
```java
// XMLIncludeTransformer.java
public class XMLIncludeTransformer {
	private void applyIncludes(Node source, final Properties variablesContext, boolean included) {
		// <1> 如果是 <include /> 标签
		if (source.getNodeName().equals("include")) {
			// <1.1> 获得 <sql /> 对应的节点
			Node toInclude = findSqlFragment(getStringAttribute(source, "refid"), variablesContext);
			// <1.2> 获得包含 <include /> 标签内的属性
			Properties toIncludeContext = getVariablesContext(source, variablesContext);
			// <1.3> 递归调用 #applyIncludes(...) 方法，继续替换。注意，此处是 <sql /> 对应的节点
			applyIncludes(toInclude, toIncludeContext, true);
			if (toInclude.getOwnerDocument() != source.getOwnerDocument()) { // 这个情况，艿艿暂时没调试出来
				toInclude = source.getOwnerDocument().importNode(toInclude, true);
			}
			// <1.4> 将 <include /> 节点替换成 <sql /> 节点
			source.getParentNode().replaceChild(toInclude, source); // 注意，这是一个奇葩的 API ，前者为 newNode ，后者为 oldNode
			// <1.4> 将 <sql /> 子节点添加到 <sql /> 节点前面
			while (toInclude.hasChildNodes()) {
				toInclude.getParentNode().insertBefore(toInclude.getFirstChild(), toInclude); // 这里有个点，一定要注意，卡了艿艿很久。当子节点添加到其它节点下面后，这个子节点会不见了，相当于是“移动操作”
			}
			// <1.4> 移除 <include /> 标签自身
			toInclude.getParentNode().removeChild(toInclude);

			// <2> 如果节点类型为 Node.ELEMENT_NODE
		} else if (source.getNodeType() == Node.ELEMENT_NODE) {
			// <2.1> 如果在处理 <include /> 标签中，则替换其上的属性，例如 <sql id="123" lang="${cpu}"> 的情况，lang 属性是可以被替换的
			if (included && !variablesContext.isEmpty()) {
				// replace variables in attribute values
				NamedNodeMap attributes = source.getAttributes();
				for (int i = 0; i < attributes.getLength(); i++) {
					Node attr = attributes.item(i);
					attr.setNodeValue(PropertyParser.parse(attr.getNodeValue(), variablesContext));
				}
			}
			// <2.2> 遍历子节点，递归调用 #applyIncludes(...) 方法，继续替换
			NodeList children = source.getChildNodes();
			for (int i = 0; i < children.getLength(); i++) {
				applyIncludes(children.item(i), variablesContext, included);
			}

			// <3> 如果在处理 <include /> 标签中，并且节点类型为 Node.TEXT_NODE ，并且变量非空
			// 则进行变量的替换，并修改原节点 source
		} else if (included && source.getNodeType() == Node.TEXT_NODE
				&& !variablesContext.isEmpty()) {
			// replace variables in text node
			source.setNodeValue(PropertyParser.parse(source.getNodeValue(), variablesContext));
		}
	}
}
```
* 这是个有**自递归逻辑**的方法，所以理解起来会有点绕，实际上还是蛮简单的。为了更好的解释，我们假设示例如下：
```xml
// mybatis-config.xml

<properties>
    <property name="cpu" value="16c" />
    <property name="target_sql" value="123" />
</properties>

// Mapper.xml

<sql id="123" lang="${cpu}">
    ${cpu}
    aoteman
    qqqq
</sql>

<select id="testForInclude">
    SELECT * FROM subject
    <include refid="${target_sql}" />
</select>
```

* 在上述示例的 `<select />` 节点进入这个方法时，会首先进入 `<2>` 这块逻辑。
  * `<2.1>` 处，因为 不满足 `included` 条件，初始传入是 `false` ，所以跳过。
  * `<2.2>` 处，遍历子节点，递归调用 `#applyIncludes(...)` 方法，继续替换。如图所示：
  > ![](/Users/apple/Documents/Work/aliyun-oss/dev-images/mybatis的include标签解析.png)
  * 子节点 `[0]` 和 `[2]` ，执行该方法时，不满足 `<1>`、`<2>`、`<3>` 任一一种情况，所以可以忽略。
  虽然说，满足 `<3>` 的节点类型为 `Node.TEXT_NODE` ，但是 `included` 此时为 `false` ，所以不满足。
  * 子节点 `[1]` ，执行该方法时，满足 `<1>` 的情况，所以走起。
* 在子节点 `[1]` ，即 `<include />` 节点进入 `<1>` 这块逻辑：
  * `<1.1>` 处，调用 `#findSqlFragment(String refid, Properties variables)` 方法，获得 `<sql />` 对应的节点，
  即上述示例看到的，`<sql id="123" lang="${cpu}"> ... </>` 。详细解析，见 「3.3 findSqlFragment」 。
  * `<1.2>` 处，调用 `#getVariablesContext(Node node, Properties inheritedVariablesContext)` 方法，
  获得包含 `<include />` 标签内的属性 `Properties` 对象。详细解析，见 「3.4 getVariablesContext」 。
  * `<1.3>` 处，递归调用 `#applyIncludes(...)` 方法，继续替换。注意，此处是 `<sql />` 对应的节点，并且 `included` 参数为 `true` 。
  详细的结果，见 😈😈😈 处。
  * `<1.4>` 处，将处理好的 `<sql />` 节点，替换掉 `<include />` 节点。逻辑有丢丢绕，耐心看下注释，好好思考。
* 😈😈😈 在 <sql /> 节点，会进入 <2> 这块逻辑：
  * `<2.1>` 处，因为 `included` 为 `true` ，所以能满足这块逻辑，会进行执行。如 `<sql id="123" lang="${cpu}">` 的情况，
  `lang` 属性是可以被替换的。
  * `<2.2>` 处，遍历子节点，递归调用 `#applyIncludes(...)` 方法，继续替换。如图所示：
  > ![](/Users/apple/Documents/Work/aliyun-oss/dev-images/mybatis处理include节点解析02.png)
  * 子节点 `[0]` ，执行该方法时，满足 `<3>` 的情况，所以可以使用变量 `Properteis` 对象，进行替换，并修改原节点。

其实，整理一下，逻辑也不会很绕。耐心耐心耐心。
其实核心算法很简单：
1. xml的Node节点的使用
2. 递归处理，以及递归的结束条件
3. 使用变量替换占位符


#### 3.3 findSqlFragment
比较简单，瞅瞅注释。

`#findSqlFragment(String refid, Properties variables)` 方法，获得对应的 `<sql />` 节点。代码如下：
```java
// XMLIncludeTransformer.java

private Node findSqlFragment(String refid, Properties variables) {
    // 因为 refid 可能是动态变量，所以进行替换
    refid = PropertyParser.parse(refid, variables); // 替换变量
    // 获得完整的 refid ，格式为 "${namespace}.${refid}"
    refid = builderAssistant.applyCurrentNamespace(refid, true);
    try {
        // 获得对应的 <sql /> 节点
        XNode nodeToInclude = configuration.getSqlFragments().get(refid);
        // 获得 Node 节点，进行克隆
        return nodeToInclude.getNode().cloneNode(true);
    } catch (IllegalArgumentException e) {
        throw new IncompleteElementException("Could not find SQL statement to include with refid '" + refid + "'", e);
    }
}

private String getStringAttribute(Node node, String name) {
    return node.getAttributes().getNamedItem(name).getNodeValue();
}
```

#### 3.4 getVariablesContext
功能：解析汇总include标签内的属性和全局properties属性。

`#getVariablesContext(Node node, Properties inheritedVariablesContext)` 方法，
获得包含 `<include />` 标签内的属性 `Properties` 对象。代码如下：

```java
// XMLIncludeTransformer.java

private Properties getVariablesContext(Node node, Properties inheritedVariablesContext) {
    // 获得 <include /> 标签内的属性集合
    Map<String, String> declaredProperties = null;
    NodeList children = node.getChildNodes();
    for (int i = 0; i < children.getLength(); i++) {
        Node n = children.item(i);
        if (n.getNodeType() == Node.ELEMENT_NODE) {
            String name = getStringAttribute(n, "name");
            // Replace variables inside
            String value = PropertyParser.parse(getStringAttribute(n, "value"), inheritedVariablesContext);
            if (declaredProperties == null) {
                declaredProperties = new HashMap<>();
            }
            if (declaredProperties.put(name, value) != null) { // 如果重复定义，抛出异常
                throw new BuilderException("Variable " + name + " defined twice in the same include definition");
            }
        }
    }
    // 如果 <include /> 标签内没有属性，直接使用 inheritedVariablesContext 即可
    if (declaredProperties == null) {
        return inheritedVariablesContext;
    // 如果 <include /> 标签内有属性，则创建新的 newProperties 集合，将 inheritedVariablesContext + declaredProperties 合并
    } else {
        Properties newProperties = new Properties();
        newProperties.putAll(inheritedVariablesContext);
        newProperties.putAll(declaredProperties);
        return newProperties;
    }
}
```

* 比较简单，瞅瞅注释。
* 如下是 `<include />` 标签内有属性的示例：
```
<sql id="userColumns"> ${alias}.id,${alias}.username,${alias}.password </sql>

<select id="selectUsers" resultType="map">
  select
    <include refid="userColumns"><property name="alias" value="t1"/></include>,
    <include refid="userColumns"><property name="alias" value="t2"/></include>
  from some_table t1
    cross join some_table t2
</select>
```