---
id: q0071
question: "Redis分布式锁使用命令？"
category: redis
tags: ["Redis", "分布式锁", "Lua", "原子性"]
difficulty: medium
created: 2026-08-22 00:05:00
source: 用户输入
---

# Redis分布式锁使用命令？

## 联想记忆法

### 记忆口诀/联想

**口诀：加锁用 SET NX PX，解锁靠比对再 DEL。**

- **SET NX PX**：原子加锁，顺手带过期时间。
- **比对再 DEL**：先确认锁还是自己的，再删除，避免误删别人持有的锁。
- **Lua 兜底**：解锁逻辑放到脚本里，一次执行完成比较和删除。

### 记忆原理

分布式锁最容易翻车的地方就是“**加锁原子性**”和“**解锁安全性**”。这句口诀正好把两个关键点钉住：先用 `SET NX PX` 保证抢锁动作原子，再用 Lua 保证释放动作原子。

### 关联知识

- 会关联到 **SETNX**：老写法，但不如 `SET NX PX` 原子。
- 会关联到 **Lua**：比较 + 删除必须原子执行。
- 会关联到 **Redisson**：工业化封装版分布式锁。
- 会关联到 **超时续期**：锁时间不能随便写死。

## 深度解答

### 1. 核心概念：Redis 分布式锁本质是“带过期时间的互斥标记”

所谓分布式锁，就是让多个进程、多个机器同时访问共享资源时，只允许一个执行者进入临界区。Redis 里最常见的做法，是用一个 key 表示锁：

- key 存在 = 锁被占用
- key 不存在 = 可以抢锁

但真正能上生产的写法，不能只是简单 `SETNX`，而是要把“加锁 + 过期时间”做成原子操作。

### 2. 底层原理：为什么推荐 `SET NX PX`

推荐加锁命令：

```redis
SET lock:order:1001 8f3c7b NX PX 30000
```

含义是：

- `NX`：只有 key 不存在时才设置
- `PX 30000`：锁 30 秒后自动过期
- value：通常放唯一请求标识，比如 UUID + 线程号

这条命令是原子的。相比老写法：

```redis
SETNX lock:order:1001 1
EXPIRE lock:order:1001 30
```

老写法存在中间窗口：如果 `SETNX` 成功后机器宕机，`EXPIRE` 没执行，锁就可能永久卡死。

### 3. 解锁为什么不能直接 DEL

如果直接执行：

```redis
DEL lock:order:1001
```

就可能把别人的锁删掉。因为你的锁可能已经过期，新线程抢到了同一个 key，而你这时候才慢半拍执行 DEL。

正确做法是：先比对 value，确认锁还是自己的，再删除。

Lua 脚本示例：

```lua
if redis.call('GET', KEYS[1]) == ARGV[1] then
  return redis.call('DEL', KEYS[1])
end
return 0
```

调用方式：

```redis
EVAL "if redis.call('GET', KEYS[1]) == ARGV[1] then return redis.call('DEL', KEYS[1]) end return 0" 1 lock:order:1001 8f3c7b
```

这一步把“比较 + 删除”合成一个原子操作，避免误删。

### 4. 实践应用：完整使用流程

典型流程是：

1. 生成唯一请求标识
2. `SET key value NX PX timeout` 抢锁
3. 抢到锁后执行业务
4. 用 Lua 校验 value 后释放锁

```java
String requestId = UUID.randomUUID().toString();
Boolean locked = stringRedisTemplate.opsForValue()
    .setIfAbsent("lock:order:1001", requestId, 30, TimeUnit.SECONDS);
if (Boolean.TRUE.equals(locked)) {
    try {
        // 业务逻辑
    } finally {
        // Lua 校验后删除
    }
}
```

### 5. 深入思考：Redis 锁不是“写完就稳了”

几个常见问题一定要提：

- **锁超时**：业务执行时间可能超过 TTL，导致锁提前过期。
- **误删锁**：必须用唯一 value + Lua 解锁。
- **重入问题**：普通 Redis 锁默认不重入，要额外设计。
- **主从切换**：极端情况下，Redis 故障切换会影响锁语义。

所以 Redis 锁适合“轻量互斥”，但对强一致性要求特别高的场景，要谨慎评估。

## 回答思路

### 答题逻辑框架

1. 先说分布式锁是一个共享资源互斥标记。
2. 再说加锁用 `SET NX PX`，保证原子性和过期时间。
3. 再说解锁不能直接 `DEL`，要 Lua 比对 value 后删除。
4. 最后补充锁超时、误删和主从切换风险。

### 重点得分点

- 能说出 `SET key value NX PX`。
- 能解释为什么不能直接 `SETNX + EXPIRE`。
- 能写出 Lua 解锁脚本。
- 能说明 value 必须唯一。

### 常见误区

- 误区 1：只要用 Redis 就自动是分布式锁。  
  正解：关键在原子性、过期和安全释放。

- 误区 2：直接 `DEL` 就行。  
  正解：会误删别人的锁。

- 误区 3：锁设置越长越安全。  
  正解：过长会降低并发，过短会提前过期。

### 面试话术

“Redis 分布式锁最常见的命令是 `SET key value NX PX timeout`，它把加锁和过期时间做成原子操作。解锁时不能直接 DEL，而是要先用唯一标识比对当前 value，再用 Lua 脚本原子删除，避免误删别人刚抢到的锁。”

---

> 📋 **分类**: redis
> 🏷️ **标签**: `Redis` `分布式锁` `Lua` `原子性`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-22 00:05:00
