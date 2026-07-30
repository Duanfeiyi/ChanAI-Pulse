function [report, config] = validate_grid_search_config(config)
%VALIDATE_GRID_SEARCH_CONFIG Validate and normalize a Step 7 request.

report = emptyReport();
if ~isstruct(config) || ~isscalar(config)
    report.errors(end + 1, 1) = ...
        "GridSearchConfig must be a scalar struct.";
    report = finalize(report, 0, strings(0, 1));
    config = struct();
    return;
end

backend = "mock";
if isfield(config, "generator_config") && ...
        isstruct(config.generator_config) && ...
        isscalar(config.generator_config) && ...
        isfield(config.generator_config, "backend")
    backend = string(config.generator_config.backend);
end
try
    defaults = default_grid_search_config(backend);
catch exception
    report.errors(end + 1, 1) = string(exception.message);
    report = finalize(report, 0, strings(0, 1));
    config = struct();
    return;
end
suppliedParameterSpace = struct();
hasSuppliedParameterSpace = isfield(config, "parameter_space");
if hasSuppliedParameterSpace
    suppliedParameterSpace = config.parameter_space;
end
config = mergeStruct(defaults, config);
if hasSuppliedParameterSpace
    config.parameter_space = suppliedParameterSpace;
end

if ~isTextScalar(config.schema_version) || ...
        string(config.schema_version) ~= "v3.0-grid-search-config.1"
    report.errors(end + 1, 1) = ...
        "schema_version must be v3.0-grid-search-config.1.";
end

if ~isstruct(config.generator_config) || ...
        ~isscalar(config.generator_config)
    report.errors(end + 1, 1) = ...
        "generator_config must be a scalar struct.";
else
    [generatorReport, normalizedGenerator] = ...
        validate_generator_config(config.generator_config);
    if generatorReport.status == "FAIL"
        report.errors = [report.errors; ...
            "generator_config: " + generatorReport.errors(:)];
    else
        config.generator_config = normalizedGenerator;
        report.warnings = [report.warnings; ...
            generatorReport.warnings(:)];
    end
end

allowedNames = ["DS_mu", "DS_sigma", "r_DS", "num_clusters", ...
    "num_rays", "LNS_ksi", "KF_mu", "KF_sigma"];
parameterNames = strings(0, 1);
totalCandidates = 0;
if ~isstruct(config.parameter_space) || ...
        ~isscalar(config.parameter_space)
    report.errors(end + 1, 1) = ...
        "parameter_space must be a scalar struct.";
else
    suppliedNames = string(fieldnames(config.parameter_space));
    unknownNames = setdiff(suppliedNames, allowedNames, "stable");
    if ~isempty(unknownNames)
        report.errors(end + 1, 1) = ...
            "Unsupported search parameters: " + ...
            strjoin(unknownNames, ", ") + ".";
    end
    parameterNames = allowedNames(ismember(allowedNames, suppliedNames)).';
    if isempty(parameterNames)
        report.errors(end + 1, 1) = ...
            "parameter_space must contain at least one supported parameter.";
    else
        normalizedSpace = struct();
        counts = zeros(numel(parameterNames), 1);
        for index = 1:numel(parameterNames)
            name = parameterNames(index);
            values = config.parameter_space.(name);
            if ~isnumeric(values) || ~isreal(values) || ...
                    ~isvector(values) || isempty(values) || ...
                    any(~isfinite(values))
                report.errors(end + 1, 1) = ...
                    "parameter_space." + name + ...
                    " must be a nonempty finite real vector.";
                continue;
            end
            values = double(values(:).');
            if numel(unique(values, "stable")) ~= numel(values)
                report.errors(end + 1, 1) = ...
                    "parameter_space." + name + ...
                    " contains duplicate values.";
            end
            report = validateParameterValues(report, name, values);
            normalizedSpace.(name) = values;
            counts(index) = numel(values);
        end
        config.parameter_space = normalizedSpace;
        if all(counts > 0)
            totalCandidates = prod(counts);
        end
    end
end

if ~isstruct(config.scoring) || ~isscalar(config.scoring)
    report.errors(end + 1, 1) = "scoring must be a scalar struct.";
else
    for name = ["pdp_weight", "delay_spread_weight"]
        if ~isNonnegativeFinite(config.scoring.(name))
            report.errors(end + 1, 1) = ...
                "scoring." + name + " must be nonnegative and finite.";
        end
    end
    weightSum = config.scoring.pdp_weight + ...
        config.scoring.delay_spread_weight;
    if ~isfinite(weightSum) || weightSum <= 0
        report.errors(end + 1, 1) = ...
            "At least one scoring weight must be positive.";
    else
        config.scoring.pdp_weight = ...
            config.scoring.pdp_weight / weightSum;
        config.scoring.delay_spread_weight = ...
            config.scoring.delay_spread_weight / weightSum;
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

if ~isstruct(config.limits) || ~isscalar(config.limits)
    report.errors(end + 1, 1) = "limits must be a scalar struct.";
else
    if ~isPositiveInteger(config.limits.max_candidates)
        report.errors(end + 1, 1) = ...
            "limits.max_candidates must be a positive integer.";
    elseif totalCandidates > config.limits.max_candidates
        report.errors(end + 1, 1) = sprintf( ...
            "Cartesian product contains %d candidates, exceeding max_candidates=%d.", ...
            totalCandidates, config.limits.max_candidates);
    end
    if ~isPositiveInteger(config.limits.retain_top_k)
        report.errors(end + 1, 1) = ...
            "limits.retain_top_k must be a positive integer.";
    elseif totalCandidates > 0
        config.limits.retain_top_k = min( ...
            config.limits.retain_top_k, totalCandidates);
    end
end

if ~isstruct(config.target) || ~isscalar(config.target)
    report.errors(end + 1, 1) = "target must be a scalar struct.";
else
    if ~isfield(config.target, "region") || ...
            ~isTextScalar(config.target.region) || ...
            lower(string(config.target.region)) ~= "known"
        report.errors(end + 1, 1) = ...
            "target.region must be 'known' in Step 7.";
    else
        config.target.region = "known";
    end
    if ~isfield(config.target, "task") || ...
            ~isstruct(config.target.task) || ...
            ~isscalar(config.target.task)
        report.errors(end + 1, 1) = ...
            "target.task must be a scalar struct.";
    end
end

if ~isstruct(config.execution) || ~isscalar(config.execution)
    report.errors(end + 1, 1) = "execution must be a scalar struct.";
else
    if ~isTextScalar(config.execution.order) || ...
            lower(string(config.execution.order)) ~= "sequential"
        report.errors(end + 1, 1) = ...
            "Step 7 execution.order must be 'sequential'.";
    else
        config.execution.order = "sequential";
    end
    if ~islogical(config.execution.continue_on_failure) || ...
            ~isscalar(config.execution.continue_on_failure) || ...
            ~config.execution.continue_on_failure
        report.errors(end + 1, 1) = ...
            "Step 7 requires execution.continue_on_failure=true.";
    end
end

report.warnings = uniqueNonempty(report.warnings);
report = finalize(report, totalCandidates, parameterNames);
end

function report = validateParameterValues(report, name, values)
switch name
    case {"DS_sigma", "KF_sigma"}
        valid = all(values >= 0);
        rule = "must contain nonnegative values.";
    case {"r_DS", "LNS_ksi"}
        valid = all(values > 0);
        rule = "must contain positive values.";
    case {"num_clusters", "num_rays"}
        valid = all(values > 0 & floor(values) == values);
        rule = "must contain positive integers.";
    otherwise
        valid = true;
        rule = "";
end
if ~valid
    report.errors(end + 1, 1) = ...
        "parameter_space." + name + " " + rule;
end
end

function report = emptyReport()
report = struct( ...
    "status", "FAIL", ...
    "is_valid", false, ...
    "total_candidates", 0, ...
    "parameter_names", strings(0, 1), ...
    "warnings", strings(0, 1), ...
    "errors", strings(0, 1));
end

function report = finalize(report, totalCandidates, parameterNames)
report.total_candidates = totalCandidates;
report.parameter_names = parameterNames(:);
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

function tf = isPositiveInteger(value)
tf = isnumeric(value) && isscalar(value) && isfinite(value) && ...
    value > 0 && floor(value) == value;
end

function tf = isPositiveFinite(value)
tf = isnumeric(value) && isscalar(value) && isfinite(value) && value > 0;
end

function tf = isNonnegativeFinite(value)
tf = isnumeric(value) && isscalar(value) && isfinite(value) && value >= 0;
end

function values = uniqueNonempty(values)
values = string(values(:));
values = values(strlength(strtrim(values)) > 0);
values = unique(values, "stable");
end
