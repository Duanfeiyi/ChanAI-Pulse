function dataset = collapse_cir_to_narrowband(dataset)
%COLLAPSE_CIR_TO_NARROWBAND Convert resolved paths to one unresolved tap.
%   The equivalent coefficient is the complex baseband response at the
%   reference frequency (sum of valid path coefficients). Tx/Rx/Nt and
%   N_sample are preserved; delay resolution and path-angle fields are not
%   claimed after the conversion.

arguments
    dataset (1, 1) struct
end

report = validate_channel_dataset(dataset);
if ~report.is_valid || string(dataset.domain) ~= "cir"
    error("collapse_cir_to_narrowband:InvalidCIR", ...
        "Input must be a valid canonical CIR dataset.");
end
shape = size5(dataset.cir.coefficient);
valid = expandField(dataset.cir.path_valid, shape);
coefficient = dataset.cir.coefficient;
coefficient(~valid) = 0;
equivalent = sum(coefficient, 3);
delayS = zeros(size(equivalent));
pathValid = true(size(equivalent));
payload = struct( ...
    "coefficient", equivalent, ...
    "delay_s", delayS, ...
    "path_valid", pathValid);
metadata = dataset.metadata;
metadata.output_profile = "narrowband_unresolved_tap";
metadata.original_npath = shape(3);
metadata.path_collapse_rule = ...
    "complex sum of valid baseband path coefficients";
dataset = create_channel_dataset("cir", payload, dataset.axes, metadata);
end

function expanded = expandField(value, targetSize)
sourceSize = size5(value);
if ~all(sourceSize == 1 | sourceSize == targetSize)
    error("collapse_cir_to_narrowband:CannotExpand", ...
        "path_valid cannot expand to CIR coefficient dimensions.");
end
expanded = repmat(reshape(value, sourceSize), targetSize ./ sourceSize);
end

function shape = size5(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end
