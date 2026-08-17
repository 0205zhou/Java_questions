---
id: q0055
question: "GET和POST的区别"
category: network
tags: []
difficulty: medium
created: 2026-08-18 00:44:08
source: 用户输入
---

# GET和POST的区别

---
id: q0056
question: GET和POST的区别
category: network
tags: [HTTP, GET, POST, 网络协议]
difficulty: easy
created: 2026-08-18 00:00:00
source: 用户输入
---

# GET和POST的区别

## 🧠 联想记忆法

### 记忆口诀/联想

**口诀：GET 像查资料，POST 像交材料。**

- **GET**：去取、去查、去看
- **POST**：去提交、去创建、去处理

### 记忆原理

这题的关键不是死背“GET 在 URL，POST 在 body”这种表层结论，而是理解它们的**语义差异**：GET 更强调“获取资源”，POST 更强调“提交数据并触发服务器处理”。当你记住“查资料”和“交材料”的场景，就不容易把“安全性、幂等性、缓存性”这些维度混淆。

### 关联知识

- 与 **HTTP 方法语义** 关联
- 与 **幂等性（Idempotency）** 关联
- 与 **缓存、浏览器历史、书签** 关联
- 与 **RESTful API** 设计关联

## 📖 深度解答

### 核心概念

GET 和 POST 都是 HTTP 方法（HTTP Method），都能向服务器传递数据，但两者的设计语义不同：

- **GET**：主要用于获取资源
- **POST**：主要用于提交数据，由服务器决定如何处理

### 底层原理

#### 1. 语义不同

GET 强调“读取资源”，理论上不应该对服务端数据产生副作用。

POST 强调“提交数据”，常用于新增、登录、下单、上传等会触发服务器处理的动作。

#### 2. 参数位置不同，但不是本质区别

- GET 参数通常放在 **URL 查询串（Query String）** 中
- POST 参数通常放在 **请求体（Request Body）** 中

但这只是常见实现，不是协议层唯一标准。面试里一定要强调：**真正本质是语义，不是位置。**

#### 3. 安全性误区

很多人说“POST 比 GET 安全”，这句话并不严谨。GET 参数暴露在 URL 中，确实更容易出现在浏览器地址栏、历史记录、日志里；但如果没有 HTTPS（HyperText Transfer Protocol Secure，安全超文本传输协议）加密，POST 请求体同样可能被窃听。所以：

- **POST 不是天然安全**
- **真正的安全依赖 HTTPS、鉴权、签名、防重放**

#### 4. 幂等性不同

- **GET 应该是幂等（Idempotent）** 的：调用一次和多次，结果应一致
- **POST 通常不是幂等**：多次提交可能新增多条数据

#### 5. 缓存和书签不同

- GET 请求更容易被浏览器、代理服务器缓存
- GET URL 可以收藏为书签
- POST 一般不直接缓存，也不适合作为书签

### 实践应用

#### 常见使用场景

| 方法 | 常见场景 |
|---|---|
| GET | 查询用户、查询订单、搜索列表 |
| POST | 登录、注册、创建订单、上传文件 |

#### 代码示例

```java
@RestController
@RequestMapping(/users)
public class UserController {

    @GetMapping(/{id})
    public User query(@PathVariable Long id) {
        return userService.getById(id);
    }

    @PostMapping
    public Long create(@RequestBody CreateUserRequest request) {
        return userService.create(request);
    }
}
```

#### 文字架构图

```text
GET /users/1
→ 表达“我要查用户 1”
→ 更偏资源读取

POST /users
Body: {name: Tom}
→ 表达“我要提交一份创建用户的材料”
→ 更偏提交动作
```

### 深入思考

1. **不要把 GET 和 POST 等同于“查”和“改”绝对规则**。这是常见设计习惯，但协议只规定语义倾向。
2. **面试高分点**：补充 RESTful（Representational State Transfer，表述性状态转移）设计思想。
3. **真实项目里幂等不能只靠 POST/GET 区分**：比如下单 POST 往往还要配合幂等号、防重令牌。

## 🗺️ 回答思路

1. 先说它们都是 HTTP 方法，但语义不同。
2. 再讲 5 个维度：语义、参数位置、幂等性、缓存性、安全性。
3. 最后落场景：查询用 GET，提交创建用 POST。
4. 如果追问，就强调 POST 不等于绝对安全，安全依赖 HTTPS 和鉴权。


---

> 📋 **分类**: network
> 🏷️ **标签**: 
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-18 00:44:08
