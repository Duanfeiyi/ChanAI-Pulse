% Optional real-engine repeatability test for ChanAI Pulse v3 Step 3.
% Set CHANAI_FULL_6GPCM_ROOT to the externally extracted engine root.

scriptPath = string(mfilename("fullpath"));
repositoryRoot = fileparts(fileparts(scriptPath));
addpath(genpath(fullfile(repositoryRoot, "core")));
engineRoot = string(getenv("CHANAI_FULL_6GPCM_ROOT"));
if strlength(strtrim(engineRoot)) == 0
    fprintf("SKIP: CHANAI_FULL_6GPCM_ROOT is not configured.\n");
    return;
end

config = default_full_6gpcm_probe_config(engineRoot);
config.sample_count = 1;
first = run_full_6gpcm_probe(config);
second = run_full_6gpcm_probe(config);

assert(isequal(first.raw.H_all, second.raw.H_all));
assert(isequal(first.raw.delay_all, second.raw.delay_all));
assert(isequal(first.dataset.cir.coefficient, ...
    second.dataset.cir.coefficient));
assert(isequal(first.dataset.cir.delay_s, second.dataset.cir.delay_s));
assert(first.report.tree_sha256_before == ...
    second.report.tree_sha256_after);
fprintf("PASS: real full 6GPCM fixed-seed output is exactly repeatable.\n");
