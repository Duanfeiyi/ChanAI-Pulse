# Step 10 参考预测模型

这里的模型只用于验证 Step 10 工程链路，不是论文精度结论，也不是面向所有场景的最终科学模型。

- 训练数据：`demo_data/v3_step9` 的 10 条确定性合成参数路线；
- 参数：`DS_mu`、`KF_mu`；
- 输入/输出：`[N_example,16,2] -> [N_example,4,2]`；
- 模型族：GRU、LSTM、TCN；
- 任务隔离：`interpolation/` 和 `extrapolation/` 分开保存；
- 普通用户：读取 registry 中离线冻结的自动选择；
- 高级用户：可以显式选择兼容的 GRU/LSTM/TCN；
- 基线：Persistence 和 Linear 只参加外部审阅，不进入普通用户自动模型池。
- `requests/`：正式产品风格的无真值请求，只有已知参数与目标位置，不含 `targets`。

模型由下面的命令生成：

```powershell
python tools/python/run_step10_predictor.py train-family `
  --data demo_data/v3_step9/step9_extrapolation_standard.h5 `
  --output demo_data/v3_step10/models/extrapolation
```

内插模型使用对应的 interpolation HDF5 和输出目录。Step 10 只输出预测后的参数；预测 CIR/H 矩阵属于 Step 11。
