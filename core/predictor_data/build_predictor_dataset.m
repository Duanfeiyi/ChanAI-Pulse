function dataset = build_predictor_dataset(sequence, taskType, config)
%BUILD_PREDICTOR_DATASET Build interpolation or extrapolation tensors.
%   Canonical tensors use [N_example, N_context, P] for inputs and
%   [N_example, N_target, P] for targets.

arguments
    sequence (1, 1) struct
    taskType (1, 1) string {mustBeMember(taskType, ...
        ["interpolation", "extrapolation"])}
    config (1, 1) struct = default_predictor_data_config()
end

report = validate_parameter_sequence(sequence);
if ~report.is_valid
    error("build_predictor_dataset:InvalidSequence", ...
        "%s", strjoin(report.errors, " | "));
end
configReport = validate_predictor_data_config(config);
if ~configReport.is_valid
    error("build_predictor_dataset:InvalidConfig", ...
        "%s", strjoin(configReport.errors, " | "));
end

if taskType == "extrapolation"
    leftLength = config.extrapolation.context_length;
    rightLength = 0;
    targetLength = config.extrapolation.target_length;
    contextLength = leftLength;
    layout = "history_then_future";
else
    leftLength = config.interpolation.left_context_length;
    rightLength = config.interpolation.right_context_length;
    targetLength = config.interpolation.target_length;
    contextLength = leftLength + rightLength;
    layout = "left_and_right_context_predict_middle";
end
spanLength = contextLength + targetLength;
parameterCount = size(sequence.values, 2);
sampleCount = size(sequence.values, 1);

inputCells = cell(0, 1);
targetCells = cell(0, 1);
inputIndexCells = cell(0, 1);
targetIndexCells = cell(0, 1);
exampleGroups = strings(0, 1);
exampleSources = strings(0, 1);
skippedInvalid = 0;
skippedBoundary = 0;

for startIndex = 1:max(0, sampleCount - spanLength + 1)
    span = startIndex:(startIndex + spanLength - 1);
    groups = string(sequence.group_id(span));
    if numel(unique(groups)) ~= 1
        skippedBoundary = skippedBoundary + 1;
        continue;
    end
    quality = upper(string(sequence.quality_status(span)));
    if any(quality == "FAIL") || ...
            any(any(~isfinite(sequence.values(span, :))))
        skippedInvalid = skippedInvalid + 1;
        continue;
    end
    sampleIndices = double(sequence.parameter_sample_index(span));
    if any(diff(sampleIndices) ~= 1)
        skippedBoundary = skippedBoundary + 1;
        continue;
    end

    if taskType == "extrapolation"
        inputRows = span(1:contextLength);
        targetRows = span(contextLength + (1:targetLength));
    else
        leftRows = span(1:leftLength);
        targetRows = span(leftLength + (1:targetLength));
        rightRows = span(leftLength + targetLength + (1:rightLength));
        inputRows = [leftRows, rightRows];
    end
    inputCells{end + 1, 1} = sequence.values(inputRows, :); %#ok<AGROW>
    targetCells{end + 1, 1} = sequence.values(targetRows, :); %#ok<AGROW>
    inputIndexCells{end + 1, 1} = ...
        double(sequence.parameter_sample_index(inputRows)).'; %#ok<AGROW>
    targetIndexCells{end + 1, 1} = ...
        double(sequence.parameter_sample_index(targetRows)).'; %#ok<AGROW>
    exampleGroups(end + 1, 1) = groups(1); %#ok<AGROW>
    sources = unique(string(sequence.label_source(span)), "stable");
    exampleSources(end + 1, 1) = strjoin(sources, "+"); %#ok<AGROW>
end

exampleCount = numel(inputCells);
inputs = nan(exampleCount, contextLength, parameterCount);
targets = nan(exampleCount, targetLength, parameterCount);
inputIndices = nan(exampleCount, contextLength);
targetIndices = nan(exampleCount, targetLength);
for index = 1:exampleCount
    inputs(index, :, :) = reshape(inputCells{index}, ...
        [1, contextLength, parameterCount]);
    targets(index, :, :) = reshape(targetCells{index}, ...
        [1, targetLength, parameterCount]);
    inputIndices(index, :) = inputIndexCells{index};
    targetIndices(index, :) = targetIndexCells{index};
end

status = "PASS";
warnings = strings(0, 1);
if exampleCount == 0
    status = "WARNING";
    warnings(end + 1, 1) = ...
        "No complete examples can be built from this sequence.";
end
if skippedInvalid > 0
    status = "WARNING";
    warnings(end + 1, 1) = string(skippedInvalid) + ...
        " candidate spans were skipped because labels failed.";
end
dataset = struct( ...
    "schema_version", "v3.0-predictor-dataset.1", ...
    "task_type", taskType, ...
    "input_dimension_order", ["N_example", "N_context", "P"], ...
    "target_dimension_order", ["N_example", "N_target", "P"], ...
    "context_layout", layout, ...
    "inputs", inputs, ...
    "targets", targets, ...
    "input_parameter_sample_index", inputIndices, ...
    "target_parameter_sample_index", targetIndices, ...
    "parameter_names", sequence.parameter_names, ...
    "parameter_units", sequence.parameter_units, ...
    "parameter_bounds", sequence.parameter_bounds, ...
    "example_group_id", exampleGroups, ...
    "example_label_source", exampleSources, ...
    "normalization", struct(), ...
    "fine_tuning", buildFineTuningMetadata(sequence), ...
    "status", status, ...
    "warnings", warnings, ...
    "summary", struct( ...
        "N_example", exampleCount, ...
        "N_context", contextLength, ...
        "N_target", targetLength, ...
        "P", parameterCount, ...
        "candidate_span_length", spanLength, ...
        "skipped_invalid_spans", skippedInvalid, ...
        "skipped_group_or_index_boundaries", skippedBoundary), ...
    "provenance", struct( ...
        "parameter_sequence_schema", sequence.schema_version, ...
        "parameter_sequence_provenance", sequence.provenance));
datasetReport = validate_predictor_dataset(dataset);
if ~datasetReport.is_valid
    error("build_predictor_dataset:InvalidResult", ...
        "%s", strjoin(datasetReport.errors, " | "));
end
end

function metadata = buildFineTuningMetadata(sequence)
validRows = upper(string(sequence.quality_status)) ~= "FAIL";
sources = unique(string(sequence.label_source(validRows)), "stable");
hasTruth = any(sources == "generator_truth");
hasFitted = any(ismember(sources, ["grid_fitted", "sa_fitted"]));
metadata = struct( ...
    "schema_version", "v3.0-fine-tuning-eligibility.1", ...
    "supported_modes", ["pretrain", "auto", "off", "force"], ...
    "default_mode", "auto", ...
    "contains_generator_truth", hasTruth, ...
    "contains_fitted_labels", hasFitted, ...
    "pretraining_eligible", hasTruth, ...
    "fine_tuning_candidate", hasFitted, ...
    "automatic_threshold_defined", false, ...
    "decision_note", ...
        "Step 9 records eligibility only; Step 10 defines experimental thresholds.");
end
