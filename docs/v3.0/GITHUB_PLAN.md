# ChanAI Pulse v3.0 GitHub 制作计划

> 目标仓库：`Duanfeiyi/ChanAI-Pulse`
>
> 本文件保存 GitHub 计划的正式内容，避免远程写入暂时不可用时丢失计划。

## 1. Milestone

标题：

```text
ChanAI Pulse v3.0.0
```

GitHub：

- [ChanAI Pulse v3.0.0 Milestone](https://github.com/Duanfeiyi/ChanAI-Pulse/milestone/1)

说明：

```text
Tracks the staged implementation of ChanAI Pulse v3.0: frozen requirements,
CIR/CTF data contracts, full 6GPCM adapters, Grid Search and SA, parameter
prediction to complex CIR, capability-aware visualization, external benchmark,
regression and release acceptance.
```

暂不设置预计完成日期。科研进度受数据、MATLAB 环境和第三方依赖影响，在没有团队日期承诺时不填写虚假截止日期。

## 2. 总追踪 Issue

标题：

```text
[Roadmap] ChanAI Pulse v3.0.0
```

GitHub：

- [Roadmap Issue #21](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/21)

主要复选项：

- [x] Step 0：冻结需求、版本、资产和协作边界
- [x] Step 1：定义统一 CIR/CTF 数据标准
- [x] Step 2：制作四类标准测试数据
- [x] Step 3：验证完整版 6GPCM 最小无界面调用
- [x] Step 4：完成模块一信道数据输入流程
- [x] Step 5：建立统一信道特性引擎
- [x] Step 6：完成 Generator Adapter
- [x] Step 7：实现真正 Grid Search
- [x] Step 8：整理随机局部搜索、实现 SA 与 Grid/SA 自动策略决策器
- [ ] Step 9：确定正式预测参数与训练数据
- [ ] Step 10：完成 Predictor Adapter
- [ ] Step 11：打通预测参数到 6GPCM CIR
- [ ] Step 12：接入冻结的三页 UI
- [ ] Step 13：建立软件外部 Benchmark
- [ ] Step 14：集成、回归、文档和发布

勾选含义：对应 Step 的实现、测试、文档、需求追踪和 PR 已经合并到 `main`。

## 3. Step 0 Issue

标题：

```text
[Step 0] 冻结 v3.0 需求、版本、资产和协作边界
```

GitHub：

- [Step 0 Issue #22](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/22)

验收项：

- [x] 确认老师提出的正式需求；
- [x] 冻结三模块界面基线；
- [x] 确认 MATLAB/Python 分工；
- [x] 确认公开仓库和第三方资源规则；
- [x] 确认完整版 6GPCM 核心不修改；
- [x] 确认 v3.0 版本命名；
- [x] 确认短分支 → PR → `main`；
- [x] 建立需求追踪表；
- [x] 建立资产登记表；
- [x] 建立 PR 和 Issue 模板；
- [x] 项目负责人审阅 Step 0 文档；
- [x] Step 0 PR #23 合并到 `main`；
- [x] 关闭 Step 0 Issue。

## 3.1 Step 1 Issue

- [Step 1 Issue #24](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/24)
- 工作分支：`codex/v3-step-1-data-contract`
- 目标：定义统一 CIR/CTF 数据标准、内插/外推任务契约、MATLAB 验证接口和 MATLAB/Python HDF5 映射。
- [Step 1 PR #25](https://github.com/Duanfeiyi/ChanAI-Pulse/pull/25)
  已于 2026-07-28 合并到 `main`。
- Step 1 Issue 已关闭，总 Roadmap 已勾选 Step 1。

## 3.2 Step 2 Issue

- [Step 2 Issue #27](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/27)
- 工作分支：`codex/v3-step-2-standard-datasets`
- 目标：制作四套确定性CIR/CTF标准数据、MATLAB/Python交叉验证、1/3/6/9能力分级和可选QuaDRiGa外围适配示例。
- [Step 2 PR #28](https://github.com/Duanfeiyi/ChanAI-Pulse/pull/28)
  已合并到 `main`。
- Step 2 Issue 已关闭，GitHub 总 Roadmap 已勾选 Step 2。

## 3.3 Step 3 Issue

- [Step 3 Issue #29](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/29)
- 工作分支：`codex/v3-step-3-full-6gpcm-spike`
- 目标：登记完整版 6GPCM 资产和哈希，在不修改核心的前提下验证最小无界面调用、固定种子复现性，并把原始输出转换成 v3 统一 CIR。
- [PR #30](https://github.com/Duanfeiyi/ChanAI-Pulse/pull/30)
  已于 2026-07-29 合并到 `main`。
- Step 3 Issue #29 已关闭，GitHub 总 Roadmap 已勾选 Step 3。

## 3.4 Step 4 Issue

- [Step 4 Issue #32](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/32)
- 工作分支：`codex/v3-step-4-input-pipeline`
- 目标：完成模块一单文件 v3 HDF5 输入、PASS/WARNING/FAIL、内插/外推任务、SAGE/WiFo 专用转换器和与正式平台隔离的体验 Demo。
- 当前状态：核心实现、Step 1～4 回归、Python 读取、真实 SAGE/WiFo 技术验证、项目负责人人工审阅、提交和 PR 自审均已完成。
- 人工审阅确认的正式 UI 自动编号/坐标换算已登记为 `UI-TODO-001`，计划在 Step 12 实现，不阻塞 Step 4。
- PR #31 已合并；Step 4 分支已快进同步到对应的最新 `main`。
- [PR #33](https://github.com/Duanfeiyi/ChanAI-Pulse/pull/33)
  已于 2026-07-29 合并到 `main`。
- Step 4 Issue #32 已关闭，GitHub 总 Roadmap 已勾选 Step 4。

## 3.5 Step 5 Issue

- [Step 5 Issue #35](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/35)
- 工作分支：`codex/v3-step-5-characteristics-engine`
- 目标：建立模块一/三共享的能力驱动特性引擎、统一图表注册表、
  共享绘图器和模拟正式第一页的独立功能 Demo。
- 科学规则、计算引擎、1/3/6/9标准数据、降级路径和第一页 Demo
  已完成本地实现、自动验证和项目负责人人工审阅。
- 本分支通过 [Step 5 Draft PR #36](https://github.com/Duanfeiyi/ChanAI-Pulse/pull/36)
  提交并完成 PR 自审；
- PR #36 已合并到 `main`，合并提交为
  `4bc50d02c9843ab8f0066a1f21e6ace304189045`；
- Step 5 Issue #35 已关闭；
- Step 5 已完成，下一阶段为 Step 6 Generator Adapter。

## 3.6 Step 6 Issue

- [Step 6 Issue #38](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/38)
- 工作分支：`codex/v3-step-6-generator-adapter`
- 目标：建立模块二/三共享的 `GeneratorConfig -> GenerationResult`
  接口，接入 Mock、6GPCM-lite 和只读外置 Full 6GPCM，并输出统一复数
  CIR/delay 与可选 CTF。
- 自动回归、真实 Full 核心完整性、独立 Demo 和项目负责人人工审阅均已通过。
- [PR #39](https://github.com/Duanfeiyi/ChanAI-Pulse/pull/39)
  已合并到 `main`；
- 合并提交：`94da784d94ea5dc1a1af897253ba93f748fee593`；
- Step 6 Issue #38 已关闭；
- Step 6 已完成，下一阶段为 Step 7 真正的 Grid Search。

## 3.7 Step 7 Issue

- [Step 7 Issue #41](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/41)
- 工作分支：`codex/v3-step-7-grid-search`
- 目标：实现模块二真正的参数笛卡尔积 Grid Search；只用任务 known 区域建立目标，
  通过 Step 6 Adapter 生成候选 CIR，再用 Step 5 特性引擎按 PDP 与 RMS 时延扩展
  分布评分和排名。
- 已冻结规则：Mock/Lite/Full 三后端、8个可搜索参数、固定随机种子、串行可取消、
  单候选失败继续、默认最多500个候选、只保留Top 5完整CIR。
- 当前状态：Issue、独立分支、核心实现、Mock/Lite/真实Full专项测试、Demo、
  审阅图、Step 1～7完整回归、接口文档和项目负责人人工审阅均已完成；
  [PR #42](https://github.com/Duanfeiyi/ChanAI-Pulse/pull/42) 已合并到 `main`；
  合并提交为 `c9492f52122d451ed736014a0b85a674431a94af`。
- Step 7 Issue #41 已关闭，GitHub 总 Roadmap 已勾选 Step 7；
- Step 7 已完成，下一阶段为 Step 8。

## 3.8 Step 8 计划

- [Step 8 Issue #44](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/44)
- 工作分支：`codex/v3-step-8-sa-optimizer`
- 经仓库、整理版和可用工作目录复查，没有找到可直接复用的旧随机局部搜索、
  Grid 或 SA 实现；因此新增项目自有 `random_greedy` 对照基线，并明确它不进入
  正式 `auto` 选择；
- 实现可复现、可取消、具有明确参数边界的 SA；
- Grid、随机局部搜索和 SA 复用 Step 7 的 known 目标、Step 6 候选生成、
  Step 5 评分、失败记录和 Manifest，不各写一套科学逻辑；
- 新增策略决策器，支持 `auto`、`grid`、`sa`；
- `auto` 综合离散/连续参数、笛卡尔积规模、生成后端成本和计算预算选择算法；
- 自动结果记录算法、选择来源和人类可读理由；
- 用户手动指定的方法不适用时明确拒绝，不得静默切换；
- 使用小型已知答案、固定随机种子、收敛/边界/失败/取消测试比较 Grid 与 SA；
- 已冻结第一版自动 Grid 上限：Mock 500、Lite 125、Full 16，统一硬上限 500；
- 当前状态：统一配置/结果、共享评估器、Random Greedy、SA、自动策略、缓存、
  Mock/Lite/真实Full测试、独立Demo、审阅图、完整回归、静态检查和项目负责人
  人工审阅均已完成；
- [PR #45](https://github.com/Duanfeiyi/ChanAI-Pulse/pull/45)
  已于 2026-07-30 合并到 `main`；
- 合并提交：`d04bc276e346c8f9c93dfaece14f8d64abdb461d`；
- Step 8 Issue #44 已关闭，GitHub 总 Roadmap 已勾选 Step 8；
- Step 8 已完成，下一阶段为 Step 9 正式预测参数与训练数据契约。

## 3.9 Step 9 计划

- [Step 9 Issue #47](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/47)
- 工作分支：`codex/v3-step-9-predictor-data`
- 目标：在训练泛用模型之前，固定参数序列、内插/外推模型张量、标签来源、
  路线级切分、训练集归一化和 MATLAB/Python HDF5；
- 标准档先使用 `DS_mu/KF_mu`，契约保留 Step 8 全部 8 个参数；
- 生成器真值用于预训练，Grid/SA 局部拟合标签主要作为上传数据微调候选；
- 外推默认 16→4，内插默认左8+右8→中4；
- 同一路线或场景不能泄漏到不同分区；
- Step 9 只登记 `pretrain/auto/off/force` 和资格元数据，Step 10 再训练泛用模型、
  实现每次上传后的可控微调并通过实验确定阈值；
- 公开仓库只保存确定性合成小样例，不上传真实测量数据、第三方权重或大型派生数据；
- 当前状态：Issue和分支已建立，核心契约、自动测试、跨语言fixture、独立Demo、
  审阅图、完整回归和项目负责人人工审阅均已完成；已获准提交、push并创建PR。

## 3.10 Step 12 对应 UI 计划

- 普通模式默认“自动选择（推荐）”，模块二继续主要在后台运行；
- 运行前后显示实际选择的 Grid 或 SA 及简短理由；
- 高级设置允许用户手动指定 Grid 或 SA；
- 手动指定不适用时给出修改范围或更换算法的建议；
- 界面显示与运行 Manifest 必须一致；
- 模块三普通模式默认泛用模型与自动微调判断，高级模式支持
  `auto/off/force`，详细条目登记在 `UI_DEFERRED_TODOS.md` 的
  `UI-TODO-002` 和 `UI-TODO-003`。

## 4. 后续 Issue 创建规则

不一次性创建大量没有立即行动的 Issue。

每次准备开始一个 Step 时：

1. 从 `.github/ISSUE_TEMPLATE/v3_step.md` 创建 Issue；
2. 填写对应需求 ID；
3. 明确范围、产出和验收标准；
4. 关联 `ChanAI Pulse v3.0.0` Milestone；
5. 开始实现后关联工作分支；
6. PR 创建后关联 PR；
7. 合并到 `main` 后关闭 Issue 并更新总 Roadmap。

## 5. 当前远程执行状态

2026-07-30 检查结果：

- 仓库存在且当前浏览器会话可以看到仓库设置；
- 已创建 `ChanAI Pulse v3.0.0` Milestone（编号 1）；
- 已创建 Roadmap Issue #21；
- 已创建 Step 0 Issue #22；
- 已创建并关闭 Step 1 Issue #24；
- Step 2 Issue #27 已关闭，PR #28 已合并；
- Step 3 Issue #29 已关闭，PR #30 已合并；
- Step 3 收尾 PR #31 已合并；
- Step 4 Issue #32 已关闭，PR #33 已合并；
- Step 5 Issue #35 已关闭，PR #36 已合并；
- Step 5 收尾 PR #37 已合并；
- Step 6 Issue #38 已关闭，PR #39 已合并；
- Step 6 收尾 PR #40 已合并；
- Step 7 Issue #41 已关闭，PR #42 已合并；
- Step 7 小型收尾 PR #43 已合并；
- Step 8 Issue #44 已关闭，PR #45 已合并；
- Step 8 小型收尾 PR #46 已合并；
- Step 9 Issue #47 已创建并指派给 `Duanfeiyi`，当前工作分支为
  `codex/v3-step-9-predictor-data`；
- GitHub 总 Roadmap 已勾选 Step 0～8；
- Step 1 PR #25 已合并；
- 当前各 Step Issue 按计划指派给 `Duanfeiyi` 并关联 Milestone；
- GitHub 连接器创建 Issue 返回 `403 Resource not accessible by integration`；
- GitHub 连接器更新 Roadmap 返回 `403`，本次通过已认证 GitHub CLI 同步 Step 2、Step 3、Step 4；
- 本次通过已认证的 GitHub 网页会话完成创建；
- 后续如希望完全使用 GitHub 连接器自动管理 Issue，仍需要补充 Issues 写权限；
- 远程对象必须以 GitHub 页面上的实际结果为准，不能因为已经准备了正文就宣称创建成功。
