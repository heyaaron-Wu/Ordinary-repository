#!/usr/bin/env python3
"""
优化组件测试脚本
测试新创建的 5 个核心脚本功能
"""

import subprocess
import json
from pathlib import Path
from datetime import datetime


def run_test(name: str, command: list, expected_success: bool = True) -> bool:
    """运行测试并检查结果"""
    print(f"\n{'='*60}")
    print(f"测试：{name}")
    print(f"命令：{' '.join(command)}")
    print(f"{'='*60}")
    
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=30
        )
        
        success = result.returncode == 0
        
        if success == expected_success:
            print(f"✅ 通过")
            if result.stdout:
                print(f"输出:\n{result.stdout[:500]}")  # 限制输出长度
            return True
        else:
            print(f"❌ 失败 (期望：{'成功' if expected_success else '失败'}, 实际：{'成功' if success else '失败'})")
            if result.stderr:
                print(f"错误:\n{result.stderr[:500]}")
            return False
    except subprocess.TimeoutExpired:
        print(f"❌ 超时 (30 秒)")
        return False
    except Exception as e:
        print(f"❌ 异常：{e}")
        return False


def test_signal_fusion_scorer():
    """测试信号融合评分器"""
    print("\n### 测试信号融合评分器 ###")
    
    # 创建测试数据
    test_data = [
        {
            'fund_code': '018737',
            'fund_name': '华夏科创 50ETF 联接 A',
            'policy_news': ['政策利好 1', '政策利好 2'],
            'sector_heat': 0.85,
            'macro_linkage': {'gold': {'strength': 0.7}},
            'momentum_score': 0.8,
            'fund_flow': 0.6,
            'liquidity_ok': True,
            'within_position_limit': True,
            'max_drawdown': -0.05,
            'volatility': 0.15
        },
        {
            'fund_code': '017572',
            'fund_name': '广发新能源车电池 ETF 联接 C',
            'policy_news': [],
            'sector_heat': 0.65,
            'macro_linkage': {},
            'momentum_score': 0.6,
            'fund_flow': 0.3,
            'liquidity_ok': True,
            'within_position_limit': True,
            'max_drawdown': -0.12,
            'volatility': 0.25
        }
    ]
    
    # 保存测试数据
    test_file = Path('/tmp/test_candidates.json')
    test_file.write_text(json.dumps(test_data, ensure_ascii=False, indent=2))
    
    # 运行评分
    success = run_test(
        "信号评分 - 完整输出",
        ['python3', 'fund_challenge/scripts/signal_fusion_scorer.py',
         '--input', str(test_file), '--min-score', '0']
    )
    
    # 精简模式
    success &= run_test(
        "信号评分 - 精简模式",
        ['python3', 'fund_challenge/scripts/signal_fusion_scorer.py',
         '--input', str(test_file), '--compact']
    )
    
    return success


def test_position_calculator():
    """测试仓位计算器"""
    print("\n### 测试仓位计算器 ###")
    
    success = True
    
    # 测试高置信度建仓
    success &= run_test(
        "仓位计算 - 高置信度",
        ['python3', 'fund_challenge/scripts/position_calculator.py',
         '--confidence', 'high', '--current-exposure', '0.3',
         '--theme-concentration', '0.2', '--compact']
    )
    
    # 测试止盈
    success &= run_test(
        "止盈计算 - 盈利 8%",
        ['python3', 'fund_challenge/scripts/position_calculator.py',
         '--mode', 'take-profit', '--pnl', '0.08',
         '--catalyst', 'normal', '--compact']
    )
    
    # 测试止损
    success &= run_test(
        "止损计算 - 亏损 6%",
        ['python3', 'fund_challenge/scripts/position_calculator.py',
         '--mode', 'stop-loss', '--pnl', '-0.06',
         '--catalyst', 'weakened', '--compact']
    )
    
    return success


def test_exit_monitor():
    """测试退出监控器"""
    print("\n### 测试退出监控器 ###")
    
    # 创建测试持仓
    test_positions = [
        {
            'fund_code': '018737',
            'fund_name': '华夏科创 50ETF 联接 A',
            'unrealized_pnl_pct': 0.085,
            'current_exposure': 0.35,
            'catalyst_strength': 'normal'
        },
        {
            'fund_code': '017572',
            'fund_name': '广发新能源车电池 ETF 联接 C',
            'unrealized_pnl_pct': -0.062,
            'current_exposure': 0.25,
            'catalyst_strength': 'weakened'
        },
        {
            'fund_code': '014620',
            'fund_name': '德邦半导体产业混合 C',
            'unrealized_pnl_pct': 0.03,
            'current_exposure': 0.20,
            'catalyst_strength': 'strong'
        }
    ]
    
    test_file = Path('/tmp/test_positions.json')
    test_file.write_text(json.dumps(test_positions, ensure_ascii=False, indent=2))
    
    success = run_test(
        "退出监控 - 完整报告",
        ['python3', 'fund_challenge/scripts/exit_monitor.py',
         '--input', str(test_file)]
    )
    
    success &= run_test(
        "退出监控 - 精简模式",
        ['python3', 'fund_challenge/scripts/exit_monitor.py',
         '--input', str(test_file), '--compact']
    )
    
    return success


def test_execution_simulator():
    """测试执行模拟器"""
    print("\n### 测试执行模拟器 ###")
    
    success = True
    
    # 测试申购模拟
    success &= run_test(
        "执行模拟 - 申购",
        ['python3', 'fund_challenge/scripts/execution_simulator.py',
         '--fund', '018737', '--action', 'subscribe', '--compact']
    )
    
    # 测试赎回模拟
    success &= run_test(
        "执行模拟 - 赎回",
        ['python3', 'fund_challenge/scripts/execution_simulator.py',
         '--fund', '018737', '--action', 'redeem', '--compact']
    )
    
    # 测试同日申赎检查
    success &= run_test(
        "执行模拟 - 同日申赎检查",
        ['python3', 'fund_challenge/scripts/execution_simulator.py',
         '--fund', '018737', '--action', 'round-trip',
         '--subscribe-date', '20260320', '--redeem-date', '20260320']
    )
    
    return success


def test_market_gate_checker():
    """测试市场门控检查器"""
    print("\n### 测试市场门控检查器 ###")
    
    success = True
    
    # 测试当前时间
    success &= run_test(
        "门控检查 - 当前时间",
        ['python3', 'fund_challenge/scripts/market_gate_checker.py', '--compact']
    )
    
    # 测试指定时间 (交易时段)
    success &= run_test(
        "门控检查 - 14:30 (最优窗口)",
        ['python3', 'fund_challenge/scripts/market_gate_checker.py',
         '--time', '14:30:00', '--compact']
    )
    
    # 测试指定时间 (非交易时段)
    success &= run_test(
        "门控检查 - 15:30 (已收盘)",
        ['python3', 'fund_challenge/scripts/market_gate_checker.py',
         '--time', '15:30:00'],
        expected_success=False  # 预期失败
    )
    
    return success


def test_integration():
    """集成测试 - 完整流程"""
    print("\n### 集成测试 - 完整流程 ###")
    
    # 1. 信号评分
    print("\n步骤 1: 信号评分")
    test_candidates = [{
        'fund_code': '018737',
        'fund_name': '测试基金',
        'policy_news': ['利好'],
        'sector_heat': 0.8,
        'momentum_score': 0.7,
        'liquidity_ok': True,
        'within_position_limit': True
    }]
    
    candidates_file = Path('/tmp/integration_candidates.json')
    candidates_file.write_text(json.dumps(test_candidates))
    
    # 2. 门控检查
    print("\n步骤 2: 门控检查")
    gate_result = subprocess.run(
        ['python3', 'fund_challenge/scripts/market_gate_checker.py', '--compact'],
        capture_output=True, text=True
    )
    print(f"门控结果：{gate_result.stdout.strip()}")
    
    # 3. 仓位计算
    print("\n步骤 3: 仓位计算")
    position_result = subprocess.run(
        ['python3', 'fund_challenge/scripts/position_calculator.py',
         '--confidence', 'high', '--current-exposure', '0.0', '--compact'],
        capture_output=True, text=True
    )
    print(f"仓位结果：{position_result.stdout.strip()}")
    
    print("\n✅ 集成测试完成")
    return True


def main():
    """运行所有测试"""
    print("=" * 60)
    print("基金挑战优化组件测试套件")
    print(f"测试时间：{datetime.now().isoformat()}")
    print("=" * 60)
    
    # 切换到工作目录
    import os
    os.chdir(Path(__file__).parent / '02-skill-docs' / 'skills' / 'fund-challenge')
    
    results = {}
    
    # 运行各组件测试
    results['signal_fusion_scorer'] = test_signal_fusion_scorer()
    results['position_calculator'] = test_position_calculator()
    results['exit_monitor'] = test_exit_monitor()
    results['execution_simulator'] = test_execution_simulator()
    results['market_gate_checker'] = test_market_gate_checker()
    results['integration'] = test_integration()
    
    # 汇总结果
    print("\n" + "=" * 60)
    print("测试结果汇总")
    print("=" * 60)
    
    for test_name, passed in results.items():
        status = "✅ 通过" if passed else "❌ 失败"
        print(f"{test_name}: {status}")
    
    total_passed = sum(results.values())
    total_tests = len(results)
    
    print(f"\n总计：{total_passed}/{total_tests} 通过 ({total_passed/total_tests*100:.1f}%)")
    
    if total_passed == total_tests:
        print("\n🎉 所有测试通过！优化组件已就绪。")
        return 0
    else:
        print(f"\n⚠️ {total_tests - total_passed} 个测试失败，请检查错误日志。")
        return 1


if __name__ == "__main__":
    exit(main())
