function result = convert_sage_folder_to_v3_hdf5( ...
        folderPath, outputFile, options)
%CONVERT_SAGE_FOLDER_TO_V3_HDF5 Pack ordered SAGE MAT files into v3 CIR.
%   The converter is intentionally specific: every selected file must have
%   a top-level sage variable and the selected SAGE record must contain a
%   fixed-size [Tx, Rx, delay_tap] complex cir array. The source files are
%   read-only and the output file must not already exist.
%
%   Required physical definition:
%     options.bandwidth_hz OR options.delay_bin_spacing_s
%
%   Useful options:
%     record_index       SAGE cell/struct record (default 1)
%     sample_semantics   default "ordered_route"
%     sample_position_m  optional N_sample-by-1/2/3 positions
%     center_frequency_hz
%     source_id
%     max_files          review/test subset; default Inf

arguments
    folderPath (1, 1) string
    outputFile (1, 1) string
    options (1, 1) struct = struct()
end

if ~isfolder(folderPath)
    error("convert_sage_folder_to_v3_hdf5:MissingFolder", ...
        "SAGE folder does not exist: %s", folderPath);
end
validateOutputPath(outputFile);

pattern = string(getOption(options, "file_pattern", "*.mat"));
files = dir(fullfile(folderPath, pattern));
files = files(~[files.isdir]);
if isempty(files)
    error("convert_sage_folder_to_v3_hdf5:NoFiles", ...
        "No SAGE MAT files match %s in %s.", pattern, folderPath);
end

[~, order] = natural_sort_files(string({files.name}));
files = files(order);
maxFiles = double(getOption(options, "max_files", Inf));
if ~isscalar(maxFiles) || maxFiles <= 0 || ...
        (~isinf(maxFiles) && mod(maxFiles, 1) ~= 0)
    error("convert_sage_folder_to_v3_hdf5:InvalidMaxFiles", ...
        "max_files must be a positive integer or Inf.");
end
files = files(1:min(numel(files), maxFiles));

recordIndex = double(getOption(options, "record_index", 1));
if ~isscalar(recordIndex) || recordIndex < 1 || mod(recordIndex, 1) ~= 0
    error("convert_sage_folder_to_v3_hdf5:InvalidRecordIndex", ...
        "record_index must be a positive integer.");
end

first = readSageRecord(files(1), recordIndex);
firstCir = normalizeSageCir(first.cir, files(1).name);
shape = [size(firstCir, 1), size(firstCir, 2), size(firstCir, 3)];
coefficient = zeros([shape, 1, numel(files)], "like", firstCir);
coefficient(:, :, :, 1, 1) = firstCir;

for index = 2:numel(files)
    record = readSageRecord(files(index), recordIndex);
    value = normalizeSageCir(record.cir, files(index).name);
    valueShape = [size(value, 1), size(value, 2), size(value, 3)];
    if ~isequal(valueShape, shape)
        error("convert_sage_folder_to_v3_hdf5:InconsistentCIRSize", ...
            "File %s has CIR size [%s], expected [%s].", ...
            files(index).name, strjoin(string(valueShape), " "), ...
            strjoin(string(shape), " "));
    end
    coefficient(:, :, :, 1, index) = value;
end

delayStepS = resolveDelayStep(options);
delayS = reshape((0:(shape(3) - 1)) * delayStepS, ...
    [1, 1, shape(3), 1, 1]);
pathValid = true(1, 1, shape(3), 1, 1);

axes = struct("sample_index", (1:numel(files)).');
if isfield(options, "sample_position_m") && ...
        ~isempty(options.sample_position_m)
    positions = options.sample_position_m;
    if ~isnumeric(positions) || size(positions, 1) ~= numel(files) || ...
            ~ismember(size(positions, 2), [1, 2, 3])
        error("convert_sage_folder_to_v3_hdf5:InvalidPositions", ...
            "sample_position_m must have one row per selected SAGE file.");
    end
    axes.sample_position_m = positions;
end

[~, folderName] = fileparts(folderPath);
sourceId = string(getOption(options, "source_id", folderName));
metadata = struct( ...
    "source", "measured_sage:" + sourceId, ...
    "sample_semantics", string(getOption( ...
        options, "sample_semantics", "ordered_route")), ...
    "converter", "convert_sage_folder_to_v3_hdf5", ...
    "source_file_count", numel(files), ...
    "source_record_index", recordIndex, ...
    "delay_bin_spacing_s", delayStepS, ...
    "source_file_pattern", pattern);
if isfield(options, "bandwidth_hz")
    metadata.bandwidth_hz = double(options.bandwidth_hz);
end
if isfield(options, "center_frequency_hz") && ...
        ~isempty(options.center_frequency_hz)
    metadata.center_frequency_hz = double(options.center_frequency_hz);
end
metadata.conversion_note = ...
    "SAGE cir tap grid converted; alpha/doa/dod require a separate " + ...
    "confirmed path-parameter mapping and were not guessed.";

payload = struct( ...
    "coefficient", coefficient, ...
    "delay_s", delayS, ...
    "path_valid", pathValid);
dataset = create_channel_dataset("cir", payload, axes, metadata);
validation = validate_channel_dataset(dataset);
if ~validation.is_valid
    error("convert_sage_folder_to_v3_hdf5:InvalidConvertedDataset", ...
        "Converted SAGE dataset failed validation: %s", ...
        strjoin(validation.errors, " | "));
end

write_channel_dataset_hdf5(outputFile, dataset);
result = struct();
result.status = validation.status;
result.dataset = dataset;
result.validation = validation;
result.capabilities = infer_channel_capabilities(dataset);
result.output_file = outputFile;
result.source_file_count = numel(files);
result.source_files_unchanged = true;
result.conversion_warnings = [ ...
    "SAGE alpha/doa/dod fields were not mapped without confirmed units " + ...
    "and path conventions."; ...
    string(validation.warnings(:))];
end

function record = readSageRecord(file, recordIndex)
data = read_sage_mat(fullfile(file.folder, file.name));
if recordIndex > data.record_count
    error("convert_sage_folder_to_v3_hdf5:MissingRecord", ...
        "File %s has %d SAGE record(s); record_index %d is unavailable.", ...
        file.name, data.record_count, recordIndex);
end
record = data.records{recordIndex};
if ~isstruct(record) || ~isfield(record, "cir")
    error("convert_sage_folder_to_v3_hdf5:MissingCIR", ...
        "Selected SAGE record in %s does not contain cir.", file.name);
end
end

function cir = normalizeSageCir(value, fileName)
if ~isnumeric(value) || isempty(value) || ndims(value) ~= 3
    error("convert_sage_folder_to_v3_hdf5:AmbiguousCIRLayout", ...
        "File %s must contain a numeric three-dimensional " + ...
        "[Tx, Rx, delay_tap] cir array; no dimension guessing is allowed.", ...
        fileName);
end
cir = value;
end

function delayStepS = resolveDelayStep(options)
if isfield(options, "delay_bin_spacing_s") && ...
        ~isempty(options.delay_bin_spacing_s)
    delayStepS = double(options.delay_bin_spacing_s);
elseif isfield(options, "bandwidth_hz") && ~isempty(options.bandwidth_hz)
    bandwidthHz = double(options.bandwidth_hz);
    if ~isscalar(bandwidthHz) || ~isfinite(bandwidthHz) || bandwidthHz <= 0
        error("convert_sage_folder_to_v3_hdf5:InvalidBandwidth", ...
            "bandwidth_hz must be a positive finite scalar.");
    end
    delayStepS = 1 / bandwidthHz;
else
    error("convert_sage_folder_to_v3_hdf5:MissingDelayDefinition", ...
        "Provide bandwidth_hz or delay_bin_spacing_s. " + ...
        "The converter will not guess a SAGE delay grid.");
end
if ~isscalar(delayStepS) || ~isfinite(delayStepS) || delayStepS <= 0
    error("convert_sage_folder_to_v3_hdf5:InvalidDelayStep", ...
        "delay_bin_spacing_s must be a positive finite scalar.");
end
end

function validateOutputPath(outputFile)
[folder, ~, extension] = fileparts(outputFile);
if lower(string(extension)) ~= ".h5"
    error("convert_sage_folder_to_v3_hdf5:InvalidOutputExtension", ...
        "Output file must use the .h5 extension.");
end
if folder ~= "" && ~isfolder(folder)
    error("convert_sage_folder_to_v3_hdf5:MissingOutputFolder", ...
        "Output folder does not exist: %s", folder);
end
if isfile(outputFile)
    error("convert_sage_folder_to_v3_hdf5:OutputExists", ...
        "Refusing to overwrite existing output: %s", outputFile);
end
end

function value = getOption(options, fieldName, defaultValue)
if isfield(options, fieldName)
    value = options.(fieldName);
else
    value = defaultValue;
end
end
