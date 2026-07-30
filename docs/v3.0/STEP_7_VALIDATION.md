# Step 7 自动验证记录

## 1. 环境

- 日期：2026-07-30
- MATLAB：R2024b
- 数据契约：`v3.0-data-contract.1`
- Generator Adapter：`v3.0-step6.1`
- Grid Search：`v3.0-step7.1`
- 外置 Full 6GPCM：只读调用

## 2. 核心 Grid Search

```text
PASS: Step 7 deterministic Cartesian Grid Search and safeguards.
```

已经验证：

- 2×3 候选空间准确产生 6 个唯一组合；
- 枚举顺序、候选 ID、分数和排名可重复；
- 重复值、空空间、未知参数、非整数簇数和 529 个超限候选提前失败；
- Mock 目标的真实参数组合得到第 1 名和 0 分；
- 只保留 Top 5 完整生成结果，但保留全部候选分数和 Manifest；
- 改写内插任务的 target 区域不会改变搜索结果；
- 一个候选生成失败时，其余候选仍继续并得到最佳结果；
- 预先取消不会产生完整或正式结果；
- 本机外置根目录不会进入公开配置或 Manifest。

## 3. 6GPCM-lite

```text
PASS: Step 7 6GPCM-lite Grid Search smoke.
```

使用小型确定性目标和候选网格，真实经过 Lite Generator Adapter 生成 CIR、
Step 5 特性计算和 Step 7 评分。真实参数组合得到最低分。

## 4. 真实外置 Full 6GPCM

```text
PASS: real Full 6GPCM Step 7 two-candidate Grid Search.
```

验证两个 `DS_mu` 候选：

- 真实 Full 后端成功执行；
- 已知目标参数得到最低分和 0 分；
- 每个保留候选均报告 Full 核心调用前后未变化；
- 外置根目录未进入公开结果。

## 5. 静态检查

对 Step 7 新增、修改的核心、测试和 Demo MATLAB 文件运行 R2024b
Code Analyzer：

```text
CHECKCODE_MESSAGES=0
```

## 6. Demo 与审阅图

```text
PASS: Step 7 interactive demo smoke.
PASS: Step 7 default Lite 27-candidate UI smoke.
PASS: Step 7 Mock/Lite/Full review sheet exported.
```

已经实际运行默认 Lite 的 27 个候选，并确认：

- 最佳候选为网格中预设目标参数，分数为 0；
- Top 5、PDP、时延扩展分布和事件日志成功渲染；
- 修改候选输入会重新计算候选总数；
- 汇总图中的 Mock、Lite 和真实 Full 均执行成功。

## 7. Step 1～7 完整回归

```text
PASS: v3 CIR/CTF data, task, capability, and HDF5 contracts.
PASS: four deterministic v3 standard CIR/CTF fixture pairs.
PASS: Step 3 full 6GPCM probe contract and error paths.
PASS: Step 4 input pipeline, task presets, and legacy adapters.
PASS: Step 5 unified characteristics, registry, and renderer.
PASS: 6GPCM-lite generator produces deterministic synthetic channel tensors.
PASS: Step 6 shared Generator Adapter contract and error paths.
PASS: real full 6GPCM Step 6 Adapter and core-integrity check.
PASS: Step 7 deterministic Cartesian Grid Search and safeguards.
PASS: Step 7 6GPCM-lite Grid Search smoke.
PASS: real Full 6GPCM Step 7 two-candidate Grid Search.
```

早先在受限沙箱内直接启动 MATLAB 时出现一次启动层
`System Error: File system inconsistency`。改用允许的 MATLAB 批处理执行环境后，
Demo、图片导出和完整回归均已成功，因此该环境问题不再阻塞 Step 7。

## 8. 当前结论

本地实现、专项测试、真实 Full 只读验证、完整回归、静态检查、可视化导出和
项目负责人人工审阅均已通过。项目负责人已经允许提交、push 并创建 PR。
