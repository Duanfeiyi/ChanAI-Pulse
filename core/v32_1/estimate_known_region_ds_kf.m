function sequence = estimate_known_region_ds_kf(channelDataset, knownIndices)
%ESTIMATE_KNOWN_REGION_DS_KF Extract DS_mu/KF_mu from the known region.
%   For each known index (snapshot for Time axis, position for Space axis),
%   derive DS_mu (median log10 RMS delay spread) and KF_mu (median
%   dominant-to-diffuse ratio in dB) from the uploaded channel's known
%   region only. num_clusters is not locally identifiable per-snapshot over
%   the probed displacement and is excluded (frozen upstream).
%
%   The function never reads target-region samples.

arguments
    channelDataset (1, 1) struct
    knownIndices (:, 1) double {mustBePositive}
end

report = validate_channel_dataset(channelDataset);
if ~report.is_valid
    error("estimate_known_region_ds_kf:InvalidDataset", ...
        "%s", strjoin(report.errors, " | "));
end

knownIndices = sort(double(knownIndices(:)));
coefficient = channelDataset.cir.coefficient;
shape = [size(coefficient, 1), size(coefficient, 2), ...
    size(coefficient, 3), size(coefficient, 4), size(coefficient, 5)];
delayS = expandToShape(channelDataset.cir.delay_s, shape);
pathValid = logical(expandToShape(channelDataset.cir.path_valid, shape));

% Determine whether indices address time snapshots (Nt) or samples (N_sample).
% A dataset carrying a position axis with one value per sample means the
% indices address the sample (position) dimension; otherwise small indices
% within Nt address time snapshots.
nt = shape(4);
nSample = shape(5);
hasPositionAxis = isfield(channelDataset.axes, "sample_position_m") && ...
    size(channelDataset.axes.sample_position_m, 1) == nSample;
if hasPositionAxis
    indexDim = "sample";
elseif all(knownIndices <= nt)
    indexDim = "time";
else
    indexDim = "sample";
end

nKnown = numel(knownIndices);
values = nan(nKnown, 2);
for row = 1:nKnown
    if indexDim == "time"
        snapshot = knownIndices(row);
        [ds, kf] = snapshotObservables(coefficient, delayS, pathValid, ...
            snapshot, "time", nt, nSample);
    else
        sample = knownIndices(row);
        [ds, kf] = snapshotObservables(coefficient, delayS, pathValid, ...
            sample, "sample", nt, nSample);
    end
    values(row, :) = [ds, kf];
end

sequence = struct( ...
    "schema_version", "v3.2-4a-known-ds-kf.1", ...
    "parameter_names", ["DS_mu", "KF_mu"], ...
    "values", values, ...
    "parameter_sample_index", knownIndices, ...
    "provenance", struct( ...
        "source", "known_region_direct_channel_observables", ...
        "index_dimension", indexDim, ...
        "target_channel_samples_read", false));
end

function [dsValue, kfValue] = snapshotObservables( ...
        coefficient, delayS, pathValid, index, indexDim, nt, nSample)
delaySpread = [];
kFactorDb = [];
if indexDim == "time"
    time = index;
    sampleRange = 1:nSample;
else
    timeRange = 1:nt;
    sample = index;
end
if indexDim == "time"
    for sample = sampleRange
        [delaySpread, kFactorDb] = accumulate( ...
            coefficient, delayS, pathValid, time, sample, ...
            delaySpread, kFactorDb);
    end
else
    for time = timeRange
        [delaySpread, kFactorDb] = accumulate( ...
            coefficient, delayS, pathValid, time, sample, ...
            delaySpread, kFactorDb);
    end
end
logDelay = log10(max(delaySpread, 1e-9));
dsValue = NaN;
if ~isempty(logDelay)
    dsValue = min(max(median(logDelay), -9), -5);
end
kfValue = NaN;
if ~isempty(kFactorDb)
    kfValue = min(max(median(kFactorDb), -30), 30);
end
end

function [delaySpread, kFactorDb] = accumulate( ...
        coefficient, delayS, pathValid, time, sample, delaySpread, kFactorDb)
snapshotPower = abs(coefficient(:, :, :, time, sample)).^2;
snapshotDelay = delayS(:, :, :, time, sample);
snapshotValid = pathValid(:, :, :, time, sample) & ...
    isfinite(snapshotPower) & snapshotPower >= 0 & isfinite(snapshotDelay);
powerVector = double(snapshotPower(snapshotValid));
delayVector = double(snapshotDelay(snapshotValid));
if ~isempty(powerVector) && sum(powerVector) > 0
    spread = compute_delay_spread(delayVector, powerVector);
    if isfinite(spread) && spread > 0
        delaySpread(end + 1, 1) = spread; %#ok<AGROW>
    end
end
pathPower = squeeze(sum(snapshotPower, [1, 2]));
pathIsValid = squeeze(any(pathValid(:, :, :, time, sample), [1, 2]));
pathPower = double(pathPower(:));
pathIsValid = logical(pathIsValid(:)) & isfinite(pathPower) & pathPower >= 0;
pathPower = pathPower(pathIsValid);
if ~isempty(pathPower) && sum(pathPower) > 0
    strongest = max(pathPower);
    diffuse = max(sum(pathPower) - strongest, realmin("double"));
    kFactorDb(end + 1, 1) = 10 * log10(strongest / diffuse); %#ok<AGROW>
end
end

function value = expandToShape(value, targetShape)
sourceShape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
if ~all(sourceShape == 1 | sourceShape == targetShape)
    error("estimate_known_region_ds_kf:CannotExpand", ...
        "A CIR field cannot expand to coefficient dimensions.");
end
value = repmat(reshape(value, sourceShape), targetShape ./ sourceShape);
end
