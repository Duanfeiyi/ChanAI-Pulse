# v3.1-0：v3.0.0 可比较基线冻结

> 状态：等待项目负责人审阅并手动合并 Draft PR。
>
> 跟踪：[Issue #65](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/65)
>
> 本文只冻结 v3.1 实验的对照，不改变 v3.0.0 产品合同、正式 UI 或模型选择。

## 1. 唯一正式对照

| 项目 | 冻结值 |
|---|---|
| 发布 Tag | `v3.0.0` |
| 基线提交 | `e43e4c94db0a276ba6e9eab2b4d683eb7d089318` |
| 正式版本 | `3.0.0` |
| 发布页 | <https://github.com/Duanfeiyi/ChanAI-Pulse/releases/tag/v3.0.0> |
| 起始分支 | `codex/v3.1-0-baseline` |
| 基线工作区 | `D:\Codex_Feiyi\ChanAI-Pulse-v3.1-0` |

任何 v3.1 模型、参数包、生成器或 Benchmark 改动都必须与本表的基线比较。不得以旧分支、未发布
提交、不同测试划分或目标区域 Ground Truth 作为对照来宣称提升。

## 2. 冻结的产品行为

v3.0.0 正式产品的自动选择不是 Step 10 的小型 fixture 模型注册表，而是经 Step 11ABC 多路线验证
后冻结的安全基线：

| 任务 | 正式参数包 | 正式自动模型 | 目标区真值 |
|---|---|---|---|
| 外推 | P6 | Persistence | 不读取 |
| 内插 | P8 | Persistence | 不读取 |

参数包的固定顺序为：

```text
P2 = DS_mu, KF_mu
P4 = P2 + DS_sigma, KF_sigma
P6 = P4 + r_DS, LNS_ksi
P8 = P6 + num_clusters, num_rays
```

`ChannelSimulatorV3App` 只允许 Persistence 进入 v3.0 正式预测链路。GRU、LSTM 和 TCN 的 Step 10
fixture 注册表及其参考权重只能证明接口可调用，不能作为 v3.0 生产模型或 v3.1 提升证据。

## 3. 数据、划分和模型准入规则

| 项目 | 冻结值 |
|---|---|
| 路线组数量 | 40 |
| 每路线样本数 | 120 |
| 划分 | 30 / 5 / 5 路线组 Train / Validation / Test |
| 生成器路线随机种子 | `11011` |
| 上下文 / 目标长度 | 16 / 4 |
| 支持任务 | 内插、外推，分别训练和验证 |
| 标签来源 | Full 6GPCM 公共 API 的生成器真值 |
| 外部/实测数据 | 仅本地独立验证，不进入公开训练集或 Git |

第一版神经网络准入门槛保持不变：平均 NRMSE 至少比最佳简单基线改善 10%；至少在 60% 的验证
路线胜出；任一路线误差不得超过基线 2 倍；多随机种子稳定；并通过参数到 CIR/CTF/特性的端到端
验证。最终 Test 只评分，不能用于挑模型或调参。

## 4. 冻结的合同与系统边界

- 数据合同：`v3.0-data-contract.1`；
- MAT 检查、映射和转换 Manifest：`v3.0-mat-inspection.1`、`v3.0-mat-conversion-mapping.1`、`v3.0-mat-conversion-manifest.1`；
- 预测结果与 Benchmark：`v3.0-prediction-result.1`、`v3.0-benchmark-result.1`；
- 产品预测只使用已知区；目标区域 Ground Truth 只由软件外部 `ChannelBenchmark` 在最终评分时读取；
- 正式模块三不显示 Ground Truth、RMSE、NRMSE、准确率或模型排名；
- Lite/Full 6GPCM 按候选逐一做兼容性和可用性检查；所有候选均失败才报错；
- Full 6GPCM 在 v3.0 基线仍是外置只读依赖，核心未重新分发、不得修改。

## 5. 基线证据

### 5.1 环境快照

2026-08-11 在干净 worktree 生成：

```text
review_data/v3_1_0/v3_0_0_baseline_environment_precheck.json
```

该 Git 忽略文件记录：`product_version=3.0.0`、`git_revision=e43e4c94...`、`git_dirty=false`、
MATLAB R2024b Update 1，以及外置 Full 6GPCM entry hash：

```text
92f60ea6539c6bd1d705296a662fc78715bbd65f91668ff7c93978232b73967f
```

候选 Full 6GPCM 源 ZIP 的既有资产清单为
`docs/v3.0/manifests/full_6gpcm_step3_asset.json`；其 ZIP SHA-256 为：

```text
fcf151adf94038a6cf10d86c6dd687938b085a8f78a64d6829b5439c1d6c5875
```

### 5.2 回归结果

在上述 worktree 运行：

```powershell
matlab -batch "cd('D:\Codex_Feiyi\ChanAI-Pulse-v3.1-0'); addpath(genpath(pwd)); run('tests/run_step14_regression.m');"
```

结果通过，覆盖：

- Step 14 MAT 检查、显式映射、转换、源文件保护和向导合同；
- Step 12 正式入口和目标真值隔离；
- Step 13 Benchmark、严格对齐、Persistence/Linear 基线、报告和 UI；
- 四套标准 fixture 的 1/3/6/9 能力；
- Step 14 聚焦回归。

这项回归验证 v3.0 平台合同仍可复现；它不是对真实多场景预测精度的科学结论。v3.1-2 至
v3.1-6 将建立新的路线级数据、模型比较和独立端到端 Benchmark。

### 5.3 本地冻结的多路线端到端摘要

以下数字来自既有的本地 Full 6GPCM 生成器真值实验资产；只在这里保存小型摘要，不复制训练语料、
checkpoint、CSV 对或大型实验输出到 Git。系统注册表状态为 `frozen_and_tested`，模型选择只使用
Validation，最终 Test 未参与选择。

| 任务 | 冻结参数包 | 冻结模型 | Test 路线数 | 参数 NRMSE 均值 | PDP NRMSE 均值 |
|---|---|---|---:|---:|---:|
| 外推 | P6 | Persistence | 5 | 0.06506503 | 0.04302913 |
| 内插 | P8 | Persistence | 5 | 0.01728673 | 0.06708091 |

选择阶段的 PDP NRMSE 分别为外推 P6 `0.01070015`、内插 P8 `0.00022462`。两项选择都采用
“验证集上在最优结果 5% 内的最小参数包”规则；相关神经网络没有通过全部安全门槛，因此系统注册表
明确记录 `baseline_fallback_no_neural_candidate_passed_all_safeguards`。

上述摘要是 v3.1 的比较起点，不是对私有实测数据的结论，也不能被解释为后续任意数据集上的通用精度。

## 6. 已知记录差异

v3.0.0 发布 Manifest 的 `key_file_hashes` 中，以下历史路径已不存在：

```text
core/prediction/create_calibrated_persistence_prediction.m
```

正式实现实际位于：

```text
core/prediction_generation/create_calibrated_persistence_prediction.m
```

因此旧 Manifest 将该键记录为 `missing`。这不影响已发布 v3.0.0 的代码或本次 Step 14 回归；
但 v3.1 后续 Manifest 工具必须使用实际路径，并把此差异作为历史兼容记录，而不是误报为代码缺失。

## 7. v3.1-0 完成条件

- [x] `v3.0.0` Tag、Release、提交和最终环境快照已核对；
- [x] 新 worktree 从正式 Tag 建立，且初始 `git_dirty=false`；
- [x] Step 14 聚焦回归在新 worktree 通过；
- [x] P6/P8 Persistence、数据隔离、参数顺序、生成器和 Benchmark 边界已记录；
- [x] Full 6GPCM 外置资产的 ZIP/入口哈希及“未重新分发”状态已记录；
- [ ] 项目负责人审阅并手动合并本 Draft PR；
- [ ] 该 PR 合并后，启动 v3.1-1 的许可证证据审计与完整入库准备。

## 8. 非范围

本阶段不复制 Full 6GPCM、不修改其核心、不训练新模型、不接入 QuaDRiGa、不实现 Nt/Nf 内部目标
生成，也不上传私有实测数据、缓存、大型训练资产或实验输出。
