---
id: q0013
question: "数据库的事务隔离级别都有哪些?MySQL默认隔离级别知道吗?会有啥问题?"
category: mysql
tags: ["事务", "隔离级别"]
difficulty: medium
created: 2026-08-10 00:55:24
source: 用户输入
---

# 数据库的事务隔离级别都有哪些?MySQL默认隔离级别知道吗?会有啥问题?


---

## 联想记忆法

### 记忆口诀/联想

**口诀："未提脏，已提跳，可重复，幻影消；串行化，全锁牢，默认 RR 别记倒"**

- **未提脏** = 读未提交（READ UNCOMMITTED）：能读到别人未提交的数据 → 脏读（Dirty Read）
- **已提跳** = 读已提交（READ COMMITTED，RC）：只能读已提交，但同一事务两次查询结果可能不同 → 不可重复读（Non-Repeatable Read）
- **可重复** = 可重复读（REPEATABLE READ，RR）：事务内多次读取结果一致 → 解决不可重复读；**MySQL 默认级别**
- **幻影消** = MySQL 的 RR 通过 MVCC 快照读 + 间隙锁，在大多数场景把幻读（Phantom Read）也解决了
- **串行化** = 串行化（SERIALIZABLE）：读加共享锁、写加排他锁，事务完全串行 → 全部异常消除，但并发性能最差
- **默认 RR 别记倒** = MySQL 默认 RR，Oracle/SQL Server 默认 RC，别混

### 记忆原理

口诀按**"级别 → 它留下的问题"**逐级押韵（脏/跳/幻），形成一条递进的"异常链"：每升一级解决一个异常、遗留下一个异常，像打怪升级——脏读（未提交）→ 不可重复读（值变了）→ 幻读（行数变了）→ 全解决。记住"脏、跳、幻"三个异常词，四级级别的遗留问题就不会漏；再用"默认 RR 别记倒"锁定 MySQL 的默认答案，这是面试第一问。

### 关联知识

- **与 MVCC 关联**：RC 每条语句生成新 ReadView（读视图），RR 事务内复用同一个 ReadView——这是"为什么 RR 能解决不可重复读"的机制答案
- **与锁关联**：当前读（锁定读）靠 Next-Key Lock（临键锁 = 记录锁 + 间隙锁）解决 RR 下的幻读，也是 RR 死锁概率高的根源
- **与 binlog 关联**：MySQL 历史上默认 RR，正是因为 5.0 时代 statement 格式 binlog 在 RC 下会产生主从不一致；binlog_format=ROW 之后 RC 变安全，很多公司才切换
- **与 ACID 关联**：隔离性（Isolation）是 ACID 之一，隔离级别就是隔离性的"档位表"

---

## 深度解答

### 第一层：核心概念

#### 为什么需要隔离级别

并发事务同时读写同一批数据时，会产生三类异常，按严重程度排列：

- **脏读（Dirty Read）**：读到**另一个事务未提交**的数据。该事务后续回滚，读到的就是"不存在"的数据——最严重的错误
- **不可重复读（Non-Repeatable Read）**：同一事务内**同一条记录读两次，值不同**（另一个事务在这期间提交了修改）
- **幻读（Phantom Read）**：同一事务内**同一个条件查询两次，结果集行数不同**（另一个事务提交了新插入的行/删除了行）。重点是"多出来的行"，不是"值变了"

注意区分：不可重复读是"同一行，值变"；幻读是"同一条件，行数变"。两者都是"前后不一致"，但对象不同。

#### 四种隔离级别（由松到严）

| 隔离级别 | 能解决的问题 | 遗留的问题 | 常见默认 |
|---|---|---|---|
| READ UNCOMMITTED（读未提交） | 无（只防脏写） | 脏读、不可重复读、幻读 | 极少使用 |
| READ COMMITTED（读已提交，RC） | 脏读 | 不可重复读、幻读 | **Oracle、SQL Server 默认** |
| REPEATABLE READ（可重复读，RR） | 脏读、不可重复读 | 幻读（标准定义；MySQL 大多数场景已解决） | **MySQL 默认** |
| SERIALIZABLE（串行化） | 全部 | 无（代价是并发最差） | 几乎不用 |

**RC、RR、SERIALIZABLE 都解决了脏读**；RC 解决脏读遗留不可重复读；RR 再解决不可重复读，标准定义下遗留幻读；SERIALIZABLE 读加共享锁写加排他锁，事务完全串行，全解决但并发最差。

---

### 第二层：底层原理（重点）

#### MVCC 快照读：RC 与 RR 的实现分水岭

InnoDB 的普通 `SELECT`（快照读/一致性非锁定读）走 **MVCC（多版本并发控制）**：利用 undo log 的版本链，为每次读生成一个 **ReadView（读视图）**，按可见性规则从版本链里挑出"我能看到的版本"。

```
行数据的版本链（undo log 串联）：
row 最新版 ← trx_id=30 ← roll_pointer ← 版本2(trx_id=25) ← 版本1(trx_id=20)

ReadView 关键字段：
  m_ids:      生成 ReadView 时"仍在活跃"的事务 id 列表
  min_trx_id: 活跃事务的最小 id
  max_trx_id: 下一个将分配的事务 id
可见性规则（简化）：
  版本 trx_id < min_trx_id        → 已提交，可见
  版本 trx_id 在 m_ids 中（活跃） → 不可见，沿 roll_pointer 往前找
  版本 trx_id ≥ max_trx_id        → 未来事务，不可见
```

**RC 与 RR 的唯一区别就在 ReadView 的生成时机**：

- **RC：每条语句生成一个新的 ReadView** → 其他事务在两条语句之间提交，新 ReadView 下"看不见它提交的修改"→ 这就是不可重复读的来源
- **RR：事务内第一次读时生成 ReadView，之后一直复用** → 无论其他事务何时提交，后续所有快照读都只看这一个视图 → **这就是 RR 解决不可重复读的机制原因，纯靠 MVCC，不依赖锁**

```
RC：SELECT ... → ReadView A → 结果 v1
    另一个事务提交 update
    SELECT ... → ReadView B → 结果 v2 ≠ v1   ← 不可重复读

RR：SELECT ... → ReadView A → 结果 v1
    另一个事务提交 update
    SELECT ... → 复用 ReadView A → 结果 v1   ← 前后一致
```

#### 当前读与 Next-Key Lock：RR 如何挡幻读

`SELECT ... FOR UPDATE`、`SELECT ... LOCK IN SHARE MODE`、`UPDATE`、`DELETE` 都是**当前读**（锁定读）：读最新已提交版本，并给数据加锁。RR 下当前读默认加 **Next-Key Lock（临键锁 = 记录锁 + 间隙锁）**：

```
记录锁（Record Lock）：锁住命中的具体行
间隙锁（Gap Lock）：   锁住记录之间的间隙，禁止其他事务在这个区间插入
Next-Key Lock：       两者相加，锁住"间隙 + 端点记录"，形如 (1, 2]（左开右闭）

例：UPDATE user SET age = age + 1 WHERE age > 20 AND age < 30;
   → 对 age 索引上 20~30 区间加 Next-Key Lock
   → 其他事务在 21~29 之间 INSERT 会被阻塞 → 幻读被物理挡死
```

在 RR 下，间隙锁保证"我加锁的区间里不会长出新的行"，幻读在当前读路径上被解决；`SERIALIZABLE` 则是把普通 SELECT 也升级为共享锁当前读，彻底串行。

#### MySQL 的 RR 与 SQL 标准的差异（高频考点）

SQL 标准认为：RR 仍有幻读，只有 SERIALIZABLE 能解决。而 **MySQL 的 RR 通过 MVCC + 间隙锁，在大多数场景下把幻读也解决了**，比标准定义更强：

- **快照读下**：ReadView 复用，新插入的行根本不可见，无幻读
- **当前读下**：Next-Key Lock 挡住区间内插入，无幻读
- **但有边角场景**：同一 RR 事务内"先快照读、后当前读"，若另一事务已插入并提交，当前读会看到新行（锁只能拦"还没插入的"，拦不住"已经插入的"）；且间隙锁只是"锁区间"而非"锁未来"，通过 `INSERT ... SELECT` 等操作组合仍可能感知幻影。另外，间隙锁把锁范围从几行扩大到整个区间，**并发度下降、死锁概率上升**——这就是 RR 的代价

#### 三种异常的现场演示（会话 A/B，文字模拟）

**脏读（READ UNCOMMITTED 下）**：

```sql
-- 会话 A                              -- 会话 B
SET SESSION TRANSACTION
  ISOLATION LEVEL READ UNCOMMITTED;
START TRANSACTION;                    START TRANSACTION;
UPDATE account SET balance = 0
  WHERE id = 1;                       -- 未提交
                                       SELECT balance FROM account
                                         WHERE id = 1;
                                       -- 读到 0（脏数据！）
ROLLBACK;  -- B 之前读到的 0 是幻影
```

**不可重复读（READ COMMITTED 下）**：

```sql
-- 会话 A（RC）                        -- 会话 B
START TRANSACTION;
SELECT amount FROM orders
  WHERE id = 9;                        -- 读到 100
                                       START TRANSACTION;
                                       UPDATE orders SET amount = 200
                                         WHERE id = 9;
                                       COMMIT;
SELECT amount FROM orders
  WHERE id = 9;                        -- 读到 200，前后不一致
COMMIT;
```

**幻读（SQL 标准下的 RR；MySQL 快照读下不会出现）**：

```sql
-- 会话 A（RR）                        -- 会话 B
START TRANSACTION;
SELECT COUNT(*) FROM orders
  WHERE status = 'PENDING';            -- 返回 3
                                       INSERT INTO orders(status)
                                         VALUES ('PENDING');
                                       COMMIT;
SELECT COUNT(*) FROM orders
  WHERE status = 'PENDING';            -- 返回 4，多出一行（幻影）
COMMIT;
```

---

### 第三层：实践应用

#### 设置与查看隔离级别

```sql
-- 查看（8.0 用 transaction_isolation，5.7 用 tx_isolation）
SELECT @@global.transaction_isolation, @@session.transaction_isolation;
-- 默认输出：REPEATABLE-READ

-- 设置（可全局/会话/下一条事务）
SET GLOBAL TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
```

#### 生产实践：为什么很多公司改 RC

阿里《Java 开发手册》明确：**禁止使用 RR，推荐 RC**。理由：

1. **间隙锁**：RR 下 UPDATE/DELETE 会加间隙锁，锁范围大 → 死锁概率显著上升（线上死锁日志里 Gap locks 占比极高）
2. **先查后写的坑**：RR 快照读看不到其他事务已提交的新行，业务"先 SELECT 判断再 INSERT"会重复插入（判断条件形同虚设），需要改用 `INSERT ... ON DUPLICATE KEY` 或唯一索引兜底
3. RC 下快照读每次读最新提交，语义更接近业务直觉；配合 `binlog_format=ROW`，主从复制同样安全

**MySQL 为什么历史上默认 RR？** 5.0 时代 binlog 默认 statement 格式（记录 SQL 原文），主从重放 SQL 时，RC 下无间隙锁、语句执行顺序不确定（如 `DELETE ... ORDER BY ... LIMIT`、无索引 UPDATE 扫全表），会导致**从库与主库数据不一致**；RR 的间隙锁把执行确定性"锁"了出来，所以默认 RR。`binlog_format=ROW`（记录行变更，从库逐行重放）之后 RC 已安全，这是改 RC 的技术前提。

---

### 第四层：深入思考

#### 1. "会有啥问题"——RR 的代价全景

| 问题 | 机制根源 | 后果 |
|---|---|---|
| 间隙锁死锁 | 锁区间而非锁行，两事务交叉锁不同区间 | 死锁概率显著上升，需频繁排查死锁日志 |
| 大事务 undo 膨胀 | RR 长事务持有同一个 ReadView，undo 版本链无法 purge（清理） | undo 表空间暴涨、回滚代价大、读变慢 |
| 快照读看不见新提交 | ReadView 复用 | "先查后写"业务判断失效，可能重复插入 |
| 并发度下降 | 间隙锁阻塞区间内插入 | 高并发插入场景吞吐受限 |

应对：短事务（小步提交）、RC + ROW 格式 binlog、间隙锁敏感语句（如按日期范围更新）改为等值条件或分批。

#### 2. 锁升级与加锁路径

InnoDB 加锁沿索引走，由小到大：记录锁 → 间隙锁 → 临键锁；**RR 下范围条件默认直接上临键锁**，这是"锁升级"的常见答法；`SERIALIZABLE` 下连普通 SELECT 都带共享锁。理解加锁路径才能解释死锁日志（两个事务各自持有间隙锁、互相等待对方区间释放）。

#### 3. 长事务的危害（必考延伸）

长事务 = 大 undo + 长锁 + 旧快照，是生产事故高发源：undo 无法 purge 导致表空间膨胀、binlog 累积延迟、主从延迟、死锁窗口拉长。`performance_schema` 与 `information_schema.innodb_trx` 可以监控长事务，是排查的标准入口。

#### 4. 面试官可能的追问方向

- "MySQL 的 RR 到底有没有幻读？" → 快照读没有（ReadView 复用），当前读有间隙锁兜底，边角场景（先快照后当前读）可能感知；标准定义下的 RR 仍允许幻读，MySQL 是超集实现
- "为什么 MySQL 的默认和 Oracle 不同？" → 历史 binlog 原因（statement 格式主从一致）+ 间隙锁让 RR 更"完整"；Oracle 没有间隙锁概念，默认 RC 是性能取向
- "RC 下还有间隙锁吗？" → 常规 RC 只加记录锁不加间隙锁（外键校验、duplicate-key 检查等少数路径仍有）
- "改成 RC 要动哪些配置？" → `binlog_format=ROW` + `SET GLOBAL TRANSACTION ISOLATION LEVEL READ COMMITTED`，并评估现有 SQL 是否依赖 RR 语义

---

## 回答思路

### 答题逻辑框架

面试时建议按以下层次递进回答，总时长控制在 **4-5 分钟**（本题为必考重点）：

```
┌─────────────────────────────────────────────────┐
│  第一层（30秒）：全景                           │
│  四级由松到严：RU / RC / RR / SERIALIZABLE     │
│  默认：MySQL = RR，Oracle/SQL Server = RC      │
├─────────────────────────────────────────────────┤
│  第二层（60秒）：三个异常                       │
│  脏读（未提交数据）→ 不可重复读（值变）        │
│  → 幻读（行数变），逐级对应每个级别            │
├─────────────────────────────────────────────────┤
│  第三层（90秒）：MySQL 如何实现（核心得分区）   │
│  MVCC：RC 每条语句新 ReadView，RR 复用 →       │
│  快照读解决不可重复读                          │
│  当前读 + Next-Key Lock（记录+间隙）→ 挡幻读  │
├─────────────────────────────────────────────────┤
│  第四层（60秒）：RR 的问题与历史                │
│  间隙锁死锁、undo 膨胀、先查后写坑             │
│  默认 RR 的历史原因（statement binlog）        │
│  ROW 格式后 RC 安全 → 阿里规范建议 RC          │
└─────────────────────────────────────────────────┘
```

### 重点得分点（面试官考察意图）

1. **三异常定义精准**：脏读 = 未提交、不可重复读 = 同一条记录值变、幻读 = 结果集行数变（新插入的行），这是第一道分水岭
2. **MVCC 的 ReadView 机制**：能说出"RC 每条语句生成新 ReadView、RR 事务内复用"，并由此解释不可重复读的解决——这是全场最亮的机制答案
3. **Next-Key Lock = 记录锁 + 间隙锁**：能说清当前读如何挡幻读，以及间隙锁的代价
4. **MySQL RR 与 SQL 标准的差异**：能辩证回答"MySQL 的 RR 快照读下无幻读、当前读有间隙锁、仍有边角场景"——面试官最想听到的层次感
5. **"会有啥问题"与历史原因**：间隙锁死锁、undo 膨胀、statement binlog 主从一致、ROW 后 RC 安全，答出这些证明你懂生产

### 常见误区（扣分点）

| 错误说法 | 正确理解 |
|----------|----------|
| "RC 解决了不可重复读" | RC 只解决脏读，仍会不可重复读（两次查询值不同） |
| "MySQL 的 RR 有幻读，和标准一样" | 快照读下无幻读（ReadView 复用），当前读靠间隙锁，大多数场景已解决；仅边角场景可能感知 |
| "幻读是读到的值变了" | 幻读是结果集**行数**变了（新插入的行）；值变是不可重复读 |
| "隔离级别越高越好" | 越高并发越差，生产主流是 RC/RR 二选一 |
| "SERIALIZABLE 性能也不错" | 它把普通 SELECT 也加共享锁，事务完全串行，性能最差 |
| "MySQL 默认隔离级别是 RC" | 是 RR；RC 是 Oracle/SQL Server 的默认 |

### 过渡话术建议

- **从全景到异常**："四个级别可以按'遗留问题'记：未提交留脏读，已提交留不可重复读，可重复读留幻读，串行化全解决。三个异常之间是递进关系..."
- **从异常到机制**："MySQL 解决这些异常不靠玄学，靠两个机制：快照读走 MVCC，RC 每条语句生成新 ReadView，RR 复用同一个 ReadView——所以 RR 里同一个事务读一百次结果都一样；当前读则走 Next-Key Lock，记录锁加间隙锁，把区间内插入直接锁死..."
- **从机制到生产**："但 RR 不是免费的：间隙锁范围大，死锁概率明显上升；而且 MySQL 默认 RR 其实有历史包袱——5.0 时代 statement 格式 binlog 在 RC 下主从会不一致。现在 ROW 格式安全了，所以阿里规范推荐 RC..."
- **总结过渡**："总结一下：隔离级别是隔离性的档位表，异常从脏到幻逐级递进；MySQL 用 MVCC 和临键锁把 RR 做成了'超标准'实现，代价是间隙锁和并发；选 RC 还是 RR，是正确性、并发与运维成本的工程权衡。"

### 时间分配建议

- **总时长 4-5 分钟**：30 秒全景 + 60 秒三异常 + 90 秒 MVCC 与锁（核心）+ 60 秒 RR 的问题与历史
- **如果面试官打断**：保住"三异常定义 + RR 的 ReadView 复用 + 默认 RR"即可，锁与历史是加分项
- **遇到追问如何应对**：被追问"MySQL 的 RR 到底有没有幻读"时，先答"快照读没有、当前读有间隙锁"，再补边角场景，分情况作答最显水平；被问锁细节没把握时，可说"锁的详细加锁路径我平时通过死锁日志分析，原理是记录锁+间隙锁的组合"

---

> 📋 **分类**: mysql
> 🏷️ **标签**: `事务` `隔离级别`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-10 00:55:24
