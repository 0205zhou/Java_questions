---
id: q0085
question: "SpringMVC执行流程"
category: spring
tags: ["SpringMVC", "DispatcherServlet", "请求流程", "Web"]
difficulty: medium
created: 2026-08-27 09:48:00
source: 用户输入
---

# SpringMVC执行流程

## 联想记忆法

### 记忆口诀/联想

**口诀：门卫先接单，路由找方法，适配去执行，视图来收尾。**

把 Spring MVC 想成一个工单流转系统：

- **门卫** = `DispatcherServlet`，统一接收请求。
- **路由** = `HandlerMapping`，根据 URL 找到处理方法。
- **适配** = `HandlerAdapter`，真正调用 Controller。
- **收尾** = `ViewResolver` / `HttpMessageConverter` / `HandlerExceptionResolver`，分别负责视图、JSON 和异常处理。

### 记忆原理

Spring MVC 的执行流程不是零散的“注解生效”，而是一个**前端控制器统一调度**的流水线。只要记住“入口、路由、执行、结果处理”四个阶段，就能把整个流程串起来。

### 关联知识

- `DispatcherServlet` 是 Spring MVC 的核心入口，本质上也是一个 Servlet。
- `@RestController` 返回 JSON 时，流程会走消息转换器而不是视图解析器。
- `HandlerInterceptor` 插在 Controller 前后，`Filter` 则更早进入请求链。

## 深度解答

### 第一层：核心概念

Spring MVC 的执行流程，本质上是**一次 HTTP 请求在 Spring Web 层内部的分发、适配、执行和结果处理过程**。

如果把它压缩成一句话：

**客户端请求先进入 `DispatcherServlet`，再由 `HandlerMapping` 找到目标方法，由 `HandlerAdapter` 执行控制器，最后根据返回值走视图解析、消息转换或异常处理。**

这套设计的关键点是“**职责拆分**”：

- 入口统一。
- 路由统一。
- 调用统一。
- 结果处理统一。

所以开发者只需要关心 Controller 里的业务逻辑，不必手动写大量 Servlet 分发代码。

### 第二层：完整执行流程

#### 1. 请求进入 Servlet 容器

浏览器或前端程序发起 HTTP 请求后，Tomcat 等 Servlet 容器先接收请求。请求会先经过 `Filter` 链，再进入 Spring MVC 的前端控制器 `DispatcherServlet`。

#### 2. `DispatcherServlet` 接收并分发

`DispatcherServlet` 是整个流程的总入口，核心方法是 `doDispatch`。它不会直接执行业务，而是负责协调后续组件。

#### 3. `HandlerMapping` 找到处理器

`HandlerMapping` 根据请求路径、HTTP 方法、请求头等条件，找到对应的 Handler。对于注解方式的 Spring MVC，常见实现是 `RequestMappingHandlerMapping`。

这一步还会拿到拦截器链 `HandlerExecutionChain`，也就是后续要执行的 `HandlerInterceptor`。

#### 4. `HandlerAdapter` 调用 Controller

Spring 并不会直接调用某个固定类型的处理器，而是通过 `HandlerAdapter` 适配不同的 Handler。对于注解控制器，常见实现是 `RequestMappingHandlerAdapter`。

它负责：

- 绑定请求参数。
- 做类型转换。
- 触发参数校验。
- 调用 Controller 方法。

#### 5. Controller 执行业务逻辑

Controller 完成业务编排后，会返回结果。这个结果可能是：

- `ModelAndView`
- 视图名字符串
- `@ResponseBody` 对象
- `ResponseEntity`
- 异常

#### 6. 结果处理

如果是传统页面返回，`DispatcherServlet` 会通过 `ViewResolver` 把视图名解析成真正的 `View`，再把 `Model` 数据渲染到页面。

如果是 REST 接口，返回对象会交给 `HttpMessageConverter` 序列化为 JSON、XML 等内容，直接写入响应体，不再走视图解析。

#### 7. 异常处理与返回

如果流程中抛出异常，Spring MVC 会交给 `HandlerExceptionResolver` 处理。可以通过 `@ExceptionHandler`、`@ControllerAdvice` 等机制统一转成友好的错误响应。

### 第三层：流程图

```text
客户端请求
   ↓
Servlet Filter
   ↓
DispatcherServlet
   ↓
HandlerMapping
   ↓
HandlerInterceptor.preHandle
   ↓
HandlerAdapter
   ↓
Controller
   ↓
HandlerInterceptor.postHandle / afterCompletion
   ↓
ViewResolver 或 HttpMessageConverter
   ↓
响应返回
```

### 第四层：两条常见返回路径

#### 1. 返回页面

```java
@Controller
public class PageController {
    @GetMapping("/home")
    public String home(Model model) {
        model.addAttribute("name", "Tom");
        return "home";
    }
}
```

这时返回值 `home` 会被当成视图名，`ViewResolver` 负责找到对应的 JSP、Thymeleaf 或其他模板，再把 `Model` 渲染到页面。

#### 2. 返回 JSON

```java
@RestController
public class UserController {
    @GetMapping("/users/{id}")
    public User getUser(@PathVariable Long id) {
        return userService.findById(id);
    }
}
```

`@RestController` 或 `@ResponseBody` 会让返回值进入消息转换器流程，Spring 根据 `Content-Type` 和返回类型选择合适的 `HttpMessageConverter`，例如 Jackson 转 JSON。

### 第五层：拦截器、过滤器和异常处理

#### Filter

Filter 属于 Servlet 规范，位置更靠前，常用于编码、跨域、日志、统一鉴权的入口处理。

#### Interceptor

Interceptor 属于 Spring MVC，更贴近 Controller 执行过程，适合登录校验、权限判断、耗时统计、模型补充。

#### Exception Resolver

异常解析器负责把业务异常、参数异常、系统异常转换成统一响应，避免 Controller 中到处写 `try-catch`。

这三者配合起来，Spring MVC 才能把“请求进入”到“结果返回”做成可插拔的流水线。

### 第六层：源码视角

`DispatcherServlet.doDispatch()` 的核心思路可以简化成：

```java
HandlerExecutionChain chain = getHandler(request);
HandlerAdapter adapter = getHandlerAdapter(chain.getHandler());
ModelAndView mv = adapter.handle(request, response, chain.getHandler());
processDispatchResult(request, response, chain, mv, ex);
```

这段代码表达了 Spring MVC 的设计哲学：**先找路，再执行，再统一收尾**。

### 第七层：深入思考

Spring MVC 的流程之所以稳定，是因为它把变化点都抽象成接口：HandlerMapping 可以替换，HandlerAdapter 可以扩展，ViewResolver 可以多种实现，消息转换器也可以按需注册。这样，框架核心流程不变，但业务形态可以从 JSP 页面、REST JSON 一直扩展到文件下载、WebSocket 升级和异步请求。

实际面试时，最容易被追问的是：

1. `HandlerMapping` 和 `HandlerAdapter` 的区别。
2. `@RestController` 为什么不走视图解析。
3. Filter、Interceptor、AOP 的执行顺序。
4. `DispatcherServlet` 为什么是 Spring MVC 的核心。

只要能把这四个问题和主流程串起来，Spring MVC 这道题就算答得比较完整。

## 回答思路

### 答题逻辑框架

1. 先给总流程一句话：请求进 `DispatcherServlet`，再经过路由、适配、执行和结果处理。
2. 再按步骤展开：Filter、DispatcherServlet、HandlerMapping、HandlerAdapter、Controller、结果处理。
3. 区分页面返回和 JSON 返回两条分支。
4. 补充拦截器、异常解析器和源码中的 `doDispatch`。
5. 最后说明 Spring MVC 的设计思想是“统一入口 + 分层解耦”。

### 重点得分点

- 说清楚 `HandlerMapping` 负责找方法，`HandlerAdapter` 负责执行方法。
- 说清楚 `@RestController` 返回对象走消息转换器，不走视图解析。
- 说清楚 Filter 在最前，Interceptor 在 Controller 前后，AOP 是方法增强。
- 说清楚异常可以交给 `HandlerExceptionResolver` 或全局异常处理。
- 能把 `DispatcherServlet` 解释成 Spring MVC 的前端控制器。

### 常见误区

- 认为 `DispatcherServlet` 直接执行业务；它只是协调分发。
- 认为 `HandlerMapping` 负责调用 Controller；它只负责找处理器。
- 认为 `@RestController` 只是少写一个注解；本质是返回值处理链不同。
- 认为拦截器和过滤器是一个层次；它们处在不同阶段。

### 面试话术

“Spring MVC 的执行流程可以概括为：请求先经过 Filter，再进入 DispatcherServlet；DispatcherServlet 通过 HandlerMapping 找到处理器和拦截器链，再通过 HandlerAdapter 调用 Controller；Controller 返回后，如果是页面就走 ViewResolver 渲染，如果是 REST 接口就走 HttpMessageConverter 转成 JSON；异常则交给 HandlerExceptionResolver 统一处理。它的核心思想就是统一入口、分层解耦。”

### 时间分配建议

- 20 秒：总流程一句话。
- 50 秒：按步骤讲清楚请求如何进入和执行。
- 30 秒：页面返回与 JSON 返回的分支。
- 20 秒：Filter、Interceptor、异常处理和源码视角。

---

> 📋 **分类**: spring
> 🏷️ **标签**: `SpringMVC` `DispatcherServlet` `请求流程` `Web`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-27 09:48:00
