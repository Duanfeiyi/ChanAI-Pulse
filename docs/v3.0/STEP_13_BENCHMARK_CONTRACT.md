# Step 13 独立 Benchmark 数据与评价契约

## 1. 边界

`ChannelSimulator` 负责预测和生成 CIR/CTF，但不读取目标区 Ground Truth，也不
显示准确度。`ChannelBenchmark` 是独立测试程序，只有它可以同时读取完整原始
数据和预测导出包。

## 2. 公平比较的前置条件

Benchmark 必须证明以下内容一致，才允许计算指标：

- 任务类型与任务轴；
- 已知区、目标区以及目标顺序；
- Tx、Rx、Nt；若双方直接比较 CTF，还包括 Nf 和频率轴；
- 时间、频率、时延、位置、角度单位；
- 目标轴坐标；
- 原输入维度与预测时记录的维度；
- 完整原始 HDF5 的 SHA-256 文件身份；
- `target_ground_truth_read_by_prediction=false`。

任何一项不一致都会停止计算，不输出“看似正常”的误差。

## 3. 共同表示

若两边都有同频率轴 CTF，就直接比较复数 CTF。若输入是 CIR，则在同一个明确
频率网格上把两边 CIR 转换为复数 CTF 后比较。这样即使两边路径数量和路径排序
不同，也不会错误地把“第 1 条预测路径”强行对齐“第 1 条真实路径”。

## 4. 指标和能力

| 数据能力 | 增加的评价指标 |
|---|---|
| 所有数据 | Complex NMSE、幅度 NRMSE、相位 MAE、复相关 |
| 宽带/多径 | PDP NRMSE、RMS 时延扩展绝对误差 |
| MIMO/角度 | 空间相关 NRMSE、角度谱 NRMSE |
| 动态时间 | 时间自相关 NRMSE、多普勒谱 NRMSE |

不具备对应维度时，结果为 `NaN/Unavailable`，而不是构造一个数值。

## 5. 基线

- Persistence：为每个目标点复制任务轴上最近的已知点；
- Linear：只用已知点沿任务轴做复数线性插值或外推。

两条基线都不能读取目标区 Ground Truth。预测结果按 Complex NMSE 与两条基线
中较好的一个比较，输出 `BETTER_THAN_BASELINE`、`SIMILAR_TO_BASELINE` 或
`WORSE_THAN_BASELINE`。

默认 App 采用一次快速评估。若生成器随机性需要统计，先独立导出至少两个相同任务
的预测包，再调用 `run_repeated_channel_benchmark`；程序会逐包严格对齐并输出每个
指标的均值、标准差、最小值和最大值，不能把同一次结果冒充多个独立随机实现。

## 6. 状态解释

`PASS` 只表示输入对齐、可以公平评价；它不代表预测准确。质量必须结合多项指标
和基线阅读，不定义没有科学依据的单一“准确率百分比”。
