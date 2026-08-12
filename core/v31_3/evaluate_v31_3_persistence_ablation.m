function [rows, summary] = evaluate_v31_3_persistence_ablation(corpusManifestPath, config)
%EVALUATE_V31_3_PERSISTENCE_ABLATION Score P2/P4/P6/P8 without leakage.
%   The deterministic Persistence baseline is evaluated over every example in
%   the merged v3.1-2 corpus. Validation is evidence for bundle freezing;
%   Test is report-only and must not influence the frozen choice.

arguments
    corpusManifestPath (1, 1) string
    config (1, 1) struct = default_v31_3_evidence_config()
end
assetReport = validate_v31_2_corpus_asset(corpusManifestPath);
if ~assetReport.is_valid
    error("evaluate_v31_3_persistence_ablation:InvalidCorpusAsset", ...
        "%s", strjoin(assetReport.errors, " | "));
end
manifest = jsondecode(fileread(corpusManifestPath));
root = fileparts(corpusManifestPath);
rows = table();
for task = config.tasks
    for bundleName = string(fieldnames(config.parameter_bundles)).'
        path = bundlePath(manifest, root, task, bundleName);
        bundle = read_predictor_data_hdf5(path);
        for partition = [config.selection_partition, config.report_partition]
            index = partitionIndex(bundle.split, partition);
            item = scorePartition(bundle, index);
            row = table(string(task), bundleName, string(partition), ...
                numel(index), numel(bundle.dataset.parameter_names), ...
                item.mean_relative_nrmse, item.median_group_relative_nrmse, ...
                item.worst_group_relative_nrmse, item.mean_raw_rmse, ...
                'VariableNames', {'task_type', 'bundle_name', 'partition', ...
                'example_count', 'parameter_count', 'mean_relative_nrmse', ...
                'median_group_relative_nrmse', 'worst_group_relative_nrmse', ...
                'mean_raw_rmse'});
            rows = [rows; row]; %#ok<AGROW>
        end
    end
end
summary = rows;
end

function path = bundlePath(manifest, root, task, bundleName)
expected = "step11abc_" + task + "_" + lower(bundleName) + ".h5";
entries = manifest.predictor_files;
paths = string({entries.relative_path});
match = endsWith(paths, expected);
if nnz(match) ~= 1
    error("evaluate_v31_3_persistence_ablation:BundleMissing", ...
        "Cannot resolve exactly one corpus bundle for %s/%s.", task, bundleName);
end
path = fullfile(root, paths(match));
end

function index = partitionIndex(split, partition)
switch string(partition)
    case "validation"
        index = split.validation_example_index;
    case "test"
        index = split.test_example_index;
    otherwise
        error("evaluate_v31_3_persistence_ablation:UnsupportedPartition", ...
            "Only validation and test are valid evidence partitions.");
end
end

function result = scorePartition(bundle, index)
data = bundle.dataset;
inputs = double(data.inputs(index, :, :));
targets = double(data.targets(index, :, :));
prediction = repmat(inputs(:, end, :), 1, size(targets, 2), 1);
sigma = reshape(double(data.normalization.standard_deviation), 1, 1, []);
meanValue = reshape(double(data.normalization.mean), 1, 1, []);
rawPrediction = prediction .* sigma + meanValue;
rawTargets = targets .* sigma + meanValue;
bounds = double(data.parameter_bounds);
span = reshape(max(eps, bounds(:, 2) - bounds(:, 1)), 1, 1, []);
relative = (rawPrediction - rawTargets) ./ span;
exampleError = sqrt(mean(relative .^ 2, [2, 3]));
rawError = sqrt(mean((rawPrediction - rawTargets) .^ 2, [2, 3]));
groups = string(data.example_group_id(index));
uniqueGroups = unique(groups, "stable");
groupError = zeros(numel(uniqueGroups), 1);
for groupIndex = 1:numel(uniqueGroups)
    groupError(groupIndex) = mean(exampleError(groups == uniqueGroups(groupIndex)));
end
result = struct( ...
    "mean_relative_nrmse", mean(exampleError), ...
    "median_group_relative_nrmse", median(groupError), ...
    "worst_group_relative_nrmse", max(groupError), ...
    "mean_raw_rmse", mean(rawError));
end
