---
id: q0021
question: "String、StringBuffer、StringBuilder的区别"
category: java
tags: []
difficulty: medium
created: 2026-08-12 00:46:54
source: 用户输入
---

# String、StringBuffer、StringBuilder的区别

# String、StringBuffer、StringBuilder 的区别

---

## 联想记忆法

### 记忆口诀/联想

**口诀:"老大 String 不变定终身,老二 Buffer 带锁慢慢拼,老三 Builder 无锁跑得快"**

把三者想象成一家三兄弟:

- **老大 String**:性格"死板",出生后**内容不可变**,任何修改都是"重新生成一个新对象"(造个新的字帖,旧的不动)
- **老二 StringBuffer**:做事**稳重**,在原来的字帖上改,但每次动笔前都**先锁上门**(线程安全),所以慢一点
- **老三 StringBuilder**:手脚**最快**,也在原字帖上改,但**不锁门**(线程不安全),单线程下性能最好

三个关键维度串起来记:**可变性 → 线程安全 → 性能**,对应三兄弟的特征 "定终身 / 带锁 / 无锁"。

### 记忆原理

用"三兄弟性格对比"的**人物化联想**,把三个抽象类变成三个有性格的人:老大不变(不可变),老二谨慎(加锁),老三冒进(无锁)。面试时只要想起"三兄弟",就能按 **不可变性 → 线程安全性 → 性能** 三个维度依次展开对比,天然构成答题的"三段式"结构,不会漏点。同时用"重新造 vs 原地改"这个生活化比喻,区分 String 与其他两者的本质差异。

### 关联知识

- **与 String 常量池关联**:String 不可变是常量池(Constant Pool)得以存在的前提——值不变才能安全共享;`intern()` 方法把运行时字符串手动放入常量池
- **与 final 关键字关联**:String 类被 `final` 修饰、底层数组被 `final` 修饰,是"不可变类(Immutable Class)"的教科书案例,与 Integer 等包装类同一设计
- **与 synchronized 关联**:StringBuffer 的线程安全靠方法上加 `synchronized` 实现,是"粗粒度锁"的代表,可与 ConcurrentHashMap 的"细粒度锁"对比
- **与编译器优化关联**:`"a" + "b"` 在编译期会被直接拼接成 `"ab"`(常量折叠),变量拼接则被优化为 `StringBuilder.append()`,这是"字节码层面的最佳实践"

---

## 深度解答

### 第一层:核心概念

#### 三者是什么

| 类 | 可变性 | 线程安全 | 性能 | 典型场景 |
|---|---|---|---|---|
| String | **不可变**(Immutable) | 天然安全(不可变即无状态竞争) | 拼接需创建新对象,**最差** | 不频繁修改的字符串、常量、key |
| StringBuffer | **可变** | **安全**(方法加 synchronized) | 比 String 好,比 StringBuilder 略差 | 多线程环境下的字符串拼接 |
| StringBuilder | **可变** | **不安全** | **最好** | 单线程环境下的字符串拼接(绝大多数场景) |

#### 一个核心区别:变与不变

- **String**:对象一旦创建,其值不能修改。`s = s + "x"` 不是"修改了原来的 s",而是**创建了一个新的 String 对象**并让引用指向它,原对象仍留在内存中等待 GC
- **StringBuffer / StringBuilder**:内部是**可变字符数组**,`append()` 直接在原数组上追加,不产生新对象

```java
String s = "hello";
s = s + " world";      // 产生新对象 "hello world",原 "hello" 成为垃圾

StringBuilder sb = new StringBuilder("hello");
sb.append(" world");   // 原地修改,无新对象产生
```

---

### 第二层:底层原理

#### String 为什么不可变

源码层面三重保障(JDK8):

```java
public final class String                     // ① 类被 final 修饰,禁止继承
    implements java.io.Serializable, ... {
    private final char[] value;               // ② 底层数组被 final 修饰
    private int hash;                         // ③ hash 缓存,无 setter 暴露修改
    ...
}
```

不可变带来的好处(这也是面试追问点):

- **线程安全**:不可变对象天然可被多线程共享,无需加锁
- **常量池共享**:值不变才能安全复用,相同字面量共享同一对象,节省内存
- **hash 缓存**:String 常作为 HashMap 的 key,不可变使 hash 只需计算一次(JDK8 起 `hash` 字段做缓存)
- **安全性**:参数传递不会因为被下游修改而"被篡改",网络地址、类名等系统底层大量使用 String

#### StringBuilder/StringBuffer 的实现与扩容

两者都继承自 `AbstractStringBuilder`(可变字符数组):

```java
abstract class AbstractStringBuilder {
    char[] value;      // 可变数组
    int count;         // 已用长度
}
```

- **追加**:`append()` 先检查容量,不够则 `ensureCapacityInternal()` 扩容
- **扩容机制**:新容量 = `(旧容量 + 1) * 2`,仍不够则直接取所需长度;通过 `Arrays.copyOf()` 拷贝到新数组
- **区别只在锁**:StringBuffer 的每个修改方法都加 `synchronized`,StringBuilder 不加

```java
// StringBuffer 源码(加了锁)
public synchronized StringBuffer append(String str) {
    super.append(str);
    return this;
}
```

#### 编译器的自动优化

**编译期常量折叠**:字面量拼接在编译期就完成:

```java
String a = "a" + "b";   // 编译期直接变成 "ab",不会 new 对象
```

**运行时优化**:变量拼接在 JDK5+ 被编译为 StringBuilder 调用(JDK9+ 用 `makeConcatWithConstants` 指令,本质仍是类似 StringBuilder 的 builder 机制):

```java
String a = "a";
String b = "b";
String c = a + b;       // 等价于 new StringBuilder(a).append(b).toString()
```

所以**循环内拼接必须手动用 StringBuilder**——否则每轮循环都 new 一个 StringBuilder:

```java
// ❌ 错误:每轮循环都创建新 StringBuilder 和新 String
String s = "";
for (int i = 0; i < 1000; i++) {
    s = s + i;
}

// ✅ 正确:复用同一个 builder
StringBuilder sb = new StringBuilder();
for (int i = 0; i < 1000; i++) {
    sb.append(i);
}
String s = sb.toString();
```

---

### 第三层:实践应用

#### 选择标准(一句话版)

- 单线程、频繁修改 → **StringBuilder**(默认选择)
- 多线程、频繁修改 → **StringBuffer**
- 不修改、只读复用 → **String**

#### 代码示例

```java
// 1. 单线程高频拼接 → StringBuilder
StringBuilder sb = new StringBuilder();
for (int i = 0; i < 100; i++) sb.append(i);

// 2. 多线程环境 → StringBuffer
StringBuffer buffer = new StringBuffer();   // 方法自带同步,无需外部加锁

// 3. 初始化指定容量,避免扩容开销
StringBuilder sb2 = new StringBuilder(1024);

// 4. 字符串比较必须用 equals,不是 ==
String x = new String("a");
String y = new String("a");
x == y;        // false:地址不同
x.equals(y);   // true:内容相同
```

#### 最佳实践

- **预估长度时指定初始容量**,避免频繁扩容的数组拷贝开销
- 字符串的 **toString() 返回前**(如实体类)也可缓存,避免重复构建
- 服务端接收外部字符串常量时优先复用 String 字面量/常量池,节省内存

---

### 第四层:深入思考

#### 追问 1:StringBuffer 与 StringBuilder 性能差距大吗?

**不大。** synchronized 在 JDK6 之后引入了**偏向锁(Biased Locking)**,单线程反复执行时锁开销几乎为 0。差距主要在竞争激烈时(锁升级为重量级锁)。所以:

- 单线程:无脑选 StringBuilder(没有锁成本,语义最清晰)
- 多线程:选 StringBuffer 或外部加锁 + StringBuilder(后者常更灵活)

#### 追问 2:为什么"不可变"是 String 的设计核心?

不可变是**常量池复用、线程安全、hash 缓存、系统安全**四个特性的共同前提,可以理解为"一票换四票"的设计取舍——牺牲修改能力,换取全局安全与共享。

#### 追问 3:可变字符串还有什么替代方案?

- `StringJoiner`(JDK8):带分隔符/前后缀的拼接,底层是 StringBuilder
- `String.join()`(JDK8):集合拼接的语法糖
- `CharBuffer` / 字符数组:极致的可变性控制,但易出错,一般不直接使用

---

## 回答思路

### 答题逻辑框架(约 1.5 分钟)

1. **一句话总起**:三者都是字符串载体,核心区别在"可变性、线程安全、性能"三个维度
2. **先说 String 不可变**:定义 + 底层(final 修饰)+ 每次修改产生新对象
3. **再对比 StringBuffer/StringBuilder**:都继承 AbstractStringBuilder、可变、原地修改;差异仅在 synchronized
4. **给结论**:单线程用 StringBuilder,多线程用 StringBuffer,只读用 String
5. **主动抛出加分点**:编译器对 "+" 的优化、循环拼接的陷阱、扩容机制、指定初始容量

### 重点得分点

- 准确说出 **String 不可变的底层保障**(final class + final char[])
- 准确说出 **StringBuffer 与 StringBuilder 唯一区别是 synchronized**
- 举出**循环内拼接**的正确与错误写法(体现实践能力)
- 能说出**不可变带来的四大好处**(线程安全/常量池/hash 缓存/安全)

### 常见误区

- ❌ 认为 `s = s + "x"` 修改了原字符串——实际是创建新对象,原对象等 GC
- ❌ 认为 StringBuffer 永远比 StringBuilder 慢很多——JDK6 后有偏向锁,单线程下差距极小
- ❌ 用 `==` 比较字符串内容——String 重写了 equals 比较内容,`==` 只比地址
- ❌ 混淆"字符串拼接用 + 就好"——循环内用 `+` 每轮都 new StringBuilder,性能灾难

### 过渡话术

- 答完 String 后:"String 有个致命缺点——不可变导致频繁修改时性能差,所以 JDK1.0 就有了 StringBuffer,JDK5 又加了不带锁的 StringBuilder……"(自然引出对比)
- 深入原理时:"不可变不仅是语法限制,更是设计选择,您知道它换来了什么吗?四件事——线程安全、常量池共享、hash 缓存、系统安全……"
- 收尾时:"最后补充一个实践细节:能预估长度就指定初始容量,能省掉多次数组扩容拷贝。"

### 时间分配建议

| 环节 | 时间 |
|---|---|
| 总起 + 三兄弟核心差异 | 20 秒 |
| String 不可变原理 + 源码依据 | 30 秒 |
| StringBuffer/StringBuilder 对比 + 扩容机制 | 30 秒 |
| 实践场景 + 代码示例(循环拼接) | 25 秒 |
| 追问延伸(性能差距/不可变好处) | 15 秒 |

---

> 📋 **分类**: java
> 🏷️ **标签**: 
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-12 00:46:54
