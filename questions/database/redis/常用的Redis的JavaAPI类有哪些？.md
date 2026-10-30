---
id: q0113
question: "常用的Redis的JavaAPI类有哪些？"
category: redis
tags: ["RedisTemplate", "Redis", "Lettuce", "Jedis", "Java API", "Redisson"]
difficulty: medium
created: 2026-10-30 20:21:50
source: 用户输入
---

# 常用的Redis的JavaAPI类有哪些？

## 联想记忆法

### 记忆口诀/联想

**口诀：Jedis 直连讲命令，Lettuce 异步靠 Netty；Template 统一做封装，Redisson 对象加锁齐。**

把调用关系想成“业务服务、统一门面、通信司机、Redis 服务端”：`RedisTemplate` 通常是门面，Jedis 和 Lettuce 是具体通信客户端；Redisson 也能直接连接 Redis，但更强调分布式对象。先分清层次，就不会把四者当成完全同级的类。

### 记忆原理

按抽象层记忆，比背类名更容易回答追问。第一层回答“网络请求由谁发”，第二层回答“Spring 如何统一使用”，第三层回答“谁提供锁、集合、限流器”。同一项目可以使用 Lettuce 驱动的 `StringRedisTemplate` 操作缓存，再用 `RedissonClient` 获取分布式锁。

### 关联知识

关联连接池、线程安全、序列化（Serialization）、异步编程、流水线（Pipeline）、Redis 事务和分布式锁。面试官问“常用 API 类”，往往也在考察是否理解客户端和框架的关系。

## 深度解答

### 1. 核心概念：常用的是哪些客户端、接口和模板

Redis 没有一套由 JDK 内置的 Java API，Java 应用通常通过第三方客户端发送 Redis 协议命令。常见入口如下：

| 体系 | 常用类或接口 | 定位与典型用途 |
| --- | --- | --- |
| Jedis | `Jedis`、`JedisPool`、`JedisPooled`、`JedisCluster` | 偏命令式使用；连接池和集群访问 |
| Lettuce | `RedisClient`、`RedisClusterClient`、`StatefulRedisConnection` | 基于 Netty 的通信客户端 |
| Lettuce 命令接口 | `RedisCommands`、`RedisAsyncCommands`、`RedisReactiveCommands` | 同步、异步、响应式调用 |
| Spring Data Redis | `RedisTemplate<K,V>`、`StringRedisTemplate` | 统一的数据访问模板，适合 Spring 应用 |
| Spring 响应式模板 | `ReactiveRedisTemplate`、`ReactiveStringRedisTemplate` | 面向响应式应用的数据访问 |
| Redisson | `Redisson`、`RedissonClient`、`RBucket`、`RMap`、`RLock` | 创建客户端和使用分布式对象 |

这里 `RedisCommands`、`RedissonClient`、`RLock` 等是接口，严格来说不全是“类”。回答时可以沿用题目的口语说法，但应主动说明各自职责，避免只罗列名称。

### 2. 底层原理：抽象层不同，线程模型也不同

Jedis 的常用 API 是同步阻塞式调用，方法返回前等待服务端结果。单个普通 `Jedis` 实例不应由多个线程并发共用，通常从 `JedisPool` 借出连接，操作后归还。`JedisPooled` 把连接池管理封装到入口对象中；`JedisCluster` 负责集群节点和槽位路由。不能把“普通 Jedis 连接不适合共享”扩大为“所有 Jedis API 都不支持多线程”。

Lettuce 基于 Netty 的非阻塞网络通信，底层可通过事件循环处理多个请求，并提供同步、异步和响应式接口。同步 API 仍会阻塞调用线程等待结果，因此“底层非阻塞”不等于“所有调用都立即返回”。普通命令通常可以共享一个线程安全连接，但阻塞命令、事务和连接状态操作需要考虑连接隔离，不能机械地让所有业务共用一条连接。

Spring Data Redis 通过连接工厂（`RedisConnectionFactory`）适配底层客户端。常见调用链是：

```text
业务代码
  -> StringRedisTemplate / RedisTemplate
  -> RedisConnectionFactory
  -> Lettuce 或 Jedis
  -> Redis
```

Spring Boot 常见自动配置默认使用 Lettuce，具体仍由依赖、配置和版本决定。`RedisTemplate` 初始化完成且配置不再变更后可供多线程共享，但底层 `RedisConnection` 不能据此推断为线程安全。响应式 Spring Data Redis 的常用驱动是 Lettuce，不能假定换成 Jedis 后仍然具备同样的响应式能力。

Redisson 同样基于 Netty，除网络访问外，还用 Lua 脚本、发布订阅（Pub/Sub）、定时任务等实现分布式对象语义。比如 `RLock` 提供重入、持有者检查和可选的自动续期，它不是 Java 本地 `ReentrantLock`，也不是只调用一次 `SETNX`。

### 3. 实践应用：Spring 中常用哪些操作接口

`RedisTemplate` 按数据结构提供操作入口：

| 操作入口 | 常见接口 | 对应数据结构 |
| --- | --- | --- |
| `opsForValue()` | `ValueOperations` | String，普通缓存和计数 |
| `opsForHash()` | `HashOperations` | Hash，对象字段 |
| `opsForList()` | `ListOperations` | List，列表和简单队列 |
| `opsForSet()` | `SetOperations` | Set，去重集合 |
| `opsForZSet()` | `ZSetOperations` | Sorted Set，排行榜 |
| `opsForStream()` | `StreamOperations` | Stream，消息流 |

下面假设 Spring 已注入 `StringRedisTemplate`，展示最常用的字符串缓存操作：

```java
import java.time.Duration;
import org.springframework.data.redis.core.StringRedisTemplate;

public class ProductCache {
    private final StringRedisTemplate redis;

    public ProductCache(StringRedisTemplate redis) {
        this.redis = redis;
    }

    public void put(long id, String json) {
        redis.opsForValue().set("product:" + id, json,
                Duration.ofMinutes(10));
    }

    public String get(long id) {
        return redis.opsForValue().get("product:" + id);
    }
}
```

`StringRedisTemplate` 适合字符串键和值，JSON 对象应先通过约定好的 JSON 序列化器转换。使用普通 `RedisTemplate` 时应明确 key、value、hash key 和 hash value 的序列化规则，不能认为 Java 对象一定自动以 JSON 保存。不同序列化器写出的字节不同，可能导致命令行看不懂值，或两个服务使用同样的逻辑 key 却无法互读。

在 Jedis 中，典型模式是 `try (Jedis jedis = pool.getResource()) { ... }`，关闭借出的连接会归还到池中；在 Lettuce 和 Redisson 中，客户端通常作为应用级对象复用，并在应用关闭时释放资源。不要每次请求创建一个客户端和事件循环，否则会增加连接、线程和握手成本。

### 4. 深入思考：如何选择及常见追问

Spring 业务缓存优先考虑模板带来的依赖注入和统一序列化；需要异步或响应式接口时关注 Lettuce；需要分布式锁、信号量等高层能力时考虑 Redisson；已有命令式 Jedis 项目也不必为了“异步更快”盲目迁移，吞吐和延迟取决于负载、连接配置、网络及 Redis 服务端能力。

流水线用于减少网络往返，不自动保证整批命令原子执行。`MULTI/EXEC` 是 Redis 事务机制，也不是关系数据库中可回滚的事务。Spring 的数据库 `@Transactional` 不能直接推导出“Redis 与 MySQL 原子提交”，跨存储一致性仍需要单独设计。客户端线程安全、命令原子性和业务事务一致性是三个不同的问题。

## 回答思路

### 答题逻辑框架

1. 先列出 Jedis、Lettuce、Spring Data Redis、Redisson 四个常见体系。
2. 说明客户端、模板、分布式对象框架的层次关系。
3. 给出 `StringRedisTemplate` 与 `opsForValue()` 等日常入口。
4. 补充线程安全、连接复用和序列化的注意事项。

### 重点得分点与常见误区

关键得分点是能说出具体类名，并解释 `RedisTemplate` 底层仍需客户端。常见误区包括：把 Lettuce 的同步调用说成不阻塞、把所有 Jedis 对象都说成不安全、认为 `RedisTemplate` 默认一定用 JSON、认为 Redisson 只能做锁。

### 过渡话术与时间分配

前 30 秒列体系和定位，接着 60 秒说明调用关系与常用操作，最后 30 秒讲选型与注意事项。可这样衔接：“类名之外，更重要的是分清抽象层，Spring 模板负责统一访问，客户端负责通信，Redisson 还负责分布式对象语义。”

### 面试参考回答

“常用的有 Jedis、Lettuce、Spring Data Redis 的 RedisTemplate 和 StringRedisTemplate，以及 RedissonClient。Jedis 常用连接池配合同步命令，Lettuce 基于 Netty，支持同步、异步和响应式接口。RedisTemplate 是 Spring 的统一访问封装，通常通过 Lettuce 或 Jedis 连接 Redis，按数据类型提供 ValueOperations、HashOperations 等接口。Redisson 则提供 RLock、RMap、RBucket 等分布式对象。选型时我还会考虑连接共享、序列化、部署模式和业务是否需要分布式协调。”


---

> 📋 **分类**: redis
> 🏷️ **标签**: `RedisTemplate` `Redis` `Lettuce` `Jedis` `Java API` `Redisson`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-10-30 20:21:50
