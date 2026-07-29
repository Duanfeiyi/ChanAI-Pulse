# Step 4 模块一输入流水线接口指南

## 1. 作用

Step 4 把一个 v3 标准 HDF5 读成统一 CIR/CTF 数据，执行数据与任务验证，并返回：

```text
dataset + task + validation + capabilities + provenance
```

正式输入函数不修改原文件，不负责 Step 5 的信道特性计算，也不接入正式 UI。

## 2. MATLAB 路径

```matlab
repoRoot = "ChanAI-Pulse 仓库目录";
addpath(genpath(fullfile(repoRoot, "core")));
```

## 3. 80/20 内插

```matlab
options = struct( ...
    "task_mode", "interpolation", ...
    "task_axis", "sample", ...
    "task_preset", "80_20");

result = import_channel_dataset("channel.h5", options);
```

内插预设把中间约 20% 作为目标区，已知区位于两侧。

## 4. 80/20 外推

```matlab
options = struct( ...
    "task_mode", "extrapolation", ...
    "task_axis", "sample", ...
    "task_preset", "80_20");

result = import_channel_dataset("channel.h5", options);
```

外推预设把前约 80% 作为已知区，最后约 20% 作为目标区。

## 5. 手动任务

```matlab
options = struct( ...
    "task_mode", "interpolation", ...
    "task_axis", "sample", ...
    "task_preset", "manual", ...
    "known_indices", [1:40, 61:100], ...
    "target_indices", 41:60);

result = import_channel_dataset("channel.h5", options);
```

允许的任务轴：

```text
sample, position, time, frequency
```

数据不具备相应物理轴时，任务返回 FAIL。例如 `Nt=1` 不能进行 time 外推。

## 6. 返回结构

```matlab
result.status
result.dataset
result.task
result.validation
result.capabilities
result.provenance
result.file
```

### `result.validation`

```matlab
result.validation.status
result.validation.is_valid
result.validation.errors
result.validation.warnings
result.validation.file
result.validation.dataset
result.validation.task
```

状态：

- `PASS`：文件、数据和任务均合格；
- `WARNING`：数据可用，但存在缺失的可选信息或尚未设置任务；
- `FAIL`：阻止进入后续模块。

### `result.provenance`

只记录文件名、格式、大小、数据来源和导入时间，不把个人计算机绝对路径写入数据集：

```matlab
result.provenance.source_file_name
result.provenance.source_format
result.provenance.source_bytes
result.provenance.dataset_source
result.provenance.imported_utc
result.provenance.read_only_import
result.provenance.original_file_unchanged
```

## 7. 文件预检

```matlab
report = inspect_channel_input_file("candidate.h5");
```

已识别类别包括：

```text
v3_channel_hdf5
legacy_wifo_hdf5
legacy_sage_mat
power_feature_mat
model_feature_mat
non_v3_hdf5
unsupported_file_format
```

预检只读，不把任意 MAT 中的第一个数值变量猜成信道。

## 8. SAGE 文件夹转换

```matlab
options = struct( ...
    "bandwidth_hz", 200e6, ...
    "record_index", 1, ...
    "sample_semantics", "ordered_route", ...
    "source_id", "road_1");

result = convert_sage_folder_to_v3_hdf5( ...
    "SAGE文件夹", ...
    "road_1_v3_cir.h5", ...
    options);
```

必须提供：

```text
bandwidth_hz
```

或者：

```text
delay_bin_spacing_s
```

Converter 不猜测时延网格，不覆盖已存在输出。首版只映射固定 `sage.cir` tap grid；`alpha/doa/dod` 在单位和路径约定确认前不自动映射。

`max_files` 可用于制作小型审阅文件：

```matlab
options.max_files = 20;
```

## 9. WiFo 旧 HDF5 转换

按有序样本解释第四维：

```matlab
options = struct( ...
    "sequence_axis", "sample", ...
    "sample_semantics", "other_ordered");

result = convert_legacy_wifo_hdf5_to_v3( ...
    "3D_CSI_01.h5", ...
    "3D_CSI_01_v3_cir.h5", ...
    options);
```

按连续时间解释第四维：

```matlab
options = struct( ...
    "sequence_axis", "time", ...
    "snapshot_interval_s", 1e-3);
```

必须明确 `sample` 或 `time`，Converter 不根据文件名猜测。

## 10. 独立体验 Demo

```matlab
addpath("examples");
step4_ingestion_demo
```

Demo 支持文件选择、内插/外推、四类任务轴、80/20 预设、手动索引、状态报告、能力表和任务区域示意图。

它不修改 `ChannelSimulatorApp`；正式 UI 接入仍属于 Step 12。
