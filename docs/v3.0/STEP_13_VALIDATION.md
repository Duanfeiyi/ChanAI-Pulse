# Step 13 自动验证记录

## 已覆盖内容

- 正常预测包严格对齐并完成评价；
- 目标顺序被故意修改时，在计算指标前拒绝；
- Persistence 与 Linear 仅使用已知区；
- Complex NMSE、幅度、相位、复相关、PDP、时延扩展与运行时间；
- 空间/角度/时间/多普勒能力指标；
- 总体、逐目标、逐链路结果；
- 两个不同固定种子的独立导出包可聚合均值/标准差，重复路径会被拒绝；
- CSV、Markdown、PNG、Manifest 时间戳导出；
- `ChannelBenchmark` 隐藏界面自动测试；
- 指标页核心结论卡、分组大指标卡、完整表格和逐目标表均可实例化并随中英文重绘；
- 四套标准数据的 1/3/6/9 能力对应关系。
- Step 12 四类正式端到端预测导出均包含目标真值隔离标记和原始 HDF5 SHA-256。

## 自动测试入口

```matlab
cd("D:\Codex_Feiyi\ChanAI-Pulse-v3-step13")
addpath(genpath(pwd))
run("tests/test_step13_benchmark.m")
run("tests/test_step13_dimension_capabilities.m")
```

预期结尾：

```text
PASS: Step 13 Benchmark core, baselines, strict alignment, reports and UI.
PASS: Step 13 metrics follow the 1/3/6/9 capability classes.
PASS: Step 13 focused regression suite.
```

2026-08-09 追加验证：`ChannelBenchmarkApp.m` Code Analyzer 为 0 条消息；完整
`run_step13_regression` 通过。另用公开固定夹具导出指标页截图，人工检查卡片未溢出、
指标文字可读、专业表格仍可访问；截图仅作本地临时审阅，不进入仓库。

公开审阅样例采用固定随机种子和轻微确定性扰动，只用于证明 Benchmark 能正确
识别好结果、基线和错位输入，不作为平台真实预测精度结论。
