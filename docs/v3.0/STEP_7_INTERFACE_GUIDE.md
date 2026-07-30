# Step 7：Grid Search 接口指南

> 配置契约：`v3.0-grid-search-config.1`
>
> 结果契约：`v3.0-grid-search-result.1`
>
> Manifest：`v3.0-grid-search-manifest.1`

## 1. 最小调用

```matlab
addpath(genpath("core"));

targetGeneration = run_generator_adapter( ...
    default_generator_config("lite_6gpcm"));

config = default_grid_search_config("lite_6gpcm");
config.parameter_space = struct( ...
    "DS_mu", [-8.05, -7.925, -7.80], ...
    "KF_mu", [-0.80, -0.39, 0.00], ...
    "num_clusters", [8, 12, 16]);

result = run_grid_search(targetGeneration.dataset, config);
disp(result.best.parameters);
```

上例完整评估 `3×3×3=27` 个候选。`targetGeneration` 只是最小演示；
正式流程中的 `targetDataset` 来自模块一已经通过检查的 v3 CIR。

## 2. 指定内插或外推的已知区域

```matlab
task = create_channel_task( ...
    "interpolation", "sample", [1:30, 40:60], 31:39);
config.target.task = task;

result = run_grid_search(dataset, config);
```

搜索只分析 `task.known_indices`，不会读取 `target_indices`。

## 3. GridSearchConfig

| 字段 | 含义 |
|---|---|
| `schema_version` | 固定为 `v3.0-grid-search-config.1` |
| `generator_config` | Step 6 单次生成配置，也是未搜索参数的固定基线 |
| `parameter_space` | 参数名到候选数值向量的映射 |
| `scoring` | PDP/时延扩展权重和数值设置 |
| `limits.max_candidates` | 笛卡尔积候选数上限，默认 500 |
| `limits.retain_top_k` | 保留完整 CIR 的最佳候选数量，默认 5 |
| `target.task` | 内插/外推任务和 known/target 索引 |
| `target.region` | Step 7 固定为 `known` |
| `execution.order` | Step 7 固定为 `sequential` |
| `execution.continue_on_failure` | Step 7 固定为 `true` |

`parameter_space` 中的字段会完整替换默认搜索空间，不会偷偷补入默认的其他参数。

## 4. 先验证、再枚举

```matlab
[report, normalized] = validate_grid_search_config(config);
if report.is_valid
    grid = enumerate_parameter_grid(normalized);
end
```

`report.total_candidates` 是各候选向量长度的乘积。重复值、空向量、未知参数、
不合法整数和超过上限都会在生成 CIR 之前失败。

## 5. GridSearchResult

| 字段 | 含义 |
|---|---|
| `status` | `PASS`、`WARNING` 或 `FAIL` |
| `outcome` | `SUCCEEDED`、`CANCELLED` 或 `FAILED` |
| `success` | 是否至少有一个有效候选且搜索未被取消 |
| `complete` | 是否评估了完整笛卡尔积 |
| `formal_eligible` | 完整搜索且最佳生成结果满足 Formal 条件 |
| `total/completed/succeeded/failed_candidates` | 候选统计 |
| `ranking` | 所有已执行候选的参数、分数、状态与公开生成 Manifest |
| `retained_candidates` | 前 Top K 的完整 GenerationResult 和评分 |
| `best` | 当前完整搜索的最佳候选 |
| `events` | 验证、目标分析、生成、评分和完成事件 |
| `manifest` | 可导出的搜索配置、统计、最佳结果和运行信息 |

调用方应同时检查：

```matlab
if result.success && result.complete
    bestParameters = result.best.parameters;
else
    disp(result.errors);
    disp(result.warnings);
end
```

不要只看 `best` 是否存在。取消搜索可能已经产生暂定候选，但它不是完整网格答案。

## 6. 进度与取消

```matlab
cancelRequested = false;
options = struct( ...
    "progress_callback", @(event) disp(event.message), ...
    "cancel_check", @() cancelRequested);

result = run_grid_search(dataset, config, options);
```

Grid Search 会在候选之间检查取消，并把同一回调继续传给 Generator Adapter。
Full 6GPCM 核心内部仍受 Step 6 的不可拆分限制。

## 7. 独立体验 Demo

```matlab
addpath("examples");
step7_grid_search_demo
```

Demo 默认使用 6GPCM-lite 和 27 个候选，可以：

- 切换 Mock、Lite 或外置 Full；
- 输入 `DS_mu`、`KF_mu`、`num_clusters` 候选；
- 在运行前查看候选总数；
- 观察候选分数、当前最佳、Top 5；
- 比较目标与最佳候选的 PDP 和 RMS 时延扩展分布；
- 查看进度事件、失败与限制说明。

该界面只用于人工检查功能，不修改正式平台 UI。模块二最终是否隐藏为后台流程，
仍按更新后的 v3.0 计划在 Step 12 接入。
