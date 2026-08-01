# Step 12 F0–F5：四类信道端到端兼容性报告

> 状态：本地实现和自动验收完成，等待项目负责人人工审阅；尚未提交、push 或创建 PR。

## 1. 结论

四套标准数据均已从正式 `ChannelSimulator.m` 入口真实完成：

```text
导入与任务验证
→ 模块二已知区处理
→ 参数预测（不读取目标真值）
→ Lite 或 Full 生成 CIR/CTF
→ 同维度检查
→ 模块三特性分析
→ CIR/CTF/Manifest 导出和回读
```

| 数据类型 | 输入维度摘要 | 自动后端 | 模块二路径 | 输出标准图 | 结果 |
|---|---|---|---|---:|---|
| 窄带静态 SISO | 1×1，Nt=1，单抽头 | Lite | 窄带能力默认标定 | 1 | PASS |
| 宽带静态 SISO | 1×1，Nt=1，多径 | Lite | Grid/SA | 3 | PASS |
| 宽带静态 MIMO | 2×4，Nt=1，多径 | Full public API | Grid/SA | 6 | PASS |
| 宽带动态 MIMO | 2×4，Nt=16，多径 | Full public API | Grid/SA | 9 | PASS |

## 2. F0 发现的原始缺口

1. 普通模式固定选择 Lite，MIMO 到模块三才因 Tx/Rx 失败；
2. 历史 Full Adapter 只调用固定 `generate_channel_v1`，入口写死2×2×Nt=2；
3. 窄带输入没有宽带 PDP，Grid/SA 会正确拒绝，但平台没有合法回退；
4. Lite 原生输出多径，若直接使用会把窄带1图错误升级为宽带3图；
5. 独立目标连续性策略误伤了每个目标内部合法的 Nt 时间序列，动态 MIMO 只显示6图；
6. 之前的测试只分别验证“输入能画图”和“SISO能预测”，没有一项测试强制四类数据全部走到导出。

## 3. F1–F4 修正

- 保留历史固定 Full 入口供回归；新增 `Full6GPCMPublicApiAdapter`；
- 通过外部包的 `simulation_parameters / antenna_array / track / channel_model / get_CIR` 配置 Tx/Rx/Nt；
- 外部核心运行前后进行完整树 SHA-256，实测哈希均为 `e5e4ec49ef25090e2d472283914187967e801b38722e10a28694efa77bfccac0`；
- 自动选择排除 Mock：SISO优先Lite，MIMO选择Full public API；
- 默认资源上限为 `Tx×Rx≤64、Nt≤256、Tx×Rx×Nt≤4096`；超过上限标为资源不足，不误称格式不兼容；
- 窄带单抽头任务不伪造PDP/DS标定，使用版本化生成器默认值，并在Manifest中记录原因；
- 将窄带生成结果折叠为一个未分辨复抽头，保持Tx/Rx/Nt/N_sample；
- 独立目标之间仍禁止路线热力图；每个目标内部连续Nt的多普勒谱、时间自相关和多普勒扩展CDF不再被错误禁用；
- 输出必须与输入保持Tx/Rx/Nt，N_sample等于目标数量，Npath由生成器决定。

## 4. F5 自动证据

- `test_step12_full_flexible_external.m`：真实2×4 MIMO、时间维度、CTF和核心哈希；
- `test_step12_four_class_end_to_end.m`：四类正式App链路、1/3/6/9、同维度、导出回读；
- `test_step12_formal_ui.m`：正式入口、自动选择和目标真值隔离；
- Step 4/5/6/8/11回归用于确认输入、特性、旧固定Full、优化和PredictionResult没有被破坏。

## 5. 仍需明确保留的边界

- 当前四类正式验收使用样本轴外推；位置轴沿用同一目标样本生成链路；
- 时间轴和频率轴可以导入、验证和画输入图，但“在Nt或Nf内部补点”的端到端任务需要重构PredictionResult的目标维定义，不在本次四类样本轴验收中冒充完成；
- 模型仍为冻结的Persistence；精度提升、GRU/LSTM/TCN自动晋级属于v3.1；
- 产品内不显示准确度，Step 13外部Benchmark负责评价；
- Full public API的资源上限是工程保护，不代表6GPCM理论能力上限。

## 6. 人工验收入口

从项目根目录执行：

```matlab
close all force
clear classes
rehash
cd("D:\Codex_Feiyi\ChanAI-Pulse-v3-step12")
ChannelSimulator
```

逐按钮步骤见 `STEP_12_MANUAL_REVIEW_GUIDE.md`。
