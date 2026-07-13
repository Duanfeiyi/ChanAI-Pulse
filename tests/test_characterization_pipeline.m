% ChanAI Pulse characterization tests using synthetic in-memory data only.
clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));

targetLength = 12;
realPower = (1:8).';
actualReal = prepare_dpsd_snapshot(realPower, "Scenario 1", targetLength);
expectedReal = legacyPrepareSnapshot(realPower, "Scenario 1", targetLength);
assert(isequal(actualReal, expectedReal), "Real-power extraction changed.");

sub6Cir = complex(reshape(1:48, 2, 3, 8), reshape(49:96, 2, 3, 8));
actualSub6 = prepare_dpsd_snapshot(sub6Cir, "Sub-6-Scenario 1", targetLength);
expectedSub6 = legacyPrepareSnapshot(sub6Cir, "Sub-6-Scenario 1", targetLength);
assert(isequal(actualSub6, expectedSub6), "Sub-6 extraction changed.");

mmwaveCir = complex(reshape(1:24, 1, 1, 6, 4), reshape(25:48, 1, 1, 6, 4));
actualMmwave = prepare_dpsd_snapshot(mmwaveCir, "mmWave-Scenario 2", targetLength);
expectedMmwave = legacyPrepareSnapshot(mmwaveCir, "mmWave-Scenario 2", targetLength);
assert(isequal(actualMmwave, expectedMmwave), "mmWave extraction changed.");

delayAxis = (0:3).' * 1e-9;
pdp = [1; 2; 3; 4];
expectedDelaySpread = sqrt(abs(sum((delayAxis .^ 2) .* pdp) / sum(pdp) - ...
    (sum(delayAxis .* pdp) / sum(pdp)) ^ 2));
assert(abs(compute_delay_spread(delayAxis, pdp) - expectedDelaySpread) < 1e-20, ...
    "Delay-spread calculation changed.");

dpsdMatrix = repmat(actualReal, 1, 4) + (0:3);
metrics = analyze_channel_data(dpsdMatrix, 100e6);
assert(isfield(metrics, "delay") && isfield(metrics, "time"), "Missing characterization metrics.");
assert(all(isfinite(metrics.delay.y)), "Delay spectrum contains invalid values.");
assert(all(isfinite(metrics.time.y)), "Doppler spectrum contains invalid values.");
assert(issorted(metrics.delay.cdf_x) && issorted(metrics.delay.cdf_y), "Delay CDF is not ordered.");

[angles, apsDb] = calculate_angular_spectrum(sub6Cir);
assert(numel(angles) == 128 && numel(apsDb) == 128, "Angular spectrum dimensions changed.");
assert(max(apsDb) <= 1e-10, "Angular spectrum is not peak-normalized.");

fprintf("PASS: characterization extraction and metrics match legacy behavior.\n");

function dpsdDbm = legacyPrepareSnapshot(data, scenarioName, targetLength)
if isreal(data)
    dpsdDbm = squeeze(data);
    if size(dpsdDbm, 1) == 1 && size(dpsdDbm, 2) > 1
        dpsdDbm = dpsdDbm.';
    end
    if all(dpsdDbm(:) >= 0) && max(dpsdDbm(:)) < 1e5
        dpsdDbm = 10 * log10(dpsdDbm / 1e-3 + 1e-20);
    end
else
    if contains(scenarioName, "RIS")
        if ndims(data) == 5
            hFreq = squeeze(sum(sum(sum(data, 1), 2), 3));
        elseif ndims(data) == 4
            hFreq = squeeze(sum(sum(data, 1), 2));
        elseif ndims(data) == 3
            hFreq = squeeze(sum(data, 1));
        else
            hFreq = squeeze(data);
        end
        if size(hFreq, 1) == 1 && size(hFreq, 2) > 1
            hFreq = hFreq.';
        end
        hTime = ifft(hFreq);
        dpsdDbm = 10 * log10(abs(hTime).^2 / 1e-3 + 1e-20);
    elseif contains(scenarioName, "Sub-6")
        if ndims(data) >= 3
            pdpLinear = squeeze(sum(sum(abs(data).^2, 1), 2));
        else
            pdpLinear = abs(data).^2;
        end
        if size(pdpLinear, 1) == 1 && size(pdpLinear, 2) > 1
            pdpLinear = pdpLinear.';
        end
        dpsdDbm = 10 * log10(pdpLinear / 1e-3 + 1e-20);
    else
        if ndims(data) >= 4
            cirSlice = squeeze(data(1, 1, :, :));
        elseif ndims(data) == 3
            cirSlice = squeeze(data(1, 1, :));
        else
            cirSlice = squeeze(data);
        end
        if size(cirSlice, 1) == 1 && size(cirSlice, 2) > 1
            cirSlice = cirSlice.';
        end
        dpsdDbm = 10 * log10(abs(cirSlice).^2 / 1e-3 + 1e-20);
    end
end

dpsdDbm = real(dpsdDbm(:));
if numel(dpsdDbm) >= targetLength
    dpsdDbm = dpsdDbm(1:targetLength);
else
    dpsdDbm = [dpsdDbm; zeros(targetLength - numel(dpsdDbm), 1) - 130];
end
end
