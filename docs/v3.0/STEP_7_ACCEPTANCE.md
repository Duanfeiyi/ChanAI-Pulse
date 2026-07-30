# Step 7 验收清单

> 当前状态：本地实现与自动验证进行中，等待项目负责人人工审阅；尚未提交或创建 PR。

## GitHub

- [x] 创建 [Step 7 Issue #41](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/41)
- [x] 创建独立分支 `codex/v3-step-7-grid-search`
- [x] 项目负责人人工审阅
- [ ] 人工审阅通过后 commit/push/Draft PR
- [ ] PR 自审
- [ ] 项目负责人最终决定合并
- [ ] 关闭 Step 7 Issue 并更新 Roadmap

## 搜索契约

- [x] `GridSearchConfig`
- [x] `GridSearchResult`
- [x] `GridSearchManifest`
- [x] 任意非空子集的 8 个 Full 可接入参数
- [x] 真正的完整笛卡尔积枚举
- [x] 稳定候选顺序和 ID
- [x] 默认候选上限 500
- [x] 默认只保留 Top 5 完整 CIR

## 数据与评分边界

- [x] 只从任务 `known` 区域建立目标
- [x] 候选仍经 Step 6 Adapter 生成标准 CIR
- [x] 目标和候选仍经 Step 5 特性引擎分析
- [x] PDP 距离默认权重 50%
- [x] RMS 时延扩展分布距离默认权重 50%
- [x] 所有候选使用相同固定随机种子
- [x] 分数越小越好，0 表示当前评分下完全一致

## 运行控制

- [x] 串行执行
- [x] 进度事件
- [x] 协作式取消
- [x] 单候选失败记录并继续
- [x] 全部失败时整次搜索失败
- [x] 取消或未完成结果不能成为正式结果
- [x] 本机 Full 根目录不进入公开配置或 Manifest

## 测试与审阅

- [x] 2×3 精确枚举为 6 个组合
- [x] 重复、空、未知、不合法和超限候选反例
- [x] Mock 已知答案精确回收
- [x] 固定种子重复运行结果一致
- [x] target 区域泄漏防护
- [x] 单候选失败继续
- [x] 取消边界
- [x] 6GPCM-lite 小型真实搜索
- [x] 外置 Full 6GPCM 两候选真实冒烟
- [x] Full 核心调用前后哈希不变
- [x] MATLAB Code Analyzer：Step 7 文件 0 条消息
- [x] Step 7 Demo 默认 Lite 27候选隐藏窗口冒烟
- [x] Step 1～7 完整回归
- [x] 可视化审阅图片
- [ ] 项目负责人人工审阅

## 明确不在本 Step

- [x] 不实现随机局部搜索
- [x] 不实现 SA
- [x] 不训练或微调预测模型
- [x] 不打通预测参数到最终 CIR
- [x] 不修改正式三模块 UI
- [x] 不修改完整版 6GPCM 核心
- [x] 不把拟合分数说成预测准确率
