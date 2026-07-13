function experiment = append_generated_training_windows(experiment, generatedSequence, options)
%APPEND_GENERATED_TRAINING_WINDOWS Add synthetic windows to training only.
%   Validation and test partitions in EXPERIMENT are deliberately unchanged.

arguments
    experiment (1, 1) struct
    generatedSequence {mustBeNumeric, mustBeNonempty}
    options.GeneratedSourceId (1, 1) string = "generated_in_app"
    options.GeneratedSourceType (1, 1) string = "synthetic_generated"
end

requiredFields = ["train", "norm_params", "window_length", "horizon"];
for requiredField = requiredFields
    if ~isfield(experiment, requiredField)
        error("append_generated_training_windows:InvalidExperiment", ...
            "Experiment is missing required temporal split fields.");
    end
end
if ndims(generatedSequence) ~= 2
    error("append_generated_training_windows:InvalidDimensions", ...
        "Generated sequence must be a [snapshot, feature] matrix.");
end

generatedSequence = double(generatedSequence);
featureCount = numel(experiment.norm_params.Mu);
if size(generatedSequence, 2) ~= featureCount
    error("append_generated_training_windows:FeatureMismatch", ...
        "Generated data has %d features; real training data has %d.", ...
        size(generatedSequence, 2), featureCount);
end

mu = experiment.norm_params.Mu.';
sigma = experiment.norm_params.Sigma.';
normalizedSequence = (generatedSequence - mu) ./ sigma;
[inputs, targets] = build_sliding_windows(normalizedSequence, ...
    experiment.window_length, experiment.horizon);

generatedTrain = struct("inputs", inputs, "targets", targets);
merged = merge_training_sources(experiment.train, generatedTrain, ...
    "GeneratedSourceId", options.GeneratedSourceId, ...
    "GeneratedSourceType", options.GeneratedSourceType);

experiment.train.inputs = merged.inputs;
experiment.train.targets = merged.targets;
experiment.train.provenance = merged.provenance;
experiment.train.input_cells = tensorToCells(merged.inputs);
experiment.training_policy = merged.policy;
experiment.generated_training = struct( ...
    "source_id", options.GeneratedSourceId, ...
    "source_type", options.GeneratedSourceType, ...
    "sample_count", size(inputs, 1));
end

function cells = tensorToCells(inputs)
sampleCount = size(inputs, 1);
featureCount = size(inputs, 2);
windowLength = size(inputs, 3);
cells = cell(sampleCount, 1);
for sampleIdx = 1:sampleCount
    cells{sampleIdx} = reshape(inputs(sampleIdx, :, :), featureCount, windowLength);
end
end
