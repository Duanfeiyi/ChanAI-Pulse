% Step 11ABC training-corpus regression test (no external engine required).

clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));

config = default_step11abc_config();
config.route.group_count = 8;
config.data.split_group_counts = [6, 1, 1];
corpus = create_step11abc_training_corpus("unused-for-embedded-profile", ...
    "Config", config, "UseExternalProfiles", false);

assert(isequal(corpus.config.parameter_bundles.P2, ...
    ["DS_mu", "KF_mu"]), "P2 parameter order changed.");
assert(isequal(corpus.config.parameter_bundles.P8, ...
    corpus.config.parameter_names), "P8 must retain canonical order.");
assert(corpus.summary.route_group_count == 8, "Unexpected group count.");
assert(corpus.bundles.extrapolation.P8.dataset.summary.N_example == 808, ...
    "Expected 8 routes x 101 extrapolation windows.");
assert(corpus.bundles.interpolation.P4.split.leakage_check.passed, ...
    "Route groups must never overlap across partitions.");
assert(all(corpus.sequence.label_source == "generator_truth"), ...
    "Training labels must be explicitly marked as generator truth.");
assert(all(mod(corpus.sequence.values(:, 7:8), 1) == 0, "all"), ...
    "Cluster/ray count labels must stay integral.");

fprintf("PASS: Step 11ABC corpus contract, P-bundle order, and group split are valid.\n");
