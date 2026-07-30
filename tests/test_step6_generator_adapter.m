% ChanAI Pulse v3 Step 6 shared Generator Adapter tests.

scriptPath = string(mfilename("fullpath"));
repositoryRoot = fileparts(fileparts(scriptPath));
addpath(genpath(fullfile(repositoryRoot, "core")));

%% Mock: deterministic, configurable five-dimensional CIR and optional CTF
mockConfig = default_generator_config("mock");
mockConfig.dimensions = struct( ...
    "Tx", 2, "Rx", 3, "Npath", 7, "Nt", 4, "N_sample", 5);
mockConfig.ctf.enabled = true;
mockConfig.ctf.frequency_hz = linspace(15.95e9, 16.05e9, 16).';
firstMock = run_generator_adapter(mockConfig);
secondMock = run_generator_adapter(mockConfig);
assert(firstMock.success && firstMock.outcome == "SUCCEEDED");
assert(firstMock.status == "WARNING", ...
    "Mock must be visibly marked as test-only.");
assert(firstMock.backend == "mock");
assert(firstMock.backend_report.test_only);
assert(~firstMock.formal_eligible);
assert(isequal(size5(firstMock.dataset.cir.coefficient), ...
    [2, 3, 7, 4, 5]));
assert(isequal(size5(firstMock.ctf_dataset.ctf.H), ...
    [2, 3, 16, 4, 5]));
assert(isequal(firstMock.dataset.cir.coefficient, ...
    secondMock.dataset.cir.coefficient));
assert(firstMock.validation.dataset.is_valid);
assert(firstMock.validation.ctf.is_valid);
assert(firstMock.manifest.config.engine_root == "");
assert(~isempty(firstMock.events));
assert(firstMock.events(end).progress == 1);

%% Cooperative cancellation before backend execution
cancelled = run_generator_adapter(mockConfig, ...
    struct("cancel_check", @() true));
assert(~cancelled.success);
assert(cancelled.cancelled);
assert(cancelled.outcome == "CANCELLED");
assert(cancelled.status == "WARNING");
assert(isempty(fieldnames(cancelled.dataset)));

%% Lite: deterministic conversion from legacy layout to canonical v3 CIR
liteConfig = default_generator_config("lite_6gpcm");
liteConfig.dimensions.Nt = 3;
liteConfig.dimensions.N_sample = 3;
liteConfig.ctf.enabled = true;
liteConfig.ctf.frequency_hz = linspace(15.975e9, 16.025e9, 8).';
firstLite = run_generator_adapter(liteConfig);
secondLite = run_generator_adapter(liteConfig);
assert(firstLite.success && firstLite.backend == "lite_6gpcm");
assert(firstLite.status == "WARNING", ...
    "Lite limitations must remain visible.");
assert(isequal(size5(firstLite.dataset.cir.coefficient), ...
    [1, 1, 31, 3, 3]));
assert(isequal(size5(firstLite.ctf_dataset.ctf.H), ...
    [1, 1, 8, 3, 3]));
assert(isequal(firstLite.dataset.cir.coefficient, ...
    secondLite.dataset.cir.coefficient));
assert(firstLite.dataset.metadata.seed_rule == ...
    "base_seed_plus_sample_index_minus_one");

%% Full adapter contract through the project-owned Step 3 test double
mockFullRoot = fullfile(repositoryRoot, "tests", "fixtures", ...
    "mock_full_6gpcm");
fullConfig = default_generator_config("full_6gpcm");
fullConfig.engine_root = mockFullRoot;
fullConfig.engine.id = "full_6gpcm_test_double";
fullConfig.engine.version = "test-only";
fullConfig.engine.source_package_name = "project_owned_test_double";
fullConfig.engine.source_package_sha256 = "";
fullConfig.engine.expected_tree_sha256 = "";
fullConfig.engine.test_only = true;
fullConfig.dimensions.N_sample = 2;
fullConfig.model.num_clusters = 2;
fullConfig.model.num_rays = 3;
fullConfig.ctf.enabled = true;
fullConfig.ctf.frequency_hz = linspace(15.99e9, 16.01e9, 5).';
fullDouble = run_generator_adapter(fullConfig);
assert(fullDouble.success);
assert(fullDouble.backend == "full_6gpcm");
assert(fullDouble.status == "WARNING");
assert(fullDouble.backend_manifest.test_only);
assert(fullDouble.backend_manifest.core_unchanged);
assert(isequal(size5(fullDouble.dataset.cir.coefficient), ...
    [2, 2, 6, 2, 2]));
assert(isequal(size5(fullDouble.ctf_dataset.ctf.H), ...
    [2, 2, 5, 2, 2]));

%% Windows-style forward slashes resolve to the same engine tree
forwardSlashFull = fullConfig;
forwardSlashFull.engine_root = replace(string(mockFullRoot), "\", "/");
forwardSlashResult = run_generator_adapter(forwardSlashFull);
assert(forwardSlashResult.success);
assert(forwardSlashResult.backend_manifest.core_unchanged);

%% Missing full engine must fail without silently using Lite
missingFull = default_generator_config("full_6gpcm");
missingFull.engine_root = fullfile(tempdir, ...
    "chanai_missing_full_6gpcm_step6");
failedFull = run_generator_adapter(missingFull);
assert(~failedFull.success);
assert(failedFull.status == "FAIL");
assert(failedFull.outcome == "FAILED");
assert(failedFull.backend == "full_6gpcm");
assert(isempty(fieldnames(failedFull.dataset)));
assert(any(contains(failedFull.errors, "engine_root")));
assert(~contains(strjoin(failedFull.errors, " "), "Lite"));

%% Unsupported full-engine geometry must be rejected, not ignored
unsupportedFull = fullConfig;
unsupportedFull.dimensions.Tx = 4;
unsupportedResult = run_generator_adapter(unsupportedFull);
assert(~unsupportedResult.success);
assert(unsupportedResult.status == "FAIL");
assert(any(contains(unsupportedResult.errors, "fixes Tx=2")));

fprintf("PASS: Step 6 shared Generator Adapter contract and error paths.\n");

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end
