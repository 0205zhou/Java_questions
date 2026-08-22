---
id: q0075
question: "MyBatis动态SQL？"
category: mybatis
tags: ["MyBatis", "动态SQL", "OGNL", "SQL"]
difficulty: medium
created: 2026-08-22 00:25:00
source: 用户输入
---

# MyBatis动态SQL？

## 联想记忆法

### 记忆口诀/联想

**口诀：if 判空，where 去头，set 去尾，foreach 拼集合。**

- **if 判空**：条件不为空才拼 SQL。
- **where 去头**：自动去掉首个 `AND` / `OR`。
- **set 去尾**：更新语句自动去掉多余逗号。
- **foreach 拼集合**：`IN (...)`、批量插入、批量更新最常用。

### 记忆原理

动态 SQL 其实就是“**按条件拼装最终 SQL**”。  
把几个最常用标签的作用记成“判空、去头、去尾、拼集合”，基本就能覆盖面试里的大部分追问。

### 关联知识

- 会关联到 **OGNL**：`test` 表达式的判断语言。
- 会关联到 **${} / #{}**：动态 SQL 里仍要注意参数安全。
- 会关联到 **<sql>/<include>**：抽公共片段减少重复。
- 会关联到 **批量操作**：`foreach` 很常见。

## 深度解答

### 1. 核心概念：动态 SQL 就是按条件生成不同 SQL

MyBatis 动态 SQL 指的是根据入参是否为空、值是多少、集合多大，动态拼接最终 SQL 的能力。  
它解决的是静态 SQL 写死后，条件太多、分支太多、重复太多的问题。

比如同一个查询：

- 传了名字就按名字过滤
- 传了状态就按状态过滤
- 传了日期范围就加时间条件

如果不用动态 SQL，就得写很多重复方法；用了动态 SQL，就可以在一个 XML 里完成。

### 2. 底层原理：MyBatis 怎么判断和拼接

MyBatis 的动态 SQL 主要靠 XML 标签和 OGNL 表达式。  
解析时先判断条件，再生成最终 SQL，最后还是走预编译和参数绑定。

常见标签有：

- `<if>`：条件判断
- `<where>`：自动处理 `WHERE` 和前导 `AND`
- `<trim>`：自定义前后缀处理
- `<set>`：更新时自动处理逗号
- `<choose>/<when>/<otherwise>`：分支选择
- `<foreach>`：遍历集合
- `<sql>/<include>`：抽取公共片段

### 3. 实践应用：典型示例

#### 查询场景

```xml
<select id="queryUser" resultType="User">
  select id, name, status
  from user
  <where>
    <if test="name != null and name != ''">
      and name = #{name}
    </if>
    <if test="status != null">
      and status = #{status}
    </if>
  </where>
</select>
```

#### 更新场景

```xml
<update id="updateUser">
  update user
  <set>
    <if test="name != null">name = #{name},</if>
    <if test="status != null">status = #{status},</if>
  </set>
  where id = #{id}
</update>
```

#### 集合场景

```xml
<select id="queryByIds" resultType="User">
  select * from user
  where id in
  <foreach collection="ids" item="id" open="(" close=")" separator=",">
    #{id}
  </foreach>
</select>
```

### 4. 深入思考：为什么动态 SQL 很实用

动态 SQL 的价值不只是“少写 if”，而是：

- 减少重复 Mapper 方法
- 让 SQL 逻辑集中维护
- 复杂查询更容易按条件扩展

但它也有局限：

- 嵌套过多会变得难读
- 条件太复杂时，XML 可维护性下降
- 过度动态化会让 SQL 不够清晰

所以复杂到一定程度时，也可以考虑 `@SelectProvider`、SQL 构造器，甚至下沉到专门的查询对象里。

## 回答思路

### 答题逻辑框架

1. 先定义：根据参数动态拼 SQL。
2. 再说原理：XML 标签 + OGNL。
3. 然后举三个核心标签：`if`、`where/set`、`foreach`。
4. 最后说优缺点和适用场景。

### 重点得分点

- 能说出 `<if>`、`<where>`、`<set>`、`<foreach>`。
- 能说明 `where` 会自动去掉多余 `AND`。
- 能举出批量 `IN` 查询示例。
- 能讲清它解决重复 SQL 的问题。

### 常见误区

- 误区 1：动态 SQL 就是字符串拼接。  
  正解：它是框架级条件拼装，仍可配合 `#{}` 参数绑定。

- 误区 2：动态 SQL 越多越好。  
  正解：太复杂会难维护。

- 误区 3：`<where>` 只是普通标签。  
  正解：它会自动处理前导 `AND/OR`。

### 面试话术

“MyBatis 动态 SQL 是通过 `<if>`、`<where>`、`<set>`、`<foreach>` 等标签，结合 OGNL 表达式，按参数动态生成最终 SQL。它能减少重复代码，适合条件查询、批量操作和动态更新，但条件太复杂时可读性会下降，所以要控制复杂度。”

---

> 📋 **分类**: mybatis
> 🏷️ **标签**: `MyBatis` `动态SQL` `OGNL` `SQL`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-22 00:25:00
