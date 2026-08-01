function report = run_step11abc_end_to_end_validation(engineRoot, benchmarkRoot, outputDirectory, options)
%RUN_STEP11ABC_END_TO_END_VALIDATION Offline P2/P4/P6/P8 Full-6GPCM check.
%   Accuracy is deliberately emitted as a separate test artifact, not UI data.

arguments
    engineRoot (1, 1) string
    benchmarkRoot (1, 1) string
    outputDirectory (1, 1) string
    options.MaxPairsPerBundle (1, 1) double {mustBeInteger, mustBePositive} = 3
end
if ~isfolder(benchmarkRoot)
    error("run_step11abc_end_to_end_validation:BenchmarkRootMissing", "Benchmark root not found: %s", benchmarkRoot);
end
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end
pairFiles = dir(fullfile(benchmarkRoot, "**", "*_step11abc_full_generator_pairs.csv"));
if isempty(pairFiles)
    error("run_step11abc_end_to_end_validation:PairsMissing", "No generator-pair CSV files found under %s", benchmarkRoot);
end
rows = table();
for fileIndex = 1:numel(pairFiles)
    filePath = fullfile(pairFiles(fileIndex).folder, pairFiles(fileIndex).name);
    data = readtable(filePath, "TextType", "string");
    [taskType, bundleName] = inferIdentity(filePath);
    selected = selectIndependentRows(data, options.MaxPairsPerBundle);
    for pairIndex = 1:height(selected)
        truth = probeFromRow(engineRoot, selected(pairIndex, :), "truth", pairIndex);
        generated = probeFromRow(engineRoot, selected(pairIndex, :), "generated", pairIndex);
        truthFeatures = cirFeatures(truth.dataset);
        generatedFeatures = cirFeatures(generated.dataset);
        newRow = table(string(taskType), string(bundleName), pairIndex, string(selected.group_id(pairIndex)), double(selected.target_step(pairIndex)), parameterNrmse(selected(pairIndex, :)), pdpNrmse(truthFeatures.pdp, generatedFeatures.pdp), abs(truthFeatures.rms_delay_s - generatedFeatures.rms_delay_s), truth.report.elapsed_s + generated.report.elapsed_s, truth.report.core_unchanged && generated.report.core_unchanged, 'VariableNames', {'task_type', 'bundle_name', 'pair_index', 'group_id', 'target_step', 'parameter_nrmse', 'pdp_nrmse', 'rms_delay_abs_error_s', 'elapsed_s', 'full_core_unchanged'});
        rows = [rows; newRow]; %#ok<AGROW>
    end
end
summary = groupsummary(rows, {'task_type', 'bundle_name'}, 'mean', {'parameter_nrmse', 'pdp_nrmse', 'rms_delay_abs_error_s'});
selection = chooseSmallestAcceptableBundle(summary);
writetable(rows, fullfile(outputDirectory, "step11abc_end_to_end_pairs.csv"));
writetable(summary, fullfile(outputDirectory, "step11abc_end_to_end_summary.csv"));
fid = fopen(fullfile(outputDirectory, "step11abc_bundle_selection.json"), "w");
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, "%s\n", jsonencode(selection, PrettyPrint=true));
report = struct("schema_version", "v3.0-step11abc-end-to-end-validation.1", "pairs", rows, "summary", summary, "bundle_selection", selection, "product_ui_accuracy_plots", false, "note", "External test evidence only; product UI remains characteristic-only.");
save(fullfile(outputDirectory, "step11abc_end_to_end_report.mat"), "report");
end

function selected = selectIndependentRows(data, maxCount)
[~, first] = unique(string(data.group_id), "stable");
selected = data(sort(first), :);
selected = selected(1:min(maxCount, height(selected)), :);
end

function [taskType, bundleName] = inferIdentity(filePath)
parts = split(string(filePath), filesep);
tokens = split(parts(end - 1), "_");
taskType = tokens(2);
bundleName = upper(tokens(end));
end

function output = probeFromRow(engineRoot, row, prefix, pairIndex)
config = default_full_6gpcm_probe_config(engineRoot);
config.random_seed = 8000 + pairIndex;
config.sample_count = 1;
config.DS_mu = row.(prefix + "_DS_mu");
config.KF_mu = row.(prefix + "_KF_mu");
config.DS_sigma = row.(prefix + "_DS_sigma");
config.KF_sigma = row.(prefix + "_KF_sigma");
config.r_DS = row.(prefix + "_r_DS");
config.LNS_ksi = row.(prefix + "_LNS_ksi");
config.num_clusters = round(row.(prefix + "_num_clusters"));
config.num_rays = round(row.(prefix + "_num_rays"));
output = run_full_6gpcm_probe(config);
end

function features = cirFeatures(dataset)
power = abs(dataset.cir.coefficient).^2;
delay = dataset.cir.delay_s;
pathPower = squeeze(sum(power, [1, 2, 4, 5]));
pathDelay = squeeze(mean(delay, [1, 2, 4, 5]));
pathPower = pathPower(:);
pathDelay = pathDelay(:);
weight = pathPower / max(eps, sum(pathPower));
meanDelay = sum(weight .* pathDelay);
rmsDelay = sqrt(max(0, sum(weight .* (pathDelay - meanDelay).^2)));
edges = linspace(0, max(1e-9, max(pathDelay)), 65);
[~, ~, bins] = histcounts(pathDelay, edges);
pdp = accumarray(max(1, bins), pathPower, [64, 1], @sum, 0);
features = struct("pdp", pdp / max(eps, sum(pdp)), "rms_delay_s", rmsDelay);
end

function value = pdpNrmse(truth, prediction)
value = sqrt(mean((truth(:) - prediction(:)).^2)) / max(eps, sqrt(mean(truth(:).^2)));
end

function value = parameterNrmse(row)
names = ["DS_mu", "KF_mu", "DS_sigma", "KF_sigma", "r_DS", "LNS_ksi", "num_clusters", "num_rays"];
truth = zeros(1, numel(names));
prediction = zeros(1, numel(names));
for index = 1:numel(names)
    truth(index) = row.("truth_" + names(index));
    prediction(index) = row.("generated_" + names(index));
end
value = sqrt(mean((truth - prediction).^2)) / max(eps, sqrt(mean(truth.^2)));
end

function selection = chooseSmallestAcceptableBundle(summary)
tasks = unique(string(summary.task_type));
decisions = struct();
for task = tasks.'
    subset = summary(string(summary.task_type) == task, :);
    score = subset.mean_pdp_nrmse;
    candidate = subset(score <= min(score) * 1.05, :);
    rank = double(extractAfter(string(candidate.bundle_name), "P"));
    [~, index] = min(rank);
    decisions.(matlab.lang.makeValidName(task)) = struct("selected_bundle", candidate.bundle_name(index), "best_pdp_nrmse", min(score), "selection_tolerance", 0.05, "reason", "smallest_bundle_within_5_percent_of_best_end_to_end_pdp_nrmse");
end
selection = struct("schema_version", "v3.0-step11abc-bundle-selection.1", "ordinary_user_policy", "auto", "advanced_user_policy", "manual_compatible_bundle_selection", "decisions", decisions);
end
