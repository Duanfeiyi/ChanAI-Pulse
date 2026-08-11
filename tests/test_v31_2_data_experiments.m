% v3.1-2 corpus and Experiment Manager regression (no external data).

clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));

config = default_v31_2_corpus_config();
config.route.group_count = 8;
config.route.samples_per_group = 48;
config.data.split_fractions = [0.75, 0.125, 0.125];
config.data.split_group_counts = [6, 1, 1];
corpus = create_v31_2_training_corpus( ...
    "Config", config, "UseExternalProfiles", false);

assert(corpus.schema_version == "v3.1-2-training-corpus.1");
assert(height(corpus.group_catalog) == 8, "Route catalog count changed.");
assert(all(corpus.group_catalog.route_speed_mps > 0), ...
    "Every route must have a positive speed.");
assert(all(corpus.group_catalog.tx_count >= 1) && ...
    all(corpus.group_catalog.rx_count >= 1), ...
    "Every route must expose antenna metadata.");
assert(all(corpus.group_catalog.route_configuration_role == "catalog_metadata_only"), ...
    "v3.1-2 route configurations must not be presented as predictor inputs.");
assert(~corpus.sequence.provenance.v31_2.full_cir_generated && ...
    ~corpus.sequence.provenance.v31_2.route_speed_applied_to_labels && ...
    ~corpus.sequence.provenance.v31_2.antenna_counts_applied_to_labels, ...
    "v3.1-2 provenance must disclose the parameter-corpus boundary.");
for task = ["interpolation", "extrapolation"]
    split = corpus.bundles.(task).P8.split;
    assert(split.leakage_check.passed, "Route groups leaked between partitions.");
    assert(numel(split.train_group_id) == 6 && ...
        isscalar(split.validation_group_id) && ...
        isscalar(split.test_group_id), "Unexpected route-group partition.");
end

assetRoot = string(tempname);
mkdir(assetRoot);
assetCleanup = onCleanup(@() rmdir(assetRoot, "s"));
asset = write_v31_2_training_corpus(corpus, assetRoot);
assert(isfile(asset.manifest_path), "Corpus manifest was not written.");
assetReport = validate_v31_2_corpus_asset(asset.manifest_path);
assert(assetReport.is_valid, strjoin(assetReport.errors, " | "));

experiment = create_experiment(assetRoot, ...
    "ExperimentId", "v31_2_smoke", ...
    "DatasetManifestPath", asset.manifest_path, ...
    "ExperimentConfig", struct("model", "Persistence", "seed", config.route.seed));
assert(string(experiment.status.status) == "pending");
recordReport = validate_experiment_record(experiment.root);
assert(recordReport.is_valid, strjoin(recordReport.errors, " | "));

experiment = update_experiment_status(experiment.root, "running", "Smoke run started.");
assert(string(experiment.status.status) == "running");
experiment = update_experiment_status(experiment.root, "completed", "Smoke run completed.");
assert(string(experiment.status.status) == "completed");
assert(numel(experiment.status.history) == 3, "Status history was not retained.");

duplicateRejected = false;
try
    create_experiment(assetRoot, "ExperimentId", "v31_2_smoke");
catch exception
    duplicateRejected = exception.identifier == "create_experiment:ExperimentExists";
end
assert(duplicateRejected, "Existing experiment ids must never be overwritten.");

% The recorded experiment configuration is immutable and content-addressed.
configProbe = create_experiment(assetRoot, ...
    "ExperimentId", "v31_2_config_tamper", ...
    "ExperimentConfig", struct("model", "Persistence"));
configManifestPath = fullfile(configProbe.root, "experiment_manifest.json");
configManifest = jsondecode(fileread(configManifestPath));
configManifest.experiment_config.model = "Altered";
fid = fopen(configManifestPath, "w");
assert(fid >= 0, "Unable to modify temporary experiment manifest for the test.");
fprintf(fid, "%s\n", jsonencode(configManifest, PrettyPrint=true));
fclose(fid);
configTamperedReport = validate_experiment_record(configProbe.root);
assert(~configTamperedReport.is_valid && any(contains( ...
    configTamperedReport.errors, "configuration hash changed")), ...
    "Experiment Manager must reject a changed experiment configuration.");

% Attached datasets are content-addressed: even harmless whitespace changes
% must invalidate the recorded SHA-256 rather than silently changing a run.
fid = fopen(asset.manifest_path, "a");
assert(fid >= 0, "Unable to modify temporary corpus manifest for the test.");
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, "\n");
clear cleanup
tamperedReport = validate_experiment_record(experiment.root);
assert(~tamperedReport.is_valid && any(contains( ...
    tamperedReport.errors, "hash changed")), ...
    "Experiment Manager must reject a changed dataset manifest.");

fprintf("PASS: v3.1-2 corpus asset, route split and Experiment Manager are valid.\n");
