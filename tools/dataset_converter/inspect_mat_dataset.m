function report = inspect_mat_dataset(inputPath)
%INSPECT_MAT_DATASET Inspect MATLAB dataset files without modifying them.
%   report = inspect_mat_dataset(inputPath) returns variable names, classes,
%   dimensions, and likely channel-related field hints for one .mat file or
%   every .mat file under a folder.

inputPath = string(inputPath);
files = resolveMatFiles(inputPath);

report = struct();
report.input_path = inputPath;
report.file_count = numel(files);
report.files = repmat(struct("path", "", "variables", []), 1, numel(files));

for k = 1:numel(files)
    filePath = files(k);
    vars = whos("-file", filePath);
    variableReports = repmat(struct( ...
        "name", "", "class", "", "size", [], "is_complex", false, ...
        "channel_hints", strings(0, 1)), 1, numel(vars));

    for v = 1:numel(vars)
        variableReports(v).name = string(vars(v).name);
        variableReports(v).class = string(vars(v).class);
        variableReports(v).size = vars(v).size;
        variableReports(v).is_complex = vars(v).complex;
        variableReports(v).channel_hints = inferHints(vars(v).name);
    end

    report.files(k).path = filePath;
    report.files(k).variables = variableReports;
end
end

function files = resolveMatFiles(inputPath)
if isfolder(inputPath)
    listing = dir(fullfile(inputPath, "**", "*.mat"));
    files = string(fullfile({listing.folder}, {listing.name}));
elseif isfile(inputPath)
    files = inputPath;
else
    error("inspect_mat_dataset:MissingPath", "Input path does not exist: %s", inputPath);
end
end

function hints = inferHints(name)
lowerName = lower(string(name));
candidateHints = ["SAGE", "CIR", "CTF", "PDP", "Doppler", "Delay", "Angle", "Channel Matrix"];
patterns = ["sage", "cir", "ctf", "pdp", "doppler", "delay", "angle", "h"];
hints = strings(0, 1);

for idx = 1:numel(patterns)
    if contains(lowerName, patterns(idx))
        hints(end + 1, 1) = candidateHints(idx); %#ok<AGROW>
    end
end
end

