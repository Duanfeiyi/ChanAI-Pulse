function report = inspect_mat_channel_source(inputPath)
%INSPECT_MAT_CHANNEL_SOURCE Read-only Step 14 MAT/folder inspection.
%   The report never guesses an ambiguous physical meaning. Known SAGE
%   folders and high-confidence complex CIR/CTF arrays receive a suggested
%   mapping; other numeric MAT files require explicit advanced mapping.

arguments
    inputPath (1, 1) string
end

report = emptyReport(inputPath);
if isfolder(inputPath)
    report = inspectFolder(report, inputPath);
elseif isfile(inputPath)
    [~, ~, extension] = fileparts(inputPath);
    extension = lower(string(extension));
    if extension == ".mat"
        report = inspectMat(report, inputPath);
    elseif ismember(extension, [".h5", ".hdf5"])
        legacy = inspect_channel_input_file(inputPath);
        report.source_kind = string(legacy.category);
        report.status = string(legacy.status);
        report.is_convertible = legacy.category == "legacy_wifo_hdf5";
        report.requires_mapping = false;
        report.errors = string(legacy.errors(:));
        report.warnings = string(legacy.warnings(:));
        report.suggested_mapping = default_mat_channel_mapping();
    else
        report.status = "FAIL";
        report.source_kind = "unsupported_extension";
        report.errors = "Select a MAT, H5/HDF5, or known SAGE folder.";
    end
else
    report.status = "FAIL";
    report.source_kind = "missing_source";
    report.errors = "The selected source does not exist: " + inputPath;
end
report = finalize(report);
end

function report = inspectFolder(report, folderPath)
files = dir(fullfile(folderPath, "*.mat"));
files = files(~[files.isdir]);
if isempty(files)
    report.status = "FAIL";
    report.source_kind = "unsupported_folder";
    report.errors = "The selected folder contains no MAT files.";
    return;
end
[~, order] = sort(lower(string({files.name})));
files = files(order);
hasSage = true(numel(files), 1);
shapeSignature = strings(numel(files), 1);
for index = 1:numel(files)
    variables = whos("-file", fullfile(files(index).folder, files(index).name));
    names = lower(string({variables.name}));
    hasSage(index) = any(names == "sage");
    shapeSignature(index) = variableSignature(variables);
end
report.file_count = numel(files);
report.folder_consistent = numel(unique(shapeSignature)) == 1;
if all(hasSage)
    report.status = "PASS";
    report.source_kind = "sage_folder";
    report.mat_version = "mixed_or_mat_v7";
    report.is_convertible = true;
    report.requires_mapping = false;
    mapping = default_mat_channel_mapping();
    mapping.adapter = "sage_folder";
    mapping.domain = "cir";
    report.suggested_mapping = mapping;
    if ~report.folder_consistent
        report.warnings(end + 1, 1) = ...
            "SAGE variables differ across files; conversion will validate every CIR shape.";
    end
else
    report.status = "FAIL";
    report.source_kind = "mixed_mat_folder";
    report.errors = [ ...
        "Arbitrary mixed MAT folders are not converted automatically."; ...
        "Select one ordinary MAT file, or a folder in which every MAT contains SAGE."];
end
end

function report = inspectMat(report, filePath)
try
    variables = whos("-file", filePath);
catch exception
    report.status = "FAIL";
    report.source_kind = "invalid_mat";
    report.errors = "MAT metadata could not be read: " + string(exception.message);
    return;
end
report.mat_version = detectMatVersion(filePath);
report.file_count = 1;
report.variables = variableRecords(variables);
names = lower(string({variables.name}));
if any(names == "sage")
    report.status = "NEEDS_FOLDER";
    report.source_kind = "single_sage_mat";
    report.is_convertible = false;
    report.errors = "Select the complete SAGE folder so samples can be ordered and converted together.";
    return;
end
if any(contains(names, "dpsd") | contains(names, "pdp")) && ...
        ~any([report.variables.is_complex])
    report.status = "FAIL";
    report.source_kind = "power_only_mat";
    report.is_power_only = true;
    report.errors = "Only PDP/DPSD power was found. Missing phase cannot be reconstructed into a complex CIR.";
    return;
end
if any(ismember(names, ["input", "output", "predictions", "ground_truth"])) && ...
        ~any([report.variables.is_complex])
    report.status = "FAIL";
    report.source_kind = "model_feature_mat";
    report.errors = "Model input/output features are not a complete complex CIR or CTF.";
    return;
end

mapping = default_mat_channel_mapping();
[complexName, domain, highConfidence] = findComplexCandidate(report.variables);
if complexName ~= ""
    mapping.complex_variable = complexName;
    mapping.domain = domain;
else
    [realName, imagName, domain] = findRealImagPair(report.variables);
    highConfidence = realName ~= "" && imagName ~= "";
    mapping.real_variable = realName;
    mapping.imag_variable = imagName;
    mapping.domain = domain;
end
mapping.delay_variable = findNamedVariable(names, string({variables.name}), ...
    ["delay_s", "delay", "tau", "delays"]);
mapping.frequency_variable = findNamedVariable(names, string({variables.name}), ...
    ["frequency_hz", "frequency", "frequencies", "freq", "f"]);
mapping.time_variable = findNamedVariable(names, string({variables.name}), ...
    ["time_s", "time", "timestamps", "timestamp"]);
mapping.sample_index_variable = findNamedVariable(names, string({variables.name}), ...
    ["sample_index", "sample_id", "sample_ids", "index"]);
mapping.position_variable = findNamedVariable(names, string({variables.name}), ...
    ["sample_position_m", "position", "positions", "location", "locations"]);

payloadName = mapping.complex_variable;
if payloadName == "", payloadName = mapping.real_variable; end
if payloadName == ""
    report.status = "FAIL";
    report.source_kind = "no_complex_channel_candidate";
    report.errors = "No complex channel variable or explicit real/imaginary pair was identified.";
    report.suggested_mapping = mapping;
    return;
end
payload = variables(string({variables.name}) == payloadName);
report.payload_bytes = double(payload.bytes);
report.large_file = report.payload_bytes >= 256 * 1024^2;
if report.large_file && report.mat_version == "v7.3"
    report.recommended_read_mode = "sample_chunked_v73";
elseif report.large_file
    report.recommended_read_mode = "in_memory_legacy_mat";
    report.warnings(end + 1, 1) = ...
        "Large pre-v7.3 MAT payloads require enough memory for one complete channel array.";
else
    report.recommended_read_mode = "in_memory";
end
mapping.source_dimension_order = suggestDimensionOrder( ...
    payload.size, mapping.domain, mapping, variables);
report.suggested_mapping = mapping;
report.is_convertible = true;
if strlength(join(mapping.source_dimension_order, ",")) > 0 && highConfidence
    report.status = "PASS";
    report.source_kind = "mapped_complex_mat";
    report.requires_mapping = false;
else
    report.status = "NEEDS_MAPPING";
    report.source_kind = "ambiguous_complex_mat";
    report.requires_mapping = true;
    report.warnings = "A complex channel candidate was found, but its dimension meanings require confirmation.";
end
end

function records = variableRecords(variables)
template = struct("name", "", "size", zeros(1, 0), "class", "", ...
    "bytes", 0, "is_complex", false, "is_numeric", false, "role", "other");
records = repmat(template, numel(variables), 1);
for index = 1:numel(variables)
    variable = variables(index);
    name = string(variable.name);
    lowerName = lower(name);
    records(index).name = name;
    records(index).size = double(variable.size);
    records(index).class = string(variable.class);
    records(index).bytes = double(variable.bytes);
    records(index).is_complex = logical(variable.complex);
    records(index).is_numeric = isNumericClass(variable.class);
    if any(contains(lowerName, ["delay", "tau"]))
        records(index).role = "delay_axis";
    elseif any(contains(lowerName, ["frequency", "freq"]))
        records(index).role = "frequency_axis";
    elseif any(contains(lowerName, ["position", "location"]))
        records(index).role = "position_axis";
    elseif any(contains(lowerName, ["sample_index", "sample_id"]))
        records(index).role = "sample_axis";
    elseif contains(lowerName, "time")
        records(index).role = "time_axis";
    elseif records(index).is_complex || ...
            any(contains(lowerName, ["cir", "ctf", "coeff", "channel", "csi"]))
        records(index).role = "channel_candidate";
    end
end
end

function [name, domain, highConfidence] = findComplexCandidate(records)
name = "";
domain = "";
highConfidence = false;
candidates = records([records.is_numeric] & [records.is_complex]);
if isempty(candidates), return; end
priority = zeros(numel(candidates), 1);
for index = 1:numel(candidates)
    lowerName = lower(candidates(index).name);
    recognized = lowerName == "h" || any(contains(lowerName, ...
        ["cir", "ctf", "coeff", "channel", "csi"]));
    priority(index) = 1 + 10 * recognized;
    priority(index) = priority(index) + log10(max(candidates(index).bytes, 1));
end
[~, selected] = max(priority);
name = candidates(selected).name;
lowerName = lower(name);
highConfidence = lowerName == "h" || any(contains(lowerName, ...
    ["cir", "ctf", "coeff", "channel", "csi"]));
if any(contains(lowerName, ["ctf", "csi", "frequency", "freq"])) || lowerName == "h"
    domain = "ctf";
else
    domain = "cir";
end
end

function [realName, imagName, domain] = findRealImagPair(records)
realName = ""; imagName = ""; domain = "";
names = lower(string({records.name}));
pairs = ["h_real", "h_imag"; "real", "imag"; ...
    "coefficient_real", "coefficient_imag"; "cir_real", "cir_imag"; ...
    "csi_real", "csi_imag"];
for index = 1:size(pairs, 1)
    realIndex = find(names == pairs(index, 1), 1);
    imagIndex = find(names == pairs(index, 2), 1);
    if isempty(realIndex) || isempty(imagIndex), continue; end
    if ~records(realIndex).is_numeric || ~records(imagIndex).is_numeric || ...
            ~isequal(records(realIndex).size, records(imagIndex).size)
        continue;
    end
    realName = records(realIndex).name;
    imagName = records(imagIndex).name;
    domain = "ctf";
    if any(contains(pairs(index, 1), ["coefficient", "cir"])), domain = "cir"; end
    return;
end
end

function order = suggestDimensionOrder(shape, domain, mapping, variables)
shape = double(shape);
axisName = "Npath";
if domain == "ctf", axisName = "Nf"; end
if numel(shape) == 5
    order = ["Tx", "Rx", axisName, "Nt", "N_sample"];
    return;
end
if numel(shape) == 2
    physicalVariable = mapping.delay_variable;
    if domain == "ctf", physicalVariable = mapping.frequency_variable; end
    axisLength = variableLength(variables, physicalVariable);
    if axisLength == shape(1)
        order = [axisName, "N_sample"];
        return;
    end
end
order = strings(1, 0);
end

function count = variableLength(variables, name)
count = 0;
if name == "", return; end
index = find(string({variables.name}) == name, 1);
if isempty(index), return; end
if sum(variables(index).size > 1) <= 1
    count = prod(variables(index).size);
end
end

function value = findNamedVariable(lowerNames, originalNames, candidates)
value = "";
for candidate = candidates
    index = find(lowerNames == candidate, 1);
    if ~isempty(index)
        value = originalNames(index);
        return;
    end
end
end

function version = detectMatVersion(filePath)
try
    h5info(filePath);
    version = "v7.3";
catch
    version = "v7_or_earlier";
end
end

function tf = isNumericClass(className)
tf = ismember(string(className), ["double", "single", "logical", ...
    "int8", "uint8", "int16", "uint16", "int32", "uint32", "int64", "uint64"]);
end

function signature = variableSignature(variables)
parts = strings(numel(variables), 1);
for index = 1:numel(variables)
    parts(index) = string(variables(index).name) + ":" + ...
        join(string(variables(index).size), "x") + ":" + string(variables(index).class);
end
signature = join(sort(parts), "|");
end

function report = emptyReport(inputPath)
report = struct( ...
    "schema_version", "v3.0-mat-inspection.1", ...
    "input_path", inputPath, ...
    "status", "UNINSPECTED", ...
    "source_kind", "unclassified", ...
    "mat_version", "not_applicable", ...
    "file_count", 0, ...
    "folder_consistent", true, ...
    "is_convertible", false, ...
    "requires_mapping", false, ...
    "is_power_only", false, ...
    "payload_bytes", 0, ...
    "large_file", false, ...
    "recommended_read_mode", "not_applicable", ...
    "variables", repmat(struct("name", "", "size", [], "class", "", ...
        "bytes", 0, "is_complex", false, "is_numeric", false, "role", ""), 0, 1), ...
    "suggested_mapping", default_mat_channel_mapping(), ...
    "warnings", strings(0, 1), ...
    "errors", strings(0, 1));
end

function report = finalize(report)
if ~isempty(report.errors) && report.status == "UNINSPECTED"
    report.status = "FAIL";
elseif isempty(report.errors) && report.status == "UNINSPECTED"
    report.status = "PASS";
end
end
