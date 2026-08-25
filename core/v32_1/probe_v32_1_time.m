function probe_v32_1_time(engineRoot)
%PROBE_V32_1_TIME Small-scale v3.2-1 Time-axis synthesis probe.
%   Generates a few time routes and reports dimension, axis and Doppler
%   checks. Writes nothing to the repository; purely a local validation run.

arguments
    engineRoot (1, 1) string = ""
end

if engineRoot == ""
    installation = resolve_full_6gpcm_root();
    engineRoot = installation.root;
end
fprintf("Full 6GPCM root: %s\n", engineRoot);
fprintf("public API present: %d\n", resolve_full_6gpcm_root().has_public_api);

scenarios = ["sub-6 GHz_UMa_LoS", "sub-6 GHz_UMa_NLoS", ...
    "cmWave_UMa_LoS", "mmWave_UMi_LoS"];
speeds = [1.0, 8.0];

routeIndex = 0;
for scenario = scenarios
    for speed = speeds
        routeIndex = routeIndex + 1;
        output = generate_v32_1_time_route(engineRoot, ...
            ScenarioName=scenario, SpeedMps=speed, ...
            TxCount=2, RxCount=4, Nt=96, Seed=11011 + routeIndex);
        dataset = output.dataset;
        dims = dataset.dimensions;
        coeff = dataset.cir.coefficient;
        fprintf("[%d] %-22s speed=%4.1f  dims=[Tx=%d Rx=%d Npath=%d Nt=%d N_sample=%d]\n", ...
            routeIndex, scenario, speed, dims.Tx, dims.Rx, dims.Npath, ...
            dims.Nt, dims.N_sample);
        assert(dims.Nt == 96, "Nt must be 96");
        assert(dims.Tx == 2 && dims.Rx == 4, "Tx/Rx must be 2/4");
        assert(isfield(dataset.axes, "time_s"), "time_s axis missing");
        assert(numel(dataset.axes.time_s) == 96, "time_s length must be 96");
        % Doppler evolution check: energy across time snapshots must vary
        % for a moving (speed>0) route.
        energyByTime = squeeze(sum(sum(sum(abs(coeff).^2, 1), 2), 3));
        energyByTime = energyByTime(:);
        spread = std(energyByTime) / max(mean(energyByTime), realmin("double"));
        fprintf("       time-energy rel. std = %.4f (must be > 0 for moving route)\n", spread);
        assert(spread > 0, "moving route must show time variation");
    end
end

fprintf("PASS: v3.2-1 Time synthesis probe generated %d routes.\n", routeIndex);
end
