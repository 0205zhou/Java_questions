---
id: q0094
question: "Gateway的路由断言工厂有哪些？"
category: distributed
tags: ["Path", "Header", "Weight", "路由断言", "PredicateFactory", "Query", "Gateway", "Method"]
difficulty: medium
created: 2026-08-31 17:52:43
source: 用户输入
---

# Gateway的路由断言工厂有哪些？

## 联想记忆法

### 记忆口诀/联想

**口诀：时间、头脸、路法、参数、来源、权重、版本、请求体。**

可以把 Gateway 的路由断言工厂按“看什么来决定路由”分组记忆：

- **看时间**：`After`、`Before`、`Between`
- **看请求外观**：`Cookie`、`Header`、`Host`
- **看请求路径和方法**：`Path`、`Method`
- **看参数**：`Query`
- **看来源地址**：`RemoteAddr`、`XForwardedRemoteAddr`
- **看流量权重**：`Weight`
- **看接口版本**：`Version`
- **看请求体**：`ReadBody`

### 记忆原理

断言（Predicate）本质上就是“这条请求符不符合某个条件”。所以不要把它当成零散类名去背，而要按“请求的哪些维度可以被拿来做匹配”来记，这样既容易背，也更接近实际配置思路。

### 关联知识

- 一条路由可以配置多个断言，多个断言通常按逻辑 **AND** 组合。
- 断言负责“能不能进这条路由”，过滤器负责“进来后怎么处理”。
- 不同 Spring Cloud Gateway 版本内置断言可能演进，但常用核心断言长期稳定。

## 深度解答

### 第一层：核心概念

Gateway 的 **Route Predicate Factory（路由断言工厂）** 用来定义路由匹配条件。只有请求满足断言条件，Gateway 才会命中该路由并继续执行后续过滤器和转发逻辑。

按照 Spring Cloud Gateway 官方文档当前内置列表，常见断言工厂包括：

1. `After`
2. `Before`
3. `Between`
4. `Cookie`
5. `Header`
6. `Host`
7. `Method`
8. `Path`
9. `Query`
10. `RemoteAddr`
11. `Weight`
12. `XForwardedRemoteAddr`
13. `Version`
14. `ReadBody`

### 第二层：分类理解

#### 1. 时间类断言

- `After`：某个时间点之后生效
- `Before`：某个时间点之前生效
- `Between`：某个时间区间内生效

适合：

- 活动开关
- 灰度窗口
- 维护窗口

```yaml
- After=2026-08-31T10:00:00+08:00[Asia/Shanghai]
```

#### 2. 请求头与域名类断言

- `Cookie`：匹配 Cookie 名称和值
- `Header`：匹配请求头
- `Host`：匹配 Host

适合：

- 多租户
- 渠道分流
- 域名路由

```yaml
- Header=X-Request-Id, \d+
- Host=**.example.com
```

#### 3. 方法与路径类断言

- `Method`：匹配 HTTP 方法
- `Path`：匹配请求路径

这是最常用的一类。

```yaml
- Method=GET,POST
- Path=/order/**
```

#### 4. 参数类断言

- `Query`：匹配查询参数是否存在，或是否匹配某个正则

适合：

- 特定参数开关
- 简单灰度路由
- 调试接口分流

#### 5. 客户端来源类断言

- `RemoteAddr`：按客户端 IP/CIDR 匹配
- `XForwardedRemoteAddr`：按 `X-Forwarded-For` 头中的真实来源地址匹配

适合：

- 内网接口保护
- 白名单控制
- 反向代理链路下的来源控制

要注意：如果网关前面还有 Nginx、SLB、WAF，仅用 `RemoteAddr` 不一定拿到最终真实客户端 IP。

#### 6. 流量分配类断言

- `Weight`：按权重分流

适合：

- 金丝雀发布
- 蓝绿发布
- 灰度流量切换

例如同一组中：

- `Weight=group1, 8`
- `Weight=group1, 2`

大致表示 80% 流量走一条路由，20% 走另一条。

#### 7. 版本类断言

- `Version`：按 API 版本匹配

适合：

- 新旧接口并存
- 接口版本演进

这个断言依赖 Spring WebFlux 的 API version 配置来解析版本。

#### 8. 请求体类断言

- `ReadBody`：读取请求体并按自定义谓词判断

它通常只能通过 Java DSL 配置，不能像普通断言那样直接用 YAML 表达复杂 Lambda 逻辑。适合少量特殊场景，不适合滥用，因为它会引入请求体读取和缓存成本。

### 第三层：实践应用

一个典型路由可以组合多个断言：

```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: order_route
          uri: lb://order-service
          predicates:
            - Path=/api/order/**
            - Method=GET,POST
            - Header=X-App-Id, app-.*
```

这表示：只有同时满足路径、方法和请求头条件的请求，才会转发到 `order-service`。

### 第四层：深入思考

1. 断言工厂是“**选路规则**”，不是“业务逻辑”。
2. 多个断言通常是 AND 关系，因此配置过多会让路由命中条件过于苛刻。
3. `Path`、`Method`、`Header`、`Query` 是最常用组合。
4. `Weight` 和 `Version` 更偏发布治理能力。
5. `ReadBody` 功能强，但成本也高，通常只在确实需要按请求体内容路由时使用。

## 回答思路

### 答题逻辑框架

1. 先解释路由断言工厂是什么。
2. 按类别列举内置断言。
3. 重点展开常用的 `Path`、`Method`、`Header`、`Query`。
4. 再补充 `Weight`、`Version`、`ReadBody` 这类加分项。

### 重点得分点

- 能列出主流内置断言。
- 能按类别讲，而不是机械背名字。
- 能说出断言负责选路、过滤器负责处理。
- 能说出多个断言通常是 AND 关系。

### 常见误区

- 把断言工厂和过滤器工厂混淆。
- 只会说 `Path`，不知道还有时间、来源、权重和版本维度。
- 在代理链路下误用 `RemoteAddr` 判断真实来源。

### 面试话术

“Gateway 的路由断言工厂就是路由匹配条件，常见内置的有 `After`、`Before`、`Between`、`Cookie`、`Header`、`Host`、`Method`、`Path`、`Query`、`RemoteAddr`、`Weight`，在新版文档里还有 `XForwardedRemoteAddr`、`Version`、`ReadBody`。实际最常用的是 `Path + Method + Header/Query`，它们负责选路，后面的过滤器再负责鉴权、限流和改写。”


---

> 📋 **分类**: distributed
> 🏷️ **标签**: `Path` `Header` `Weight` `路由断言` `PredicateFactory` `Query` `Gateway` `Method`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-31 17:52:43
