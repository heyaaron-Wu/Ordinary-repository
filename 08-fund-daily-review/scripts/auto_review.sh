#!/bin/bash
# 基金日终复盘自动化脚本
# 功能：生成复盘报告 → 推送到 GitHub → 推送到飞书

set -e

# 配置
WORKSPACE="/home/admin/.openclaw/workspace"
REVIEW_DIR="$WORKSPACE/08-fund-daily-review/reviews"
SCRIPTS_DIR="$WORKSPACE/08-fund-daily-review/scripts"
STATE_FILE="$WORKSPACE/fund_challenge/state.json"
DATE=${1:-$(date +%Y-%m-%d)}

echo "🦞 OpenClaw 基金日终复盘自动化"
echo "================================"
echo "日期：$DATE"
echo ""

# 步骤 1: 生成复盘报告
echo "📝 步骤 1: 生成复盘报告..."
cd "$WORKSPACE"
python3 "$SCRIPTS_DIR/daily_review_generator.py" \
  --state "$STATE_FILE" \
  --output "$REVIEW_DIR/" \
  --date "$DATE"

REVIEW_FILE="$REVIEW_DIR/review-${DATE}.md"
if [ -f "$REVIEW_FILE" ]; then
    echo "✅ 复盘报告已生成：$REVIEW_FILE"
else
    echo "❌ 复盘报告生成失败"
    exit 1
fi
echo ""

# 步骤 2: 提交到 Git
echo "📤 步骤 2: 提交到 GitHub..."
cd "$WORKSPACE"
git add "$REVIEW_FILE"
git commit -m "📊 添加 ${DATE} 日终复盘报告" || echo "无变更或已提交"
echo "✅ Git 提交完成"
echo ""

# 步骤 3: 推送到 GitHub
echo "🚀 步骤 3: 推送到 GitHub..."
cd "$WORKSPACE"
git pull --rebase || true
git push origin OpenClaw-Fund-Trading
echo "✅ GitHub 推送成功"
echo ""

# 步骤 4: 推送到飞书
echo "📱 步骤 4: 推送到飞书..."
cd "$SCRIPTS_DIR"

# 提取关键数据
TOTAL_PNL=$(grep "当日收益" "$REVIEW_FILE" | head -1 | cut -d'|' -f2 | tr -d ' ' | cut -d'元' -f1)
PORTFOLIO_VALUE=$(grep "组合总值" "$REVIEW_FILE" | head -1 | cut -d'|' -f2 | tr -d ' ' | cut -d'元' -f1)
POSITIONS_COUNT=$(grep "持仓数量" "$REVIEW_FILE" | head -1 | cut -d'|' -f2 | tr -d ' ')

# 飞书 Webhook
WEBHOOK="YOUR_FEISHU_WEBHOOK"

# 构建消息
if [[ "$TOTAL_PNL" == *"+"* ]]; then
    PNL_ICON="✅"
elif [[ "$TOTAL_PNL" == *"-"* ]]; then
    PNL_ICON="❌"
else
    PNL_ICON="⚠️"
fi

MESSAGE="📊 基金日终复盘 - ${DATE}

【持仓概览】
• 持仓数量：${POSITIONS_COUNT:-N/A}
• 当日收益：${TOTAL_PNL:-N/A}元 ${PNL_ICON}
• 组合总值：${PORTFOLIO_VALUE:-N/A}元

【GitHub 存档】
https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system/blob/OpenClaw-Fund-Trading/08-fund-daily-review/reviews/review-${DATE}.md

⚠️ 市场有风险，投资需谨慎"

# 推送飞书
RESPONSE=$(curl -s -X POST "$WEBHOOK" \
  -H "Content-Type: application/json" \
  -d "{\"msg_type\":\"text\",\"content\":{\"text\":\"$MESSAGE\"}}")

if echo "$RESPONSE" | grep -q '"StatusCode":0\|"code":0\|"msg":"success"'; then
    echo "✅ 飞书推送成功！"
else
    echo "⚠️ 飞书推送失败（可能 Webhook 配置问题）"
    echo "响应：$RESPONSE"
    echo "请检查飞书机器人配置"
fi
echo ""

# 完成
echo "================================"
echo "✅ 日终复盘完成！"
echo ""
echo "📄 报告文件：$REVIEW_FILE"
echo "🔗 GitHub 链接：https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system/blob/OpenClaw-Fund-Trading/08-fund-daily-review/reviews/review-${DATE}.md"
echo ""
