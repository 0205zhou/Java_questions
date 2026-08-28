---
id: q0018
question: "SpringBoot启动时都做了什么？"
category: spring
tags: ["SpringBoot", "启动流程", "ApplicationContext", "内嵌容器"]
difficulty: medium
created: 2026-08-11 00:50:58
source: 用户输入
---

# SpringBoot启动时都做了什么？

---

## 联想记忆法

### 记忆口诀/联想

**口诀:「一创、二备、三刷、四跑,监听全程跑不了」**

> 面试中“SpringBoot 启动流程”和“SpringBoot 启动时都做了什么”通常是同一个问题。回答重点不是罗列 API，而是说清 `SpringApplication.run()` 如何准备环境、创建并刷新容器、启动内嵌服务器，最后执行启动回调。

- **一创**:`new SpringApplication(...)` —— 创建应用实例,先"摸清家底":推断 Web 应用类型(SERVLET / REACTIVE / NONE)、加载初始化器和监听器
- **二备**:准备环境 —— 解析命令行参数、合并系统属性与环境变量、加载 `application.yml`,顺带打印 Banner
- **三刷**:`refreshContext()` 刷新容器 —— **最核心的一步**:解析主配置类、触发自动装配、创建内嵌 Tomcat、实例化单例 Bean
- **四跑**:跑起来 —— 执行 `ApplicationRunner` / `CommandLineRunner` 钩子,业务代码就位
- **监听全程**:`SpringApplicationRunListener` 贯穿始终,每个关键节点发事件:Starting → EnvironmentPrepared → ContextPrepared → ContextLoaded → Started → Ready

再浓缩一句:**「new 一下、run 一路、refresh 一步」** —— 本质就三件事:创建实例、走完 run、刷新容器,其余都是这三件事的细节。

### 记忆原理

用**数字递进编码**:1→2→3→4 四个动作严格按时间顺序排列,每个数字对应"动词+对象"(创建应用、准备环境、刷新容器、执行钩子),最后补一句"监听全程"收尾。数字顺序天然不可逆,背下数字就背下了流程顺序。比起死记 refresh() 的十来个方法,五步主干 + "最核心在刷新"这个锚点,记忆负担小得多,面试时还能顺着数字展开讲细节。

### 关联知识

- **与 Spring Framework 的 refresh 关联**:SpringBoot 启动的本质 = Spring 容器 `refresh()` 模板方法——骨架由 Spring 提供,SpringBoot 只是把内嵌服务器、自动装配等步骤嵌进去
- **与自动装配关联**:`@EnableAutoConfiguration` 的生效时机就在 refresh 的 `invokeBeanFactoryPostProcessors` 阶段,两题常连问
- **与 Spring 事件机制关联**:RunListener 是观察者模式(Observer Pattern)的典型应用,事件发布贯穿启动全程
- **与内嵌容器关联**:Tomcat **不是在 run() 一开始启动的**,而是在 refresh 的 `onRefresh()` 中创建——这是最常见的误解,也是加分点
- **与 Bean 生命周期关联**:单例 Bean 在 `finishBeanFactoryInitialization` 阶段统一实例化(懒加载除外)

---

## 深度解答

### 第一层:核心概念

#### 什么是 SpringBoot 启动流程

**SpringBoot 启动时做的事情，是从 `main` 方法入口到应用对外可用的一整套初始化过程**:创建 `SpringApplication`、准备 Environment、创建并刷新 `ApplicationContext`、启动内嵌服务器、执行启动回调。用一句话概括:

> **启动流程 = 创建一个 Spring 容器 + 准备环境 + 刷新这个容器(创建内嵌 Web 服务器)+ 执行启动钩子。**

传统 SSM 项目需要配置 web.xml、手动注册 DispatcherServlet、装配 Spring 配置文件,步骤繁琐且分散;SpringBoot 把这一切收敛成 `SpringApplication.run()` 一行代码,背后是"约定大于配置"的自动化。

代码入口(几乎所有 SpringBoot 应用都一样):

```java
@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```

从调用关系看，静态方法先创建 `SpringApplication`，再调用它的 `run(args)`；因此“启动”不是只执行一个注解，而是由 `SpringApplication` 编排多个阶段：

```text
main()
  -> SpringApplication.run(source, args)
  -> 创建应用实例并推断 Web 类型
  -> 准备 Environment 和配置
  -> 创建 ApplicationContext
  -> refresh()
       -> 解析配置与自动配置
       -> 注册 BeanPostProcessor
       -> 创建内嵌 WebServer
       -> 实例化非懒加载单例 Bean
  -> 执行 Runner
  -> 发布 ApplicationReadyEvent
```

### 第二层:底层原理

#### 第一步:`new SpringApplication(primarySources)`——创建实例,摸清家底

`run()` 内部首先 `new SpringApplication(...)`,构造器中完成三件事:

1. **推断 Web 应用类型**(`WebApplicationType`):按 classpath 中是否存在对应类决定——
   - 存在 `org.springframework.web.reactive.DispatcherHandler` 且不存在 `spring-webmvc` → `REACTIVE`
   - 存在 `jakarta.servlet.Servlet` 或 `org.springframework.web.context.ConfigurableWebApplicationContext` → `SERVLET`
   - 否则 → `NONE`(纯非 Web 应用)
2. **加载初始化器和监听器**:通过 `SpringFactoriesLoader` 从所有 `META-INF/spring.factories` 中读取 `ApplicationContextInitializer` 和 `ApplicationListener`,拿到系统预置的扩展点
3. **定位主配置类**:从调用栈找到含 `main` 方法的类(即带 `@SpringBootApplication` 的类),作为后续容器配置的起点

#### 第二步:`run()` 执行——环境准备与监听器启动

1. 创建 `SpringApplicationRunListeners`(实现是 `EventPublishingRunListener`),发布 **ApplicationStartingEvent**
2. **准备 Environment**:`DefaultApplicationArguments` 解析命令行参数 → 读取系统属性、系统环境变量 → 通过 `ConfigDataEnvironmentPostProcessor` 加载 `application.properties` / `application.yml`(支持 profile、配置中心),发布 **EnvironmentPreparedEvent**。配置来源会按照优先级合并，命令行参数通常可以覆盖配置文件中的同名属性。
3. **打印 Banner**(可被 `spring.main.banner-mode` 关闭)
4. **创建 ApplicationContext**:按 `WebApplicationType` 选择——SERVLET → `AnnotationConfigServletWebServerApplicationContext`,REACTIVE → `AnnotationConfigReactiveWebServerApplicationContext`,NONE → `AnnotationConfigApplicationContext`
5. **prepareContext 准备上下文**:把主配置类注册成 BeanDefinition、执行 `ApplicationContextInitializer`、注册监听器,发布 **ContextPreparedEvent** 与 **ContextLoadedEvent**。此时容器已经有配置源，但还没有完成完整的 Bean 创建。

#### 第三步:refreshContext——启动流程的心脏

调用 `AbstractApplicationContext.refresh()`(Spring 的模板方法,12 个方法的关键几步):

| 步骤 | 方法 | 做什么 |
|---|---|---|
| ① | `prepareBeanFactory` | 设置 Bean 工厂基础设施(类加载器、SpEL 解析器等) |
| ② | `invokeBeanFactoryPostProcessors` | **`ConfigurationClassPostProcessor` 解析 `@Configuration`**,处理 `@Import` → `@EnableAutoConfiguration` 在此生效(自动装配的入口) |
| ③ | `registerBeanPostProcessors` | 注册 `BeanPostProcessor`(如 AOP、`@Autowired` 处理) |
| ④ | `initMessageSource` / `initApplicationEventMulticaster` | 初始化国际化与事件广播器 |
| ⑤ | `onRefresh` | **ServletWebServerApplicationContext 在这里创建内嵌 Web 服务器**(Tomcat/Jetty/Undertow,由 `WebServerFactory` 自动配置) |
| ⑥ | `finishBeanFactoryInitialization` | **实例化所有非懒加载的单例 Bean** |
| ⑦ | `finishRefresh` | 发布 **ContextRefreshedEvent**,启动完成 |

> 💡 结论:**Tomcat 不是最先启动的,而是在 refresh 到 onRefresh 阶段才创建**——面试高频陷阱。

#### 第四步:启动后钩子

refresh 完成后,`run()` 继续:

1. 调用容器中所有 `ApplicationRunner` 和 `CommandLineRunner`(可用 `@Order` 排序)——常用于预热缓存、初始化数据等
2. 发布 **ApplicationStartedEvent**、**ApplicationReadyEvent**(此时对外宣称"可以接收请求了")
3. 若启动异常,发布 **ApplicationFailedEvent**

#### 完整时序(文字架构图)

```
main() → new SpringApplication(推断类型/加载initializer+listener/定位主类)
  → run():
    [Starting] 创建 RunListeners
    → 准备 Environment + 加载配置文件 [EnvironmentPrepared]
    → 打印 Banner
    → 创建 ApplicationContext
    → prepareContext 注册主类/执行 Initializer [ContextPrepared][ContextLoaded]
    → refreshContext:
        invokeBeanFactoryPostProcessors(解析配置类与自动配置)
        registerBeanPostProcessors
        onRefresh(创建并启动内嵌 Tomcat)
        finishBeanFactoryInitialization(实例化单例)
        finishRefresh [ContextRefreshed]
    → 执行 ApplicationRunner / CommandLineRunner
    → 执行 Runner → [Started] → [Ready] 应用对外可用
```

### 第三层:实践应用

#### 在启动流程上挂"钩子"的四种姿势

| 扩展点 | 时机 | 适用场景 |
|---|---|---|
| `SpringApplicationRunListener` | 启动全程各节点 | 做监控、埋点、环境审计(需注册到 spring.factories) |
| `ApplicationRunner` / `CommandLineRunner` | 容器刷新完成后 | 初始化数据、预热缓存、启动后自检 |
| `ApplicationContextInitializer` | 上下文创建后、refresh 前 | 提前注入属性、自定义 Environment |
| `@PostConstruct` / `InitializingBean` | 单例 Bean 实例化时 | 依赖注入完成后的初始化 |

示例:启动后加载字典缓存

```java
@Component
public class CacheWarmer implements ApplicationRunner {
    @Override
    public void run(ApplicationArguments args) {
        System.out.println("预热字典缓存...");
    }
}
```

#### 排查启动慢

- 开启懒加载:`spring.main.lazy-initialization=true`(大面积 @Lazy,首次访问才初始化)
- 在 `application.yml` 加 `debug=true` 查看自动配置与启动耗时明细
- 用 `SpringApplicationRunListener` 打点,定位每个阶段耗时

### 第四层:深入思考

- **为什么设计成模板方法 + 事件两套机制?** `refresh()` 模板方法固定流程骨架,子类只需覆写关键步骤(`onRefresh` 挂服务器);RunListener 事件则把"过程观察"从流程中解耦出来,两者叠加让框架既可扩展又不过度耦合
- **SpringBoot 3.x 有什么变化?** 启动流程整体不变,但 `spring.factories` 已被 `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports` 取代;同时支持 GraalVM native image,构建期完成初始化,运行期不再有"启动流程"
- **面试追问方向**:启动流程与自动装配的关系?内嵌 Tomcat 在哪一步启动?refresh() 为什么要抛异常回滚?Spring 的事件和 SpringBoot 的启动事件有什么区别?

---

## 回答思路

### 答题逻辑框架

建议按"**总—分—总**"展开(约 3~4 分钟):

1. **一句话总览**:启动流程本质是"创建一个 Spring 容器并刷新它",一行 `SpringApplication.run()` 背后是环境准备、容器刷新、服务器启动三步
2. **分步展开**:按"一创二备三刷四跑"讲,重点砸在**第三步 refresh**——讲清 `invokeBeanFactoryPostProcessors`(自动装配)、`onRefresh`(内嵌服务器)、`finishBeanFactoryInitialization`(单例实例化)三个子步骤
3. **收尾升华**:补上 RunListener 事件链与 Runner 钩子,说明整个流程"可观测、可扩展"

### 重点得分点

- ✅ 说出 `WebApplicationType` 推断(SERVLET/REACTIVE/NONE)
- ✅ 说出 **Tomcat 在 refresh 的 onRefresh 阶段创建**,而不是启动第一步
- ✅ 说出 `invokeBeanFactoryPostProcessors` 是自动装配生效的位置(联动自动装配原理题)
- ✅ 说出事件链 Starting → EnvironmentPrepared → ContextPrepared → ContextLoaded → Started → Ready
- ✅ 说出 ApplicationRunner 与 CommandLineRunner 的区别(前者拿封装好的 Arguments,后者拿原始 args)

### 常见误区

- ❌ "Tomcat 在 main 之后立刻启动" → 错,在 refresh 的 onRefresh
- ❌ "refresh() 是 SpringBoot 的方法" → 错,是 Spring Framework `AbstractApplicationContext` 的模板方法
- ❌ 把 `ApplicationListener`(容器事件)和 `SpringApplicationRunListener`(启动过程事件)混为一谈
- ❌ 只背步骤名,说不出每个步骤"为什么存在"

### 过渡话术

- 引出自动装配:"启动流程中最关键的一步是 refresh,而自动装配正是在 refresh 的 BeanFactory 后置处理阶段完成的,下面展开讲讲自动装配的原理……"

### 时间分配建议

- 总览 20 秒 → 分步(创建/环境 1 分钟 + refresh 2 分钟)→ 收尾(事件与钩子 40 秒)→ 追问互动 30 秒

---

> 📋 **分类**: spring
> 🏷️ **标签**: `SpringBoot`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-11 00:50:58
