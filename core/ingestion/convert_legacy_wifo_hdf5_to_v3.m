function result = convert_legacy_wifo_hdf5_to_v3( ...
        inputFile, outputFile, options)
%CONVERT_LEGACY_WIFO_HDF5_TO_V3 Convert known legacy 3D_CSI layout to CIR.
%   OPTIONS.sequence_axis must be "sample" or "time"; the converter will
%   not guess whether the legacy fourth dimension is route samples or a
%   continuous time axis. A time conversion also requires time_s or
%   snapshot_interval_s.

arguments
    inputFile (1, 1) string
    outputFile (1, 1) string
    options (1, 1) struct = struct()
end

if ~isfile(inputFile)
    error("convert_legacy_wifo_hdf5_to_v3:MissingInput", ...
        "Legacy WiFo HDF5 file does not exist: %s", inputFile);
end
validateOutputPath(outputFile);
requiredPaths = ["/csi/real", "/csi/imag", "/delay"];
for datasetPath = requiredPaths
    if ~datasetExists(inputFile, datasetPath)
        error("convert_legacy_wifo_hdf5_to_v3:MissingDataset", ...
            "Legacy WiFo input is missing %s.", datasetPath);
    end
end

sequenceAxis = lower(strtrim(string(getOption( ...
    options, "sequence_axis", ""))));
if ~ismember(sequenceAxis, ["sample", "time"])
    error("convert_legacy_wifo_hdf5_to_v3:MissingSequenceMeaning", ...
        "Set options.sequence_axis to 'sample' or 'time'; " + ...
        "the legacy layout is scientifically ambiguous.");
end

realPart = h5read(inputFile, "/csi/real");
imagPart = h5read(inputFile, "/csi/imag");
if ~isequal(size(realPart), size(imagPart))
    error("convert_legacy_wifo_hdf5_to_v3:ComplexShapeMismatch", ...
        "Legacy /csi/real and /csi/imag sizes do not match.");
end
if ndims(realPart) ~= 4
    error("convert_legacy_wifo_hdf5_to_v3:UnexpectedCSIShape", ...
        "Legacy CSI must have [Tx, Rx, Npath, sequence] dimensions.");
end

legacyShape = [size(realPart, 1), size(realPart, 2), ...
    size(realPart, 3), size(realPart, 4)];
coefficient4 = complex(realPart, imagPart);
delay = double(h5read(inputFile, "/delay"));
if numel(delay) ~= legacyShape(3)
    error("convert_legacy_wifo_hdf5_to_v3:DelayCountMismatch", ...
        "Legacy delay count does not match the path dimension.");
end
delayS = reshape(delay(:), [1, 1, legacyShape(3), 1, 1]);
pathValid = true(1, 1, legacyShape(3), 1, 1);

axes = struct();
metadata = baseMetadata(inputFile, options);
if sequenceAxis == "sample"
    coefficient = reshape(coefficient4, ...
        [legacyShape(1:3), 1, legacyShape(4)]);
    axes.sample_index = (1:legacyShape(4)).';
    metadata.sample_semantics = string(getOption( ...
        options, "sample_semantics", "ordered_route"));
    if isfield(options, "sample_position_m") && ...
            ~isempty(options.sample_position_m)
        positions = options.sample_position_m;
        if ~isnumeric(positions) || ...
                size(positions, 1) ~= legacyShape(4) || ...
                ~ismember(size(positions, 2), [1, 2, 3])
            error("convert_legacy_wifo_hdf5_to_v3:InvalidPositions", ...
                "sample_position_m must have one row per legacy sequence value.");
        end
        axes.sample_position_m = positions;
    end
else
    coefficient = reshape(coefficient4, ...
        [legacyShape(1:3), legacyShape(4), 1]);
    axes.sample_index = 1;
    if isfield(options, "time_s") && ~isempty(options.time_s)
        timeS = double(options.time_s(:));
        if numel(timeS) ~= legacyShape(4)
            error("convert_legacy_wifo_hdf5_to_v3:TimeCountMismatch", ...
                "time_s must contain one value per legacy sequence value.");
        end
    elseif isfield(options, "snapshot_interval_s")
        intervalS = double(options.snapshot_interval_s);
        if ~isscalar(intervalS) || ~isfinite(intervalS) || intervalS <= 0
            error("convert_legacy_wifo_hdf5_to_v3:InvalidTimeStep", ...
                "snapshot_interval_s must be a positive finite scalar.");
        end
        timeS = (0:(legacyShape(4) - 1)).' * intervalS;
        metadata.snapshot_interval_s = intervalS;
    else
        error("convert_legacy_wifo_hdf5_to_v3:MissingTimeAxis", ...
            "Time conversion requires time_s or snapshot_interval_s.");
    end
    axes.time_s = timeS;
    metadata.sample_semantics = "independent";
end

payload = struct( ...
    "coefficient", coefficient, ...
    "delay_s", delayS, ...
    "path_valid", pathValid);
if datasetExists(inputFile, "/doppler")
    doppler = double(h5read(inputFile, "/doppler"));
    if numel(doppler) == legacyShape(3)
        payload.doppler_hz = reshape(doppler(:), ...
            [1, 1, legacyShape(3), 1, 1]);
    end
end

dataset = create_channel_dataset("cir", payload, axes, metadata);
validation = validate_channel_dataset(dataset);
if ~validation.is_valid
    error("convert_legacy_wifo_hdf5_to_v3:InvalidConvertedDataset", ...
        "Converted WiFo dataset failed validation: %s", ...
        strjoin(validation.errors, " | "));
end
write_channel_dataset_hdf5(outputFile, dataset);

warnings = string(validation.warnings(:));
if attributeExists(inputFile, "/", "n_subcarriers")
    warnings(end + 1, 1) = ...
        "Legacy n_subcarriers is metadata only; /csi third dimension " + ...
        "contains paths, so the output is CIR rather than CTF.";
end

result = struct();
result.status = validation.status;
result.dataset = dataset;
result.validation = validation;
result.capabilities = infer_channel_capabilities(dataset);
result.output_file = outputFile;
result.source_file_unchanged = true;
result.conversion_warnings = warnings;
end

function metadata = baseMetadata(inputFile, options)
[~, baseName, extension] = fileparts(inputFile);
metadata = struct();
metadata.source = "legacy_wifo:" + string(getOption( ...
    options, "source_id", baseName + extension));
metadata.converter = "convert_legacy_wifo_hdf5_to_v3";
metadata.legacy_layout = "Tx_Rx_Npath_sequence";
metadata.delay_unit_source = "s";

copyAttributes = [ ...
    "center_freq", "bandwidth", "n_subcarriers", ...
    "dataset_id", "scenario", "creation_date"];
for attributeName = copyAttributes
    if attributeExists(inputFile, "/", attributeName)
        value = h5readatt(inputFile, "/", attributeName);
        targetName = matlab.lang.makeValidName(char(attributeName));
        metadata.(targetName) = normalizeAttribute(value);
    end
end
if isfield(metadata, "center_freq")
    metadata.center_frequency_hz = double(metadata.center_freq);
end
if isfield(metadata, "bandwidth")
    metadata.bandwidth_hz = double(metadata.bandwidth);
end
end

function value = normalizeAttribute(value)
if ischar(value) || isstring(value)
    value = string(value);
elseif isnumeric(value) && isscalar(value)
    value = double(value);
end
end

function validateOutputPath(outputFile)
[folder, ~, extension] = fileparts(outputFile);
if lower(string(extension)) ~= ".h5"
    error("convert_legacy_wifo_hdf5_to_v3:InvalidOutputExtension", ...
        "Output file must use the .h5 extension.");
end
if folder ~= "" && ~isfolder(folder)
    error("convert_legacy_wifo_hdf5_to_v3:MissingOutputFolder", ...
        "Output folder does not exist: %s", folder);
end
if isfile(outputFile)
    error("convert_legacy_wifo_hdf5_to_v3:OutputExists", ...
        "Refusing to overwrite existing output: %s", outputFile);
end
end

function exists = datasetExists(filePath, datasetPath)
try
    h5info(filePath, datasetPath);
    exists = true;
catch
    exists = false;
end
end

function exists = attributeExists(filePath, objectPath, attributeName)
try
    h5readatt(filePath, objectPath, attributeName);
    exists = true;
catch
    exists = false;
end
end

function value = getOption(options, fieldName, defaultValue)
if isfield(options, fieldName)
    value = options.(fieldName);
else
    value = defaultValue;
end
end
