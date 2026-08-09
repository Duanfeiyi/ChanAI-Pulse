% Step 13 independent Benchmark acceptance.
clearvars;
clc;

repoRoot = string(fileparts(fileparts(mfilename("fullpath"))));
addpath(repoRoot);
addpath(genpath(fullfile(repoRoot, "core")));
addpath(genpath(fullfile(repoRoot, "examples")));
temporaryRoot = string(tempname);
cleanup = onCleanup(@() removeTemporary(temporaryRoot));
paths = prepare_step13_review_data(temporaryRoot);

%% Good inputs align, produce base and dimension-driven metrics and baselines.
config = default_channel_benchmark_config();
config.export_report = true;
config.output_root = fullfile(temporaryRoot, "reports");
result = run_channel_benchmark(paths.original_file, ...
    paths.prediction_directory, config);
assert(result.comparability_status == "PASS");
assert(result.quality_label == "BETTER_THAN_BASELINE");
assert(result.metrics.prediction.complex_nmse < 0.01);
assert(result.metrics.prediction.complex_correlation > 0.99);
assert(result.metrics.prediction.complex_nmse < ...
    result.metrics.persistence.complex_nmse);
assert(isfinite(result.metrics.prediction.spatial_correlation_nrmse));
assert(isfinite(result.metrics.prediction.angular_spectrum_nrmse));
assert(isfinite(result.metrics.prediction.time_autocorrelation_nrmse));
assert(isfinite(result.metrics.prediction.doppler_spectrum_nrmse));
assert(numel(result.per_target) == 6);
assert(numel(result.per_link) == 8);
assert(isfile(result.exports.summary_csv));
assert(isfile(result.exports.per_target_csv));
assert(isfile(result.exports.per_link_csv));
assert(isfile(result.exports.report_markdown));
assert(isfile(result.exports.metrics_png));
assert(isfile(result.exports.target_png));
assert(isfile(result.exports.manifest_json));

%% Optional repeated-realization entry reports mean and standard deviation.
repeatConfig = default_channel_benchmark_config();
repeatConfig.repeat_count = 2;
repeatPaths = prepare_step13_review_data(fullfile(temporaryRoot, "repeat_2"), ...
    NoiseSeed=1414);
repeated = run_repeated_channel_benchmark(paths.original_file, ...
    [paths.prediction_directory; repeatPaths.prediction_directory], repeatConfig);
assert(repeated.repeat_count == 2);
assert(repeated.comparability_status == "PASS");
assert(repeated.aggregate.complex_nmse.available_count == 2);
assert(repeated.aggregate.complex_nmse.std > 0);

%% Deliberate target-order mismatch is blocked before metric calculation.
blocked = false;
try
    run_channel_benchmark(paths.original_file, ...
        paths.misaligned_prediction_directory);
catch exception
    blocked = exception.identifier == "run_channel_benchmark:AlignmentFailed";
end
assert(blocked, "A misaligned prediction package was not blocked.");

%% The independent UI uses the same core and can export the same report.
app = ChannelBenchmark(Visible="off");
cleanupApp = onCleanup(@() delete(app));
app.loadBenchmarkInputs(paths.original_file, paths.prediction_directory);
uiResult = app.runCurrentBenchmark();
state = app.getReviewState();
assert(state.has_result);
assert(state.comparability_status == "PASS");
assert(abs(uiResult.metrics.prediction.complex_nmse - ...
    result.metrics.prediction.complex_nmse) < 1e-12);
assert(height(app.MetricTable.Data) == 12);
app.LanguageDropDown.Value = "en";
callback = app.LanguageDropDown.ValueChangedFcn;
callback([], []);
assert(app.InputTab.Title == "1. Data & Alignment");
assert(app.RunButton.Text == "Run Benchmark");
app.LanguageDropDown.Value = "zh";
callback([], []);
assert(app.InputTab.Title == "1. 数据与对齐");
uiFiles = app.exportCurrentBenchmark(fullfile(temporaryRoot, "ui_reports"));
assert(isfile(uiFiles.manifest_json));
app.loadBenchmarkInputs(paths.original_file, ...
    paths.misaligned_prediction_directory);
resetState = app.getReviewState();
assert(~resetState.has_result);
assert(app.RunButton.Enable == "off");
assert(isempty(app.MetricTable.Data));

fprintf("PASS: Step 13 Benchmark core, baselines, strict alignment, reports and UI.\n");

function removeTemporary(path)
if isfolder(path), rmdir(path, "s"); end
end
