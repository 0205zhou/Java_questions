---
id: q0038
question: "HashMap和HashTable的区别"
category: java
tags: ["HashMap", "HashTable"]
difficulty: medium
created: 2026-08-14 00:54:34
source: 用户输入
---

# HashMap和HashTable的区别

## 联想记忆法

### 记忆口诀/联想

**口诀:"HashMap 快但不安全,HashTable 安全但老旧;一个许空一个不许,一个 2 幂一个质数"**

把两者想成**两个时代的安全柜**:

- **HashTable**(JDK1.0 的老古董):每一格都上锁(方法级 synchronized),安全但**慢**;不能放 null 钥匙(不允许 null key);柜子初始 11 格,按质数扩容
- **HashMap**(JDK1.2 的现代款):**不上锁**(线程不安全,快);可以放一把 null 钥匙和任意 null 值;柜子初始 16 格,2 的 N 次方扩容,配位运算

**结论:要线程安全也别用 HashTable——用 ConcurrentHashMap(锁粒度细得多)。**

### 记忆原理

用"老柜子 vs 新柜子"的对比场景,把四个核心差异挂上去:**线程安全(锁)、null 支持、初始容量与扩容、哈希算法**。记忆主线是"**一个用锁换安全但牺牲性能,一个放弃锁换速度**",再记"两个不许**(HashTable 不许 null、HashMap 多线程不许用)"。最后锚住一句结论:**HashTable 已被 ConcurrentHashMap 取代**,这是面试的落点。

### 关联知识

- **与 ConcurrentHashMap 关联**:线程安全 Map 的正统答案是它——HashTable 全表锁 vs ConcurrentHashMap 分段/CAS 细粒度锁,是必问对比
- **与 HashMap 底层关联**:2 的 N 次方、红黑树、扩容机制是 HashMap 侧的知识(HashTable 只有链表、质数扩容)
- **与线程安全关联**:HashMap 并发下的丢数据/死循环(JDK7)是经典事故,引出"为什么要用 ConcurrentHashMap"
- **与 fail-fast 关联**:HashMap 迭代器 fail-fast(HashTable 的 Enumerator 不是),并发修改抛 ConcurrentModificationException

---

## 深度解答

### 第一层:核心概念

#### 是什么

HashTable 是 **JDK 1.0 时代的遗留类(legacy class)**,HashMap 是 **JDK 1.2 引入**的替代品,两者都是"哈希表 + 链表"实现键值存储,但设计目标截然不同:

| 维度 | HashMap | HashTable |
|---|---|---|
| 线程安全 | **否**(非线程安全) | **是**(方法级 synchronized 全表锁) |
| 性能 | 高(无锁,JDK8 树化兜底) | 低(所有操作串行化) |
| null key | 允许 1 个 | **不允许**(抛 NPE) |
| null value | 允许 | **不允许**(抛 NPE) |
| 初始容量 | 16(2 的 4 次方) | **11**(质数) |
| 扩容 | **翻倍**(保持 2 的幂) | **2 倍 + 1**(质数扩容) |
| 索引计算 | `(n-1) & hash`(位运算) | `hash % capacity`(取模) |
| 哈希函数 | 扰动函数(高 16 位异或低 16 位) | 直接用 hashCode(可再 hash) |
| 继承 | `AbstractMap` | `Dictionary`(遗留抽象类) |
| 迭代器 | **fail-fast** | 内部 Enumerator,非 fail-fast |
| 推荐度 | 单线程首选 | **不推荐,用 ConcurrentHashMap 替代** |

---

### 第二层:底层原理

#### ① 线程安全:为什么 HashTable 用锁,HashMap 不用

- HashTable 的每个公共方法(`put`/`get`/`size`…)都加 **synchronized(锁整个 this 对象)**,同一时刻**只有一个线程能访问表**,天然安全
- 代价:**所有操作串行化**——即使 100 个线程同时做不同桶的读写,也得排队,吞吐量随并发数直线下降
- HashMap 为性能放弃内置锁:**单线程下快 2~3 倍**(无锁同步开销),多线程并发 put 会**丢失数据**(两个线程同时写同一桶,后写覆盖先写),JDK7 并发扩容还可能**链表成环死循环**(已修复)
- 正确用法:单线程用 HashMap;**多线程用 ConcurrentHashMap**(JDK8 锁桶头节点 + CAS,读无锁,并发度远超 HashTable 的全表锁)

```java
// HashTable 的同步方式(简化)
public synchronized V put(K key, V value) { ... }   // 锁整个表
public synchronized V get(Object key) { ... }

// ConcurrentHashMap:锁粒度 = 单个桶头节点(JDK8)
// 不同桶的写操作可以并行;读操作无锁
```

#### ② null 支持:为什么 HashTable 不许 null

- HashMap:允许 **1 个 null key**(hash(null)=0,固定放 0 号桶)和**任意数量 null value**——因为 `get()` 返回 null 有两种语义("没有"或"值为 null"),HashMap 接受这种歧义
- HashTable **不允许 null key/value**:源码里直接 `if (value == null) throw new NullPointerException()`。官方理由:null 在 HashTable 的方法语义中不合法(同步哈希表的设计惯例),也避免 `get` 返回 null 无法区分"键不存在"与"值就是 null"

#### ③ 容量策略:质数 vs 2 的幂

- HashTable 初始 **11**(质数),扩容 `capacity × 2 + 1`——**保持质数**:质数容量让取模结果对"规律性哈希值"(如等差数列 key)更抗碰撞,这是**"直接取模时代"的抗碰撞哲学**
- HashMap 初始 **16**,扩容翻倍——保持 **2 的幂**:让 `(n-1) & hash` 位运算可用(快),且扩容迁移只需一次位运算判断(原位 or 原位+oldCap)
- 两者的取舍:质数抗规律碰撞但**无法用位运算**;2 的幂更快但**依赖扰动函数保证均匀**——HashMap 用扰动函数 + 红黑树兜底,解决了均匀问题,所以全面胜出

#### ④ 迭代器:fail-fast 与遗留 Enumerator

- HashMap 的迭代器是 **fail-fast**:迭代过程中结构被修改(非 remove 方法),立即抛 **ConcurrentModificationException**(通过 modCount 计数检测),**宁可快速失败也不产生未知行为**
- HashTable 的 `enumerator` **不是 fail-fast**(JDK1.0 时代的遗留设计,不检查 modCount)——迭代中修改可能得到不一致结果而不报错
- 注意:fail-fast 不是"检测到立刻安全",它只是**尽力而为的并发提醒**,正确并发修改还是要用并发容器

#### ⑤ 继承体系差异

- HashMap extends `AbstractMap`(1.2 引入的现代集合框架)
- HashTable extends `Dictionary`(1.0 的遗留抽象类,现在已标记为"过时设计",新代码不用)

---

### 第三层:实践应用

#### 实际选型决策树

```java
// 单线程读写 → HashMap(首选)
Map<String, Object> cache = new HashMap<>();

// 多线程读写,读多写少 → ConcurrentHashMap
Map<String, Object> concurrentCache = new ConcurrentHashMap<>(16);

// 需要"没有该键才插入"的原子操作 → ConcurrentHashMap.putIfAbsent
concurrentCache.putIfAbsent(key, expensiveBuild());

// 不要再写 new Hashtable<>() —— 除非维护 1.0 时代的老代码
```

#### HashMap 并发使用的三种修法

| 方案 | 做法 | 适用 |
|---|---|---|
| Collections.synchronizedMap | 包装层加锁(也是全表锁) | 简单场景,性能同 HashTable |
| ConcurrentHashMap | 细粒度锁 + CAS | **主流推荐** |
| 自己加锁(如锁业务方法) | 由业务控制 | 读多写少且读允许脏读 |

#### 经典面试场景演示

```java
// HashMap 允许 null
Map<String, String> map = new HashMap<>();
map.put(null, "a");          // OK:null key 固定进 0 号桶
map.put("k", null);          // OK:null value 允许

// HashTable 不允许 null
Hashtable<String, String> ht = new Hashtable<>();
ht.put(null, "a");           // ❌ NullPointerException
ht.put("k", null);           // ❌ NullPointerException

// 线程安全对比:并发 put 100 万次
// HashMap  → 数据丢失(数量 < 100 万)
// Hashtable → 数量正确,但吞吐量显著低于 ConcurrentHashMap
```

---

### 第四层:深入思考

#### 追问 1:既然 HashTable 线程安全,为什么还要 ConcurrentHashMap?

**并发度差距**:

- HashTable:全表一把锁,**任意时刻只有一个线程在写**,并发量再大也串行——锁竞争是吞吐量天花板
- ConcurrentHashMap(JDK8):**锁桶头节点(synchronized + CAS)**,不同桶的写互不阻塞;读操作无锁(volatile 读)——并发量线性提升,吞吐量是 HashTable 的数倍到数十倍
- 结论:HashTable 的"安全"是**以吞吐量为代价的假安全**,现代并发场景被 ConcurrentHashMap 全面取代

#### 追问 2:HashMap 的 get 返回 null 怎么区分"没有"和"值就是 null"?

`get` 无法区分,要用 `containsKey` 先判断:

```java
map.put("k", null);
map.get("k") != null;        // false,但 key 存在!
map.containsKey("k");        // true —— 判断 key 是否存在用这个
```

这是 HashMap 允许 null value 的歧义代价,实战中常被坑。

#### 追问 3:JDK8 的 ConcurrentHashMap 和 HashTable 的锁实现差在哪?

HashTable 锁 `this`(一个 Monitor);ConcurrentHashMap 锁 `Node`(桶头),配合 **CAS 无锁插入**(空桶直接 CAS 放入)+ synchronized(非空桶锁头节点),并发度从"1"提升到"桶的数量级"。JDK8 还移除了分段锁(Segment),结构更简洁、锁粒度更细。

#### 追问 4:扩容机制差在哪?

HashTable 扩容重算每个元素位置(取模);HashMap 利用 2 的幂,元素只需判断 `hash & oldCap`,高位链/低位链一次迁移。**HashTable 扩容是 O(n) 全量重算,HashMap 是 O(n) 但每元素 O(1) 判断**,且不反转链表。

---

## 回答思路

### 答题逻辑框架(约 2 分钟)

1. **先定调**:HashTable 是 JDK1.0 遗留类,HashMap 是 1.2 的现代替代,核心差异是"线程安全换性能"
2. **逐维对比**:线程安全(synchronized vs 无锁)、null(不许 vs 许)、容量(11 质数 vs 16 的 2 幂)、哈希(取模 vs 位运算)、迭代器(fail-fast 与否)
3. **讲为什么 HashMap 快**:无锁 + 位运算 + 扰动函数,JDK8 还有红黑树兜底
4. **讲为什么 HashTable 被淘汰**:全表锁并发度太差,线程安全的正解是 ConcurrentHashMap
5. **收尾实践**:单线程 HashMap、多线程 ConcurrentHashMap;顺带说出 null 的 get 歧义(containsKey)

### 重点得分点

- 准确说出**四大差异:线程安全、null 支持、容量与扩容、哈希算法**
- 准确说出具体数字:**初始 16 vs 11,扩容翻倍 vs 2 倍+1**
- 准确说出 **ConcurrentHashMap 是线程安全场景的正解**,以及为什么(锁粒度)
- 说出 HashMap 允许 **1 个 null key**(hash 固定 0)和任意 null value
- 说出 HashTable 的 synchronized 是**锁整个对象**(方法级),不是分段

### 常见误区

- ❌ 说"HashTable 线程安全所以推荐用它"——并发场景正解是 ConcurrentHashMap
- ❌ 说"HashMap 不允许 null"——HashMap 允许,HashTable 才不允许
- ❌ 说"两者初始容量都是 16"——HashTable 是 11(质数)
- ❌ 说"HashMap 的迭代器也不 fail-fast"——HashMap 抛 ConcurrentModificationException,HashTable 的 Enumerator 不抛
- ❌ 说"ConcurrentHashMap 和 HashTable 一样是全表锁"——JDK8 是锁桶头 + CAS

### 过渡话术

- 开场:"两者是两代产物:HashTable 是 JDK1.0 的遗留类,HashMap 是 1.2 的替代品,我用四个维度对比……"
- 引线程安全:"线程安全是最大差异——HashTable 方法级同步,全表一把锁;HashMap 无锁,单线程快很多……"
- 收尾:"如果面试官问线程安全怎么选,我的答案是 ConcurrentHashMap:锁粒度细、读无锁,这才是现代正解,HashTable 已经退场。"

### 时间分配建议

| 环节 | 时间 |
|---|---|
| 定调 + 四维对比 | 40 秒 |
| 线程安全(锁 vs 无锁 + 并发度) | 30 秒 |
| null 与容量差异 | 20 秒 |
| 迭代器 + 继承 | 15 秒 |
| ConcurrentHashMap 替代结论 + 追问 | 25 秒 |

---

> 📋 **分类**: java
> 🏷️ **标签**: `HashMap` `HashTable`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-14 00:54:34
