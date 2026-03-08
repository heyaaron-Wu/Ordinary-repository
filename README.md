# 📈 Fund Challenge System (基金挑战自动化决策系统)

> **一个基于大语言模型（LLM）、由证据驱动且具备强风控能力的场外基金自动化交易与决策系统。**

## 📑 项目简介

本系统专为场外基金（Mutual Funds）交易挑战设计，采用高度解耦的微服务/多技能架构。系统通过 12 个核心技能（Skills）协同工作，解决自动交易决策中常见的数据过时、大模型幻觉、风控失位以及非标执行规则等痛点，确保每一笔交易决策都**合规、有据可查且风险可控**。

---
## 🏗️ 核心架构与技能模块 (Core Modules)
系统按逻辑划分为五大核心层级，各司其职

# 1. 核心调度层 (Orchestration)
负责整个系统的节奏控制与工作流串联。

* **`fund-challenge-orchestrator` (主协调器)**
  * 作用： 系统的“大脑”与中枢。负责协调所有子技能的执行顺序，确保工作流按预定步骤（从健康检查到最终执行）有条不紊地进行。

* **`fund-challenge-daily-trader-core` (每日交易核心)**
  * 作用： 端到端的工作流引擎。深度整合所有底层子技能，实现从市场信号分析到最终执行决策的闭环自动化流程。

# 2. 盘前与数据防护层 (Pre-flight & Data Security)
在任何计算开始前，确保环境合规与数据纯洁。

* **`fund-challenge-market-calendar-gate` (市场日历门控)**
  * 作用： 时序风控。验证当前是否为法定交易日，并精准核对交易截止时间（如场外基金常见的 15:00 截单），确保所有操作在合规时间窗内。

* **`fund-challenge-data-guard` (数据防护)**
  * 作用： 系统的安全屏障。对获取到的外部数据进行严格的完整性校验，从物理层面防止“幻觉”或脏数据污染后续决策。

* **`fund-challenge-identity-freshness-guard` (身份与新鲜度验证)**
  * 作用： 标的级校验。严格核验基金代码与名称的一致性，并检查行情/基本面数据的新鲜度，拒绝使用过期信息。

# 3. 信号与风控引擎层 (Signal & Risk Engine)
负责“买什么”、“买多少”以及“风险有多大”。

* **`fund-challenge-signal-fusion-engine` (信号融合引擎)**
  * 作用： 多模态信息处理。融合新闻资讯、宏观政策、板块热度等多源信号，通过算法生成投资机会排序（Alpha），锁定最优买入标的。

* **`fund-challenge-position-risk-engine` (仓位风险引擎)**
  * 作用： 投资组合守护者。实时计算当前持仓的风险敞口、行业集中度，并动态测算止盈/止损点位，确保总体风险严格控制在安全阈值内。

# 4. 规则解析与模拟执行层 (Rules & Execution Sim)
针对场外基金的复杂性进行预演和落地。

* **`fund-challenge-instrument-rules` (工具规则)**
  * 作用： 字典与规则库。深度解析单只基金的具体交易规则（如限购额度、赎回费率阶梯、T+n 确认机制），避免触发平台违规。

* **`fund-challenge-offexchange-exec-sim` (场外基金执行模拟)**
  * 作用： 预演沙盘。基于 T+n 确认与结算机制模拟未来资金流，评估申购/赎回的可行性，防止因资金冻结或规则限制导致的执行失败。

* **`fund-challenge-execution-engine` (执行引擎)**
  * 作用： 动作发射器。管理执行状态并负责实际的执行逻辑（判断何时触发下单提醒/指令），完成与交易终端的交互。

# 5. 审计与账本后处理层 (Audit & Post-mortem)
确保所有的决策都有迹可循，状态持久化。

* **`fund-challenge-evidence-audit` (证据审计)**
  * 作用： 决策质检员。捕获并强校验决策过程中的推导依据，严格执行“无充分证据不发车”的原则，是执行前的最后一道风控。

* **`fund-challenge-ledger-postmortem` (账本后审)**
  * 作用： 历史记录官。记录交易确认后的资金与持仓状态变化，完成账本审计与持久化，为系统后续的复盘与自学习提供绝对可靠的数据源。

    
## 🔄 系统运行生命周期 (Lifecycle Workflow)
1.启动与准入： `orchestrator` 唤醒系统，`market-calendar-gate` 判断是否开盘，`data-guard` 与 `identity-freshness-guard` 准备并清洗当日数据。

2.信号与决策： `signal-fusion-engine` 捕捉机会，交由 `position-risk-engine` 评估仓位可行性。

3.合规预演： `instrument-rules` 结合 `offexchange-exec-sim` 模拟交易，确保资金和规则允许。

4.证据门控： `evidence-audit` 检查整个逻辑链条，无误后放行。

5.执行与回写： `execution-engine` 触发交易动作，最后由 `ledger-postmortem` 更新本地账本。


## 🏗️ 系统架构流转图 (Architecture & Workflow)

```mermaid
graph TD
    %% 定义样式
    classDef orchestrator fill:#f9f2f4,stroke:#d9534f,stroke-width:2px;
    classDef preflight fill:#e8f4f8,stroke:#5bc0de,stroke-width:2px;
    classDef engine fill:#fcf8e3,stroke:#f0ad4e,stroke-width:2px;
    classDef execution fill:#dff0d8,stroke:#5cb85c,stroke-width:2px;
    classDef postprocess fill:#f4f4f4,stroke:#777,stroke-width:2px;

    %% 核心调度层
    subgraph Orchestration [1. 核心调度层]
        O1[fund-challenge-orchestrator <br/> 主协调器]:::orchestrator
        O2[fund-challenge-daily-trader-core <br/> 每日交易核心]:::orchestrator
    end

    %% 盘前与数据防护层
    subgraph Preflight_&_Data_Security [2. 盘前与数据防护层]
        P1[fund-challenge-market-calendar-gate <br/> 市场日历门控]:::preflight
        P2[fund-challenge-data-guard <br/> 数据防护]:::preflight
        P3[fund-challenge-identity-freshness-guard <br/> 身份与新鲜度验证]:::preflight
    end

    %% 信号与风控引擎层
    subgraph Signal_&_Risk_Engine [3. 信号与风控引擎层]
        S1[fund-challenge-signal-fusion-engine <br/> 信号融合引擎]:::engine
        S2[fund-challenge-position-risk-engine <br/> 仓位风险引擎]:::engine
    end

    %% 规则解析与模拟执行层
    subgraph Rules_&_Execution_Sim [4. 规则解析与模拟执行层]
        R1[fund-challenge-instrument-rules <br/> 工具规则]:::execution
        R2[fund-challenge-offexchange-exec-sim <br/> 场外基金执行模拟]:::execution
        R3[fund-challenge-execution-engine <br/> 执行引擎]:::execution
    end

    %% 审计与账本后处理层
    subgraph Audit_&_Post-mortem [5. 审计与账本后处理层]
        A1[fund-challenge-evidence-audit <br/> 证据审计]:::postprocess
        A2[fund-challenge-ledger-postmortem <br/> 账本后审]:::postprocess
    end

    %% 流程连线
    O1 -->|触发每日任务| P1
    P1 -->|时间合规| P2
    P2 -->|数据清洗| P3
    P3 -->|标的可用| S1
    S1 -->|输出Alpha信号| S2
    S2 -->|风险可控/生成仓位| R1
    R1 -->|应用平台规则| R2
    R2 -->|模拟T+n流转成功| A1
    A1 -->|证据链条完整| R3
    R3 -->|执行交易动作| A2
    A2 -->|更新本地账本| O2
    O2 -.->|闭环反馈| O1
