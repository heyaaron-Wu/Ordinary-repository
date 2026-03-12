# OpenClaw Workspace 文件结构

**更新时间:** 2026-03-12  
**隐私级别:** 混合（公开 + 私有）

---

## 📁 文件夹结构

```
workspace/
├── 01-public-configs/      # ✅ 可公开 - 基础配置
├── 02-skill-docs/          # ✅ 可公开 - 技能文档（已清理隐私）
├── 03-system-docs/         # ✅ 可公开 - 系统文档（已清理隐私）
├── 04-private-configs/     # 🔒 私有 - 含敏感信息
├── 05-scripts/             # ✅ 可公开 - 工具脚本
└── 06-data/                # 🔒 私有 - 数据文件
```

---

## 📂 各文件夹说明

### 📁 01-public-configs/ (可公开)

**内容:** 基础配置文件，不含敏感信息

**文件列表:**
- `AGENTS.md` - Agent 配置指南
- `SOUL.md` - Agent 人格定义
- `USER.md` - 用户信息（不含隐私）
- `TOOLS.md` - 工具配置（不含 API keys）
- `HEARTBEAT.md` - 心跳任务配置
- `IDENTITY.md` - Agent 身份
- `BOOTSTRAP.md` - 启动指南

**隐私状态:** ✅ 安全，可公开

---

### 📁 02-skill-docs/ (可公开)

**内容:** 技能文档和说明

**子文件夹:**
- `agent-browser/` - 浏览器自动化技能
- `akshare-finance/` - 财经数据技能
- `etf-assistant/` - ETF 助理技能
- `finance-lite/` - 市场简报技能
- `news-summary/` - 新闻摘要技能
- `proactive-agent/` - 主动代理技能
- `searxng/` - 隐私搜索技能
- `self-improving-agent/` - 自我改进技能
- `skill-vetter/` - 技能审查技能
- `stock-watcher/` - 股票监控技能

**隐私状态:** ⚠️ 已清理 webhook，可公开

---

### 📁 03-system-docs/ (可公开)

**内容:** 系统文档、优化报告、使用指南

**文件列表:**
- 系统优化报告
- 定时任务分析
- 基金挑战文档
- GitHub 集成指南
- InStreet 技能学习报告
- 问题报告

**隐私状态:** ⚠️ 部分文档含 webhook，需要清理

**待清理文件:**
- `cron_optimization_summary.md` - 含飞书 webhook
- `github_integration_benefits.md` - 含示例 webhook
- `fund_challenge_*.md` - 含飞书/钉钉 webhook

---

### 🔒 04-private-configs/ (私有 - 不推送)

**内容:** 包含敏感信息的配置文件

**子文件夹:**
- `memory/` - 记忆文件（含个人习惯）
- `fund_challenge/` - 基金挑战配置（含持仓信息）
- `fund-challenge/` - 基金挑战技能（含 webhook）

**隐私状态:** 🔴 包含敏感信息，不推送到公开仓库

**敏感信息:**
- 飞书 Webhook URL
- 钉钉 Access Token
- 持仓金额和交易记录
- 个人使用习惯

---

### 📁 05-scripts/ (可公开)

**内容:** 工具脚本

**文件列表:**
- `setup-github-integration.sh` - GitHub 集成配置脚本

**隐私状态:** ✅ 安全，可公开

---

### 🔒 06-data/ (私有 - 不推送)

**内容:** 数据文件

**子文件夹:**
- `health-history.json` - 健康检查历史

**隐私状态:** 🟡 含服务器信息，建议不推送

---

## 🎯 推送策略

### ✅ 可以推送的文件夹

```bash
git add 01-public-configs/
git add 02-skill-docs/
git add 03-system-docs/  # 需先清理 webhook
git add 05-scripts/
```

### 🔒 不应该推送的文件夹

```bash
# 添加到 .gitignore
04-private-configs/
06-data/
```

---

## 📝 .gitignore 配置

```gitignore
# 私有配置
04-private-configs/
06-data/

# 证据文件夹
evidence/

# 脚本文件夹（如果不是公开的）
scripts/

# 临时文件
*.tmp
*.log
.cache/

# 凭证文件
.git-credentials
.env
```

---

## 🔐 隐私清理清单

### 需要清理的文件

| 文件 | 隐私内容 | 清理状态 |
|------|----------|----------|
| `03-system-docs/cron_optimization_summary.md` | 飞书 webhook | ❌ 待清理 |
| `03-system-docs/github_integration_benefits.md` | 示例 webhook | ❌ 待清理 |
| `03-system-docs/fund_challenge_*.md` | 飞书/钉钉 webhook | ❌ 待清理 |

### 清理方法

**替换 webhook URL 为占位符:**

```bash
# 飞书 webhook
https://open.feishu.cn/open-apis/bot/v2/hook/f1286a3e-4e41-4809-a0bc-fd2bbbbc3f10
→
https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_FEISHU_WEBHOOK

# 钉钉 access_token
access_token=6ab3e0f7233d9656c72b0f80a2e8d20a5a917adc82700719f7259b5325b22430
→
access_token=YOUR_DINGTALK_ACCESS_TOKEN
```

---

## 🚀 下一步操作

### 1. 清理隐私信息

```bash
# 替换所有 webhook URL
cd /home/admin/.openclaw/workspace/03-system-docs
sed -i 's|https://open\.feishu\.cn/open-apis/bot/v2/hook/[a-f0-9-]*|https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_FEISHU_WEBHOOK|g' *.md
sed -i 's|access_token=[a-f0-9]*|access_token=YOUR_DINGTALK_ACCESS_TOKEN|g' *.md
```

### 2. 更新 .gitignore

```bash
cd /home/admin/.openclaw/workspace
cat >> .gitignore << 'EOF'

# 私有配置
04-private-configs/
06-data/
evidence/
scripts/
EOF
```

### 3. 删除远程分支并重新推送

```bash
# 删除远程分支
git push origin --delete main

# 重新添加公开文件
git add 01-public-configs/
git add 02-skill-docs/
git add 03-system-docs/
git add 05-scripts/
git add .gitignore

# 提交
git commit -m "🔒 重组文件结构，移除隐私内容"

# 推送
git push -u origin main
```

---

## 📊 文件统计

| 文件夹 | 文件数 | 大小 | 隐私级别 | 推送状态 |
|--------|--------|------|----------|----------|
| 01-public-configs/ | 7 | ~50KB | ✅ 公开 | ✅ 推送 |
| 02-skill-docs/ | ~100 | ~2MB | ✅ 公开 | ✅ 推送 |
| 03-system-docs/ | ~20 | ~500KB | ⚠️ 需清理 | ⚠️ 清理后推送 |
| 04-private-configs/ | ~50 | ~1MB | 🔴 私有 | ❌ 不推送 |
| 05-scripts/ | 1 | ~5KB | ✅ 公开 | ✅ 推送 |
| 06-data/ | ~5 | ~100KB | 🟡 敏感 | ❌ 不推送 |

---

*文档创建时间：2026-03-12 22:50*
