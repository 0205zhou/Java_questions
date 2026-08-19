---
id: q0058
question: "MyBatis中有哪些设计模式?"
category: mybatis
tags: ["MyBatis", "设计模式"]
difficulty: medium
created: 2026-08-20 00:00:00
source: 用户输入
---

# MyBatis中有哪些设计模式?

---

## 联想记忆法

### 记忆口诀/联想

**口诀："代理接接口，工厂造会话；模板定流程，建造组配置；装饰套插件，责任链过拦截，策略选执行"。**

- **代理接接口**：`MapperProxy` 用 JDK 动态代理，让没有实现类的 Mapper 接口可以直接调用。
- **工厂造会话**：`SqlSessionFactory`、`MapperProxyFactory` 负责创建会话和 Mapper 代理。
- **模板定流程**：`BaseExecutor`、`SimpleExecutor` 等围绕固定执行流程扩展。
- **建造组配置**：`SqlSessionFactoryBuilder` 逐步构建复杂的 `Configuration` 和 `SqlSessionFactory`。
- **装饰套插件**：MyBatis 插件通过代理包装 Executor、StatementHandler 等核心对象。
- **责任链过拦截**：多个 Interceptor 按顺序组成拦截链。
- **策略选执行**：不同 Executor、缓存实现和日志实现可以按配置替换。

面试时可以先说：**MyBatis 不是只用了一个模式，而是用工厂和建造者完成初始化，用代理解决 Mapper 调用，再用模板方法、装饰器、责任链和策略模式支撑 SQL 执行与扩展。**

### 记忆原理

按照“启动 → 调用 → 执行 → 扩展”的生命周期记忆：启动时 Builder 负责组装配置，Factory 负责生产对象；调用时 Proxy 把接口方法翻译为 `MappedStatement`；执行时 Template 固定流程、Strategy 选择实现；扩展时 Decorator 和 Chain 把插件插入调用链。模式名不再是孤立清单，而是和一条 SQL 的生命周期绑定。

### 关联知识

- `MapperProxy` 与 Spring AOP 的 JDK 动态代理都基于 `Proxy` 和 `InvocationHandler`。
- `SqlSessionFactory` 是 MyBatis 与 Spring Boot 自动装配的核心产物。
- `Executor` 上挂着一级缓存，二级缓存通过装饰器包装 Executor。
- MyBatis 插件只拦截四类核心对象，分页插件通常拦截 `StatementHandler`。
- `MappedStatement`、`Configuration` 和 `TypeHandler` 共同完成从 Java 方法到 JDBC 调用的转换。

---

## 深度解答

### 第一层：核心概念

MyBatis 是半自动化持久层框架。开发者负责 SQL，框架负责连接管理、参数绑定、结果映射和缓存。它的设计模式主要服务于两个目标：**把 JDBC 的固定样板流程封装起来，同时保留 SQL 和执行策略的扩展能力。**

#### 1. 代理模式：Mapper 接口为什么能直接调用

```java
UserMapper mapper = sqlSession.getMapper(UserMapper.class);
User user = mapper.selectById(1L);
```

`UserMapper` 通常只有接口，没有手写实现类。`getMapper` 返回的是 `MapperProxy` 代理对象。调用 `selectById` 时，代理根据接口全限定名和方法名拼出 `namespace + id`，从 `Configuration` 中找到 `MappedStatement`，再调用 `SqlSession.selectOne`。

因此 Mapper 代理解决的是“面向接口编程，但又不想为每条 SQL 手写实现类”的问题。

#### 2. 工厂模式：统一生产框架对象

`SqlSessionFactory` 根据全局配置创建 `SqlSession`；`MapperProxyFactory` 创建指定 Mapper 接口的代理；`ObjectFactory` 创建结果对象；`DataSourceFactory` 创建数据源。这些工厂把对象创建逻辑集中管理，使调用方不需要了解构造参数、生命周期和具体实现。

要区分：`SqlSessionFactory` 是生产 SqlSession 的工厂，不是每次查询都创建一个新工厂。工厂通常在应用启动时创建并长期复用，SqlSession 则应按请求或事务范围获取。

#### 3. 建造者模式：构建复杂配置对象

```java
SqlSessionFactory factory = new SqlSessionFactoryBuilder().build(inputStream);
```

解析 XML、环境、数据源、事务管理器、Mapper、类型别名和插件的步骤很多，而且存在默认值和可选分支。`XMLConfigBuilder`、`XMLMapperBuilder` 等解析器分阶段读取配置，最后由 `SqlSessionFactoryBuilder` 组装 `Configuration` 并构建工厂。

建造者模式把复杂对象的构建过程与最终对象分离，避免调用方直接面对大量构造参数，也方便在不同配置来源之间复用解析流程。

### 第二层：底层原理

#### 4. 模板方法模式：固定 JDBC 执行骨架

MyBatis 的 `BaseExecutor` 把查询、更新、提交、回滚、关闭等公共步骤抽出，具体 Executor 再决定是否批处理或复用 Statement。一次查询大致遵循：

```text
Executor.query
  → 一级缓存检查
  → 生成 CacheKey
  → doQuery
  → StatementHandler.prepare
  → ParameterHandler.setParameters
  → JDBC execute
  → ResultSetHandler.handleResultSets
  → 写回缓存
```

公共骨架固定，变化点由 `SimpleExecutor`、`ReuseExecutor`、`BatchExecutor` 实现。这是模板方法思想：稳定流程由抽象层控制，具体步骤由子类提供。

#### 5. 装饰器模式：缓存和插件如何叠加

MyBatis 不必修改原始 Executor，就能给它增加缓存能力。`CachingExecutor` 持有一个真正的 Executor，在调用前后加入二级缓存逻辑，这就是典型的对象组合式装饰。

插件也采用类似思想。MyBatis 读取 `@Intercepts` 注解后，通过 `Plugin.wrap` 对目标对象创建代理。多个插件可以逐层包装：

```text
业务代码
  ↓
插件代理 A
  ↓
插件代理 B
  ↓
CachingExecutor
  ↓
SimpleExecutor
```

装饰器适合动态叠加职责，缓存、分页、审计、SQL 改写等能力可以独立开关。

#### 6. 责任链模式：多个拦截器依次执行

多个 Interceptor 注册后，MyBatis 将它们保存到 `InterceptorChain`。创建 Executor 或 StatementHandler 时，链条按注册顺序调用 `pluginAll`，每个插件决定执行前置逻辑、目标调用和后置逻辑。任一环节都可以修改参数、记录耗时，甚至阻止后续调用。

责任链让插件之间解耦：分页插件不需要知道审计插件的实现，框架也不必把所有扩展逻辑写死在核心代码中。

#### 7. 策略模式：可替换的执行策略

`ExecutorType.SIMPLE`、`REUSE`、`BATCH` 对应不同的 SQL 执行策略：普通执行、复用 PreparedStatement、批量执行。缓存、日志、事务管理器和语言驱动也都通过接口提供多种实现。

策略模式的关键是：调用方依赖稳定抽象，具体算法在运行时由配置或工厂选择。例如批量导入可以使用 `BATCH`，普通查询则使用 `SIMPLE`，上层 Mapper 代码无需改变。

### 第三层：实践应用

#### 查看 Mapper 调用链

```java
try (SqlSession session = sqlSessionFactory.openSession()) {
    UserMapper mapper = session.getMapper(UserMapper.class);
    User user = mapper.selectById(1L);
    session.commit();
}
```

在 Spring 中通常由 `SqlSessionTemplate` 管理 SqlSession 生命周期，业务代码只注入 Mapper。需要注意：SqlSession 不是线程安全对象，不应作为单例字段共享；SqlSessionFactory 才适合应用级复用。

#### 编写一个插件时的切入点

```java
@Intercepts(@Signature(
        type = StatementHandler.class,
        method = "prepare",
        args = {Connection.class, Integer.class}))
public class TimingInterceptor implements Interceptor {
    @Override
    public Object intercept(Invocation invocation) throws Throwable {
        long start = System.nanoTime();
        try {
            return invocation.proceed();
        } finally {
            System.out.println("耗时: " + (System.nanoTime() - start));
        }
    }
}
```

插件必须明确目标类型、方法和参数签名。`invocation.proceed()` 是责任链继续向下传递的关键；忘记调用它会直接截断 SQL 执行。

### 第四层：深入思考

- **代理与装饰器的区别**：两者都能包装对象，但代理更强调控制访问和隐藏真实对象，MapperProxy 主要负责把接口调用转成框架调用；装饰器更强调在保持原接口的情况下动态增加职责，CachingExecutor 更接近装饰器。
- **模板方法与策略的区别**：模板方法通常由继承复用流程骨架，策略模式通过组合替换完整算法。MyBatis 两者并存，既复用 Executor 公共流程，又允许切换 ExecutorType。
- **为什么插件不直接修改源码**：核心对象稳定，插件通过代理插入扩展逻辑，符合开闭原则；代价是代理层增加调试复杂度，插件顺序不当还可能改变 SQL 语义。
- **为什么 MyBatis 没有完全自动生成 SQL**：它把 SQL 控制权交给开发者，适合复杂查询和精细优化，但也要求开发者关注 SQL 注入、索引和参数安全。

---

## 回答思路

### 答题逻辑框架

1. 先总述：MyBatis 的设计模式围绕初始化、Mapper 调用、SQL 执行和插件扩展展开。
2. 重点讲代理：Mapper 没有实现类，`MapperProxy` 把接口方法映射到 `MappedStatement`。
3. 再讲工厂和建造者：`SqlSessionFactory` 生产会话，Builder 组装复杂配置。
4. 扩展模式收尾：Executor 体现模板和策略，缓存/插件体现装饰器与责任链。
5. 最后用一条 SQL 链路串起来：`MapperProxy → SqlSession → Executor → StatementHandler → JDBC`。

### 重点得分点

- 能说清 `MapperProxy` 是 JDK 动态代理。
- 能区分 `SqlSessionFactory`、`MapperProxyFactory` 的职责。
- 能举出 `SimpleExecutor`、`ReuseExecutor`、`BatchExecutor`。
- 能解释 `CachingExecutor` 为什么属于装饰器思想。
- 能说出插件拦截的四类对象：Executor、StatementHandler、ParameterHandler、ResultSetHandler。

### 常见误区

- ❌ 认为每个 Mapper 都有 MyBatis 自动生成的 Java 实现类；实际是运行时代理。
- ❌ 认为 `SqlSession` 可以作为单例共享；它不是线程安全的。
- ❌ 把所有带接口的代码都称为工厂模式；要指出具体的对象创建职责。
- ❌ 认为插件可以拦截任意方法；必须匹配四类对象和精确方法签名。
- ❌ 忘记 `invocation.proceed()`，导致责任链被截断。

### 过渡话术

“Mapper 代理解决了入口问题，但代理拿到方法后还要找到 SQL 并执行，所以接下来进入 SqlSession、Executor 和 StatementHandler 组成的执行链。”

### 时间分配建议

- 30 秒讲整体分类。
- 60 秒讲 MapperProxy 和工厂。
- 60 秒讲 Executor 的模板、策略、缓存装饰。
- 30 秒讲插件责任链和常见误区。

---

> 📋 **分类**: mybatis
> 🏷️ **标签**: `MyBatis`, `设计模式`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-20 00:00:00
