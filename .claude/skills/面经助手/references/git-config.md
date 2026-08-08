# Git 认证配置

> 使用 SSH 方式推送（本机 `~/.ssh/id_rsa` 已配置 GitHub，无需 Token）。

---

## 凭证

| 配置项 | 值 |
|--------|-----|
| GITHUB_USERNAME | `0205zhou` |
| GITHUB_REPO | `zcx-questions` |
| GIT_REMOTE_URL | `git@github.com:0205zhou/zcx-questions.git` |
| GIT_USER_NAME | `旭` |
| GIT_USER_EMAIL | `2875709559@qq.com` |
| GIT_BRANCH | `main` |
| LOCAL_PATH | `D:\zcx-questions` |

---

## Git 操作命令模板

```bash
cd /d/zcx-questions

# 配置身份
git config user.name "旭"
git config user.email "2875709559@qq.com"

# 配置 remote（SSH 方式，无需 Token）
git remote set-url origin git@github.com:0205zhou/zcx-questions.git

# 提交并推送
git add outputs/ questions/ docs/
git commit -m "docs: 面经解答 + 题库更新 — $(date +%Y-%m-%d_%H:%M)"
git push origin main
```

---

## 故障排查

如果 push 返回 SSH 认证错误：
1. 检查 `~/.ssh/id_rsa.pub` 是否已添加到 GitHub → Settings → SSH Keys
2. `ssh -T git@github.com` 测试连接（返回 `Hi 0205zhou!` 即正常）

---

## 安全红线

- **严禁**在任何文件（脚本、配置、文档）中硬编码 GitHub Token / API Key
- 所有密钥一律走环境变量或 SSH 认证
