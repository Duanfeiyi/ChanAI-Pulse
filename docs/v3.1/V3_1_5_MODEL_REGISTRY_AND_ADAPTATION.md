# v3.1-5：官方 Base Model、ModelRegistry v2 与安全微调

## 1. 本步骤交付什么

v3.1-5 把 v3.1-4 的正式实验结果变成克隆仓库后即可调用的模型产品包：内插和外推各包含 GRU、LSTM、TCN、DLinear、NLinear 五个 P8 checkpoint，并由 ModelRegistry v2 统一登记兼容条件、验证证据、推荐结果和文件哈希。

普通用户继续由系统选择经过离线验证冻结的安全模型：

- 内插：Persistence；
- 外推：Kalman。

这不是因为神经网络文件不存在，而是 v3.1-4 中没有任何训练模型同时通过全部预注册准入门槛。五类神经模型可以供高级用户手动研究和比较，但系统不会把它们伪装成默认最优模型。

## 2. 克隆后可用的模型

| 类型 | 内插 | 外推 | 普通模式自动推荐 | 高级模式可手选 | 可做输出头微调 |
|---|---:|---:|---:|---:|---:|
| Persistence | 内置 | 内置 | 内插推荐 | 是 | 否 |
| Linear | 内置 | 内置 | 否 | 是 | 否 |
| AR(4) | 内置 | 内置 | 否 | 是 | 否 |
| Kalman | 内置 | 内置 | 外推推荐 | 是 | 否 |
| GRU | checkpoint | checkpoint | 条件适配通过后可采用 | 是 | 是 |
| LSTM | checkpoint | checkpoint | 条件适配通过后可采用 | 是 | 是 |
| TCN | checkpoint | checkpoint | 条件适配通过后可采用 | 是 | 是 |
| DLinear | checkpoint | checkpoint | 否 | 是 | 否 |
| NLinear | checkpoint | checkpoint | 否 | 是 | 否 |

官方包位于 `models/official/v3.1.0/`，共 10 个 checkpoint 和 2 份 Registry。实验搜索过程中的其他 checkpoint、语料、缓存和大型输出不进入 Git。

## 3. 普通模式会怎样工作

```text
读取目标为空的预测请求
→ 检查任务、P8 顺序、单位和 16→4 形状
→ 使用 Registry 冻结推荐
→ 若另有合规的已知区域标签，尝试 GRU/LSTM/TCN 输出头微调
→ 在已知区域内部的独立验证集上比较
→ 同时超过原 checkpoint 和安全基线，且达到改善门槛：采用最佳适配模型
→ 否则：回滚到 Persistence（内插）或 Kalman（外推）
```

如果输入超过 Registry 声明的分布范围，自动路径不尝试微调，直接保留安全基线并在结果中记录 `distribution_guard_safe_fallback`。所有模型选择、回滚原因、候选尝试、Registry 哈希和 checkpoint 哈希都会写入结果。

## 4. 微调的安全边界

用户上传的数据不能“读一下就默认把整个通用模型改掉”。v3.1-5 采用以下限制：

1. 只允许 GRU、LSTM、TCN 的输出头更新，编码器保持冻结；
2. 只使用用户明确提供的、带标签的已知区域；
3. 已知区域内部必须再划分适配训练集和验证集；
4. 适配训练和适配验证都不能与本次待预测目标区域重叠；
5. 适配后没有达到验证改善门槛时自动回滚；
6. 预测目标区域 Ground Truth 不进入选择、训练或验证；
7. `force` 只表示“缺少条件时明确报错”，不表示允许绕过泄漏与兼容性检查。

因此，checkpoint 提供可复用的起点，微调负责适应用户数据；它不会消除任务、参数顺序、单位、输入长度或数据分布不兼容的问题。

## 5. Python 命令行使用

先准备符合 P8 合同、且不含目标标签的 predictor request JSON。自动模式示例：

```powershell
python tools/python/run_step10_predictor.py predict-request `
  --request <your_request.json> `
  --registry models/official/v3.1.0/extrapolation/extrapolation_model_registry_v2.json `
  --selection auto `
  --adaptation auto `
  --adaptation-data <your_known_region_p8.h5> `
  --output <prediction.json> `
  --device cpu
```

克隆后可先把 `<your_request.json>` 换成 `demo_data/v31_5/requests/extrapolation_neutral_p8_request.json` 做零标签冒烟测试。该公开请求的输入等于 Registry 训练均值，只验证接口和模型加载，不代表准确度样例。

没有独立已知区域标签时，省略 `--adaptation-data`；自动模式会使用冻结基线。高级用户手选 GRU：

```powershell
python tools/python/run_step10_predictor.py predict-request `
  --request <your_request.json> `
  --registry models/official/v3.1.0/extrapolation/extrapolation_model_registry_v2.json `
  --selection manual `
  --model gru `
  --adaptation off `
  --output <prediction.json> `
  --device cpu
```

`--model` 可选 `persistence`、`linear`、`ar`、`kalman`、`gru`、`lstm`、`tcn`、`dlinear`、`nlinear`。手选非推荐模型时，结果会明确记录 `manual_non_recommended: true`。

## 6. MATLAB Adapter 使用

现有 MATLAB Adapter 已支持 Registry v2。高级调用示例：

```matlab
config = default_predictor_adapter_config();
config.selection_mode = "manual";
config.requested_model = "gru";
config.adaptation_mode = "off";

result = run_predictor_request_adapter( ...
    "your_request.json", ...
    "models/official/v3.1.0/extrapolation/extrapolation_model_registry_v2.json", ...
    config);
```

普通调用保持 `selection_mode="auto"`。若设置 `adaptation_mode="auto"` 并提供 `adaptation_data_path`，Adapter 会执行同一套安全适配与回滚规则。

## 7. 兼容性和防篡改

加载 Registry v2 时会检查：

- 任务是内插还是外推；
- context layout；
- P8 参数名称、顺序和单位；
- 输入长度 16、输出长度 4、参数数 8；
- checkpoint 相对路径不能逃逸模型包；
- checkpoint SHA-256 必须与 Registry 一致；
- checkpoint 内嵌模型类型必须与登记类型一致。

任何硬兼容条件不满足都会明确报错，不会静默换成另一个神经模型。

## 8. 本步骤与后续步骤的边界

v3.1-5 已完成模型文件分发、Registry、Python 服务、MATLAB Adapter、高级手选和安全微调逻辑。正式 `ChannelSimulatorV3App` 中的完整可视化模型选择、状态展示及“上传原始信道→提取 P8→预测”的产品交互仍安排在 v3.1-7；这是 UI 产品接入工作，不应在底层链路尚未完成时伪装成已经接通。

下一步 v3.1-6 将独立评价“预测 P8 → Full 6GPCM → CIR/CTF”的端到端结果。只有独立 Benchmark 才能形成正式准确度结论。

## 9. 验收要点

- 两份 Registry 均含 9 个可选模型；
- 10 个 checkpoint 均可在 CPU 上安全加载且哈希一致；
- 普通模式冻结为内插 Persistence、外推 Kalman；
- 高级模式可运行全部 9 种模型；
- P8 单位不一致、checkpoint 被修改、路径逃逸都会被拒绝；
- 自动微调只能接受经已知区域验证的改善，否则回滚；
- 适配训练或验证区域与实际目标重叠时拒绝执行；
- 旧版 ModelRegistry v1 与 Step 10 行为继续通过回归。
