# Spring MVC 是什么

> 类型:Spring 框架
> 提问频率:⭐⭐⭐⭐⭐

---

## S (Situation) — 背景

在传统 Servlet 开发中,写一个接口非常繁琐:

- 每个请求都要手动解析请求参数、处理编码、分发到不同业务、渲染视图
- 请求接收、业务处理、视图渲染耦合在一起,代码大量重复
- 难以单元测试,难以扩展
- 需要一个基于 **MVC 设计模式** 的框架来解耦这些职责

## T (Task) — 要解决的问题

让开发者**只需要关注 Controller 里的业务逻辑**,框架统一完成:

- 请求的接收与分发
- 参数的自动绑定
- 视图的解析与渲染

## A (Action) — 解决方案

### 1. 定义

**Spring MVC 是基于 Servlet API 实现的、遵循 MVC(Model-View-Controller)设计模式的 Web 框架**,是 Spring 框架的一部分:

- **Model(模型)**:业务数据和业务逻辑
- **View(视图)**:页面展示层
- **Controller(控制器)**:接收请求、调用模型、返回视图

### 2. 核心组件

| 组件 | 职责 |
|---|---|
| **DispatcherServlet** | 前端控制器,统一接收所有请求并分发,是核心中的核心 |
| **HandlerMapping** | 根据 URL 找到对应的 Handler(Controller 方法) |
| **HandlerAdapter** | 适配并调用 Handler,处理参数绑定 |
| **Controller** | 真正执行业务逻辑的地方 |
| **ModelAndView** | 封装模型数据 + 视图名 |
| **ViewResolver** | 根据视图名解析出真正的 View(如 JSP、Thymeleaf) |
| **View** | 渲染数据,输出响应 |

### 3. 完整执行流程(必须背下来)

```
① 客户端发送请求
        ↓
② DispatcherServlet 接收请求
        ↓
③ DispatcherServlet 通过 HandlerMapping 找到对应的 Handler(Controller 方法)
        ↓
④ 通过 HandlerAdapter 调用 Controller 方法(自动完成参数绑定)
        ↓
⑤ Controller 执行完业务,返回 ModelAndView
        ↓
⑥ DispatcherServlet 通过 ViewResolver 解析视图名,得到 View
        ↓
⑦ View 渲染模型数据,返回响应给客户端
```

### 4. 常用注解

- `@Controller` / `@RestController` — 声明控制器(RestController = Controller + ResponseBody)
- `@RequestMapping` — 映射 URL 与请求方式(GET/POST/PUT/DELETE)
- `@PathVariable` — 从 URL 路径中取参数(`/user/{id}`)
- `@RequestParam` — 从查询参数中取参数
- `@RequestBody` — 从请求体中取 JSON 并反序列化为对象

### 5. 与 Spring Boot 的关系

- Spring Boot 的 `spring-boot-starter-web` 内置 Tomcat,自动装配 DispatcherServlet
- 开发者无需配置 web.xml,写一个 `@RestController` 就能暴露接口

## R (Result) — 效果

- **关注点分离**:参数绑定、请求分发、视图解析全部交给框架,开发者只写业务
- **易于测试**:Controller 可脱离容器独立单元测试(MockMvc)
- **扩展性强**:HandlerMapping、HandlerAdapter、ViewResolver 都可自定义替换
- 成为 Java Web 开发的事实标准,被 Spring Boot 完全继承

---

## 💡 追问点速背

1. **DispatcherServlet 是单例吗?** → 是,一个应用只有一个
2. **@RestController 和 @Controller 区别?** → RestController = Controller + ResponseBody,返回 JSON 而非视图
3. **Spring MVC 和 Struts2 的区别?** → Spring MVC 方法级拦截、单例、更轻量;Struts2 类级拦截、多例
4. **请求乱码怎么处理?** → 配置 CharacterEncodingFilter(UTF-8)
5. **静态资源怎么处理?** → 放 static 目录或配置 ResourceHandler,交给默认 Servlet
