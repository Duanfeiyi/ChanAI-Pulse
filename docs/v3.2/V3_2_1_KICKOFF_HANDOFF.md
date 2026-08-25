# v3.2-1 开工交接快照（给下一任 Agent）

> 目的：让接手的 Agent（无论是否更换模型）不重爬长对话，直接安全开工。
> 日期：本快照随 v3.2-1 开工前产生。
> 注意：本快照是工作快照，不是正式文档，暂不入库。

---

## 1. 我在哪一步（一句话）

- 项目已发布 v3.0.0、v3.1.0（Tag `v3.1.0` 已建）。
- v3.2 规划已完成 v3.2-0（合同冻结，PR #77 已合并到 main，`15f4970`）。
- **当前处在 v3.2-1（建三维数据集）**：Time 轴、Frequency 轴的数据合成 + 标定 + 滑窗链路**已探路通过**；Space 轴（复用 v3.1 语料）和"统一验证 + 扩规模"待做。
- Time 轴预测对象已重新定义为"秒级慢变 DS_mu/KF_mu（2 维，num_clusters 冻结）"。

---

## 2. 当前分支与工作区状态

- 真实工作区：`D:\Codex_Feiyi\ChanAI-Pulse-v3.1-7`
- 当前分支：`codex/v3.2-0-task-contract`（已合并，勿继续在其上开发；新工作应基于最新 origin/main 另开分支）
- origin/main：`15f4970 Merge pull request #77`
- 未跟踪文件（均未入库，讨论/探路产物）：
  - `docs/v3.2/V3_2_1_DATA_SYNTHESIS_DRAFT.md`（协议设计稿）
  - `docs/v3.2/V3_2_0_TASK_CONTRACT_DRAFT.md`（合同设计稿，已按 Time 重定义更新）
  - `docs/v3.2/V3_2_1_KICKOFF_HANDOFF.md`（本快照）
  - `core/v32_1/*.m`（Time/Frequency 生成 + 标定 + 探路脚本，共 6 个）
- 本快照本身也不入库。

⚠️ 旧脏工作区 `D:\Codex_Feiyi\ChanAI Pulse` 绝对不动（reset/checkout/覆盖/删除都不行）。

---

## 3. 铁律（任何操作前先确认不违反）

1. **不 merge**：所有 PR 由项目负责人 `Duanfeiyi` 手动合并。
2. **不擅自远端操作**：未经当次明确授权，不 commit、不 push、不建 PR、不建 Tag/Release。
3. **不改 Full 6GPCM 核心**：`third_party/full_6gpcm/` 零改动，只走外围 Adapter。
4. **数据不入 Git**：大型语料、checkpoint、缓存、私有数据一律放 Git 外资产目录，仓库只存代码/配置/Manifest/摘要/小 fixture。
5. **产品预测不读目标真值**。
6. **权限申请用中文**，说明操作、原因、范围、风险。
7. **不碰桌面源资料、不上传私有数据**。

---

## 4. v3.2 已确认的全部决策（接手后不必重议）

### 4.1 决策 A~J

| 决策 | 结论 |
|---|---|
| A | 三轴合同一起冻结；实现按成熟度推进：Space → Frequency 内插 → Time 外推 |
| B | Frequency 带内缺失恢复（含带内边缘）= 正式；跨频段/跨中心频率 = 🧪 实验，绝不冒充 |
| C | 数据用合成数据补（Full 6GPCM + QuaDRiGa 异源） |
| D | 双轨坐标：下标（存储/对齐）+ 物理坐标（判定/加权）；坐标可选增强，缺则退化 |
| E | 向后兼容，不破坏 v3.0/v3.1 sample/position 合同 |
| F | 因果与无泄漏 = 硬规则（Time 外推因果、滑窗不跨分组） |
| G | 沿用 v3.1 准入门槛（NRMSE 改善 10%、60% 验证路线胜出、≤2 倍基线、多种子、端到端） |
| H | 用 Full 6GPCM 合成 Time/Frequency 数据，存 Git 外 |
| I | QuaDRiGa 只当异源测试集，不作生成后端 |
| J | Space 三种坐标形态：regular_grid / irregular_points / trajectory |

### 4.2 深水区 1~5 结论

- **1**：预测引擎统一、对象分轴。Time/Space 走参数级（P8→Full 6GPCM→CIR/CTF）；Frequency 走波形级（CTF 复数→完整 CTF→可选 IFFT CIR）。引擎复用 v3.1 的"序列预测+已知区回测选模+local_guard+双向内插"。
  - **Time 轴重新定义（2026-08 探查后）**：预测对象是**秒级慢变的 `DS_mu`/`KF_mu`（2 维）**，`num_clusters` 冻结。依据：Full 6GPCM 大尺度参数沿位置慢变（去相关距离 20m），须路线位移跨越多倍相关距离（数十至上百米）才有可观测慢变，对应秒级时间尺度。
- **2**：Time 外推四种泄漏（滑窗跨组/归一化/双向结构/标定）都要防。
- **3**：Frequency 不经过 Full 6GPCM（单频点复数标定不出 P8）；IFFT 红线：完整 CIR→IFFT 得 CTF 不算预测；预测 CTF→IFFT 得 CIR 须标注。
- **4**：合成数据 ≠ 真实泛化，如实声明；QuaDRiGa 当异源测试集缓解循环论证。
- **5**：Space 不规则/轨迹用 IDW/Kriging/弧长参数化做基线。

### 4.3 v3.2-1 数据协议参数（已确认，开工直接照此执行）

- Time 滑窗：**16→4 起步**（复用 v3.1 神经经验，后续滚动扩展）。
- Time Nt：默认 **96**（每路线时刻数）；采样间隔 **100 ms（秒级）**，速度 8 m/s，使路线位移约 76.8 m、跨越 ~4 倍去相关距离。
- Time 预测字段：**DS_mu、KF_mu（2 维）**，num_clusters 冻结。
- Time 数据形态：训练用参数序列（96×2）；原始 CIR 只留 2~3 条探路小样本当标定回归基准，不存全量原始 CIR（Npath=400 会致 GB 级）。
- Frequency Nf：**64**，子载波间隔 120 kHz。
- Frequency 缺失模式 3 档起步：**均匀隔1挖1（缺50%）、随机50%、成块缺8**；缺失模式写进 Manifest 当标签（供分模式报告）。
- 划分比例：**84/18/18**（沿用 v3.1）。
- 探路规模：Time/Frequency 各 **20~40 条路线**，先验证再扩 120。
- Space 数据：**不复用 v3.1 语料**（其 label 是 generator truth + 人造平滑扰动，与产品机制 B 语义脱节）；改为机制 B 重新生成（`generate_v32_1_space_route.m` + `estimate_v32_1_space_p8_sequence.m`，探路通过）。
- Space 预测字段：DS_mu、KF_mu（2 维），num_clusters 冻结（与 Time 一致）。

---

## 5. 已就位的资产路径

- Full 6GPCM：`third_party/full_6gpcm/`（公共 API 入口 `@channel_model/channel_model.m`）
- QuaDRiGa（已 clone + 核对版本/许可证）：`D:\Codex_Feiyi\ChanAI-Pulse-v3.1-assets\external\QuaDRiGa-2.8.1-0`（HEAD `2778666...`，与项目核验的 2.8.1-0 一致）
- v3.1 语料（Space 复用来源）：`D:\Codex_Feiyi\ChanAI-Pulse-v3.1-assets\corpora\chanaipulse-v3.1-corpus.1\predictor_bundles\`
- v3.2 语料目标目录：`D:\Codex_Feiyi\ChanAI-Pulse-v3.1-assets\corpora\chanaipulse-v3.2-corpus.1\`
- MATLAB：`E:\matlab2024b\bin\matlab.exe`
- Python（PyTorch 环境）：`D:\Codex_Feiyi\ChanAI-Pulse-v3.1-assets\runtime\v31_4\.venv\Scripts\python.exe`

---

## 6. 关键模板代码（写生成脚本时复用）

- Time 轴生成模板：`core/step11abc/generate_step11abc_full_route.m`（已能产"一条路线多时刻"，扩展 Nt 即可）
- CIR→CTF：`core/fixtures/cir_to_ctf.m` + `core/generation/create_ctf_dataset_from_cir.m`（现成，Frequency 数据直接复用）
- Full 6GPCM 公共 API 调用：`core/generation/run_full_6gpcm_public_api_adapter.m`（含树哈希前后核对、`track('linear')` 产时间演化）
- Full 6GPCM 树哈希：`core/generation/full_6gpcm_probe/hash_full_6gpcm_tree.m`

---

## 7. 已完成 + 下一步

### 7.1 已完成（探路已验证）

- **Time 轴**：`core/v32_1/generate_v32_1_time_route.m`（生成秒级采样、长位移的 Time CIR）+ `estimate_v32_1_time_p8_sequence.m`（逐时刻标定 DS_mu/KF_mu 2 字段，num_clusters 冻结锚点）+ `probe_v32_1_time_full.m`（16→4 滑窗，每条 96 时刻路线产出 77 个外推例子，因果性/维度/慢变均通过）。
- **Space 轴**：`core/v32_1/generate_v32_1_space_route.m`（沿位置 CIR 路线，含 sample_position_m）+ `estimate_v32_1_space_p8_sequence.m`（逐位置标定 DS_mu/KF_mu 2 字段，num_clusters 冻结锚点）+ `probe_v32_1_space.m`（96 位置，DS/KF 沿位置慢变通过）。
- **Frequency 轴**：`core/v32_1/generate_v32_1_frequency_spectrum.m`（静态 CIR → `cir_to_ctf` 得 CTF → 3 档缺失模式）+ `probe_v32_1_frequency.m`（uniform_half / random_half / block_8 三档均通过，Nf=64）。
- **QuaDRiGa**：已 clone 到 Git 外资产目录，版本/许可证核对通过。

### 7.2 下一步

1. 三轴探路数据统一验证（Time/Space 的 16→4 滑窗 + Frequency 的缺失恢复）；
2. 扩规模到 120 路线（84/18/18 划分）；
3. 生成数据 Manifest 冻结，v3.2-1 收尾。

**已无未决决策**——所有参数（16→4、Time Nt=96/100ms/8m/s、Time 2 字段、Nf=64、3 档缺失、84/18/18、探路规模、脚本位置、资产目录）均已由用户确认。
