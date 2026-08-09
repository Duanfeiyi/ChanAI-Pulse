# Step 13 人工审阅指南

## 一、准备两个输入

在 MATLAB 中执行：

```matlab
close all force
clear classes
rehash
cd("D:\Codex_Feiyi\ChanAI-Pulse-v3-step13")
addpath(genpath(pwd))
paths = prepare_step13_review_data();
```

`paths.original_file` 是完整原始 H5；`paths.prediction_directory` 是正常预测导出
文件夹；`paths.misaligned_prediction_directory` 是故意错位的反例。

## 二、打开正式 Benchmark App

```matlab
app = ChannelBenchmark;
```

第一页按顺序操作：

1. “选择完整原始 H5”，加载 `paths.original_file`；
2. “选择预测导出文件夹”，加载 `paths.prediction_directory`；
3. 点击“检查是否可以公平比较”，应显示 `PASS`、Known=26、Target=6；
4. 点击“开始 Benchmark”。

也可以避免手动浏览路径：

```matlab
app.loadBenchmarkInputs(paths.original_file, paths.prediction_directory)
```

## 三、看什么

第二页检查：

- 顶部四张大卡应突出显示“可比性 PASS”“优于基线”“复数 NMSE”和“复数相关系数”；
- Prediction 的 Complex NMSE 应低于 Persistence 和 Linear；Complex Correlation 应接近 1；
- “基础与时延 / 空间与角度 / 时间与多普勒 / 运行耗时”页签中的每个指标都应独立占据大卡；
- 每张指标卡同时列出 Prediction/Persistence/Linear，并说明越低越好、越接近 1 越好或仅记录耗时；
- 数据维度不支持的指标必须显示“当前数据不支持”，不能显示成 0；
- “完整指标表”仍保留 12 项专业数据；
- 逐目标表有 6 行；
- `PASS` 只代表对齐通过，质量结论应显示 `BETTER_THAN_BASELINE`。

第三页检查：

- 左图是三种方法整体 Complex NMSE，越低越好；
- 右图是逐目标 NMSE；
- 点击“导出完整报告”后，应生成 CSV、Markdown、两张 PNG 和 Manifest；
- 再导出一次应生成另一个时间戳文件夹，不覆盖第一次。

## 四、检查严格拦截

重新加载原始文件和 `paths.misaligned_prediction_directory`。点击检查后必须 FAIL，
“开始 Benchmark”按钮必须保持禁用。此反例证明程序不会拿错位数据硬算准确度。

## 五、中英文

分别选择中文和 English，检查三个页签、按钮和主要说明是否同步切换。

## 人工通过条件

- 正常包可以评价，错位包不能评价；
- 1/3/6/9 能力不会出现不支持指标；
- 指标、基线和质量结论能看懂；
- 报告可打开、可追溯且不覆盖；
- App 与 `ChannelSimulator` 完全独立。
