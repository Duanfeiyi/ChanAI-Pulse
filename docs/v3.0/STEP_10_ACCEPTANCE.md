# Step 10 验收清单

> 当前状态：代码、自动验证和项目负责人人工审阅已完成；允许提交、push 和创建 PR，最终合并仍由项目负责人手动决定。

## GitHub

- [x] Issue #50 已建立
- [x] 独立分支 `codex/v3-step-10-predictor-adapter`
- [x] 项目负责人人工审阅通过
- [ ] 提交并 push
- [ ] 创建 PR
- [ ] 项目负责人手动合并 PR

## 模型与契约

- [x] `DS_mu/KF_mu`
- [x] `[N,16,2] -> [N,4,2]`
- [x] GRU
- [x] LSTM
- [x] TCN
- [x] Persistence 基线
- [x] Linear 基线
- [x] 内插双侧编码
- [x] 外推因果编码
- [x] 内插/外推模型文件隔离

## 选择与微调

- [x] 普通用户离线自动选择
- [x] 自动选择不读取本次目标真值
- [x] 高级用户手选 GRU/LSTM/TCN
- [x] 不兼容选择明确拒绝
- [x] `off/auto/force` 微调模式
- [x] 只更新输出头
- [x] 目标区域泄漏检查
- [x] 最小改善阈值
- [x] 早停、时间限制和回滚

## 接口与界面

- [x] Python CLI
- [x] MATLAB Adapter
- [x] JSON 预测输出
- [x] 正式无 Ground Truth 预测请求 JSON
- [x] 模块三正式风格 Demo 骨架
- [x] Demo 普通/高级模式
- [x] 产品界面没有准确度或 Ground Truth
- [x] CIR/CTF/1/3/6/9 图明确等待 Step 11
- [x] 外部测试审阅图

## 明确不在 Step 10

- [x] 不生成预测 CIR/H
- [x] 不接入模块三信道特性图
- [x] 不把 Transformer/PatchTST/iTransformer 作为交付门槛
- [x] 不宣称公开参考模型代表真实信道预测精度
- [x] 不自动合并任何 PR
