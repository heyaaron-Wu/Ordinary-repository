#!/bin/bash
# 基金日终复盘 - 飞书推送脚本

DATE=${1:-$(date +%Y-%m-%d)}
REVIEW_FILE="../reviews/review-${DATE}.md"

# 飞书 Webhook URL (从 MEMORY.md 获取)
WEBHOOK="YOUR_FEISHU_WEBHOOK"

echo "📊 开始推送 ${DATE} 日终复盘到飞书..."

# 检查复盘文件
if [ ! -f "$REVIEW_FILE" ]; then
    echo "❌ 复盘文件不存在：$REVIEW_FILE"
    exit 1
fi

# 提取数据
TOTAL_PNL=$(grep "当日收益" "$REVIEW_FILE" 2>/dev/null | head -1 | awk -F'|' '{print $2}' | tr -d ' ' || echo "N/A")
PORTFOLIO_VALUE=$(grep "组合总值" "$REVIEW_FILE" 2>/dev/null | head -1 | awk -F'|' '{print $2}' | tr -d ' ' || echo "N/A")

# 简化消息
MESSAGE="📊 基金日终复盘 - ${DATE}

当日收益：${TOTAL_PNL} 元
组合总值：${PORTFOLIO_VALUE} 元

详细报告已保存到 GitHub:
https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system/blob/OpenClaw-Fund-Trading/08-fund-daily-review/reviews/review-${DATE}.md

⚠️ 市场有风险，投资需谨慎"

# 推送
echo "推送内容:"
echo "$MESSAGE"
echo ""

RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$WEBHOOK" \
  -H "Content-Type: application/json" \
  -d "{\"msg_type\":\"text\",\"content\":{\"text\":\"$MESSAGE\"}}")

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d':' -f2)
RESPONSE_BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:")

echo "HTTP 状态码：$HTTP_CODE"
echo "响应内容：$RESPONSE_BODY"

if [ "$HTTP_CODE" = "200" ]; then
    if echo "$RESPONSE_BODY" | grep -q '"StatusCode":0\|"code":0'; then
        echo "✅ 飞书推送成功！"
        exit 0
    fi
fi

echo "❌ 飞书推送失败，请检查 Webhook URL 是否正确"
echo "当前 Webhook: $WEBHOOK"
exit 1
