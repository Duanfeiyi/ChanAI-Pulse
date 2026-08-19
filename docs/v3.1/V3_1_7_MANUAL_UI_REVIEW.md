# v3.1-7 PR 前人工 UI 验收指南

> 本指南验收真实 P8、任意长度、Hybrid、双向内插、手动模型警告、生成和导出。已知区回测不是目标区准确率；正式精度仍由独立 `ChannelBenchmark` 验证。

## 1. 启动准备

只使用 v3.1-7 干净工作树。在 MATLAB 执行：

```matlab
close all force
clear classes
rehash

cd("D:\Codex_Feiyi\ChanAI-Pulse-v3.1-7")
addpath(genpath(pwd))
% 可省略；App 会自动寻找已安装 PyTorch 的环境
setenv("CHANAI_STEP10_PYTHON", ...
    "D:\Codex_Feiyi\ChanAI-Pulse-v3.1-assets\runtime\v31_4\.venv\Scripts\python.exe")
app = ChannelSimulator;
```

预期：标题 `ChanAI Pulse v3.1.0-rc.1`；普通模式、中文；三个主页签齐全。未设置环境变量时，App 会检查项目 `.venv`、同级 v3.1 assets 环境，再检查能实际启动的系统 Python。

## 2. A：普通模式自动 Hybrid（必测）

1. 选择 `demo_data/v3_standard_fixtures/wideband_static_siso_cir.h5`；
2. 选择“外推：已知 → 未来”“样本”“自动 80/20”；
3. 点击“加载、验证并分析”；
4. 确认已知索引 1～26、目标 27～32，预检为 6GPCM-Lite；
5. 点击“开始预测”，完成后进入“3. 预测结果”并收起进度。

预期：

- 总模型显示 `hybrid`；逐参数约为 `DS_mu=harmonic, KF_mu=ar, num_clusters=persistence`；
- 已知区回测为 5 个 6-step 窗口，所选 NRMSE 约 `0.0111`；
- 蓝线显示全部 26 个已知点，不只显示最后 16 个；
- DS、KF 橙线延续曲线趋势，不再水平冻结，也不应出现最初截图的无规律大幅跳点；
- 图标题分别显示 `DS_mu · HARMONIC`、`KF_mu · AR`；
- 连续性可能显示 WARNING（当前约 `3.193 / 3.0`），但 6 个目标 CIR 正常生成并可导出；
- 页面明确目标区 Ground Truth 未读取，不声称“目标区准确率”。

## 3. B：高级模式模型列表（必测）

切到高级模式和“高级用户手动选择”，展开列表。

预期共有 12 个候选：Persistence、Linear、Quadratic Trend、Holt Damped Trend、Harmonic/Fourier、Adaptive AR、Kalman、GRU、LSTM、TCN、DLinear、NLinear。后五项仍标为实验候选，不保证最优。

## 4. C：手动 Persistence 的性能警告（必测）

1. 保持 1～26 → 27～32；
2. 手选 Persistence、CPU、关闭适配；
3. 点击“执行预测并生成 CIR”。

预期：

- 仍生成 6 个目标，模型保持 Persistence，不静默改成 Hybrid；
- 橙线保持最后已知值，这是算法定义，不是程序错误；
- 若其已知区回测弱于本地最佳基线，状态显示 WARNING 并写明原因；
- 导出仍可用。

## 5. D：GRU 任意目标长度滚动（必测）

1. 保持原 6 目标任务；
2. 手选 GRU（实验）、CPU、关闭适配；
3. 执行预测。

预期：

- 不再因“目标不是 4 个”被拒绝；
- 生成恰好 6 个目标，模型仍为 GRU；
- 状态/Manifest 提示旧 checkpoint 原生 16→4，本次用了滚动兼容，长 horizon 误差可能累积；
- 若 GRU 已知区回测出现极端退化，只显示 WARNING，不拒绝；逐参数文字应出现 `gru+local_guard(...)`，并明确这是保留 GRU 权重的透明稳定融合，不是静默替换；
- 当前公开样例经过 guard 后的 KF 橙线应大致在 `1.2～1.5 dB`，不能再出现原先 raw GRU 的 `-1～-3 dB` 大幅偏移；
- 结果不得包含多余的第 7、8 点。

## 6. E：已知点多于 16 时全部使用（必测）

1. 选择“精确手动范围”；
2. 已知区填 `1:28`，目标区填 `29:32`；
3. 普通模式运行。

预期：蓝线显示全部 28 个已知点；Manifest 的 `known_context_parameters` 有 28 行。旧 checkpoint 可在内部取最近 16 点，但自动回测、趋势候选和图表不能丢掉前 12 点。

## 7. F：8 点任意内插（必测）

1. 精确手动范围；任务改为“内插：两侧 → 中间”；
2. 已知区填 `1:12,21:32`，目标区填 `13:20`；
3. 手选 Harmonic/Fourier、CPU、关闭适配并运行。

预期：

- 成功生成 8 个目标；
- 蓝线左右两段合计 24 个点，橙线填在中间缺口；
- 橙线同时与左右边界衔接，不是只从左侧盲目外推；
- 模型保持 Harmonic，不静默替换；
- Manifest 记录双向预测/融合语义和目标真值未读取。

## 8. G：硬错误才拒绝（必测）

在精确范围中故意让已知区和目标区重叠，例如已知 `1:26`、目标 `26:32`，重新加载。

预期：模块一明确拒绝索引重叠，模块三不运行且没有旧 CIR/导出残留。这类任务合同错误才属于硬拒绝。

## 9. H：导出 Manifest（必测）

回到成功的普通 Hybrid 结果，导出到空目录，确认至少包含：

- `predicted_cir.h5`
- `predicted_ctf.h5`
- `prediction_result.json`
- `prediction_manifest.json`
- `generator_manifest.json`

`prediction_manifest.json` 应包含：

- `selection.selected_model = "hybrid"`；
- `selection.selected_model_by_parameter`；
- `selection.target_ground_truth_read_for_selection = false`；
- `target_region_channel_samples_read = false`；
- `backtest.example_count = 5`、`backtest.contract`、各候选逐参数分数；
- `continuity.effect = "warning_only"`；
- `known_context_parameters` 共 26 行；
- 3 个局部观测字段、5 个冻结字段；
- `known_region_extraction.provenance.source = "known_region_direct_channel_observables"`；
- `warnings` 和范围/整数投影记录。

不得出现 `repeated_aggregate_p8_calibration`，也不得声称读取目标真值选模。

## 10. I：英文与布局（必测）

切换 English，查看三个主页、12 模型列表、Hybrid 摘要、WARNING 和两张参数图；缩小再放大窗口。

预期：关键文字可理解；`DS_mu`、`KF_mu`、CIR、CTF 等科学符号保持；控件不重叠，按钮不被截断。

## 11. J：运行环境故障（可选）

把 `CHANAI_STEP10_PYTHON` 临时设为不存在路径，并确保没有其他可发现环境后重启 App。

预期：模块三明确停止，不绕过 Python 预测器，不保留上一轮 CIR。恢复路径后重启即可。

## 12. 反馈格式

```text
A 普通模式自动 Hybrid：通过 / 不通过
B 高级模式 12 模型列表：通过 / 不通过
C 手动 Persistence 警告但生成：通过 / 不通过
D GRU 六目标滚动：通过 / 不通过
E 全部已知点均显示/登记：通过 / 不通过
F 8 点双向内插：通过 / 不通过
G 重叠索引硬拒绝：通过 / 不通过
H CIR/CTF/Manifest 导出：通过 / 不通过
I English 与布局：通过 / 不通过
J Python 故障停止（可选）：通过 / 未测试 / 不通过
其他现象：
```

A～I 全通过后，方可授权提交、push 和创建 PR。PR 仍由项目负责人手动审阅合并；Codex 不创建 Tag 或 GitHub Release。
