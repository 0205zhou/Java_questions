---
id: q0083
question: "Spring的常用注解"
category: spring
tags: ["Spring", "注解", "IoC", "依赖注入", "配置"]
difficulty: medium
created: 2026-08-27 09:44:00
source: 用户输入
---

# Spring的常用注解

## 联想记忆法

### 记忆口诀/联想

**口诀：组件先注册，依赖再注入；配置来组装，切面管增强；Web 接请求，事务保一致。**

按 Spring 的使用过程记忆：

- **注册**：`@Component`、`@Service`、`@Repository`、`@Controller`。
- **注入**：`@Autowired`、`@Resource`、`@Qualifier`、`@Primary`。
- **组装**：`@Configuration`、`@Bean`、`@ComponentScan`、`@Value`、`@ConfigurationProperties`。
- **增强**：`@Aspect`、`@Before`、`@Around`、`@Transactional`。
- **Web**：`@RestController`、`@RequestMapping`、`@RequestBody`、`@PathVariable`。

### 记忆原理

不要按字母死记注解，而要问它在容器生命周期的哪一步发挥作用：**扫描发现 Bean、创建 Bean、注入依赖、配置属性、代理增强、处理请求**。把注解放回这条链路，遇到陌生注解也能推断其职责。

### 关联知识

- `@Component` 及其派生注解依赖组件扫描，扫描范围不对时 Bean 不会注册。
- `@Autowired` 和 `@Resource` 解决的是依赖注入，不是 Bean 注册。
- `@Transactional`、`@Cacheable`、`@Async` 往往通过 Spring AOP 代理生效。
- `@SpringBootApplication` 是 Spring Boot 中常见的组合注解，不等于整个 Spring 注解体系。

## 深度解答

### 第一层：组件注册与分层注解

#### 1. `@Component`

`@Component` 表示一个类是 Spring 管理的组件。启动时，组件扫描会发现它并注册为 Bean，默认 Bean 名称通常是类名首字母小写，例如 `userService`。

```java
@Component
public class IdGenerator {
    public String nextId() {
        return UUID.randomUUID().toString();
    }
}
```

#### 2. `@Service`、`@Repository`、`@Controller`

这三个注解本质上都是 `@Component` 的语义化派生注解，但表达了不同的分层职责：

| 注解 | 典型职责 |
|---|---|
| `@Service` | 业务服务层，承载业务编排和事务边界 |
| `@Repository` | 数据访问层，表示 DAO 或仓储组件 |
| `@Controller` | Spring MVC 控制器，处理 Web 请求 |

`@Repository` 还可以参与 Spring 的持久化异常转换，把底层数据访问异常转换为 Spring 统一的数据访问异常体系。分层注解不是强制限制，但能让代码结构、组件扫描和异常处理意图更清晰。

#### 3. `@RestController`

`@RestController` 等价于 `@Controller` 加类级别的 `@ResponseBody`，适合返回 JSON、文本等响应体的 REST 接口。

```java
@RestController
@RequestMapping("/users")
public class UserController {
    @GetMapping("/{id}")
    public User find(@PathVariable Long id) {
        return userService.findById(id);
    }
}
```

返回的 Java 对象会交给 `HttpMessageConverter` 序列化，而不是被当成视图名称解析。

### 第二层：依赖注入注解

#### 1. `@Autowired`

`@Autowired` 默认按类型查找依赖，可以用于构造器、字段和 Setter 方法。若同一类型存在多个 Bean，应配合 `@Qualifier` 或 `@Primary` 消除歧义。

```java
@Service
public class OrderService {
    private final PaymentGateway gateway;

    public OrderService(@Qualifier("wechatPayment") PaymentGateway gateway) {
        this.gateway = gateway;
    }
}
```

新代码通常优先使用构造器注入，因为依赖显式、对象创建后状态完整、支持 `final`，并且更方便单元测试。

#### 2. `@Resource`

`@Resource` 来自 Jakarta/Java 注解体系，常见默认语义更偏向按名称匹配，也可以指定 `name` 或 `type`。它和 `@Autowired` 的匹配策略不同，具体行为应结合注解属性和 Spring 版本判断，不能简单绝对地说“永远按名称”。

#### 3. `@Qualifier` 与 `@Primary`

- `@Qualifier("beanName")`：在注入点明确指定要使用的 Bean。
- `@Primary`：多个候选 Bean 都符合类型时，指定一个默认候选。

```java
@Component("alipayPayment")
class AlipayPayment implements PaymentGateway {}

@Component("wechatPayment")
@Primary
class WechatPayment implements PaymentGateway {}
```

`@Qualifier` 更明确，适合业务上确实需要选择某个实现的场景；`@Primary` 更适合有一个常用默认实现、其他实现只在特殊场景使用的情况。

### 第三层：配置与 Bean 组装注解

#### 1. `@Configuration` 与 `@Bean`

`@Configuration` 声明配置类，`@Bean` 声明一个由方法创建并交给 Spring 容器管理的 Bean。它们特别适合组装第三方类库对象、连接池、HTTP 客户端和自定义基础设施。

```java
@Configuration
public class ClientConfiguration {

    @Bean
    public ObjectMapper objectMapper() {
        return new ObjectMapper()
                .findAndRegisterModules();
    }
}
```

`@Bean` 方法返回的对象会进入 Spring 容器，其他 Bean 可以像注入普通组件一样使用它。

#### 2. `@ComponentScan`

`@ComponentScan` 指定组件扫描的包范围，用于发现 `@Component`、`@Service` 等组件。Spring Boot 通常会以启动类所在包为根包进行扫描；如果启动类位置不合理，可能出现“明明加了注解但注入失败”的问题。

#### 3. `@Import`、`@ImportResource`

- `@Import` 导入配置类、组件或注册器，常用于模块化装配。
- `@ImportResource` 导入 XML 配置文件，主要用于兼容老项目。

现代项目一般优先采用 Java 配置、组件扫描或自动配置，只有在需要兼容旧配置时才大量使用 XML。

#### 4. `@Value` 与 `@ConfigurationProperties`

`@Value` 适合注入单个配置项：

```java
@Value("${payment.timeout:3s}")
private Duration timeout;
```

`@ConfigurationProperties` 适合把一组具有层级结构的配置绑定到类型安全的配置类中，字段多、配置复杂时可读性更好。

```java
@ConfigurationProperties(prefix = "payment")
public class PaymentProperties {
    private Duration timeout = Duration.ofSeconds(3);
    private int retryCount = 2;
    // getter/setter
}
```

### 第四层：Web 请求映射注解

| 注解 | 作用 |
|---|---|
| `@RequestMapping` | 声明 URL、HTTP 方法、请求头等匹配条件 |
| `@GetMapping` / `@PostMapping` | `@RequestMapping` 的 GET/POST 组合注解 |
| `@PathVariable` | 获取路径变量，如 `/users/{id}` |
| `@RequestParam` | 获取查询参数，如 `?page=1` |
| `@RequestBody` | 将 JSON 请求体反序列化为 Java 对象 |
| `@RequestHeader` | 获取请求头 |
| `@ResponseStatus` | 指定响应状态码 |
| `@ExceptionHandler` | 处理控制器方法抛出的异常 |
| `@ControllerAdvice` | 对多个控制器提供全局增强和异常处理 |
| `@RestControllerAdvice` | `@ControllerAdvice` 加 `@ResponseBody` |

参数绑定示例：

```java
@PostMapping
public User create(@RequestBody @Valid CreateUserRequest request,
                   @RequestHeader("X-Trace-Id") String traceId) {
    return userService.create(request, traceId);
}
```

`@Valid` 和 `@Validated` 用于触发参数校验，通常配合 `@NotBlank`、`@Size`、`@Min` 等约束注解。

### 第五层：AOP、事务与生命周期注解

#### AOP 与事务

- `@Aspect`：声明切面类。
- `@Pointcut`：定义切点表达式。
- `@Before`、`@After`、`@Around`：定义通知执行时机。
- `@Transactional`：声明事务边界。
- `@Order`：调整多个切面或组件的执行顺序。

```java
@Transactional(rollbackFor = Exception.class)
public void submitOrder(SubmitOrderCommand command) {
    // 保存订单、扣减库存等需要保持一致性的操作
}
```

`@Transactional` 依赖代理，内部自调用、私有方法和错误的事务管理器配置都可能导致它不按预期生效。

#### 缓存与异步

- `@EnableCaching`：开启 Spring 缓存注解能力。
- `@Cacheable`：方法执行前查缓存，命中时直接返回。
- `@CachePut`：执行方法并用返回值更新缓存。
- `@CacheEvict`：删除缓存。
- `@EnableAsync`：开启异步方法能力。
- `@Async`：将方法提交到异步执行器。

这些注解同样经常通过 AOP 代理实现，使用时应配置缓存键、过期策略、线程池和异常处理，而不是把注解当成完整的缓存或异步方案。

#### 生命周期

- `@PostConstruct`：依赖注入完成后执行初始化逻辑。
- `@PreDestroy`：Bean 销毁前执行清理逻辑。
- `@Scope`：声明 Bean 作用域，如 singleton、prototype、request。

初始化方法适合检查配置、建立轻量资源；耗时任务、外部依赖重试和复杂启动编排应避免阻塞整个容器启动。

### 第六层：Spring Boot 常见组合注解

`@SpringBootApplication` 通常可以理解为以下能力的组合：

- `@SpringBootConfiguration`：标识 Spring Boot 配置类。
- `@EnableAutoConfiguration`：根据类路径和配置自动装配组件。
- `@ComponentScan`：扫描当前包及其子包中的组件。

此外，`@EnableConfigurationProperties` 用于启用配置属性类，`@ConditionalOnMissingBean`、`@ConditionalOnClass` 等条件注解常出现在自动配置实现中，用来根据环境决定是否注册 Bean。

## 回答思路

### 答题逻辑框架

1. 先按职责分类，而不是从头背注解清单。
2. 先讲 Bean 注册：`@Component` 及 `@Service`、`@Repository`、`@Controller`。
3. 再讲依赖注入：`@Autowired`、`@Resource`、`@Qualifier`、`@Primary`。
4. 补充配置组装、Web 映射、事务缓存和生命周期注解。
5. 最后说明组合注解和 AOP 代理带来的生效条件。

### 重点得分点

- 能说出派生注解的关系：`@Service` 等本质上是语义化组件注解。
- 能区分 Bean 注册与依赖注入两个不同步骤。
- 能说明 `@RestController`、`@SpringBootApplication` 的组合语义。
- 能指出 `@Transactional`、`@Cacheable`、`@Async` 依赖代理。
- 能说明 `@Value` 适合少量配置，复杂配置更适合 `@ConfigurationProperties`。

### 常见误区

- 认为所有注解都负责创建 Bean；`@Autowired` 只是注入依赖。
- 认为 `@Controller` 返回对象一定是 JSON；还要看是否有 `@ResponseBody`。
- 认为 `@Transactional` 加在哪个方法上都有效；代理调用路径和方法可见性很重要。
- 认为 `@ComponentScan` 会扫描整个项目；默认范围通常与配置类所在包有关。
- 把 Spring 注解和 Spring Boot 注解混为一谈；Boot 注解很多是对 Spring 能力的组合和自动配置封装。

### 面试话术

“Spring 常用注解可以按职责分成几类：组件注册用 @Component、@Service、@Repository、@Controller；依赖注入用 @Autowired、@Resource、@Qualifier；配置组装用 @Configuration、@Bean、@Value；Web 开发用 @RestController、@RequestMapping、@RequestBody；事务、缓存和异步分别常用 @Transactional、@Cacheable、@Async。需要注意，这些注解背后通常依赖组件扫描、BeanPostProcessor 或 AOP 代理，并不是加上注解就脱离容器自动生效。”

### 时间分配建议

- 30 秒：组件注册和注入。
- 40 秒：配置、Web 常用注解。
- 30 秒：事务、缓存、异步和生命周期。
- 20 秒：组合注解、代理生效条件和常见误区。

---

> 📋 **分类**: spring
> 🏷️ **标签**: `Spring` `注解` `IoC` `依赖注入` `配置`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-27 09:44:00
