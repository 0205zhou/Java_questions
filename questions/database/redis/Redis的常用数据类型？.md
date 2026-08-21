---
id: q0068
question: "Redis的常用数据类型？"
category: redis
tags: ["Redis", "String", "Hash", "ZSet", "Stream"]
difficulty: medium
created: 2026-08-21 01:15:00
source: 用户输入
---

# Redis的常用数据类型？

## 联想记忆法

### 记忆口诀/联想

**口诀：值串 String，对象 Hash，队列 List，去重 Set，排行 ZSet，位图统签到，Geo 管位置，Stream 管消息。**

可以把 Redis 常用类型理解成一套“工具箱”：

- 只放一个值，用 **String**
- 放一个对象，用 **Hash**
- 按顺序排队，用 **List**
- 做集合去重，用 **Set**
- 既要集合又要排序，用 **ZSet**
- 做签到布尔位，用 **Bitmap**
- 做 UV 去重统计，用 **HyperLogLog**
- 做经纬度附近搜索，用 **GEO**
- 做消息流和消费组，用 **Stream**

### 记忆原理

这套记法从“业务意图”出发，不从底层实现出发。因为面试官问数据类型，通常不是想听你机械背名字，而是想知道你能不能根据需求选对结构。把“类型”和“适用场景”绑定起来，记忆和实战都会更稳。

### 关联知识

- 会关联到 **时间复杂度**：不同类型命令复杂度不同
- 会关联到 **底层结构**：如 SDS、哈希表、跳表、listpack
- 会关联到 **大 Key 问题**：同一个类型也可能因为设计不当变成大 Key
- 会关联到 **业务选型**：消息队列到底用 List 还是 Stream、排行榜为什么用 ZSet

---

## 深度解答

### 1. 核心概念：Redis 的价值很大一部分来自“数据结构多样”

很多数据库存数据的方式比较统一，而 Redis 不一样。它直接把常见业务场景拆成多种数据结构，所以你做计数、去重、排序、队列、位置检索时，不需要自己在应用层硬拼逻辑。

面试时可以先给结论：**Redis 并不是只有 key-value，而是围绕业务操作提供了多种结构化能力。**

### 2. String：最基础也最常用

`String` 是 Redis 最基础的数据类型，但它并不只是“字符串”，还可以存：

- 普通文本
- 数字计数
- JSON 串
- 序列化对象
- 二进制内容

常用命令：

```redis
SET user:1 zhangsan
GET user:1
INCR article:100:view
DECR stock:sku:9001
```

典型场景：

- 缓存对象
- 计数器
- 分布式锁的锁值
- Token 和验证码

如果面试官问“为什么 String 用得最多”，你可以答：因为很多业务状态本质上都能抽象成一个值。

### 3. Hash：适合对象字段存储

`Hash` 适合一个 key 对应多个字段的场景，相当于 Redis 里存了一个轻量对象。

```redis
HSET user:1 name zhangsan age 20 city beijing
HGET user:1 name
HGETALL user:1
```

典型场景：

- 用户信息
- 商品属性
- 配置集合

相比把整个对象序列化成一个 String，Hash 的好处是**可以只改一个字段，不必整对象回写**。但字段特别多或对象特别大时，也要注意大 Hash 问题。

### 4. List：有序、可重复，适合队列

`List` 是一个有序列表，支持两端插入和弹出。

```redis
LPUSH task_queue job1
LPUSH task_queue job2
RPOP task_queue
LRANGE task_queue 0 -1
```

典型场景：

- 简单消息队列
- 最新动态列表
- 评论时间流

不过现在如果要做更完整的消息流处理，很多时候会更推荐 `Stream`，因为 List 不支持消费组这类能力。

### 5. Set：无序、不重复，适合去重和关系运算

`Set` 的特点是元素不重复。

```redis
SADD user:1:tags java redis mysql
SMEMBERS user:1:tags
SINTER user:1:follow user:2:follow
```

典型场景：

- 标签集合
- 黑名单、白名单
- 共同好友、共同关注
- 业务去重

它的强项是**集合关系运算**，比如交集、并集、差集，这在推荐系统和社交关系中很常见。

### 6. ZSet：可排序集合，排行榜核心结构

`ZSet` 是 Redis 非常有代表性的类型。它在 Set 的基础上为每个元素引入一个 `score`，因此既能去重，又能排序。

```redis
ZADD rank:game 100 userA
ZADD rank:game 120 userB
ZREVRANGE rank:game 0 9 WITHSCORES
ZRANK rank:game userA
```

典型场景：

- 积分排行榜
- 热门榜单
- 延迟任务
- 按权重排序的数据

它的底层常结合跳表和哈希表，所以查成员与查排名都比较高效。

### 7. Bitmap：海量布尔状态非常省空间

Bitmap 本质上不是独立新结构，而是对 String 做位操作。  
如果你只关心“是/否、签/未签、在线/离线”，它会非常适合。

```redis
SETBIT sign:20260821:1001 1 1
GETBIT sign:20260821:1001 1
BITCOUNT sign:20260821:1001
```

典型场景：

- 用户签到
- 活跃状态统计
- 在线标记

它的优点是单位数据占用极小，但不适合存复杂业务信息。

### 8. HyperLogLog：做基数统计

HyperLogLog 适合统计“去重后的数量”，例如 UV。

```redis
PFADD uv:20260821 user1 user2 user3
PFCOUNT uv:20260821
```

典型场景：

- 网站 UV
- 独立设备数
- 去重访问统计

优点是占用内存极小，缺点是有误差，所以适合“看趋势和规模”，不适合做严格精准计费。

### 9. GEO：地理位置处理

Redis 提供了地理位置能力，可以存经纬度并做附近搜索。

```redis
GEOADD shop 116.397128 39.916527 beijing
GEODIST shop beijing shanghai km
GEORADIUS shop 116.39 39.90 5 km
```

典型场景：

- 附近门店
- 附近的人
- 配送距离计算

它适合轻量位置服务，但如果是复杂地图路线规划，就不是 Redis 的擅长范围了。

### 10. Stream：更现代的消息流结构

`Stream` 是 Redis 较新的消息流模型，支持消息 ID、消费组、确认机制。

```redis
XADD order_stream * orderId 1001 userId 88
XGROUP CREATE order_stream g1 0
XREADGROUP GROUP g1 c1 COUNT 1 STREAMS order_stream >
```

典型场景：

- 订单异步处理
- 事件通知
- 日志流转

相比 List，它更像一个真正的消息流系统，所以在 Redis 内部做轻量 MQ 时很常见。

### 11. 实践应用：如何快速选型

如果面试官问到“那你怎么选”，可以这样答：

| 需求 | 优先类型 |
|---|---|
| 存简单值、计数 | `String` |
| 存对象字段 | `Hash` |
| 做先进先出队列 | `List` |
| 做标签和去重 | `Set` |
| 做排行榜和延迟任务 | `ZSet` |
| 做签到和状态位 | `Bitmap` |
| 做 UV 去重统计 | `HyperLogLog` |
| 做附近搜索 | `GEO` |
| 做消息流 | `Stream` |

### 12. 深入思考：类型选错，Redis 也会被你用慢

#### 1. 不要把所有对象都塞成一个大 JSON String

这样读写简单，但局部更新成本高，而且对象一大就容易形成大 Key。

#### 2. 不要为了“看起来统一”而硬用同一种结构

比如排行榜如果用 List 或 Set 实现，逻辑会变复杂，性能也不如 ZSet。

#### 3. 类型会影响后续扩展能力

你今天只是做“简单队列”，明天可能就要“多消费者、失败重试、消息确认”。  
这时 List 和 Stream 的差别就会立刻体现出来。

---

## 回答思路

### 答题逻辑框架

建议这样回答：

1. 先说 Redis 常用数据类型不止五种，但核心最常用的是 `String`、`Hash`、`List`、`Set`、`ZSet`
2. 再补充 `Bitmap`、`HyperLogLog`、`GEO`、`Stream`
3. 每说一个类型，最好带一个业务场景
4. 最后再总结“选类型就是选操作模型”

### 重点得分点

- 说出五大基础类型是基础分
- 能补充 `Bitmap`、`HyperLogLog`、`GEO`、`Stream` 是加分项
- 能把 **类型和业务场景一一对应** 是高分项
- 能指出 `ZSet` 常用于排行榜、`Stream` 适合轻量消息流，会显得更实战

### 常见误区

- 误区 1：Redis 只有五种类型  
  正解：基础常见是五种，但还有位图、基数统计、GEO、Stream 等扩展能力

- 误区 2：Hash 一定比 String 存对象更好  
  正解：要看字段数量、访问模式和对象大小

- 误区 3：List 就能完全替代消息队列  
  正解：简单队列可以，复杂消息语义更适合 Stream 或专业 MQ

### 面试话术

“Redis 最常用的数据类型是 String、Hash、List、Set、ZSet。String 常用于缓存和计数器，Hash 常用于对象字段，List 适合简单队列，Set 适合去重和关系运算，ZSet 适合排行榜。另外在一些细分场景里，还会用 Bitmap 做签到、HyperLogLog 做 UV、GEO 做附近搜索、Stream 做消息流。核心原则是：业务需要什么操作模型，就选对应的数据结构。”

---

> 📋 **分类**: redis
> 🏷️ **标签**: `Redis` `String` `Hash` `ZSet` `Stream`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-21 01:15:00
