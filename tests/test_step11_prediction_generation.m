% ChanAI Pulse v3 Step 11 prediction-parameter to CIR tests.

scriptPath = string(mfilename("fullpath"));
repositoryRoot = fileparts(fileparts(scriptPath));
addpath(genpath(fullfile(repositoryRoot, "core")));

prediction = syntheticPrediction();

%% Mock known answer: four targets, deterministic seeds, CIR/CTF, provenance
mockConfig = default_prediction_generation_config("mock");
mockConfig.dimensions = struct( ...
    "Tx", 2, "Rx", 2, "Nf", 16, "Nt", 3, "Npath", 6);
mockConfig.ctf.frequency_hz = linspace(15.95e9, 16.05e9, 16).';
request = create_prediction_generation_request(prediction, mockConfig);
first = run_prediction_generation(request);
second = run_prediction_generation(request);
assert(first.success && second.success);
assert(first.status == "WARNING");
assert(~first.formal_eligible);
assert(isequal(first.prediction_result.cir_dataset.cir.coefficient, ...
    second.prediction_result.cir_dataset.cir.coefficient));
assert(isequal(size5(first.prediction_result.cir_dataset.cir.coefficient), ...
    [2, 2, 6, 3, 4]));
assert(isequal(size5(first.prediction_result.ctf_dataset.ctf.H), ...
    [2, 2, 16, 3, 4]));
assert(first.prediction_result.cir_dataset.metadata.sample_semantics == ...
    "independent");
assert(first.prediction_result.generator_manifest. ...
    combination.all_or_nothing);
assert(~first.prediction_result.generator_manifest. ...
    combination.target_position_injected);
seeds = [first.target_diagnostics.random_seed];
assert(numel(unique(seeds)) == 4);
provenance = first.target_diagnostics(1).parameter_provenance;
assert(provenance([provenance.name] == "DS_mu").source == "predicted");
assert(provenance([provenance.name] == "KF_mu").source == "predicted");
assert(provenance([provenance.name] == "DS_sigma").source == ...
    "versioned_default");
assert(first.prediction_result.analysis.metrics. ...
    doppler_power_spectrum.available);
assert(first.prediction_result.analysis.metrics. ...
    time_autocorrelation.available);
assert(~first.prediction_result.analysis.metrics. ...
    delay_sample_heatmap.available);
assert(first.prediction_result.analysis.registry. ...
    available_standard_plot_count == 9);
assert(isequal(first.prediction_result.analysis.continuity_policy. ...
    blocked_metric_ids, "delay_sample_heatmap"));
frequencyCorrelation = first.prediction_result.analysis.metrics. ...
    frequency_autocorrelation.y;
assert(all(frequencyCorrelation <= 1 + 1e-12));
assert(first.cache_key == second.cache_key);

%% Parameter-source priority: calibrated before scenario/default
priorityConfig = mockConfig;
priorityConfig.parameter_sources.calibrated.DS_sigma = 0.12;
priorityConfig.parameter_sources.calibrated.calibration_version = ...
    "step8-demo";
priorityConfig.parameter_sources.scenario.DS_sigma = 0.21;
priorityRequest = create_prediction_generation_request( ...
    prediction, priorityConfig);
priorityResult = run_prediction_generation(priorityRequest);
priorityProvenance = priorityResult.target_diagnostics(1). ...
    parameter_provenance;
entry = priorityProvenance([priorityProvenance.name] == "DS_sigma");
assert(entry.value == 0.12);
assert(entry.source == "module2_calibrated");
assert(entry.source_version == "step8-demo");

%% Missing or invalid formal parameters fail; predictions remain available
missingConfig = mockConfig;
missingConfig.parameter_sources.versioned_defaults.DS_sigma = NaN;
missingRequest = create_prediction_generation_request( ...
    prediction, missingConfig);
missing = run_prediction_generation(missingRequest);
assert(~missing.success);
assert(isempty(fieldnames(missing.prediction_result)));
assert(isequal(missing.predicted_parameters, ...
    missingRequest.predicted_parameters));
assert(any(contains(missing.errors, "DS_sigma")));

badPrediction = prediction;
badPrediction.prediction_parameters(1, 1, 1) = NaN;
badRequest = create_prediction_generation_request( ...
    badPrediction, mockConfig);
bad = run_prediction_generation(badRequest);
assert(~bad.success);
assert(any(contains(bad.errors, "finite real matrix")));

outOfRangePrediction = prediction;
outOfRangePrediction.prediction_parameters(1, 1, 1) = -20;
outOfRangeRequest = create_prediction_generation_request( ...
    outOfRangePrediction, mockConfig);
outOfRange = run_prediction_generation(outOfRangeRequest);
assert(~outOfRange.success);
assert(any(contains(outOfRange.errors, "outside approved range")));

%% Cancellation is all-or-nothing
cancelled = run_prediction_generation(request, ...
    struct("cancel_check", @() true));
assert(~cancelled.success && cancelled.cancelled);
assert(cancelled.outcome == "CANCELLED");
assert(isempty(fieldnames(cancelled.prediction_result)));

%% Lite integration: deterministic and visibly preview-only
liteConfig = default_prediction_generation_config("lite_6gpcm");
liteConfig.dimensions.Nf = 8;
liteConfig.dimensions.Nt = 1;
liteConfig.ctf.frequency_hz = linspace(15.98e9, 16.02e9, 8).';
liteRequest = create_prediction_generation_request(prediction, liteConfig);
liteFirst = run_prediction_generation(liteRequest);
liteSecond = run_prediction_generation(liteRequest);
assert(liteFirst.success && liteSecond.success);
assert(liteFirst.status == "WARNING");
assert(~liteFirst.formal_eligible);
assert(isequal(liteFirst.prediction_result.cir_dataset.cir.coefficient, ...
    liteSecond.prediction_result.cir_dataset.cir.coefficient));
assert(isequal(size5(liteFirst.prediction_result.ctf_dataset.ctf.H), ...
    [1, 1, 8, 1, 4]));
assert(liteFirst.prediction_result.analysis.registry. ...
    available_standard_plot_count == 3);

%% Full adapter test double: preview succeeds, formal publication is rejected
mockFullRoot = fullfile(repositoryRoot, "tests", "fixtures", ...
    "mock_full_6gpcm");
fullConfig = default_prediction_generation_config("full_6gpcm");
fullConfig.engine_root = mockFullRoot;
fullConfig.engine.id = "full_6gpcm_test_double";
fullConfig.engine.version = "test-only";
fullConfig.engine.source_package_name = "project_owned_test_double";
fullConfig.engine.source_package_sha256 = "";
fullConfig.engine.expected_tree_sha256 = "";
fullConfig.engine.test_only = true;
fullConfig.dimensions.Nf = 5;
fullConfig.ctf.frequency_hz = linspace(15.99e9, 16.01e9, 5).';
fullRequest = create_prediction_generation_request(prediction, fullConfig);
fullPreview = run_prediction_generation(fullRequest);
assert(fullPreview.success);
assert(isequal(size5( ...
    fullPreview.prediction_result.cir_dataset.cir.coefficient), ...
    [2, 2, 240, 2, 4]));
assert(all(~[fullPreview.target_diagnostics.formal_eligible]));
assert(fullPreview.prediction_result.analysis.metrics. ...
    angular_power_spectrum.available);
assert(fullPreview.prediction_result.analysis.metrics. ...
    angular_spread_cdf.available);
assert(fullPreview.prediction_result.analysis.registry. ...
    available_standard_plot_count == 8);

formalConfig = fullConfig;
formalConfig.mode = "formal";
formalRequest = create_prediction_generation_request( ...
    prediction, formalConfig);
formalDouble = run_prediction_generation(formalRequest);
assert(~formalDouble.success);
assert(any(contains(formalDouble.errors, ...
    "not eligible for formal publication")));

unsupportedConfig = fullConfig;
unsupportedConfig.dimensions.Tx = 1;
unsupportedRequest = create_prediction_generation_request( ...
    prediction, unsupportedConfig);
unsupported = run_prediction_generation(unsupportedRequest);
assert(~unsupported.success);
assert(any(contains(unsupported.errors, "fixes Tx=2")));

%% Export writes separate HDF5 data and compact JSON manifests
exportRoot = string(tempname);
mkdir(exportRoot);
cleanup = onCleanup(@() rmdir(exportRoot, "s"));
files = export_prediction_result_bundle( ...
    first.prediction_result, exportRoot);
assert(isfile(files.cir_hdf5));
assert(isfile(files.ctf_hdf5));
assert(isfile(files.result_json));
assert(isfile(files.generator_manifest_json));
assert(isfile(files.prediction_manifest_json));
roundTrip = read_channel_dataset_hdf5(files.cir_hdf5);
assert(isequal(roundTrip.cir.coefficient, ...
    first.prediction_result.cir_dataset.cir.coefficient));
clear cleanup

%% Cache key changes when a defining value changes
changed = request;
changed.master_seed = changed.master_seed + 1;
assert(compute_prediction_generation_cache_key(changed) ~= ...
    requestCacheKey(first));

fprintf("PASS: Step 11 predicted parameters to deterministic CIR/CTF, provenance, strict failures, continuity, and export.\n");

function prediction = syntheticPrediction()
values = zeros(1, 4, 2);
values(1, :, 1) = [-7.90, -7.86, -7.82, -7.78];
values(1, :, 2) = [-0.40, -0.20, 0.00, 0.20];
prediction = struct( ...
    "schema_version", "v3.0-predicted-channel-parameters.1", ...
    "request_contains_target_ground_truth", false, ...
    "task_type", "extrapolation", ...
    "parameter_names", ["DS_mu", "KF_mu"], ...
    "parameter_units", ["log10_s", "dB"], ...
    "prediction_parameters", values, ...
    "target_parameter_sample_index", [17, 18, 19, 20], ...
    "selection", struct( ...
        "mode", "auto", ...
        "selected_model", "tcn", ...
        "selection_basis", "offline_validation_registry"), ...
    "adaptation", struct( ...
        "requested_mode", "off", ...
        "status", "skipped", ...
        "accepted", false), ...
    "model", struct( ...
        "checkpoint", "synthetic-test", ...
        "manifest_schema_version", ...
        "v3.0-predictor-model-manifest.1"));
end

function key = requestCacheKey(serviceResult)
key = serviceResult.cache_key;
end

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end
