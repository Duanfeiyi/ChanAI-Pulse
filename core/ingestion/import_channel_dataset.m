function result = import_channel_dataset(filePath, options)
%IMPORT_CHANNEL_DATASET Run the Step 4 module-one input pipeline.
%   RESULT always contains dataset, task, validation, capabilities, and
%   provenance fields. Expected user-data problems are returned as a FAIL
%   report instead of leaking low-level MAT/HDF5 exceptions.
%
%   OPTIONS fields:
%     task_mode       interpolation | extrapolation | "" (no task)
%     task_axis       sample | position | time | frequency
%     task_preset     "80_20" | "manual"
%     known_indices   manual known indices
%     target_indices  manual target indices
%     description     optional TaskSpec description

arguments
    filePath (1, 1) string
    options (1, 1) struct = struct()
end

result = emptyResult();
beforeInfo = safeFileInfo(filePath);
fileReport = inspect_channel_input_file(filePath);
result.file = fileReport;
if ~fileReport.is_valid
    result.validation = combineReports(fileReport, [], []);
    result.status = result.validation.status;
    return;
end

try
    dataset = read_channel_dataset_hdf5(filePath);
catch exception
    readReport = failureReport( ...
        "The v3 HDF5 payload could not be reconstructed: " + ...
        string(exception.message));
    result.validation = combineReports(fileReport, readReport, []);
    result.status = result.validation.status;
    return;
end

datasetReport = validate_channel_dataset(dataset);
result.dataset = dataset;
if ~datasetReport.is_valid
    result.validation = combineReports(fileReport, datasetReport, []);
    result.status = result.validation.status;
    return;
end

result.capabilities = infer_channel_capabilities(dataset);
result.provenance = createProvenance(filePath, fileReport, ...
    beforeInfo, safeFileInfo(filePath), dataset);

[task, taskReport] = buildTask(dataset, options);
result.task = task;
result.validation = combineReports(fileReport, datasetReport, taskReport);
result.status = result.validation.status;
end

function [task, report] = buildTask(dataset, options)
task = struct();
mode = lower(strtrim(string(getOption(options, "task_mode", ""))));
axisName = lower(strtrim(string(getOption(options, "task_axis", ""))));
if mode == "" && axisName == ""
    report = warningReport( ...
        "Channel data passed validation, but no interpolation/extrapolation " + ...
        "task has been configured yet.");
    return;
elseif mode == "" || axisName == ""
    report = failureReport( ...
        "Both task_mode and task_axis are required when configuring a task.");
    return;
end

preset = lower(strtrim(string(getOption(options, "task_preset", "manual"))));
description = string(getOption(options, "description", ""));
try
    if preset == "80_20"
        task = create_channel_task_preset(dataset, mode, axisName, ...
            struct("description", description));
    elseif preset == "manual"
        known = getOption(options, "known_indices", []);
        target = getOption(options, "target_indices", []);
        taskOptions = taskAxisOptions(dataset, axisName);
        taskOptions.description = description;
        task = create_channel_task(mode, axisName, ...
            known, target, taskOptions);
    else
        report = failureReport( ...
            "task_preset must be '80_20' or 'manual'.");
        return;
    end
    report = validate_channel_task(dataset, task);
catch exception
    report = failureReport( ...
        "The task could not be created: " + string(exception.message));
end
end

function options = taskAxisOptions(dataset, axisName)
options = struct("axis_values", [], "axis_unit", "index");
if axisName == "position"
    axisName = "space";  % v3.2 compatibility alias
end
switch axisName
    case "sample"
        if isfield(dataset.axes, "sample_index")
            options.axis_values = dataset.axes.sample_index(:);
        end
    case "space"
        options.axis_unit = "m";
        if isfield(dataset.axes, "sample_position_m")
            positions = dataset.axes.sample_position_m;
            if isvector(positions)
                options.axis_values = positions(:);
            else
                % N_sample-by-(1|2|3) route coordinates: use the
                % along-track x component as the space axis value.
                options.axis_values = positions(:, 1);
            end
        end
    case "time"
        options.axis_unit = "s";
        if isfield(dataset.axes, "time_s")
            options.axis_values = dataset.axes.time_s(:);
        end
    case "frequency"
        options.axis_unit = "Hz";
        if isfield(dataset.axes, "frequency_hz")
            options.axis_values = dataset.axes.frequency_hz(:);
        end
end
end

function provenance = createProvenance(filePath, fileReport, ...
        beforeInfo, afterInfo, dataset)
[~, baseName, extension] = fileparts(filePath);
provenance = struct();
provenance.source_file_name = string(baseName) + string(extension);
provenance.source_format = fileReport.source_extension;
provenance.source_bytes = fileReport.source_bytes;
provenance.dataset_source = string(dataset.metadata.source);
provenance.imported_utc = string(datetime("now", ...
    "TimeZone", "UTC", "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'"));
provenance.read_only_import = true;
provenance.original_file_unchanged = ...
    beforeInfo.exists && afterInfo.exists && ...
    beforeInfo.bytes == afterInfo.bytes && ...
    beforeInfo.modified == afterInfo.modified;
end

function info = safeFileInfo(filePath)
info = struct("exists", false, "bytes", 0, "modified", NaN);
if isfile(filePath)
    value = dir(filePath);
    info.exists = true;
    info.bytes = value.bytes;
    info.modified = value.datenum;
end
end

function combined = combineReports(fileReport, datasetReport, taskReport)
combined = struct( ...
    "is_valid", true, ...
    "status", "PASS", ...
    "errors", strings(0, 1), ...
    "warnings", strings(0, 1), ...
    "file", fileReport, ...
    "dataset", datasetReport, ...
    "task", taskReport);

stages = {fileReport, datasetReport, taskReport};
stageNames = ["file", "dataset", "task"];
for index = 1:numel(stages)
    report = stages{index};
    if isempty(report)
        continue;
    end
    if isfield(report, "errors")
        for message = string(report.errors(:)).'
            combined.errors(end + 1, 1) = ...
                stageNames(index) + ": " + message;
        end
    end
    if isfield(report, "warnings")
        for message = string(report.warnings(:)).'
            combined.warnings(end + 1, 1) = ...
                stageNames(index) + ": " + message;
        end
    end
end

if ~isempty(combined.errors)
    combined.status = "FAIL";
    combined.is_valid = false;
elseif ~isempty(combined.warnings)
    combined.status = "WARNING";
else
    combined.status = "PASS";
end
end

function report = failureReport(message)
report = struct( ...
    "is_valid", false, ...
    "status", "FAIL", ...
    "errors", string(message), ...
    "warnings", strings(0, 1));
end

function report = warningReport(message)
report = struct( ...
    "is_valid", true, ...
    "status", "WARNING", ...
    "errors", strings(0, 1), ...
    "warnings", string(message));
end

function result = emptyResult()
result = struct( ...
    "status", "FAIL", ...
    "dataset", struct(), ...
    "task", struct(), ...
    "validation", struct(), ...
    "capabilities", struct(), ...
    "provenance", struct(), ...
    "file", struct());
end

function value = getOption(options, fieldName, defaultValue)
if isfield(options, fieldName)
    value = options.(fieldName);
else
    value = defaultValue;
end
end
