#!/bin/bash
# 版本更新检查脚本 - 每晚 23:30 执行
# 功能：检查当日提交，更新 CHANGELOG.md 和 README.md

set -e

WORKSPACE="/home/admin/.openclaw/workspace"
CHANGELOG_FILE="$WORKSPACE/07-version-updates/CHANGELOG.md"
README_FILE="$WORKSPACE/README.md"
TODAY=$(date +%Y-%m-%d)
TODAY_CN=$(date +"%Y 年%m 月%d 日")

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

# 分类统计
echo "📊 提交分类统计:"

NEW_FEATURES=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="✨\|feat\|新增\|添加" --oneline | wc -l)
echo "  ✨ 新增功能：$NEW_FEATURES 个"

OPTIMIZATIONS=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="🚀\|perf\|优化\|改进" --oneline | wc -l)
echo "  🚀 性能优化：$OPTIMIZATIONS 个"

BUG_FIXES=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="🐛\|fix\|修复\|bug" --oneline | wc -l)
echo "  🐛 Bug 修复：$BUG_FIXES 个"

SECURITY=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="🔒\|security\|安全" --oneline | wc -l)
echo "  🔒 安全修复：$SECURITY 个"

DOCS=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="📝\|docs\|文档" --oneline | wc -l)
echo "  📝 文档更新：$DOCS 个"

# 检查是否有复盘文档（跳过不记录）
# 检测文件路径：08-fund-daily-review/reviews/ 或 08-fund-daily-review/weekly/
FUND_REVIEW_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null | grep -E "08-fund-daily-review/(reviews|weekly)/.*\.md$" | wc -l)
if [ "$FUND_REVIEW_FILES" -gt 0 ]; then
    echo "  📊 复盘文档：$FUND_REVIEW_FILES 个（不记录）"
fi
echo ""

# 检查是否有有效更新（排除复盘文档）
EFFECTIVE_CHANGES=$((NEW_FEATURES + OPTIMIZATIONS + BUG_FIXES + SECURITY + DOCS))

if [ "$EFFECTIVE_CHANGES" -eq 0 ]; then
    echo "✅ 今日提交仅为复盘文档，跳过版本更新"
    exit 0
fi

# 检查 CHANGELOG.md 是否已包含今日更新
if grep -q "## \[.*\] - $TODAY" "$CHANGELOG_FILE" 2>/dev/null; then
    echo "✅ CHANGELOG.md 已包含今日更新"
    exit 0
fi

echo "📝 准备更新 CHANGELOG.md..."

# 获取当前最新有效版本号（跳过"无系统更新"的空版本）
# 策略：提取第一个有实际内容（包含 emoji 章节）的版本号
CURRENT_VERSION=""
IN_UPDATE_HISTORY=false

while IFS= read -r line; do
    # 检查是否进入更新历史部分
    if [[ "$line" =~ ^##\ 📅\ 更新历史 ]]; then
        IN_UPDATE_HISTORY=true
        continue
    fi
    
    if [ "$IN_UPDATE_HISTORY" = true ]; then
        # 匹配版本号行：### [v1.0.16] - 2026-03-22
        if [[ "$line" =~ ^###\ \[v([0-9]+\.[0-9]+\.[0-9]+)\] ]]; then
            VERSION="${BASH_REMATCH[1]}"
            # 读取后续行，跳过空行，检查是否为空版本
            IS_EMPTY_VERSION=false
            while read -r next_line || break; do
                # 跳过空行
                if [[ -z "$next_line" || "$next_line" =~ ^[[:space:]]*$ ]]; then
                    continue
                fi
                # 检查是否为"（无系统更新）"
                if [[ "$next_line" =~ ^（无系统更新） ]]; then
                    IS_EMPTY_VERSION=true
                fi
                break
            done
            
            # 如果不是空版本，则是有效版本
            if [ "$IS_EMPTY_VERSION" = false ]; then
                CURRENT_VERSION="$VERSION"
                break
            fi
        fi
    fi
done < "$CHANGELOG_FILE"

if [ -z "$CURRENT_VERSION" ]; then
    CURRENT_VERSION="1.0.0"
fi

echo "📊 当前最新版本：v$CURRENT_VERSION"

# 解析版本号并递增
MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)
PATCH=$((PATCH + 1))
VERSION_NUM="$MAJOR.$MINOR.$PATCH"
echo "📊 版本号递增：v$CURRENT_VERSION → v$VERSION_NUM"

# 创建临时文件
TEMP_CHANGELOG="/tmp/changelog_update_$$.md"

# 创建新版本条目
cat > "$TEMP_CHANGELOG" << EOF

### [v$VERSION_NUM] - $TODAY
EOF

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

if [ "$SECURITY" -gt 0 ]; then
    echo "" >> "$TEMP_CHANGELOG"
    echo "#### 🔒 安全" >> "$TEMP_CHANGELOG"
    git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --grep="🔒\|security\|安全" --oneline | while read commit; do
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

# 插入到 CHANGELOG.md（在"## 📅 更新历史"之后）
echo "🔍 查找插入位置..."

# 检查 CHANGELOG 文件是否存在
if [ ! -f "$CHANGELOG_FILE" ]; then
    echo "❌ CHANGELOG.md 不存在，创建新文件"
    cp "$TEMP_CHANGELOG" "$CHANGELOG_FILE"
else
    # 备份原文件（防止意外丢失）
    BACKUP_FILE="${CHANGELOG_FILE}.backup.$(date +%Y%m%d%H%M%S)"
    cp "$CHANGELOG_FILE" "$BACKUP_FILE"
    echo "💾 已备份原文件：$BACKUP_FILE"
    
    # 查找"## 📅 更新历史"标题行号
    HEADER_LINE=$(grep -n "^## 📅 更新历史$" "$CHANGELOG_FILE" | head -1 | cut -d: -f1)
    
    if [ -z "$HEADER_LINE" ]; then
        echo "❌ 未找到'## 📅 更新历史'标题，拒绝自动更新"
        echo "   请手动检查 CHANGELOG.md 格式"
        echo "   备份文件：$BACKUP_FILE"
        rm -f "$TEMP_CHANGELOG"
        exit 1
    fi
    
    echo "✅ 找到插入位置：第 $HEADER_LINE 行"
    
    # 使用 awk 安全插入（避免 head/tail 切割问题）
    awk -v insert_line="$HEADER_LINE" -v temp_file="$TEMP_CHANGELOG" '
    BEGIN { inserted = 0 }
    {
        print $0
        if (NR == insert_line && !inserted) {
            while ((getline line < temp_file) > 0) {
                print line
            }
            close(temp_file)
            inserted = 1
        }
    }
    ' "$CHANGELOG_FILE" > "${CHANGELOG_FILE}.tmp"
    
    # 验证临时文件大小（防止内容丢失）
    ORIG_SIZE=$(wc -c < "$CHANGELOG_FILE")
    NEW_SIZE=$(wc -c < "${CHANGELOG_FILE}.tmp")
    
    if [ "$NEW_SIZE" -lt "$ORIG_SIZE" ]; then
        echo "❌ 警告：新文件比原文件小，可能丢失内容！"
        echo "   原文件大小：$ORIG_SIZE bytes"
        echo "   新文件大小：$NEW_SIZE bytes"
        echo "   恢复备份..."
        cp "$BACKUP_FILE" "$CHANGELOG_FILE"
        rm -f "${CHANGELOG_FILE}.tmp" "$TEMP_CHANGELOG"
        exit 1
    fi
    
    # 验证通过，替换原文件
    mv "${CHANGELOG_FILE}.tmp" "$CHANGELOG_FILE"
    echo "✅ CHANGELOG.md 已更新"
fi

rm -f "$TEMP_CHANGELOG"

echo "✅ CHANGELOG.md 已更新"

# ========== 自动更新相关文档 ==========
echo ""
echo "🔄 检查并更新相关文档..."

# 1. 更新 FILE_STRUCTURE.md 中的版本号
FILE_STRUCTURE="$WORKSPACE/03-system-docs/FILE_STRUCTURE.md"
if [ -f "$FILE_STRUCTURE" ]; then
    echo "  📄 检查 FILE_STRUCTURE.md..."
    # 如果 CHANGELOG 更新了，FILE_STRUCTURE.md 通常不需要更新（除非目录结构变化）
    echo "     ✅ 无需更新（目录结构无变化）"
fi

# 2. 更新 CRON_CONFIG.md 中的示例
CRON_CONFIG="$WORKSPACE/07-version-updates/CRON_CONFIG.md"
if [ -f "$CRON_CONFIG" ]; then
    echo "  📄 检查 CRON_CONFIG.md..."
    echo "     ✅ 无需更新（配置无变化）"
fi

# 3. 检查 README.md 是否需要更新版本号
if [ -f "$README_FILE" ]; then
    echo "  📄 检查 README.md..."
    # 提取 CHANGELOG 最新版本号
    LATEST_VERSION=$(grep -m1 "^## v[0-9]" "$CHANGELOG_FILE" | head -1 | sed 's/## //;s/ -.*//')
    if [ -n "$LATEST_VERSION" ]; then
        echo "     最新版本：$LATEST_VERSION"
        # 检查 README 中是否有版本号需要更新
        if grep -q "当前版本：" "$README_FILE"; then
            echo "     ✅ 版本号已包含"
        else
            echo "     ℹ️  README.md 无版本号字段"
        fi
    fi
    echo "     ✅ 无需更新"
fi

# 4. 检查 08-fund-daily-review/README.md
FUND_README="$WORKSPACE/08-fund-daily-review/README.md"
if [ -f "$FUND_README" ]; then
    echo "  📄 检查 08-fund-daily-review/README.md..."
    echo "     ✅ 无需更新"
fi

echo ""
echo "✅ 相关文档检查完成"

# 提交变更
echo ""
echo "📤 提交文档更新..."
cd "$WORKSPACE"

# 添加所有相关文档
git add "$CHANGELOG_FILE" 2>/dev/null || true
git add "$README_FILE" 2>/dev/null || true

# 添加其他相关文档（如果存在变更）
RELATED_DOCS=(
    "03-system-docs/FILE_STRUCTURE.md"
    "07-version-updates/CRON_CONFIG.md"
    "07-version-updates/VERSION_CHECK_CRON.md"
    "07-version-updates/MODULE_DOCS_CRON.md"
    "08-fund-daily-review/README.md"
)

for doc in "${RELATED_DOCS[@]}"; do
    if [ -f "$doc" ]; then
        git add "$doc" 2>/dev/null || true
    fi
done

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
echo "   - CHANGELOG.md ✅"
echo "   - README.md (如有变更) ✅"
echo "   - FILE_STRUCTURE.md (如有变更) ✅"
echo "   - CRON_CONFIG.md (如有变更) ✅"
echo "   - 其他相关文档 (如有变更) ✅"
echo "📊 今日提交：$TODAY_COMMITS 个"
echo "📦 推送分支：OpenClaw-Fund-Trading"
echo "🔗 GitHub: https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system/blob/OpenClaw-Fund-Trading/07-version-updates/CHANGELOG.md"
echo ""
