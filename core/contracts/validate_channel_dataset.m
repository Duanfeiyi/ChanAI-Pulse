function report = validate_channel_dataset(dataset)
%VALIDATE_CHANNEL_DATASET Validate a ChanAI Pulse v3 channel-data struct.
%   REPORT = VALIDATE_CHANNEL_DATASET(DATASET) is read-only. REPORT.status is
%   PASS, WARNING, or FAIL, with concrete errors and warnings.

report = struct( ...
    "is_valid", true, ...
    "status", "PASS", ...
    "errors", strings(0, 1), ...
    "warnings", strings(0, 1));

if ~isstruct(dataset) || ~isscalar(dataset)
    report = addError(report, "Dataset must be a scalar struct.");
    report = finalize(report);
    return;
end

requiredTopFields = ["schema_version", "domain", "dimension_order", ...
    "dimensions", "units", "axes", "metadata"];
for fieldName = requiredTopFields
    if ~isfield(dataset, fieldName)
        report = addError(report, "Missing top-level field: " + fieldName);
    end
end
if ~isempty(report.errors)
    report = finalize(report);
    return;
end

domain = lower(string(dataset.domain));
if ~ismember(domain, ["ctf", "cir"])
    report = addError(report, "domain must be 'ctf' or 'cir'.");
    report = finalize(report);
    return;
end

report = validateUnits(report, dataset.units);
report = validateMetadata(report, dataset.metadata);

if domain == "ctf"
    report = validateCTF(report, dataset);
else
    report = validateCIR(report, dataset);
end

report = validateAxes(report, dataset);
report = finalize(report);
end

function report = validateCTF(report, dataset)
expectedOrder = ["Tx", "Rx", "Nf", "Nt", "N_sample"];
if ~isequal(string(dataset.dimension_order(:)).', expectedOrder)
    report = addError(report, ...
        "CTF dimension_order must be Tx, Rx, Nf, Nt, N_sample.");
end
if ~isfield(dataset, "ctf") || ~isstruct(dataset.ctf) || ...
        ~isfield(dataset.ctf, "H")
    report = addError(report, "CTF dataset must contain dataset.ctf.H.");
    return;
end

H = dataset.ctf.H;
if ~isnumeric(H) || isempty(H) || ndims(H) > 5
    report = addError(report, ...
        "dataset.ctf.H must be a nonempty numeric array with at most five dimensions.");
    return;
end
if any(~isfinite(real(H(:)))) || any(~isfinite(imag(H(:))))
    report = addError(report, "dataset.ctf.H contains NaN or Inf.");
end
if isreal(H)
    report = addWarning(report, ...
        "dataset.ctf.H is real-valued; a complex CTF is expected for full channel information.");
end

shape = fiveDimensionalSize(H);
report = compareDimension(report, dataset.dimensions, "Tx", shape(1));
report = compareDimension(report, dataset.dimensions, "Rx", shape(2));
report = compareDimension(report, dataset.dimensions, "Nf", shape(3));
report = compareDimension(report, dataset.dimensions, "Nt", shape(4));
report = compareDimension(report, dataset.dimensions, "N_sample", shape(5));
end

function report = validateCIR(report, dataset)
expectedOrder = ["Tx", "Rx", "Npath", "Nt", "N_sample"];
if ~isequal(string(dataset.dimension_order(:)).', expectedOrder)
    report = addError(report, ...
        "CIR dimension_order must be Tx, Rx, Npath, Nt, N_sample.");
end
if ~isfield(dataset, "cir") || ~isstruct(dataset.cir)
    report = addError(report, "CIR dataset must contain dataset.cir.");
    return;
end

requiredFields = ["coefficient", "delay_s", "path_valid"];
for fieldName = requiredFields
    if ~isfield(dataset.cir, fieldName)
        report = addError(report, "Missing CIR field: cir." + fieldName);
    end
end
if ~isempty(report.errors)
    return;
end

coefficient = dataset.cir.coefficient;
delayS = dataset.cir.delay_s;
pathValid = dataset.cir.path_valid;
if ~isnumeric(coefficient) || isempty(coefficient) || ndims(coefficient) > 5
    report = addError(report, ...
        "cir.coefficient must be a nonempty numeric array with at most five dimensions.");
    return;
end
if ~isnumeric(delayS) || ~isreal(delayS) || isempty(delayS) || ndims(delayS) > 5
    report = addError(report, ...
        "cir.delay_s must be a nonempty real numeric array with at most five dimensions.");
    return;
end
if ~islogical(pathValid) && ~isnumeric(pathValid)
    report = addError(report, "cir.path_valid must be logical or numeric.");
    return;
end

shape = fiveDimensionalSize(coefficient);
delayShape = fiveDimensionalSize(delayS);
validShape = fiveDimensionalSize(pathValid);
if ~isBroadcastable(delayShape, shape)
    report = addError(report, ...
        "cir.delay_s dimensions cannot expand to cir.coefficient dimensions.");
    return;
end
if ~isBroadcastable(validShape, shape)
    report = addError(report, ...
        "cir.path_valid dimensions cannot expand to cir.coefficient dimensions.");
    return;
end

expandedDelay = expandToSize(delayS, shape);
expandedValid = logical(expandToSize(pathValid, shape));
validCoefficient = coefficient(expandedValid);
validDelay = expandedDelay(expandedValid);
if isempty(validCoefficient)
    report = addError(report, "CIR contains no valid paths.");
else
    if any(~isfinite(real(validCoefficient))) || ...
            any(~isfinite(imag(validCoefficient)))
        report = addError(report, ...
            "Valid CIR paths contain non-finite complex coefficients.");
    end
    if any(~isfinite(validDelay)) || any(validDelay < 0)
        report = addError(report, ...
            "Valid CIR paths must have finite, nonnegative delay_s values.");
    end
end
if isreal(coefficient)
    report = addWarning(report, ...
        "cir.coefficient is real-valued; complex path coefficients are expected.");
end

report = compareDimension(report, dataset.dimensions, "Tx", shape(1));
report = compareDimension(report, dataset.dimensions, "Rx", shape(2));
report = compareDimension(report, dataset.dimensions, "Npath", shape(3));
report = compareDimension(report, dataset.dimensions, "Nt", shape(4));
report = compareDimension(report, dataset.dimensions, "N_sample", shape(5));

optionalPathFields = ["aoa_rad", "aod_rad", "doppler_hz"];
for fieldName = optionalPathFields
    if isfield(dataset.cir, fieldName)
        optionalShape = fiveDimensionalSize(dataset.cir.(fieldName));
        if ~isBroadcastable(optionalShape, shape)
            report = addError(report, ...
                "cir." + fieldName + " dimensions cannot expand to coefficient dimensions.");
        end
    end
end
end

function report = validateAxes(report, dataset)
dims = dataset.dimensions;
axes = dataset.axes;
metadata = dataset.metadata;

if isfield(axes, "frequency_hz")
    report = validateAxisVector(report, axes.frequency_hz, dims.Nf, ...
        "axes.frequency_hz", true);
elseif dims.Nf > 1 && ~hasFrequencyDefinition(metadata)
    report = addWarning(report, ...
        "Nf > 1 but no frequency_hz axis or center/subcarrier spacing is available.");
end

if isfield(axes, "time_s")
    report = validateAxisVector(report, axes.time_s, dims.Nt, ...
        "axes.time_s", true);
elseif dims.Nt > 1 && ~isPositiveScalarField(metadata, "snapshot_interval_s")
    report = addWarning(report, ...
        "Nt > 1 but no time_s axis or snapshot_interval_s is available.");
end

if isfield(axes, "sample_index")
    report = validateAxisVector(report, axes.sample_index, dims.N_sample, ...
        "axes.sample_index", false);
else
    report = addWarning(report, "axes.sample_index is missing.");
end

if isfield(axes, "sample_position_m")
    positionSize = size(axes.sample_position_m);
    if ~isnumeric(axes.sample_position_m) || ...
            positionSize(1) ~= dims.N_sample || ...
            ~ismember(positionSize(2), [1, 2, 3])
        report = addError(report, ...
            "axes.sample_position_m must be N_sample-by-1, 2, or 3.");
    end
end

sampleSemantics = "independent";
if isfield(metadata, "sample_semantics")
    sampleSemantics = lower(string(metadata.sample_semantics));
end
if sampleSemantics == "ordered_route" && ...
        ~isfield(axes, "sample_position_m")
    report = addWarning(report, ...
        "sample_semantics is ordered_route but sample_position_m is missing.");
end
end

function report = validateAxisVector(report, value, expectedLength, label, monotonic)
if ~isnumeric(value) || ~isreal(value) || ~isvector(value) || ...
        numel(value) ~= expectedLength
    report = addError(report, ...
        label + " must be a real vector with " + expectedLength + " values.");
    return;
end
if any(~isfinite(value))
    report = addError(report, label + " contains NaN or Inf.");
elseif monotonic && numel(value) > 1 && any(diff(value(:)) <= 0)
    report = addError(report, label + " must be strictly increasing.");
end
end

function report = validateUnits(report, units)
required = struct( ...
    "frequency", "Hz", "time", "s", "delay", "s", ...
    "position", "m", "angle", "rad", "power", "linear");
fieldNames = string(fieldnames(required));
for fieldName = fieldNames.'
    if ~isfield(units, fieldName)
        report = addError(report, "Missing units." + fieldName + ".");
    elseif string(units.(fieldName)) ~= string(required.(fieldName))
        report = addError(report, ...
            "units." + fieldName + " must use canonical value '" + ...
            string(required.(fieldName)) + "'.");
    end
end
end

function report = validateMetadata(report, metadata)
if ~isstruct(metadata) || ~isscalar(metadata)
    report = addError(report, "metadata must be a scalar struct.");
    return;
end
if ~isfield(metadata, "source") || ...
        ismember(lower(strtrim(string(metadata.source))), ...
        ["", "unknown", "unspecified"])
    report = addWarning(report, ...
        "metadata.source is missing or unspecified; provenance is incomplete.");
end
allowedSemantics = ["independent", "ordered_route", "ordered_time", ...
    "ordered_frequency", "other_ordered"];
if isfield(metadata, "sample_semantics") && ...
        ~ismember(lower(string(metadata.sample_semantics)), allowedSemantics)
    report = addError(report, ...
        "metadata.sample_semantics uses an unsupported value.");
end
end

function report = compareDimension(report, dimensions, fieldName, actualValue)
if ~isfield(dimensions, fieldName)
    report = addError(report, "Missing dimensions." + fieldName + ".");
elseif dimensions.(fieldName) ~= actualValue
    report = addError(report, ...
        "dimensions." + fieldName + " does not match the payload size.");
end
end

function tf = hasFrequencyDefinition(metadata)
tf = isPositiveScalarField(metadata, "center_frequency_hz") && ...
    isPositiveScalarField(metadata, "subcarrier_spacing_hz");
end

function tf = isPositiveScalarField(value, fieldName)
tf = isfield(value, fieldName) && isnumeric(value.(fieldName)) && ...
    isscalar(value.(fieldName)) && isfinite(value.(fieldName)) && ...
    value.(fieldName) > 0;
end

function shape = fiveDimensionalSize(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end

function tf = isBroadcastable(sourceSize, targetSize)
tf = all(sourceSize == 1 | sourceSize == targetSize);
end

function expanded = expandToSize(value, targetSize)
sourceSize = fiveDimensionalSize(value);
expanded = repmat(reshape(value, sourceSize), targetSize ./ sourceSize);
end

function report = addError(report, message)
report.errors(end + 1, 1) = string(message);
report.is_valid = false;
end

function report = addWarning(report, message)
report.warnings(end + 1, 1) = string(message);
end

function report = finalize(report)
if ~isempty(report.errors)
    report.status = "FAIL";
    report.is_valid = false;
elseif ~isempty(report.warnings)
    report.status = "WARNING";
    report.is_valid = true;
else
    report.status = "PASS";
    report.is_valid = true;
end
end
