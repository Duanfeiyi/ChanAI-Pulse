function report = validate_predictor_dataset(dataset)
%VALIDATE_PREDICTOR_DATASET Validate canonical input/target tensors.

errors = strings(0, 1);
warnings = strings(0, 1);
required = ["schema_version", "task_type", ...
    "input_dimension_order", "target_dimension_order", ...
    "inputs", "targets", "input_parameter_sample_index", ...
    "target_parameter_sample_index", "parameter_names", ...
    "parameter_units", "parameter_bounds", "example_group_id", ...
    "example_label_source", "summary"];
for name = required
    if ~isfield(dataset, name)
        errors(end + 1, 1) = "Missing dataset field: " + name; %#ok<AGROW>
    end
end
if ~isempty(errors)
    report = finishReport(errors, warnings);
    return;
end
if string(dataset.schema_version) ~= "v3.0-predictor-dataset.1"
    errors(end + 1, 1) = "Unsupported predictor dataset schema.";
end
if ~ismember(string(dataset.task_type), ...
        ["interpolation", "extrapolation"])
    errors(end + 1, 1) = "Unsupported predictor task_type.";
end
if ~isequal(string(dataset.input_dimension_order(:)).', ...
        ["N_example", "N_context", "P"]) || ...
        ~isequal(string(dataset.target_dimension_order(:)).', ...
        ["N_example", "N_target", "P"])
    errors(end + 1, 1) = "Predictor tensor dimension order is invalid.";
end
expectedInput = [dataset.summary.N_example, ...
    dataset.summary.N_context, dataset.summary.P];
expectedTarget = [dataset.summary.N_example, ...
    dataset.summary.N_target, dataset.summary.P];
if ~isequal(size3(dataset.inputs), expectedInput)
    errors(end + 1, 1) = "Input tensor shape does not match summary.";
end
if ~isequal(size3(dataset.targets), expectedTarget)
    errors(end + 1, 1) = "Target tensor shape does not match summary.";
end
if ~isequal(size(dataset.input_parameter_sample_index), ...
        expectedInput(1:2)) || ...
        ~isequal(size(dataset.target_parameter_sample_index), ...
        expectedTarget(1:2))
    errors(end + 1, 1) = "Predictor index matrices do not match tensor lengths.";
end
if numel(dataset.parameter_names) ~= expectedInput(3) || ...
        numel(dataset.parameter_units) ~= expectedInput(3) || ...
        ~isequal(size(dataset.parameter_bounds), [expectedInput(3), 2])
    errors(end + 1, 1) = "Parameter metadata does not match P.";
end
if numel(dataset.example_group_id) ~= expectedInput(1) || ...
        numel(dataset.example_label_source) ~= expectedInput(1)
    errors(end + 1, 1) = "Example metadata must have one row per example.";
end
if any(~isfinite(dataset.inputs(:))) || ...
        any(~isfinite(dataset.targets(:)))
    errors(end + 1, 1) = "Predictor tensors must contain finite values.";
end
for example = 1:expectedInput(1)
    if ~isempty(intersect( ...
            dataset.input_parameter_sample_index(example, :), ...
            dataset.target_parameter_sample_index(example, :)))
        errors(end + 1, 1) = ...
            "Input and target indices must not overlap."; %#ok<AGROW>
        break;
    end
end
if expectedInput(1) == 0
    warnings(end + 1, 1) = "Dataset contains no complete examples.";
end
report = finishReport(errors, warnings);
end

function shape = size3(value)
shape = [size(value, 1), size(value, 2), size(value, 3)];
end

function report = finishReport(errors, warnings)
if ~isempty(errors)
    status = "FAIL";
elseif ~isempty(warnings)
    status = "WARNING";
else
    status = "PASS";
end
report = struct( ...
    "status", status, ...
    "is_valid", isempty(errors), ...
    "errors", errors, ...
    "warnings", warnings);
end
