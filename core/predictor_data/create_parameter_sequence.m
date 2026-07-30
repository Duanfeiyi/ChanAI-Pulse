function sequence = create_parameter_sequence(values, parameterNames, options)
%CREATE_PARAMETER_SEQUENCE Create a canonical Step 9 parameter sequence.
%   VALUES has shape N_parameter_sample x P. OPTIONS may contain:
%   group_id, label_source, fit_score, quality_status, units, bounds,
%   parameter_sample_index, raw_window_start/end/center, and provenance.

arguments
    values double
    parameterNames
    options (1, 1) struct = struct()
end

values = double(values);
parameterNames = string(parameterNames(:)).';
if isvector(values) && isscalar(parameterNames)
    values = values(:);
end
[sampleCount, parameterCount] = size(values);
if parameterCount ~= numel(parameterNames)
    error("create_parameter_sequence:ParameterCountMismatch", ...
        "VALUES has %d columns, but %d parameter names were provided.", ...
        parameterCount, numel(parameterNames));
end
if sampleCount < 1 || parameterCount < 1
    error("create_parameter_sequence:EmptyValues", ...
        "At least one parameter sample and one parameter are required.");
end

sequence = struct( ...
    "schema_version", "v3.0-parameter-sequence.1", ...
    "dimension_order", ["N_parameter_sample", "P"], ...
    "values", values, ...
    "parameter_names", parameterNames, ...
    "parameter_units", optionRow(options, "units", ...
        defaultParameterUnits(parameterNames), parameterCount), ...
    "parameter_bounds", optionBounds(options, parameterNames), ...
    "parameter_sample_index", optionNumericColumn(options, ...
        "parameter_sample_index", (1:sampleCount).', sampleCount), ...
    "raw_window_start", optionNumericColumn(options, ...
        "raw_window_start", (1:sampleCount).', sampleCount), ...
    "raw_window_end", optionNumericColumn(options, ...
        "raw_window_end", (1:sampleCount).', sampleCount), ...
    "raw_window_center", optionNumericColumn(options, ...
        "raw_window_center", (1:sampleCount).', sampleCount), ...
    "group_id", optionStringColumn(options, "group_id", ...
        repmat("group-001", sampleCount, 1), sampleCount), ...
    "label_source", optionStringColumn(options, "label_source", ...
        repmat("generator_truth", sampleCount, 1), sampleCount), ...
    "fit_score", optionNumericColumn(options, "fit_score", ...
        nan(sampleCount, 1), sampleCount), ...
    "quality_status", optionStringColumn(options, "quality_status", ...
        repmat("PASS", sampleCount, 1), sampleCount), ...
    "provenance", optionStruct(options, "provenance"), ...
    "summary", struct( ...
        "N_parameter_sample", sampleCount, ...
        "P", parameterCount));

report = validate_parameter_sequence(sequence);
if ~report.is_valid
    error("create_parameter_sequence:InvalidSequence", ...
        "%s", strjoin(report.errors, " | "));
end
end

function value = optionRow(options, fieldName, fallback, count)
value = fallback;
if isfield(options, fieldName)
    value = string(options.(fieldName));
end
value = string(value(:)).';
if numel(value) ~= count
    error("create_parameter_sequence:OptionSizeMismatch", ...
        "Option %s must contain %d values.", fieldName, count);
end
end

function value = optionBounds(options, names)
count = numel(names);
value = defaultParameterBounds(names);
if isfield(options, "bounds")
    value = double(options.bounds);
end
if ~isequal(size(value), [count, 2])
    error("create_parameter_sequence:BoundsSizeMismatch", ...
        "Parameter bounds must have shape P x 2.");
end
end

function value = optionNumericColumn(options, fieldName, fallback, count)
value = fallback;
if isfield(options, fieldName)
    value = double(options.(fieldName));
end
value = double(value(:));
if numel(value) ~= count
    error("create_parameter_sequence:OptionSizeMismatch", ...
        "Option %s must contain %d values.", fieldName, count);
end
end

function value = optionStringColumn(options, fieldName, fallback, count)
value = fallback;
if isfield(options, fieldName)
    value = string(options.(fieldName));
end
if isscalar(value)
    value = repmat(string(value), count, 1);
else
    value = string(value(:));
end
if numel(value) ~= count
    error("create_parameter_sequence:OptionSizeMismatch", ...
        "Option %s must contain %d values.", fieldName, count);
end
end

function value = optionStruct(options, fieldName)
value = struct();
if isfield(options, fieldName)
    value = options.(fieldName);
end
end

function units = defaultParameterUnits(names)
units = repmat("engine_native", size(names));
units(names == "DS_mu") = "log10_s";
units(names == "DS_sigma") = "log10_s_std";
units(names == "r_DS") = "dimensionless";
units(ismember(names, ["num_clusters", "num_rays"])) = "count";
units(names == "LNS_ksi") = "dB";
units(ismember(names, ["KF_mu", "KF_sigma"])) = "dB";
end

function bounds = defaultParameterBounds(names)
bounds = repmat([-Inf, Inf], numel(names), 1);
bounds(ismember(names, ["DS_sigma", "KF_sigma"]), 1) = 0;
bounds(ismember(names, ["r_DS", "LNS_ksi"]), 1) = eps;
bounds(ismember(names, ["num_clusters", "num_rays"]), 1) = 1;
end
