# v3.2-1：Time / Frequency 数据合成协议 —— 设计稿（讨论稿）

> 状态：**设计稿，尚未冻结、尚未入库**。本文用于固化 v3.2-1（三维数据集）中
> Time / Frequency 两轴数据合成的协议设计，供项目负责人审阅。审阅通过后才写生成
> 脚本并实际生成数据；本稿在此之前不提交、不建 PR。
>
> 依赖：v3.2-0 合同（已冻结，PR #77）。Space 轴数据由 v3.1 语料直接复用，不在本稿。

---

## 0. 核心事实与结论

| 事实 | 来源 | 结论 |
|---|---|---|
| Full 6GPCM 公共 API 只产出 CIR（时延域），不产出 CTF | `run_full_6gpcm_public_api_adapter.m` | Time 数据直接产出；Frequency 数据需 CIR→FFT 得 CTF |
| CIR→CTF 已有现成函数 `cir_to_ctf.m` / `create_ctf_dataset_from_cir.m` | 已读源码 | Frequency 数据复用，不新写 FFT |
| Full 6GPCM 支持 `Nt > 1` 时 rx 走 `track('linear')`，产出带多普勒的时间演化 | adapter 第 121~127 行 | Time 数据主路径已通 |
| v3.1 语料生成器 `generate_step11abc_full_route.m` 已能产"一条路线多时刻" | 已读源码 | 有成熟模板可复用 |

**一句话**：Time 数据 = Full 6GPCM 直接产出（现成）；Frequency 数据 = Full 6GPCM 产 CIR
+ 复用 `cir_to_ctf` 得 CTF（现成）。两条路都不改 Full 6GPCM 核心。

---

## 1. Time 轴数据合成协议

### 1.1 目标

为 Time 轴外推/内插，生成"沿时间采样的 CIR 序列"，并从其中逐时刻标定出**秒级慢变的
`DS_mu`、`KF_mu` 参数序列**（`num_clusters` 冻结）。训练主力是参数序列，原始 CIR 只保留
探路小样本用于标定法回归测试。

> 重新定义依据（2026-08 探查确认）：Full 6GPCM 的大尺度参数沿**空间位置**慢变，去相关
> 距离 `DS_lambda=20m`、`KF_lambda=20m`。要让 DS/KF 有时间可观测的慢变，路线总位移须
> 跨越多倍相关距离（数十至上百米），对应秒级时间尺度。

### 1.2 参数（本轮已确认 + 重新定义后更新）

| 参数 | 取值 | 说明 |
|---|---|---|
| Nt（每路线时刻数） | **96** | 足够切出多个 16→4 滑窗 |
| 场景 | 复用 v3.1 语料 12 类（sub-6G/cmWave/mmWave × UMa/UMi/RMa/Indoor × LoS/NLoS） | 复用 `generate_step11abc_full_route.m` 的场景名 |
| 速度 | 8 m/s（探路档；正式可扩 0.5~12） | 速度决定单位时间的位移，从而决定 DS/KF 慢变速率 |
| 天线 | 2×4（探路档；正式可扩 1×1~2×4） | 复用 v3.1 语料配置 |
| 采样间隔 | **100 ms（秒级）** | 使 96 时刻覆盖约 76.8 m 位移，跨越 ~4 倍去相关距离，DS/KF 可观测慢变 |
| 预测字段 | **DS_mu、KF_mu（2 维）** | `num_clusters` 冻结，不参与时间预测 |

### 1.3 数据形态（重新定义后确认）

- **训练主力 = 参数序列**：逐时刻标定 `DS_mu`/`KF_mu`，得到 `96 × 2` 序列，体积小，与 v3.1 语料形态一致；
- **保留探路小样本原始 CIR**：每轴 2~3 条路线，用于将来标定法回归测试，不参与训练；
- **不存全量原始 CIR**（Npath=400 会致 GB 级体积）。

### 1.4 切分规则（防时间泄漏，深水区 2 硬约束）

- **按整条时间路线隔离** Train/Validation/Test，绝不按时间段切；
- 同一条路线的所有时刻只能落在同一个 split；
- 外推任务：已知时刻严格早于目标时刻（因果）。

### 1.5 生成流程

```text
对每条路线：
  sps.setScenario(scenario) + track('linear', speed) + 天线阵列
  → get_CIR → 一条 [Tx,Rx,Npath,Nt] 的时间序列 CIR
  → 转成 v3 CIR 合同（含 time_s 坐标）
  → 逐时刻标定 DS_mu/KF_mu → 96×2 参数序列
  → 参数序列存 Git 外语料目录；原始 CIR 只留探路小样本
```

复用 `generate_step11abc_full_route.m` 的调用模式，扩展 Nt、采样间隔（秒级）和坐标写入。

---

## 2. Frequency 轴数据合成协议

### 2.1 目标

为 Frequency 轴带内缺失恢复，生成"子载波级 CTF 频谱"：从完整 CTF 中按缺失模式挖掉
部分子载波，任务是从已知子载波恢复缺失子载波。

### 2.2 参数（本轮已确认）

| 参数 | 取值 | 说明 |
|---|---|---|
| 子载波数 Nf | **64**（推荐）或 128 | 复用现有 CTF 的 64 频点习惯 |
| 子载波间隔 | 120 kHz（复用 fixture 习惯） | 与 v3 标准 fixture 一致 |
| 缺失模式 | 均匀 / 随机 / 成块 三种 | 训练与测试都要覆盖 |

### 2.3 生成流程

```text
用 Full 6GPCM 产 CIR（同 Time 数据，或复用静态场景）
  → create_ctf_dataset_from_cir(cir, frequencyHz) 得完整 CTF
  → 按缺失模式挖掉目标子载波，记录 known/target 子载波索引
  → 存 Git 外语料目录（含 frequency_hz 坐标 + 缺失模式标记）
```

### 2.4 红线（决策 B 细化）

- 只做**带内**缺失恢复（含带内边缘），跨频段不做正式、只标 🧪；
- 缺失子载波是"真实挖掉后再预测"，不是"从完整 CIR 做 IFFT 冒充"。

---

## 3. Space 轴数据合成协议（2026-08 修正：不复用 v3.1 语料）

### 3.1 目标

为 Space 轴外推/内插，生成"沿位置采样的 CIR 路线"，并逐位置标定出**沿位置慢变的
`DS_mu`/`KF_mu` 参数序列（2 维，num_clusters 冻结）**。

> 修正依据：v3.1 语料 `step11abc_*.h5` 的 label 是 generator truth + 人造平滑扰动
> （机制 A），与产品"从 CIR 真实标定"（机制 B）语义脱节，复用会重蹈 v3.1 的坑。
> 因此 Space 轴改为**用机制 B 重新生成**，与 Time/Frequency 一致。

### 3.2 参数

| 参数 | 取值 | 说明 |
|---|---|---|
| N_sample（每路线位置数） | **96** | 足够切出多个 16→4 滑窗 |
| 场景 | 复用 v3.1 语料 12 类 | 复用 `generate_step11abc_full_route.m` 的场景名 |
| 速度 | 8 m/s（探路档） | 速度决定单位时间位移，从而决定 DS/KF 沿位置慢变速率 |
| 天线 | 2×4（探路档） | 复用 v3.1 语料配置 |
| 采样间隔 | **100 ms** | 使 96 位置覆盖约 76.8 m，跨越 ~4 倍去相关距离 |
| 预测字段 | **DS_mu、KF_mu（2 维）** | num_clusters 冻结 |

### 3.3 生成流程

```text
对每条路线：
  sps.setScenario(scenario) + track('linear', speed) + 天线阵列
  → get_CIR → 一条 [Tx,Rx,Npath,N_position] 的沿位置 CIR（转成 N_sample 维）
  → 从 rx_track.positions 提取 sample_position_m 坐标
  → 逐位置标定 DS_mu/KF_mu → 96×2 参数序列（num_clusters 冻结锚点）
  → 参数序列存 Git 外语料目录；原始 CIR 只留探路小样本
```

复用 `generate_v32_1_space_route.m` + `estimate_v32_1_space_p8_sequence.m`（已探路通过）。

---

## 4. 资产存放（决策 H 落地）

- 全部生成数据存 `D:\Codex_Feiyi\ChanAI-Pulse-v3.1-assets\corpora\chanaipulse-v3.2-corpus.1\`，**不入 Git**；
- 仓库只存：生成脚本（`core/` 或 `tools/`）、配置、Manifest、摘要、小 fixture；
- 每份数据带 Manifest：场景、速度、天线、Nt/Nf、种子、划分、坐标、来源（full_6gpcm_public_api）、生成器版本、树哈希。

---

## 5. 已确认/待拍的协议参数

1. **Time Nt**：96（已确认）；**采样间隔 100 ms、速度 8 m/s**（已确认）。
2. **Time/Space 预测字段**：DS_mu、KF_mu（2 维），num_clusters 冻结（已确认）。
3. **Space N_sample**：96；采样间隔 100 ms、速度 8 m/s（已确认，探路通过）。
4. **Frequency Nf**：64，子载波间隔 120 kHz（已确认）。
5. **Frequency 缺失模式 3 档**：uniform_half / random_half / block_8（已确认，探路通过）。
6. **划分比例**：84/18/18（已确认）。
7. **生成规模**：先小规模探路（每轴 20~40 条路线）验证，再扩到 120 路线。

---

## 6. 下一步

1. 三轴探路数据统一验证（Time/Space 的 16→4 滑窗 + Frequency 的缺失恢复）；
2. 扩规模到 120 路线（84/18/18 划分）；
3. 生成数据 Manifest 冻结，v3.2-1 收尾。
