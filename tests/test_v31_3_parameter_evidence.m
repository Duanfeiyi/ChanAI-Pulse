% v3.1-3 parameter-evidence regression without a Full 6GPCM long run.

clearvars;
clc;

repoRoot = fileparts(fileparts(mfilename("fullpath")));
addpath(genpath(fullfile(repoRoot, "core")));

corpusConfig = default_v31_2_corpus_config();
corpusConfig.route.group_count = 8;
corpusConfig.route.samples_per_group = 48;
corpusConfig.data.split_fractions = [0.75, 0.125, 0.125];
corpusConfig.data.split_group_counts = [6, 1, 1];
corpusConfig.corpus_id = "v31_3_test_corpus";
corpus = create_v31_2_training_corpus( ...
    "Config", corpusConfig, "UseExternalProfiles", false);
assetRoot = string(tempname);
mkdir(assetRoot);
cleanup = onCleanup(@() rmdir(assetRoot, "s"));
asset = write_v31_2_training_corpus(corpus, assetRoot);

config = default_v31_3_evidence_config();
[rows, summary] = evaluate_v31_3_persistence_ablation( ...
    asset.manifest_path, config);
assert(height(rows) == 16, "Expected validation/test evidence for 2 tasks and 4 bundles.");
assert(height(summary) == height(rows));
assert(all(rows.example_count > 0) && all(isfinite(rows.mean_relative_nrmse)), ...
    "Every v3.1-3 ablation row must contain finite evidence.");
assert(all(ismember(unique(rows.partition), ["validation", "test"])), ...
    "Ablation may only read validation and test partitions.");

syntheticSensitivity = table(config.parameter_names(:), (1:8).', ...
    'VariableNames', {'parameter_name', 'sensitivity_score'});
frozen = freeze_v31_3_parameter_bundles(syntheticSensitivity, rows, config);
assert(~frozen.test_truth_used_for_selection, ...
    "The frozen bundle choice must not use test truth.");
assert(numel(frozen.decisions) == 2, "One frozen decision per task is required.");
assert(string(frozen.decisions(1).bundle_name) == "P8" && ...
    string(frozen.decisions(2).bundle_name) == "P8", ...
    "The deterministic synthetic evidence should preserve P8/P8 task choices.");
assert(string(frozen.selection_partition) == "validation" && ...
    ~frozen.test_truth_used_for_selection, ...
    "The freeze record must derive its no-test-truth claim from validation-only selection.");

testSelection = config;
testSelection.selection_partition = "test";
assertThrows(@() freeze_v31_3_parameter_bundles( ...
    syntheticSensitivity, rows, testSelection), ...
    "validate_v31_3_evidence_config:SelectionMustBeValidation");

validationReport = config;
validationReport.report_partition = "validation";
assertThrows(@() evaluate_v31_3_persistence_ablation( ...
    asset.manifest_path, validationReport), ...
    "validate_v31_3_evidence_config:ReportMustBeTest");

unmapped = config;
unmapped.parameter_names(8) = "unsupported_parameter";
unmapped.parameter_bundles.P8(8) = "unsupported_parameter";
assertThrows(@() validate_v31_3_evidence_config(unmapped), ...
    "validate_v31_3_evidence_config:IncompleteGeneratorMapping");

flooredSensitivity = syntheticSensitivity;
flooredSensitivity.sensitivity_score(1) = ...
    config.freezing.sensitivity_score_floor / 2;
floored = freeze_v31_3_parameter_bundles(flooredSensitivity, rows, config);
assert(floored.effective_sensitivity_scores(1) == 0, ...
    "Sensitivity evidence below the configured floor must not affect coverage.");

fprintf("PASS: v3.1-3 ablation and parameter-bundle freeze are valid.\n");

function assertThrows(action, expectedIdentifier)
try
    action();
catch exception
    assert(string(exception.identifier) == expectedIdentifier, ...
        "Expected %s, received %s.", expectedIdentifier, exception.identifier);
    return;
end
error("test_v31_3_parameter_evidence:ExpectedError", ...
    "Expected %s to be raised.", expectedIdentifier);
end
