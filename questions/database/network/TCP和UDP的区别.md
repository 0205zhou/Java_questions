---
id: q0054
question: "TCP和UDP的区别"
category: network
tags: [TCP, UDP, 网络协议]
difficulty: medium
created: 2026-08-18 00:00:00
source: 用户输入
---

# TCP和UDP的区别

## 🧠 联想记忆法

### 记忆口诀/联想

**口诀：TCP 像打电话，UDP 像发传单。**

- **TCP**（Transmission Control Protocol，传输控制协议）像打电话：先建立连接，再确认对方有没有收到，通话中还会纠错、重传、按顺序说话。
- **UDP**（User Datagram Protocol，用户数据报协议）像发传单：直接把内容扔出去，尽力而为，收不收得到、顺不顺序都不管。

### 记忆原理

这道题的本质是记住两组对立能力：**可靠性 vs 速度**、**面向连接 vs 无连接**。把 TCP 想成“需要仪式感的正式沟通”，把 UDP 想成“追求即时性的广播”。一旦联想到“打电话”和“发传单”，三次握手、确认重传、流量控制、拥塞控制这些 TCP 特性就会自然浮现出来。

### 关联知识

- 与 **三次握手、四次挥手** 关联
- 与 **HTTP/HTTPS** 关联：HTTP 底层通常跑在 TCP 上
- 与 **实时音视频、DNS、直播** 关联：这类场景常优先 UDP

## 📖 深度解答

### 核心概念

TCP 和 UDP 都是 **传输层协议（Transport Layer Protocol）**，负责把应用层数据从一台主机送到另一台主机。但它们的设计目标不同：

- **TCP** 追求可靠传输，保证“到、全、序、稳”
- **UDP** 追求传输效率和低延迟，允许少量丢包

### 底层原理

#### 1. 连接方式不同

TCP 是 **面向连接（Connection-oriented）** 的，通信前要先建立连接。连接建立后，双方维护状态，后续数据就像“有专属通道”一样传输。

UDP 是 **无连接（Connectionless）** 的，发送前不需要建立连接，拿到目的地址就直接发。

#### 2. 可靠性不同

TCP 通过下面机制保证可靠：

- **序列号**：保证数据按序到达
- **确认应答（ACK）**：收到后回执
- **重传机制**：丢包就重发
- **流量控制**：避免把接收方撑爆
- **拥塞控制**：避免把网络打爆

UDP 不做这些事，它只负责尽最大努力发送。

#### 3. 传输效率不同

TCP 头部更大，协议状态更多，开销也更高；UDP 头部只有 8 字节，协议更轻，所以延迟低、吞吐切换快。

#### 4. 顺序性不同

TCP 保证字节流有序；UDP 不保证顺序，后发的数据可能先到。

### 实践应用

#### TCP 适合

- 网页请求（HTTP/HTTPS）
- 文件传输
- 邮件
- 数据库连接

#### UDP 适合

- 语音通话
- 视频直播
- 在线游戏
- DNS 查询

#### 代码示例

```java
// TCP 示例：Socket 客户端（简化）
Socket socket = new Socket("127.0.0.1", 8080);
OutputStream out = socket.getOutputStream();
out.write("hello tcp".getBytes(StandardCharsets.UTF_8));
out.flush();

// UDP 示例：DatagramSocket 客户端（简化）
DatagramSocket datagramSocket = new DatagramSocket();
byte[] data = "hello udp".getBytes(StandardCharsets.UTF_8);
DatagramPacket packet = new DatagramPacket(
        data, data.length, InetAddress.getByName("127.0.0.1"), 9090);
datagramSocket.send(packet);
```

### 深入思考

- **TCP 不一定“永远更好”**：如果业务可以容忍少量丢包，UDP 往往更快、更省状态。
- **UDP 也可以做可靠性增强**：比如应用层自己加序号、重传、确认。
- **面试回答最好落到场景**：
  - 强一致、不能丢：TCP
  - 低延迟、允许抖动：UDP

## 🗺️ 回答思路

1. 先说两者都属于传输层协议。
2. 再从“连接方式、可靠性、效率、顺序性”四个维度对比。
3. 最后补场景：TCP 用于可靠传输，UDP 用于实时传输。
4. 如果追问，补三次握手、重传、流量控制、拥塞控制。
