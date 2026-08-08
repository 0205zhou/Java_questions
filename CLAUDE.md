# CLAUDE.md — zcx-questions 面试八股文档仓库

## 项目概述

zcx-questions — 基于 **Harness Engineering（驾驭工程）** 的 AI 面试备考系统。

核心能力：输入面试题 → 深度解答 → 质量审查 → **自动归档题库** → 生成文档 → Git 推送。

## 核心架构

```
/面经助手 (Skill 统一入口)
    ├── 阶段1: 题目解析 & 分类（先读简历）
    ├── 阶段2: 并行答题 (interview-answerer × N)
    ├── 阶段3: 质量审查 (quality-reviewer × N)
    ├── 阶段4: 重答循环 (FAIL ≤ 2 次)
    ├── 阶段5: 文档组装 (doc-assembler)
    ├── 阶段6: 输出落盘 (outputs/)
    ├── 阶段7: 题库归档 (question_manager.py)
    ├── 阶段8: 站点生成 (generate_site.py)
    ├── 阶段9: Git 推送 (SSH)
    └── 阶段10: 结果报告
```

### 3 个 Agent

| Agent | 职责 |
|-------|------|
| `interview-answerer` | 深度解答单题：记忆法 + 原理拆解 + 答题思路 |
| `quality-reviewer` | 15 项清单审查，FAIL → 自动重答 |
| `doc-assembler` | 组装最终 Markdown 文档 |

### Python 脚本（scripts/）

| 脚本 | 职责 |
|------|------|
| `interview_agent.py` | 核心：独立运行的 AI Agent（调用 Anthropic API，走环境变量） |
| `question_manager.py` | 题库增删查改、分类标签、难度估计 |
| `generate_site.py` | 同步题库数据到 docs/（网页端） |
| `md_to_pdf.py` | Markdown → PDF |
| `memory_trainer.py` | 交互式记忆训练 |
| `batch_process.py` | 批量答题 |
| `push-output.sh` | 一键推送（SSH 方式） |
| 其余 14 个 | 扩展工具（导出/统计/复习计划等，见各文件头部注释） |

## 题库系统

- `questions/index.json` — 主索引（网页端动态加载）
- `questions/database/{category}/{slug}.md` — 每道题独立归档，文件名 = 问题名
- 分类目录：`java/`、`spring/`、`redis/`、`mysql/`、`jvm/`、`并发/`、`网络/`、`系统设计/`、`distributed/`、`behavioral/`、`devops/` 等
- 自动分类 + 自动标签 + 自动难度判断（question_manager.py）

## 文档格式规范（每道题必含）

### 1. 🧠 联想记忆法（必须排第一）
- **记忆口诀/联想**：顺口溜或口诀，一句概括核心
- **记忆原理**：解释为什么好记（认知钩子）
- **关联知识**：与其他考点的关联

### 2. 📖 深度解答（四层递进）
| 层级 | 内容 |
|---|---|
| 核心概念 | 是什么：定义、解决的问题 |
| 底层原理 | 为什么：机制、源码、设计哲学 |
| 实践应用 | 怎么用：代码示例、最佳实践 |
| 深入思考 | 权衡对比、局限、追问方向 |

### 3. 🗺️ 回答思路
答题逻辑框架 / 重点得分点 / 常见误区 / 过渡话术 / 时间分配建议

### 质量要求
- 专业书面语，术语首次出现括号附英文
- 技术题必须含代码示例或文字架构图
- 篇幅 ≥ 1800 字，解释 WHY 而非只陈述 WHAT

## 技术约定

### Agent 定义
- `.claude/agents/*.md` — YAML frontmatter + system prompt
- `description` 必须包含 "Use this agent when..." 格式
- 不指定 model 字段（继承会话模型）

### Skill 定义
- `.claude/skills/面经助手/SKILL.md` — frontmatter + 执行指令
- `/面经助手` 是唯一用户入口，`references/` 下为约束/流程/凭证/简历

### Git 规范
- Git 身份：`旭` / `2875709559@qq.com`（见 skills/面经助手/references/git-config.md）
- 认证：**SSH 方式**（`git@github.com:0205zhou/zcx-questions.git`），严禁硬编码 Token
- Commit: `docs: 面经解答 + 题库更新 — YYYY-MM-DD HH:MM`
- Branch: `main`

### 输出规范
- 文档：`outputs/面经解答-YYYYMMDD-HHMM.md`
- 题库：`questions/database/{category}/{slug}.md`
- 每道题必含：🧠 联想记忆法 → 📖 深度解答 → 🗺️ 回答思路

## 个人信息红线

- 个人化问题（自我介绍、项目经历等）**严禁编造**
- 必须基于简历：`.claude/skills/面经助手/references/resume/resume.md`（R1~R6 约束）
- 量化数据以简历实际为准，禁止使用占位符以外的数字
- 仓库内**任何文件禁止出现真实凭证**

## Harness Engineering 关键原则

1. **关注点分离** — 答题、审查、归档三个职责独立
2. **质量内建** — 审查是强制阶段，不是事后补救
3. **自动沉淀** — 每道题自动归档到题库，不需要手动操作
4. **数据驱动** — index.json 驱动网页端展示
5. **确定性编排** — Skill 定义 10 阶段，不依赖模型自主决策
6. **零凭证** — 认证只走 SSH/环境变量，仓库永不落盘密钥
