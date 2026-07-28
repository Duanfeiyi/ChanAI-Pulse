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

- [ ] Step 0：冻结需求、版本、资产和协作边界
- [ ] Step 1：定义统一 CIR/CTF 数据标准
- [ ] Step 2：制作四类标准测试数据
- [ ] Step 3：验证完整版 6GPCM 最小无界面调用
- [ ] Step 4：完成模块一信道数据输入流程
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
- [ ] 项目负责人审阅 Step 0 文档；
- [ ] Step 0 PR 合并到 `main`；
- [ ] 关闭 Step 0 Issue。

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

2026-07-28 检查结果：

- 仓库存在且当前浏览器会话可以看到仓库设置；
- 已创建 `ChanAI Pulse v3.0.0` Milestone（编号 1）；
- 已创建 Roadmap Issue #21；
- 已创建 Step 0 Issue #22；
- 两个 Issue 已指派给 `Duanfeiyi` 并关联 Milestone；
- GitHub 连接器创建 Issue 返回 `403 Resource not accessible by integration`；
- 本次通过已认证的 GitHub 网页会话完成创建；
- 后续如希望完全使用 GitHub 连接器自动管理 Issue，仍需要补充 Issues 写权限；
- 远程对象必须以 GitHub 页面上的实际结果为准，不能因为已经准备了正文就宣称创建成功。
