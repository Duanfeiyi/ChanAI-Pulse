# Step 8 自动验证记录

## 1. 环境

- 日期：2026-07-30
- MATLAB：R2024b
- Generator Adapter：`v3.0-step6.1`
- Grid Search：`v3.0-step7.1`
- 参数优化：`v3.0-step8.1`
- Full 6GPCM：外置只读调用

## 2. Step 8 专项测试

```text
PASS: Step 8 unified optimizer, SA, cache, and auto strategy.
PASS: Step 8 6GPCM-lite SA smoke.
PASS: real Full 6GPCM Step 8 minimal SA smoke.
PASS: Step 8 interactive optimizer demo smoke.
PASS: Step 8 review sheet and Lite demo screenshot exported.
```

已验证：

- 小型全离散空间自动选择 Grid；
- 连续/整数区间或超过后端自动上限时选择 SA；
- 手动 Grid 不适用时明确失败；
- 标准 Metropolis 接受概率；
- 显式边界、初值投影、整数和物理规则；
- Mock 已知参数可由 Grid、SA、Random Greedy 找回；
- Random Greedy 从不接受较差移动；
- 固定 `3103/8103` 种子和 Manifest；
- 重复候选缓存不消耗实际目标评估预算；
- 无改进、温度、预算、连续失败和取消停止路径；
- 6GPCM-lite 真实生成与评分；
- Full 6GPCM 最小 SA 和核心未修改校验；
- 自动策略、三算法对照、SA温度/接受率、PDP/DS 图可渲染。

## 3. 完整回归

```text
PASS: v3 CIR/CTF data, task, capability, and HDF5 contracts.
PASS: four deterministic v3 standard CIR/CTF fixture pairs.
PASS: Step 3 full 6GPCM probe contract and error paths.
PASS: Step 4 input pipeline, task presets, and legacy adapters.
PASS: Step 5 unified characteristics, registry, and renderer.
PASS: 6GPCM-lite generator produces deterministic synthetic channel tensors.
PASS: Step 6 shared Generator Adapter contract and error paths.
PASS: real full 6GPCM Step 6 Adapter and core-integrity check.
PASS: Step 7 deterministic Cartesian Grid Search and safeguards.
PASS: Step 7 6GPCM-lite Grid Search smoke.
PASS: real Full 6GPCM Step 7 two-candidate Grid Search.
PASS: Step 8 unified optimizer, SA, cache, and auto strategy.
PASS: Step 8 6GPCM-lite SA smoke.
PASS: real Full 6GPCM Step 8 minimal SA smoke.
PASS: Step 1-8 complete MATLAB regression.
```

Step 8 新增核心、测试和 Demo 的 MATLAB Code Analyzer：

```text
CHECKCODE_MESSAGES=0
```

## 4. 当前结论

核心实现、专项测试、真实 Full 只读验证、Step 1～8 完整回归、静态检查、
可视化导出和项目负责人人工审阅均已通过。已获准 commit、push 和创建 PR。
