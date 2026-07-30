% Optional real external full 6GPCM Step 6 adapter smoke test.

scriptPath = string(mfilename("fullpath"));
repositoryRoot = fileparts(fileparts(scriptPath));
addpath(genpath(fullfile(repositoryRoot, "core")));

engineRoot = string(getenv("CHANAI_FULL_6GPCM_ROOT"));
if strlength(strtrim(engineRoot)) == 0
    fprintf("SKIP: CHANAI_FULL_6GPCM_ROOT is not configured.\n");
    return;
end

config = default_generator_config("full_6gpcm");
config.engine_root = engineRoot;
config.dimensions.N_sample = 1;
config.ctf.enabled = true;
config.ctf.frequency_hz = linspace(15.95e9, 16.05e9, 16).';
result = run_generator_adapter(config);
assert(result.success, strjoin(result.errors, " | "));
assert(result.backend == "full_6gpcm");
assert(result.backend_manifest.core_unchanged);
assert(result.backend_manifest.tree_sha256_before == ...
    result.backend_manifest.tree_sha256_after);
assert(result.validation.dataset.is_valid);
assert(result.validation.ctf.is_valid);
assert(isequal(size5(result.dataset.cir.coefficient), ...
    [2, 2, 240, 2, 1]));
assert(isequal(size5(result.ctf_dataset.ctf.H), ...
    [2, 2, 16, 2, 1]));
fprintf("PASS: real full 6GPCM Step 6 Adapter and core-integrity check.\n");

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end
