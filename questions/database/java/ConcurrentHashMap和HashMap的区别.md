---
id: q0039
question: "ConcurrentHashMap和HashMap的区别"
category: java
tags: ["HashMap", "ConcurrentHashMap", "线程安全"]
difficulty: medium
created: 2026-08-15 00:53:19
source: 用户输入
---

# ConcurrentHashMap和HashMap的区别

## 联想记忆法

### 记忆口诀/联想

**口诀:"一个裸奔一个带甲,一个许 null 一个禁 null;一个算得准一个数不清"**

把两者想成**两个打架的战士**:

- **HashMap**:光膀子上阵(**无锁**,单线程环境跑得快),可以带一把 null 钥匙(null key)和一堆 null 值;size() 老老实实一个个数,**精确**
- **ConcurrentHashMap**:穿着盔甲(**CAS + synchronized 细粒度锁**,多线程安全),**禁止 null**(null key 和 null value 都不许,放了直接抛 NPE);size() 靠计数器估计,**近似值**

**结论:单线程用 HashMap,多线程用 ConcurrentHashMap——锁粒度细,性能远好于 HashTable。**

### 记忆原理

用"裸奔 vs 带甲"的对比,把四个核心差异挂上去:**线程安全(锁机制)、null 支持、性能、size() 语义**。记忆主线是"**一个用锁换安全、一个放弃锁换速度**",再记"**两个不许**(CHM 不许 null 是设计的刻意为之,记住它常常是面试第一个追问点)",最后锚住结论:**并发场景的正统答案是 ConcurrentHashMap**。

### 关联知识

- **与 HashTable 关联**:同为线程安全 Map,CHM 用细粒度锁替代 HashTable 全表锁,是必问对比
- **与 HashMap 底层关联**:CHM 1.8 复用了 HashMap 的"数组 + 链表 + 红黑树"结构,树化阈值 8、退树 6 完全一致
- **与 JDK 版本关联**:CHM 1.7 是分段锁(Segment),1.8 改为 CAS + synchronized,是面试高频追问
- **与 fail-fast 关联**:HashMap 迭代器 fail-fast,CHM 迭代器是弱一致(weakly consistent),多线程下不抛 ConcurrentModificationException

---

## 深度解答

### 第一层:核心概念

#### 是什么

ConcurrentHashMap 是 **JDK 1.5 引入的线程安全哈希表**,HashMap 是 JDK 1.2 引入的**非线程安全**哈希表。两者在 JDK 1.8 中都采用"**数组 + 链表 + 红黑树**"的底层结构,核心区别在于**是否提供并发安全保证**:

| 维度 | HashMap | ConcurrentHashMap |
|---|---|---|
| 线程安全 | 否(多线程读写会丢数据、1.7 会死循环) | **是**(CAS + synchronized) |
| null key/value | **允许** | **禁止**(抛 NPE) |
| 底层结构 | 数组 + 链表 + 红黑树 | 数组 + 链表 + 红黑树(1.8) |
| 锁粒度 | 无锁 | 1.7 分段锁;1.8 桶(槽位)级锁 |
| size() | 精确值 | **近似值**(CAS 计数器 + CounterCell) |
| 迭代器 | fail-fast | 弱一致(不抛 ConcurrentModificationException) |
| 适用场景 | 单线程 | 多线程共享读写 |

#### 为什么不能混用

HashMap 在多线程下有两个著名事故:**数据丢失**(两个线程同时 put 覆盖彼此的写入,JDK7 还表现为头插法成环导致 **get 死循环**)和**数据错乱**。因此多线程共享的 Map 必须用 ConcurrentHashMap,而不是 HashMap + 手动 synchronized(全表锁性能差,且容易漏锁)。

### 第二层:底层原理

#### 1.8 的锁机制:CAS + synchronized 桶级锁

1.8 放弃了 1.7 的 Segment 分段锁(继承 ReentrantLock),改为更细的**桶级锁**:

```java
// 插入流程(putVal 简化逻辑)
static final <K,V> V putVal(...) {
    // 1. 桶为空 → CAS 直接写入,无锁竞争
    if ((f = tabAt(tab, i)) == null) {
        if (casTabAt(tab, i, null, new Node<K,V>(...)))
            break;
    }
    // 2. 桶非空 → 对桶头节点 synchronized 加锁
    else if (f.hash == MOVED) { ... }   // 扩容协助
    else {
        synchronized (f) {              // 只锁这一个桶
            // 链表/红黑树插入
        }
    }
}
```

- **table 数组是 volatile** 的,保证扩容/初始化时的可见性
- **tabAt / casTabAt** 通过 `Unsafe.compareAndSwapObject` 原子读写桶元素,避免整个数组加锁
- **树化桶用 TreeBin** 作为头节点,锁 TreeBin 即可锁住整棵红黑树
- **size()** 通过 baseCount + CounterCell 数组累加,是 CAS 累加器(类似 LongAdder),**并发下是近似值**——这是与 HashMap 的重要语义差异

#### 为什么不许 null

`ConcurrentHashMap.put(key, null)` 或 `put(null, value)` 直接抛 **NullPointerException**。官方理由:HashMap 允许 null 是因为 `get(key) == null` 可以表示"键不存在";而并发环境下"不存在"和"值为 null"**语义上无法安全区分**(get 先返回 null、随后别的线程才 put 进值,调用方无法判断),作者 Doug Lea 干脆禁止 null,避免二义性。

#### 1.7 与 1.8 对比

| 维度 | 1.7 | 1.8 |
|---|---|---|
| 锁粒度 | Segment(继承 ReentrantLock),默认 16 段 | 单个桶 |
| put 无锁竞争 | get 无锁;put 需分段锁 | 空桶 CAS,冲突才 synchronized |
| 并发度 | 最多 16 个段并发 | 近似 桶数 |
| 扩容 | 段内扩容 | 支持多线程协助扩容(Transfer) |

### 第三层:实践应用

```java
// 正确用法:多线程场景直接选 CHM
Map<String, Integer> wordCount = new ConcurrentHashMap<>();
wordCount.merge(word, 1, Integer::sum);      // 原子复合操作,1.8+

// HashMap 的正确单线程用法
Map<String, Integer> cache = new HashMap<>(); // 仅在单线程使用
```

- **复合操作**:`get + put` 不是原子的,用 `computeIfAbsent` / `merge` / `compute` 替代
- **初始化**:预估容量 `new ConcurrentHashMap<>(capacity)`,避免频繁扩容;1.8 构造参数是**期望容量**,实际容量会做 2 的幂对齐
- **遍历**:1.8 的 size() 是近似值,要求精确统计时应自行加同步或改用其他方案

### 第四层:深入思考

**追问 1:CHM 的锁这么细,还有性能问题吗?**
热点桶(如多个 key 哈希到同一桶)仍有锁竞争;且 synchronized 在 JDK 1.6 后有偏向锁、轻量级锁优化,实际竞争成本很低。

**追问 2:什么时候用 ConcurrentSkipListMap?**
需要**有序**的并发 Map 时(跳表实现,无锁读,log(n) 操作),CHM 不保证顺序。

**追问 3:CHM 1.8 扩容为什么不阻塞全表?**
扩容迁移时用"协助扩容"机制:每个线程领取一个 stride 的桶区间迁移,迁移完把桶置为 ForwardingNode(MOVED),其他线程读写时遇到 MOVED 会**帮助迁移**,实现无锁协作扩容。

---

## 回答思路

### 答题逻辑框架

1. **一句话定位**:都是哈希表,一个非线程安全一个线程安全
2. **列差异表格**:线程安全、null、性能、size() 语义四大差异
3. **讲底层**:1.8 的 CAS + synchronized 桶级锁,volatile 数组
4. **落应用**:单线程 HashMap,多线程 CHM,复合操作用 merge/compute
5. **埋延伸**:可以主动引出 HashTable 对比和 1.7 分段锁,展示知识深度

### 重点得分点

- ✅ 说出 **CAS + synchronized 桶级锁**,而不是笼统的"线程安全"
- ✅ 说出 **null 被禁止** 及其原因(避免二义性)
- ✅ 说出 size() 是**近似值**(CounterCell 累加器)
- ✅ 主动提 1.7 vs 1.8 的锁机制演进

### 常见误区

- ❌ "CHM 用 ReentrantLock"——1.7 是,1.8 不是(1.8 用 CAS + synchronized)
- ❌ "CHM 允许 null"——只有 HashMap 允许
- ❌ "CHM 迭代器 fail-fast"——是弱一致,不抛 ConcurrentModificationException

### 过渡话术

- 引出下一个考点:"CHM 锁粒度这么细,那它和加整表锁的 HashTable 比,好在哪里?"(自然过渡到 HashTable 对比)
- 追问接话:"1.8 的锁策略升级,离不开 synchronized 在 JVM 层的优化……"(可转锁升级考点)

### 时间分配建议

- 记忆口诀 15 秒 → 差异表 30 秒 → 底层机制 60 秒(重点)→ 应用与追问 30 秒 → 共约 2 分钟,若被追问 1.7/1.8 再展开 1 分钟


---

> 📋 **分类**: java
> 🏷️ **标签**: `HashMap` `ConcurrentHashMap` `线程安全`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-15 00:53:19
