function metadata = parse_dataset_metadata(metadataInput)
%PARSE_DATASET_METADATA Read ChanAIs metadata from JSON file or struct.
%   metadata = parse_dataset_metadata(metadataInput) accepts a metadata
%   struct or a path to metadata.json and returns a struct.

if isstruct(metadataInput)
    metadata = metadataInput;
    return;
end

metadataPath = string(metadataInput);
if ~isfile(metadataPath)
    error("parse_dataset_metadata:MissingFile", "Metadata file not found: %s", metadataPath);
end

metadataText = fileread(metadataPath);
metadata = jsondecode(metadataText);
end

