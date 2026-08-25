function probe_v32_1_space(engineRoot)
%PROBE_V32_1_SPACE Verify Space-axis CIR synthesis + per-position P8 extraction.

arguments
    engineRoot (1, 1) string = ""
end

if engineRoot == ""
    engineRoot = resolve_full_6gpcm_root().root;
end

route = generate_v32_1_space_route(engineRoot, ...
    ScenarioName="sub-6 GHz_UMa_LoS", SpeedMps=8.0, ...
    SnapshotIntervalS=0.100, TxCount=2, RxCount=4, NSample=96, Seed=6600);

dataset = route.dataset;
dims = dataset.dimensions;
fprintf("Space route: Tx=%d Rx=%d Npath=%d Nt=%d N_sample=%d\n", ...
    dims.Tx, dims.Rx, dims.Npath, dims.Nt, dims.N_sample);
assert(dims.N_sample == 96, "N_sample must be 96");
assert(dims.Nt == 1, "Space route should use Nt=1 per position");
assert(isfield(dataset.axes, "sample_position_m"), "sample_position_m missing");
pos = dataset.axes.sample_position_m;
fprintf("sample_position_m shape: [%d %d]\n", size(pos, 1), size(pos, 2));
assert(size(pos, 1) == dims.N_sample, "position rows must equal N_sample");

seq = estimate_v32_1_space_p8_sequence(dataset);
fprintf("Space P8 sequence: %d positions x %d observables\n", ...
    size(seq.values, 1), size(seq.values, 2));
assert(size(seq.values, 1) == 96, "sequence must have 96 positions");
assert(size(seq.values, 2) == 2, "sequence must have 2 observables (DS_mu, KF_mu)");
assert(isequal(seq.parameter_names, ["DS_mu", "KF_mu"]), ...
    "observable names mismatch");
assert(isfield(seq.frozen_anchor, "num_clusters"), ...
    "num_clusters frozen anchor missing");
assert(logical(seq.frozen_anchor.num_clusters_is_position_invariant), ...
    "num_clusters must be marked position-invariant");

dsSpread = std(seq.values(:, 1), "omitnan");
kfSpread = std(seq.values(:, 2), "omitnan");
fprintf("per-position std: DS=%.4f KF=%.4f\n", dsSpread, kfSpread);
fprintf("DS_mu range [%.4f, %.4f], KF_mu range [%.3f, %.3f]\n", ...
    min(seq.values(:, 1)), max(seq.values(:, 1)), ...
    min(seq.values(:, 2)), max(seq.values(:, 2)));
fprintf("num_clusters frozen anchor: %d\n", seq.frozen_anchor.num_clusters);
assert(dsSpread > 0 || kfSpread > 0, ...
    "Space route must yield position-varying observables");
assert(all(isfinite(seq.values), "all"), "observables must be finite");

fprintf("PASS: Space-axis CIR synthesis + per-position P8 extraction works.\n");
end
