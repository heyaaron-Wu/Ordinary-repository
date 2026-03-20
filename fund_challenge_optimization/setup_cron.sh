#!/bin/bash
# 基金挑战定时任务配置脚本
# 自动添加 crontab 任务

set -e

WORKSPACE="/home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge"
BACKUP_FILE="crontab_backup_$(date +%Y%m%d_%H%M%S).txt"

echo "========================================"
echo "基金挑战定时任务配置脚本"
echo "========================================"
echo ""

# 1. 备份现有配置
echo "[1/4] 备份现有 crontab 配置..."
crontab -l > "$BACKUP_FILE" 2>/dev/null || echo "无现有配置，跳过备份"
echo "✅ 备份完成：$BACKUP_FILE"
echo ""

# 2. 创建日志目录
echo "[2/4] 创建日志目录..."
mkdir -p "$WORKSPACE/logs"
echo "✅ 日志目录：$WORKSPACE/logs"
echo ""

# 3. 添加定时任务
echo "[3/4] 添加定时任务..."

# 定义要添加的任务
CRON_TASKS="# 基金挑战定时任务 (由 setup_cron.sh 添加于 $(date +%Y-%m-%d))
# 13:35 - 候选池刷新 (交易日)
35 13 * * * cd $WORKSPACE && python3 scripts/is_trading_day.py && python3 scripts/universe_refresh_script_only.py --workspace $(dirname $WORKSPACE) >> logs/universe_refresh.log 2>&1
# 14:48 - 执行门控 (交易日)
48 14 * * * cd $WORKSPACE && python3 scripts/is_trading_day.py && python3 scripts/market_gate_checker.py --evidence evidence/latest.json >> logs/exec_gate.log 2>&1
"

# 检查任务是否已存在
if crontab -l 2>/dev/null | grep -q "fund-challenge"; then
    echo "⚠️  检测到已有基金挑战任务，跳过添加"
else
    # 添加任务
    (crontab -l 2>/dev/null; echo "$CRON_TASKS") | crontab -
    echo "✅ 定时任务添加成功"
fi
echo ""

# 4. 验证配置
echo "[4/4] 验证配置..."
echo ""
echo "当前 crontab 配置:"
echo "----------------------------------------"
crontab -l | grep -A5 "基金挑战" || echo "未找到基金挑战任务"
echo "----------------------------------------"
echo ""

# 测试脚本可执行性
echo "测试脚本可执行性:"
for script in universe_refresh_script_only.py market_gate_checker.py; do
    if [ -f "$WORKSPACE/scripts/$script" ]; then
        echo "✅ $script 存在"
    else
        echo "❌ $script 不存在"
    fi
done
echo ""

# 完成
echo "========================================"
echo "配置完成!"
echo "========================================"
echo ""
echo "下一步:"
echo "1. 手动测试任务执行:"
echo "   cd $WORKSPACE"
echo "   python3 scripts/market_gate_checker.py --compact"
echo ""
echo "2. 查看 cron 日志:"
echo "   grep CRON /var/log/syslog | tail -10"
echo ""
echo "3. 如需恢复原配置:"
echo "   crontab $BACKUP_FILE"
echo ""
