# 定时任务配置说明

**版本更新检查 - 每晚 23:30 自动执行**

---

## 📋 任务说明

### 任务名称
`version-update-check` - 版本更新检查

### 执行时间
```
每天 23:30（北京时间）
```

### Cron 表达式
```bash
30 23 * * *
```

### 任务功能
1. ✅ 检查当日是否有代码提交
2. ✅ 分类统计提交类型（新增/优化/修复/文档/安全）
3. ✅ 自动更新 CHANGELOG.md
4. ✅ 自动提交并推送到 GitHub
5. ✅ 如无更新则跳过，不产生变更

---

## 🚀 配置方法

### 方法 1: OpenClaw Cron（推荐）

在 OpenClaw 中配置定时任务：

```json
{
  "id": "version-update-check",
  "name": "版本更新检查",
  "description": "每晚 23:30 检查当日版本更新并更新 CHANGELOG",
  "enabled": true,
  "schedule": {
    "kind": "cron",
    "expr": "30 23 * * *"
  },
  "sessionTarget": "isolated",
  "wakeMode": "now",
  "payload": {
    "kind": "agentTurn",
    "message": "bash /home/admin/.openclaw/workspace/07-version-updates/scripts/check_daily_updates.sh",
    "timeoutSeconds": 300
  },
  "retryPolicy": {
    "maxRetries": 1,
    "retryDelaySeconds": 60
  },
  "delivery": {
    "mode": "none"
  }
}
```

### 方法 2: System Cron

```bash
# 编辑 crontab
crontab -e

# 添加以下行
30 23 * * * cd /home/admin/.openclaw/workspace/07-version-updates/scripts && bash check_daily_updates.sh >> /tmp/version-check.log 2>&1
```

### 方法 3: 手动执行

```bash
# 手动测试
cd /home/admin/.openclaw/workspace/07-version-updates/scripts
bash check_daily_updates.sh
```

---

## 📊 执行流程

```
23:30 定时触发
    ↓
检查今日 Git 提交
    ↓
有提交？──否──→ ✅ 无需更新，退出
    │
   是
    ↓
分类统计提交
├─ ✨ 新增功能
├─ 🚀 性能优化
├─ 🐛 Bug 修复
├─ 📝 文档更新
└─ 🔒 安全修复
    ↓
生成更新日志
    ↓
更新 CHANGELOG.md
    ↓
Git 提交并推送
    ↓
✅ 完成
```

---

## 📝 输出示例

### 有更新时

```bash
🔍 版本更新检查
==============
日期：2026-03-13

📊 检查今日提交记录...
发现 5 个提交

📝 今日提交详情:
ff8e0c5 🤖 添加版本更新检查脚本 + 更新.gitignore
db51066 Update CHANGELOG.md
4456f6d 📚 添加飞书推送完全指南
b0924e7 🤖 添加日终复盘自动化脚本
b03acad 📊 添加 2026-03-12 日终复盘报告

📊 提交分类统计:
  ✨ 新增功能：2 个
  🚀 性能优化：1 个
  🐛 Bug 修复：0 个
  📝 文档更新：2 个
  🔒 安全修复：0 个

📝 准备更新 CHANGELOG.md...
📝 更新 CHANGELOG.md...
✅ CHANGELOG.md 已更新

📤 提交 CHANGELOG 更新...
[OpenClaw-Fund-Trading xxx] 📝 更新版本更新日志 - 2026-03-13

🚀 推送到 GitHub...
To https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system.git
   xxx..yyy  OpenClaw-Fund-Trading -> OpenClaw-Fund-Trading

================================
✅ 版本更新检查完成！

📄 更新文件：07-version-updates/CHANGELOG.md
📊 今日提交：5 个
🔗 GitHub: https://github.com/.../CHANGELOG.md
```

### 无更新时

```bash
🔍 版本更新检查
==============
日期：2026-03-13

📊 检查今日提交记录...
✅ 今日无提交记录，无需更新 CHANGELOG
```

---

## 📁 相关文件

| 文件 | 路径 | 作用 |
|------|------|------|
| 检查脚本 | `07-version-updates/scripts/check_daily_updates.sh` | 主执行脚本 |
| 更新日志 | `07-version-updates/CHANGELOG.md` | 版本历史记录 |
| 配置说明 | `07-version-updates/CRON_CONFIG.md` | 本文档 |

---

## 🔧 故障排查

### 问题 1: 脚本无法执行

**错误:** `Permission denied`

**解决方案:**
```bash
chmod +x 07-version-updates/scripts/check_daily_updates.sh
```

### 问题 2: Git 推送失败

**错误:** `Updates were rejected`

**解决方案:**
```bash
cd /home/admin/.openclaw/workspace
git pull --rebase
git push
```

### 问题 3: CHANGELOG.md 格式错误

**解决方案:**
1. 检查 CHANGELOG.md 文件格式
2. 确保包含版本历史部分
3. 参考模板格式

---

## 📊 日志查看

### 查看执行日志

```bash
# 查看最新日志
tail -f /tmp/version-check.log

# 查看历史日志
cat /tmp/version-check.log | grep "2026-03-13"
```

### 查看 Git 提交

```bash
cd /home/admin/.openclaw/workspace
git log --since="2026-03-13" --until="2026-03-14" --oneline
```

### 查看 CHANGELOG 更新

```bash
cd /home/admin/.openclaw/workspace
git diff HEAD~1 07-version-updates/CHANGELOG.md
```

---

## 🎯 最佳实践

### 1. 提交信息规范

使用统一的提交信息格式：

```
✨ feat: 添加新功能
🚀 perf: 性能优化
🐛 fix: Bug 修复
📝 docs: 文档更新
🔒 security: 安全修复
```

### 2. 定期检查

每周检查一次 CHANGELOG.md：
```bash
# 每周一 9:00 检查
0 9 * * 1 cd /home/admin/.openclaw/workspace/07-version-updates && cat CHANGELOG.md | head -30
```

### 3. 版本发布

每月发布一个正式版本：
```markdown
## [v1.1.0] - 2026-04-01

### ✨ 新增
- 3 月份所有新功能

### 🚀 优化
- 性能改进

### 🐛 修复
- Bug 修复
```

---

## 🔗 相关链接

- [GitHub 仓库](https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system)
- [CHANGELOG.md](https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system/blob/OpenClaw-Fund-Trading/07-version-updates/CHANGELOG.md)
- [版本更新脚本](https://github.com/heyaaron-Wu/Semi-automatic-artificial-intelligence-system/blob/OpenClaw-Fund-Trading/07-version-updates/scripts/check_daily_updates.sh)

---

*最后更新：2026-03-13*
