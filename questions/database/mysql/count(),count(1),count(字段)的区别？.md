---
id: q0061
question: "count(*),count(1),count(字段)的区别？"
category: mysql
tags: []
difficulty: medium
created: 2026-08-21 00:48:03
source: 用户输入
---

# count(*),count(1),count(字段)的区别？

## 联想记忆法

### 记忆口诀/联想

**口诀：星一都数有效，字段先判非空；InnoDB 三者同路，NULL 值另算。**

- `COUNT(*)`：统计结果集中的行数。
- `COUNT(1)`：每行都提供一个非 NULL 常量 1，也统计行数。
- `COUNT(column)`：只统计该列值不为 `NULL` 的行。

### 记忆原理

把 `COUNT` 想成“逐行验票”：`*` 和 `1` 对每一行都能验票，所以统计所有行；字段则要检查这张票上的字段是否为空，`NULL` 行不计入。口诀中的“星一都数”用于记住常见等价性，“字段先判非空”用于防止遗漏 NULL。

### 关联知识

- `NULL` 与 SQL 三值逻辑：`NULL` 不是空字符串，也不是 0。
- InnoDB 的索引、聚簇索引和覆盖索引会影响 `COUNT` 的执行成本。
- `COUNT(*)` 统计的是满足 `WHERE` 条件的行数，不是整张表无条件的固定元数据值。

---

## 深度解答

### 第一层：核心概念

三种写法的语义分别是：

```sql
COUNT(*)       -- 统计结果集的行数
COUNT(1)       -- 对每行计算常量 1，统计非 NULL 表达式的行数
COUNT(column)  -- 只统计 column IS NOT NULL 的行数
```

例如表中有四行，其中 `nickname` 有一行是 `NULL`：

| id | nickname |
|---:|---|
| 1 | 张三 |
| 2 | 李四 |
| 3 | `NULL` |
| 4 | 王五 |

```sql
SELECT COUNT(*), COUNT(1), COUNT(nickname)
FROM user_account;
```

结果通常是 `4、4、3`。如果加上 `WHERE`，三者都只对过滤后的结果集计算。

### 第二层：底层原理

#### 1. `COUNT(*)`

`*` 在这里不是把所有列取出来再相加，也不是“统计非空字段”。它表达的是“结果集中的行”。在 InnoDB 中，MySQL 需要按照可见性、事务隔离和 `WHERE` 条件处理记录，因此一般不能像某些非事务引擎那样直接从一个固定表元数据返回精确行数。

优化器会选择成本较低的访问路径，例如扫描较窄的二级索引，前提是能够正确完成统计。`COUNT(*)` 不等于一定全表扫描。

#### 2. `COUNT(1)`

`1` 是对每行都为非 `NULL` 的常量表达式，因此只要该行进入结果集，就会被计数。从结果语义看，`COUNT(1)` 与 `COUNT(*)` 都统计行数。现代 MySQL 优化器通常会将二者处理成相同或近似的执行计划，不能把“`COUNT(1)` 一定更快”当成优化结论。

#### 3. `COUNT(column)`

它统计表达式值非 `NULL` 的行。字段可以是普通列，也可以是表达式：

```sql
SELECT COUNT(phone), COUNT(NULLIF(status, 0))
FROM user_account;
```

第一列只计算 `phone` 非 NULL 的行；第二列只统计 `status` 不为 0 且结果非 NULL 的行。`COUNT(column)` 的关键不是字段是否有空字符串，而是表达式结果是否为 SQL `NULL`。

### 第三层：实践应用

#### 1. 统计总行数与非空字段数

```sql
-- 统计已注册用户总数
SELECT COUNT(*)
FROM user_account
WHERE status = 1;

-- 统计填写手机号的用户数
SELECT COUNT(phone)
FROM user_account
WHERE status = 1;

-- 更直观地表达非空条件
SELECT COUNT(*)
FROM user_account
WHERE status = 1 AND phone IS NOT NULL;
```

当业务含义是“符合条件的行数”，优先写 `COUNT(*)`；当业务含义是“某字段非空的数量”，使用 `COUNT(column)` 或显式的 `WHERE column IS NOT NULL`。

#### 2. `COUNT(*)` 与 `COUNT(id)` 的选择

如果 `id` 是 `NOT NULL` 主键，那么 `COUNT(id)` 在结果上常与 `COUNT(*)` 一样，但表达意图不如 `COUNT(*)` 清晰。若字段允许 NULL，`COUNT(id)` 会少算 NULL 行。统计行数时不要为了“看起来使用了索引”而随意改成 `COUNT(id)`。

#### 3. 使用 `EXPLAIN` 分析性能

```sql
EXPLAIN
SELECT COUNT(*)
FROM orders
WHERE user_id = 1001 AND status = 1;
```

检查实际索引、扫描行数和过滤比例。对于大表，重点是让过滤条件有合理索引、减少扫描范围，而不是在 `COUNT(*)` 与 `COUNT(1)` 之间反复切换。

如果查询只需要索引中的列，优化器可能选择较窄的二级索引来扫描；但是否选择某个索引取决于统计信息和成本估算。不要把“使用了索引”误认为“完全不读表数据”或“必然更快”。

#### 4. 分组统计

```sql
SELECT status, COUNT(*) AS total
FROM orders
GROUP BY status;

SELECT status, COUNT(delivered_at) AS delivered_count
FROM orders
GROUP BY status;
```

前者统计每个状态的订单总行数，后者统计每个状态中已经填写发货时间的订单数。用字段计数时必须确认 NULL 是否恰好代表“未发生”。

### 第四层：深入思考

#### 性能上三者有区别吗

在现代 MySQL 中，`COUNT(*)` 和 `COUNT(1)` 对非 NULL 行的计数通常没有有意义的性能差异。真正决定性能的因素包括：

- 是否有 `WHERE` 条件以及过滤选择性。
- 扫描的数据页和索引页数量。
- 是否需要回表。
- 事务隔离下的可见性判断。
- Buffer Pool 命中率、统计信息和并发负载。

因此工程上推荐：统计行数使用语义清晰的 `COUNT(*)`，不要依赖 `COUNT(1)` 的“性能神话”。

#### `COUNT(*)` 会不会自动使用主键

不应简单回答“会”或“不会”。优化器可能选择主键索引，也可能选择更窄的二级索引，甚至在条件不合适时全表扫描。InnoDB 没有一个在所有事务场景都准确的全局行数计数器，执行计划要由实际 SQL、索引和数据分布决定。

#### `COUNT(*)` 与 `COUNT(column)` 的 NULL 细节

以下值都不是 SQL `NULL`，会被 `COUNT(column)` 计数：

- 空字符串 `''`。
- 数字 0。
- 字符串 `'NULL'`。

只有真正的 `NULL` 不计数。判断时可以用：

```sql
SELECT COUNT(*) - COUNT(phone) AS missing_phone
FROM user_account;
```

它表示结果集中手机号为 NULL 的行数。

#### 近似计数与准确计数

超大表的实时精确 `COUNT(*)` 可能成本较高。若业务只需要展示近似数量，可以使用统计信息、缓存计数或离线汇总；若用于结算、库存、权限等关键逻辑，必须使用准确数据并处理事务一致性，不能拿近似值替代。

#### 面试官常见追问

- `COUNT(0)` 呢：和 `COUNT(1)` 一样，常量非 NULL，统计行数。
- `COUNT(DISTINCT column)` 呢：统计去重后的非 NULL 值数量。
- `COUNT(*)` 是否包含 NULL 行：包含，只要该行满足查询条件。
- `COUNT(column)` 是否统计空字符串：统计，空字符串不是 NULL。

---

## 回答思路

### 答题逻辑框架

1. 先用一句话给结论：`COUNT(*)` 和 `COUNT(1)` 通常都数行，`COUNT(字段)` 排除字段值为 NULL 的行。
2. 用四行示例表演示结果 `4、4、3`。
3. 解释三者语义、优化器处理和 InnoDB 行可见性。
4. 补充 `NULL`、空字符串、索引和 `EXPLAIN`。
5. 以“语义优先，别迷信 COUNT(1)”收尾。

### 重点得分点

- 不把 `COUNT(*)` 说成统计所有字段非空。
- 明确 `COUNT(column)` 只排除真正的 `NULL`。
- 说明 `COUNT(*)` 与 `COUNT(1)` 通常无本质性能差别。
- 能把性能优化重点放在过滤条件、索引和扫描行数上。

### 常见误区

- 认为 `COUNT(1)` 一定比 `COUNT(*)` 快。
- 认为 `COUNT(*)` 会把整行所有列都读取出来。
- 把空字符串、0 或字符串 `NULL` 当成 SQL NULL。
- 认为 InnoDB 可以无条件从元数据秒回精确总行数。

### 过渡话术

“这道题先不要从性能神话开始，而要先区分统计对象：`*` 和常量统计行，字段统计非空值。语义明确后，再结合执行计划讨论性能。”

### 时间分配建议

- 30 秒讲核心结论和 NULL 示例。
- 60 秒讲底层语义与执行计划。
- 30 秒讲实践选择、误区和超大表计数。


---

> 📋 **分类**: java
> 🏷️ **标签**: 
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-21 00:48:03
