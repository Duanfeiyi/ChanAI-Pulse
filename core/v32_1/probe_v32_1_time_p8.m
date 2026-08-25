function probe_v32_1_time_p8(engineRoot)
%PROBE_V32_1_TIME_P8 Verify slow-varying Time-axis DS_mu/KF_mu extraction.
%   Generates a moving Time route with second-scale sampling, derives
%   per-snapshot DS_mu/KF_mu, and checks that the sequence varies across time
%   (DS/KF slow variation must appear over long displacement) while
%   num_clusters is reported as a frozen anchor.

arguments
    engineRoot (1, 1) string = ""
end

if engineRoot == ""
    engineRoot = resolve_full_6gpcm_root().root;
end

route = generate_v32_1_time_route(engineRoot, ...
    ScenarioName="sub-6 GHz_UMa_LoS", SpeedMps=8.0, ...
    SnapshotIntervalS=0.100, TxCount=2, RxCount=4, Nt=96, Seed=2202);

seq = estimate_v32_1_time_p8_sequence(route.dataset);

fprintf("Time observable sequence: %d snapshots x %d observables\n", ...
    size(seq.values, 1), size(seq.values, 2));
fprintf("parameter_names: %s\n", strjoin(seq.parameter_names, ", "));
assert(size(seq.values, 1) == 96, "sequence must have 96 snapshots");
assert(size(seq.values, 2) == 2, "sequence must have 2 observables (DS_mu, KF_mu)");
assert(isequal(seq.parameter_names, ["DS_mu", "KF_mu"]), ...
    "observable names mismatch");
assert(isfield(seq, "time_s"), "time_s missing");
assert(numel(seq.time_s) == 96, "time_s must have 96 entries");
assert(isfield(seq.frozen_anchor, "num_clusters"), ...
    "num_clusters frozen anchor missing");
assert(logical(seq.frozen_anchor.num_clusters_is_time_invariant), ...
    "num_clusters must be marked time-invariant");

fprintf("DS_mu range: [%.4f, %.4f]\n", ...
    min(seq.values(:, 1)), max(seq.values(:, 1)));
fprintf("KF_mu range: [%.3f, %.3f]\n", ...
    min(seq.values(:, 2)), max(seq.values(:, 2)));
fprintf("num_clusters frozen anchor: %d\n", ...
    seq.frozen_anchor.num_clusters);

% A long-displacement moving route must yield time-varying DS or KF.
dsSpread = std(seq.values(:, 1), "omitnan");
kfSpread = std(seq.values(:, 2), "omitnan");
fprintf("per-snapshot std: DS=%.4f KF=%.4f\n", dsSpread, kfSpread);
assert(dsSpread > 0 || kfSpread > 0, ...
    "long-displacement moving route must yield slow-varying DS or KF");

assert(all(isfinite(seq.values), "all"), ...
    "observable values must be finite");

fprintf("PASS: slow-varying Time DS_mu/KF_mu extraction works.\n");
end
