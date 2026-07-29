# Step 3 自动验证记录

> 验证日期：2026-07-29
>
> MATLAB：R2024b Update 1
> 分支：`codex/v3-step-3-full-6gpcm-spike`

## 1. Step 3 项目自有探针测试

```text
PASS: Step 3 full 6GPCM probe contract and error paths.
```

覆盖：

- 项目自有假引擎；
- 固定种子重复运行；
- 原始到统一 CIR 转换；
- 缺少外置目录；
- 非法参数；
- 调用前后测试替身文件树不变。

## 2. 真实完整版 6GPCM 冒烟测试

```text
PASS: real full 6GPCM headless probe and canonical CIR conversion.
```

确认：

- MATLAB `-batch` 无界面调用成功；
- 原始单样本尺寸 `[2,2,2,240]`；
- 统一 CIR 尺寸 `[2,2,240,2,1]`；
- 系数为有限复数；
- delay 为有限、非负秒；
- 输出通过 Step 1 数据契约；
- 核心文件树没有改变。

## 3. 真实固定种子复现

```text
PASS: real full 6GPCM fixed-seed output is exactly repeatable.
```

使用相同参数和随机种子 `3103` 连续调用两次，以下数组逐元素完全相同：

- `H_all`；
- `delay_all`；
- 统一 `cir.coefficient`；
- 统一 `cir.delay_s`。

## 4. 真实三样本审阅输出

```text
raw shape:       3 × [2,2,2,240]
canonical shape: [2,2,240,2,3]
delay range:     8.506 ns ～ 126.501 ns
core unchanged:  true
```

外置临时结果：

```text
full_6gpcm_probe_cir.h5
full_6gpcm_probe_summary.json
```

仓库只保存小型技术审阅 PNG，不保存真实 HDF5 或第三方核心。

## 5. Python 读取真实 HDF5

```text
PASS: Python read real Step 3 HDF5 shape (2, 2, 240, 2, 3)
dtype complex128
```

说明 MATLAB 写出的真实 CIR 可由 Step 1 Python 读取器按相同五维顺序恢复。

## 6. 回归测试

通过：

- Step 1 CIR/CTF、任务、能力和 HDF5 契约；
- Step 2 四套确定性标准 CIR/CTF；
- 6GPCM-lite；
- 历史 dataset contract；
- 时间顺序切分与预处理；
- 信道特性计算与绘图；
- 信道生成绘图；
- 预测实验、TCN/LSTM/GRU 和预测绘图；
- App 运行路径；
- MATLAB 基础环境 smoke test；
- 5 项 Python 单元测试。

MATLAB Code Analyzer：

```text
CHECKCODE_MESSAGES=0
```

## 7. 环境跳过项

以下两个旧测试依赖未进入干净 Git 工作树的本地测量归档：

```text
tests/test_measured_dataset_probe.m
tests/test_real_data_validation.m
```

缺少目录：

```text
datasets/measured/raw_archives
```

因此本次没有把它们标记为通过。这是既有私有测试数据缺失，不是 Step 3 功能失败；Step 3 没有修改这些测试或测量数据流程。
