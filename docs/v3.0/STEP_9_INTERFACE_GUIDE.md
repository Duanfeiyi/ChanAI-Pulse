# Step 9 预测参数与训练数据接口指南

## 1. 这一步到底做什么

Step 9 不训练神经网络。它先把“未来模型要吃的数据”整理成固定形状，解决四个问题：

1. 每一列是什么参数；
2. 内插和外推各把哪些位置交给模型；
3. 哪些路线用于训练、验证和测试；
4. MATLAB 与 Python 怎样读取完全相同的数据。

可以把它理解成先统一试卷格式。Step 10 才是让模型做题。

## 2. 两层数据

### 参数序列

```text
values: [N_parameter_sample, P]
```

- `N_parameter_sample`：沿路线、场景或时间排好的参数样本数；
- `P`：参数列数；
- 第一版标准列为 `DS_mu`、`KF_mu`；
- 契约支持的全部 8 列为
  `DS_mu`、`DS_sigma`、`r_DS`、`num_clusters`、`num_rays`、
  `LNS_ksi`、`KF_mu`、`KF_sigma`。

每一行还带有：

- `group_id`：属于哪条路线/场景；
- `label_source`：生成器真值、Grid 拟合值或 SA 拟合值；
- `fit_score`：拟合距离；
- `quality_status`：`PASS/WARNING/FAIL`；
- 原始信道窗口的起点、终点和中心位置。

### 模型样本

```text
inputs : [N_example, N_context, P]
targets: [N_example, N_target,  P]
```

这就是 Step 10 可以直接接收的统一模型张量。

## 3. 外推与内插

外推默认：

```text
已知历史 16 个 → 预测后续 4 个
```

内插默认：

```text
已知左侧 8 个 + 已知右侧 8 个 → 补出中间 4 个
```

两种任务的输入长度都是 16、标签长度都是 4，便于以后通过同一 Predictor
Adapter 调用；但第一版仍分别训练和保存模型文件。

## 4. 创建生成器真值序列

```matlab
addpath(genpath("core"));

values = [
    -8.00, -0.5
    -7.98, -0.4
    -7.96, -0.3
];

sequence = build_generator_truth_parameter_sequence( ...
    values, ["DS_mu", "KF_mu"], struct( ...
        "group_id", ["route-01"; "route-01"; "route-01"], ...
        "bounds", [-9, -7; -10, 20]));
```

生成器真值最适合 Step 10 的泛用模型预训练和自动测试。

## 5. 从上传信道局部拟合参数

```matlab
optimizationConfig = default_optimization_config("lite_6gpcm");

[sequence, details] = build_fitted_parameter_sequence( ...
    channelDataset, optimizationConfig, struct( ...
        "window_length", 16, ...
        "stride", 4, ...
        "parameter_names", ["DS_mu", "KF_mu"], ...
        "group_id", "measured-route-01"));
```

每个连续 16 点信道窗口形成一个参数标签，窗口每次向前移动 4 点。实际使用
Grid 还是 SA 由 Step 8 统一入口决定，序列会明确记录 `grid_fitted` 或
`sa_fitted`。失败窗口不会伪装成正常标签，而会保留为 `FAIL`，下游自动排除。

## 6. 形成模型样本、切分和归一化

```matlab
config = default_predictor_data_config();

dataset = build_predictor_dataset( ...
    sequence, "extrapolation", config);

split = split_predictor_dataset_by_group(dataset, config);

dataset = normalize_predictor_dataset( ...
    dataset, sequence, split, config);
```

切分按照完整 `group_id` 完成。相邻路线点不会被随机拆到训练集和测试集。
Z-score 的均值、标准差只使用训练组计算，验证组和测试组不参与统计。

## 7. 写入 MATLAB/Python 共用 HDF5

```matlab
bundle = struct( ...
    "parameter_sequence", sequence, ...
    "dataset", dataset, ...
    "split", split);

write_predictor_data_hdf5("predictor_data.h5", bundle);
```

为避免误覆盖，目标文件已经存在时函数会拒绝写入。

MATLAB 读取：

```matlab
bundle = read_predictor_data_hdf5("predictor_data.h5");
```

Python 读取：

```python
from read_predictor_data_hdf5 import read_predictor_data_hdf5

bundle = read_predictor_data_hdf5("predictor_data.h5")
print(bundle["inputs"].shape)   # (N_example, N_context, P)
print(bundle["targets"].shape)  # (N_example, N_target, P)
```

## 8. 微调模式在 Step 9 中如何处理

契约提前登记四种模式：

- `pretrain`：泛用模型预训练；
- `auto`：以后自动判断是否适合微调；
- `off`：不使用上传数据微调；
- `force`：高级用户明确要求微调。

Step 9 只记录标签来源和微调候选资格，不武断规定“多少条数据一定能微调”。
Step 10 会通过实验确定阈值和模型行为。

## 9. 标准小样例

仓库中的 `demo_data/v3_step9` 包含：

- `step9_extrapolation_standard.h5`；
- `step9_interpolation_standard.h5`；
- `manifest.json`。

它们由固定公式产生，仅用于接口、形状和可视化审阅，不是真实测量数据，也不是
预测准确度证据。
