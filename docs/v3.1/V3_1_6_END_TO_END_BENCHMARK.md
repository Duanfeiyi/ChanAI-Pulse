# v3.1-6 参数预测到 Full 6GPCM 的独立端到端 Benchmark

v3.1-6 回答一个比“预测参数误差多小”更接近产品的问题：预测出的 P8 参数真正交给 Full 6GPCM 后，生成的 CIR/CTF 与真实参数生成的信道相差多少。

## 冻结实验协议

- 任务：内插、外推；参数包均为 P8。
- 候选：Persistence、Linear、AR、Kalman、GRU、LSTM、TCN、DLinear、NLinear、v3.0 正式基线，以及单独报告的安全适配结果。
- 参数级评测：Validation/Test 的全部窗口，按路线聚合；保留原单位误差、NRMSE 和 v3.1-3 敏感度加权 NRMSE。
- Full 6GPCM 评测：每条路线最后一个窗口的第一个目标点；Validation 使用固定 SHA-256 排名的 5 条路线，Test 使用全部 18 条路线。
- 稳定性：Test 的固定 6 条路线使用 31601、31602、31603 三个种子，其余使用 31601。
- 公平性：真实参数和预测参数使用相同场景、载频、速度、Tx/Rx、目标点与派生随机种子。
- 信道网格：`Nt=4`、64 个固定 CTF 频点、100 MHz 带宽、128 点零填充 IFFT 时延网格。
- Test 规则：Validation 门禁通过后才能创建；Test 不得改变 Registry、阈值或普通模式默认模型。
- 适配语义：独立的在线适配审计可以使用同一 Test 路线中严格早于当前目标的已知区标签；隐藏目标区真值永不参与适配、Registry 或阈值选择。该结果与未适配主报告分开。

协议的机器可读版本是 `configs/v31_6_end_to_end_benchmark.json`。

## 两阶段工作流

第一阶段在 Validation 上冻结并验证完整管线：

1. Python 使用 target-free request 运行 Registry v2 全部候选；
2. 已知区域适配数据必须与真实目标同路线、且所有标签严格早于真实目标；
3. 生成参数级全窗口 CSV 与 Full 6GPCM 代表点配对 CSV；
4. MATLAB 通过只读公共 Adapter 生成真实侧和预测侧 CIR/CTF；
5. 主要指标有限、配置哈希一致、Test 未使用且 Full 6GPCM 核心未改变时，写出 Validation Gate。

第二阶段只做一次 Test：

1. Test 导出必须绑定已通过的 Validation Gate；
2. 运行全部 18 条路线和固定多种子子集；
3. 输出正式描述性证据，但不依据 Test 结果修改任何选择规则；
4. 大型逐行结果保存在 Git 外部，仓库只保留小型摘要和来源哈希。

## 指标

- 参数：路线级参数 NRMSE、敏感度加权 NRMSE、逐参数原单位误差。
- 复杂信道：complex NMSE/NRMSE、幅度 NRMSE、相位 MAE、复相关系数。
- 时延：固定网格 PDP NRMSE、RMS delay spread 绝对误差。
- 空间：归一化空间相关矩阵差异。
- 时间/频率：相邻快拍相干性、相邻频点相干性、短窗 Doppler power NRMSE。
- 统计：均值、标准差、中位数、P90/P95、路线级 95% bootstrap CI、相对当前推荐模型的路线胜率。
- 耗时：批量推理、适配、真实信道生成、预测信道生成和指标计算耗时。

公共 Adapter 当前不输出射线角度，所以角谱指标必须显示为 unavailable，不能用零值代替。SISO 路线只有一个 Tx×Rx 链路，空间相关差异同样不可定义。`Nt=4` 只支持短窗时间/Doppler 诊断，不代表长序列多普勒研究。

## 运行入口

参数导出：

```powershell
python tools/python/run_v31_6_benchmark.py validation `
  --config configs/v31_6_end_to_end_benchmark.json `
  --data-directory <predictor_bundles> `
  --registry-root models/official/v3.1.0 `
  --corpus-manifest <corpus_manifest.json> `
  --output-directory <validation_export>
```

Full 6GPCM Validation：

```matlab
addpath(genpath(fullfile(repositoryRoot, "core")));
run_v31_6_full_benchmark(pairCsv, exportManifest, protocolConfig, outputDirectory);
```

Test 参数导出还必须提供 `--validation-gate`；Test 的 MATLAB 调用还必须提供 `ValidationGate=...`。

最终小型报告由 `tools/python/build_v31_6_report.py` 生成。工具会再次核验配置、Gate、Test 导出和信道结果的绑定关系，并确保报告不含外部绝对路径。

## 产品结论边界

v3.1-6 可以判断参数预测经 Full 6GPCM 后的端到端影响，也能显示某个模型在本次独立 Test 上的描述性表现。它不会自动将 Test 排名最高的模型改为普通模式默认模型。当前普通模式仍由冻结的 Registry v2 决定：内插 Persistence、外推 Kalman；神经网络继续作为高级/研究候选，除非未来通过预先声明的新准入实验。
