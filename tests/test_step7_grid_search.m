% ChanAI Pulse v3 Step 7 deterministic Grid Search tests.

scriptPath = string(mfilename("fullpath"));
repositoryRoot = fileparts(fileparts(scriptPath));
addpath(genpath(fullfile(repositoryRoot, "core")));

%% A true 2x3 Cartesian product has six stable, unique candidates
enumerationConfig = default_grid_search_config("mock");
enumerationConfig.parameter_space = struct( ...
    "DS_mu", [-8.1, -7.9], ...
    "num_clusters", [8, 12, 16]);
[enumerationReport, enumerationConfig] = ...
    validate_grid_search_config(enumerationConfig);
assert(enumerationReport.is_valid);
assert(enumerationReport.total_candidates == 6);
grid = enumerate_parameter_grid(enumerationConfig);
assert(numel(grid) == 6);
assert(isequal(string({grid.id}).', compose("GS-%06d", (1:6).')));
expectedPairs = [ ...
    -8.1, 8; ...
    -8.1, 12; ...
    -8.1, 16; ...
    -7.9, 8; ...
    -7.9, 12; ...
    -7.9, 16];
actualPairs = zeros(6, 2);
for index = 1:6
    actualPairs(index, :) = [grid(index).parameters.DS_mu, ...
        grid(index).parameters.num_clusters];
end
assert(isequal(actualPairs, expectedPairs));

%% Invalid, duplicate, unsupported, or oversized spaces fail early
duplicateConfig = enumerationConfig;
duplicateConfig.parameter_space.DS_mu = [-8, -8];
duplicateReport = validate_grid_search_config(duplicateConfig);
assert(~duplicateReport.is_valid);
assert(any(contains(duplicateReport.errors, "duplicate")));

unknownConfig = enumerationConfig;
unknownConfig.parameter_space.doppler_hz = [10, 20];
unknownReport = validate_grid_search_config(unknownConfig);
assert(~unknownReport.is_valid);
assert(any(contains(unknownReport.errors, "Unsupported")));

emptyConfig = enumerationConfig;
emptyConfig.parameter_space = struct();
emptyReport = validate_grid_search_config(emptyConfig);
assert(~emptyReport.is_valid);

oversizedConfig = enumerationConfig;
oversizedConfig.parameter_space = struct( ...
    "DS_mu", linspace(-9, -7, 23), ...
    "KF_mu", linspace(-2, 2, 23));
oversizedReport = validate_grid_search_config(oversizedConfig);
assert(~oversizedReport.is_valid);
assert(oversizedReport.total_candidates == 529);
assert(any(contains(oversizedReport.errors, "max_candidates")));

integerConfig = enumerationConfig;
integerConfig.parameter_space = struct("num_clusters", [8, 8.5]);
integerReport = validate_grid_search_config(integerConfig);
assert(~integerReport.is_valid);

%% Known mock parameters are recovered with an exact zero score
targetConfig = default_generator_config("mock");
targetConfig.dimensions.Tx = 1;
targetConfig.dimensions.Rx = 1;
targetConfig.dimensions.Npath = 10;
targetConfig.dimensions.Nt = 2;
targetConfig.dimensions.N_sample = 6;
targetGeneration = run_generator_adapter(targetConfig);
assert(targetGeneration.success);

searchConfig = default_grid_search_config("mock");
searchConfig.generator_config = targetConfig;
searchConfig.generator_config.engine_root = ...
    "C:\private\must-not-enter-manifest";
searchConfig.parameter_space = struct( ...
    "DS_mu", [targetConfig.model.DS_mu - 0.1, ...
        targetConfig.model.DS_mu], ...
    "KF_mu", [targetConfig.model.KF_mu, ...
        targetConfig.model.KF_mu + 0.6], ...
    "num_clusters", [targetConfig.model.num_clusters - 3, ...
        targetConfig.model.num_clusters]);
searchConfig.limits.retain_top_k = 5;
first = run_grid_search(targetGeneration.dataset, searchConfig);
second = run_grid_search(targetGeneration.dataset, searchConfig);
assert(first.success && first.complete);
assert(first.outcome == "SUCCEEDED");
assert(first.total_candidates == 8);
assert(first.completed_candidates == 8);
assert(first.succeeded_candidates == 8);
assert(first.failed_candidates == 0);
assert(first.best.parameters.DS_mu == targetConfig.model.DS_mu);
assert(first.best.parameters.KF_mu == targetConfig.model.KF_mu);
assert(first.best.parameters.num_clusters == ...
    targetConfig.model.num_clusters);
assert(first.best.total_score < 1e-12);
assert(~first.best.provisional);
assert(numel(first.retained_candidates) == 5);
assert(numel(first.ranking) == 8);
assert(isequal([first.ranking.total_score], ...
    [second.ranking.total_score]));
assert(isequal(string({first.ranking.id}), ...
    string({second.ranking.id})));
assert(first.config.generator_config.engine_root == "");
assert(first.manifest.config.generator_config.engine_root == "");
assert(~contains(string(jsonencode(first.manifest)), ...
    "must-not-enter-manifest"));
assert(~first.formal_eligible, ...
    "Mock test-only searches must never be formal eligible.");

%% Target-region mutation cannot leak into known-region fitting
task = create_channel_task("interpolation", "sample", ...
    [1, 2, 5, 6], [3, 4]);
knownConfig = searchConfig;
knownConfig.target.task = task;
knownConfig.parameter_space = struct( ...
    "DS_mu", [targetConfig.model.DS_mu - 0.1, ...
        targetConfig.model.DS_mu], ...
    "KF_mu", [targetConfig.model.KF_mu, ...
        targetConfig.model.KF_mu + 0.6]);
baselineKnown = run_grid_search( ...
    targetGeneration.dataset, knownConfig);
mutatedDataset = targetGeneration.dataset;
mutatedDataset.cir.coefficient(:, :, :, :, 3:4) = ...
    mutatedDataset.cir.coefficient(:, :, :, :, 3:4) * 1e6;
mutatedDataset.cir.delay_s(:, :, :, :, 3:4) = ...
    mutatedDataset.cir.delay_s(:, :, :, :, 3:4) + 1e-3;
mutatedKnown = run_grid_search(mutatedDataset, knownConfig);
assert(baselineKnown.success && mutatedKnown.success);
assert(isequal([baselineKnown.ranking.total_score], ...
    [mutatedKnown.ranking.total_score]));
assert(baselineKnown.best.id == mutatedKnown.best.id);

%% One failed candidate is recorded while the valid candidate still wins
failureConfig = searchConfig;
failureConfig.parameter_space = struct( ...
    "DS_mu", [targetConfig.model.DS_mu, 400]);
failureConfig.limits.retain_top_k = 2;
partialFailure = run_grid_search( ...
    targetGeneration.dataset, failureConfig);
assert(partialFailure.success && partialFailure.complete);
assert(partialFailure.succeeded_candidates == 1);
assert(partialFailure.failed_candidates == 1);
assert(partialFailure.status == "WARNING");
assert(partialFailure.best.parameters.DS_mu == ...
    targetConfig.model.DS_mu);
assert(any(~[partialFailure.ranking.success]));

%% Cancellation never produces a formal or completed best result
cancelled = run_grid_search(targetGeneration.dataset, ...
    searchConfig, struct("cancel_check", @() true));
assert(~cancelled.success);
assert(cancelled.cancelled);
assert(cancelled.outcome == "CANCELLED");
assert(~cancelled.complete);
assert(~cancelled.formal_eligible);
assert(cancelled.completed_candidates == 0);

fprintf("PASS: Step 7 deterministic Cartesian Grid Search and safeguards.\n");
