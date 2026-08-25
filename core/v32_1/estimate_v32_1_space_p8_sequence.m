function sequence = estimate_v32_1_space_p8_sequence(dataset)
%ESTIMATE_V32_1_SPACE_P8_SEQUENCE Per-position slow-varying Space observables.
%   For a Space-axis CIR route ([Tx,Rx,Npath,Nt,N_sample]), derive
%   DS_mu / KF_mu independently at each position snapshot, producing a
%   2-column observable sequence with N_sample rows. num_clusters is a
%   discrete slow variable that does not vary over short/moderate displacement,
%   so it is reported as a single frozen anchor rather than a predicted
%   per-position target (aligned with the Time-axis redefinition). The
%   remaining five P8 fields are not locally identifiable and are left to the
%   product layer to freeze.

arguments
    dataset (1, 1) struct
end

report = validate_channel_dataset(dataset);
if ~report.is_valid
    error("estimate_v32_1_space_p8_sequence:InvalidDataset", ...
        "%s", strjoin(report.errors, " | "));
end
if lower(string(dataset.domain)) ~= "cir"
    error("estimate_v32_1_space_p8_sequence:RequiresCIR", ...
        "Space-axis P8 observables require a CIR dataset.");
end

coefficient = dataset.cir.coefficient;
shape = size5(coefficient);
nSample = shape(5);
if nSample < 2
    error("estimate_v32_1_space_p8_sequence:SingleSample", ...
        "A Space-axis route needs N_sample > 1 positions.");
end

delayS = expandToShape(dataset.cir.delay_s, shape);
pathValid = logical(expandToShape(dataset.cir.path_valid, shape));

names = ["DS_mu", "KF_mu"];
values = nan(nSample, 2);
clusterCounts = nan(nSample, 1);
for sample = 1:nSample
    delaySpread = [];
    kFactorDb = [];
    significantCount = [];
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
    if isempty(kFactorDb) || isempty(significantCount)
        continue;
    end
    logDelay = log10(max(delaySpread, 1e-9));
    dsValue = NaN;
    if ~isempty(logDelay)
        dsValue = bounded(median(logDelay), -9, -5);
    end
    values(sample, :) = [dsValue, bounded(median(kFactorDb), -20, 30)];
    clusterCounts(sample, 1) = round(bounded(median(significantCount), 4, 30));
end

frozenClusterAnchor = round(bounded(median(clusterCounts, "omitnan"), 4, 30));
sequence = struct( ...
    "schema_version", "v3.2-1-space-p8-sequence.1", ...
    "parameter_names", names, ...
    "values", values, ...
    "position_sample_index", (1:nSample).', ...
    "sample_position_m", dataset.axes.sample_position_m, ...
    "quality_status", repmat("PASS", nSample, 1), ...
    "frozen_anchor", struct( ...
        "num_clusters", frozenClusterAnchor, ...
        "num_clusters_is_position_invariant", true), ...
    "provenance", struct( ...
        "source", "per_position_local_p8_observables", ...
        "derivation", "median_log10_rms_delay_spread_seconds", ...
        "kf_definition", "median_dominant_to_remaining_power_ratio_db", ...
        "num_clusters_definition", "median_count_within_20db_of_strongest", ...
        "num_clusters_position_behavior", "frozen_anchor_over_positions", ...
        "target_channel_samples_read", false, ...
        "frozen_parameter_names", ...
            ["DS_sigma", "KF_sigma", "r_DS", "LNS_ksi", "num_rays", ...
             "num_clusters"]));
end

function value = expandToShape(value, targetShape)
sourceShape = size5(value);
if ~all(sourceShape == 1 | sourceShape == targetShape)
    error("estimate_v32_1_space_p8_sequence:CannotExpand", ...
        "A CIR field cannot expand to coefficient dimensions.");
end
value = repmat(reshape(value, sourceShape), targetShape ./ sourceShape);
end

function value = bounded(value, lower, upper)
value = min(max(double(value), lower), upper);
end

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end
