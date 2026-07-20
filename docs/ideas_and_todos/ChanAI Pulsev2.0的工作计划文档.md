# ChanAI Pulse v2.0 工作计划

**制定日期：** 2026-07-20  
**状态：** 已确认的研发路线；待按阶段审批实施。  
**关联文档：** [平台功能设计.md](平台功能设计.md)、[已确认总体路线](07_confirmed_master_plan.md)、[开放问题与待办](06_open_issues_and_todos.md)。

## 1. 版本定位

| 版本 | 定位 | 主要能力 |
| --- | --- | --- |
| v1.0 | 冻结的Legacy平台 | SAGE/DPSD功率域、6GPCM-Lite、TCN/LSTM/GRU、现有三页GUI |
| v2.0 | 新一代Complex-H研究与预测平台 | 真正QuaDRiGa、动态宽带SISO复数 \(H(t,f)\)、通用Base Model、用户快速适配 |
| v2.1 | MIMO扩展 | 固定规模 \(H[t,f,N_r,N_t]\)、空间/波束域与系统级指标 |
| v3.0远景 | 更广泛的通用研究平台 | 跨频段、跨场景、动态宽带MIMO空时频信道预测 |

v2.0的科学目标应严格定义为：

> 在明确的载频、带宽、频率网格和若干代表性动态场景范围内，建立动态宽带SISO复数 \(H(t,f)\) 的通用Base Model，并利用用户已观测历史数据进行安全快速适配，预测未来H。

v2.0不应在缺乏证据时宣称“全频段、全场景、MIMO通用预测”。

## 2. v1.0冻结策略

v1.0是可运行的Legacy Baseline，不再承担v2.0的新科学路线。冻结后：

- 当前GitHub稳定主线作为v1.0代码基线；
- 建立正式版本标签，例如 `v1.0.0`；
- 发布说明中明确已知限制：功率域主流程、DS CDF待修复、Freq/Space尚非真实预测模式、6GPCM-Lite仅为轻量合成基线、没有Complex-H Base Model；
- 保留v1.0的三页GUI、6GPCM-Lite和TCN/LSTM/GRU；
- v1.0后续只接收严重运行故障、安全问题或发布阻断问题的修复；
- 不在v1.0继续进行大规模功能重构；
- 真实数据始终只留在本地，不提交GitHub。

## 3. 分支与合并策略

```text
main / v1.0稳定线
  └─ 标签：v1.0.0

develop/v2.0
  ├─ feature/v2-quadriga-data
  ├─ feature/v2-complex-h-contract
  ├─ feature/v2-generation-engine
  ├─ feature/v2-complex-benchmark
  ├─ feature/v2-base-model
  ├─ feature/v2-adaptation
  └─ feature/v2-ui-integration
```

规则：

1. v2.0功能分支先合入 `develop/v2.0`；
2. `main`在v2.0完成前保持v1.0稳定；
3. 每个PR只覆盖一个可比较、可测试、可回退的工作包；
4. 可以推送和创建PR，但任何Merge只能由项目负责人手工操作；
5. 所有v2.0功能必须保留或显式隔离v1.0 Legacy管线；
6. 不提交真实测量数据、原始数据、私有模型输入或实验输出。

## 4. v2.0工作步骤

### Step V2-0：冻结v1.0并建立v2.0开发线

**目标：** 固定可回退的v1.0版本，建立不影响v1.0的v2.0研发空间。

**工作内容：**

- 核对GitHub `main`与本地稳定提交；
- 创建或核验 `v1.0.0` 标签；
- 编写v1.0 Release Notes和已知限制；
- 从v1.0标签建立 `develop/v2.0`；
- 将平台设计、v2.0计划和后续待办文档纳入v2.0开发线；
- 建立v2.0 PR模板与人工GUI验收模板；
- 不改变v1.0预测算法、物理指标、真实数据和运行行为。

**交付物：**

- v1.0.0标签/Release；
- `develop/v2.0`分支；
- v2.0设计文档与工作计划；
- v1.0已知限制清单。

**验收：** v1.0可以从标签检出、运行和回退；v2.0文档不会让用户误解为v1.0已实现的功能。

### Step V2-1：建立真正QuaDRiGa最小可复现生成管线

**目标：** 获得可审计、可复现的官方QuaDRiGa动态Complex-H数据，而不是名称相似的自编随机生成数据。

**工作内容：**

- 获取并核验官方QuaDRiGa包、许可证、版本和MATLAB兼容性；
- 建立最小官方运行验证，确认实际调用QuaDRiGa API；
- 固定首个任务：动态宽带SISO、固定载频/带宽/频率网格、少量3GPP场景、明确终端轨迹与快拍间隔；
- 建立 `GenerationConfig → QuaDRiGa Adapter → GenerationResult`；
- 输出路径复系数、路径时延、轨迹、天线、场景、随机种子和派生 \(H(t,f)\)；
- 生成小型公开Synthetic Demo和本地研究数据集；
- 建立种子复现、维度、复数性、时间连续性和坐标完整性自动测试。

**交付物：**

- QuaDRiGa环境说明；
- v2.0 QuaDRiGa Adapter；
- 最小Complex-H Synthetic Demo；
- 数据集卡和生成清单；
- 自动测试和人工运行说明。

**验收：** 同一版本、配置和随机种子可复现；生成结果具有明确时间/频率轴；不将旧“Quadriga 3D CSI”误标为正式QuaDRiGa数据。

### Step V2-2：统一Complex-H数据契约与模块一数据底座

**目标：** 让平台真正理解不同来源数据，而不是将所有输入压成匿名功率bin。

**工作内容：**

- 建立统一Complex-H布局：\(H[T,F,N_r,N_t]\)；
- 保存时间轴、频率轴、阵列维度、复数表示、来源和预处理记录；
- 建立SAGE、Legacy Power、QuaDRiGa和HDF5 Re/Im Adapter；
- 建立自动识别器、`Capability Profile`和预适配报告；
- 建立SAGE派生H流程，明确标识 `Derived H from SAGE`；
- 检查时间顺序、相位连续性、频率/时延轴、缺失值、维度和元数据；
- 建立Complex-H幅度、相位、PDP与Doppler核心计算。

**交付物：**

- Complex-H Dataset Specification；
- 数据转换器和质量验证器；
- 可追溯的Canonical Dataset；
- 合成测试夹具与真实数据只读人工检查说明。

**验收：** 功率数据不能伪造相位；没有物理坐标的数据不能生成错误单位图；SAGE、直接H和派生H被正确区分。

### Step V2-3：完成模块一v2.0界面

**目标：** 将数据识别、预适配与Complex-H可视化接入平台第一页。

**工作内容：**

- `Load & Validate`；
- 自动识别结果和兼容性状态；
- 数据元信息与能力标签；
- Data Quality面板；
- Legacy与Complex-H两套自适应四图；
- 原始数据/预适配数据对照；
- 明确是否允许进入模块二和模块三。

**验收：** 复杂数据字段、单位和不支持能力均可解释；Legacy流程仍可运行；Complex-H图不以占位数据伪造。

### Step V2-4：统一生成引擎与模块二v2.0

**目标：** 将“生成后直接送入AI”升级为可选、可比较、可审计的训练数据准备流程。

**第一部分：** `None` 与6GPCM-Lite

- 支持跳过生成；
- 保留6GPCM-Lite作为快速Legacy/原型基线；
- 修复其时延轴与带宽一致性；
- 分离Preview、正式生成、保存和加入Train。

**第二部分：** QuaDRiGa与完整6GPCM候选

- 接入已验证的QuaDRiGa Adapter；
- 评估旧完整6GPCM候选代码的许可、依赖和科学正确性；
- 通过独立Adapter接入，不直接将外部压缩包并入App。

**第三部分：** 生成质量与数据治理

- 对比Real Train与Generated的PDP、经验DS CDF、K-S/Wasserstein及可用动态统计；
- 合成数据只允许进入Adapt Train；
- Validation和Test始终保持真实且独立；
- 输出Generation Manifest和Augmentation Report。

**验收：** Preview不会进入训练；生成成功不等于自动加入训练；数据表示不兼容时必须阻止混合。

### Step V2-5：建立Complex-H Benchmark与首批预测基线

**目标：** 在训练通用Base Model前，先定义并验证一个明确的预测任务。

**首个任务：**

```text
输入：过去L个时刻的H(t,f)
输出：未来1～K个时刻的H(t,f)
范围：动态宽带SISO
```

**工作内容：**

- 固定历史窗口、预测范围、快拍间隔和频率网格；
- 建立按轨迹/场景/种子的Train、Validation、Test与Cross-scenario Test；
- 建立Persistence、线性/AR、Complex TCN、Complex GRU/LSTM等基线；
- 明确WiFo是否可在许可证和任务定义对齐后作为研究候选；
- 实现Complex NMSE、复相关、幅度误差、相位误差和误差随预测范围变化；
- 加入PDP、经验DS CDF、Doppler和资源成本；
- 建立基础Experiment Manager。

**验收：** 所有模型在相同切分、相同随机种子和相同指标下比较；Test不用于模型选择；结果可复现。

### Step V2-6：训练并注册通用Base Model

**目标：** 得到在v2.0定义范围内可直接预测的通用Complex-H模型。

**工作内容：**

- 使用多场景QuaDRiGa和许可明确的开放数据预训练；
- 评估是否加入经过验证的SAGE派生H；
- 选择稳定的模型架构和复数表示；
- 使用固定Validation选择模型；
- 在固定真实/独立Test上验证；
- 保存权重、归一化参数、模型配置和Benchmark结果；
- 建立Model Card和Base Model Registry；
- Base Model设置为只读。

**验收：** 可运行Direct Prediction；模型输入输出和适用边界明确；不以未验证的模拟数据宣称泛化能力。

### Step V2-7：用户快速适配与模块三v2.0

**目标：** 完成“Base Model + 用户历史数据 → 专用Adapted Model”的在线工作流。

**工作内容：**

- Direct Prediction；
- Fast Adaptation：冻结主干，仅更新输出层、最后块或Adapter；
- Validation早停、适配前后比较与自动回退；
- Deep Fine-tuning作为高级研究模式；
- 区分Held-out Evaluation与真正Future Forecast；
- 保存Adapted Model与Prediction；
- 导出完整Experiment Bundle；
- 完成第三页Base/Adapted对比、复数图表和评价报告。

**验收：** Base Model不可被覆盖；Test不参与适配；未来预测不显示伪造Ground Truth；适配结果可独立保存和回退。

### Step V2-8：v2.0集成验收与发布

**目标：** 将数据、生成、Base Model、适配和GUI作为一个可复现实验平台发布。

**工作内容：**

- 三页v2.0端到端自动测试；
- 真实数据只读人工GUI验收；
- Legacy和Complex-H双管线回归；
- 科学指标和物理坐标审计；
- 数据隐私、许可证和开源资产审计；
- 安装说明、用户手册和发布说明；
- 从 `develop/v2.0` 发起人工审阅PR并最终由项目负责人Merge。

**发布门槛：**

- 真正QuaDRiGa可复现；
- Complex-H数据契约稳定；
- Base Model和Fast Adaptation可用；
- 独立真实Test和实验记录完整；
- v1.0 Legacy能力未被破坏；
- 无真实数据进入GitHub。

## 5. v2.0里程碑

| 里程碑 | 完成标志 |
| --- | --- |
| v2.0-alpha.1 | 官方QuaDRiGa最小生成、Complex-H数据契约和Demo |
| v2.0-alpha.2 | 模块一Complex-H导入/验证/可视化，首个Benchmark |
| v2.0-alpha.3 | 模块二多生成器与训练数据治理 |
| v2.0-beta.1 | 通用Base Model和Direct Prediction |
| v2.0-beta.2 | Fast Adaptation和模块三集成 |
| v2.0-rc.1 | 完整测试、人工验收、许可证与数据审计 |
| v2.0.0 | 由项目负责人手动Merge和发布 |

## 6. v2.0当前优先级

当前最优先的研发任务是：

> **Step V2-0完成版本隔离后，立即执行Step V2-1：建立官方QuaDRiGa的最小可复现动态宽带SISO Complex-H生成管线。**

理由：没有可信、坐标完整、相位连续的Complex-H数据，就无法可靠建立数据契约、Benchmark或通用Base Model。

## 7. 通用实施约束

1. 真实数据只在本地读取、训练和验收，不提交、复制或打包进GitHub；
2. 每项科学逻辑变更独立PR，附数值回归测试和人工GUI验收；
3. 每项PR允许推送，但绝不自动Merge；
4. Base Model、Adapted Model、生成数据和实验报告必须可追溯；
5. 不把未验证的概念渲染、模拟数据或按钮状态描述为已实现科学能力；
6. v2.0先完成SISO Complex-H，MIMO作为v2.1独立范围；
7. 不使用Validation/Test校准生成器或选择适配参数；
8. 任何QuaDRiGa、WiFo或外部代码接入前先检查许可证、版本、依赖和任务适配性。
