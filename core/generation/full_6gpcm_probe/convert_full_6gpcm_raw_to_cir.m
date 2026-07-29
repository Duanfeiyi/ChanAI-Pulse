function dataset = convert_full_6gpcm_raw_to_cir(HAll, delayAll, metadata)
%CONVERT_FULL_6GPCM_RAW_TO_CIR Convert Step 3 raw cells to v3 CIR.
%   Raw generate_channel_v1 cells use [Tx, Rx, Nt, Npath]. The canonical
%   ChanAI Pulse CIR uses [Tx, Rx, Npath, Nt, N_sample].

if ~iscell(HAll) || ~iscell(delayAll) || isempty(HAll) || ...
        numel(HAll) ~= numel(delayAll)
    error("convert_full_6gpcm_raw_to_cir:InvalidCells", ...
        "HAll and delayAll must be nonempty cell arrays of equal length.");
end
if nargin < 3 || ~isstruct(metadata) || ~isscalar(metadata)
    error("convert_full_6gpcm_raw_to_cir:InvalidMetadata", ...
        "metadata must be a scalar struct.");
end

sampleCount = numel(HAll);
rawShapes = zeros(sampleCount, 4);
for sample = 1:sampleCount
    H = HAll{sample};
    delayS = delayAll{sample};
    if ~isnumeric(H) || isempty(H) || ndims(H) > 4
        error("convert_full_6gpcm_raw_to_cir:InvalidH", ...
            "HAll{%d} must be a nonempty numeric array with at most four dimensions.", ...
            sample);
    end
    if ~isnumeric(delayS) || ~isreal(delayS) || isempty(delayS) || ...
            ndims(delayS) > 4
        error("convert_full_6gpcm_raw_to_cir:InvalidDelay", ...
            "delayAll{%d} must be a nonempty real array with at most four dimensions.", ...
            sample);
    end
    rawShapes(sample, :) = size4(H);
    if ~isequal(rawShapes(sample, :), size4(delayS))
        error("convert_full_6gpcm_raw_to_cir:ShapeMismatch", ...
            "HAll{%d} and delayAll{%d} must have identical raw shapes.", ...
            sample, sample);
    end
    if isreal(H) || any(~isfinite(real(H(:)))) || ...
            any(~isfinite(imag(H(:))))
        error("convert_full_6gpcm_raw_to_cir:InvalidCoefficient", ...
            "HAll{%d} must contain finite complex coefficients.", sample);
    end
    if any(~isfinite(delayS(:))) || any(delayS(:) < 0)
        error("convert_full_6gpcm_raw_to_cir:InvalidDelay", ...
            "delayAll{%d} must contain finite nonnegative seconds.", sample);
    end
end

reference = rawShapes(1, [1, 2, 3]);
if any(any(rawShapes(:, [1, 2, 3]) ~= reference, 2))
    error("convert_full_6gpcm_raw_to_cir:InconsistentDimensions", ...
        "All samples must use the same Tx, Rx, and Nt dimensions.");
end

txCount = reference(1);
rxCount = reference(2);
timeCount = reference(3);
maxPathCount = max(rawShapes(:, 4));
canonicalShape = [txCount, rxCount, maxPathCount, timeCount, sampleCount];
coefficient = complex(zeros(canonicalShape, "like", real(HAll{1})));
delayS = zeros(canonicalShape, "like", delayAll{1});
pathValid = false(canonicalShape);

for sample = 1:sampleCount
    pathCount = rawShapes(sample, 4);
    canonicalH = permute(reshape(HAll{sample}, rawShapes(sample, :)), ...
        [1, 2, 4, 3]);
    canonicalDelay = permute( ...
        reshape(delayAll{sample}, rawShapes(sample, :)), [1, 2, 4, 3]);
    coefficient(:, :, 1:pathCount, :, sample) = canonicalH;
    delayS(:, :, 1:pathCount, :, sample) = canonicalDelay;
    pathValid(:, :, 1:pathCount, :, sample) = true;
end

metadata.sample_semantics = "independent";
metadata.raw_dimension_order = ["Tx", "Rx", "Nt", "Npath"];
metadata.raw_sample_container = "cell_array";
axes = struct("sample_index", (1:sampleCount).');
if isfield(metadata, "snapshot_interval_s") && ...
        isnumeric(metadata.snapshot_interval_s) && ...
        isscalar(metadata.snapshot_interval_s) && ...
        isfinite(metadata.snapshot_interval_s) && ...
        metadata.snapshot_interval_s > 0
    axes.time_s = (0:timeCount - 1).' * metadata.snapshot_interval_s;
end

payload = struct( ...
    "coefficient", coefficient, ...
    "delay_s", delayS, ...
    "path_valid", pathValid);
dataset = create_channel_dataset("cir", payload, axes, metadata);
end

function shape = size4(value)
shape = [size(value, 1), size(value, 2), ...
    size(value, 3), size(value, 4)];
end
