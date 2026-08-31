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

---

## 8. v3.2-4a 进度快照（三轴 UI 集成，工作分支 `codex/v3.2-4a`，未提交）

> 上一快照以来：v3.2-0 合同（PR #77）、v3.2-1 数据（PR #78/#79）、v3.2-2 模型研究（PR #80/#81）、注册表（PR #82）、v3.2-3 端到端（PR #83）均已合并；origin/main HEAD `315fb0f`。

### 8.1 已完成（本地已验证，未提交）

- **统一预测入口** `core/v32_1/run_v32_axis_prediction.m`：按 task.axis 分派——sample→v3.1-7；time→AR(4) 外推 DS/KF；space→Persistence 外推 DS/KF；frequency→线性插值恢复 CTF 幅度/相位（不调 Full 6GPCM）。全部带泄漏守卫（不读目标区）。
- **已知区 DS/KF 提取** `core/v32_1/estimate_known_region_ds_kf.m`：按位置轴/时间轴判别索引维度，DS 界 [-9,-5]、KF 界 [-30,30]。
- **频率恢复服务** `core/v32_1/run_v32_frequency_generation.m` + `recover_inband_ctf_spectrum.m` + `ifft_ctf_to_cir.m`：确定性恢复 → CTF 数据集 → IFFT CIR → 特性引擎 → canonical prediction result（镜像 run_prediction_generation 契约）。
- **App 接线** `app/ChannelSimulatorV3App.m`：
  - 任务轴四项 样本/空间/时间/频率（position→space 兼容别名，任务层用 space，生成层映射回 position——生成请求校验器只认 position）；
  - 频率轴"缺失子载波模式"下拉（uniform_half/random_half/block_8，仅频率轴启用）；
  - `registryRecommendation` 按轴（time→ar / space→persistence / frequency→linear_interpolation / sample→v3.1 策略）；
  - `createProductParameterPrediction` 三轴分派；`runPredictionGeneration` 频率分支；time/space 每目标 Nt=1 + full_track_speed_mps=8.0（v3.2-3a/3b 语义）；
  - 模块三参数轴渲染频率 magnitude/phase；v3.2 专属摘要；翻译表补充。
- **轴别名修复**：`select_channel_task_region`、`create_channel_task_preset`、`validate_benchmark_alignment` 均接受 space；`import_channel_dataset`/App 的空间位置轴按沿轨 x（N×3 取第 1 列）取值。
- **审计更新**：`audit_platform_compatibility` 的 `time_frequency_target_generation_supported=true`（v3.2-4a 起成立）。
- **测试**：`tests/run_v32_4_regression.m`（三轴核心链路，含泄漏篡改校验）、`tests/probe_v32_4_app_import.m`（无头三轴导入）、`test_step12_formal_ui.m`/`test_step12extra_usability_and_audit.m` 更新。**全部 PASS，v3.1-7 全量回归零退化。**
- **审阅指引**：`docs/v3.2/V3_2_4_UI_MANUAL_REVIEW_GUIDE.md`（人工审阅清单与勾选表）。

### 8.2 下一步

1. **v3.2-4a 已合并**（PR #86 → origin/main `d6395c2`）。
2. **v3.2-4b 已完成**（工作分支 codex/v3.2-4b，未提交）：
   - 报错用户可读化：`core/errors/user_error_guidance.m` + App `presentUserError`（4 个 catch 收口）+ 指引"常见报错与处理"节；
   - 三维独立 Benchmark：`run_channel_benchmark`/`validate_benchmark_alignment` 按轴适配（time/frequency/sample/space 目标抽取、索引维度、轴值、基线、逐目标指标）；三轴端到端验证 PASS（`probe_v32_4b_benchmark_three_axis`）；
   - 全部回归零退化（step13/v3.2-4a/v3.1-7/UI）。
3. 待办：v3.2-4b 建分支 → PR（Duanfeiyi 手动合并）；随后 v3.2-4c（发布验收 + release）。

### 8.3 v3.2-4a 审阅修复轮（人工审阅发现的问题已修复）

1. **图1（频率导入报错不友好）**：`create_channel_task_preset` 的轴长不足错误现在带轴名与长度并给出引导（"CTF 频谱文件应选频率轴"）；App `loadAndAnalyze` 增加 CIR 文件+频率轴 的域↔轴匹配引导（CTF+非频率不拦截，保留 v3.1-7 遗留流程）。
2. **图2（空间轴只有 3 图）**：探针文件元数据富化（`export_v32_4_probe_import_files` 现在写入 frequency_count=64、subcarrier_spacing_hz=120e3、tx_array/rx_array ULA 几何，且强制重生成）。空间轴模块一现为 **6 标准 + 1 附加**（频率自相关经派生 CTF、角度两图经 ULA 波束空间）。诚实降级：时间轴单路线（N_sample=1）6 图（3 个 CDF 不可用）；频率模块一已知区洞状网格 2 图；频率模块三恢复 CIR 4 图（CDF 单谱降级）。
3. **图3（三轴手动选模型被拒）**：新增 `core/v32_1/v32_axis_manual_forecast.m`（MATLAB 经典模型族 persistence/linear/quadratic/holt/harmonic/ar/kalman，逐模型与 Python `flexible_forecast.py` 数值一致 ≤3.5e-14）。时间/空间轴高级模式手动选择经典模型可直接运行；神经模型（gru/lstm/tcn/dlinear/nlinear）给出明确不可用原因；频率轴手动给出明确说明（恢复为确定性线性插值）。
4. **图4（频率轴模块二标定失败）**：根因 = 频率轴已知区是洞状非均匀子载波网格，Step-8 优化器构建 PDP 拟合目标（CTF→CIR 需均匀网格）必然失败（`build_channel_fit_target:MissingPdp`）。修复 = 频率轴跳过参数优化，新增 `core/v32_1/create_frequency_axis_calibration.m` 占位标定（success=true，策略=frequency_deterministic_recovery，如实标注"不依赖标定"），模块二快速通过 → 模块三恢复。对恢复精度零影响（恢复本就不读标定）。无头端到端验证 `prediction_success=1, selected_model=linear_interpolation`。
5. 新增回归覆盖：手动经典模型 7 个、神经模型拒绝、三轴模块一图数断言、频率轴端到端。全部 PASS，v3.1-7 零退化。

### 8.4 v3.2-4a 频率精度提升（方案 A：结构分流 hybrid，已实现并评估）

- **背景**：v3.2-2b 发布的频率基线（mag/phase 线性插值）complex NMSE 0.76–0.84；产品复数插值已将其降至 uniform 0.18 / random 0.37（block 仍 0.80）。1A 延迟域稀疏恢复（OMP）在 block_8 0.59、random 0.25 更优，但 uniform_half 因隔点采样混叠退化到 1.06。
- **方案 A（采纳）**：`core/v32_1/recover_inband_ctf_hybrid.m` 按**目标索引最大连续段 ≥4** 无泄漏分流——block 型走 `recover_inband_ctf_delay_sparse.m`（延迟域 OMP，support=8），其余走复数线性。选择器只看缺口形状，不读真值。
- **产品级全语料评估**（`core/v32_1/probe_v32_4_frequency_hybrid_eval.m`，用上线同款 MATLAB 函数跑 2880 序列）：
  - block_8：hybrid 0.592 vs linear 0.796 → **+25.6%**，胜出率 72.8%
  - random_half：0.255 vs 0.374 → **+32.0%**，胜出率 75.1%
  - uniform_half：0.169 vs 0.169 → 0%（保持最优，不劣化）
  - 整体（3 模式等权）≈ 0.339 vs 0.446 → **+24%**
  - 报告：`chanaipulse-v3.2-corpus.1/v32_4a_frequency_hybrid_eval.json`（Git 外）
- **准入说明**：block/random 满足 ≥10% 改善与 ≥60% 胜出；uniform 保持最优不劣化（设计使然，非退步）。**已由 Duanfeiyi 确认按整体口径验收**（3 模式等权整体改善约 +24%，达标）。
- **Manifest 如实记录**：selection.selected_model / model.model_type / engine.id = 实际方法；recovery_dispatch = structure_hybrid_1a_contiguous_block_ge_4。

### 8.5 v3.2-4a 三轴 × 12 模型全接入（高级模式手动选择）

- 需求：高级模式三轴**每个实验方法都能接入运行**（好坏不论）。
- 实现：
  - 经典 7 模型（persistence/linear/quadratic/holt/harmonic/ar/kalman）：MATLAB（`v32_axis_manual_forecast.m`），时间/空间=DS/KF 序列外推；频率=沿频率轴对 [Re, Im] 序列预测（`run_v32_axis_prediction.recoverWithModel`）。
  - 神经 5 模型（gru/lstm/tcn/dlinear/nlinear）：Python 在线拟合外推（`python/chanai_predictor/v32_4_axis_neural.py` + `core/v32_1/v32_axis_neural_forecast.m`），在已知区序列上现场拟合小模型后滚动外推，无预训练 checkpoint；**实验性质**，Manifest `execution_contract` 含 `online_fit`、provenance 标 `manual_experimental_override`。
  - App：取消神经/频率手动拒绝，神经模型自动解析 Python 运行时（`resolvePredictorPython`，仅在选神经模型时要求）。
- 自动模式不变：时间=AR、空间=Persistence、频率=structure_hybrid。
- 验证：回归测试覆盖 12 模型 × 三轴可运行断言，全部 PASS，v3.1-7 零退化。
