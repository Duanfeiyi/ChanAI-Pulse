# ChanAI Pulse 待解决问题与后续拆分路线图

**最后更新：** 2026-07-13  
**当前基线：** PR #5 已合并；App 已具备时序 `70% / 15% / 15%` 的 Train / Validation / Test 流程。

本文件用于记录暂缓工作、明确后续拆分顺序，并防止团队在多人并行时遗漏已经发现的科学或工程问题。

## 一、永远不变的验收准则

> **可运行 App 是永远不动摇的验收标准。每一次拆分 PR 都必须满足：**
>
> 1. 不破坏三页 GUI、按钮流程和中英文切换；
> 2. 不删除旧功能，不修改原始实测数据；
> 3. 不提交或公开任何真实测量数据、压缩包、`datasets/` 或 `legacy/`；
> 4. 通过相关 MATLAB 自动测试与 `tests/smoke_test.m`；
> 5. 改动到 App 行为时，必须完成对应页面的人工 GUI 验收；
> 6. 一个 PR 只解决一个清晰问题，可回滚、可比较、可审阅。

## 二、已经完成的基础工作

- Characterization 的数据提取、角度谱和部分特性计算已外提至 `core/characterization/`。
- 6GPCM-lite 生成器已外提至 `core/generation/`，并明确标记为 synthetic。
- 数据契约、SAGE 读取、预处理和时序切分基础已位于 `core/dataset/` 与 `core/preprocessing/`。
- 预测实验已具备独立 Train / Validation / Test；归一化只由训练段计算。
- `Real + Synthetic` 模式中，生成数据只扩充训练，不进入验证和最终 Test。
- TCN、LSTM、GRU 的现有层结构未改动；通用层构建与 hold-out prediction 已开始位于 `core/prediction/`。

## 三、待解决问题清单

| ID | 优先级 | 问题 | 当前影响 | 建议阶段 |
| --- | --- | --- | --- | --- |
| EVAL-001 | P1 | DS CDF 当前采用均值/方差的高斯近似，不是经验 CDF。 | DS 分布的长尾、多峰和真实差异可能被掩盖。 | 6C |
| EVAL-002 | P2 | Group RMSE 在 42 个 Test Target 时只覆盖前 40 个。 | 总 Test RMSE 正确，但分组图遗漏尾部样本。 | 6C |
| EVAL-003 | P2 | 训练进度窗使用标准化内部尺度，易与 dBm 报告混淆。 | 初学者可能把训练窗数值误认为物理 RMSE。 | 6C |
| GEN-001 | P1 | 6GPCM-lite 的 `delay_grid_step_ns` 与由带宽决定的实际 delay axis 尚未严格统一。 | 生成数据的延迟尺度可能失真，影响 DS/PDP 相关结论。 | 6D |
| GEN-002 | P1 | 尚未在固定 Test 集上证明生成数据优于 real-only training。 | 不能宣称数据增强一定提升预测性能。 | 6E |
| PHY-001 | P2 | Angular PSD 与 Doppler 目前主要是特性展示，尚非预测误差的独立验证。 | 不能据此宣称已准确预测角度或多普勒。 | 6C / v1.2 |
| PRED-001 | P1 | TCN、LSTM、GRU 的训练调用仍主要集中在 App 编排函数中。 | 多人修改算法时仍可能碰到同一大 App 文件。 | Step 8 |
| PRED-002 | P2 | 递归未来预测、评估结果封装和实验配置尚未完全成为稳定的纯函数接口。 | Web/Python 迁移与批量实验复用能力不足。 | Step 8 / Step 9 |
| DATA-001 | P1 | ChanAIs Dataset 尚未形成完整可公开的数据标准、转换器和 demo。 | 不利于多来源数据统一接入和协作。 | Step 7 |
| REPRO-001 | P2 | 配置、随机种子、模型、图和指标尚未自动沉淀为一次实验记录。 | 结果复现与多人比较成本高。 | Step 9 |
| BENCH-001 | P2 | 尚无固定任务、数据划分、基线和统一报告的 Benchmark。 | 不适合做正式算法横向比较。 | Step 10 / v1.2 |

### 暂缓工作的使用边界

6C、6D、6E 可以暂时由不同成员延后完成，但在它们完成前：

- 只将 6GPCM-lite 描述为 **synthetic, geometry-inspired generator**；
- 不宣称其已被真实测量数据物理校准；
- 不以当前 DS CDF 图作为最终论文结论；
- `Real + Synthetic` 结果仅说明平台流程可运行，不能单独证明增强有效。

## 四、下一阶段：Step 7 - ChanAIs Dataset Foundation

Step 7 不改变现有训练、预测或 GUI，只建立未来所有数据工作的统一入口。

### 7A：数据标准与 SAGE 兼容审阅

**目标：** 完善 `docs/DATASET_SPECIFICATION.md`，审阅现有 `core/dataset/` 接口，确定统一字段、目录层级和可见性规则。

**重点：**

- 明确 `metadata.json` 必填项：场景、频段、带宽、天线、极化、轨迹、LOS、采样间隔、数据来源、可见性等。
- 固化 SAGE 映射：`alpha`、`doa`、`delay`、`cir`、`cir_e`、`likelihood`。
- 明确 SAGE、CIR、CTF、PDP、Doppler、Angular Spectrum、Feature Tensor 的标准表示。
- 所有真实数据只读、本地处理，结果目录必须被 `.gitignore` 排除。

**建议分支：** `feature/chanais-dataset-foundation`

### 7B：只读 Dataset Converter Framework

**目标：** 让不同成员可在本地将 SAGE MAT 数据映射为统一 ChanAIs 表示，而不改动原文件。

**目标文件：**

```text
tools/dataset_converter/inspect_mat_dataset.m
tools/dataset_converter/convert_sage_to_chanais.m
tools/dataset_converter/build_metadata_template.m
tools/dataset_converter/README.md
```

**验收：** 对本地 SAGE 数据仅做读取、变量检查和本地忽略目录输出；Git 中不能出现真实 MAT 或转换产物。

### 7C：Synthetic SAGE Demo Dataset

**目标：** 生成可公开的 SAGE-like demo，供 clone 后解析、可视化和测试。

```text
demo_data/chanais_demo/
  synthetic_sage_scenario1.mat
  metadata.json
  README.md
```

demo 必须显式声明为 synthetic，字段可包含 `sage.alpha`、`sage.doa`、`sage.delay`、`sage.cir`、`sage.cir_e` 和 `sage.likelihood`，但不得来源于真实测量文件。

### 7D：Dataset Manager 最小接口

**目标：** 补齐并测试以下无 GUI 接口，暂不改变 App 的 Load Data 按钮。

```text
core/dataset/load_chanais_dataset.m
core/dataset/validate_chanais_dataset.m
core/dataset/read_sage_mat.m
core/dataset/parse_dataset_metadata.m
```

## 五、Step 8 - Prediction Algorithms 细化拆分

Step 7A 合并后，可以开始拆分三个算法。原则是：**复制现有行为到纯函数，App 只保留按钮、提示和绘图调度。绝不同时重写三个算法。**

### 8A：共享预测协议固定

先固定输入输出协议，避免三个成员各自定义不同格式。

```text
输入：experiment.train / validation / test
输出：trainedNet、normalization parameters、validation metrics、test predictions
```

共享函数保持在：

```text
core/prediction/prepare_temporal_prediction_experiment.m
core/prediction/predict_holdout_partition.m
core/prediction/run_prediction.m
core/prediction/recursive_predict.m
```

### 8B：TCN 单独拆分

**建议分支：** `feature/prediction-tcn-module`

```text
core/prediction/train_tcn.m
core/prediction/build_tcn_layers.m
tests/test_tcn_prediction.m
```

要求：层数、滤波器数、dilation、学习率和 epoch 不变；先由 App 调用 TCN 新函数，人工运行现有 TCN 流程。

### 8C：LSTM 单独拆分

**建议分支：** `feature/prediction-lstm-module`

```text
core/prediction/train_lstm.m
core/prediction/build_lstm_layers.m
tests/test_lstm_prediction.m
```

要求：保持两层 256 LSTM、dropout 与现有训练选项不变。

### 8D：GRU 单独拆分

**建议分支：** `feature/prediction-gru-module`

```text
core/prediction/train_gru.m
core/prediction/build_gru_layers.m
tests/test_gru_prediction.m
```

要求：保持两层 256 GRU、dropout 与现有训练选项不变。

### 8E：统一训练调度与递归预测

在三个算法均独立通过后，再引入很薄的调度层：

```text
core/prediction/train_prediction_model.m
core/prediction/run_prediction.m
core/prediction/recursive_predict.m
core/evaluation/evaluate_prediction_result.m
```

App 的 `trainModel_Generic` 和 `runPredictionLogic_Generic` 最终只负责：读取 UI 值、调用纯函数、更新图和弹窗。

## 六、Step 9 - Experiment Manager 与可复现性

在算法拆分稳定后，引入一次实验一次目录的机制：

```text
experiments/exp_YYYYMMDD_HHMMSS/
  config.json
  metrics.json
  model.mat
  norm_params.mat
  prediction_results.mat
  figures/
  log.txt
```

必须记录：数据来源标签、切分比例、随机种子、算法、训练时间、Validation/Test 指标。真实数据的内容不能复制进实验目录或 Git。

## 七、暂缓但必须回归的 6C / 6D / 6E

### 6C：评估指标修正

- 用经验 CDF 替换 DS Gaussian approximation。
- 新增 K-S Distance；可选 Wasserstein Distance。
- Group RMSE 覆盖所有 Test Target。
- 明确训练窗 normalized metric 与报告 dBm metric 的区别。

### 6D：6GPCM-lite 校准

- 统一 `bandwidth`、FFT、delay grid、delay axis。
- 对比本地实测的 PDP、DS CDF、Doppler。
- 校准版本与现有 lite baseline 并存，先比较再替换默认模式。

### 6E：生成数据有效性 A/B 实验

固定相同真实 Test 集，比较：

```text
Real-only training
Real + synthetic training
Synthetic pretraining + real fine-tuning
```

报告 Test RMSE、NRMSE、Capacity Accuracy、DS CDF / K-S 与推理耗时。

## 八、Step 10 - ChanAI Benchmark（v1.2）

只有 Step 7、Step 8、Step 9 与 6C 至少稳定后，才进入 Benchmark：

- 固定 Characterization、Generation、Prediction、Missing-data Completion 任务；
- 固定数据划分和随机种子；
- 固定 TCN、LSTM、GRU 与传统方法基线；
- 自动生成 CSV、图和 HTML/TXT 报告；
- 不公开真实测量数据。

## 九、长期版本路线

```text
v1.1  ChanAIs Dataset
v1.2  ChanAI Benchmark
v2.0  Physics-Informed Prediction
v2.1  Cross-Scenario Generalization
v3.0  Web Platform and Cloud Deployment
```

其中 Physics-Informed Prediction 应在 6C 与 6D 完成后再引入，例如对 PDP、DS、容量或物理一致性加入辅助约束；不能以未校准的 synthetic 数据替代真实 Test。

## 十、多人协作建议

| 角色 | 可负责分支 | 尽量避免同时修改 |
| --- | --- | --- |
| 数据成员 | Step 7A/7B/7C | `app/ChannelSimulatorApp.m` |
| TCN 成员 | 8B | LSTM/GRU 文件 |
| LSTM 成员 | 8C | TCN/GRU 文件 |
| GRU 成员 | 8D | TCN/LSTM 文件 |
| 指标成员 | 6C | 网络层结构 |
| 生成成员 | 6D/6E | 预测 UI 调度 |
| 集成成员 | App 调用与 GUI 验收 | 大规模算法重写 |

每个成员从最新 `main` 创建自己的 feature branch；完成后先运行测试、再创建 PR。集成成员只在 PR 审阅通过后合并到 `main`。

## 十一、何时才算“拆分基本完成”

满足以下条件才可称为预测模块基本拆分完成：

1. App 仅保留 UI 控件、语言、回调、绘图与错误提示；
2. TCN、LSTM、GRU 均有独立训练函数、独立测试和明确输入输出；
3. 递归预测、评估和实验保存不依赖 UI 对象；
4. 每个算法分支都通过 App 人工验收；
5. 新旧基线在同一 Test 集上的输出维度、指标计算与主要结果趋势可比较；
6. 真实数据始终只留在本地，公开仓库只含 synthetic demo。
