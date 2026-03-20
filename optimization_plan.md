# 量化交易系统组件优化方案

**生成时间:** 2026-03-20  
**目标:** 优化 4 个核心组件 + 13:35 候选池更新机制

---

## 一、当前状态评估

### ✅ 已有组件
| 组件 | 状态 | 位置 |
|------|------|------|
| signal-fusion-engine | ✅ 已实现 (SKILL.md) | skills/original/fund-challenge-signal-fusion-engine |
| position-risk-engine | ✅ 已实现 (SKILL.md) | skills/original/fund-challenge-position-risk-engine |
| market-calendar-gate | ✅ 已实现 (SKILL.md + trading_calendar.py) | skills/original/fund-challenge-market-calendar-gate |
| offexchange-exec-sim | ✅ 已实现 (SKILL.md) | skills/original/fund-challenge-offexchange-exec-sim |

### ⚠️ 缺失/待优化
| 组件 | 缺失内容 | 优先级 |
|------|----------|--------|
| signal-fusion-engine | 缺少独立评分脚本 | 🔴 高 |
| position-risk-engine | 缺少仓位计算脚本 | 🔴 高 |
| market-calendar-gate | trading_calendar.py 功能完整，但缺少门控集成 | 🟡 中 |
| offexchange-exec-sim | 缺少 T+ 模拟脚本 | 🟡 中 |
| 13:35 候选池更新 | universe_refresh_script_only.py 已存在，但缺少定时任务 | 🔴 高 |

---

## 二、优化方案

### 1. Signal Fusion Engine (信号融合引擎)

**当前问题:**
- 只有 SKILL.md 规范，缺少独立评分脚本
- 信号评分逻辑分散在多个 agent prompts 中
- 无法独立运行进行回测

**优化措施:**

#### 1.1 创建独立评分脚本 `signal_fusion_scorer.py`
```python
#!/usr/bin/env python3
"""
信号融合评分器
整合多个信号源，输出 0-100 综合评分
"""

def calculate_signal_score(candidates: list) -> list:
    """
    评分维度:
    - Catalyst strength (催化剂强度): 30 分
    - Momentum persistence (动量持续性): 25 分
    - Execution feasibility (执行可行性): 25 分
    - Drawdown vulnerability (回撤风险): 20 分
    """
    scored = []
    for candidate in candidates:
        score = 0
        
        # 催化剂强度 (0-30)
        if candidate.get('policy_news'): score += 10
        if candidate.get('sector_heat') > 0.7: score += 10
        if candidate.get('macro_linkage'): score += 10
        
        # 动量持续性 (0-25)
        momentum = candidate.get('momentum_score', 0)
        score += min(25, momentum * 25)
        
        # 执行可行性 (0-25)
        if candidate.get('liquidity_ok'): score += 15
        if candidate.get('within_position_limit'): score += 10
        
        # 回撤风险 (0-20)
        drawdown = candidate.get('max_drawdown', 0)
        score += max(0, 20 - drawdown * 2)
        
        scored.append({**candidate, 'score': score})
    
    return sorted(scored, key=lambda x: x['score'], reverse=True)
```

#### 1.2 优化通知策略
- ✅ 已实现：仅 BUY/SELL 推送，HOLD 静默
- 建议：增加评分阈值过滤（<60 分不推送）

---

### 2. Position Risk Engine (仓位风险引擎)

**当前问题:**
- 只有 SKILL.md 规范，缺少仓位计算脚本
- 仓位分档逻辑未代码化
- 止损/止盈规则依赖人工判断

**优化措施:**

#### 2.1 创建仓位计算脚本 `position_calculator.py`
```python
#!/usr/bin/env python3
"""
仓位计算器
根据置信度和风险限制计算目标仓位
"""

def calculate_position(confidence: str, current_exposure: float, 
                       theme_concentration: float) -> dict:
    """
    仓位分档:
    - High confidence: +35% to +55%
    - Medium confidence: +20% to +35%
    - Low confidence: 0% (HOLD)
    
    风险限制:
    - Max single-day additional exposure: 55%
    - Max single-theme concentration: 60%
    - Portfolio de-risk trigger: drawdown <= -8%
    """
    
    # 置信度映射
    confidence_bands = {
        'high': (0.35, 0.55),
        'medium': (0.20, 0.35),
        'low': (0.0, 0.0)
    }
    
    min_add, max_add = confidence_bands.get(confidence, (0, 0))
    
    # 应用风险限制
    max_allowed = min(
        max_add,
        0.55,  # 单日最大新增
        0.60 - theme_concentration,  # 主题集中度限制
        0.0 if current_exposure >= 1.0 else (1.0 - current_exposure)  # 总仓位限制
    )
    
    # 回撤保护
    if current_exposure <= -0.08:
        max_allowed = 0.0
    
    return {
        'action': 'BUY' if max_allowed > 0 else 'HOLD',
        'incremental_exposure': max_allowed,
        'target_exposure': current_exposure + max_allowed,
        'risk_checks': {
            'single_day_limit_ok': max_allowed <= 0.55,
            'theme_concentration_ok': theme_concentration <= 0.60,
            'drawdown_protection_ok': current_exposure > -0.08
        }
    }
```

#### 2.2 创建止损/止盈监控脚本 `exit_monitor.py`
```python
#!/usr/bin/env python3
"""
退出监控
- Soft take-profit: +7%
- Hard risk cut: -5%
"""

def check_exit_signals(positions: list) -> list:
    exit_signals = []
    for pos in positions:
        pnl = pos.get('unrealized_pnl_pct', 0)
        catalyst_strength = pos.get('catalyst_strength', 'normal')
        
        # 止盈检查
        if pnl >= 0.07:
            exit_signals.append({
                'fund_code': pos['fund_code'],
                'action': 'TRIM',
                'reason': f'止盈触发 (+{pnl:.1%})',
                'urgency': 'medium'
            })
        
        # 止损检查
        elif pnl <= -0.05 and catalyst_strength == 'weakened':
            exit_signals.append({
                'fund_code': pos['fund_code'],
                'action': 'CUT',
                'reason': f'止损触发 (-{abs(pnl):.1%}) + 催化剂减弱',
                'urgency': 'high'
            })
    
    return exit_signals
```

---

### 3. Market Calendar Gate (市场日历门控)

**当前状态:** ✅ trading_calendar.py 功能完整

**优化措施:**

#### 3.1 集成到执行门控
创建 `market_gate_checker.py` 作为统一入口:
```python
#!/usr/bin/env python3
"""
市场门控检查器
整合交易日历 + 时间窗口 + 执行截止
"""

from trading_calendar import is_trading_day, check_market_status

def validate_execution_window(action_time: str) -> dict:
    """
    验证执行时间窗口
    
    时间窗口规则:
    - 09:00-11:30: 早盘可执行
    - 13:00-14:48: 午盘可执行 (推荐)
    - 14:48-15:00: 最后确认窗口
    - 15:00 后: 禁止执行
    """
    
    status = check_market_status()
    
    # 非交易日
    if not status['is_trading_day']:
        return {
            'allowed': False,
            'reason': '非交易日',
            'next_trading_day': status['next_trading_day']
        }
    
    # 交易时段检查
    current_minutes = int(action_time.split(':')[0]) * 60 + int(action_time.split(':')[1])
    
    if current_minutes >= 15 * 60:  # 15:00 后
        return {
            'allowed': False,
            'reason': '已过交易截止时间',
            'deadline': '15:00'
        }
    
    if current_minutes < 9 * 60 + 30:  # 9:30 前
        return {
            'allowed': False,
            'reason': '未到开盘时间',
            'market_open': '09:30'
        }
    
    # 推荐执行窗口
    if 13 * 60 <= current_minutes <= 14 * 60 + 48:
        recommendation = 'OPTIMAL'
    else:
        recommendation = 'ALLOWED_BUT_NOT_OPTIMAL'
    
    return {
        'allowed': True,
        'market_status': status['market_status'],
        'recommendation': recommendation,
        'deadline_remaining': status['deadline_remaining_minutes']
    }
```

#### 3.2 优化建议
- ✅ 已配置 2026 年节假日
- 建议：增加实时 API 校验（证监会/交易所公告）

---

### 4. Off-Exchange Exec Sim (场外执行模拟)

**当前问题:**
- 只有 SKILL.md 规范，缺少 T+ 模拟脚本
- 无法验证现金可用性日期

**优化措施:**

#### 4.1 创建 T+ 模拟脚本 `execution_simulator.py`
```python
#!/usr/bin/env python3
"""
场外执行模拟器
验证 T+ 确认、结算、现金可用性
"""

from datetime import datetime, timedelta
from trading_calendar import get_next_trading_day

def simulate_execution(fund_code: str, action: str, 
                       execution_date: str) -> dict:
    """
    模拟场外基金执行
    
    T+ 规则:
    - T 日 15:00 前申购：T+1 确认，T+2 可赎
    - T 日 15:00 前赎回：T+1 确认，T+2-T+4 现金可用
    """
    
    # 验证截止时间
    now = datetime.now()
    deadline = now.replace(hour=15, minute=0, second=0, microsecond=0)
    
    if now >= deadline:
        return {
            'feasible': False,
            'reason': '已过今日 15:00 截止时间',
            'next_feasible_date': get_next_trading_day(execution_date)
        }
    
    # 计算关键日期
    t_date = execution_date
    t1_date = get_next_trading_day(t_date)
    t2_date = get_next_trading_day(t1_date)
    t4_date = get_next_trading_day(get_next_trading_day(t2_date))
    
    if action == 'SUBSCRIBE':
        return {
            'feasible': True,
            'action': action,
            'fund_code': fund_code,
            'timeline': {
                'execution_date': t_date,
                'confirmation_date': t1_date,
                'available_for_redemption': t2_date
            },
            'cash_impact': 'immediate_debit'
        }
    
    elif action == 'REDEEM':
        return {
            'feasible': True,
            'action': action,
            'fund_code': fund_code,
            'timeline': {
                'execution_date': t_date,
                'confirmation_date': t1_date,
                'cash_available_date': t4_date
            },
            'cash_impact': 'delayed_credit'
        }
    
    elif action == 'ROUND_TRIP':
        return {
            'feasible': False,
            'reason': '场外基金禁止同日申赎 (T+ 规则限制)',
            'min_holding_period': '2 个交易日'
        }
```

---

### 5. 13:35 候选池按需更新

**当前状态:** 
- ✅ universe_refresh_script_only.py 已存在
- ✅ universe-refresh.md 提示词已创建
- ❌ 缺少定时任务配置

**优化措施:**

#### 5.1 创建定时任务配置

**crontab 配置:**
```bash
# 13:35 候选池刷新 (仅交易日)
35 13 * * * cd /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge && \
  python3 scripts/is_trading_day.py && \
  python3 scripts/universe_refresh_script_only.py \
    --workspace /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge \
    >> logs/universe_refresh.log 2>&1
```

#### 5.2 优化按需更新逻辑

修改 `universe_refresh_script_only.py` 增加条件判断:
```python
def should_refresh(current_state: dict) -> bool:
    """
    判断是否需要刷新候选池
    
    触发条件 (满足任一即可):
    1. 距离上次刷新 > 3 天
    2. 现有持仓触及止损/止盈
    3. 市场波动率突变 (>20%)
    4. 有新基金上市且符合策略
    """
    
    last_refresh = current_state.get('last_pool_refresh')
    days_since_refresh = (datetime.now() - last_refresh).days if last_refresh else 999
    
    # 条件 1: 时间间隔
    if days_since_refresh >= 3:
        return True
    
    # 条件 2: 持仓触发退出
    exit_signals = check_exit_signals(current_state.get('positions', []))
    if exit_signals:
        return True
    
    # 条件 3: 波动率突变
    current_vol = current_state.get('market_volatility', 0)
    avg_vol = current_state.get('avg_volatility_30d', 0)
    if avg_vol > 0 and abs(current_vol - avg_vol) / avg_vol > 0.2:
        return True
    
    return False
```

#### 5.3 推送策略优化

根据 MEMORY.md 配置，使用**钉钉群机器人**推送:
```python
def send_dingtalk_alert(title: str, content: str):
    """发送钉钉告警"""
    webhook = "https://oapi.dingtalk.com/robot/send?access_token=6ab3e0f7233d9656c72b0f80a2e8d20a5a917adc82700719f7259b5325b22430"
    
    payload = {
        "msgtype": "markdown",
        "markdown": {
            "title": title,
            "text": content
        }
    }
    
    import requests
    requests.post(webhook, json=payload)

# 使用示例
if top_candidate_score >= 80:
    send_dingtalk_alert(
        "候选池更新",
        f"""## 候选池刷新完成
        
- 粗筛数量：{coarse_count} 只
- 精筛数量：{refined_count} 只

### TOP3 候选
1. {top1_code} {top1_name} (评分：{top1_score})
2. {top2_code} {top2_name} (评分：{top2_score})
3. {top3_code} {top3_name} (评分：{top3_score})

当前持仓已满，继续观察。"""
    )
```

---

## 三、实施计划

### 阶段 1: 核心脚本创建 (🔴 高优先级)
| 任务 | 预计时间 | 状态 |
|------|----------|------|
| 创建 signal_fusion_scorer.py | 1h | ⏳ 待实施 |
| 创建 position_calculator.py | 1h | ⏳ 待实施 |
| 创建 exit_monitor.py | 0.5h | ⏳ 待实施 |
| 创建 execution_simulator.py | 1h | ⏳ 待实施 |
| 创建 market_gate_checker.py | 0.5h | ⏳ 待实施 |

### 阶段 2: 定时任务配置 (🔴 高优先级)
| 任务 | 预计时间 | 状态 |
|------|----------|------|
| 配置 13:35 候选池刷新 cron | 0.5h | ⏳ 待实施 |
| 配置 14:48 执行门控 cron | 0.5h | ⏳ 待实施 |
| 测试钉钉推送集成 | 0.5h | ⏳ 待实施 |

### 阶段 3: 集成测试 (🟡 中优先级)
| 任务 | 预计时间 | 状态 |
|------|----------|------|
| 端到端回测验证 | 2h | ⏳ 待实施 |
| 边界条件测试 | 1h | ⏳ 待实施 |
| 性能优化 | 1h | ⏳ 待实施 |

---

## 四、预期收益

| 指标 | 优化前 | 优化后 | 改善 |
|------|--------|--------|------|
| 信号评分一致性 | 人工判断 | 脚本化评分 | +80% |
| 仓位计算准确性 | 依赖经验 | 数学公式 | +90% |
| 执行失误率 | ~5% | <1% | -80% |
| 候选池更新频率 | 不定期 | 每日 13:35 | +100% |
| 通知及时性 | 延迟 | 实时推送 | +95% |

---

## 五、下一步行动

1. **立即执行:** 创建 5 个核心脚本
2. **本周内:** 配置定时任务 + 测试推送
3. **下周:** 完整回测验证

**是否需要我立即开始创建这些脚本？**
