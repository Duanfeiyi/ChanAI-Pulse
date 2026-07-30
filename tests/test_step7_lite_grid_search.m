% Step 7 engineering smoke test through 6GPCM-lite.

scriptPath = string(mfilename("fullpath"));
repositoryRoot = fileparts(fileparts(scriptPath));
addpath(genpath(fullfile(repositoryRoot, "core")));

targetConfig = default_generator_config("lite_6gpcm");
targetConfig.dimensions.Nt = 3;
targetConfig.dimensions.N_sample = 4;
target = run_generator_adapter(targetConfig);
assert(target.success);

config = default_grid_search_config("lite_6gpcm");
config.generator_config = targetConfig;
config.parameter_space = struct( ...
    "DS_mu", [targetConfig.model.DS_mu - 0.1, ...
        targetConfig.model.DS_mu], ...
    "KF_mu", [targetConfig.model.KF_mu, ...
        targetConfig.model.KF_mu + 0.5]);
config.limits.retain_top_k = 2;
result = run_grid_search(target.dataset, config);

assert(result.success && result.complete);
assert(result.total_candidates == 4);
assert(result.best.parameters.DS_mu == targetConfig.model.DS_mu);
assert(result.best.parameters.KF_mu == targetConfig.model.KF_mu);
assert(result.best.total_score < 1e-12);
assert(result.manifest.backend == "lite_6gpcm");
assert(numel(result.retained_candidates) == 2);
fprintf("PASS: Step 7 6GPCM-lite Grid Search smoke.\n");
