## 什么是Sentinel
Sentinel译为“哨兵”，是阿里开源的项目。
随着微服务的流行，服务和服务之间的稳定性变得越来越重要。<a href="https://sentinelguard.io/">Sentinel</a> 以流量为切入点，从流量控制、流量路由、熔断降级、系统自适应过载保护、热点流量防护等多个维度保护服务的稳定性。

## 典型应用场景
1. MQ中消息在某些时间段（比如行情交易的高峰期，秒杀期等）消息并发量非常大时，
   通过Sentinel起到“削峰填谷”的作用；
2. 某个业某个业务服务非常复杂，需要调用大量微服务，其中某服务不可用时，不影响整体业务运行，
   如提交某个订单，需要调用诸如验证库存，验证优惠金额，支付，验证手机号等，其中验证手机号服务不可用时，采用**降级**的方式让其通过，不影响整个提交订单的业务；
3. 上述订单业务提交时，依赖的下游应用控制线程数，请求上下文超过阈值时，新的请求立即拒绝，即针对**流控**，可基于QPS或线程数在某些业务场景下，都会有用，如下就是一个qps瞬时拉大时，通过流量缓慢增加，避免系统被压垮的情况：

所以Sentinel的典型应用就是**流量控制**和**服务降级熔断**

## Sentinel 具有以下特征
* **丰富的应用场景**：Sentinel 承接了阿里巴巴近 10 年的双十一大促流量的核心场景，例如秒杀（即突发流量控制在系统容量可以承受的范围）、消息削峰填谷、集群流量控制、实时熔断下游不可用应用等。
* **完备的实时监控**：Sentinel 同时提供实时的监控功能。您可以在控制台中看到接入应用的单台机器秒级数据，甚至 500 台以下规模的集群的汇总运行情况。
* <mark>**广泛的开源生态**</mark>：Sentinel 提供开箱即用的与其它开源框架/库的整合模块，例如与 Spring Cloud、Apache Dubbo、gRPC、Quarkus 的整合。您只需要引入相应的依赖并进行简单的配置即可快速地接入 Sentinel。同时 Sentinel 提供 Java/Go/C++ 等多语言的原生实现。
* **完善的 SPI 扩展机制**：Sentinel 提供简单易用、完善的 SPI 扩展接口。您可以通过实现扩展接口来快速地定制逻辑。例如定制规则管理、适配动态数据源等。

在以上特征中，<mark>无疑于开发相关最紧密的就是Sentinel提供了广泛的开源生态的结合</mark>，可以非常方便的与Spring Cloud、Apache Dubbo等结合使用

## 如何使用
重要的事情说3遍。**版本一致性**、**版本一致性**、**版本一致性**必须说一下。
* Sentinel核心与开源生态要兼容。
* Sentinel和Sentinel Dashboard版本务必一样

### 项目中使用Sentinel
即**Sentinel** + **Sentinel Dashboard** + **广泛的开源生态**（<mark>推荐</mark>）。Sentinel针对各个主流框架都提供了适配（包括Servlet，Dubbo，SpringBoot/SpringCloud，gRPC，RocketMQ等），
本文以SpringBoot2举例（通过笔者测试发现，SpringBoot 1.x支持不好，自定义流控规则不可用），
首先我们需要确定好我们使用的版本

1. 首先确定版本（先定好兼容的Spring Cloud、Spring Boot、Spring Cloud Alibaba）。
如下笔者已经根据Spring Cloud官方推荐确定好了boot、cloud、alibaba的版本。
```xml
<!-- Spring Boot的版本-->
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>2.2.5.RELEASE</version>
    <relativePath/> <!-- lookup parent from repository -->
</parent>

<dependencies>
    <dependency>
        <groupId>com.alibaba.cloud</groupId>
        <artifactId>spring-cloud-starter-alibaba-sentinel</artifactId>
    </dependency>
</dependencies>
<dependencyManagement>
    <dependencies>
        <!-- Spring Cloud的版本 -->
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-dependencies</artifactId>
            <version>Hoxton.SR3</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
        <!-- Spring Cloud的版本 -->
        <dependency>
            <groupId>com.alibaba.cloud</groupId>
            <artifactId>spring-cloud-alibaba-dependencies</artifactId>
            <version>2.2.1.RELEASE</version>
            <type>pom</type>
            <scope>import</scope>
        </dependency>
    </dependencies>
</dependencyManagement>

```
2. 确定 Sentinel 的版本

依据Spring Cloud Alibaba的版本然后就可以知道Sentinel的版本（如上文为Sentinel 1.7.1），
下载对应的`Sentinel Dashboard 1.7.1`版本。

3. 部署 Sentinel Dashboard
```shell
java -Dserver.port=8888 -Dcsp.sentinel.dashboard.server=localhost:8888 -Dproject.name=sentinel-dashboard -jar sentinel-dashboard.jar
```

4. 定义项目链接Sentinel的配置文件，即application.yml文件，如下：
```yaml
project:
  name: 在控制台显示的项目名
spring:
  cloud:
    sentinel:
      transport:
        dashboard: localhost:8888
```
5. 在项目中加入依赖

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-alibaba-sentinel</artifactId>
</dependency>
```
6. 至此环境准备好了


#### 基本使用 - 资源与规则
##### 资源定义
关于资源定义采用**主流框架的默认适配 + 注解方式定义资源**就足够了。
<a href="https://sentinelguard.io/zh-cn/docs/basic-api-resource-rule.html">官方资源定义的各种方式</a>
>在Java代码中，通过`@SentinelResource("test")`来定义服务对应的资源名，如果不指数，URI即为资源名。

##### 规则的种类
Sentinel 支持以下几种规则：**流量控制规则**、**熔断降级规则**、**系统保护规则**、**来源访问控制规则** 和 **热点参数规则**。
* 流量控制规则 (FlowRule)
* 熔断降级规则 (DegradeRule)
* 系统保护规则 (SystemRule)
* 访问控制规则 (AuthorityRule)
* 热点规则 (ParamFlowRule)

#### 流量控制
流量控制规则定义如下：
![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20221023_2.png)
可基于QPS/并发数的流量控制两种方式来定义

指定并发线程数限流时，用于保护业务线程数不被耗尽。例如，当应用所依赖的下游应用由于某种原因导致服务不稳定、响应延迟增加，对于调用者来说，意味着吞吐量下降和更多的线程数占用，极端情况下甚至导致线程池耗尽。

指定QPS流量控制时，当 QPS 超过某个阈值的时候，则采取措施进行流量控制。针对QPS，提供了3种流量控制手段
1. 直接拒绝。该方式是默认的流量控制方式，当QPS超过任意规则的阈值后，新的请求就会被立即拒绝，拒绝方式为抛出FlowException。这种方式适用于对系统处理能力确切已知的情况下，比如通过压测确定了系统的准确水位时。
2. 冷启动。该方式主要用于系统长期处于低水位的情况下，当流量突然增加时，直接把系统拉升到高水位可能瞬间把系统压垮。通过"冷启动"，让通过的流量缓慢增加，在一定时间内逐渐增加到阈值上限，给冷系统一个预热的时间，避免冷系统被压垮的情况。
3. 匀速器。这种方式严格控制了请求通过的间隔时间，也即是让请求以均匀的速度通过，对应的是漏桶算法。

#### 熔断降级
降级规则定义如下：
![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20221023_3.png)

可基于慢调用比例、异常比例、异常数 3种方式来定义
1. 慢调用比例 (SLOW_REQUEST_RATIO)：选择以慢调用比例作为阈值，需要设置允许的慢调用 RT（即最大的响应时间），请求的响应时间大于该值则统计为慢调用。当单位统计时长（statIntervalMs）内请求数目大于设置的最小请求数目，并且慢调用的比例大于阈值，则接下来的熔断时长内请求会自动被熔断。经过熔断时长后熔断器会进入探测恢复状态（HALF-OPEN 状态），若接下来的一个请求响应时间小于设置的慢调用 RT 则结束熔断，若大于设置的慢调用 RT 则会再次被熔断。
2. 异常比例 (ERROR_RATIO)：当单位统计时长（statIntervalMs）内请求数目大于设置的最小请求数目，并且异常的比例大于阈值，则接下来的熔断时长内请求会自动被熔断。经过熔断时长后熔断器会进入探测恢复状态（HALF-OPEN 状态），若接下来的一个请求成功完成（没有错误）则结束熔断，否则会再次被熔断。异常比率的阈值范围是 [0.0, 1.0]，代表 0% - 100%。
3. 异常数 (ERROR_COUNT)：当单位统计时长内的异常数目超过阈值之后会自动进行熔断。经过熔断时长后熔断器会进入探测恢复状态（HALF-OPEN 状态），若接下来的一个请求成功完成（没有错误）则结束熔断，否则会再次被熔断。

#### 热点参数限流
何为热点？热点即经常访问的数据。很多时候我们希望统计某个热点数据中访问频次最高的 Top K 数据，并对其访问进行限制。比如：

* 商品 ID 为参数，统计一段时间内最常购买的商品 ID 并进行限制
* 用户 ID 为参数，针对一段时间内频繁访问的用户 ID 进行限制
![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/sentinel-hot-param-overview-1.png)

热点参数限流会统计传入参数中的热点参数，并根据配置的限流阈值与模式，对包含热点参数的资源调用进行限流。热点参数限流可以看做是一种特殊的流量控制，仅对包含热点参数的资源调用生效。

Sentinel Parameter Flow Control

Sentinel 利用 LRU 策略统计最近最常访问的热点参数，结合令牌桶算法来进行参数级别的流控。

#### @SentinelResource 注解
该注解负责定义sentinel的资源和对应的处理方式
fallback：  只只负责业务异常的处理
blockHandler： 只只负责sentinel控制台配置违规

### 不遵守版本一致性的错误举例
在Sentinel 采用的是1.7.0 版本， Sentinel Dashboard 是1.7.1版本下，在Sentinel Dashboard设置流控规则时报错如下：
![](https://firefish-dev-images.oss-cn-hangzhou.aliyuncs.com/dev-images/Snip20221023_6.png)
而Sentinel Dashboard 日志报错为：
```log
com.alibaba.csp.sentinel.dashboard.client.CommandFailedException: invalid type。
```

本质上就是没有控制好Sentinel 和 Sentinel Dashboard的版本一致性。有兴趣可以看看官方的<a href="https://github.com/alibaba/Sentinel/issues/924"> issue </a>


## 相关官方网址
* Sentinel 社区官方网站：https://sentinelguard.io/