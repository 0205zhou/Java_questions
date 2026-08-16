---
id: q0053
question: "CountDownLatch 和 CyclicBarrier 区别 ?"
category: 并发
tags: ["CountDownLatch", "线程协作", "并发工具", "CyclicBarrier"]
difficulty: medium
created: 2026-08-17 00:53:17
source: 用户输入
---

# CountDownLatch 和 CyclicBarrier 区别 ?

﻿### 1. 🧠 联想记忆法

**记忆口诀/联想**："一个倒计时，一个围成圈；前者等人到齐，后者等人同时过门。"

**记忆原理**：`CountDownLatch` 和 `CyclicBarrier` 都是同步辅助工具，但关注点不同。前者是“我等别人做完”，后者是“大家一起到达再一起走”。记住“一个是计数归零，一个是屏障放行”，面试时就很好展开。

**关联知识**：这题常和线程池、并发协作、`Semaphore`、`Phaser`、任务编排一起考。面试官一般会追问：谁负责减计数、谁能重置、是否能重复使用、适合什么业务流程。

### 2. 📖 深度解答

#### 2.1 核心概念：两个工具都用于线程协作，但语义不同

`CountDownLatch` 和 `CyclicBarrier` 都是 `java.util.concurrent` 提供的同步辅助类，用来协调多个线程的执行顺序。

它们看起来都像“等一等”，但语义完全不同：

- `CountDownLatch`：**一个或多个线程等待其他线程完成后再继续**
- `CyclicBarrier`：**多个线程互相等待，等所有线程都到达屏障后一起继续**

可以简单理解为：

- `CountDownLatch` 是“等别人干完活”
- `CyclicBarrier` 是“大家一起到齐再出发”

---

#### 2.2 对比表：最直观的区别

| 维度 | CountDownLatch | CyclicBarrier |
|---|---|---|
| 核心语义 | 等待计数归零 | 等待一组线程都到达 |
| 计数方式 | 递减 | 固定人数到齐 |
| 是否可重用 | 不能重置后重复使用 | 可以循环使用 |
| 谁触发放行 | 计数到 0 | 最后一个线程到达 |
| 常见场景 | 启动门闩、任务汇总 | 分阶段并行、集体汇合 |
| 是否有回调 | 没有 | 可带 `barrierAction` |

---

#### 2.3 `CountDownLatch`：倒计时门闩

`CountDownLatch` 的核心是一个初始计数器。

```java
CountDownLatch latch = new CountDownLatch(3);
```

含义是：还需要 3 次 `countDown()`，计数器才会归零。

常见用法：

```java
CountDownLatch latch = new CountDownLatch(3);

for (int i = 0; i < 3; i++) {
    new Thread(() -> {
        try {
            // 执行任务
        } finally {
            latch.countDown();
        }
    }).start();
}

latch.await();
System.out.println("all done");
```

它的特点是：

- 主线程或某个线程等待其他工作线程完成
- 计数只能递减
- 归零后一次性放行
- 用完就结束，不能像屏障那样反复复用

典型场景：

- 等待多个初始化任务完成后再启动系统
- 等待一批子任务执行完后汇总结果
- 并行调用多个接口后统一返回

---

#### 2.4 `CyclicBarrier`：循环屏障

`CyclicBarrier` 的语义是：

> 多个线程都要先到同一个点，等最后一个线程到了，大家一起继续。

```java
CyclicBarrier barrier = new CyclicBarrier(3, () -> {
    System.out.println("all arrived");
});
```

它的用法是：

```java
for (int i = 0; i < 3; i++) {
    new Thread(() -> {
        try {
            // 阶段一
            barrier.await();
            // 阶段二
        } catch (Exception e) {
            Thread.currentThread().interrupt();
        }
    }).start();
}
```

它的特点是：

- 必须凑够指定数量的线程
- 最后一个线程到达时放行所有等待线程
- 可重复使用，所以叫 cyclic
- 可以带一个 barrier action，在全部到达时执行额外动作

典型场景：

- 多个线程分阶段并行计算
- 游戏中多人同时准备完毕再开始
- 大数据计算中的阶段性汇合

---

#### 2.5 本质区别：一个是“等完成”，一个是“等到齐”

这是最核心的一句话。

##### `CountDownLatch`

- 侧重点是任务完成顺序
- 谁做完谁 `countDown()`
- 等待方关注“结果是否都结束了”

##### `CyclicBarrier`

- 侧重点是线程到达同步点
- 谁先到都得等
- 关注“大家是不是都到同一阶段了”

所以：

- `CountDownLatch` 更像“门闩”
- `CyclicBarrier` 更像“集结点”

---

#### 2.6 能不能互相替代

不能简单互换。

##### `CountDownLatch` 适合：

- 一个线程等多个线程完成
- 任务结束信号
- 初始化门闩

##### `CyclicBarrier` 适合：

- 多个线程分阶段协作
- 每一阶段都要等所有人到齐
- 需要重复使用屏障

如果你只是想“等所有任务做完”，`CountDownLatch` 更自然。
如果你想“每一轮都同步一下再进入下一轮”，`CyclicBarrier` 更自然。

---

#### 2.7 一个更直观的例子

##### CountDownLatch：等所有人完成后再汇总

```java
CountDownLatch latch = new CountDownLatch(3);
List<String> result = new CopyOnWriteArrayList<>();

for (int i = 0; i < 3; i++) {
    new Thread(() -> {
        try {
            result.add(fetchData());
        } finally {
            latch.countDown();
        }
    }).start();
}

latch.await();
System.out.println(result);
```

这里主线程只关心：三个任务是不是都做完了。

##### CyclicBarrier：大家都准备好后一起开始下一轮

```java
CyclicBarrier barrier = new CyclicBarrier(3, () -> System.out.println("start next stage"));

for (int i = 0; i < 3; i++) {
    new Thread(() -> {
        try {
            doStageOne();
            barrier.await();
            doStageTwo();
        } catch (Exception e) {
            Thread.currentThread().interrupt();
        }
    }).start();
}
```

这里的关键不是“结束”，而是“阶段同步”。

---

#### 2.8 深入思考：为什么还要区分这两个类

因为它们解决的是两类完全不同的问题：

- `CountDownLatch` 解决“完成等待”
- `CyclicBarrier` 解决“协作汇合”

如果把它们混用，代码会变得很难读：

- 想等完成却用了屏障，语义不清
- 想分阶段协作却用了门闩，流程表达不出来

所以面试里最加分的不是“背出两个类名”，而是能直接说出业务语义：

> 我是要等别人做完，还是要让大家到同一点再一起继续？

### 3. 🗺️ 回答思路

#### 3.1 面试时的答题框架

1. 先说两者都是线程协作工具
2. 再给一句话区别：`CountDownLatch` 等完成，`CyclicBarrier` 等到齐
3. 讲计数方式和是否可重用
4. 分别举一个典型使用场景
5. 最后补充 `barrierAction` 和实际选型

#### 3.2 重点得分点

- `CountDownLatch` 计数递减，不能重复使用
- `CyclicBarrier` 是可循环重用的屏障
- `CountDownLatch` 适合一个线程等多个任务完成
- `CyclicBarrier` 适合多个线程分阶段汇合

#### 3.3 常见误区

- 把两个类都理解成“等线程结束”
- 以为 `CyclicBarrier` 不能重复使用
- 误把 `CountDownLatch` 当作线程之间互相等待的屏障
- 只会说 API，不会说适用语义

#### 3.4 可直接复述的收尾话术

你可以最后总结一句：

> `CountDownLatch` 是倒计时门闩，适合一个线程等多个任务完成；`CyclicBarrier` 是循环屏障，适合多个线程到齐后一起继续执行。前者关注“完成”，后者关注“汇合”，语义不同，不能简单互换。


---

> 📋 **分类**: 并发
> 🏷️ **标签**: `CountDownLatch` `线程协作` `并发工具` `CyclicBarrier`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-17 00:53:17
