function record = create_experiment(assetRoot, options)
%CREATE_EXPERIMENT Create a no-overwrite local experiment record.

arguments
    assetRoot (1, 1) string
    options.ExperimentId (1, 1) string = ""
    options.DatasetManifestPath (1, 1) string = ""
    options.ExperimentConfig (1, 1) struct = struct()
    options.CodeRoot (1, 1) string = ""
end

manager = default_experiment_manager_config(assetRoot);
if strlength(strtrim(assetRoot)) == 0
    error("create_experiment:InvalidAssetRoot", "assetRoot cannot be empty.");
end
if ~isfolder(assetRoot)
    mkdir(assetRoot);
end
if strlength(options.CodeRoot) > 0
    manager.repository_root = options.CodeRoot;
end
experimentId = options.ExperimentId;
if strlength(experimentId) == 0
    experimentId = "exp_" + string(datetime("now", "TimeZone", "UTC", ...
        "Format", "yyyyMMdd_HHmmss_SSS"));
end
if isempty(regexp(char(experimentId), "^[A-Za-z0-9][A-Za-z0-9_.-]*$", "once"))
    error("create_experiment:InvalidExperimentId", ...
        "ExperimentId may contain only letters, numbers, underscore, dot and dash.");
end
experimentRoot = fullfile(assetRoot, manager.experiment_subdirectory, experimentId);
if isfolder(experimentRoot) || isfile(experimentRoot)
    error("create_experiment:ExperimentExists", ...
        "Refusing to overwrite experiment: %s", experimentRoot);
end

dataset = datasetReference(options.DatasetManifestPath);
mkdir(experimentRoot);
mkdir(fullfile(experimentRoot, "logs"));
mkdir(fullfile(experimentRoot, "reports"));
mkdir(fullfile(experimentRoot, "artifacts"));
manifest = struct( ...
    "schema_version", "v3.1-2-experiment-record.1", ...
    "experiment_id", experimentId, ...
    "created_utc", utcNow(), ...
    "manager", manager, ...
    "dataset", dataset, ...
    "experiment_config", options.ExperimentConfig, ...
    "experiment_config_sha256", sha256_experiment_config(options.ExperimentConfig), ...
    "code", codeReference(manager.repository_root), ...
    "output_directories", struct("logs", "logs", "reports", "reports", "artifacts", "artifacts"));
status = struct( ...
    "schema_version", "v3.1-2-experiment-status.1", ...
    "experiment_id", experimentId, ...
    "status", "pending", ...
    "updated_utc", utcNow(), ...
    "message", "Experiment record created.", ...
    "history", struct("status", "pending", "updated_utc", utcNow(), ...
        "message", "Experiment record created."));
writeNewJson(fullfile(experimentRoot, "experiment_manifest.json"), manifest);
writeNewJson(fullfile(experimentRoot, "status.json"), status);
record = read_experiment(experimentRoot);
end

function value = datasetReference(path)
value = struct("manifest_path", "", "manifest_sha256", "", "provided", false);
if strlength(path) == 0
    return;
end
if ~isfile(path)
    error("create_experiment:DatasetManifestMissing", ...
        "Dataset manifest does not exist: %s", path);
end
value.manifest_path = path;
value.manifest_sha256 = sha256_file(path);
value.provided = true;
end

function value = codeReference(repositoryRoot)
value = struct("repository_root", repositoryRoot, "git_revision", "unknown", ...
    "git_dirty", "unknown", "matlab_version", string(version), ...
    "matlab_release", string(version("-release")), "platform", string(computer));
if ~isfolder(repositoryRoot)
    return;
end
[status, revision] = system("git -C " + quoteForSystem(repositoryRoot) + " rev-parse HEAD");
if status == 0
    value.git_revision = strtrim(string(revision));
end
[status, porcelain] = system("git -C " + quoteForSystem(repositoryRoot) + " status --porcelain");
if status == 0
    value.git_dirty = ~isempty(strtrim(porcelain));
end
end

function value = quoteForSystem(path)
value = '"' + replace(string(path), '"', '\\"') + '"';
end

function writeNewJson(path, value)
if isfile(path)
    error("create_experiment:RecordExists", ...
        "Refusing to overwrite %s", path);
end
fid = fopen(path, "w");
if fid < 0
    error("create_experiment:CannotWrite", "Cannot create %s", path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "%s\n", jsonencode(value, PrettyPrint=true));
end

function value = utcNow()
value = string(datetime("now", "TimeZone", "UTC", ...
    "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'"));
end
