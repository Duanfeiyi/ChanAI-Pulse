# 系统架构思路与待办

**最后更新：** 2026-07-17  
**状态：** 当前模块化拆分进行中；Legacy Power 与 Complex-H 并行架构方向已确认，完整路线见 `07_confirmed_master_plan.md`。

## 1. 当前架构事实

- `app/ChannelSimulatorApp.m` 仍是唯一桌面入口和主要 UI 状态容器；
- 特性分析、生成、预处理、预测和评价已有部分纯函数位于 `core/`；
- Characterization、Generation、Prediction 绘图已外提到 `app/plotting/`；
- 当前预测引擎保留 TCN、LSTM、GRU 基线；
- 数据集生命周期拆分已进入本地人工审阅阶段；
- App 可运行、可人工验收、可回退仍是每个结构 PR 的硬性要求。

## 2. 建议的目标分层

```text
UI / App Layer
  - 控件、页面、语言、提示、进度、人工操作

Application Workflow Layer
  - 导入工作流、生成工作流、训练工作流、适配工作流、预测工作流

Domain / Core Layer
  - 数据契约、特性计算、生成器接口、预测、评价、切分

Model Layer
  - Power Baseline、Complex-H Base Model、Adapter、模型注册表

Infrastructure Layer
  - 本地文件、实验目录、模型保存、日志、配置、隐私边界
```

App 回调只组织用户流程，不直接实现数据处理、模型训练或评价公式。

## 3. 旧流程与新流程并存

建议保留两条明确管线：

```text
Legacy Power Pipeline
  PDP / DPSD → TCN / LSTM / GRU → 功率预测与旧指标

Complex-H Pipeline
  Complex H → Base Model → Adapter / Fine-tuning → Future Complex H
```

新管线稳定前不得删除旧基线。数据契约根据输入能力决定路由，不允许把功率数据伪装成复数 H。

## 4. 生成器架构

统一生成器接口应允许多个后端：

```text
Generation Engine Interface
├─ 6GPCM-lite：轻量、测试、基线、离线备用
├─ QuaDRiGa：主要研究级 GSCM 后端
└─ Future adapters：DeepMIMO / 其他仿真数据导入
```

生成结果首先保留复数 CIR/H、轴和元数据；PDP、DS、Doppler 等作为派生特征计算，不能在接口入口提前丢失相位。

## 5. 模型管理架构

Base Model 与 Adapted Model 必须分离：

```text
models/
  base/<base_model_id>/
    model
    schema
    normalization
    training_config
    metrics
  adapted/<adapted_model_id>/
    base_model_id
    adapter_or_delta
    adaptation_config
    validation_metrics
    provenance
```

真实数据本身不得复制到模型目录或公开仓库。模型是否允许公开需要另行进行隐私、许可和反演风险审查。

## 6. 实验管理

每次训练、适配和预测应具有独立实验记录：

```text
experiments/exp_YYYYMMDD_HHMMSS/
  config
  data_manifest
  split_manifest
  base_model_id
  adapted_model_id
  metrics
  predictions
  figures
  log
```

真实文件路径应脱敏或以本地 ID 引用；不能进入公开 Git。

## 7. 架构待办

| ID | 优先级 | 待办 | 状态 |
| --- | --- | --- | --- |
| ARCH-001 | P1 | 完成当前 App 非 UI 逻辑拆分，并保持旧行为 | 进行中 |
| ARCH-002 | P1 | 定义 Legacy Power 与 Complex-H 两条明确路由 | 待设计 |
| ARCH-003 | P1 | 引入 Application Workflow 层，App 只做流程编排 | 待实现 |
| ARCH-004 | P1 | 定义 Base / Adapted Model Registry | 待设计 |
| ARCH-005 | P2 | 建立一次实验一次记录的 Experiment Manager | 旧路线已提出，待实现 |
| ARCH-006 | P2 | 建立统一 Generation Engine 接口与 QuaDRiGa adapter | 待实现 |
| ARCH-007 | P2 | 为长时间训练/适配建立取消、失败回滚和状态恢复 | 待设计 |
