# Step 11 预测参数生成 CIR 接口指南

> 契约版本：`v3.0-prediction-generation-request.1` / `v3.0-prediction-result.1`
>
> GitHub：Issue #52

## 1. 用初学者能理解的话说明

Step 10 给出的不是完整信道，而是四个目标点各自的两个参数：

```text
目标 1：DS_mu、KF_mu
目标 2：DS_mu、KF_mu
目标 3：DS_mu、KF_mu
目标 4：DS_mu、KF_mu
```

6GPCM 一次只能接收一组参数。因此 Step 11 的实际工作是：

```text
第 1 组预测参数 → 生成第 1 个 CIR
第 2 组预测参数 → 生成第 2 个 CIR
第 3 组预测参数 → 生成第 3 个 CIR
第 4 组预测参数 → 生成第 4 个 CIR
                         ↓
              按目标顺序合并为一个数据集
```

最终 CIR 的标准维度为：

```text
[Tx, Rx, Npath, Nt, N_sample]
```

这里 `N_sample=4`，代表四个预测目标点，不是把四个点误当成 `Nt`。

## 2. 首版参数来源

首版模型直接预测：

- `DS_mu`
- `KF_mu`

6GPCM 还需要 `DS_sigma、r_DS、num_clusters、num_rays、LNS_ksi、KF_sigma、doppler_hz`。
这些参数按固定优先级补齐：

```text
模块二标定结果 → 场景配置 → 带版本的默认值
```

每个参数都在 `parameter_provenance` 中记录数值、来源和来源版本。正式模式中缺少必要参数、
出现 `NaN/Inf`、越界或整数参数不是整数时直接失败，不静默裁剪或猜测。

## 3. 主要调用方式

```matlab
predictorResult = run_predictor_request_adapter( ...
    requestJson, modelRegistryJson, predictorConfig);

config = default_prediction_generation_config("lite_6gpcm");
config.prediction_example_index = 1;
config.dimensions.Nt = 1;

request = create_prediction_generation_request( ...
    predictorResult, config);
serviceResult = run_prediction_generation(request);

assert(serviceResult.success);
predictionResult = serviceResult.prediction_result;
```

正式完整版：

```matlab
config = default_prediction_generation_config("full_6gpcm");
config.mode = "formal";
config.engine_root = "D:\external\full_6gpcm";
request = create_prediction_generation_request(predictorResult, config);
serviceResult = run_prediction_generation(request);
```

正式模式不会自动降级为 Lite。完整版缺失或维度不兼容时，保留预测参数和逐目标诊断，但不发布
部分 CIR。

## 4. 输入

`create_prediction_generation_request` 接收：

- Step 10 `PredictedChannelParameters`；
- `backend/mode`；
- `Tx/Rx/Nf/Nt/Npath`；
- 明确频率轴；
- 场景信息；
- 参数来源；
- 主随机种子；
- Full 外置根目录和引擎版本。

Step 10 的批量结果可以包含多个例子，`prediction_example_index` 明确选择其中一个例子的四个目标点。

## 5. 输出

`run_prediction_generation` 返回服务层结果：

- `success/status/outcome/formal_eligible`；
- 原始 `predicted_parameters`；
- 四个 `target_diagnostics`；
- 进度事件；
- 缓存键；
- 成功时的 `prediction_result`。

`PredictionResult` 包含：

- 预测参数及目标索引；
- 复数 `cir_dataset` 和 `delay_s`；
- 可选 `ctf_dataset`；
- 请求维度和实际维度；
- 模块一共用的特性分析和图表注册表；
- Predictor、Generator、随机种子、来源和组合 Manifest；
- CIR/CTF 验证报告。

## 6. 种子与缓存

每次运行先记录 `master_seed`，再由目标编号和目标轴值确定性派生四个不同种子。
相同模型版本、预测参数、生成器版本、场景、维度、频率轴和主种子得到相同缓存键。

缓存键目前用于结果识别和未来缓存接入；Step 11 不会因为键相同而绕过正式生成器验收。

## 7. 导出

```matlab
files = export_prediction_result_bundle( ...
    predictionResult, "D:\review\step11_output");
```

产生：

- `predicted_cir.h5`
- `predicted_ctf.h5`（启用 CTF 时）
- `prediction_result.json`
- `generator_manifest.json`
- `prediction_manifest.json`

复数数组只写入 HDF5；JSON 保存可读的配置、来源、维度和诊断，不把复数数组伪装成普通 JSON。
接口拒绝覆盖已存在文件。

## 8. 进度、取消与超时

`run_prediction_generation` 支持：

```matlab
options.progress_callback = @(event) disp(event);
options.cancel_check = @() false;
```

取消在四个目标之间检查。完整版入口是不可修改的单体函数，无法在核心调用中途安全终止；
`full_timeout_s` 会在该次调用返回后检查并丢弃超时结果。这一限制会进入文档和诊断，不能宣称为
核心内部的硬中断。
