function report = validate_parameter_sequence(sequence)
%VALIDATE_PARAMETER_SEQUENCE Validate the canonical Step 9 sequence.

errors = strings(0, 1);
warnings = strings(0, 1);
required = ["schema_version", "dimension_order", "values", ...
    "parameter_names", "parameter_units", "parameter_bounds", ...
    "parameter_sample_index", "raw_window_start", "raw_window_end", ...
    "raw_window_center", "group_id", "label_source", "fit_score", ...
    "quality_status", "provenance"];
for name = required
    if ~isfield(sequence, name)
        errors(end + 1, 1) = "Missing required field: " + name; %#ok<AGROW>
    end
end
if ~isempty(errors)
    report = finishReport(errors, warnings);
    return;
end

values = double(sequence.values);
[sampleCount, parameterCount] = size(values);
names = string(sequence.parameter_names(:)).';
supported = default_predictor_data_config().supported_parameter_names;
if ~isequal(string(sequence.dimension_order(:)).', ...
        ["N_parameter_sample", "P"])
    errors(end + 1, 1) = ...
        "dimension_order must be [N_parameter_sample, P].";
end
if parameterCount ~= numel(names) || numel(unique(names)) ~= numel(names)
    errors(end + 1, 1) = ...
        "Parameter names must be unique and match the value columns.";
end
unknown = setdiff(names, supported);
if ~isempty(unknown)
    errors(end + 1, 1) = ...
        "Unsupported parameters: " + strjoin(unknown, ", ");
end
if ~isequal(size(sequence.parameter_bounds), [parameterCount, 2])
    errors(end + 1, 1) = "parameter_bounds must have shape P x 2.";
elseif any(sequence.parameter_bounds(:, 1) > ...
        sequence.parameter_bounds(:, 2))
    errors(end + 1, 1) = ...
        "Every lower parameter bound must be <= its upper bound.";
end

rowFields = ["parameter_sample_index", "raw_window_start", ...
    "raw_window_end", "raw_window_center", "group_id", ...
    "label_source", "fit_score", "quality_status"];
for name = rowFields
    if numel(sequence.(name)) ~= sampleCount
        errors(end + 1, 1) = name + ...
            " must have one value per parameter sample."; %#ok<AGROW>
    end
end
if numel(sequence.parameter_units) ~= parameterCount
    errors(end + 1, 1) = ...
        "parameter_units must have one value per parameter.";
end
allowedSources = ["generator_truth", "grid_fitted", "sa_fitted", ...
    "direct_channel_observed"];
badSources = setdiff(unique(string(sequence.label_source)), allowedSources);
if ~isempty(badSources)
    errors(end + 1, 1) = ...
        "Unsupported label_source: " + strjoin(badSources, ", ");
end
allowedQuality = ["PASS", "WARNING", "FAIL"];
badQuality = setdiff(upper(unique(string(sequence.quality_status))), ...
    allowedQuality);
if ~isempty(badQuality)
    errors(end + 1, 1) = ...
        "Unsupported quality_status: " + strjoin(badQuality, ", ");
end
if any(strlength(strtrim(string(sequence.group_id))) == 0)
    errors(end + 1, 1) = "group_id values must not be empty.";
end
if any(sequence.raw_window_end < sequence.raw_window_start)
    errors(end + 1, 1) = ...
        "raw_window_end must not precede raw_window_start.";
end
failedRows = upper(string(sequence.quality_status)) == "FAIL";
if any(~failedRows & any(~isfinite(values), 2))
    errors(end + 1, 1) = ...
        "PASS/WARNING rows must contain finite parameter values.";
end
if isequal(size(sequence.parameter_bounds), [parameterCount, 2])
    below = values < sequence.parameter_bounds(:, 1).';
    above = values > sequence.parameter_bounds(:, 2).';
    if any(~failedRows & any(below | above, 2))
        errors(end + 1, 1) = ...
            "PASS/WARNING parameter values must respect physical bounds.";
    end
end
if any(failedRows)
    warnings(end + 1, 1) = ...
        string(sum(failedRows)) + " failed rows will be excluded.";
end
report = finishReport(errors, warnings);
end

function report = finishReport(errors, warnings)
report = struct( ...
    "status", ternary(isempty(errors), ...
        ternary(isempty(warnings), "PASS", "WARNING"), "FAIL"), ...
    "is_valid", isempty(errors), ...
    "errors", errors, ...
    "warnings", warnings);
end

function value = ternary(condition, whenTrue, whenFalse)
if condition
    value = whenTrue;
else
    value = whenFalse;
end
end
