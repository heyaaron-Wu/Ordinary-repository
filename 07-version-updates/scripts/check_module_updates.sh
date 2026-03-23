#!/bin/bash
# 模块文档更新检查脚本
# 功能：检查各文件夹当日是否有更新，如有则更新对应 README.md 和 CHANGELOG.md

set -e

WORKSPACE="/home/admin/.openclaw/workspace"
CHANGELOG_FILE="$WORKSPACE/07-version-updates/CHANGELOG.md"
TODAY=$(date +%Y-%m-%d)

echo "🔍 模块文档更新检查"
echo "=================="
echo "日期：$TODAY"
echo ""

cd "$WORKSPACE"

# 检查今日是否有提交
TODAY_COMMITS=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --oneline 2>/dev/null | wc -l)

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

# 存储每个模块的今日提交详情
declare -A MODULE_COMMIT_DETAILS

# 检查每个模块
UPDATED_MODULES=()
CODE_CHANGE_MODULES=()

for module_path in "${!MODULES[@]}"; do
    module_name="${MODULES[$module_path]}"
    
    # 检查该模块今日是否有文件变更
    MODULE_COMMITS=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --oneline -- "$module_path" 2>/dev/null | wc -l)
    
    if [ "$MODULE_COMMITS" -gt 0 ]; then
        echo "✅ 模块更新：$module_name ($module_path)"
        echo "   提交数：$MODULE_COMMITS"
        
        # 获取提交详情
        COMMIT_DETAILS=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --oneline -- "$module_path" 2>/dev/null)
        MODULE_COMMIT_DETAILS["$module_path"]="$COMMIT_DETAILS"
        
        # 检查是否有代码/功能变更（非纯文档）
        MODULE_CODE_CHANGES=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --oneline -- "$module_path" 2>/dev/null | grep -v "📝\|docs\|文档" | wc -l)
        
        if [ "$MODULE_CODE_CHANGES" -gt 0 ]; then
            CODE_CHANGE_MODULES+=("$module_path")
            echo "   📊 包含代码/功能变更"
        else
            echo "   📝 仅文档更新"
        fi
        
        # 检查是否有 README.md
        README_PATH="$WORKSPACE/$module_path/README.md"
        if [ -f "$README_PATH" ]; then
            echo "   📄 README.md: 已存在"
            
            # 检查 README.md 是否需要更新（包含今日日期）
            if ! grep -q "$TODAY" "$README_PATH" 2>/dev/null; then
                echo "   📝 README.md: 需要更新最后更新时间"
                
                # 更新 README.md 中的最后更新时间
                if grep -q "最后更新：" "$README_PATH"; then
                    sed -i "s/最后更新：.*/最后更新：$TODAY/" "$README_PATH"
                elif grep -q "\*最后更新：" "$README_PATH"; then
                    sed -i "s/\*最后更新：.*/\*最后更新：$TODAY\*/" "$README_PATH"
                else
                    # 在文件末尾添加更新时间
                    echo "" >> "$README_PATH"
                    echo "*最后更新：$TODAY*" >> "$README_PATH"
                fi
                
                echo "   ✅ README.md 已更新"
            else
                echo "   ✅ README.md: 已包含今日更新"
            fi
        else
            echo "   ⚠️  README.md: 不存在（可创建模板）"
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
    MODULE_COMMITS=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --oneline -- "$module_path" 2>/dev/null | wc -l)
    UPDATE_SUMMARY+="- **$module_name** ($module_path): $MODULE_COMMITS 个提交\n"
done

echo -e "$UPDATE_SUMMARY"

# 更新 CHANGELOG.md
if [ -f "$CHANGELOG_FILE" ]; then
    echo "📝 更新 CHANGELOG.md..."
    
    # 检查是否已包含今日更新
    if grep -q "## \[.*\] - $TODAY" "$CHANGELOG_FILE" 2>/dev/null; then
        echo "✅ CHANGELOG.md 已包含今日更新"
    else
        # 获取当前最新版本号（从"## 📅 更新历史"之后查找，排除示例行）
        CURRENT_VERSION=$(awk '/^## 📅 更新历史/,0' "$CHANGELOG_FILE" | grep -oP '^\### \[v\K[0-9.]+' | head -1)
        if [ -z "$CURRENT_VERSION" ]; then
            CURRENT_VERSION="1.0.0"
        fi
        
        # 解析版本号
        MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
        MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
        PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)
        
        # 只有代码变更才递增版本号
        if [ ${#CODE_CHANGE_MODULES[@]} -gt 0 ]; then
            PATCH=$((PATCH + 1))
            VERSION_NUM="$MAJOR.$MINOR.$PATCH"
            echo "📊 版本号递增：v$CURRENT_VERSION → v$VERSION_NUM"
            VERSION_HEADER="### [v$VERSION_NUM] - $TODAY"
        else
            VERSION_NUM="$CURRENT_VERSION"
            echo "📊 版本号不变：v$VERSION_NUM (仅文档更新)"
            VERSION_HEADER="### [v$VERSION_NUM] - $TODAY (文档更新)"
        fi
        
        TEMP_CHANGELOG="/tmp/changelog_module_update_$$.md"
        cat > "$TEMP_CHANGELOG" << EOF

$VERSION_HEADER

#### 📁 模块更新
EOF
        
        for module_path in "${UPDATED_MODULES[@]}"; do
            module_name="${MODULES[$module_path]}"
            MODULE_COMMITS=$(git log --since="$TODAY 00:00:00" --until="$TODAY 23:59:59" --oneline -- "$module_path" 2>/dev/null | wc -l)
            echo "- **$module_name**: $MODULE_COMMITS 个提交" >> "$TEMP_CHANGELOG"
        done
        
        # 插入到 CHANGELOG.md（在"## 📅 更新历史"之后）
        HEADER_LINES=$(grep -n "^## 📅 更新历史" "$CHANGELOG_FILE" | cut -d: -f1)
        if [ -z "$HEADER_LINES" ]; then
            HEADER_LINES=20  # fallback
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
    fi
fi

# 提交变更
echo ""
echo "📤 提交文档更新..."
cd "$WORKSPACE"

# 添加 CHANGELOG.md
git add "$CHANGELOG_FILE" 2>/dev/null || true

# 添加所有更新过的 README.md
for module_path in "${UPDATED_MODULES[@]}"; do
    README_PATH="$WORKSPACE/$module_path/README.md"
    if [ -f "$README_PATH" ]; then
        git add "$README_PATH" 2>/dev/null || true
    fi
done

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
