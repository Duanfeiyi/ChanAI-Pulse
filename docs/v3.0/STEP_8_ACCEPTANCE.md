# Step 8 验收清单

> 当前状态：本地实现、完整回归和项目负责人人工审阅均已完成，允许提交、
> push 并创建 PR。

## GitHub

- [x] 创建 [Step 8 Issue #44](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/44)
- [x] 创建独立分支 `codex/v3-step-8-sa-optimizer`
- [x] 项目负责人人工审阅
- [ ] 人工审阅通过后 commit、push、创建 PR
- [ ] PR 自审
- [ ] 项目负责人最终决定合并
- [ ] Step 8 Issue 关闭
- [ ] Roadmap 勾选 Step 8

## 算法与接口

- [x] 统一 `OptimizationConfig`
- [x] 统一 auto/Grid/SA 结果与 Manifest
- [x] 共享 known 目标、生成器和评分器
- [x] 项目自有 `random_greedy` 对照基线
- [x] 项目自有、无需额外工具箱的透明 SA
- [x] 8个可调参数的任意非空子集
- [x] 离散、连续、整数变量和显式边界
- [x] 初值投影、高斯邻域、降温步长
- [x] Metropolis 接受规则
- [x] 重复候选缓存
- [x] Top 5 完整 CIR

## 决策与运行边界

- [x] `auto`、`grid`、`sa`
- [x] Mock/Lite/Full 自动 Grid 上限
- [x] 记录请求、实际策略、来源和理由
- [x] 手动 Grid 不适用时失败，不静默切换
- [x] 生成器种子 3103 / 优化器种子 8103
- [x] 预算、温度、无改进和连续失败停止
- [x] 单候选失败继续
- [x] 协作式取消
- [x] 本机外置路径脱敏
- [x] Full 6GPCM 核心不修改

## 测试与审阅

- [x] 自动选择和手动覆盖边界
- [x] Mock 已知答案
- [x] Random Greedy 不接受较差移动
- [x] SA 接受概率独立测试
- [x] 缓存与停止原因
- [x] 取消路径
- [x] 6GPCM-lite 冒烟
- [x] 真实 Full 6GPCM 冒烟
- [x] 独立 Demo 冒烟
- [x] 两张实际运行审阅图
- [x] MATLAB Code Analyzer 0条消息
- [x] Step 1～8 完整回归
- [x] 项目负责人人工审阅

## 明确不在本 Step

- [x] 不训练或微调预测模型
- [x] 不生成模块三预测结果
- [x] 不把拟合距离称为预测准确率
- [x] 不修改正式三页 UI
- [x] 不修改完整版 6GPCM 核心
