---
id: q0010
question: "MySQL常用查询关键字?"
category: mysql
tags: ["sql", "基础"]
difficulty: easy
created: 2026-08-10 00:55:23
source: 用户输入
---

# MySQL常用查询关键字?


---

## 联想记忆法

### 记忆口诀/联想

**口诀:"查选筛聚排连并,窗函分支助你赢——FROM 先行 WHERE 后,G-H-S-O-L 依次走"**

拆解:

- **查** = 查询核心:SELECT / FROM / WHERE(AND/OR/NOT)/ DISTINCT
- **筛** = 条件筛选:LIKE / IN / BETWEEN / IS NULL
- **聚** = 分组聚合:GROUP BY / HAVING / COUNT / SUM / AVG / MAX / MIN
- **排** = 排序分页:ORDER BY(ASC/DESC)/ LIMIT
- **连** = 表连接:INNER / LEFT / RIGHT JOIN
- **并** = 集合运算:UNION / UNION ALL
- **窗** = 窗口函数:ROW_NUMBER / RANK / DENSE_RANK / LAG / LEAD
- **分支** = CASE WHEN

执行顺序口诀:**"先 FROM 后 WHERE,GROUP 之后 HAVING 起,SELECT 投影 ORDER 排,最后 LIMIT 把数取"**——对应 FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT。

### 记忆原理

口诀设计成**"七类功能 + 一条执行流水线"**的双钩子:先用"查筛聚排连并窗"七个字把高频关键字分类钉住;再把**执行顺序作为主线**串起理解——数据库处理 SQL 就是一条流水线:从数据源(FROM)开始,逐层收窄(WHERE 筛行 → GROUP BY 分组 → HAVING 筛组 → SELECT 投影 → ORDER BY 排序 → LIMIT 截断)。记住了流水线,就记住了"为什么 WHERE 不能用聚合函数"这类必考题——因为时机还没到。

### 关联知识

- **与索引/执行计划关联**:WHERE、JOIN 条件决定索引是否生效,EXPLAIN 可见 type/key/rows
- **与 SQL 优化关联**:深分页优化(延迟关联、书签分页)、ON vs WHERE 位置、覆盖索引
- **与窗口函数对比关联**:窗口函数不折叠行(不像 GROUP BY),是 8.0 新特性考点
- **与子查询/EXISTS 关联**:IN vs EXISTS 的语义与性能是经典追问

---

## 深度解答

### 第一层：核心概念

MySQL 的查询关键字按**职责**可分为八类:基础筛选、条件筛选、分组聚合、排序分页、表连接、集合运算、条件分支、窗口函数。本文用一张学生成绩表贯穿所有示例:

```sql
-- 建表
CREATE TABLE student (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(20) NOT NULL,
  class_id INT,
  score DECIMAL(5,2)
);

-- 造数据
INSERT INTO student (name, class_id, score) VALUES
('张三', 1, 88.5), ('李四', 1, 92.0), ('王五', 2, 75.0),
('赵六', 2, 99.5), ('孙七', 2, 88.5), ('周八', 1, NULL),
('钱九', 1, 92.0);

-- 班级表(用于 JOIN 演示)
CREATE TABLE class (
  id INT PRIMARY KEY,
  name VARCHAR(20)
);
INSERT INTO class VALUES (1, '一班'), (2, '二班'), (3, '三班');
```

---

### 第二层：底层原理

#### SQL 书写顺序 vs 执行顺序(必考)

```
书写顺序(眼睛看到的):
SELECT → FROM → WHERE → GROUP BY → HAVING → ORDER BY → LIMIT

执行顺序(数据库真实处理逻辑):
① FROM(含 JOIN / ON) → ② WHERE → ③ GROUP BY
→ ④ HAVING → ⑤ SELECT(含聚合/去重) → ⑥ ORDER BY → ⑦ LIMIT
```

文字执行流程图:

```
          ┌──────────────────────────────────────────┐
          │ ① FROM:确定数据源(多表先 JOIN/ON 关联)     │
          │ ② WHERE:行级过滤,剔除不满足条件的行        │
          │ ③ GROUP BY:按列分组,产生"组"               │
          │ ④ HAVING:组级过滤,可用聚合函数             │
          │ ⑤ SELECT:投影列,计算聚合函数/DISTINCT/表达式│
          │ ⑥ ORDER BY:对结果集排序                    │
          │ ⑦ LIMIT:截断行数,输出分页                  │
          └──────────────────────────────────────────┘
```

两个"为什么"由此而来:

- **为什么 WHERE 不能写聚合函数**:WHERE 在分组之前、逐行判断,此刻还没有"组"的概念,自然没有 SUM/COUNT 可用;HAVING 在分组之后执行,作用对象是"组",所以能用聚合函数
- **为什么 SELECT 中起的别名不能用在 WHERE**:WHERE 先于 SELECT 执行,别名尚未诞生;但 MySQL 允许 ORDER BY 用别名(因为排序发生在 SELECT 之后)

---

### 第三层：实践应用

#### 1. 基础筛选

```sql
-- WHERE 与逻辑运算符
SELECT * FROM student WHERE class_id = 1 AND score >= 90;
SELECT * FROM student WHERE NOT (class_id = 2 OR score IS NULL);

-- LIKE 模糊查询(% 任意多个字符,_ 单个字符)
SELECT * FROM student WHERE name LIKE '张%';
SELECT * FROM student WHERE name LIKE '_四';

-- IN / BETWEEN / IS NULL
SELECT * FROM student WHERE class_id IN (1, 2);
SELECT * FROM student WHERE score BETWEEN 80 AND 95;   -- 含边界
SELECT * FROM student WHERE score IS NULL;             -- 不能用 = NULL
```

#### 2. 分组聚合

```sql
-- 每班平均分、最高分、人数
SELECT class_id,
       COUNT(*)      AS cnt,
       AVG(score)    AS avg_score,
       MAX(score)    AS max_score
FROM student
GROUP BY class_id;

-- HAVING 筛选组(平均分大于 85 的班)
SELECT class_id, AVG(score) AS avg_score
FROM student
GROUP BY class_id
HAVING avg_score > 85;
```

**COUNT(\*) vs COUNT(1) vs COUNT(列)**:

| 写法 | 统计什么 | 是否忽略 NULL |
|---|---|---|
| COUNT(*) | 统计行数(含 NULL 行) | 不忽略 |
| COUNT(1) | 统计行数,等价 COUNT(*) | 不忽略 |
| COUNT(列) | 统计该列**非 NULL** 的个数 | 忽略 NULL |

示例验证(一班 4 行,其中 1 行 score 为 NULL):

```sql
SELECT COUNT(*) AS all_rows, COUNT(score) AS has_score
FROM student WHERE class_id = 1;    -- all_rows = 4,has_score = 3
```

结论:MySQL 中 COUNT(*) 与 COUNT(1) 性能几乎一致(优化器都会优化为直接数行);COUNT(列) 语义不同,统计的是非空值。**统计行数用 COUNT(*),统计非空值用 COUNT(列)**。

#### 3. 排序分页

```sql
-- 降序排序 + 分页(第 2 页,每页 2 条)
SELECT * FROM student
ORDER BY score DESC
LIMIT 2 OFFSET 2;    -- 或写作 LIMIT 2, 2
```

#### 4. 表连接

```sql
-- INNER JOIN:只保留两边都匹配的行
SELECT s.name, c.name AS class_name
FROM student s
INNER JOIN class c ON s.class_id = c.id;

-- LEFT JOIN:左表全部保留,右表无匹配则补 NULL
SELECT s.name, c.name AS class_name
FROM student s
LEFT JOIN class c ON s.class_id = c.id;

-- RIGHT JOIN:右表全部保留,左表无匹配则补 NULL
SELECT s.name, c.name AS class_name
FROM student s
RIGHT JOIN class c ON s.class_id = c.id;
```

三种连接的结果差异(三班没有学生):

| 数据行 | INNER JOIN | LEFT JOIN | RIGHT JOIN |
|---|---|---|---|
| 一班/二班的学生 | 匹配到班级 | 匹配到班级 | 匹配到班级 |
| 三班(没有学生) | 不出现 | 不出现(左表没有 class_id=3 的行) | 出现,学生为 NULL |

可见:LEFT JOIN 保留左表全部行、RIGHT JOIN 保留右表全部行,INNER JOIN 只保留两边都匹配的行。

#### 5. 集合运算

```sql
-- UNION:合并两查询结果并去重(有去重开销)
SELECT name FROM student WHERE class_id = 1
UNION
SELECT name FROM student WHERE score > 90;

-- UNION ALL:合并不去重,直接拼接(性能更好)
SELECT name FROM student WHERE class_id = 1
UNION ALL
SELECT name FROM student WHERE score > 90;
```

UNION 会做去重(隐式排序或哈希),UNION ALL 直接拼接;数据量大且确知无重复(或允许重复)时,UNION ALL 明显更快。

#### 6. 子查询与 EXISTS

```sql
-- IN:先执行子查询,再与主查询的值比对
SELECT * FROM student WHERE class_id IN (SELECT id FROM class WHERE id > 1);

-- EXISTS:逐行判断子查询是否有结果(相关子查询 correlated subquery)
SELECT * FROM student s
WHERE EXISTS (SELECT 1 FROM class c WHERE c.id = s.class_id AND c.id > 1);
```

**IN vs EXISTS 的语义**:IN 是"值在集合中",EXISTS 是"存在性判断"。性能上经典结论是"小表驱动大表":子查询结果集小且值很少重复时用 IN(或直接 JOIN);子查询结果集大而主表小时用 EXISTS。MySQL 8.0 优化器对两者的改写已经很聪明,不必迷信旧结论,以 EXPLAIN 为准。

#### 7. 条件分支 CASE WHEN

```sql
-- 成绩分档
SELECT name, score,
       CASE
         WHEN score >= 90 THEN '优秀'
         WHEN score >= 80 THEN '良好'
         WHEN score IS NULL THEN '缺考'
         ELSE '及格以下'
       END AS grade
FROM student;
```

#### 8. 窗口函数(MySQL 8.0+)

```sql
-- 每班按分数排名:三种排名方式对比
SELECT name, class_id, score,
       ROW_NUMBER()  OVER (PARTITION BY class_id ORDER BY score DESC) AS rn,
       RANK()        OVER (PARTITION BY class_id ORDER BY score DESC) AS rk,
       DENSE_RANK()  OVER (PARTITION BY class_id ORDER BY score DESC) AS drk
FROM student;

-- 累计分数、上一名/下一名的分数
SELECT name, class_id, score,
       SUM(score) OVER (PARTITION BY class_id ORDER BY score DESC) AS running_total,
       LAG(score)  OVER (PARTITION BY class_id ORDER BY score DESC) AS prev_score,
       LEAD(score) OVER (PARTITION BY class_id ORDER BY score DESC) AS next_score
FROM student;
```

一班按分数降序(92.0 / 92.0 / 88.5 / NULL)三种排名的差异:

| 分数 | ROW_NUMBER | RANK | DENSE_RANK |
|---|---|---|---|
| 92.0 | 1 | 1 | 1 |
| 92.0 | 2 | 1 | 1 |
| 88.5 | 3 | 3 | 2 |
| NULL | 4 | 4 | 3 |

可见:ROW_NUMBER 同分也给不同序号;RANK 同分同排名但**跳号**;DENSE_RANK 同分同排名**不跳号**。窗口函数与 GROUP BY 的最大区别:窗口函数**不折叠行**,每一行都保留并附上聚合结果。

#### 9. 其他：USE / SHOW / DESC / EXPLAIN

```sql
USE mydb;                            -- 切换默认数据库
SHOW DATABASES;                      -- 查看所有库
SHOW TABLES;                         -- 查看当前库所有表
DESC student;                        -- 查看表结构(等价 SHOW COLUMNS FROM student)
EXPLAIN SELECT * FROM student WHERE score > 90;  -- 查看执行计划(进阶)
```

---

### 第四层：深入思考

#### 1. HAVING 与 WHERE 的本质区别

| 维度 | WHERE | HAVING |
|---|---|---|
| 过滤对象 | 行(分组前) | 组(分组后) |
| 是否可用聚合函数 | 不能用 | 能用 |
| 执行时机 | 早,先收窄数据量 | 晚,数据量已定 |
| 性能建议 | 能用 WHERE 过滤的别放 HAVING | 只在过滤组时用 |

#### 2. ON 与 WHERE 在 LEFT JOIN 中的位置差异

- **ON 在连接阶段执行**:决定右表哪些行能匹配上;左表行**无条件保留**,匹配不上就补 NULL
- **WHERE 在连接完成后执行**:对结果集做行过滤;如果对右表列加条件(如 `WHERE c.id > 1`),不满足条件的左表行会被整体剔除,**"左表全部保留"的语义被破坏**,结果等价于 INNER JOIN

```sql
-- 一班、二班的学生都保留
SELECT s.name, c.name FROM student s
LEFT JOIN class c ON s.class_id = c.id;

-- 加 WHERE c.id > 1 后,一班学生也被过滤掉 → 等价 INNER JOIN
SELECT s.name, c.name FROM student s
LEFT JOIN class c ON s.class_id = c.id
WHERE c.id > 1;
```

#### 3. LIMIT 深分页的性能问题与优化

`LIMIT 100000, 10` 会先扫描并**丢弃前 10 万行**,再返回 10 行——offset 越大越慢,线上慢查询的高发场景之一。两种常用优化:

```sql
-- 方案一:延迟关联(delayed join):先查主键,再回表取整行
SELECT s.* FROM student s
INNER JOIN (SELECT id FROM student ORDER BY score DESC LIMIT 100000, 10) t
  ON s.id = t.id
ORDER BY s.score DESC;

-- 方案二:书签分页(keyset pagination):记住上一页最后一条的位置
SELECT * FROM student
WHERE (score, id) < (88.5, 5)     -- 上一页最后一条是 score=88.5, id=5
ORDER BY score DESC, id DESC
LIMIT 10;
```

方案二(也叫游标分页)需要排序列 + 唯一列(id)构成可比较的元组,且依赖索引;适合"只有上一页/下一页"的滚动场景,不适合随机跳页。

#### 4. 面试官可能的追问方向

- **"GROUP BY 和窗口函数的区别?"** → GROUP BY 折叠行(每组一行),窗口函数不折叠行,每一行都保留并附上聚合结果
- **"为什么 LIKE '%张%' 不走索引?"** → 前导模糊无法利用 B+ 树的有序性;左前缀匹配('张%')才能走索引
- **"EXPLAIN 里 type=ref 和 range 的区别?"** → ref 是等值匹配,range 是范围扫描
- **"DISTINCT 和 GROUP BY 的执行区别?"** → 语义不同:前者去重整行,后者分组聚合;实现上都可能用到索引排序

---

## 回答思路

### 答题逻辑框架

面试时建议按以下层次递进回答,总时长控制在 **3-4 分钟**:

```
┌────────────────────────────────────────────┐
│ 第一层(30秒):分类总述                       │
│ "查询关键字按职责分八类:筛选/聚合/排序/    │
│  连接/集合/子查询/分支/窗口函数"            │
├────────────────────────────────────────────┤
│ 第二层(60秒):书写顺序 vs 执行顺序(核心)     │
│ FROM→WHERE→GROUP BY→HAVING→SELECT→ORDER→   │
│ LIMIT,解释为什么 WHERE 不能用聚合函数       │
├────────────────────────────────────────────┤
│ 第三层(60秒):挑 2-3 个高频差异展开          │
│ COUNT 系列 / JOIN 结果集 / UNION /          │
│ IN vs EXISTS / 窗口函数排名                 │
├────────────────────────────────────────────┤
│ 第四层(30秒):优化延伸                       │
│ ON vs WHERE、深分页优化、EXPLAIN            │
└────────────────────────────────────────────┘
```

### 重点得分点(面试官考察意图)

1. **书写顺序 vs 执行顺序**:能一字不差背出两条顺序,并解释"WHERE 在分组前逐行过滤,所以不能用聚合函数"——必考核心

2. **HAVING 与 WHERE 的本质区别**:行级过滤 vs 组级过滤——考察对分组机制的理解

3. **COUNT(\*) / COUNT(1) / COUNT(列) 的区别**:NULL 处理差异——考察细节准确度

4. **LEFT JOIN 中 ON 与 WHERE 的位置差异**:过滤时机与左表保留语义——考察对连接原理的理解

5. **UNION vs UNION ALL**:去重开销——考察性能意识

6. **窗口函数 RANK 家族**:ROW_NUMBER/RANK/DENSE_RANK 的排名差异——考察 8.0 新特性

7. **深分页优化**:延迟关联/书签分页——考察实战优化能力

### 常见误区(扣分点)

| 错误说法 | 正确理解 |
|----------|----------|
| "SQL 按书写顺序执行" | 逻辑执行顺序:FROM→WHERE→GROUP BY→HAVING→SELECT→ORDER BY→LIMIT |
| "WHERE 里能用 SUM/COUNT" | 不能;WHERE 在分组前逐行过滤,聚合函数只能在 HAVING(或 SELECT)使用 |
| "COUNT(*) 比 COUNT(1) 慢" | MySQL 中两者性能几乎一致;COUNT(列) 统计非 NULL 个数,语义不同 |
| "LEFT JOIN 用 WHERE 过滤右表列不影响左表" | 会对左表行整体剔除,破坏保留语义,结果等价 INNER JOIN |
| "UNION 和 UNION ALL 一样" | UNION 去重(有排序/哈希开销),UNION ALL 直接拼接更快 |
| "IN 一定比 EXISTS 慢" | 取决于驱动表大小;MySQL 8.0 优化器常改写两者,以 EXPLAIN 为准 |
| "LIMIT 100000, 10 和 LIMIT 10 一样快" | 深分页要扫描并丢弃前 10 万行,需延迟关联/书签分页优化 |
| "score = NULL 能查到空值" | 必须用 IS NULL;= NULL 永远不成立 |

### 过渡话术建议

- **从分类到执行顺序**:"查询关键字看着多,但核心就一条主线——执行顺序。数据库处理 SQL 是从数据源开始的:先 FROM 确定表,再 WHERE 筛行,GROUP BY 分组,HAVING 筛组,然后 SELECT 投影,ORDER BY 排序,LIMIT 截断..."
- **从顺序到差异**:"正因为 WHERE 在分组之前逐行执行,所以它不能用聚合函数,而 HAVING 在分组之后,能用 SUM/COUNT——这就是两者最本质的区别..."
- **从基础到进阶**:"分页这块,`LIMIT 100000, 10` 这种深分页会先扫描再丢弃 10 万行,线上慢查询常出自这里;优化可以延迟关联先查主键,或者用书签分页记住游标..."
- **收尾过渡**:"如果往深了问,就是窗口函数——8.0 引入后,分组排名这类需求不用再写 @变量 自连接,一条 ROW_NUMBER() OVER(PARTITION BY...) 就解决了。"

### 时间分配建议

- **面试总时长 45 分钟的场景**:此问题回答控制在 3-4 分钟内;执行顺序 1 分钟(核心),分类与示例 1.5 分钟,差异对比 1 分钟,优化延伸 0.5 分钟
- **如果面试官打断**:说完"执行顺序 + WHERE/HAVING 区别"即可停,这是高频核心
- **遇到追问如何应对**:追问窗口函数或深分页细节时,先给结论再给示例;不熟悉的边缘语法(如 ROLLUP)可以明说"不常用,常规场景用 GROUP BY 就足够"

---

> 📋 **分类**: mysql
> 🏷️ **标签**: `sql` `基础`
> 📊 **难度**: easy
> 📅 **归档时间**: 2026-08-10 00:55:23
