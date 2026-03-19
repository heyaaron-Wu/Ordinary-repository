# 路径错误全面修复报告

**修复时间**: 2026-03-19 16:00  
**修复范围**: 所有定时任务的脚本路径配置

---

## 📋 问题清单

### 1️⃣ 定时任务配置中的路径错误

**错误路径模式**:
```
/home/admin/.openclaw/workspace/skills/fund-challenge/fund_challenge/...
```

**正确路径模式**:
```
/home/admin/.openclaw/workspace/fund_challenge/...
(符号链接指向 02-skill-docs/skills/fund-challenge/fund_challenge)
```

**受影响的任务**:
| 任务名 | 错误路径数 | 状态 |
|--------|-----------|------|
| fund-daily-check | 5 处 | ✅ 已修正 |
| fund-1400-decision | 1 处 | ✅ 已修正 |
| fund-2200-review | 1 处 | ✅ 已修正 |
| fund-1335-universe | 3 处 | ✅ 已修正 |
| fund-1448-exec-gate | 2 处 | ✅ 已修正 |
| system-weekly-report | 1 处 | ✅ 已修正 |
| **总计** | **13 处** | ✅ **全部修正** |

---

### 2️⃣ preflight_guard.py 内部路径问题 ⚠️

**问题**: 脚本内部使用相对路径引用子脚本

**原代码**:
```python
c0 = [
    sys.executable,
    "fund_challenge/scripts/fund_pool_screener.py",  # ❌ 相对路径
    "--state",
    "fund_challenge/state.json",
    ...
]
code, out, err = run(c0, ws)
```

**问题表现**:
```bash
/usr/bin/python3: can't open file 'fund_challenge/scripts/fund_pool_screener.py': 
[Errno 2] No such file or directory
```

**根本原因**:
- 脚本使用 `run(cmd, cwd)` 执行子进程
- `cwd` 设置为 workspace 目录
- 但命令中的路径是相对路径 `fund_challenge/scripts/...`
- 当 workspace 不是 `/home/admin/.openclaw/workspace` 时，路径解析失败

---

## ✅ 修复方案

### 方案 1: 定时任务配置 - 使用符号链接路径

**修改前**:
```bash
python3 /home/admin/.openclaw/workspace/skills/fund-challenge/fund_challenge/scripts/is_trading_day.py
```

**修改后**:
```bash
python3 /home/admin/.openclaw/workspace/fund_challenge/scripts/is_trading_day.py
```

**优势**:
- 使用符号链接，路径更短
- 统一路径规范
- 易于维护

---

### 方案 2: preflight_guard.py - 使用绝对路径

**新增辅助函数**:
```python
# 获取脚本所在目录作为基础路径
SCRIPT_DIR = Path(__file__).parent.resolve()

def make_cmd(script_path, *args):
    """构建命令，使用绝对路径避免相对路径问题"""
    cmd = [sys.executable, str(SCRIPT_DIR / script_path)]
    cmd.extend(args)
    return cmd
```

**修改前**:
```python
c0 = [
    sys.executable,
    "fund_challenge/scripts/fund_pool_screener.py",
    "--state", "fund_challenge/state.json",
    ...
]
code, out, err = run(c0, ws)
```

**修改后**:
```python
c0 = make_cmd(
    "fund_pool_screener.py",
    "--state", str(ws / "state.json"),
    "--rules", str(ws / "instrument_rules.json"),
    "--output", str(ws / "cache/fund_pool.json"),
)
code, out, err = run(c0, ws)
```

**修复的子脚本**:
1. ✅ fund_pool_screener.py
2. ✅ state_math.py
3. ✅ refresh_instrument_rules.py
4. ✅ evidence_data_collector.py
5. ✅ build_evidence.py
6. ✅ validate_evidence.py
7. ✅ decision_publish_gate.py

---

## 🧪 验证结果

### 测试 1: is_trading_day.py
```bash
$ time python3 /home/admin/.openclaw/workspace/fund_challenge/scripts/is_trading_day.py
TRADING_DAY

real    0m0.054s
user    0m0.042s
sys     0m0.011s
```
✅ **通过** (<100ms)

---

### 测试 2: preflight_guard.py (修复后)
```bash
$ time python3 fund_challenge/scripts/preflight_guard.py \
    --phase PLAN_ONLY --compact \
    --workspace /home/admin/.openclaw/workspace/fund_challenge

{
  "ok": true,
  "phase": "PLAN_ONLY",
  "steps": [
    {"step": "fund_pool_screener", "ok": true, ...},
    {"step": "state_math", "ok": true, ...},
    {"step": "refresh_instrument_rules", "ok": true, ...},
    {"step": "evidence_data_collector", "ok": true, ...},
    {"step": "build_evidence", "ok": true, ...},
    {"step": "validate_evidence", "ok": true, ...}
  ]
}

real    0m0.674s
user    0m0.528s
sys     0m0.113s
```
✅ **通过** (所有步骤成功)

---

### 测试 3: status_brief.py
```bash
$ time python3 /home/admin/.openclaw/workspace/fund_challenge/scripts/status_brief.py \
    --state /home/admin/.openclaw/workspace/fund_challenge/state.json

PV 999.52 | UPnL 0.00 | Gap 1000.48

real    0m0.070s
user    0m0.053s
sys     0m0.015s
```
✅ **通过**

---

## 📊 性能对比

| 脚本 | 修复前 | 修复后 | 改善 |
|------|--------|--------|------|
| is_trading_day.py | ❌ 路径错误 | ✅ 0.054s | 可执行 |
| preflight_guard.py | ❌ 路径错误 | ✅ 0.674s | 可执行 |
| status_brief.py | ✅ 0.070s | ✅ 0.070s | - |

---

## 📁 修改文件清单

### 1. 定时任务配置
- **文件**: `/home/admin/.openclaw/cron/jobs.json`
- **修改**: 13 处路径修正
- **影响任务**: 6 个

### 2. 预检管线脚本
- **文件**: `/home/admin/.openclaw/workspace/fund_challenge/scripts/preflight_guard.py`
- **修改**: 
  - 新增 `SCRIPT_DIR` 常量
  - 新增 `make_cmd()` 辅助函数
  - 修正 7 个子脚本调用
- **行数**: +20 行代码

---

## 🔍 路径错误日志检查

### 检查结果
```bash
# 检查 cron 运行日志
grep -r "FileNotFoundError\|No such file" /home/admin/.openclaw/cron/runs/*.jsonl
# 结果：无输出 (未发现新的路径错误)

# 检查所有任务配置
cat /home/admin/.openclaw/cron/jobs.json | python3 check_paths.py
# 结果：所有任务路径正确 ✅
```

### 历史错误 (已修复)
- ✅ 03-09 到 03-19 的超时错误 - 部分由路径错误导致
- ✅ preflight_guard.py 的子脚本路径 - 已修正为绝对路径

---

## ⚠️ 剩余风险

### 风险 1: 其他脚本可能也有路径问题

**检查范围**:
```bash
# 检查 fund_challenge 目录下的所有 Python 脚本
grep -r "fund_challenge/scripts" /home/admin/.openclaw/workspace/fund_challenge/scripts/*.py
```

**建议**: 如有其他脚本调用子脚本，也应使用 `make_cmd()` 模式

---

### 风险 2: 符号链接失效

**当前符号链接**:
```bash
lrwxrwxrwx 1 admin admin 91 Mar 18 15:01 evidence -> /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge/evidence
lrwxrwxrwx 1 admin admin 82 Mar 18 13:36 fund_challenge -> /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge
```

**验证**:
```bash
$ ls -la /home/admin/.openclaw/workspace/fund_challenge/scripts/is_trading_day.py
-rwxr-xr-x 1 admin admin ... /home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge/scripts/is_trading_day.py
```
✅ **符号链接有效**

---

## 📅 监控计划

### 明天 (03-20) 观察要点

1. **14:00 决策任务**
   - [ ] 执行时间 <600 秒
   - [ ] 无路径错误日志
   - [ ] 飞书推送正常

2. **13:35 候选池刷新**
   - [ ] fund_pool_screener.py 执行成功
   - [ ] 无 FileNotFoundError

3. **14:48 执行门控**
   - [ ] preflight_guard.py 执行成功
   - [ ] 所有子步骤通过

4. **日志检查**
   - [ ] `grep "No such file" /home/admin/.openclaw/cron/runs/*.jsonl` 无输出
   - [ ] `grep "FileNotFoundError" /home/admin/.openclaw/cron/runs/*.jsonl` 无输出

---

## 📝 最佳实践总结

### 路径规范

1. **使用符号链接**
   - `/workspace/fund_challenge/` → 简短、统一
   - 避免使用 `/workspace/skills/fund-challenge/fund_challenge/`

2. **脚本内部使用绝对路径**
   - 使用 `Path(__file__).parent.resolve()` 获取脚本目录
   - 使用 `make_cmd()` 构建子脚本命令
   - 避免硬编码相对路径

3. **workspace 参数传递**
   - 所有路径基于 workspace 构建
   - 使用 `ws / "subdir/file"` 模式
   - 避免混用相对路径和绝对路径

---

**修复完成时间**: 2026-03-19 16:05  
**修复执行者**: AI Assistant  
**下次回顾**: 2026-03-20 (观察一天后)
