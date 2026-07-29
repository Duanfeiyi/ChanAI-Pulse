function report = inspect_channel_input_file(filePath)
%INSPECT_CHANNEL_INPUT_FILE Classify a proposed v3 channel input file.
%   The inspection is read-only. It distinguishes standard v3 HDF5 files
%   from known legacy SAGE, DPSD/model-feature, and WiFo layouts so callers
%   can present an actionable error instead of a low-level HDF5 exception.

arguments
    filePath (1, 1) string
end

report = newReport();
if ~isfile(filePath)
    report = addError(report, ...
        "The selected file does not exist: " + filePath);
    report.category = "missing_file";
    report = finalize(report);
    return;
end

fileInfo = dir(filePath);
[~, baseName, extension] = fileparts(filePath);
extension = lower(string(extension));
report.source_file_name = string(baseName) + extension;
report.source_extension = extension;
report.source_bytes = fileInfo.bytes;

if extension ~= ".h5"
    if extension == ".mat"
        report = inspectMatFile(report, filePath);
    else
        report.category = "unsupported_file_format";
        report = addError(report, ...
            "Step 4 accepts one ChanAI Pulse v3 .h5 file. " + ...
            "The selected file uses '" + extension + "'.");
    end
    report = finalize(report);
    return;
end

try
    h5info(filePath);
catch exception
    report.category = "invalid_hdf5";
    report = addError(report, ...
        "The selected .h5 file is not a readable HDF5 file: " + ...
        string(exception.message));
    report = finalize(report);
    return;
end

requiredAttributes = ["schema_version", "domain", ...
    "dimension_order_json", "units_json", "metadata_json"];
missingAttributes = strings(0, 1);
for attributeName = requiredAttributes
    if ~attributeExists(filePath, "/", attributeName)
        missingAttributes(end + 1, 1) = attributeName; %#ok<AGROW>
    end
end

if ~isempty(missingAttributes)
    if datasetExists(filePath, "/csi/real") && ...
            datasetExists(filePath, "/csi/imag")
        report.category = "legacy_wifo_hdf5";
        report = addError(report, ...
            "This is a legacy WiFo-style HDF5 file, not a v3 input file. " + ...
            "Convert it with convert_legacy_wifo_hdf5_to_v3 first.");
    else
        report.category = "non_v3_hdf5";
        report = addError(report, ...
            "This HDF5 file is missing required v3 root attributes: " + ...
            strjoin(missingAttributes, ", ") + ".");
    end
    report = finalize(report);
    return;
end

try
    schemaVersion = string(h5readatt(filePath, "/", "schema_version"));
    domain = lower(string(h5readatt(filePath, "/", "domain")));
catch exception
    report.category = "invalid_v3_metadata";
    report = addError(report, ...
        "The v3 root metadata could not be read: " + ...
        string(exception.message));
    report = finalize(report);
    return;
end

report.schema_version = schemaVersion;
report.domain = domain;
if ~startsWith(schemaVersion, "v3.0-data-contract.")
    report = addError(report, ...
        "Unsupported schema_version '" + schemaVersion + ...
        "'. Expected v3.0-data-contract.*.");
end

if domain == "ctf"
    requiredDatasets = [ ...
        "/ctf/H_real_values", "/ctf/H_real_shape", ...
        "/ctf/H_imag_values", "/ctf/H_imag_shape"];
elseif domain == "cir"
    requiredDatasets = [ ...
        "/cir/coefficient_real_values", ...
        "/cir/coefficient_real_shape", ...
        "/cir/coefficient_imag_values", ...
        "/cir/coefficient_imag_shape", ...
        "/cir/delay_s_values", "/cir/delay_s_shape", ...
        "/cir/path_valid_values", "/cir/path_valid_shape"];
else
    requiredDatasets = strings(0, 1);
    report = addError(report, ...
        "Root attribute domain must be 'cir' or 'ctf'.");
end

missingDatasets = strings(0, 1);
for datasetPath = requiredDatasets
    if ~datasetExists(filePath, datasetPath)
        missingDatasets(end + 1, 1) = datasetPath; %#ok<AGROW>
    end
end
if ~isempty(missingDatasets)
    report = addError(report, ...
        "The v3 payload is incomplete. Missing datasets: " + ...
        strjoin(missingDatasets, ", ") + ".");
end

if isempty(report.errors)
    report.category = "v3_channel_hdf5";
end
report = finalize(report);
end

function report = inspectMatFile(report, filePath)
try
    variables = whos("-file", filePath);
catch exception
    report.category = "invalid_mat";
    report = addError(report, ...
        "The selected MAT file could not be inspected: " + ...
        string(exception.message));
    return;
end

names = lower(string({variables.name}));
if any(names == "sage")
    report.category = "legacy_sage_mat";
    report = addError(report, ...
        "This is a legacy SAGE MAT file. Step 4 uploads one standard .h5; " + ...
        "convert the complete SAGE folder with " + ...
        "convert_sage_folder_to_v3_hdf5 first.");
elseif any(contains(names, "dpsd") | contains(names, "pdp"))
    report.category = "power_feature_mat";
    report = addError(report, ...
        "This MAT file contains a power feature such as DPSD/PDP, not a " + ...
        "complete complex CIR or CTF. Lost phase cannot be reconstructed.");
elseif any(ismember(names, [ ...
        "input", "output", "predictions", "ground_truth"]))
    report.category = "model_feature_mat";
    report = addError(report, ...
        "This MAT file is a model input/output or prediction result, not a " + ...
        "standard complex CIR/CTF channel file.");
else
    report.category = "unsupported_mat";
    report = addError(report, ...
        "MAT files are not a formal Step 4 upload format. Convert the " + ...
        "source data to one v3 standard .h5 file first.");
end
end

function report = newReport()
report = struct( ...
    "is_valid", true, ...
    "status", "PASS", ...
    "errors", strings(0, 1), ...
    "warnings", strings(0, 1), ...
    "category", "unclassified", ...
    "source_file_name", "", ...
    "source_extension", "", ...
    "source_bytes", 0, ...
    "schema_version", "", ...
    "domain", "");
end

function report = addError(report, message)
report.errors(end + 1, 1) = string(message);
report.is_valid = false;
end

function report = finalize(report)
if ~isempty(report.errors)
    report.status = "FAIL";
    report.is_valid = false;
elseif ~isempty(report.warnings)
    report.status = "WARNING";
else
    report.status = "PASS";
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

function exists = datasetExists(filePath, datasetPath)
try
    h5info(filePath, datasetPath);
    exists = true;
catch
    exists = false;
end
end
