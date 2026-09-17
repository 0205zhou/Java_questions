---
id: q0110
question: "Redis的每个类型添加数据的命令是什么样的？查数据的命令是什么样的？"
category: redis
tags: ["Redis", "数据类型", "命令", "String", "Hash", "List", "Set", "ZSet", "Stream"]
difficulty: medium
created: 2026-09-17 21:20:39
source: 用户输入
---

# Redis的每个类型添加数据的命令是什么样的？查数据的命令是什么样的？

## 联想记忆法

### 记忆口诀/联想

**口诀：String 用 SET/GET，Hash 用 HSET/HGET，List 两边推两边查，Set 用 SADD/SMEMBERS，ZSet 用 ZADD/ZRANGE，Bitmap 按位 SETBIT/GETBIT，HyperLogLog 用 PFADD/PFCOUNT，GEO 用 GEOADD/GEOPOS，Stream 用 XADD/XREAD。**

可以把 Redis 命令理解成“类型名前缀 + 动作”：

- 普通字符串没有明显前缀：`SET`、`GET`
- Hash 命令大多以 `H` 开头：`HSET`、`HGET`
- Set 命令大多以 `S` 开头：`SADD`、`SMEMBERS`
- ZSet 命令大多以 `Z` 开头：`ZADD`、`ZRANGE`
- Stream 命令大多以 `X` 开头：`XADD`、`XREAD`

### 记忆原理

这道题不要死背所有命令，而是按“**写入命令 + 查询命令 + 典型场景**”三个点记。面试时先回答五大基础类型，再补充 Bitmap、HyperLogLog、GEO、Stream，基本就能覆盖常见追问。

### 关联知识

- **数据类型选型**：不同命令对应不同数据结构和业务模型
- **时间复杂度**：`GET`、`HGET`、`SISMEMBER` 通常很快，`SMEMBERS`、`HGETALL`、`LRANGE 0 -1` 可能扫出大 Key
- **大 Key 风险**：查询全部元素类命令要谨慎，比如 `HGETALL`、`SMEMBERS`、`ZRANGE 0 -1`
- **消息队列**：List 能做简单队列，Stream 更适合消费组、消息确认和多消费者场景

---

## 深度解答

### 面试版回答

Redis 每种数据类型都有对应的写入和查询命令。最常用的五种里，String 用 `SET` 写、`GET` 查；Hash 用 `HSET` 写字段、`HGET` 或 `HGETALL` 查；List 用 `LPUSH`/`RPUSH` 写，`LRANGE` 查列表，`LPOP`/`RPOP` 弹出；Set 用 `SADD` 添加，`SMEMBERS` 或 `SISMEMBER` 查询；ZSet 用 `ZADD` 带分数添加，`ZRANGE`/`ZREVRANGE` 按排名查。

扩展类型里，Bitmap 用 `SETBIT` 写位、`GETBIT`/`BITCOUNT` 查；HyperLogLog 用 `PFADD` 添加、`PFCOUNT` 统计基数；GEO 用 `GEOADD` 添加经纬度、`GEOPOS`/`GEODIST`/`GEOSEARCH` 查询；Stream 用 `XADD` 写消息、`XREAD` 或 `XREADGROUP` 读消息。实际项目里，不建议一上来就用查全量的命令，数据量大时应该分页、按范围查，或者用 `SCAN` 类命令渐进式遍历。

### 第一层：核心概念

Redis 的命令设计和数据类型强绑定。回答这类问题时，最好不要只罗列命令，而是说明“这个类型适合什么数据，它怎么添加，怎么查询”。

可以先按下面这张表总览：

| 类型 | 添加数据命令 | 查询数据命令 | 常见用途 |
|---|---|---|---|
| String | `SET`、`MSET`、`INCR` | `GET`、`MGET` | 缓存、计数器、验证码 |
| Hash | `HSET`、`HMSET` | `HGET`、`HMGET`、`HGETALL` | 对象字段、配置 |
| List | `LPUSH`、`RPUSH` | `LRANGE`、`LINDEX`、`LPOP`、`RPOP` | 队列、列表流 |
| Set | `SADD` | `SMEMBERS`、`SISMEMBER`、`SCARD` | 去重、标签、关系运算 |
| ZSet | `ZADD`、`ZINCRBY` | `ZRANGE`、`ZREVRANGE`、`ZSCORE` | 排行榜、延迟任务 |
| Bitmap | `SETBIT` | `GETBIT`、`BITCOUNT` | 签到、布尔状态 |
| HyperLogLog | `PFADD` | `PFCOUNT` | UV、去重基数统计 |
| GEO | `GEOADD` | `GEOPOS`、`GEODIST`、`GEOSEARCH` | 附近的人、附近门店 |
| Stream | `XADD` | `XREAD`、`XRANGE`、`XREADGROUP` | 消息流、事件流 |

### 第二层：按类型展开命令

#### 1. String：一个 key 对应一个 value

String 是最基础的数据类型，可以存字符串、数字、JSON、序列化对象。

添加数据：

```redis
SET user:name zhangsan
SET verify:code:1001 8848 EX 300
MSET user:1:name zhangsan user:1:age 20
INCR article:1001:view
INCRBY stock:sku:1001 10
```

查询数据：

```redis
GET user:name
MGET user:1:name user:1:age
GET article:1001:view
```

说明：

- `SET key value` 是最基本写法
- `SET key value EX seconds` 常用于验证码、Token 缓存
- `INCR`/`INCRBY` 要求 value 能被当作整数处理，常用于计数器

#### 2. Hash：一个 key 下存多个 field

Hash 适合存对象字段，例如用户信息、商品属性、配置项。

添加数据：

```redis
HSET user:1001 name zhangsan
HSET user:1001 age 20 city beijing
HMSET user:1002 name lisi age 22 city shanghai
HINCRBY user:1001 login_count 1
```

查询数据：

```redis
HGET user:1001 name
HMGET user:1001 name age city
HGETALL user:1001
HKEYS user:1001
HVALS user:1001
HLEN user:1001
```

说明：

- 新版本里通常直接用 `HSET` 批量设置多个 field
- `HGETALL` 会一次性取出所有字段，大 Hash 上要谨慎
- 如果只查部分字段，优先用 `HGET` 或 `HMGET`

#### 3. List：有序、可重复，支持两端操作

List 适合队列、时间线、最新记录等场景。

添加数据：

```redis
LPUSH task:queue job1
LPUSH task:queue job2
RPUSH task:queue job3
```

查询数据：

```redis
LRANGE task:queue 0 -1
LRANGE task:queue 0 9
LINDEX task:queue 0
LLEN task:queue
```

弹出数据：

```redis
LPOP task:queue
RPOP task:queue
BLPOP task:queue 5
BRPOP task:queue 5
```

说明：

- `LPUSH + RPOP` 可以做先进先出队列
- `LPUSH + LRANGE 0 9` 可以做最新列表
- `BLPOP`/`BRPOP` 是阻塞弹出，适合简单消费者等待任务

#### 4. Set：无序、不重复

Set 适合去重、标签、黑名单、共同好友等场景。

添加数据：

```redis
SADD user:1001:tags java redis mysql
SADD blacklist userA userB
```

查询数据：

```redis
SMEMBERS user:1001:tags
SISMEMBER user:1001:tags redis
SCARD user:1001:tags
SRANDMEMBER user:1001:tags 2
```

集合运算：

```redis
SINTER user:1:follows user:2:follows
SUNION user:1:follows user:2:follows
SDIFF user:1:follows user:2:follows
```

说明：

- `SADD` 添加重复元素不会报错，但集合里只保留一份
- 判断是否存在用 `SISMEMBER`，不要把所有元素查出来再在应用层判断
- `SMEMBERS` 查全量，大 Set 上要谨慎

#### 5. ZSet：有序集合，每个 member 带 score

ZSet 适合排行榜、热度榜、延迟任务等场景。

添加数据：

```redis
ZADD rank:game 100 userA
ZADD rank:game 120 userB 90 userC
ZINCRBY rank:game 10 userA
```

查询数据：

```redis
ZRANGE rank:game 0 9 WITHSCORES
ZREVRANGE rank:game 0 9 WITHSCORES
ZSCORE rank:game userA
ZRANK rank:game userA
ZREVRANK rank:game userA
ZCOUNT rank:game 100 200
ZRANGEBYSCORE rank:game 100 200 WITHSCORES
```

说明：

- `ZRANGE` 默认按 score 从小到大
- 排行榜通常用 `ZREVRANGE`，按分数从高到低
- 延迟任务可以把执行时间戳作为 score，用 `ZRANGEBYSCORE` 查到期任务

#### 6. Bitmap：按 bit 位记录状态

Bitmap 本质上是 String 的位操作，适合签到、是否活跃、是否在线等布尔状态。

添加数据：

```redis
SETBIT sign:2026-09 1001 1
SETBIT sign:2026-09 16 1
```

查询数据：

```redis
GETBIT sign:2026-09 16
BITCOUNT sign:2026-09
BITPOS sign:2026-09 1
```

说明：

- `SETBIT key offset value` 中 offset 是偏移位，value 只能是 0 或 1
- 做月签到时，offset 可以用日期减一，例如 9 月 17 日对应 offset 16
- Bitmap 很省内存，但只能表达简单状态

#### 7. HyperLogLog：统计去重数量

HyperLogLog 用于基数统计，比如网站 UV、独立访客数。

添加数据：

```redis
PFADD uv:2026-09-17 user1 user2 user3
PFADD uv:2026-09-17 user2
```

查询数据：

```redis
PFCOUNT uv:2026-09-17
PFMERGE uv:2026-09 uv:2026-09-16 uv:2026-09-17
PFCOUNT uv:2026-09
```

说明：

- `PFADD` 添加重复用户不会让统计值重复增长
- `PFCOUNT` 统计的是近似去重数量，不是精确值
- 适合运营统计，不适合订单、库存、金额这类必须精确的场景

#### 8. GEO：地理位置

GEO 适合附近门店、附近的人、配送距离等场景。

添加数据：

```redis
GEOADD shop:city 116.397128 39.916527 beijing_shop
GEOADD shop:city 121.473701 31.230416 shanghai_shop
```

查询数据：

```redis
GEOPOS shop:city beijing_shop
GEODIST shop:city beijing_shop shanghai_shop km
GEOSEARCH shop:city FROMLONLAT 116.40 39.90 BYRADIUS 5 km WITHDIST
```

旧版本常见写法：

```redis
GEORADIUS shop:city 116.40 39.90 5 km WITHDIST
```

说明：

- `GEOADD` 参数顺序是经度、纬度、成员名
- 新版本更推荐 `GEOSEARCH`，老资料里常见 `GEORADIUS`
- Redis GEO 适合轻量附近查询，不负责复杂路线规划

#### 9. Stream：消息流

Stream 适合事件流、轻量消息队列、消费组模型。

添加数据：

```redis
XADD order:stream * orderId 1001 userId 88 amount 99.00
XADD order:stream * orderId 1002 userId 89 amount 199.00
```

查询数据：

```redis
XRANGE order:stream - +
XREVRANGE order:stream + - COUNT 10
XREAD COUNT 2 STREAMS order:stream 0
```

消费组读取：

```redis
XGROUP CREATE order:stream g1 0 MKSTREAM
XREADGROUP GROUP g1 c1 COUNT 1 STREAMS order:stream >
XACK order:stream g1 1758000000000-0
```

说明：

- `XADD key * field value` 中 `*` 表示 Redis 自动生成消息 ID
- `XREAD` 是普通读取，`XREADGROUP` 是消费组读取
- `XACK` 用于确认消息已经处理完成

### 第三层：实践应用

#### 常用命令速查表

| 类型 | 写入示例 | 查询示例 |
|---|---|---|
| String | `SET token:1 abc EX 3600` | `GET token:1` |
| Hash | `HSET user:1 name zhangsan age 20` | `HMGET user:1 name age` |
| List | `LPUSH msg:list m1 m2` | `LRANGE msg:list 0 9` |
| Set | `SADD user:1:roles admin user` | `SISMEMBER user:1:roles admin` |
| ZSet | `ZADD hot:rank 100 item1` | `ZREVRANGE hot:rank 0 9 WITHSCORES` |
| Bitmap | `SETBIT sign:1 16 1` | `GETBIT sign:1 16` |
| HyperLogLog | `PFADD uv:today u1 u2` | `PFCOUNT uv:today` |
| GEO | `GEOADD shops 116.40 39.90 s1` | `GEOSEARCH shops FROMLONLAT 116.4 39.9 BYRADIUS 3 km` |
| Stream | `XADD orders * id 1 status paid` | `XREAD COUNT 10 STREAMS orders 0` |

#### 项目里怎么用

- 缓存用户详情：简单对象可以 `SET user:1 json`，需要频繁改字段可以 `HSET user:1 name age`
- 秒杀库存：用 `DECR` 或 Lua 脚本保证扣减逻辑原子性
- 最新消息列表：用 `LPUSH + LRANGE 0 9`
- 标签去重：用 `SADD` 存用户标签，用 `SISMEMBER` 判断是否存在
- 排行榜：用 `ZINCRBY` 增加分数，用 `ZREVRANGE` 查询 Top N
- 签到：用 `SETBIT` 写每天状态，用 `BITCOUNT` 统计签到次数
- UV：用 `PFADD` 添加用户标识，用 `PFCOUNT` 查去重访问量
- 附近门店：用 `GEOADD` 写门店坐标，用 `GEOSEARCH` 查附近门店
- 订单事件流：用 `XADD` 写事件，用 `XREADGROUP` 多消费者处理

### 第四层：深入思考

#### 1. 查全量命令要慎用

`HGETALL`、`SMEMBERS`、`LRANGE key 0 -1`、`ZRANGE key 0 -1` 都很方便，但如果 key 里数据很多，会一次性拉出大量数据，可能造成 Redis 阻塞、网络传输变大、应用内存升高。线上更推荐按范围分页，或者用 `HSCAN`、`SSCAN`、`ZSCAN` 这类渐进式遍历命令。

#### 2. 写入命令不只是“添加”，还可能改变业务语义

例如 `SET` 默认会覆盖旧值；如果只想不存在时写入，要用 `SET key value NX`。`ZADD` 对已有 member 会更新 score；如果是累计分数，应该用 `ZINCRBY`。所以命令选错不只是语法问题，而是业务语义会变。

#### 3. List 和 Stream 的选择

如果只是简单队列，List 的 `LPUSH + BRPOP` 就够用；如果需要多消费者、消息确认、失败重试、消息历史保留，Stream 更合适。面试时说清这个权衡，会比只背命令更有实战感。

---

## 回答思路

### 答题逻辑框架

1. 先说 Redis 命令和数据类型绑定，回答时按类型展开
2. 先讲五大基础类型：String、Hash、List、Set、ZSet
3. 再补充扩展类型：Bitmap、HyperLogLog、GEO、Stream
4. 每个类型都说“写入命令 + 查询命令 + 场景”
5. 最后提醒线上避免查全量命令，注意大 Key 风险

### 重点得分点

- 能准确说出 `SET/GET`、`HSET/HGET`、`LPUSH/LRANGE`、`SADD/SMEMBERS`、`ZADD/ZRANGE`
- 能补充 `SETBIT/GETBIT`、`PFADD/PFCOUNT`、`GEOADD/GEOSEARCH`、`XADD/XREAD`
- 能区分查询和弹出：`LRANGE` 是查，`LPOP/RPOP` 是取出并删除
- 能说出查全量命令的风险，体现线上经验
- 能结合场景选命令，而不是机械背语法

### 常见误区

| 误区 | 正确理解 |
|---|---|
| `GET` 可以查所有类型 | `GET` 只适合 String，Hash 要用 `HGET`，Set 要用 `SMEMBERS` 等 |
| `LRANGE` 和 `LPOP` 一样 | `LRANGE` 只查询不删除，`LPOP` 会弹出并删除 |
| `SMEMBERS` 可以随便用 | 小集合可以，大集合会有阻塞和网络传输风险 |
| `ZADD` 每次都是新增 | member 已存在时会更新 score |
| HyperLogLog 是精确去重 | 它是近似基数统计，有误差 |
| Stream 和 List 没区别 | Stream 支持消息 ID、消费组、ACK，更适合复杂消息流 |

### 面试话术

“我一般按类型记 Redis 命令。String 用 `SET` 添加、`GET` 查询；Hash 用 `HSET` 添加字段、`HGET/HGETALL` 查询；List 用 `LPUSH/RPUSH` 添加，`LRANGE` 查询，`LPOP/RPOP` 弹出；Set 用 `SADD` 添加，`SMEMBERS/SISMEMBER` 查询；ZSet 用 `ZADD` 添加分数和成员，`ZRANGE/ZREVRANGE` 查排行榜。扩展类型里，Bitmap 用 `SETBIT/GETBIT`，HyperLogLog 用 `PFADD/PFCOUNT`，GEO 用 `GEOADD/GEOSEARCH`，Stream 用 `XADD/XREAD/XREADGROUP`。线上我会避免无脑查全量，防止大 Key 和阻塞问题。”

### 时间分配建议

- 1 分钟版本：只讲五大基础类型和核心命令
- 2 分钟版本：补充 Bitmap、HyperLogLog、GEO、Stream
- 被追问实践经验时：重点讲大 Key 风险、查全量风险、List 和 Stream 的区别

---

> 📋 **分类**: redis
> 🏷️ **标签**: `Redis` `数据类型` `命令` `String` `Hash` `List` `Set` `ZSet` `Stream`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-09-17 21:20:39
