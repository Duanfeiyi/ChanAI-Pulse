% ChanAI Pulse prediction experiment preparation test.
clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));

sequence = [(1:90).', 100 + (1:90).', 200 + 2 * (1:90).'];
experiment = prepare_temporal_prediction_experiment(sequence, ...
    "TrainFraction", 0.70, "ValidationFraction", 0.15, ...
    "WindowLength", 10, "Horizon", 1);

assert(experiment.window_length == 10, "Unexpected effective window length.");
assert(experiment.train.raw_indices(end) == 62, "Unexpected train range.");
assert(experiment.validation.raw_indices(1) == 63, "Validation range is incorrect.");
assert(experiment.test.raw_indices(1) == 76, "Test range is incorrect.");
assert(max(experiment.train.target_indices) <= 62, "Train targets leak forward.");
assert(min(experiment.validation.target_indices) >= 63, "Validation targets leak backward.");
assert(min(experiment.test.target_indices) >= 76, "Test targets leak backward.");

expectedMu = mean(sequence(1:62, :), 1).';
assert(max(abs(experiment.norm_params.Mu - expectedMu)) < 1e-12, ...
    "Normalization must use training snapshots only.");
assert(experiment.training_policy == "real_train_only", "Unexpected initial policy.");

generatedSequence = sequence(1:30, :) + 0.25;
augmented = append_generated_training_windows(experiment, generatedSequence, ...
    "GeneratedSourceId", "synthetic_fixture");
assert(size(augmented.train.inputs, 1) > size(experiment.train.inputs, 1), ...
    "Generated windows were not appended to training.");
assert(isequal(augmented.validation.inputs, experiment.validation.inputs), ...
    "Validation data must remain unchanged.");
assert(isequal(augmented.test.inputs, experiment.test.inputs), ...
    "Test data must remain unchanged.");
assert(augmented.training_policy == "training_only_real_plus_synthetic", ...
    "Generated data policy was not recorded.");

shortExperiment = prepare_temporal_prediction_experiment(sequence(1:50, :), ...
    "WindowLength", 10);
assert(shortExperiment.window_length == 6, ...
    "Short sequences should use a safe common window length.");

fprintf("PASS: temporal prediction experiment preserves hold-out validation and test partitions.\n");
