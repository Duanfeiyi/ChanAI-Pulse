# ChanAI Pulse v3.0 基线文档

> 状态：Step 0～4 已完成并合并；Step 5 实现与人工审阅已完成，等待 PR 合并
>
> 决策日期：2026-07-28
>
> 项目负责人及 PR 最终批准人：`Duanfeiyi`

本目录用于冻结 ChanAI Pulse v3.0 的产品需求、资产边界、版本规则和协作方式。后续实现发生争议时，先查阅本目录，再决定是否修改代码。

## 已确认的项目原则

1. v3.0 保持三个模块，不重新设计整体页面结构。
2. 模块一负责数据输入、格式检查、内插/外推任务设置和输入信道特性展示。
3. 模块二负责 6GPCM 信道生成、Grid Search、随机搜索基线和 SA 优化。
4. 模块三先预测信道参数，再调用 6GPCM 生成目标区域的复数 CIR。
5. 模块一和模块三共享相同的信道特性计算与图表能力判断规则。
6. 软件内部不展示预测准确度；准确度验证放在独立 Benchmark 中。
7. MATLAB GUI 继续保留，底层算法允许使用 MATLAB 或 Python，但必须通过清晰接口连接。
8. 仓库继续公开；经项目负责人确认允许纳入的第三方资源可以上传，但必须保留许可证、来源和署名。
9. 完整版 6GPCM 的核心实现不修改，只允许外围封装、适配和增加接口。
10. 每个可验收成果使用短期分支和 PR 合并到 `main`，最终由 `Duanfeiyi` 决定是否合并。

## 文档入口

- [正式需求](REQUIREMENTS.md)
- [需求追踪表](REQUIREMENTS_TRACEABILITY.md)
- [统一 CIR/CTF 数据契约](DATA_CONTRACT.md)
- [数据接口调用指南](DATA_INTERFACE_GUIDE.md)
- [历史与第三方资产登记表](ASSET_REGISTER.md)
- [第三方代码和数据政策](THIRD_PARTY_POLICY.md)
- [版本命名规则](VERSIONING.md)
- [v3.0 开发与 PR 流程](DEVELOPMENT_WORKFLOW.md)
- [GitHub 制作计划](GITHUB_PLAN.md)
- [Step 0 验收清单](STEP_0_ACCEPTANCE.md)
- [Step 1 验收清单](STEP_1_ACCEPTANCE.md)
- [Step 1 验证记录](STEP_1_VALIDATION.md)
- [Step 2 四套标准数据说明](STEP_2_STANDARD_DATA.md)
- [Step 2 验收清单](STEP_2_ACCEPTANCE.md)
- [Step 2 验证记录](STEP_2_VALIDATION.md)
- [Step 2 PR前可视化审阅](STEP_2_VISUAL_REVIEW.md)
- [Step 2 可选QuaDRiGa示例](QUADRIGA_OPTIONAL_EXAMPLE.md)
- [Step 3 完整版 6GPCM 技术探针](STEP_3_FULL_6GPCM_SPIKE.md)
- [完整版 6GPCM 外置配置](FULL_6GPCM_EXTERNAL_SETUP.md)
- [Step 3 PR 前可视化审阅](STEP_3_VISUAL_REVIEW.md)
- [Step 3 自动验证记录](STEP_3_VALIDATION.md)
- [Step 3 验收清单](STEP_3_ACCEPTANCE.md)
- [Step 4 整理版数据审计](STEP_4_SOURCE_DATA_AUDIT.md)
- [Step 4 输入流水线接口指南](STEP_4_INTERFACE_GUIDE.md)
- [Step 4 自动验证记录](STEP_4_VALIDATION.md)
- [Step 4 人工与可视化审阅](STEP_4_VISUAL_REVIEW.md)
- [Step 4 验收清单](STEP_4_ACCEPTANCE.md)
- [v3.0 后续 UI 待办](UI_DEFERRED_TODOS.md)
- [Step 5 科学计算规则](STEP_5_SCIENTIFIC_RULES.md)
- [Step 5 接口指南](STEP_5_INTERFACE_GUIDE.md)
- [Step 5 验收清单](STEP_5_ACCEPTANCE.md)
- [Step 5 验证记录](STEP_5_VALIDATION.md)
- [Step 5 Demo 与图表人工审阅](STEP_5_VISUAL_REVIEW.md)
- [Step 6 Generator Adapter 接口指南](STEP_6_INTERFACE_GUIDE.md)
- [Step 6 验收清单](STEP_6_ACCEPTANCE.md)
- [Step 6 自动验证记录](STEP_6_VALIDATION.md)
- [Step 6 Demo 与人工审阅](STEP_6_VISUAL_REVIEW.md)

## 变更规则

本目录是基线，不等于永远不能修改。后续老师或团队提出新要求时：

1. 先说明为什么需要修改；
2. 更新对应的需求编号或资产记录；
3. 说明对代码、数据、测试和界面的影响；
4. 通过独立 PR 由项目负责人批准；
5. 不允许只改代码而不更新对应文档。
