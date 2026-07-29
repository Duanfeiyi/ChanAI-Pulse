% ChanAI Pulse v3 Step 3 probe tests using a project-owned test double.

scriptPath = string(mfilename("fullpath"));
repositoryRoot = fileparts(fileparts(scriptPath));
addpath(genpath(fullfile(repositoryRoot, "core")));
mockRoot = fullfile(repositoryRoot, "tests", "fixtures", ...
    "mock_full_6gpcm");

config = default_full_6gpcm_probe_config(mockRoot);
config.engine_id = "full_6gpcm_test_double";
config.source_package_name = "project_owned_test_double";
config.source_version = "test-only";
config.source_package_sha256 = "";
config.expected_tree_sha256 = "";
config.num_clusters = 2;
config.num_rays = 3;
config.sample_count = 2;
config.random_seed = 3103;

first = run_full_6gpcm_probe(config);
second = run_full_6gpcm_probe(config);
assert(first.report.status == "PASS");
assert(first.report.core_unchanged);
assert(first.report.tree_sha256_before == first.report.tree_sha256_after);
assert(first.report.validation.is_valid);
assert(isequal(first.dataset.dimension_order, ...
    ["Tx", "Rx", "Npath", "Nt", "N_sample"]));
assert(isequal(size5(first.dataset.cir.coefficient), [2, 2, 6, 2, 2]));
assert(isequal(size5(first.dataset.cir.delay_s), [2, 2, 6, 2, 2]));
assert(all(first.dataset.cir.path_valid(:)));
assert(first.dataset.metadata.sample_semantics == "independent");
assert(~first.report.capabilities.delay_sample_heatmap);
assert(first.report.capabilities.classification == ...
    "wideband_dynamic_mimo");
assert(isequal(first.dataset.cir.coefficient, ...
    second.dataset.cir.coefficient));
assert(isequal(first.dataset.cir.delay_s, second.dataset.cir.delay_s));

missingConfig = config;
missingConfig.engine_root = fullfile(tempdir, ...
    "chanai_missing_full_6gpcm_step3");
assertError(@() run_full_6gpcm_probe(missingConfig), ...
    "run_full_6gpcm_probe:MissingEngineRoot");

invalidConfig = config;
invalidConfig.sample_count = 0;
assertError(@() run_full_6gpcm_probe(invalidConfig), ...
    "run_full_6gpcm_probe:InvalidConfig");

fprintf("PASS: Step 3 full 6GPCM probe contract and error paths.\n");

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end

function assertError(functionHandle, expectedIdentifier)
didThrow = false;
try
    functionHandle();
catch exception
    didThrow = true;
    assert(string(exception.identifier) == string(expectedIdentifier), ...
        "Expected %s but received %s.", ...
        expectedIdentifier, exception.identifier);
end
assert(didThrow, "Expected error %s was not raised.", expectedIdentifier);
end
