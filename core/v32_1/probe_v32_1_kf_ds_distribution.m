function probe_v32_1_kf_ds_distribution(engineRoot)
%PROBE_V32_1_KF_DS_DISTRIBUTION Inspect true (un-clipped) KF/DS observables.
%   Regenerates routes across all 12 scenarios, computes per-snapshot KF/DS
%   medians WITHOUT the product bounds clipping, and reports how far they
%   fall outside the current bounds [-20,30] dB (KF) / [-9,-5] log10 s (DS).

arguments
    engineRoot (1, 1) string = ""
end

if engineRoot == ""
    engineRoot = resolve_full_6gpcm_root().root;
end

scenarios = [ ...
    "sub-6 GHz_UMa_LoS", "sub-6 GHz_UMa_NLoS", ...
    "sub-6 GHz_UMi_LoS", "sub-6 GHz_UMi_NLoS", ...
    "sub-6 GHz_RMa_LoS", "sub-6 GHz_RMa_NLoS", ...
    "sub-6 GHz_Indoor_LoS", "sub-6 GHz_Indoor_NLoS", ...
    "cmWave_UMa_LoS", "cmWave_UMa_NLoS", ...
    "mmWave_UMi_LoS", "mmWave_UMi_NLoS"];

allKf = [];
allDs = [];
for index = 1:numel(scenarios)
    scenario = scenarios(index);
    route = generate_v32_1_time_route(engineRoot, ...
        ScenarioName=scenario, SpeedMps=8.0, ...
        SnapshotIntervalS=0.100, TxCount=2, RxCount=4, Nt=96, ...
        Seed=95000 + index);
    [kf, ds] = trueObservables(route.dataset);
    allKf = [allKf; kf(:)]; %#ok<AGROW>
    allDs = [allDs; ds(:)]; %#ok<AGROW>
    fprintf("%-22s KF[min=%.1f max=%.1f med=%.1f]  DS[min=%.3f max=%.3f med=%.3f]\n", ...
        scenario, min(kf), max(kf), median(kf), min(ds), max(ds), median(ds));
end

fprintf("\n===== aggregated true (un-clipped) distribution =====\n");
fprintf("KF_mu: min=%.2f max=%.2f  p5=%.2f p95=%.2f  mean=%.2f\n", ...
    min(allKf), max(allKf), prctile(allKf, 5), prctile(allKf, 95), mean(allKf));
fprintf("DS_mu: min=%.4f max=%.4f  p5=%.4f p95=%.4f  mean=%.4f\n", ...
    min(allDs), max(allDs), prctile(allDs, 5), prctile(allDs, 95), mean(allDs));

% Fraction outside current bounds.
fprintf("\n===== fraction outside current bounds =====\n");
fprintf("KF outside [-20,30]: %.2f%%\n", 100 * mean(allKf < -20 | allKf > 30));
fprintf("KF below -20: %.2f%%\n", 100 * mean(allKf < -20));
fprintf("KF above 30:  %.2f%%\n", 100 * mean(allKf > 30));
fprintf("DS outside [-9,-5]: %.2f%%\n", 100 * mean(allDs < -9 | allDs > -5));
fprintf("DS below -9: %.2f%%\n", 100 * mean(allDs < -9));
fprintf("DS above -5: %.2f%%\n", 100 * mean(allDs > -5));
end

function [kfOut, dsOut] = trueObservables(dataset)
coefficient = dataset.cir.coefficient;
shape = [size(coefficient, 1), size(coefficient, 2), ...
    size(coefficient, 3), size(coefficient, 4), size(coefficient, 5)];
delayS = expandToShape(dataset.cir.delay_s, shape);
pathValid = logical(expandToShape(dataset.cir.path_valid, shape));
kfOut = nan(shape(4), 1);
dsOut = nan(shape(4), 1);
for time = 1:shape(4)
    delaySpread = [];
    kFactorDb = [];
    for sample = 1:shape(5)
        snapshotPower = abs(coefficient(:, :, :, time, sample)).^2;
        snapshotDelay = delayS(:, :, :, time, sample);
        snapshotValid = pathValid(:, :, :, time, sample) & ...
            isfinite(snapshotPower) & snapshotPower >= 0 & ...
            isfinite(snapshotDelay);
        powerVector = double(snapshotPower(snapshotValid));
        delayVector = double(snapshotDelay(snapshotValid));
        if isempty(powerVector) || sum(powerVector) <= 0
            continue;
        end
        spread = compute_delay_spread(delayVector, powerVector);
        if isfinite(spread) && spread > 0
            delaySpread(end + 1, 1) = spread; %#ok<AGROW>
        end
        pathPower = squeeze(sum(snapshotPower, [1, 2]));
        pathIsValid = squeeze(any(pathValid(:, :, :, time, sample), [1, 2]));
        pathPower = double(pathPower(:));
        pathIsValid = logical(pathIsValid(:)) & isfinite(pathPower) & ...
            pathPower >= 0;
        pathPower = pathPower(pathIsValid);
        if isempty(pathPower) || sum(pathPower) <= 0
            continue;
        end
        strongest = max(pathPower);
        diffuse = max(sum(pathPower) - strongest, realmin("double"));
        kFactorDb(end + 1, 1) = 10 * log10(strongest / diffuse); %#ok<AGROW>
    end
    if ~isempty(kFactorDb)
        kfOut(time) = median(kFactorDb);
    end
    if ~isempty(delaySpread)
        dsOut(time) = log10(max(median(delaySpread), 1e-9));
    end
end
end

function value = expandToShape(value, targetShape)
sourceShape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
if ~all(sourceShape == 1 | sourceShape == targetShape)
    error("probe_v32_1_kf_ds_distribution:CannotExpand", ...
        "A CIR field cannot expand to coefficient dimensions.");
end
value = repmat(reshape(value, sourceShape), targetShape ./ sourceShape);
end
