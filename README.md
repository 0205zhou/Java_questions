# 🎯 Java_questions — 面试八股文档仓库

基于 **Harness Engineering（驾驭工程）** 的 AI 面试备考系统。

**核心能力**：输入面试题 → 深度解答 → 质量审查 → 自动归档题库 → 生成文档 → Git 推送。

## 🚀 快速开始

```bash
# 1. 环境检查与依赖安装
bash setup.sh

# 2. 打开 Claude Code,使用统一入口
cd /d/Java_questions
claude
```

## 💡 使用方式

### 方式 1:Claude Code Skill(推荐)

```
/面经助手
第1题：JDK8中HashMap为什么要转成红黑树
第2题：MySQL 索引底层为什么用 B+ 树？
```

自动执行 10 阶段流程：解析分类 → 并行答题 → 质量审查 → 重答循环 → 组装 → 落盘 → 归档 → 生成站点 → Git 推送 → 报告。

### 方式 2:Python 脚本

```bash
# 题库管理
python scripts/question_manager.py stats                     # 题库统计
python scripts/question_manager.py search "HashMap"          # 搜索题目
python scripts/question_manager.py add -q "题目" -a "答案" -c java  # 添加题目

# 站点生成(GitHub Pages 数据)
python scripts/generate_site.py

# Markdown → PDF
python scripts/md_to_pdf.py outputs/面经解答-YYYYMMDD-HHMM.md

# 一键推送
bash scripts/push-output.sh
```

### 方式 3:网页端

启用 GitHub Pages(Settings → Pages → Deploy from branch: main, /docs),访问:

```
https://0205zhou.github.io/Java_questions/questions.html
```

## 📁 目录结构

```
Java_questions/
├── .claude/
│   ├── agents/                    # 3 个 Agent(答题器/审查器/组装器)
│   └── skills/面经助手/            # Skill 统一入口
│       ├── SKILL.md               # 10 阶段流程指令
│       └── references/            # 约束/流程/Git 配置/简历(占位)
├── questions/
│   ├── index.json                 # 题库主索引(网页端数据源)
│   └── database/{category}/       # 每道题一个 md,文件名=问题名
│       ├── java/
│       ├── spring/
│       ├── redis/
│       └── ...
├── scripts/                       # Python 工具脚本
├── outputs/                       # 组装后的面经文档
├── docs/                          # 网页端(GitHub Pages)
├── CLAUDE.md                      # 仓库规则(Claude Code 自动加载)
└── setup.sh                       # 一键安装
```

## 📋 文档格式规范

每道题一个 Markdown 文件,必须包含三大板块:

1. **🧠 联想记忆法**(必须排第一)— 记忆口诀/联想 + 记忆原理 + 关联知识
2. **📖 深度解答** — 核心概念(是什么)→ 底层原理(为什么)→ 实践应用(怎么用)→ 深入思考(权衡/追问)
3. **🗺️ 回答思路** — 答题逻辑框架 + 重点得分点 + 常见误区 + 过渡话术 + 时间分配建议

详见 `CLAUDE.md`。

## 🛡️ 安全说明

- Git 认证使用 **SSH** 方式,仓库内不存储任何 Token / API Key
- 个人化问题(自我介绍/项目经历)基于 `.claude/skills/面经助手/references/resume/resume.md` 回答,严禁编造
