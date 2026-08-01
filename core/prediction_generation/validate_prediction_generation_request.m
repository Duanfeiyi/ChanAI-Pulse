function report = validate_prediction_generation_request(request)
%VALIDATE_PREDICTION_GENERATION_REQUEST Strict Step 11 request validation.

report = emptyReport();
if ~isstruct(request) || ~isscalar(request)
    report.errors(end + 1, 1) = "Request must be a scalar struct.";
    report = finalize(report);
    return;
end
required = ["schema_version", "task_type", "task_axis", ...
    "parameter_names", "parameter_units", "predicted_parameters", ...
    "target_parameter_sample_index", "target_axis_values", ...
    "target_count", "dimensions", "scenario", "ctf", "backend", ...
    "mode", "master_seed", "parameter_sources", "parameter_bounds", ...
    "engine", "continuity", "runtime", "prediction_manifest"];
missing = required(~isfield(request, required));
for name = missing
    report.errors(end + 1, 1) = "Missing request field: " + name;
end
if ~isempty(report.errors)
    report = finalize(report);
    return;
end

if string(request.schema_version) ~= ...
        "v3.0-prediction-generation-request.1"
    report.errors(end + 1, 1) = "Unsupported request schema_version.";
end
if ~ismember(string(request.task_type), ...
        ["interpolation", "extrapolation"])
    report.errors(end + 1, 1) = ...
        "task_type must be interpolation or extrapolation.";
end
if ~ismember(string(request.task_axis), ...
        ["sample", "position", "time", "frequency"])
    report.errors(end + 1, 1) = ...
        "task_axis must be sample, position, time, or frequency.";
end
if ~ismember(string(request.backend), ...
        ["mock", "lite_6gpcm", "full_6gpcm"])
    report.errors(end + 1, 1) = "Unsupported generator backend.";
end
if ~ismember(string(request.mode), ["preview", "formal"])
    report.errors(end + 1, 1) = "mode must be preview or formal.";
elseif string(request.mode) == "formal" && ...
        string(request.backend) ~= "full_6gpcm"
    report.errors(end + 1, 1) = ...
        "Formal prediction CIR requires the full_6gpcm backend.";
end

values = request.predicted_parameters;
names = string(request.parameter_names(:));
units = string(request.parameter_units(:));
if ~isnumeric(values) || ~isreal(values) || ~ismatrix(values) || ...
        isempty(values) || any(~isfinite(values(:)))
    report.errors(end + 1, 1) = ...
        "predicted_parameters must be a finite real matrix.";
elseif size(values, 1) ~= request.target_count || ...
        size(values, 2) ~= numel(names)
    report.errors(end + 1, 1) = ...
        "predicted_parameters shape does not match targets and parameter names.";
end
if numel(names) ~= numel(units) || ...
        numel(unique(names)) ~= numel(names)
    report.errors(end + 1, 1) = ...
        "parameter_names/units must be aligned and names must be unique.";
end
for requiredName = ["DS_mu", "KF_mu"]
    if ~any(names == requiredName)
        report.errors(end + 1, 1) = ...
            "First Step 11 release requires predicted " + requiredName + ".";
    end
end
if ~isPositiveInteger(request.target_count) || ...
        numel(request.target_parameter_sample_index) ~= request.target_count || ...
        numel(request.target_axis_values) ~= request.target_count
    report.errors(end + 1, 1) = ...
        "Target indices and axis values must match target_count.";
end
if any(~isfinite(double(request.target_axis_values(:))))
    report.errors(end + 1, 1) = "target_axis_values must be finite.";
end
if ~isNonnegativeInteger(request.master_seed)
    report.errors(end + 1, 1) = ...
        "master_seed must be a nonnegative integer.";
end

for fieldName = ["Tx", "Rx", "Nf", "Nt"]
    if ~isfield(request.dimensions, fieldName) || ...
            ~isPositiveInteger(request.dimensions.(fieldName))
        report.errors(end + 1, 1) = ...
            "dimensions." + fieldName + " must be a positive integer.";
    end
end
if ~isfield(request.dimensions, "Npath") || ...
        ~isNonnegativeInteger(request.dimensions.Npath)
    report.errors(end + 1, 1) = ...
        "dimensions.Npath must be a nonnegative integer.";
end
if ~isfield(request.ctf, "enabled") || ...
        ~islogical(request.ctf.enabled) || ~isscalar(request.ctf.enabled)
    report.errors(end + 1, 1) = "ctf.enabled must be logical.";
elseif request.ctf.enabled
    frequencyHz = request.ctf.frequency_hz;
    if ~isnumeric(frequencyHz) || ~isreal(frequencyHz) || ...
            ~isvector(frequencyHz) || ...
            numel(frequencyHz) ~= request.dimensions.Nf || ...
            any(~isfinite(frequencyHz)) || ...
            (numel(frequencyHz) > 1 && any(diff(frequencyHz(:)) <= 0))
        report.errors(end + 1, 1) = ...
            "ctf.frequency_hz must be increasing and match dimensions.Nf.";
    end
end
if ~isfield(request.runtime, "full_timeout_s") || ...
        ~isnumeric(request.runtime.full_timeout_s) || ...
        ~isscalar(request.runtime.full_timeout_s) || ...
        ~isfinite(request.runtime.full_timeout_s) || ...
        request.runtime.full_timeout_s <= 0
    report.errors(end + 1, 1) = ...
        "runtime.full_timeout_s must be positive and finite.";
end

if isfield(request.prediction_manifest, ...
        "request_contains_target_ground_truth") && ...
        logical(request.prediction_manifest. ...
        request_contains_target_ground_truth)
    report.errors(end + 1, 1) = ...
        "Prediction manifest must declare a target-free product request.";
end
report = finalize(report);
end

function report = emptyReport()
report = struct("is_valid", true, "status", "PASS", ...
    "errors", strings(0, 1), "warnings", strings(0, 1));
end

function report = finalize(report)
report.errors = unique(report.errors, "stable");
if ~isempty(report.errors)
    report.is_valid = false;
    report.status = "FAIL";
elseif ~isempty(report.warnings)
    report.status = "WARNING";
else
    report.status = "PASS";
end
end

function tf = isPositiveInteger(value)
tf = isnumeric(value) && isscalar(value) && isfinite(value) && ...
    value > 0 && floor(value) == value;
end

function tf = isNonnegativeInteger(value)
tf = isnumeric(value) && isscalar(value) && isfinite(value) && ...
    value >= 0 && floor(value) == value;
end
