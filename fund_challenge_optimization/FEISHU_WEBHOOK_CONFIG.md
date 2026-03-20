# 飞书 Webhook 配置指南

**更新时间:** 2026-03-20 13:58  
**状态:** ✅ 已测试通过

---

## 📋 当前状态

### ✅ 已测试的推送

**测试时间:** 2026-03-20 13:58  
**结果:** 推送成功 (`StatusCode: 0`)

**推送内容:**
- 粗筛：20 只基金（完整列表 + 评分）
- 精筛：17 只基金（≥80 分，完整列表 + 评分）
- TOP1: 008763 天弘越南市场 (94 分)

---

## 🔧 Webhook 配置

### 当前使用的 Webhook

```
https://open.feishu.cn/open-apis/bot/v2/hook/f1286a3e-4e41-4809-a0bc-fd2bbbbc3f10
```

### 如何获取你的 Webhook

1. **打开飞书群聊**
2. **右上角设置** → **群机器人**
3. **添加机器人** → **自定义机器人**
4. **复制 Webhook 地址**

### 配置方式

#### 方式 1: 命令行参数

```bash
python3 fund_challenge/scripts/universe_refresh_script_only.py \
  --workspace /path/to/fund_challenge \
  --feishu \
  --webhook "https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_WEBHOOK"
```

#### 方式 2: 环境变量

```bash
export FEISHU_WEBHOOK="https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_WEBHOOK"

python3 fund_challenge/scripts/universe_refresh_script_only.py \
  --workspace /path/to/fund_challenge \
  --feishu
```

#### 方式 3: 修改脚本默认值

编辑 `universe_refresh_script_only.py`:

```python
parser.add_argument('--webhook', type=str,
                    default='https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_WEBHOOK',
                    help='飞书 webhook URL')
```

#### 方式 4: 配置文件

创建 `.env.local` 文件 (不提交到 Git):

```bash
FEISHU_WEBHOOK=https://open.feishu.cn/open-apis/bot/v2/hook/YOUR_WEBHOOK
```

---

## 📊 推送效果

### 消息格式

```
🔔 候选池更新报告

粗筛：20 只
精筛：17 只 (≥80 分)

### 📋 粗筛完整列表

| 排名 | 代码 | 名称 | 类别 | 评分 |
|------|------|------|------|------|
| 1 | 020899 | 天弘中证全指通信设备指数发起 A | 科技成长 | 🔴 0 分 |
| ...

### ⭐ 精筛完整列表 (≥80 分)

| 排名 | 代码 | 名称 | 类别 | 评分 |
|------|------|------|------|------|
| 1 | 008763 | 天弘越南市场股票发起 (QDII)A | 海外 | 🟢 94 分 |
| ...

---
更新时间：2026-03-20 13:58
```

### 评分说明

- 🟢 **≥80 分**: 精筛入选，强烈推荐
- 🟡 **70-79 分**: 中等评分，观望
- 🔴 **<70 分**: 低评分，不推荐

---

## 🚀 定时任务配置

### Crontab 配置

```bash
# 13:35 - 候选池刷新 (交易日)
35 13 * * * cd /path/to/fund_challenge && \
  python3 scripts/is_trading_day.py && \
  python3 scripts/universe_refresh_script_only.py \
    --workspace /path/to/fund_challenge \
    --feishu \
    --webhook "YOUR_WEBHOOK" >> logs/universe_refresh.log 2>&1
```

### 自动推送条件

**默认行为:**
- ✅ 每次刷新都推送完整列表
- ✅ 包含粗筛和精筛完整数据
- ✅ 显示每只基金的评分

**可选配置:**
- 只在发现高评分基金时推送
- 只推送精筛列表
- 设置评分阈值

---

## 🧪 测试命令

### 测试推送

```bash
cd /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge

# 测试推送
python3 fund_challenge/scripts/universe_refresh_script_only.py \
  --workspace /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge \
  --feishu \
  --webhook "https://open.feishu.cn/open-apis/bot/v2/hook/f1286a3e-4e41-4809-a0bc-fd2bbbbc3f10"
```

### 使用 curl 测试

```bash
curl -X POST "YOUR_WEBHOOK" \
  -H "Content-Type: application/json" \
  -d '{
    "msg_type": "text",
    "content": {
      "text": "测试消息"
    }
  }'
```

---

## ⚠️ 注意事项

### 安全说明

1. **不要公开 Webhook**
   - Webhook 包含访问令牌
   - 不要提交到 Git
   - 使用 `.env.local` 管理

2. **权限控制**
   - Webhook 只能发送到配置的群
   - 无法读取群消息
   - 无法管理群成员

3. **频率限制**
   - 建议每分钟不超过 10 条
   - 候选池刷新每天 1 次即可

### 故障排除

**推送失败:**
```bash
# 检查网络连接
curl https://open.feishu.cn

# 检查 Webhook 格式
echo $FEISHU_WEBHOOK

# 查看错误日志
tail logs/universe_refresh.log
```

**消息格式错误:**
- 确保使用 `msg_type: interactive`
- 检查 Markdown 语法
- 验证 JSON 格式

---

## 📝 更新日志

### 2026-03-20 13:58

- ✅ 修改 `universe_refresh_script_only.py`
- ✅ 添加完整粗筛/精筛列表输出
- ✅ 添加飞书推送功能
- ✅ 测试推送成功

**推送内容:**
- 粗筛 20 只基金（完整列表）
- 精筛 17 只基金（≥80 分）
- TOP1: 008763 (94 分)

---

## 📞 联系支持

**文档:** `fund_challenge_optimization/README.md`  
**配置:** `fund_challenge_optimization/CRON_JOBS.md`  
**测试:** `fund_challenge_optimization/test_optimization.py`

---

*最后更新：2026-03-20 13:58*
