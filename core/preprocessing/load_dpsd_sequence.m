function [sequence, metadata] = load_dpsd_sequence(folderPath, options)
%LOAD_DPSD_SEQUENCE Load naturally sorted DPSD vectors from MAT files.
%   This function reads source files without modifying them. Each MAT file
%   must contain the requested vector variable, named `dpsd` by default.

arguments
    folderPath (1, 1) string
    options.Pattern (1, 1) string = "*.mat"
    options.VariableName (1, 1) string = "dpsd"
end

if ~isfolder(folderPath)
    error("load_dpsd_sequence:MissingFolder", "DPSD folder not found: %s", folderPath);
end

listing = dir(fullfile(folderPath, options.Pattern));
if isempty(listing)
    error("load_dpsd_sequence:NoFiles", "No files matching %s were found in %s.", options.Pattern, folderPath);
end

[sortedNames, order] = natural_sort_files(string({listing.name}));
listing = listing(order);
sequence = [];

for idx = 1:numel(listing)
    filePath = fullfile(listing(idx).folder, listing(idx).name);
    loaded = load(filePath, char(options.VariableName));

    if ~isfield(loaded, options.VariableName)
        error("load_dpsd_sequence:MissingVariable", ...
            "File %s does not contain variable %s.", filePath, options.VariableName);
    end

    vector = loaded.(options.VariableName);
    if ~isnumeric(vector) || ~isvector(vector)
        error("load_dpsd_sequence:InvalidVector", ...
            "Variable %s in %s must be a numeric vector.", options.VariableName, filePath);
    end

    vector = double(vector(:).');
    if isempty(sequence)
        sequence = zeros(numel(listing), numel(vector));
    elseif size(sequence, 2) ~= numel(vector)
        error("load_dpsd_sequence:InconsistentLength", ...
            "DPSD vector length differs in %s.", filePath);
    end

    sequence(idx, :) = vector;
end

metadata = struct();
metadata.folder = folderPath;
metadata.files = sortedNames;
metadata.variable_name = options.VariableName;
metadata.sequence_size = size(sequence);
end

