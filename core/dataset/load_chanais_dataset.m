function dataset = load_chanais_dataset(datasetRoot)
%LOAD_CHANAIS_DATASET Load metadata and file inventory for ChanAIs Dataset.
%   dataset = load_chanais_dataset(datasetRoot) validates the dataset,
%   reads metadata.json, and lists public data files. It does not train,
%   predict, or modify data.

datasetRoot = string(datasetRoot);
validation = validate_chanais_dataset(datasetRoot);
if ~validation.is_valid
    error("load_chanais_dataset:InvalidDataset", "Invalid ChanAIs Dataset: %s", strjoin(validation.errors, "; "));
end

metadata = parse_dataset_metadata(fullfile(datasetRoot, "metadata.json"));
matFiles = dir(fullfile(datasetRoot, "data", "**", "*.mat"));
jsonFiles = dir(fullfile(datasetRoot, "data", "**", "*.json"));

dataset = struct();
dataset.root = datasetRoot;
dataset.metadata = metadata;
dataset.validation = validation;
dataset.status = validation.status;
dataset.files = struct();
dataset.files.mat = string(fullfile({matFiles.folder}, {matFiles.name}));
dataset.files.json = string(fullfile({jsonFiles.folder}, {jsonFiles.name}));
dataset.loaded_at = string(datetime("now", "Format", "yyyy-MM-dd HH:mm:ss"));
end
