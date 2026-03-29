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
echo "📊 检查复盘文档..."

# 检查是否有复盘文档提交（日终复盘/周复盘）
# 检测文件路径：08-fund-daily-review/reviews/ 或 08-fund-daily-review/weekly/
FUND_REVIEW_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null | grep -E "08-fund-daily-review/(reviews|weekly)/.*\.md$" | wc -l)

if [ "$FUND_REVIEW_FILES" -eq 0 ]; then
    echo "✅ 今日无复盘文档，跳过版本更新"
    exit 0
fi

echo "发现 $FUND_REVIEW_FILES 个复盘文档"
git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null | grep -E "08-fund-daily-review/(reviews|weekly)/.*\.md$"
echo ""

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

# 创建新版本条目（只记录复盘文档）
cat > "$TEMP_CHANGELOG" << EOF

### [v$VERSION_NUM] - $TODAY

#### 📊 复盘文档
EOF

# 添加复盘文档文件名
git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null | grep -E "08-fund-daily-review/(reviews|weekly)/.*\.md$" | while read filepath; do
    # 提取文件名
    FILENAME=$(basename "$filepath")
    echo "- 📄 $FILENAME" >> "$TEMP_CHANGELOG"
done

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
