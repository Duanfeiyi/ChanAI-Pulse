function [selected, info, report] = select_channel_task_region( ...
        dataset, task, region)
%SELECT_CHANNEL_TASK_REGION Select the all-data or known task region.
%   The input dataset is never modified. MATLAB one-based task indices are
%   applied only to the declared task axis.

arguments
    dataset (1, 1) struct
    task (1, 1) struct = struct()
    region (1, 1) string {mustBeMember(region, ["known", "all"])} = "known"
end

selected = dataset;
info = struct( ...
    "region", region, ...
    "task_applied", false, ...
    "axis", "none", ...
    "indices", [], ...
    "original_length", NaN, ...
    "selected_length", NaN);
report = struct("status", "PASS", "errors", strings(0, 1), ...
    "warnings", strings(0, 1));

if region == "all" || isempty(fieldnames(task))
    return;
end

taskReport = validate_channel_task(dataset, task);
if ~taskReport.is_valid
    report.status = "FAIL";
    report.errors = taskReport.errors;
    report.warnings = taskReport.warnings;
    return;
end

axisName = lower(string(task.axis));
indices = double(task.known_indices(:)).';
info.task_applied = true;
info.axis = axisName;
info.indices = indices(:);

switch axisName
    case {"sample", "position", "space"}
        info.original_length = dataset.dimensions.N_sample;
        selected = subsetDatasetDimension(selected, 5, indices);
        selected.dimensions.N_sample = numel(indices);
        selected.axes = subsetSampleAxes(selected.axes, indices);
    case "time"
        info.original_length = dataset.dimensions.Nt;
        selected = subsetDatasetDimension(selected, 4, indices);
        selected.dimensions.Nt = numel(indices);
        if isfield(selected.axes, "time_s") && ...
                numel(selected.axes.time_s) >= max(indices)
            selected.axes.time_s = selected.axes.time_s(indices);
        end
    case "frequency"
        if lower(string(dataset.domain)) ~= "ctf"
            report.status = "FAIL";
            report.errors(end + 1, 1) = ...
                "Frequency-region selection requires a CTF dataset.";
            return;
        end
        info.original_length = dataset.dimensions.Nf;
        selected = subsetDatasetDimension(selected, 3, indices);
        selected.dimensions.Nf = numel(indices);
        if isfield(selected.axes, "frequency_hz") && ...
                numel(selected.axes.frequency_hz) >= max(indices)
            selected.axes.frequency_hz = selected.axes.frequency_hz(indices);
        end
    otherwise
        report.status = "FAIL";
        report.errors(end + 1, 1) = ...
            "Unsupported task axis: " + axisName;
        return;
end

info.selected_length = numel(indices);
end

function dataset = subsetDatasetDimension(dataset, dimension, indices)
domain = lower(string(dataset.domain));
if domain == "ctf"
    dataset.ctf.H = subsetValue(dataset.ctf.H, dimension, indices);
else
    fields = ["coefficient", "delay_s", "path_valid", ...
        "aoa_rad", "aod_rad", "doppler_hz"];
    for fieldName = fields
        if isfield(dataset.cir, fieldName)
            dataset.cir.(fieldName) = subsetValue( ...
                dataset.cir.(fieldName), dimension, indices);
        end
    end
end
end

function value = subsetValue(value, dimension, indices)
shape = size5(value);
if shape(dimension) == 1
    return;
end
subscripts = repmat({':'}, 1, 5);
subscripts{dimension} = indices;
value = value(subscripts{:});
newShape = shape;
newShape(dimension) = numel(indices);
value = reshape(value, newShape);
end

function axes = subsetSampleAxes(axes, indices)
if isfield(axes, "sample_index") && ...
        size(axes.sample_index, 1) >= max(indices)
    axes.sample_index = axes.sample_index(indices, :);
end
if isfield(axes, "sample_position_m") && ...
        size(axes.sample_position_m, 1) >= max(indices)
    axes.sample_position_m = axes.sample_position_m(indices, :);
end
end

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end
