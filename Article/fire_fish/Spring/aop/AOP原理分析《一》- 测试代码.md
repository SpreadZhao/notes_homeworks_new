
@[TOC](文章结构)

### 代码结构
![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/2022-09-12-11-38-33-image.png)
### 切面类
AspectJTest.java
```java
@Aspect
public class AspectJTest {

    @Pointcut("execution(* *.test(..))")
    public void test() {}

     @Before("test()")
    public void beforeTest() {
        System.err.println("aspect @Before...");
    }

    @After("test()")
    public void afterTest() {
        System.err.println("aspect @After...");
    }

    @Around("test()")
    public Object aroundTest(ProceedingJoinPoint p) {
        System.err.println("aspect @Around...before...");
        Object o = null;
        try {
            o = p.proceed();
        } catch (Throwable throwable) {
            throwable.printStackTrace();
        }
        System.err.println("aspect @Around...after...");
        return o;
    }
}
```
### 被增强的类
将被增强方法进行增强
TestBean.java
```java
@Data
public class TestBean {

    private String testStr = "testStr";

    public void test() {
        System.err.println("test...");
    }
}
```


### aop配置
application.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:aop="http://www.springframework.org/schema/aop"
       xsi:schemaLocation="
            http://www.springframework.org/schema/beans
            https://www.springframework.org/schema/beans/spring-beans.xsd
            http://www.springframework.org/schema/aop
            https://www.springframework.org/schema/aop/spring-aop.xsd">
    <!--    开启aop-->
    <aop:aspectj-autoproxy/>
    <!--    bean -->
    <bean id="test" class="com.firefish.springsourcecodedeepanalysis.chapter07.TestBean"/>
    <!--    切面-->
    <bean class="com.firefish.springsourcecodedeepanalysis.chapter07.AspectJTest"/>
</beans>

```
### 测试程序
AopTest.java
```java
public class AopTest {

	public static void main(String[] args) {
		ClassPathXmlApplicationContext context =
				new ClassPathXmlApplicationContext("com/firefish/springsourcecodedeepanalysis/chapter07/application.xml");

		TestBean bean = (TestBean) context.getBean("test");
		bean.test();
	}
}
```

传送门：<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#项目介绍">**保姆式Spring5源码解析**</a>

欢迎与作者一起交流技术和工作生活

<a href="https://gitee.com/firefish985/spring-framework-deepanalysis/tree/5.1.x#联系作者">**联系作者**</a>

