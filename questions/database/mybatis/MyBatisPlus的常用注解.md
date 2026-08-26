---
id: q0077
question: "MyBatisPlus的常用注解"
category: mybatis
tags: ["实体映射", "MyBatis-Plus", "注解"]
difficulty: medium
created: 2026-08-26 10:48:51
source: 用户输入
---

# MyBatisPlus的常用注解

## 联想记忆法

### 记忆口诀/联想

**口诀：表名 `TableName`，主键 `TableId`，字段 `TableField`；逻辑删、乐观锁、自动填充，分别看 `TableLogic`、`Version`、`FieldFill`。**

可以按“**表、键、列、行为**”四层记：

- **表**：`@TableName` 解决实体类和表名的对应关系。
- **键**：`@TableId` 解决主键字段和主键生成策略。
- **列**：`@TableField` 解决字段名、是否参与 SQL、更新策略和填充策略。
- **行为**：`@TableLogic`、`@Version`、`@EnumValue` 等改变字段在 CRUD 中的处理方式。

### 记忆原理

MP 注解本质上是在补充数据库元数据。实体类只写 Java 属性时，框架需要知道“它对应哪张表、哪个字段是主键、哪些字段要忽略、更新时是否允许为空”。因此注解不是装饰，而是参与 SQL 生成和结果映射的配置。

### 关联知识

- 与 `BaseMapper<T>` 关联：Mapper 泛型实体最终会读取这些注解。
- 与自动填充处理器关联：`@TableField(fill = ...)` 只声明时机，真正赋值还需要 `MetaObjectHandler`。
- 与插件关联：`@Version` 需要乐观锁插件，`@TableLogic` 需要逻辑删除配置。
- 与 Spring 关联：`@Mapper`、`@MapperScan` 负责 Mapper 注册，不属于 MyBatis-Plus 的实体映射注解。

## 深度解答

### 第一层：核心概念

MyBatis-Plus 常用注解可以分为以下几组。

#### 1. 表级注解：`@TableName`

```java
@TableName(value = "sys_user", autoResultMap = true)
public class User {
}
```

`value` 指定数据库表名。当实体类名和表名遵循默认规则时可以省略；如果实体类是 `User`，表名是 `sys_user`，就应该显式配置。`autoResultMap = true` 常用于需要自定义类型处理器、JSON 字段或枚举映射的场景，让 MP 为结果映射生成更完整的 ResultMap。

#### 2. 主键注解：`@TableId`

```java
@TableId(value = "user_id", type = IdType.ASSIGN_ID)
private Long id;
```

`value` 指定数据库主键列名；`type` 指定主键生成策略。常见策略包括：

| 策略 | 含义 |
|---|---|
| `AUTO` | 使用数据库自增主键 |
| `NONE` | 不指定策略，使用默认行为 |
| `INPUT` | 由业务代码或调用方手动传入 |
| `ASSIGN_ID` | MP 分配 ID，常用于雪花算法生成的 `Long` 或字符串 |
| `ASSIGN_UUID` | MP 分配 UUID，常用于字符串主键 |

具体策略必须与数据库字段类型和项目 ID 方案一致，不能只看注解名称。

#### 3. 字段注解：`@TableField`

```java
@TableField(value = "user_name", condition = SqlCondition.LIKE)
private String name;

@TableField(select = false)
private String password;

@TableField(exist = false)
private String departmentName;
```

常用属性包括：

- `value`：指定列名，例如 `user_name`。
- `exist`：是否为数据库真实字段。`false` 表示只用于业务展示，不参与默认 SQL。
- `select`：是否默认查询该字段，敏感字段可设置为 `false`，需要时再显式查询。
- `insertStrategy`、`updateStrategy`、`whereStrategy`：控制字段值为空时是否参与新增、更新和条件 SQL。
- `fill`：指定新增或更新时的自动填充时机。
- `typeHandler`：指定字段的类型处理器，例如 JSON 与 Java 对象之间的转换。
- `jdbcType`：指定 JDBC 类型，通常只在类型推断不足时使用。

#### 4. 逻辑删除：`@TableLogic`

```java
@TableLogic(value = "0", delval = "1")
private Integer deleted;
```

使用逻辑删除时，删除操作通常会被改写成更新删除标记，普通查询会自动追加未删除条件。它适合需要保留历史记录的场景，但并不等于数据真正消失，唯一索引、恢复和历史数据清理仍需单独设计。

#### 5. 乐观锁：`@Version`

```java
@Version
private Integer version;
```

更新时会把旧版本作为条件，并在成功更新后递增版本号，避免两个事务互相覆盖。该注解通常需要配合 `OptimisticLockerInnerInterceptor` 使用；它解决的是更新冲突检测，不是所有并发问题的完整方案。

#### 6. 自动填充：`@TableField(fill = ...)`

```java
@TableField(fill = FieldFill.INSERT)
private LocalDateTime createTime;

@TableField(fill = FieldFill.INSERT_UPDATE)
private LocalDateTime updateTime;
```

注解只说明填充时机，实际值由实现 `MetaObjectHandler` 的处理器写入：

```java
@Component
public class AuditMetaObjectHandler implements MetaObjectHandler {
    @Override
    public void insertFill(MetaObject metaObject) {
        strictInsertFill(metaObject, "createTime", LocalDateTime.class, LocalDateTime.now());
    }

    @Override
    public void updateFill(MetaObject metaObject) {
        strictUpdateFill(metaObject, "updateTime", LocalDateTime.class, LocalDateTime.now());
    }
}
```

#### 7. 枚举与其他常见注解

`@EnumValue` 标记枚举中真正持久化的字段；`@IEnum` 可以通过实现接口声明枚举值。`@OrderBy` 可以声明默认排序字段，但复杂排序仍建议在查询中显式写出。`@KeySequence` 适用于需要数据库序列生成主键的场景，常见于 Oracle 等数据库。

### 第二层：底层原理

项目启动或 Mapper 初始化时，MP 会解析实体类的注解并建立 `TableInfo`、字段元数据和主键信息。通用 CRUD 方法据此选择表名、列名、主键策略和字段策略；逻辑删除、乐观锁等拦截器再在 SQL 执行前后补充相应条件或处理参数。

因此注解之间存在配套关系：`@TableField(fill = ...)` 没有 `MetaObjectHandler` 就不会自动产生时间；`@Version` 没有乐观锁拦截器就不会自动完成版本条件；`@TableLogic` 的值配置错误会导致查询或删除结果异常。排查问题时不能只检查实体注解，还要检查全局配置和插件注册。

### 第三层：实践应用

```java
@Data
@TableName("order_info")
public class Order {
    @TableId(type = IdType.ASSIGN_ID)
    private Long id;

    @TableField("order_no")
    private String orderNo;

    @TableLogic
    private Integer deleted;

    @Version
    private Integer version;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createTime;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updateTime;

    @TableField(exist = false)
    private String userName;
}
```

实际项目建议把基础审计字段抽到父类，再用 `@TableField` 统一填充；敏感字段不要仅依赖 `select = false` 做安全控制，接口返回层仍应使用 DTO 脱敏；字段策略要和“空值是否表示清空”这一业务语义保持一致。

### 第四层：深入思考

注解越多并不代表设计越好。`@TableField(exist = false)` 适合少量派生字段，但复杂查询结果不应该强行塞进实体类；可以使用 VO 和 `resultMap`。逻辑删除会影响唯一索引和数据体积，乐观锁失败后要定义重试或提示策略，自动填充也要考虑批量导入、补数据和手工 SQL 是否绕过实体生命周期。

## 回答思路

### 答题逻辑框架

1. 先按表、主键、字段、行为四类归纳。
2. 重点讲 `@TableName`、`@TableId`、`@TableField`。
3. 再补 `@TableLogic`、`@Version`、`FieldFill` 三个高频能力。
4. 最后强调配套插件和 `MetaObjectHandler`，并区分 `@Mapper`。

### 重点得分点

- 能说明 `@TableField(exist = false)`、`select = false` 的区别。
- 能指出 `@TableField(fill = ...)` 需要自动填充处理器。
- 能说明 `@Version` 和 `@TableLogic` 需要对应的拦截器或配置。
- 能区分实体映射注解与 Mapper 扫描注解。

### 常见误区

- 误区 1：`@TableLogic` 会物理删除数据。正解：它通常改为更新删除标记。
- 误区 2：加了 `@Version` 就自动有乐观锁。正解：还需要注册乐观锁拦截器。
- 误区 3：`select = false` 等于安全隔离。正解：它只是默认查询策略，接口仍需脱敏。
- 误区 4：自动填充只加注解即可。正解：还要实现 `MetaObjectHandler`。

### 面试话术

“MyBatis-Plus 注解可以按表、主键、字段和行为来记。最常用的是 @TableName、@TableId、@TableField；行为类常见 @TableLogic、@Version，以及 @TableField(fill = ...) 配合 MetaObjectHandler 做自动填充。需要注意，@Mapper 和 @MapperScan 是 MyBatis 的 Mapper 注册能力，不是实体字段映射注解。”

### 时间分配建议

分类 20 秒，核心注解 70 秒，插件配套 30 秒，误区和实践 30 秒。


---

> 📋 **分类**: mybatis
> 🏷️ **标签**: `实体映射` `MyBatis-Plus` `注解`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-26 10:48:51
