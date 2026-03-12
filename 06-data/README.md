# 06-data/ - 数据文件

**🔒 此文件夹包含敏感数据，不推送到 GitHub**

---

## 📁 文件夹说明

此文件夹用于存储 OpenClaw 的数据文件，包含服务器健康数据等敏感信息，**不应推送到公开仓库**。

---

## 🔒 隐私保护

### 为什么不推送？

此文件夹包含以下敏感信息：

1. **服务器健康数据** - 系统运行状态、性能指标
2. **历史监控记录** - 长期趋势数据
3. **配置信息** - 可能包含敏感配置

### .gitignore 配置

已在根目录 `.gitignore` 中配置：

```gitignore
# 私有配置 - 不推送
06-data/
```

---

## 📋 本地文件结构

```
06-data/
└── health-history.json        # 健康检查历史数据
```

---

## ⚠️ 重要提示

### 不要提交

**切勿**将此文件夹中的任何文件提交到 Git：

```bash
# ❌ 错误做法
git add 06-data/
git commit -m "添加数据文件"

# ✅ 正确做法
# 保持 .gitignore 配置，不提交
```

### 备份建议

建议定期备份此文件夹：

```bash
# 本地备份
cp -r 06-data/ ~/backup/openclaw-data-$(date +%Y%m%d)/
```

---

## 🔐 安全最佳实践

1. ✅ 使用 .gitignore 排除数据文件
2. ✅ 定期备份到安全位置
3. ✅ 限制文件访问权限
4. ✅ 不在公开场合分享数据内容

```bash
# 设置文件权限
chmod 600 06-data/health-history.json
```

---

## 📝 本地使用

### 访问数据文件

```bash
# 查看健康历史
cat 06-data/health-history.json | python3 -m json.tool

# 分析趋势
python3 -c "import json; data=json.load(open('06-data/health-history.json')); print(data)"
```

---

## 🔗 相关文件

- [隐私审计报告](../03-system-docs/PRIVACY_AUDIT_REPORT.md)
- [文件结构说明](../03-system-docs/FILE_STRUCTURE.md)
- [.gitignore](../.gitignore)

---

*最后更新：2026-03-13*

**⚠️ 此文件仅用于说明，06-data/ 文件夹内容不推送到 GitHub**
