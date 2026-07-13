% ChanAI Pulse 6GPCM-lite generation test using synthetic configuration only.
clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));

config = default_6gpcm_lite_config();
config.snapshots = 8;
config.clusters = 5;
config.rays = 7;
config.delay_max_ns = 63;
config.random_seed = 110;

first = generate_6gpcm_lite(config);
second = generate_6gpcm_lite(config);

assert(isequal(size(first.cir), [1, 1, 8, 64]), "Unexpected generated CIR tensor shape.");
assert(isequal(size(first.delay), [1, 1, 8, 64]), "Unexpected generated delay tensor shape.");
assert(~isreal(first.cir), "Generated CIR must preserve complex channel coefficients.");
assert(all(isfinite(first.delay_spread_ns)) && all(first.delay_spread_ns >= 0), ...
    "Generated delay spreads are invalid.");
assert(isequal(first.cir, second.cir), "Fixed random seed must give repeatable output.");
assert(all(diff(first.preview.cluster_delays_s) >= 0), "Cluster delays must be sorted.");

dpsdDbm = generation_result_to_dpsd(first);
assert(isequal(size(dpsdDbm), [64, 8]), "Generated DPSD has unexpected shape.");
assert(all(isfinite(dpsdDbm), "all"), "Generated DPSD contains invalid values.");

singleSnapshot = first;
singleSnapshot.cir = first.cir(:, :, 1, :);
singleDpsdDbm = generation_result_to_dpsd(singleSnapshot);
assert(isequal(size(singleDpsdDbm), [64, 1]), "Single-snapshot DPSD has unexpected shape.");

fprintf("PASS: 6GPCM-lite generator produces deterministic synthetic channel tensors.\n");
