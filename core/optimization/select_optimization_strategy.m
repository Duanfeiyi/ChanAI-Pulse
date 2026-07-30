function selection = select_optimization_strategy(config)
%SELECT_OPTIMIZATION_STRATEGY Explain and choose Grid Search or SA.

requested = lower(string(config.requested_strategy));
names = string(fieldnames(config.variables));
allDiscrete = true;
gridCandidates = 1;
for index = 1:numel(names)
    variable = config.variables.(names(index));
    isDiscrete = string(variable.type) == "discrete";
    allDiscrete = allDiscrete && isDiscrete;
    if isDiscrete
        gridCandidates = gridCandidates * numel(variable.values);
    else
        gridCandidates = Inf;
    end
end

backend = string(config.generator_config.backend);
backendCap = config.auto.grid_candidate_caps.(backend);
hardCap = config.limits.max_grid_candidates;
effectiveCap = min(backendCap, hardCap);

selection = struct( ...
    "requested_strategy", requested, ...
    "selected_strategy", "", ...
    "source", "", ...
    "reason_code", "", ...
    "reason", "", ...
    "all_variables_discrete", allDiscrete, ...
    "grid_candidate_count", gridCandidates, ...
    "backend_grid_cap", backendCap, ...
    "hard_grid_cap", hardCap);

if requested == "grid"
    selection.selected_strategy = "grid";
    selection.source = "manual";
    selection.reason_code = "MANUAL_GRID";
    selection.reason = ...
        "用户明确选择 Grid Search；配置已通过离散空间和硬上限检查。";
elseif requested == "sa"
    selection.selected_strategy = "sa";
    selection.source = "manual";
    selection.reason_code = "MANUAL_SA";
    selection.reason = "用户明确选择模拟退火 SA。";
elseif allDiscrete && gridCandidates <= effectiveCap
    selection.selected_strategy = "grid";
    selection.source = "auto";
    selection.reason_code = "AUTO_SMALL_DISCRETE_GRID";
    selection.reason = sprintf( ...
        "全部变量均为离散值，组合数 %d 不超过当前后端自动上限 %d。", ...
        gridCandidates, effectiveCap);
else
    selection.selected_strategy = "sa";
    selection.source = "auto";
    if ~allDiscrete
        selection.reason_code = "AUTO_CONTINUOUS_OR_INTEGER_SA";
        selection.reason = ...
            "搜索空间包含连续或整数区间，不能完整枚举，因此自动选择 SA。";
    else
        selection.reason_code = "AUTO_GRID_TOO_LARGE_SA";
        selection.reason = sprintf( ...
            "离散组合数 %d 超过当前后端自动上限 %d，因此自动选择 SA。", ...
            gridCandidates, effectiveCap);
    end
end
end
