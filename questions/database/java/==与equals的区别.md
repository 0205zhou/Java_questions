---
id: q0023
question: "==与equals的区别"
category: java
tags: []
difficulty: medium
created: 2026-08-12 00:48:21
source: 用户输入
---

# ==与equals的区别

# == 与 equals 的区别

---

## 联想记忆法

### 记忆口诀/联想

**口诀:"== 比'值'还是比'址',基本类型比数值,引用类型比地址;equals 看实现,默认就是 ==,String 重写成内容"**

拆成三句记忆:

- **"== 看类型"**:基本类型比**数值**(内容),引用类型比**地址**(同一个对象)
- **"equals 看实现"**:Object 的默认实现就是 `==`(比地址),**谁重写就按谁的规则比**
- **"String 重写了"**:String、Integer 等都重写了 equals,比的是**内容**

### 记忆原理

用一个核心问题概括全题:**"比的是'同一个东西'还是'一样的东西'?"**——`==` 默认问"是不是同一个",equals 默认也是,但 String 们重写后问"是不是一样"。抓住"**默认相同、重写改变**"这 8 个字,所有分支都能推导出来:equals 没重写就跟 == 一样,重写了就按内容比。再把"引用类型与基本类型的 == 语义不同"作为补充锚点,两个维度(什么类型 / 用什么方法)交叉覆盖,不会漏。

### 关联知识

- **与 hashCode 约定关联**:重写 equals 必须重写 hashCode,否则 HashMap/HashSet 行为错乱——这是重写 equals 的第一道红线
- **与常量池关联**:`"a" == "a"` 为 true(常量池复用),`new String("a") == new String("a")` 为 false——"看似相同地址却不同"的经典例子
- **与包装类缓存关联**:`Integer a = 127; Integer b = 127; a == b` 为 true(-128~127 有 IntegerCache),128 就变 false——面试高频陷阱
- **与 Objects.equals 关联**:JDK7 的 `Objects.equals()` 已做 null 判断,是推荐实践

---

## 深度解答

### 第一层:核心概念

#### 两者是什么

- **`==`**:Java 的运算符(Operator),用于比较**两个操作数是否"相同"**
  - 基本类型:比较**数值**是否相等
  - 引用类型:比较**内存地址**是否相等(是否指向同一个对象)
- **equals**:Object 类的方法(Method),**默认实现等价于 `==`**,各子类可重写来自定义"相等"规则

```java
int a = 1, b = 1;
a == b;                      // true:基本类型比数值

String s1 = new String("hi");
String s2 = new String("hi");
s1 == s2;                    // false:两个不同对象,地址不同
s1.equals(s2);               // true:String 重写 equals,比内容
```

#### 核心区别一句话

**`==` 比"是不是同一个对象",equals 比"符不符合相等规则";equals 默认就是 `==`,只有重写后才不同。**

---

### 第二层:底层原理

#### Object.equals 的默认实现

```java
// java.lang.Object
public boolean equals(Object obj) {
    return (this == obj);    // 默认:就是比地址
}
```

所以对任何**没重写 equals** 的类(如自定义的实体类),`a.equals(b)` 与 `a == b` 完全等价。

#### String 如何重写 equals

```java
public boolean equals(Object anObject) {
    if (this == anObject) return true;         // 同一个对象,直接 true
    if (anObject instanceof String) {          // 类型不匹配直接 false
        String anotherString = (String) anObject;
        int n = value.length;
        if (n == anotherString.value.length) { // 先比长度,长度不同直接 false
            // 逐字符比较
            for (int i = 0; i < n; i++) {
                if (value[i] != anotherString.value[i]) return false;
            }
            return true;
        }
    }
    return false;
}
```

实现细节体现三个优化思想:**先比引用(最快) → 再比类型 → 再比长度 → 最后逐字符**。

#### 为什么 `==` 在基本类型和引用类型上语义不同

- 基本类型变量存的是**值本身**,所以 `==` 直接比数值
- 引用类型变量存的是**对象的地址(句柄/引用)**,所以 `==` 比的是"是否指向同一块内存"

#### 常量池与包装类缓存的影响

```java
String x = "a";          // 字面量 → 常量池
String y = "a";          // 复用常量池中已有对象
x == y;                  // true:同一对象

String x2 = new String("a");   // 强制 new,堆上新对象
String y2 = new String("a");   // 又一个新对象
x2 == y2;                // false

Integer i1 = 127, i2 = 127;    // 自动装箱,命中 IntegerCache(-128~127)
i1 == i2;                // true
Integer i3 = 128, i4 = 128;    // 超出缓存范围,各自 new
i3 == i4;                // false ← 高频陷阱
```

---

### 第三层:实践应用

#### 正确重写 equals 的规范(五条约定)

```java
public class User {
    private String name;
    private int age;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;                    // ① 自反:同对象直接 true
        if (o == null || getClass() != o.getClass()) return false;  // ② 非空 + 类型
        User user = (User) o;
        return age == user.age
                && Objects.equals(name, user.name);    // ③ 字段逐一比较(Objects 处理 null)
    }

    @Override
    public int hashCode() {                            // ④ 必须一起重写!
        return Objects.hash(name, age);
    }
}
```

五条约定的官方要求(Effective Java 第 11 条):

1. **自反性**:`x.equals(x)` 为 true
2. **对称性**:`x.equals(y)` 与 `y.equals(x)` 结果一致
3. **传递性**:`x.equals(y) && y.equals(z)` 则 `x.equals(z)`
4. **一致性**:对象不变时,多次调用结果一致
5. **非空性**:`x.equals(null)` 为 false

#### 为什么不重写 hashCode 会出问题

HashMap 的定位流程是"**先 hashCode 找桶,再 equals 比对象**":

```java
HashMap<User, String> map = new HashMap<>();
User u1 = new User("Tom", 20);
map.put(u1, "value");

User u2 = new User("Tom", 20);   // equals 与 u1 相同
map.get(u2);                     // 若未重写 hashCode:u2 的桶与 u1 不同 → 返回 null!
```

只重写 equals 不重写 hashCode,equals 相等但 hash 不同,哈希结构就"找不到"对象。

#### 日常比较的最佳实践

```java
// 字符串比较:永远用 equals(或 equalsIgnoreCase)
if ("admin".equals(input)) { ... }          // 推荐:常量在前,天然防空指针

// 需要 null 安全的比较
Objects.equals(a, b);                        // JDK7+:内部已处理 null

// 数字包装类比较:用 equals 或 compareTo
Integer m = 100, n = 100;
m.equals(n);                                 // true,正确做法
```

---

### 第四层:深入思考

#### 追问 1:重写 equals 用 `getClass()` 还是 `instanceof`?

- **`getClass() != o.getClass()`**:严格要求类型完全一致(子类与父类不相等),适合"数值/实体"类
- **`instanceof`**:允许子类对象参与比较(父类 equals 可被继承复用),适合"行为/接口"类,但需注意对称性可能被破坏
- 现代实践倾向于 `getClass()` + 组合优先于继承,天然避免对称性破坏

#### 追问 2:为什么 String 的 equals 要先比地址?

这是**短路优化**:同一个对象必然相等,省去类型检查、长度比较、逐字符循环,是"小对象高频调用"场景下非常关键的性能细节。String.equals 在 HashMap 等场景中被调用极频繁,一次短路能省下完整比较链路。

#### 追问 3:如何比较数组内容?

```java
int[] arr1 = {1, 2, 3};
int[] arr2 = {1, 2, 3};
arr1.equals(arr2);        // false:数组没有重写 equals,仍比地址!
Arrays.equals(arr1, arr2) // true:Arrays 工具类提供内容比较
```

---

## 回答思路

### 答题逻辑框架(约 1.5 分钟)

1. **先给结论**:`==` 是运算符,比"数值或地址";equals 是方法,默认就是 `==`
2. **分场景展开**:基本类型(比数值)、引用类型(比地址)、未重写 equals(等价 ==)、重写 equals(自定义规则)
3. **举经典例子**:String 字面量 vs new String;包装类 127/128 陷阱
4. **落到规范**:重写 equals 的五条约定 + hashCode 必须一起重写
5. **实践收尾**:Objects.equals、常量在前等最佳实践

### 重点得分点

- 准确说出"基本类型比数值,引用类型比地址"
- 准确说出"equals 默认就是 ==,String 重写为内容比较"
- 说出 **hashCode 与 equals 必须同时重写**及其原因(HashMap 找桶逻辑)
- 举出 **Integer 127/128 缓存陷阱**或常量池例子(体现"知其然也知其所以然")

### 常见误区

- ❌ 认为 equals 天生就是比内容——只有重写过的类才是,自定义类默认比地址
- ❌ 用 `==` 比较两个 String 内容,偶尔对(常量池复用)就以为一直对
- ❌ 只重写 equals 不重写 hashCode,导致 HashMap/HashSet 行为异常
- ❌ 忘记比较数组内容要用 `Arrays.equals`(数组没重写 equals)

### 过渡话术

- 开头定调:"这个问题的核心就一句话:equals 的默认实现就是 ==,区别来自各子类的重写……"
- 讲陷阱时:"这里有一个 99% 的人踩过的坑——Integer 在 -128 到 127 之间有缓存,超出范围 == 就失灵了……"
- 收尾升华:"比较语义本质上是在回答'同一个还是同样的',而正确实现一套 equals/hashCode 正是良好哈希结构的基石。"

### 时间分配建议

| 环节 | 时间 |
|---|---|
| 总起 + 语义划分(基本/引用) | 20 秒 |
| equals 默认实现 + String 重写 | 30 秒 |
| 常量池/IntegerCache 陷阱示例 | 20 秒 |
| 重写规范(五条约定 + hashCode) | 25 秒 |
| 最佳实践 + 追问 | 15 秒 |

---

> 📋 **分类**: java
> 🏷️ **标签**: 
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-12 00:48:21
