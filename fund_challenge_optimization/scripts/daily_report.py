#!/usr/bin/env python3
"""
基金挑战日报生成脚本
每日 23:00 自动发送持仓收益日报

用法:
    python3 daily_report.py --workspace /path/to/fund_challenge --feishu --webhook YOUR_WEBHOOK

功能:
1. 读取持仓数据
2. 计算当日收益
3. 生成日报消息
4. 飞书推送
"""

import argparse
import json
import sys
from pathlib import Path
from datetime import datetime
from typing import List, Dict


def load_state(state_file: Path) -> dict:
    """加载持仓状态"""
    if not state_file.exists():
        return {}
    
    with open(state_file, 'r', encoding='utf-8') as f:
        return json.load(f)


def load_ledger(ledger_file: Path) -> List[dict]:
    """加载交易记录"""
    if not ledger_file.exists():
        return []
    
    transactions = []
    with open(ledger_file, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                transactions.append(json.loads(line))
            except:
                continue
    
    return transactions


def calculate_daily_pnl(positions: List[dict]) -> Dict[str, float]:
    """计算当日收益"""
    daily_pnl = {}
    
    for pos in positions:
        code = pos.get('code', 'UNKNOWN')
        name = pos.get('name', 'Unknown')
        
        # 获取当日盈亏
        pnl = pos.get('daily_pnl', 0)
        pnl_rate = pos.get('daily_pnl_rate', 0)
        
        daily_pnl[code] = {
            'name': name,
            'pnl': pnl,
            'pnl_rate': pnl_rate,
            'market_value': pos.get('market_value', 0),
            'unrealized_pnl': pos.get('unrealized_pnl', 0)
        }
    
    return daily_pnl


def format_daily_report(state: dict, daily_pnl: Dict[str, dict], transactions: List[dict]) -> str:
    """格式化日报消息"""
    lines = []
    
    # 标题
    today = datetime.now().strftime('%Y-%m-%d')
    weekday = datetime.now().strftime('%A')
    weekday_zh = {'Monday': '周一', 'Tuesday': '周二', 'Wednesday': '周三', 
                  'Thursday': '周四', 'Friday': '周五', 'Saturday': '周六', 'Sunday': '周日'}
    
    lines.append(f"**📊 基金日报 {today}** ({weekday_zh.get(weekday, weekday)})")
    lines.append("")
    lines.append(f"**发送时间**: {datetime.now().strftime('%H:%M')}")
    lines.append("")
    lines.append("---")
    lines.append("")
    
    # 今日收益
    lines.append("### 💰 今日收益")
    lines.append("")
    
    if daily_pnl:
        total_daily_pnl = sum(info['pnl'] for info in daily_pnl.values())
        
        lines.append("| 基金 | 盈亏金额 | 状态 |")
        lines.append("|------|----------|------|")
        
        for code, info in sorted(daily_pnl.items(), key=lambda x: x[1]['pnl'], reverse=True):
            emoji = "✅" if info['pnl'] > 0 else "❌" if info['pnl'] < 0 else "➖"
            pnl_sign = "+" if info['pnl'] > 0 else ""
            lines.append(f"| {info['name'][:15]}.. | {pnl_sign}{info['pnl']:.2f} 元 | {emoji} |")
        
        lines.append("")
        total_emoji = "🟢" if total_daily_pnl > 0 else "🔴" if total_daily_pnl < 0 else "➖"
        total_sign = "+" if total_daily_pnl > 0 else ""
        lines.append(f"**今日合计**: {total_emoji} **{total_sign}{total_daily_pnl:.2f} 元**")
    else:
        lines.append("暂无持仓数据")
    
    lines.append("")
    lines.append("---")
    lines.append("")
    
    # 本周表现
    lines.append("### 📈 本周表现")
    lines.append("")
    
    # 统计本周交易
    week_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    week_transactions = [t for t in transactions 
                        if datetime.fromisoformat(t.get('timestamp', '2000-01-01')) >= week_start]
    
    buy_count = sum(1 for t in week_transactions if t.get('action') == 'buy')
    sell_count = sum(1 for t in week_transactions if t.get('action') == 'sell')
    
    lines.append(f"**交易笔数**: 买入 {buy_count} 笔 / 卖出 {sell_count} 笔")
    
    if state:
        total_pnl = state.get('total_unrealized_pnl', 0)
        portfolio_value = state.get('portfolio_value', 0)
        lines.append(f"**累计收益**: {total_pnl:+.2f} 元 ({total_pnl/portfolio_value*100:.2f}%)")
    
    lines.append("")
    lines.append("---")
    lines.append("")
    
    # 当前持仓
    lines.append("### 📦 当前持仓")
    lines.append("")
    
    if state and 'positions' in state:
        lines.append("| 基金 | 市值 | 累计盈亏 |")
        lines.append("|------|------|----------|")
        
        for pos in state['positions']:
            name = pos.get('name', 'Unknown')[:15]
            market_value = pos.get('market_value', 0)
            unrealized_pnl = pos.get('unrealized_pnl', 0)
            pnl_sign = "+" if unrealized_pnl > 0 else ""
            lines.append(f"| {name}.. | {market_value:.2f} 元 | {pnl_sign}{unrealized_pnl:.2f} 元 |")
        
        lines.append("")
        lines.append(f"**总市值**: {state.get('portfolio_value', 0):.2f} 元")
        lines.append(f"**可用现金**: {state.get('cash', 0):.2f} 元")
    else:
        lines.append("暂无持仓")
    
    lines.append("")
    lines.append("---")
    lines.append("")
    
    # 备注
    lines.append("### 📝 备注")
    lines.append("")
    lines.append("1. 日报发送时间：每日 23:00")
    lines.append("2. 周报发送时间：**每周五 23:00**")
    lines.append("3. 数据来源：支付宝/天天基金")
    lines.append("")
    
    # 下次发送
    next_day = datetime.now().replace(hour=23, minute=0, second=0, microsecond=0)
    if datetime.now().hour >= 23:
        from datetime import timedelta
        next_day += timedelta(days=1)
    
    lines.append(f"*下次日报：{next_day.strftime('%Y-%m-%d %H:%M')}*")
    
    return "\n".join(lines)


def send_feishu_report(webhook: str, content: str) -> bool:
    """发送飞书日报"""
    try:
        import requests
        
        payload = {
            "msg_type": "interactive",
            "card": {
                "header": {
                    "title": {
                        "tag": "plain_text",
                        "content": "📊 基金日报"
                    },
                    "template": "blue"
                },
                "elements": [
                    {
                        "tag": "markdown",
                        "content": content
                    }
                ]
            }
        }
        
        response = requests.post(webhook, json=payload, timeout=10)
        result = response.json()
        
        return result.get('StatusCode', 1) == 0 or result.get('code', 1) == 0
    
    except Exception as e:
        print(f"发送失败：{e}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(description='基金日报生成脚本')
    parser.add_argument('--workspace', type=str, required=True,
                        help='基金挑战工作目录')
    parser.add_argument('--feishu', action='store_true',
                        help='发送飞书推送')
    parser.add_argument('--webhook', type=str, default='',
                        help='飞书 webhook URL')
    parser.add_argument('--json', action='store_true',
                        help='输出 JSON 格式')
    args = parser.parse_args()
    
    workspace = Path(args.workspace).resolve()
    
    # 数据文件路径 (支持多种可能的位置)
    possible_state_paths = [
        Path("/home/admin/.openclaw/workspace/04-private-configs/fund_challenge/state.json"),
        workspace.parent.parent / "04-private-configs/fund_challenge/state.json",
        workspace / "state.json",
    ]
    
    possible_ledger_paths = [
        Path("/home/admin/.openclaw/workspace/04-private-configs/fund_challenge/ledger.jsonl"),
        workspace.parent.parent / "04-private-configs/fund_challenge/ledger.jsonl",
        workspace / "ledger.jsonl",
    ]
    
    # 查找存在的文件
    state_file = None
    ledger_file = None
    
    for path in possible_state_paths:
        if path.exists():
            state_file = path
            break
    
    for path in possible_ledger_paths:
        if path.exists():
            ledger_file = path
            break
    
    if not state_file:
        print("警告：未找到 state.json 文件", file=sys.stderr)
    if not ledger_file:
        print("警告：未找到 ledger.jsonl 文件", file=sys.stderr)
    
    # 加载数据
    state = load_state(state_file) if state_file else {}
    transactions = load_ledger(ledger_file) if ledger_file else []
    
    # 计算当日收益
    positions = state.get('positions', [])
    daily_pnl = calculate_daily_pnl(positions)
    
    # 生成报告
    report = format_daily_report(state, daily_pnl, transactions)
    
    # 输出
    if args.json:
        print(json.dumps({"report": report}, ensure_ascii=False))
    else:
        print(report)
    
    # 发送飞书
    if args.feishu and args.webhook:
        print("\n正在发送飞书日报...")
        success = send_feishu_report(args.webhook, report)
        if success:
            print("✅ 日报已发送")
        else:
            print("❌ 发送失败")
    
    # 返回当日总收益
    total_daily_pnl = sum(info['pnl'] for info in daily_pnl.values())
    return total_daily_pnl


if __name__ == "__main__":
    pnl = main()
    sys.exit(0)
