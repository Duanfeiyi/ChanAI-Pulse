# ChanAI Pulse 待解决问题与后续路线图

**最后更新：** 2026-07-13
**当前状态：** Step 7 已合并；Step 8 Unified Prediction Engine 正在 PR 审阅。

本文件记录暂缓问题、后续研究任务和拆分顺序，防止多人协作时遗漏已发现的工程或科学问题。

## 永远不变的验收准则

> **可运行 App 是永远不动摇的验收标准。每一次拆分 PR 都必须满足：**

1. 不破坏三页 GUI、按钮流程、中英文切换和现有图表；
2. 不删除旧功能，不修改原始实测数据；
3. 不提交真实测量数据、压缩包、`datasets/` 或 `legacy/`；
4. 通过相关 MATLAB 自动测试和 `tests/smoke_test.m`；
5. 影响 App 行为时，必须完成对应页面的人工 GUI 验收；
6. 一个 PR 只处理一组可说明、可比较、可回滚的变更。

## 已完成的基础工作

- Characterization 的数据提取、角度谱和部分特性计算已位于 `core/characterization/`。
- 6GPCM-lite 生成器已位于 `core/generation/`，并明确标记为 synthetic。
- 时序 Train / Validation / Test 切分与训练段归一化已独立实现。
- Real + Synthetic 模式仅用生成数据扩充训练段，不污染验证和最终 Test。
- ChanAIs Dataset 的分级元数据、SAGE 转换、公开 synthetic demo 和 Dataset Manager 已合并。
- Step 8 已将 TCN、LSTM、GRU 的共享训练、预测、递归预测和评估逻辑外提到 `core/prediction/`，等待 PR 审阅。

## 待解决问题

| ID | 优先级 | 问题 | 当前边界 | 建议阶段 |
| --- | --- | --- | --- | --- |
| EVAL-001 | P1 | DS CDF 目前是高斯近似，不是经验 CDF。 | 不应用于最终分布结论。 | 6C |
| EVAL-002 | P2 | Group RMSE 可能遗漏末尾 Test Target。 | 总 RMSE 正确，分组图可能不完整。 | 6C |
| EVAL-003 | P2 | 训练窗的标准化尺度容易与 dBm 报告混淆。 | 文档和 UI 需更明确区分。 | 6C |
| GEN-001 | P1 | 6GPCM-lite 的 delay grid 与物理 delay axis 尚未严格校准。 | 仅能称为 synthetic, geometry-inspired generator。 | 6D |
| GEN-002 | P1 | 生成数据是否提升真实 Test 性能尚未完成 A/B 证明。 | 不能宣称增强一定提高泛化。 | 6E |
| PHY-001 | P2 | Angular PSD 与 Doppler 当前主要是展示结果。 | 不能据此宣称角度或多普勒已被独立准确预测。 | 6C / v1.2 |
| DOMAIN-001 | P1 | Frequency-domain prediction 尚未实现。`Freq` 按钮目前只改变 UI 选中状态。 | 当前仍运行时序预测流程，不能宣称已完成 CTF 或子载波预测。 | Step 9 后 / v1.2 |
| DOMAIN-002 | P1 | Spatial-domain prediction 尚未实现。`Space` 按钮目前只改变 UI 选中状态。 | 当前 Angular PSD 是展示结果，不能宣称已完成天线、角度或位置域预测。 | Step 9 后 / v1.2 |
| REPRO-001 | P2 | 实验配置、随机种子、模型、图和指标尚未自动归档。 | 多人复现实验成本较高。 | Step 9 |
| BENCH-001 | P2 | 尚无固定任务、基线和统一报告的 Benchmark。 | 不适合正式横向论文比较。 | Step 10 / v1.2 |

## 新增：预测算法升级任务

这些任务是**算法研究与性能优化**，不是当前 Step 8 的工程拆分内容。现有 TCN、LSTM、GRU 必须保留为可复现 baseline，不能被新模型直接覆盖。

| ID | 优先级 | 任务 | 建议做法 | 前置条件 |
| --- | --- | --- | --- | --- |
| MODEL-001 | P1 | 建立 TCN-Res 基线。 | 新增残差块和多个 dilation block，命名为 `TCN-Res`，与现有 `TCN` 并存。 | Step 8 合并、固定 Test 集。 |
| MODEL-002 | P2 | TCN 可调感受野。 | 将层数、kernel size、dilation schedule、window length 写入 config；不得改写现有默认 TCN。 | MODEL-001 或 Benchmark 协议。 |
| MODEL-003 | P2 | 评估 TCN Dropout 与归一化策略。 | 在相同数据切分上比较无 Dropout、Dropout、BatchNorm、WeightNorm；不盲目叠加。 | 固定随机种子与 A/B 实验。 |
| MODEL-004 | P2 | 研究序列末端输出替代全局平均池化。 | 对比 `globalAveragePooling1dLayer` 与 last-timestep/sequence-to-one 输出。 | 固定同一窗口和 Test 集。 |
| MODEL-005 | P2 | LSTM/GRU 结构可调。 | 将层数、hidden units、Dropout 和学习率作为配置；保留当前两层 256 单元模型。 | Experiment Manager。 |
| MODEL-006 | P2 | LSTM/GRU 训练策略优化。 | 研究 early stopping、ValidationPatience、学习率策略与梯度阈值。 | 独立验证集和可复现实验记录。 |
| MODEL-007 | P1 | 三算法统一公平比较。 | 在相同 Train/Validation/Test、相同输入窗口和重复随机种子下报告均值与方差。 | 6C、Step 9、Step 10。 |

### 当前模型的定位

- `TCN`：三层 causal dilated convolution，dilation 为 `1 / 2 / 4`，采用 global average pooling，属于轻量 baseline。
- `LSTM`：两层 256-unit LSTM，第二层采用 `OutputMode="last"`，含 Dropout 0.2。
- `GRU`：两层 256-unit GRU，第二层采用 `OutputMode="last"`，含 Dropout 0.2。

TCN-Res、注意力、WeightNorm、可调隐藏层或早停都值得研究，但必须作为独立模型版本和独立 PR；不得在没有对照实验时替换现有 baseline。

## 未完成的 Frequency / Space 域任务

目前第三页的三个按钮表达的是平台目标，而不是三个都已落地的预测模式：`Time` 已实现；`Freq` 和 `Space` 仍是待实现入口。现阶段请保持选择 `Time`，以避免对实验含义产生误解。

### Frequency domain（Freq）

1. 明确输入数据为 CTF、子载波响应或频率采样后的特征张量，并在 Dataset Specification 中写清维度和单位；
2. 定义具体任务，例如由已知子载波补全缺失子载波，或由部分频段预测目标频段；
3. 为频域任务建立独立的数据预处理、训练入口、评价指标和图表；
4. 只有当 `selectedTarget="Freq"` 真正路由到上述流程后，才能将其称为频域预测。

### Spatial domain（Space）

1. 明确空间维度来自天线阵元、AoA/AoD、波束或空间位置，而不是仅显示 Angular PSD；
2. 定义具体任务，例如缺失阵元补全、角度谱预测或空间位置之间的信道插值；
3. 建立独立的空间数据形状、切分方法、模型入口和误差指标；
4. 只有当 `selectedTarget="Space"` 真正路由到上述流程后，才能将其称为空间域预测。

## 后续工作顺序

1. **完成 Step 8 PR 审阅与人工验收**：确认 TCN、LSTM、GRU 都能从 App 训练、预测和显示报告。
2. **6C 评估严谨化**：经验 DS CDF、完整 Group RMSE、训练尺度说明。
3. **6D / 6E 生成器校准与增强 A/B 实验**：固定真实 Test 集，不以训练曲线替代 Test 结论。
4. **Step 9 Experiment Manager**：自动保存 config、seed、模型、归一化参数、指标、图和日志。
5. **Frequency / Space 域实现 PR**：在可复现实验记录的基础上，分别实现真实的频域和空间域任务，不能只增加按钮。
6. **Step 10 Benchmark**：固定任务、划分、baseline 和报告。
7. **模型升级 PR**：以 `TCN-Res` 为优先，再做 TCN 感受野和 LSTM/GRU 超参数研究。

## 数据安全边界

- 真实数据只可在本地读取、训练、测试和 Benchmark；
- 真实 MAT、raw archive、提取结果和转换结果不得提交或复制到公开 demo；
- GitHub 仅可包含 synthetic demo；
- 每次 PR 提交前必须检查 `git status` 和 `git ls-files`。
