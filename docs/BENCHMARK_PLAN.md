# ChanAI Pulse v3.0 独立 Benchmark

## 当前状态

Step 13 已把原来的“未来规划”落实为独立 MATLAB 程序。正式预测平台仍由
`ChannelSimulator.m` 启动；准确度评价由并列入口 `ChannelBenchmark.m` 启动。
两者不会共享目标区真值。

## 两个输入

1. 完整的原始 v3 HDF5 信道文件：Benchmark 从中读取目标区 Ground Truth；
2. `ChannelSimulator` 导出的预测文件夹：至少包含 `predicted_cir.h5`、
   `prediction_result.json`、`generator_manifest.json` 和
   `prediction_manifest.json`。

新导出包带有 `benchmark_context`。它只记录已知区、目标区、任务轴和原输入
维度，不包含目标区真值。旧导出包缺少这段信息时会被严格拒绝，需要重新导出。

## 评价规则

- 先验证任务、目标顺序、Tx/Rx/Nt/Nf、单位、坐标和原文件 SHA-256；
- 只在对齐通过后读取目标区真值并计算指标；
- Persistence 与 Linear 基线只使用已知区；
- `PASS/WARNING/FAIL` 只表示数据是否可公平比较；
- 预测质量用误差和“优于/接近/差于基线”表达，不伪造统一准确率百分比。

基础指标包括 Complex NMSE、幅度 NRMSE、相位 MAE、复相关、PDP NRMSE、
RMS 时延扩展误差和运行时间。空间、角度、时间和多普勒指标根据输入维度逐级
启用，与平台的 1/3/6/9 图能力规则一致。

## 输出

每次导出创建新的时间戳文件夹，绝不覆盖旧结果。内容包括：

- 总表、逐目标表、逐 Tx/Rx 链路表 CSV；
- Markdown 报告；
- 全局指标和逐目标比较 PNG；
- 可追溯 Benchmark Manifest JSON。

PDF、资源占用、跨数据集排行榜和 GRU/LSTM/TCN 正式模型排名留给 Step 14/v3.1。
