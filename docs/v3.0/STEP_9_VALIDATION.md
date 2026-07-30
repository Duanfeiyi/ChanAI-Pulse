# Step 9 自动验证记录

## 1. 环境

- 日期：2026-07-30
- MATLAB：R2024b
- Python：Step 1 已建立的隔离环境
- HDF5：MATLAB 自带接口与 Python `h5py`
- Full 6GPCM：已登记的本机外置只读核心

## 2. Step 9 专项测试

```text
PASS: Step 9 parameter sequence, tasks, split, normalization, and HDF5.
PASS: Step 9 interactive demo smoke.
```

覆盖：

- 280×2 标准参数序列；
- 全部8参数白名单和标准 `DS_mu/KF_mu`；
- 外推16→4；
- 内插左8+右8→中4；
- 10条路线形成90个样本；
- 路线级7/1/2切分和无组重叠；
- 训练集专属Z-score；
- 修改验证/测试数据不改变归一化统计；
- 反归一化恢复；
- `FAIL` 标签不进入模型样本；
- 单参数 `P=1`；
- 真实 Step 8 Grid 入口形成 `grid_fitted` 局部标签；
- MATLAB HDF5 往返。

## 3. MATLAB/Python 交叉读取

Python 单元测试：

```text
Ran 1 test in 0.127s
OK
```

读取 MATLAB 生成的公开外推 fixture：

```text
schema_version: v3.0-predictor-data-hdf5.1
parameter_values_shape: [280, 2]
inputs_shape: [90, 16, 2]
targets_shape: [90, 4, 2]
partition_counts: train=63, validation=9, test=18
```

第二次独立生成 fixture 后，Python 比较参数、输入、标签和分区数组：

```text
PASS: Step 9 regenerated fixtures are logically identical.
```

HDF5 容器内部元数据的物理排布不作为字节级稳定接口；逻辑数组、显式形状和
JSON 语义才是契约。

## 4. Step 1～9 完整回归

```text
PASS: v3 CIR/CTF data, task, capability, and HDF5 contracts.
PASS: four deterministic v3 standard CIR/CTF fixture pairs.
PASS: Step 3 full 6GPCM probe contract and error paths.
PASS: Step 4 input pipeline, task presets, and legacy adapters.
PASS: Step 5 unified characteristics, registry, and renderer.
PASS: 6GPCM-lite generator produces deterministic synthetic channel tensors.
PASS: Step 6 shared Generator Adapter contract and error paths.
PASS: real full 6GPCM Step 6 Adapter and core-integrity check.
PASS: Step 7 deterministic Cartesian Grid Search and safeguards.
PASS: Step 7 6GPCM-lite Grid Search smoke.
PASS: real Full 6GPCM Step 7 two-candidate Grid Search.
PASS: Step 8 unified optimizer, SA, cache, and auto strategy.
PASS: Step 8 6GPCM-lite SA smoke.
PASS: real Full 6GPCM Step 8 minimal SA smoke.
PASS: Step 9 parameter sequence, tasks, split, normalization, and HDF5.
PASS: Step 1-9 complete MATLAB regression.
```

真实 Full 测试继续核对 `core_unchanged` 和调用前后哈希，Step 9 没有修改或
复制外置核心。

## 5. 静态检查与可视化

Step 9 新增核心、Demo 和测试：

```text
CHECKCODE_MESSAGES=0
```

实际运行导出：

- `step9_predictor_data_demo.png`；
- `step9_predictor_data_review.png`。

## 6. 当前结论

Step 9 的核心契约、局部拟合标签、任务样本、分组切分、训练集归一化、
MATLAB/Python HDF5、公开小样例、Demo、完整回归和静态检查均已通过。

项目负责人人工审阅已通过，并已明确允许 commit、push 和创建 PR。
