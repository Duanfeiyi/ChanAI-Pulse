function frozen = freeze_v31_3_parameter_bundles(sensitivitySummary, ablationRows, config)
%FREEZE_V31_3_PARAMETER_BUNDLES Choose evidence-backed P-bundles per task.

arguments
    sensitivitySummary table
    ablationRows table
    config (1, 1) struct = default_v31_3_evidence_config()
end
required = ["parameter_name", "sensitivity_score"];
if ~all(ismember(required, string(sensitivitySummary.Properties.VariableNames)))
    error("freeze_v31_3_parameter_bundles:InvalidSensitivitySummary", ...
        "Sensitivity summary must include parameter_name and sensitivity_score.");
end
scores = zeros(numel(config.parameter_names), 1);
for index = 1:numel(config.parameter_names)
    match = string(sensitivitySummary.parameter_name) == config.parameter_names(index);
    if nnz(match) ~= 1
        error("freeze_v31_3_parameter_bundles:MissingParameter", ...
            "Sensitivity evidence is missing %s.", config.parameter_names(index));
    end
    scores(index) = sensitivitySummary.sensitivity_score(match);
end
if any(~isfinite(scores)) || sum(scores) <= 0
    error("freeze_v31_3_parameter_bundles:InvalidScores", ...
        "Sensitivity scores must be finite with positive total evidence.");
end
coverage = cumsum(scores) / sum(scores);
p6Coverage = coverage(6);
p8Increment = 1 - p6Coverage;
decisions = repmat(struct("task_type", "", "bundle_name", "", ...
    "reason", "", "sensitivity_coverage", 0, ...
    "persistence_validation_relative_nrmse", NaN), 0, 1);
for task = config.tasks
    if task == "extrapolation"
        bundle = smallestBundleAtCoverage(coverage, ...
            config.freezing.minimum_extrapolation_coverage);
    else
        if p6Coverage >= config.freezing.minimum_interpolation_coverage && ...
                p8Increment < config.freezing.minimum_p8_increment
            bundle = 6;
        else
            bundle = 8;
        end
    end
    bundleName = "P" + bundle;
    evidence = ablationRows(string(ablationRows.task_type) == task & ...
        string(ablationRows.bundle_name) == bundleName & ...
        string(ablationRows.partition) == config.selection_partition, :);
    if height(evidence) ~= 1
        error("freeze_v31_3_parameter_bundles:AblationEvidenceMissing", ...
            "Validation ablation evidence is missing %s/%s.", task, bundleName);
    end
    decisions(end + 1, 1) = struct( ...
        "task_type", task, "bundle_name", bundleName, ...
        "reason", "Full-6GPCM sensitivity coverage and validation-only Persistence diagnostic.", ...
        "sensitivity_coverage", coverage(bundle), ...
        "persistence_validation_relative_nrmse", evidence.mean_relative_nrmse); %#ok<AGROW>
end
frozen = struct( ...
    "schema_version", "v3.1-3-parameter-bundle-freeze.1", ...
    "selection_partition", config.selection_partition, ...
    "test_truth_used_for_selection", false, ...
    "parameter_names", config.parameter_names, ...
    "parameter_bounds", config.parameter_bounds, ...
    "sensitivity_scores", table2struct(sensitivitySummary), ...
    "decisions", decisions, ...
    "full_6gpcm_core_modified", false, ...
    "note", "P-bundle choices are frozen from sensitivity and validation-only evidence; final independent end-to-end accuracy remains v3.1-6 scope.");
end

function count = smallestBundleAtCoverage(coverage, threshold)
candidates = [2, 4, 6, 8];
count = 8;
for candidate = candidates
    if coverage(candidate) >= threshold
        count = candidate;
        return;
    end
end
end
