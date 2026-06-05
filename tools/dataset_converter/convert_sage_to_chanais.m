function chanais = convert_sage_to_chanais(inputPath, outputDir, metadata)
%CONVERT_SAGE_TO_CHANAIS Convert SAGE-like MAT files to ChanAIs structure.
%   chanais = convert_sage_to_chanais(inputPath, outputDir, metadata)
%   reads one SAGE .mat file or a folder of .mat files and writes a
%   normalized ChanAIs-compatible .mat file under outputDir.
%
%   The function never modifies original input files. Generated outputs
%   from private datasets should remain local and should not be committed.

arguments
    inputPath (1, 1) string
    outputDir (1, 1) string = ""
    metadata = struct()
end

if isempty(fieldnames(metadata))
    metadata = build_metadata_template();
end

files = resolveMatFiles(inputPath);
records = struct([]);
warnings = strings(0, 1);

for fileIdx = 1:numel(files)
    filePath = files(fileIdx);
    loaded = load(filePath);

    if ~isfield(loaded, "sage")
        warnings(end + 1, 1) = "Missing sage variable: " + filePath; %#ok<AGROW>
        continue;
    end

    sageRecords = normalizeSageContainer(loaded.sage);
    parsedName = parseSageFilename(filePath);

    for recordIdx = 1:numel(sageRecords)
        source = sageRecords{recordIdx};
        record = struct();
        record.record_id = sprintf("sage_%04d_%04d", fileIdx, recordIdx);
        record.source_file = filePath;
        record.time_window = parsedName.time_window;
        record.polarization = parsedName.polarization;
        record.frequency_id = parsedName.frequency_id;
        record.trajectory = parsedName.trajectory;
        record.data_type = "SAGE";
        record.path_parameters = struct();
        record.quality = struct();

        record = copyIfPresent(record, source, "alpha", "path_parameters", "alpha");
        record = copyIfPresent(record, source, "doa", "path_parameters", "doa");
        record = copyIfPresent(record, source, "delay", "path_parameters", "delay");
        record = copyIfPresent(record, source, "cir", "", "cir");
        record = copyIfPresent(record, source, "cir_e", "", "cir_estimated");
        record = copyIfPresent(record, source, "likelihood", "quality", "likelihood");

        missing = requiredSageFieldsMissing(source);
        if ~isempty(missing)
            record.warning = "Missing SAGE fields: " + strjoin(missing, ", ");
        end

        records = [records, record]; %#ok<AGROW>
    end
end

chanais = struct();
chanais.metadata = metadata;
chanais.records = records;
chanais.features = struct();
chanais.labels = struct();
chanais.converter = struct( ...
    "name", "convert_sage_to_chanais", ...
    "version", "v1.1.0-draft", ...
    "input_path", inputPath, ...
    "warnings", warnings);

if outputDir ~= ""
    if ~isfolder(outputDir)
        mkdir(outputDir);
    end
    outputFile = fullfile(outputDir, "chanais_sage_converted.mat");
    save(outputFile, "chanais", "-v7.3");
end
end

function files = resolveMatFiles(inputPath)
if isfolder(inputPath)
    listing = dir(fullfile(inputPath, "**", "*.mat"));
    files = string(fullfile({listing.folder}, {listing.name}));
elseif isfile(inputPath)
    files = inputPath;
else
    error("convert_sage_to_chanais:MissingPath", "Input path does not exist: %s", inputPath);
end
end

function sageRecords = normalizeSageContainer(sage)
if iscell(sage)
    sageRecords = sage(:);
elseif isstruct(sage)
    sageRecords = num2cell(sage(:));
else
    warning("convert_sage_to_chanais:UnsupportedSage", "Unsupported sage container class: %s", class(sage));
    sageRecords = {};
end
end

function parsed = parseSageFilename(filePath)
[~, name, ~] = fileparts(filePath);
tokens = split(string(name), "_");
parsed = struct("polarization", "unspecified", "frequency_id", "unspecified", ...
    "trajectory", "unspecified", "time_window", "unspecified");

if numel(tokens) >= 2 && startsWith(tokens(1), "Pol", "IgnoreCase", true)
    parsed.polarization = tokens(1) + "_" + tokens(2);
end

sageIdx = find(strcmpi(tokens, "SAGE"), 1);
if ~isempty(sageIdx)
    if numel(tokens) >= sageIdx + 1
        parsed.frequency_id = tokens(sageIdx + 1);
    end
    if numel(tokens) >= sageIdx + 2
        parsed.trajectory = tokens(sageIdx + 2);
    end
    if numel(tokens) >= sageIdx + 3
        parsed.time_window = tokens(sageIdx + 3);
    end
end
end

function record = copyIfPresent(record, source, sourceField, parentField, targetField)
if ~isfield(source, sourceField)
    return;
end

if parentField == ""
    record.(targetField) = source.(sourceField);
else
    record.(parentField).(targetField) = source.(sourceField);
end
end

function missing = requiredSageFieldsMissing(source)
required = ["alpha", "doa", "delay", "cir", "cir_e", "likelihood"];
missing = required(~isfield(source, required));
end

