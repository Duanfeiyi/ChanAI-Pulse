# Step 10 Demo 与人工审阅说明

## 1. 打开可交互 Demo

```matlab
step10_module3_demo( ...
    "PythonExecutable", "你的Step10虚拟环境/python.exe", ...
    "AutoRun", true);
```

建议人工检查：

1. 普通用户模式下，模型下拉框被禁用，运行后显示 registry 实际选择；
2. 高级用户模式下，可以手选 GRU、LSTM、TCN；
3. 外推和内插都能得到 `[18,4,2]` 参考预测结果；
4. 参数图只包含“已知参数”和“模型预测”，没有 Ground Truth/误差曲线；
5. CIR/CTF、PDP、角度域、多普勒域区域全部显示“等待 Step 11”；
6. 导出 CIR 按钮不可用，预测参数 JSON 可以导出；
7. 页面明确告诉用户本阶段只预测 `DS_mu/KF_mu`。

## 2. 两张审阅图

- `review_assets/step10/step10_module3_demo.png`
  - 正式模块三风格；
  - 使用真实 Predictor Adapter；
  - 可在 Step 11/12 继续复用；
  - 不包含准确度。

- `review_assets/step10/step10_predictor_external_review.png`
  - 明确属于软件外部；
  - 对比 GRU/LSTM/TCN/Persistence/Linear；
  - 展示预测与 Ground Truth，仅供工程审阅；
  - 公开确定性合成 fixture 不是科学精度结论。

## 3. 当前参考结果怎么理解

在固定公开 fixture 与固定随机种子下，TCN 的验证 Normalized RMSE 最低，因此两类任务的普通模式都冻结为 TCN。

这只说明：

> 在这份小型确定性工程样本上，当前 TCN 参考实现最适合演示自动选择链路。

它不说明：

> TCN 在所有真实无线信道数据上永远最好。

真实结论必须等更丰富生成数据和实测数据通过外部 Benchmark 验证。
