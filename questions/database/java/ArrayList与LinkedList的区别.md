---
id: q0041
question: "ArrayList与LinkedList的区别"
category: java
tags: ["集合", "LinkedList", "ArrayList"]
difficulty: medium
created: 2026-08-15 00:53:47
source: 用户输入
---

# ArrayList与LinkedList的区别

## 联想记忆法

### 记忆口诀/联想

**口诀:"一个连排大通铺,一个独门小别院;一个点名直接报号,一个挨家挨户找"**

把两者想成**两种宿舍**:

- **ArrayList**:一排**连续的房间**(连续内存),**报号直达**(按下标 O(1) 随机访问),但中间插队要整排挪人(O(n));扩容时整栋扩建 1.5 倍
- **LinkedList**:每间房是**独立小屋**(节点),房与房之间挂**双向指针**(prev/next);找某间房必须**从门口挨个走**(O(n) 查找),但门口加人/加队首队尾超快(O(1))

**结论:查得多用 ArrayList(数组连续、缓存友好),增删两头用 LinkedList(但实际高频场景少,队列通常用 ArrayDeque)。**

### 记忆原理

用"大通铺 vs 独门小院"的空间想象,把底层结构(连续数组 vs 链表)与操作复杂度(随机访问 O(1) vs O(n)、中部插入 O(n) vs O(1))绑定在一起。记忆主线是"**底层决定行为**":一切差异都来自"数组是连续内存、链表是分散节点"这一个事实,抓住这一点,随机访问、缓存、内存占用全都能推导出来。

### 关联知识

- **与 HashMap 关联**:HashMap 桶内链表在冲突多时转红黑树,同一套链表/数组的权衡逻辑
- **与 ArrayDeque 关联**:LinkedList 实现了 Deque,但队列场景 ArrayDeque 更优(循环数组,无节点开销)
- **与 CopyOnWriteArrayList 关联**:并发读多写少场景的替代品
- **与 Collections.synchronizedList 关联**:两者线程都不安全,包装后的性能差异

---

## 深度解答

### 第一层:核心概念

#### 是什么

ArrayList 是**基于动态数组(dynamic array)**的 List,LinkedList 是**基于双向链表(doubly linked list)**的 List。两者都实现 List 接口,都能存任意对象、允许 null、线程不安全,但**底层数据结构决定了完全不同的性能特征**:

| 维度 | ArrayList | LinkedList |
|---|---|---|
| 底层结构 | 动态数组(连续内存) | 双向链表(节点 + prev/next) |
| 随机访问 get(i) | **O(1)**(下标直接寻址) | **O(n)**(从头遍历) |
| 尾部添加 add(e) | O(1) 摊还(扩容时 O(n)) | **O(1)** |
| 头部/中部插入 | **O(n)**(元素整体后移) | 插入本身 O(1),但**定位 O(n)** |
| 删除 | O(n)(整体前移) | O(1)(找到节点后改指针) |
| 内存占用 | 连续数组,有预留空间 | 每节点多两个指针(prev/next) |
| 缓存局部性 | **好**(连续内存,CPU 缓存命中高) | 差(节点分散,频繁缺页/缓存未命中) |
| 扩容 | 1.5 倍扩容(右移一位) | 无容量概念 |
| 遍历方式 | for + get 高效;iterator 亦可 | 必须 iterator/foreach(用 get 是 O(n²)) |

### 第二层:底层原理

#### ArrayList:连续数组 + 1.5 倍扩容

- 底层 `Object[] elementData`,默认初始容量 10
- `get(i)` = `elementData[i]`,一次内存寻址,**O(1)**
- `add(e)` 尾部:容量够直接写,**摊还 O(1)**;容量不够触发 `grow()`:**newCapacity = oldCapacity + (oldCapacity >> 1)`,即 **1.5 倍**,并 `Arrays.copyOf` 拷贝整个数组,**O(n)**
- 插入/删除中部:先 `System.arraycopy` 移动后半段元素,再写/删,平均 **O(n/2)**
- 连续内存意味着**缓存局部性好**:CPU 预取按 cache line(64 字节)批量加载,遍历时命中率高

#### LinkedList:双向链表 + 节点开销

- 每个节点 `Node<E>` 持有 item、prev、next 三个引用,JDK 8 后是**双向链表**(1.7 前是双向循环链表)
- `get(i)` 会先判断 index 在前半还是后半(`index < (size >> 1)`),从**离得近的一端**遍历,最坏 **O(n)**
- 节点在堆中**随机分布**,遍历时 cache line 频繁失效,实际性能比 O(n) 理论值更差
- 内存:每存一个元素多两个指针(64 位 JVM 下约多 16 字节 + 对象头),且没有连续预分配,GC 压力更大
- 实现了 Deque 接口,可当栈/队列用(addFirst/addLast/pollFirst 等)

### 第三层:实践应用

```java
// ✅ ArrayList:随机访问、尾部追加、遍历为主的场景
List<String> list = new ArrayList<>();
for (int i = 0; i < 10000; i++) list.add("item" + i);  // 尾部添加,快
String s = list.get(5000);                              // O(1),快
for (String x : list) { ... }                           // 顺序遍历,缓存友好

// ❌ 经典错误:LinkedList 用 get 遍历 → O(n²)
for (int i = 0; i < list.size(); i++) list.get(i);      // 每次都从头遍历!

// ✅ LinkedList:频繁在头部/尾部增删(但要小心定位成本)
LinkedList<String> queue = new LinkedList<>();
queue.addLast("a");
String head = queue.pollFirst();                        // O(1)

// 队列优先方案:ArrayDeque 优于 LinkedList(无节点开销、缓存友好)
ArrayDeque<String> deque = new ArrayDeque<>();
```

- **选型口诀**:随机访问多 → ArrayList;增删主要在两端 → ArrayDeque(队列)或 LinkedList(需索引/中间操作时)
- **扩容防御**:预估数据量时 `new ArrayList<>(capacity)`,避免频繁 1.5 倍扩容拷贝
- **线程安全**:两者都不安全,并发场景用 `CopyOnWriteArrayList` 或 `Collections.synchronizedList`

### 第四层:深入思考

**追问 1:LinkedList 真的比 ArrayList 增删快吗?**
不一定。`add(index, e)` 需要先 `node(index)` 定位,O(n);数据量大时定位成本可能超过 ArrayList 的移动成本。LinkedList 只在"**已持有节点引用**"或"**两端操作**"时才有优势,而普通业务代码几乎拿不到中间节点引用,所以实际中 LinkedList 优势场景很少。

**追问 2:为什么 HashMap 1.8 桶内链表超过 8 转红黑树?**
链表 O(n) 与数组"连续"特性无关,是为了退化场景(哈希全冲突)时避免 O(n) 退化到 O(n²) 级别的遍历成本——红黑树保证最坏 O(log n)。

**追问 3:ArrayList 的 subList 有什么坑?**
`subList` 返回的是**视图**(共享底层数组),对子列表的修改会反映到原列表;原列表结构性修改后,子列表操作抛 ConcurrentModificationException。

---

## 回答思路

### 答题逻辑框架

1. **一句话定位**:一个动态数组、一个双向链表
2. **列差异表**:随机访问、插入删除、内存、缓存四维度
3. **讲底层**:连续内存 vs 节点指针,1.5 倍扩容 vs 无容量概念
4. **给选型结论**:查多选 ArrayList;两端增删选 ArrayDeque/LinkedList;并指出 LinkedList 的定位坑
5. **埋延伸**:引出 ArrayDeque、HashMap 树化、ConcurrentModificationException

### 重点得分点

- ✅ 说出底层结构 + 各操作复杂度(随机访问 O(1)/O(n),插入 O(n)/O(1))
- ✅ 说出 ArrayList 扩容 **1.5 倍**、初始容量 10
- ✅ 说出**缓存局部性**(面试加分项)
- ✅ 主动指出 LinkedList 中部插入"定位 O(n)"这个反直觉点

### 常见误区

- ❌ "LinkedList 增删一定比 ArrayList 快"——定位成本 O(n),要看场景
- ❌ "ArrayList 只有 10 个容量"——是初始容量,满了自动 1.5 倍扩容
- ❌ "LinkedList 支持 O(1) 随机访问"——只有 get(0)/get(size-1) 附近快
- ❌ 忘记两者都**线程不安全**

### 过渡话术

- 引出队列:"既然 LinkedList 能当队列,那 ArrayDeque 凭什么更优?"(转 ArrayDeque)
- 引出 HashMap:"HashMap 也是数组 + 链表,和 ArrayList 的数组有什么不同?"(转哈希表)

### 时间分配建议

- 记忆口诀 15 秒 → 差异表 30 秒 → 底层原理 60 秒 → 选型实践 30 秒 → 追问(缓存/树化)45 秒 → 共约 3 分钟


---

> 📋 **分类**: java
> 🏷️ **标签**: `集合` `LinkedList` `ArrayList`
> 📊 **难度**: medium
> 📅 **归档时间**: 2026-08-15 00:53:47
