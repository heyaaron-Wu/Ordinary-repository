# 定时任务优化报告 - 2026-03-19

## 📋 问题背景

### 问题 1:14:00 决策任务连续超时
- **错误次数**: 5 次连续错误
- **错误原因**: `cron: job execution timed out`
- **原超时时间**: 300 秒
- **影响**: 无法生成有效决策，导致 14:48 门控缺少参考依据

### 问题 2:14:48 执行门控无推送
- **现象**: 任务执行成功但无推送 (`deliveryStatus: not-delivered`)
- **原因**: 原配置仅在推翻 14:00 决策时才推送
- **影响**: 14:00 失败时，用户无法获知状态

---

## ✅ 优化方案

### 方案 3: 添加兜底推送 + 优化 14:00 任务

#### 1️⃣ 14:00 决策任务优化

| 项目 | 优化前 | 优化后 |
|------|--------|--------|
| 超时时间 | 300 秒 | **600 秒** |
| 错误计数 | 5 次 | **0 次（已重置）** |
| 推送策略 | 可选 | **必须推送** |
| 输出限制 | <300 字 | **<200 字** |
| 时间分配 | 无明确分配 | **分步骤限时** |

**新的时间分配：**
- 交易日检查：60 秒内
- 快速预检：120 秒内
- 读取证据：120 秒内
- 生成决策：180 秒内
- 推送结果：60 秒内
- **总计**: 540 秒（预留 60 秒缓冲）

**输出模板：**
```
📊 14:00 决策报告

【决策】HOLD/BUY/SELL
【理由】1-2 句话说明核心原因
【截止】15:00 前执行
【状态】持仓市值 XXX 元，现金 XXX 元
```

---

#### 2️⃣ 14:48 执行门控优化

| 项目 | 优化前 | 优化后 |
|------|--------|--------|
| 超时时间 | 300 秒 | **600 秒** |
| 推送策略 | 仅推翻时推送 | **新增兜底推送** |

**新的推送策略：**

| 14:00 决策 | 14:48 评分 | 推送行为 |
|-----------|-----------|----------|
| HOLD | 任意 | ❌ 静默 |
| BUY/SELL | ≥60 分 | ❌ 静默确认 |
| BUY/SELL | <60 分 | ✅ 推送 HOLD 告警（推翻原决策） |
| **不可用/失败** | 任意 | ✅ **兜底推送**（14:00 失败告警 + 当前状态） |

**兜底推送示例：**
```
⚠️ 14:48 执行门控 - 兜底告警

14:00 决策：失败/超时
门控评分：XX/100
当前状态：持仓市值 XXX 元
建议：人工介入决策
```

---

## 📊 配置变更详情

### 文件位置
```
/home/admin/.openclaw/cron/jobs.json
```

### 变更摘要
```json
// fund-1400-decision
{
  "timeoutSeconds": 600,  // 300 → 600
  "state": {
    "consecutiveErrors": 0  // 5 → 0
  }
}

// fund-1448-exec-gate
{
  "timeoutSeconds": 600,  // 300 → 600
  "message": "新增兜底推送逻辑"
}
```

### 备份文件
```
/home/admin/.openclaw/cron/jobs.json.backup.20260319_151500
```

---

## 🧪 测试验证

### 飞书 Webhook 测试
```bash
curl -s -X POST "https://open.feishu.cn/open-apis/bot/v2/hook/f1286a3e-4e41-4809-a0bc-fd2bbbbc3f10" \
  -H "Content-Type: application/json" \
  -d '{"msg_type":"text","content":{"text":"测试消息"}}'
```

**结果**: ✅ 推送成功 (`StatusCode: 0, msg: success`)

---

## 📅 下次运行时间

| 任务 | 下次运行时间 |
|------|-------------|
| fund-1400-decision | 下一个交易日 14:00 |
| fund-1448-exec-gate | 下一个交易日 14:48 |

---

## ⚠️ 注意事项

1. **观察下次执行**: 重点关注 14:00 任务是否能在 600 秒内完成
2. **监控推送**: 验证 14:00 和 14:48 的推送是否正常
3. **兜底推送测试**: 如果 14:00 再次失败，验证 14:48 兜底推送是否触发
4. **错误计数监控**: 如果连续错误再次达到 3 次，任务会自动暂停

---

## 🔧 手动干预命令

### 检查错误状态
```bash
# 查看任务运行日志
cat /home/admin/.openclaw/cron/runs/fund-1400-decision.jsonl | tail -5
cat /home/admin/.openclaw/cron/runs/fund-1448-exec-gate.jsonl | tail -5
```

### 重置错误计数
```bash
# 如果需要手动重置
python3 -c "
import json
with open('/home/admin/.openclaw/cron/jobs.json', 'r') as f:
    data = json.load(f)
for job in data['jobs']:
    if job['name'] in ['fund-1400-decision', 'fund-1448-exec-gate']:
        job['state']['consecutiveErrors'] = 0
with open('/home/admin/.openclaw/cron/jobs.json', 'w') as f:
    json.dump(data, f, indent=2)
"
```

### 手动触发测试
```bash
# 手动运行 14:00 决策脚本
python3 /home/admin/.openclaw/workspace/skills/fund-challenge/fund_challenge/scripts/is_trading_day.py
python3 /home/admin/.openclaw/workspace/skills/fund-challenge/fund_challenge/scripts/preflight_guard.py --phase PLAN_ONLY --compact --workspace /home/admin/.openclaw/workspace/skills/fund-challenge
```

---

**优化完成时间**: 2026-03-19 15:15  
**优化执行者**: AI Assistant  
**下次回顾**: 2026-03-20 (观察一天后)
