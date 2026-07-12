function data = denormalize_samples(normalized, params)
%DENORMALIZE_SAMPLES Restore data normalized by normalize_samples.

if ~isstruct(params) || ~isfield(params, "sample_min") || ~isfield(params, "sample_range")
    error("denormalize_samples:InvalidParams", "Normalization parameters are incomplete.");
end

sampleCount = size(normalized, 1);
if numel(params.sample_min) ~= sampleCount || numel(params.sample_range) ~= sampleCount
    error("denormalize_samples:SizeMismatch", "Normalization parameters do not match sample count.");
end

flat = reshape(double(normalized), sampleCount, []);
dataFlat = flat .* params.sample_range + params.sample_min;
data = reshape(dataFlat, size(normalized));
end

