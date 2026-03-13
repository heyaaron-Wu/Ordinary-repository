# MEMORY.md - Long-Term Memory

## Preferences

- **联网搜索优先使用 searxng skill** —— 只要涉及联网搜索任务，优先调用 searxng 技能而非直接使用 web_search 工具。

- **消息推送通过飞书群机器人 Webhook** —— 所有定时任务、自动报告、系统通知等消息，统一通过飞书群机器人推送：
  ```
  https://open.feishu.cn/open-apis/bot/v2/hook/f1286a3e-4e41-4809-a0bc-fd2bbbbc3f10
  ```
  - **推送方式：使用 curl 命令直接在任务中推送**（不依赖 cron delivery 模式）
  - **支持格式：**
    1. **文本通知** - 简单消息，适合日常通知
    2. **富文本卡片** - 结构化展示，适合日报/周报
  - **示例：**
    ```bash
    # 1. 文本通知
    curl -X POST "https://open.feishu.cn/open-apis/bot/v2/hook/f1286a3e-4e41-4809-a0bc-fd2bbbbc3f10" \
      -H "Content-Type: application/json" \
      -d '{"msg_type":"text","content":{"text":"🔔 通知内容"}}'

    # 2. 富文本卡片（推荐用于报告）
    curl -X POST "https://open.feishu.cn/open-apis/bot/v2/hook/f1286a3e-4e41-4809-a0bc-fd2bbbbc3f10" \
      -H "Content-Type: application/json" \
      -d '{
        "msg_type": "interactive",
        "card": {
          "header": {
            "title": {"tag": "plain_text", "content": "标题"},
            "template": "blue"
          },
          "elements": [
            {"tag": "markdown", "content": "**内容**"}
          ]
        }
      }'
    ```

## Notes

- Created: 2026-03-05
- Updated: 2026-03-13:
  - 删除净值获取功能及相关脚本
  - 统一推送渠道为飞书（删除钉钉、企业微信相关配置）
  - **日终复盘必须推送到 GitHub 归档**

## GitHub Workflow

### 日终复盘 GitHub 推送流程

**每日 22:00 复盘后必须执行:**

1. **生成复盘报告** → `fund_challenge/daily_reviews/YYYY-MM-DD.md`
2. **更新状态文件** → `fund_challenge/state.json`
3. **更新交易账本** → `fund_challenge/ledger.jsonl`
4. **Git 提交并推送**

**推送命令:**
```bash
cd /home/admin/.openclaw/workspace

# 添加文件
git add fund_challenge/daily_reviews/YYYY-MM-DD.md
git add fund_challenge/state.json
git add fund_challenge/ledger.jsonl

# 提交
git commit -m "📊 添加 MM 月 DD 日日终复盘
- 当日盈亏：XXX 元 (X.XX%)
- 累计盈亏：XXX 元 (X.XX%)
- 简要说明"

# 推送
git pull --rebase origin OpenClaw-Fund-Trading
git push origin OpenClaw-Fund-Trading
```

**推送后通知飞书:**
```bash
curl -X POST "https://open.feishu.cn/open-apis/bot/v2/hook/f1286a3e-4e41-4809-a0bc-fd2bbbbc3f10" \
  -H "Content-Type: application/json" \
  -d '{
    "msg_type":"text",
    "content":{
      "text":"✅ MM 月 DD 日日终复盘已完成\n\n📊 当日盈亏：XXX 元\n📈 累计盈亏：XXX 元\n💾 数据已归档到 GitHub\n\n🔗 https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system"
    }
  }'
```

## Privacy Guidelines

### GitHub 推送隐私检查清单

**⚠️ 重要:** 推送到 GitHub 前必须审查以下内容，避免泄露隐私和敏感信息。

**❌ 禁止提交:**
- API tokens / keys (包括飞书、钉钉、企业微信 Webhook)
- 密码 / 凭证
- 私钥文件 (*.pem, *.key)
- 个人身份信息 (身份证、手机号、邮箱)
- 财务数据 (持仓明细、账户余额、基金代码)
- `04-private-configs/` 目录全部内容
- `.openclaw/cron/jobs.json` (含 Webhook URL)

**✅ 可以提交:**
- 系统配置文档 (03-system-docs/)
- 技能代码 (02-skill-docs/skills/)
- 公开文档
- 脚本文件 (不含敏感配置)

**推送前检查命令:**
```bash
# 1. 查看待提交文件
git status

# 2. 审查改动内容
git diff --cached

# 3. 确认无敏感信息后再推送
git push
```

**.gitignore 建议配置:**
```
# 敏感配置
*.env
*.key
*.pem
*token*
*secret*
*.webhook

# 私有配置目录
04-private-configs/
05-scripts/setup-github-integration.sh

# OpenClaw 运行时
.openclaw/
cron/
cache/
*.log
```

**已删除的敏感内容:**
- ✅ 净值获取脚本 (net_value_fetcher.py, daily_pnl_updater.py)
- ✅ 净值缓存文件 (nav_cache.json)
- ✅ 基金持仓 review 文档
- ✅ 净值优化文档
