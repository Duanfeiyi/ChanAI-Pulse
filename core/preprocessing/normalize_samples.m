function [normalized, params] = normalize_samples(data)
%NORMALIZE_SAMPLES Apply min-max normalization independently per sample.
%   The first dimension is treated as the sample dimension. Remaining
%   dimensions are normalized together for each sample.

if ~isnumeric(data) || isempty(data)
    error("normalize_samples:InvalidInput", "Data must be a nonempty numeric array.");
end

sampleCount = size(data, 1);
flat = reshape(double(data), sampleCount, []);
sampleMin = min(flat, [], 2);
sampleMax = max(flat, [], 2);
sampleRange = sampleMax - sampleMin;
zeroRange = sampleRange == 0;
safeRange = sampleRange;
safeRange(zeroRange) = 1;

normalizedFlat = (flat - sampleMin) ./ safeRange;
normalizedFlat(zeroRange, :) = 0;
normalized = reshape(normalizedFlat, size(data));

params = struct();
params.sample_min = sampleMin;
params.sample_max = sampleMax;
params.sample_range = sampleRange;
params.zero_range = zeroRange;
params.original_size = size(data);
end

