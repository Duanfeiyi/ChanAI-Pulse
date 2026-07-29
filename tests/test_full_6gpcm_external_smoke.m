% Optional real-engine smoke test for ChanAI Pulse v3 Step 3.
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
result = run_full_6gpcm_probe(config);
assert(result.report.status == "PASS");
assert(result.report.core_unchanged);
assert(result.report.coefficient_is_complex);
assert(result.report.coefficient_all_finite);
assert(result.report.delay_all_finite);
assert(result.report.validation.is_valid);
assert(isequal(result.report.raw_shapes, [2, 2, 2, 240]));
assert(isequal(result.report.canonical_shape, [2, 2, 240, 2, 1]));
fprintf("PASS: real full 6GPCM headless probe and canonical CIR conversion.\n");
