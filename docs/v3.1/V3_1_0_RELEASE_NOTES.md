# ChanAI Pulse v3.1.0 Release Notes

## 本次正式版的核心成果

v3.1 在 v3.0 的可信平台上完成四件事：让 Full 6GPCM 随仓库分发并下载即用；建立规模更大、划分更严格、可复现的训练与验证数据；公平比较 Persistence/Linear/AR/Kalman 与 GRU/LSTM/TCN/DLinear/NLinear 等候选；并用独立 Benchmark 判断预测参数经过 Full 6GPCM 后是否仍能生成可信 CIR/CTF。

v3.1-7 把上述能力接入正式 `ChannelSimulatorV3App`：不再受固定 16 个已知点→4 个目标点限制，产品从上传数据的已知区直接观测真实 P8 序列，逐参数回测选模（允许 Hybrid），支持任意长度外推与双向内插，用警告而非拒绝处理性能一般的情况，并保留旧 16→4 神经 checkpoint 的透明滚动兼容。

## v3.1 各阶段新增

- **v3.1-0**：冻结 v3.0.0 对照组、数据划分与 16→4 实验合同（PR #66）。
- **v3.1-1**：Full 6GPCM 完整入库（586 文件、约 94 MB）、自动发现与零配置生成（PR #68）。
- **v3.1-2**：扩充可复现参数语料与 Experiment Manager 最小版（PR #69）。
- **v3.1-3**：P2/P4/P6/P8 敏感度与消融，冻结 P8（内插）/P8（外推）（PR #70、#71）。
- **v3.1-4**：Persistence/Linear/AR/Kalman/GRU/LSTM/TCN/DLinear/NLinear 公平训练与调参（PR #72）。
- **v3.1-5**：ModelRegistry v2、官方实验 checkpoint、安全回退与受控微调（PR #73）。
- **v3.1-6**：参数预测→Full 6GPCM→CIR/CTF 的独立端到端 Benchmark（PR #74，660 对对照）。
- **v3.1-7**：真实 P8、任意长度预测与正式产品接入（PR #75）。

## v3.1-7 产品行为

- 从上传已知区 CIR/CTF 按原顺序直接观测 `DS_mu`、`KF_mu`、`num_clusters`，不再把一组聚合标定值重复成伪序列；不可辨识字段（例如窄带单径的 `DS_mu`）动态冻结为标定值，不导致整次运行失败。
- 普通模式逐参数回测选模，可形成 Hybrid；新增 Quadratic、Holt、Harmonic/Fourier、Adaptive AR 等趋势候选。
- 任意长度内插采用左→右、右→左两次预测并按边界距离融合。
- 高级手选模型即使回测或连续性较差也只显示 WARNING、仍执行且不静默替换；只有任务/运行时/checkpoint/数值/生成器硬错误才拒绝。
- 手选模型某参数已知区误差超过本地最佳基线 4 倍时，启用透明 `local_guard`（至少保留 10% 手选权重），UI 与 Manifest 均记录。
- 旧 16→4 神经 checkpoint 保留为 legacy 实验权重；任意目标长度使用有状态滚动兼容并记录误差累积风险，不伪装成新训练的变长官方权重。

## 冻结的产品边界

- 正式目标生成仍限样本/位置轴；Time/Frequency 完整目标预测属于 v3.2。
- Full 6GPCM 核心未修改，所有接口化、参数映射、兼容性判断与回退均由外围 Adapter 完成。
- 准确度只在独立 `ChannelBenchmark` 展示；产品 UI 的“已知区回测”不是未知目标区准确率。
- 产品预测路径不读取目标区域 Ground Truth；真值仅由独立 Benchmark 或验收在预测完成后读取。
- 神经 checkpoint 是实验候选，不是普遍优于基线的保证。

## 发布说明

`v3.1.0` 是本次正式源码版本。v3.1-7 的 PR #75 已由 `Duanfeiyi` 手动合并到 `main`。
GitHub `v3.1.0` Tag/Release 必须在下列最终动作完成后，由项目负责人手动创建：

1. v3.1-7 人工 UI A~I 验收通过；
2. PR #75 由 `Duanfeiyi` 手动合并；
3. 版本号与发布文案收尾 PR 由 `Duanfeiyi` 手动合并；
4. 在最终干净 `main` revision 上重新生成基线 Manifest 并确认 `git_dirty=false`；
5. 项目负责人明确批准发布。

Codex 不会自行合并 PR 或创建正式发布 Tag/GitHub Release。
