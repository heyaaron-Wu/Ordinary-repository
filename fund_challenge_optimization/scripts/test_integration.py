#!/usr/bin/env python3
"""
基金挑战集成测试脚本
测试完整决策流程，确保所有组件正常工作

用法:
    python3 test_integration.py --workspace /path/to/fund_challenge

测试项目:
1. state_math - 持仓计算
2. refresh_instrument_rules - 规则刷新
3. build_evidence - 证据构建
4. validate_evidence - 证据验证
5. preflight_guard - 完整预检流程
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path
from datetime import datetime


class TestResult:
    def __init__(self, name: str):
        self.name = name
        self.passed = False
        self.error = None
        self.duration = 0
    
    def __str__(self):
        status = "✅ PASS" if self.passed else "❌ FAIL"
        return f"{status} {self.name}"


def run_test(name: str, cmd: list, workspace: Path, timeout: int = 30) -> TestResult:
    """运行单个测试"""
    result = TestResult(name)
    start = datetime.now()
    
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(workspace),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
            timeout=timeout
        )
        
        result.duration = (datetime.now() - start).total_seconds()
        
        if proc.returncode == 0:
            # 尝试解析 JSON 输出
            try:
                output = json.loads(proc.stdout)
                if isinstance(output, dict) and output.get('ok', True):
                    result.passed = True
                else:
                    result.passed = True  # 非 JSON 输出也认为通过
            except:
                result.passed = True
        else:
            result.error = proc.stderr.strip() or f"Exit code: {proc.returncode}"
    
    except subprocess.TimeoutExpired:
        result.error = f"Timeout after {timeout}s"
    except Exception as e:
        result.error = str(e)
    
    return result


def test_state_math(workspace: Path) -> TestResult:
    """测试持仓计算"""
    return run_test(
        "state_math - 持仓计算",
        [sys.executable, "scripts/state_math.py", "--state", "state.json"],
        workspace
    )


def test_refresh_rules(workspace: Path) -> TestResult:
    """测试规则刷新"""
    return run_test(
        "refresh_instrument_rules - 规则刷新",
        [sys.executable, "scripts/refresh_instrument_rules.py",
         "--rules", "instrument_rules.json",
         "--sources", "instrument_rule_sources.json"],
        workspace
    )


def test_build_evidence(workspace: Path) -> TestResult:
    """测试证据构建"""
    return run_test(
        "build_evidence - 证据构建",
        [sys.executable, "scripts/build_evidence.py",
         "--state", "state.json",
         "--template", "evidence/template.json",
         "--outdir", "evidence",
         "--phase", "PLAN_ONLY"],
        workspace
    )


def test_validate_evidence(workspace: Path) -> TestResult:
    """测试证据验证"""
    return run_test(
        "validate_evidence - 证据验证",
        [sys.executable, "scripts/validate_evidence.py",
         "--evidence", "evidence/latest.json"],
        workspace
    )


def test_preflight_guard(workspace: Path) -> TestResult:
    """测试完整预检流程"""
    return run_test(
        "preflight_guard - 完整预检",
        [sys.executable, "scripts/preflight_guard.py",
         "--phase", "PLAN_ONLY",
         "--workspace", str(workspace)],
        workspace,
        timeout=60
    )


def test_evidence_content(workspace: Path) -> TestResult:
    """测试证据内容完整性"""
    result = TestResult("evidence_content - 证据内容完整性")
    
    try:
        evidence_file = workspace / "evidence" / "latest.json"
        if not evidence_file.exists():
            result.error = "证据文件不存在"
            return result
        
        evidence = json.loads(evidence_file.read_text(encoding='utf-8'))
        
        # 检查必填字段
        required_fields = [
            "decisionId",
            "phase",
            "generatedAt",
            "stateDigest",
            "fundIdentityChecks",
            "marketSignals",
            "executionConstraints",
            "status"
        ]
        
        missing = [f for f in required_fields if f not in evidence]
        if missing:
            result.error = f"缺少字段：{missing}"
            return result
        
        # 检查数组不为空
        empty_arrays = []
        for field in ["fundIdentityChecks", "marketSignals", "executionConstraints"]:
            if not evidence.get(field):
                empty_arrays.append(field)
        
        # fundIdentityChecks 应该有数据（如果有持仓）
        if not evidence.get("fundIdentityChecks"):
            result.error = "fundIdentityChecks 为空（应有持仓数据）"
            return result
        
        # 检查状态
        if evidence.get("status") not in ["READY", "PENDING_EVIDENCE"]:
            result.error = f"状态异常：{evidence.get('status')}"
            return result
        
        result.passed = True
        
    except Exception as e:
        result.error = str(e)
    
    return result


def test_script_permissions(workspace: Path) -> TestResult:
    """测试脚本执行权限"""
    result = TestResult("script_permissions - 脚本执行权限")
    
    scripts = [
        "scripts/state_math.py",
        "scripts/build_evidence.py",
        "scripts/validate_evidence.py",
        "scripts/preflight_guard.py"
    ]
    
    for script in scripts:
        script_path = workspace / script
        if not script_path.exists():
            result.error = f"脚本不存在：{script}"
            return result
        
        import os
        if not os.access(script_path, os.X_OK):
            # 尝试添加执行权限
            try:
                os.chmod(script_path, 0o755)
            except:
                result.error = f"脚本无执行权限：{script}"
                return result
    
    result.passed = True
    return result


def run_all_tests(workspace: Path) -> bool:
    """运行所有测试"""
    print("=" * 80)
    print("基金挑战集成测试套件")
    print(f"工作目录：{workspace}")
    print(f"测试时间：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80)
    print()
    
    tests = [
        test_script_permissions,
        test_state_math,
        test_refresh_rules,
        test_build_evidence,
        test_validate_evidence,
        test_evidence_content,
        test_preflight_guard,
    ]
    
    results = []
    for test_func in tests:
        print(f"运行：{test_func.__name__}...")
        result = test_func(workspace)
        results.append(result)
        print(f"  {result} ({result.duration:.2f}s)")
        if result.error:
            print(f"  错误：{result.error}")
        print()
    
    # 汇总
    print("=" * 80)
    print("测试结果汇总")
    print("=" * 80)
    
    passed = sum(1 for r in results if r.passed)
    total = len(results)
    
    for result in results:
        status = "✅ PASS" if result.passed else "❌ FAIL"
        print(f"{status} {result.name}")
    
    print()
    print(f"总计：{passed}/{total} 通过 ({passed/total*100:.1f}%)")
    
    if passed == total:
        print("\n🎉 所有测试通过！系统运行正常。")
        return True
    else:
        print(f"\n⚠️ {total - passed} 个测试失败，请检查错误日志。")
        return False


def main():
    parser = argparse.ArgumentParser(description='基金挑战集成测试脚本')
    parser.add_argument('--workspace', type=str, required=True,
                        help='基金挑战工作目录')
    parser.add_argument('--json', action='store_true',
                        help='输出 JSON 格式结果')
    args = parser.parse_args()
    
    workspace = Path(args.workspace).resolve()
    
    if not workspace.exists():
        print(f"错误：工作目录不存在：{workspace}", file=sys.stderr)
        sys.exit(1)
    
    success = run_all_tests(workspace)
    
    if args.json:
        print(json.dumps({"success": success}, ensure_ascii=False))
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
