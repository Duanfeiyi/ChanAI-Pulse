# ChanAI Pulse v3.0 统一 CIR/CTF 数据契约

> 契约版本：`v3.0-data-contract.1`
>
> 状态：Step 1 实现基线
>
> GitHub：[#24](https://github.com/Duanfeiyi/ChanAI-Pulse/issues/24)

## 1. 这份契约解决什么问题

过去的数组经常只有一个变量名和尺寸。软件看到 `1×1×128×100` 时，无法知道 128 是子载波、100 是时间，还是二者其实代表样本。错误理解维度会产生“代码能运行、物理意义却错误”的结果。

v3.0 因此把信道数值、维度名称、物理坐标、单位、样本含义和来源放进同一个 `ChannelDataset`。模块一、模块二和模块三都使用这份结构，不再各自猜测。

## 2. 已冻结的维度顺序

单个频域 CTF 样本：

```text
H = Tx × Rx × Nf × Nt
```

完整 CTF 数据集：

```text
H = Tx × Rx × Nf × Nt × N_sample
```

MATLAB 索引形式：

```matlab
H(tx, rx, frequency, time, sample)
```

`N_sample` 固定放在最后。这样取出任意一个样本后，仍然保持项目习惯的 `Tx × Rx × Nf × Nt`。

### `Nt` 与 `N_sample`

- `Nt`：一个样本内部连续测量的时刻数量。
- `N_sample`：一共有多少份样本、位置或实验记录。

例如沿道路 200 个位置采集，每个位置连续测量 10 个时刻：

```text
N_sample = 200
Nt = 10
```

独立文件的数量不能自动解释成连续时间。只有存在真实时间轴或采样间隔时，`Nt` 才能支持时间相关和多普勒分析。

## 3. CTF 数据

CTF 使用：

```matlab
dataset.ctf.H
dataset.dimension_order = ["Tx", "Rx", "Nf", "Nt", "N_sample"]
```

`H` 是复数频域信道。实部和虚部共同保存幅度与相位信息，功率可由 `abs(H).^2` 得到。

当 `Nf > 1` 时，数据还应提供：

```matlab
dataset.axes.frequency_hz
```

或者在元数据中同时提供：

```matlab
dataset.metadata.center_frequency_hz
dataset.metadata.subcarrier_spacing_hz
```

没有频率定义时，数据仍可安全读取，但软件不能严谨计算频率相关或由 IFFT 得到真实时延轴。

## 4. 路径域 CIR 数据

路径域 CIR 使用：

```text
coefficient = Tx × Rx × Npath × Nt × N_sample
delay_s     = Tx × Rx × Npath × Nt × N_sample
path_valid  = Tx × Rx × Npath × Nt × N_sample
```

对应字段：

```matlab
dataset.cir.coefficient
dataset.cir.delay_s
dataset.cir.path_valid
dataset.dimension_order = ["Tx", "Rx", "Npath", "Nt", "N_sample"]
```

- `coefficient`：复数路径系数。
- `delay_s`：路径时延，底层单位固定为秒。
- `path_valid`：该位置是否为真实路径。

不同样本的路径数可以不同。交换文件使用 `Npath_max` 大小的数组，并用 `path_valid` 区分真实路径和填充位置。`delay_s` 可以在 Tx/Rx 维度为 1，由接口广播到所有天线对，从而避免重复保存相同路径时延。

可选路径字段：

```matlab
dataset.cir.aoa_rad
dataset.cir.aod_rad
dataset.cir.doppler_hz
```

没有角度数据或阵列几何信息时，不宣称支持角度功率谱。

## 5. 维度字段

`dataset.dimensions` 始终明确包含：

```text
Tx
Rx
Nf
Nt
N_sample
Npath
```

CTF 的 `Npath` 为 0，路径域 CIR 的 `Nf` 为 0。验证器会对照真实数组大小，禁止只修改维度标签而不修改数据。

## 6. 坐标轴

`dataset.axes` 支持：

| 字段 | 含义 | 典型大小 |
|---|---|---|
| `frequency_hz` | 子载波或频率点 | `Nf×1` |
| `time_s` | 单个样本内部的连续时间 | `Nt×1` |
| `sample_index` | 样本编号 | `N_sample×1` |
| `sample_position_m` | 样本物理位置 | `N_sample×1/2/3` |

坐标轴必须与对应维度长度一致。真实物理轴必须递增，且不能包含 `NaN` 或 `Inf`。

## 7. 样本含义

`dataset.metadata.sample_semantics` 必须使用以下值之一：

| 值 | 含义 |
|---|---|
| `independent` | 独立样本，不连接成路线或时间 |
| `ordered_route` | 沿测量路线有顺序的样本 |
| `ordered_time` | 样本本身按时间排列 |
| `ordered_frequency` | 样本代表有序频段或频率组 |
| `other_ordered` | 其他明确说明的有序样本 |

热力图要求样本具有真实顺序。`independent` 样本即使数量很多，也不能被画成一条虚构路线。

## 8. 底层单位

正式数据使用 SI 单位：

| 物理量 | 底层单位 |
|---|---|
| 频率 | `Hz` |
| 时间 | `s` |
| 时延 | `s` |
| 位置 | `m` |
| 角度 | `rad` |
| 功率 | `linear` |

GUI 可以显示 GHz、MHz、ms、ns 或 dB，但进入核心层前必须转换为以上单位。

## 9. 来源与复现信息

所有正式输出至少记录：

```matlab
dataset.schema_version
dataset.metadata.source
dataset.metadata.created_utc
```

生成数据还应记录：

```matlab
dataset.metadata.generator
dataset.metadata.generator_version
dataset.metadata.random_seed
dataset.metadata.config
```

测量数据则应记录允许公开的来源说明，但不得把敏感位置、设备标识或私有原始文件路径写入公开仓库。

## 10. 内插与外推任务

任务使用独立的 `TaskSpec`：

```matlab
task.mode
task.axis
task.known_indices
task.target_indices
task.axis_values
task.axis_unit
```

规则：

- `mode` 只能是 `interpolation` 或 `extrapolation`。
- 已知区域和目标区域不得重叠。
- 内插目标必须位于已知索引范围内部。
- 外推目标必须位于已知索引范围外部。
- 频率任务要求 `Nf > 1`。
- 时间任务要求 `Nt > 1`。
- 位置任务要求位置轴或明确的 `task.axis_values`。

`task.axis_values` 可以描述比现有输入更大的目标网格。例如已有样本 1–80、目标是 81–100 时，任务网格长度可以是 100。

## 11. 数据能力而不是固定图表

`infer_channel_capabilities` 根据数据和元数据报告：

- 是否能画 PDP；
- 是否能计算频率自相关；
- 是否有角度信息；
- 是否能计算空间相关；
- 是否有连续时间信息；
- 是否能计算多普勒与时间自相关；
- 是否有足够样本形成经验 CDF；
- 是否能按路线或样本顺序绘制时延热力图。

Step 1 只定义判断规则。正式信道特性计算和绘图在 Step 5 完成。

## 12. MATLAB/Python HDF5 交换

MATLAB 和 Python 对 HDF5 多维数组和复数类型的默认表示存在差异。v3.0 第一版交换格式优先保证正确性：

```text
复数数组 -> real 一维数据 + imag 一维数据 + canonical shape
```

扁平化顺序固定为 MATLAB column-major。Python 读取时使用：

```python
array.reshape(shape, order="F")
```

CTF 的 `H` 以及 CIR 的路径字段始终保存完整五维形状，即使某一维等于
1，也不会用 `squeeze` 删除。坐标轴不是信道张量：例如
`sample_position_m` 会保留 `N_sample × 2/3` 的原始二维表形状。

这样两端都能恢复：

```text
Tx × Rx × Nf/Npath × Nt × N_sample
```

交换文件不直接依赖 MATLAB `-v7.3` 内部对象表示，也不依赖 h5py 的复合复数类型。

## 13. 与历史契约的关系

旧的 `canonicalize_cir.m` 使用：

```text
antenna × delay_or_frequency × snapshot
```

它继续服务历史 SAGE/ChanAIs 数据，不在 Step 1 中删除或修改。历史数据进入 v3.0 主链路前必须通过 Converter 明确映射为本契约，不能只用 `squeeze` 猜测 Tx、Rx、频率、时间和样本含义。
