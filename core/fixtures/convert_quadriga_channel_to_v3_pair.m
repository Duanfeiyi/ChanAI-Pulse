function pair = convert_quadriga_channel_to_v3_pair( ...
    qdChannel, frequencyHz, samplePositionM, metadata)
%CONVERT_QUADRIGA_CHANNEL_TO_V3_PAIR Adapt one QuaDRiGa channel externally.
%   PAIR = CONVERT_QUADRIGA_CHANNEL_TO_V3_PAIR(CHANNEL, FREQUENCYHZ,
%   SAMPLEPOSITIONM, METADATA) converts qd_channel.coeff and .delay to the
%   ChanAI Pulse v3 CIR/CTF contract. QuaDRiGa uses
%   [Rx, Tx, path, snapshot]; ChanAI Pulse uses
%   [Tx, Rx, Npath, Nt, N_sample]. Each QuaDRiGa snapshot is treated as one
%   ordered route sample, so Nt=1.
%
%   This adapter reads the third-party object but never modifies it.

arguments
    qdChannel (1, 1)
    frequencyHz (:, 1) double
    samplePositionM (:, :) double
    metadata (1, 1) struct
end

if ~isprop(qdChannel, "coeff") || ~isprop(qdChannel, "delay")
    error("convert_quadriga_channel_to_v3_pair:InvalidChannel", ...
        "Input must expose QuaDRiGa coeff and delay properties.");
end

sourceCoefficient = qdChannel.coeff;
sourceDelay = qdChannel.delay;
sourceShape = size4(sourceCoefficient);
rxCount = sourceShape(1);
txCount = sourceShape(2);
pathCount = sourceShape(3);
sampleCount = sourceShape(4);
if size(samplePositionM, 1) ~= sampleCount || ...
        ~ismember(size(samplePositionM, 2), [1, 2, 3])
    error("convert_quadriga_channel_to_v3_pair:InvalidPositions", ...
        "samplePositionM must be N_sample-by-1, 2, or 3.");
end

coefficient = permute(reshape(sourceCoefficient, sourceShape), ...
    [2, 1, 3, 4]);
coefficient = reshape(coefficient, ...
    [txCount, rxCount, pathCount, 1, sampleCount]);
delayS = normalizeDelay(sourceDelay, sourceShape);
pathValid = isfinite(delayS) & ...
    isfinite(real(coefficient)) & isfinite(imag(coefficient)) & ...
    abs(coefficient) > 0;

centerFrequencyHz = mean(frequencyHz);
frequencyOffsetsHz = frequencyHz - centerFrequencyHz;
axesCommon = struct( ...
    "sample_index", (1:sampleCount).', ...
    "sample_position_m", samplePositionM, ...
    "time_s", 0);
metadata.source = "QuaDRiGa";
metadata.sample_semantics = "ordered_route";
metadata.center_frequency_hz = centerFrequencyHz;
if numel(frequencyHz) > 1
    metadata.subcarrier_spacing_hz = median(diff(frequencyHz));
end
if ~isfield(metadata, "created_utc")
    metadata.created_utc = "2026-07-29T00:00:00Z";
end

cirPayload = struct( ...
    "coefficient", coefficient, ...
    "delay_s", delayS, ...
    "path_valid", pathValid);
cirDataset = create_channel_dataset("cir", cirPayload, ...
    axesCommon, metadata);
H = cir_to_ctf(coefficient, delayS, frequencyOffsetsHz);
ctfAxes = axesCommon;
ctfAxes.frequency_hz = frequencyHz;
ctfDataset = create_channel_dataset("ctf", struct("H", H), ...
    ctfAxes, metadata);

pair = struct("cir", cirDataset, "ctf", ctfDataset);
end

function delayS = normalizeDelay(sourceDelay, coefficientShape)
delayShape = size4(sourceDelay);
if delayShape(1) == coefficientShape(1) && ...
        delayShape(2) == coefficientShape(2) && ...
        delayShape(3) == coefficientShape(3) && ...
        delayShape(4) == coefficientShape(4)
    delayS = permute(reshape(sourceDelay, delayShape), [2, 1, 3, 4]);
elseif size(sourceDelay, 1) == coefficientShape(3) && ...
        size(sourceDelay, 2) == coefficientShape(4)
    delayS = reshape(sourceDelay, ...
        [1, 1, coefficientShape(3), coefficientShape(4)]);
else
    error("convert_quadriga_channel_to_v3_pair:UnsupportedDelayShape", ...
        "Unsupported QuaDRiGa delay shape [%s].", ...
        join(string(delayShape), " "));
end
delayS = reshape(delayS, ...
    [size(delayS, 1), size(delayS, 2), ...
    coefficientShape(3), 1, coefficientShape(4)]);
end

function shape = size4(value)
shape = [size(value, 1), size(value, 2), ...
    size(value, 3), size(value, 4)];
end
