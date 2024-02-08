> 前提：
>
> 1. 了解过 Spring、Spring Boot
> 2. 了解过 Servlet 规范的 Filter 接口
> 3. 对 Spring Security 有入门使用
> 4. 最好了解责任链模式

## 1 原理概述

Spring Security 的功能是通过 servlet 规范的 filter 接口来实现的。在请求达到真正处理方法之前需要经过一系列的由 Spring Security 过滤器组成的过滤器链，这个过滤器链就完成了 Spring Security 的功能。

**原理：总体上是，把用户自定义的每一项配置条目（SecurityConfigurer）翻译为 `javax.servlet.Filter`，所有 Filter 组成一个 filterChainProxy 对象；在请求达到真正处理方法时执行过滤器链对象 filterChainProxy。**

以以下最简单的代码为例来说明 Spring Security 的原理：

1. 引入 Spring Security 的pom依赖

2. 开启 Spring Security

   ```java
   @EnableWebSecurity
   ```

3. 自定义配置如下

   ```java
   @Configuration
   // 开启Security
   @EnableWebSecurity
   public class SecurityConfig extends WebSecurityConfigurerAdapter {
       @Override
       protected void configure(HttpSecurity http) throws Exception {
           http
               // 禁用csrf
               .csrf().disable()
               // 因为用token所以禁用session管理
               .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)
               // 对请求进行认证
   			.and().authorizeRequests()
               // 允许登陆请求
   			.antMatchers(HttpMethod.GET, "/login").permitAll()
               // 拒绝其他所有请求
   			.anyRequest().authenticated();
       }
   }
   ```

在以上的自定义配置中，每一项配置在底层实际上就是 `SecurityConfigurer`，而每一个`SecurityConfigurer`基本上都会被翻译为一个`javax.servlet.Filter`，这些 Filter 组成过滤器链 `filterChain`来完成Spring Security的功能。

下面是详细点的介绍原理部分。

## 2 Spring Security 原理

@EnableWebSecurity 注解引入了 WebSecurityConfiguration

```java
@Import({ WebSecurityConfiguration.class,
		SpringWebMvcImportSelector.class,
		OAuth2ImportSelector.class })
@EnableGlobalAuthentication
@Configuration
public @interface EnableWebSecurity {
   
}
```

继续看 WebSecurityConfiguration，完成了过滤器链。**springSecurityFilterChain 方法完成了主体功能**

```java
@Configuration
public class WebSecurityConfiguration implements ImportAware, BeanClassLoaderAware {
    
    // 过滤器链
    @Bean(name = AbstractSecurityWebApplicationInitializer.DEFAULT_FILTER_NAME)
	public Filter springSecurityFilterChain() throws Exception {
        // <1>
		boolean hasConfigurers = webSecurityConfigurers != null
				&& !webSecurityConfigurers.isEmpty();
        // <2>
		if (!hasConfigurers) {
			WebSecurityConfigurerAdapter adapter = objectObjectPostProcessor
					.postProcess(new WebSecurityConfigurerAdapter() {
					});
			webSecurity.apply(adapter);
		}
        // <3>
		return webSecurity.build();
	}
}
```

* 在 <1> 处，`webSecurityConfigurers` 保存的是容器中收集到的 `WebSecurityConfigurer` 实现类。

  > 很明显，我们自定义的 SecurityConfig 类就是该接口实现类，故在这里被收集到

* 在 <2> 处，如果没有自定义 `WebSecurityConfigurer` 实现类，Spring Security 会有默认的配置的

* 在 <3> 处，重点方法，完成过滤器链的构建

### 2.1 加载我们自定义的配置

继续看 `webSecurity.build();`

```java
protected final O doBuild() throws Exception {
    synchronized (configurers) {
        buildState = BuildState.INITIALIZING;

        beforeInit();
        // <1>
        init();

        buildState = BuildState.CONFIGURING;

        beforeConfigure();
        configure();

        buildState = BuildState.BUILDING;

        O result = performBuild();

        buildState = BuildState.BUILT;

        return result;
    }
}
```

```java
private void init() throws Exception {
    // <1>
    Collection<SecurityConfigurer<O, B>> configurers = getConfigurers();

    for (SecurityConfigurer<O, B> configurer : configurers) {
        // <2>
        configurer.init((B) this);
    }

    for (SecurityConfigurer<O, B> configurer : configurersAddedInInitializing) {
        configurer.init((B) this);
    }
}
```

在 <1> 处，获取到的就是我们自定义的配置 SecurityConfig 类

在 <2> 处，SecurityConfig类是有继承体系的，会先调用父类的方法，最后也会回调我们覆盖的 configure 方法来加载我们定义的配置。

```java
public void init(final WebSecurity web) throws Exception {
    // <1>
    final HttpSecurity http = getHttp();
    // <2>
    web.addSecurityFilterChainBuilder(http).postBuildAction(new Runnable() {
        public void run() {
            FilterSecurityInterceptor securityInterceptor = http
                .getSharedObject(FilterSecurityInterceptor.class);
            web.securityInterceptor(securityInterceptor);
        }
    });
}
```

在 <1> 处，生成 HttpSecurity 类。重点方法

在 <2> 处，把http添加到 filterChain 的 Builder中，稍后会进行build。

继续看 getHttp 方法：

```java
protected final HttpSecurity getHttp() throws Exception {
    if (http != null) {
        return http;
    }

    DefaultAuthenticationEventPublisher eventPublisher = objectPostProcessor
        .postProcess(new DefaultAuthenticationEventPublisher());
    localConfigureAuthenticationBldr.authenticationEventPublisher(eventPublisher);

    // <1>
    AuthenticationManager authenticationManager = authenticationManager();
    authenticationBuilder.parentAuthenticationManager(authenticationManager);
    authenticationBuilder.authenticationEventPublisher(eventPublisher);
    Map<Class<? extends Object>, Object> sharedObjects = createSharedObjects();

    // <2>
    http = new HttpSecurity(objectPostProcessor, authenticationBuilder,
                            sharedObjects);
    // <3>
    if (!disableDefaults) {
        // @formatter:off
        http
            .csrf().and()
            .addFilter(new WebAsyncManagerIntegrationFilter())
            .exceptionHandling().and()
            .headers().and()
            .sessionManagement().and()
            .securityContext().and()
            .requestCache().and()
            .anonymous().and()
            .servletApi().and()
            .apply(new DefaultLoginPageConfigurer<>()).and()
            .logout();
        // @formatter:on
        ClassLoader classLoader = this.context.getClassLoader();
        List<AbstractHttpConfigurer> defaultHttpConfigurers =
            SpringFactoriesLoader.loadFactories(AbstractHttpConfigurer.class, classLoader);

        for (AbstractHttpConfigurer configurer : defaultHttpConfigurers) {
            http.apply(configurer);
        }
    }
    // <4>	处理自定义配置
    configure(http);
    return http;
}
```

在 <1> 处，创建了 AuthenticationManager，他的功能是处理 Authentication 请求（认证请求）

在 <2> 处，用几个对象封装成为了HttpSecurity对象

在 <3> 处，是否禁用了默认的配置

在 <4> 处，会加载我们自定义的 SecurityConfig 类的 Configure 方法

继续看 authenticationManager 方法：

```java
protected AuthenticationManager authenticationManager() throws Exception {
   if (!authenticationManagerInitialized) {
      // <1> 配置 身份验证管理器生成器
      configure(localConfigureAuthenticationBldr);
      // <2> 如果用户没有配置自定义的 身份验证管理器生成器 则为true
      if (disableLocalConfigureAuthenticationBldr) {
         authenticationManager = authenticationConfiguration
               .getAuthenticationManager();
      }
      // <3> 如果用户配置了自定义的 身份验证管理器生成器 则为false
      else {
         authenticationManager = localConfigureAuthenticationBldr.build();
      }
      authenticationManagerInitialized = true;
   }
   return authenticationManager;
}
```

### 2.2 得到了 FilterChainProxy 对象

经过步骤2框架已经加载到我们自定义的配置类 SecurityConfig 了，接下来是如何处理自定义的配置类。在我们的 configure 方法中我们用 `http.xxx`配置了很多条目，实际在底层每个条目都对应一个 `SecurityConfigurer`。

加载完自定义配置后，调用回到如下代码

```java
public void init(final WebSecurity web) throws Exception {
    // <1>
    final HttpSecurity http = getHttp();
    // <2>
    web.addSecurityFilterChainBuilder(http).postBuildAction(new Runnable() {
        public void run() {
            FilterSecurityInterceptor securityInterceptor = http
                .getSharedObject(FilterSecurityInterceptor.class);
            web.securityInterceptor(securityInterceptor);
        }
    });
}
```

看 addSecurityFilterChainBuilder 方法，只是把http添加到 this.securityFilterChainBuilders 中，还没开始构建 filterChain。

```java
public WebSecurity addSecurityFilterChainBuilder(
      SecurityBuilder<? extends SecurityFilterChain> securityFilterChainBuilder) {
   this.securityFilterChainBuilders.add(securityFilterChainBuilder);
   return this;
}
```

调用继续回到如下代码：

```java
protected final O doBuild() throws Exception {
    synchronized (configurers) {
        buildState = BuildState.INITIALIZING;

        beforeInit();
        init();

        buildState = BuildState.CONFIGURING;

        beforeConfigure();
        configure();

        buildState = BuildState.BUILDING;

        O result = performBuild();

        buildState = BuildState.BUILT;

        return result;
    }
}
```

看 performBuild 方法：

```java
protected Filter performBuild() throws Exception {
   // <1>
   for (SecurityBuilder<? extends SecurityFilterChain> securityFilterChainBuilder : securityFilterChainBuilders) {
      securityFilterChains.add(securityFilterChainBuilder.build());
   }
   // <2>
   FilterChainProxy filterChainProxy = new FilterChainProxy(securityFilterChains);
   

   Filter result = filterChainProxy;
    
   postBuildAction.run();
   return result;
}
```

在 <1> 处，通过 build 方法才真正把之前我们自定义的每一项配置条目由 SecurityConfigurer 翻译为 `javax.servlet.Filter`接口。

在 <2> 处，把 securityFilterChains 构建为 **FilterChainProxy 对象并返回。这就是我们要找的过滤器链对象**

### 2.3 执行过滤器链 FilterChainProxy

```java
public void doFilter(ServletRequest request, ServletResponse response,
      FilterChain chain) throws IOException, ServletException {
   boolean clearContext = request.getAttribute(FILTER_APPLIED) == null;
   if (clearContext) {
      try {
         request.setAttribute(FILTER_APPLIED, Boolean.TRUE);
         doFilterInternal(request, response, chain);
      }
      finally {
         SecurityContextHolder.clearContext();
         request.removeAttribute(FILTER_APPLIED);
      }
   }
   else {
      doFilterInternal(request, response, chain);
   }
}
```

doFilterInternal 方法

```java
private void doFilterInternal(ServletRequest request, ServletResponse response,
      FilterChain chain) throws IOException, ServletException {

   // 包装 request
   FirewalledRequest fwRequest = firewall
         .getFirewalledRequest((HttpServletRequest) request);
   // 包装 response
   HttpServletResponse fwResponse = firewall
         .getFirewalledResponse((HttpServletResponse) response);

   // 获取配置的 filters
   List<Filter> filters = getFilters(fwRequest);

   // 把所有的过滤器filters组成一个VirtualFilterChain来执行
   VirtualFilterChain vfc = new VirtualFilterChain(fwRequest, chain, filters);
   vfc.doFilter(fwRequest, fwResponse);
}
```

```java
public void doFilter(ServletRequest request, ServletResponse response)
      throws IOException, ServletException {
   // <1> 是不是最后一个拦截器
   if (currentPosition == size) {

      this.firewalledRequest.reset();

      originalChain.doFilter(request, response);
   }
   else {
      // 位置加一
      currentPosition++;
	  // 获取下一个拦截器
      Filter nextFilter = additionalFilters.get(currentPosition - 1);
	  // 执行拦截器
      nextFilter.doFilter(request, response, this);
   }
}
```

## 3 总结

通过继承 WebSecurityConfigurerAdapter 类实现自定义配置的加载，每一个自定义配置条目都是（SecurityConfigurer），每一个条目都被翻译为 `javax.servlet.Filter`，所有 Filter 组成一个过滤器链（filterChainProxy）；在请求被执行前先执行过滤器链 filterChainProxy。

常见的关键类：

| 类                   | 说明                                                         |
| -------------------- | ------------------------------------------------------------ |
| javax.servlet.Filter | servlet规范定义的类，在请求前被执行                          |
| SecurityConfigurer   | 代表了Spring Security 的每一个配置条目                       |
| FilterChainProxy     | 拦截器链                                                     |
| HttpSecurity         | 用来配置 Security http的                                     |
| WebSecurity          | The WebSecurity is created by WebSecurityConfiguration to create the FilterChainProxy known as the Spring Security Filter Chain (springSecurityFilterChain). The springSecurityFilterChain is the Filter that the DelegatingFilterProxy delegates to. |

