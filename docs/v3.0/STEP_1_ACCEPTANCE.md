# Step 1 验收清单

> GitHub Issue：[#24](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/24)
>
> 分支：`codex/v3-step-1-data-contract`

## 数据与任务契约

- [x] CTF 顺序固定为 `Tx × Rx × Nf × Nt × N_sample`。
- [x] CIR 顺序固定为 `Tx × Rx × Npath × Nt × N_sample`。
- [x] `N_sample` 固定放在最后。
- [x] 明确区分 `Nt` 与 `N_sample`。
- [x] 路径 CIR 包含复数系数、时延和有效路径标记。
- [x] 定义 SI 单位、坐标轴、样本语义和来源字段。
- [x] 定义内插和外推 `TaskSpec`。

## 接口

- [x] `create_channel_dataset`
- [x] `validate_channel_dataset`
- [x] `create_channel_task`
- [x] `validate_channel_task`
- [x] `infer_channel_capabilities`
- [x] `write_channel_dataset_hdf5`
- [x] `read_channel_dataset_hdf5`
- [x] Python `read_channel_hdf5`

## 本分支验证结果

- [x] MATLAB 数据契约自动测试通过。
- [x] MATLAB HDF5 往返测试通过。
- [x] Python HDF5 读取测试通过。
- [x] MATLAB 写入、Python 读取集成测试通过。
- [x] MATLAB Code Analyzer 检查通过。
- [x] 现有 ChanAIs 数据契约回归测试通过。
- [x] `git diff --check` 通过。
- [x] 需求追踪表更新。
- [ ] Step 1 PR 审阅并合并到 `main`。

详细命令、环境和结果见
[Step 1 验证记录](STEP_1_VALIDATION.md)。

## 不在 Step 1 范围

- 四类完整标准测试数据；
- 正式信道特性计算与绘图；
- 完整版 6GPCM；
- Grid Search 与 SA；
- 预测模型与预测 CIR；
- GUI 改造；
- 预测准确度验证。
