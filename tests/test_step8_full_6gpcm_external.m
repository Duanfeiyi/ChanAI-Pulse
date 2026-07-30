% Real external Full 6GPCM Step 8 minimal SA smoke test.

scriptPath = string(mfilename("fullpath"));
repositoryRoot = fileparts(fileparts(scriptPath));
addpath(genpath(fullfile(repositoryRoot, "core")));

engineRoot = string(getenv("CHANAI_FULL_6GPCM_ROOT"));
assert(strlength(strtrim(engineRoot)) > 0 && isfolder(engineRoot), ...
    "Set CHANAI_FULL_6GPCM_ROOT to the extracted full engine.");

targetConfig = default_generator_config("full_6gpcm");
targetConfig.engine_root = engineRoot;
targetConfig.dimensions.N_sample = 1;
targetConfig.random_seed = 3103;
target = run_generator_adapter(targetConfig);
assert(target.success);
assert(target.backend_manifest.core_unchanged);

config = default_optimization_config("full_6gpcm");
config.requested_strategy = "sa";
config.generator_config = targetConfig;
config.variables = struct("DS_mu", struct( ...
    "type", "discrete", ...
    "values", [targetConfig.model.DS_mu, ...
        targetConfig.model.DS_mu + 0.1], ...
    "initial", targetConfig.model.DS_mu + 0.1, ...
    "step_fraction", 1));
config.limits.max_evaluations = 2;
config.sa.no_improvement_limit = 8;
config.sa.proposals_per_temperature = 4;
result = run_parameter_optimization(target.dataset, config);

assert(result.success && result.complete);
assert(result.selected_strategy == "sa");
assert(result.best.parameters.DS_mu == targetConfig.model.DS_mu);
assert(result.best.total_score < 1e-12);
for index = 1:numel(result.retained_candidates)
    assert(result.retained_candidates(index). ...
        generation_result.backend_manifest.core_unchanged);
end
fprintf("PASS: real Full 6GPCM Step 8 minimal SA smoke.\n");
