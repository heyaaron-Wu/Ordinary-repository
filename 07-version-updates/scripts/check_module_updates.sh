#!/bin/bash
# 模块文档更新检查脚本
# 功能：检查各文件夹当日是否有更新，如有则更新对应 README.md

set -e

WORKSPACE="/home/admin/.openclaw/workspace"
TODAY=$(date +%Y-%m-%d)
TODAY_COMMITS=$(git -C "$WORKSPACE" log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --oneline 2>/dev/null | wc -l)

echo "🔍 模块文档更新检查"
echo "=================="
echo "日期：$TODAY"
echo ""

cd "$WORKSPACE"

# 检查今日是否有提交
if [ "$TODAY_COMMITS" -eq 0 ]; then
    echo "✅ 今日无提交记录，无需更新模块文档"
    exit 0
fi

echo "发现 $TODAY_COMMITS 个提交"
echo ""

# 定义需要检查的模块
declare -A MODULES=(
    ["01-public-configs"]="基础配置"
    ["02-skill-docs/skills"]="技能文档"
    ["03-system-docs"]="系统文档"
    ["04-private-configs"]="私有配置"
    ["05-scripts"]="工具脚本"
    ["06-data"]="数据文件"
    ["07-version-updates"]="版本更新"
    ["08-fund-daily-review"]="基金日终复盘"
)

# 检查每个模块
UPDATED_MODULES=()
for module_path in "${!MODULES[@]}"; do
    module_name="${MODULES[$module_path]}"
    
    # 检查该模块今日是否有文件变更
    MODULE_COMMITS=$(git -C "$WORKSPACE" log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --oneline -- "$module_path" 2>/dev/null | wc -l)
    
    if [ "$MODULE_COMMITS" -gt 0 ]; then
        echo "✅ 模块更新：$module_name ($module_path)"
        echo "   提交数：$MODULE_COMMITS"
        
        # 检查是否有 README.md
        if [ -f "$WORKSPACE/$module_path/README.md" ]; then
            echo "   📄 README.md: 已存在"
        else
            echo "   ⚠️  README.md: 不存在"
        fi
        
        UPDATED_MODULES+=("$module_path")
        echo ""
    fi
done

# 如果没有模块更新
if [ ${#UPDATED_MODULES[@]} -eq 0 ]; then
    echo "✅ 今日无模块更新，无需更新文档"
    exit 0
fi

# 生成更新摘要
echo "📝 生成更新摘要..."
UPDATE_SUMMARY="# 模块更新摘要 - $TODAY\n\n"
UPDATE_SUMMARY+="今日共更新 ${#UPDATED_MODULES[@]} 个模块：\n\n"

for module_path in "${UPDATED_MODULES[@]}"; do
    module_name="${MODULES[$module_path]}"
    MODULE_COMMITS=$(git -C "$WORKSPACE" log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --oneline -- "$module_path" 2>/dev/null | wc -l)
    UPDATE_SUMMARY+="- **$module_name** ($module_path): $MODULE_COMMITS 个提交\n"
done

echo -e "$UPDATE_SUMMARY"

# 更新 07-version-updates/CHANGELOG.md
CHANGELOG_FILE="$WORKSPACE/07-version-updates/CHANGELOG.md"
if [ -f "$CHANGELOG_FILE" ]; then
    echo "📝 更新 CHANGELOG.md..."
    
    # 检查是否已包含今日更新
    if grep -q "## \[.*\] - $TODAY" "$CHANGELOG_FILE" 2>/dev/null; then
        echo "✅ CHANGELOG.md 已包含今日更新"
    else
        # 生成版本号
        VERSION_NUM=$TODAY_COMMITS
        
        TEMP_CHANGELOG="/tmp/changelog_update_$$.md"
        cat > "$TEMP_CHANGELOG" << EOF

### [v1.0.$VERSION_NUM] - $TODAY

#### 📁 模块更新
EOF
        
        for module_path in "${UPDATED_MODULES[@]}"; do
            module_name="${MODULES[$module_path]}"
            MODULE_COMMITS=$(git -C "$WORKSPACE" log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --oneline -- "$module_path" 2>/dev/null | wc -l)
            echo "- **$module_name**: $MODULE_COMMITS 个提交" >> "$TEMP_CHANGELOG"
        done
        
        # 插入到 CHANGELOG.md
        {
            head -n 20 "$CHANGELOG_FILE"
            cat "$TEMP_CHANGELOG"
            echo ""
            tail -n +21 "$CHANGELOG_FILE"
        } > "${CHANGELOG_FILE}.tmp"
        
        mv "${CHANGELOG_FILE}.tmp" "$CHANGELOG_FILE"
        rm -f "$TEMP_CHANGELOG"
        
        echo "✅ CHANGELOG.md 已更新"
    fi
fi

# 提交变更
echo ""
echo "📤 提交文档更新..."
cd "$WORKSPACE"

git add "$CHANGELOG_FILE" 2>/dev/null || true

COMMIT_MSG="📝 自动更新模块文档 - $TODAY"
git commit -m "$COMMIT_MSG" 2>/dev/null || echo "无变更或已提交"

# 推送
echo "🚀 推送到 GitHub..."
git pull --rebase || true
git push origin OpenClaw-Fund-Trading

echo ""
echo "================================"
echo "✅ 模块文档更新检查完成！"
echo ""
echo "📊 今日提交：$TODAY_COMMITS 个"
echo "📁 更新模块：${#UPDATED_MODULES[@]} 个"
echo "📄 更新文件：CHANGELOG.md"
echo "🔗 GitHub: https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system/blob/OpenClaw-Fund-Trading/07-version-updates/CHANGELOG.md"
echo ""
