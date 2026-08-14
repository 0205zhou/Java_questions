---
id: q0040
question: "ConcurrentHashMap和HashTable的区别"
category: java
tags: ["synchronized", "ConcurrentHashMap", "HashTable", "线程安全"]
difficulty: medium
created: 2026-08-15 00:53:38
source: 用户输入
---

# ConcurrentHashMap和HashTable的区别

## 联想记忆法

### 记忆口诀/联想

**口诀:"一个锁全店一个锁单间;一个初 11 一个初 16;都不许 null,都是安全罐"**

把两者想成**两个仓储柜**:

- **HashTable**(JDK1.0 老古董):**整柜上锁**(方法级 synchronized,get/put 全表锁),一次只许一个人进出,安全但**慢**;初始 11 格,质数扩容
- **ConcurrentHashMap**(JDK1.5 现代款):**只锁单间**(1.8 桶级锁:空桶 CAS、冲突才 synchronized),多人可同时在不同格子存取,又安全又快;初始 16 格,2 的幂扩容

**共同点:都不允许 null key 和 null value。** 区别在锁的粒度——HashTable 是"一把大锁锁全表",CHM 是"细粒度锁只锁一个桶"。

### 记忆原理

用"锁全店 vs 锁单间"的极端对比,把两者的核心差异浓缩成**锁粒度**一个词——这是它们唯一本质区别,其余差异(性能、并发度、扩容方式)都是锁粒度的派生结果。再记"两个都不许 null"和"扩容策略不同(质数 vs 2 幂)"两个次要点。面试落点:**HashTable 已被 CHM 全面取代**。

### 关联知识

- **与 HashMap 关联**:HashMap 许 null、CHM 禁 null,三方对比是必考组合拳
- **与 synchronized 关联**:HashTable 是方法级锁的典型反面教材,引出锁升级、锁粒度优化
- **与 ReentrantLock 关联**:CHM 1.7 的 Segment 继承 ReentrantLock,是"为什么放弃"的追问点
- **与 CAS 关联**:CHM 1.8 空桶 CAS 写入,衔接"CAS 是什么、ABA 问题"考点

---

## 深度解答

### 第一层:核心概念

#### 是什么

HashTable 是 **JDK 1.0 时代的遗留类(legacy class)**,ConcurrentHashMap 是 **JDK 1.5 引入的线程安全哈希表**。两者都能在多线程下安全使用,但**锁的粒度天差地别**:

| 维度 | HashTable | ConcurrentHashMap |
|---|---|---|
| 锁粒度 | **全表锁**(方法级 synchronized) | **桶级锁**(1.8:空桶 CAS + 冲突 synchronized) |
| 并发度 | 1(任何时刻只有一个线程能操作) | 接近桶数(不同桶可并行) |
| 性能 | 低,所有操作串行化 | 高,读多无锁、写仅锁冲突桶 |
| null key/value | **禁止**(抛 NPE) | **禁止**(抛 NPE) |
| 底层结构 | 数组 + 链表(无树化) | 数组 + 链表 + 红黑树(1.8) |
| 初始容量 | 11(质数) | 16(2 的幂) |
| 扩容 | 2 倍 + 1 | 2 倍(保持 2 的幂) |
| size() | 精确(全表锁下天然精确) | 近似值(CounterCell 累加) |
| 迭代器 | Enumerator,非 fail-fast | 弱一致(weakly consistent) |
| 状态 | **已过时,不推荐** | 并发场景正统选择 |

### 第二层:底层原理

#### HashTable 如何保证线程安全:全表锁

HashTable 的所有公开方法(put、get、remove、size……)都用 `public synchronized` 修饰,即**方法级同步,锁的是整个 HashTable 实例**:

```java
public synchronized V put(K key, V value) { ... }
public synchronized V get(Object key) { ... }
```

- 同一时刻**只有一个线程**能执行任意一个方法,其他线程全部阻塞在 monitor 入口
- 优点:实现简单、绝对安全;缺点:**并发度 = 1**,多线程环境下退化成串行,吞吐量极低
- 连只读的 get 也要抢锁,读多写少场景浪费严重

#### ConcurrentHashMap 如何保证线程安全:细粒度锁

**JDK 1.7:分段锁(Segment)**
- 内部是 `Segment[]`,每个 Segment 继承 `ReentrantLock`,默认 16 段
- put 时先定位段,再对**段**加锁;不同段的线程可并行 → 并发度 = 段数(默认 16)
- get 不加锁:靠 volatile 修饰的 Entry 数组和 `Unsafe.getObjectVolatile` 保证可见性

**JDK 1.8:CAS + synchronized 桶级锁**
- 数组元素用 `Unsafe.compareAndSwapObject`(即 `tabAt/casTabAt`)读写
- put 流程:桶为空 → **CAS 原子写入**,完全无锁;桶非空 → 对**桶头节点**加 synchronized 锁(只锁这一个桶);树化桶锁 TreeBin
- get 全程无锁:volatile 数组 + 不可变 Node 保证安全发布
- 扩容采用**多线程协助迁移**:迁移中的桶置为 ForwardingNode(MOVED),其他线程遇到 MOVED 会参与迁移

#### 为什么都不许 null

两个类的 `put(null, ...)` 都会抛 **NullPointerException**。HashTable 是历史习惯(早期容器都不许 null),CHM 是刻意设计:并发下 `get(key) == null` 无法区分"键不存在"和"值为 null",且 put 与 get 之间存在时序,允许 null 会造成二义性,干脆禁止。

#### 为什么 HashTable 被淘汰

- 全表锁导致**并发度 = 1**,扩展性差
- 早期无替代品时不得不用,CHM 出现后唯一推荐理由消失
- JDK 官方也建议:单线程用 HashMap,多线程用 ConcurrentHashMap

### 第三层:实践应用

```java
// ❌ 不推荐:HashTable 全表锁,并发场景性能差
Map<String, Object> ht = new Hashtable<>();

// ✅ 推荐:ConcurrentHashMap,细粒度锁
Map<String, Object> chm = new ConcurrentHashMap<>();
chm.computeIfAbsent("key", k -> loadFromDB(k));   // 原子复合操作
```

- 需要**并发 + 高性能**的共享 Map → ConcurrentHashMap
- 需要**有序**并发 Map → ConcurrentSkipListMap
- 复合操作(先查后写)必须用 `computeIfAbsent/merge/compute`,否则有竞态

### 第四层:深入思考

**追问 1:为什么 1.8 放弃 Segment?**
Segment 锁粒度是"段"(默认 16 段),段内多个桶仍互斥;且 Segment 继承 ReentrantLock 有额外开销。1.8 直接锁到**单个桶**,并发度大幅提升;synchronized 经过 JVM 锁优化(偏向锁/轻量级锁)后性能不输显式锁。

**追问 2:CHM 读为什么不加锁?**
Node 的 key/value 都是 final,链表/树只在插入时变化且通过 CAS + volatile 发布;读时通过 volatile 读数组元素获取最新引用,因此读天然安全。

**追问 3:HashTable 的 size() 为什么精确?**
全表锁下每次操作都独占,size() 返回的 count 字段不可能被并发修改——精确是"串行化"的副产品,而非优势。

---

## 回答思路

### 答题逻辑框架

1. **一句话定位**:都是线程安全哈希表,本质区别是锁粒度
2. **对比表**:锁粒度、并发度、null、扩容四维度
3. **分别讲实现**:HashTable 方法级 synchronized → CHM 1.7 分段锁 → 1.8 CAS + 桶级锁(重点讲 1.8)
4. **落结论**:HashTable 已过时,并发场景用 CHM
5. **埋延伸**:引出 HashMap(许 null)、锁升级、CAS 等考点

### 重点得分点

- ✅ 明确说出 HashTable 是**方法级全表锁**,并发度 = 1
- ✅ 明确说出 CHM 1.8 是 **CAS + synchronized 桶级锁**,get 无锁
- ✅ 说出两者**都不许 null**(这是最容易记错的一点)
- ✅ 能对比 1.7 Segment 与 1.8 锁的演进

### 常见误区

- ❌ "CHM 和 HashTable 一样都允许 null"——两者都禁止
- ❌ "CHM 1.8 用 ReentrantLock"——1.7 的 Segment 才是
- ❌ "HashTable 用 CAS"——HashTable 只有 synchronized,没有 CAS
- ❌ 把"线程安全"停留在口号上,说不出锁的具体实现

### 过渡话术

- 引出 HashMap:"那 HashMap 和它们比呢?HashMap 允许 null,但线程不安全……"(转三方对比)
- 引出锁优化:"CHM 1.8 敢用 synchronized,是因为 JVM 的锁升级机制……"(转 synchronized 考点)

### 时间分配建议

- 记忆口诀 15 秒 → 对比表 30 秒 → 线程安全实现 90 秒(重点,HashTable 30 秒 + CHM 60 秒)→ 结论与延伸 30 秒 → 共约 3 分钟


---

> 📋 **分类**: java
> 🏷️ **标签**: `synchronized` `ConcurrentHashMap` `HashTable` `线程安全`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-15 00:53:38
