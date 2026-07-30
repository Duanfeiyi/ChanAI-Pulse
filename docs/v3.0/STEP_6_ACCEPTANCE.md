# Step 6 验收清单

> 当前状态：项目负责人已合并 PR #39，Step 6 正式完成。

## GitHub

- [x] 创建 [Step 6 Issue #38](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/38)
- [x] 创建独立分支 `codex/v3-step-6-generator-adapter`
- [x] 项目负责人人工审阅
- [x] 人工审阅通过后 commit/push/Draft PR
- [x] [Draft PR #39](https://github.com/Duanfeiyi/ChanAI-Pulse/pull/39)
- [x] PR 自审：23个预期文件、目标 `main`、GitHub 判定 `MERGEABLE`
- [x] 项目负责人最终决定合并
- [x] PR #39 已合并到 `main`
- [x] Step 6 Issue #38 已关闭

## 统一契约

- [x] `GeneratorConfig`
- [x] `GenerationResult`
- [x] `GenerationManifest`
- [x] PASS/WARNING/FAIL
- [x] SUCCEEDED/CANCELLED/FAILED
- [x] `Tx/Rx/Npath/Nt/N_sample` 明确分离
- [x] 可选明确频率轴 CTF
- [x] 本机外置路径不进入公开 Manifest

## Adapter

- [x] `MockGeneratorAdapter`
- [x] `Lite6GPCMAdapter`
- [x] `Full6GPCMAdapter`
- [x] Full 核心只读且调用前后核对哈希
- [x] Full 缺失时不静默回退 Lite
- [x] Full 未暴露配置明确拒绝而非忽略

## 后台服务

- [x] 无界面统一入口
- [x] 阶段与进度事件
- [x] 协作式取消协议
- [x] Mock/Lite 样本间取消
- [x] Full 核心调用前后取消及能力限制说明

## 测试与审阅

- [x] Mock 固定种子复现
- [x] Lite 固定种子复现
- [x] Full 测试替身契约
- [x] 真实外置 Full 冒烟和核心完整性
- [x] CIR/CTF 维度与 v3 数据契约
- [x] Full 缺失、不支持配置和取消反例
- [x] Step 1～6 回归
- [x] MATLAB Code Analyzer（新增 `.m` 文件 0 条消息）
- [x] 独立 Step 6 Demo 隐藏窗口冒烟测试
- [x] Step 6 可视化审阅图

## 明确不在本 Step

- [x] 不实现 Grid Search
- [x] 不实现随机局部搜索或 SA
- [x] 不训练或微调预测模型
- [x] 不打通预测参数到 CIR
- [x] 不修改正式三模块 UI
- [x] 不修改完整版 6GPCM 核心
