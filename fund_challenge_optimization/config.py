#!/usr/bin/env python3
"""
基金挑战统一配置管理
集中管理所有配置项，避免硬编码和配置分散

用法:
    from config import Config
    config = Config.load()
    print(config.WORKSPACE)
    print(config.FEISHU_WEBHOOK)
"""

import json
import os
from pathlib import Path
from typing import Optional


class Config:
    """配置管理类"""
    
    # 默认配置
    DEFAULTS = {
        # 路径配置
        "WORKSPACE": "/home/admin/.openclaw/workspace/02-skill-docs/skills/fund-challenge/fund_challenge",
        "SCRIPTS_DIR": "scripts",
        "EVIDENCE_DIR": "evidence",
        "CACHE_DIR": "cache",
        "LOGS_DIR": "logs",
        
        # 飞书配置
        "FEISHU_WEBHOOK": "YOUR_FEISHU_WEBHOOK",
        "FEISHU_ENABLED": False,
        
        # 定时任务配置
        "CRON_ENABLED": True,
        "DECISION_TIME": "14:00",
        "EXEC_GATE_TIME": "14:48",
        "UNIVERSE_REFRESH_TIME": "13:35",
        "DAILY_REPORT_TIME": "23:00",
        "WEEKLY_REPORT_TIME": "23:00",  # 周五 23:00
        "WEEKLY_REPORT_DAY": 4,  # 周五 (0=周一，4=周五)
        
        # 决策配置
        "DECISION_PHASE": "PLAN_ONLY",  # PLAN_ONLY or EXECUTE_READY
        "MAX_POSITIONS": 5,
        "MIN_CASH_RESERVE": 0.0,
        
        # 评分阈值
        "MIN_SCORE_TO_BUY": 80,
        "MIN_SCORE_TO_HOLD": 60,
        "TAKE_PROFIT_THRESHOLD": 0.07,  # +7%
        "STOP_LOSS_THRESHOLD": -0.05,   # -5%
        
        # 超时配置 (秒)
        "PREFLIGHT_TIMEOUT": 60,
        "EVIDENCE_BUILD_TIMEOUT": 120,
        "WEBHOOK_TIMEOUT": 10,
        
        # 日志配置
        "LOG_LEVEL": "INFO",
        "LOG_FORMAT": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    }
    
    def __init__(self, config_dict: dict = None):
        """初始化配置"""
        self._config = config_dict or {}
        
        # 应用默认值
        for key, value in self.DEFAULTS.items():
            if key not in self._config:
                self._config[key] = value
        
        # 环境变量覆盖
        self._load_from_env()
    
    def _load_from_env(self):
        """从环境变量加载配置"""
        env_mapping = {
            "FC_WORKSPACE": "WORKSPACE",
            "FC_FEISHU_WEBHOOK": "FEISHU_WEBHOOK",
            "FC_FEISHU_ENABLED": "FEISHU_ENABLED",
            "FC_LOG_LEVEL": "LOG_LEVEL",
        }
        
        for env_key, config_key in env_mapping.items():
            if env_key in os.environ:
                value = os.environ[env_key]
                # 类型转换
                if config_key in ["FEISHU_ENABLED", "CRON_ENABLED"]:
                    value = value.lower() in ["true", "1", "yes"]
                elif config_key in ["MAX_POSITIONS"]:
                    value = int(value)
                elif config_key in ["MIN_CASH_RESERVE", "TAKE_PROFIT_THRESHOLD", "STOP_LOSS_THRESHOLD"]:
                    value = float(value)
                
                self._config[config_key] = value
    
    @classmethod
    def load(cls, config_file: Optional[str] = None) -> "Config":
        """从文件加载配置"""
        config_dict = {}
        
        # 尝试从多个位置加载配置文件
        possible_paths = [
            config_file,  # 显式指定
            "config.json",  # 当前目录
            "fund_challenge/config.json",  # 子目录
            os.path.expanduser("~/.fund_challenge/config.json"),  # 用户目录
        ]
        
        for path in possible_paths:
            if path and Path(path).exists():
                try:
                    with open(path, 'r', encoding='utf-8') as f:
                        config_dict = json.load(f)
                    break
                except Exception as e:
                    print(f"警告：配置文件加载失败 {path}: {e}")
        
        return cls(config_dict)
    
    def save(self, config_file: str):
        """保存配置到文件"""
        path = Path(config_file)
        path.parent.mkdir(parents=True, exist_ok=True)
        
        # 只保存非默认值
        custom_config = {
            k: v for k, v in self._config.items()
            if self.DEFAULTS.get(k) != v
        }
        
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(custom_config, f, ensure_ascii=False, indent=2)
    
    def __getattr__(self, name: str):
        """支持 config.WORKSPACE 访问"""
        if name in self._config:
            return self._config[name]
        raise AttributeError(f"配置项不存在：{name}")
    
    def __setattr__(self, name: str, value):
        """支持 config.WORKSPACE = '...' 设置"""
        if name == "_config":
            super().__setattr__(name, value)
        else:
            self._config[name] = value
    
    def get(self, key: str, default=None):
        """获取配置项"""
        return self._config.get(key, default)
    
    def set(self, key: str, value):
        """设置配置项"""
        self._config[key] = value
    
    def to_dict(self) -> dict:
        """转换为字典"""
        return self._config.copy()
    
    def validate(self) -> list:
        """验证配置，返回错误列表"""
        errors = []
        
        # 检查必要路径
        workspace = Path(self.WORKSPACE)
        if not workspace.exists():
            errors.append(f"工作目录不存在：{workspace}")
        
        # 检查脚本目录
        scripts_dir = workspace / self.SCRIPTS_DIR
        if not scripts_dir.exists():
            errors.append(f"脚本目录不存在：{scripts_dir}")
        
        # 检查 Webhook 配置
        if self.FEISHU_ENABLED and self.FEISHU_WEBHOOK == "YOUR_FEISHU_WEBHOOK":
            errors.append("飞书 Webhook 未配置实际值")
        
        # 检查评分阈值
        if self.MIN_SCORE_TO_BUY < self.MIN_SCORE_TO_HOLD:
            errors.append("买入评分阈值应高于持仓阈值")
        
        # 检查超时配置
        if self.PREFLIGHT_TIMEOUT < 10:
            errors.append("预检超时时间过短 (<10s)")
        
        return errors
    
    def __repr__(self):
        return f"Config({self._config})"


# 全局配置实例
_config: Optional[Config] = None


def get_config() -> Config:
    """获取全局配置实例"""
    global _config
    if _config is None:
        _config = Config.load()
    return _config


def init_config(config_file: Optional[str] = None):
    """初始化全局配置"""
    global _config
    _config = Config.load(config_file)
    return _config


# 命令行工具
if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='配置管理工具')
    parser.add_argument('--show', action='store_true', help='显示当前配置')
    parser.add_argument('--validate', action='store_true', help='验证配置')
    parser.add_argument('--init', action='store_true', help='初始化配置文件')
    parser.add_argument('--config-file', type=str, default='config.json', help='配置文件路径')
    args = parser.parse_args()
    
    if args.init:
        config = Config()
        config.save(args.config_file)
        print(f"✅ 配置文件已创建：{args.config_file}")
        print("请编辑此文件配置实际值")
    
    elif args.show:
        config = Config.load(args.config_file)
        print("当前配置:")
        for key, value in sorted(config.to_dict().items()):
            print(f"  {key}: {value}")
    
    elif args.validate:
        config = Config.load(args.config_file)
        errors = config.validate()
        if errors:
            print("❌ 配置验证失败:")
            for error in errors:
                print(f"  - {error}")
            exit(1)
        else:
            print("✅ 配置验证通过")
    
    else:
        parser.print_help()
