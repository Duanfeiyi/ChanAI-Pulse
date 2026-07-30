% ChanAI Pulse v3 Step 8 optimizer, SA, and auto-selection tests.

scriptPath = string(mfilename("fullpath"));
repositoryRoot = fileparts(fileparts(scriptPath));
addpath(genpath(fullfile(repositoryRoot, "core")));

%% Unified config and automatic selection are explicit and deterministic
config = default_optimization_config("mock");
[report, config] = validate_optimization_config(config);
assert(report.is_valid);
assert(report.selection.selected_strategy == "grid");
assert(report.selection.reason_code == "AUTO_SMALL_DISCRETE_GRID");
assert(report.selection.grid_candidate_count == 27);

continuous = config;
continuous.variables = struct("DS_mu", struct( ...
    "type", "continuous", "lower", -8.1, "upper", -7.7, ...
    "initial", -7.9, "step_fraction", 0.1));
[continuousReport, continuous] = ...
    validate_optimization_config(continuous);
assert(continuousReport.is_valid);
assert(continuousReport.selection.selected_strategy == "sa");
assert(continuousReport.selection.reason_code == ...
    "AUTO_CONTINUOUS_OR_INTEGER_SA");

manualInvalid = continuous;
manualInvalid.requested_strategy = "grid";
manualInvalidReport = validate_optimization_config(manualInvalid);
assert(~manualInvalidReport.is_valid);
assert(any(contains(manualInvalidReport.errors, ...
    "requires every variable")));

continuousCount = continuous;
continuousCount.variables = struct("num_clusters", struct( ...
    "type", "continuous", "lower", 6, "upper", 20, ...
    "initial", 12, "step_fraction", 0.1));
continuousCountReport = validate_optimization_config(continuousCount);
assert(~continuousCountReport.is_valid);
assert(any(contains(continuousCountReport.errors, ...
    "represents a count")));

largeGrid = default_optimization_config("mock");
largeGrid.requested_strategy = "grid";
largeGrid.variables = struct("DS_mu", struct( ...
    "type", "discrete", "values", linspace(-9, -7, 501), ...
    "initial", -8, "step_fraction", 0.1));
largeGridReport = validate_optimization_config(largeGrid);
assert(~largeGridReport.is_valid);
assert(any(contains(largeGridReport.errors, ...
    "max_grid_candidates")));

projected = continuous;
projected.variables.DS_mu.initial = -100;
[projectedReport, projected] = validate_optimization_config(projected);
assert(projectedReport.is_valid);
assert(projected.variables.DS_mu.initial == ...
    projected.variables.DS_mu.lower);

fullAuto = default_optimization_config("full_6gpcm");
[fullAutoReport, ~] = validate_optimization_config(fullAuto);
assert(fullAutoReport.is_valid);
assert(fullAutoReport.selection.selected_strategy == "sa");
assert(fullAutoReport.selection.reason_code == ...
    "AUTO_GRID_TOO_LARGE_SA");

%% Standard Metropolis rule is independently inspectable
assert(metropolis_acceptance_probability(-0.1, 0.1) == 1);
assert(metropolis_acceptance_probability(0, 0.1) == 1);
assert(abs(metropolis_acceptance_probability(0.1, 0.1) - exp(-1)) ...
    < 1e-15);

%% Build a small deterministic target
targetConfig = default_generator_config("mock");
targetConfig.dimensions.Tx = 1;
targetConfig.dimensions.Rx = 1;
targetConfig.dimensions.Npath = 10;
targetConfig.dimensions.Nt = 2;
targetConfig.dimensions.N_sample = 5;
targetGeneration = run_generator_adapter(targetConfig);
assert(targetGeneration.success);

%% Unified auto entry chooses Grid and recovers the exact known parameters
autoConfig = default_optimization_config("mock");
autoConfig.generator_config = targetConfig;
autoConfig.variables = struct( ...
    "DS_mu", struct( ...
        "type", "discrete", ...
        "values", [targetConfig.model.DS_mu - 0.1, ...
            targetConfig.model.DS_mu], ...
        "initial", targetConfig.model.DS_mu - 0.1, ...
        "step_fraction", 1), ...
    "KF_mu", struct( ...
        "type", "discrete", ...
        "values", [targetConfig.model.KF_mu, ...
            targetConfig.model.KF_mu + 0.5], ...
        "initial", targetConfig.model.KF_mu + 0.5, ...
        "step_fraction", 1));
autoResult = run_parameter_optimization( ...
    targetGeneration.dataset, autoConfig);
assert(autoResult.success && autoResult.complete);
assert(autoResult.selected_strategy == "grid");
assert(autoResult.best.parameters.DS_mu == targetConfig.model.DS_mu);
assert(autoResult.best.parameters.KF_mu == targetConfig.model.KF_mu);
assert(autoResult.best.total_score < 1e-12);

%% SA and Random Greedy use the same proposals and evaluator
saConfig = autoConfig;
saConfig.requested_strategy = "sa";
saConfig.variables = struct("DS_mu", struct( ...
    "type", "discrete", ...
    "values", [targetConfig.model.DS_mu, ...
        targetConfig.model.DS_mu + 0.12], ...
    "initial", targetConfig.model.DS_mu + 0.12, ...
    "step_fraction", 1));
saConfig.limits.max_evaluations = 8;
saConfig.limits.retain_top_k = 2;
saConfig.sa.no_improvement_limit = 15;
saConfig.sa.proposals_per_temperature = 4;
saConfig.sa.optimizer_seed = 8103;
saResult = run_simulated_annealing( ...
    targetGeneration.dataset, saConfig);
greedyResult = run_random_greedy_search( ...
    targetGeneration.dataset, saConfig);
assert(saResult.success && saResult.complete);
assert(greedyResult.success && greedyResult.complete);
assert(saResult.best.parameters.DS_mu == targetConfig.model.DS_mu);
assert(saResult.best.total_score < 1e-12);
assert(greedyResult.best.total_score < 1e-12);
assert(saResult.manifest.optimizer_seed == 8103);
assert(saResult.manifest.generator_seed == 3103);
greedyAccepted = greedyResult.history([greedyResult.history.accepted]);
assert(all([greedyAccepted.delta_from_current] <= 0));
assert(greedyResult.worse_accepted_proposals == 0);

%% Duplicate proposals are cached and do not consume objective calls
cacheConfig = saConfig;
cacheConfig.variables.DS_mu.values = targetConfig.model.DS_mu;
cacheConfig.variables.DS_mu.initial = targetConfig.model.DS_mu;
cacheConfig.limits.max_evaluations = 10;
cacheConfig.sa.no_improvement_limit = 5;
cached = run_simulated_annealing( ...
    targetGeneration.dataset, cacheConfig);
assert(cached.success);
assert(cached.objective_evaluations == 1);
assert(cached.total_proposals == 6);
assert(sum([cached.history.cached]) == 5);
assert(cached.stop_reason == "no_improvement_limit");

%% Cancellation remains non-formal
cancelled = run_simulated_annealing(targetGeneration.dataset, ...
    saConfig, struct("cancel_check", @() true));
assert(~cancelled.success);
assert(cancelled.cancelled);
assert(cancelled.outcome == "CANCELLED");
assert(~cancelled.formal_eligible);

fprintf("PASS: Step 8 unified optimizer, SA, cache, and auto strategy.\n");
