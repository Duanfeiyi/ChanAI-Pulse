# 实验数据切分与增强规范

## 目的

本规范定义 ChanAI Pulse 后续训练实验如何使用本地真实数据和合成生成数据。它不改变当前 App 的训练行为；后续训练接入必须遵守本规范。

## 基本原则

```text
真实本地时序数据
  -> Train (70%)
  -> Validation (15%)
  -> Test (15%)

生成数据
  -> 只能加入 Train
```

真实数据不得上传 GitHub。生成数据若公开，必须标记为 synthetic 或经过脱敏的 measurement-calibrated synthetic。

## 为什么按时间切分

信道快拍前后相关。随机打乱会让相邻甚至几乎相同的快拍同时出现在训练和测试中，造成未来信息泄漏。必须先按时间或测量轨迹切分，再分别构造预测滑窗。

## 窗口规则

预测窗口不得跨越分区边界。例如窗口长度为 10、预测步长为 1 时，验证段的首个可用样本必须完全由验证段内的 10 个历史快拍构成；训练段末尾不能借用验证段作为目标。

## 数据来源标签

| `source_type` | 用途 | 是否可用于最终指标 |
| --- | --- | --- |
| `real_train` | 模型训练 | 否 |
| `real_validation` | 选择训练轮数、模型与参数 | 否 |
| `real_test` | 最终独立测试 | 是 |
| `synthetic_generated` | 训练集扩充或预训练 | 否 |
| `measurement_calibrated_synthetic` | 已脱敏的校准合成数据 | 否，除非另做生成质量评估 |

## 正式实验应报告什么

至少比较以下三组，并在同一份 `real_test` 上报告结果：

1. Real-only training
2. Real + generated augmentation
3. Generated pretraining + real fine-tuning

报告应包括 Train、Validation 与 Test 的数据规模，以及 Test RMSE、NRMSE、Capacity Accuracy、DS CDF / K-S Distance 和推理时间。

## 当前状态

本阶段只提供纯函数和合成测试。下一阶段才会将该协议接入 TCN、LSTM、GRU 训练与 App 训练进度窗口。
