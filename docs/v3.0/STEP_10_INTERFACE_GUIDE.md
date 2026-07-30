# Step 10 通用预测模型与 Predictor Adapter 接口指南

## 1. 初学者先理解整条链

Step 9 已经把参数整理成统一“试卷”：

```text
输入  [N_example, 16, 2]
输出  [N_example,  4, 2]
参数  DS_mu、KF_mu
```

Step 10 做三件事：

1. 让 GRU、LSTM、TCN 学习这套输入输出关系；
2. 用统一 Predictor Adapter 调用它们；
3. 输出预测后的参数 JSON。

Step 10 **不生成 CIR**。Step 11 才会把预测参数交给 6GPCM，生成预测 CIR/H。

## 2. 内插和外推为什么分开

- 外推：已知过去 16 点，预测后面 4 点；
- 内插：已知左边 8 点和右边 8 点，补中间 4 点。

虽然形状相同，信息方向不同。因此模型文件和 ModelRegistry 分目录保存，不能混用：

```text
demo_data/v3_step10/models/
├─ extrapolation/
└─ interpolation/
```

外推网络只沿已知历史读取；内插网络分别编码左、右两侧，再合并信息。

## 3. 训练模型族

安装依赖：

```powershell
python -m pip install -r tools/python/requirements-v3-step10.txt
```

训练外推模型：

```powershell
python tools/python/run_step10_predictor.py train-family `
  --data demo_data/v3_step9/step9_extrapolation_standard.h5 `
  --output demo_data/v3_step10/models/extrapolation
```

命令会训练 GRU、LSTM、TCN，同时计算 Persistence、Linear 两个简单基线。

普通用户的自动模型只从 GRU/LSTM/TCN 中选择。选择依据是在训练阶段已经冻结的验证集 Normalized RMSE。正式预测时不读取目标区域 Ground Truth。

## 4. Python 预测接口

正式平台先生成**不含目标答案**的请求：

```powershell
python tools/python/run_step10_predictor.py make-request `
  --data demo_data/v3_step9/step9_extrapolation_standard.h5 `
  --output demo_data/v3_step10/requests/extrapolation_request.json `
  --partition test
```

这里从测试分区制作请求只是公开 Demo 的便捷方式。写出的 JSON 只有已知参数和位置，没有 `targets`。

普通模式预测：

```powershell
python tools/python/run_step10_predictor.py predict-request `
  --request demo_data/v3_step10/requests/extrapolation_request.json `
  --registry demo_data/v3_step10/models/extrapolation/extrapolation_model_registry.json `
  --output predicted_parameters.json `
  --selection auto
```

高级模式手选 GRU：

```powershell
python tools/python/run_step10_predictor.py predict-request `
  --request demo_data/v3_step10/requests/interpolation_request.json `
  --registry demo_data/v3_step10/models/interpolation/interpolation_model_registry.json `
  --output predicted_parameters.json `
  --selection manual `
  --model gru
```

如果模型任务、参数列、输入长度或输出长度不兼容，接口会明确报错，不会暗中替换模型。

## 5. MATLAB 调用

```matlab
addpath(genpath("core"));

config = default_predictor_adapter_config();
config.python_executable = "你的Python路径";
config.selection_mode = "auto";
config.adaptation_mode = "off";

result = run_predictor_request_adapter( ...
    "demo_data/v3_step10/requests/extrapolation_request.json", ...
    "demo_data/v3_step10/models/extrapolation/extrapolation_model_registry.json", ...
    config);
```

主要输出：

- `prediction_parameters`：反归一化并投影到物理边界后的预测参数；
- `prediction_normalized`：模型内部标准化值；
- `target_parameter_sample_index`：每个预测值对应的位置；
- `selection`：自动/手动、请求模型、实际模型和选择依据；
- `adaptation`：是否微调、是否接受或回滚；
- `cir_status.available=false`：明确说明 Step 10 尚无预测 CIR。

`run_predictor_adapter` 仍保留为带标签数据的训练/外部评估包装器；正式产品调用应使用 `run_predictor_request_adapter`。

如果要使用安全适配，还要单独提供只允许从已知区域构造的标签数据：

```matlab
config.adaptation_mode = "auto";
config.adaptation_data_path = "known_region_predictor_data.h5";
```

正式无真值 request 和已知区 adaptation data 是两个对象，不能把待预测目标答案塞回 request。

## 6. 安全微调

支持三种模式：

- `off`：直接使用预训练模型；
- `auto`：仅微调输出头，验证集改善达到阈值才接受，否则回滚；
- `force`：明确要求微调，条件不足时直接报错。

共同规则：

1. 只使用已知区域的训练/验证样本；
2. 实际目标区域的 `(group_id, sample_index)` 不得进入微调；
3. 只更新 `head.weight/head.bias`，不改编码器；
4. 有最大 epoch、耐心值和时间限制；
5. 验证改善不足就回到原模型。

## 7. Demo

```matlab
step10_module3_demo( ...
    "PythonExecutable", "你的Python路径", ...
    "AutoRun", true);
```

Demo 是后续正式模块三页面的可复用骨架：

- 普通用户系统自动选模型；
- 高级用户手选 GRU/LSTM/TCN；
- 显示真实预测参数和 Adapter 状态；
- 不显示 Ground Truth、RMSE 或准确度图；
- CIR、CTF 和 1/3/6/9 张信道特性图暂时禁用，并明确标注“等待 Step 11”。
