# Step 6：Generator Adapter 接口指南

> 接口版本：`v3.0-step6.1`
>
> 配置契约：`v3.0-generator-config.1`
>
> 结果契约：`v3.0-generation-result.1`

## 1. Step 6 解决什么问题

模块二需要反复生成候选信道，模块三需要把预测参数生成成目标 CIR。两者不应该各写一套 6GPCM 调用代码。

Step 6 建立统一入口：

```text
GeneratorConfig
    ↓
run_generator_adapter
    ↓
GenerationResult
```

调用方不需要知道内部是项目自有 Mock、6GPCM-lite，还是外置完整版 6GPCM。

本 Step 只负责“一次生成”。Grid Search、随机搜索、SA 和预测模型分别留到 Step 7～11。

## 2. 最小调用

```matlab
addpath(genpath("core"));

config = default_generator_config("lite_6gpcm");
config.random_seed = 3103;
config.dimensions.Nt = 8;
config.dimensions.N_sample = 4;

result = run_generator_adapter(config);
disp(result.status);
dataset = result.dataset;
```

如果还需要频域 CTF，必须提供明确的绝对频率轴：

```matlab
config.ctf.enabled = true;
config.ctf.frequency_hz = linspace(15.95e9, 16.05e9, 64).';
result = run_generator_adapter(config);
ctfDataset = result.ctf_dataset;
```

平台不会在频率信息不足时擅自猜测 CTF 频率轴。

## 3. GeneratorConfig

主要字段如下：

| 字段 | 含义 |
|---|---|
| `schema_version` | 固定为 `v3.0-generator-config.1` |
| `backend` | `mock`、`lite_6gpcm` 或 `full_6gpcm` |
| `mode` | `preview` 或 `formal` |
| `random_seed` | 非负整数随机种子 |
| `dimensions.Tx/Rx` | 发射/接收天线数量 |
| `dimensions.Npath` | 路径数；Lite/Full 由后端生成结果决定 |
| `dimensions.Nt` | 每个样本内的测量时刻数量 |
| `dimensions.N_sample` | 独立样本或路线样本数量 |
| `scenario` | 场景、载频、带宽、轨迹类型和时间间隔 |
| `model` | DS、K 因子、簇、射线和 Doppler 等生成参数 |
| `ctf` | 是否生成 CTF 以及明确的绝对频率轴 |
| `backend_options` | 后端专属选项，例如 Lite 的最大时延窗口 |
| `engine_root` | 仅 Full 后端使用的本地外置根目录 |
| `engine` | 后端身份、版本、包哈希和测试标记 |

`engine_root` 只用于本机运行。`sanitize_generator_config` 会在公开配置和 Manifest 中移除真实路径，只记录是否已经配置，避免导出本机隐私。

## 4. GenerationResult

关键字段如下：

| 字段 | 含义 |
|---|---|
| `status` | `PASS`、`WARNING` 或 `FAIL` |
| `outcome` | `SUCCEEDED`、`CANCELLED` 或 `FAILED` |
| `success` | 是否得到可用正式数据 |
| `cancelled` | 是否由取消请求终止或丢弃 |
| `formal_eligible` | 是否由显式 Formal 模式产生且不是测试替身 |
| `backend` | 实际请求的后端；失败时也不会改成其他后端 |
| `dataset` | v3 路径域 CIR；失败/取消时为空 |
| `ctf_dataset` | 可选 v3 CTF |
| `validation` | 配置、CIR 和 CTF 验证报告 |
| `warnings/errors` | 面向调用方的明确说明 |
| `events` | 后台阶段、进度、消息和 UTC 时间 |
| `backend_manifest` | Adapter、核心哈希和后端专属运行信息 |
| `manifest` | 配置、随机种子、尺寸、运行时间和结果摘要 |

CIR 始终使用：

```text
coefficient[Tx, Rx, Npath, Nt, N_sample]
delay_s[Tx, Rx, Npath, Nt, N_sample]
```

CTF 始终使用：

```text
H[Tx, Rx, Nf, Nt, N_sample]
```

## 5. 三种 Adapter 的边界

| Adapter | 用途 | 当前限制 |
|---|---|---|
| `MockGeneratorAdapter` | CI、契约测试、界面演示 | 不是物理信道，成功结果也必须保留 test-only WARNING |
| `Lite6GPCMAdapter` | 快速工程测试和轻量合成 | 当前只支持 SISO；不能冒充完整版 6GPCM |
| `Full6GPCMAdapter` | 调用外置完整版 6GPCM | 当前历史入口固定场景、16 GHz、2×2、静态轨迹和 `Nt=2` |

完整版当前入口只暴露 DS、K 因子、簇、射线和样本数等参数。对于它没有暴露的天线、场景、轨迹或 `Nt` 设置，Adapter 会明确拒绝不支持的值，不会静默忽略。

## 6. Full 6GPCM 外置调用

```matlab
config = default_generator_config("full_6gpcm");
config.engine_root = "C:\你的外置完整版6GPCM目录";
config.dimensions.N_sample = 1;
result = run_generator_adapter(config);
```

也可以配置环境变量：

```powershell
$env:CHANAI_FULL_6GPCM_ROOT = "C:\你的外置完整版6GPCM目录"
```

安全规则：

- 不修改或复制外部核心；
- 调用前后核对核心文件树哈希；
- 找不到 Full 时返回 `FAIL`；
- 不会自动改用 Lite；
- 导出的 Manifest 不包含本机完整路径。

## 7. 后台进度和取消

```matlab
cancelRequested = false;
options = struct( ...
    "progress_callback", @(event) disp(event), ...
    "cancel_check", @() cancelRequested);
result = run_generator_adapter(config, options);
```

Mock 和 Lite 会在样本之间检查取消请求。完整版的历史核心调用是一个不可拆开的函数，而且核心禁止修改，因此只能在进入核心前和核心返回后检查取消请求。正式 UI 必须如实显示这项能力差异。

## 8. PASS、WARNING、FAIL 怎么理解

- `PASS`：得到合法 CIR，且没有需要特别说明的限制；
- `WARNING`：得到合法 CIR，但后端存在必须展示的限制，例如 Mock test-only、Lite 工程性质或 Full 固定场景；
- `FAIL`：没有可用 CIR，例如配置非法、Full 未安装、核心哈希不符或输出违反 v3 契约。

不要只检查 `status`。调用方应优先检查：

```matlab
if result.success
    dataset = result.dataset;
else
    disp(result.errors);
end
```

Preview 结果和 Mock 结果的 `formal_eligible=false`，后续流程不能把它们自动当成正式预测链路输入。

## 9. 独立 Demo

```matlab
addpath("examples");
step6_generator_adapter_demo
```

Demo 可以选择 Mock、Lite 或 Full，查看后台进度、CIR/CTF 尺寸、PDP、CTF 热力图、WARNING/FAIL 和事件日志。它不修改正式 `ChannelSimulatorApp.m`；正式接入留到 Step 12。

## 10. Python 后续接入

Step 6 的核心输出是已经冻结的 v3 CIR/CTF 数据结构。后续 Python 生成器只要实现相同配置和结果 Schema，即可通过新的 Adapter 加入，不要求修改 GUI，也不需要改变模块二或模块三的科学职责。
