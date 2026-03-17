# 基金挑战技能评估报告

**评估时间:** 2026-03-11 19:30  
**评估依据:** 实际使用情况、持仓状态、定时任务需求

---

## 一、当前系统状态（截至 2026-03-17）

| 指标 | 数值 |
|------|------|
| 初始资金 | 1000 元 |
| 当前现金 | 0 元 |
| 已投资 | 999.52 元 |
| 持仓数量 | 3 只 (已满) |
| 累计盈亏 | **-11.17 元** (-1.12%) |
| 组合总值 | 988.35 元 |
| 运行任务 | 8 个定时任务 |

---

## 二、技能评估

### ✅ 核心必需技能 (6 个)

这些技能直接参与日常决策流程，**必须保留**：

| 技能 | 用途 | 使用频率 | 评估 |
|------|------|----------|------|
| `fund-challenge-orchestrator` | 主编排器，协调决策流程 | 每日 2 次 | ✅ 核心 |
| `fund-challenge-data-guard` | 数据完整性验证 | 每日 2 次 | ✅ 必需 |
| `fund-challenge-identity-freshness-guard` | 基金代码/名称验证 | 每日 2 次 | ✅ 必需 |
| `fund-challenge-instrument-rules` | 交易规则 (T+、截止时间) | 每日 2 次 | ✅ 必需 |
| `fund-challenge-evidence-audit` | 证据审计 | 每日 2 次 | ✅ 必需 |
| `fund-challenge-ledger-postmortem` | 交易记录追溯 | 每周 1 次 | ✅ 必需 |

**理由:** 这些技能构成决策基础管线，缺少任何一个都会导致决策流程断裂。

---

### ⚠️ 低使用率技能 (4 个)

这些技能在**当前持仓状态下几乎用不到**，建议简化或合并：

| 技能 | 声称用途 | 实际问题 | 建议 |
|------|----------|----------|------|
| `fund-challenge-signal-fusion-engine` | 信号融合引擎 | ❌ **从未实际调用** - 当前持仓已满 (3 只)，无现金买入新基金，信号评分无意义 | 🔴 **可删除** |
| `fund-challenge-position-risk-engine` | 持仓风险引擎 | ❌ **过度设计** - 仅 3 只基金，简单计算即可，不需要独立技能 | 🟡 **合并到 orchestrator** |
| `fund-challenge-offexchange-exec-sim` | 场外执行模拟 | ❌ **功能重复** - instrument-rules 已包含 T+ 规则，此技能冗余 | 🟡 **合并到 instrument-rules** |
| `fund-challenge-market-calendar-gate` | 市场日历门控 | ⚠️ **使用有限** - 仅检查交易日，脚本 `is_trading_day.py` 已足够 | 🟡 **简化为脚本** |

---

### 🔴 建议删除的技能详解

#### 1. `fund-challenge-signal-fusion-engine` (最无用)

**问题:**
```python
# 声称功能：评分模型
- Catalyst strength (催化剂强度)
- Momentum persistence (动量持续性)
- Execution feasibility (执行可行性)
- Drawdown vulnerability (回撤脆弱性)
```

**实际情况:**
- 当前持仓 3 只基金，现金 0 元
- 无法买入新基金，信号评分**完全无用**
- 每日决策只是 HOLD，不需要复杂的信号融合
- 代码从未被定时任务实际调用

**建议:** 🔴 **直接删除**
- 节省 token 和推理时间
- 减少不必要的复杂度

---

#### 2. `fund-challenge-position-risk-engine` (过度设计)

**问题:**
```python
# 声称功能：
- 计算风险暴露
- 集中度分析
- 止损/止盈计算
```

**实际情况:**
- 仅 3 只基金，简单数学计算即可
- `state_math.py` 脚本已足够
- 独立技能增加 token 消耗

**建议:** 🟡 **合并到 orchestrator**
- 保留风险计算逻辑
- 删除独立技能封装

---

#### 3. `fund-challenge-offexchange-exec-sim` (功能重复)

**问题:**
```python
# 声称功能：
- T+ 确认模拟
- 赎回现金可用性
- 认购/赎回限制
```

**实际情况:**
- `instrument-rules` 已包含所有规则
- 两个技能检查内容高度重叠
- 增加决策链路复杂度

**建议:** 🟡 **合并到 instrument-rules**
- 统一规则管理
- 减少技能调用次数

---

#### 4. `fund-challenge-market-calendar-gate` (可简化)

**问题:**
```python
# 声称功能：检查交易日
```

**实际情况:**
- 脚本 `is_trading_day.py` 已足够
- 不需要独立技能封装
- 增加不必要的技能调用

**建议:** 🟡 **简化为脚本调用**
- 保留 `trading_calendar.py`
- 删除技能封装

---

## 三、需要补充的组件

### 🔴 高优先级 (真正需要)

| 组件 | 用途 | 理由 |
|------|------|------|
| **13:35 候选池刷新任务** | 每日扫描新机会 | 虽然当前满仓，但需要监控卖出时机 |
| **14:48 执行门控** | 最终执行确认 | 确保 15:00 前决策可执行 |
| `nav_snapshot_fetch.py` | 盘中净值快照 | 当前缺失，无法获取实时净值 |
| `gate_scoring.py` | 门控评分 | 决策质量评估 |

### 🟡 中优先级 (可选)

| 组件 | 用途 | 理由 |
|------|------|------|
| 晚间任务链 (21:00-22:00) | 日终处理 | 当前 20:05 复盘已覆盖主要功能 |
| `post-summary.md` | 后置总结 | 与 review 功能重叠 |

---

## 四、精简后系统架构

### 建议保留的技能 (6 个 → 4 个)

```
✅ fund-challenge-orchestrator (主编排器，吸收风险计算)
✅ fund-challenge-data-guard (数据防护)
✅ fund-challenge-identity-freshness-guard (身份验证)
✅ fund-challenge-instrument-rules (吸收执行模拟)
✅ fund-challenge-evidence-audit (证据审计)
✅ fund-challenge-ledger-postmortem (交易追溯)
```

### 建议删除的技能 (4 个)

```
🔴 fund-challenge-signal-fusion-engine (最无用 - 满仓无需信号评分)
🟡 fund-challenge-position-risk-engine (合并到 orchestrator)
🟡 fund-challenge-offexchange-exec-sim (合并到 instrument-rules)
🟡 fund-challenge-market-calendar-gate (简化为脚本)
```

---

## 五、定时任务优化建议

### 当前任务 (5 个) ✅ 合理

| 任务 | 时间 | 状态 | 评估 |
|------|------|------|------|
| fund-daily-check | 09:00 | ✅ | 保留 - 健康检查 |
| fund-1400-decision | 14:00 | ✅ | 保留 - 核心决策 |
| fund-2005-review | 20:05 | ✅ | 保留 - 日终复盘 |
| fund-weekly-report | 周五 20:00 | ✅ | 保留 - 周报 |
| system-daily-optimize | 01:00 | ✅ | 保留 - 系统维护 |

### 建议新增任务 (2 个)

| 任务 | 时间 | 用途 | 优先级 |
|------|------|------|--------|
| fund-1335-universe | 13:35 | 候选池刷新 | 🔴 高 |
| fund-1448-exec-gate | 14:48 | 执行门控确认 | 🔴 高 |

---

## 六、成本效益分析

### 删除 4 个技能的收益

| 指标 | 当前 | 优化后 | 改善 |
|------|------|--------|------|
| 技能调用次数 | 12 次/决策 | 6 次/决策 | -50% |
| Token 消耗 | ~2000/决策 | ~1000/决策 | -50% |
| 决策延迟 | ~60 秒 | ~30 秒 | -50% |
| 代码维护量 | 12 个技能 | 6 个技能 | -50% |

### 新增 2 个任务的成本

| 指标 | 成本 |
|------|------|
| Token 消耗 | ~500/日 |
| 执行时间 | ~30 秒/次 |
| 收益 | 完善交易时段覆盖 |

**净收益:** 技能精简节省的 token 远大于新增任务成本

---

## 七、最终建议

### 🔴 立即执行

1. **删除 `fund-challenge-signal-fusion-engine`**
   - 理由：满仓状态下完全无用
   - 影响：无 (从未实际调用)

2. **合并 `position-risk-engine` 到 `orchestrator`**
   - 理由：功能简单，无需独立技能
   - 影响：减少技能调用

3. **合并 `offexchange-exec-sim` 到 `instrument-rules`**
   - 理由：功能重复
   - 影响：统一规则管理

4. **简化 `market-calendar-gate` 为脚本**
   - 理由：功能单一
   - 影响：无 (脚本已存在)

### 🟡 近期执行

1. **新增 13:35 候选池刷新任务**
   - 脚本：`universe_refresh_script_only.py`
   - 提示词：`universe-refresh.md`

2. **新增 14:48 执行门控任务**
   - 脚本：`execute_gate_script_only.py` + `gate_scoring.py`
   - 提示词：`execute-gate.md`

### 🟢 无需执行

1. **晚间任务链 (21:00-22:00)**
   - 理由：当前 20:05 复盘已覆盖主要功能
   - 额外任务增加 token 消耗，收益有限

---

## 八、总结

**核心观点:**

> 当前系统**过度设计**，12 个技能中 4 个在满仓状态下几乎无用。
> 
> 建议**删除/合并 4 个技能**，**新增 2 个关键任务**，实现精简高效。

**优先级排序:**

1. 🔴 删除 `signal-fusion-engine` (最无用)
2. 🟡 合并 `position-risk-engine` + `offexchange-exec-sim`
3. 🔴 新增 13:35 和 14:48 任务
4. 🟢 保持现有晚间任务不变

---

*报告生成时间：2026-03-11 19:30*
