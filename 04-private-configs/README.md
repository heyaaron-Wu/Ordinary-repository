# 04-private-configs/ - 私有配置文件

**🔒 此文件夹包含敏感信息，不推送到 GitHub**

---

## 📁 文件夹说明

此文件夹用于存储 OpenClaw 的私有配置文件，包含敏感信息，**不应推送到公开仓库**。

### 包含内容

- `memory/` - 记忆文件（个人使用习惯、配置偏好）
- `fund_challenge/` - 基金挑战配置（持仓信息、交易记录）
- `fund-challenge/` - 基金挑战技能配置
- 其他私有配置文件

---

## 🔒 隐私保护

### 为什么不推送？

此文件夹包含以下敏感信息：

1. **持仓信息** - 基金持仓金额、交易记录
2. **个人习惯** - 使用偏好、配置习惯
3. **API Keys** - 各种服务的访问令牌
4. **Webhook URLs** - 飞书、钉钉等推送地址

### .gitignore 配置

已在根目录 `.gitignore` 中配置：

```gitignore
# 私有配置 - 不推送
04-private-configs/
```

---

## 📋 本地文件结构

```
04-private-configs/
├── memory/                    # 记忆文件
│   ├── 2026-03-08.md
│   ├── 2026-03-10.md
│   └── failures.md
├── fund_challenge/            # 基金挑战配置
│   ├── state.json
│   ├── ledger.jsonl
│   └── ...
└── fund-challenge/            # 基金挑战技能
    └── ...
```

---

## ⚠️ 重要提示

### 不要提交

**切勿**将此文件夹中的任何文件提交到 Git：

```bash
# ❌ 错误做法
git add 04-private-configs/
git commit -m "添加私有配置"

# ✅ 正确做法
# 保持 .gitignore 配置，不提交
```

### 备份建议

建议定期备份此文件夹到安全位置：

```bash
# 加密备份
tar -czf private-configs-backup-$(date +%Y%m%d).tar.gz 04-private-configs/
# 存储到安全位置（不要上传到公开仓库）
```

---

## 🔐 安全最佳实践

1. ✅ 使用 .gitignore 排除私有文件
2. ✅ 定期备份到加密存储
3. ✅ 不在公开场合分享配置内容
4. ✅ 定期轮换 API Keys 和 Webhook URLs
5. ✅ 限制文件访问权限

```bash
# 设置文件权限
chmod 600 04-private-configs/fund_challenge/state.json
```

---

## 📝 本地使用

### 访问私有配置

```bash
# 查看记忆文件
cat 04-private-configs/memory/failures.md

# 查看基金状态
cat 04-private-configs/fund_challenge/state.json

# 查看交易记录
cat 04-private-configs/fund_challenge/ledger.jsonl
```

---

## 🔗 相关文件

- [隐私审计报告](../03-system-docs/PRIVACY_AUDIT_REPORT.md)
- [文件结构说明](../03-system-docs/FILE_STRUCTURE.md)
- [.gitignore](../.gitignore)

---

*最后更新：2026-03-13*

**⚠️ 此文件仅用于说明，04-private-configs/ 文件夹内容不推送到 GitHub**
