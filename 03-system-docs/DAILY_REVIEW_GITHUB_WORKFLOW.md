# 日终复盘 GitHub 推送工作流

**创建时间:** 2026-03-13  
**执行频率:** 每个交易日 22:00 后  
**状态:** ✅ 必须执行

---

## 📋 流程概述

```
22:00 日终复盘 → 生成报告 → 更新 state → Git 提交 → 推送到 GitHub → 飞书通知
```

---

## 🎯 必须推送的文件

### 1. 日终复盘报告

**路径:** `fund_challenge/daily_reviews/YYYY-MM-DD.md`

**内容:**
- 当日盈亏数据
- 持仓明细
- 操作总结
- 明日计划
- 风险提示

**示例:**
```bash
fund_challenge/daily_reviews/2026-03-13.md
```

### 2. 状态文件

**路径:** `fund_challenge/state.json`

**内容:**
- 最新净值
- 持仓份额
- 累计盈亏
- 现金余额

### 3. 交易账本

**路径:** `fund_challenge/ledger.jsonl`

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
2. 更新 `state.json` 中的净值
3. 生成 `daily_reviews/YYYY-MM-DD.md`

**模板:** 参考 `fund_challenge/daily_reviews/2026-03-13.md`

---

### 步骤 2: Git 提交

```bash
cd /home/admin/.openclaw/workspace

# 1. 添加文件
git add fund_challenge/daily_reviews/2026-03-13.md
git add fund_challenge/state.json
git add fund_challenge/ledger.jsonl

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

### 步骤 4: 飞书通知

**推送成功后通知飞书群:**

```bash
curl -X POST "https://open.feishu.cn/open-apis/bot/v2/hook/f1286a3e-4e41-4809-a0bc-fd2bbbbc3f10" \
  -H "Content-Type: application/json" \
  -d '{
    "msg_type": "text",
    "content": {
      "text": "✅ 3 月 13 日日终复盘已完成\n\n📊 当日盈亏：-9.42 元 (-0.94%)\n📈 累计盈亏：-9.42 元 (-0.94%)\n💾 数据已归档到 GitHub\n\n📁 文件位置:\n- 日终复盘：fund_challenge/daily_reviews/2026-03-13.md\n- 状态更新：fund_challenge/state.json\n\n🔗 GitHub: https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system"
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

**路径:** `05-scripts/push_daily_review.sh`

```bash
#!/bin/bash
# 日终复盘 GitHub 推送脚本

DATE=$(date +%Y-%m-%d)
WORKSPACE="/home/admin/.openclaw/workspace"
BRANCH="OpenClaw-Fund-Trading"

cd $WORKSPACE

# 检查文件是否存在
if [ ! -f "fund_challenge/daily_reviews/${DATE}.md" ]; then
    echo "❌ 复盘报告不存在：fund_challenge/daily_reviews/${DATE}.md"
    exit 1
fi

# Git 操作
git add fund_challenge/daily_reviews/${DATE}.md
git add fund_challenge/state.json
git add fund_challenge/ledger.jsonl

git commit -m "📊 添加 ${DATE} 日终复盘
- 自动提交"

git pull --rebase origin $BRANCH
git push origin $BRANCH

if [ $? -eq 0 ]; then
    echo "✅ 推送成功"
    
    # 飞书通知
    curl -X POST "https://open.feishu.cn/open-apis/bot/v2/hook/f1286a3e-4e41-4809-a0bc-fd2bbbbc3f10" \
      -H "Content-Type: application/json" \
      -d "{
        \"msg_type\": \"text\",
        \"content\": {
          \"text\": \"✅ ${DATE} 日终复盘已归档到 GitHub\"
        }
      }"
else
    echo "❌ 推送失败"
    exit 1
fi
```

**使用方法:**
```bash
chmod +x 05-scripts/push_daily_review.sh
./05-scripts/push_daily_review.sh
```

---

## ✅ 验收清单

每次日终复盘后检查：

- [ ] 复盘报告已生成 (`fund_challenge/daily_reviews/YYYY-MM-DD.md`)
- [ ] `state.json` 已更新（最新净值）
- [ ] `ledger.jsonl` 已更新（如有交易）
- [ ] Git 提交已完成
- [ ] GitHub 推送成功
- [ ] 飞书通知已发送
- [ ] GitHub 仓库可访问文件

---

## 🔍 验证方法

### 1. 检查本地文件

```bash
ls -lh fund_challenge/daily_reviews/
cat fund_challenge/state.json | python3 -m json.tool
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
https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system/tree/OpenClaw-Fund-Trading/fund_challenge/daily_reviews
```

### 4. 检查飞书消息

查看飞书群是否收到：
- 日终复盘卡片消息
- GitHub 归档完成通知

---

## 📊 示例：3 月 13 日推送

### 提交记录

```bash
commit 311a77d
Author: AI Assistant
Date:   Fri Mar 13 22:40:15 2026 +0800

    📝 更新 3 月 13 日交易数据和系统文档
    
    - 更新 state.json (3 月 13 日净值)
    - 添加 ledger.jsonl
    - 更新 MEMORY.md (统一飞书推送)
    - 添加系统文档:
      - 清理报告
      - Cron 问题分析
      - Cron 修复完成
      - 决策重推记录

commit 50a4547
Author: AI Assistant
Date:   Fri Mar 13 22:36:47 2026 +0800

    📊 添加 3 月 13 日日终复盘
    
    - 当日盈亏：-9.42 元 (-0.94%)
    - 累计盈亏：-9.42 元 (-0.94%)
    - 半导体领跌 -2.02%，科创 50 -0.72%，新能源电池 -0.07%
    - 满仓观望，无操作
    - 飞书推送完成
```

### 推送的文件

```
fund_challenge/
├── daily_reviews/
│   └── 2026-03-13.md          # 日终复盘报告
├── state.json                  # 状态文件
└── ledger.jsonl                # 交易账本
```

### 飞书通知

```
✅ 3 月 13 日日终复盘已完成

📊 当日盈亏：-9.42 元 (-0.94%)
📈 累计盈亏：-9.42 元 (-0.94%)
💾 数据已归档到 GitHub

📁 文件位置:
- 日终复盘：fund_challenge/daily_reviews/2026-03-13.md
- 状态更新：fund_challenge/state.json

🔗 GitHub: https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system
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
- `state.json`（仅净值和份额）
- `ledger.jsonl`（交易记录）

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

---

## 📚 相关文档

- `MEMORY.md` - 系统偏好配置
- `DAILY_REVIEW_ARCHIVE_YYYYMMDD.md` - 归档记录
- `03-system-docs/` - 系统文档目录

---

**最后更新:** 2026-03-13  
**下次执行:** 2026-03-14 (周六，非交易日，跳过)  
**实际下次:** 2026-03-17 (周二) 22:00
