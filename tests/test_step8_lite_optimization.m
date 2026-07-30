% Step 8 SA smoke test through 6GPCM-lite.

scriptPath = string(mfilename("fullpath"));
repositoryRoot = fileparts(fileparts(scriptPath));
addpath(genpath(fullfile(repositoryRoot, "core")));

targetConfig = default_generator_config("lite_6gpcm");
targetConfig.dimensions.Nt = 3;
targetConfig.dimensions.N_sample = 4;
target = run_generator_adapter(targetConfig);
assert(target.success);

config = default_optimization_config("lite_6gpcm");
config.requested_strategy = "sa";
config.generator_config = targetConfig;
config.variables = struct("DS_mu", struct( ...
    "type", "discrete", ...
    "values", [targetConfig.model.DS_mu, ...
        targetConfig.model.DS_mu + 0.1], ...
    "initial", targetConfig.model.DS_mu + 0.1, ...
    "step_fraction", 1));
config.limits.max_evaluations = 4;
config.sa.no_improvement_limit = 8;
config.sa.proposals_per_temperature = 4;
result = run_parameter_optimization(target.dataset, config);

assert(result.success && result.complete);
assert(result.selected_strategy == "sa");
assert(result.best.parameters.DS_mu == targetConfig.model.DS_mu);
assert(result.best.total_score < 1e-12);
assert(result.details.manifest.backend == "lite_6gpcm");
fprintf("PASS: Step 8 6GPCM-lite SA smoke.\n");
