# 基金挑战定时任务配置

**配置时间:** 2026-03-20  
**服务器:** iZrj9c7d48bli5s0wanvmyZ  
**工作目录:** /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge  
**推送平台:** 飞书 (Feishu)

---

## Crontab 配置

### 编辑 crontab
```bash
crontab -e
```

### 添加以下任务

```bash
# ============================================
# 基金挑战定时任务
# ============================================

# 09:00 - 健康检查 (交易日)
0 9 * * * cd /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge && python3 scripts/is_trading_day.py && python3 scripts/healthcheck_brief.py >> logs/healthcheck.log 2>&1

# 13:35 - 候选池刷新 (交易日)
35 13 * * * cd /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge && python3 scripts/is_trading_day.py && python3 scripts/universe_refresh_script_only.py --workspace /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge >> logs/universe_refresh.log 2>&1

# 14:00 - 决策生成 (交易日)
0 14 * * * cd /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge && python3 scripts/is_trading_day.py && python3 scripts/run_decision_pipeline.py --mode plan >> logs/decision.log 2>&1

# 14:48 - 执行门控 (交易日)
48 14 * * * cd /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge && python3 scripts/is_trading_day.py && python3 scripts/market_gate_checker.py --evidence evidence/latest.json >> logs/exec_gate.log 2>&1

# 20:05 - 日终复盘 (每日)
5 20 * * * cd /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge && python3 scripts/daily_bundle_runner.py >> logs/review.log 2>&1

# ============================================
# 监控脚本 (可选)
# ============================================

# 每 30 分钟检查一次退出信号 (交易时段)
*/30 9-15 * * * cd /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge && python3 scripts/exit_monitor.py --input cache/positions.json --compact >> logs/exit_monitor.log 2>&1

# 每周日 22:00 - 周报
0 22 * * 0 cd /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge && python3 scripts/weekly_report.py >> logs/weekly.log 2>&1
```

---

## 验证配置

### 1. 查看当前 crontab
```bash
crontab -l
```

### 2. 测试单个任务
```bash
# 测试候选池刷新
cd /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge
python3 scripts/is_trading_day.py && python3 scripts/universe_refresh_script_only.py --workspace /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge

# 测试执行门控
python3 scripts/market_gate_checker.py --evidence evidence/latest.json
```

### 3. 查看 cron 日志
```bash
# 查看 cron 服务状态
systemctl status cron

# 查看 cron 日志
grep CRON /var/log/syslog | tail -20
```

---

## 日志目录结构

```
logs/
├── healthcheck.log      # 健康检查日志
├── universe_refresh.log # 候选池刷新日志
├── decision.log         # 决策生成日志
├── exec_gate.log        # 执行门控日志
├── review.log           # 日终复盘日志
├── exit_monitor.log     # 退出监控日志
└── weekly.log           # 周报日志
```

### 创建日志目录
```bash
mkdir -p /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/logs
```

---

## 任务说明

### 13:35 候选池刷新
- **用途:** 扫描全市场基金，更新候选池
- **触发条件:** 交易日 + 距离上次刷新≥3 天 或 持仓触发退出
- **推送:** 仅当发现评分≥80 的候选基金时推送飞书

### 14:48 执行门控
- **用途:** 最终执行确认，确保 15:00 前决策可执行
- **检查项:**
  - 是否交易日
  - 证据新鲜度 (≤30 分钟)
  - 时间窗口 (14:48-15:00 最后确认窗口)
- **推送:** 门控未通过时推送飞书告警

---

## 飞书推送集成

所有脚本已集成飞书推送，webhook 配置:
```
https://open.feishu.cn/open-apis/bot/v2/hook/f1286a3e-4e41-4809-a0bc-fd2bbbbc3f10
```

### 推送场景
| 脚本 | 推送条件 | 推送内容 |
|------|----------|----------|
| signal_fusion_scorer.py | 评分≥60 | TOP3 候选基金 + 评分 + 建议 |
| exit_monitor.py | 有高/中优先级退出信号 | 止损/止盈告警 + 紧急度 |
| universe_refresh_script_only.py | 发现评分≥80 的候选 | 候选池更新通知 |

### 飞书推送示例

**信号评分推送:**
```bash
python3 fund_challenge/scripts/signal_fusion_scorer.py --feishu
```

**退出监控告警:**
```bash
python3 fund_challenge/scripts/exit_monitor.py --input cache/positions.json --feishu
```

---

## 故障排除

### 任务未执行
1. 检查 cron 服务：`systemctl status cron`
2. 检查 crontab 语法：`crontab -l`
3. 检查日志：`grep CRON /var/log/syslog`

### 脚本执行失败
1. 检查 Python 路径：`which python3`
2. 检查依赖：`pip3 list | grep requests`
3. 手动执行脚本查看错误

### 飞书推送失败
1. 检查网络连接：`curl https://open.feishu.cn`
2. 检查 webhook URL 是否正确
3. 查看脚本日志中的错误信息
4. 确认飞书机器人已添加到目标群聊

---

## 备份与恢复

### 备份当前 crontab
```bash
crontab -l > crontab_backup_$(date +%Y%m%d).txt
```

### 恢复 crontab
```bash
crontab crontab_backup_YYYYMMDD.txt
```

---

## 快速配置脚本

### 一键添加所有任务
```bash
# 备份现有配置
crontab -l > crontab_backup_$(date +%Y%m%d).txt 2>/dev/null

# 添加新任务
(crontab -l 2>/dev/null; cat << 'EOF'

# 基金挑战定时任务
35 13 * * * cd /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge && python3 scripts/is_trading_day.py && python3 scripts/universe_refresh_script_only.py --workspace /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge >> logs/universe_refresh.log 2>&1
48 14 * * * cd /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge && python3 scripts/is_trading_day.py && python3 scripts/market_gate_checker.py --evidence evidence/latest.json >> logs/exec_gate.log 2>&1

EOF
) | crontab -

# 验证
crontab -l
```

---

*配置完成后，请运行 `crontab -l` 验证任务已正确添加*
