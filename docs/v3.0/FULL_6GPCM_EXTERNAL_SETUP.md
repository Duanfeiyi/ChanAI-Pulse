# 完整版 6GPCM 外置配置说明

> 适用于 Step 3 技术探针。正式 Generator Adapter 将在 Step 6 制作。

## 为什么不把完整版直接放进仓库

当前找到的压缩包没有 `LICENSE`、`NOTICE` 或其他明确的公开再分发文件。因此，Step 3 采用：

```text
完整版 6GPCM：保留在本机外部目录，只读使用
ChanAI Pulse：只保存我们自己写的探针、转换器、测试和文档
```

这不是说完整版不能用于项目研究，而是现阶段没有足够证据说明可以把全部源码公开上传到 GitHub。

## 需要准备什么

1. MATLAB 能运行项目现有代码；
2. 把完整版压缩包解压到仓库外部的新目录；
3. 不修改解压目录中的任何核心文件；
4. 确认根目录下存在 `generate_channel_v1.m`。

示意路径：

```text
C:\research-assets\full-6gpcm\
    generate_channel_v1.m
    @channel_model\
    +mf\
    ...
```

请不要把个人绝对路径写进 Git 或提交到 GitHub。

## 最小调用

MATLAB：

```matlab
repoRoot = "你的 ChanAI-Pulse 仓库路径";
engineRoot = "你的外置完整版 6GPCM 根目录";

addpath(genpath(fullfile(repoRoot, "core")));
config = default_full_6gpcm_probe_config(engineRoot);
result = run_full_6gpcm_probe(config);

result.report
size(result.dataset.cir.coefficient)
```

默认输出的统一顺序是：

```text
Tx × Rx × Npath × Nt × N_sample
```

## 自动测试

PowerShell：

```powershell
$env:CHANAI_FULL_6GPCM_ROOT = "你的外置完整版 6GPCM 根目录"
matlab -batch "run('tests/test_full_6gpcm_external_smoke.m')"
matlab -batch "run('tests/test_full_6gpcm_external_repeatability.m')"
```

没有设置环境变量时，真实引擎测试会显示 `SKIP`，普通 CI 仍可用项目自有的假引擎测试接口和错误路径。

## 探针会检查什么

- 外部根目录和入口函数是否存在；
- 实际调用的 `generate_channel_v1` 是否来自指定目录；
- 输入参数是否为合法标量；
- 原始系数是否为有限复数；
- delay 是否为有限、非负秒；
- 原始输出是否能转换成 v3 五维 CIR；
- 转换后的数据是否通过 Step 1 契约；
- 调用前后完整文件树哈希是否一致；
- 固定随机种子能否得到完全相同的结果。

## 探针不会做什么

- 不修改完整版 6GPCM 核心；
- 不把第三方核心复制进仓库；
- 不评价信道模型科学准确度；
- 不实现 Grid Search 或 SA；
- 不连接最终 GUI；
- 不冒充 Step 6 的正式 Generator Adapter。

## 常见错误

### `UnexpectedCoreHash`

指定目录的文件清单与当前登记资产不一致。不要直接跳过，请先确认：

- 是否选错版本；
- 是否有人修改或新增了文件；
- 是否从不同来源得到另一个压缩包。

### `WrongEntryPoint`

MATLAB 路径中存在同名函数，而且实际解析到的入口不在指定外置目录。探针会主动停止，避免调用错版本。

### `MissingEngineRoot`

外置路径不存在。请检查路径，不要把仓库目录误当作完整版核心目录。
