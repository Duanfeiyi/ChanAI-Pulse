# v3.2-0：Time / Space / Frequency 三维任务合同 —— 已冻结（待入库）

> 状态：**合同已冻结（设计稿完成，待正式化入库）**。本文固化 2026-08 讨论中已确认的
> A~J 决策点与深水区 1~5 结论，并已获项目负责人确认。正式化入库前不提交、不建 PR、
> 不创建 Tag。
>
> 讨论基线：交接文档 §8、主计划 §5，以及本轮对话中由项目负责人逐项确认的决策。

---

## 0. 一句话定位

v3.2 把 time / space / frequency 从"能选、能画图"的骨架，升级为"有严格坐标合同、
无泄漏数据集、可预测、可生成 CIR/CTF、可独立 Benchmark 评价"的**一等预测任务**。

**核心架构结论（深水区 1 + 3）**：预测引擎统一、预测对象分轴。

- Time / Space 走**参数级**：预测 P8 参数序列 → 喂 Full 6GPCM → 生成目标 CIR/CTF。
- Frequency 走**波形级**：预测缺失频点的 CTF 复数 → 得到完整 CTF → 可选 IFFT 得 CIR。
- 三轴复用同一套"序列预测 + 已知区回测逐点选模 + local_guard + 双向内插"引擎，
  引擎只操作"沿坐标排列的序列"，不关心序列元素是 P8 参数还是 CTF 复数。

---

## 1. 已确认决策点（A~J）固化

| 决策 | 内容 | 结论 |
|---|---|---|
| A | 三轴优先级 | 合同层三轴一起冻结；实现层按成熟度推进：Space → Frequency 内插 → Time 外推 |
| B | Frequency 边界 | 带内缺失恢复（含带内边缘）= 正式；跨频段/跨中心频率 = 🧪 实验，绝不冒充正式 |
| C | 数据来源 | 现有 fixture 坐标齐全但规模不足（Time 几乎无、Frequency 无子载波语料）；用合成数据补 |
| D | 坐标语义 | 双轨：下标（存储/对齐）+ 物理坐标（判定/加权）；坐标是可选增强，非硬门槛 |
| E | 向后兼容 | 不破坏 v3.0/v3.1 的 sample/position 合同；time/frequency 为新增一等轴 |
| F | 因果与无泄漏 | 硬规则：产品预测不读目标真值；Time 外推必须因果 + 滑窗不跨分组 |
| G | 准入门槛 | 沿用 v3.1（NRMSE 改善 10%、60% 验证路线胜出、任一路线 ≤2 倍基线、多种子、端到端）；Time 加因果检查、Frequency 加带内/跨频段分开报告 |
| H | 合成数据 | 授权用内置 Full 6GPCM 合成 Time/Frequency 数据，存 Git 外资产目录，不入库 |
| I | QuaDRiGa | 仅作**异源独立测试集**（缓解循环论证），不作生成后端；需项目负责人自行准备官方 checkout（建议 2.8.1-0）；保留许可证 + 登记来源版本 |
| J | Space 坐标形态 | 明确三种：regular_grid / irregular_points / trajectory；用双轨坐标 + IDW/Kriging/弧长参数化做基线 |

---

## 2. 三轴正式定义

### 2.1 Time（时间轴）

- **外推**：由过去时刻预测未来时刻。已知时刻必须严格早于目标时刻。
- **内插**：恢复时间轴内部缺失区间，可使用两侧已知。
- **因果硬约束（决策 F）**：外推只允许因果模型；训练/归一化/标定不得使用未来信息。
- **预测对象（2026-08 探查后重新定义）**：Time 轴预测的是**秒级慢变的大尺度参数 `DS_mu`、`KF_mu`**，`num_clusters` 在时间轴上冻结（不参与时间预测）。
  - 依据：Full 6GPCM 的大尺度参数（DS/KF）沿**空间位置**慢变，去相关距离默认 `DS_lambda=20m`、`KF_lambda=20m`。接收机位移远小于相关距离时 DS/KF 几乎不变；位移跨越多倍相关距离（数十至上百米）时才有可观测的慢变。
  - 时间尺度是**秒级**（不是毫秒级快变）；毫秒级快变的是相位/多普勒/瞬时 CIR 系数，不在本轴参数预测范围内。
  - `num_clusters` 是离散慢变量，在几十米位移内不变，因此 Time 轴将其冻结，与 v3.1-7 产品语义一致。
- **关键物理量**：真实时间戳 `time_s`、采样间隔（秒级，如 100 ms）、速度/轨迹、多普勒。

### 2.2 Space（空间轴）

- **定位**：现有 sample/position 轴的统一升级。
- **外推**：由已知位置/轨迹预测未知位置。
- **内插**：补回已知位置之间的缺失位置。
- **三种坐标形态（决策 J）**：
  1. `regular_grid`：等间距有序网格，用下标即可（v3.0/v3.1 已覆盖）。
  2. `irregular_points`：任意散布位置，内插/外推判定与预测均基于真实坐标距离。
  3. `trajectory`：连续移动轨迹，按累计弧长参数化后等价于一维坐标。
- **预测对象（2026-08 探查后确认）**：Space 轴预测**沿位置慢变的 `DS_mu`、`KF_mu`（2 维）**，`num_clusters` 冻结。
  - 依据：与 Time 轴同源——大尺度参数沿空间位置慢变（去相关距离 20m）；`num_clusters` 是离散慢变量，在几十米位移内不变。
- **数据来源（2026-08 修正）**：Space 轴数据**不复用 v3.1 语料**（其 label 是 generator truth + 人造平滑扰动，与产品"从 CIR 真实标定"语义脱节）；改为**用机制 B（从 CIR 逐位置真实标定）重新生成**，与 Time/Frequency 一致。
- **关键物理量**：真实位置 `sample_position_m`、距离单位、空间相关性。

### 2.3 Frequency（频率轴）

- **正式（带内）**：缺失子载波 / 稀疏频点 → 完整频率网格恢复。
  - 含带内**边缘**缺失（单侧无已知），单独标注"边缘恢复"，仍属正式。
- **实验（🧪 跨频段）**：跨中心频率 / 跨频段预测，默认不进正式能力、不进 UI 默认路径。
- **红线（决策 B）**：跨频段与带内必须分开标签、分开报告。
- **关键物理量**：中心频率、带宽、子载波间隔、频率坐标 `frequency_hz`。

---

## 3. 统一任务合同（TaskRequest 扩展草案）

### 3.1 现状（v3.1 已有骨架）

`core/contracts/create_channel_task.m` / `validate_channel_task.m` 已支持：

- `task.axis ∈ {sample, position, time, frequency}`
- `task.mode ∈ {interpolation, extrapolation}`
- `task.known_indices` / `target_indices`（1-based 整数下标）
- `task.axis_values` / `axis_unit`（物理坐标）

### 3.2 扩展方向（双轨坐标，决策 D/E）

**保留**：`known_indices` / `target_indices`（下标，用于存储与对齐，不破坏既有代码）。

**新增**：`known_coordinates` / `target_coordinates`（物理坐标值，承载真实秒/米/Hz）。

**新增**：`axis_coordinates`（统一坐标描述）与每轴约束字段：

```text
task.axis                = "time" | "space" | "frequency"   （新增一等轴；
                          "sample" / "position" 继续作为 Space 的兼容别名）
task.mode                = "interpolation" | "extrapolation"
task.known_indices       = [1-based 下标]                    （保留，存储/对齐）
task.target_indices      = [1-based 下标]                    （保留，存储/对齐）
task.known_coordinates   = [物理坐标]                       （新增，可选）
task.target_coordinates  = [物理坐标]                       （新增，可选）
task.axis_coordinates    = struct(coordinates, unit)          （新增，统一坐标）
task.space_topology      = "regular_grid"|"irregular_points"|"trajectory"  （Space 轴，决策 J）
task.causality           = "causal" | "non_causal"           （Time 外推强制 causal）
task.frequency_scope     = "in_band" | "cross_band"          （Frequency 轴，决策 B）
```

### 3.3 双轨坐标的降级规则（决策 D 落地）

- 有 `*_coordinates` → 用坐标做"内插/外推判定"与"距离加权"。
- 无 `*_coordinates` → 退化为下标，行为与 v3.0/v3.1 一致（不报错、不回归）。
- 部分坐标缺失 → 该轴降级，不影响其他轴。
- **结论**：坐标是可选增强，不是入场门槛。

---

## 4. 预测对象分轴（深水区 1 + 3 落地）

| 轴 | 预测对象 | 序列元素 | 预测后链路 |
|---|---|---|---|
| Time | 秒级慢变的大尺度参数（时延域） | `DS_mu`, `KF_mu`（2 维；`num_clusters` 冻结） | 喂 Full 6GPCM → 目标 CIR → FFT 得 CTF |
| Space | 沿位置慢变的大尺度参数（时延域） | `DS_mu`, `KF_mu`（2 维；`num_clusters` 冻结） | 同上 |
| Frequency | CTF 复数（频域） | 每频点 (幅度, 相位) | 直接得完整 CTF → 可选 IFFT 得 CIR（标注"由预测 CTF 得到"） |

### 4.1 为什么 Frequency 不经过 Full 6GPCM

单个子载波只有一个复数，物理上无法标定出 `DS_mu`/`KF_mu`/`num_clusters`（这些是
"整段时延响应"的统计量）。因此 Frequency 的预测对象必然是 CTF 复数本身，频域结果
就是最终产物，无需再经参数→波形重建。

### 4.2 复数的序列化与评分（深水区 3 细节）

**序列化**：每频点复数拆为 `(幅度, 相位)` 两个实数通道；相位先做解缠处理消除
±180° 跳变；两条通道各自作为独立序列喂给引擎（与 v3.1 逐参数预测同构）。

**回测评分三档**：

| 档 | 方法 | 用途 |
|---|---|---|
| 1 | 幅度、相位**分别**算 NRMSE | 已知区回测逐通道选模（最快、直观） |
| 2 | 复数**指针距离**（综合幅度+相位误差） | 选模后的综合评分 |
| 3 | 完整 CTF 频谱比对（复数 NMSE/相关） | 独立 ChannelBenchmark 最终验收 |

### 4.3 IFFT 红线澄清（决策 B 细化）

- ❌ 冒充预测：从**完整 CIR** 做 IFFT 得到**完整 CTF**，声称"预测了频点"。
- ✅ 合法：从**预测出的完整 CTF** 做 IFFT 得 CIR，**明确标注**"该 CIR 由预测 CTF
  经确定性 IFFT 得到"——这是换域展示，不冒充预测。

---

## 5. 三维数据集合同（v3.2-1 前置，决策 C/H）

### 5.1 Time 数据

- 沿时间采样的 CIR 序列：`[16 已知时刻] → [4 目标时刻]` 滑窗；
- 保存真实时间戳、采样间隔、速度、Tx/Rx 轨迹；
- 外推必须因果；滑窗不跨数据集分组边界；
- 按**整条时间路线**隔离 Train/Validation/Test（防泄漏，深水区 2）。

### 5.2 Space 数据

- 规则网格 / 不规则位置 / 连续轨迹三种形态；
- 保存真实坐标与距离单位；
- 按整条路线/场景隔离分组。

### 5.3 Frequency 数据

- 带内缺失子载波 / 稀疏频点到完整网格；
- 保存中心频率、带宽、子载波间隔、频率坐标；
- 缺失模式（均匀/随机/成块）需显式定义。

### 5.4 数据来源与资产政策

- 训练/验证：内置 Full 6GPCM 合成，存 Git 外 `ChanAI-Pulse-v3.1-assets/corpora/` 模式；
- 异源测试集：QuaDRiGa（外部 checkout，仅转换，不复制核心），用于跨生成器泛化验证；
- 仓库只存：代码、配置、Manifest、小 fixture、摘要；
- **诚实声明（深水区 4）**：合成数据结论 ≠ 真实信道泛化结论，写入所有报告。

---

## 6. 模型能力声明与准入门槛（v3.2-2 前置，决策 G）

### 6.1 能力声明字段

模型注册时声明：

```text
supported_axes       = ["space"] | ["time"] | ["frequency"] | ...
causal               = true | false          （Time 外推只允许 causal=true）
interpolation_ok     = true | false
extrapolation_ok     = true | false
frequency_scope      = "in_band" | "cross_band"   （Frequency 轴）
```

### 6.2 每轴基线模型

- Space：Persistence、Linear、IDW、Kriging（规则网格用前两者，不规则/轨迹用后两者）；
- Time：Persistence、Linear、AR、Kalman、因果 GRU/LSTM/TCN（外推）；双向模型仅内插；
- Frequency：线性/样条插值、IDW（带内），神经网络须超基线才准入。

### 6.3 准入门槛（沿用 v3.1）

平均 NRMSE 改善 ≥10%、≥60% 验证路线胜出、任一路线 ≤2 倍基线误差、多种子稳定、
端到端通过；Time 额外检查因果性，Frequency 额外分开报告带内/跨频段。

---

## 7. Benchmark 对齐规则（v3.2-4 前置，决策 B/G）

- **严格坐标对齐**：时间、位置、频率坐标不得错位（下标 + 坐标双轨校验）。
- **分轴指标**：
  - Time：多步误差、时间相关性、连续性、CIR/CTF、多普勒；
  - Space：不同距离的预测误差、空间相关、位置插值/外推、CIR/CTF；
  - Frequency：复数频域误差、幅度/相位、缺失子载波恢复、频率相关性。
- **带内 vs 跨频段分开报告**（硬性），跨频段标 🧪，不得混入正式结论。
- **产品预测与 Benchmark 隔离不变**：产品不读目标真值，准确度只由独立 ChannelBenchmark 给出。

---

## 8. 红线与诚实边界（贯穿全版本）

1. Full 6GPCM 核心不修改，只扩外围 Adapter。
2. 产品预测路径不读取目标区 Ground Truth。
3. Time 外推必须因果，滑窗不跨分组（四种泄漏：滑窗跨组、归一化、双向结构、标定）。
4. Frequency 跨频段 = 实验，绝不冒充正式；IFFT 不冒充预测。
5. 合成数据 ≠ 真实信道泛化结论，如实声明。
6. QuaDRiGa 仅作异源测试集，不复制核心，保留许可证并登记来源版本。
7. 神经模型不因"高级"而强制准入，须过门槛；否则用基线。

---

## 9. 尚未最终确定、留待实施时细化的点

> 这些不影响合同冻结方向，但进入对应工作包前需再敲定。

1. Frequency 的"缺失模式"标准定义（均匀/随机/成块的精确规格）—— v3.2-1 前定。
2. 复数的"指针距离"评分公式（幅度+相位综合的精确数学式）—— v3.2-2 前定。
3. Space 不规则/轨迹的 Kriging 基线是否作为首版必须（还是先 IDW）—— v3.2-2 前定。
4. QuaDRiGa checkout 的确切存放路径与版本提交号—— v3.2-1 实施时定。
5. Time 轴"整条时间路线"的生成协议（Full 6GPCM 如何产出一条带时间演化的序列）—— v3.2-1 实施时定。

---

## 10. 下一步

1. 项目负责人审阅本稿，确认第 1~8 节与已讨论结论一致；
2. 审阅通过后，再决定是否将本稿正式化为 `docs/v3.2/V3_2_0_TASK_CONTRACT.md` 并入库
   （此时才进入 v3.2-1 数据集实施）；
3. 在正式化之前，本稿不提交、不建 PR。
