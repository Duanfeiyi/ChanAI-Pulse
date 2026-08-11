# v3.1-2：可复现实验语料与 Experiment Manager 最小版

> 状态：已实现并通过 v3.1-2 累计回归，等待项目负责人审阅和手动合并 Draft PR。
> 跟踪：由于当前 GitHub CLI 登录令牌失效，Issue 将在重新登录后创建；本地实现和验证不受影响。

## 目标

本阶段为 v3.1-3～v3.1-6 建立可追溯的公开合成语料和本地实验档案能力。它不训练或排名新模型，不改变 v3.0 CIR/CTF 合同，不修改 Full 6GPCM 核心，也不上传大型语料、缓存、checkpoint 或实验输出。

## 数据语料

`default_v31_2_corpus_config` 定义默认的公开合成语料：

- `120` 个路线组，每路线 `120` 个参数样本；
- Train / Validation / Test 为 `84 / 18 / 18` 路线组；
- 维持冻结的 P2/P4/P6/P8 参数顺序、16/4 上下文/目标长度，以及内插/外推分离；
- 记录场景、中心频率、速度、Tx/Rx 天线数量和路线时长；其中速度和天线数量在 v3.1-2 中仅是路线目录元数据，不是预测器输入，也不改变参数标签；
- 标签由 Full 6GPCM 公共 API 场景配置加确定性路线扰动派生；它们不是实测标签，也不等同于按每组速度和天线配置实际生成的 CIR；
- 内置 Full 6GPCM 核心不被修改。

按速度和 Tx/Rx 天线配置实际运行 Full 6GPCM、生成 CIR/CTF 并评价参数预测影响，属于 v3.1-6 的独立端到端 Benchmark。v3.1-2 不提前宣称具备这项能力。

按完整路线组切分，所有滑窗都只能属于一个分区。训练归一化只能从训练路线计算；Validation/Test 不参与选择或调参。

## 本地资产目录

默认资产目录是仓库同级的：

```text
ChanAI-Pulse-v3.1-assets/
├─ corpora/<corpus-id>/
│  ├─ predictor_bundles/*.h5
│  └─ corpus_manifest.json
└─ experiments/<experiment-id>/
   ├─ experiment_manifest.json
   ├─ status.json
   ├─ logs/
   ├─ reports/
   └─ artifacts/
```

它不在 Git worktree 内。Git 只追踪生成代码、配置、Manifest Schema、小型 fixture、测试和文档。每个语料 HDF5 都由大小和 SHA-256 写入相对路径 Manifest；验证器拒绝绝对路径、`..` 路径和哈希变化。

生成默认本地语料：

```matlab
addpath(genpath(pwd))
asset = create_v31_2_local_assets();
```

已有相同 corpus id 时函数会停止，绝不覆盖。若要使用其他资产根目录：

```matlab
asset = create_v31_2_local_assets("D:\research-assets\ChanAI-Pulse-v3.1-assets");
```

## Experiment Manager 最小版

`create_experiment` 在 Git 外资产目录建立唯一实验目录并写入不可覆盖的 `experiment_manifest.json`。它记录：

- 实验 ID、UTC 创建时间和配置哈希；
- 数据集 Manifest 路径与 SHA-256；
- 当前 Git revision/dirty 状态；
- MATLAB 版本、Release、平台；
- 输出子目录和本地资产策略。

`update_experiment_status` 只允许 `pending → running → completed/failed` 或 `pending → failed`，并保留完整状态历史。`validate_experiment_record` 会验证结构、实验与状态 ID、实验配置哈希，以及已附加数据 Manifest 是否被替换。

## 验证

在仓库根目录运行：

```powershell
matlab -batch "cd('repository-root'); addpath(genpath(pwd)); run('tests/run_v31_2_regression.m');"
```

该回归同时覆盖 v3.1-1 的 bundled Full 6GPCM 回归，以及 v3.1-2 的路线级无泄漏划分、参数语料能力边界、无覆盖资产写入、文件哈希、实验状态迁移、重复实验 ID 拒绝、实验配置篡改和数据 Manifest 篡改检测。

## 非范围

- v3.1-3 的参数敏感度与 P-bundle 冻结；
- v3.1-4 的 GRU/LSTM/TCN 等模型训练与排名；
- v3.1-5 ModelRegistry v2 与上传数据微调；
- v3.1-6 的最终端到端精度结论；
- v3.1-7 的正式 UI；
- v3.2 Time / Space / Frequency 一等任务；
- 私有实测数据和公开泛化结论。
