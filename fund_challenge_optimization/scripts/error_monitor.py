#!/usr/bin/env python3
"""
基金挑战错误监控脚本
监控定时任务错误，连续错误达到阈值时自动告警

用法:
    python3 error_monitor.py --workspace /path/to/fund_challenge --webhook YOUR_WEBHOOK

功能:
1. 监控 cron 任务错误
2. 连续错误计数
3. 自动告警 (达到阈值)
4. 错误日志分析
"""

import argparse
import json
import sys
from pathlib import Path
from datetime import datetime, timedelta
from typing import List, Dict


class ErrorMonitor:
    """错误监控类"""
    
    # 监控的任务
    MONITORED_TASKS = [
        "fund-1400-decision",
        "fund-1448-exec-gate",
        "fund-1335-universe-refresh",
        "fund-0900-healthcheck",
        "fund-2005-review",
    ]
    
    # 告警阈值
    WARNING_THRESHOLD = 2   # 连续 2 次错误发警告
    CRITICAL_THRESHOLD = 3  # 连续 3 次错误发严重告警
    
    def __init__(self, workspace: Path):
        self.workspace = workspace
        self.cron_dir = workspace.parent.parent.parent / ".openclaw" / "cron"
        self.runs_dir = self.cron_dir / "runs"
        self.state_file = self.cron_dir / "error_monitor_state.json"
    
    def load_state(self) -> dict:
        """加载监控状态"""
        if self.state_file.exists():
            return json.loads(self.state_file.read_text(encoding='utf-8'))
        return {
            "tasks": {},
            "last_check": None,
            "total_alerts": 0
        }
    
    def save_state(self, state: dict):
        """保存监控状态"""
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        self.state_file.write_text(
            json.dumps(state, ensure_ascii=False, indent=2),
            encoding='utf-8'
        )
    
    def get_task_runs(self, task_name: str, limit: int = 10) -> List[dict]:
        """获取任务运行记录"""
        runs_file = self.runs_dir / f"{task_name}.jsonl"
        
        if not runs_file.exists():
            return []
        
        runs = []
        with open(runs_file, 'r', encoding='utf-8') as f:
            for line in f:
                try:
                    runs.append(json.loads(line))
                except:
                    continue
        
        # 按时间倒序
        runs.sort(key=lambda x: x.get('startedAt', ''), reverse=True)
        return runs[:limit]
    
    def check_task_errors(self, task_name: str, state: dict) -> dict:
        """检查单个任务的错误"""
        runs = self.get_task_runs(task_name)
        
        if not runs:
            return {
                "task": task_name,
                "status": "UNKNOWN",
                "message": "无运行记录",
                "consecutive_errors": 0
            }
        
        # 检查最近运行
        consecutive_errors = 0
        last_error = None
        last_success = None
        
        for run in runs:
            status = run.get('status', 'unknown')
            if status == 'error' or run.get('exitCode', 0) != 0:
                consecutive_errors += 1
                if not last_error:
                    last_error = run
            else:
                if not last_success:
                    last_success = run
                break
        
        # 确定状态
        if consecutive_errors >= self.CRITICAL_THRESHOLD:
            status = "CRITICAL"
        elif consecutive_errors >= self.WARNING_THRESHOLD:
            status = "WARNING"
        elif consecutive_errors > 0:
            status = "ERROR"
        else:
            status = "OK"
        
        return {
            "task": task_name,
            "status": status,
            "consecutive_errors": consecutive_errors,
            "last_run": runs[0].get('startedAt') if runs else None,
            "last_success": last_success.get('startedAt') if last_success else None,
            "last_error": last_error.get('startedAt') if last_error else None,
            "last_error_message": last_error.get('error', '') if last_error else None
        }
    
    def check_all_tasks(self) -> List[dict]:
        """检查所有任务"""
        results = []
        
        for task_name in self.MONITORED_TASKS:
            result = self.check_task_errors(task_name, {})
            results.append(result)
        
        return results
    
    def should_alert(self, task_result: dict, state: dict) -> bool:
        """判断是否应该发送告警"""
        task_name = task_result['task']
        consecutive_errors = task_result['consecutive_errors']
        
        # 获取上次的错误计数
        last_state = state.get('tasks', {}).get(task_name, {})
        last_errors = last_state.get('consecutive_errors', 0)
        
        # 新增错误且达到阈值
        if consecutive_errors > last_errors and consecutive_errors >= self.WARNING_THRESHOLD:
            return True
        
        return False
    
    def format_alert(self, task_result: dict) -> str:
        """格式化告警消息"""
        status_emoji = {
            "CRITICAL": "🔴",
            "WARNING": "🟡",
            "ERROR": "🟠"
        }
        
        emoji = status_emoji.get(task_result['status'], "❓")
        
        lines = [
            f"{emoji} **定时任务错误告警**",
            "",
            f"**任务**: {task_result['task']}",
            f"**状态**: {task_result['status']}",
            f"**连续错误**: {task_result['consecutive_errors']} 次",
            "",
        ]
        
        if task_result.get('last_error'):
            lines.append(f"**最后错误时间**: {task_result['last_error']}")
        
        if task_result.get('last_error_message'):
            lines.append(f"**错误信息**: {task_result['last_error_message'][:100]}")
        
        if task_result.get('last_success'):
            lines.append(f"**最后成功**: {task_result['last_success']}")
        
        lines.append("")
        lines.append("**建议操作**:")
        lines.append("1. 查看任务日志")
        lines.append("2. 检查脚本是否正常")
        lines.append("3. 手动运行测试")
        
        return "\n".join(lines)
    
    def send_alert(self, webhook: str, message: str) -> bool:
        """发送告警"""
        try:
            import requests
            
            payload = {
                "msg_type": "text",
                "content": {
                    "text": message
                }
            }
            
            response = requests.post(webhook, json=payload, timeout=10)
            result = response.json()
            
            return result.get('StatusCode', 1) == 0 or result.get('code', 1) == 0
        
        except Exception as e:
            print(f"告警发送失败：{e}", file=sys.stderr)
            return False
    
    def run_monitor(self, webhook: str = "", send_alert: bool = False) -> dict:
        """运行监控"""
        state = self.load_state()
        results = self.check_all_tasks()
        
        alerts_sent = 0
        
        for result in results:
            # 更新状态
            task_name = result['task']
            if task_name not in state['tasks']:
                state['tasks'][task_name] = {}
            
            # 检查是否需要告警
            if send_alert and webhook and self.should_alert(result, state):
                alert_message = self.format_alert(result)
                if self.send_alert(webhook, alert_message):
                    alerts_sent += 1
                    state['total_alerts'] = state.get('total_alerts', 0) + 1
            
            # 更新任务状态
            state['tasks'][task_name].update({
                'consecutive_errors': result['consecutive_errors'],
                'last_check': datetime.now().isoformat(),
                'status': result['status']
            })
        
        # 保存状态
        state['last_check'] = datetime.now().isoformat()
        self.save_state(state)
        
        return {
            "timestamp": datetime.now().isoformat(),
            "tasks": results,
            "alerts_sent": alerts_sent,
            "total_alerts": state.get('total_alerts', 0)
        }


def format_report(result: dict) -> str:
    """格式化监控报告"""
    lines = []
    
    lines.append("## 🔍 错误监控报告")
    lines.append("")
    lines.append(f"**检查时间**: {result['timestamp']}")
    lines.append(f"**告警发送**: {result['alerts_sent']} 条")
    lines.append(f"**累计告警**: {result['total_alerts']} 条")
    lines.append("")
    
    lines.append("**任务状态**:")
    lines.append("")
    
    status_emoji = {
        "OK": "✅",
        "ERROR": "🟠",
        "WARNING": "🟡",
        "CRITICAL": "🔴",
        "UNKNOWN": "❓"
    }
    
    for task in result['tasks']:
        emoji = status_emoji.get(task['status'], "❓")
        lines.append(f"{emoji} **{task['task']}**: {task['status']}")
        
        if task['consecutive_errors'] > 0:
            lines.append(f"   - 连续错误：{task['consecutive_errors']} 次")
        
        if task.get('last_run'):
            lines.append(f"   - 最后运行：{task['last_run']}")
    
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description='基金挑战错误监控脚本')
    parser.add_argument('--workspace', type=str, required=True,
                        help='基金挑战工作目录')
    parser.add_argument('--webhook', type=str, default='',
                        help='飞书 webhook URL')
    parser.add_argument('--send-alert', action='store_true',
                        help='发送告警 (达到阈值时)')
    parser.add_argument('--json', action='store_true',
                        help='输出 JSON 格式')
    args = parser.parse_args()
    
    workspace = Path(args.workspace).resolve()
    
    if not workspace.exists():
        print(json.dumps({"error": f"工作目录不存在：{workspace}"}))
        sys.exit(1)
    
    monitor = ErrorMonitor(workspace)
    result = monitor.run_monitor(
        webhook=args.webhook,
        send_alert=args.send_alert
    )
    
    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print(format_report(result))
    
    # 有严重错误时返回非零
    has_critical = any(t['status'] == 'CRITICAL' for t in result['tasks'])
    sys.exit(1 if has_critical else 0)


if __name__ == "__main__":
    main()
