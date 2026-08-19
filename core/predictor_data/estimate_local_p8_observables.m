function estimate = estimate_local_p8_observables(channelDataset)
%ESTIMATE_LOCAL_P8_OBSERVABLES Derive identifiable local P8 proxies.
%   DS_mu is the median log10 RMS delay spread. KF_mu is the median
%   dominant-to-diffuse power ratio. num_clusters is a conservative count
%   of paths/taps within 20 dB of the strongest component. These values are
%   computed from the supplied known-only channel samples; no generator is
%   fitted and no target-region channel sample is required.

arguments
    channelDataset (1, 1) struct
end

report = validate_channel_dataset(channelDataset);
if ~report.is_valid
    error("estimate_local_p8_observables:InvalidDataset", ...
        "%s", strjoin(report.errors, " | "));
end
[coefficient, delayS, pathValid, derivation] = canonicalCir(channelDataset);
shape = size5(coefficient);
delaySpread = zeros(0, 1);
kFactorDb = zeros(0, 1);
significantCount = zeros(0, 1);
for sample = 1:shape(5)
    for time = 1:shape(4)
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
        significantCount(end + 1, 1) = sum( ...
            pathPower >= strongest * 10^(-20 / 10)); %#ok<AGROW>
    end
end
if isempty(kFactorDb) || isempty(significantCount)
    error("estimate_local_p8_observables:InsufficientObservations", ...
        "Known-only local samples do not contain usable power observations.");
end

logDelay = log10(max(delaySpread, 1e-9));
delayValue = NaN;
if ~isempty(logDelay)
    delayValue = bounded(median(logDelay), -9, -5);
end
values = [delayValue, ...
    bounded(median(kFactorDb), -20, 30), ...
    round(bounded(median(significantCount), 4, 30))];
dispersion = [robustSpread(logDelay) / 4, ...
    robustSpread(kFactorDb) / 50, ...
    robustSpread(significantCount) / 26];
availableNames = ["DS_mu", "KF_mu", "num_clusters"];
availableNames = availableNames(isfinite(values));
estimate = struct( ...
    "schema_version", "v3.1-local-p8-observables.1", ...
    "parameter_names", ["DS_mu", "KF_mu", "num_clusters"], ...
    "values", values, ...
    "available_parameter_names", availableNames, ...
    "unavailable_parameter_names", setdiff( ...
        ["DS_mu", "KF_mu", "num_clusters"], availableNames, "stable"), ...
    "quality_status", "PASS", ...
    "quality_score", sum(dispersion, "omitnan"), ...
    "observation_count", struct( ...
        "delay_spread", numel(delaySpread), ...
        "k_factor", numel(kFactorDb), ...
        "significant_path_count", numel(significantCount)), ...
    "derivation", derivation, ...
    "definitions", struct( ...
        "DS_mu", "median_log10_rms_delay_spread_seconds", ...
        "KF_mu", "median_dominant_to_remaining_power_ratio_db", ...
        "num_clusters", "median_count_within_20db_of_strongest"));
end

function [coefficient, delayS, pathValid, derivation] = canonicalCir(dataset)
if lower(string(dataset.domain)) == "cir"
    coefficient = dataset.cir.coefficient;
    shape = size5(coefficient);
    delayS = expandToShape(dataset.cir.delay_s, shape);
    pathValid = logical(expandToShape(dataset.cir.path_valid, shape));
    derivation = "direct_cir_paths";
    return;
end

frequencyHz = double(dataset.axes.frequency_hz(:));
if numel(frequencyHz) < 2
    error("estimate_local_p8_observables:NoFrequencyGrid", ...
        "CTF input needs at least two frequency points for delay derivation.");
end
spacing = median(diff(frequencyHz));
tolerance = max(abs(spacing) * 1e-6, eps(max(abs(frequencyHz))));
if spacing == 0 || any(abs(diff(frequencyHz) - spacing) > tolerance)
    error("estimate_local_p8_observables:NonuniformFrequencyGrid", ...
        "CTF-to-delay estimation requires a uniform frequency grid.");
end
coefficient = ifft(ifftshift(dataset.ctf.H, 3), [], 3);
shape = size5(coefficient);
delayAxis = reshape((0:(shape(3) - 1)) / ...
    (shape(3) * abs(spacing)), [1, 1, shape(3), 1, 1]);
delayS = repmat(delayAxis, [shape(1), shape(2), 1, shape(4), shape(5)]);
pathValid = true(shape);
derivation = "uniform_ctf_inverse_fft_taps";
end

function value = expandToShape(value, targetShape)
sourceShape = size5(value);
if ~all(sourceShape == 1 | sourceShape == targetShape)
    error("estimate_local_p8_observables:CannotExpand", ...
        "A CIR field cannot expand to coefficient dimensions.");
end
value = repmat(reshape(value, sourceShape), targetShape ./ sourceShape);
end

function value = robustSpread(values)
values = double(values(:));
if isempty(values)
    value = NaN;
    return;
end
value = median(abs(values - median(values)));
end

function value = bounded(value, lower, upper)
value = min(max(double(value), lower), upper);
end

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end
