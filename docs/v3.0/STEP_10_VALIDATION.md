# Step 10 自动验证记录

> 当前状态：实现阶段自动验证通过，等待项目负责人进行 PR 前人工审阅。

## Python 环境

- Python 3.12；
- NumPy 2.5.1；
- h5py 3.16.0；
- PyTorch 2.13.0 CPU；
- Matplotlib 3.11.1。

本机有 NVIDIA RTX 4060 Laptop GPU，但本次公开参考权重使用 CPU 版 PyTorch 训练，避免把 CUDA 环境作为运行前提。

## Python 自动测试

```powershell
python -m unittest -v tests.python.test_step10_predictor_adapter
```

结果：12 项通过。

覆盖：

- GRU/LSTM/TCN 的 `[N,16,2] -> [N,4,2]`；
- Persistence/Linear 基线；
- 普通用户离线自动选择；
- 修改测试 Ground Truth 后，选择和预测完全不变；
- 高级用户手选；
- 内插/外推 registry 混用拒绝；
- 微调目标重叠拒绝；
- 微调只允许更新输出头。
- 正式预测请求不包含目标 Ground Truth；
- 无真值请求与外部评估包装器得到相同预测；
- 没有独立已知区标签时，强制微调会被拒绝。
- 有独立已知区标签时可以执行头部适配，目标重叠计数保持为 0。
- 将适配数据的测试分区 Ground Truth 故意加 1000 后，适配预测完全不变。

## MATLAB 跨语言测试

```matlab
run("tests/test_step10_predictor_adapter.m")
```

结果：

```text
PASS: Step 10 MATLAB Predictor Adapter, auto/manual selection, and task isolation.
```

同时验证正式 MATLAB Demo 调用的是不含目标真值的 JSON request，并与外部评估包装器产生一致预测。

## Step 1–10 回归

- Step 1–7 本地/Mock/Lite 测试通过；
- Step 8 Optimizer/SA/Lite 通过；
- Step 9 参数数据契约通过；
- Step 10 跨语言接口通过；
- Python 全套现有 18 项测试通过；
- `CHANAI_FULL_6GPCM_ROOT` 本次未配置，因此 Step 7/8 的真实外置 Full 6GPCM 测试记为环境性未运行，不伪报通过；
- 完整 Full 6GPCM 核心未被修改。

## 参考模型结果

### 外推

| 模型 | 验证 Normalized RMSE |
|---|---:|
| GRU | 0.259 |
| LSTM | 0.224 |
| TCN | 0.068 |
| Persistence | 0.386 |
| Linear | 0.959 |

自动选择：TCN。

### 内插

| 模型 | 验证 Normalized RMSE |
|---|---:|
| GRU | 0.236 |
| LSTM | 0.358 |
| TCN | 0.104 |
| Persistence | 0.267 |
| Linear | 0.508 |

自动选择：TCN。

以上数字只用于确定性合成 fixture 的工程审阅，不构成真实信道精度声明。
