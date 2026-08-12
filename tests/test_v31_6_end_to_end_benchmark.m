function tests = test_v31_6_end_to_end_benchmark
%TEST_V31_6_END_TO_END_BENCHMARK Smoke-test the frozen MATLAB evaluator.
tests = functiontests(localfunctions);
end

function testIdenticalAndChangedChannels(testCase)
repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(repoRoot, "core")));
H = complex(randn(2, 2, 8, 4, 1), randn(2, 2, 8, 4, 1));
first = channel(H);
same = compare_v31_6_channels(first, first);
verifyEqual(testCase, same.complex_nmse, 0, AbsTol=1e-14);
second = channel(H * 1.1);
changed = compare_v31_6_channels(first, second);
verifyGreaterThan(testCase, changed.complex_nmse, 0);
verifyGreaterThan(testCase, changed.pdp_nrmse, 0);
verifyFalse(testCase, changed.angular_metric_available);
end

function testValidationSmokeCreatesBoundGate(testCase)
repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(repoRoot, "core")));
temporaryRoot = string(tempname);
mkdir(temporaryRoot);
cleanup = onCleanup(@() rmdir(temporaryRoot, 's')); %#ok<NASGU>
configPath = string(fullfile(repoRoot, "configs", ...
    "v31_6_end_to_end_benchmark.json"));
pairPath = fullfile(temporaryRoot, "pairs.csv");
rows = syntheticRows();
writetable(rows, pairPath);
exportPath = fullfile(temporaryRoot, "export.json");
export = struct("schema_version", "v3.1-6-parameter-export.1", ...
    "evaluation_partition", "validation", ...
    "protocol_config_sha256", compute_benchmark_file_sha256(configPath), ...
    "generator_pairs_sha256", compute_benchmark_file_sha256(pairPath));
writeText(exportPath, jsonencode(export));
% The smoke fixture exercises two candidates only; the formal runner rejects
% incomplete frozen matrices before generation. Duplicate rows to the frozen
% Validation size without changing the two expected summary candidates.
rows = repmat(rows, 55, 1);
writetable(rows, pairPath);
export.generator_pairs_sha256 = compute_benchmark_file_sha256(pairPath);
writeText(exportPath, jsonencode(export));
output = fullfile(temporaryRoot, "results");
[details, summary, manifest] = run_v31_6_full_benchmark( ...
    pairPath, exportPath, configPath, output, ...
    Backend="mock", Mode="preview");
verifyEqual(testCase, height(details), 2);
verifyEqual(testCase, height(summary), 2);
verifyEqual(testCase, string(manifest.evaluation_partition), "validation");
gate = jsondecode(fileread(fullfile(output, "v31_6_validation_gate.json")));
verifyTrue(testCase, gate.passed);
verifyFalse(testCase, gate.test_partition_used);
verifyEqual(testCase, string(gate.protocol_config_sha256), ...
    compute_benchmark_file_sha256(configPath));
end

function testTestRejectsGateNotBoundIntoExport(testCase)
repoRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(fullfile(repoRoot, "core")));
temporaryRoot = string(tempname);
mkdir(temporaryRoot);
cleanup = onCleanup(@() rmdir(temporaryRoot, 's')); %#ok<NASGU>
configPath = string(fullfile(repoRoot, "configs", ...
    "v31_6_end_to_end_benchmark.json"));
pairPath = fullfile(temporaryRoot, "pairs.csv");
rows = syntheticRows();
rows.partition(:) = "test";
writetable(rows, pairPath);
gatePath = fullfile(temporaryRoot, "gate.json");
gate = struct("schema_version", "v3.1-6-validation-gate.1", ...
    "passed", true, "test_partition_used", false, ...
    "protocol_config_sha256", compute_benchmark_file_sha256(configPath));
writeText(gatePath, jsonencode(gate));
exportPath = fullfile(temporaryRoot, "export.json");
export = struct("schema_version", "v3.1-6-parameter-export.1", ...
    "evaluation_partition", "test", ...
    "protocol_config_sha256", compute_benchmark_file_sha256(configPath), ...
    "generator_pairs_sha256", compute_benchmark_file_sha256(pairPath), ...
    "validation_gate", struct("sha256", repmat('0', 1, 64), "payload", gate));
writeText(exportPath, jsonencode(export));
rows = repmat(rows, 330, 1);
writetable(rows, pairPath);
export.generator_pairs_sha256 = compute_benchmark_file_sha256(pairPath);
writeText(exportPath, jsonencode(export));
verifyError(testCase, @() run_v31_6_full_benchmark( ...
    pairPath, exportPath, configPath, fullfile(temporaryRoot, "results"), ...
    Backend="mock", Mode="preview", ValidationGate=gatePath), ...
    "run_v31_6_full_benchmark:GateHashMismatch");
end

function dataset = channel(H)
dataset = struct("ctf_dataset", struct("ctf", struct("H", H), ...
    "axes", struct("frequency_hz", linspace(15.95e9, 16.05e9, 8).')));
end

function rows = syntheticRows()
candidates = ["persistence"; "linear"];
rows = table(repmat("validation", 2, 1), ...
    repmat("interpolation", 2, 1), candidates, candidates, ...
    repmat("persistence", 2, 1), repmat("route-00", 2, 1), ...
    repmat(100, 2, 1), repmat(31601, 2, 1), false(2, 1), ...
    repmat("deterministic_mock", 2, 1), repmat(16e9, 2, 1), ...
    repmat(1.0, 2, 1), repmat(2, 2, 1), repmat(2, 2, 1), ...
    repmat(0.1, 2, 1), repmat(0.1, 2, 1), ...
    'VariableNames', {'partition', 'task_type', 'candidate_id', ...
    'selected_model', 'registry_recommended_model', 'group_id', ...
    'target_step', 'protocol_seed', 'is_stability_subset', 'scenario_name', ...
    'carrier_frequency_hz', 'route_speed_mps', 'tx_count', 'rx_count', ...
    'parameter_nrmse', 'sensitivity_weighted_nrmse'});
names = ["DS_mu", "KF_mu", "DS_sigma", "KF_sigma", ...
    "r_DS", "LNS_ksi", "num_clusters", "num_rays"];
truth = [-7.925, -0.39, 0.060, 2.4, 2.8, 3.0, 12, 20];
for index = 1:numel(names)
    rows.("truth_" + names(index)) = repmat(truth(index), 2, 1);
    rows.("predicted_" + names(index)) = repmat(truth(index), 2, 1);
end
rows.predicted_DS_mu(2) = rows.predicted_DS_mu(2) + 0.05;
end

function writeText(path, text)
file = fopen(path, 'w');
cleanup = onCleanup(@() fclose(file)); %#ok<NASGU>
fwrite(file, text, 'char');
end
