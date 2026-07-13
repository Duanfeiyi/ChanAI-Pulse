function result = validate_chanais_dataset(datasetRoot)
%VALIDATE_CHANAIS_DATASET Validate a ChanAIs Dataset folder.
%   result = validate_chanais_dataset(datasetRoot) performs read-only
%   validation and returns PASS, WARNING, or FAIL. Core metadata is needed
%   for loading; recommended metadata improves scientific interpretation.

datasetRoot = string(datasetRoot);
coreFields = ["dataset_id", "scenario", "data_source", "data_type", "visibility"];
recommendedFields = ["environment", "frequency_band", "carrier_frequency", ...
    "bandwidth", "antenna_configuration", "polarization", "mobility", ...
    "trajectory", "los_condition", "sampling_interval", "time_window", ...
    "license", "units"];
supportedTypes = ["SAGE", "CIR", "CTF", "PDP", "Doppler", ...
    "Angular Spectrum", "Feature Tensor", "Prediction Target"];

result = struct();
result.dataset_root = datasetRoot;
result.is_valid = true;
result.status = "PASS";
result.errors = strings(0, 1);
result.warnings = strings(0, 1);
result.missing_core_fields = strings(0, 1);
result.missing_recommended_fields = strings(0, 1);
result.detected_data_files = strings(0, 1);

if ~isfolder(datasetRoot)
    result = addError(result, "Dataset root does not exist.");
    result = finalizeResult(result);
    return;
end

metadataPath = fullfile(datasetRoot, "metadata.json");
if ~isfile(metadataPath)
    result = addError(result, "metadata.json is missing.");
    result = finalizeResult(result);
    return;
end

try
    metadata = parse_dataset_metadata(metadataPath);
catch exception
    result = addError(result, "Cannot read metadata.json: " + string(exception.message));
    result = finalizeResult(result);
    return;
end

for idx = 1:numel(coreFields)
    fieldName = coreFields(idx);
    if ~isUsableMetadataValue(metadata, fieldName)
        result.missing_core_fields(end + 1, 1) = fieldName; %#ok<AGROW>
        result = addError(result, "Missing core metadata value: " + fieldName);
    end
end

for idx = 1:numel(recommendedFields)
    fieldName = recommendedFields(idx);
    if ~isUsableMetadataValue(metadata, fieldName)
        result.missing_recommended_fields(end + 1, 1) = fieldName; %#ok<AGROW>
        result.warnings(end + 1, 1) = "Missing recommended metadata value: " + fieldName; %#ok<AGROW>
    end
end

if isfield(metadata, "data_type") && isUsableMetadataValue(metadata, "data_type")
    declaredTypes = string(metadata.data_type);
    if ~any(ismember(lower(declaredTypes(:)), lower(supportedTypes)))
        result = addError(result, "Unsupported data_type: " + strjoin(declaredTypes, ", "));
    end
end

dataFiles = [dir(fullfile(datasetRoot, "data", "**", "*.mat")); ...
    dir(fullfile(datasetRoot, "data", "**", "*.h5")); ...
    dir(fullfile(datasetRoot, "data", "**", "*.hdf5"))];
if isempty(dataFiles)
    result = addError(result, "No supported channel data file was found under data/.");
else
    result.detected_data_files = string(fullfile({dataFiles.folder}, {dataFiles.name})).';
end

expectedDirs = ["data", fullfile("data", "raw"), fullfile("data", "processed"), ...
    fullfile("data", "features"), "labels", "splits"];
for idx = 1:numel(expectedDirs)
    candidate = fullfile(datasetRoot, expectedDirs(idx));
    if ~isfolder(candidate)
        result.warnings(end + 1, 1) = "Recommended folder missing: " + expectedDirs(idx); %#ok<AGROW>
    end
end

if isfield(metadata, "visibility")
    visibility = string(metadata.visibility);
    if any(strcmpi(visibility, ["private_measured", "restricted", "internal_only"]))
        result.warnings(end + 1, 1) = "Dataset visibility is not public; do not commit converted data without review.";
    end
end

result = finalizeResult(result);
end

function isUsable = isUsableMetadataValue(metadata, fieldName)
isUsable = isfield(metadata, fieldName);
if ~isUsable
    return;
end

value = metadata.(fieldName);
if isempty(value)
    isUsable = false;
    return;
end

if ischar(value) || isstring(value)
    normalized = lower(strtrim(string(value)));
    isUsable = all(normalized ~= "") && all(normalized ~= "unspecified") && ...
        all(normalized ~= "unknown");
end
end

function result = addError(result, message)
result.is_valid = false;
result.errors(end + 1, 1) = message; %#ok<AGROW>
end

function result = finalizeResult(result)
if ~isempty(result.errors)
    result.status = "FAIL";
elseif ~isempty(result.warnings)
    result.status = "WARNING";
else
    result.status = "PASS";
end
end
