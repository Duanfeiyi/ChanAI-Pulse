function result = validate_chanais_dataset(datasetRoot)
%VALIDATE_CHANAIS_DATASET Validate a ChanAIs Dataset folder.
%   result = validate_chanais_dataset(datasetRoot) checks metadata and
%   expected folder structure without modifying data.

datasetRoot = string(datasetRoot);
requiredFields = ["dataset_id", "scenario", "environment", "frequency_band", ...
    "carrier_frequency", "bandwidth", "antenna_configuration", "polarization", ...
    "mobility", "trajectory", "los_condition", "sampling_interval", ...
    "time_window", "data_source", "data_type", "license", "visibility"];

result = struct();
result.dataset_root = datasetRoot;
result.is_valid = true;
result.errors = strings(0, 1);
result.warnings = strings(0, 1);

if ~isfolder(datasetRoot)
    result.is_valid = false;
    result.errors(end + 1, 1) = "Dataset root does not exist.";
    return;
end

metadataPath = fullfile(datasetRoot, "metadata.json");
if ~isfile(metadataPath)
    result.is_valid = false;
    result.errors(end + 1, 1) = "metadata.json is missing.";
    return;
end

metadata = parse_dataset_metadata(metadataPath);
for idx = 1:numel(requiredFields)
    fieldName = requiredFields(idx);
    if ~isfield(metadata, fieldName)
        result.is_valid = false;
        result.errors(end + 1, 1) = "Missing required metadata field: " + fieldName; %#ok<AGROW>
    end
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
end

