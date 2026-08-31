function report = validate_channel_task(dataset, task)
%VALIDATE_CHANNEL_TASK Validate interpolation/extrapolation task regions.

report = struct( ...
    "is_valid", true, ...
    "status", "PASS", ...
    "errors", strings(0, 1), ...
    "warnings", strings(0, 1));

if ~isstruct(task) || ~isscalar(task)
    report = addError(report, "Task must be a scalar struct.");
    report = finalize(report);
    return;
end

required = ["schema_version", "mode", "axis", ...
    "known_indices", "target_indices"];
for fieldName = required
    if ~isfield(task, fieldName)
        report = addError(report, "Missing task field: " + fieldName);
    end
end
if ~isempty(report.errors)
    report = finalize(report);
    return;
end

mode = lower(string(task.mode));
axisName = lower(string(task.axis));
if axisName == "position"
    axisName = "space";  % v3.2 compatibility alias
end
if ~ismember(mode, ["interpolation", "extrapolation"])
    report = addError(report, ...
        "Task mode must be interpolation or extrapolation.");
end
if ~ismember(axisName, ["sample", "space", "time", "frequency"])
    report = addError(report, ...
        "Task axis must be sample, space, time, or frequency.");
end
if ~isempty(report.errors)
    report = finalize(report);
    return;
end

known = double(task.known_indices(:));
target = double(task.target_indices(:));
if isempty(known)
    report = addError(report, "known_indices must not be empty.");
end
if isempty(target)
    report = addError(report, "target_indices must not be empty.");
end
if any(~isfinite(known)) || any(known < 1) || any(mod(known, 1) ~= 0)
    report = addError(report, ...
        "known_indices must contain positive finite integers.");
end
if any(~isfinite(target)) || any(target < 1) || any(mod(target, 1) ~= 0)
    report = addError(report, ...
        "target_indices must contain positive finite integers.");
end
if numel(unique(known)) ~= numel(known)
    report = addError(report, "known_indices contains duplicates.");
end
if numel(unique(target)) ~= numel(target)
    report = addError(report, "target_indices contains duplicates.");
end
if any(ismember(known, target))
    report = addError(report, ...
        "known_indices and target_indices must not overlap.");
end

axisLength = taskAxisLength(dataset, task, axisName);
if isfinite(axisLength) && ...
        (any(known > axisLength) || any(target > axisLength))
    report = addError(report, ...
        "Task indices exceed the declared task-axis length.");
end

if isempty(report.errors)
    lowerKnown = min(known);
    upperKnown = max(known);
    if mode == "interpolation" && ...
            any(target <= lowerKnown | target >= upperKnown)
        report = addError(report, ...
            "Interpolation targets must lie strictly inside the known-index range.");
    elseif mode == "extrapolation" && ...
            any(target > lowerKnown & target < upperKnown)
        report = addError(report, ...
            "Extrapolation targets must lie outside the known-index range.");
    end
end

if axisName == "frequency" && dataset.dimensions.Nf <= 1
    report = addError(report, ...
        "Frequency interpolation/extrapolation requires Nf > 1.");
elseif axisName == "time" && dataset.dimensions.Nt <= 1
    report = addError(report, ...
        "Time interpolation/extrapolation requires Nt > 1.");
elseif axisName == "space" && ...
        ~isfield(dataset.axes, "sample_position_m") && ...
        (~isfield(task, "axis_values") || isempty(task.axis_values))
    report = addError(report, ...
        "Space task requires sample_position_m or task.axis_values.");
end

report = finalize(report);
end

function axisLength = taskAxisLength(dataset, task, axisName)
if isfield(task, "axis_values") && ~isempty(task.axis_values)
    axisLength = numel(task.axis_values);
    return;
end
switch axisName
    case {"sample", "space", "position"}
        axisLength = dataset.dimensions.N_sample;
    case "time"
        axisLength = dataset.dimensions.Nt;
    case "frequency"
        axisLength = dataset.dimensions.Nf;
    otherwise
        axisLength = NaN;
end
end

function report = addError(report, message)
report.errors(end + 1, 1) = string(message);
report.is_valid = false;
end

function report = finalize(report)
if ~isempty(report.errors)
    report.status = "FAIL";
    report.is_valid = false;
elseif ~isempty(report.warnings)
    report.status = "WARNING";
else
    report.status = "PASS";
end
end
