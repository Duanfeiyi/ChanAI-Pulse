% Step 12 configurable Full 6GPCM public API integration test.
clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));
engineRoot = string(getenv("CHANAI_FULL_6GPCM_ROOT"));
if strlength(strtrim(engineRoot)) == 0
    candidate = fullfile(fileparts(repoRoot), ...
        "ChanAI-Pulse-v3-step11abc-assets", "full6gpcm", "source");
    if isfolder(candidate)
        engineRoot = string(candidate);
    end
end
if strlength(strtrim(engineRoot)) == 0 || ~isfolder(engineRoot)
    fprintf("SKIP: configurable external Full 6GPCM root is unavailable.\n");
    return;
end

before = hash_full_6gpcm_tree(engineRoot);
config = default_generator_config("full_6gpcm");
config.mode = "formal";
config.engine_root = engineRoot;
config.backend_options.full_interface = "public_api";
config.dimensions = struct( ...
    "Tx", 2, "Rx", 4, "Npath", 0, "Nt", 3, "N_sample", 1);
config.scenario.track_type = "linear";
config.scenario.snapshot_interval_s = 1e-3;
config.ctf.enabled = true;
config.ctf.frequency_hz = linspace(15.95e9, 16.05e9, 8).';

result = run_generator_adapter(config);
assert(result.success);
assert(result.formal_eligible);
assert(result.backend_manifest.interface == "public_api");
assert(result.backend_manifest.core_unchanged);
assert(isequal(size5(result.dataset.cir.coefficient), [2, 4, 240, 3, 1]));
assert(isequal(size5(result.ctf_dataset.ctf.H), [2, 4, 8, 3, 1]));
assert(result.dataset.dimensions.Tx == 2);
assert(result.dataset.dimensions.Rx == 4);
assert(result.dataset.dimensions.Nt == 3);
after = hash_full_6gpcm_tree(engineRoot);
assert(before.aggregate_sha256 == after.aggregate_sha256);

fprintf("PASS: configurable external Full 6GPCM preserves MIMO/time dimensions and core hash.\n");

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end
