function report = run_v31_3_parameter_evidence(assetRoot, options)
%RUN_V31_3_PARAMETER_EVIDENCE Run and record the v3.1-3 evidence study.
%   All generated reports stay under the caller-selected Git-external asset
%   root. Existing experiment ids are refused rather than overwritten.

arguments
    assetRoot (1, 1) string
    options.CorpusManifestPath (1, 1) string
    options.EngineRoot (1, 1) string = ""
    options.ExperimentId (1, 1) string = "v31_3_parameter_evidence.1"
    options.Config (1, 1) struct = default_v31_3_evidence_config()
end
config = options.Config;
if string(config.schema_version) ~= "v3.1-3-parameter-evidence-config.1"
    error("run_v31_3_parameter_evidence:UnsupportedConfig", ...
        "Unsupported v3.1-3 evidence configuration.");
end
assetReport = validate_v31_2_corpus_asset(options.CorpusManifestPath);
if ~assetReport.is_valid
    error("run_v31_3_parameter_evidence:InvalidCorpusAsset", ...
        "%s", strjoin(assetReport.errors, " | "));
end
installation = resolve_full_6gpcm_root("EngineRoot", options.EngineRoot);
if ~installation.has_public_api
    error("run_v31_3_parameter_evidence:FullEngineUnavailable", ...
        "Full 6GPCM public API is unavailable at %s.", installation.root);
end
record = create_experiment(assetRoot, ...
    "ExperimentId", options.ExperimentId, ...
    "DatasetManifestPath", options.CorpusManifestPath, ...
    "ExperimentConfig", config, ...
    "CodeRoot", string(fileparts(fileparts(fileparts(mfilename("fullpath"))))));
update_experiment_status(record.root, "running", ...
    "Running v3.1-3 ablation and Full 6GPCM sensitivity evidence.");
try
    [ablationRows, ablationSummary] = evaluate_v31_3_persistence_ablation( ...
        options.CorpusManifestPath, config);
    [sensitivityRows, sensitivitySummary] = evaluate_v31_3_full_sensitivity( ...
        installation.root, config);
    frozen = freeze_v31_3_parameter_bundles( ...
        sensitivitySummary, ablationRows, config);
    reportDirectory = fullfile(record.root, "reports");
    writetable(ablationRows, fullfile(reportDirectory, "persistence_ablation.csv"));
    writetable(sensitivityRows, fullfile(reportDirectory, "full_6gpcm_sensitivity.csv"));
    writetable(sensitivitySummary, fullfile(reportDirectory, "full_6gpcm_sensitivity_summary.csv"));
    writeJson(fullfile(reportDirectory, "parameter_bundle_freeze.json"), frozen);
    report = struct( ...
        "schema_version", "v3.1-3-parameter-evidence-report.1", ...
        "experiment_root", record.root, ...
        "corpus_manifest_path", options.CorpusManifestPath, ...
        "corpus_manifest_sha256", sha256_file(options.CorpusManifestPath), ...
        "ablation_summary", ablationSummary, ...
        "sensitivity_summary", sensitivitySummary, ...
        "parameter_bundle_freeze", frozen, ...
        "full_6gpcm_core_modified", false);
    save(fullfile(reportDirectory, "v31_3_parameter_evidence_report.mat"), "report");
    update_experiment_status(record.root, "completed", ...
        "Completed v3.1-3 evidence study.");
catch exception
    update_experiment_status(record.root, "failed", string(exception.message));
    rethrow(exception)
end
end

function writeJson(path, value)
if isfile(path)
    error("run_v31_3_parameter_evidence:ReportExists", ...
        "Refusing to overwrite %s", path);
end
fid = fopen(path, "w");
if fid < 0
    error("run_v31_3_parameter_evidence:CannotWrite", ...
        "Cannot write %s", path);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "%s\n", jsonencode(value, PrettyPrint=true));
end
