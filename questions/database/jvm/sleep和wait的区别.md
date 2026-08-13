---
id: q0026
question: "sleep和wait的区别"
category: jvm
tags: ["并发", "多线程"]
difficulty: medium
created: 2026-08-13 19:39:18
source: 用户输入
---

# sleep和wait的区别

## 联想记忆法

### 记忆口诀/联想

**口诀:"谁的方法谁管锁:Thread 睡不放手,Object 等先放手"**

把线程想成**排队打饭的人**:

- `sleep` 是"**自己**趴桌上睡一会儿"(Thread 的静态方法):睡觉期间手里**一直抱着饭盆(锁)不撒手**,别的线程别想抢
- `wait` 是"**叫服务员**说我要等一会儿"(Object 的方法):必须先**把饭盆放到桌上(释放锁)**,自己退到候餐区(等待队列),等服务员(其他线程)喊你(`notify`)才能回来重新抢饭盆

### 记忆原理

记忆锚点是**"锁的释放与否"**——这是两者最本质的区别,也是面试官最想听的第一句话。用"抱着饭盆睡 vs 放下饭盆等"的场景联想,把"是否持有锁"这个抽象概念具象化,一提就记住。再配合**归属关系**("Thread 的方法 vs Object 的方法")记第二层,层次分明不易混。

### 关联知识

- **与 synchronized 关联**:`wait` 必须在**持有监视器锁**(synchronized 代码块/方法)的前提下调用,否则抛 `IllegalMonitorStateException`;`sleep` 则不需要锁
- **与锁释放关联**:`notify`/`notifyAll` 与 `wait` 配对使用,是经典的**生产者-消费者**模式核心
- **与 JUC 关联**:`Lock` 体系用 `Condition.await()`/`signal()` 替代 `wait`/`notify`,语义更丰富(可区分多条件队列)
- **与线程状态关联**:`sleep` 后线程处于 `TIMED_WAITING`,`wait` 后处于 `WAITING`/`TIMED_WAITING`——面试追问"线程有哪些状态"时是现成的例子

---

## 深度解答

### 第一层:核心概念

#### 是什么

`sleep` 和 `wait` 都是让线程**暂停执行**的手段,但二者有本质区别:

| 对比维度 | `Thread.sleep(long)` | `Object.wait()` |
|---|---|---|
| 归属 | Thread 类的**静态方法** | Object 类的**实例方法**(所有对象都有) |
| 是否释放锁 | **不释放**持有的锁 | **释放**持有的锁(进入等待队列) |
| 调用前提 | 无需持有锁,随时可调 | 必须在同步代码块/方法中持有监视器锁 |
| 唤醒方式 | 时间到自动醒来 | 需 `notify()`/`notifyAll()` 或 `wait(timeout)` 超时 |
| 进入状态 | `TIMED_WAITING`(计时等待) | `WAITING`(无限等待)/ `TIMED_WAITING`(计时等待) |
| 作用对象 | 当前线程自身 | 调用它所在对象的"等待集合" |

```java
// sleep:抱着锁睡 —— 其他线程进不来
synchronized (lock) {
    Thread.sleep(1000);   // 持有 lock 期间睡觉,别的线程拿不到 lock
}

// wait:放下锁等 —— 其他线程可以进来
synchronized (lock) {
    lock.wait();          // 释放 lock,加入 lock 的等待队列
}
```

#### 解决的问题

- `sleep`:单纯的**让出 CPU 时间片**,常用于模拟耗时、控制节奏、限流降温
- `wait`:解决**条件不满足时的协作等待**——生产者发现队列满了,不能死循环自旋(浪费 CPU),而是释放锁等待消费者腾出空间,再由消费者唤醒自己

---

### 第二层:底层原理

#### 为什么 sleep 不释放锁

`sleep` 的语义是"**让当前线程暂停指定的毫秒数**",它只操作**线程自身**的调度状态,与对象监视器(Monitor)毫无关系。JVM 对 `sleep` 的实现只涉及线程状态迁移(运行 → 计时等待),不触碰对象头中的 Monitor 记录,因此**不释放锁也不需要锁**。设计意图是:如果调用者正在同步块里,sleep 后锁依然在手里,醒来后可以直接继续执行,避免"醒来后重新抢锁失败"的复杂性。

#### 为什么 wait 必须释放锁

`wait` 的语义是"**当前线程放弃监视器,进入该监视器的等待集合**",这是**线程间协作**机制。如果不释放锁,其他线程永远无法进入同步块去调用 `notify` 唤醒它——**自己等不到被唤醒,造成死锁**。所以 JVM 规定 `wait` 必须先持有锁(校验 Monitor),进入等待状态时**原子性地释放锁并挂起**,收到通知后再去**重新竞争锁**(注意:唤醒不等于拿到锁,要参与锁竞争)。

#### 关于 InterruptedException

两者都会抛出 `InterruptedException`(受检异常),语义不同:

- `sleep` 被中断:立即抛出异常,**不改变**锁持有状态
- `wait` 被中断:抛出异常并**从等待队列移除**

这也是为什么调用它们必须 try-catch——强制调用者处理"线程被中断"的协作信号。

#### 虚假唤醒(Spurious Wakeup)

`wait` 可能在没有收到 `notify` 的情况下被唤醒(操作系统层面的原因)。因此**标准写法是 while 循环包裹 wait**:

```java
synchronized (queue) {
    while (queue.isEmpty()) {   // 必须用 while,不能用 if
        queue.wait();
    }
    // 取出元素...
}
```

用 `while` 保证醒来后重新检查条件,防止条件不满足就继续执行——这是面试官常挖的细节坑。

---

### 第三层:实践应用

#### 生产者-消费者经典案例

```java
class Buffer {
    private final Queue<Integer> queue = new LinkedList<>();
    private final int CAPACITY = 10;

    public synchronized void produce(int item) throws InterruptedException {
        while (queue.size() == CAPACITY) {
            wait();                       // 满了,释放锁等消费者
        }
        queue.offer(item);
        notifyAll();                      // 唤醒所有等待的消费者
    }

    public synchronized int consume() throws InterruptedException {
        while (queue.isEmpty()) {
            wait();                       // 空了,释放锁等生产者
        }
        int item = queue.poll();
        notifyAll();
        return item;
    }
}
```

#### 何时用 sleep 而不是 wait

- 需要"**单纯停一下**",不涉及协作:`sleep`
- 需要在**同步块内让出锁**让别人干活:`wait`(生产-消费、线程间通信)
- 注意:**永远不要用 `sleep` 去"实现"线程协作**(如睡眠轮询等待某个条件),这是典型的坏味道,应改用 `wait`/`notify` 或 JUC 的 `CountDownLatch`、`Condition` 等

---

### 第四层:深入思考

#### 追问 1:notify 和 notifyAll 怎么选?

`notify` 只随机唤醒**一个**等待线程,`notifyAll` 唤醒**全部**。单生产者单消费者用 `notify` 即可;多生产者多消费者场景必须用 `notifyAll`,否则可能出现"唤醒的线程条件仍不满足继续等,而满足条件的线程没被唤醒"的**信号丢失**问题。

#### 追问 2:wait(timeout) 和 sleep(timeout) 能互相替代吗?

不能。`wait(timeout)` 超时后**需要重新竞争锁**才能继续,`sleep` 超时后**直接继续执行**(锁还在手里)。同样在同步块内,`wait(1000)` 意味着"最多等 1 秒,期间别人可以干活",`sleep(1000)` 意味着"霸占锁 1 秒"。语义完全不同。

#### 追问 3:与 Condition 的关系?

`Lock` + `Condition` 是 `synchronized` + `wait/notify` 的升级版:`Condition.await()` 对应 `wait`,`signal()` 对应 `notify`。优势是**一把锁可以有多个条件队列**(如"队列满"和"队列空"分开等待),且支持超时、中断、公平性控制,写复杂协作时更清晰。

#### 追问 4:sleep(0) 有什么用?

`sleep(0)` 不睡,但会**触发一次线程调度**,让出当前时间片给同优先级的其他线程,常用于"礼让"式调度。

---

## 回答思路

### 答题逻辑框架(约 2 分钟)

1. **一句话定调**:两者都能让线程暂停,但 **sleep 不释放锁、wait 释放锁**
2. **展开对比**:归属(Thread 静态 vs Object 实例)、唤醒方式、调用前提、进入的线程状态
3. **补细节**:InterruptedException、while 包裹 wait 防虚假唤醒
4. **上代码**:生产者-消费者简单示意,体现会用
5. **主动延伸**:提到 JUC 的 Condition 是升级替代品(加分项)

### 重点得分点

- 第一句就说"**是否释放锁**"——这是核心差异,先命中
- 准确说出 `wait` 必须在 synchronized 内调用,否则 `IllegalMonitorStateException`
- 准确说出 `wait` 用 `notify`/`notifyAll` 唤醒,sleep 到点自动醒
- 说出 `sleep` 是 Thread 静态方法、`wait` 是 Object 方法(对象级别,所有对象都有)
- 主动说出 **while + wait 防虚假唤醒**(细节控,明显加分)

### 常见误区

- ❌ 说"sleep 和 wait 都能让线程暂停,差不多"——漏掉锁释放这个核心差异
- ❌ 说"wait 也要 try-catch 或者必须捕获 InterruptedException"——对,但忘了说 sleep 一样要捕获
- ❌ 把 `notify` 说成是唤醒后立刻执行——唤醒后还要**重新竞争锁**
- ❌ 在非同步块调用 wait——抛 `IllegalMonitorStateException`,不是编译错

### 过渡话术

- 开场:"sleep 和 wait 最核心的区别就一句话:sleep 不释放锁,wait 释放锁。具体展开……"
- 从 wait 引到协作:"wait 是线程间协作的工具,经典场景就是生产者-消费者,而它的唤醒依赖于 notify,这里有个细节——建议用 while 包裹 wait 来防虚假唤醒……"
- 收尾延伸:"如果项目里用的 JUC 的 Lock,对应的就是 Condition 的 await/signal,语义更丰富。"

### 时间分配建议

| 环节 | 时间 |
|---|---|
| 核心差异(锁释放 + 归属) | 20 秒 |
| 对比展开(唤醒/前提/状态) | 30 秒 |
| 细节(异常/虚假唤醒) | 20 秒 |
| 代码示例(生产者-消费者) | 30 秒 |
| 追问延伸(Condition 等) | 20 秒 |

---

> 📋 **分类**: jvm
> 🏷️ **标签**: `并发` `多线程`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-13 19:39:18
