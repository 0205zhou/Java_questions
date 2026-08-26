---
id: q0076
question: "MyBatisPlus的优点"
category: mybatis
tags: ["MyBatis-Plus", "Wrapper", "插件", "CRUD"]
difficulty: medium
created: 2026-08-26 10:47:03
source: 用户输入
---

# MyBatisPlus的优点

## 联想记忆法

### 记忆口诀/联想

**口诀：基于 MyBatis 不替代，CRUD、Wrapper、插件、生成器，少写代码但不丢 SQL 控制力。**

- **基于 MyBatis**：MyBatis-Plus（简称 MP）不是另一个 ORM，而是在 MyBatis 上做增强。
- **CRUD**：`BaseMapper` 提供常见单表增删改查。
- **Wrapper**：条件构造器把查询条件组织成 Java 代码，Lambda 版本还能减少字段名写错。
- **插件**：分页、乐观锁、逻辑删除、自动填充等通用能力可以统一配置。
- **生成器**：根据表结构生成实体、Mapper、Service、XML 等基础代码。

### 记忆原理

可以把 MyBatis 想成“发动机”，MP 是加装在发动机上的“工程工具箱”：发动机仍然负责 SQL 执行和映射，工具箱负责补齐重复的单表代码、条件拼装和常见插件。这样既能获得开发效率，又不会像全自动 ORM 那样完全失去 SQL 控制权。

### 关联知识

- 与 `BaseMapper<T>` 关联：泛型 `T` 表示当前 Mapper 对应的实体类型。
- 与 `IService<T>` 关联：Service 层可以复用批量保存、分页等通用方法。
- 与 MyBatis 动态 SQL 关联：Wrapper 最终仍会生成 SQL 片段，复杂 SQL 仍可回到 XML 或注解。
- 与数据库设计关联：逻辑删除、乐观锁和自动填充都依赖合理的表字段设计。

## 深度解答

### 第一层：核心概念

MyBatis-Plus 是 MyBatis 的增强工具，目标是在不改变 MyBatis 原有使用方式的前提下，减少单表 CRUD 和基础配置的重复代码。它不强制开发者放弃 XML、注解 SQL 或原生 MyBatis 能力；复杂查询仍可以使用 MyBatis 原来的方式。

它的主要优点如下：

1. **通用 CRUD，减少样板代码**：继承 `BaseMapper<User>` 后，就可以直接使用 `selectById`、`selectList`、`insert`、`updateById`、`deleteById` 等方法，不必为每个简单操作重复写 Mapper XML。
2. **条件构造器更方便**：`QueryWrapper`、`UpdateWrapper` 可以按条件组装查询；`LambdaQueryWrapper` 使用方法引用表达字段，避免硬编码字符串字段名。
3. **通用 Service 层**：`IService` 和 `ServiceImpl` 封装了保存、批量保存、更新、删除、分页等常见服务逻辑，适合标准的单表业务。
4. **插件能力完整**：通过 MyBatis-Plus 的拦截器可以接入分页、乐观锁、逻辑删除、非法 SQL 检查等能力，减少项目中的重复实现。
5. **代码生成器提高建模效率**：根据数据库表结构生成实体类、Mapper、Service、Controller 和 XML，可以快速搭建后台管理类项目的基础代码。
6. **对原生 MyBatis 兼容**：MP 底层仍然依托 MyBatis 的 `SqlSession`、Mapper、Executor 和类型处理机制，已有 MyBatis 项目可以渐进式接入。
7. **实体映射约定较完善**：通过 `@TableName`、`@TableId`、`@TableField` 等注解可以处理表名、主键、字段名不一致等问题；配合自动填充可以统一维护创建时间和更新时间。

### 第二层：底层原理

以 `BaseMapper<User>` 为例，泛型实体类型会被 MP 解析为表元数据，包括表名、主键字段、普通字段和字段策略。MP 根据这些元数据构造通用 SQL，并将其注册为 MyBatis 可以执行的映射语句。实际执行时仍由 MyBatis 创建参数映射、获取连接、执行 JDBC、处理结果集。

条件构造器并不是把参数直接拼接成一条不安全的字符串。类似下面的 `eq(User::getStatus, 1)` 会生成条件片段和参数占位关系，值通常仍按 MyBatis 参数绑定规则处理。需要特别注意的是，动态列名、排序字段等结构化内容不能简单地当作普通值绑定，必须使用白名单或固定映射，否则仍可能引入 SQL 注入风险。

分页能力也不是只在内存中截取结果。分页插件会根据数据库类型改写或生成分页 SQL，并执行查询总数和分页数据查询。生产环境要关注 count 查询成本、深分页性能和排序字段索引，不能因为使用了分页插件就忽略 SQL 优化。

### 第三层：实践应用

```java
@Mapper
public interface UserMapper extends BaseMapper<User> {
}

@Service
public class UserService extends ServiceImpl<UserMapper, User> {
    public List<User> findEnabledUsers(String keyword) {
        LambdaQueryWrapper<User> wrapper = Wrappers.lambdaQuery(User.class)
                .eq(User::getEnabled, true)
                .like(keyword != null && !keyword.isBlank(), User::getName, keyword)
                .orderByDesc(User::getCreateTime);
        return list(wrapper);
    }
}
```

工程中通常这样选择：单表标准 CRUD 优先使用 MP；条件组合但仍属于单表查询时使用 Lambda Wrapper；复杂多表关联、报表统计、窗口函数和数据库特有语法使用 XML 或注解 SQL。不要为了“全都用 Wrapper”而把复杂查询写成难读的 Java 链式代码。

### 第四层：深入思考

MP 的核心收益是**开发效率和一致性**，不是保证所有 SQL 都更快。通用方法会隐藏一部分 SQL 细节，批量操作、分页 count、自动填充和逻辑删除也可能带来额外开销。团队还需要统一 Wrapper 使用规范、字段更新策略和分页配置，否则不同开发者可能生成风格不一致的 SQL。

另外，逻辑删除不等于物理删除，唯一索引设计和历史数据清理仍需单独考虑；乐观锁只能降低并发覆盖风险，不能替代事务和业务幂等；代码生成器生成的是起点，不能代替领域建模和 SQL 评审。

## 回答思路

### 答题逻辑框架

1. 先给结论：MP 是基于 MyBatis 的增强，不是替代品。
2. 依次回答四类收益：通用 CRUD、Wrapper、插件、代码生成。
3. 说明底层仍由 MyBatis 执行 SQL，因此可以兼容 XML 和自定义 SQL。
4. 最后补充边界：复杂查询仍写 XML，性能和安全仍需评审。

### 重点得分点

- 能说出 `BaseMapper`、`IService`、`LambdaQueryWrapper`。
- 能说明分页、逻辑删除、乐观锁、自动填充是插件或扩展能力。
- 能说出“减少重复代码，但保留 SQL 控制力”。
- 能指出 Wrapper 不是无条件安全，动态字段和排序要做白名单。

### 常见误区

- 误区 1：MyBatis-Plus 是全自动 ORM。正解：它仍然保留 MyBatis 的 SQL 控制方式。
- 误区 2：使用 MP 就不用写 SQL。正解：复杂查询仍应使用 XML 或注解 SQL。
- 误区 3：分页插件天然解决性能问题。正解：count、深分页和索引仍需优化。
- 误区 4：逻辑删除等于真正删除。正解：数据仍在库中，唯一索引和归档策略要单独设计。

### 面试话术

“MyBatis-Plus 是对 MyBatis 的增强，优点主要是通过 BaseMapper 和 IService 提供通用 CRUD，通过 Wrapper 尤其是 Lambda Wrapper 简化条件构造，再通过插件提供分页、乐观锁、逻辑删除和自动填充等能力，并可用代码生成器减少基础代码。它的优势是提高单表开发效率，但复杂关联和报表查询仍建议使用原生 MyBatis 的 XML 或注解 SQL，同时要关注生成 SQL 的性能和安全。”

### 时间分配建议

结论 20 秒，四项核心能力 60 秒，底层兼容性 30 秒，局限和实践取舍 30 秒，总计约 2 分钟。


---

> 📋 **分类**: mybatis
> 🏷️ **标签**: `MyBatis-Plus` `Wrapper` `插件` `CRUD`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-26 10:47:03
