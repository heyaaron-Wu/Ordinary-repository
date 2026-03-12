#!/bin/bash
# GitHub 集成自动配置脚本
# 使用方法：./setup-github-integration.sh

set -e

echo "🦞 OpenClaw GitHub 集成配置脚本"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
WORKSPACE_DIR="$HOME/.openclaw/workspace"
GITHUB_TOKEN=""
GITHUB_USERNAME=""
REPO_URL=""

echo -e "${BLUE}步骤 1: 获取 GitHub Token${NC}"
echo "如果没有 Token，请访问：https://github.com/settings/tokens"
echo "点击 'Generate new token (classic)'"
echo "Scopes 勾选：repo, workflow"
echo ""
read -p "请输入你的 GitHub Token: " -s GITHUB_TOKEN
echo ""

echo -e "${BLUE}步骤 2: 获取 GitHub 用户名${NC}"
read -p "请输入你的 GitHub 用户名: " GITHUB_USERNAME

echo -e "${BLUE}步骤 3: 配置远程仓库${NC}"
echo "选项 1: 使用现有仓库"
echo "选项 2: 创建新仓库"
read -p "请选择 (1/2): " REPO_CHOICE

if [ "$REPO_CHOICE" = "1" ]; then
    read -p "请输入仓库 URL (https://github.com/USER/REPO.git): " REPO_URL
else
    REPO_NAME="${GITHUB_USERNAME}-openclaw-workspace"
    echo ""
    echo "将创建新仓库：$REPO_NAME"
    read -p "仓库可见性？(public/private): " REPO_VISIBILITY
    
    # 使用 GitHub CLI 创建仓库
    if command -v gh &> /dev/null; then
        gh repo create "$REPO_NAME" --$REPO_VISIBILITY --source=. --remote=origin --push
        REPO_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
    else
        echo -e "${YELLOW}警告：未检测到 GitHub CLI (gh)，无法自动创建仓库${NC}"
        echo "请手动创建仓库后，再运行此脚本选择选项 1"
        exit 1
    fi
fi

echo -e "${BLUE}步骤 4: 配置 Git 凭证${NC}"
cd "$WORKSPACE_DIR"

# 配置凭证存储
git config --global credential.helper store

# 设置远程仓库（如果已存在则更新）
if git remote | grep -q "^origin$"; then
    git remote set-url origin "$REPO_URL"
else
    git remote add origin "$REPO_URL"
fi

echo -e "${BLUE}步骤 5: 测试连接${NC}"
# 测试 GitHub API
echo "测试 GitHub API 连接..."
RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user)
LOGIN=$(echo $RESPONSE | grep -o '"login": "[^"]*"' | cut -d'"' -f4)

if [ -n "$LOGIN" ]; then
    echo -e "${GREEN}✓ GitHub API 连接成功！${NC}"
    echo "  用户名：$LOGIN"
else
    echo -e "${RED}✗ GitHub API 连接失败${NC}"
    echo "请检查 Token 是否正确"
    exit 1
fi

echo -e "${BLUE}步骤 6: 推送到 GitHub${NC}"
git branch -M main
git push -u origin main

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ GitHub 集成配置完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "仓库地址：$REPO_URL"
echo "当前分支：main"
echo ""
echo -e "${YELLOW}下一步建议:${NC}"
echo "1. 在 GitHub 上查看仓库"
echo "2. 配置 GitHub Actions 自动同步"
echo "3. 设置 Webhook 实现双向同步"
echo ""
echo -e "${YELLOW}安全提示:${NC}"
echo "• Token 已存储在 ~/.git-credentials"
echo "• 不要将 .git-credentials 提交到 Git"
echo "• 建议每 90 天轮换一次 Token"
echo ""
