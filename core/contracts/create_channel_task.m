function task = create_channel_task(mode, axisName, knownIndices, targetIndices, options)
%CREATE_CHANNEL_TASK Build an interpolation or extrapolation TaskSpec.
%   TASK = CREATE_CHANNEL_TASK(MODE, AXISNAME, KNOWN, TARGET, OPTIONS)
%   creates a task using 1-based indices. OPTIONS may contain axis_values,
%   axis_unit, and description.

arguments
    mode (1, 1) string
    axisName (1, 1) string
    knownIndices {mustBeNumeric}
    targetIndices {mustBeNumeric}
    options (1, 1) struct = struct()
end

mode = lower(strtrim(mode));
axisName = lower(strtrim(axisName));
if ~ismember(mode, ["interpolation", "extrapolation"])
    error("create_channel_task:UnsupportedMode", ...
        "Mode must be 'interpolation' or 'extrapolation'.");
end
if ~ismember(axisName, ["sample", "position", "time", "frequency"])
    error("create_channel_task:UnsupportedAxis", ...
        "Axis must be sample, position, time, or frequency.");
end

task = struct();
task.schema_version = "v3.0-task-contract.1";
task.mode = mode;
task.axis = axisName;
task.known_indices = unique(double(knownIndices(:)), "stable");
task.target_indices = unique(double(targetIndices(:)), "stable");
task.axis_values = getOption(options, "axis_values", []);
task.axis_unit = string(getOption(options, "axis_unit", "index"));
task.description = string(getOption(options, "description", ""));
end

function value = getOption(options, fieldName, defaultValue)
if isfield(options, fieldName)
    value = options.(fieldName);
else
    value = defaultValue;
end
end
