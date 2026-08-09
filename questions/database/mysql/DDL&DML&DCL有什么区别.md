---
id: q0009
question: "DDL&DML&DCL有什么区别?"
category: mysql
tags: ["基础", "sql"]
difficulty: easy
created: 2026-08-10 00:55:15
source: 用户输入
---

# DDL&DML&DCL有什么区别?


---

## 联想记忆法

### 记忆口诀/联想

**口诀:"DDL 动结构,DML 动数据,DCL 动权限,TCL 控事务——隐式提交 DDL,事务回滚靠 DML"**

或者用更简的**"定、改、控、交"**四字诀:

- **定** = DDL(Data Definition Language,数据定义语言)定义结构:CREATE / ALTER / DROP / TRUNCATE / RENAME
- **改** = DML(Data Manipulation Language,数据操作语言)改数据行:INSERT / UPDATE / DELETE
- **控** = DCL(Data Control Language,数据控制语言)控权限:GRANT / REVOKE
- **交** = TCL(Transaction Control Language,事务控制语言)控事务:COMMIT / ROLLBACK / SAVEPOINT

再加一个**回滚锚点**:能 ROLLBACK 的只有 DML(且必须在事务内);DDL 隐式提交不可回滚。

### 记忆原理

口诀的钩子是**"动词 + 对象"**:四种语言各自对应一个操作对象——结构、数据、权限、事务。四个首字母 D-D-D-T 用"定改控交"四个动作压成一句;再从**"能不能回滚"**这个锚点切入:能回滚的是 DML(有事务、有 undo log),不能回滚的是 DDL(隐式提交),与数据无关的是 DCL。一条主线串起全部考点,面试时不会漏点。

### 关联知识

- **与事务机制关联**:DML 可回滚依赖 undo log 与事务模型;DDL 隐式提交(implicit commit)是事务模型的一部分
- **与 MySQL 8.0 atomic DDL 关联**:新版本 DDL 具备语句级原子性,但依然不可用 ROLLBACK 回滚——这是最容易混淆的点
- **与 binlog/主从复制关联**:DELETE 逐行记 binlog(Row 格式),TRUNCATE 只记一条 DDL——影响复制与恢复
- **与权限体系关联**:DCL 操作的是 mysql 库中的权限表(user/db 等),GRANT 后需重连才生效

---

## 深度解答

### 第一层：核心概念

#### 什么是四大语言

SQL(Structured Query Language,结构化查询语言)按**操作对象**分为四大类:

| 类别 | 全称 | 操作对象 | 主要关键字 |
|---|---|---|---|
| DDL | Data Definition Language(数据定义语言) | 数据库/表**结构** | CREATE、ALTER、DROP、TRUNCATE、RENAME |
| DML | Data Manipulation Language(数据操作语言) | 数据**行** | INSERT、UPDATE、DELETE |
| DQL | Data Query Language(数据查询语言) | 查询 | SELECT(常并入 DML 讨论,更规范是单列) |
| DCL | Data Control Language(数据控制语言) | **权限** | GRANT、REVOKE |
| TCL | Transaction Control Language(事务控制语言) | 事务 | COMMIT、ROLLBACK、SAVEPOINT |

一句话:**DDL 建结构、DML 动数据、DCL 管权限、TCL 控事务**。SELECT 通常单独划为 DQL,因为它既不改变结构也不改变数据。

#### 最核心的区别：能不能回滚

- **DML 在事务内执行,可 ROLLBACK**:DML 对行的修改写入 undo log,事务未提交前可以撤销
- **DDL 隐式提交,不可回滚**:执行 DDL 会自动提交当前事务,DDL 本身也立即生效;MySQL 8.0 之前,DDL 执行中崩溃还可能残留半成品状态
- **DCL 控制权限,不涉及业务数据**:授权与回收不产生数据变更

---

### 第二层：底层原理

#### 为什么 DML 能回滚而 DDL 不能

1. **undo log 只记录"行级变更"**:回滚的本质是"撤销",undo log 记录的是每一行数据的修改前快照(旧版本)。DML 修改的是行,每条变更都有对应的 undo 记录,所以可以逐行撤销;DDL 修改的是**表结构(元数据)**,不是行数据,undo log 无从记录
2. **隐式提交机制**:MySQL 规定,DDL 语句执行前会隐式提交当前事务,执行后立即生效并提交。因此事务内的 DML 一旦碰到 DDL,前面的修改也会被一并提交,无法整体回滚
3. **MySQL 8.0 的 atomic DDL**:8.0 起,单个 DDL 语句的数据字典更新、存储引擎操作、binlog 写入被合并为**单个原子操作**,要么全部成功要么全部回滚,崩溃后不会残留中间状态(例如建表建到一半)。注意区分:**atomic DDL 保证的是"语句执行过程中的原子性/崩溃安全",不是"事后可以 ROLLBACK"**——DROP 之后依然找不回表

#### 各类语言的 SQL 示例

**DDL(结构操作,隐式提交,不可回滚)**

```sql
-- 建表
CREATE TABLE user (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(32) NOT NULL,
  age INT
) ENGINE=InnoDB;

-- 修改表结构:加列 / 改类型
ALTER TABLE user ADD COLUMN email VARCHAR(64) AFTER name;
ALTER TABLE user MODIFY COLUMN age TINYINT;

-- 清空表数据(保留结构,DDL,不可回滚)
TRUNCATE TABLE user;

-- 删除表(结构+数据一起删,不可回滚)
DROP TABLE user;

-- 重命名表
RENAME TABLE user TO user_backup;
```

**DML(行操作,事务内可回滚)**

```sql
-- 事务内执行 DML
START TRANSACTION;
INSERT INTO user (name, age) VALUES ('张三', 25);
UPDATE user SET age = 26 WHERE name = '张三';
DELETE FROM user WHERE name = '张三';
ROLLBACK;   -- 全部撤销,表里没有任何记录

-- 提交
COMMIT;
```

**DCL(权限控制)**

```sql
-- 授权:只给查询权限
GRANT SELECT ON mydb.user TO 'readonly'@'%';

-- 回收权限
REVOKE SELECT ON mydb.user FROM 'readonly'@'%';

-- 查看当前用户的权限
SHOW GRANTS FOR 'readonly'@'%';
```

**TCL(事务控制)**

```sql
START TRANSACTION;
UPDATE account SET balance = balance - 100 WHERE id = 1;
SAVEPOINT sp1;                          -- 设置保存点
UPDATE account SET balance = balance + 100 WHERE id = 2;
ROLLBACK TO SAVEPOINT sp1;              -- 只回滚到 sp1,不撤销第一条 UPDATE
COMMIT;
```

---

### 第三层：实践应用

#### TRUNCATE vs DELETE vs DROP 全对比

| 维度 | DELETE | TRUNCATE | DROP |
|---|---|---|---|
| 语言分类 | DML | DDL | DDL |
| 操作对象 | 行数据(可带 WHERE 条件) | 整表数据(保留表结构) | 表结构 + 数据 + 索引 |
| 是否可回滚 | 事务内可 ROLLBACK | 不可回滚(隐式提交) | 不可回滚 |
| 是否触发触发器 | 逐行触发 DELETE 触发器 | 不触发触发器 | 不触发 |
| 自增计数 | 不重置,继续累加 | 重置为初始值 | 表已删除 |
| 性能 | 慢:逐行删除 + binlog 逐行记录 | 快:直接释放数据页,binlog 只记 DDL | 快 |
| binlog 记录 | Row 格式逐行记 | 记录为一条 DDL 语句 | 记录为一条 DDL 语句 |

#### 为什么线上"删除数据"不用 TRUNCATE

- **不可回滚**:误删后无法用 ROLLBACK 找回,只能靠备份恢复,代价巨大
- **不触发触发器**:依赖触发器做审计/同步逻辑的场景会静默失效
- **自增重置**:可能导致主键复用,引发历史引用错乱
- **复制行为差异**:Row 模式下 DELETE 在从库逐行回放;TRUNCATE 需要表级锁,大表在主从间可能放大锁时间
- 正确姿势:需要清空数据时,**先备份/确认,再用 DELETE 包在事务里分批删**,而不是 TRUNCATE

#### 账号设计与权限最小化

- **只读账号**:`GRANT SELECT ON mydb.* TO 'readonly'@'%';` 用于报表、BI 只读查询
- **读写账号**:`GRANT SELECT, INSERT, UPDATE, DELETE ON mydb.* TO 'app'@'%';`——**只授 DML,不授 DDL**,防止应用侧误删表
- **DBA 账号**:才授 DDL/全局权限,且只给运维人员
- **原则:权限最小化(least privilege)**:每个账号只授完成任务所需的最少权限;定期 REVOKE 回收离职/调整人员的权限;密码走密钥管理,不硬编码在代码里

---

### 第四层：深入思考

#### 1. atomic DDL 到底解决了什么

MySQL 8.0 之前,DDL 执行中崩溃可能留下"表结构部分变更"的脏状态,而且数据字典分散在各 .frm 文件;8.0 把数据字典统一收进 InnoDB,DDL 的数据字典变更与存储引擎变更合并为原子操作,配合 redo log 保证崩溃可恢复。**但要注意**:atomic DDL 不是"把 DROP TABLE 变成可回滚",而是"执行过程中不会半途而废",两者是不同维度,面试时一定要主动讲清这一点。

#### 2. "DML 慢而 DDL 快"的直觉对吗

不完全对。TRUNCATE 快,是因为它不逐行操作、直接释放表的数据页;但 **ALTER TABLE 在大表上是出了名的慢**(多数 ALTER 需要重建表,8.0 的 INSTANT/INPLACE 算法部分场景可免复制)。"DDL 都很快"是常见错觉,ALTER 的在线 DDL 选项(ALGORITHM=INSTANT/INPLACE/COPY)值得了解。

#### 3. 面试官可能的追问方向

- **"DELETE 全表比 TRUNCATE 慢多少,为什么?"** → 逐行删、逐行记 binlog、可能触发触发器;TRUNCATE 直接释放数据页
- **"GRANT 之后一定要 FLUSH PRIVILEGES 吗?"** → 用 GRANT 语句授权会自动生效;只有手动改权限表(直接 INSERT 到 mysql.user)才需要 FLUSH
- **"事务里执行了 DDL,前面的 DML 还能回滚吗?"** → 不能,DDL 触发隐式提交,前面的 DML 也被一并提交
- **"MySQL 8.0 能恢复被 DROP 的表吗?"** → 不能靠事务;要靠 binlog/备份(闪回工具)恢复
- **"UPDATE 不写 WHERE 会怎样?"** → 全表更新,生产事故高发区;配合事务与影响行数确认

---

## 回答思路

### 答题逻辑框架

面试时建议按以下层次递进回答,总时长控制在 **2-3 分钟**:

```
┌────────────────────────────────────────────┐
│ 第一层(20秒):分类总述                       │
│ "SQL 按操作对象分四类:DDL 动结构、DML 动数据 │
│  、DCL 动权限、TCL 控事务"                   │
├────────────────────────────────────────────┤
│ 第二层(40秒):每类关键字 + 一个示例          │
│ CREATE/ALTER/DROP + INSERT/UPDATE/DELETE + │
│ GRANT/REVOKE + COMMIT/ROLLBACK              │
├────────────────────────────────────────────┤
│ 第三层(60秒):最核心的区别——回滚            │
│ DML 有事务+undo log 可回滚;DDL 隐式提交;   │
│ 8.0 atomic DDL 是语句级原子性,不是可回滚    │
├────────────────────────────────────────────┤
│ 第四层(40秒):TRUNCATE/DELETE/DROP 对比表    │
│ + 权限最小化实践                            │
└────────────────────────────────────────────┘
```

### 重点得分点(面试官考察意图)

1. **分类与关键字准确**:四类语言的中英文全称、操作对象、典型关键字不错不漏——基础分

2. **回滚机制解释到原理层**:能说出"undo log 只记录行级变更,所以 DML 可回滚、DDL 不可回滚",而不是背结论——核心得分点

3. **知道隐式提交**:DDL 执行前会隐式提交当前事务——考察对事务模型的理解

4. **8.0 atomic DDL 的新特性**:能分清"语句级原子性"与"可回滚"的区别——考察版本敏感度

5. **TRUNCATE/DELETE/DROP 对比**:操作对象、回滚、触发器、自增、性能、binlog 六维度——考察细节完备度

6. **权限最小化意识**:只授所需权限、读写分离账号——考察工程素养

### 常见误区(扣分点)

| 错误说法 | 正确理解 |
|----------|----------|
| "DDL 也能用 ROLLBACK 回滚" | DDL 隐式提交不可回滚;可回滚的只有事务内的 DML |
| "TRUNCATE 属于 DML" | TRUNCATE 是 DDL(清空数据、隐式提交) |
| "SELECT 属于 DML" | 通常单独划分为 DQL(数据查询语言) |
| "DROP 表之后还能 ROLLBACK 恢复" | 不能;8.0 atomic DDL 只保证执行过程原子性 |
| "MySQL 8.0 的 DDL 可以回滚了" | atomic DDL 是崩溃安全,不是事务回滚,两者不要混淆 |
| "GRANT 后必须 FLUSH PRIVILEGES" | GRANT 语句授权自动生效;只有直接改权限表才需 FLUSH |
| "DELETE 不记 binlog" | DELETE 逐行记录(Row 格式),这也是它比 TRUNCATE 慢的原因 |

### 过渡话术建议

- **从分类到原理**:"四类语言按操作对象划分——DDL 动结构、DML 动数据、DCL 动权限、TCL 控事务。面试官最常追问的是回滚:为什么 DML 能回滚而 DDL 不能?因为 undo log 只记录行级变更,而 DDL 改的是元数据,且 DDL 会隐式提交..."
- **从旧版本到新版本**:"MySQL 8.0 引入 atomic DDL 后,DDL 有了语句级原子性,崩溃不会残留半成品,但它依然不是可回滚的——这两点经常被混淆..."
- **从概念到实践**:"实际运维中,清空一张大表我不会用 TRUNCATE,而是先备份、再用 DELETE 包在事务里分批删,因为 TRUNCATE 不可回滚、不触发触发器、还会重置自增..."
- **收尾过渡**:"权限这块我习惯遵循最小化原则:应用账号只授 DML,只读账号只授 SELECT,DDL 权限只给 DBA——这样即使应用被注入,损失也有限。"

### 时间分配建议

- **面试总时长 45 分钟的场景**:回答控制在 2-3 分钟内;分类与示例 1 分钟,回滚原理 1 分钟,对比表与实践 1 分钟
- **如果面试官打断**:说完"四类语言 + DDL 不可回滚的原因"即可停,这是核心中的核心
- **遇到追问如何应对**:追问到 atomic DDL 源码实现细节可答"核心是数据字典合并进 InnoDB、配合 redo log 保证崩溃恢复,具体实现细节我可以再确认"——守住主线不丢分

---

> 📋 **分类**: mysql
> 🏷️ **标签**: `基础` `sql`
> 📊 **难度**: easy
> 📅 **归档时间**: 2026-08-10 00:55:15
