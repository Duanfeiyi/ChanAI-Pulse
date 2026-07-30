# Step 5 验证记录

## 1. 环境

- MATLAB：R2024b
- 输入合同：`v3.0-data-contract.1`
- Step 5 引擎：`v3.0-step5.1`

## 2. 四类标准 CIR

```text
narrowband_static_siso | PASS | 1/1 | heat=0
wideband_static_siso   | PASS | 3/3 | heat=1
wideband_static_mimo   | PASS | 6/6 | heat=1
wideband_dynamic_mimo  | PASS | 9/9 | heat=1
```

## 3. 四类标准 CTF

实际 HDF5 经过 Step 4 读取后：

```text
narrowband_static_siso_ctf.h5 | PASS | 1/1
wideband_static_siso_ctf.h5   | PASS | 3/3
wideband_static_mimo_ctf.h5   | PASS | 6/6
wideband_dynamic_mimo_ctf.h5  | PASS | 9/9
```

验证了均匀频率轴的 IFFT、频率自相关和显式 ULA 波束空间路径。

## 4. 任务隔离

动态 MIMO 80/20内插：

```text
原始 N_sample = 32
known = 26
target = 6
Step 5 分析 N_sample = 26
```

把 target 区复系数放大1000倍后，known 区 PDP 和其他结果保持不变。

## 5. CDF 样本规则

- 1个已知样本：三类经验 CDF 均不可用；
- 10个已知样本：CDF可用，整体状态为 WARNING；
- 32个标准样本：达到推荐数量，状态 PASS。

## 6. 降级路径

- `sample_semantics=independent`：附加热力图不可用；
- 移除时间轴和间隔：多普勒、时间自相关、多普勒扩展 CDF 不可用；
- 移除 AoA/AoD 和阵列几何：角度功率谱与角度扩展 CDF 不可用；
- 所有不可用 metric 的 x/y/z 保持空，不生成占位数据。

## 7. 严格可见图表复查

修正后，四套 CIR/CTF 的界面可见清单完全一致：

```text
窄带静态 SISO：功率                                      = 1
宽带静态 SISO：3张标准图 + 热力图                         = 4
宽带静态 MIMO：6张标准图 + 热力图                         = 7
宽带动态 MIMO：9张标准图 + 热力图                         = 10
```

- 标准 CIR 即使附带生成器 AoA/AoD，SISO 也不开放角度图；
- 宽带标准分类不把普通功率作为额外下拉项；
- `Tx=2, Rx=1, Nf=1, Nt=1, N_sample=1` 时空间相关不可用；
- 非四类标准组合的 `ideal_standard_plot_count=0`，不显示虚假 `x/10`；
- 自动测试比较精确图表 ID，不再只比较数量。

## 8. road1 与 WiFo

```text
road1 | PASS | available standard 3/6
WiFo  | PASS | available standard 3/6
```

两者均开放 PDP、DS CDF、空间相关和附加热力图；没有频率/角度伪图。

## 9. 数值不变量

- 所有可用 metric 的公开 x/y/z 均为有限值；
- 所有归一化功率图最大值为0 dB；
- PDP时延单调；
- 频率和时间自相关零间隔为1；
- 空间相关矩阵对角线为1；
- CDF横纵轴单调，末值为1。

## 10. Demo 与绘图

```text
PASS: Step 5 module-one demo smoke test.
PASS: narrowband SISO strict-gating Demo smoke test.
PASS: four Step 5 standard review sheets.
PASS: sanitized module-one Demo screenshot.
PASS: sanitized narrowband SISO gating screenshot.
```

截图只显示标准合成文件名，不包含本机绝对路径。
导出包由 `create_step5_export_bundle` 统一生成，带版本化 schema，并验证没有
复制源 `dataset`；Demo 只新建用户指定的 MAT，不修改原始 HDF5。

## 11. 静态检查

```text
CHECKCODE_MESSAGES=0
```

## 12. 回归

```text
PASS: v3 CIR/CTF data, task, capability, and HDF5 contracts.
PASS: four deterministic v3 standard CIR/CTF fixture pairs.
PASS: Step 3 full 6GPCM probe contract and error paths.
PASS: Step 4 input pipeline, task presets, and legacy adapters.
PASS: Step 5 unified characteristics, registry, and renderer.
PASS: Step 1-5 regression suite.
```

## 13. 完成状态

- 项目负责人人工审阅通过；
- PR #36 已合并到 `main`；
- Step 5 Issue #35 已关闭；
- Step 5 已完成，可以进入 Step 6。

## 14. PR 交付

- 分支：`codex/v3-step-5-characteristics-engine`
- 提交：`c1c2fc8 Implement Step 5 channel characteristics engine`
- Draft PR：[PR #36](https://github.com/Duanfeiyi/ChanAI-Pulse/pull/36)
- PR 目标为 `main`，已由项目负责人合并；
- 合并提交：`4bc50d02c9843ab8f0066a1f21e6ace304189045`；
- PR精确包含26个预期文件，不包含本地 `outputs/step5_review` 实测转换数据；
- 仓库当前没有为该分支报告远程自动检查，本地 MATLAB 回归和静态检查作为
  本 Step 的自动验证依据。
