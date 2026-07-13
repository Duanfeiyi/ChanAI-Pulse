% ChanAI Pulse experiment split test using synthetic in-memory sequences.
clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));

sequence = [(1:60).', (1001:1060).'];
split = create_chronological_train_val_test_split(sequence, ...
    "TrainFraction", 0.70, "ValidationFraction", 0.15, ...
    "WindowLength", 3, "Horizon", 1);

assert(isequal(split.train.raw_indices, (1:42).'), "Unexpected train raw range.");
assert(isequal(split.validation.raw_indices, (43:51).'), "Unexpected validation raw range.");
assert(isequal(split.test.raw_indices, (52:60).'), "Unexpected test raw range.");
assert(max(split.train.target_indices) <= 42, "Train targets crossed into validation data.");
assert(min(split.validation.target_indices) >= 43 && max(split.validation.target_indices) <= 51, ...
    "Validation windows crossed a split boundary.");
assert(min(split.test.target_indices) >= 52, "Test windows crossed a split boundary.");
assert(split.train.provenance.source_type == "real_train", "Train provenance is incorrect.");
assert(split.validation.provenance.source_type == "real_validation", "Validation provenance is incorrect.");
assert(split.test.provenance.source_type == "real_test", "Test provenance is incorrect.");

generatedTrain = struct();
generatedTrain.inputs = split.train.inputs(1:2, :, :) + 0.1;
generatedTrain.targets = split.train.targets(1:2, :) + 0.1;
merged = merge_training_sources(split.train, generatedTrain, ...
    "GeneratedSourceId", "synthetic_test_fixture");
assert(size(merged.inputs, 1) == size(split.train.inputs, 1) + 2, "Generated samples were not appended.");
assert(merged.provenance(1).source_type == "real_train", "Real provenance was not retained.");
assert(merged.provenance(2).source_type == "synthetic_generated", "Generated provenance was not recorded.");
assert(merged.policy == "training_only_real_plus_synthetic", "Training-only policy was not recorded.");

fprintf("PASS: chronological train/validation/test split prevents window leakage.\n");
