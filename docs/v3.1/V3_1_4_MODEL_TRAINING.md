# v3.1-4：P8 模型公平训练与准入

## 目标与边界

v3.1-4 在 v3.1-2 的公开合成路线语料和 v3.1-3 冻结的 P8 参数包上，分别为内插与外推任务训练、调参和比较候选模型。本阶段给出离线准入建议，但不改动 v3.0 产品 Registry、普通/高级用户界面或 Full 6GPCM 核心；这些产品化工作属于 v3.1-5 及以后。

正式比较池为：

- 简单与强基线：Persistence、Linear、AR(4)、常速度 Kalman；
- 可训练候选：GRU、LSTM、TCN、DLinear、NLinear；
- Transformer、PatchTST、iTransformer 保留为研究候选，不阻塞本阶段交付，也不因模型更复杂而默认准入。

外推模型只能读取历史 16 个已知点。内插可以读取目标缺口两侧各 8 个已知点。所有模型预测未来 4 个 P8 参数点；训练、验证和测试继续使用 v3.1-2 固定的 84/18/18 条路线级划分。

## 防泄漏流程

```text
固定 P8 语料与路线划分
→ 在 Train 上更新权重
→ 在 Validation 上搜索配置、早停和准入
→ 三随机种子汇总并冻结每类任务的候选
→ 仅用 Validation 预测对执行轻量 Full 6GPCM 门
→ 门通过后只打开一次 Test
```

搜索、早停、模型选择、准入和 Full 6GPCM 门都不读取 Test。`finalize-test` 要求已有成功的验证门清单，并以“不覆盖”方式创建唯一的 Test 结果文件；再次执行会明确失败。

## 调参与损失

跟踪配置见 [`configs/v31_4_model_study.json`](../../configs/v31_4_model_study.json)。第一阶段对每个模型执行两组小型配置搜索；第二阶段锁定验证最优配置，用三个固定随机种子报告均值、标准差、每条路线误差和最差路线。主结论使用训练集统计得到的逐参数 z-score 后等权 MSE。TCN 在本机一轮计时中 CPU 为约 17.7 秒、CUDA 为约 117.6 秒，因此保留完整候选但固定走 CPU，并使用 30 轮、5 轮耐心的有界预算；其余候选走请求设备并使用 60 轮、8 轮耐心。设备选择只影响计算位置，不改变数据、损失或准入规则。

另对验证表现最好的可训练结构执行一次“v3.1-3 Full 6GPCM 敏感度加权”消融。该消融只用于说明损失权重影响，不参与本轮模型选择，避免在同一验证集上继续追逐偶然收益。

## 准入规则

候选必须同时满足：

1. 三随机种子平均 NRMSE 相对本任务最强简单基线至少改善 10%；
2. 至少在 60% 的验证路线胜出；
3. 任一验证路线误差不超过对应基线的 2 倍；
4. 三随机种子 NRMSE 的相对标准差不超过 10%；
5. 冻结候选后通过只使用验证对的 Full 6GPCM 轻量门。

任一条件不满足时，结论必须是回退到该任务的最佳简单基线，而不是强行推荐神经网络。v3.1-4 的门只确认生成器可用性、参数映射和有限验证对上的下游合理性；最终独立 CIR/CTF 精度结论仍由 v3.1-6 负责。

## 本地运行

所有 checkpoint、日志、完整指标和生成器输出必须写到 Git 外资产目录。仓库只跟踪代码、配置、测试、本文档和不含本机路径的小型结论摘要。

```powershell
python tools/python/run_v31_4_model_study.py study `
  --data-directory <corpus>/predictor_bundles `
  --output-directory <assets>/experiments/v31_4_model_study.1 `
  --device auto
```

验证候选冻结后，在 MATLAB R2024b 中运行：

```matlab
report = run_v31_4_full_6gpcm_gate("<assets>/experiments/v31_4_model_study.1");
```

只有该门成功后，才执行一次：

```powershell
python tools/python/run_v31_4_model_study.py finalize-test `
  --study-manifest <experiment>/v31_4_model_study_manifest.json `
  --gate-manifest <experiment>/full_6gpcm_gate/v31_4_full_6gpcm_gate.json `
  --data-directory <corpus>/predictor_bundles `
  --device auto
```

## 自动化检查

`tests/python/test_v31_4_model_study.py` 覆盖 AR/Kalman 输出有限且不读取目标、DLinear/NLinear 两类任务形状、外推因果声明、配置一致性和多条件准入。既有 Step 10/11ABC 测试继续保护 GRU/LSTM/TCN、checkpoint、Registry 和请求预测兼容性。

## 正式结果

正式运行完成后，本节只记录可公开、可审查的小型摘要；完整实验资产保留在 Git 外。Test 结果是冻结选择后的描述性报告，不反向改变选择。

_待本次正式本地实验与 Full 6GPCM 验证门完成后填写。_
