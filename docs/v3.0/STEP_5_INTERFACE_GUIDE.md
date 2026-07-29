# Step 5 统一信道特性接口指南

## 1. 主接口

```matlab
analysis = analyze_channel_characteristics(dataset)
```

带任务：

```matlab
analysis = analyze_channel_characteristics(dataset, ...
    Task=task, Region="known", ModuleRole="input");
```

审阅完整标准数据：

```matlab
analysis = analyze_channel_characteristics(dataset, Region="all");
```

`Region="known"` 是正式任务默认值。有任务时只分析已知区域；没有任务时
等价于分析当前数据全部可用区域。

## 2. 输入

### dataset

符合 `v3.0-data-contract.1` 的单个 CIR 或 CTF `ChannelDataset`。

### Task

可选 `ChannelTask`。由 Step 1/4 的任务接口创建并验证。

### Region

```text
known | all
```

### ModuleRole

```text
input | prediction | review
```

该字段只记录调用来源，不改变计算公式。相同数据在模块一和模块三必须得到
相同结果。

## 3. 输出

```matlab
analysis.status
analysis.classification
analysis.dataset_summary
analysis.selection
analysis.metrics
analysis.registry
analysis.warnings
analysis.errors
analysis.provenance
```

每项 metric 统一包含：

```matlab
metric.id
metric.title_zh
metric.available
metric.reason
metric.kind
metric.x
metric.y
metric.z
metric.x_unit
metric.y_unit
metric.z_unit
metric.series_labels
metric.aggregation
metric.normalization
metric.summary
metric.warnings
```

## 4. 图表注册表

`analysis.registry` 决定：

- 标准特性是否可用；
- 所属基础/空间/时间类别；
- 是否计入 1、3、6、9；
- 是否为附加图；
- 不支持原因；
- 对应 metric。

绘图器只读取注册表和 metric，不根据维度重新猜测能力。

界面应通过统一选择函数取得可见图：

```matlab
entries = select_channel_plot_entries(analysis.registry);
```

- 四类标准组合：只返回可用标准图和附加图；
- 非标准组合：返回科学上可用的图，但
  `registry.is_standard_classification = false`，不声明 `x/10`；
- `registry.available_plot_count` 只表示内部可计算数量，不等于四类标准界面数量。

## 5. 单图绘制

```matlab
render_channel_characteristic(ax, analysis, "pdp");
```

如果图不可用，axes 显示不支持原因，不生成占位数据。

## 6. 错误行为

- 非法数据合同：`analysis.status = "FAIL"`；
- 缺少某项元数据：数据可以 PASS/WARNING，但该 metric 不可用；
- CDF 样本较少：metric 可用并携带 WARNING；
- 不均匀时间轴：多普勒和时间自相关不可用；
- SISO或缺少角度/阵列几何：角度图不可用；
- MIMO 只有一次有效观测：空间相关不可用；
- 函数不修改输入 dataset 和原文件。

## 7. Demo 导出

第一页 Demo 的“导出结果”只写出新的 MAT：

```matlab
exportBundle.analysis
exportBundle.task
exportBundle.dataset_summary
exportBundle.exported_utc
```

该结构由 `create_step5_export_bundle(analysis, task)` 统一生成，并带有
`schema = "chanai-pulse-step5-export-v1"`。它不把原始大数组复制进导出包，
不修改上传的 HDF5。已存在目标文件必须由用户明确确认后才能覆盖。
