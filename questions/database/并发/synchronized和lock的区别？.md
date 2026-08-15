---
id: q0048
question: "synchronized和lock的区别？"
category: 并发
tags: ["synchronized", "Lock", "ReentrantLock"]
difficulty: medium
created: 2026-08-16 17:20:10
source: 用户输入
---

# synchronized和lock的区别？

## 联想记忆法

### 记忆口诀/联想

**口诀：“一个是自带门，一个是手拿钥匙：前者简单自动，后者灵活可控。”**

把两者想成两种进门方式：

- **synchronized**：房门自带门锁，进去自动上锁，出去自动解锁。
- **Lock**：你自己拿钥匙开门、上锁、解锁，流程更灵活，但也更容易忘记关门。

### 记忆原理

`synchronized` 的核心是 JVM 内建监视器（monitor），语法简单、异常安全、释放锁自动完成；`Lock` 是接口，代表显式锁，提供更多高级能力，比如可中断、可超时、公平锁、多个条件队列等。面试中可以直接从“自动 vs 显式”“简单 vs 灵活”“JVM 级 vs API 级”三个角度对比。

### 关联知识

- `synchronized` 与对象头、monitor、锁升级相关。
- `Lock` 典型实现是 `ReentrantLock`，底层依赖 AQS（AbstractQueuedSynchronizer）。
- `Lock` 的 `Condition` 相当于更灵活的等待队列。
- 两者都可用于线程同步，但适用场景不同。

---

## 深度解答

### 第一层:核心概念

#### 是什么

`synchronized` 是 Java 语言级别的关键字，用来修饰方法或代码块；`Lock` 是 `java.util.concurrent.locks` 包下的接口，代表显式锁。常见实现是 `ReentrantLock`。

| 维度 | synchronized | Lock |
|---|---|---|
| 形式 | 关键字 | 接口 |
| 加锁/解锁 | 自动 | 手动 `lock()` / `unlock()` |
| 异常安全 | 自动释放 | 需要 `finally` 释放 |
| 可中断 | 不支持直接中断等待锁 | `lockInterruptibly()` 支持 |
| 超时获取 | 不支持 | `tryLock()` / `tryLock(timeout)` |
| 公平性 | 非公平为主 | 可选公平/非公平 |
| 条件队列 | 单一等待集合 | 多个 `Condition` |
| 性能 | JDK 6 以后优化很大 | 灵活，功能更强 |

### 第二层:底层原理

#### synchronized 的机制

`synchronized` 由 JVM 实现。进入同步块时尝试获取对象监视器（monitor），成功后持有锁，退出代码块时自动释放。它的核心优势是**语法级保障**：即使发生异常，也会自动释放锁。

```java
synchronized (lock) {
    // 临界区
}
```

JVM 还会根据竞争情况进行锁优化：偏向锁、轻量级锁、重量级锁，这使得无竞争或轻竞争场景下性能更好。

#### Lock 的机制

`Lock` 是 API 级显式锁，最常见实现 `ReentrantLock` 底层基于 AQS。它通过一个状态变量和等待队列来维护锁竞争，提供了更多控制能力。

```java
Lock lock = new ReentrantLock();
lock.lock();
try {
    // 临界区
} finally {
    lock.unlock();
}
```

AQS 的思路是：抢锁失败的线程进入队列挂起，被唤醒后再次竞争。因为它是代码式控制，所以你可以决定：能不能中断、等多久、是否公平、是否使用多个条件队列。

#### 核心差异本质

1. **自动性**：`synchronized` 自动释放锁，`Lock` 必须手动释放。
2. **功能性**：`Lock` 功能更多，尤其适合复杂同步场景。
3. **表达力**：`Lock` 能清楚表达“可中断、限时等待、公平竞争”等业务意图。
4. **适用性**：`synchronized` 更适合简单、短小、异常安全要求高的临界区。

### 第三层:实践应用

```java
// synchronized
private final Object monitor = new Object();

public void incr() {
    synchronized (monitor) {
        count++;
    }
}

// ReentrantLock
private final Lock lock = new ReentrantLock();

public void incr2() {
    lock.lock();
    try {
        count++;
    } finally {
        lock.unlock();
    }
}
```

适用建议：

- 临界区简单、代码短、同步需求明确，优先 `synchronized`。
- 需要可中断等待锁、超时获取锁、多个条件变量、尝试获取锁时，用 `Lock`。
- 需要公平锁时，`ReentrantLock(true)` 更直接。
- 需要避免忘记释放锁的风险，`synchronized` 更省心。

### 第四层:深入思考

**为什么 `synchronized` 仍然没有被淘汰？** 因为它简单、语义稳定、JVM 优化成熟，而且自动释放锁减少了大量人为错误。对大多数业务代码来说，`synchronized` 足够好。

**为什么还要用 `Lock`？** 因为很多高级同步需求不是“能不能加锁”这么简单，而是“加不到锁怎么办、等多久、是否允许打断、是否公平、如何拆分等待条件”。这些都需要 `Lock`。

**性能上谁更快？** 不能一概而论。无竞争场景下两者都很快；高竞争、复杂协作场景下，`Lock` 的控制能力可能更适合业务，但也不意味着一定更快。现代 JVM 对 `synchronized` 已经做了很多优化，不能用老观念判断。

---

## 回答思路

### 答题逻辑框架

1. 先说一句话结论：`synchronized` 是 JVM 内建锁，`Lock` 是显式锁。
2. 从“自动/手动、简单/灵活、功能多/少”三个维度对比。
3. 说出 `Lock` 的高级能力：中断、超时、公平、Condition。
4. 补充底层：monitor vs AQS。
5. 给出选型建议和代码示例。

### 重点得分点

- `synchronized` 自动释放锁，`Lock` 需要 `finally`。
- `Lock` 支持 `tryLock`、`lockInterruptibly`、公平锁、`Condition`。
- `synchronized` 是 JVM 级，`Lock` 是 API 级。
- 能说清楚各自适用场景。

### 常见误区

- 认为 `Lock` 一定比 `synchronized` 快。
- 忘记 `Lock` 必须在 `finally` 中释放。
- 把 `Condition` 当成 `Object.wait/notify` 的简单替代，而忽略它可以有多个等待队列。
- 只会背特性，不会说底层机制。

### 过渡话术

- “既然锁有自动和显式之分，那 `synchronized` 自己内部又有哪些锁升级？”
- “如果线程一直拿不到锁，就会进入什么状态，这和死锁有什么关系？”

### 时间分配建议

- 概念和对比：60 秒。
- 底层原理：45 秒。
- 代码和选型：45 秒。
- 追问扩展：30 秒，总计约 3 分钟。

---

> 📋 **分类**: 并发
> 🏷️ **标签**: `synchronized` `Lock` `ReentrantLock`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-16 17:20:10
