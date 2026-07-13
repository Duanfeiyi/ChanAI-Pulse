# 信道特性分析拆分说明

本文件记录步骤 4 中从 MATLAB App 外提的非界面计算逻辑。目标是让数据同学可以修改或测试特性分析代码，而不需要触碰 UI 控件、三页布局、训练代码或预测代码。

## 当前数据流

```text
MAT 文件
  -> extract_raw_data
  -> prepare_dpsd_snapshot
  -> analyze_channel_data
  -> Delay PSD / DS CDF / Doppler / Angular Spectrum
  -> App 绘图
```

## 纯函数职责

| 函数 | 输入 | 输出 | 是否访问 GUI |
| --- | --- | --- | --- |
| `extract_raw_data` | 常见 MAT 容器 | 数值数组 | 否 |
| `prepare_dpsd_snapshot` | 原始信道数组、场景、目标长度 | App 使用的 dBm 列向量 | 否 |
| `calculate_angular_spectrum` | 复信道数组 | 角度轴与归一化 APS | 否 |
| `compute_delay_spread` | 时延轴、线性 PDP | RMS Delay Spread | 否 |
| `compute_doppler_spectrum` | 时序信号 | 归一化多普勒显示曲线 | 否 |
| `analyze_channel_data` | DPSD dBm 矩阵、带宽 | 用于绘图的指标结构 | 否 |

## 兼容性原则

- `prepare_dpsd_snapshot` 逐行复现原 App 的 Sub-6、RIS 与其他场景处理分支。
- App 仅将原有内联代码替换为一次函数调用，输出长度和补齐值仍为 `-130 dBm`。
- 本阶段不解释或重排 SAGE CIR 的物理轴；真实数据的轴语义将在后续接入特性分析时由 metadata 明确指定。
- 所有测试均使用内存中的合成数组，不读取、不复制、不提交真实测量数据。

## 验收

运行：

```matlab
run("tests/test_characterization_pipeline.m")
run("tests/smoke_test.m")
```

合并前还需人工打开 App，至少检查数据加载、四类特性图、三页切换及中英文界面。

### 步骤 4 验收记录

- 日期：2026-07-13
- 自动测试：`test_characterization_pipeline.m`、`test_dataset_contract.m`、`test_preprocessing.m` 与 `smoke_test.m` 均通过。
- 人工 GUI 验收：通过。App 打开、三页切换、中英文切换、demo 加载与四类特性图、信道生成、训练与预测页面均正常，无报错。
- 截图和训练产物仅用于本地验收，不作为仓库文件提交。
