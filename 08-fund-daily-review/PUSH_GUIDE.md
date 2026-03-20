# 基金日终复盘 - 自动化推送指南

**同时推送到 GitHub 和飞书群**

---

## 🚀 快速开始

### 一键自动化（推荐）

```bash
# 生成今日复盘并推送
cd /home/admin/.openclaw/workspace
bash 08-fund-daily-review/scripts/auto_review.sh

# 生成指定日期复盘并推送
bash 08-fund-daily-review/scripts/auto_review.sh 2026-03-12
```

**自动化流程:**
1. ✅ 生成复盘报告
2. ✅ 提交到 Git
3. ✅ 推送到 GitHub
4. ✅ 推送到飞书群

---

## 📱 飞书推送配置

### 步骤 1: 创建飞书机器人

1. 打开飞书群设置
2. 选择 "群机器人"
3. 点击 "添加机器人"
4. 选择 "自定义机器人"
5. 填写机器人信息：
   - 名称：基金复盘助手
   - 头像：📊（可选）
6. **复制 Webhook URL**

### 步骤 2: 配置 Webhook

编辑推送脚本，替换 Webhook URL：

```bash
# 编辑推送脚本
vim 08-fund-daily-review/scripts/push_to_feishu.sh

# 找到这一行并替换为你的 Webhook
WEBHOOK="YOUR_FEISHU_WEBHOOK"  # 请替换为实际的飞书 webhook
```

### 步骤 3: 测试推送

```bash
# 测试推送
cd 08-fund-daily-review/scripts
bash push_to_feishu.sh 2026-03-12
```

---

## 📊 推送效果

### 飞书消息示例

```
📊 基金日终复盘 - 2026-03-12

【持仓概览】
• 持仓数量：3 只
• 当日收益：-7.04 元 ❌
• 组合总值：992.48 元

【GitHub 存档】
https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system/blob/OpenClaw-Fund-Trading/08-fund-daily-review/reviews/review-2026-03-12.md

⚠️ 市场有风险，投资需谨慎
```

### GitHub 报告

查看完整的 Markdown 格式复盘报告：
```
https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system/blob/OpenClaw-Fund-Trading/08-fund-daily-review/reviews/review-2026-03-12.md
```

---

## 🔧 脚本说明

### auto_review.sh - 自动化脚本

**功能:**
- 生成复盘报告
- Git 提交
- GitHub 推送
- 飞书推送

**使用方法:**
```bash
# 今日复盘
bash auto_review.sh

# 指定日期
bash auto_review.sh 2026-03-12
```

**参数说明:**
- `$1`: 日期（可选，默认今日）

---

### push_to_feishu.sh - 飞书推送脚本

**功能:**
- 提取复盘数据
- 构建推送消息
- 推送到飞书

**使用方法:**
```bash
# 推送指定日期复盘
bash push_to_feishu.sh 2026-03-12
```

**推送内容:**
- 持仓数量
- 当日收益
- 组合总值
- GitHub 链接
- 风险提示

---

### daily_review_generator.py - 报告生成器

**功能:**
- 读取状态文件
- 计算当日盈亏
- 生成 Markdown 报告

**使用方法:**
```bash
python3 daily_review_generator.py \
  --state ../../fund_challenge/state.json \
  --output ../reviews/ \
  --date 2026-03-12
```

**参数:**
- `--state`: 状态文件路径
- `--output`: 输出目录
- `--date`: 日期
- `--push`: 推送到飞书（可选）
- `--webhook`: 飞书 Webhook URL（可选）

---

## ⏰ 定时任务配置

### 方法 1: OpenClaw Cron

在 OpenClaw 中配置定时任务：

```json
{
  "name": "fund-2200-review",
  "description": "基金挑战 - 22:00 日终复盘",
  "schedule": "0 22 * * 1-5",
  "payload": {
    "kind": "agentTurn",
    "message": "bash /home/admin/.openclaw/workspace/08-fund-daily-review/scripts/auto_review.sh"
  }
}
```

### 方法 2: System Cron

```bash
# 编辑 crontab
crontab -e

# 添加每日 22:00 执行
0 22 * * 1-5 cd /home/admin/.openclaw/workspace/08-fund-daily-review/scripts && bash auto_review.sh
```

---

## 📝 文件结构

```
08-fund-daily-review/
├── README.md                      # 使用说明
├── scripts/
│   ├── auto_review.sh            # 自动化脚本 ⭐
│   ├── push_to_feishu.sh         # 飞书推送脚本
│   └── daily_review_generator.py # 报告生成器
├── templates/
│   └── daily_review_template.md  # 报告模板
└── reviews/
    ├── review-2026-03-12.md      # 3 月 12 日复盘
    └── ...
```

---

## 🔍 故障排查

### 问题 1: 飞书推送失败

**错误:** `{"code":9499,"msg":"Bad Request","data":{}}`

**解决方案:**
1. 检查 Webhook URL 是否正确
2. 确认飞书机器人已启用
3. 检查网络连接
4. 确认消息内容长度（不超过 4096 字符）

**测试:**
```bash
curl -X POST "YOUR_FEISHU_WEBHOOK" \
  -H "Content-Type: application/json" \
  -d '{"msg_type":"text","content":{"text":"测试消息"}}'
```

### 问题 2: Git 推送失败

**错误:** `Updates were rejected`

**解决方案:**
```bash
# 先拉取远程变更
git pull --rebase

# 再推送
git push
```

### 问题 3: 复盘报告生成失败

**错误:** `状态文件不存在`

**解决方案:**
1. 检查 state.json 路径是否正确
2. 确认文件存在：`ls -la fund_challenge/state.json`
3. 检查文件权限

---

## 📊 推送记录

| 日期 | 当日收益 | GitHub | 飞书 |
|------|----------|--------|------|
| 2026-03-12 | -7.04 元 | ✅ | ✅ |

---

## 🎯 最佳实践

### 1. 每日执行

建议每个交易日 22:00 自动执行：
```bash
0 22 * * 1-5 bash auto_review.sh
```

### 2. 数据备份

复盘报告自动存档到 GitHub，建议定期备份：
```bash
# 每月备份一次
git archive --format=zip --output=reviews-backup-$(date +%Y%m).zip OpenClaw-Fund-Trading:08-fund-daily-review/reviews/
```

### 3. 隐私保护

- ✅ Webhook URL 不提交到 Git
- ✅ 敏感数据本地存储
- ✅ 飞书推送使用占位符

---

## 🔗 相关链接

- [GitHub 仓库](https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system)
- [复盘报告存档](https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system/tree/OpenClaw-Fund-Trading/08-fund-daily-review/reviews)
- [飞书开放平台](https://open.feishu.cn/document/)

---

*最后更新：2026-03-13*
