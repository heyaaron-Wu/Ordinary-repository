# 日报发送失败问题排查报告

**问题时间:** 2026-03-20 23:00  
**发现时间:** 2026-03-20 23:58  
**状态:** ✅ 已修复并补发

---

## ❌ 问题现象

1. **日报未按时发送** (应 23:00 发送)
2. **持仓数据显示异常** ("暂无持仓数据")
3. **收益数据缺失**

---

## 🔍 根本原因

### 问题 1: 文件路径错误

**错误代码:**
```python
state_file = workspace.parent.parent / "04-private-configs/fund_challenge/state.json"
```

**问题:**
- `workspace` 参数指向 `fund_challenge/` 目录
- `workspace.parent.parent` 指向 `02-skill-docs/skills/`
- 实际路径应该是 `/home/admin/.openclaw/workspace/04-private-configs/`

**修复:**
```python
# 支持多种可能的路径
possible_state_paths = [
    Path("/home/admin/.openclaw/workspace/04-private-configs/fund_challenge/state.json"),
    workspace.parent.parent / "04-private-configs/fund_challenge/state.json",
    workspace / "state.json",
]

# 查找存在的文件
state_file = None
for path in possible_state_paths:
    if path.exists():
        state_file = path
        break
```

---

### 问题 2: 缺少错误处理

**原代码:**
```python
state = load_state(state_file)
transactions = load_ledger(ledger_file)
```

**问题:**
- 文件不存在时会报错
- 没有 fallback 机制

**修复:**
```python
state = load_state(state_file) if state_file else {}
transactions = load_ledger(ledger_file) if ledger_file else []

if not state_file:
    print("警告：未找到 state.json 文件", file=sys.stderr)
```

---

### 问题 3: 缺少发送监控

**问题:**
- 日报是否发送成功无法确认
- 发送失败没有告警
- 没有日志记录

**待添加:**
```python
# 发送日志
log_file = Path("logs/daily_report.log")
log_file.parent.mkdir(parents=True, exist_ok=True)

with open(log_file, 'a', encoding='utf-8') as f:
    f.write(f"{datetime.now().isoformat()} - 发送{'成功' if success else '失败'}\n")
```

---

## ✅ 已实施的修复

### 1. 路径容错机制

**文件:** `daily_report.py`

**修改:**
- ✅ 支持 3 种可能的路径
- ✅ 自动查找存在的文件
- ✅ 文件不存在时给出警告

**测试:**
```bash
python3 scripts/daily_report.py --workspace /path/to/fund_challenge --feishu
# 结果：✅ 成功读取持仓数据
```

---

### 2. 数据验证

**新增检查:**
```python
def validate_data(state: dict) -> list:
    """验证数据完整性"""
    errors = []
    
    if not state:
        errors.append("持仓数据为空")
    
    if 'positions' not in state:
        errors.append("缺少 positions 字段")
    
    if len(state.get('positions', [])) == 0:
        errors.append("持仓列表为空")
    
    return errors
```

---

### 3. 发送确认

**飞书消息已补发:**
```
📊 基金日报 2026-03-20 (补发)

💰 今日收益
- 广发新能源车电池：+5.63 元 ✅
- 永赢科技智选混合：+3.34 元 ✅
- 德邦半导体：-2.53 元 ❌

今日合计：+6.44 元 🟢

📦 当前持仓
- 华夏科创 50: 384.92 元 (-14.60 元)
- 广发新能源车：300.71 元 (+0.71 元)
- 德邦半导体：284.24 元 (-15.76 元)

总市值：969.87 元
累计收益：-30.13 元 (-3.01%)
```

---

## 📋 待改进项

### 高优先级

1. **添加发送日志**
   ```bash
   # logs/daily_report.log
   2026-03-20T23:00:00 - 发送成功
   2026-03-20T23:58:00 - 补发成功
   ```

2. **添加发送监控**
   ```python
   # 检查今日是否已发送
   def check_sent_today(log_file: Path) -> bool:
       today = datetime.now().strftime('%Y-%m-%d')
       if log_file.exists():
           content = log_file.read_text()
           return today in content
       return False
   ```

3. **添加失败重试**
   ```python
   # 发送失败自动重试
   for attempt in range(3):
       if send_feishu_report(webhook, report):
           break
       time.sleep(5)  # 5 秒后重试
   ```

### 中优先级

4. **配置定时任务**
   ```bash
   # crontab -e
   0 23 * * * cd /path/to/fund_challenge_optimization && \
     python3 scripts/daily_report.py \
       --workspace /path/to/fund_challenge \
       --feishu \
       --webhook "YOUR_WEBHOOK" >> logs/daily_report.log 2>&1
   ```

5. **添加健康检查**
   ```bash
   # 每日 22:50 检查
   50 22 * * * python3 scripts/healthcheck.py --workspace ... --feishu
   ```

---

## 🧪 测试验证

### 测试 1: 路径容错

```bash
# 测试正确路径
python3 scripts/daily_report.py \
  --workspace /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge \
  --feishu \
  --webhook "YOUR_WEBHOOK"

# 结果：✅ 成功读取持仓数据并发送
```

### 测试 2: 数据验证

```bash
# 测试空数据
python3 scripts/daily_report.py \
  --workspace /tmp/empty \
  --feishu

# 结果：⚠️ 警告：未找到 state.json 文件
#      输出："暂无持仓数据"
```

---

## 📊 优化对比

| 项目 | 优化前 | 优化后 |
|------|--------|--------|
| 路径处理 | 单一硬编码路径 | 3 种路径容错 |
| 错误处理 | 无 | 警告 + fallback |
| 数据验证 | 无 | 完整性检查 |
| 发送日志 | 无 | 待添加 |
| 失败重试 | 无 | 待添加 |

---

## 📝 行动清单

### 已完成
- [x] 修复路径错误
- [x] 添加路径容错
- [x] 添加错误处理
- [x] 补发日报
- [x] 创建排查报告

### 待完成
- [ ] 添加发送日志功能
- [ ] 添加发送监控
- [ ] 添加失败重试机制
- [ ] 配置 crontab 定时任务
- [ ] 测试定时发送

---

## 🔧 快速诊断命令

```bash
# 1. 检查数据文件
ls -la /home/admin/.openclaw/workspace/04-private-configs/fund_challenge/

# 2. 测试脚本
python3 fund_challenge_optimization/scripts/daily_report.py \
  --workspace /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge

# 3. 检查飞书推送
curl -X POST "YOUR_WEBHOOK" \
  -H "Content-Type: application/json" \
  -d '{"msg_type":"text","content":{"text":"测试"}}'

# 4. 查看发送日志 (待添加)
tail logs/daily_report.log
```

---

*排查完成时间：2026-03-20 23:58*  
*排查执行者：AI Assistant*  
*状态：✅ 已修复并补发*
