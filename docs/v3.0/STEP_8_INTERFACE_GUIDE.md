# Step 8：参数优化接口指南

> 统一配置：`v3.0-optimization-config.1`
>
> 统一结果：`v3.0-parameter-optimization-result.1`
>
> SA/随机贪心结果：`v3.0-stochastic-optimization-result.1`

## 1. 推荐的统一调用

```matlab
addpath(genpath("core"));

config = default_optimization_config("lite_6gpcm");
config.requested_strategy = "auto";
config.generator_config = generatorConfig;
config.variables = struct( ...
    "DS_mu", struct( ...
        "type", "continuous", ...
        "lower", -8.10, ...
        "upper", -7.70, ...
        "initial", -7.925, ...
        "step_fraction", 0.10), ...
    "num_clusters", struct( ...
        "type", "integer", ...
        "lower", 6, ...
        "upper", 20, ...
        "initial", 12, ...
        "step_fraction", 0.10));

result = run_parameter_optimization(dataset, config);
```

因为含连续/整数区间，自动策略会选择 SA。

## 2. 小型离散空间

```matlab
config.variables = struct( ...
    "DS_mu", struct( ...
        "type", "discrete", ...
        "values", [-8.05, -7.925, -7.80], ...
        "initial", -7.925, ...
        "step_fraction", 0.10), ...
    "KF_mu", struct( ...
        "type", "discrete", ...
        "values", [-0.80, -0.39, 0], ...
        "initial", -0.39, ...
        "step_fraction", 0.10));
```

Mock/Lite 下 3×3=9 组通常自动选择 Grid。Full 是否选择 Grid 还要看 Full 的
自动上限。

## 3. OptimizationConfig 主要字段

| 字段 | 含义 |
|---|---|
| `requested_strategy` | `auto`、`grid` 或 `sa` |
| `generator_config` | Step 6 生成器基线和固定随机种子 |
| `variables` | 待优化参数及类型、范围、初值和步长比例 |
| `scoring` | PDP/时延扩展拟合距离配置 |
| `target.task` | 内插/外推任务的 known/target 划分 |
| `limits.max_evaluations` | SA 实际生成与评分预算 |
| `limits.max_consecutive_failures` | 连续候选失败上限 |
| `limits.retain_top_k` | 保存完整 CIR 的最佳候选数 |
| `limits.max_grid_candidates` | 手动 Grid 硬上限 |
| `sa` | 温度、降温、停止、提案数和随机种子 |
| `auto.grid_candidate_caps` | 各生成后端的自动 Grid 上限 |

先验证：

```matlab
[report, normalized] = validate_optimization_config(config);
disp(report.selection);
```

`report.selection.reason` 可直接用于未来正式 UI。

## 4. 统一结果怎样读取

```matlab
if result.success && result.complete
    disp(result.selected_strategy);
    disp(result.selection_reason);
    disp(result.best.parameters);
    disp(result.best.total_score);
else
    disp(result.errors);
    disp(result.warnings);
end
```

重要字段：

| 字段 | 含义 |
|---|---|
| `requested_strategy` | 调用者要求的方法 |
| `selected_strategy` | 实际执行的 `grid` 或 `sa` |
| `selection_source` | `auto` 或 `manual` |
| `selection_reason_code/reason` | 选择原因 |
| `counts` | 计划、完成、成功、失败、提案和实际评估次数 |
| `best` | 最佳参数、分数组成和完整生成结果 |
| `retained_candidates` | Top K 的完整 CIR |
| `details` | Grid 或 SA 的算法专用过程 |
| `manifest` | 可保存的版本、配置、选择和运行记录 |

SA 专用过程在 `result.details` 中，包括：

- `history`：每次提案的参数、分数、温度、是否接受、是否缓存；
- `temperature_history`：每个温度层的接受率和当前最佳；
- `worse_accepted_proposals`：SA 接受较差移动的次数；
- `stop_reason`：停止原因；
- `objective_evaluations` 与 `total_proposals`：实际昂贵调用与总提案数。

## 5. Random Greedy 对照

```matlab
baseline = run_random_greedy_search(dataset, config);
sa = run_simulated_annealing(dataset, config);
```

两者使用同一个 `OptimizationConfig`。Random Greedy 不进入统一 `auto` 正式选择，
只用于算法研究、测试和人工审阅。

## 6. 进度与取消

```matlab
cancelRequested = false;
options = struct( ...
    "progress_callback", @(event) disp(event.message), ...
    "cancel_check", @() cancelRequested);

result = run_parameter_optimization(dataset, config, options);
```

取消是协作式的：平台会在候选之间检查。Full 6GPCM 单次核心调用内部仍不能被本项目
强行拆断。

## 7. 独立体验 Demo

```matlab
addpath("examples");
step8_optimizer_demo
```

Demo 可以切换后端、自动/Grid/SA、候选空间和 SA 预算，并显示：

- 请求策略、实际策略和选择理由；
- 选中策略的分数与当前最佳；
- SA 温度与接受率；
- Grid、Random Greedy、SA 的成本与最佳分数对照；
- 目标与最佳候选的 PDP、RMS 时延扩展；
- 最佳参数和科学边界。

它是 Step 8 功能审阅界面，不代替 Step 12 的正式平台 UI。
