function task = create_channel_task_preset(dataset, mode, axisName, options)
%CREATE_CHANNEL_TASK_PRESET Create the approved 80/20 task partition.
%   Interpolation places the target block in the middle and keeps samples
%   on both sides. Extrapolation uses the first 80% as known and the final
%   20% as target. All indices are MATLAB 1-based indices.

arguments
    dataset (1, 1) struct
    mode (1, 1) string
    axisName (1, 1) string
    options (1, 1) struct = struct()
end

mode = lower(strtrim(mode));
axisName = lower(strtrim(axisName));
axisLength = getAxisLength(dataset, axisName);
if mode == "interpolation" && axisLength < 3
    error("create_channel_task_preset:AxisTooShort", ...
        "Interpolation needs at least three values on the selected axis.");
elseif mode == "extrapolation" && axisLength < 2
    error("create_channel_task_preset:AxisTooShort", ...
        "Extrapolation needs at least two values on the selected axis.");
elseif ~ismember(mode, ["interpolation", "extrapolation"])
    error("create_channel_task_preset:UnsupportedMode", ...
        "Mode must be interpolation or extrapolation.");
end

targetCount = max(1, round(axisLength * 0.20));
if mode == "interpolation"
    targetCount = min(targetCount, axisLength - 2);
    targetStart = floor((axisLength - targetCount) / 2) + 1;
    targetIndices = targetStart:(targetStart + targetCount - 1);
    knownIndices = setdiff(1:axisLength, targetIndices, "stable");
else
    targetCount = min(targetCount, axisLength - 1);
    knownIndices = 1:(axisLength - targetCount);
    targetIndices = (axisLength - targetCount + 1):axisLength;
end

taskOptions = axisTaskOptions(dataset, axisName);
taskOptions.description = string(getOption(options, "description", ...
    "Step 4 80/20 quick preset"));
task = create_channel_task(mode, axisName, ...
    knownIndices, targetIndices, taskOptions);
end

function axisLength = getAxisLength(dataset, axisName)
switch axisName
    case {"sample", "position"}
        axisLength = dataset.dimensions.N_sample;
    case "time"
        axisLength = dataset.dimensions.Nt;
    case "frequency"
        axisLength = dataset.dimensions.Nf;
    otherwise
        error("create_channel_task_preset:UnsupportedAxis", ...
            "Axis must be sample, position, time, or frequency.");
end
end

function taskOptions = axisTaskOptions(dataset, axisName)
taskOptions = struct("axis_values", [], "axis_unit", "index");
switch axisName
    case "sample"
        if isfield(dataset.axes, "sample_index")
            taskOptions.axis_values = dataset.axes.sample_index(:);
        end
    case "position"
        taskOptions.axis_unit = "m";
        if isfield(dataset.axes, "sample_position_m") && ...
                isvector(dataset.axes.sample_position_m)
            taskOptions.axis_values = dataset.axes.sample_position_m(:);
        end
    case "time"
        taskOptions.axis_unit = "s";
        if isfield(dataset.axes, "time_s")
            taskOptions.axis_values = dataset.axes.time_s(:);
        end
    case "frequency"
        taskOptions.axis_unit = "Hz";
        if isfield(dataset.axes, "frequency_hz")
            taskOptions.axis_values = dataset.axes.frequency_hz(:);
        end
end
end

function value = getOption(options, fieldName, defaultValue)
if isfield(options, fieldName)
    value = options.(fieldName);
else
    value = defaultValue;
end
end
