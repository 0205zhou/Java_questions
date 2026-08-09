---
id: q0017
question: "MySQL都有哪些种类的函数?"
category: mysql
tags: ["函数"]
difficulty: easy
created: 2026-08-10 01:03:49
source: 用户输入
---

# MySQL都有哪些种类的函数?


---

## 联想记忆法

### 记忆口诀/联想

**口诀:"字数日,流聚 J,密系转,记心间"**

- **字数日** = 字符串函数、数值函数、日期时间函数 —— 三大"纯数据处理"类
- **流聚 J** = 流程控制函数、聚合函数(aggregate function)、JSON 函数 —— 三大"逻辑与结构化"类
- **密系转** = 加密与哈希函数、系统信息函数、类型转换函数 —— 三大"安全与元数据"类
- **记心间** = 九类函数全部记住,答题时先抛分类再逐个展开

扩展成一句完整口诀:**"字符数值日期,流程聚合 JSON,加密系统转换,九类函数记全"** —— 每一句对应三类,四句把官方功能分类一网打尽。

### 记忆原理

这个口诀采用**"三字诀"的节奏**,三字一组、四组收尾,和四字诀一样靠"组块化(chunking)"降低记忆负担:九类函数压缩成九个字,面试时先说"九类分别是:字符串、数值、日期、流程、聚合、JSON、加密、系统、转换",再问一句"最后一类是什么?类型转换",分类框架就完整了。每个三字组内部按"常用度递减"排列(字符串、数值、日期是最常用的,加密、系统、转换相对冷门),顺着热度自然带出,不会卡壳。

### 关联知识

- **与索引失效关联**:函数包裹列(如 `WHERE DATE(create_time) = ...`)导致索引失效,是函数题最经典的追问方向,答案要准备好"函数→索引→改写范围查询→8.0 函数索引"这条链
- **与 GROUP BY / 聚合关联**:聚合函数必须与 GROUP BY 搭配才有意义,过滤聚合结果要用 HAVING 而不是 WHERE,涉及 SQL 执行顺序
- **与 JSON 字段关联**:MySQL 5.7 引入 JSON 类型,8.0 完善 JSON 函数,JSON 字段能否走索引(可以,但只能对生成列建索引)是进阶考点
- **与类型转换关联**:字符串与数字比较时的隐式转换(implicit conversion)会导致索引失效,`CAST` / `CONVERT` 显式转换是兜底手段
- **与 SQL 执行顺序关联**:WHERE → GROUP BY → HAVING → SELECT → ORDER BY,决定了"WHERE 不能用 SELECT 别名、聚合函数不能进 WHERE"等规则,函数题常与执行顺序题捆绑考

---

## 深度解答

### 第一层：核心概念

#### 什么是 MySQL 函数

MySQL 内置函数(Built-in Function)是一组预定义的、接收输入参数并返回计算结果的处理单元,可以直接嵌入 SQL 语句中,替代在业务代码里手写逻辑。按官方文档的功能分类,共九大类:

| 分类 | 代表函数 | 典型用途 |
|---|---|---|
| 字符串函数 | CONCAT、SUBSTRING、LENGTH、CHAR_LENGTH、REPLACE、TRIM、LOWER、UPPER、LEFT、RIGHT、LPAD、RPAD、LOCATE、INSTR | 拼接、截取、替换、大小写转换、填充、定位 |
| 数值函数 | ABS、ROUND、CEIL、FLOOR、MOD、POW、SQRT、RAND、TRUNCATE | 取整、四舍五入、取余、随机数、截断 |
| 日期时间函数 | NOW、SYSDATE、CURDATE、CURTIME、DATE_FORMAT、DATEDIFF、TIMESTAMPDIFF、DATE_ADD、DATE_SUB、EXTRACT、UNIX_TIMESTAMP、FROM_UNIXTIME | 取当前时间、格式化、日期运算 |
| 流程控制函数 | IF、IFNULL、NULLIF、CASE WHEN | 条件分支、空值兜底,实现"SQL 里的 if-else" |
| 聚合函数 | COUNT、SUM、AVG、MAX、MIN、GROUP_CONCAT | 对一组行做统计汇总,常与 GROUP BY 连用 |
| JSON 函数 | JSON_EXTRACT、JSON_KEYS、JSON_CONTAINS、JSON_ARRAY、JSON_OBJECT | 存取、查询、构造 JSON 数据(MySQL 5.7+) |
| 加密与哈希函数 | MD5、SHA1、SHA2、AES_ENCRYPT、AES_DECRYPT | 数据加密、完整性校验 |
| 系统信息函数 | VERSION、DATABASE、USER、CURRENT_USER、CONNECTION_ID | 获取服务器、会话、连接信息 |
| 类型转换函数 | CAST、CONVERT | 显式类型转换 |

这套分类体系的关键在于:函数是**纯计算逻辑**,不改变表结构和数据本身(INSERT/UPDATE 场景除外),理解分类只是起点,面试真正的分水岭是"各类函数的机制差异"和"函数对查询性能的影响"。

---

### 第二层：底层原理

#### 为什么区分 LENGTH 与 CHAR_LENGTH

两者都计算字符串长度,但**单位不同**:`LENGTH` 返回字节数(byte),`CHAR_LENGTH` 返回字符数(character)。在 utf8mb4 字符集下,一个汉字占 3 字节,一个 emoji 占 4 字节:

```sql
SELECT LENGTH('哈'), CHAR_LENGTH('哈');          -- 3, 1
SELECT LENGTH('hello'), CHAR_LENGTH('hello');    -- 5, 5
```

纯 ASCII 场景两者无差异,一旦混入中文差异立刻显现。统计"用户昵称最多几个字"必须用 `CHAR_LENGTH`,用 `LENGTH` 会得到字节数导致误判——这是最常考的易错点。

#### 为什么 NOW() 和 SYSDATE() 不同

两者都返回当前日期时间,但取值时刻不同:

```sql
SELECT NOW(), SYSDATE(), SLEEP(2), NOW(), SYSDATE();
-- NOW() 两次相同:语句开始时刻;SYSDATE() 两次不同:各自执行时刻
```

- `NOW()` 在**语句开始**时取一次值,整条语句内保持不变
- `SYSDATE()` 在**函数执行**时才取当前时刻,同一条语句内多次调用可能不同

`NOW()` 的安全性在于:基于语句的复制(binlog)和主从同步中,从库重放同一语句时 NOW() 仍取语句开始时刻,主从结果一致;SYSDATE() 是执行时刻,重放时可能偏差,导致主从不一致。所以业务上优先用 NOW()。

#### 流程控制函数的差异

`IF(expr, v1, v2)` 是三目运算符的 SQL 版:expr 为真返回 v1,否则 v2。而**空值处理**有三个易混淆的函数:

| 函数 | 参数个数 | 行为 |
|---|---|---|
| IFNULL(v1, v2) | 2 | v1 为 NULL 返回 v2,否则返回 v1 |
| COALESCE(v1, v2, ...) | N | 从左到右返回**第一个非 NULL** 值,全 NULL 则返回 NULL |
| NULLIF(a, b) | 2 | a 等于 b 返回 NULL,否则返回 a |

`COALESCE` 是 SQL 标准语法,支持任意多个参数,是 `IFNULL` 的超集;`NULLIF` 常用于防除零(如 `COUNT / NULLIF(SUM(x), 0)`)。CASE WHEN 是最灵活的流程控制,有**简单 CASE** 和**搜索 CASE** 两种写法:

```sql
-- 简单 CASE:等值匹配
SELECT CASE status WHEN 1 THEN '正常' WHEN 2 THEN '禁用' ELSE '未知' END
FROM user;

-- 搜索 CASE:任意条件
SELECT CASE WHEN score >= 90 THEN '优秀'
            WHEN score >= 60 THEN '及格'
            ELSE '不及格' END AS level
FROM exam;
```

#### 聚合函数与 GROUP BY 的关系

聚合函数把"多行压成一行",失去分组就没有意义:没有 GROUP BY 时,整张表被视为一个组。过滤分组结果必须用 HAVING(WHERE 在分组前执行,聚合结果尚不存在),这就是 SQL 执行顺序 FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY 的直接推论。COUNT 家族细节:COUNT(*) 统计所有行;COUNT(1) 与 COUNT(*) 等价(括号内只要非 NULL 即计数,常量 1 恒非 NULL);COUNT(列) 跳过该列为 NULL 的行——三者的差异在"列可空"时体现,结论与"MySQL 常用查询关键字"一题中 COUNT 的表述一致。

#### 类型转换:隐式与显式

MySQL 在做不同类型比较时会发生**隐式转换**:字符串与数字比较,字符串会先转成数字,如 `WHERE phone = 123456` 会把 phone 列(字符串)隐式转数字,导致该列无法走索引。显式转换用两个函数:

```sql
SELECT CAST('123' AS SIGNED);          -- 标准 SQL 语法:CAST(expr AS type)
SELECT CONVERT('123', SIGNED);         -- MySQL 语法:CONVERT(expr, type)
```

两者功能等价,差别在写法:CAST 是 SQL 标准、参数顺序为 `expr AS type`;CONVERT 是 MySQL 特有、参数顺序为 `expr, type`,且 CONVERT 还支持字符集转换 `CONVERT(expr USING utf8mb4)`。

#### 加密函数的安全边界

MD5 / SHA1 / SHA2 是**单向哈希**(one-way hash),不可逆,用于完整性校验和指纹;AES_ENCRYPT / AES_DECRYPT 是**可逆加密**(对称加密,需同一把 key):

```sql
SELECT MD5('abc'), SHA2('abc', 256);    -- 固定长度十六进制串
SELECT AES_ENCRYPT('secret', 'key'), AES_DECRYPT(AES_ENCRYPT('secret', 'key'), 'key');
```

关键安全观念:**用户密码绝不能存可逆加密结果**。MD5/SHA1 已证实可被彩虹表(rainbow table)和字典攻击破解,即便加盐(salt)也建议用专门的密码哈希算法(bcrypt、scrypt、Argon2,它们自带盐且计算代价高,天然抵抗暴力破解);AES 可逆意味着数据库泄露时加密 key 若同库泄露,密文等于明文。

#### JSON 函数的机制

MySQL 5.7 引入 JSON 类型(校验合法性、内部存储优化),8.0 完善函数支持。查询 JSON 字段用 `JSON_EXTRACT`,其 `->` 与 `->>` 是简写:`->` 返回带引号的 JSON 值,`->>` 返回纯文本(去引号):

```sql
SELECT doc->'$.name' AS name_json, doc->>'$.name' AS name_text,
       JSON_KEYS(doc) AS keys_list,
       JSON_CONTAINS(doc->'$.tags', '"急"') AS has_tag
FROM article
WHERE doc->>'$.author' = '张三';
```

`->>` 等价于 `JSON_UNQUOTE(JSON_EXTRACT(...))`,日常取字段值优先用 `->>`。

---

### 第三层：实践应用

#### 综合实战:一个用户报表查询

把日期格式化、CASE 状态转换、GROUP_CONCAT 行转列、范围条件组合起来:

```sql
SELECT
    DATE_FORMAT(create_time, '%Y-%m-%d') AS 注册日期,
    CASE WHEN status = 1 THEN '正常' WHEN status = 2 THEN '禁用' ELSE '未知' END AS 状态,
    GROUP_CONCAT(DISTINCT tag ORDER BY tag SEPARATOR '、') AS 标签,
    COUNT(*) AS 人数
FROM user
WHERE create_time >= '2026-01-01' AND create_time < '2026-08-10'
GROUP BY DATE_FORMAT(create_time, '%Y-%m-%d'), status
HAVING COUNT(*) >= 3
ORDER BY 注册日期 DESC;
```

要点:WHERE 用**范围条件**而不是 `DATE(create_time) = '2026-08-10'`(见第四层);GROUP_CONCAT 默认上限是 `group_concat_max_len`(默认 1024 字节),标签多时会被静默截断,需 `SET SESSION group_concat_max_len = 65535`;GROUP BY 的字段必须是 SELECT 中非聚合列。

#### 常见函数速查示例

```sql
-- 字符串:拼接与截取
SELECT CONCAT('a', '-', 'b'), SUBSTRING('hello world', 1, 5), REPLACE('a-b-c', '-', '/'),
       LPAD('7', 4, '0'), LOCATE('o', 'hello');     -- a-b / hello / a/b/c / 0007 / 5

-- 数值:取整与随机
SELECT ABS(-5), ROUND(3.14159, 2), CEIL(3.1), FLOOR(3.9), MOD(10, 3),
       TRUNCATE(3.14159, 2), RAND(42);              -- 5 / 3.14 / 4 / 3 / 1 / 3.14 / 固定序列

-- 日期:格式化与运算
SELECT DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s'),
       DATEDIFF('2026-08-10', '2026-01-01'),        -- 相差天数
       TIMESTAMPDIFF(MONTH, '2026-01-01', NOW()),   -- 单位:YEAR/MONTH/DAY/HOUR...
       DATE_ADD('2026-08-10', INTERVAL 1 DAY),
       EXTRACT(YEAR FROM NOW()),
       FROM_UNIXTIME(UNIX_TIMESTAMP('2026-08-10 12:00:00'));

-- 流程与空值
SELECT IF(age >= 18, '成年', '未成年'),
       COALESCE(NULL, NULL, 'first'),
       IFNULL(NULL, '兜底');
```

#### WHERE / ORDER BY 中使用函数的注意事项

- **WHERE 中函数包裹列 → 索引失效**(详见第四层),这是使用函数的第一铁律
- **ORDER BY 函数运算**无法利用索引排序,需 filesort;数据量大时考虑把计算结果落为冗余列或函数索引
- **WHERE 中不能使用 SELECT 别名**(SELECT 在 WHERE 之后执行),ORDER BY 可以用别名
- 聚合函数不能出现在 WHERE 中,只能用 HAVING

---

### 第四层：深入思考

#### 1. 函数包裹列为何导致索引失效(最经典追问)

索引(B+ 树)按列**原始值**排序,`WHERE DATE(create_time) = '2026-08-10'` 对索引键做了函数变换,MySQL 无法在树中直接定位变换后的值,只能全表扫描并对每行计算函数——除非函数索引:

```sql
-- 不走索引:对列做函数运算,索引键被"污染"
SELECT * FROM user WHERE DATE(create_time) = '2026-08-10';

-- 走索引:改写为范围查询,优化器可用 create_time 索引
SELECT * FROM user
WHERE create_time >= '2026-08-10 00:00:00' AND create_time < '2026-08-11 00:00:00';

-- MySQL 8.0 函数索引兜底:直接对表达式建索引
ALTER TABLE user ADD INDEX idx_date((DATE(create_time)));
```

回答这条追问的完整链路:函数包裹列 → 索引失效 → 改写为范围查询(最优解)→ 确需函数则用 8.0 函数索引(expression index)→ 隐式转换同理(数字与字符串比较)。

#### 2. SQL 函数 vs 业务层计算,算在哪一层

| 方案 | 优点 | 缺点 |
|---|---|---|
| SQL 函数计算 | 逻辑靠近数据、减少传输量、一次 SQL 完成 | 难测试、难复用、函数写复杂后不可读、可能阻断索引 |
| 业务层计算 | 可单元测试、可复用、可加日志和兜底 | 要多查数据、传输放大、N+1 风险 |

原则:能用 SQL 做聚合(数据量大时必须在 SQL 层,业务层算不了),能用 WHERE 过滤就别 SELECT 出来再算;可读性复杂或需要复用的逻辑放业务层。

#### 3. 易混淆点对比表

| 对比组 | 区别要点 |
|---|---|
| LENGTH vs CHAR_LENGTH | 字节数 vs 字符数,utf8mb4 下中文为 3 字节 |
| NOW vs SYSDATE | 语句开始时刻 vs 执行时刻;前者利于主从复制一致 |
| COUNT(*) vs COUNT(1) vs COUNT(列) | 前两者等价(非 NULL 计数);COUNT(列) 跳过 NULL,有索引覆盖时 COUNT(列) 可能更快 |
| IFNULL vs COALESCE vs NULLIF | 2 参数;N 参数取第一个非 NULL;a==b 返回 NULL |
| CAST vs CONVERT | 写法不同;CONVERT 额外支持字符集转换 |
| ROUND vs TRUNCATE | 四舍五入 vs 直接截断;ROUND 有浮点精度问题 |
| JSON_EXTRACT -> vs ->> | 带引号 JSON 值 vs 去引号纯文本 |

#### 4. 面试官可能的追问方向

- **"隐式转换为什么会让索引失效?"** → 对列做类型转换等价于函数包裹列,索引键被变换,无法二分定位
- **"函数索引和普通索引有区别吗?"** → 8.0 对表达式建索引,优化器识别到相同表达式时可用,需注意表达式必须完全一致
- **"GROUP_CONCAT 拼接超长会怎样?"** → 被 `group_concat_max_len`(默认 1024)静默截断,线上要主动调大
- **"字符串列和数字比较会发生什么?"** → 字符串列隐式转数字,索引失效;建议参数侧显式转换或加引号
- **"为什么密码不用 MD5 存?"** → 无盐 MD5 可查彩虹表;应使用 bcrypt 等自带盐的慢哈希

---

## 回答思路

### 答题逻辑框架

面试时建议按以下层次递进回答,总时长控制在 **3-4 分钟**:

```
┌──────────────────────────────────────────────────┐
│  第一层（20秒）：总览分类                         │
│  "九类:字符串、数值、日期、流程、聚合、           │
│   JSON、加密、系统、类型转换"                     │
├──────────────────────────────────────────────────┤
│  第二层（60秒）：挑核心类展开                     │
│  字符串:LENGTH vs CHAR_LENGTH                     │
│  日期:NOW vs SYSDATE;流程:IFNULL/COALESCE/NULLIF │
├──────────────────────────────────────────────────┤
│  第三层（60秒）：实战示例                         │
│  日期格式化+CASE+GROUP_CONCAT 综合查询            │
├──────────────────────────────────────────────────┤
│  第四层（30秒）：性能与边界                       │
│  函数包裹列 → 索引失效 → 范围改写/函数索引        │
└──────────────────────────────────────────────────┘
```

### 重点得分点(面试官考察意图)

1. **分类框架完整**:能一口气说出九大类并各举代表函数——证明知识成体系而非零散记忆

2. **易混点辨析**:主动讲出 LENGTH vs CHAR_LENGTH(字节 vs 字符)、NOW vs SYSDATE(语句时刻 vs 执行时刻)、IFNULL/COALESCE/NULLIF 差异——这些是"背过文档"和"真懂"的分水岭

3. **索引失效闭环**:能讲全"函数包裹列 → 索引失效 → 范围查询改写 → 8.0 函数索引"整条链路——考察性能意识

4. **安全观念**:说出"密码不要用可逆加密/MD5 存,用加盐慢哈希"——考察工程安全素养

5. **执行顺序意识**:能解释"聚合函数为什么只能出现在 HAVING"——考察对 SQL 执行顺序的理解

### 常见误区(扣分点)

| 错误说法 | 正确理解 |
|----------|----------|
| "LENGTH 和 CHAR_LENGTH 一样,都是长度" | LENGTH 是字节数,CHAR_LENGTH 是字符数,utf8mb4 下中文差 3 倍 |
| "NOW() 和 SYSDATE() 完全等价" | NOW() 取语句开始时刻,SYSDATE() 取执行时刻,影响主从复制一致性 |
| "MD5 加密密码没问题" | MD5 是单向哈希且可被彩虹表破解,密码应存加盐慢哈希(bcrypt 等) |
| "COUNT(*) 比 COUNT(1) 慢" | 两者等价;COUNT(列) 才因跳过 NULL 而有语义差异 |
| "WHERE 里可以用 SELECT 的别名" | 执行顺序 WHERE 先于 SELECT,别名不可用,ORDER BY 才可用 |
| "IFNULL 和 COALESCE 完全一样" | IFNULL 只收 2 参数,COALESCE 收 N 个返回第一个非 NULL |

### 过渡话术建议

- **从总览到细节**:"MySQL 的函数按官方文档分九大类,字符串、数值、日期、流程、聚合、JSON、加密、系统信息、类型转换。面试最常考的是前三类和流程控制,我先说最经典的几个辨析..."
- **从原理到实践**:"像 LENGTH 和 CHAR_LENGTH 看起来一样,实际上一个按字节一个按字符,utf8mb4 下中文差异很大,所以做昵称长度校验必须用 CHAR_LENGTH。类似的,我们项目里写报表查询时..."
- **从用法到性能**:"函数本身不难,难点在性能——一旦在 WHERE 里对列做函数运算,比如 DATE(create_time) = '2026-08-10',索引就失效了,标准做法是改写为 create_time >= '2026-08-10 00:00:00' AND create_time < '2026-08-11 00:00:00' 的范围查询..."
- **总结过渡**:"总的来说,函数是 SQL 的'工具箱',分类是骨架,易混点是考点,而'函数会不会让索引失效'是决定回答质量的分水岭。"

### 时间分配建议

- **面试总时长 45 分钟的场景**:此问题回答控制在 3-4 分钟内,分类总览 20 秒 + 核心辨析 60 秒 + 实战 60 秒 + 索引失效 30 秒,余量留给追问
- **如果面试官打断**:说完分类框架 + 索引失效闭环即可停,这是核心中的核心;加密安全观念是加分项
- **遇到追问如何应对**:不确定细节(如 GROUP_CONCAT 默认值精确数值)可以说"默认 1024 字节,生产环境我们会调大到 65535,具体数值可以再确认"——承认边界但不丢失核心点

---

> 📋 **分类**: mysql
> 🏷️ **标签**: `函数`
> 📊 **难度**: easy
> 📅 **归档时间**: 2026-08-10 01:03:49
