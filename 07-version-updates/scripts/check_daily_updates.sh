#!/bin/bash
# 版本更新检查脚本 - 每晚 23:30 执行
# 功能：检查当日提交，更新 CHANGELOG.md 和 README.md

set -e

WORKSPACE="/home/admin/.openclaw/workspace"
CHANGELOG_FILE="$WORKSPACE/07-version-updates/CHANGELOG.md"
README_FILE="$WORKSPACE/README.md"
TODAY=$(date +%Y-%m-%d)
TODAY_CN=$(date +%Y 年%m 月%d 日)

echo "🔍 版本更新检查"
echo "=============="
echo "日期：$TODAY"
echo ""

cd "$WORKSPACE"

# 检查今日是否有提交
echo "📊 检查今日提交记录..."
TODAY_COMMITS=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --oneline 2>/dev/null | wc -l)

if [ "$TODAY_COMMITS" -eq 0 ]; then
    echo "✅ 今日无提交记录，无需更新"
    exit 0
fi

echo "发现 $TODAY_COMMITS 个提交"
echo ""

# 获取今日提交详情
echo "📝 今日提交详情:"
git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --oneline
echo ""

# 分类统计（排除纯文档提交）
echo "📊 提交分类统计:"

NEW_FEATURES=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="✨\|feat\|新增\|添加" --oneline | wc -l)
echo "  ✨ 新增功能：$NEW_FEATURES 个"

OPTIMIZATIONS=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="🚀\|perf\|优化\|改进" --oneline | wc -l)
echo "  🚀 性能优化：$OPTIMIZATIONS 个"

BUG_FIXES=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="🐛\|fix\|修复\|bug" --oneline | wc -l)
echo "  🐛 Bug 修复：$BUG_FIXES 个"

DOCS=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="📝\|docs\|文档" --oneline | wc -l)
echo "  📝 文档更新：$DOCS 个"

SECURITY=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="🔒\|security\|安全" --oneline | wc -l)
echo "  🔒 安全修复：$SECURITY 个"
echo ""

# 检查是否有实际代码/功能变更（排除纯文档更新）
CODE_CHANGES=$((NEW_FEATURES + OPTIMIZATIONS + BUG_FIXES + SECURITY))

if [ "$CODE_CHANGES" -eq 0 ]; then
    echo "✅ 今日提交仅为文档更新，不更新版本号"
fi

# 检查 CHANGELOG.md 是否已包含今日更新
if grep -q "## \[.*\] - $TODAY" "$CHANGELOG_FILE" 2>/dev/null; then
    echo "✅ CHANGELOG.md 已包含今日更新"
    exit 0
fi

echo "📝 准备更新 CHANGELOG.md..."

# 获取当前最新版本号并递增（从"## 📅 更新历史"之后查找，排除示例行）
CURRENT_VERSION=$(awk '/^## 📅 更新历史/,0' "$CHANGELOG_FILE" | grep -oP '^\### \[v\K[0-9.]+' | head -1)
if [ -z "$CURRENT_VERSION" ]; then
    CURRENT_VERSION="1.0.0"
fi

# 解析版本号
MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)

# 只有代码变更才递增版本号
if [ "$CODE_CHANGES" -gt 0 ]; then
    PATCH=$((PATCH + 1))
    VERSION_NUM="$MAJOR.$MINOR.$PATCH"
    echo "📊 版本号递增：v$CURRENT_VERSION → v$VERSION_NUM"
else
    VERSION_NUM="$CURRENT_VERSION"
    echo "📊 版本号不变：v$VERSION_NUM (仅文档更新)"
fi

# 创建临时文件
TEMP_CHANGELOG="/tmp/changelog_update_$$.md"

# 只有代码变更才创建新版本条目，否则标记为文档更新
if [ "$CODE_CHANGES" -gt 0 ]; then
    cat > "$TEMP_CHANGELOG" << EOF

### [v$VERSION_NUM] - $TODAY
EOF
else
    cat > "$TEMP_CHANGELOG" << EOF

### [v$VERSION_NUM] - $TODAY (文档更新)
EOF
fi

# 添加各类更新
if [ "$NEW_FEATURES" -gt 0 ]; then
    echo "" >> "$TEMP_CHANGELOG"
    echo "#### ✨ 新增" >> "$TEMP_CHANGELOG"
    git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="✨\|feat\|新增\|添加" --oneline | while read commit; do
        MSG=$(echo "$commit" | cut -d' ' -f2-)
        echo "- $MSG" >> "$TEMP_CHANGELOG"
    done
fi

if [ "$OPTIMIZATIONS" -gt 0 ]; then
    echo "" >> "$TEMP_CHANGELOG"
    echo "#### 🚀 优化" >> "$TEMP_CHANGELOG"
    git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="🚀\|perf\|优化\|改进" --oneline | while read commit; do
        MSG=$(echo "$commit" | cut -d' ' -f2-)
        echo "- $MSG" >> "$TEMP_CHANGELOG"
    done
fi

if [ "$BUG_FIXES" -gt 0 ]; then
    echo "" >> "$TEMP_CHANGELOG"
    echo "#### 🐛 修复" >> "$TEMP_CHANGELOG"
    git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="🐛\|fix\|修复\|bug" --oneline | while read commit; do
        MSG=$(echo "$commit" | cut -d' ' -f2-)
        echo "- $MSG" >> "$TEMP_CHANGELOG"
    done
fi

if [ "$DOCS" -gt 0 ]; then
    echo "" >> "$TEMP_CHANGELOG"
    echo "#### 📝 文档" >> "$TEMP_CHANGELOG"
    git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="📝\|docs\|文档" --oneline | while read commit; do
        MSG=$(echo "$commit" | cut -d' ' -f2-)
        echo "- $MSG" >> "$TEMP_CHANGELOG"
    done
fi

if [ "$SECURITY" -gt 0 ]; then
    echo "" >> "$TEMP_CHANGELOG"
    echo "#### 🔒 安全" >> "$TEMP_CHANGELOG"
    git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="🔒\|security\|安全" --oneline | while read commit; do
        MSG=$(echo "$commit" | cut -d' ' -f2-)
        echo "- $MSG" >> "$TEMP_CHANGELOG"
    done
fi

# 插入到 CHANGELOG.md（在"## 📅 更新历史"之后）
HEADER_LINES=$(grep -n "^## 📅 更新历史" "$CHANGELOG_FILE" | cut -d: -f1)
if [ -z "$HEADER_LINES" ]; then
    HEADER_LINES=20  #  fallback
fi

{
    head -n $HEADER_LINES "$CHANGELOG_FILE"
    cat "$TEMP_CHANGELOG"
    echo ""
    tail -n +$((HEADER_LINES + 1)) "$CHANGELOG_FILE"
} > "${CHANGELOG_FILE}.tmp"

mv "${CHANGELOG_FILE}.tmp" "$CHANGELOG_FILE"
rm -f "$TEMP_CHANGELOG"

echo "✅ CHANGELOG.md 已更新"

# 更新 README.md 中的版本信息
echo ""
echo "📝 检查 README.md..."

if [ -f "$README_FILE" ]; then
    if grep -q "## 📈 版本历史" "$README_FILE" 2>/dev/null || grep -q "## 📈 更新历史" "$README_FILE" 2>/dev/null; then
        echo "✅ README.md 包含版本历史，无需更新"
    else
        echo "ℹ️  README.md 不包含版本历史部分（可选）"
    fi
fi

# 提交变更
echo ""
echo "📤 提交文档更新..."
cd "$WORKSPACE"

git add "$CHANGELOG_FILE" 2>/dev/null || true
git add "$README_FILE" 2>/dev/null || true

COMMIT_MSG="📝 自动更新版本日志 - $TODAY"
git commit -m "$COMMIT_MSG" 2>/dev/null || echo "无变更或已提交"

# 推送
echo "🚀 推送到 GitHub..."
git pull --rebase || true
git push origin OpenClaw-Fund-Trading

echo ""
echo "================================"
echo "✅ 版本更新检查完成！"
echo ""
echo "📄 更新文件:"
echo "   - CHANGELOG.md"
echo "   - README.md (如有需要)"
echo "📊 今日提交：$TODAY_COMMITS 个"
echo "🔗 GitHub: https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system/blob/OpenClaw-Fund-Trading/07-version-updates/CHANGELOG.md"
echo ""
