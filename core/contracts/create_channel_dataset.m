function dataset = create_channel_dataset(domain, payload, axes, metadata)
%CREATE_CHANNEL_DATASET Build a ChanAI Pulse v3 channel-data structure.
%   DATASET = CREATE_CHANNEL_DATASET(DOMAIN, PAYLOAD, AXES, METADATA)
%   creates either:
%     CTF: H [Tx, Rx, Nf, Nt, N_sample]
%     CIR: coefficient/delay [Tx, Rx, Npath, Nt, N_sample]
%
%   DOMAIN is "ctf" or "cir". PAYLOAD is a struct containing H for CTF,
%   or coefficient and delay_s for CIR. AXES and METADATA are ordinary
%   structs. Missing optional structs may be passed as struct().

arguments
    domain (1, 1) string
    payload (1, 1) struct
    axes (1, 1) struct = struct()
    metadata (1, 1) struct = struct()
end

domain = lower(strtrim(domain));
if ~ismember(domain, ["ctf", "cir"])
    error("create_channel_dataset:UnsupportedDomain", ...
        "Domain must be 'ctf' or 'cir'.");
end

dataset = struct();
dataset.schema_version = "v3.0-data-contract.1";
dataset.domain = domain;
dataset.units = struct( ...
    "frequency", "Hz", ...
    "time", "s", ...
    "delay", "s", ...
    "position", "m", ...
    "angle", "rad", ...
    "power", "linear");
dataset.axes = axes;
dataset.metadata = addMetadataDefaults(metadata);
dataset.ctf = struct();
dataset.cir = struct();

if domain == "ctf"
    if ~isfield(payload, "H")
        error("create_channel_dataset:MissingCTF", ...
            "CTF payload must contain payload.H.");
    end

    H = normalizeFiveDimensions(payload.H, "payload.H");
    shape = fiveDimensionalSize(H);
    dataset.dimension_order = ["Tx", "Rx", "Nf", "Nt", "N_sample"];
    dataset.dimensions = struct( ...
        "Tx", shape(1), "Rx", shape(2), "Nf", shape(3), ...
        "Nt", shape(4), "N_sample", shape(5), "Npath", 0);
    dataset.ctf.H = H;
else
    requiredFields = ["coefficient", "delay_s"];
    for fieldName = requiredFields
        if ~isfield(payload, fieldName)
            error("create_channel_dataset:MissingCIRField", ...
                "CIR payload must contain payload.%s.", fieldName);
        end
    end

    coefficient = normalizeFiveDimensions(payload.coefficient, ...
        "payload.coefficient");
    delayS = normalizeFiveDimensions(payload.delay_s, "payload.delay_s");
    coefficientShape = fiveDimensionalSize(coefficient);
    delayShape = fiveDimensionalSize(delayS);
    if ~isBroadcastable(delayShape, coefficientShape)
        error("create_channel_dataset:IncompatibleDelayShape", ...
            "delay_s size [%s] cannot expand to coefficient size [%s].", ...
            join(string(delayShape), " "), join(string(coefficientShape), " "));
    end

    if isfield(payload, "path_valid")
        pathValid = normalizeFiveDimensions(payload.path_valid, ...
            "payload.path_valid");
        validShape = fiveDimensionalSize(pathValid);
        if ~isBroadcastable(validShape, coefficientShape)
            error("create_channel_dataset:IncompatiblePathMask", ...
                "path_valid size [%s] cannot expand to coefficient size [%s].", ...
                join(string(validShape), " "), ...
                join(string(coefficientShape), " "));
        end
        pathValid = logical(pathValid);
    else
        expandedDelay = expandToSize(delayS, coefficientShape);
        pathValid = isfinite(expandedDelay) & ...
            isfinite(real(coefficient)) & isfinite(imag(coefficient));
    end

    dataset.dimension_order = ["Tx", "Rx", "Npath", "Nt", "N_sample"];
    dataset.dimensions = struct( ...
        "Tx", coefficientShape(1), "Rx", coefficientShape(2), "Nf", 0, ...
        "Nt", coefficientShape(4), "N_sample", coefficientShape(5), ...
        "Npath", coefficientShape(3));
    dataset.cir.coefficient = coefficient;
    dataset.cir.delay_s = delayS;
    dataset.cir.path_valid = pathValid;

    optionalPathFields = ["aoa_rad", "aod_rad", "doppler_hz"];
    for fieldName = optionalPathFields
        if isfield(payload, fieldName)
            dataset.cir.(fieldName) = normalizeFiveDimensions( ...
                payload.(fieldName), "payload." + fieldName);
        end
    end
end

if ~isfield(dataset.axes, "sample_index")
    dataset.axes.sample_index = (1:dataset.dimensions.N_sample).';
end
end

function metadata = addMetadataDefaults(metadata)
if ~isfield(metadata, "source")
    metadata.source = "unspecified";
end
if ~isfield(metadata, "sample_semantics")
    metadata.sample_semantics = "independent";
end
if ~isfield(metadata, "created_utc")
    metadata.created_utc = string(datetime("now", ...
        "TimeZone", "UTC", "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'"));
end
end

function value = normalizeFiveDimensions(value, fieldLabel)
if ~isnumeric(value) && ~islogical(value)
    error("create_channel_dataset:InvalidPayloadType", ...
        "%s must be numeric or logical.", fieldLabel);
end
if isempty(value)
    error("create_channel_dataset:EmptyPayload", ...
        "%s must not be empty.", fieldLabel);
end
if ndims(value) > 5
    error("create_channel_dataset:TooManyDimensions", ...
        "%s has more than five dimensions.", fieldLabel);
end
shape = fiveDimensionalSize(value);
value = reshape(value, shape);
end

function shape = fiveDimensionalSize(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end

function isCompatible = isBroadcastable(sourceSize, targetSize)
isCompatible = all(sourceSize == 1 | sourceSize == targetSize);
end

function expanded = expandToSize(value, targetSize)
sourceSize = fiveDimensionalSize(value);
if ~isBroadcastable(sourceSize, targetSize)
    error("create_channel_dataset:CannotExpand", ...
        "Value cannot expand to the requested target size.");
end
expanded = repmat(value, targetSize ./ sourceSize);
end
