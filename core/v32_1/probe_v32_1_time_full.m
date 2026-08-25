function probe_v32_1_time_full(engineRoot)
%PROBE_V32_1_TIME_FULL End-to-end Time-axis synthesis + windowing probe.
%   Generates several long-displacement Time routes, derives per-snapshot
%   DS_mu/KF_mu, wraps them into a parameter sequence, and builds 16->4
%   extrapolation windows. Verifies: non-constant observables, correct window
%   counts, and known/target non-overlap.

arguments
    engineRoot (1, 1) string = ""
end

if engineRoot == ""
    engineRoot = resolve_full_6gpcm_root().root;
end

scenarios = ["sub-6 GHz_UMa_LoS", "sub-6 GHz_UMa_NLoS"];
routeCount = numel(scenarios);
names = ["DS_mu", "KF_mu"];
bounds = [-9.0, -5.0; -20, 30];

for routeIndex = 1:routeCount
    route = generate_v32_1_time_route(engineRoot, ...
        ScenarioName=scenarios(routeIndex), SpeedMps=8.0, ...
        SnapshotIntervalS=0.100, TxCount=2, RxCount=4, Nt=96, ...
        Seed=4400 + routeIndex);
    seq = estimate_v32_1_time_p8_sequence(route.dataset);

    sequence = create_parameter_sequence(seq.values, names, struct( ...
        "group_id", repmat("route-" + compose("%02d", routeIndex), 96, 1), ...
        "parameter_sample_index", (1:96).', ...
        "bounds", bounds, ...
        "label_source", "direct_channel_observed", ...
        "quality_status", repmat("PASS", 96, 1), ...
        "provenance", seq.provenance));

    dataConfig = default_predictor_data_config();
    dataset = build_predictor_dataset(sequence, "extrapolation", dataConfig);

    nt = 96;
    expectedExamples = nt - 16 - 4 + 1;  % 96-20+1 = 77
    fprintf("[%s] examples=%d (expected %d), input=%dx16x2, target=%dx4x2\n", ...
        scenarios(routeIndex), dataset.summary.N_example, expectedExamples, ...
        dataset.summary.N_example, dataset.summary.N_example);
    assert(dataset.summary.N_example == expectedExamples, ...
        "unexpected example count");
    assert(size(dataset.inputs, 2) == 16 && size(dataset.inputs, 3) == 2, ...
        "input tensor must be [N,16,2]");
    assert(size(dataset.targets, 2) == 4 && size(dataset.targets, 3) == 2, ...
        "target tensor must be [N,4,2]");

    % Known/target index non-overlap and causality: every example's max input
    % index must be strictly less than its min target index.
    inIdx = dataset.input_parameter_sample_index;
    tgtIdx = dataset.target_parameter_sample_index;
    assert(all(max(inIdx, [], 2) < min(tgtIdx, [], 2)), ...
        "extrapolation windows must be strictly causal");

    % Observables must vary across the route (not a constant sequence).
    dsSpread = std(seq.values(:, 1), "omitnan");
    kfSpread = std(seq.values(:, 2), "omitnan");
    assert(dsSpread > 0 || kfSpread > 0, ...
        "long-displacement route must yield slow-varying observables");
end

fprintf("PASS: end-to-end Time synthesis + 16->4 windowing works.\n");
end
