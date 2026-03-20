#!/usr/bin/env python3
"""
基金挑战健康检查脚本
每日开盘前自动检查系统状态，确保决策流程正常

用法:
    python3 healthcheck.py --workspace /path/to/fund_challenge

检查项目:
1. 脚本可执行性
2. 证据文件完整性
3. Webhook 连通性
4. 持仓状态
5. 交易日历
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path
from datetime import datetime


class HealthCheck:
    def __init__(self, name: str):
        self.name = name
        self.status = "UNKNOWN"  # OK, WARNING, ERROR
        self.message = ""
        self.details = {}
    
    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "status": self.status,
            "message": self.message,
            "details": self.details
        }


def check_script_executable(workspace: Path) -> HealthCheck:
    """检查脚本可执行性"""
    check = HealthCheck("脚本可执行性")
    
    scripts = [
        "scripts/state_math.py",
        "scripts/build_evidence.py",
        "scripts/validate_evidence.py",
        "scripts/preflight_guard.py",
        "scripts/universe_refresh_script_only.py"
    ]
    
    missing = []
    not_executable = []
    
    for script in scripts:
        script_path = workspace / script
        if not script_path.exists():
            missing.append(script)
        else:
            import os
            if not os.access(script_path, os.X_OK):
                not_executable.append(script)
    
    if missing:
        check.status = "ERROR"
        check.message = f"脚本缺失：{', '.join(missing)}"
    elif not_executable:
        check.status = "WARNING"
        check.message = f"脚本无执行权限：{', '.join(not_executable)}"
        check.details["fix"] = "运行 chmod +x scripts/*.py"
    else:
        check.status = "OK"
        check.message = f"所有 {len(scripts)} 个脚本可执行"
    
    return check


def check_evidence_files(workspace: Path) -> HealthCheck:
    """检查证据文件完整性"""
    check = HealthCheck("证据文件完整性")
    
    evidence_dir = workspace / "evidence"
    latest_file = evidence_dir / "latest.json"
    template_file = evidence_dir / "template.json"
    
    if not evidence_dir.exists():
        check.status = "ERROR"
        check.message = "证据目录不存在"
        return check
    
    if not latest_file.exists():
        check.status = "WARNING"
        check.message = "最新证据文件不存在 (将自动生成)"
        return check
    
    if not template_file.exists():
        check.status = "ERROR"
        check.message = "证据模板文件缺失"
        return check
    
    try:
        evidence = json.loads(latest_file.read_text(encoding='utf-8'))
        
        # 检查必填字段
        required = ["decisionId", "phase", "status", "stateDigest"]
        missing = [f for f in required if f not in evidence]
        
        if missing:
            check.status = "WARNING"
            check.message = f"证据文件缺少字段：{missing}"
        else:
            check.status = "OK"
            check.message = f"证据文件完整 (决策：{evidence['decisionId']})"
            check.details["decision_id"] = evidence["decisionId"]
            check.details["status"] = evidence.get("status", "UNKNOWN")
            check.details["generated_at"] = evidence.get("generatedAt", "UNKNOWN")
    
    except Exception as e:
        check.status = "ERROR"
        check.message = f"证据文件解析失败：{e}"
    
    return check


def check_webhook_connectivity(webhook_url: str) -> HealthCheck:
    """检查 Webhook 连通性"""
    check = HealthCheck("飞书 Webhook 连通性")
    
    if not webhook_url or webhook_url == "YOUR_FEISHU_WEBHOOK":
        check.status = "WARNING"
        check.message = "Webhook 未配置 (使用占位符)"
        check.details["fix"] = "在 CRON_JOBS.md 中配置实际 webhook"
        return check
    
    try:
        import requests
        
        # 发送测试消息
        payload = {
            "msg_type": "text",
            "content": {
                "text": "🔍 健康检查测试消息"
            }
        }
        
        response = requests.post(webhook_url, json=payload, timeout=10)
        result = response.json()
        
        if result.get('StatusCode', 1) == 0 or result.get('code', 1) == 0:
            check.status = "OK"
            check.message = "Webhook 连通性正常"
        else:
            check.status = "WARNING"
            check.message = f"Webhook 返回错误：{result}"
    
    except requests.exceptions.Timeout:
        check.status = "ERROR"
        check.message = "Webhook 连接超时"
    except requests.exceptions.ConnectionError:
        check.status = "ERROR"
        check.message = "无法连接到飞书服务器"
    except Exception as e:
        check.status = "ERROR"
        check.message = f"Webhook 测试失败：{e}"
    
    return check


def check_portfolio_state(workspace: Path) -> HealthCheck:
    """检查持仓状态"""
    check = HealthCheck("持仓状态")
    
    state_file = workspace / "state.json"
    
    if not state_file.exists():
        check.status = "WARNING"
        check.message = "持仓状态文件不存在"
        return check
    
    try:
        state = json.loads(state_file.read_text(encoding='utf-8'))
        
        holdings = state.get("holdings", [])
        cash = float(state.get("cash", 0))
        portfolio_value = float(state.get("holdingsMarketValue", 0)) + cash
        
        check.status = "OK"
        check.message = f"持仓正常 ({len(holdings)}只，市值 {portfolio_value:.2f}元)"
        check.details["holdings_count"] = len(holdings)
        check.details["cash"] = cash
        check.details["portfolio_value"] = portfolio_value
        
        # 检查异常情况
        warnings = []
        if cash == 0:
            warnings.append("现金为 0，无法加仓")
        if len(holdings) >= 5:
            warnings.append("持仓已满 (5 只)")
        
        if warnings:
            check.message += " ⚠️ " + "，".join(warnings)
    
    except Exception as e:
        check.status = "ERROR"
        check.message = f"持仓状态解析失败：{e}"
    
    return check


def check_trading_calendar() -> HealthCheck:
    """检查交易日历"""
    check = HealthCheck("交易日历")
    
    try:
        # 导入交易日历模块
        from pathlib import Path
        import sys
        
        # 尝试查找 trading_calendar.py
        calendar_script = None
        for base in [
            Path(__file__).parent,
            Path.cwd(),
            Path("/home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge/scripts")
        ]:
            candidate = base / "trading_calendar.py"
            if candidate.exists():
                calendar_script = candidate
                break
        
        if not calendar_script:
            check.status = "WARNING"
            check.message = "交易日历脚本未找到"
            return check
        
        # 运行交易日检查
        result = subprocess.run(
            [sys.executable, str(calendar_script), "--status"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
            timeout=10
        )
        
        status = json.loads(result.stdout)
        
        if status.get("is_trading_day"):
            check.status = "OK"
            check.message = "今日是交易日"
            check.details["market_status"] = status.get("market_status", "UNKNOWN")
            check.details["deadline"] = status.get("deadline_message", "UNKNOWN")
        else:
            check.status = "WARNING"
            check.message = "今日是非交易日"
            check.details["reason"] = status.get("message", "UNKNOWN")
            check.details["next_trading_day"] = status.get("next_trading_day", "UNKNOWN")
    
    except Exception as e:
        check.status = "WARNING"
        check.message = f"交易日历检查失败：{e}"
    
    return check


def run_healthcheck(workspace: Path, webhook_url: str = "") -> dict:
    """运行所有健康检查"""
    checks = [
        check_script_executable(workspace),
        check_evidence_files(workspace),
        check_webhook_connectivity(webhook_url),
        check_portfolio_state(workspace),
        check_trading_calendar(),
    ]
    
    # 统计
    ok_count = sum(1 for c in checks if c.status == "OK")
    warning_count = sum(1 for c in checks if c.status == "WARNING")
    error_count = sum(1 for c in checks if c.status == "ERROR")
    
    # 总体状态
    if error_count > 0:
        overall_status = "ERROR"
    elif warning_count > 0:
        overall_status = "WARNING"
    else:
        overall_status = "OK"
    
    return {
        "timestamp": datetime.now().isoformat(),
        "workspace": str(workspace),
        "overall_status": overall_status,
        "summary": {
            "ok": ok_count,
            "warning": warning_count,
            "error": error_count,
            "total": len(checks)
        },
        "checks": [c.to_dict() for c in checks]
    }


def format_report(result: dict, compact: bool = False) -> str:
    """格式化健康检查报告"""
    lines = []
    
    # 标题
    status_emoji = {"OK": "✅", "WARNING": "⚠️", "ERROR": "❌"}
    emoji = status_emoji.get(result["overall_status"], "❓")
    
    lines.append(f"{emoji} 系统健康检查报告")
    lines.append("")
    lines.append(f"**检查时间**: {result['timestamp']}")
    lines.append(f"**总体状态**: {result['overall_status']}")
    lines.append("")
    
    # 汇总
    summary = result["summary"]
    lines.append("**检查汇总**:")
    lines.append(f"- ✅ 正常：{summary['ok']}")
    lines.append(f"- ⚠️ 警告：{summary['warning']}")
    lines.append(f"- ❌ 错误：{summary['error']}")
    lines.append("")
    
    # 详细检查
    lines.append("**详细检查**:")
    lines.append("")
    
    for check in result["checks"]:
        check_emoji = {"OK": "✅", "WARNING": "⚠️", "ERROR": "❌"}
        emoji = check_emoji.get(check["status"], "❓")
        lines.append(f"{emoji} **{check['name']}**: {check['message']}")
        
        if not compact and check.get("details"):
            for key, value in check["details"].items():
                lines.append(f"  - {key}: {value}")
    
    lines.append("")
    
    # 建议
    if result["overall_status"] != "OK":
        lines.append("**建议操作**:")
        for check in result["checks"]:
            if check["status"] != "OK" and "fix" in check.get("details", {}):
                lines.append(f"- {check['name']}: {check['details']['fix']}")
    
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description='基金挑战健康检查脚本')
    parser.add_argument('--workspace', type=str, required=True,
                        help='基金挑战工作目录')
    parser.add_argument('--webhook', type=str, default='',
                        help='飞书 webhook URL')
    parser.add_argument('--send-alert', action='store_true',
                        help='发送飞书告警 (仅当状态异常时)')
    parser.add_argument('--compact', action='store_true',
                        help='精简输出模式')
    parser.add_argument('--json', action='store_true',
                        help='输出 JSON 格式')
    args = parser.parse_args()
    
    workspace = Path(args.workspace).resolve()
    
    if not workspace.exists():
        print(json.dumps({"error": f"工作目录不存在：{workspace}"}))
        sys.exit(1)
    
    # 运行检查
    result = run_healthcheck(workspace, args.webhook)
    
    # 输出
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        report = format_report(result, compact=args.compact)
        print(report)
    
    # 发送告警
    if args.send_alert and result["overall_status"] != "OK" and args.webhook:
        try:
            import requests
            
            alert_message = f"⚠️ 系统健康检查异常\n\n{format_report(result, compact=True)}"
            
            payload = {
                "msg_type": "text",
                "content": {"text": alert_message}
            }
            
            requests.post(args.webhook, json=payload, timeout=10)
            print("\n✅ 告警已发送")
        
        except Exception as e:
            print(f"\n⚠️ 告警发送失败：{e}")
    
    # 退出码
    sys.exit(0 if result["overall_status"] == "OK" else 1)


if __name__ == "__main__":
    main()
