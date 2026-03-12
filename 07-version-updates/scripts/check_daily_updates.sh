#!/bin/bash
# 版本更新检查脚本
# 功能：检查当日是否有文件变更，如有则更新 CHANGELOG.md

set -e

WORKSPACE="/home/admin/.openclaw/workspace"
CHANGELOG_FILE="$WORKSPACE/07-version-updates/CHANGELOG.md"
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)

echo "🔍 版本更新检查"
echo "=============="
echo "日期：$TODAY"
echo ""

cd "$WORKSPACE"

# 检查今日是否有提交
echo "📊 检查今日提交记录..."
TODAY_COMMITS=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --oneline 2>/dev/null | wc -l)

if [ "$TODAY_COMMITS" -eq 0 ]; then
    echo "✅ 今日无提交记录，无需更新 CHANGELOG"
    exit 0
fi

echo "发现 $TODAY_COMMITS 个提交"

# 获取今日提交详情
echo ""
echo "📝 今日提交详情:"
git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --oneline

# 分类统计
echo ""
echo "📊 提交分类统计:"

# 新增功能
NEW_FEATURES=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="✨\|feat\|新增\|添加" --oneline | wc -l)
echo "  ✨ 新增功能：$NEW_FEATURES 个"

# 优化
OPTIMIZATIONS=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="🚀\|perf\|优化\|改进" --oneline | wc -l)
echo "  🚀 性能优化：$OPTIMIZATIONS 个"

# Bug 修复
BUG_FIXES=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="🐛\|fix\|修复\|bug" --oneline | wc -l)
echo "  🐛 Bug 修复：$BUG_FIXES 个"

# 文档更新
DOCS=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="📝\|docs\|文档" --oneline | wc -l)
echo "  📝 文档更新：$DOCS 个"

# 安全修复
SECURITY=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="🔒\|security\|安全" --oneline | wc -l)
echo "  🔒 安全修复：$SECURITY 个"

# 检查是否需要更新 CHANGELOG
TOTAL_CHANGES=$((NEW_FEATURES + OPTIMIZATIONS + BUG_FIXES + DOCS + SECURITY))

if [ "$TOTAL_CHANGES" -eq 0 ]; then
    echo ""
    echo "✅ 今日提交不涉及版本更新，无需更新 CHANGELOG"
    exit 0
fi

echo ""
echo "📝 准备更新 CHANGELOG.md..."

# 检查 CHANGELOG.md 是否已包含今日更新
if grep -q "## \[.*\] - $TODAY" "$CHANGELOG_FILE" 2>/dev/null; then
    echo "✅ CHANGELOG.md 已包含今日更新"
    exit 0
fi

# 生成更新日志内容
TEMP_FILE="/tmp/changelog_update.md"

cat > "$TEMP_FILE" << EOF

### [v1.0.$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --oneline | wc -l)] - $TODAY
EOF

# 添加新增功能
if [ "$NEW_FEATURES" -gt 0 ]; then
    echo "" >> "$TEMP_FILE"
    echo "#### ✨ 新增" >> "$TEMP_FILE"
    git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="✨\|feat\|新增\|添加" --oneline | while read commit; do
        MSG=$(echo "$commit" | cut -d' ' -f2-)
        echo "- $MSG" >> "$TEMP_FILE"
    done
fi

# 添加优化
if [ "$OPTIMIZATIONS" -gt 0 ]; then
    echo "" >> "$TEMP_FILE"
    echo "#### 🚀 优化" >> "$TEMP_FILE"
    git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="🚀\|perf\|优化\|改进" --oneline | while read commit; do
        MSG=$(echo "$commit" | cut -d' ' -f2-)
        echo "- $MSG" >> "$TEMP_FILE"
    done
fi

# 添加 Bug 修复
if [ "$BUG_FIXES" -gt 0 ]; then
    echo "" >> "$TEMP_FILE"
    echo "#### 🐛 修复" >> "$TEMP_FILE"
    git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="🐛\|fix\|修复\|bug" --oneline | while read commit; do
        MSG=$(echo "$commit" | cut -d' ' -f2-)
        echo "- $MSG" >> "$TEMP_FILE"
    done
fi

# 添加文档更新
if [ "$DOCS" -gt 0 ]; then
    echo "" >> "$TEMP_FILE"
    echo "#### 📝 文档" >> "$TEMP_FILE"
    git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="📝\|docs\|文档" --oneline | while read commit; do
        MSG=$(echo "$commit" | cut -d' ' -f2-)
        echo "- $MSG" >> "$TEMP_FILE"
    done
fi

# 添加安全修复
if [ "$SECURITY" -gt 0 ]; then
    echo "" >> "$TEMP_FILE"
    echo "#### 🔒 安全" >> "$TEMP_FILE"
    git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="🔒\|security\|安全" --oneline | while read commit; do
        MSG=$(echo "$commit" | cut -d' ' -f2-)
        echo "- $MSG" >> "$TEMP_FILE"
    done
fi

# 插入到 CHANGELOG.md
echo ""
echo "📝 更新 CHANGELOG.md..."

# 读取现有内容
EXISTING_CONTENT=$(cat "$CHANGELOG_FILE")

# 创建新文件
{
    head -n 20 "$CHANGELOG_FILE"  # 保留标题和说明部分
    cat "$TEMP_FILE"              # 添加今日更新
    echo ""
    tail -n +21 "$CHANGELOG_FILE" # 保留后续内容
} > "${CHANGELOG_FILE}.tmp"

mv "${CHANGELOG_FILE}.tmp" "$CHANGELOG_FILE"

echo "✅ CHANGELOG.md 已更新"

# 提交变更
echo ""
echo "📤 提交 CHANGELOG 更新..."
cd "$WORKSPACE"
git add "$CHANGELOG_FILE"
git commit -m "📝 更新版本更新日志 - $TODAY" || echo "无变更或已提交"

# 推送
echo "🚀 推送到 GitHub..."
git pull --rebase || true
git push origin OpenClaw-Fund-Trading

echo ""
echo "================================"
echo "✅ 版本更新检查完成！"
echo ""
echo "📄 更新文件：$CHANGELOG_FILE"
echo "📊 今日提交：$TODAY_COMMITS 个"
echo "🔗 GitHub: https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system/blob/OpenClaw-Fund-Trading/07-version-updates/CHANGELOG.md"
echo ""

# 清理
rm -f "$TEMP_FILE"
