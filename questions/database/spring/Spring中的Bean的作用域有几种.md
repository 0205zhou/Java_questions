---
id: q0080
question: "Spring中的Bean的作用域有几种"
category: spring
tags: ["Spring", "Bean", "作用域", "Scope"]
difficulty: medium
created: 2026-08-26 10:53:45
source: 用户输入
---

# Spring中的Bean的作用域有几种

## 联想记忆法

### 记忆口诀/联想

**口诀：单例全局一份，原型每取一份；请求、会话、应用、WebSocket，跟着 Web 生命周期走。**

- **singleton**：容器中默认一份。
- **prototype**：每次向容器获取时创建一个新对象。
- **request**：一次 HTTP 请求一份。
- **session**：一个 HTTP 会话一份。
- **application**：一个 Web `ServletContext` 一份。
- **websocket**：一个 WebSocket 会话一份。

### 记忆原理

作用域回答的不是“类能不能创建”，而是“**同一个 Bean 定义在什么生命周期内复用实例**”。先判断应用是不是 Web 环境，再根据共享范围从大到小记：容器、每次获取、请求、会话、应用、WebSocket。

### 关联知识

- 与生命周期关联：作用域决定创建时机、实例复用范围和销毁时机。
- 与代理关联：singleton 注入 request Bean 时，需要 scoped proxy 或 `ObjectProvider`。
- 与线程安全关联：singleton 不是线程安全保证，共享可变状态仍需并发控制。
- 与 Spring 注解关联：`@Scope`、`@RequestScope`、`@SessionScope`、`@ApplicationScope` 可以声明作用域。

## 深度解答

### 第一层：核心概念

Spring Bean 作用域（Scope）用于定义 Bean 实例的生命周期和复用范围。Spring Framework 常见的标准作用域有 6 种，其中前两种适用于普通 IoC 容器，后四种是 Web 环境作用域：

| 作用域 | 实例复用范围 | 典型场景 |
|---|---|---|
| `singleton` | 每个 Spring 容器一个实例 | Service、Repository、配置组件 |
| `prototype` | 每次从容器获取时创建新实例 | 有独立状态的短生命周期对象 |
| `request` | 每个 HTTP 请求一个实例 | 请求上下文、请求级缓存 |
| `session` | 每个 HTTP Session 一个实例 | 会话级购物车或用户状态 |
| `application` | 每个 Web 应用的 ServletContext 一个实例 | Web 应用级共享对象 |
| `websocket` | 每个 WebSocket 会话一个实例 | 长连接会话状态 |

#### 1. singleton：默认作用域

```java
@Service
@Scope(ConfigurableBeanFactory.SCOPE_SINGLETON)
public class UserService {
}
```

不写 `@Scope` 时默认就是 singleton。在同一个 Spring `ApplicationContext` 中，容器通常只创建一个实例并缓存，后续按名称获取得到同一个对象。这里的“单例”是**容器级单例**，不是 JVM 中绝对只能有一个实例；不同容器、不同 ClassLoader 或手动 `new` 都可能产生其他实例。

#### 2. prototype：原型作用域

```java
@Component
@Scope(ConfigurableBeanFactory.SCOPE_PROTOTYPE)
public class TaskContext {
}
```

每次调用 `getBean(TaskContext.class)` 时，容器都会创建一个新实例。prototype 适合对象内部带有本次任务状态、不能被多个线程共享的场景。但它并不意味着“每次调用业务方法都自动新建”，如果 prototype Bean 直接注入 singleton，默认只会在 singleton 创建时注入一次。

#### 3. request：请求作用域

```java
@RequestScope
@Component
public class RequestContext {
}
```

在一次 HTTP 请求内多次获取得到同一个实例，不同请求之间实例不同。该作用域依赖 Web 上下文，通常用于保存请求 ID、请求级缓存或请求范围的用户信息。脱离请求线程直接访问时可能抛出作用域未激活异常。

#### 4. session：会话作用域

```java
@SessionScope
@Component
public class CartContext {
}
```

同一个 HTTP Session 复用一个实例，不同 Session 使用不同实例。因为 Session 可能跨多个请求被并发访问，所以其中的可变状态还要考虑线程安全、序列化和集群会话同步问题。

#### 5. application：应用作用域

```java
@ApplicationScope
@Component
public class ApplicationSettings {
}
```

它与 Web 应用的 `ServletContext` 关联，在一个 Web 应用范围内复用实例。它和 singleton 很像，但语义不同：singleton 绑定 Spring 容器，application 绑定 Servlet Web 应用。如果一个 Web 应用中存在多个 Spring 容器，两者的实例数量可能不同。

#### 6. websocket：WebSocket 作用域

该作用域按 WebSocket 会话复用 Bean，适合保存一次 WebSocket 长连接期间的状态。它不是普通非 Web Spring 容器默认就能使用的作用域，需要 WebSocket 相关基础设施和作用域上下文支持。

### 第二层：底层原理

作用域信息会保存在 BeanDefinition 中。singleton Bean 通常由 `DefaultSingletonBeanRegistry` 缓存；prototype Bean 每次创建但不由容器长期缓存。request、session 等 Web 作用域则通过对应的 `Scope` 实现，把实例保存到当前请求、Session 或 WebSocket 的上下文中。

作用域不匹配是高频问题。比如 singleton 依赖 request Bean：singleton 只创建一次，但 request Bean 应该随请求变化，直接注入真实对象会把某一次请求实例固定下来。Spring 通常通过 scoped proxy 注入一个代理，调用时再从当前请求上下文获取真实对象；也可以注入 `ObjectProvider<RequestContext>`，在使用时调用 `getObject()`。

```java
@Service
public class AuditService {
    private final ObjectProvider<RequestContext> contextProvider;

    public AuditService(ObjectProvider<RequestContext> contextProvider) {
        this.contextProvider = contextProvider;
    }

    public String requestId() {
        return contextProvider.getObject().getRequestId();
    }
}
```

### 第三层：实践应用

声明作用域有两种常见方式：

```java
@Component
@Scope(value = WebApplicationContext.SCOPE_REQUEST,
       proxyMode = ScopedProxyMode.TARGET_CLASS)
public class RequestToken {
}
```

或者使用语义更清晰的组合注解：

```java
@RequestScope
@Component
public class RequestToken {
}
```

普通 Service 和 Repository 通常使用 singleton，但不要在其中保存用户请求级的可变字段：

```java
@Service
public class UserService {
    // 不要把当前用户、当前请求参数放到实例字段中
    public User find(Long id) {
        return loadFromDatabase(id);
    }
}
```

如果需要每次使用都获得一个新的 prototype Bean，可以注入 `ObjectProvider`、`Provider<T>`，或者使用方法注入；直接把 prototype 当普通依赖注入 singleton 通常达不到预期。

### 第四层：深入思考

prototype Bean 的一个重要边界是：Spring 负责创建和依赖注入，但通常不负责完整的销毁回调管理。需要释放资源的 prototype 对象必须由业务方或专门的工厂明确管理，否则可能出现连接、线程或文件句柄泄漏。

singleton 也不等于线程安全。Spring 只保证实例复用，不会自动保护实例字段；无状态 Bean 最容易安全复用，有状态组件应缩小作用域或使用并发安全的数据结构。request/session 作用域也不能绕过分布式系统中的会话共享和集群一致性问题。

## 回答思路

### 答题逻辑框架

1. 先说 Spring 常见 6 种作用域，指出 singleton 是默认值。
2. 重点比较 singleton 与 prototype。
3. 再讲 Web 环境的 request、session、application、websocket。
4. 最后补充作用域代理、原型销毁和线程安全。

### 重点得分点

- 能完整说出 6 种标准作用域。
- 能准确说明 prototype 是每次从容器获取时创建，而非每次业务调用创建。
- 能指出 request、session 等需要 Web 上下文。
- 能解释短作用域注入长作用域时使用代理或 `ObjectProvider`。

### 常见误区

- 误区 1：singleton 在整个 JVM 只有一个。正解：是 Spring 容器级单例。
- 误区 2：singleton 自动线程安全。正解：共享状态仍需并发控制。
- 误区 3：prototype 注入 singleton 后每次都会新建。正解：默认只注入一次。
- 误区 4：prototype 的销毁方法一定由 Spring 调用。正解：容器通常不负责完整销毁管理。
- 误区 5：request 作用域可以在任意线程访问。正解：必须有激活的请求上下文。

### 面试话术

“Spring 常见 Bean 作用域有 singleton、prototype，以及 Web 环境下的 request、session、application 和 websocket。singleton 是默认的容器级单例，prototype 是每次从容器获取时新建。Web 作用域分别绑定请求、会话、ServletContext 和 WebSocket 会话。需要注意作用域不匹配：把 request Bean 注入 singleton 时要使用 scoped proxy 或 ObjectProvider；prototype 的销毁和线程安全也不能交给作用域自动解决。”

### 时间分配建议

六种作用域 70 秒，singleton/prototype 对比 30 秒，作用域代理和误区 40 秒。


---

> 📋 **分类**: spring
> 🏷️ **标签**: `Spring` `Bean` `作用域` `Scope`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-26 10:53:45
