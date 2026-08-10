# ChanAI Pulse v3.0.0 Release Notes

## 本次正式版的核心成果

ChanAI Pulse v3.0 把早期分散的演示代码整理成两个职责分离的正式入口：

- `ChannelSimulator`：导入、任务设置、能力驱动特性图、模块二后台标定、模块三参数预测、6GPCM 生成和 CIR/CTF/Manifest 导出；
- `ChannelBenchmark`：在软件外部读取原始完整信道和预测导出，独立评价准确度。

正式平台支持四类信道维度对应的 1/3/6/9 张标准特性图，并在有多样本时提供可选时延—样本功率热力图。模块一和模块三共用同一能力规则。

## Step 14 新增

1. 模块一正式 MAT 转换向导：MAT v7/v7.3、复数变量、实/虚部配对、显式维度映射、SAGE 文件夹和旧 WiFo HDF5；
2. 输出新标准 H5 和独立转换 Manifest，验证源文件哈希不变且禁止覆盖；
3. 大型 v7.3 数据按 `N_sample` 分块读取，标准 H5 数值按块写入；
4. 主流程、模块二和 MAT 转换统一使用横向填充式进度条；
5. 更新中文/英文展示、用户指南、测试、发布检查和基线 Manifest 工具；
6. 完成 Step 1–13 的累计回归，保持 Benchmark 与预测界面职责隔离。

## 冻结的 v3.0 产品边界

- 自动模型：Persistence；
- 参数包：P6/P8 工程基线；
- 正式目标任务：样本/位置轴内插与外推；
- 生成器：6GPCM-Lite 与外置 Full 6GPCM Adapter 的逐候选兼容性选择；
- 准确度：只在独立 `ChannelBenchmark` 展示；
- GRU/LSTM/TCN 自动准入、泛用模型预训练和上传数据安全微调：进入 v3.1；
- QuaDRiGa 正式注册、时间/频率目标生成和更多参数包：后续版本。

## 发布说明

`v3.0.0` 是本次正式源码版本。PR #62 已于 2026-08-09 由 `Duanfeiyi` 手动合并到
`main`，合并提交为 `d74157e86e59238c6345418439e922a687bc44ce`。GitHub `v3.0.0`
Tag/Release 仍必须在下列最终动作完成后，由项目负责人手动创建：

1. Step 14 人工验收通过；
2. PR 由 `Duanfeiyi` 手动合并；
3. 合并后的文档收尾 PR 由 `Duanfeiyi` 手动合并；
4. 在最终干净 `main` revision 上重新生成基线 Manifest；
5. 项目负责人明确批准发布。

Codex 不会自行合并 PR 或创建正式发布 Tag。
