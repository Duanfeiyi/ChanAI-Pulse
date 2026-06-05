function sageData = read_sage_mat(matFile)
%READ_SAGE_MAT Read a SAGE-compatible .mat file without modifying it.
%   sageData = read_sage_mat(matFile) loads the top-level variable `sage`,
%   normalizes cell/struct containers, and returns lightweight metadata.

matFile = string(matFile);
if ~isfile(matFile)
    error("read_sage_mat:MissingFile", "SAGE file not found: %s", matFile);
end

loaded = load(matFile);
if ~isfield(loaded, "sage")
    error("read_sage_mat:MissingSage", "The file does not contain a top-level sage variable: %s", matFile);
end

records = normalizeSageContainer(loaded.sage);
fieldSummary = repmat(struct("record_index", [], "fields", strings(0, 1), ...
    "has_cir", false, "cir_size", [], "cir_is_complex", false), 1, numel(records));

for idx = 1:numel(records)
    item = records{idx};
    fieldSummary(idx).record_index = idx;
    if isstruct(item)
        fieldSummary(idx).fields = string(fieldnames(item));
        if isfield(item, "cir")
            fieldSummary(idx).has_cir = true;
            fieldSummary(idx).cir_size = size(item.cir);
            fieldSummary(idx).cir_is_complex = ~isreal(item.cir);
        end
    end
end

sageData = struct();
sageData.source_file = matFile;
sageData.record_count = numel(records);
sageData.records = records;
sageData.summary = fieldSummary;
end

function records = normalizeSageContainer(sage)
if iscell(sage)
    records = sage(:);
elseif isstruct(sage)
    records = num2cell(sage(:));
else
    error("read_sage_mat:UnsupportedSage", "Unsupported sage variable class: %s", class(sage));
end
end

