function alignment = validate_benchmark_alignment(original, bundle, originalFile)
%VALIDATE_BENCHMARK_ALIGNMENT Strictly prove that two inputs are comparable.

arguments
    original (1, 1) struct
    bundle (1, 1) struct
    originalFile (1, 1) string = ""
end

errors = strings(0, 1);
warnings = strings(0, 1);
context = bundle.result.benchmark_context;
task = struct();
if ~isfield(context, "task")
    errors(end + 1, 1) = "benchmark_context.task is missing.";
else
    task = context.task;
end
requiredTask = ["axis", "mode", "known_indices", "target_indices"];
missing = requiredTask(~isfield(task, requiredTask));
if ~isempty(missing)
    errors(end + 1, 1) = "Task fields missing: " + strjoin(missing, ", ");
end
if ~isempty(errors)
    alignment = finishAlignment(errors, warnings, task);
    return;
end
predicted = bundle.cir;
taskAxis = lower(string(task.axis));
if taskAxis == "position"
    taskAxis = "space";
end
for name = ["Tx", "Rx"]
    if original.dimensions.(name) ~= predicted.dimensions.(name)
        errors(end + 1, 1) = sprintf( ...
            "%s mismatch: original=%d, predicted=%d.", name, ...
            original.dimensions.(name), predicted.dimensions.(name)); %#ok<AGROW>
    end
end
if taskAxis ~= "time" && ...
        original.dimensions.Nt ~= predicted.dimensions.Nt
    % On a Time task, Nt is the task axis: the original route has many
    % snapshots while each predicted target carries one snapshot.
    errors(end + 1, 1) = sprintf( ...
        "Nt mismatch: original=%d, predicted=%d.", ...
        original.dimensions.Nt, predicted.dimensions.Nt);
end
if original.domain == "ctf" && ~isempty(fieldnames(bundle.ctf)) && ...
        original.dimensions.Nf ~= bundle.ctf.dimensions.Nf
    errors(end + 1, 1) = sprintf( ...
        "Nf mismatch: original=%d, predicted=%d.", ...
        original.dimensions.Nf, bundle.ctf.dimensions.Nf);
end
for name = ["frequency", "time", "delay", "position", "angle"]
    if isfield(original.units, name) && isfield(predicted.units, name) && ...
            string(original.units.(name)) ~= string(predicted.units.(name))
        errors(end + 1, 1) = sprintf( ...
            "%s unit mismatch: original=%s, predicted=%s.", name, ...
            string(original.units.(name)), string(predicted.units.(name))); %#ok<AGROW>
    end
end
target = double(task.target_indices(:));
known = double(task.known_indices(:));
if isempty(known) || isempty(target)
    errors(end + 1, 1) = "Known and target regions must both be non-empty.";
    alignment = finishAlignment(errors, warnings, task);
    return;
end
axisName = lower(string(task.axis));
if axisName == "position"
    axisName = "space";
end
switch axisName
    case {"time"}
        axisLength = original.dimensions.Nt;
    case {"frequency"}
        axisLength = original.dimensions.Nf;
    otherwise
        axisLength = original.dimensions.N_sample;
end
if any(target < 1 | target > axisLength) || ...
        any(known < 1 | known > axisLength)
    errors(end + 1, 1) = sprintf( ...
        "Known/target indices exceed the original %s-axis length (%d).", ...
        axisName, axisLength);
end
if ~isempty(intersect(known, target))
    errors(end + 1, 1) = "Known and target regions overlap.";
end
if axisName ~= "frequency" && predicted.dimensions.N_sample ~= numel(target)
    errors(end + 1, 1) = sprintf( ...
        "Predicted target count=%d but task declares %d targets.", ...
        predicted.dimensions.N_sample, numel(target));
end
if isfield(bundle.result, "target_parameter_sample_index")
    if ~isequal(double(bundle.result.target_parameter_sample_index(:)), target)
        errors(end + 1, 1) = ...
            "Prediction target order differs from benchmark task target order.";
    end
end
if isfield(task, "axis_values") && ...
        numel(task.axis_values) >= max(target) && ...
        isfield(bundle.result, "target_axis_values")
    expectedAxis = double(task.axis_values(target));
    actualAxis = double(bundle.result.target_axis_values(:));
    if numel(expectedAxis) ~= numel(actualAxis) || ...
            any(abs(expectedAxis(:) - actualAxis(:)) > ...
            max(1, max(abs(expectedAxis(:)))) * 1e-10)
        errors(end + 1, 1) = ...
            "Prediction target-axis coordinates differ from the declared task.";
    end
end
if axisName ~= "frequency" && isfield(predicted.axes, "sample_index") && ...
        ~isequal(double(predicted.axes.sample_index(:)), target)
    errors(end + 1, 1) = ...
        "predicted_cir.h5 sample_index does not match declared target order.";
end
if axisName == "frequency" && ...
        isempty(fieldnames(bundle.ctf))
    errors(end + 1, 1) = ...
        "Frequency-axis benchmark requires a predicted CTF dataset.";
end
if ~ismember(lower(string(task.axis)), ...
        ["sample", "position", "space", "time", "frequency"])
    errors(end + 1, 1) = ...
        "Step 13 v3.0 benchmark requires a sample/position/space/time/frequency task axis.";
end
if isfield(context, "original_dimensions")
    expected = context.original_dimensions;
    for name = ["Tx", "Rx", "Nt", "N_sample"]
        if isfield(expected, name) && ...
                double(expected.(name)) ~= original.dimensions.(name)
            errors(end + 1, 1) = sprintf( ...
                "Original %s differs from the dataset used for prediction.", ...
                name); %#ok<AGROW>
        end
    end
end
if isfield(context, "original_file_sha256")
    if originalFile == ""
        warnings(end + 1, 1) = ...
            "Original-file SHA-256 was recorded but no path was supplied for verification.";
    elseif ~strcmpi(string(context.original_file_sha256), ...
            compute_benchmark_file_sha256(originalFile))
        errors(end + 1, 1) = ...
            "The complete original HDF5 is not the exact file used for prediction.";
    end
else
    warnings(end + 1, 1) = ...
        "Prediction export has no original-file SHA-256 identity.";
end
if ~isfield(context, "target_ground_truth_read_by_prediction") || ...
        logical(context.target_ground_truth_read_by_prediction)
    errors(end + 1, 1) = ...
        "Prediction export does not prove target-ground-truth isolation.";
end
alignment = finishAlignment(errors, warnings, task);
end

function result = finishAlignment(errors, warnings, task)
status = "FAIL";
if isempty(errors), status = "PASS"; end
result = struct( ...
    "schema_version", "v3.0-benchmark-alignment.1", ...
    "status", status, "is_comparable", isempty(errors), ...
    "task_axis", safeField(task, "axis", ""), ...
    "task_mode", safeField(task, "mode", ""), ...
    "known_indices", safeField(task, "known_indices", []), ...
    "target_indices", safeField(task, "target_indices", []), ...
    "errors", errors, "warnings", warnings);
end

function value = safeField(input, name, fallback)
value = fallback;
if isstruct(input) && isfield(input, name), value = input.(name); end
end
