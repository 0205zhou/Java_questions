---
id: q0047
question: "synchronized和lock的区别？"
category: 并发
tags: ["synchronized", "Lock", "ReentrantLock"]
difficulty: medium
created: 2026-08-17 00:48:12
source: 用户输入
---

# synchronized和lock的区别？

### 1. 🧠 联想记忆法

**记忆口诀/联想**：一个是内置门锁，一个是手动钥匙；前者省心，后者灵活。

**记忆原理**：`synchronized` 和 `Lock` 本质上都是为了保护临界区，但控制方式完全不同。`synchronized` 更像语言自带的自动门禁，进入就加锁，离开就释放；`Lock` 更像程序员自己拿钥匙控制门锁，步骤更多，但能力也更强。面试时从“自动 vs 手动”“JVM 内建 vs 并发包 API”“简单 vs 灵活”三条线展开，最容易答完整。

**关联知识**：这个问题常和 `AQS`、`ReentrantLock`、`Condition`、`synchronized` 锁升级、可中断锁、公平锁一起考。面试官通常不是想听你背一个对比表，而是想看你能不能根据业务场景解释为什么某处用 `synchronized`，某处要换成 `Lock`。

### 2. 📖 深度解答

#### 2.1 核心概念：`synchronized` 和 `Lock` 都是同步手段，但控制层级不同

`synchronized` 是 Java 语言级关键字，直接由 JVM 支持；`Lock` 是 `java.util.concurrent.locks` 包里的接口，典型实现是 `ReentrantLock`。

两者的共同目标都是：

- 保证同一时刻只有一个线程进入临界区
- 保护共享资源的一致性
- 避免并发更新导致的数据错乱

但它们的控制风格不同：

- `synchronized`：**隐式加锁、隐式释放锁**
- `Lock`：**显式加锁、显式释放锁**

这决定了二者在易用性、功能性、可扩展性上的差异。

---

#### 2.2 第一层对比：语法和使用方式不同

`synchronized` 直接写在方法或代码块上：

```java
public synchronized void add() {
    count++;
}

public void add2() {
    synchronized (this) {
        count++;
    }
}
```

`Lock` 则要手动调用：

```java
private final Lock lock = new ReentrantLock();

public void add3() {
    lock.lock();
    try {
        count++;
    } finally {
        lock.unlock();
    }
}
```

从写法上就能看出核心差别：

- `synchronized` 语法更短，出错面更小
- `Lock` 更啰嗦，但程序员可以自己决定何时加锁、何时释放、失败后怎么办

这就是为什么很多简单同步逻辑优先用 `synchronized`，而复杂并发协调更偏向 `Lock`。

---

#### 2.3 第二层对比：异常安全和释放锁机制不同

这是面试里最常见、也最重要的区别之一。

##### `synchronized`：异常时自动释放锁

`synchronized` 的释放动作由 JVM 保证。只要线程退出同步块或同步方法，不管是正常结束还是抛异常，锁都会自动释放。

这意味着：

- 不容易因为疏忽造成锁泄漏
- 非常适合简单、直接的临界区保护

##### `Lock`：必须手动释放锁

`Lock` 不会自动释放。如果你写了 `lock.lock()` 却忘了 `unlock()`，其他线程可能永远拿不到锁。

因此标准写法必须是：

```java
lock.lock();
try {
    // 业务逻辑
} finally {
    lock.unlock();
}
```

如果没放在 `finally` 里，代码在异常分支上就可能把锁永远占住。这是 `Lock` 灵活性的代价，也是很多并发 bug 的来源。

所以在工程实践里，`Lock` 并不是“比 `synchronized` 高级就默认更好”，而是“功能更强，但使用责任更重”。

---

#### 2.4 第三层对比：底层实现机制不同

##### `synchronized` 的底层

`synchronized` 依赖 JVM 的监视器锁（monitor）。进入同步块时，线程尝试获取对象监视器；获取成功后进入临界区，退出时释放监视器。

在 HotSpot JVM 中，`synchronized` 还会结合对象头里的 `Mark Word` 做锁状态优化，例如：

- 偏向锁
- 轻量级锁
- 重量级锁

也就是说，`synchronized` 并不是一上来就把线程挂起，它会根据竞争程度逐步升级，尽量减少无竞争和轻竞争场景下的成本。

##### `Lock` 的底层

常见的 `ReentrantLock` 底层依赖 `AQS`（AbstractQueuedSynchronizer，抽象队列同步器）。

AQS 的核心思想是：

- 用一个 `state` 表示锁状态
- 获取锁失败的线程进入同步队列
- 通过 CAS 修改状态
- 配合 `park/unpark` 做阻塞和唤醒

这套机制让 `Lock` 能扩展出很多 `synchronized` 不直接提供的能力，比如：

- 中断等待锁
- 尝试获取锁
- 超时获取锁
- 公平锁/非公平锁
- 多个条件队列

所以从底层看，`synchronized` 更偏“JVM 内建能力”，`Lock` 更偏“并发框架能力”。

---

#### 2.5 第四层对比：功能特性上 `Lock` 更丰富

这里是最容易拉开回答层次的部分。

| 对比维度 | `synchronized` | `Lock` |
|---|---|---|
| 形式 | 关键字 | 接口 / 实现类 |
| 加锁释放 | 自动 | 手动 |
| 异常释放 | 自动释放 | 必须 `finally` 释放 |
| 可中断获取锁 | 不直接支持 | 支持 `lockInterruptibly()` |
| 尝试获取锁 | 不支持 | 支持 `tryLock()` |
| 超时获取锁 | 不支持 | 支持 `tryLock(timeout)` |
| 公平性 | 无法直接指定 | 可选公平锁/非公平锁 |
| 等待队列 | 一个隐式监视器等待集 | 多个 `Condition` |
| 适用场景 | 简单同步 | 复杂并发协作 |

下面几个点要重点会讲。

##### 1）可中断获取锁

如果一个线程在等待 `synchronized` 锁，它不能像 `sleep`、`wait` 那样直接响应中断来退出等待。

而 `Lock` 可以这样写：

```java
lock.lockInterruptibly();
```

这意味着等待锁的线程如果被中断，可以提前结束等待。这个能力在取消任务、超时控制、线程池任务终止中很有价值。

##### 2）尝试获取锁

`Lock` 可以非阻塞尝试拿锁：

```java
if (lock.tryLock()) {
    try {
        // 获取成功
    } finally {
        lock.unlock();
    }
} else {
    // 获取失败，走降级逻辑
}
```

这在避免死锁、快速失败、服务降级里很常见。`synchronized` 做不到这种精细控制。

##### 3）公平锁

`ReentrantLock` 可以创建公平锁：

```java
Lock fairLock = new ReentrantLock(true);
```

公平锁倾向于按等待顺序分配锁，避免线程长期饥饿。但公平通常意味着更低吞吐，所以默认仍然多用非公平锁。

`synchronized` 没有直接暴露公平性配置。

##### 4）多个条件队列

`synchronized` 配合 `wait/notify/notifyAll` 时，所有等待线程都挂在同一个监视器等待集上。

而 `Lock` 可以配多个 `Condition`：

```java
Condition notEmpty = lock.newCondition();
Condition notFull = lock.newCondition();
```

这让生产者-消费者、有限缓冲区、复杂状态机这类场景更容易精确唤醒，而不是一把 `notifyAll()` 把所有线程都叫起来。

---

#### 2.6 第五层对比：性能不能简单说谁一定更快

很多人背八股时会说：`Lock` 比 `synchronized` 快。这种说法放在今天已经很粗糙了。

在早期 JDK 中，`synchronized` 的确相对笨重；但从 JDK 6 开始，JVM 对它做了大量优化：

- 偏向锁
- 轻量级锁
- 自旋
- 锁消除
- 锁粗化

所以现在更准确的说法是：

- **低竞争、简单同步场景**：`synchronized` 完全够用，而且代码更安全
- **高竞争或复杂控制场景**：`Lock` 因为有更多手段，往往更适合工程需求
- **性能是否更优**：取决于竞争模式、临界区长度、唤醒策略，而不是只看关键字名称

面试里不要绝对化地说“`Lock` 更快”，这样容易被追问翻车。

---

#### 2.7 实践应用：什么时候选 `synchronized`，什么时候选 `Lock`

##### 更适合 `synchronized` 的场景

- 临界区很小，逻辑简单
- 只是做互斥保护，没有超时、中断、公平等高级需求
- 希望降低编码失误风险
- 更在意代码可读性和稳定性

例如：

- 单例初始化
- 简单计数器保护
- 小范围对象状态更新

##### 更适合 `Lock` 的场景

- 需要可中断获取锁
- 需要超时控制
- 需要尝试获取锁后快速失败
- 需要公平锁
- 需要多个条件队列
- 复杂并发容器或框架内部实现

例如：

- 生产者消费者模型
- 复杂任务调度器
- 限时抢占资源
- 自定义同步器

---

#### 2.8 一个更贴近面试的例子

比如有个下单接口，提交线程如果拿不到资源锁，希望 200ms 内快速失败，而不是一直等：

```java
private final ReentrantLock lock = new ReentrantLock();

public boolean tryCreateOrder() throws InterruptedException {
    if (!lock.tryLock(200, TimeUnit.MILLISECONDS)) {
        return false;
    }
    try {
        // 创建订单
        return true;
    } finally {
        lock.unlock();
    }
}
```

这种需求下，`Lock` 明显更合适，因为：

- 可以设置超时
- 可以在失败时直接降级
- 不会把请求线程无限阻塞住

如果只是对象内部一个简单字段更新，那 `synchronized` 更直接。

---

#### 2.9 深入思考：本质不是替代关系，而是分工关系

面试里说到最后，最好能上升一句：

> `synchronized` 和 `Lock` 不是谁完全替代谁，而是适合的复杂度层级不同。`synchronized` 更像默认同步手段，简单、稳妥、异常安全；`Lock` 更像高级同步工具，适用于需要精细并发控制的场景。

这句话比单纯背表格更像真正理解了并发设计。

### 3. 🗺️ 回答思路

#### 3.1 面试时的答题框架

可以按下面顺序答：

1. **先给一句总定义**：`synchronized` 是 JVM 内建锁，`Lock` 是并发包里的显式锁。
2. **再说基础区别**：一个自动加解锁，一个手动加解锁。
3. **再说核心能力差异**：`Lock` 支持中断、超时、尝试获取、公平锁、多 `Condition`。
4. **补充底层原理**：`synchronized` 走 monitor 和锁升级，`ReentrantLock` 走 AQS。
5. **最后给选型建议**：简单场景优先 `synchronized`，复杂并发控制再选 `Lock`。

#### 3.2 面试加分点

- 能说出 `Lock` 典型实现是 `ReentrantLock`
- 能讲清 `Condition` 比 `wait/notify` 更灵活
- 能指出 `Lock` 必须在 `finally` 中释放
- 能说明现代 JVM 下别再简单说“`synchronized` 性能差”
- 能从业务角度解释为什么某些场景必须用 `tryLock(timeout)`

#### 3.3 常见误区

- 误区 1：认为 `Lock` 一定比 `synchronized` 快
  - 现在不能这么绝对，JVM 对 `synchronized` 已经优化很多。
- 误区 2：把 `Lock` 当成只是“写法不同”
  - 它真正的价值在于可中断、超时、公平、多条件队列这些能力。
- 误区 3：写了 `lock.lock()` 却没放在 `finally` 里
  - 这是最典型的工程事故来源。
- 误区 4：复杂并发场景还硬用 `wait/notify`
  - 很多时候 `Condition` 的表达力更强。

#### 3.4 可直接复述的收尾话术

你可以最后总结一句：

> `synchronized` 和 `Lock` 都能实现线程同步，但前者偏简单和异常安全，后者偏灵活和可控。简单互斥我会优先用 `synchronized`，涉及中断、超时、公平锁或多条件队列时，我会选择 `ReentrantLock` 这类 `Lock` 实现。


---

> 📋 **分类**: 并发
> 🏷️ **标签**: `synchronized` `Lock` `ReentrantLock`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-17 00:48:12
