---
id: q0105
question: "Nginx的作用？"
category: network
tags: ["Nginx", "反向代理", "负载均衡", "静态资源", "网关"]
difficulty: medium
created: 2026-09-05 09:00:00
source: 用户输入
---

# Nginx的作用？

## 联想记忆法

### 记忆口诀/联想

**口诀：前门接请求，后门转服务；静态自己发，动态代理走；还能做均衡、缓存和安全。**

把 Nginx 想成系统入口处的“总服务台”：

- 用户先把请求交给 Nginx。
- 静态文件由 Nginx 直接返回。
- 动态请求转发给后面的 Java、Go 或 Node.js 服务。
- 多台后端服务之间由 Nginx 分配流量。
- HTTPS、域名、限流、缓存和日志也可以集中处理。

### 记忆原理

Nginx 的作用可以按请求路径记忆：**接入 → 判断 → 处理或转发 → 保护 → 记录**。先把它放在客户端和业务服务之间，再理解反向代理、负载均衡和网关能力，就不会把 Nginx 只记成“部署静态网页的工具”。

### 关联知识

- 正向代理与反向代理。
- HTTP、HTTPS、WebSocket 和 TCP/UDP 代理。
- 负载均衡、健康检查、服务发现和故障转移。
- CDN、缓存、限流、灰度发布和微服务网关。
- Linux 下的配置检查、平滑 reload 和日志排障。

---

## 深度解答

### 第一层：核心概念

Nginx（Engine X）是一个高性能的事件驱动网络服务器。它最常见的角色是 HTTP Web 服务器和反向代理，同时也可以提供静态文件服务、负载均衡、内容缓存、HTTPS 终止、TCP/UDP 代理以及邮件代理等能力。

在典型 Java Web 系统中，Nginx 位于客户端和应用服务之间：

```text
浏览器 / App
      |
      | HTTP / HTTPS
      v
    Nginx
   /  |  \
  /   |   \
前端  API1 API2
静态  Java Java
资源  服务 服务
```

因此，Nginx 本身不一定承载核心业务逻辑。它更像一个高性能的流量入口，负责把请求正确、稳定、安全地送到合适的位置。

### 第二层：Nginx 的主要作用

#### 1. 作为 Web 服务器提供静态资源

Nginx 可以直接读取并返回 HTML、CSS、JavaScript、图片、字体和下载文件等静态资源。相比让 Java 应用线程处理大量静态文件，Nginx 更适合做这类简单、高并发、低计算量的工作。

```nginx
server {
    listen 80;
    server_name example.com;

    location / {
        root /var/www/frontend;
        index index.html;
    }
}
```

前端项目构建后通常会生成 `dist` 或 `build` 目录，把该目录交给 Nginx 服务即可。Nginx 还可以通过 `expires`、`Cache-Control` 等响应头帮助浏览器缓存静态资源。

#### 2. 作为反向代理

反向代理（Reverse Proxy）是 Nginx 最核心的用途之一。客户端只访问 Nginx，不需要知道后端应用的真实地址；Nginx 根据域名、路径和请求规则把请求转发到后端服务。

```nginx
server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

反向代理带来的价值包括：

- 隐藏后端服务的真实地址和端口。
- 统一入口，客户端不需要感知内部服务拓扑。
- 统一处理域名、HTTPS、请求头和日志。
- 让后端应用只关注业务，而不用直接暴露在公网。
- 可以根据 URL 路径把请求路由到不同服务。

例如：

```text
/          -> 前端静态目录
/api/      -> 用户服务
/order/    -> 订单服务
/upload/   -> 文件服务
```

#### 3. 实现负载均衡

当一个服务有多个实例时，Nginx 可以把请求分发到不同后端，提升吞吐量和可用性。

```nginx
upstream order_service {
    server 10.0.0.11:8080;
    server 10.0.0.12:8080;
    server 10.0.0.13:8080;
}

server {
    listen 80;

    location /order/ {
        proxy_pass http://order_service;
    }
}
```

常见负载均衡方式包括：

- **轮询（Round Robin）**：按顺序把请求分给各个实例，配置简单。
- **加权轮询（Weight）**：性能更强的机器获得更多请求。
- **最少连接（Least Connections）**：优先选择当前连接数较少的实例。
- **IP Hash**：根据客户端 IP 选择相对固定的后端，适合部分需要会话粘性的场景。

负载均衡不是简单地“平均分发”。如果后端服务处理时间差异很大，轮询可能导致慢实例积压；如果使用 IP Hash，客户端 IP 变化、NAT 和节点下线也可能造成分布不均。实际方案要结合会话设计、连接数、响应时间和故障恢复策略。

#### 4. 作为 HTTPS 终止层

Nginx 可以在入口处配置 TLS 证书，完成 HTTPS 握手和加解密，再通过内网 HTTP 或 HTTPS 转发给后端。

```nginx
server {
    listen 443 ssl;
    server_name example.com;

    ssl_certificate     /etc/nginx/cert/example.crt;
    ssl_certificate_key /etc/nginx/cert/example.key;

    location / {
        proxy_pass http://backend;
    }
}
```

这样做的好处是证书和 TLS 配置集中管理，后端服务不必重复配置证书。生产环境还要考虑 TLS 版本、密码套件、证书续期、HSTS、敏感请求头和真实客户端协议的传递。

需要注意：HTTPS 终止后，如果 Nginx 到后端使用明文 HTTP，内网链路仍需满足安全边界；对于跨机房、零信任或敏感数据场景，也可以继续使用 HTTPS 或 mTLS。

#### 5. 作为网关入口

Nginx 可以按照域名、路径、请求方法、请求头等条件做基础路由，承担一部分网关职责：

- 统一入口和域名管理。
- 请求转发与路径重写。
- 访问控制和基础认证。
- 限制请求体大小和请求速率。
- 设置跨域响应头。
- 统一记录访问日志和上游耗时。
- 连接后端服务并隐藏内部拓扑。

不过，Nginx 的能力边界要和专业 API Gateway 区分。复杂的动态路由、服务注册发现、细粒度鉴权、插件生态和业务级限流，可能更适合 Spring Cloud Gateway、APISIX、Kong 等方案。Nginx 可以做入口，但不意味着所有网关逻辑都应该写进 Nginx 配置。

#### 6. 提供缓存和压缩

对于变化不频繁的公开资源或上游响应，Nginx 可以做缓存，减少后端服务压力。对文本资源启用 gzip 或 Brotli，也能减少网络传输量。

```nginx
gzip on;
gzip_types text/plain text/css application/json application/javascript;

location /static/ {
    root /var/www/frontend;
    expires 7d;
}
```

缓存必须明确失效策略。带有用户身份、权限或实时状态的响应不能简单地全局缓存，否则可能出现数据泄露或读到旧数据。前端静态资源通常采用文件名加 hash 的方式解决长期缓存后的版本更新问题。

#### 7. 支持 WebSocket 和 TCP/UDP 代理

Nginx 可以代理 WebSocket，但需要显式传递升级相关请求头：

```nginx
location /chat/ {
    proxy_pass http://chat_backend;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

对于 TCP/UDP 服务，也可以使用 stream 模块做四层代理。四层代理通常只关心连接和字节流，不理解 HTTP 路径、Cookie 或 JSON 内容；七层 HTTP 代理则能基于请求内容做更细的路由。

### 第三层：一次请求的处理流程

一个经过 Nginx 的 HTTP 请求，大致会经历：

```text
客户端建立连接
  -> Nginx 接收请求
  -> 根据 listen 和 server_name 选择 server
  -> 根据 URI 匹配 location
  -> 返回静态资源或转发给 upstream
  -> 读取上游响应
  -> 添加响应头、压缩或缓存
  -> 返回客户端并记录日志
```

Nginx 采用事件驱动的处理方式，一个 worker 可以管理大量连接。它擅长处理连接、网络 IO 和简单转发，但不适合在配置层实现复杂业务计算。后端应用如果执行长时间任务，仍然要使用异步任务、消息队列或专用服务，不能指望 Nginx 替代业务线程池。

### 第四层：常用配置与运维命令

常见配置结构：

```nginx
events {
    worker_connections 1024;
}

http {
    upstream app {
        server 127.0.0.1:8080;
    }

    server {
        listen 80;
        server_name example.com;

        location / {
            proxy_pass http://app;
        }
    }
}
```

修改配置后，建议先检查语法，再平滑加载：

```bash
nginx -t
nginx -s reload
```

常见排查路径：

```bash
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
curl -I http://127.0.0.1/
curl -v http://127.0.0.1/api/health
ss -lntp
```

如果出现 502，重点检查 Nginx 是否能连接上游、上游端口是否监听、应用是否启动以及防火墙规则。如果出现 504，重点检查上游响应是否超时、后端线程池是否耗尽、数据库或下游服务是否变慢。不能只看到 Nginx 返回码就断定是 Nginx 本身故障。

### 第五层：深入思考

#### Nginx 和 Tomcat 的关系

Nginx 主要负责连接接入、静态资源和反向代理；Tomcat 负责运行 Java Web 应用。常见部署方式是 Nginx 在前、Tomcat 在后：

```text
用户 -> Nginx -> Tomcat / Spring Boot -> MySQL / Redis
```

Nginx 不是 Tomcat 的替代品，Tomcat 也不是 Nginx 的替代品。前者擅长网络入口和转发，后者擅长执行 Java Servlet、过滤器、控制器和业务代码。

#### Nginx 不能自动解决所有高并发问题

Nginx 可以减少连接和静态资源压力，但后端数据库、缓存、线程池、消息队列和业务锁仍可能成为瓶颈。增加 Nginx 实例也不能自动解决慢 SQL、缓存击穿或服务内部锁竞争。

#### 反向代理的真实 IP

经过多层代理后，后端看到的 TCP 对端通常是 Nginx。要传递真实客户端 IP，需要使用 `X-Real-IP`、`X-Forwarded-For` 等请求头，同时必须只信任可信代理写入的头，不能无条件相信客户端自己提交的 IP。

## 回答思路

### 答题逻辑框架

1. 先定义 Nginx：高性能 Web 服务器和反向代理。
2. 按“静态资源、反向代理、负载均衡、HTTPS、缓存、网关”展开。
3. 用请求链路图说明 Nginx 在系统中的位置。
4. 补充 WebSocket、TCP/UDP 代理和常用运维命令。
5. 最后说明 Nginx 和 Tomcat 的分工，以及 502/504 的排查方向。

### 重点得分点

- 能说清正向代理和反向代理的区别。
- 能解释 upstream、proxy_pass 和负载均衡策略。
- 能说明 Nginx 为什么适合静态资源和连接转发。
- 能讲出 HTTPS 终止、真实 IP、缓存和 WebSocket 配置。
- 能区分 Nginx、Tomcat 和专业 API Gateway 的职责边界。

### 常见误区

- 误区 1：Nginx 只是用来部署前端静态页面。  
  正解：它还常用于反向代理、负载均衡、HTTPS、缓存和网关入口。

- 误区 2：配置了 upstream 就能保证服务高可用。  
  正解：还要考虑健康检查、故障摘除、重试、连接超时和后端本身的容量。

- 误区 3：Nginx 返回 502 一定是 Nginx 挂了。  
  正解：通常应先检查上游连接、端口、进程和应用日志。

- 误区 4：把所有业务鉴权和复杂逻辑都写进 Nginx 配置。  
  正解：Nginx 适合流量治理，复杂业务规则应放在应用或专业网关。

### 面试话术

“Nginx 在系统中通常作为高性能入口，主要承担静态资源服务、反向代理和负载均衡，也可以集中处理 HTTPS、缓存、压缩、限流、WebSocket 和 TCP/UDP 代理。典型链路是客户端先访问 Nginx，Nginx 根据域名和路径把请求直接返回或转发给后端服务。它和 Tomcat 是分工关系：Nginx 负责接入和转发，Tomcat 或 Spring Boot 负责执行业务代码。线上排障时，我会结合 `nginx -t`、访问日志、错误日志、上游端口和应用监控判断问题到底在入口还是后端。”

---

> 📋 **分类**: network
> 🏷️ **标签**: `Nginx` `反向代理` `负载均衡` `静态资源` `网关`
> 📊 **难度**: 中级
> 📅 **归档时间**: 2026-09-05 09:00:00
