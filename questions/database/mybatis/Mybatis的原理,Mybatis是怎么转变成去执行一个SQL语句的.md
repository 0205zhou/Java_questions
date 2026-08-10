---
id: q0020
question: "Mybatis的原理,Mybatis是怎么转变成去执行一个SQL语句的"
category: mybatis
tags: ["MyBatis"]
difficulty: medium
created: 2026-08-11 00:52:47
source: 用户输入
---

# Mybatis的原理,Mybatis是怎么转变成去执行一个SQL语句的

---

## 联想记忆法

### 记忆口诀/联想

**口诀:「代理把门,会话引路,执行器调度,语句器写稿,结果器收尾」——五层电梯下到底,SQL 就跑出来了**

- **代理把门**:`MapperProxy`(JDK 动态代理)拦住对 Mapper 接口的调用——**接口没有实现类,全靠代理**假装实现了
- **会话引路**:`SqlSession` 根据 namespace + id 找到对应的 `MappedStatement`(一条 SQL 的完整"档案")
- **执行器调度**:`Executor` 决定执行策略(缓存、批处理),调度 SQL 的最终执行
- **语句器写稿**:`StatementHandler` 创建 JDBC `PreparedStatement`,`ParameterHandler` 把 Java 参数写进 `?` 占位符
- **结果器收尾**:`ResultSetHandler` 把 JDBC 的 `ResultSet` 一行行映射回 Java 对象

五个角色的首字连起来:**「代、会、执、语、结」**——谐音"**大会计执愚姐**",或用"代理会见执行语言的结果"这种顺口串来回忆顺序。

### 记忆原理

采用**拟人化五角色流水线**,和记忆 Spring MVC 的"D-M-A-V 四角色"是同一套认知钩子:角色即组件、顺序即调用链。关键锚点是第一层——**"Mapper 接口没有实现类"**这个反常识事实,记住"动态代理"就抓住了 MyBatis 的命门,后面四层都是顺着调用栈自然展开。每层只问一句"它负责什么",五句话即可讲完整条链路。

### 关联知识

- **与 JDBC 关联**:MyBatis 是对 JDBC 的封装,底层仍是 `DriverManager` → `Connection` → `PreparedStatement` → `ResultSet` 那套
- **与动态代理关联**:JDK 动态代理(`Proxy` + `InvocationHandler`)是 Mapper 接口机制的核心,与 Spring AOP 底层同源
- **与 Spring 集成关联**:`SqlSessionTemplate` 是 SqlSession 的 Spring 版本(线程安全),`MapperFactoryBean` 负责生产 Mapper 代理
- **与 Spring Boot 关联**:`MybatisAutoConfiguration` 自动装配 SqlSessionFactory、SqlSessionTemplate、MapperScannerConfigurer——自动装配原理题的"活例子"
- **与插件机制关联**:Executor / StatementHandler / ParameterHandler / ResultSetHandler 四大对象都能被插件包装——分页插件 PageHelper 就是拦截 StatementHandler
- **与缓存关联**:一级缓存(SqlSession 级)、二级缓存(namespace 级)都挂在 Executor 上

---

## 深度解答

### 第一层:核心概念

#### MyBatis 是什么、解决什么问题

**MyBatis 是一个半自动化的 ORM(Object Relational Mapping)持久层框架**:SQL 由开发者编写(半自动),参数绑定与结果映射由框架完成。相比原生 JDBC,它解决了三个痛点:

1. **样板代码**:获取连接、创建 Statement、遍历 ResultSet、关资源——全部由框架代劳
2. **参数/结果映射**:Java 类型 ↔ SQL 类型由 TypeHandler 自动转换,不再手写 setString/getString
3. **SQL 与代码分离**:SQL 写在 XML 或注解里,可维护、可复用

#### 核心问题:接口明明没有实现类,调用为什么能成功

```java
UserMapper mapper = sqlSession.getMapper(UserMapper.class);  // 返回的是代理对象
User user = mapper.selectById(1L);   // 代理拦截这次调用,翻译成一条 SQL 执行
```

**答案就是 JDK 动态代理**:`getMapper()` 返回的是 `MapperProxyFactory` 用 `Proxy.newProxyInstance()` 创建的代理对象,不是 UserMapper 的实现类。调用 `mapper.selectById(1)` 时,所有方法调用都会进入 `MapperProxy.invoke()`——这就是"怎么转变成执行 SQL"的入口。

### 第二层:底层原理——一条 SQL 的完整执行链路

#### 准备阶段:SQL 是怎么"注册"进框架的

1. **解析全局配置**(mybatis-config.xml 或 Boot 中的 `@ConfigurationProperties`):数据源、缓存开关、类型别名等
2. **解析 Mapper XML**:`XMLMapperBuilder` 读取 `UserMapper.xml`,把每个 `<select>/<insert>/<update>/<delete>` 解析成一个 **`MappedStatement`**,包含:SQL 语句(带 `?` 占位符)、参数映射、结果映射、statementType 等;它的唯一标识是 **namespace + id**(如 `com.example.UserMapper.selectById`)
3. `MappedStatement` 注册进全局 `Configuration`——相当于"每条 SQL 的档案库"
4. **Mapper 接口注册**:`MapperScannerConfigurer`(或 `@MapperScan` / `@Mapper`)扫描接口,为每个接口注册一个 `MapperFactoryBean`

#### 阶段 A:接口调用 → 代理拦截

```java
// mapper.selectById(1L) 实际进入:
public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
    // 1. Object 方法(toString/hashCode)直接走本类
    // 2. 默认方法走 default 逻辑
    // 3. 其余 → MapperMethod.execute(sqlSession, args)
}
```

`MapperMethod` 根据方法名(selectById)匹配 `MappedStatement`(mybatis 约定 **方法名 = MappedStatement 的 id**),再从 `@Param` 注解构造参数对象。

#### 阶段 B:SqlSession 引路

`MapperMethod` 调用 `SqlSession.selectOne/selectList/insert...`。MyBatis 里 SqlSession 是门面(Facade),只做路由;真正干活的是 Executor。Spring 集成下是 **`SqlSessionTemplate`**(线程安全,内部用 SqlSessionProxy 再包一层,保证每个线程独立 SqlSession 且事务同步)。

#### 阶段 C:Executor 调度

`SqlSession` 把调用交给 `Executor`(实现是装饰器链):

```
CachingExecutor(二级缓存,可关闭)
  └── BaseExecutor(抽象,管一级缓存 LocalCache)
        ├── SimpleExecutor   — 每语句新建 Statement
        ├── ReuseExecutor    — 复用已编译的 Statement
        └── BatchExecutor    — 批量执行
```

Executor 拿到 `MappedStatement`,调用 `query()`,内部交给 `StatementHandler`。

#### 阶段 D:StatementHandler 写稿——SQL 真正到达 JDBC

`PreparedStatementHandler`(StatementHandler 实现)做三件事:

1. **prepare()**:根据 SQL 文本调用 `connection.prepareStatement(sql)`,得到 JDBC `PreparedStatement`(预编译,SQL 注入防线之一)
2. **parameterize()**:交给 `ParameterHandler` → 遍历参数映射,用对应 **`TypeHandler`**(如 IntegerTypeHandler)调用 `ps.setInt(i, value)`,把 Java 参数写入每个 `?` 占位符
3. **query()**:`ps.execute()` / `ps.executeQuery()`,SQL 在数据库执行

#### 阶段 E:ResultSetHandler 收尾——结果变成对象

数据库返回 `ResultSet` 后,`ResultSetHandler` 负责:

1. 遍历行,根据结果映射(ResultMap 或自动映射)找到目标类的属性
2. 用 TypeHandler 读值(`rs.getLong()` 等),支持**自动映射**(列名下划线转驼峰 `user_name → userName`)、嵌套查询、一对多集合
3. 通过反射/无参构造器/Builder 组装成 POJO(或 List、Map、基础类型)

#### 完整时序(文字架构图)

```
mapper.selectById(1L)
  → MapperProxy.invoke(MapperMethod.execute)
      → SqlSession.selectOne(SqlSessionTemplate)
          → Executor.query(CachingExecutor → BaseExecutor)
              → StatementHandler.query(PreparedStatementHandler)
                  → ParameterHandler.setParameters(TypeHandler 写参)
                  → PreparedStatement.execute()
                      → [数据库执行 SQL]
                  → ResultSetHandler.handleResultSets(TypeHandler 读值 + 反射映射)
      ← 返回 User 对象
```

#### 插件:四大对象都可以被"加戏"

Executor、StatementHandler、ParameterHandler、ResultSetHandler 在创建时都会经过 `InterceptorChain.pluginAll()`,用动态代理包装一层——**MyBatis 插件就是拦截这四大接口的方法**。PageHelper 分页插件即拦截 StatementHandler,执行前拼上 `LIMIT`,执行后查 count。

#### 缓存

- **一级缓存**:BaseExecutor 的 LocalCache,默认开启,**SqlSession 级别**(同一 SqlSession 内同 SQL 不重复查库);会话关闭即失效
- **二级缓存**:CachingExecutor 的 namespace 级缓存,默认关闭(`<cache/>` 开启),跨 SqlSession 共享

### 第三层:实践应用

#### 一个最小完整链路

```java
// UserMapper.java —— 只有接口,没有实现类
public interface UserMapper {
    User selectById(@Param("id") Long id);
}
```

```xml
<!-- UserMapper.xml —— 被解析成 MappedStatement(id = 接口名.方法名) -->
<mapper namespace="com.example.UserMapper">
    <select id="selectById" resultType="com.example.User">
        SELECT id, user_name AS userName FROM user WHERE id = #{id}
    </select>
</mapper>
```

```java
// 使用(Spring 环境直接注入接口,MyBatis 自动注入代理)
@Autowired
private UserMapper userMapper;

User user = userMapper.selectById(1L);
```

#### 与 Spring 集成时的关键点

- `SqlSessionFactoryBean` → 生产 `SqlSessionFactory`(Configuration 的工厂)
- `SqlSessionTemplate` → 线程安全的 SqlSession,与 Spring 事务(SpringManagedTransaction)同步提交/回滚
- `MapperFactoryBean` → 每个 Mapper 接口一个,`getObject()` 返回动态代理
- Boot 场景下由 `MybatisAutoConfiguration` 全自动装配

#### 常见调优手段

- 批量插入用 `ExecutorType.BATCH` 或 MyBatis-Plus 的 `IService.saveBatch`
- 合理使用二级缓存 + Redis 做分布式缓存(Cache 接口可自定义)
- SQL 用 `#{}` 而非 `${}`(预编译防注入);确实要动态拼接用 `${}` 时注意白名单校验

### 第四层:深入思考

- **为什么 MyBatis 被称"半自动"?** SQL 完全由开发者掌控(性能可控、复杂 SQL 友好),代价是"要自己写 SQL";对比 JPA/Hibernate 全自动映射 + 二级缓存 + 延迟加载,但 SQL 生成对复杂查询不透明、性能调优门槛高。**面试高频题:MyBatis vs JPA**
- **为什么用 PreparedStatement 而不是 Statement?** 预编译(一次编译多次执行)+ 参数与 SQL 分离(`?` 占位符由参数器写入,注入字符只是参数值),从机制上防 SQL 注入
- **一级缓存为什么经常"没生效"?** 每次查询前 SqlSession 会清缓存(任何增删改都会清);且 Spring 集成下若不在同一事务内,每次调用都新建 SqlSession,缓存形同虚设——很多人误以为是 bug
- **追问方向**:MyBatis-Plus 与 MyBatis 的关系(MP 基于 MyBatis 做增强:通用 Mapper、条件构造器,底层仍是 Executor + MappedStatement)?分页插件原理?多数据源如何实现(多个 SqlSessionFactory)?`#{id}` 和 `${id}` 的区别?

---

## 回答思路

### 答题逻辑框架

按"**一个反常识 + 五层链路 + 一个深入点**"展开(约 4~5 分钟):

1. **抛出反常识结论**:Mapper 接口没有实现类,调用能被处理全靠 JDK 动态代理(MapperProxy)
2. **讲五层链路**(代→会→执→语→结):代理拦截 → SqlSession 路由到 MappedStatement → Executor 调度(顺带讲缓存挂载点)→ StatementHandler + ParameterHandler 生成 PreparedStatement → ResultSetHandler 映射结果
3. **点出三个"细节加分"**:`#{}` 预编译防注入、TypeHandler 类型转换、四大对象插件机制(分页插件原理)
4. **收尾**:MyBatis 是对 JDBC 的封装 + 半自动对比 Hibernate

### 重点得分点

- ✅ 一句话点破"Mapper 接口没有实现类,是 JDK 动态代理"
- ✅ 说出 `MappedStatement` 的 id = namespace + 方法名
- ✅ 说出四大核心对象:Executor / StatementHandler / ParameterHandler / ResultSetHandler
- ✅ 说出 PreparedStatement 的预编译与防 SQL 注入
- ✅ 能画出"代理 → SqlSession → Executor → StatementHandler → ResultSetHandler"调用链

### 常见误区

- ❌ "MyBatis 给接口生成了实现类" → 错,是运行时动态代理,编译期没有任何实现类
- ❌ 把一级缓存(SqlSession 级)和二级缓存(namespace 级)记反
- ❌ 说 MyBatis 直接用 Statement 拼接 SQL → 默认是 PreparedStatement 预编译
- ❌ 把 `${}` 当安全用法 → `${}` 是字符串拼接,有注入风险;`#{}` 才是预编译占位
- ❌ 分页插件原理答不上来 → 拦截 StatementHandler 在 SQL 上拼 LIMIT

### 过渡话术

- 引出缓存/分库分表:"MyBatis 的执行链路里 Executor 挂着一二级缓存,插件机制还能拦截四大对象——像分库分表中间件(ShardingSphere)就是在 SQL 执行前改写 SQL 的,这属于框架层扩展……"

### 时间分配建议

- 反常识结论 + 代理 1 分钟 → 五层链路 2.5 分钟 → 缓存/插件 1 分钟 → MyBatis vs JPA 对比收尾 30 秒

---

> 📋 **分类**: mybatis
> 🏷️ **标签**: `MyBatis`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-11 00:52:47
