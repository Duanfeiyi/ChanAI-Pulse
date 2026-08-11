function report = validate_v31_2_corpus_asset(manifestPath)
%VALIDATE_V31_2_CORPUS_ASSET Verify local corpus files against its manifest.

arguments
    manifestPath (1, 1) string
end
errors = strings(0, 1);
warnings = strings(0, 1);
if ~isfile(manifestPath)
    report = finish("FAIL", false, "Corpus manifest does not exist.", warnings);
    return;
end
try
    manifest = jsondecode(fileread(manifestPath));
catch exception
    report = finish("FAIL", false, string(exception.message), warnings);
    return;
end
if ~isfield(manifest, "schema_version") || ...
        string(manifest.schema_version) ~= "v3.1-2-corpus-asset-manifest.1"
    errors(end + 1, 1) = "Unsupported corpus asset manifest schema.";
end
if ~isfield(manifest, "predictor_files")
    errors(end + 1, 1) = "Corpus manifest does not contain predictor_files.";
end
if isempty(errors)
    root = fileparts(manifestPath);
    entries = manifest.predictor_files;
    if ~isstruct(entries)
        errors(end + 1, 1) = "predictor_files must be a struct array.";
    else
        for index = 1:numel(entries)
            relativePath = string(entries(index).relative_path);
            if isAbsolutePath(relativePath) || contains(relativePath, "..")
                errors(end + 1, 1) = "Manifest contains unsafe predictor file path."; %#ok<AGROW>
                continue;
            end
            path = fullfile(root, relativePath);
            if ~isfile(path)
                errors(end + 1, 1) = "Manifest predictor file is missing: " + relativePath; %#ok<AGROW>
            else
                info = dir(path);
                if info.bytes ~= entries(index).bytes
                    errors(end + 1, 1) = "Predictor file size changed: " + relativePath; %#ok<AGROW>
                end
                if sha256_file(path) ~= string(entries(index).sha256)
                    errors(end + 1, 1) = "Predictor file hash changed: " + relativePath; %#ok<AGROW>
                end
            end
        end
    end
end
if isempty(errors)
    report = finish("PASS", true, errors, warnings);
else
    report = finish("FAIL", false, errors, warnings);
end
end

function tf = isAbsolutePath(path)
tf = startsWith(path, ["/", "\\"]) || ~isempty(regexp(char(path), "^[A-Za-z]:", "once"));
end

function report = finish(status, valid, errors, warnings)
report = struct("status", status, "is_valid", valid, ...
    "errors", string(errors), "warnings", warnings);
end
