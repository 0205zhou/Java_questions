---
id: q0019
question: "SpringBoot自动装配原理"
category: spring
tags: ["SpringBoot"]
difficulty: medium
created: 2026-08-11 00:51:53
source: 用户输入
---

# SpringBoot自动装配原理

---

## 联想记忆法

### 记忆口诀/联想

**口诀:「启、导、读、滤、装」——自动装配五步流水线**

- **启**:`@EnableAutoConfiguration` 注解按下"自动装配启动键"
- **导**:它内部通过 `@Import(AutoConfigurationImportSelector.class)` 导入一个**选择器**(ImportSelector),把"该装配什么"的决策交给它
- **读**:选择器的 `getCandidateConfigurations()` 读取 `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`(Boot 2.7+;老版本读 spring.factories),拿到**全部候选自动配置类名单**(100+ 个)
- **滤**:逐个用 `@ConditionalOnClass` / `@ConditionalOnMissingBean` / `@ConditionalOnProperty` 等**条件注解过滤**,条件不满足的直接淘汰
- **装**:通过的配置类被当成 `@Configuration` 导入容器,**注册对应 Bean**(如没有用户自定义时装配 Tomcat、DataSource)

再配一句:**「用户 Bean 优先,条件不全不装」**——`@ConditionalOnMissingBean` 保证了"你写过就不重复装"。

### 记忆原理

五个单字动词"**启导读滤装**"构成一条工厂流水线:启动按钮 → 传送带(选择器)→ 货单(imports 文件)→ 质检(条件注解)→ 入库(注册 Bean)。每个字对应一个明确机制,顺序就是源码调用顺序。用"流水线"这种具象场景编码五个抽象组件,比死记类名好记得多;类名只作为每个环节的"零件名"挂靠上去即可。

### 关联知识

- **与启动流程关联**:自动装配生效于 refresh 的 `invokeBeanFactoryPostProcessors` 阶段(ConfigurationClassPostProcessor 解析 @Configuration 时)
- **与 @Import 机制关联**:`@EnableAutoConfiguration` 本质是 @Import 的高级用法,类似 `@EnableAsync`、`@EnableScheduling`——理解 @Import 就理解了自动装配的入口
- **与 SPI 思想关联**:AutoConfiguration.imports / spring.factories 就是 Spring 生态的 SPI(Service Provider Interface),"按声明注册、按条件加载"
- **与自定义 starter 关联**:写自定义 starter 时同样要提供 AutoConfiguration.imports + 条件注解——自动装配原理就是 starter 的"魂"
- **与 Condition 接口关联**:所有 @ConditionalOnXxx 底层都实现 Spring 的 Condition 接口,在 BeanDefinition 注册阶段判定

---

## 深度解答

### 第一层:核心概念

#### 什么是自动装配

**自动装配(Auto-Configuration)指 SpringBoot 根据 classpath 依赖、配置文件与已有 Bean,自动创建一组"合理默认"的 Bean 和配置**,让开发者"引入依赖即能用"。核心思想是**约定大于配置(Convention over Configuration)**:

- 引入 `spring-boot-starter-web` → 自动配置内嵌 Tomcat、DispatcherServlet、Jackson
- 引入 `spring-boot-starter-jdbc` + 数据源依赖 → 自动配置 DataSource、JdbcTemplate
- 不满足默认需求时,用条件注解 + 用户 Bean 覆盖,无需删框架代码

`@SpringBootApplication` 是一个组合注解,拆开看就是启动流程与自动装配的钥匙:

```java
@SpringBootConfiguration   // 本身是 @Configuration,标记当前类为配置类
@EnableAutoConfiguration   // ★ 自动装配的入口
@ComponentScan(...)        // 扫描主类所在包及其子包的组件
```

### 第二层:底层原理

#### 环节 1:入口——@EnableAutoConfiguration 与 @Import

`@EnableAutoConfiguration` 注解上有一个关键注解:

```java
@Import(AutoConfigurationImportSelector.class)
public @interface EnableAutoConfiguration { ... }
```

`@Import` 会把 `AutoConfigurationImportSelector` 导入容器。由于它实现了 `ImportSelector` 接口,Spring 在解析配置类时会调用它的 `selectImports()` 方法,返回值(String[] 类名)**在运行时才确定要导入哪些类**——这就是"选择器"的含金量:静态 @Import 只能写死,选择器可以动态决策。

#### 环节 2:读取候选——候选名单从哪来

`AutoConfigurationImportSelector.getCandidateConfigurations()` 的核心逻辑:

```java
List<String> configurations = SpringFactoriesLoader.loadFactoryNames(
        getSpringFactoriesLoaderFactoryClass(), getBeanClassLoader());
```

- Boot **2.7+ / 3.x**:读取所有 jar 中的 `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`,每行一个自动配置类全限定名
- Boot **2.7 之前**:读取 `META-INF/spring.factories` 中 `EnableAutoConfiguration` 键对应的列表

拿到的是一份**全量候选清单**,例如 `DataSourceAutoConfiguration`、`ServletWebServerFactoryAutoConfiguration`、`MybatisAutoConfiguration` 等,这些类遍布依赖 jar 中,应用本身无需显式 import 任何框架类。

#### 环节 3:过滤——条件注解把关

候选不能全装,否则引入一个无关依赖也会多出无用 Bean。`AutoConfigurationImportSelector` 通过 `AutoConfigurationImportFilter`(默认 `OnClassCondition` 等)先做**粗过滤**:候选类上的 `@ConditionalOnClass` 标注的类不存在于 classpath → 直接移除(这一步发生在"真正解析配置"之前,避免加载不必要的类)。

进入容器后,每个自动配置类身上还有**细粒度条件注解**(都基于 Spring 的 `Condition` 接口,在注册 BeanDefinition 阶段调用 `matches()` 判断):

| 条件注解 | 判定依据 | 典型用途 |
|---|---|---|
| `@ConditionalOnClass` / `@ConditionalOnMissingClass` | classpath 是否存在某类 | 引入依赖才装配 |
| `@ConditionalOnBean` / `@ConditionalOnMissingBean` | 容器中是否已有某 Bean | **用户自定义优先** |
| `@ConditionalOnProperty` | 配置项是否存在/等于某值 | `spring.datasource.*` 开关 |
| `@ConditionalOnWebApplication` | 是否 Web 应用 | Web 相关配置 |
| `@ConditionalOnExpression` | SpEL 表达式 | 复杂组合条件 |

以 `RedisAutoConfiguration` 为例:

```java
@AutoConfiguration
@ConditionalOnClass(RedisOperations.class)          // 没有 redis 依赖就不装配
@ConditionalOnMissingBean(RedisConnectionFactory.class)  // 用户配过就用用户的
public class RedisAutoConfiguration { ... }
```

#### 环节 4:排序与生效

自动配置类之间也有依赖关系,通过 `@AutoConfigureBefore` / `@AutoConfigureAfter` / `@AutoConfigureOrder` 声明顺序,`AutoConfigurationSorter` 负责拓扑排序,保证如"先配数据源再配 MyBatis"。

#### 环节 5:如何观察"到底装配了什么"

`application.yml` 设置 `debug=true`,启动日志会打印 **Positive matches / Negative matches / Exclusions** 三段条件评估报告——面试官常问"你怎么排查自动配置是否生效",这就是标准答案。

#### 用户如何覆盖自动配置

1. `exclude` 排除:`@SpringBootApplication(exclude = DataSourceAutoConfiguration.class)`
2. 配置排除:`spring.autoconfigure.exclude=xxx`
3. **推荐**:自己写一个同类型 Bean 让 `@ConditionalOnMissingBean` 失效(如自定义 `RedisConnectionFactory`)

### 第三层:实践应用

#### 手写一个自动配置(starter 雏形)

```java
// 1. 自动配置类
@AutoConfiguration
@ConditionalOnClass(MyService.class)
@ConditionalOnProperty(prefix = "my.service", name = "enabled", havingValue = "true", matchIfMissing = true)
@EnableConfigurationProperties(MyProperties.class)   // 绑定 my.service.* 配置
public class MyServiceAutoConfiguration {
    @Bean
    @ConditionalOnMissingBean
    public MyService myService(MyProperties props) {
        return new MyService(props.getUrl());
    }
}
```

```java
// 2. 注册候选(必须,否则 SpringBoot 不知道这个自动配置类存在)
// META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports:
// com.example.autoconfigure.MyServiceAutoConfiguration
```

```java
// 3. 属性绑定类
@ConfigurationProperties(prefix = "my.service")
public class MyProperties {
    private String url = "http://default";
    // getter / setter ...
}
```

用户只要在依赖里加上这个 jar,再在 yml 里写 `my.service.url=xxx`,无需任何显式配置即可使用——这就是 starter 的全部秘密。

#### 常见 starter 的自动配置长什么样

- `spring-boot-starter-web` → `ServletWebServerFactoryAutoConfiguration`(内嵌 Tomcat)+ `DispatcherServletAutoConfiguration`(DispatcherServlet)
- `mybatis-spring-boot-starter` → `MybatisAutoConfiguration`(`@ConditionalOnClass(SqlSessionFactory.class)`,装配 SqlSessionFactory、MapperScannerConfigurer)
- `spring-boot-starter-redis` → `RedisAutoConfiguration`(Lettuce 连接工厂 + StringRedisTemplate)

### 第四层:深入思考

- **为什么不直接加载全部配置类?** 全部加载会让启动变慢、Bean 冗余且可能冲突;条件注解把"判定"推迟到运行时,实现按需装配,是"空间换时间"在依赖管理上的体现
- **与 Spring Framework 的 @EnableXxx 对比**:`@EnableAsync` 等也是 @Import 一个选择器/配置类,但**数量有限、写死导入**;SpringBoot 把这一模式系统化为"SPI 文件 + 全量候选 + 条件过滤",本质是同一个机制的量产版
- **演进过程**:spring.factories(2.7 前)→ AutoConfiguration.imports(2.7 引入、3.0 强制),动机是 spring.factories 中混合了多种工厂类型、难以按模块独立发布;同时 3.x 也移除了部分无条件的配置类
- **性能代价**:每次启动都要扫描所有 jar 的 imports 文件并对 100+ 候选做条件评估,有 `spring.autoconfigure.exclude` 这类"减负"手段
- **追问方向**:@ConditionalOnMissingBean 失效场景?条件注解和 @Profile 的区别?如何实现自定义 Condition?

---

## 回答思路

### 答题逻辑框架

按"**入口 → 决策 → 过滤 → 落地**"四步讲(约 3~4 分钟):

1. **先讲结论**:自动装配 = "依赖引入即生效",靠 @EnableAutoConfiguration 打开开关
2. **拆注解**:@SpringBootApplication 组合注解 → @EnableAutoConfiguration → @Import(AutoConfigurationImportSelector)
3. **讲选择器**:读 AutoConfiguration.imports 拿全量候选(这里可提 spring.factories 的版本演进,加分)
4. **讲条件注解**:重点举 @ConditionalOnClass(有依赖才装)和 @ConditionalOnMissingBean(用户优先)两个例子,顺带讲 debug=true 查看评估报告

### 重点得分点

- ✅ 说出 @Import + ImportSelector 这个"动态导入"机制
- ✅ 说出候选名单来源文件(AutoConfiguration.imports / spring.factories)与版本差异
- ✅ 说出两个以上 @ConditionalOnXxx 并解释语义
- ✅ 说出"用户自定义 Bean 优先"是靠 @ConditionalOnMissingBean 实现的
- ✅ 能现场写出自定义 starter 的三件套(自动配置类 + imports 文件 + 属性绑定)

### 常见误区

- ❌ "自动装配 = @ComponentScan" → 错,ComponentScan 扫的是用户包,自动装配扫的是依赖 jar 的 SPI 文件
- ❌ "所有自动配置类都会被加载" → 错,条件注解过滤,debug=true 可看 Negative matches
- ❌ 以为 @SpringBootApplication 是一个独立注解 → 是组合注解(@SpringBootConfiguration + @EnableAutoConfiguration + @ComponentScan)
- ❌ 说不出如何排查"为什么我的配置没生效"(标准答案:exclude 检查 + debug=true 条件报告)

### 过渡话术

- 引出 MyBatis:"自动装配解决的是'Bean 从哪来',而 MyBatis 解决的是'SQL 怎么执行'——它的 SqlSessionFactory 正是通过 MybatisAutoConfiguration 装配进来的,下面讲 MyBatis 把一条 SQL 执行出来的完整链路……"

### 时间分配建议

- 结论 + 拆注解 1 分钟 → 选择器与 SPI 文件 1 分钟 → 条件注解 1 分钟 → 自定义 starter 演示 + 收尾 1 分钟

---

> 📋 **分类**: spring
> 🏷️ **标签**: `SpringBoot`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-11 00:51:53
