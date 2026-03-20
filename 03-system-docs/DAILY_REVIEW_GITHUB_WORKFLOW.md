# 日终复盘 GitHub 推送工作流

**创建时间:** 2026-03-13  
**执行频率:** 每个交易日 22:00 后  
**状态:** ✅ 必须执行

---

## 📋 流程概述

```
22:00 日终复盘 → 生成报告 → 更新 state → Git 提交 → 推送到 GitHub
```

**注意:** 不需要飞书通知 GitHub 推送完成

---

## 🎯 必须推送的文件

### 1. 日终复盘报告

**路径:** `08-fund-daily-review/reviews/YYYY-MM-DD.md`

**内容:**
- 当日盈亏数据
- 持仓明细
- 操作总结
- 明日计划
- 风险提示

**示例:**
```bash
08-fund-daily-review/reviews/2026-03-13.md
```

### 2. 状态文件

**路径:** `08-fund-daily-review/state.json`

**内容:**
- 最新净值
- 持仓份额
- 累计盈亏
- 现金余额

### 3. 交易账本

**路径:** `08-fund-daily-review/ledger.jsonl`

**内容:**
- 所有交易记录
- 买卖操作
- 分红记录

---

## 📝 标准操作流程

### 步骤 1: 生成复盘报告

**时间:** 22:00 后（净值更新完成）

**操作:**
1. 根据用户提供的实际收益数据
2. 更新 `08-fund-daily-review/state.json` 中的净值
3. 生成 `08-fund-daily-review/reviews/YYYY-MM-DD.md`

**模板:** 参考 `08-fund-daily-review/reviews/2026-03-13.md`

---

### 步骤 2: Git 提交

```bash
cd /home/admin/.openclaw/workspace

# 1. 添加文件
git add 08-fund-daily-review/reviews/2026-03-13.md
git add 08-fund-daily-review/state.json
git add 08-fund-daily-review/ledger.jsonl

# 2. 查看状态
git status

# 3. 提交
git commit -m "📊 添加 3 月 13 日日终复盘

- 当日盈亏：-9.42 元 (-0.94%)
- 累计盈亏：-9.42 元 (-0.94%)
- 半导体领跌 -2.02%，科创 50 -0.72%，新能源电池 -0.07%
- 满仓观望，无操作
- 飞书推送完成"
```

**提交信息格式:**
```
📊 添加 MM 月 DD 日日终复盘

- 当日盈亏：XXX 元 (X.XX%)
- 累计盈亏：XXX 元 (X.XX%)
- 简要说明（涨跌幅、操作等）
- 飞书推送完成
```

---

### 步骤 3: 推送到 GitHub

```bash
# 1. 先拉取远程更新（避免冲突）
git pull --rebase origin OpenClaw-Fund-Trading

# 2. 推送
git push origin OpenClaw-Fund-Trading
```

**处理冲突:**
```bash
# 如果有冲突
git status  # 查看冲突文件
# 手动解决冲突
git add <resolved_file>
git rebase --continue
git push origin OpenClaw-Fund-Trading
```

---

### 步骤 4: 飞书推送复盘报告

**推送成功后通知飞书群（仅推送复盘报告，不通知 GitHub）:**

```bash
curl -X POST "YOUR_FEISHU_WEBHOOK" \
  -H "Content-Type: application/json" \
  -d '{
    "msg_type": "interactive",
    "card": {
      "header": {
        "title": {"tag": "plain_text", "content": "📊 基金日终复盘 - 2026-03-13"},
        "template": "red"
      },
      "elements": [
        {
          "tag": "div",
          "text": {
            "tag": "lark_md",
            "content": "**【今日盈亏】**\n🔴 -9.42 元 (-0.94%)\n\n**【累计收益】**\n• 累计盈亏：-9.42 元\n• 累计收益率：-0.94%"
          }
        }
      ]
    }
  }'
```

**预期响应:**
```json
{"StatusCode":0,"StatusMessage":"success","code":0,"data":{},"msg":"success"}
```

---

## 🔧 自动化脚本（可选）

### 创建推送脚本

**路径:** `08-fund-daily-review/scripts/push_daily_review.sh`

```bash
#!/bin/bash
# 日终复盘 GitHub 推送脚本

DATE=$(date +%Y-%m-%d)
WORKSPACE="/home/admin/.openclaw/workspace"
BRANCH="OpenClaw-Fund-Trading"

cd $WORKSPACE

# 检查文件是否存在
if [ ! -f "08-fund-daily-review/reviews/${DATE}.md" ]; then
    echo "❌ 复盘报告不存在：08-fund-daily-review/reviews/${DATE}.md"
    exit 1
fi

# Git 操作
git add 08-fund-daily-review/reviews/${DATE}.md
git add 08-fund-daily-review/state.json
git add 08-fund-daily-review/ledger.jsonl

git commit -m "📊 添加 ${DATE} 日终复盘
- 自动提交"

git pull --rebase origin $BRANCH
git push origin $BRANCH

if [ $? -eq 0 ]; then
    echo "✅ 推送成功"
else
    echo "❌ 推送失败"
    exit 1
fi
```

**使用方法:**
```bash
chmod +x 08-fund-daily-review/scripts/push_daily_review.sh
./08-fund-daily-review/scripts/push_daily_review.sh
```

---

## ✅ 验收清单

每次日终复盘后检查：

- [ ] 复盘报告已生成 (`08-fund-daily-review/reviews/YYYY-MM-DD.md`)
- [ ] `state.json` 已更新（最新净值）
- [ ] `ledger.jsonl` 已更新（如有交易）
- [ ] Git 提交已完成
- [ ] GitHub 推送成功
- [ ] 飞书复盘报告已发送
- [ ] GitHub 仓库可访问文件

---

## 🔍 验证方法

### 1. 检查本地文件

```bash
ls -lh 08-fund-daily-review/reviews/
cat 08-fund-daily-review/state.json | python3 -m json.tool
```

### 2. 检查 Git 状态

```bash
cd /home/admin/.openclaw/workspace
git log --oneline -5
git status
```

### 3. 检查 GitHub 仓库

访问：
```
https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system/tree/OpenClaw-Fund-Trading/08-fund-daily-review
```

### 4. 检查飞书消息

查看飞书群是否收到日终复盘卡片消息

---

## 📊 示例：3 月 13 日推送

### 提交记录

```bash
commit 68534a9
Author: AI Assistant
Date:   Sat Mar 14 00:34:15 2026 +0800

    📁 重构：迁移基金复盘文件到新目录
    
    - 删除 fund_challenge/ 文件夹
    - 迁移到 08-fund-daily-review/
      - reviews/2026-03-13.md (日终复盘)
      - state.json (状态文件)
      - ledger.jsonl (交易账本)
    - 添加系统文档
    - 更新 MEMORY.md
```

### 推送的文件

```
08-fund-daily-review/
├── reviews/
│   └── 2026-03-13.md          # 日终复盘报告
├── state.json                  # 状态文件
└── ledger.jsonl                # 交易账本
```

### 飞书通知

```
📊 基金日终复盘 - 2026-03-13

【今日盈亏】
🔴 -9.42 元 (-0.94%)

【累计收益】
• 累计盈亏：-9.42 元
• 累计收益率：-0.94%
```

---

## ⚠️ 注意事项

### 隐私保护

**不要推送:**
- `04-private-configs/` 目录内容
- 含 Webhook URL 的配置文件
- 个人敏感信息

**可以推送:**
- 日终复盘报告（已脱敏）
- state.json（仅净值和份额）
- ledger.jsonl（交易记录）

### 推送时间

- **最佳时间:** 22:00-23:00（净值更新后）
- **最晚时间:** 当日 23:59 前
- **非交易日:** 跳过

### 冲突处理

如遇推送冲突：
1. 不要强制推送 (`git push -f`)
2. 先 `git pull --rebase`
3. 解决冲突后再推送
4. 必要时联系人工介入

### 飞书通知

- ✅ 发送日终复盘报告到飞书
- ❌ **不需要**发送 GitHub 推送完成通知

---

## 📚 相关文档

- `MEMORY.md` - 系统偏好配置
- `08-fund-daily-review/README.md` - 目录说明
- `08-fund-daily-review/PUSH_GUIDE.md` - 推送指南

---

**最后更新:** 2026-03-14  
**下次执行:** 2026-03-17 (周二) 22:00
