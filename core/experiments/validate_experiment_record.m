function report = validate_experiment_record(experimentRoot)
%VALIDATE_EXPERIMENT_RECORD Verify experiment structure and data identity.

arguments
    experimentRoot (1, 1) string
end
errors = strings(0, 1);
warnings = strings(0, 1);
try
    record = read_experiment(experimentRoot);
catch exception
    report = struct("status", "FAIL", "is_valid", false, ...
        "errors", string(exception.message), "warnings", warnings);
    return;
end
manifest = record.manifest;
status = record.status;
for field = ["schema_version", "experiment_id", "manager", "dataset", ...
        "experiment_config", "experiment_config_sha256", "code"]
    if ~isfield(manifest, field)
        errors(end + 1, 1) = "Missing manifest field: " + field; %#ok<AGROW>
    end
end
if isempty(errors)
    if string(manifest.schema_version) ~= "v3.1-2-experiment-record.1"
        errors(end + 1, 1) = "Unsupported experiment manifest schema.";
    end
    allowed = ["pending", "running", "completed", "failed"];
    if ~isfield(status, "status") || ~any(string(status.status) == allowed)
        errors(end + 1, 1) = "Experiment status is missing or invalid.";
    end
    if isfield(manifest.dataset, "provided") && logical(manifest.dataset.provided)
        path = string(manifest.dataset.manifest_path);
        if ~isfile(path)
            errors(end + 1, 1) = "Referenced dataset manifest is missing.";
        elseif sha256_file(path) ~= string(manifest.dataset.manifest_sha256)
            errors(end + 1, 1) = "Referenced dataset manifest hash changed.";
        end
    else
        warnings(end + 1, 1) = "No dataset manifest is attached to this experiment.";
    end
end
if isempty(errors)
    statusText = "PASS";
    valid = true;
else
    statusText = "FAIL";
    valid = false;
end
report = struct("status", statusText, "is_valid", valid, ...
    "errors", errors, "warnings", warnings);
end
