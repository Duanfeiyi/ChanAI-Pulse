function result = run_full_6gpcm_probe_example(engineRoot)
%RUN_FULL_6GPCM_PROBE_EXAMPLE Minimal external Step 3 invocation.
%   The full 6GPCM core remains outside the repository and is never edited.

arguments
    engineRoot (1, 1) string
end

repositoryRoot = fileparts(fileparts(string(mfilename("fullpath"))));
addpath(genpath(fullfile(repositoryRoot, "core")));
config = default_full_6gpcm_probe_config(engineRoot);
result = run_full_6gpcm_probe(config);

fprintf("Status: %s\n", result.report.status);
fprintf("Raw first sample [Tx Rx Nt Npath]: %s\n", ...
    mat2str(result.report.raw_shapes(1, :)));
fprintf("Canonical CIR [Tx Rx Npath Nt N_sample]: %s\n", ...
    mat2str(result.report.canonical_shape));
fprintf("Core unchanged: %d\n", result.report.core_unchanged);
end
