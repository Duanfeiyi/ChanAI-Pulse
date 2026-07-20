# ChanAI Pulse 开发者精简路线

**最后更新：** 2026-07-17  
**读者：** 平台开发者、算法同学、数据同学和 PR 审阅者。  
**完整依据：** `07_confirmed_master_plan.md`

## 1. 我们要做什么

当前功率域预测继续保留为 Legacy Baseline。新主线先实现动态宽带 SISO 复数 `H(t,f)` 预测，再做多源预训练、用户快速适配，最后扩展到 MIMO 空时频 H。

长期平台定位是“面向全频段全场景研究”，不能描述为当前已经对任意频段和场景实现通用预测。

## 2. 数据来源

- QuaDRiGa：主要研究级仿真数据；
- DeepMIMO：射线追踪补充；
- 开放实测复数 CSI：真实微调与独立 Test；
- 6GPCM-lite：轻量基线、测试、GUI 和备用生成器。

所有数据进入统一 H 契约，必须记录轴、单位、载频、带宽、采样间隔、天线、轨迹、相位质量、来源和许可。

## 3. 两条管线

```text
Legacy Power:
PDP / DPSD → 旧 TCN/LSTM/GRU → 功率预测

Complex-H:
Complex H → Base Model → Adapter/Fine-tuning → Future Complex H
```

不得把 Power-only 数据伪装成复数 H，也不得在新管线稳定前删除旧管线。

## 4. 未来用户流程

```text
导入数据
→ 数据/相位/时间轴检查
→ 特性可视化
→ 选择 Base Model
→ 运行直接预测基线
→ 可选 QuaDRiGa 扩充
→ 快速适配（默认）或深度微调
→ Validation 检查，变差自动回退
→ 保存 Adapted Model
→ 预测未来 H
→ 复数、物理和通信系统指标
```

Base Model 只读；Adapted Model 必须独立保存。

## 5. 模型与指标

先做 Persistence、AR、Kalman，再做 TCN/LSTM/GRU Re/Im 双通道。复杂模型必须等统一 Benchmark 后再进入。

至少报告：

- complex NMSE、相关、幅度和相位误差；
- 经验 PDP/DS CDF、K-S 或 Wasserstein；
- 可达速率、容量或波束赋形损失；
- 训练、推理和适配成本。

## 6. 数据安全与实验边界

- 先按轨迹/场景/会话切分，再构造窗口；
- Synthetic 只进入训练或预训练；
- 真实 Test 不得参与生成器校准、微调或模型选择；
- 真正未来数据不得用于在线适配；
- 真实数据不提交 GitHub；
- 静态独立 drop 不得当成时间序列。

## 7. 最近实施顺序

1. 完成当前 App 模块化拆分与人工 UI 验收；
2. 修正 DS CDF、频率/时延轴等科学问题；
3. 冻结 SISO 复数 H 数据契约与首个任务；
4. 建立 QuaDRiGa 和开放数据 adapter；
5. 完成传统与 TCN/LSTM/GRU 复数基线；
6. 接入 Complex-H 平台流程；
7. 训练 Base Model；
8. 实现快速适配、回退和 Adapted Model；
9. 建立 Experiment Manager / Benchmark；
10. 扩展固定规模 MIMO。

## 8. PR 规则

- 一个 PR 只解决一组清晰问题；
- 结构拆分不混入科学算法修改；
- App 行为变化必须人工 GUI 验收；
- 保持旧功能可回退；
- Codex 不自动 merge，最终合并只由用户人工执行。

