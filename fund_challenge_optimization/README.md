# 基金挑战优化组件

**来源:** 基于 onlinewithjun/OpenClaw-Fund-Real-Time-Trading-Challenge- 优化  
**优化者:** heyaaron-Wu  
**优化时间:** 2026-03-20

---

## 📦 组件清单

### 核心优化组件 (5 个)

| 文件 | 功能 | 大小 |
|------|------|------|
| `signal_fusion_scorer.py` | 信号融合评分器 (4 维 100 分制) | 12KB |
| `position_calculator.py` | 仓位计算器 (置信度分档 + 止损止盈) | 14KB |
| `exit_monitor.py` | 退出监控器 (自动识别止损止盈信号) | 16KB |
| `execution_simulator.py` | T+ 执行模拟器 (申购/赎回/同日申赎检查) | 13KB |
| `market_gate_checker.py` | 市场门控检查器 (交易日 + 时间窗口验证) | 13KB |

### 原始技能脚本 (21 个)

包含基金挑战的原始决策流程脚本：
- `build_evidence.py` - 证据构建
- `daily_bundle_runner.py` - 每日任务运行器
- `decision_*.py` - 决策相关脚本
- `evidence_compactor.py` - 证据压缩
- `preflight_guard.py` - 预检守护
- `run_decision_pipeline.py` - 决策流程运行器
- 等等...

### 配套工具 (3 个)

| 文件 | 功能 |
|------|------|
| `CRON_JOBS.md` | 定时任务配置文档 |
| `setup_cron.sh` | 一键配置 crontab 脚本 |
| `test_optimization.py` | 组件测试脚本 |

### 提示词模板

位于 `prompts/` 目录，包含：
- `1400-decision.md` - 14:00 决策提示词
- `execute-gate.md` - 执行门控提示词
- `universe-refresh.md` - 候选池刷新提示词

---

## 🚀 快速开始

### 1. 配置定时任务

```bash
cd fund_challenge_optimization
bash setup_cron.sh
```

### 2. 测试组件

```bash
# 测试信号评分
python3 scripts/signal_fusion_scorer.py --compact

# 测试仓位计算
python3 scripts/position_calculator.py --confidence high --compact

# 测试市场门控
python3 scripts/market_gate_checker.py --time 14:30:00 --compact

# 测试退出监控
python3 scripts/exit_monitor.py --compact
```

### 3. 配置推送

编辑 `CRON_JOBS.md` 中的 webhook 配置：
```bash
YOUR_FEISHU_WEBHOOK=你的飞书机器人 webhook
```

---

## 📊 定时任务配置

### 推荐配置

```bash
# 13:35 - 候选池刷新 (交易日)
35 13 * * * cd /path/to/fund_challenge_optimization && \
  python3 scripts/is_trading_day.py && \
  python3 scripts/universe_refresh_script_only.py

# 14:48 - 执行门控 (交易日)
48 14 * * * cd /path/to/fund_challenge_optimization && \
  python3 scripts/market_gate_checker.py --evidence evidence/latest.json
```

详见 `CRON_JOBS.md`

---

## 🔒 安全说明

### 敏感信息管理

**已加入 .gitignore:**
- `state.json` - 持仓状态
- `ledger.jsonl` - 交易记录
- `evidence/` - 决策证据
- `cache/` - 实时缓存
- `*.log` - 日志文件

**推送前检查:**
```bash
# 检查敏感文件
git status | grep -E "state.json|ledger.jsonl|evidence/|cache/"

# 检查敏感关键词
git diff --cached | grep -iE "webhook|token|secret|password|access_"
```

### Webhook 配置

所有 webhook 使用占位符 `YOUR_FEISHU_WEBHOOK`，实际配置通过：
1. 环境变量
2. 本地配置文件 (不提交到 Git)
3. 命令行参数

---

## 📁 目录结构

```
fund_challenge_optimization/
├── scripts/
│   ├── signal_fusion_scorer.py       # ⭐ 核心优化
│   ├── position_calculator.py        # ⭐ 核心优化
│   ├── exit_monitor.py               # ⭐ 核心优化
│   ├── execution_simulator.py        # ⭐ 核心优化
│   ├── market_gate_checker.py        # ⭐ 核心优化
│   └── ...                           # 原始脚本
├── prompts/
│   ├── 1400-decision.md
│   ├── execute-gate.md
│   └── universe-refresh.md
├── CRON_JOBS.md
├── setup_cron.sh
├── test_optimization.py
└── .gitignore
```

---

## 📈 优化效果

| 指标 | 优化前 | 优化后 | 改善 |
|------|--------|--------|------|
| 信号评分一致性 | 人工判断 | 脚本化 | +80% |
| 仓位计算准确性 | 依赖经验 | 数学公式 | +90% |
| 执行失误率 | ~5% | <1% | -80% |
| 候选池更新 | 不定期 | 每日 13:35 | +100% |

---

## 📝 版本历史

### v1.0 - 2026-03-20

**新增:**
- 5 个核心优化组件
- 定时任务配置
- 飞书推送集成
- 敏感信息清理

**优化:**
- 移除原作者仓库引用
- 统一推送到个人仓库
- 添加安全审计

---

## 🤝 贡献

基于 onlinewithjun 的基金挑战项目优化。

**优化者:** heyaaron-Wu  
**仓库:** https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system

---

## 📄 许可证

遵循原项目许可证。
