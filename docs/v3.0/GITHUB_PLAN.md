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
- [ ] Step 5：建立统一信道特性引擎
- [ ] Step 6：完成 Generator Adapter
- [ ] Step 7：实现真正 Grid Search
- [ ] Step 8：整理随机局部搜索并实现 SA
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
  提交并完成PR自审；合并前总 Roadmap 保持 Step 5 未勾选。

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

2026-07-29 检查结果：

- 仓库存在且当前浏览器会话可以看到仓库设置；
- 已创建 `ChanAI Pulse v3.0.0` Milestone（编号 1）；
- 已创建 Roadmap Issue #21；
- 已创建 Step 0 Issue #22；
- 已创建并关闭 Step 1 Issue #24；
- Step 2 Issue #27 已关闭，PR #28 已合并；
- Step 3 Issue #29 已关闭，PR #30 已合并；
- Step 3 收尾 PR #31 已合并；
- Step 4 Issue #32 已关闭，PR #33 已合并；
- Step 5 Issue #35 已创建并关联 v3.0.0 Milestone，Draft PR #36 已创建并自审；
- Step 1 PR #25 已合并；
- 当前各 Step Issue 按计划指派给 `Duanfeiyi` 并关联 Milestone；
- GitHub 连接器创建 Issue 返回 `403 Resource not accessible by integration`；
- GitHub 连接器更新 Roadmap 返回 `403`，本次通过已认证 GitHub CLI 同步 Step 2、Step 3、Step 4；
- 本次通过已认证的 GitHub 网页会话完成创建；
- 后续如希望完全使用 GitHub 连接器自动管理 Issue，仍需要补充 Issues 写权限；
- 远程对象必须以 GitHub 页面上的实际结果为准，不能因为已经准备了正文就宣称创建成功。
