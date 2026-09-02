---
id: q0102
question: "Seata分布式事务使用和原理？"
category: distributed
tags: ["RM", "分布式事务", "TCC", "TC", "Saga", "Seata", "AT", "XA", "TM"]
difficulty: hard
created: 2026-09-02 14:44:49
source: 用户输入
---

# Seata分布式事务使用和原理？

## 联想记忆法

### 记忆口诀/联想

**口诀：TM 定范围，TC 做协调，RM 管资源；AT 自动补偿，TCC 手写三步，XA 原生两阶段，Saga 反向补偿。**

把 Seata 想成分布式事务总控系统：

- **TM**：发起和决定全局事务。
- **TC**：记录状态、协调提交或回滚。
- **RM**：管理本地资源和分支事务。

### 记忆原理

Seata 面试题通常包含两部分：**项目怎么接入**和**事务怎么协同**。先记角色，再记生命周期，最后记四种模式的差异，回答就不会只停留在“加一个注解”。

### 关联知识

- Seata 解决的是微服务跨库、跨服务场景下的事务一致性问题。
- AT、TCC、XA 主要按两阶段事务行为组织；Saga 更偏长事务和补偿。
- Seata 不能替代业务幂等、重试、超时和最终一致性设计。

## 深度解答

### 第一层：核心概念

Seata 是面向微服务架构的分布式事务框架。它把一个跨服务的业务事务拆成一个**全局事务（Global Transaction）**，再把各服务内部的本地事务作为多个**分支事务（Branch Transaction）**进行协调。

例如下单场景：

```text
订单服务扣库存服务扣余额服务
        \     |     /
          一个全局事务
```

如果其中一个分支失败，Seata 会根据事务模式驱动其他分支提交、回滚或执行补偿。

### 第二层：三大核心角色

#### 1. TM：Transaction Manager

事务管理器负责：

- 开启全局事务
- 提交全局事务
- 回滚全局事务
- 决定全局事务结果

在 Spring 项目中，业务入口通常通过 `@GlobalTransactional` 声明一个全局事务：

```java
@GlobalTransactional
public void createOrder(OrderCommand command) {
    orderService.create(command);
    storageService.deduct(command);
    accountService.debit(command);
}
```

#### 2. TC：Transaction Coordinator

事务协调器是 Seata Server 的核心，负责：

- 维护全局事务和分支事务状态
- 生成和管理 XID
- 接收 RM 注册分支事务
- 驱动二阶段提交或回滚
- 处理超时和重试

#### 3. RM：Resource Manager

资源管理器位于各业务服务中，负责：

- 管理本地数据源或业务资源
- 向 TC 注册分支事务
- 汇报分支执行状态
- 执行提交、回滚或补偿

三者关系可以概括为：

```text
TM -> TC：开始/提交/回滚全局事务
RM -> TC：注册/汇报分支事务
TC -> RM：驱动分支提交/回滚
```

### 第三层：Seata 完整工作流程

#### 1. 开启全局事务

TM 向 TC 发起请求，TC 创建全局事务并返回 XID。

#### 2. 传播 XID

XID 会沿着服务调用链传播到下游服务。下游服务拿到 XID 后，知道自己属于同一个全局事务。

#### 3. 注册分支事务

每个服务执行本地数据库操作时，RM 向 TC 注册一个分支事务，并记录资源信息。

#### 4. 执行本地事务

各服务先执行自己的本地操作。不同事务模式会在这里采用不同机制：

- AT 记录前后镜像和 undo log
- TCC 执行 Try
- XA 执行 XA 分支
- Saga 执行正向动作

#### 5. 全局提交或回滚

所有分支成功时，TM 请求 TC 提交；任一分支失败时，TM 请求 TC 回滚。TC 再驱动各 RM 完成第二阶段动作。

### 第四层：四种事务模式

#### 1. AT 模式

AT（Automatic Transaction）是 Seata 中使用非常广泛的模式，基于支持本地 ACID 的关系型数据库，对业务代码侵入较小。

核心过程：

```text
一阶段：拦截 SQL，记录 before image / after image 和 undo_log，提交本地事务
二阶段提交：异步清理 undo_log
二阶段回滚：根据 undo_log 生成反向操作恢复数据
```

典型接入步骤：

1. 部署 Seata Server。
2. 在每个业务服务引入 Seata 客户端和对应数据源代理依赖。
3. 创建 `undo_log` 表。
4. 配置事务组、注册中心、配置中心和 TC 地址。
5. 使用 `@GlobalTransactional` 标记全局事务入口。
6. 确保下游调用链能传播 XID。

AT 的优点是开发成本低、对业务侵入小；缺点是依赖数据库和 SQL 解析，对复杂 SQL、长事务和隔离性要求高的场景要谨慎评估。

#### 2. TCC 模式

TCC（Try-Confirm-Cancel）把分支事务的三个阶段交给业务代码实现：

- Try：预留资源
- Confirm：确认提交
- Cancel：释放或回滚资源

```java
@TwoPhaseBusinessAction(
        name = "stockAction",
        commitMethod = "confirm",
        rollbackMethod = "cancel")
public boolean tryStock(BusinessActionContext context,
                        String skuId, int count) {
    return stockRepository.reserve(skuId, count);
}

public boolean confirm(BusinessActionContext context) {
    return stockRepository.confirm(context);
}

public boolean cancel(BusinessActionContext context) {
    return stockRepository.cancel(context);
}
```

TCC 不依赖底层数据库必须支持统一事务，但需要业务实现 Try、Confirm、Cancel，并处理幂等、空回滚和悬挂问题，开发复杂度较高。

#### 3. XA 模式

XA 依赖数据库等资源对 XA 协议的支持，Seata 负责协调 XA 分支完成两阶段提交。

优点：

- 对业务代码侵入小
- 隔离性和一致性更强
- 适合已有 XA 能力的关系型数据库

缺点：

- prepare 后资源可能长时间持锁
- 阻塞时间长，性能和吞吐较差
- 依赖底层资源支持 XA

#### 4. Saga 模式

Saga 适合长事务和步骤较多的业务流程。每个参与者先提交本地事务，如果后续步骤失败，就按已成功步骤执行补偿操作。

```text
正向：创建订单 -> 扣库存 -> 扣余额
失败：扣余额失败
补偿：恢复库存 -> 取消订单
```

Saga 的优点是本地事务短、适合异步和长流程；缺点是隔离性弱，补偿逻辑需要业务开发，并且补偿本身也要保证幂等。

### 第五层：项目中的使用步骤

#### 1. 选择事务模式

- 普通关系型数据库、希望少改业务代码：优先评估 AT
- 需要精细控制资源、跨非数据库资源：评估 TCC
- 底层资源支持 XA、强调强隔离：评估 XA
- 长流程、多步骤、允许最终一致：评估 Saga

#### 2. 部署 Seata Server

生产环境通常需要配置：

- 注册中心
- 配置中心
- TC 集群
- 事务日志存储
- 数据库或 Redis 等存储方案

#### 3. 业务服务接入客户端

每个参与分布式事务的服务都要接入 Seata 客户端，并配置相同的事务组和 TC 地址。

#### 4. 配置数据源和表结构

AT 模式需要使用 Seata 数据源代理，并在业务库中创建 `undo_log` 表。具体表结构要和当前客户端版本匹配，不要直接复制不兼容版本的脚本。

#### 5. 标记全局事务入口

通常只在业务调用链最上层标记 `@GlobalTransactional`，不要在每个下游方法上随意嵌套，否则会让事务边界和故障排查变复杂。

#### 6. 验证 XID 传播和回滚

测试时要模拟：

- 正常提交
- 中间服务异常
- 超时
- 重试
- 服务重启

确认 XID 能传播到下游，并确认各分支最终状态符合预期。

### 第六层：深入思考

#### Seata 不是万能的强一致方案

Seata 依赖网络、TC 和各参与者配合，不能消除分布式系统中的网络分区、超时和重复调用。它解决的是事务协调问题，业务仍然要设计幂等、重试、超时和补偿。

#### 为什么要按场景选择模式

- AT 开发简单，但对数据库和 SQL 有要求。
- TCC 灵活，但业务侵入和维护成本高。
- XA 一致性和隔离性好，但资源锁持有时间长。
- Saga 适合长流程，但通常是最终一致而不是强隔离。

## 回答思路

### 答题逻辑框架

1. 先定义 Seata：微服务分布式事务框架。
2. 讲清 TM、TC、RM 三个角色。
3. 按“开启、传播、注册、执行、提交/回滚”讲生命周期。
4. 重点展开 AT，简述 TCC、XA、Saga 的差异。
5. 最后说项目接入步骤和选型注意事项。

### 重点得分点

- 能说出 TM、TC、RM 的职责。
- 能说出 XID 传播和分支事务注册。
- 能说明 AT 的 undo_log、前后镜像和二阶段回滚。
- 能对比 AT、TCC、XA、Saga 的适用场景。
- 能说出 `@GlobalTransactional`、数据源代理和 `undo_log`。

### 常见误区

- 把 Seata 当成单机事务增强工具。
- 只会说 `@GlobalTransactional`，说不出 TC、RM 和 XID。
- 认为 AT 模式不需要任何数据库表。
- 认为 Seata 能自动解决重复调用和业务幂等。
- 把 Saga 的补偿当成数据库回滚。

### 面试话术

“Seata 把跨服务事务拆成一个全局事务和多个分支事务，由 TM 发起和决定，TC 统一协调，RM 管理各服务本地资源。项目接入时先部署 Seata Server，再让各服务引入客户端、配置事务组和 TC 地址；AT 模式还要配置数据源代理和 `undo_log`，最后在业务入口使用 `@GlobalTransactional`。AT 通过 undo log 自动回滚，TCC 由业务实现 Try/Confirm/Cancel，XA 依赖资源协议，Saga 则通过补偿完成长事务。”


---

> 📋 **分类**: distributed
> 🏷️ **标签**: `RM` `分布式事务` `TCC` `TC` `Saga` `Seata` `AT` `XA` `TM`
> 📊 **难度**: hard
> 📅 **归档时间**: 2026-09-02 14:44:49
