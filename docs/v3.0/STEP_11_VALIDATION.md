# Step 11 自动验证记录

> 验证日期：2026-08-01

## 1. Mock 已知答案与错误路径

`tests/test_step11_prediction_generation.m` 验证：

- 四个目标分别派生不同且可重复的种子；
- 相同请求生成完全一致的复数 CIR/CTF；
- `DS_mu/KF_mu` 来源为预测，其他参数按标定、场景、默认值优先级补齐；
- 缺参数、`NaN`、越界参数和不兼容维度明确失败；
- 取消与单目标失败不发布部分结果；
- 独立目标禁用多普勒、时间相关和路线热力图；
- 归一化频率自相关不超过 1；
- HDF5/JSON/Manifest 导出并完成 CIR 往返读取；
- 缓存键包含结果定义输入。

结果：`PASS`。

## 2. Lite 集成

同一测试验证：

- Lite 四目标调用；
- CIR/CTF 维度；
- 固定请求的逐元素可重复性；
- 结果明确为 Preview/Warning，不冒充正式 Full。

结果：`PASS`。

## 3. Full 项目测试替身

验证：

- 四次目标调用和顺序合并；
- Preview 可完成接口测试；
- test double 不具备 formal eligibility；
- 正式模式拒绝测试替身；
- `Tx/Rx/Nt` 不兼容时在生成前失败。

结果：`PASS`。

## 4. 真实完整版 6GPCM

外置根目录：由原压缩包只读解压到仓库外的隔离临时目录，不进入 Git。

来源压缩包 SHA-256：

```text
fcf151adf94038a6cf10d86c6dd687938b085a8f78a64d6829b5439c1d6c5875
```

命令：

```matlab
run("tests/test_step11_full_6gpcm_external.m")
```

结果：

- 真实调用 `generate_channel_v1.m` 四次；
- CIR：`[2, 2, 240, 2, 4]`；
- CTF：`[2, 2, 16, 2, 4]`；
- 四次调用均验证核心树前后哈希一致；
- 所有目标明确记录 `target_position_injected=false`；
- 正式链路结果：`PASS`。

## 5. 完整回归

最终运行：

```matlab
run("tests/run_step1_to_step11_regression.m")
```

结果：Step 1～11 全部 `PASS`；其中 Step 6、7、8、11 均调用真实外置 Full，核心完整性检查通过。

Python 使用仓库现有 `unittest` 测试：

```powershell
python -m unittest discover -s tests/python -p "test_*.py" -v
```

结果：18 项全部通过。

MATLAB Code Analyzer 对 Step 11 新增和受影响文件进行静态检查：

```text
CHECKCODE_ISSUES=0
```

当前结论：工程实现和自动验证完成，等待项目负责人 PR 前人工审阅；尚未提交、push 或创建 PR。
