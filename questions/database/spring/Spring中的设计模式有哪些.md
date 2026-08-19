---
id: q0057
question: "Spring中的设计模式有哪些?"
category: spring
tags: ["Spring", "设计模式"]
difficulty: medium
created: 2026-08-20 00:00:00
source: 用户输入
---

# Spring中的设计模式有哪些?

---

## 联想记忆法

### 记忆口诀/联想

**口诀："工厂生 Bean，单例做底盘；代理切 AOP，模板管流程；观察发事件，适配连生态，责任链拦请求"**

把 Spring 里最常考的一组设计模式压缩成 7 个抓手：

- **工厂生 Bean** = 工厂模式（Factory Pattern）：`BeanFactory`、`ApplicationContext` 负责创建和管理对象
- **单例做底盘** = 单例模式（Singleton Pattern）：Spring 默认作用域就是 singleton
- **代理切 AOP** = 代理模式（Proxy Pattern）：AOP、事务、懒加载、Mapper 代理都靠代理增强
- **模板管流程** = 模板方法模式（Template Method Pattern）：`JdbcTemplate`、`RedisTemplate`、`RestTemplate` 封装固定流程
- **观察发事件** = 观察者模式（Observer Pattern）：`ApplicationEventPublisher` + `ApplicationListener`
- **适配连生态** = 适配器模式（Adapter Pattern）：`HandlerAdapter`、`AdvisorAdapter`
- **责任链拦请求** = 责任链模式（Chain of Responsibility Pattern）：拦截器链、过滤器链、安全过滤器链

再补一句总纲：**"IoC 用工厂管对象，AOP 用代理做增强，MVC 用适配 + 责任链串流程。"**

### 记忆原理

这个口诀采用的是**按 Spring 三大能力分桶记忆**：IoC 容器这一桶主要是工厂、单例；AOP 这一桶核心是代理；Web/MVC 这一桶高频是适配器、责任链；基础设施层常出现模板方法与观察者。也就是说，不是死背一堆模式名，而是先问自己：**这个模式在 Spring 里解决什么问题？**

- 对象怎么创建？→ 工厂模式
- 默认对象怎么复用？→ 单例模式
- 不改源码怎么增强？→ 代理模式
- 通用流程怎么复用？→ 模板方法模式
- 框架内部怎么解耦通知？→ 观察者模式
- 多种 Controller / Advice 怎么统一调用？→ 适配器模式
- 多个拦截步骤怎么串起来？→ 责任链模式

这种“问题 → 模式 → Spring 场景”的三段式记忆，比只背定义更不容易忘。

### 关联知识

- **与 IoC 关联**：Spring 的核心是 IoC（Inversion of Control，控制反转），工厂模式和单例模式是 IoC 容器落地的地基
- **与 AOP 关联**：代理模式几乎是 Spring AOP 的灵魂，事务管理 `@Transactional` 也是 AOP 的直接应用
- **与 Spring MVC 关联**：MVC 里 `DispatcherServlet` 调度过程中，适配器模式和责任链模式特别高频
- **与 MyBatis-Spring 关联**：MyBatis 整合 Spring 时，Mapper 接口代理也属于代理模式，与 Spring AOP 底层思想相通
- **与模板类家族关联**：`JdbcTemplate`、`RedisTemplate`、`KafkaTemplate`、`RestTemplate` 命名本身就暴露了模板方法模式

---

## 深度解答

### 第一层：核心概念

#### 为什么 Spring 里会大量出现设计模式

Spring 本质上不是一个“只提供几个注解”的工具包，而是一个**大型基础设施框架**。这种框架要解决的问题很多：

1. **对象如何统一创建与管理**
2. **如何在不改业务代码的前提下增强能力**
3. **如何让流程可扩展而又不失控**
4. **如何把不同技术、不同接口风格统一接入**
5. **如何让框架内部模块彼此解耦**

而设计模式就是对这些通用问题的经典答案。所以 Spring 不是“为了用模式而用模式”，而是因为它解决的全是典型框架级问题，自然会大量落到设计模式上。

#### 面试怎么回答更好

这个题不要只报菜名：“有工厂、单例、代理、模板……” 这样只能拿到基础分。更好的回答方式是：

- **先按模块分**：IoC / AOP / MVC
- **再说模式**：每个模块对应哪些模式
- **最后举源码或类名**：让答案落地

面试官真正想考的是：**你是不是理解 Spring 的设计哲学，而不是只会背模式定义。**

---

### 第二层：底层原理

#### 1. 工厂模式（Factory Pattern）——IoC 容器的起点

Spring IoC 容器本质就是一个超级工厂。

最典型的两个接口：

- `BeanFactory`
- `ApplicationContext`

它们负责根据 BeanDefinition（Bean 的“配方”）创建对象，而不是让业务代码直接 `new`。

```java
ApplicationContext context = new ClassPathXmlApplicationContext("applicationContext.xml");
UserService userService = context.getBean(UserService.class);
```

这里的关键点不是 `getBean()` 这句代码本身，而是它背后的思想：

- 对象创建逻辑被统一收口到容器
- 对象依赖关系由容器注入
- 业务代码只声明“我要什么”，不关心“怎么创建”

这就是工厂模式和控制反转结合后的效果。

进一步看，Spring 里还有很多“工厂的工厂”：

- `FactoryBean`：允许你自定义复杂对象的创建逻辑
- `BeanFactoryPostProcessor`：在 Bean 真正实例化前修改 BeanDefinition
- `AutowireCapableBeanFactory`：提供更高级的自动装配能力

也就是说，Spring 不是简单地“用了一个工厂模式”，而是**把工厂模式做成了一个分层体系**。

#### 2. 单例模式（Singleton Pattern）——Spring 默认作用域

Spring 中 Bean 的默认 scope 是 `singleton`：

```java
@Service
public class OrderService {
}
```

如果你不额外声明 scope，那么整个容器里通常只会有一个 `OrderService` 实例。容器内部会通过缓存保存已经创建好的单例对象，再次获取时直接复用。

```java
Object bean = getSingleton(beanName);
```

这里要注意一个**面试高频细节**：

- **经典单例模式**：类自己控制实例创建，如私有构造 + 静态实例
- **Spring 单例**：不是 JVM 全局单例，而是**容器级单例（per-container singleton）**

也就是说：

- 同一个 Spring 容器里，Bean 通常只有一份
- 不同容器里，可以各自有自己的单例实例

所以 Spring 的单例更准确地说是“**容器管理下的单例缓存策略**”。

#### 3. 代理模式（Proxy Pattern）——AOP、事务、懒加载的灵魂

Spring AOP 最核心的模式就是代理模式。

常见场景：

- `@Transactional` 事务管理
- `@Async` 异步调用
- `@Cacheable` 缓存增强
- `@Aspect` 切面逻辑

Spring 会在目标对象外面包一层代理对象，调用先进入代理，再决定是否织入额外逻辑。

```java
@Service
public class AccountService {
    @Transactional
    public void transfer() {
        // 业务逻辑
    }
}
```

调用 `transfer()` 时，真正被注入到容器里的往往不是原始 `AccountService`，而是增强后的代理对象。执行链路大致如下：

```text
调用方
  ↓
代理对象（JDK 动态代理 / CGLIB）
  ↓
事务拦截器 TransactionInterceptor
  ↓
目标方法 AccountService.transfer()
  ↓
提交 / 回滚事务
```

Spring 常见两种代理方式：

- **JDK 动态代理**：目标类实现了接口时优先使用
- **CGLIB 代理**：目标类没有接口时使用，底层通过继承生成子类

这题经常顺带追问：**为什么 Spring AOP 默认不能拦截 private / final 方法？**
因为代理模式本质上是在“外层包一层”，不是改字节码本体；`final` 无法被子类覆写，`private` 也不参与外部多态调用。

#### 4. 模板方法模式（Template Method Pattern）——固定流程 + 可变步骤

Spring 里带 `Template` 后缀的类，几乎都在体现模板方法模式：

- `JdbcTemplate`
- `RedisTemplate`
- `RestTemplate`
- `KafkaTemplate`
- `MongoTemplate`

以 `JdbcTemplate` 为例，JDBC 原生开发要自己写很多样板代码：

1. 获取连接
2. 创建 Statement
3. 绑定参数
4. 执行 SQL
5. 处理结果集
6. 关闭资源
7. 异常处理

Spring 把“固定不变的流程”封装起来，把“可变的业务片段”留给你通过回调实现：

```java
List<User> users = jdbcTemplate.query(
    "select id, name from user where age > ?",
    new Object[]{18},
    (rs, rowNum) -> new User(rs.getLong("id"), rs.getString("name"))
);
```

在这个例子里：

- 获取连接、执行 SQL、异常转换、关闭资源 → Spring 固定完成
- 每一行如何映射成对象 → 由你提供 `RowMapper`

这正是模板方法模式的经典特征：

- **骨架流程由父类/框架定义**
- **个别步骤留给子类或回调定制**

#### 5. 观察者模式（Observer Pattern）——Spring 事件机制

Spring 事件发布/监听机制就是观察者模式的标准实现。

核心角色：

- **事件发布者**：`ApplicationEventPublisher`
- **事件对象**：`ApplicationEvent` 或任意普通对象（Spring 4.2+）
- **事件监听器**：`ApplicationListener` 或 `@EventListener`

```java
@Component
public class OrderCreatedListener {
    @EventListener
    public void handle(OrderCreatedEvent event) {
        System.out.println("监听到订单创建事件：" + event.getOrderId());
    }
}
```

```java
publisher.publishEvent(new OrderCreatedEvent(this, orderId));
```

它的价值在于**解耦**：

- 下单服务只负责“发布事件”
- 积分、通知、日志等后续逻辑作为监听器独立处理
- 发布方不需要知道谁会消费事件

这就是观察者模式最经典的应用：**一处发生变化，多处自动响应，但彼此不直接依赖。**

#### 6. 适配器模式（Adapter Pattern）——统一调用入口

Spring MVC 中 `HandlerAdapter` 是适配器模式的代表。

为什么需要它？因为不同类型的 Handler（Controller）调用方式可能不同，如果 `DispatcherServlet` 直接写死调用逻辑，就无法扩展。

于是 Spring 设计成：

```text
DispatcherServlet
   ↓
找到 Handler
   ↓
交给对应的 HandlerAdapter
   ↓
由 Adapter 负责真正调用 Handler
```

这就相当于：

- `DispatcherServlet` 只认统一接口
- 不同风格的处理器通过适配器“翻译”成统一调用方式

适配器模式的好处是：**调用方不需要知道被适配对象的具体细节。**

除了 MVC，Spring AOP 里也有 `AdvisorAdapter` 之类的设计，用于把不同 Advice 类型统一适配。

#### 7. 责任链模式（Chain of Responsibility Pattern）——请求逐层过滤与增强

Spring Web 和 Spring Security 里责任链模式非常明显。

典型场景：

- `FilterChain`
- `HandlerInterceptor` 链
- Spring Security 的过滤器链 `SecurityFilterChain`

请求进入系统后，不是一步到 Controller，而是会依次经过多个过滤/拦截节点：

```text
HTTP Request
  ↓
Filter1（编码）
  ↓
Filter2（鉴权）
  ↓
Filter3（日志）
  ↓
DispatcherServlet
  ↓
Interceptor1（权限）
  ↓
Interceptor2（审计）
  ↓
Controller
```

每个节点只关心自己的职责，处理完再交给下一个节点。这种模式的优势在于：

- 职责拆分清晰
- 顺序可配置
- 增删一个处理节点代价小

所以责任链模式在 Spring 的 Web 请求处理链上几乎无处不在。

---

### 第三层：实践应用

#### 真实开发里最该会认的 5 类场景

如果面试官追问“你在实际开发里最常见的是哪些”，可以这么落地：

1. **IoC 容器创建 Bean** → 工厂模式 + 单例模式
2. **`@Transactional` / `@Cacheable` / `@Async`** → 代理模式
3. **`JdbcTemplate` / `RedisTemplate`** → 模板方法模式
4. **Spring 事件发布监听** → 观察者模式
5. **Filter / Interceptor / Security 链** → 责任链模式

这是最贴近业务开发、也是最容易结合项目经验的答法。

#### 一个综合例子：下单流程里的模式协作

假设有一个电商下单接口：

```java
@Transactional
public void createOrder(CreateOrderCommand command) {
    orderRepository.save(...);
    applicationEventPublisher.publishEvent(new OrderCreatedEvent(...));
}
```

这里其实已经串了多个设计模式：

- `OrderService` Bean 由 Spring 容器工厂创建 → **工厂模式**
- 默认只有一个 `OrderService` 实例 → **单例模式**
- `@Transactional` 生效靠代理 → **代理模式**
- JDBC 落库底层常通过 `JdbcTemplate` / ORM 模板封装流程 → **模板方法模式**
- 订单创建后发通知、加积分 → **观察者模式**
- 请求进 Controller 前经过 Filter、Interceptor、Security → **责任链模式**

这就是为什么说 Spring 不是“零散用了几个模式”，而是把多个模式协同成一套完整基础设施。

---

### 第四层：深入思考

#### 1. Spring 为什么特别偏爱代理模式

因为 Spring 的很多核心能力都要求：

- **不侵入业务代码**
- **运行时动态增强**
- **对业务类低耦合**

代理模式天然适合这个目标。你写一个普通 Service，Spring 在外面包一层，就能给你加事务、日志、监控、缓存、鉴权。业务代码几乎无感知，这正是 Spring 哲学里“非侵入式（non-invasive）”的重要体现。

#### 2. Spring 为什么模板类这么多

因为基础设施代码最大的特点就是：**流程很稳定，变化点很局部。**

例如数据库访问、缓存访问、HTTP 调用，这些事情的“通用骨架”几乎固定，但每次真正变化的是：

- SQL 是什么
- 参数是什么
- 结果如何映射

模板方法模式正适合这种“80% 固定、20% 可变”的场景。所以 Spring 大量提供 `XXXTemplate`，本质是在复用流程骨架，降低样板代码。

#### 3. Spring MVC 为什么一定要适配器

因为框架要考虑扩展性。假如没有适配器，`DispatcherServlet` 就得知道每种 Controller 的调用细节，未来一旦扩展新的处理器类型，核心调度器就得改。用了适配器后：

- 核心调度器稳定
- 新类型只要扩展新的 Adapter 即可
- 框架开放扩展、封闭修改

这其实也顺带体现了**开闭原则（Open-Closed Principle）**。

#### 4. 面试官高频追问方向

- **Spring 里最核心的设计模式是哪一个？**
  - 如果只能选一个，通常答 **代理模式** 或 **工厂模式** 都可以
  - 工厂模式是 IoC 的根，代理模式是 AOP 的魂
- **`BeanFactory` 和 `FactoryBean` 有什么区别？**
  - 前者是容器本身，后者是“专门生产某种 Bean 的工厂 Bean”
- **Spring 单例和传统单例一样吗？**
  - 不一样，Spring 是容器级单例，不是 JVM 绝对单例
- **为什么 `@Transactional` 会失效？**
  - 本质还是代理没生效，比如自调用、非 public 方法、未经过代理对象调用等

---

## 回答思路

### 答题逻辑框架

面试时建议按 **“先总后分，按模块展开”** 的结构回答，控制在 **3-4 分钟**：

```text
1. 先给总论
   Spring 是框架级基础设施，设计模式很多，重点集中在 IoC、AOP、MVC 三块

2. 按模块展开
   IoC：工厂模式、单例模式
   AOP：代理模式
   基础设施：模板方法模式、观察者模式
   MVC / Web：适配器模式、责任链模式

3. 每个模式带一个 Spring 类名或场景
   BeanFactory / ApplicationContext
   @Transactional
   JdbcTemplate
   ApplicationEventPublisher
   HandlerAdapter
   FilterChain / InterceptorChain

4. 最后总结
   IoC 用工厂管对象，AOP 用代理做增强，MVC 用适配和责任链串流程
```

### 重点得分点

- ✅ 能按 **IoC / AOP / MVC** 分模块回答，而不是乱报模式名
- ✅ 能说出 **`BeanFactory` / `ApplicationContext` → 工厂模式**
- ✅ 能说出 **`@Transactional` / AOP → 代理模式**
- ✅ 能说出 **`JdbcTemplate` → 模板方法模式**
- ✅ 能说出 **`HandlerAdapter` → 适配器模式**
- ✅ 能说出 **Filter / Interceptor / SecurityFilterChain → 责任链模式**

### 常见误区

- ❌ 只背“有工厂、单例、代理、观察者”但举不出 Spring 场景
- ❌ 把 `FactoryBean` 和 `BeanFactory` 混为一谈
- ❌ 说 Spring 单例就是 JVM 全局单例——不准确，它是容器级单例
- ❌ 说 AOP 是装饰器模式——更准确的标准答案应是**代理模式**
- ❌ 只会讲 IoC 和 AOP，不会把 MVC 里的适配器、责任链答出来

### 过渡话术

- **从总论切入**：
  “Spring 作为一个框架，设计模式非常多，但面试里高频考的主要集中在 IoC、AOP 和 MVC 三块。我按这三个模块拆开讲会更清楚。”

- **从 IoC 过渡到 AOP**：
  “IoC 解决的是对象怎么创建和管理，AOP 解决的是对象创建出来之后，怎么在不改业务代码的情况下做增强，所以这里核心就切到代理模式了。”

- **从 AOP 过渡到 MVC**：
  “如果说代理模式是 Spring 在服务层增强能力的核心，那到了 Web 层，Spring 更强调统一调度与流程编排，所以会看到适配器模式和责任链模式。”

### 时间分配建议

- **总时长 3-4 分钟**
- 30 秒讲总论
- 2 分钟讲 7 个高频模式及对应 Spring 场景
- 30-60 秒总结设计哲学与高频追问

如果时间不够，优先保住这四个：

1. 工厂模式
2. 单例模式
3. 代理模式
4. 模板方法模式

这是最基础的得分盘；再补适配器、观察者、责任链，就是加分项。

---

> 📋 **分类**: spring
> 🏷️ **标签**: `Spring`, `设计模式`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-20 00:00:00
