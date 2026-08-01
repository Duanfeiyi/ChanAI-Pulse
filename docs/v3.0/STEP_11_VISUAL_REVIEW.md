# Step 11 Demo 与人工审阅

## 1. 启动命令

在 MATLAB 中执行：

```matlab
cd("你的 ChanAI-Pulse Step 11 工作树")
addpath(genpath("examples"))

pythonExe = "你的 Step 10 Python 虚拟环境/python.exe";

step11_module3_demo( ...
    "PythonExecutable", pythonExe, ...
    "Backend", "lite_6gpcm", ...
    "TaskType", "extrapolation");
```

Lite 用于界面和集成体验，不代表正式 6GPCM。

如需本机完整版体验：

```matlab
step11_module3_demo( ...
    "PythonExecutable", pythonExe, ...
    "Backend", "full_6gpcm", ...
    "EngineRoot", "只读解压的完整版 6GPCM 根目录");
```

## 2. 应该看到什么

- 顶部保持模块三正式页面风格；
- 普通用户为系统自动选模型，高级用户可以选择 GRU/LSTM/TCN；
- 页面显示实际模型和 `DIRECT/ADAPTED`；
- 左中区域显示已知参数与四个预测参数点；
- 下面显示预测 CIR 能合法支持的信道特性；
- 页面没有 Ground Truth、RMSE、NRMSE 或准确率；
- Lite 宽带静态 SISO 样例显示 3 张标准图：PDP、频率自相关、时延扩展 CDF；
- 状态明确写着 Lite 预览，不冒充 Full。

## 3. 初学者如何判断

1. 两条参数曲线应在索引上前后衔接，橙色四点是预测区，不是真值。
2. PDP 横轴是时延、纵轴是相对功率，表示能量通过不同路径到达。
3. 频率自相关零频移应为 1，整条曲线不能超过 1。
4. 时延扩展 CDF 从 0 向 1 上升，四个目标样本会形成四级经验分布。
5. 页面显示 `CIR 维度 1×1×31×1×4`，对应
   `Tx×Rx×Npath×Nt×N_sample`。
6. 独立目标提示必须可见；不应出现多普勒、时间相关和路线热力图。

## 4. 审阅截图

`review_assets/step11/step11_module3_demo.png`

该截图来自真实 Step 10 TCN Predictor Adapter 与真实 Lite Generator Adapter，不使用伪造 CIR。

`review_assets/step11/step11_module3_full_demo.png`

该截图来自真实 Step 10 TCN Predictor Adapter 与外置 Full 6GPCM，展示具备已知 2 单元 ULA
几何的 6 张 MIMO 特性图。完整版核心仍未进入仓库。
