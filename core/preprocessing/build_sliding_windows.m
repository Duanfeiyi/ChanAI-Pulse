function [inputs, targets, metadata] = build_sliding_windows(sequence, windowLength, horizon)
%BUILD_SLIDING_WINDOWS Build chronological prediction samples from DPSD data.
%   sequence is [record, feature]. inputs is [sample, feature, time].

arguments
    sequence {mustBeNumeric, mustBeNonempty}
    windowLength (1, 1) double {mustBeInteger, mustBePositive}
    horizon (1, 1) double {mustBeInteger, mustBePositive} = 1
end

if ndims(sequence) ~= 2
    error("build_sliding_windows:InvalidDimensions", "Sequence must be a two-dimensional [record, feature] matrix.");
end

[recordCount, featureCount] = size(sequence);
sampleCount = recordCount - windowLength - horizon + 1;
if sampleCount < 1
    error("build_sliding_windows:InsufficientRecords", ...
        "Need at least windowLength + horizon records.");
end

inputs = zeros(sampleCount, featureCount, windowLength, "like", sequence);
targets = zeros(sampleCount, featureCount, "like", sequence);
targetIndices = zeros(sampleCount, 1);

for sampleIdx = 1:sampleCount
    window = sequence(sampleIdx:(sampleIdx + windowLength - 1), :);
    inputs(sampleIdx, :, :) = reshape(window.', 1, featureCount, windowLength);
    targetIndex = sampleIdx + windowLength + horizon - 1;
    targets(sampleIdx, :) = sequence(targetIndex, :);
    targetIndices(sampleIdx) = targetIndex;
end

metadata = struct();
metadata.window_length = windowLength;
metadata.horizon = horizon;
metadata.sample_count = sampleCount;
metadata.target_indices = targetIndices;
end

