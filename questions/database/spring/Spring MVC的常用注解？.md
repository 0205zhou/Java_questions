---
id: q0086
question: "Spring MVC的常用注解？"
category: spring
tags: ["Web", "Spring", "Spring MVC", "注解", "参数绑定"]
difficulty: medium
created: 2026-08-28 18:40:05
source: 用户输入
---

# Spring MVC的常用注解？

## 联想记忆法

### 记忆口诀/联想

**口诀：控制器接请求，Mapping 定路由，参数注入靠绑定，结果交给消息转换器，异常统一处理。**

可以把 Spring MVC 的注解想成一条 HTTP 请求流水线：

1. **声明入口**：`@Controller`、`@RestController` 标记谁负责接收请求。
2. **匹配路由**：`@RequestMapping`、`@GetMapping`、`@PostMapping` 等决定什么 URL 和 HTTP 方法进入哪个处理方法。
3. **绑定参数**：`@PathVariable` 取路径变量，`@RequestParam` 取查询参数，`@RequestBody` 取请求体，`@RequestHeader` 取请求头。
4. **校验与响应**：`@Valid` / `@Validated` 做参数校验，`@ResponseBody` 或 `@RestController` 把返回值写进响应体。
5. **统一治理**：`@ControllerAdvice`、`@RestControllerAdvice` 和 `@ExceptionHandler` 处理跨控制器的异常与公共逻辑。

### 记忆原理

不要孤立记忆注解名称，而是沿着“请求进来后如何变成响应”来记：**先找到控制器，再找到方法，再把请求数据绑定成 Java 参数，最后把返回值转换成 HTTP 响应**。每个注解都对应流水线上的一个固定位置，面试时即使遇到不常见的组合注解，也能根据职责推断它的作用。

### 关联知识

- `@RequestMapping` 依赖 `RequestMappingHandlerMapping` 完成路由注册和匹配。
- 方法参数解析和返回值处理由 `HandlerMethodArgumentResolver`、`HandlerMethodReturnValueHandler` 等组件完成。
- `@RequestBody` 和 `@ResponseBody` 通常会触发 `HttpMessageConverter`，JSON 场景常见实现是 Jackson 消息转换器。
- `@Valid` / `@Validated` 依赖 Bean Validation 实现；校验失败通常由 `MethodArgumentNotValidException` 等异常表现出来。
- `@RestControllerAdvice` 是 `@ControllerAdvice` 与 `@ResponseBody` 的组合，适合 REST 接口统一返回错误结构。

## 深度解答

### 第一层：核心概念

Spring MVC 常用注解可以按五类理解：**控制器声明、路由映射、请求参数绑定、响应与校验、异常与公共增强**。它们本身并不是把所有 Web 工作都完成了，而是向 Spring MVC 提供元数据，框架再通过组件扫描、HandlerMapping、参数解析器和消息转换器完成真正的请求处理。

#### 1. 控制器声明

`@Controller` 表示一个类是 Spring MVC 控制器。控制器方法返回字符串时，默认可能被当成视图名称交给 `ViewResolver` 解析。

`@RestController` 等价于 `@Controller` 加上类级别的 `@ResponseBody`，方法返回的对象会被写入 HTTP 响应体，通常由 Jackson 序列化成 JSON：

```java
@RestController
@RequestMapping("/users")
public class UserController {
    @GetMapping("/{id}")
    public User detail(@PathVariable Long id) {
        return userService.findById(id);
    }
}
```

`@ResponseBody` 也可以单独标在控制器方法或类上。当项目主要提供 REST API 时，通常直接使用 `@RestController`；当项目同时返回页面和 JSON 时，可以按方法粒度选择是否使用 `@ResponseBody`。

#### 2. 路由映射

`@RequestMapping` 可以标记在类或方法上，支持配置路径、HTTP 方法、请求参数、请求头和媒体类型：

```java
@Controller
@RequestMapping("/orders")
public class OrderController {

    @RequestMapping(
            path = "/{id}",
            method = RequestMethod.GET,
            produces = MediaType.APPLICATION_JSON_VALUE)
    @ResponseBody
    public Order get(@PathVariable Long id) {
        return orderService.get(id);
    }
}
```

实际项目更常用语义更清晰的组合注解：

| 注解 | 常见含义 |
|---|---|
| `@GetMapping` | 处理 GET 请求 |
| `@PostMapping` | 创建资源或提交数据 |
| `@PutMapping` | 整体更新资源 |
| `@PatchMapping` | 部分更新资源 |
| `@DeleteMapping` | 删除资源 |

这些注解本质上是带有固定 HTTP 方法属性的 `@RequestMapping` 组合注解。类级路径用于表达资源前缀，方法级路径用于表达具体操作；这样路由结构更容易维护，也便于统一配置拦截器和权限。

#### 3. 请求参数绑定

`@PathVariable` 用于获取 URL 路径中的占位变量：

```java
@GetMapping("/users/{userId}/orders/{orderId}")
public Order getOrder(@PathVariable Long userId,
                      @PathVariable Long orderId) {
    return orderService.getUserOrder(userId, orderId);
}
```

`@RequestParam` 用于获取查询参数或表单参数，常见于分页、筛选和排序：

```java
@GetMapping
public PageResult<User> page(
        @RequestParam(defaultValue = "1") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(required = false) String keyword) {
    return userService.page(page, size, keyword);
}
```

`@RequestBody` 用于把 JSON、XML 等请求体反序列化为 Java 对象。它不是简单地读取字符串，而是通过 `HttpMessageConverter` 根据 `Content-Type` 选择合适的转换器：

```java
@PostMapping
public User create(@RequestBody @Valid CreateUserRequest request) {
    return userService.create(request);
}
```

`@RequestHeader` 读取请求头，适用于链路追踪、幂等键、租户标识等场景；`@CookieValue` 读取 Cookie；`@RequestPart` 用于 multipart 文件或表单的一部分。

#### 4. 校验与数据转换

`@Valid` 通常触发对象级 Bean Validation；`@Validated` 支持分组校验，也常用于类级别的方法参数校验：

```java
public class CreateUserRequest {
    @NotBlank
    private String name;

    @Email
    private String email;
}
```

如果请求体校验失败，Spring MVC 会抛出相应异常；如果是路径参数或查询参数校验，还可能涉及 `HandlerMethodValidationException` 等异常。生产项目通常在全局异常处理器中把这些异常转换成统一的错误码和字段提示。

`@DateTimeFormat` 和 `@NumberFormat` 可用于控制日期、数字参数的转换格式。对于复杂转换，可以实现 `Converter`、`Formatter` 或注册 `WebBindingInitializer`，不建议在 Controller 中手动重复解析。

#### 5. 响应控制

`@ResponseStatus` 可以声明固定 HTTP 状态码：

```java
@ResponseStatus(HttpStatus.CREATED)
@PostMapping
public User create(@RequestBody CreateUserRequest request) {
    return userService.create(request);
}
```

但在复杂场景中，更推荐返回 `ResponseEntity<T>`，由代码根据业务结果动态设置状态码、响应头和响应体。`@ModelAttribute` 用于把请求参数绑定到表单对象，也可以把方法或字段加入模型；`@SessionAttributes` 和 `@SessionAttribute` 用于特定的会话数据场景，REST API 中应谨慎使用。

#### 6. 异常处理与统一增强

`@ExceptionHandler` 标记异常处理方法，可以放在控制器内部处理局部异常：

```java
@ExceptionHandler(OrderNotFoundException.class)
public ResponseEntity<ErrorResponse> handle(OrderNotFoundException ex) {
    return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new ErrorResponse("ORDER_NOT_FOUND", ex.getMessage()));
}
```

`@ControllerAdvice` 对多个控制器提供统一的异常处理、数据绑定和模型增强；`@RestControllerAdvice` 额外带有响应体语义，适合 JSON API：

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ErrorResponse handleValidation(MethodArgumentNotValidException ex) {
        return ErrorResponse.from(ex.getBindingResult());
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnknown(Exception ex) {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ErrorResponse("SYSTEM_ERROR", "系统繁忙"));
    }
}
```

`@InitBinder` 可以定制参数绑定和校验器；`@ModelAttribute` 方法可以在请求处理前准备公共模型数据。它们适合有明确复用价值的场景，不能把复杂业务逻辑塞入 Controller 增强方法。

### 第二层：底层原理

请求到达 `DispatcherServlet` 后，Spring MVC 大致经历以下过程：

```text
HTTP 请求
  -> HandlerMapping 根据 @RequestMapping 找到 HandlerMethod
  -> HandlerAdapter 调用控制器方法
  -> 参数解析器处理 @PathVariable / @RequestParam / @RequestBody
  -> Controller 返回结果
  -> 返回值处理器决定视图渲染或响应体写出
  -> HttpMessageConverter 序列化对象
  -> HTTP 响应
```

启动时，`RequestMappingHandlerMapping` 扫描控制器方法，把注解中的路径、HTTP 方法和条件注册为映射关系。请求到达后，HandlerMapping 负责“找谁处理”；HandlerAdapter 负责“如何调用”。参数注解最终由不同的参数解析器处理，返回值注解则由返回值处理器处理。这种职责拆分让 Spring MVC 可以同时支持视图、REST、文件下载、异步返回值等多种处理方式。

### 第三层：实践应用与最佳实践

一个典型 REST 控制器可以这样组织：

```java
@RestController
@RequestMapping("/api/products")
public class ProductController {

    @GetMapping("/{id}")
    public ProductResponse get(@PathVariable Long id) {
        return productService.get(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ProductResponse create(@RequestBody @Valid CreateProductRequest request) {
        return productService.create(request);
    }
}
```

实践中建议：

- Controller 负责协议适配，不直接承载复杂业务和数据库细节。
- 路径参数表示资源层级，查询参数表示筛选、分页或排序条件。
- 对必填参数明确声明，不要依赖空指针或手动 `if` 判断兜底。
- 使用 DTO 接收请求和返回响应，避免直接暴露持久化实体。
- 全局异常统一转换，避免每个方法复制相同的 try-catch。
- `@RequestBody` 要配合正确的 `Content-Type`，否则可能出现无法读取请求体的问题。
- 不要把可变请求数据保存到单例 Controller 的成员变量中，Controller 默认是单例且会被并发访问。

### 第四层：深入思考与易错点

1. `@Controller` 不等于返回 JSON。只有方法或类带有 `@ResponseBody`，返回值才会走消息转换器；`@RestController` 是最常见的组合方式。
2. `@RequestParam` 和 `@PathVariable` 的来源不同：`/users/{id}` 用后者，`/users?id=1` 用前者。
3. `@RequestBody` 处理的是请求体，不适合读取 URL 查询参数；JSON 反序列化失败和参数缺失也应统一处理。
4. `@Valid` 只是触发校验，约束规则仍需写在 DTO 上，并且异常结果需要被正确返回给调用方。
5. `@RequestMapping` 可以通过路径、方法、参数、请求头和媒体类型联合匹配，不能只把它理解为 URL 字符串映射。
6. 注解只有在 Spring MVC 容器管理的 Controller 上才会被识别；自己 `new` 控制器、没有组件扫描或没有注册 DispatcherServlet 时，注解不会自动生效。

## 回答思路

### 答题逻辑框架

1. 先按请求链路给出分类：控制器、路由、参数、响应、异常。
2. 重点讲 `@RestController`、`@RequestMapping`、`@GetMapping` / `@PostMapping`。
3. 用一个接口示例串起 `@PathVariable`、`@RequestParam`、`@RequestBody`、`@Valid`。
4. 补充 `@ControllerAdvice`、`@ExceptionHandler` 和 `@RestControllerAdvice`。
5. 最后说明注解背后的 HandlerMapping、参数解析器和 HttpMessageConverter。

### 重点得分点

- 能说清 `@Controller` 与 `@RestController` 的区别。
- 能区分路径参数、查询参数、请求体和请求头的绑定注解。
- 能说明 `@GetMapping` 等是 `@RequestMapping` 的组合注解。
- 能解释 `@RequestBody` 为什么能把 JSON 变成 Java 对象。
- 能指出全局异常处理和参数校验的常见组合方式。
- 能说出注解依赖 Spring MVC 容器，不是普通 Java 类上的魔法。

### 常见误区

- 把 `@RequestParam` 和 `@PathVariable` 混用。
- 认为 `@Controller` 返回对象就一定会自动转 JSON。
- 只会罗列注解，却说不清 HandlerMapping、参数解析器和消息转换器的职责。
- 认为加了 `@Valid` 就会自动生成统一错误响应。
- 在单例 Controller 中保存请求级可变状态，导致并发线程安全问题。

### 面试话术

“Spring MVC 常用注解可以按请求处理链路来记：`@Controller` 或 `@RestController` 声明入口，`@RequestMapping` 及其 `@GetMapping`、`@PostMapping` 负责路由，`@PathVariable`、`@RequestParam`、`@RequestBody`、`@RequestHeader` 负责参数绑定，`@Valid` 做校验，`@ControllerAdvice` 和 `@ExceptionHandler` 做统一异常处理。它们背后分别由 HandlerMapping、参数解析器、返回值处理器和 HttpMessageConverter 执行。”

### 时间分配建议

- 20 秒：按链路分类并给出总览。
- 60 秒：路由和参数绑定注解。
- 40 秒：响应、校验和异常处理。
- 30 秒：底层组件与常见误区。


---

> 📋 **分类**: spring
> 🏷️ **标签**: `Web` `Spring` `Spring MVC` `注解` `参数绑定`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-28 18:40:05
