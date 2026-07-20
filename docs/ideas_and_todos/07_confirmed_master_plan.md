# ChanAI Pulse 后续总体发展思路（确认审阅版）

**确认日期：** 2026-07-17  
**状态：** 总体方向已获得用户确认；具体工作包参数仍需在实施前冻结。  
**用途：** 作为后续正式路线图、平台交互设计、系统架构、数据模型和科研实验计划的共同上位依据。

## 1. 双层定位

### 平台长期愿景

> ChanAI Pulse 是面向全频段、全场景无线信道研究的数据处理、特性分析、信道生成与智能预测平台，并朝动态宽带 MIMO 复数信道 H 预测能力演进。

“全频段、全场景”描述长期覆盖范围。当前对外应使用“面向全频段、全场景研究”，不能宣称已在任意频段和场景完成可靠预测。

### 当前科研主线

> 从现有功率域预测基线出发，先实现动态宽带 SISO 复数 H 预测，再研究仿真预训练、用户数据适配和跨场景泛化，最终扩展到动态宽带 MIMO 空时频复数 H 张量预测。

## 2. 能力阶段

### 当前已经实现

- MATLAB 三页平台与中英文界面；
- 特性分析、6GPCM-lite 生成、训练与预测工作流；
- TCN、LSTM、GRU 功率域实数向量预测基线；
- 时间顺序 Train / Validation / Test；
- 生成数据只加入训练集；
- 初步数据契约、数据集管理、核心逻辑外提和人工 UI 验收流程。

当前预测对象是功率域特征向量，不是完整复数 H；DS 是由功率分布派生的统计量。

### 下一阶段

第一版新任务确定为动态宽带 SISO 复数 H 预测：

- 默认预测频域 `H(t,f)`；
- 同时保留 CIR `h(t,τ)`；
- 使用 FFT/IFFT 提供可追踪转换；
- 普通实数网络以 Re/Im 双通道表示复数；
- 先在研究脚本与自动测试中建立可靠基线，再接入 UI。

### 中期与长期

1. 建立多源数据预训练 Base Model；
2. 实现用户数据快速适配与 Adapted Model；
3. 验证跨轨迹、速度和场景泛化；
4. 扩展固定规模 MIMO；
5. 扩展多子载波空时频复数 H 张量；
6. 逐步研究跨频段、可变天线、数字孪生和信道地图。

## 3. 核心科学问题

> 多场景仿真预训练能否减少新场景需要的真实信道数据，并通过少量实测历史数据快速适配，提高未来复数 H 的预测精度与通信系统性能？

主要子问题：

- QuaDRiGa 预训练与真实数据从零训练的差异；
- 有效适配所需的真实数据量；
- 输出层、部分主干、Adapter、元学习的差异；
- 未见轨迹、速度、场景和频段上的泛化；
- 功率域与复数 H 预测的系统性能差异；
- QuaDRiGa、DeepMIMO、6GPCM-lite 的数据域差异。

## 4. 数据来源

### QuaDRiGa

作为主要研究级生成引擎，生成连续轨迹、复数 CIR/CTF、Doppler、空间一致性和 SISO/MIMO 数据，用于预训练及用户数据有限时的训练扩充。

### DeepMIMO 与其他射线追踪数据

作为几何环境和复杂 MIMO 数据补充；必须标记为仿真或射线追踪，不得描述为实测。

### 开放实测 CSI

用于真实微调、独立 Test、仿真到真实差距和跨场景验证。使用前必须检查复数值、连续轨迹、时间戳、相位一致性、载频、带宽、天线、许可证和隐私。

### 6GPCM-lite

保留为 Lightweight Baseline、自动测试/GUI 数据源、复数接口原型和备用生成器。其复数 CIR 有继续利用价值，但当前简单功率混合增强不作为新 H 主线的核心科学方法。

## 5. 统一复数 H 数据标准

概念上的统一表示：

```text
H[time, frequency, rx_antenna, tx_antenna] : complex
X[time, frequency, rx_antenna, tx_antenna, 2]
2 = Real / Imaginary
```

数据契约至少记录：

- H/CIR/CTF 及其 domain；
- 时间、频率或时延轴；
- Tx/Rx 天线维度；
- 载频、带宽、子载波间隔、采样间隔；
- 速度、轨迹、场景；
- 相位参考、同步和质量；
- 数据来源、许可、可见性和处理历史；
- 真实 H、估计 H-hat、生成 H 和功率派生量的区别。

只有复数、连续、物理轴明确的数据进入 Complex-H Pipeline；PDP/DPSD 等功率数据继续进入 Legacy Power Pipeline。

## 6. 静态与动态路由

| 类型 | 主要任务 |
| --- | --- |
| `dynamic_temporal` | 未来 H、Doppler 和信道老化预测 |
| `spatial_track` | 空间插值、位置外推和信道地图 |
| `static_drop` | 特性分析、统计建模和生成 |
| `static_repeated_measurement` | 噪声、估计稳定性和重复性分析 |

独立静态 drop 不得排列成虚假时间序列。静态场景仍有 CIR、PDP、DS 和频率选择性，只是理想情况下慢时间变化与 Doppler 为零。

## 7. 离线 Base Model 工作流

```text
QuaDRiGa
+ DeepMIMO / 其他仿真
+ 授权开放实测 CSI
→ 统一复数 H 数据契约
→ 质量、相位和元数据检查
→ 按场景/轨迹/位置/会话划分
→ 构造预测滑窗
→ 训练和验证 Base Model
→ 保存模型、归一化、配置、指标和适用范围
→ 加入 Base Model Registry
```

“通用模型”可以是具有明确适用边界的模型家族，例如 SISO-Wideband、High-Mobility、MIMO-Sub6，而不是从一开始追求一个无边界万能模型。

## 8. 在线用户适配工作流

```text
导入用户历史复数 H
→ 检查并统一数据
→ 根据元数据选择 Base Model
→ Base Model 直接预测，建立零样本基线
→ 判断是否需要生成扩充和参数适配
→ 冻结 Base Model 主体
→ 训练输出层、最后预测块或 Adapter
→ Validation early stopping
→ 比较适配前后指标
→ 变差则回退 Base Model
→ 保存独立 Adapted Model
→ 预测真正未来 H
```

Base Model 永远只读；Adapted Model 单独保存其来源、数据范围、训练层、配置和验证结果。

用户模式：

- 直接预测：不改网络权重；
- 快速适配：默认，只更新少量参数；
- 深度微调：高级，需要更多数据和更严格验证。

## 9. 数据划分与扩充边界

必须先按轨迹、场景、位置或测量会话划分，再构造窗口：

```text
真实 Train       → 训练、生成器校准、适配
真实 Validation  → 模型选择与 early stopping
真实 Test        → 最终独立报告
Synthetic        → 只进入预训练或训练
```

禁止使用完整真实数据校准生成器后随机切分，禁止相邻快拍泄漏，禁止使用真正未来数据适配，禁止使用合成 Test 替代真实结论。

## 10. 未来平台任务流

```text
导入动态宽带复数信道数据
→ 数据类型识别与质量检查
→ 统一转换为复数 H
→ 特性分析与可视化
→ 读取场景和物理元数据
→ 推荐/选择 Base Model
→ 运行直接预测基线
→ 判断是否需要扩充与适配
→ （可选）QuaDRiGa / 6GPCM-lite 扩充训练数据
→ 快速适配或深度微调
→ Validation 检查与失败回退
→ 保存 Adapted Model
→ 预测未来复数 H
→ 点级、物理级和系统级评价
→ 保存完整实验
```

## 11. 三页交互演进

### 第一页：数据与特性

导入 H/CIR/CTF/PDP，检查复数能力、相位、时间顺序和元数据，展示幅度、相位、PDP、DS、Doppler 和天线相关性。Power-only 数据必须明确路由到旧基线。

### 第二页：生成与扩充

选择 None、6GPCM-lite 或 QuaDRiGa；生成并预览连续复数轨迹；比较仿真与真实训练段；“生成”与“加入训练”作为两个独立动作。

### 第三页：模型适配与预测

选择 Base Model；运行直接预测；选择适配等级；训练并验证 Adapter/微调层；比较适配前后指标；预测未来 H；保存 Adapted Model。

## 12. 模型顺序

1. Persistence、移动平均/线性外推、AR、Kalman；
2. TCN、LSTM、GRU 的 Re/Im 复数基线；
3. Base Model、输出层/最后块微调、Adapter、元学习；
4. 固定规模 MIMO、角度—时延域、注意力、Transformer、复杂值与物理约束模型。

新模型不得未经统一 Benchmark 直接替换既有基线。

## 13. 评价体系

### 点级

Complex NMSE、复数相关、幅度误差、相位误差、单步和多步误差。

### 分布与物理级

经验 PDP、经验 DS CDF、K-S/Wasserstein、Doppler、空间相关性。

### 通信系统级

可达速率、容量、波束赋形/预编码损失、相比过时 CSI 的收益、推理与适配成本。

CDF 只能作为宏观统计验证，不能替代逐样本 complex NMSE 和通信系统收益。

## 14. 对照实验

在同一独立真实 Test 上比较：

```text
Persistence / AR / Kalman
真实数据从零训练
QuaDRiGa-only
真实 + QuaDRiGa
QuaDRiGa 预训练 + 真实微调
Base Model 零样本
Base Model + 用户快速适配
```

报告数据量、可训练参数量、训练/适配耗时、多个随机种子的均值方差、complex NMSE 与系统级性能。

## 15. 系统架构

```text
UI / App
→ Application Workflow
→ Domain / Core
→ Model Registry / Adapter
→ Experiment / Storage / Privacy Infrastructure
```

同时保留：

```text
Legacy Power Pipeline
Complex-H Pipeline
```

App 只负责页面、语言、提示、进度和流程编排；数据处理、训练、适配、预测与评价位于可测试核心层。

## 16. 实施顺序

1. 完成当前平台模块化拆分与人工验收；
2. 修正 DS CDF、频率/时延轴、Group RMSE 等科学基线；
3. 冻结动态宽带 SISO 复数 H 任务与数据契约；
4. 建立 QuaDRiGa、DeepMIMO、开放实测和 6GPCM-lite 复数数据管线；
5. 建立传统与 TCN/LSTM/GRU 复数预测基线；
6. 接入平台 Complex-H 基础流程；
7. 训练和管理多源 Base Model；
8. 实现用户数据快速适配、验证与回退；
9. 建立 Experiment Manager 与统一 Benchmark；
10. 扩展固定规模 MIMO，再研究跨频段、可变规模和长期平台能力。

## 17. 暂不优先

- 宣称当前已实现全频段全场景预测；
- 删除旧 Power Baseline 或 6GPCM-lite；
- 一开始即做 massive MIMO 或复杂值 Transformer；
- 数据契约未明确前堆叠新模型；
- 独立静态 drop 冒充时间序列；
- 生成数据进入真实 Validation/Test；
- 使用未来数据完成适配；
- 只报告 CDF 而不报告点级与系统级收益；
- 核心能力稳定前进行大规模 UI 美化或 Web/Cloud 迁移。

## 18. 一句话总路线

> 完成现有平台基线与模块化，建立统一复数 H 数据标准，以 QuaDRiGa 和开放数据训练场景受限的通用 Base Model，通过用户历史数据快速适配得到专用模型，预测未来复数 H，并最终扩展到动态宽带 MIMO 空时频信道张量和面向全频段全场景的长期研究平台。

