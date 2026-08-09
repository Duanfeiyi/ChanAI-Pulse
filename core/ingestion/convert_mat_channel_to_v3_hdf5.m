function result = convert_mat_channel_to_v3_hdf5( ...
        inputFile, outputFile, mapping, options)
%CONVERT_MAT_CHANNEL_TO_V3_HDF5 Explicit, source-preserving MAT converter.
%   Ambiguous variables and dimensions are never guessed here; they must
%   already be frozen in MAPPING by inspection or the advanced UI.

arguments
    inputFile (1, 1) string
    outputFile (1, 1) string
    mapping (1, 1) struct
    options.ProgressCallback = []
    options.ChunkReadThresholdBytes (1, 1) double = 256 * 1024^2
    options.SampleChunkSize (1, 1) double = 64
end

if ~isfile(inputFile)
    error("convert_mat_channel_to_v3_hdf5:MissingInput", ...
        "Input MAT file does not exist: %s", inputFile);
end
if lower(string(fileExtension(inputFile))) ~= ".mat"
    error("convert_mat_channel_to_v3_hdf5:NotMat", ...
        "Generic MAT conversion requires a .mat input file.");
end
validateOutput(outputFile);
if isfile(outputManifestPath(outputFile))
    error("convert_mat_channel_to_v3_hdf5:ManifestExists", ...
        "Refusing to overwrite existing manifest: %s", ...
        outputManifestPath(outputFile));
end
inspection = inspect_mat_channel_source(inputFile);
validation = validate_mat_channel_mapping(mapping, inspection.variables);
if ~validation.is_valid
    error("convert_mat_channel_to_v3_hdf5:InvalidMapping", "%s", ...
        strjoin(validation.errors, " | "));
end

notify(options.ProgressCallback, 0.05, "inspection", ...
    "MAT metadata and explicit mapping validated.");
sourceHashBefore = compute_benchmark_file_sha256(inputFile);
[channel, sourceOrder, readMode] = readComplexChannel( ...
    inputFile, mapping, inspection, options);
if isreal(channel)
    error("convert_mat_channel_to_v3_hdf5:RealOnlyChannel", ...
        "A real-only array cannot represent a complete complex CIR/CTF. " + ...
        "Choose an explicit imaginary variable or a complex variable.");
end
if any(~isfinite(real(channel(:)))) || any(~isfinite(imag(channel(:))))
    error("convert_mat_channel_to_v3_hdf5:NonFiniteChannel", ...
        "The selected channel contains NaN or Inf.");
end
notify(options.ProgressCallback, 0.25, "read_payload", ...
    "Complex channel values loaded without modifying the source MAT.");

domain = lower(string(mapping.domain));
[canonical, canonicalShape] = canonicalizeChannel(channel, sourceOrder, domain);
axes = buildAxes(inputFile, mapping, canonicalShape, domain);
metadata = buildMetadata(inputFile, mapping, inspection);
metadata.converter_read_mode = readMode;
if domain == "ctf"
    payload = struct("H", canonical);
else
    delayS = buildDelay(inputFile, mapping, canonicalShape, sourceOrder);
    payload = struct("coefficient", canonical, "delay_s", delayS, ...
        "path_valid", true(1, 1, canonicalShape(3), 1, 1));
end
notify(options.ProgressCallback, 0.55, "canonicalize", ...
    "Canonical five-dimensional channel and physical axes prepared.");

dataset = create_channel_dataset(domain, payload, axes, metadata);
datasetValidation = validate_channel_dataset(dataset);
if ~datasetValidation.is_valid
    error("convert_mat_channel_to_v3_hdf5:InvalidDataset", "%s", ...
        strjoin(datasetValidation.errors, " | "));
end
capabilities = infer_channel_capabilities(dataset);
notify(options.ProgressCallback, 0.72, "write_hdf5", ...
    "Writing a new standard v3 HDF5 file.");
write_channel_dataset_hdf5(outputFile, dataset);

sourceHashAfter = compute_benchmark_file_sha256(inputFile);
if sourceHashAfter ~= sourceHashBefore
    error("convert_mat_channel_to_v3_hdf5:SourceModified", ...
        "Source MAT hash changed during conversion; the output is not trusted.");
end
manifest = conversionManifest(inputFile, outputFile, mapping, inspection, ...
    dataset, datasetValidation, capabilities, sourceHashBefore, readMode);
manifestFile = outputManifestPath(outputFile);
writeJson(manifestFile, manifest);
notify(options.ProgressCallback, 1.0, "complete", ...
    "Conversion complete; source MAT hash is unchanged.");

result = struct( ...
    "schema_version", "v3.0-mat-conversion-result.1", ...
    "status", datasetValidation.status, ...
    "output_file", outputFile, ...
    "manifest_file", manifestFile, ...
    "dataset", dataset, ...
    "validation", datasetValidation, ...
    "capabilities", capabilities, ...
    "inspection", inspection, ...
    "source_sha256", sourceHashBefore, ...
    "read_mode", readMode, ...
    "source_file_unchanged", true);
end

function [value, order, readMode] = readComplexChannel(filePath, mapping, inspection, options)
order = string(mapping.source_dimension_order(:)).';
readMode = "in_memory";
if inspection.mat_version == "v7.3" && ...
        double(inspection.payload_bytes) >= options.ChunkReadThresholdBytes && ...
        any(order == "N_sample")
    value = readComplexChannelBySampleChunks(filePath, mapping, order, ...
        max(1, round(options.SampleChunkSize)), options.ProgressCallback);
    readMode = "sample_chunked_v73";
    return;
end
if strlength(string(mapping.complex_variable)) > 0
    content = load(filePath, char(mapping.complex_variable));
    value = content.(char(mapping.complex_variable));
else
    content = load(filePath, char(mapping.real_variable), char(mapping.imag_variable));
    realPart = content.(char(mapping.real_variable));
    imagPart = content.(char(mapping.imag_variable));
    if ~isequal(size(realPart), size(imagPart))
        error("convert_mat_channel_to_v3_hdf5:ComplexShapeMismatch", ...
            "Selected real and imaginary variables have different dimensions.");
    end
    value = complex(realPart, imagPart);
end

function value = readComplexChannelBySampleChunks(filePath, mapping, order, chunkSize, callback)
source = matfile(filePath);
sampleAxis = find(order == "N_sample", 1);
if strlength(string(mapping.complex_variable)) > 0
    variableName = string(mapping.complex_variable);
    variableInfo = whos(source, char(variableName));
    sourceShape = double(variableInfo.size);
    value = complex(zeros(sourceShape, char(variableInfo.class)));
    for first = 1:chunkSize:sourceShape(sampleAxis)
        last = min(sourceShape(sampleAxis), first + chunkSize - 1);
        subscripts = repmat({':'}, 1, numel(sourceShape));
        subscripts{sampleAxis} = first:last;
        value(subscripts{:}) = source.(char(variableName))(subscripts{:});
        notify(callback, 0.08 + 0.16 * last / sourceShape(sampleAxis), ...
            "read_payload", sprintf("Reading v7.3 sample block %d:%d.", first, last));
    end
else
    realName = string(mapping.real_variable);
    imagName = string(mapping.imag_variable);
    variableInfo = whos(source, char(realName));
    sourceShape = double(variableInfo.size);
    value = complex(zeros(sourceShape, char(variableInfo.class)));
    for first = 1:chunkSize:sourceShape(sampleAxis)
        last = min(sourceShape(sampleAxis), first + chunkSize - 1);
        subscripts = repmat({':'}, 1, numel(sourceShape));
        subscripts{sampleAxis} = first:last;
        value(subscripts{:}) = complex( ...
            source.(char(realName))(subscripts{:}), ...
            source.(char(imagName))(subscripts{:}));
        notify(callback, 0.08 + 0.16 * last / sourceShape(sampleAxis), ...
            "read_payload", sprintf("Reading v7.3 sample block %d:%d.", first, last));
    end
end
end
if ~isnumeric(value) || isempty(value)
    error("convert_mat_channel_to_v3_hdf5:InvalidChannel", ...
        "Selected channel data must be a nonempty numeric array.");
end
end

function [value, targetShape] = canonicalizeChannel(value, sourceOrder, domain)
axisName = "Npath";
if domain == "ctf", axisName = "Nf"; end
targetOrder = ["Tx", "Rx", axisName, "Nt", "N_sample"];
actualSize = size(value);
if numel(actualSize) ~= numel(sourceOrder)
    error("convert_mat_channel_to_v3_hdf5:DimensionCountMismatch", ...
        "Source has %d stored dimensions but mapping declares %d.", ...
        numel(actualSize), numel(sourceOrder));
end
existingOrder = targetOrder(ismember(targetOrder, sourceOrder));
permutation = zeros(1, numel(existingOrder));
for index = 1:numel(existingOrder)
    permutation(index) = find(sourceOrder == existingOrder(index));
end
if numel(permutation) > 1
    value = permute(value, permutation);
end
existingSize = size(value);
targetShape = ones(1, 5);
for index = 1:numel(existingOrder)
    targetShape(targetOrder == existingOrder(index)) = existingSize(index);
end
value = reshape(value, targetShape);
end

function delayS = buildDelay(filePath, mapping, targetShape, sourceOrder)
if strlength(string(mapping.delay_variable)) > 0
    content = load(filePath, char(mapping.delay_variable));
    raw = double(content.(char(mapping.delay_variable)));
    scale = unitScale(string(mapping.delay_unit), "delay");
    raw = raw * scale;
    if isvector(raw) && numel(raw) == targetShape(3)
        delayS = reshape(raw(:), [1, 1, targetShape(3), 1, 1]);
    elseif isequal(fiveDimensionalSize(raw), targetShape)
        delayS = raw;
    elseif isequal(size(raw), sizeFromOrder(targetShape, sourceOrder, "cir"))
        [delayS, ~] = canonicalizeChannel(raw, sourceOrder, "cir");
    else
        error("convert_mat_channel_to_v3_hdf5:DelayShapeMismatch", ...
            "Delay variable must be an Npath vector or match the channel dimensions.");
    end
else
    step = double(mapping.delay_bin_spacing_s);
    delayS = reshape((0:(targetShape(3) - 1)) * step, ...
        [1, 1, targetShape(3), 1, 1]);
end
if any(~isfinite(delayS(:))) || any(delayS(:) < 0)
    error("convert_mat_channel_to_v3_hdf5:InvalidDelay", ...
        "Delay values must be finite and nonnegative after unit conversion.");
end
end

function shape = fiveDimensionalSize(value)
shape = [size(value, 1), size(value, 2), size(value, 3), ...
    size(value, 4), size(value, 5)];
end

function axes = buildAxes(filePath, mapping, shape, domain)
axes = struct();
axes.sample_index = readAxisOrDefault(filePath, ...
    string(mapping.sample_index_variable), shape(5), (1:shape(5)).', 1);
if strlength(string(mapping.position_variable)) > 0
    position = readVariable(filePath, mapping.position_variable);
    position = double(position) * unitScale(string(mapping.position_unit), "position");
    if size(position, 1) ~= shape(5) || ~ismember(size(position, 2), [1, 2, 3])
        error("convert_mat_channel_to_v3_hdf5:PositionShapeMismatch", ...
            "Position must be N_sample-by-1, 2, or 3.");
    end
    axes.sample_position_m = position;
end
if strlength(string(mapping.time_variable)) > 0
    axes.time_s = readAxis(filePath, mapping.time_variable, shape(4), ...
        unitScale(string(mapping.time_unit), "time"), "time");
elseif isPositiveScalar(mapping.snapshot_interval_s) && shape(4) > 1
    axes.time_s = (0:(shape(4) - 1)).' * double(mapping.snapshot_interval_s);
end
if domain == "ctf"
    if strlength(string(mapping.frequency_variable)) > 0
        axes.frequency_hz = readAxis(filePath, mapping.frequency_variable, ...
            shape(3), unitScale(string(mapping.frequency_unit), "frequency"), "frequency");
    elseif isPositiveScalar(mapping.center_frequency_hz) && ...
            isPositiveScalar(mapping.subcarrier_spacing_hz)
        offsets = ((0:(shape(3) - 1)) - (shape(3) - 1) / 2).';
        axes.frequency_hz = double(mapping.center_frequency_hz) + ...
            offsets * double(mapping.subcarrier_spacing_hz);
    end
end
end

function metadata = buildMetadata(filePath, mapping, inspection)
[~, baseName, extension] = fileparts(filePath);
sourceId = string(mapping.source_id);
if sourceId == "", sourceId = string(baseName) + string(extension); end
metadata = struct( ...
    "source", "converted_mat:" + sourceId, ...
    "sample_semantics", string(mapping.sample_semantics), ...
    "converter", "convert_mat_channel_to_v3_hdf5", ...
    "source_mat_version", string(inspection.mat_version), ...
    "source_file_name", string(baseName) + string(extension), ...
    "mapping_schema_version", string(mapping.schema_version));
optional = ["center_frequency_hz", "subcarrier_spacing_hz", ...
    "snapshot_interval_s", "delay_bin_spacing_s"];
for name = optional
    if isfield(mapping, name) && isPositiveScalar(mapping.(name))
        metadata.(name) = double(mapping.(name));
    end
end
end

function manifest = conversionManifest(inputFile, outputFile, mapping, ...
        inspection, dataset, validation, capabilities, sourceHash, readMode)
manifest = struct( ...
    "schema_version", "v3.0-mat-conversion-manifest.1", ...
    "created_utc", string(datetime("now", "TimeZone", "UTC", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'")), ...
    "source_file_name", string(fileNameOnly(inputFile)), ...
    "source_sha256", sourceHash, ...
    "source_unchanged", true, ...
    "read_mode", readMode, ...
    "output_file_name", string(fileNameOnly(outputFile)), ...
    "mapping", jsonSafeMapping(mapping), ...
    "inspection_status", string(inspection.status), ...
    "domain", string(dataset.domain), ...
    "dimensions", dataset.dimensions, ...
    "validation_status", string(validation.status), ...
    "validation_warnings", string(validation.warnings(:)), ...
    "capability_classification", string(capabilities.classification), ...
    "generated_sample_index", strlength(string(mapping.sample_index_variable)) == 0, ...
    "phase_reconstructed", false);
end

function safe = jsonSafeMapping(mapping)
safe = mapping;
safe.source_dimension_order = string(mapping.source_dimension_order(:)).';
end

function value = readAxis(filePath, variableName, expected, scale, label)
value = double(readVariable(filePath, variableName));
if ~isvector(value) || numel(value) ~= expected
    error("convert_mat_channel_to_v3_hdf5:AxisLengthMismatch", ...
        "%s axis must contain %d values.", label, expected);
end
value = value(:) * scale;
if any(~isfinite(value)) || (numel(value) > 1 && any(diff(value) <= 0))
    error("convert_mat_channel_to_v3_hdf5:InvalidAxis", ...
        "%s axis must be finite and strictly increasing.", label);
end
end

function value = readAxisOrDefault(filePath, variableName, expected, defaultValue, scale)
if variableName == ""
    value = defaultValue;
else
    value = readAxis(filePath, variableName, expected, scale, "sample index");
end
end

function value = readVariable(filePath, variableName)
content = load(filePath, char(variableName));
if ~isfield(content, char(variableName))
    error("convert_mat_channel_to_v3_hdf5:MissingVariable", ...
        "MAT variable does not exist: %s", variableName);
end
value = content.(char(variableName));
end

function scale = unitScale(unit, quantity)
unit = lower(strtrim(unit));
switch quantity
    case {"delay", "time"}
        choices = ["s", "ms", "us", "ns"];
        scales = [1, 1e-3, 1e-6, 1e-9];
    case "frequency"
        choices = ["hz", "khz", "mhz", "ghz"];
        scales = [1, 1e3, 1e6, 1e9];
    case "position"
        choices = ["m", "cm", "mm", "km"];
        scales = [1, 1e-2, 1e-3, 1e3];
end
index = find(choices == unit, 1);
if isempty(index)
    error("convert_mat_channel_to_v3_hdf5:UnsupportedUnit", ...
        "Unsupported %s unit: %s", quantity, unit);
end
scale = scales(index);
end

function expected = sizeFromOrder(targetShape, sourceOrder, domain)
axisName = "Npath";
if domain == "ctf", axisName = "Nf"; end
targetOrder = ["Tx", "Rx", axisName, "Nt", "N_sample"];
expected = zeros(1, numel(sourceOrder));
for index = 1:numel(sourceOrder)
    expected(index) = targetShape(targetOrder == sourceOrder(index));
end
end

function notify(callback, fraction, phase, detail)
if isempty(callback), return; end
event = struct("fraction", fraction, "phase", string(phase), ...
    "detail", string(detail), "indeterminate", false);
callback(event);
end

function writeJson(filePath, value)
if isfile(filePath)
    error("convert_mat_channel_to_v3_hdf5:ManifestExists", ...
        "Refusing to overwrite existing manifest: %s", filePath);
end
identifier = fopen(filePath, "wt", "n", "UTF-8");
if identifier < 0
    error("convert_mat_channel_to_v3_hdf5:ManifestWriteFailed", ...
        "Cannot create conversion manifest: %s", filePath);
end
cleanup = onCleanup(@() fclose(identifier));
fprintf(identifier, "%s\n", jsonencode(value, "PrettyPrint", true));
clear cleanup
end

function value = outputManifestPath(outputFile)
[folder, baseName] = fileparts(outputFile);
value = string(fullfile(folder, baseName + ".conversion_manifest.json"));
end

function validateOutput(outputFile)
[folder, ~, extension] = fileparts(outputFile);
if lower(string(extension)) ~= ".h5"
    error("convert_mat_channel_to_v3_hdf5:InvalidOutput", ...
        "Output must use the .h5 extension.");
end
if folder ~= "" && ~isfolder(folder)
    error("convert_mat_channel_to_v3_hdf5:MissingOutputFolder", ...
        "Output folder does not exist: %s", folder);
end
if isfile(outputFile)
    error("convert_mat_channel_to_v3_hdf5:OutputExists", ...
        "Refusing to overwrite existing output: %s", outputFile);
end
end

function value = fileExtension(path)
[~, ~, extension] = fileparts(path);
value = string(extension);
end

function value = fileNameOnly(path)
[~, name, extension] = fileparts(path);
value = string(name) + string(extension);
end

function tf = isPositiveScalar(value)
tf = isnumeric(value) && isscalar(value) && isfinite(value) && value > 0;
end
