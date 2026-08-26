---
id: q0004
question: "resultMap和resultType有什么区别"
category: java
tags: []
difficulty: medium
created: 2026-08-09 03:09:32
source: 用户输入
---

# resultMap和resultType有什么区别


---

## 联想记忆法

### 记忆口诀/联想

**口诀："T 简单，M 复杂；单表 T，多表 M；别名对齐 T 搞定，定制映射找 M"**

或者用 **"Type 直接写类型，Map 慢慢配映射；列名属性能对上，resultType 就够用；对不上、要嵌套，resultMap 来掌控"** 来记忆整个知识体系：

- **T 简单** = resultType：直接写要映射的 Java 类型，MyBatis 自动按列名匹配属性
- **M 复杂** = resultMap：显式定义每一列的映射关系，可处理嵌套对象、多表关联
- **单表 T 多表 M** = 单表查询列名能对齐就用 resultType；多表 join 或列名对不上就用 resultMap
- **别名对齐** = 单表查多表时，用 SQL 别名（AS）把列名对齐到属性名，就能继续用 resultType

### 记忆原理

这个口诀用 **"T vs M" 的字母对比** 作为记忆锚点：**T = Type（类型），M = Map（映射）**。一个字母就能想起本质——Type 是"写个类型完事"，Map 是"慢慢配映射"。再配上"简单/复杂、单表/多表"的场景对应，面试时先说字母对比（一句话），再说场景选择（两句话），最后说底层原理，层次清晰不慌。

### 关联知识

- **与 SQL 别名（AS）关联**：resultType 能处理多表查询的前提就是列名与属性对齐，对齐手段就是 AS 别名——"单表查多表"这个技巧面试官常追问
- **与驼峰映射关联**：`map-underscore-to-camel-case: true` 开启后，`user_name` 列自动映射 `userName` 属性，是 resultType 自动映射的官方补丁
- **与 ORM 框架对比关联**：MyBatis 是半自动 ORM（SQL 自己写、映射半自动），Hibernate 是全自动 ORM——resultType/resultMap 正是"半自动"的体现
- **与 VO/DTO 分层关联**：查询结果映射到 VO（视图对象）而非实体类时，列名经常对不上，resultMap 是常用解法
- **与 MyBatis 查询流程关联**：`select → ResultSet → RowMapper → 对象`，resultType 和 resultMap 控制的是"ResultSet 怎么变成对象"这一步

---

## 深度解答

### 第一层：核心概念

#### 先纠正命名

面试中常把它们口头说成 `ResultType` 和 `ResultMap`，但 MyBatis 配置属性的标准写法是小写开头的 **`resultType`** 和 **`resultMap`**。它们都是查询结果映射配置，并不是两个 Java 类型。

#### 是什么

`resultType` 和 `resultMap` 都是 `<select>` 标签中用于**控制查询结果如何映射为 Java 对象**的属性：

- **resultType**：期望返回的 Java 类型（全限定类名或别名），MyBatis 将结果集的**列名**自动匹配到对象的**属性名**
- **resultMap**：显式定义「数据库列 → Java 属性」的映射关系，支持构造器、嵌套结果、一对多/一对一关联

一句话区别：**resultType 靠"约定"（列名=属性名），resultMap 靠"配置"（显式声明每一列）**。

如果返回的是基本类型、字符串、单个对象或对象列表，通常直接写 `resultType`；如果返回对象的属性和列名无法自然对应，或者需要一对一、一对多嵌套，则使用 `resultMap`。二者在同一个 `<select>` 中二选一，不能同时配置。

#### 解决什么问题

- resultType：简化单表/列名对齐场景的映射，少写配置
- resultMap：解决列名对不上、嵌套对象（多表 join）、特殊类型映射等 resultType 搞不定的场景

#### 注意

两者在同一个 select 中**互斥**，不能同时使用。

---

### 第二层：底层原理

#### resultType 的工作原理（自动映射）

```
ResultSet 行数据
   ↓ 反射 + 列名匹配
setXxx() 自动填充
   ↓
Java 对象
```

1. MyBatis 拿到查询结果后，通过 `ResultSetMetaData` 获取每一列的**列名**
2. 将列名与目标类型的属性做匹配（默认要求**列名 = 属性名**，不区分大小写）
3. 匹配上就调用对应 setter 反射赋值（`column → property`，涉及 `ObjectWrapper.set`）

关键点：**resultType 的底层就是一个自动生成的 ResultMap**（只有一个 `id` 的映射，启用 autoMapping）。

#### 驼峰映射开关

```yaml
mybatis:
  configuration:
    map-underscore-to-camel-case: true   # user_name → userName
```

开启后，自动映射支持**下划线转驼峰**，数据库命名风格（user_name）和 Java 命名风格（userName）不再冲突。这是 resultType 最常用的"补丁"。

#### autoMapping 的三个级别

| 级别 | 行为 |
|---|---|
| NONE | 关闭自动映射，只认显式配置 |
| PARTIAL（默认） | 自动映射除嵌套结果（association/collection）以外的列 |
| FULL | 自动映射所有列，包括嵌套结果 |

#### resultMap 的工作原理（显式映射）

```xml
<resultMap id="orderMap" type="com.example.Order">
    <!-- 主键列，优化性能 -->
    <id property="id" column="order_id"/>
    <!-- 普通列 -->
    <result property="orderNo" column="order_no"/>
    <result property="amount" column="total_amount"/>
    <!-- 一对一：关联 User 对象 -->
    <association property="user" javaType="User">
        <id property="id" column="user_id"/>
        <result property="name" column="user_name"/>
    </association>
    <!-- 一对多：订单下的商品列表 -->
    <collection property="items" ofType="Item">
        <id property="id" column="item_id"/>
        <result property="name" column="item_name"/>
    </collection>
</resultMap>
```

解析过程：

1. MyBatis 启动时解析 `<resultMap>` 为 `ResultMap` 对象（包含一组 `ResultMapping`）
2. 每个 `ResultMapping` 记录 `column → property`、`typeHandler`（类型处理器）、`jdbcType`
3. 查询执行时，根据 ResultMap 逐列设置到对象属性；`association`/`collection` 会创建子映射器递归处理
4. ResultMap 解析结果**被缓存**（`StrictMap`），同一 resultMap 复用，不重复解析

#### 区别的本质

| 维度 | resultType | resultMap |
|---|---|---|
| 映射方式 | 自动映射（列名=属性名） | 显式声明（column→property） |
| 嵌套对象 | ❌ 不支持 | ✅ association（一对一）/ collection（一对多） |
| 列名不一致 | ❌ 需要别名或驼峰开关 | ✅ 直接声明 |
| 构造器/类型处理器 | ❌ | ✅ constructor / typeHandler |
| 配置量 | 少 | 多 |
| 启动开销 | 无 | 有解析与缓存 |

---

### 第三层：实践应用

#### 场景 1：单表查询（resultType）

```java
public interface UserMapper {
    // 列名 id、name、age 与 User 属性一致 → resultType 直接搞定
    @Select("SELECT id, name, age FROM user WHERE id = #{id}")
    User findById(Long id);
}
```

#### 场景 2：单表列名对不上 → 别名对齐（仍是 resultType）

```sql
-- 数据库列 user_name 与属性 userName：开驼峰开关，或 SQL 别名
SELECT user_id AS id, user_name AS name FROM user WHERE id = #{id}
```

#### 场景 3：多表 join → resultMap

```xml
<select id="findOrderWithUser" resultMap="orderMap">
    SELECT o.order_id, o.order_no, o.total_amount,
           u.user_id, u.user_name
    FROM `order` o
    LEFT JOIN user u ON o.user_id = u.user_id
    WHERE o.order_id = #{id}
</select>
```

#### 场景 4：一对多 → collection

```xml
<resultMap id="userMap" type="User">
    <id property="id" column="user_id"/>
    <collection property="orders" ofType="Order">
        <id property="id" column="order_id"/>
        <result property="amount" column="total_amount"/>
    </collection>
</resultMap>
```

#### 最佳实践清单

1. **优先 resultType**：单表、列名对齐、不需要嵌套 → 少写配置
2. **列名对齐三板斧**：SQL 别名 → 驼峰开关 → resultMap（按代价从小到大）
3. **多表嵌套必须 resultMap**：association/collection 是 resultType 给不了的
4. **主键列用 `<id>` 标记**：MyBatis 用它做对象去重与缓存 key
5. **嵌套查询注意 N+1**：collection 的 `select` 属性（嵌套查询）每行执行一次子查询，大数据量改用 join + resultMap 一次查出

---

### 第四层：深入思考

#### 1. resultType 能查多表吗

能，但有前提：**列名必须能对齐到目标类型**。多表查询结果是一个"大宽表"，如果目标对象能容纳所有列（或只取需要的列并做别名），resultType 完全可以用；一旦需要嵌套对象（order.user 是独立的 User），就必须 resultMap。

#### 2. resultMap 的局限与坑

- **启动解析有开销**（虽然后续缓存），大量 resultMap 会拖慢启动
- 列名冲突：多表 join 时两表都有 id 列，必须用别名区分并显式声明，否则映射错乱
- 嵌套集合用错列会**重复渲染**（一对多时每行都 new 集合），要注意结果归并

#### 3. 注解版 resultMap

```java
@Results(id = "userMap", value = {
    @Result(property = "id", column = "user_id"),
    @Result(property = "orders", column = "user_id",
            many = @Many(select = "com.xx.OrderMapper.findByUserId"))
})
```

本质与 XML resultMap 相同，适合简单场景；复杂映射仍推荐 XML（可读性和复用性更好）。

#### 4. 面试官追问方向

- **"resultType 底层是什么？"** → 本质是一个只含 id、开了自动映射的隐式 ResultMap
- **"驼峰开关怎么配置？"** → `map-underscore-to-camel-case: true`
- **"一对一和一对多分别用什么标签？"** → `association`（has one）/ `collection`（has many）
- **"嵌套查询和嵌套结果有什么区别？"** → 嵌套查询 = 多次 SQL（有 N+1 风险）；嵌套结果 = 一次 join 查出再归并
- **"什么情况下必须用 resultMap？"** → 嵌套对象、列名无法对齐、需要 typeHandler 定制转换

---

## 回答思路

### 答题逻辑框架

面试时建议按以下层次递进回答，总时长控制在 **2-3 分钟**：

```
┌─────────────────────────────────────────────────┐
│  第一层（20秒）：一句话对比                       │
│  "resultType 靠列名自动匹配属性,                 │
│   resultMap 显式声明每一列的映射"                │
├─────────────────────────────────────────────────┤
│  第二层（40秒）：场景选择                         │
│  单表列名对齐 → resultType                      │
│  多表/嵌套/列名对不上 → resultMap                │
├─────────────────────────────────────────────────┤
│  第三层（40秒）：关键细节                         │
│  驼峰开关、别名对齐、association/collection      │
├─────────────────────────────────────────────────┤
│  第四层（20秒）：底层一句话                       │
│  "resultType 本质是隐式 ResultMap + 自动映射"    │
└─────────────────────────────────────────────────┘
```

### 重点得分点（面试官考察意图）

1. **一句话本质区别**（核心得分点）：resultType 自动映射 vs resultMap 显式映射——先给结论再展开
2. **场景判断能力**：能说出"列名对齐就能用 resultType，嵌套对象必须 resultMap"——考察实际写 SQL 的经验
3. **驼峰开关**：能说出 `map-underscore-to-camel-case`——考察对 MyBatis 配置的熟悉度
4. **嵌套映射细节**：能说出 association（一对一）/ collection（一对多）的区别——考察进阶使用经验

### 常见误区（扣分点）

| 错误说法 | 正确理解 |
|----------|----------|
| "resultType 只能查单表" | 多表查询只要列名对齐（别名/驼峰）也能用 |
| "resultMap 一定比 resultType 好" | 简单场景 resultType 更简洁，resultMap 有解析成本 |
| "resultType 和 resultMap 可以同时用" | 互斥，同一 select 只能选一个 |
| "驼峰开关解决所有列名问题" | 只解决下划线转驼峰，其他不一致要靠别名或 resultMap |
| "collection 嵌套查询没毛病" | 有 N+1 查询风险，大数据量要权衡 |

### 过渡话术建议

- **从定义到选择**："两者的核心区别是映射方式：一个靠列名约定，一个靠显式配置。那什么时候用哪个呢？我的经验是..."
- **从场景到细节**："多表查询如果要用 resultType，有个技巧是 SQL 别名对齐；不过一旦要嵌套对象，就必须上 resultMap 了..."
- **总结过渡**："总的来说，resultType 是 MyBatis 的默认快车道，resultMap 是复杂映射的定制工具——能用前者就别用后者，需要定制时也别硬撑。"

### 时间分配建议

- **面试总时长 45 分钟的场景**：此问题回答控制在 2-3 分钟内，这是 MyBatis 的入门级问题，重点是"先说清区别、再展示场景经验"
- **如果面试官打断**：说完"自动映射 vs 显式映射 + 场景选择"即可，嵌套映射细节留作追问
- **遇到追问如何应对**：被追问 N+1、嵌套查询等话题，先答原理再给建议（"嵌套查询本质是每行执行一次子查询，数据量大时我会改用 join + 嵌套结果"），展示实战意识

---

> 📋 **分类**: java
> 🏷️ **标签**: 
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-09 03:09:32
