# Step 6 自动验证记录

## 1. 环境

- 日期：2026-07-30
- MATLAB：R2024b
- 数据契约：`v3.0-data-contract.1`
- GeneratorConfig：`v3.0-generator-config.1`
- GenerationResult：`v3.0-generation-result.1`
- 外置 Full 6GPCM：只读调用，不记录本机根目录

## 2. Adapter 契约

```text
PASS: Step 6 shared Generator Adapter contract and error paths.
```

验证内容：

- Mock 和 Lite 固定种子结果可复现；
- Mock 按 `Tx/Rx/Npath/Nt/N_sample` 生成五维复数 CIR；
- Lite 把历史输出转换为标准五维 CIR；
- Mock、Lite、Full 均可按明确绝对频率轴生成 CTF；
- Full 项目自有测试替身满足统一结果契约；
- Windows 正斜杠和反斜杠形式均能定位同一外置引擎；
- Full 缺失、几何不支持和预先取消均返回明确结果；
- Full 失败时不会静默回退 Lite；
- 公开 Manifest 不包含本机 `engine_root`。

## 3. 真实完整版 6GPCM

```text
PASS: real full 6GPCM Step 6 Adapter and core-integrity check.
```

实际结果：

```text
backend = full_6gpcm
status = PASS
outcome = SUCCEEDED
CIR = [Tx=2, Rx=2, Npath=240, Nt=2, N_sample=1]
CTF = [Tx=2, Rx=2, Nf=16, Nt=2, N_sample=1]
core_unchanged = true
```

运行前后核对外置引擎文件树哈希，核心保持不变。

## 4. Demo 冒烟

```text
PASS: Step 6 Mock demo smoke.
PASS: Step 6 Lite demo smoke and screenshot.
PASS: Step 6 real Full 6GPCM demo smoke.
```

Demo 的成功结果会显示 PDP、CTF、尺寸、状态和后台事件。回调发生错误时，
`UserData.success=false`，隐藏窗口测试不会再把“生成成功但渲染失败”误判为通过。

## 5. Step 1～6 回归

```text
PASS: v3 CIR/CTF data, task, capability, and HDF5 contracts.
PASS: four deterministic v3 standard CIR/CTF fixture pairs.
PASS: Step 3 full 6GPCM probe contract and error paths.
PASS: Step 4 input pipeline, task presets, and legacy adapters.
PASS: Step 5 unified characteristics, registry, and renderer.
PASS: 6GPCM-lite generator produces deterministic synthetic channel tensors.
PASS: Step 6 shared Generator Adapter contract and error paths.
PASS: real full 6GPCM Step 6 Adapter and core-integrity check.
```

## 6. 静态检查

对 Step 6 新增和修改的 14 个 MATLAB 文件运行 R2024b Code Analyzer：

```text
CHECKCODE_MESSAGES=0
```

## 7. Python 环境说明

本 Step 没有修改 Python 代码。尝试运行既有 Python 数据契约测试时，当前
项目 Python 环境缺少 `pytest` 和 `h5py`，所以测试未启动；这不是测试断言
失败。Step 1～5 MATLAB 跨格式回归已经通过。本记录不把未执行的 Python
测试标记为通过。

## 8. PR 交付

- 分支：`codex/v3-step-6-generator-adapter`
- 实现提交：`101c954 feat(v3): add Step 6 generator adapter`
- PR：[PR #39](https://github.com/Duanfeiyi/ChanAI-Pulse/pull/39)
- 目标分支：`main`
- PR 自审：23个预期文件，GitHub 判定 `MERGEABLE`
- 项目负责人已合并 PR #39；
- 合并提交：`94da784d94ea5dc1a1af897253ba93f748fee593`；
- Step 6 Issue #38 已按 `Closes #38` 自动关闭；
- 仓库没有为该分支报告远程自动检查；本记录中的本地 MATLAB 回归、
  真实 Full 6GPCM 完整性测试和静态检查作为自动验证依据。

## 9. 当前结论

自动验收、项目负责人人工审阅、PR 自审和最终合并均已完成。
Step 6 正式结束，下一阶段为 Step 7 真正的 Grid Search。
