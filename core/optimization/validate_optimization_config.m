function [report, config] = validate_optimization_config(config)
%VALIDATE_OPTIMIZATION_CONFIG Validate and normalize a Step 8 request.

report = emptyReport();
if ~isstruct(config) || ~isscalar(config)
    report.errors(end + 1, 1) = ...
        "OptimizationConfig must be a scalar struct.";
    config = struct();
    report = finalize(report);
    return;
end

backend = "mock";
if isfield(config, "generator_config") && ...
        isstruct(config.generator_config) && ...
        isfield(config.generator_config, "backend")
    backend = string(config.generator_config.backend);
end
try
    defaults = default_optimization_config(backend);
catch exception
    report.errors(end + 1, 1) = string(exception.message);
    config = struct();
    report = finalize(report);
    return;
end

suppliedVariables = struct();
hasSuppliedVariables = isfield(config, "variables");
if hasSuppliedVariables
    suppliedVariables = config.variables;
end
config = mergeStruct(defaults, config);
if hasSuppliedVariables
    config.variables = suppliedVariables;
end

if ~isTextScalar(config.schema_version) || ...
        string(config.schema_version) ~= "v3.0-optimization-config.1"
    report.errors(end + 1, 1) = ...
        "schema_version must be v3.0-optimization-config.1.";
end

requested = lower(strtrim(string(config.requested_strategy)));
if ~isscalar(requested) || ...
        ~ismember(requested, ["auto", "grid", "sa"])
    report.errors(end + 1, 1) = ...
        "requested_strategy must be auto, grid, or sa.";
else
    config.requested_strategy = requested;
end

if ~isstruct(config.generator_config) || ...
        ~isscalar(config.generator_config)
    report.errors(end + 1, 1) = ...
        "generator_config must be a scalar struct.";
else
    [generatorReport, normalizedGenerator] = ...
        validate_generator_config(config.generator_config);
    if ~generatorReport.is_valid
        report.errors = [report.errors; ...
            "generator_config: " + generatorReport.errors(:)];
    else
        config.generator_config = normalizedGenerator;
        report.warnings = [report.warnings; generatorReport.warnings(:)];
    end
end

[report, config, variableNames, allDiscrete, gridCount] = ...
    validateVariables(report, config);
report.parameter_names = variableNames;
report.all_variables_discrete = allDiscrete;
report.grid_candidate_count = gridCount;

[report, config] = validateScoring(report, config);
[report, config] = validateLimits(report, config);
[report, config] = validateSa(report, config, numel(variableNames));
[report, config] = validateAuto(report, config);
[report, config] = validateTargetAndExecution(report, config);

if isempty(report.errors) && config.requested_strategy == "grid"
    if ~allDiscrete
        report.errors(end + 1, 1) = ...
            "Manual Grid Search requires every variable to use type='discrete'.";
    elseif gridCount > config.limits.max_grid_candidates
        report.errors(end + 1, 1) = sprintf( ...
            "Grid contains %d candidates, exceeding max_grid_candidates=%d.", ...
            gridCount, config.limits.max_grid_candidates);
    end
end

if isempty(report.errors)
    report.selection = select_optimization_strategy(config);
end
report.warnings = uniqueNonempty(report.warnings);
report.errors = uniqueNonempty(report.errors);
report = finalize(report);
end

function [report, config, names, allDiscrete, gridCount] = ...
        validateVariables(report, config)
allowed = ["DS_mu", "DS_sigma", "r_DS", "num_clusters", ...
    "num_rays", "LNS_ksi", "KF_mu", "KF_sigma"];
names = strings(0, 1);
allDiscrete = false;
gridCount = 0;
if ~isstruct(config.variables) || ~isscalar(config.variables)
    report.errors(end + 1, 1) = "variables must be a scalar struct.";
    return;
end
supplied = string(fieldnames(config.variables));
unknown = setdiff(supplied, allowed, "stable");
if ~isempty(unknown)
    report.errors(end + 1, 1) = ...
        "Unsupported optimization variables: " + strjoin(unknown, ", ") + ".";
end
names = allowed(ismember(allowed, supplied)).';
if isempty(names)
    report.errors(end + 1, 1) = ...
        "variables must contain at least one supported parameter.";
    return;
end

normalized = struct();
allDiscrete = true;
gridCount = 1;
for index = 1:numel(names)
    name = names(index);
    descriptor = config.variables.(name);
    if ~isstruct(descriptor) || ~isscalar(descriptor) || ...
            ~isfield(descriptor, "type") || ...
            ~isTextScalar(descriptor.type)
        report.errors(end + 1, 1) = ...
            "variables." + name + " must be a scalar descriptor with type.";
        allDiscrete = false;
        gridCount = Inf;
        continue;
    end
    type = lower(strtrim(string(descriptor.type)));
    if ~ismember(type, ["continuous", "integer", "discrete"])
        report.errors(end + 1, 1) = ...
            "variables." + name + ...
            ".type must be continuous, integer, or discrete.";
        allDiscrete = false;
        gridCount = Inf;
        continue;
    end
    if ismember(name, ["num_clusters", "num_rays"]) && ...
            type == "continuous"
        report.errors(end + 1, 1) = ...
            "variables." + name + ...
            " represents a count and cannot use type='continuous'.";
    end
    defaultInitial = config.generator_config.model.(name);
    stepFraction = 0.10;
    if isfield(descriptor, "step_fraction")
        stepFraction = descriptor.step_fraction;
    end
    if ~isPositiveFinite(stepFraction) || stepFraction > 1
        report.errors(end + 1, 1) = ...
            "variables." + name + ...
            ".step_fraction must be in (0, 1].";
    end

    if type == "discrete"
        if ~isfield(descriptor, "values") || ...
                ~isnumeric(descriptor.values) || ...
                ~isreal(descriptor.values) || ...
                ~isvector(descriptor.values) || ...
                isempty(descriptor.values) || ...
                any(~isfinite(descriptor.values))
            report.errors(end + 1, 1) = ...
                "variables." + name + ...
                ".values must be a nonempty finite real vector.";
            continue;
        end
        values = double(descriptor.values(:).');
        if numel(unique(values, "stable")) ~= numel(values)
            report.errors(end + 1, 1) = ...
                "variables." + name + ".values contains duplicates.";
        end
        report = validatePhysical(report, name, values);
        initial = defaultInitial;
        if isfield(descriptor, "initial")
            initial = descriptor.initial;
        end
        if ~isFiniteScalar(initial)
            report.errors(end + 1, 1) = ...
                "variables." + name + ".initial must be finite.";
            initial = values(1);
        end
        [~, nearest] = min(abs(values - double(initial)));
        normalized.(name) = struct( ...
            "type", type, ...
            "values", values, ...
            "initial", values(nearest), ...
            "step_fraction", double(stepFraction));
        gridCount = gridCount * numel(values);
    else
        allDiscrete = false;
        gridCount = Inf;
        if ~isfield(descriptor, "lower") || ...
                ~isfield(descriptor, "upper") || ...
                ~isFiniteScalar(descriptor.lower) || ...
                ~isFiniteScalar(descriptor.upper) || ...
                descriptor.lower >= descriptor.upper
            report.errors(end + 1, 1) = ...
                "variables." + name + ...
                " requires explicit finite lower < upper bounds.";
            continue;
        end
        lowerBound = double(descriptor.lower);
        upperBound = double(descriptor.upper);
        if type == "integer" && ...
                (floor(lowerBound) ~= lowerBound || ...
                floor(upperBound) ~= upperBound)
            report.errors(end + 1, 1) = ...
                "Integer bounds for variables." + name + ...
                " must be integers.";
        end
        report = validatePhysical(report, name, ...
            [lowerBound, upperBound]);
        initial = defaultInitial;
        if isfield(descriptor, "initial")
            initial = descriptor.initial;
        end
        if ~isFiniteScalar(initial)
            report.errors(end + 1, 1) = ...
                "variables." + name + ".initial must be finite.";
            initial = lowerBound;
        end
        initial = min(upperBound, max(lowerBound, double(initial)));
        if type == "integer"
            initial = round(initial);
        end
        normalized.(name) = struct( ...
            "type", type, ...
            "lower", lowerBound, ...
            "upper", upperBound, ...
            "initial", initial, ...
            "step_fraction", double(stepFraction));
    end
end
config.variables = normalized;
end

function report = validatePhysical(report, name, values)
switch name
    case {"DS_sigma", "KF_sigma"}
        valid = all(values >= 0);
        rule = "must be nonnegative.";
    case {"r_DS", "LNS_ksi"}
        valid = all(values > 0);
        rule = "must be positive.";
    case {"num_clusters", "num_rays"}
        valid = all(values > 0 & floor(values) == values);
        rule = "must be positive integers.";
    otherwise
        valid = true;
        rule = "";
end
if ~valid
    report.errors(end + 1, 1) = ...
        "variables." + name + " " + rule;
end
end

function [report, config] = validateScoring(report, config)
if ~isstruct(config.scoring) || ~isscalar(config.scoring)
    report.errors(end + 1, 1) = "scoring must be a scalar struct.";
    return;
end
for name = ["pdp_weight", "delay_spread_weight"]
    if ~isNonnegativeFinite(config.scoring.(name))
        report.errors(end + 1, 1) = ...
            "scoring." + name + " must be nonnegative and finite.";
    end
end
weightSum = config.scoring.pdp_weight + ...
    config.scoring.delay_spread_weight;
if isfinite(weightSum) && weightSum > 0
    config.scoring.pdp_weight = config.scoring.pdp_weight / weightSum;
    config.scoring.delay_spread_weight = ...
        config.scoring.delay_spread_weight / weightSum;
else
    report.errors(end + 1, 1) = ...
        "At least one scoring weight must be positive.";
end
if ~isPositiveInteger(config.scoring.common_delay_bins) || ...
        config.scoring.common_delay_bins < 16
    report.errors(end + 1, 1) = ...
        "scoring.common_delay_bins must be an integer >= 16.";
end
for name = ["delay_window_margin", ...
        "delay_spread_log_scale_decades", "epsilon"]
    if ~isPositiveFinite(config.scoring.(name))
        report.errors(end + 1, 1) = ...
            "scoring." + name + " must be positive and finite.";
    end
end
end

function [report, config] = validateLimits(report, config)
if ~isstruct(config.limits) || ~isscalar(config.limits)
    report.errors(end + 1, 1) = "limits must be a scalar struct.";
    return;
end
for name = ["max_evaluations", "max_consecutive_failures", ...
        "retain_top_k", "max_grid_candidates"]
    if ~isPositiveInteger(config.limits.(name))
        report.errors(end + 1, 1) = ...
            "limits." + name + " must be a positive integer.";
    end
end
end

function [report, config] = validateSa(report, config, parameterCount)
if ~isstruct(config.sa) || ~isscalar(config.sa)
    report.errors(end + 1, 1) = "sa must be a scalar struct.";
    return;
end
for name = ["initial_temperature", "minimum_temperature", ...
        "initial_step_fraction", "minimum_step_fraction"]
    if ~isPositiveFinite(config.sa.(name))
        report.errors(end + 1, 1) = ...
            "sa." + name + " must be positive and finite.";
    end
end
if isPositiveFinite(config.sa.initial_temperature) && ...
        isPositiveFinite(config.sa.minimum_temperature) && ...
        config.sa.minimum_temperature >= config.sa.initial_temperature
    report.errors(end + 1, 1) = ...
        "sa.minimum_temperature must be below initial_temperature.";
end
if ~isPositiveFinite(config.sa.cooling_rate) || ...
        config.sa.cooling_rate >= 1
    report.errors(end + 1, 1) = ...
        "sa.cooling_rate must be in (0, 1).";
end
if ~isPositiveInteger(config.sa.optimizer_seed)
    report.errors(end + 1, 1) = ...
        "sa.optimizer_seed must be a positive integer.";
end
if ~isPositiveInteger(config.sa.no_improvement_limit)
    report.errors(end + 1, 1) = ...
        "sa.no_improvement_limit must be a positive integer.";
end
if ~isnumeric(config.sa.proposals_per_temperature) || ...
        ~isscalar(config.sa.proposals_per_temperature) || ...
        ~isfinite(config.sa.proposals_per_temperature) || ...
        config.sa.proposals_per_temperature < 0 || ...
        floor(config.sa.proposals_per_temperature) ~= ...
        config.sa.proposals_per_temperature
    report.errors(end + 1, 1) = ...
        "sa.proposals_per_temperature must be zero or a positive integer.";
elseif config.sa.proposals_per_temperature == 0
    config.sa.proposals_per_temperature = max(5, 2 * parameterCount);
end
if config.sa.minimum_step_fraction > config.sa.initial_step_fraction
    report.errors(end + 1, 1) = ...
        "sa.minimum_step_fraction cannot exceed initial_step_fraction.";
end
end

function [report, config] = validateAuto(report, config)
if ~isstruct(config.auto) || ~isscalar(config.auto) || ...
        ~isstruct(config.auto.grid_candidate_caps) || ...
        ~isscalar(config.auto.grid_candidate_caps)
    report.errors(end + 1, 1) = ...
        "auto.grid_candidate_caps must be a scalar struct.";
    return;
end
for backend = ["mock", "lite_6gpcm", "full_6gpcm"]
    if ~isfield(config.auto.grid_candidate_caps, backend) || ...
            ~isPositiveInteger( ...
                config.auto.grid_candidate_caps.(backend))
        report.errors(end + 1, 1) = ...
            "auto.grid_candidate_caps." + backend + ...
            " must be a positive integer.";
    end
end
end

function [report, config] = validateTargetAndExecution(report, config)
if ~isstruct(config.target) || ~isscalar(config.target) || ...
        ~isfield(config.target, "task") || ...
        ~isstruct(config.target.task) || ...
        ~isscalar(config.target.task) || ...
        ~isfield(config.target, "region") || ...
        lower(string(config.target.region)) ~= "known"
    report.errors(end + 1, 1) = ...
        "target must contain scalar task and region='known'.";
else
    config.target.region = "known";
end
if ~isstruct(config.execution) || ~isscalar(config.execution) || ...
        lower(string(config.execution.order)) ~= "sequential" || ...
        ~islogical(config.execution.continue_on_failure) || ...
        ~isscalar(config.execution.continue_on_failure) || ...
        ~config.execution.continue_on_failure
    report.errors(end + 1, 1) = ...
        "Step 8 requires sequential execution and continue_on_failure=true.";
else
    config.execution.order = "sequential";
end
end

function report = emptyReport()
report = struct( ...
    "status", "FAIL", ...
    "is_valid", false, ...
    "parameter_names", strings(0, 1), ...
    "all_variables_discrete", false, ...
    "grid_candidate_count", 0, ...
    "selection", struct(), ...
    "warnings", strings(0, 1), ...
    "errors", strings(0, 1));
end

function report = finalize(report)
if isempty(report.errors)
    report.is_valid = true;
    if isempty(report.warnings)
        report.status = "PASS";
    else
        report.status = "WARNING";
    end
else
    report.is_valid = false;
    report.status = "FAIL";
end
end

function output = mergeStruct(defaults, supplied)
output = defaults;
for nameCell = fieldnames(supplied).'
    name = nameCell{1};
    if isfield(output, name) && isstruct(output.(name)) && ...
            isscalar(output.(name)) && isstruct(supplied.(name)) && ...
            isscalar(supplied.(name))
        output.(name) = mergeStruct(output.(name), supplied.(name));
    else
        output.(name) = supplied.(name);
    end
end
end

function tf = isTextScalar(value)
tf = (isstring(value) && isscalar(value)) || ...
    (ischar(value) && (isrow(value) || isempty(value)));
end

function tf = isFiniteScalar(value)
tf = isnumeric(value) && isreal(value) && ...
    isscalar(value) && isfinite(value);
end

function tf = isPositiveInteger(value)
tf = isFiniteScalar(value) && value > 0 && floor(value) == value;
end

function tf = isPositiveFinite(value)
tf = isFiniteScalar(value) && value > 0;
end

function tf = isNonnegativeFinite(value)
tf = isFiniteScalar(value) && value >= 0;
end

function values = uniqueNonempty(values)
values = string(values(:));
values = values(strlength(strtrim(values)) > 0);
values = unique(values, "stable");
end
