---
id: q0079
question: "Spring中的Bean有几种注入方式"
category: spring
tags: ["依赖注入", "DI", "Bean", "Spring"]
difficulty: medium
created: 2026-08-26 10:51:10
source: 用户输入
---

# Spring中的Bean有几种注入方式

## 联想记忆法

### 记忆口诀/联想

**口诀：构造器最稳，Setter 可选，字段最省但难测；方法参数适合配置和批量。**

- **构造器注入**：对象创建时必须拿到依赖，适合必需依赖，最推荐。
- **Setter 注入**：对象可以先创建，依赖之后设置，适合可选或可变依赖。
- **字段注入**：直接在字段上标注 `@Autowired`，代码短，但隐藏依赖、测试和不可变性较差。
- **方法参数注入**：在 `@Bean` 方法或配置方法参数中声明依赖，适合组装 Bean。

### 记忆原理

判断注入方式不要只背注解，先问依赖是不是“**必须存在**”。必须存在就放构造器，让对象从诞生起就是完整状态；可选依赖才考虑 Setter；字段注入只是书写方便，并不代表设计更优。

### 关联知识

- 与 IoC 关联：注入是 Spring 实现控制反转的具体手段。
- 与 Bean 生命周期关联：构造器注入发生在实例化阶段，字段和 Setter 注入发生在实例化之后的属性填充阶段。
- 与依赖解析关联：`@Autowired` 主要按类型，`@Qualifier` 缩小候选，`@Primary` 指定默认候选。
- 与测试关联：构造器注入可以直接 `new` 类并传入 Mock，不依赖反射或 Spring 容器。

## 深度解答

### 第一层：核心概念

Spring 中常说的 Bean 注入方式，通常有三种主流方式：**构造器注入、Setter 注入、字段注入**；在配置类中还经常使用**方法参数注入**。它们的共同目标都是让容器把当前 Bean 所依赖的对象传进来，而不是由业务代码自己 `new`。

#### 1. 构造器注入

```java
@Service
public class UserService {
    private final UserRepository repository;

    public UserService(UserRepository repository) {
        this.repository = repository;
    }
}
```

当类只有一个构造器时，Spring 通常可以直接使用它，不必再写 `@Autowired`。构造器注入的特点是：依赖明确、对象创建后状态完整、字段可以声明为 `final`、单元测试简单，还能较早暴露循环依赖。

#### 2. Setter 注入

```java
@Component
public class ReportService {
    private Exporter exporter;

    @Autowired
    public void setExporter(Exporter exporter) {
        this.exporter = exporter;
    }
}
```

Setter 注入适合可选依赖、允许后续替换的依赖，或者需要兼容无参构造器的场景。可选依赖可以使用 `@Autowired(required = false)`、`Optional<T>` 或 `ObjectProvider<T>` 表达，但要确保业务代码能处理依赖不存在的情况。

#### 3. 字段注入

```java
@Service
public class OrderService {
    @Autowired
    private OrderRepository repository;
}
```

字段注入写法最短，历史项目中很常见，但依赖不会出现在构造器或公开 API 中，类脱离容器后字段可能为空，字段也不能自然地保持 `final`。因此新代码通常不推荐把字段注入作为默认方案。

#### 4. 方法参数注入

在 `@Bean` 方法中，方法参数就是容器需要解析和注入的依赖：

```java
@Configuration
public class ClientConfig {
    @Bean
    public OrderClient orderClient(OrderRepository repository,
                                   @Value("${order.timeout:3s}") Duration timeout) {
        return new OrderClient(repository, timeout);
    }
}
```

配置类的 `@Bean` 方法参数注入特别适合组装第三方对象、连接池、客户端和适配器。普通组件也可以在一个 `@Autowired` 方法的参数中声明多个依赖，本质上仍是方法注入。

### 第二层：底层原理

Spring 启动时先把 Bean 的定义注册到容器，然后在创建目标 Bean 时解析依赖。构造器注入发生在实例化之前：容器先确定构造器和参数，再递归创建参数对应的 Bean，最后调用构造器。字段和 Setter 注入通常由 `AutowiredAnnotationBeanPostProcessor` 等后置处理器在实例化后执行反射注入。

依赖解析通常遵循“**类型优先，名称或限定符消歧**”的思路：

1. 先根据依赖类型找候选 Bean。
2. 如果只有一个候选，直接注入。
3. 多个候选时，优先考虑 `@Primary`。
4. 仍有歧义时，使用 `@Qualifier` 或匹配字段/参数名称。
5. 没有候选且依赖是必需的，容器启动失败；可选依赖则根据配置允许缺失。

例如：

```java
public PaymentService(@Qualifier("wechatPayment") PaymentGateway gateway) {
    this.gateway = gateway;
}
```

`@Resource` 是 Jakarta 注解，常见语义更偏向按名称查找；找不到名称时再根据类型处理，具体行为要结合 Spring 版本和注解属性判断。面试中应避免简单地说成“@Autowired 按类型、@Resource 永远按名称”，更准确的说法是两者默认匹配策略和消歧方式不同。

### 第三层：实践应用

推荐把必需依赖全部放进构造器：

```java
@Service
public class InventoryService {
    private final InventoryRepository repository;
    private final StockPolicy policy;

    public InventoryService(InventoryRepository repository,
                            StockPolicy policy) {
        this.repository = repository;
        this.policy = policy;
    }
}
```

当接口存在多个实现时，用 `@Qualifier` 表达业务选择，而不是依赖变量名碰巧匹配：

```java
@Component("remoteStockPolicy")
public class RemoteStockPolicy implements StockPolicy {}

public InventoryService(InventoryRepository repository,
                        @Qualifier("remoteStockPolicy") StockPolicy policy) {
    this.repository = repository;
    this.policy = policy;
}
```

需要注入多个 Bean 时，可以声明 `List<PaymentGateway>` 或 `Map<String, PaymentGateway>`，Spring 会按类型收集候选；这适合策略模式、责任链和插件式扩展，但要定义顺序或明确的 Bean 名称规则。

### 第四层：深入思考

构造器注入并不是因为“字段注入一定不能用”，而是因为它更能表达类的真实依赖关系。字段注入在快速开发、旧项目维护或框架代理限制下仍可能存在，但应该意识到它会隐藏依赖、增加反射耦合，并让没有 Spring 的单元测试更麻烦。

注入方式也要和作用域匹配。把 request 作用域 Bean 直接注入 singleton 时，需要代理或 `ObjectProvider` 让每次调用获取当前请求对象；把原型 Bean 注入单例时，默认只会在单例创建时取一次，不会每次调用都创建新对象。

## 回答思路

### 答题逻辑框架

1. 先回答三种主流方式：构造器、Setter、字段。
2. 说明配置类中 `@Bean` 方法参数也是常见注入方式。
3. 重点比较依赖完整性、可测试性和可变性。
4. 补充 `@Autowired`、`@Resource`、`@Qualifier`、`@Primary` 的匹配规则。

### 重点得分点

- 明确推荐构造器注入，并说明理由。
- 能解释字段注入的隐藏依赖和测试问题。
- 能说出多个实现用 `@Qualifier` 或 `@Primary` 消歧。
- 能识别集合注入和 `@Bean` 方法参数注入。

### 常见误区

- 误区 1：只有字段上加 `@Autowired` 才叫注入。正解：构造器和 Setter 同样是注入。
- 误区 2：`@Resource` 永远按名称。正解：其匹配规则比这句话更复杂，不能绝对化。
- 误区 3：原型 Bean 注入单例后每次调用都会新建。正解：默认只注入一次，需要 Provider 或代理才能按需获取。
- 误区 4：多个实现随便注入一个。正解：需要 `@Qualifier`、`@Primary` 或明确名称。

### 面试话术

“Spring Bean 常见注入方式有构造器、Setter 和字段注入，配置类中还常用 @Bean 方法参数注入。新代码我优先用构造器注入，因为依赖显式、对象创建后状态完整、支持 final，也更容易做单元测试。@Autowired 默认按类型解析，多个实现时可用 @Qualifier 或 @Primary；@Resource 更偏向按名称匹配。字段注入虽然简洁，但隐藏依赖、测试和不可变性较差。”

### 时间分配建议

三种方式 60 秒，依赖解析规则 40 秒，推荐实践和作用域问题 30 秒。


---

> 📋 **分类**: spring
> 🏷️ **标签**: `依赖注入` `DI` `Bean` `Spring`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-26 10:51:10
