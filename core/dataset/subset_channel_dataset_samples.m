function selected = subset_channel_dataset_samples(dataset, indices)
%SUBSET_CHANNEL_DATASET_SAMPLES Select ordered samples without changing source.

arguments
    dataset (1, 1) struct
    indices (:, 1) double {mustBeInteger, mustBePositive}
end

report = validate_channel_dataset(dataset);
if ~report.is_valid
    error("subset_channel_dataset_samples:InvalidDataset", ...
        "%s", strjoin(report.errors, " | "));
end
indices = double(indices(:)).';
if isempty(indices) || max(indices) > dataset.dimensions.N_sample || ...
        any(diff(indices) <= 0)
    error("subset_channel_dataset_samples:InvalidIndices", ...
        "Indices must be nonempty, strictly increasing, and within N_sample.");
end
selected = dataset;
if lower(string(dataset.domain)) == "ctf"
    selected.ctf.H = subsetFifth(selected.ctf.H, indices);
else
    for name = ["coefficient", "delay_s", "path_valid", ...
            "aoa_rad", "aod_rad", "doppler_hz"]
        if isfield(selected.cir, name)
            selected.cir.(name) = subsetFifth( ...
                selected.cir.(name), indices);
        end
    end
end
selected.dimensions.N_sample = numel(indices);
for name = string(fieldnames(selected.axes)).'
    value = selected.axes.(name);
    if isnumeric(value) && size(value, 1) == dataset.dimensions.N_sample
        selected.axes.(name) = value(indices, :);
    elseif isnumeric(value) && isvector(value) && numel(value) == ...
            dataset.dimensions.N_sample
        selected.axes.(name) = reshape(value(indices), [], 1);
    end
end
end

function output = subsetFifth(input, indices)
shape = [size(input, 1), size(input, 2), size(input, 3), ...
    size(input, 4), size(input, 5)];
if shape(5) == 1
    output = input;
    return;
end
output = input(:, :, :, :, indices);
shape(5) = numel(indices);
output = reshape(output, shape);
end
