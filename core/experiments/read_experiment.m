function record = read_experiment(experimentRoot)
%READ_EXPERIMENT Load immutable manifest and mutable status for one run.

arguments
    experimentRoot (1, 1) string
end
manifestPath = fullfile(experimentRoot, "experiment_manifest.json");
statusPath = fullfile(experimentRoot, "status.json");
if ~isfile(manifestPath) || ~isfile(statusPath)
    error("read_experiment:MissingRecord", ...
        "Experiment manifest or status is missing in %s", experimentRoot);
end
record = struct( ...
    "root", experimentRoot, ...
    "manifest", jsondecode(fileread(manifestPath)), ...
    "status", jsondecode(fileread(statusPath)));
end
