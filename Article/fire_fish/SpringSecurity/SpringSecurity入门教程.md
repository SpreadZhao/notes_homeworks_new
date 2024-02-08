## 什么是SpringSecurity
提供了授权（authorization）和鉴权（authentication）



## 入门案例
https://www.iocoder.cn/Spring-Boot/Spring-Security/?self

步骤如下：
1. web场景下的配置类
```java
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    // ...
}
```
2. 重写 `#configure(AuthenticationManagerBuilder auth) `方法，  实现"鉴权功能"
```java
@Override
protected void configure(AuthenticationManagerBuilder auth) throws Exception {
    auth.
            // <X> 使用内存中的 InMemoryUserDetailsManager
            inMemoryAuthentication()
            // <Y> 不使用 PasswordEncoder 密码编码器
            .passwordEncoder(NoOpPasswordEncoder.getInstance())
            // <Z> 配置 admin 用户
            .withUser("admin").password("admin").roles("ADMIN")
            // <Z> 配置 normal 用户
            .and().withUser("normal").password("normal").roles("NORMAL");
}
```
实际项目中，我们更多采用调用
`AuthenticationManagerBuilder#userDetailsService(userDetailsService) `方法，
使用自定义实现的 `UserDetailsService `实现类，更加**灵活**且**自由**的实现认证的用户信息的读取。

3. 重写` #configure(HttpSecurity http) `方法，主要配置 URL 的权限控制
```java
@Override
protected void configure(HttpSecurity http) throws Exception {
    http
            // <X> 配置请求地址的权限
            .authorizeRequests()
                .antMatchers("/test/echo").permitAll() // 所有用户可访问
                .antMatchers("/test/admin").hasRole("ADMIN") // 需要 ADMIN 角色
                .antMatchers("/test/normal").access("hasRole('ROLE_NORMAL')") // 需要 NORMAL 角色。
                // 任何请求，访问的用户都需要经过认证
                .anyRequest().authenticated()
            .and()
            // <Y> 设置 Form 表单登录
            .formLogin()
//                    .loginPage("/login") // 登录 URL 地址
                .permitAll() // 所有用户可访问
            .and()
            // 配置退出相关
            .logout()
//                    .logoutUrl("/logout") // 退出 URL 地址
                .permitAll(); // 所有用户可访问
}
```
最最最常用的配置
`#(String... antPatterns) `方法，配置匹配的 URL 地址，基于 `Ant 风格路径表达式` ，可传入多个（这个风格必须了解，spring系列中非常常用）

【常用】#permitAll() 方法，所有用户可访问。
【常用】#denyAll() 方法，所有用户不可访问。
【常用】#authenticated() 方法，登录用户可访问。
【常用】#hasRole(String role) 方法， 拥有指定角色的用户可访问。
【常用】#hasAnyRole(String... roles) 方法，拥有指定任一角色的用户可访问。
【常用】#hasAuthority(String authority) 方法，拥有指定权限(authority)的用户可访问。
【常用】#hasAuthority(String... authorities) 方法，拥有指定任一权限(authority)的用户可访问。
【最牛】#access(String attribute) 方法，当 Spring EL 表达式的执行结果为 true 时，可以访问。【等价与注解@PreAuthorize。 预授权】


4. 也可以开启权限的注解配置（更加简单了）
`@PreAuthorize `注解，等价于 `#access(String attribute)` 方法，，当 Spring EL 表达式的执行结果为 true 时，可以访问。
```java
// 如：
@PreAuthorize("hasRole('ROLE_ADMIN')")          // 等价与在配置类中配置中低效的配置授权
@GetMapping("/admin")
public String admin() {
    return "我是管理员";
}
```

