function capabilities = infer_channel_capabilities(dataset)
%INFER_CHANNEL_CAPABILITIES Report which channel plots data can support.
%   This function reports capabilities only. Scientific calculations and
%   plot rendering remain separate concerns.

arguments
    dataset (1, 1) struct
end

dims = dataset.dimensions;
domain = lower(string(dataset.domain));
hasFrequency = dims.Nf > 1 && ( ...
    hasAxis(dataset.axes, "frequency_hz", dims.Nf) || ...
    hasFrequencyMetadata(dataset.metadata));
hasTime = dims.Nt > 1 && ( ...
    hasAxis(dataset.axes, "time_s", dims.Nt) || ...
    isPositiveScalarField(dataset.metadata, "snapshot_interval_s"));
hasMultipleSamples = dims.N_sample > 1;
hasOrderedSamples = hasMultipleSamples && isOrderedSampleSet(dataset);
hasArray = dims.Tx > 1 || dims.Rx > 1;
hasAngle = domain == "cir" && ( ...
    isfield(dataset.cir, "aoa_rad") || isfield(dataset.cir, "aod_rad"));
% A single unresolved tap is the narrowband CIR representation. Merely
% having a delay field must not upgrade that fixture to wideband.
hasPathDelay = domain == "cir" && dims.Npath > 1 && ...
    isfield(dataset.cir, "delay_s") && ...
    isfield(dataset.cir, "path_valid");
hasWideband = hasFrequency || hasPathDelay;

capabilities = struct();
capabilities.classification = classifyData(dims, hasWideband, hasTime);
capabilities.power = true;
capabilities.pdp = hasWideband;
capabilities.frequency_autocorrelation = hasFrequency;
capabilities.delay_spread_cdf = hasWideband && hasMultipleSamples;
capabilities.angular_power_spectrum = hasArray && hasAngle;
capabilities.spatial_correlation = hasArray && ...
    (dims.Nt * dims.N_sample > 1);
capabilities.angular_spread_cdf = hasArray && hasAngle && hasMultipleSamples;
capabilities.doppler_power_spectrum = hasTime;
capabilities.time_autocorrelation = hasTime;
capabilities.doppler_spread_cdf = hasTime && hasMultipleSamples;
capabilities.delay_sample_heatmap = hasWideband && hasOrderedSamples;
capabilities.cdf_minimum_met = dims.N_sample >= 2;
capabilities.cdf_recommended_sample_count = 20;
capabilities.cdf_recommended_met = dims.N_sample >= ...
    capabilities.cdf_recommended_sample_count;

capabilities.reasons = struct();
capabilities.reasons.frequency = capabilityReason(hasFrequency, ...
    "Frequency axis is available.", ...
    "Need Nf > 1 plus frequency_hz or center/subcarrier spacing.");
capabilities.reasons.time = capabilityReason(hasTime, ...
    "Continuous time information is available.", ...
    "Need Nt > 1 plus time_s or snapshot_interval_s.");
capabilities.reasons.angle = capabilityReason(hasAngle, ...
    "Path angle information is available.", ...
    "Need CIR aoa_rad or aod_rad for angle-domain plots.");
capabilities.reasons.sample_statistics = capabilityReason(hasMultipleSamples, ...
    "Multiple samples are available.", ...
    "Need N_sample > 1 for an empirical distribution.");
capabilities.reasons.ordered_heatmap = capabilityReason(hasOrderedSamples, ...
    "Samples have declared physical order.", ...
    "Heatmaps need ordered sample semantics, not independent samples.");
end

function classification = classifyData(dims, hasWideband, hasTime)
hasArray = dims.Tx > 1 || dims.Rx > 1;
if ~hasWideband && ~hasTime && ~hasArray
    classification = "narrowband_static_siso";
elseif hasWideband && ~hasTime && ~hasArray
    classification = "wideband_static_siso";
elseif hasWideband && ~hasTime && hasArray
    classification = "wideband_static_mimo";
elseif hasWideband && hasTime && hasArray
    classification = "wideband_dynamic_mimo";
elseif hasTime
    classification = "dynamic_channel";
else
    classification = "other_channel";
end
end

function tf = hasAxis(axes, fieldName, expectedLength)
tf = isfield(axes, fieldName) && isnumeric(axes.(fieldName)) && ...
    isvector(axes.(fieldName)) && numel(axes.(fieldName)) == expectedLength;
end

function tf = hasFrequencyMetadata(metadata)
tf = isPositiveScalarField(metadata, "center_frequency_hz") && ...
    isPositiveScalarField(metadata, "subcarrier_spacing_hz");
end

function tf = isPositiveScalarField(value, fieldName)
tf = isfield(value, fieldName) && isnumeric(value.(fieldName)) && ...
    isscalar(value.(fieldName)) && isfinite(value.(fieldName)) && ...
    value.(fieldName) > 0;
end

function tf = isOrderedSampleSet(dataset)
if ~isfield(dataset.metadata, "sample_semantics")
    tf = false;
    return;
end
semantics = lower(string(dataset.metadata.sample_semantics));
tf = ismember(semantics, ...
    ["ordered_route", "ordered_time", "ordered_frequency", "other_ordered"]);
end

function message = capabilityReason(isAvailable, yesMessage, noMessage)
if isAvailable
    message = yesMessage;
else
    message = noMessage;
end
end
