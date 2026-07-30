function dataset = create_ctf_dataset_from_cir(cirDataset, frequencyHz)
%CREATE_CTF_DATASET_FROM_CIR Evaluate a canonical CIR on absolute frequencies.

arguments
    cirDataset (1, 1) struct
    frequencyHz (:, 1) double
end

validation = validate_channel_dataset(cirDataset);
if ~validation.is_valid || string(cirDataset.domain) ~= "cir"
    error("create_ctf_dataset_from_cir:InvalidCIR", ...
        "A valid v3 CIR dataset is required.");
end
if isempty(frequencyHz) || any(~isfinite(frequencyHz)) || ...
        (numel(frequencyHz) > 1 && any(diff(frequencyHz) <= 0))
    error("create_ctf_dataset_from_cir:InvalidFrequencyAxis", ...
        "frequencyHz must be a nonempty increasing finite vector.");
end
if ~isfield(cirDataset.metadata, "center_frequency_hz") || ...
        ~isscalar(cirDataset.metadata.center_frequency_hz) || ...
        ~isfinite(cirDataset.metadata.center_frequency_hz)
    error("create_ctf_dataset_from_cir:MissingCenterFrequency", ...
        "CIR metadata.center_frequency_hz is required.");
end

coefficient = cirDataset.cir.coefficient;
valid = expandLogical(cirDataset.cir.path_valid, size5(coefficient));
coefficient(~valid) = 0;
offsetHz = frequencyHz - double(cirDataset.metadata.center_frequency_hz);
H = cir_to_ctf(coefficient, cirDataset.cir.delay_s, offsetHz);

axes = struct( ...
    "frequency_hz", frequencyHz, ...
    "sample_index", cirDataset.axes.sample_index);
if isfield(cirDataset.axes, "time_s")
    axes.time_s = cirDataset.axes.time_s;
end
if isfield(cirDataset.axes, "sample_position_m")
    axes.sample_position_m = cirDataset.axes.sample_position_m;
end
metadata = cirDataset.metadata;
metadata.source = string(metadata.source) + "_ctf";
metadata.subcarrier_spacing_hz = inferSpacing(frequencyHz);
dataset = create_channel_dataset("ctf", struct("H", H), axes, metadata);
end

function value = inferSpacing(frequencyHz)
if numel(frequencyHz) > 1
    value = median(diff(frequencyHz));
else
    value = 1;
end
end

function expanded = expandLogical(value, targetSize)
sourceSize = size5(value);
if ~all(sourceSize == 1 | sourceSize == targetSize)
    error("create_ctf_dataset_from_cir:InvalidPathMask", ...
        "path_valid cannot expand to the CIR coefficient dimensions.");
end
expanded = logical(repmat(reshape(value, sourceSize), ...
    targetSize ./ sourceSize));
end

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end
