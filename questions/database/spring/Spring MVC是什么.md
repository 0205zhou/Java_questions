---
id: q0002
question: "Spring MVC是什么"
category: spring
tags: ["Spring"]
difficulty: medium
created: 2026-08-09 02:58:14
source: 用户输入
---


# Spring MVC 是什么

---

## 联想记忆法

### 记忆口诀/联想

**口诀："D 把门，M 找路，A 干活，V 送客"**

或者用 **"请求进门 Dispatcher，Mapping 寻路 Adapter 干，ModelAndView 来打包，Resolver 渲染把客还"** 来记忆整个知识体系：

- **D 把门** = DispatcherServlet（前端控制器）：统一接收所有请求，像门卫一样把门
- **M 找路** = HandlerMapping：根据 URL 找到对应的 Handler（Controller 方法），像带路的
- **A 干活** = HandlerAdapter：适配并调用 Controller 方法，真正干活的
- **V 送客** = ViewResolver + View：解析视图名、渲染结果，把响应"送客"出去

### 记忆原理

这个口诀采用**"拟人化流水线"**的方式，把 Spring MVC 的请求处理流程比作"门卫 → 带路的 → 干活的 → 送客的"四个角色。**记住四个字母 D、M、A、V 的顺序**，就等于记住了整个执行流程的顺序：请求先进 DispatcherServlet（D），再由 HandlerMapping（M）找方法，HandlerAdapter（A）执行，最后 ViewResolver/View（V）渲染返回。字母本身就是触发点，顺字母就能把七步流程串起来。

### 关联知识

- **与 Servlet 规范关联**：Spring MVC 基于 Servlet API 实现，DispatcherServlet 本质就是一个 Servlet，在 web.xml / Spring Boot 中注册 —— 理解 Spring MVC 前先理解 Servlet
- **与 Spring IoC 关联**：DispatcherServlet、HandlerMapping 等组件都是注册在 Spring 容器中的 Bean，Spring MVC 是 Spring 容器之上的一层 Web 封装
- **与 Spring Boot 关联**：spring-boot-starter-web 自动装配 DispatcherServlet 和默认配置，无需 web.xml —— 面试常问"Spring MVC 和 Spring Boot 什么关系"
- **与 AOP 关联**：拦截器（Interceptor）的底层就是 AOP 思想，切在 Handler 执行前后
- **与 Filter 关联**：Servlet Filter 在 DispatcherServlet 之前执行，两者职责不同（详见第四层）
- **与 RPC/Feign 对比关联**：RPC 是"方法调用"级别的远程通信，Spring MVC 是"HTTP 请求分发"，都是"分发-执行"思想的体现

---

## 深度解答

### 第一层：核心概念

#### 什么是 MVC 设计模式

MVC（Model-View-Controller）是一种**关注点分离（Separation of Concerns）**的设计模式：

| 角色 | 职责 |
|---|---|
| **Model（模型）** | 业务数据 + 业务逻辑，不关心怎么展示 |
| **View（视图）** | 页面展示层，只负责渲染数据 |
| **Controller（控制器）** | 接收请求、调用模型、选择视图，充当"调度员" |

#### 什么是 Spring MVC

**Spring MVC 是基于 Servlet API 实现的、遵循 MVC 设计模式的 Web 框架**，是 Spring 框架的一部分。它解决了传统 Servlet 开发中的痛点：

- 传统 Servlet：每个请求都要手动解析参数、手动分发、手动渲染，代码重复、耦合高、难测试
- Spring MVC：框架统一完成请求接收、参数绑定、视图解析，**开发者只需要写 Controller 业务逻辑**

---

### 第二层：底层原理

#### 核心组件及其职责

| 组件 | 角色 | 职责 |
|---|---|---|
| **DispatcherServlet** | 前端控制器 | 统一接收所有请求并分发，MVC 流程的"总开关" |
| **HandlerMapping** | 路由表 | 根据 URL 找到对应的 Handler（Controller 方法），如 RequestMappingHandlerMapping |
| **HandlerAdapter** | 适配器 | 适配不同的 Handler 类型，负责调用 Controller 方法并完成参数绑定 |
| **Controller** | 业务逻辑 | 真正执行业务的地方 |
| **ModelAndView** | 结果载体 | 封装模型数据 + 视图名 |
| **ViewResolver** | 视图解析器 | 根据视图名解析出真正的 View（如 JSP、Thymeleaf），如 InternalResourceViewResolver |
| **View** | 渲染器 | 渲染模型数据，输出响应 |

#### 完整执行流程（必须背下来）

```
① 客户端发送 HTTP 请求
        ↓
② DispatcherServlet 接收请求（doDispatch）
        ↓
③ HandlerMapping 根据 URL 找到对应的 Handler（Controller 方法）+ 拦截器链
        ↓
④ HandlerAdapter 适配并调用 Controller 方法（自动完成参数绑定、数据校验）
        ↓
⑤ Controller 执行完业务，返回 ModelAndView
        ↓
⑥ DispatcherServlet 通过 ViewResolver 解析视图名，得到 View
        ↓
⑦ View 渲染模型数据，生成响应返回客户端
```

#### 源码关键点：DispatcherServlet.doDispatch

```java
protected void doDispatch(HttpServletRequest request, HttpServletResponse response) {
    // 1. 通过 HandlerMapping 获取执行链（Handler + 拦截器）
    HandlerExecutionChain mappedHandler = getHandler(processedRequest);
    // 2. 通过 HandlerAdapter 执行 Controller 方法
    HandlerAdapter ha = getHandlerAdapter(mappedHandler.getHandler());
    // 3. 真正调用，返回 ModelAndView
    ModelAndView mv = ha.handle(processedRequest, response, mappedHandler.getHandler());
    // 4. 视图解析与渲染
    processDispatchResult(processedRequest, response, mappedHandler, mv, dispatchException);
}
```

#### @RestController 的原理（消息转换器）

```java
@RestController
public class UserController {
    @GetMapping("/user/{id}")
    public User getUser(@PathVariable Long id) {
        return userService.getById(id);   // 直接返回对象
    }
}
```

- `@RestController` = `@Controller` + `@ResponseBody`
- `@ResponseBody` 会走 **HttpMessageConverter（消息转换器）**，如 MappingJackson2HttpMessageConverter
- Controller 返回的 Java 对象 → Jackson 序列化为 JSON → 写入响应体
- 不加 `@ResponseBody` 时，返回的字符串会被当作**视图名**去解析 —— 这是理解"RestController 返回 JSON 而不是页面"的关键

---

### 第三层：实践应用

#### 常用注解速查

| 注解 | 作用 |
|---|---|
| `@Controller` / `@RestController` | 声明控制器 / 声明 REST 控制器（返回 JSON） |
| `@RequestMapping` | 映射 URL 与请求方式，可加 `@GetMapping` 等组合注解 |
| `@PathVariable` | 从 URL 路径取参数（`/user/{id}`） |
| `@RequestParam` | 从查询参数取参数（`?name=xx`），可设置 defaultValue |
| `@RequestBody` | 从请求体取 JSON 反序列化为对象 |
| `@RequestHeader` | 从请求头取参数 |
| `@Valid` / `@Validated` | 配合 JSR-303 校验（@NotNull、@Size 等） |

#### 全局异常处理（@ControllerAdvice）

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public Result<Void> handleBusiness(BusinessException e) {
        return Result.fail(e.getCode(), e.getMessage());
    }

    @ExceptionHandler(Exception.class)
    public Result<Void> handleException(Exception e) {
        log.error("系统异常", e);
        return Result.fail(500, "系统繁忙，请稍后重试");
    }
}
```

#### 拦截器（Interceptor）示例

```java
@Component
public class LoginInterceptor implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        // 登录校验：token 无效直接拦截，返回 401
        if (request.getAttribute("userId") == null) {
            response.setStatus(401);
            return false;
        }
        return true;
    }
}
```

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new LoginInterceptor())
                .addPathPatterns("/**")
                .excludePathPatterns("/login", "/register");
    }
}
```

#### 与 Spring Boot 的关系

- `spring-boot-starter-web` 内嵌 Tomcat + 自动装配 DispatcherServlet，无需 web.xml
- 开发者只写 `@RestController` 就能暴露接口，配置默认值开箱即用
- Spring Boot 是"约定大于配置"的封装，底层仍然是 Spring MVC 那套机制

---

### 第四层：深入思考

#### 1. Filter vs Interceptor 的区别（高频追问）

| 维度 | Servlet Filter | Spring 拦截器 Interceptor |
|---|---|---|
| 所属 | Servlet 规范 | Spring 框架 |
| 执行时机 | DispatcherServlet **之前** | Controller 方法**之前** |
| 能访问 | 只能访问 request/response | 还能访问 Handler、ModelAndView、Bean 容器 |
| 使用场景 | 编码、跨域、日志、鉴权 | 登录校验、权限、性能监控 |

执行顺序：`请求 → Filter → DispatcherServlet → Interceptor → Controller`

#### 2. 为什么不用原生 Servlet

- 原生 Servlet 需要手动解析参数、手动渲染视图、每个 URL 一个 Servlet，类爆炸
- Spring MVC 通过 HandlerMapping 实现**方法级映射**（一个 URL → 一个方法），通过消息转换器实现**参数自动绑定**，开发效率数量级提升

#### 3. Spring MVC 与 Struts2 的对比

| 维度 | Spring MVC | Struts2 |
|---|---|---|
| 拦截粒度 | 方法级（URL → 方法） | 类级（Action） |
| 单例/多例 | 单例，更省内存 | 多例（有 ThreadLocal 变量） |
| 解耦程度 | 与 Spring 天然融合 | 耦合较深，已被淘汰 |
| 现状 | 事实标准 | 基本退出主流 |

#### 4. Spring MVC 的线程模型与性能

- DispatcherServlet 是**单例**，但请求处理由 Tomcat 的多线程支撑：**每个请求一个线程**，从 Tomcat 线程池中获取
- 线程安全的边界：Controller 内不要用共享可变成员变量，否则多线程并发下会出现数据竞争
- 异步场景：Spring MVC 支持 `Callable` / `WebAsyncTask` / Servlet 3.1 异步请求，高并发长任务可释放线程

#### 5. Spring WebFlux 与 Spring MVC 的关系

- Spring 5 推出的 WebFlux 是**响应式** Web 框架（Reactor，非阻塞），基于 Netty
- 适用场景：高并发 IO 密集型（网关、推送服务）；但传统业务（JDBC 阻塞 IO）仍是 Spring MVC 主场
- 面试加分点：能说出"Spring MVC 是同步阻塞模型，WebFlux 是异步非阻塞模型，两者并存不冲突"

---

## 回答思路

### 答题逻辑框架

面试时建议按以下层次递进回答，总时长控制在 **3-5 分钟**：

```
┌─────────────────────────────────────────────────┐
│  第一层（20秒）：一句话定义                       │
│  "Spring MVC 是基于 Servlet 的 MVC 设计模式       │
│   的 Web 框架，核心是 DispatcherServlet"          │
├─────────────────────────────────────────────────┤
│  第二层（60秒）：核心组件                         │
│  DispatcherServlet / HandlerMapping /           │
│  HandlerAdapter / ViewResolver                  │
├─────────────────────────────────────────────────┤
│  第三层（60秒）：完整执行流程                     │
│  请求 → D 分发 → M 找方法 → A 执行 → V 渲染      │
├─────────────────────────────────────────────────┤
│  第四层（30秒）：注解与原理                       │
│  @RestController 为什么返回 JSON（消息转换器）    │
├─────────────────────────────────────────────────┤
│  第五层（40秒）：深度对比                         │
│  Filter vs Interceptor / 与 Spring Boot 关系     │
└─────────────────────────────────────────────────┘
```

### 重点得分点（面试官考察意图）

1. **流程完整度**（核心得分点）：能把七步流程按顺序背下来（D → M → A → Controller → MV → Resolver → View）——考察对框架运行机制的掌握

2. **组件职责清晰**：能说出 HandlerMapping 和 HandlerAdapter 的区别（一个找方法、一个调方法）——这是最容易被混淆的两兄弟

3. **@RestController 原理**：能说出 "= @Controller + @ResponseBody，走 HttpMessageConverter 序列化"——考察是否理解底层而非只会用

4. **Filter vs Interceptor**：能说清执行顺序（Filter 在 DispatcherServlet 前）——考察对 Servlet 规范的理解

5. **与 Spring Boot 的关系**：能说出"Spring Boot 是自动配置的封装，底层还是 Spring MVC"——考察对技术栈脉络的理解

### 常见误区（扣分点）

| 错误说法 | 正确理解 |
|----------|----------|
| "DispatcherServlet 处理业务逻辑" | 它只做分发（前端控制器），业务在 Controller |
| "HandlerMapping 负责执行方法" | 它只负责找 Handler，执行是 HandlerAdapter 的事 |
| "@RestController 返回 String 是 JSON" | 返回 String 默认按文本/视图名处理，返回对象才走 Jackson 转 JSON |
| "拦截器是 Servlet 规范的一部分" | 拦截器是 Spring 的组件，Filter 才是 Servlet 规范的 |
| "Spring MVC = Spring Boot" | Spring Boot 是生态/自动配置，Spring MVC 是其中的 Web 框架 |

### 过渡话术建议

- **从定义到流程**："Spring MVC 的核心思想是前端控制器模式，我们来看一个请求进来后它经历的完整流程..."
- **从流程到组件**："流程里有个细节：HandlerMapping 负责根据 URL 找到方法，HandlerAdapter 负责真正调用它，这两步分离是为了支持不同类型的 Handler..."
- **从 MVC 到 REST**："如果接口只需要返回 JSON 而不需要页面，就用 @RestController，它的底层是消息转换器，把 Java 对象序列化成 JSON..."
- **总结过渡**："总的来说，Spring MVC 用前端控制器把请求处理的各个阶段解耦了，开发者只关注 Controller 里的业务，这是它成为 Java Web 事实标准的原因。"

### 时间分配建议

- **面试总时长 45 分钟的场景**：此问题回答控制在 3-5 分钟内，重点把流程讲完整，留时间给追问（Filter vs Interceptor、参数绑定细节等）
- **如果面试官打断**：说完"七步流程 + DispatcherServlet 职责"即可停，这是核心；注解和对比是加分项
- **遇到追问如何应对**：追问到 WebFlux 等冷门点，可以回答"我了解 WebFlux 是响应式框架，但主要用 Spring MVC 做业务开发，两者定位不同"——展示知识面但不强行装懂


---

> 📋 **分类**: spring
> 🏷️ **标签**: `Spring`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-09 02:58:14
