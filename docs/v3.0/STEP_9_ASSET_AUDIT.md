# Step 9 预测相关历史资产复查

## 1. 复查范围

- 当前 `ChanAI-Pulse` 仓库；
- 本机整理版目录 `SRTP_智能预测信道模型_整理版`；
- 已登记的完整版 6GPCM 外置资产边界。

本次只阅读和判断复用方式，没有把真实测量数据、第三方权重或外部核心复制到
公开工作分支。

## 2. 当前仓库能继续使用的内容

| 资产 | 结论 | Step 9 处理 |
|---|---|---|
| `build_sliding_windows.m` | B | 复用滑窗思想；旧输出 `[sample,feature,time]` 且只预测单点，不能直接作为新契约 |
| `prepare_temporal_prediction_experiment.m` | A/B | 保留“先切分、再滑窗、训练集统计”的正确方向；改为按组切分和统一三维顺序 |
| `create_chronological_train_val_test_split.m` | B | 可参考时间隔离，但不能替代路线/场景级防泄漏 |
| `normalize_samples.m` | D（本任务） | 旧函数逐样本 Min-Max，会造成语义不一致；Step 9 不使用 |
| `train_prediction_model.m` 与 TCN/LSTM/GRU 骨架 | B | 留给 Step 10，经 Predictor Adapter 和新形状适配后使用 |
| Step 7/8 Grid、SA 和统一入口 | A | 用于从局部上传信道形成 `grid_fitted/sa_fitted` 参数标签 |

## 3. 整理版中的旧 GRU

找到早期 MATLAB/Python GRU 预测实验和输入输出 MAT 文件。其特点包括：

- 部分路径和特征数硬编码；
- 使用逐样本 Min-Max；
- 存在普通随机切分；
- 主要直接预测 DPSD 幅度，而不是当前冻结的 6GPCM 参数序列。

因此它适合作为“曾经做过预测实验”的算法参考，但不能直接成为 Step 9 正式数据
接口，也不能证明 v3.0 的参数预测已经完成。

## 4. 整理版中的 WiFo

WiFo 的主要思路是把复数 CSI 拆成实部/虚部通道，通过时频掩码进行恢复。它有
Python/PyTorch、外部依赖、权重和专用 HDF5 数据。

可借鉴：

- 掩码任务表达；
- 预训练模型与下游适配的思想；
- 复数 CSI 的双通道处理方式。

不能直接复用为 Step 9 标准预测器，原因是：

- 它预测的是复数 H/CSI，而 Step 9 第一版预测 `DS_mu/KF_mu`；
- 输入语义、维度和任务标签不同；
- 上游许可证、权重与数据授权仍未完整确认；
- GPU 与 PyTorch 运行边界应在 Step 10 单独评估。

## 5. 完整版 6GPCM

Step 9 不修改或复制完整版核心。它在当前链条中的作用是：

1. 提供 `generator_truth` 参数及其生成信道；
2. 作为 Grid/SA 候选生成后端；
3. 在 Step 11 把预测参数重新变成完整复数 CIR。

## 6. 复查后的计划调整

- 不沿用旧逐样本 Min-Max，新增训练组专属 Z-score Manifest；
- 不沿用普通随机相邻窗切分，新增 `group_id` 级切分；
- 不把旧 DPSD/CSI 预测输出冒充 6GPCM 参数；
- Step 9 只完成数据契约，旧 TCN/LSTM/GRU 与 WiFo 候选统一延后到 Step 10；
- 公开仓库只加入本项目生成的小型确定性参数 fixture。
