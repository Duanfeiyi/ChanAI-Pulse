% ChanAI Pulse v3 Step 9 predictor-data contract tests.

scriptPath = string(mfilename("fullpath"));
repositoryRoot = fileparts(fileparts(scriptPath));
addpath(genpath(fullfile(repositoryRoot, "core")));

%% Deterministic parameter truth with ten independent route groups
config = default_predictor_data_config();
assert(validate_predictor_data_config(config).is_valid);
invalidConfig = config;
invalidConfig.split.fractions = [0.8, 0.3, 0.1];
assert(~validate_predictor_data_config(invalidConfig).is_valid);
groupCount = 10;
rowsPerGroup = 28;
rowCount = groupCount * rowsPerGroup;
index = (1:rowCount).';
groupId = strings(rowCount, 1);
sampleIndex = zeros(rowCount, 1);
values = zeros(rowCount, 2);
for group = 1:groupCount
    rows = (group - 1) * rowsPerGroup + (1:rowsPerGroup);
    local = (1:rowsPerGroup).';
    groupId(rows) = "route-" + compose("%02d", group);
    sampleIndex(rows) = local;
    values(rows, 1) = -8.05 + 0.002 * local + 0.01 * group;
    values(rows, 2) = -1.0 + 0.04 * local + 0.05 * group;
end
options = struct( ...
    "group_id", groupId, ...
    "parameter_sample_index", sampleIndex, ...
    "raw_window_start", index, ...
    "raw_window_end", index + 15, ...
    "raw_window_center", index + 7.5, ...
    "bounds", [-9, -7; -10, 20], ...
    "provenance", struct("fixture", "step9-deterministic"));
sequence = build_generator_truth_parameter_sequence( ...
    values, ["DS_mu", "KF_mu"], options);
report = validate_parameter_sequence(sequence);
assert(report.is_valid);
assert(isequal(size(sequence.values), [280, 2]));
assert(isequal(sequence.parameter_units, ["log10_s", "dB"]));

%% The same contract accepts the full Step 8 eight-parameter profile
allNames = config.supported_parameter_names;
generatorDefaults = default_generator_config("mock");
model = generatorDefaults.model;
allValues = zeros(3, numel(allNames));
for parameterIndex = 1:numel(allNames)
    allValues(:, parameterIndex) = model.(allNames(parameterIndex));
end
allSequence = build_generator_truth_parameter_sequence( ...
    allValues, allNames);
assert(validate_parameter_sequence(allSequence).is_valid);
assert(isequal(allSequence.parameter_bounds(4, :), [1, Inf]));

%% Frozen extrapolation layout: 16 known -> next 4
extrapolation = build_predictor_dataset( ...
    sequence, "extrapolation", config);
assert(extrapolation.summary.N_context == 16);
assert(extrapolation.summary.N_target == 4);
assert(extrapolation.summary.P == 2);
assert(extrapolation.summary.N_example == 90);
assert(isequal(extrapolation.input_parameter_sample_index(1, :), 1:16));
assert(isequal(extrapolation.target_parameter_sample_index(1, :), 17:20));
assert(isequal(size(extrapolation.inputs), [90, 16, 2]));
assert(isequal(size(extrapolation.targets), [90, 4, 2]));
assert(validate_predictor_dataset(extrapolation).is_valid);

%% Frozen interpolation layout: left 8 + right 8 -> missing middle 4
interpolation = build_predictor_dataset( ...
    sequence, "interpolation", config);
assert(interpolation.summary.N_context == 16);
assert(interpolation.summary.N_target == 4);
assert(isequal(interpolation.input_parameter_sample_index(1, :), ...
    [1:8, 13:20]));
assert(isequal(interpolation.target_parameter_sample_index(1, :), 9:12));
assert(interpolation.context_layout == ...
    "left_and_right_context_predict_middle");

%% Group split is 7/1/2 and cannot leak adjacent route samples
split = split_predictor_dataset_by_group(extrapolation, config);
assert(split.leakage_check.passed);
assert(numel(split.train_group_id) == 7);
assert(isscalar(split.validation_group_id));
assert(numel(split.test_group_id) == 2);
assert(all(split.example_partition_code > 0));

%% Z-score is fitted only on training groups
manifest = fit_parameter_normalization( ...
    sequence, split.train_group_id, config);
changed = sequence;
heldOut = ~ismember(changed.group_id, split.train_group_id);
changed.values(heldOut, :) = changed.values(heldOut, :) + [0.5, 5];
manifestAfterHeldOutChange = fit_parameter_normalization( ...
    changed, split.train_group_id, config);
assert(max(abs(manifest.mean - ...
    manifestAfterHeldOutChange.mean)) < 1e-12);
assert(max(abs(manifest.standard_deviation - ...
    manifestAfterHeldOutChange.standard_deviation)) < 1e-12);
normalized = normalize_predictor_dataset( ...
    extrapolation, sequence, split, config);
restored = denormalize_predictor_parameters( ...
    normalized.inputs, normalized.normalization);
assert(max(abs(restored(:) - extrapolation.inputs(:))) < 1e-12);
projected = denormalize_predictor_parameters( ...
    reshape([1e6, -1e6], [1, 1, 2]), normalized.normalization);
assert(projected(1, 1, 1) == -7);
assert(projected(1, 1, 2) == -10);

countSequence = build_generator_truth_parameter_sequence( ...
    [10; 11], "num_clusters", struct("group_id", "count-group"));
countManifest = fit_parameter_normalization( ...
    countSequence, "count-group", config);
roundedCount = denormalize_predictor_parameters(0.49, countManifest);
assert(roundedCount == round(roundedCount));

%% Failed fitted labels are never converted into model examples
failed = sequence;
failed.values(10, :) = NaN;
failed.quality_status(10) = "FAIL";
failedDataset = build_predictor_dataset(failed, "extrapolation", config);
assert(failedDataset.summary.N_example < extrapolation.summary.N_example);
assert(all(isfinite(failedDataset.inputs(:))));

%% A one-parameter profile preserves the declared trailing P dimension
singleOptions = options;
singleOptions.bounds = options.bounds(1, :);
singleSequence = build_generator_truth_parameter_sequence( ...
    values(:, 1), "DS_mu", singleOptions);
singleDataset = build_predictor_dataset( ...
    singleSequence, "extrapolation", config);
singleSplit = split_predictor_dataset_by_group(singleDataset, config);
singleNormalized = normalize_predictor_dataset( ...
    singleDataset, singleSequence, singleSplit, config);
assert(singleDataset.summary.P == 1);
assert(isequal(size(singleNormalized.inputs), [90, 16]));
singleRestored = denormalize_predictor_parameters( ...
    singleNormalized.inputs, singleNormalized.normalization);
assert(max(abs(singleRestored(:) - singleDataset.inputs(:))) < 1e-12);

%% Local channel windows become auditable Grid/SA fitted labels
generatorConfig = default_generator_config("mock");
generatorConfig.dimensions.Tx = 1;
generatorConfig.dimensions.Rx = 1;
generatorConfig.dimensions.Npath = 8;
generatorConfig.dimensions.Nt = 2;
generatorConfig.dimensions.N_sample = 6;
generated = run_generator_adapter(generatorConfig);
assert(generated.success);
fitConfig = default_optimization_config("mock");
fitConfig.generator_config = generatorConfig;
fitConfig.generator_config.dimensions.N_sample = 3;
fitConfig.variables = struct( ...
    "DS_mu", struct("type", "discrete", ...
        "values", generatorConfig.model.DS_mu, ...
        "initial", generatorConfig.model.DS_mu, ...
        "step_fraction", 0.1), ...
    "KF_mu", struct("type", "discrete", ...
        "values", generatorConfig.model.KF_mu, ...
        "initial", generatorConfig.model.KF_mu, ...
        "step_fraction", 0.1));
[fittedSequence, fittedDetails] = build_fitted_parameter_sequence( ...
    generated.dataset, fitConfig, struct( ...
        "window_length", 3, "stride", 3, ...
        "group_id", "fitted-route"));
assert(fittedDetails.success_count == 2);
assert(all(fittedSequence.label_source == "grid_fitted"));
assert(all(isfinite(fittedSequence.fit_score)));

%% Portable MATLAB HDF5 round trip
temporaryFile = string(tempname) + ".h5";
cleanupFile = onCleanup(@() deleteIfExists(temporaryFile));
bundle = struct( ...
    "parameter_sequence", sequence, ...
    "dataset", normalized, ...
    "split", split);
write_predictor_data_hdf5(temporaryFile, bundle);
loaded = read_predictor_data_hdf5(temporaryFile);
assert(loaded.schema_version == "v3.0-predictor-data-hdf5.1");
assert(isequal(loaded.parameter_sequence.values, sequence.values));
assert(isequal(size(loaded.dataset.inputs), [90, 16, 2]));
assert(max(abs(loaded.dataset.inputs(:) - ...
    normalized.inputs(:))) < 1e-12);
assert(isequal(loaded.split.example_partition_code, ...
    split.example_partition_code));

%% Scalar JSON strings survive a one-example, one-group HDF5 round trip
soloOptions = struct( ...
    "group_id", "solo-route", ...
    "parameter_sample_index", (1:20).', ...
    "bounds", [-9, -7; -10, 20]);
soloSequence = build_generator_truth_parameter_sequence( ...
    values(1:20, :), ["DS_mu", "KF_mu"], soloOptions);
soloDataset = build_predictor_dataset( ...
    soloSequence, "extrapolation", config);
soloSplit = split_predictor_dataset_by_group(soloDataset, config);
soloDataset = normalize_predictor_dataset( ...
    soloDataset, soloSequence, soloSplit, config);
soloFile = string(tempname) + ".h5";
soloCleanup = onCleanup(@() deleteIfExists(soloFile));
write_predictor_data_hdf5(soloFile, struct( ...
    "parameter_sequence", soloSequence, ...
    "dataset", soloDataset, ...
    "split", soloSplit));
soloLoaded = read_predictor_data_hdf5(soloFile);
assert(isscalar(soloLoaded.dataset.example_group_id));
assert(soloLoaded.dataset.example_group_id == "solo-route");
assert(isscalar(soloLoaded.split.train_group_id));
assert(soloLoaded.split.train_group_id == "solo-route");
clear soloCleanup

fixturePath = getenv("CHAI_STEP9_TEST_FIXTURE");
if strlength(fixturePath) > 0
    copyfile(temporaryFile, fixturePath);
end

fprintf("PASS: Step 9 parameter sequence, tasks, split, normalization, and HDF5.\n");
clear cleanupFile

function deleteIfExists(filePath)
if isfile(filePath)
    delete(filePath);
end
end
