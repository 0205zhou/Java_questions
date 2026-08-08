#!/bin/bash
# ======================================================
# zcx-questions — Git Auto-Push Script
# 使用 SSH 方式推送(本机 ~/.ssh/id_rsa 已配置 GitHub)
# 不含任何硬编码凭证
# ======================================================
set -e

# ---- 配置(来自 references/git-config.md)----
GIT_USER_NAME="旭"
GIT_USER_EMAIL="2875709559@qq.com"
GIT_REMOTE_URL="git@github.com:0205zhou/zcx-questions.git"
GIT_BRANCH="main"

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GREEN='\033[0;32m' YELLOW='\033[1;33m' RED='\033[0;31m' NC='\033[0m'

echo -e "${GREEN}[zcx-questions]${NC} Auto-push..."

if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}[ERROR]${NC} Project not found: $PROJECT_DIR"
    exit 1
fi
cd "$PROJECT_DIR"

# ---- Ensure git identity ----
git config user.name "$GIT_USER_NAME" 2>/dev/null || true
git config user.email "$GIT_USER_EMAIL" 2>/dev/null || true

# ---- Ensure remote (SSH, no token) ----
git remote set-url origin "$GIT_REMOTE_URL" 2>/dev/null || true

# ---- Regenerate site data ----
echo -e "${GREEN}[INFO]${NC} Regenerating site..."
python scripts/generate_site.py 2>/dev/null || echo "  ⚠️  generate_site failed, continuing"

# ---- Stage ----
echo -e "${GREEN}[INFO]${NC} Staging files..."
git add outputs/ questions/ docs/ CLAUDE.md .claude/ 2>/dev/null || true

# ---- Check changes ----
if git diff --quiet --cached; then
    echo -e "${YELLOW}[SKIP]${NC} No changes."
    exit 0
fi

# ---- Commit ----
TIMESTAMP=$(date +"%Y-%m-%d %H:%M")
git commit -m "docs: 面经解答 + 题库更新 — ${TIMESTAMP}"

# ---- Push ----
echo -e "${GREEN}[INFO]${NC} Pushing to ${GIT_BRANCH}..."
git push origin "$GIT_BRANCH"

echo -e "${GREEN}[DONE]${NC} Pushed! 🚀"
