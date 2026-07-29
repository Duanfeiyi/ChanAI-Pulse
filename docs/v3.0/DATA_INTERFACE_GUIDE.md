# ChanAI Pulse v3.0 数据接口调用指南

> 面向 MATLAB/Python 接口开发者。完整字段语义见 [统一 CIR/CTF 数据契约](DATA_CONTRACT.md)。

## 1. MATLAB 路径

在调用前加入核心目录：

```matlab
repoRoot = "你的 ChanAI-Pulse 仓库路径";
addpath(genpath(fullfile(repoRoot, "core")));
```

## 2. 创建 CTF

```matlab
H = complex(randn(1, 1, 64, 1, 100), ...
            randn(1, 1, 64, 1, 100));

axes = struct( ...
    "frequency_hz", (3.5e9 + (0:63) * 15e3).', ...
    "sample_index", (1:100).');

metadata = struct( ...
    "source", "synthetic_example", ...
    "sample_semantics", "independent");

dataset = create_channel_dataset( ...
    "ctf", struct("H", H), axes, metadata);
```

输出 `dataset.ctf.H` 固定解释为：

```text
Tx × Rx × Nf × Nt × N_sample
```

## 3. 创建路径域 CIR

```matlab
coefficient = complex(randn(2, 2, 8, 5, 20), ...
                      randn(2, 2, 8, 5, 20));
delay_s = rand(1, 1, 8, 5, 20) * 200e-9;
path_valid = true(size(delay_s));

payload = struct( ...
    "coefficient", coefficient, ...
    "delay_s", delay_s, ...
    "path_valid", path_valid);

dataset = create_channel_dataset( ...
    "cir", payload, struct(), ...
    struct("source", "6gpcm_example"));
```

`delay_s` 的 Tx/Rx 维度可以为 1，验证器会确认它能否广播到所有天线对。

## 4. 验证数据

```matlab
report = validate_channel_dataset(dataset);
```

返回：

```matlab
report.is_valid
report.status
report.errors
report.warnings
```

状态含义：

- `PASS`：格式和必要物理信息完整。
- `WARNING`：数据可安全读取，但部分物理能力缺失。
- `FAIL`：数组、维度、单位或有效路径存在阻塞错误。

验证器只读，不会修改上传数据。

## 5. 创建与验证内插任务

```matlab
task = create_channel_task( ...
    "interpolation", ...
    "sample", ...
    [1:40, 61:100], ...
    41:60, ...
    struct("axis_values", 1:100));

taskReport = validate_channel_task(dataset, task);
```

## 6. 创建与验证外推任务

```matlab
task = create_channel_task( ...
    "extrapolation", ...
    "sample", ...
    1:80, ...
    81:100, ...
    struct("axis_values", 1:100));

taskReport = validate_channel_task(dataset, task);
```

## 7. 查询可视化能力

```matlab
capabilities = infer_channel_capabilities(dataset);
```

典型字段：

```matlab
capabilities.pdp
capabilities.frequency_autocorrelation
capabilities.angular_power_spectrum
capabilities.spatial_correlation
capabilities.doppler_power_spectrum
capabilities.time_autocorrelation
capabilities.delay_sample_heatmap
```

界面后续只显示值为 `true` 的能力，并显示 `capabilities.reasons` 中的缺失原因。

## 8. 写入与读取 HDF5

MATLAB 写入：

```matlab
write_channel_dataset_hdf5("channel.h5", dataset);
```

MATLAB 读取：

```matlab
datasetReloaded = read_channel_dataset_hdf5("channel.h5");
```

为了避免覆盖原始数据，写入函数默认拒绝覆盖已经存在的文件。

## 9. Python 读取

建议建立隔离环境：

```powershell
python -m venv .venv
.venv\Scripts\python -m pip install -r tools\python\requirements-v3-contract.txt
```

命令行查看：

```powershell
.venv\Scripts\python tools\python\read_channel_hdf5.py channel.h5
```

代码调用：

```python
from read_channel_hdf5 import read_channel_hdf5

dataset = read_channel_hdf5("channel.h5")
H = dataset["ctf"]["H"]
print(H.shape)
```

Python 读取器返回的数组仍然使用标准顺序：

- CTF 与 CIR 路径字段保持完整五维；
- `sample_position_m` 等坐标表保持原始二维形状；
- 不需要也不应先对信道数组调用 `squeeze`。

```text
Tx × Rx × Nf/Npath × Nt × N_sample
```

预测器 Adapter 如果需要 sample-first，再在 Adapter 内部显式 `transpose`，不能偷偷改变公共文件契约。

## 10. 常见错误

### 把样本当作时间

错误：

```text
有100个文件，所以Nt=100
```

正确做法：如果文件互相独立，应使用 `N_sample=100`。只有文件之间具有连续时间关系且有时间间隔时，才能映射为 `Nt`。

### 单位写成 GHz 或 ns

GUI 可以输入 GHz/ns，但核心结构必须转换成 Hz/s。验证器遇到非标准底层单位会返回 `FAIL`。

### 只有多天线就画角度谱

多天线不等于已经得到 AoA/AoD。角度功率谱需要路径角度或经过验证的阵列处理方法。

### 使用 `squeeze` 后猜维度

`squeeze` 会删除单例维度。例如 `Tx=1` 和 `Rx=1` 可能直接消失。v3 接口依赖明确的五维顺序，不能从压缩后的数组长度反推物理含义。

## 11. 最小示例和测试

- `examples/v3_data_contract_example.m`
- `examples/write_v3_ctf_hdf5_example.m`
- `tests/test_v3_data_contract.m`
- `tests/python/test_channel_hdf5_reader.py`

## 12. Step 2 四套标准数据

读取场景并在内存中生成一对CIR/CTF：

```matlab
scenarios = load_v3_standard_scenarios();
pair = generate_v3_standard_pair(scenarios(4));

size(pair.cir.cir.coefficient)
size(pair.ctf.ctf.H)
```

输出全部八个HDF5文件到一个新的空目录：

```matlab
manifest = write_v3_standard_fixtures("新的输出目录");
```

Python：

```powershell
python -m pip install -r tools/python/requirements-v3-step2.txt
python tools/python/generate_v3_standard_fixtures.py --output 新的输出目录
```

生成器拒绝覆盖已有文件。正式仓库内的审阅基线位于：

```text
demo_data/v3_standard_fixtures/
```

## 13. 外部QuaDRiGa转换

```matlab
pair = generate_quadriga_v3_example( ...
    "外部QuaDRiGa根目录", ...
    "新的输出目录");
```

项目只保存外围示例和转换器，不复制或修改QuaDRiGa核心。详情见`QUADRIGA_OPTIONAL_EXAMPLE.md`。

## 14. Step 3 外置完整版 6GPCM 技术探针

```matlab
engineRoot = "外置完整版 6GPCM 根目录";
config = default_full_6gpcm_probe_config(engineRoot);
result = run_full_6gpcm_probe(config);
```

主要返回：

```matlab
result.raw.H_all
result.raw.delay_all
result.dataset
result.report
result.manifest
```

原始单样本顺序：

```text
Tx × Rx × Nt × Npath
```

转换后的公共 CIR 顺序：

```text
Tx × Rx × Npath × Nt × N_sample
```

此处 `N_sample` 表示独立随机实现，不表示道路位置。完整配置、测试和边界见：

- `FULL_6GPCM_EXTERNAL_SETUP.md`
- `STEP_3_FULL_6GPCM_SPIKE.md`
