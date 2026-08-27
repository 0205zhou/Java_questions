---
id: q0084
question: "@Resource和@Autowired的区别"
category: spring
tags: ["Spring", "依赖注入", "Autowired", "Resource", "Bean"]
difficulty: medium
created: 2026-08-27 09:46:00
source: 用户输入
---

# @Resource和@Autowired的区别

## 联想记忆法

### 记忆口诀/联想

**口诀：Autowired 先看类型，Qualifier 来指定；Resource 先看名字，type 可强制。**

把依赖注入想成在仓库中找货：

- `@Autowired` 先问“哪种类型的货物”，类型唯一就直接拿；多个候选时再用 `@Qualifier` 或 `@Primary` 消歧。
- `@Resource` 更像先按“货架名称”找，默认会结合字段或 Setter 属性名；找不到合适名称时，Spring 对未显式指定名称的情况还可以回退到类型匹配。

### 记忆原理

两者最本质的区别有三组：**来源不同、默认匹配策略不同、可使用位置不同**。

- `@Autowired` 是 Spring 提供的注解，核心语义是按类型注入。
- `@Resource` 来自 Java/Jakarta 的通用注解规范，常见语义偏向按名称注入。
- `@Autowired` 可用于构造器，`@Resource` 通常用于字段或 Setter 方法。

### 关联知识

- 多个实现优先使用构造器注入并配合 `@Qualifier`，比依赖变量名碰巧匹配更明确。
- `@Primary` 适合指定默认实现，`@Qualifier` 适合在具体注入点表达选择。
- 两者都依赖 Spring 容器和相关 `BeanPostProcessor`，脱离容器直接 `new` 对象时都不会自动注入。

## 深度解答

### 第一层：核心区别

`@Autowired` 和 `@Resource` 都用于让 Spring 把容器中的 Bean 注入到当前对象，但它们并不是同一个注解的两个名字。

| 对比项 | `@Autowired` | `@Resource` |
|---|---|---|
| 注解来源 | Spring Framework | Java/Jakarta Common Annotations |
| 默认匹配 | 以类型为主 | 以名称为主，未明确名称时可结合类型回退 |
| 指定实现 | `@Qualifier` | `name` 属性或 `type` 属性 |
| 构造器注入 | 支持 | 通常不用于构造器 |
| 字段/Setter | 支持 | 支持字段和方法注入 |
| 必需属性 | `required` 默认是 `true` | 没有同名的 `required` 属性 |
| 常见使用风格 | Spring 项目中更常见 | 希望使用标准注解或明确按名称时常见 |

最简洁的面试结论是：**`@Autowired` 默认按类型查找依赖，`@Resource` 默认更偏向按名称查找依赖；两者都能完成依赖注入，但匹配规则和适用位置不同。**

### 第二层：`@Autowired` 的匹配规则

Spring 处理 `@Autowired` 时，通常先根据依赖类型寻找候选 Bean：

1. 没有候选 Bean，且依赖是必需的，容器启动失败。
2. 只有一个候选 Bean，直接注入。
3. 有多个候选 Bean，优先考虑 `@Primary`。
4. 仍有多个候选时，使用注入点上的 `@Qualifier`。
5. 在某些场景下，参数名或字段名也可以作为进一步的匹配线索，但不应把变量名当成最主要的配置手段。

```java
public interface PaymentGateway {
    void pay(String orderId);
}

@Component("alipayGateway")
class AlipayGateway implements PaymentGateway {
    public void pay(String orderId) {}
}

@Component("wechatGateway")
class WechatGateway implements PaymentGateway {
    public void pay(String orderId) {}
}

@Service
class OrderService {
    private final PaymentGateway gateway;

    public OrderService(@Qualifier("wechatGateway") PaymentGateway gateway) {
        this.gateway = gateway;
    }
}
```

如果不加 `@Qualifier` 或 `@Primary`，容器发现两个 `PaymentGateway` 候选时通常会抛出 `NoUniqueBeanDefinitionException`，因为它无法猜测业务真正需要哪一个。

`@Autowired` 可以用于构造器、字段和方法：

```java
@Autowired
public OrderService(PaymentGateway gateway) {
    this.gateway = gateway;
}
```

当类只有一个构造器时，现代 Spring 通常可以直接使用该构造器，不必再写 `@Autowired`。这也是新代码优先构造器注入的原因之一。

### 第三层：`@Resource` 的匹配规则

`@Resource` 由 Jakarta Common Annotations 定义，常见写法如下：

```java
@Resource(name = "wechatGateway")
private PaymentGateway gateway;
```

指定 `name` 时，含义很明确：按这个 Bean 名称查找。也可以指定 `type`：

```java
@Resource(type = PaymentGateway.class)
private PaymentGateway gateway;
```

当没有显式指定 `name` 时，Spring 通常会先根据字段名或 Setter 属性名推断默认名称。例如字段名为 `wechatGateway`，容器中存在同名 Bean，就会优先使用它；如果没有这样的名称，Spring 对未指定名称的 `@Resource` 可以继续按类型解析。因此准确表述应是“默认偏向名称匹配，必要时可回退到类型”，而不是“`@Resource` 永远按名称”。

```java
@Resource
private PaymentGateway wechatGateway;
```

这段代码通常会先尝试名为 `wechatGateway` 的 Bean。若项目中有多个同类型实现，依赖字段名和 Bean 名称隐式匹配会降低可读性，所以在关键业务依赖上应显式指定名称，或者改用构造器注入和 `@Qualifier`。

### 第四层：两者在实际代码中的选择

#### 推荐 `@Autowired` + 构造器注入的情况

- 项目大量使用 Spring 原生能力。
- 依赖主要按接口类型组织。
- 希望依赖关系显式表达在构造器中。
- 希望字段使用 `final`，并方便单元测试。
- 需要配合 `@Qualifier`、`@Primary`、`ObjectProvider` 或集合注入。

```java
@Service
public class InventoryService {
    private final InventoryRepository repository;
    private final StockPolicy policy;

    public InventoryService(InventoryRepository repository,
                            @Qualifier("defaultStockPolicy") StockPolicy policy) {
        this.repository = repository;
        this.policy = policy;
    }
}
```

#### 适合使用 `@Resource` 的情况

- 团队希望使用 Java/Jakarta 标准注解，降低对 Spring 注解的直接依赖。
- 业务确实是“按名称选择实现”，名称具有稳定、明确的业务含义。
- 维护已有项目，原有代码已经统一使用 `@Resource`。
- 字段或 Setter 注入能够满足兼容性要求。

但“标准注解”不代表它在所有场景下都比 `@Autowired` 更优。对于必需依赖，构造器注入带来的显式依赖和可测试性通常比字段注入的简洁更重要。

### 第五层：可选依赖与集合注入

`@Autowired` 默认要求依赖存在，可以使用 `required = false`、`Optional<T>` 或 `ObjectProvider<T>` 表达可选依赖：

```java
public ReportService(ObjectProvider<Exporter> exporterProvider) {
    this.exporterProvider = exporterProvider;
}
```

对于 `@Resource`，没有与 `@Autowired(required = false)` 完全对应的 `required` 属性。若依赖可能不存在，更建议通过 `Optional`、Provider 或配置条件明确表达，而不是让字段默默保持空值。

两者也都可以参与集合或 Map 注入，但通常更适合使用构造器参数：

```java
public PaymentService(List<PaymentGateway> gateways,
                      Map<String, PaymentGateway> gatewayMap) {
    // Spring 按类型收集多个实现，Map 的 key 通常是 Bean 名称
}
```

### 第六层：底层处理与常见限制

Spring 会通过 `AutowiredAnnotationBeanPostProcessor` 处理 `@Autowired`，通过通用注解相关的后置处理器处理 `@Resource`。它们一般发生在 Bean 实例化之后、初始化方法执行之前的属性填充阶段；构造器注入则发生在实例化时。

两者都需要注意：

- 当前对象必须由 Spring 容器创建，自己 `new` 出来的对象不会被自动注入。
- 注入点所在包必须被扫描或通过配置注册。
- 同类型多个实现时必须解决歧义。
- 循环依赖可能导致容器启动失败，尤其是构造器循环依赖。
- 字段注入隐藏依赖，测试时不容易直接构造对象，因此不建议作为新代码默认方案。

## 回答思路

### 答题逻辑框架

1. 先说共同点：两者都是 Spring 中的依赖注入注解。
2. 再说来源：`@Autowired` 是 Spring 注解，`@Resource` 是 Java/Jakarta 标准注解。
3. 核心对比匹配规则：前者类型优先，后者名称优先但可回退类型。
4. 补充多个实现的处理：`@Qualifier`、`@Primary`、`name`、`type`。
5. 说明构造器支持和推荐实践：新代码优先构造器注入，避免隐藏依赖。

### 重点得分点

- 不能绝对地说 `@Resource` 永远按名称，应该说明默认名称匹配和类型回退。
- 能说出 `@Autowired` 遇到多个实现时使用 `@Qualifier` 或 `@Primary`。
- 能指出 `@Autowired` 支持构造器，`@Resource` 常用于字段和 Setter。
- 能说明两者都依赖 Spring 容器，自己 `new` 对象不会注入。
- 能把注解选择和构造器注入、可测试性联系起来。

### 常见误区

- 认为 `@Autowired` 只要按类型就永远不会看名称；名称可能作为消歧线索，但不是首要策略。
- 认为 `@Resource` 永远按名称；未指定名称时，Spring 可按类型回退。
- 认为两个注解可以无条件互换；构造器支持、属性配置和多实现处理方式不同。
- 认为字段上加注解就能注入普通 Java 对象；对象必须由 Spring 容器管理。

### 面试话术

“@Autowired 是 Spring 提供的注解，默认按类型注入，多个实现时通常用 @Qualifier 或 @Primary 消歧；@Resource 来自 Java/Jakarta 标准注解，默认更偏向按名称匹配，也可以显式指定 name 或 type，未指定名称时 Spring 还可能回退到类型。@Autowired 可以用于构造器，而 @Resource 常用于字段和 Setter。新代码我更倾向于构造器注入，因为依赖明确、支持 final、也更方便测试。”

### 时间分配建议

- 20 秒：共同点和一句话结论。
- 40 秒：来源、匹配规则和多实现消歧。
- 30 秒：构造器、字段、Setter 的适用差异。
- 20 秒：底层后置处理器、容器要求和最佳实践。

---

> 📋 **分类**: spring
> 🏷️ **标签**: `Spring` `依赖注入` `Autowired` `Resource` `Bean`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-27 09:46:00
